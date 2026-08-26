#!/usr/bin/env bash

# Report what Omarchy's shell configuration defines that this one has not
# decided about yet. Run it after `omarchy update`.
#
# Omarchy ships a Bash configuration full of aliases and functions, some of
# which are worth having here. omarchy/ledger.tsv records the verdict on each
# one; this subtracts the ledger from what Omarchy currently defines, so the
# output is only ever the new arrivals. Add a row to the ledger for each and
# the next run is quiet again.
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
ledger="$repo_dir/omarchy/ledger.tsv"
omarchy_path="${OMARCHY_PATH:-/usr/share/omarchy}"
bash_dir="$omarchy_path/default/bash"

if [[ ! -d $bash_dir ]]; then
  printf 'Omarchy is not installed at %s; nothing to review.\n' "$omarchy_path"
  exit 0
fi
if [[ ! -r $ledger ]]; then
  printf 'Missing ledger: %s\n' "$ledger" >&2
  exit 1
fi

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

undecided=$(comm -23 <(current_definitions) <(decided))

printf 'Omarchy %s\n' "$(pacman -Q omarchy 2>/dev/null | awk '{print $2}' || printf 'version unknown')"
printf '%s definitions, %s decided in the ledger.\n\n' \
  "$(current_definitions | wc -l)" "$(decided | wc -l)"

if [[ -z $undecided ]]; then
  printf 'Nothing new.\n'
  exit 0
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
