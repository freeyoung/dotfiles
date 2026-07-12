#!/usr/bin/env bash

set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

command -v vim >/dev/null 2>&1 || {
  echo "Required command not found: vim" >&2
  exit 2
}

(cd "$repo_dir" && vim --cmd "set runtimepath^=$repo_dir" -Nu "$repo_dir/vimrc" -i NONE -n -es -c 'qa!')
echo "Vim configuration loaded successfully: $repo_dir/vimrc"
