# General commands.
alias ag='rg'
alias ccat='bat --style=plain --paging=never'

# Ansible.
alias cas='ansible-playbook -i inventory/staging site.yml --diff --limit'
alias cap='ansible-playbook -i inventory/production site.yml --diff --limit'
alias cai='ansible-playbook -i inventory/internal site.yml --diff --limit'

# Kubernetes.
alias k='kubectl'

# Filesystem and clipboard helpers.
ls() {
  local -a ls_options=(--color=auto)
  [[ -t 1 ]] && ls_options+=(-F)
  command ls "${ls_options[@]}" "$@"
}
alias l='ls -lah'
copypath() {
  if (( $+commands[pbcopy] )); then
    print -rn -- "$PWD" | pbcopy
  elif (( $+commands[wl-copy] )); then
    print -rn -- "$PWD" | wl-copy
  elif (( $+commands[xclip] )); then
    print -rn -- "$PWD" | xclip -selection clipboard
  else
    print -u2 'copypath: install pbcopy, wl-clipboard, or xclip first'
    return 127
  fi
}

# SSH and transfers.
alias sk='ssh-keygen -R'
alias sv='ssh -v'
alias svr='ssh -v -l root'
alias cpv='rsync -ah --info=progress2'
alias rsync-copy='rsync -avz --progress'
alias rsync-move='rsync -avz --progress --remove-source-files'

# Deliberately small Git shorthand set. Static forms are zsh-abbr
# abbreviations (defined after plugins load) so history keeps full commands;
# dynamic forms remain functions below.

_zsh_git_current_branch() {
  command git symbolic-ref --quiet --short HEAD || {
    print -u2 'error: not on a named Git branch'
    return 1
  }
}

_zsh_git_main_branch() {
  local ref remote
  for ref in refs/{heads,remotes/{origin,upstream}}/{main,trunk,mainline,default,stable,master}; do
    if command git show-ref --quiet --verify "$ref"; then
      print -r -- "${ref:t}"
      return 0
    fi
  done

  for remote in origin upstream; do
    ref=$(command git symbolic-ref --quiet --short "refs/remotes/$remote/HEAD" 2>/dev/null) || continue
    if [[ $ref == "$remote/"* ]]; then
      print -r -- "${ref#"$remote/"}"
      return 0
    fi
  done

  print -u2 'error: could not determine the Git main branch'
  return 1
}

gcm() {
  local branch
  branch=$(_zsh_git_main_branch) || return
  command git checkout "$branch"
}

ggpush() {
  local branch
  branch=$(_zsh_git_current_branch) || return
  command git push origin "$branch" "$@"
}

ggpull() {
  local branch
  branch=$(_zsh_git_current_branch) || return
  command git pull origin "$branch" "$@"
}

_zsh_100m() {
  local target=${1:?usage: 100m <base-url>}
  local -a wget_args
  [[ "$target" == https://* ]] && wget_args+=(--no-check-certificate)
  wget "${wget_args[@]}" -O /dev/null "${target%/}/100mb.bin"
}
alias 100m='_zsh_100m'

gencsr() {
  local domain=${1:-}
  if [[ -z "$domain" ]]; then
    print -u2 'FQDN required!'
    return 2
  fi
  openssl req -out "${domain}.csr" -new -newkey rsa:2048 -nodes \
    -keyout "${domain}.key" -sha256
}

mkpass() {
  local length=${1:-32}
  LC_ALL=C tr -dc '_A-Za-z0-9' </dev/urandom | head -c "$length"
  print
}

# Search process command lines without matching the search command itself.
any() {
  if (( $# != 1 )); then
    print -u2 'usage: any <process-pattern>'
    return 2
  fi
  command pgrep -afil "$1"
}

# Preserve the familiar archive-extraction command. This intentionally
# overrides /opt/X11/bin/x in interactive zsh sessions.
x() {
  if (( $# == 0 )); then
    print -u2 'usage: x <archive> [...]'
    return 2
  fi
  ouch decompress "$@"
}

_zsh_github_repo() {
  local remote=$1
  remote=${remote#*github.com[:/]}
  remote=${remote%.git}
  [[ "$remote" == */* ]] || return 1
  print -r -- "$remote"
}

open-pr() {
  local target=${1:-master}
  local origin upstream branch repo origin_name upstream_repo upstream_name url

  origin=$(git config --get remote.origin.url) || {
    print -u2 'open-pr: the current repository has no origin remote'
    return 1
  }
  branch=$(git branch --show-current) || return
  [[ -n "$branch" ]] || {
    print -u2 'open-pr: the current repository has no checked-out branch'
    return 1
  }
  repo=$(_zsh_github_repo "$origin") || {
    print -u2 'open-pr: origin is not a GitHub remote'
    return 1
  }

  upstream=$(git config --get remote.upstream.url)
  if [[ -z "$upstream" ]]; then
    url="https://github.com/${repo}/pull/new/${target}...${branch}"
  else
    origin_name=${repo%%/*}
    upstream_repo=$(_zsh_github_repo "$upstream") || {
      print -u2 'open-pr: upstream is not a GitHub remote'
      return 1
    }
    upstream_name=${upstream_repo%%/*}
    url="https://github.com/${repo}/pull/new/${upstream_name}:${target}...${origin_name}:${branch}"
  fi

  if [[ "$(uname -s)" == Darwin ]]; then
    open "$url"
  else
    xdg-open "$url"
  fi
}
