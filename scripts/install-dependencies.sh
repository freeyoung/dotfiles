#!/usr/bin/env bash

# Install shared command-line dependencies. Homebrew provides them on macOS and
# on Linux hosts that already use Linuxbrew; a native Linux package manager is
# used otherwise, since distributions ship the same GNU userland directly. Arch
# (pacman) and Debian and its derivatives (apt) are mapped.
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
    bat eza git ripgrep kubectl ouch tmux
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

# Debian and its derivatives package almost all of the Brewfile set, under
# their own names: GNU sed is `sed` rather than `gnu-sed`, and Go is
# `golang-go`. Which of them a given release carries varies -- starship and
# kubectl are recent arrivals, and Debian and Ubuntu picked them up at
# different times -- so what is missing from the archive is named rather than
# silently dropped, and the rest still installs. curl is listed because the
# plugin restore and the upstream installers below need it and a minimal
# Debian does not have it; zsh for the same reason as on Arch. Node is
# deliberately absent -- mise installs the versions projects pin. So are mise,
# uv and ouch, which no Debian release carries: naming them here would leave
# the list permanently unsatisfied, and every run would then refresh the
# package lists over the network to rediscover that. They are handled below.
install_with_apt() {
  local -a packages=(
    zsh curl
    fzf starship zoxide
    coreutils gawk grep sed
    golang-go
    neovim vim
    bat eza git ripgrep kubectl tmux
  )
  local -a wanted=() available=() unavailable=()
  local package candidate

  # dpkg answers from the local status database, so this needs no package
  # lists and no network for the common case where nothing is missing.
  for package in "${packages[@]}"; do
    if [[ "$(dpkg-query -W -f='${db:Status-Status}' "$package" 2>/dev/null)" != installed ]]; then
      wanted+=("$package")
    fi
  done

  if (( ${#wanted[@]} == 0 )); then
    printf 'All apt dependencies are already installed.\n'
    return 0
  fi

  # apt-cache answers from /var/lib/apt/lists, so stale or empty lists would
  # report a packaged tool as unavailable. Refresh before asking.
  sudo apt-get update

  # awk reads apt-cache to the end rather than exiting on the line it wants:
  # quitting early closes the pipe under the writer, and the SIGPIPE that
  # follows is a 141 that pipefail propagates and set -e acts on.
  for package in "${wanted[@]}"; do
    candidate="$(
      apt-cache policy "$package" 2>/dev/null |
        command awk -F': ' '!found && $1 ~ /Candidate$/ { print $2; found = 1 }'
    )"
    if [[ -n "$candidate" && "$candidate" != '(none)' ]]; then
      available+=("$package")
    else
      unavailable+=("$package")
    fi
  done

  if (( ${#available[@]} )); then
    printf 'Installing with apt: %s\n' "${available[*]}"
    # Recommends are left on: git's are less, ssh-client and patch, which this
    # configuration uses everywhere and which --no-install-recommends drops.
    # The frontend goes through env rather than a `sudo VAR=value` assignment,
    # which sudoers rejects unless the rule grants setenv.
    sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y "${available[@]}"
  fi

  if (( ${#unavailable[@]} )); then
    printf 'Not packaged for this release, skipped: %s\n' "${unavailable[*]}" >&2
  fi
}

# Debian packages neither mise nor uv, and both are load-bearing here: a
# runtime version comes from mise on every host (see zsh/modules/runtimes.zsh,
# and mise/config.toml, which the installer links for it), and mise builds
# project virtualenvs through uv. Each publishes an installer that writes one
# binary into ~/.local/bin, which ~/.zshrc already puts on PATH -- so neither
# needs root, and neither leaves an apt source on the host to maintain. A tool
# a package manager has already provided is left alone.
install_upstream_binaries() {
  local tool installer

  # A plain case rather than an associative array: this script is also read by
  # the bash macOS ships, which is 3.2 and has none.
  for tool in mise uv; do
    if command -v "$tool" >/dev/null 2>&1; then
      continue
    fi
    case "$tool" in
      mise) installer='https://mise.run' ;;
      uv)   installer='https://astral.sh/uv/install.sh' ;;
    esac
    command -v curl >/dev/null 2>&1 || {
      printf 'curl is required to install %s.\n' "$tool" >&2
      return 1
    }
    printf 'Installing %s from %s\n' "$tool" "$installer"
    curl -fsSL "$installer" | sh
  done

  # ouch has no Debian package and no first-party installer worth adding. Only
  # the x() helper uses it, and that falls back to tar and unzip, so say so
  # once instead of failing the bootstrap.
  if ! command -v ouch >/dev/null 2>&1; then
    printf 'ouch is unavailable; x() will extract with tar and unzip instead.\n'
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
elif [[ $(uname -s) == Linux ]] && command -v apt-get >/dev/null 2>&1; then
  install_with_apt
  install_upstream_binaries
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
