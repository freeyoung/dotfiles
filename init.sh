#!/usr/bin/env bash

set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Required command not found: $1" >&2
    exit 2
  fi
}

backup_and_link() {
  local source="$1"
  local target="$2"

  if [[ -L "$target" && "$(readlink "$target")" == "$source" ]]; then
    echo "Already linked: $target"
    return
  fi

  if [[ -e "$target" || -L "$target" ]]; then
    local backup
    backup="${target}.backup-$(date +%Y%m%d%H%M%S)"
    mv "$target" "$backup"
    echo "Backed up $target to $backup"
  fi

  ln -s "$source" "$target"
  echo "Linked $target -> $source"
}

require_command zsh
require_command vim
require_command curl
require_command git
require_command fzf
require_command rg

backup_and_link "$repo_dir/tmux.conf" "$HOME/.tmux.conf"
backup_and_link "$repo_dir/vimrc" "$HOME/.vimrc"
backup_and_link "$repo_dir/zshrc.oh-my-zsh" "$HOME/.zshrc"
backup_and_link "$repo_dir/zshrc.extras" "$HOME/.zshrc.extras"

if [[ ! -f "$repo_dir/autoload/plug.vim" ]]; then
  curl -fsSL --create-dirs -o "$repo_dir/autoload/plug.vim" \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

mkdir -p "$repo_dir/state/undo" "$repo_dir/state/swap" "$repo_dir/state/backup"
if [[ -f "$repo_dir/plugins.lock.vim" ]]; then
  vim -Nu NONE -n -es \
    -c "execute 'source' fnameescape('$repo_dir/autoload/plug.vim')" \
    -c "execute 'source' fnameescape('$repo_dir/plugs.vim')" \
    -c "execute 'source' fnameescape('$repo_dir/plugins.lock.vim')" \
    -c 'qa'
else
  vim -Nu NONE -n -es \
    -c "execute 'source' fnameescape('$repo_dir/autoload/plug.vim')" \
    -c "execute 'source' fnameescape('$repo_dir/plugs.vim')" \
    -c 'PlugInstall --sync' \
    -c 'qa'
fi

if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  git clone https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
else
  echo "Keeping existing oh-my-zsh installation: $HOME/.oh-my-zsh"
fi

echo "Bootstrap complete. Set your login shell manually with: chsh -s $(command -v zsh)"
