#!/usr/bin/env bash

set -euo pipefail

# Overriding HOME does not isolate this on its own: XDG_DATA_HOME and its
# siblings are absolute paths into the real home, so Vim went on finding the
# real plugin directory and this check passed on a machine where a fresh host
# would have failed. Clear them, which is what a fresh host looks like.
unset XDG_DATA_HOME XDG_CONFIG_HOME XDG_STATE_HOME XDG_CACHE_HOME

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/vim-bootstrap.XXXXXX")"
trap 'rm -rf "$tmp_dir"' EXIT

file_mode() {
  if [[ "$(uname -s)" == Darwin ]]; then
    stat -f '%Lp' "$1"
  else
    stat -c '%a' "$1"
  fi
}

tar \
  --exclude='./.git' \
  --exclude='./autoload' \
  --exclude='./plugged' \
  --exclude='./state' \
  --exclude='./undodir' \
  --exclude='./pack' \
  --exclude='./.ruff_cache' \
  -cf - -C "$repo_dir" . | tar -xf - -C "$tmp_dir"
mkdir -p "$tmp_dir/home"

HOME="$tmp_dir/home" bash "$tmp_dir/install" --links-only
HOME="$tmp_dir/home" bash "$tmp_dir/scripts/check-vim-config.sh"

first_ssh_directive="$(
  awk 'NF && $1 !~ /^#/ { print; exit }' "$tmp_dir/ssh/config"
)"
[[ "$first_ssh_directive" == 'IgnoreUnknown UseKeychain' ]] || {
  echo 'SSH portability guard must precede local includes' >&2
  exit 1
}
grep -Eq '^[[:space:]]+UseKeychain[[:space:]]+yes$' "$tmp_dir/ssh/config" || {
  echo 'Shared SSH config does not enable the macOS keychain' >&2
  exit 1
}

if command -v ssh >/dev/null 2>&1; then
  missing_ssh_home="$tmp_dir/missing-ssh-home"
  mkdir -p "$missing_ssh_home"
  HOME="$missing_ssh_home" \
    ssh -G -T -F "$tmp_dir/ssh/config" dotfiles-bootstrap.invalid >/dev/null

  effective_ssh_config="$(
    HOME="$tmp_dir/home" \
      ssh -G -T -F "$tmp_dir/home/.ssh/config" dotfiles-bootstrap.invalid
  )"
  for expected_setting in \
    'addkeystoagent true' \
    'forwardagent yes' \
    'serveraliveinterval 30'; do
    grep -qx "$expected_setting" <<< "$effective_ssh_config" || {
      printf 'Missing effective SSH setting: %s\n' "$expected_setting" >&2
      exit 1
    }
  done
fi

linked_targets=(
  .vim .vimrc .tmux.conf .zshrc .zprofile .zsh_plugins.txt
  .gitconfig .config/git/ignore .ssh/config .config/nvim/init.vim .config/starship.toml
  .config/zsh-abbr/user-abbreviations .config/mise/config.toml
)
# The installer guards these; mirror each guard rather than assume the host.
[[ $OSTYPE == linux* ]] && linked_targets+=(.config/fontconfig/fonts.conf .XCompose)
command -v Hyprland >/dev/null 2>&1 &&
  linked_targets+=(.config/hypr/input.lua .config/hypr/looknfeel.lua .config/hypr/bindings.lua)
command -v kitty >/dev/null 2>&1 && linked_targets+=(.config/kitty/kitty.conf)
[[ -d $tmp_dir/home/.config/omarchy ]] &&
  linked_targets+=(.config/omarchy/plugins/eric.tray)
command -v fcitx5 >/dev/null 2>&1 &&
  linked_targets+=(.config/fcitx5/table/wubi-large.conf)

for target in "${linked_targets[@]}"; do
  [[ -L "$tmp_dir/home/$target" ]] || {
    echo "Installer did not link $target" >&2
    exit 1
  }
done

[[ -f "$tmp_dir/home/.config/zsh/local.zsh" ]] || {
  echo 'Installer did not create local.zsh' >&2
  exit 1
}
[[ -f "$tmp_dir/home/.config/git/local.gitconfig" ]] || {
  echo 'Installer did not create local.gitconfig' >&2
  exit 1
}
[[ -f "$tmp_dir/home/.ssh/config.local" ]] || {
  echo 'Installer did not create SSH config.local' >&2
  exit 1
}

printf '%s\n' '# preserve-on-reinstall' >> "$tmp_dir/home/.ssh/config.local"
chmod 644 "$tmp_dir/home/.ssh/config.local"
ssh_local_checksum="$(cksum "$tmp_dir/home/.ssh/config.local")"
HOME="$tmp_dir/home" bash "$tmp_dir/install" --links-only
[[ "$(cksum "$tmp_dir/home/.ssh/config.local")" == "$ssh_local_checksum" ]] || {
  echo 'Installer overwrote the existing SSH config.local' >&2
  exit 1
}
[[ "$(file_mode "$tmp_dir/home/.ssh/config.local")" == 600 ]] || {
  echo 'Installer did not secure SSH config.local permissions' >&2
  exit 1
}

