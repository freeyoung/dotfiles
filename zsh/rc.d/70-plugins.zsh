# Fish-like suggestions should fall back to the completion engine when history
# has no match (for example, gco site -> gco site.yml).
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
# Keep ghost completions muted. Use a fixed 256-colour neutral grey (rather
# than the terminal's mutable ANSI magenta) for history-search matches selected
# with the up/down arrows.
HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND='bg=240,fg=white,bold'

# Antidote compiles the manifest into a static source file on manifest changes,
# avoiding plugin-manager work in ordinary shell startups.
zsh_plugins=${ZDOTDIR:-$HOME}/.zsh_plugins
zsh_antidote=''
if [[ -n ${HOMEBREW_PREFIX:-} && -r "$HOMEBREW_PREFIX/opt/antidote/share/antidote/antidote.zsh" ]]; then
  zsh_antidote="$HOMEBREW_PREFIX/opt/antidote/share/antidote/antidote.zsh"
elif [[ -r "$HOME/.antidote/antidote.zsh" ]]; then
  zsh_antidote="$HOME/.antidote/antidote.zsh"
fi
if [[ ! -r ${zsh_plugins}.zsh || ${zsh_plugins}.txt -nt ${zsh_plugins}.zsh ]]; then
  if [[ -r "$zsh_antidote" && -r ${zsh_plugins}.txt ]]; then
    source "$zsh_antidote"
    antidote bundle <"${zsh_plugins}.txt" >"${zsh_plugins}.zsh.new" && mv "${zsh_plugins}.zsh.new" "${zsh_plugins}.zsh"
  fi
fi
if [[ -r ${zsh_plugins}.zsh ]]; then
  source "${zsh_plugins}.zsh"
else
  # Keep the shell usable if a first-time manifest build is offline. These
  # are the cached Antidote copies, not the obsolete Homebrew plugin formulae.
  if [[ $OSTYPE == darwin* ]]; then
    zsh_plugin_cache="${XDG_CACHE_HOME:-$HOME/Library/Caches}/antidote/github.com"
  else
    zsh_plugin_cache="${XDG_CACHE_HOME:-$HOME/.cache}/antidote/github.com"
  fi
  [[ -r "$zsh_plugin_cache/zsh-users/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh" ]] && \
    source "$zsh_plugin_cache/zsh-users/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh"
  [[ -r "$zsh_plugin_cache/zsh-users/zsh-history-substring-search/zsh-history-substring-search.plugin.zsh" ]] && \
    source "$zsh_plugin_cache/zsh-users/zsh-history-substring-search/zsh-history-substring-search.plugin.zsh"
  if [[ -r "$zsh_plugin_cache/romkatv/zsh-defer/zsh-defer.plugin.zsh" ]]; then
    source "$zsh_plugin_cache/romkatv/zsh-defer/zsh-defer.plugin.zsh"
    [[ -r "$zsh_plugin_cache/olets/zsh-abbr/zsh-abbr.plugin.zsh" ]] && \
      zsh-defer source "$zsh_plugin_cache/olets/zsh-abbr/zsh-abbr.plugin.zsh"
  fi
  [[ -r "$zsh_plugin_cache/zdharma-continuum/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh" ]] && \
    source "$zsh_plugin_cache/zdharma-continuum/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"
  unset zsh_plugin_cache
fi
unset zsh_antidote

# F-Sy-H already distinguishes real paths from invalid text. Make every
# existing filesystem object link-like and match the option cyan.
if (( $+FAST_HIGHLIGHT_STYLES )); then
  FAST_HIGHLIGHT_STYLES[path]='fg=cyan,underline'
  FAST_HIGHLIGHT_STYLES[path-to-dir]='fg=cyan,underline'
fi
