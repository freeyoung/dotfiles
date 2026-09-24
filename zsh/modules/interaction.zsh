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

# Option+Left/Right as a terminal sends it when it does not rewrite it to
# esc b / esc f (Ghostty on the Mac is set not to, so herdr can see the arrow).
bindkey -M emacs '^[[1;3D' backward-word-fish
bindkey -M emacs '^[[1;3C' forward-word-fish

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

# Ctrl-X Ctrl-E opens the current command line in $VISUAL/$EDITOR. zsh ships
# the widget but binds nothing, unlike bash's readline default. The completion
# system already claims Ctrl-X e, so take only the double-Ctrl form.
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -M emacs '^X^E' edit-command-line

# In kitty, Ctrl-L keeps the cleared lines in scrollback, as iTerm2 does. zsh's
# clear-screen erases the display, and kitty drops what it erases instead of
# saving it, so ask kitty to scroll the prompt to the top. That needs kitty's
# shell integration (prompt marks) and its remote control socket. Programs such
# as Claude Code still receive Ctrl-L as before, because only this zle binding
# changes. Other terminals keep the stock widget.
if [[ -n $KITTY_WINDOW_ID && -n $KITTY_LISTEN_ON ]] && (( $+commands[kitten] )); then
  clear-screen-keep-scrollback() {
    kitten @ --to "$KITTY_LISTEN_ON" action --match "id:$KITTY_WINDOW_ID" scroll_prompt_to_top \
      >/dev/null 2>&1 || zle clear-screen
  }
  zle -N clear-screen-keep-scrollback
  bindkey -M emacs '^L' clear-screen-keep-scrollback
fi
