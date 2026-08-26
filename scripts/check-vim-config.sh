#!/usr/bin/env bash

set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
vim_dir="$repo_dir/vim"

command -v vim >/dev/null 2>&1 || {
  echo "Required command not found: vim" >&2
  exit 2
}

# -es keeps Vim silent, which means a configuration it rejects fails with no
# indication of why. Capture both streams and print them on failure.
vim_output=""
vim_status=0
vim_output="$(
  cd "$vim_dir" &&
    vim --cmd "set runtimepath^=$vim_dir" -Nu "$vim_dir/vimrc" \
      -i NONE -n -es -c 'qa!' 2>&1
)" || vim_status=$?

if (( vim_status != 0 )); then
  printf 'Vim rejected %s (exit %s)\n' "$vim_dir/vimrc" "$vim_status" >&2
  [[ -n $vim_output ]] && printf '%s\n' "$vim_output" >&2
  vim --version | head -1 >&2
  exit 1
fi

echo "Vim configuration loaded successfully: $vim_dir/vimrc"
