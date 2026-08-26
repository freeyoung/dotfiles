# Node versions come from mise; see runtimes.zsh. What remains here is the
# tooling that sits on top of a resolved runtime.

# Keep the kubectl completion when using its short alias.
(( $+_comps[kubectl] )) && compdef k=kubectl

# fzf uses the same menu height as the previous fish configuration.
export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS:---height 40%}"
# Distributions disagree on where fzf's shell integration lives: Homebrew uses
# opt/fzf/shell, Arch /usr/share/fzf, Debian /usr/share/doc/fzf/examples. Probe
# each so Ctrl-R and Ctrl-T bind wherever fzf came from.
typeset -a zsh_fzf_dirs
zsh_fzf_dirs=(
  ${HOMEBREW_PREFIX:+"$HOMEBREW_PREFIX/opt/fzf/shell"}
  /usr/share/fzf
  /usr/share/doc/fzf/examples
)
for zsh_fzf_dir in "${zsh_fzf_dirs[@]}"; do
  [[ -r "$zsh_fzf_dir/key-bindings.zsh" ]] || continue
  source "$zsh_fzf_dir/key-bindings.zsh"
  [[ -r "$zsh_fzf_dir/completion.zsh" ]] && source "$zsh_fzf_dir/completion.zsh"
  break
done
unset zsh_fzf_dir zsh_fzf_dirs
