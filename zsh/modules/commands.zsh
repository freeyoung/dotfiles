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
# eza renders the listing, but the flags stay GNU ls's, because the same hands
# type ls on servers that will never have eza and a half-learned habit is worse
# than none. Where the two disagree the GNU meaning wins:
#
#   -t  ls sorts by time, eza picks which timestamp to display
#   -S  ls sorts by size, eza accepts it but sorts the other way round
#   -F  ls appends type indicators, eza wants a WHEN value after it
#   -a  ls lists . and .. too; eza's -a is ls's -A, and its -aa is ls's -a
#
# One difference is left standing: eza collates byte-wise, so a dotfile sorts
# ahead of everything, where GNU ls under a UTF-8 locale ignores the leading
# dot and files it under its letter. eza exposes no collation setting, and no
# habit rides on where .gitignore lands in the alphabet.
#
# The directions matter more than the names. eza sorts ascending; ls puts the
# newest and the largest first, and its -r reverses whatever sort is in
# effect. So the reverse flag is the XOR of "this sort is descending in ls" and
# "the user asked for -r", not a straight translation of -r.
if (( $+commands[eza] )); then
  ls() {
    local -a eza_args paths
    local sort_field='' classify=auto arg letters
    local -i gnu_reverse=0 sort_desc=0 opts_done=0 i

    for arg in "$@"; do
      if (( opts_done )); then
        paths+=("$arg")
        continue
      fi
      case $arg in
        --) opts_done=1 ;;
        --*) eza_args+=("$arg") ;;
        -?*)
          letters=${arg#-}
          for (( i = 1; i <= ${#letters}; i++ )); do
            case ${letters[i]} in
              t) sort_field=modified; sort_desc=1 ;;
              S) sort_field=size; sort_desc=1 ;;
              X) sort_field=extension ;;
              U) sort_field=none ;;
              r) gnu_reverse=1 ;;
              F) classify=always ;;
              a) eza_args+=(-a -a) ;;
              A) eza_args+=(-a) ;;
              *) eza_args+=("-${letters[i]}") ;;
            esac
          done
          ;;
        *) paths+=("$arg") ;;
      esac
    done

    [[ -n $sort_field ]] && eza_args+=("--sort=$sort_field")
    (( sort_desc ^ gnu_reverse )) && eza_args+=(--reverse)
    command eza --color=auto "--classify=$classify" "${eza_args[@]}" "${paths[@]}"
  }
else
  ls() {
    local -a ls_options=(--color=auto)
    [[ -t 1 ]] && ls_options+=(-F)
    command ls "${ls_options[@]}" "$@"
  }
fi
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

# --- Adapted from Omarchy -------------------------------------------------
# Omarchy's Bash configuration is Linux- and Hyprland-specific in places, so
# each of these carries the guard that makes it safe to define on macOS too.

# Linux only: macOS has its own open(1), a full utility with -a, -R, -n and
# more, which this one-line xdg-open wrapper would shadow. The body is a
# subshell so the background job never reaches the interactive job table.
if [[ $OSTYPE == linux* ]] && (( $+commands[xdg-open] )); then
  open() ( xdg-open "$@" >/dev/null 2>&1 & )
fi

# eza, without taking over ls. Omarchy aliases ls itself, which turns a bare
# ls into a long listing and drops the GNU flags; keep ls() as it is and reach
# for eza deliberately.
if (( $+commands[eza] )); then
  alias e='eza -lh --group-directories-first --icons=auto --git'
  alias ea='e -a'
  alias et='eza --tree --level=2 --long --icons --git'
  alias eta='et -a'
fi

# Pick a file with fzf, previewing it on the way. Kitty can draw images
# inline; every other terminal falls back to bat for everything.
if (( $+commands[fzf] && $+commands[bat] )); then
  ff() {
    local preview='bat --style=numbers --color=always {}'
    if [[ $TERM == xterm-kitty ]] && (( $+commands[kitty] )); then
      preview='case $(file --mime-type -b {}) in
        image/*) kitty icat --clear --transfer-mode=memory --stdin=no --place=${FZF_PREVIEW_COLUMNS}x${FZF_PREVIEW_LINES}@0x0 {} ;;
        *) bat --style=numbers --color=always {} ;;
      esac'
    fi
    fzf --preview "$preview" "$@"
  }

  # Open the picked file in the editor.
  eff() {
    local file
    file=$(ff) || return
    [[ -n $file ]] && "${EDITOR:-vim}" "$file"
  }

  # Copy a file to a remote destination, newest first in the picker. The
  # ordering comes from a zsh glob qualifier rather than find -printf, which
  # is a GNU extension the BSD find on macOS does not have.
  sff() {
    if (( $# == 0 )); then
      print -u2 'Usage: sff <destination>   (e.g. sff host:/tmp/)'
      return 1
    fi
    local file
    file=$(print -rl -- **/*(.om) 2>/dev/null | ff) || return
    [[ -n $file ]] && scp "$file" "$1"
  }
