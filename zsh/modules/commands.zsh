# General commands.
alias ag='rg'
alias ccat='bat --style=plain --paging=never'

# Ansible.
unalias cas cap cai 2>/dev/null
cas() {
  ansible-playbook -i inventory/staging site.yml --diff --limit "$@"
}
cap() {
  ansible-playbook -i inventory/production site.yml --diff --limit "$@"
}
cai() {
  ansible-playbook -i inventory/internal site.yml --diff --limit "$@"
}

# Kubernetes.
alias k='kubectl'

# Filesystem and clipboard helpers.
ls() {
  local -a ls_options=(--color=auto)
  [[ -t 1 ]] && ls_options+=(-F)
  command ls "${ls_options[@]}" "$@"
}
alias l='ls -lah'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
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

# Wrap ssh to clean up the terminal and reconnect when a connection drops.
#
# A remote tmux, pager, or editor arms terminal modes over the SSH pipe (mouse
# tracking, focus reporting, the alternate screen) that only it can disarm. If
# the connection dies instead of exiting cleanly, those modes stay armed on the
# local terminal, and every mouse move floods the prompt with escape junk.
ssh() {
  local rc started

  started=$SECONDS
  command ssh "$@"
  rc=$?

  [[ -t 1 ]] || return $rc
  _zsh_ssh_disarm

  # Reconnect only when an interactive session drops. ssh exits 255 for
  # transport failures, but a fast 255 with no established session is a
  # connect or auth failure; a remote command's own 255 is indistinguishable
  # and must not have its side effects replayed; and redirected stdin would
  # feed the rest of the piped input to a fresh remote shell.
  if (( rc != 255 )) || [[ ! -t 0 ]] || ! _zsh_ssh_interactive "$@" ||
    (( SECONDS - started < 30 )); then
    return $rc
  fi

  # Retry in a subshell: Ctrl-C reaches the whole foreground process group, so
  # it cancels both the in-flight attempt and the loop. Keep retrying fast
  # failures, since a rebooting server refuses connections too.
  (
    while true; do
      print 'Connection lost. Reconnecting (Ctrl-C to stop)...'
      sleep 2
      command ssh "$@"
      rc=$?
      _zsh_ssh_disarm
      (( rc != 255 )) && exit $rc
    done
  )
}

# Disarm mouse tracking (1000/1002/1003 with 1006 encoding), focus reporting
# (1004), and the alternate screen (1049), and show the cursor again.
_zsh_ssh_disarm() {
  printf '\e[?1000l\e[?1002l\e[?1003l\e[?1006l\e[?1004l\e[?1049l\e[?25h'
}

# True for an interactive session: a destination and no remote command. The
# letters are the ssh(1) options that take a value, so their arguments are not
# mistaken for the destination.
_zsh_ssh_interactive() {
  local value_opts='BbcDEeFIiJLlmOoPpQRSWw'
  local -a ssh_args=("$@")
  local arg letters dest='' opts_done='' resolved
  local -i i

  while (( $# )); do
    arg="$1"
    shift

    if [[ -z $opts_done && $arg == '--' ]]; then
      opts_done=1
    elif [[ -z $opts_done && $arg == -?* ]]; then
      letters="${arg#-}"
      for (( i = 0; i < ${#letters}; i++ )); do
        if [[ $value_opts == *"${letters:$i:1}"* ]]; then
          # The value is glued to the letter (-p2222) unless the letter ends
          # the argument, in which case it consumes the next one (-p 2222).
          (( i == ${#letters} - 1 )) && shift
          break
        fi
      done
    elif [[ -z $dest ]]; then
      dest="$arg"
    else
      return 1
    fi
  done

  [[ -n $dest ]] || return 1

  # A RemoteCommand from ssh_config or -o replays on reconnect just like a
  # positional command. ssh -G resolves the effective configuration for this
  # exact invocation without connecting. Fail closed when it cannot resolve,
  # since an undetected RemoteCommand must not replay. An explicit "none"
  # cancels a configured command, and some versions emit it when unset.
  resolved=$(command ssh -G "${ssh_args[@]}" 2>/dev/null) || return 1
  ! print -r -- "$resolved" | command grep -i '^remotecommand ' |
    command grep -qvi '^remotecommand none$'
}

# Ad-hoc SSH port forwarding: forward, drop, list.
fip() {
  (( $# < 2 )) && { print -u2 'Usage: fip <host> <port>...'; return 1; }
  local host="$1" port
  shift
  for port in "$@"; do
    command ssh -f -N -L "${port}:localhost:${port}" "$host" &&
      print "Forwarding localhost:$port -> $host:$port"
  done
}

dip() {
  (( $# == 0 )) && { print -u2 'Usage: dip <port>...'; return 1; }
  local port
  for port in "$@"; do
    if pkill -f "ssh.*-L ${port}:localhost:${port}"; then
      print "Stopped forwarding port $port"
    else
      print "No forwarding on port $port"
    fi
  done
}

lip() {
  # ps is used rather than pgrep -a, which is a GNU extension BSD ps hosts
  # (macOS) do not provide.
  local found
  found=$(command ps -eo pid=,args= |
    command grep -E 'ssh .*-L [0-9]+:localhost:[0-9]+' |
    command grep -v grep)
  if [[ -n $found ]]; then
    print -r -- "$found"
  else
    print 'No active forwards'
  fi
}

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

# Worktrees as sibling directories named <repo>--<branch>, which is what lets
# gwr recover the branch from the directory it is standing in. Named gwa/gwr
# rather than the ga/gd this idea was borrowed from: gd is already the
# abbreviation for git diff, and ga reads as git add everywhere else.
gwa() {
  local branch="$1" wt_path
  if [[ -z $branch ]]; then
    print -u2 'Usage: gwa <branch>'
    return 1
  fi
  # A slash would put the worktree somewhere other than beside the repository.
  if [[ $branch == */* ]]; then
    print -u2 "gwa: branch names containing '/' have no sibling-directory form"
    return 1
  fi
  command git rev-parse --git-dir >/dev/null 2>&1 || return 1

  wt_path="../${PWD:t}--${branch}"
  command git worktree add -b "$branch" "$wt_path" || return
  # New checkout, so mise has not been told the config there is trustworthy.
  (( $+commands[mise] )) && mise trust "$wt_path" >/dev/null 2>&1
  cd "$wt_path"
}

gwr() {
  local cwd worktree root branch
  cwd=$PWD
  worktree=${cwd:t}
  root=${worktree%%--*}
  branch=${worktree#*--}

  # Refuse anywhere that is not a gwa-created worktree, so this cannot delete
  # an ordinary checkout that happens to be the current directory.
  if [[ $root == $worktree ]]; then
    print -u2 "gwr: $worktree is not a <repo>--<branch> worktree"
    return 1
  fi
  command git rev-parse --git-dir >/dev/null 2>&1 || return 1

  print -n "Remove worktree $worktree and branch $branch? [y/N] "
  if ! read -q; then
    print
    return 1
  fi
  print

  cd "../$root" || return 1
  command git worktree remove "$cwd" --force || return 1
  command git branch -D "$branch"
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
