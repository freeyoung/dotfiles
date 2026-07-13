#!/usr/bin/env bash

# Install shared command-line dependencies.  Homebrew is the complete,
# reproducible path; native Linux package managers receive a useful baseline.
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

warn() {
  printf 'Warning: %s\n' "$*" >&2
}

brew_bin() {
  if command -v brew >/dev/null 2>&1; then
    command -v brew
  elif [[ -x /opt/homebrew/bin/brew ]]; then
    printf '%s\n' /opt/homebrew/bin/brew
  elif [[ -x "$HOME/.linuxbrew/bin/brew" ]]; then
    printf '%s\n' "$HOME/.linuxbrew/bin/brew"
  elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
    printf '%s\n' /home/linuxbrew/.linuxbrew/bin/brew
  fi
}

install_homebrew_macos() {
  printf 'Homebrew is required on macOS; installing it now.\n'
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

install_native_linux() {
  local manager
  printf 'No Linuxbrew found; installing the native Linux baseline.\n'

  if command -v apt-get >/dev/null 2>&1; then
    manager=apt
    sudo apt-get update
    sudo apt-get install -y zsh git curl vim tmux fzf ripgrep
    for package in bat zoxide starship; do
      sudo apt-get install -y "$package" || warn "apt package unavailable: $package"
    done
  elif command -v dnf >/dev/null 2>&1; then
    manager=dnf
    sudo dnf install -y zsh git curl vim-enhanced tmux fzf ripgrep
    for package in bat zoxide starship; do
      sudo dnf install -y "$package" || warn "dnf package unavailable: $package"
    done
  elif command -v pacman >/dev/null 2>&1; then
    manager=pacman
    sudo pacman -Sy --needed --noconfirm zsh git curl vim tmux fzf ripgrep
    for package in bat zoxide starship; do
      sudo pacman -S --needed --noconfirm "$package" || warn "pacman package unavailable: $package"
    done
  else
    warn 'No supported package manager found. Install Linuxbrew, or install zsh, git, curl, vim, tmux, fzf, ripgrep, bat, zoxide, and starship manually.'
    return 0
  fi

  printf 'Native %s baseline installed. For fnm, pyenv, kubectl, ouch, and pinned Homebrew-equivalent versions, install Linuxbrew and rerun.\n' "$manager"
}

install_antidote_from_git() {
  if [[ -r "$HOME/.antidote/antidote.zsh" ]]; then
    return
  fi
  command -v git >/dev/null 2>&1 || {
    warn 'Cannot install Antidote: git is unavailable.'
    return
  }
  printf 'Installing Antidote into %s/.antidote\n' "$HOME"
  git clone --depth=1 https://github.com/mattmc3/antidote.git "$HOME/.antidote"
}

brew_path=$(brew_bin || true)
if [[ -z "$brew_path" && $(uname -s) == Darwin ]]; then
  command -v curl >/dev/null 2>&1 || {
    printf 'curl is required to install Homebrew.\n' >&2
    exit 2
  }
  install_homebrew_macos
  brew_path=$(brew_bin)
fi

if [[ -n "$brew_path" ]]; then
  eval "$("$brew_path" shellenv)"
  "$brew_path" bundle --file "$repo_dir/Brewfile"
else
  install_native_linux
  install_antidote_from_git
fi
