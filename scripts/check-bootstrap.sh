#!/usr/bin/env bash

set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/vim-bootstrap.XXXXXX")"
trap 'rm -rf "$tmp_dir"' EXIT

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
HOME="$tmp_dir/home" zsh -n "$tmp_dir/zsh/zshrc"

for target in \
  .vim .vimrc .tmux.conf .zshrc .zprofile .zsh_plugins.txt \
  .gitconfig .config/nvim/init.vim .config/starship.toml .config/zsh-abbr/user-abbreviations; do
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

echo "Clean offline bootstrap check passed in $tmp_dir"
