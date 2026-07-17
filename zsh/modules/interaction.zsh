# zsh-history-substring-search is the Fish-compatible history widget. Bind
# after F-Sy-H has loaded to avoid its unknown-widget startup warnings.
# Its default is arbitrary-substring matching; Fish arrows search the current
# command-line prefix, so opt into the plugin's prefix-only mode.
HISTORY_SUBSTRING_SEARCH_PREFIXED=1
if (( $+widgets[history-substring-search-up] )); then
  [[ -n ${terminfo[kcuu1]} ]] && bindkey "${terminfo[kcuu1]}" history-substring-search-up
  [[ -n ${terminfo[kcud1]} ]] && bindkey "${terminfo[kcud1]}" history-substring-search-down
  bindkey '^[[A' history-substring-search-up
  bindkey '^[[B' history-substring-search-down
fi

# Keep F-Sy-H's normal tokenization; punctuation boundaries are scoped to
# the widgets below instead of changing global WORDCHARS.
typeset -g WORDCHARS='*?_-.[]~=/&;!#$%^(){}<>'

# Fish-style Meta-word movement for dotted and hyphenated names.
backward-word-fish() {
  local WORDCHARS="${WORDCHARS//[.-]}"
  zle backward-word
}
forward-word-fish() {
  local WORDCHARS="${WORDCHARS//[.-]}"
  zle forward-word
}
zle -N backward-word-fish
zle -N forward-word-fish
bindkey -M emacs '^[b' backward-word-fish
bindkey -M emacs '^[f' forward-word-fish

# Avoid leaking unbound Ctrl+Left/Right CSI sequences (…1;5D/C) into the
# command line; give them the same word movement as Option+Left/Right.
bindkey -M emacs '^[[1;5D' backward-word-fish
bindkey -M emacs '^[[1;5C' forward-word-fish

# Keep native Tab completion. Ctrl+F accepts the inline history suggestion,
# matching Fish's dark suggestion + accept interaction.
bindkey '^I' expand-or-complete
(( $+widgets[autosuggest-accept] )) && bindkey '^F' autosuggest-accept

# Make Ctrl-W use the same dotted and hyphenated boundaries as Meta-word
# movement while retaining slash-aware deletion for paths.
backward-kill-path-component() {
  local left=$LBUFFER

  # Skip separators so repeated Ctrl-W keeps moving across dotted and
  # hyphenated parts.
  while [[ ${left[-1]} == [[:space:].-] ]]; do
    left=${left[1,-2]}
  done

  if [[ ${left[-1]} == / ]]; then
    # Keep a trailing slash when deleting a component below it.
    left=${left[1,-2]}
    while [[ -n $left && ${left[-1]} != [[:space:]./-] ]]; do
      left=${left[1,-2]}
    done
    if [[ ${left[-1]} == / ]]; then
      left=${left[1,-2]}/
    fi
  else
    while [[ -n $left && ${left[-1]} != [[:space:]./-] ]]; do
      left=${left[1,-2]}
    done
  fi

  LBUFFER=$left
}
zle -N backward-kill-path-component
bindkey '^W' backward-kill-path-component
