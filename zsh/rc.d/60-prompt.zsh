# Starship's built-in duration renderer uses e.g. "10s123ms". Preserve the
# requested Duration: X.XXXs form and print it immediately after the command.
zmodload zsh/datetime
typeset -g _zsh_prompt_command_started_at=''

_zsh_prompt_duration_preexec() {
  _zsh_prompt_command_started_at=$EPOCHREALTIME
}

_zsh_prompt_duration_precmd() {
  local command_status=$?
  local elapsed
  local duration

  if [[ -n $_zsh_prompt_command_started_at ]]; then
    (( elapsed = EPOCHREALTIME - _zsh_prompt_command_started_at ))
    if (( elapsed > 10 )); then
      printf -v duration 'Duration: %.3fs' "$elapsed"
      print -P "%F{yellow}${duration}%f"
    fi
  fi
  _zsh_prompt_command_started_at=''
  return $command_status
}

# Register before Starship so the duration line is printed before the next
# prompt is rendered, while preserving the original command status.
add-zsh-hook preexec _zsh_prompt_duration_preexec
add-zsh-hook precmd _zsh_prompt_duration_precmd

# Starship owns the prompt and registers its prompt hooks before highlighting.
if (( $+commands[starship] )); then
  eval "$(starship init zsh)"
fi