fi

# ouch handles far more formats, but these keep working where it is absent.
compress() { tar -czf "${1%/}.tar.gz" "${1%/}"; }
alias decompress='tar -xzf'

# A bare n edits the current directory.
if (( $+commands[nvim] )); then
  n() { (( $# )) && command nvim "$@" || command nvim .; }
fi

if (( $+commands[mise] )); then
  # mise holds new releases back for a cooling-off period by default; this
  # asks for them anyway.
  alias mup='MISE_MINIMUM_RELEASE_AGE=0 mise up'
fi

(( $+commands[docker] )) && alias d='docker'

# tmux. Omarchy pairs each of these with a herdr twin and hard-codes the
# programs each pane runs; here the command is always an argument, so the
# layout is the reusable part.
if (( $+commands[tmux] )); then
  alias t='tmux attach || tmux new -s Work'

  # Dev layout: editor filling the left, a command on the right, a shell along
  # the bottom. A second command splits the right-hand pane.
  #   tdl 'claude --permission-mode auto' [second-command]
  tdl() {
    if (( $# == 0 )); then
      print -u2 'Usage: tdl <command> [second-command]'
      return 1
    fi
    [[ -n $TMUX ]] || { print -u2 'tdl: start tmux first'; return 1; }

    local dir=$PWD editor_pane=$TMUX_PANE side_pane second_pane

    tmux rename-window -t "$editor_pane" "${dir:t}"
    tmux split-window -v -p 15 -t "$editor_pane" -c "$dir"
    side_pane=$(tmux split-window -h -p 30 -t "$editor_pane" -c "$dir" -P -F '#{pane_id}')

    if [[ -n $2 ]]; then
      second_pane=$(tmux split-window -v -t "$side_pane" -c "$dir" -P -F '#{pane_id}')
      tmux send-keys -t "$second_pane" "$2" C-m
    fi

    tmux send-keys -t "$side_pane" "$1" C-m
    tmux send-keys -t "$editor_pane" "${EDITOR:-vim} ." C-m
    # Omarchy selects $opencode_pane here, which that function never assigns --
    # a leftover from the square layout, so focus lands nowhere in particular.
    tmux select-pane -t "$editor_pane"
  }

  # Swarm: the same command in a tiled grid of panes.
  #   tsl 4 'claude --permission-mode auto'
  tsl() {
    if (( $# < 2 )); then
      print -u2 'Usage: tsl <pane-count> <command>'
      return 1
    fi
    [[ -n $TMUX ]] || { print -u2 'tsl: start tmux first'; return 1; }

    local -i count=$1
    local cmd=$2 dir=$PWD pane
    local -a panes=("$TMUX_PANE")

    tmux rename-window -t "$TMUX_PANE" "${dir:t}"
    while (( ${#panes} < count )); do
      panes+=("$(tmux split-window -h -t "${panes[-1]}" -c "$dir" -P -F '#{pane_id}')")
      tmux select-layout -t "${panes[1]}" tiled
    done

    for pane in "${panes[@]}"; do
      tmux send-keys -t "$pane" "$cmd" C-m
    done
    tmux select-pane -t "${panes[1]}"
  }
fi

# Linux only: writing an image to a block device has no macOS equivalent, and
# the tools below are GNU/util-linux. Omarchy picks the drive with its own
# omarchy-drive-select; fall back to fzf so this needs nothing from it.
if [[ $OSTYPE == linux* ]]; then
  iso2sd() {
    if (( $# < 1 )); then
      print -u2 'Usage: iso2sd <image> [device]'
      return 1
    fi
    local image=$1 drive=$2

    if [[ -z $drive ]]; then
      (( $+commands[fzf] )) || {
        print -u2 'iso2sd: name the device, or install fzf to pick one'
        return 1
      }
      drive=$(lsblk -dpno NAME,SIZE,MODEL |
        command grep -E '^/dev/(sd|mmcblk)' |
        fzf --prompt='target device> ' --height=40%) || return
      drive=${drive%% *}
    fi

    [[ -b $drive ]] || { print -u2 "iso2sd: not a block device: $drive"; return 1; }
    print "About to overwrite $drive with $image."
    print -n 'This destroys everything on it. Continue? [y/N] '
    read -q || { print; return 1; }
    print

    sudo dd bs=4M status=progress oflag=sync if="$image" of="$drive" && sudo eject "$drive"
  }
fi
