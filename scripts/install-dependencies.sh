#!/usr/bin/env bash

# Install shared command-line dependencies. Homebrew provides them on macOS and
# on Linux hosts that already use Linuxbrew; a native Linux package manager is
# used otherwise, since distributions ship the same GNU userland directly.
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

# Resolve both macOS Homebrew and Linuxbrew without assuming their prefix.
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
  # macOS gets the official installer; Linuxbrew is installed separately.
  printf 'Homebrew is required on macOS; installing it now.\n'
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

# macOS needs Homebrew's g-prefixed builds because its own userland is BSD.
# Linux distributions provide the same tools unprefixed, so accept either, but
# confirm the unprefixed one really is GNU rather than a BSD or busybox build.
# Match the product string exactly: a target triple such as
# x86_64-pc-linux-gnu would make a bare "gnu" search succeed for anything.
gnu_product_string() {
  case "$1" in
    ls)   printf '%s\n' '(GNU coreutils)' ;;
    grep) printf '%s\n' '(GNU grep)' ;;
    sed)  printf '%s\n' '(GNU sed)' ;;
    awk)  printf '%s\n' 'GNU Awk' ;;
  esac
}

ensure_gnu_tools() {
  local tool
  local -a missing=()

  # Every invocation goes through `command` so a function or alias of the same
  # name -- this configuration defines ls() itself -- cannot answer for the
  # binary that the rest of the shell will actually run.
  for tool in ls grep sed awk; do
    if command -v "g$tool" >/dev/null 2>&1; then
      continue
    fi
    if command -v "$tool" >/dev/null 2>&1 &&
       command "$tool" --version 2>/dev/null |
         command head -n 1 |
         command grep -Fq "$(gnu_product_string "$tool")"; then
      continue
    fi
    missing+=("$tool")
  done

  if (( ${#missing[@]} )); then
    printf 'Required GNU tools are missing or are not GNU builds: %s\n' \
      "${missing[*]}" >&2
    printf 'Install the coreutils, grep, sed, and gawk packages for this host.\n' >&2
    return 1
  fi
}

# Arch ships everything in the Brewfile except antidote, which lives in the AUR
# and is consumed from a plain checkout instead so no AUR helper becomes a
# bootstrap dependency. zsh is listed explicitly: macOS provides it as the login
# shell, Arch does not install it by default. Node is deliberately absent --
# mise installs the versions projects pin.
install_with_pacman() {
  local -a packages=(
    zsh
    fzf starship zoxide
    coreutils gawk grep sed
    mise go uv
    neovim vim
    bat git ripgrep kubectl ouch tmux
  )
  local -a missing=()
  local package

  # pacman -T reports what is unsatisfied, so a package already supplied under
  # another name counts as present. mise is the case that matters here: the AUR
  # and Omarchy builds are named mise-bin and conflict with the official mise,
  # so testing the literal name would reinstall it into a conflict.
  for package in "${packages[@]}"; do
    if [[ -n "$(pacman -T "$package" 2>/dev/null)" ]]; then
      missing+=("$package")
    fi
  done

  if (( ${#missing[@]} )); then
    printf 'Installing with pacman: %s\n' "${missing[*]}"
    sudo pacman -S --needed --noconfirm "${missing[@]}"
  else
    printf 'All pacman dependencies are already installed.\n'
  fi
}

# zsh/modules/plugins.zsh reads this checkout directly; see its candidate list.
install_antidote_checkout() {
  local antidote_dir="$HOME/.antidote"
  local candidate

  if command -v brew >/dev/null 2>&1 &&
     [[ -r "${HOMEBREW_PREFIX:-}/opt/antidote/share/antidote/antidote.zsh" ]]; then
    return 0
  fi
  for candidate in \
    /usr/share/zsh-antidote/antidote.zsh \
    /usr/share/zsh/plugins/antidote/antidote.zsh; do
    [[ -r "$candidate" ]] && return 0
  done

  if [[ -d "$antidote_dir/.git" ]]; then
    printf 'Kept antidote checkout: %s\n' "$antidote_dir"
    return 0
  fi
  if [[ -e "$antidote_dir" ]]; then
    printf 'Not a git checkout, leaving alone: %s\n' "$antidote_dir" >&2
    return 0
  fi

  command -v git >/dev/null 2>&1 || {
    printf 'git is required to install antidote.\n' >&2
    return 1
  }
  printf 'Cloning antidote into %s\n' "$antidote_dir"
  git clone --depth 1 https://github.com/mattmc3/antidote "$antidote_dir"
}

# Resolve Homebrew before deciding how the host is bootstrapped.
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
  # Install the complete shared dependency set, then enforce GNU userland.
  eval "$("$brew_path" shellenv)"
  "$brew_path" bundle --file "$repo_dir/Brewfile"
  ensure_gnu_tools
elif [[ $(uname -s) == Linux ]] && command -v pacman >/dev/null 2>&1; then
  install_with_pacman
  install_antidote_checkout
  ensure_gnu_tools
elif [[ $(uname -s) == Linux ]]; then
  # Other distributions are not mapped yet; Linuxbrew keeps them working.
  printf 'No supported native package manager found.\n' >&2
  printf 'Install Linuxbrew (or add a mapping for this distribution) and rerun install.\n' >&2
  exit 2
else
  # Keep unsupported Unix hosts explicit instead of silently degrading.
  printf 'Homebrew is required for this dotfiles setup. Install it and rerun install.\n' >&2
  exit 2
fi
