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

# Keep native Tab completion. Ctrl+F accepts the inline history suggestion,
# matching Fish's dark suggestion + accept interaction.
bindkey '^I' expand-or-complete
(( $+widgets[autosuggest-accept] )) && bindkey '^F' autosuggest-accept

# Make Ctrl-W remove one path component, like Fish:
# "vim vim/config/filetypes.vim" becomes "vim vim/config".
backward-kill-path-component() {
  local left=$LBUFFER

  # Ignore trailing whitespace while looking for the previous component.
  if [[ ${left[-1]} == [[:space:]] ]]; then
    while [[ ${left[-1]} == [[:space:]] ]]; do
      left=${left[1,-2]}
    done
  fi

  if [[ ${left[-1]} == / ]]; then
    # Keep a trailing slash when deleting a component below it.
    left=${left[1,-2]}
    while [[ -n $left && ${left[-1]} != [[:space:]/] ]]; do
      left=${left[1,-2]}
    done
    if [[ ${left[-1]} == / ]]; then
      left=${left[1,-2]}/
    fi
  else
    while [[ -n $left && ${left[-1]} != [[:space:]/] ]]; do
      left=${left[1,-2]}
    done
  fi

  LBUFFER=$left
}
zle -N backward-kill-path-component
bindkey '^W' backward-kill-path-component
