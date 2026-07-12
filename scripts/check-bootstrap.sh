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

HOME="$tmp_dir/home" bash "$tmp_dir/init.sh"
HOME="$tmp_dir/home" bash "$tmp_dir/scripts/check-vim-config.sh"

[[ -d "$tmp_dir/home/.oh-my-zsh" ]] || {
  echo "Bootstrap did not create oh-my-zsh" >&2
  exit 1
}

for plugin in fzf fzf.vim vim-lsp vim-lsp-settings; do
  expected="$(grep -F "g:plugs['$plugin'].commit" "$tmp_dir/plugins.lock.vim" | sed -E "s/.*commit = '([^']+)'.*/\1/")"
  plugin_dir="$tmp_dir/plugged/$plugin"
  [[ -d "$plugin_dir/.git" ]] || {
    echo "Bootstrap did not install plugin checkout: $plugin" >&2
    exit 1
  }
  actual="$(git -C "$plugin_dir" rev-parse --short HEAD)"
  [[ "$actual" == "$expected" ]] || {
    echo "Plugin $plugin is at $actual, expected $expected" >&2
    exit 1
  }
done

echo "Clean bootstrap check passed in $tmp_dir"
