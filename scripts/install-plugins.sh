#!/usr/bin/env bash

# Restore the Zsh plugin bundle and the pinned Vim plugin snapshot.
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

warn() {
  printf 'Warning: %s\n' "$*" >&2
}

antidote_source=''
if command -v brew >/dev/null 2>&1; then
  candidate="$(brew --prefix antidote 2>/dev/null || true)/share/antidote/antidote.zsh"
  [[ -r "$candidate" ]] && antidote_source=$candidate
fi
[[ -z "$antidote_source" && -r "$HOME/.antidote/antidote.zsh" ]] && antidote_source="$HOME/.antidote/antidote.zsh"

if [[ -n "$antidote_source" ]]; then
  plugins_file="$repo_dir/zsh/plugins.txt"
  compiled_file="$HOME/.zsh_plugins.zsh"
  zsh -fc 'source "$1"; antidote bundle <"$2" >"$3"' antidote-bootstrap \
    "$antidote_source" "$plugins_file" "${compiled_file}.new"
  mv "${compiled_file}.new" "$compiled_file"
  printf 'Restored Zsh plugins: %s\n' "$compiled_file"
else
  warn 'Antidote is unavailable; skipped Zsh plugin restoration.'
fi

if ! command -v vim >/dev/null 2>&1; then
  warn 'Vim is unavailable; skipped Vim plugin restoration.'
  exit 0
fi
if ! command -v curl >/dev/null 2>&1; then
  warn 'curl is unavailable; skipped Vim plugin restoration.'
  exit 0
fi

vim_data_home="${XDG_DATA_HOME:-$HOME/.local/share}/vim"
plug_vim="$vim_data_home/autoload/plug.vim"
if [[ ! -r "$plug_vim" ]]; then
  mkdir -p "$(dirname "$plug_vim")"
  curl -fsSL --create-dirs -o "$plug_vim" \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

vim -Nu NONE -n -es \
  -c "execute 'source' fnameescape('$repo_dir/config/paths.vim')" \
  -c "execute 'source' fnameescape('$plug_vim')" \
  -c "execute 'source' fnameescape('$repo_dir/plugs.vim')" \
  -c "execute 'source' fnameescape('$repo_dir/plugins.lock.vim')" \
  -c 'qa!'
printf 'Restored pinned Vim plugins.\n'
