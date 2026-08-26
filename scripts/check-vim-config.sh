#!/usr/bin/env bash

set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
vim_dir="$repo_dir/vim"

command -v vim >/dev/null 2>&1 || {
  echo "Required command not found: vim" >&2
  exit 2
}

# -es is silent Ex mode, which suppresses messages -- including the error that
# made Vim exit non-zero, so a rejected configuration says nothing at all about
# itself. verbosefile captures what the screen would have shown, and verbose=1
# names each file as it is sourced, so the log ends at the one that failed.
verbose_log="$(mktemp "${TMPDIR:-/tmp}/vim-check.XXXXXX")"
trap 'rm -f "$verbose_log"' EXIT

vim_status=0
(
  cd "$vim_dir" &&
    vim --cmd "set runtimepath^=$vim_dir" \
      --cmd "set verbose=1 verbosefile=$verbose_log" \
      -Nu "$vim_dir/vimrc" -i NONE -n -es -c 'qa!'
) || vim_status=$?

if (( vim_status != 0 )); then
  printf 'Vim rejected %s (exit %s)\n' "$vim_dir/vimrc" "$vim_status" >&2
  vim --version | head -1 >&2
  printf -- '--- last 40 lines of the load log ---\n' >&2
  tail -40 "$verbose_log" >&2
  exit 1
fi

echo "Vim configuration loaded successfully: $vim_dir/vimrc"
