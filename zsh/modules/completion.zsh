# History and completion.
HISTFILE="${ZDOTDIR:-$HOME}/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000
setopt append_history inc_append_history share_history
setopt hist_expire_dups_first hist_ignore_all_dups hist_ignore_space
setopt hist_reduce_blanks hist_save_no_dups

# Use fish-compatible Emacs-style bindings. The history-search plugin binds
# the arrow widgets after it is loaded below.
bindkey -e

autoload -Uz compinit
typeset -g ZSH_COMPDUMP="${ZDOTDIR:-$HOME}/.zcompdump"

# A full compaudit is useful, but scanning every completion directory at every
# prompt startup is not. Audit on first use and then once every 24 hours;
# ordinary shells load the trusted dump directly. `brewup` below explicitly
# rebuilds this cache after packages add or update completion definitions.
_zsh_init_completions() {
  setopt localoptions extendedglob

  if [[ ! -r $ZSH_COMPDUMP || -n ${ZSH_COMPDUMP}(#qN.mh+24) ]]; then
    compinit -d "$ZSH_COMPDUMP"
  else
    compinit -C -d "$ZSH_COMPDUMP"
  fi
}

_zsh_refresh_completions() {
  rm -f -- "$ZSH_COMPDUMP"
  compinit -d "$ZSH_COMPDUMP"
  print 'Completion cache refreshed.'
}

# Fully update Homebrew and immediately rebuild Zsh completion metadata.
brewup() {
  command brew update && \
    command brew upgrade -y && \
    command brew cleanup --prune=all -s || return
  _zsh_refresh_completions
}

# After ordinary completion has no result, offer Fish-like fuzzy completion
# for a filename in the current directory or the final segment of an existing
# path. Thus `vim conf` finds `tmux.conf`, while `vim scripts/vim` finds
# `scripts/check-vim-config.sh`. Matching is case-insensitive and
# subsequence-based, so `scripts/vcg` finds the same target. `compadd -U` is
# deliberate: this function does the matching itself.
_zsh_fuzzy_path_complete() {
  setopt localoptions extendedglob

  local typed=$PREFIX directory needle fuzzy character
  local -a matches

  if [[ $typed == */* ]]; then
    directory=${typed:h}
    needle=${typed:t}
  else
    directory=.
    needle=$typed
  fi
  [[ -n $needle && -d $directory ]] || return 1

  fuzzy='(#i)*'
  for character in ${(s::)needle}; do
    fuzzy+="${(b)character}*"
  done
  if [[ $directory == . ]]; then
    matches=( ${~fuzzy}(N) )
  else
    matches=( "$directory"/${~fuzzy}(N) )
  fi
  (( $#matches )) || return 1

  compadd -U -Q -a matches
}

# Use Zsh's native completion UI rather than a separate picker. complist
# renders option descriptions, colours match groups, and makes long lists
# navigable with the arrow keys. Run the fuzzy filename fallback only after
# normal completion (and its ignored-file retry) has no match.
zmodload zsh/complist
zstyle ':completion:*' menu select
zstyle ':completion:*' completer _complete _ignored _zsh_fuzzy_path_complete
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' list-packed true
zstyle ':completion:*' list-rows-first true
zstyle ':completion:*' list-separator '  '
zstyle ':completion:*' select-prompt '%F{242}[%p] %m/%M%f'
zstyle ':completion:*' list-prompt '%F{242}… %m more matches%f'
zstyle ':completion:*:descriptions' format '%F{220}-- %d --%f'
zstyle ':completion:*:messages' format '%F{220}-- %d --%f'
zstyle ':completion:*:warnings' format '%F{red}-- no matches found --%f'
zstyle ':completion:*:corrections' format '%F{220}-- correct %d --%f'
# Keep options cool-toned and their explanatory text warm, like the familiar
# fish list while retaining native Zsh completion semantics.
zstyle ':completion:*:options' list-colors \
  '=(#b)(--|-)([[:alnum:]-]##)([[:space:]]##)(*)=0=39=39=0=220'
_zsh_init_completions

# Keep the familiar z command while letting zoxide learn directory frecency.
# It follows compinit so zoxide's zsh completion is registered correctly.
if (( $+commands[zoxide] )); then
  eval "$(zoxide init zsh --cmd z)"
fi
