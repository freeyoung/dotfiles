#!/usr/bin/env bash

# Install shared command-line dependencies. Homebrew/Linuxbrew is required for
# the reproducible GNU userland used by this configuration.
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

ensure_gnu_tools() {
  local tool
  local -a missing=()

  # The prefixed names are always provided by the Homebrew formulas; the
  # corresponding unprefixed names are exposed through zsh's gnubin paths.
  for tool in gls ggrep gsed gawk; do
    command -v "$tool" >/dev/null 2>&1 || missing+=("$tool")
  done

  if (( ${#missing[@]} )); then
    printf 'Required GNU tools are missing: %s\n' "${missing[*]}" >&2
    printf 'Run brew bundle again, or install the coreutils, grep, gnu-sed, and gawk formulas.\n' >&2
    return 1
  fi
}

# Resolve Homebrew before deciding whether the host can be bootstrapped.
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
elif [[ $(uname -s) == Linux ]]; then
  # A partial native-Linux install would violate the command semantics above.
  printf 'Linuxbrew is required for this dotfiles setup. Install Linuxbrew and rerun install.\n' >&2
  exit 2
else
  # Keep unsupported Unix hosts explicit instead of silently degrading.
  printf 'Homebrew is required for this dotfiles setup. Install it and rerun install.\n' >&2
  exit 2
fi
