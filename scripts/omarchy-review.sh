#!/usr/bin/env bash

# Report what Omarchy has grown that this configuration has not decided about,
# and what Omarchy has taken back. Run it after `omarchy update`.
#
# Two things drift, and they drift differently.
#
# Omarchy ships a Bash configuration full of aliases and functions, some of
# which are worth having here. omarchy/ledger.tsv records the verdict on each
# one; this subtracts the ledger from what Omarchy currently defines, so the
# output is only ever the new arrivals. That is news, not a problem.
#
# Omarchy also ships user configuration files, and four of them this repository
# either owns or has to keep out of the way. omarchy-refresh-config copies
# $OMARCHY_PATH/config/<path> over ~/.config/<path> with cp -f, which writes
# through a symlink rather than replacing it -- so a refresh overwrites the
# contents of a file in this repository, where git will show it, instead of
# quietly detaching the link. The Omarchy menu reaches this through
# omarchy-refresh-hyprland and omarchy-refresh-tmux, which name exactly these
# files, so it is one click away rather than hypothetical. That is a
# regression, so it exits 1; new definitions on their own exit 0.
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
ledger="$repo_dir/omarchy/ledger.tsv"
omarchy_path="${OMARCHY_PATH:-/usr/share/omarchy}"
bash_dir="$omarchy_path/default/bash"
config_dir="$omarchy_path/config"

if [[ ! -d $bash_dir ]]; then
  printf 'Omarchy is not installed at %s; nothing to review.\n' "$omarchy_path"
  exit 0
fi
if [[ ! -r $ledger ]]; then
  printf 'Missing ledger: %s\n' "$ledger" >&2
  exit 1
fi

# Path under ~/.config, then the file in this repository that should be linked
# there -- or "-" where nothing should be at that path at all, because tmux
# reads a file there after ~/.tmux.conf and would override it.
managed_files=(
  'tmux/tmux.conf|-'
  'hypr/input.lua|hypr/input.lua'
  'hypr/looknfeel.lua|hypr/looknfeel.lua'
  'hypr/bindings.lua|hypr/bindings.lua'
  'hypr/autostart.lua|hypr/autostart.lua'
  'kitty/kitty.conf|kitty/kitty.conf'
  'omarchy/plugins/eric.tray|omarchy/plugins/eric.tray'
  'starship.toml|starship/starship.toml'
)

# Aliases, functions, and exports, minus the ones whose names start with an
# underscore -- those are Omarchy's internal helpers, not an interface.
current_definitions() {
  {
    grep -ohE '^alias [a-zA-Z0-9_.-]+=' \
      "$bash_dir"/aliases "$bash_dir"/envs "$bash_dir"/shell 2>/dev/null |
      sed 's/^alias //; s/=$//'
    grep -ohE '^[a-zA-Z0-9_-]+\(\)' \
      "$bash_dir"/aliases "$bash_dir"/fns/* 2>/dev/null |
      sed 's/()//'
    grep -ohE '^export [A-Z_]+' "$bash_dir"/envs 2>/dev/null |
      sed 's/^export //'
  } | grep -v '^_' | sort -u
}

decided() {
  grep -v '^#' -- "$ledger" | awk -F'\t' 'NF { print $1 }' | sort -u
}

# Whether a refresh has run recently enough to still have its backup around.
# omarchy-refresh-config leaves <file>.bak.<epoch> when the contents differed.
refresh_backup() {
  local target="$1" backup
  backup="$(
    find "$(dirname "$target")" -maxdepth 1 -name "$(basename "$target").bak.*" \
      -print 2>/dev/null | sort | tail -1
  )"
  printf '%s' "$backup"
}

report_files() {
  local row config_path repo_path target problem backup drifted=0

  for row in "${managed_files[@]}"; do
    config_path="${row%%|*}"
    repo_path="${row##*|}"
    target="$HOME/.config/$config_path"
    problem=""

    if [[ $repo_path == '-' ]]; then
      if [[ -e $target || -L $target ]]; then
        problem="reappeared, and tmux reads it after ~/.tmux.conf"
      fi
    elif [[ ! -L $target ]]; then
      [[ -e $target ]] &&
        problem="is no longer a link into this repository" ||
        problem="is missing"
    elif [[ "$(readlink -f -- "$target")" != "$repo_dir/$repo_path" ]]; then
      problem="links somewhere else: $(readlink -- "$target")"
    elif [[ -e "$config_dir/$config_path" ]] &&
         cmp -s "$repo_dir/$repo_path" "$config_dir/$config_path"; then
      problem="was overwritten with Omarchy's default, through the link"
    fi

    [[ -n $problem ]] || continue
    drifted=1
    printf '  ~/.config/%s\n      %s\n' "$config_path" "$problem"
    backup="$(refresh_backup "$target")"
    [[ -n $backup ]] &&
      printf '      Omarchy saved the previous contents as %s\n' "${backup/#$HOME/\~}"
  done

  return $(( drifted ))
}

printf 'Omarchy %s\n' "$(pacman -Q omarchy 2>/dev/null | awk '{print $2}' || printf 'version unknown')"
printf '%s definitions, %s decided in the ledger.\n' \
  "$(current_definitions | wc -l)" "$(decided | wc -l)"
printf '%s managed files checked against what Omarchy ships.\n\n' "${#managed_files[@]}"

file_drift=0
file_report="$(report_files)" || file_drift=1
if (( file_drift )); then
  printf 'Files Omarchy has taken back:\n\n%s\n' "$file_report"
  printf '\nRestore them with:\n\n'
  printf '  git -C %s checkout -- .\n' "${repo_dir/#$HOME/\~}"
  printf '  bash %s/install --links-only\n\n' "${repo_dir/#$HOME/\~}"
fi

undecided=$(comm -23 <(current_definitions) <(decided))
if [[ -z $undecided ]]; then
  printf 'No new shell definitions.\n'
  exit "$file_drift"
fi

printf 'Not in the ledger:\n\n'
while read -r name; do
  [[ -n $name ]] || continue
  printf '  %s\n' "$name"
  # Show where it comes from, which is usually enough to judge it.
  grep -rhn -m1 -E "^(alias )?${name}(\(\)|=)" "$bash_dir"/aliases \
    "$bash_dir"/envs "$bash_dir"/shell "$bash_dir"/fns/* 2>/dev/null |
    head -1 | sed 's/^/      /'
done <<<"$undecided"

printf '\nAdd a row to %s for each, then rerun.\n' "${ledger#"$repo_dir"/}"
exit "$file_drift"
