# Keep pyenv's startup minimal: shims select each project's configured Python
# version without running pyenv's costly general-purpose initialiser.
export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"
if [[ -d "$PYENV_ROOT" ]]; then
  path=("$PYENV_ROOT/shims" "$PYENV_ROOT/bin" $path)
fi

# Activate/deactivate pyenv virtualenvs named by a project's .python-version.
# Initialisation itself is deferred until such a project is entered; starting
# pyenv just to emit its hook costs about 80 ms in ordinary shells.
if (( $+commands[pyenv] )) && { [[ -d "$PYENV_ROOT/plugins/pyenv-virtualenv" ]] || [[ -n ${HOMEBREW_PREFIX:-} && -d "$HOMEBREW_PREFIX/opt/pyenv-virtualenv" ]]; }; then
  export PYENV_SHELL=zsh
  typeset -g _zsh_pyenv_virtualenv_initialized=0

  _zsh_pyenv_virtualenv_version_file() {
    local directory=$PWD
    while [[ $directory != / ]]; do
      if [[ -f "$directory/.python-version" || -L "$directory/.python-version" ]]; then
        REPLY="$directory/.python-version"
        return 0
      fi
      directory=${directory:h}
    done
    return 1
  }

  _zsh_pyenv_virtualenv_init() {
    (( _zsh_pyenv_virtualenv_initialized )) && return
    eval "$(pyenv virtualenv-init - zsh)"
    typeset -g _zsh_pyenv_virtualenv_initialized=1
  }

  _zsh_pyenv_virtualenv_use() {
    if _zsh_pyenv_virtualenv_version_file; then
      _zsh_pyenv_virtualenv_init
      _pyenv_virtualenv_hook
    elif (( _zsh_pyenv_virtualenv_initialized )); then
      _pyenv_virtualenv_hook
    fi
  }

  add-zsh-hook chpwd _zsh_pyenv_virtualenv_use
  _zsh_pyenv_virtualenv_use
fi
