# Use fnm only for projects that explicitly opt in with .node-version or
# .nvmrc. Outside such a project, Homebrew's Node and its global tools remain
# authoritative. Initialising fnm itself is deferred until such a project is
# entered, so ordinary shells do not pay for its environment setup.
if (( $+commands[fnm] )); then
  typeset -g _zsh_fnm_initialized=0
  typeset -g _zsh_fnm_multishell_bin=''

  # A nested Zsh can inherit fnm's path from a parent shell. Remove it until
  # this shell enters a version-managed project.
  if [[ -n ${FNM_MULTISHELL_PATH:-} ]]; then
    path=("${(@)path:#${FNM_MULTISHELL_PATH}/bin}")
  fi

  _zsh_fnm_init() {
    (( _zsh_fnm_initialized )) && return
    eval "$(fnm env --shell zsh --resolve-engines=false)"
    typeset -g _zsh_fnm_multishell_bin="${FNM_MULTISHELL_PATH}/bin"
    path=("${(@)path:#${_zsh_fnm_multishell_bin}}")
    typeset -g _zsh_fnm_initialized=1
  }

  _zsh_fnm_node_version_file() {
    local directory=$PWD
    while [[ $directory != / ]]; do
      if [[ -f "$directory/.node-version" ]]; then
        REPLY="$directory/.node-version"
        return 0
      fi
      if [[ -f "$directory/.nvmrc" ]]; then
        REPLY="$directory/.nvmrc"
        return 0
      fi
      directory=${directory:h}
    done
    return 1
  }

  _zsh_fnm_use_node_version_file() {
    local version_file version
    if _zsh_fnm_node_version_file; then
      version_file=$REPLY
      version=$(<"$version_file")
      version=${version%%$'\n'*}
      _zsh_fnm_init
      path=("$_zsh_fnm_multishell_bin" "${(@)path:#${_zsh_fnm_multishell_bin}}")
      fnm use --silent-if-unchanged "$version" || print -u2 "fnm: could not use $version from $version_file"
    elif [[ -n $_zsh_fnm_multishell_bin ]]; then
      path=("${(@)path:#${_zsh_fnm_multishell_bin}}")
    fi
  }

  add-zsh-hook chpwd _zsh_fnm_use_node_version_file
  _zsh_fnm_use_node_version_file
fi

# Keep the kubectl completion when using its short alias.
(( $+_comps[kubectl] )) && compdef k=kubectl

# fzf uses the same menu height as the previous fish configuration.
export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS:---height 40%}"
if [[ -n ${HOMEBREW_PREFIX:-} && -r "$HOMEBREW_PREFIX/opt/fzf/shell/key-bindings.zsh" ]]; then
  source "$HOMEBREW_PREFIX/opt/fzf/shell/key-bindings.zsh"
  source "$HOMEBREW_PREFIX/opt/fzf/shell/completion.zsh"
elif [[ -r /usr/share/doc/fzf/examples/key-bindings.zsh ]]; then
  source /usr/share/doc/fzf/examples/key-bindings.zsh
  [[ -r /usr/share/doc/fzf/examples/completion.zsh ]] && source /usr/share/doc/fzf/examples/completion.zsh
fi