migration_home="$tmp_dir/migration-home"
mkdir -p "$migration_home/.ssh"
printf '%s\n' \
  'Host legacy-private' \
  '  HostName 192.0.2.20' \
  > "$migration_home/.ssh/config"
HOME="$migration_home" bash "$tmp_dir/install" --links-only
grep -qx 'Host legacy-private' "$migration_home/.ssh/config.local" || {
  echo 'Installer did not migrate the existing SSH configuration' >&2
  exit 1
}
migration_backup="$(
  find "$migration_home/.dotfiles-backups" \
    -type f -path '*/.ssh/config' -print -quit
)"
if [[ -z "$migration_backup" ]] ||
   ! grep -qx 'Host legacy-private' "$migration_backup"; then
  echo 'Installer did not back up the existing SSH configuration' >&2
  exit 1
fi

merge_home="$tmp_dir/merge-home"
mkdir -p "$merge_home/.ssh"
printf '%s\n' \
  'ServerAliveInterval 42' \
  'Host legacy-private' \
  '  HostName 192.0.2.20' \
  > "$merge_home/.ssh/config"
printf '%s\n' \
  'Host existing-private' \
  '  HostName 192.0.2.22' \
  > "$merge_home/.ssh/config.local"
HOME="$merge_home" bash "$tmp_dir/install" --links-only
for expected_host in 'Host existing-private' 'Host legacy-private'; do
  grep -qx "$expected_host" "$merge_home/.ssh/config.local" || {
    printf 'Merged SSH config is missing: %s\n' "$expected_host" >&2
    exit 1
  }
done
if command -v ssh >/dev/null 2>&1; then
  merge_effective_config="$(
    HOME="$merge_home" \
      ssh -G -T -F "$merge_home/.ssh/config" merge-test.invalid
  )"
  grep -qx 'serveraliveinterval 42' <<< "$merge_effective_config" || {
    echo 'Merged SSH global settings have the wrong scope' >&2
    exit 1
  }
fi

recursive_home="$tmp_dir/recursive-home"
mkdir -p "$recursive_home/.ssh"
printf '%s\n' \
  'Include=~/.ssh/config.loca[lx] sub/../config.local */config.local config.d/*.conf' \
  'Host recursive-private' \
  '  HostName 192.0.2.21' \
  > "$recursive_home/.ssh/config"
HOME="$recursive_home" bash "$tmp_dir/install" --links-only
grep -qx 'Host recursive-private' "$recursive_home/.ssh/config.local" || {
  echo 'Installer did not preserve config following a managed Include' >&2
  exit 1
}
grep -Fqx 'Include */config.local config.d/*.conf' \
  "$recursive_home/.ssh/config.local" || {
  echo 'Installer did not isolate recursive SSH Includes' >&2
  exit 1
}

# tmux reads every configuration file it finds, so one at the XDG path would
# override ~/.tmux.conf rather than add to it. Omarchy installs such a file.
shadow_home="$tmp_dir/tmux-shadow-home"
mkdir -p "$shadow_home/.config/tmux"
printf '%s\n' 'set -g prefix C-Space' > "$shadow_home/.config/tmux/tmux.conf"
HOME="$shadow_home" bash "$tmp_dir/install" --links-only
if [[ -e "$shadow_home/.config/tmux/tmux.conf" ]]; then
  echo 'Installer left a tmux configuration that shadows ~/.tmux.conf' >&2
  exit 1
fi
shadow_backup="$(
  find "$shadow_home/.dotfiles-backups" \
    -type f -path '*/.config/tmux/tmux.conf' -print -quit
)"
if [[ -z "$shadow_backup" ]] ||
   ! grep -qx 'set -g prefix C-Space' "$shadow_backup"; then
  echo 'Installer did not back up the shadowing tmux configuration' >&2
  exit 1
fi

# tmux reports configuration errors to the client that sourced the file, and
# says nothing when the server starts detached -- so source it from a client.
if command -v tmux >/dev/null 2>&1; then
  # tmux exits with the status of the last command it was given, so source-file
  # has to be the last one -- appending kill-server here would report that
  # kill-server succeeded and swallow a rejected configuration.
  tmux_socket="dotfiles-check-$$"
  tmux_status=0
  tmux -L "$tmux_socket" -f /dev/null start-server \; \
    source-file "$tmp_dir/tmux.conf" || tmux_status=$?
  tmux -L "$tmux_socket" kill-server 2>/dev/null || true
  if (( tmux_status != 0 )); then
    echo 'Tmux rejected the configuration' >&2
    exit 1
  fi
  printf 'Tmux configuration check passed.\n'
fi

echo "Clean offline bootstrap check passed in $tmp_dir"
