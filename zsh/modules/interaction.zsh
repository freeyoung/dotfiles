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
  local address_left=$left ipv4 octet
  local -a octets
  local -i valid_ipv4=1

  # Treat a complete IPv4 address immediately before the cursor as one unit.
  # The boundary check avoids taking an address-looking suffix out of a
  # hostname or a longer dotted number.
  while [[ ${address_left[-1]} == [[:space:]] ]]; do
    address_left=${address_left[1,-2]}
  done
  if [[ $address_left =~ '(^|[^[:alnum:]_.])([0-9]{1,3}(\.[0-9]{1,3}){3})$' ]]; then
    ipv4=$match[2]
    octets=( ${(s:.:)ipv4} )
    for octet in $octets; do
      if (( 10#$octet > 255 )); then
        valid_ipv4=0
        break
      fi
    done
    if (( valid_ipv4 )); then
      LBUFFER=${address_left%$ipv4}
      return
    fi
  fi

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
