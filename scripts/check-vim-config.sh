#!/usr/bin/env bash

set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
vim_dir="$repo_dir/vim"

command -v vim >/dev/null 2>&1 || {
  echo "Required command not found: vim" >&2
  exit 2
}

(cd "$vim_dir" && vim --cmd "set runtimepath^=$vim_dir" -Nu "$vim_dir/vimrc" -i NONE -n -es -c 'qa!')
echo "Vim configuration loaded successfully: $vim_dir/vimrc"
