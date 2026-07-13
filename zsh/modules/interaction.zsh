# zsh-history-substring-search is the Fish-compatible history widget. Bind
# after F-Sy-H has loaded to avoid its unknown-widget startup warnings.
# Its default is arbitrary-substring matching; Fish arrows search the current
# command-line prefix, so opt into the plugin's prefix-only mode.
HISTORY_SUBSTRING_SEARCH_PREFIXED=1
[[ -n ${terminfo[kcuu1]} ]] && bindkey "${terminfo[kcuu1]}" history-substring-search-up
[[ -n ${terminfo[kcud1]} ]] && bindkey "${terminfo[kcud1]}" history-substring-search-down
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# Keep native Tab completion. Ctrl+F accepts the inline history suggestion,
# matching Fish's dark suggestion + accept interaction.
bindkey '^I' expand-or-complete
bindkey '^F' autosuggest-accept

# This file is deliberately outside the repository. It is for machine- and
# employer-specific aliases, integrations, and paths; copy the committed
# example on a fresh host before editing it.
[[ -r "$HOME/.config/zsh/local.zsh" ]] && source "$HOME/.config/zsh/local.zsh"
