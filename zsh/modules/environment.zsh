# Homebrew, PATH, locale, and shared shell helpers.

# Login shells initialise Homebrew in ~/.zprofile. Keep this fallback for
# editor terminals and manually-started non-login shells, without paying for a
# second `brew shellenv` in normal iTerm login shells.
if [[ -z ${HOMEBREW_PREFIX:-} ]]; then
  if (( $+commands[brew] )); then
    eval "$(brew shellenv zsh)"
  elif [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv zsh)"
  elif [[ -x "$HOME/.linuxbrew/bin/brew" ]]; then
    eval "$("$HOME/.linuxbrew/bin/brew" shellenv zsh)"
  elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv zsh)"
  fi
fi

# A nested non-login Zsh can inherit HOMEBREW_PREFIX without inheriting the
# fpath mutation from `brew shellenv`. Keep Homebrew completion functions
# discoverable independently of whether the shellenv fallback ran.
typeset -U path PATH fpath
if [[ -n ${HOMEBREW_PREFIX:-} && -d "$HOMEBREW_PREFIX/share/zsh/site-functions" ]]; then
  fpath=("$HOMEBREW_PREFIX/share/zsh/site-functions" $fpath)
fi

typeset -a zsh_gnu_paths zsh_managed_paths
# These must precede /usr/bin so `ls`, `grep`, etc. resolve to Homebrew GNU
# tools even when the terminal starts with a plain macOS PATH.
zsh_gnu_paths=(
  "${HOMEBREW_PREFIX:-/opt/homebrew}/opt/grep/libexec/gnubin"
  "${HOMEBREW_PREFIX:-/opt/homebrew}/opt/coreutils/libexec/gnubin"
)
for zsh_gnu_path in "${zsh_gnu_paths[@]}"; do
  [[ -d "$zsh_gnu_path" ]] && path=("$zsh_gnu_path" $path)
done
zsh_managed_paths=(
  "$HOME/.local/bin"
  "$HOME/go/bin"
  "$HOME/.antigravity/antigravity/bin"
  "$HOME/.bun/bin"
  "$HOME/.kimi-code/bin"
)
for zsh_managed_path in "${zsh_managed_paths[@]}"; do
  [[ -d "$zsh_managed_path" ]] && path+=("$zsh_managed_path")
done
unset zsh_gnu_path zsh_gnu_paths zsh_managed_path zsh_managed_paths

export EDITOR="${EDITOR:-vim}"
export BUN_INSTALL="$HOME/.bun"
# Preserve an existing host locale; use the familiar UTF-8 locale only when a
# minimal environment has not set one. LC_ALL remains overridable by the host.
export LANG="${LANG:-en_US.UTF-8}"
export LC_ALL="${LC_ALL:-$LANG}"

# This file is deliberately outside the repository. It is for machine- and
# employer-specific aliases, integrations, and paths; copy the committed
# example on a fresh host before editing it.
[[ -r "$HOME/.config/zsh/local.zsh" ]] && source "$HOME/.config/zsh/local.zsh"

# Runtime modules and prompt hooks share this helper.
autoload -Uz add-zsh-hook
