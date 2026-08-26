# Language runtimes are managed by mise: one activation covers Python, Node, Go
# and anything else a project pins, so no per-runtime version manager needs its
# own shell hook. mise resolves versions on directory change through a single
# precmd hook that costs about 4 ms, which is why the deferred initialisation
# this module used to carry for pyenv and fnm is gone.
#
# mise also creates and activates a project virtualenv when its config asks for
# one, replacing pyenv-virtualenv:
#
#   [tools]
#   python = "3.13"
#
#   [env]
#   _.python.venv = { path = ".venv", create = true }
#
# Unlike pyenv-virtualenv it exports VIRTUAL_ENV and PATH without touching
# PROMPT, so this module no longer has to load after prompt.zsh.

# mise ignores .python-version, .nvmrc and friends unless the tools that own
# them are named here; the default is to read only mise's own config files.
# Projects in this configuration still pin versions the traditional way.
export MISE_IDIOMATIC_VERSION_FILE_ENABLE_TOOLS="${MISE_IDIOMATIC_VERSION_FILE_ENABLE_TOOLS:-python,node}"

if (( $+commands[mise] )); then
  eval "$(mise activate zsh)"
fi
