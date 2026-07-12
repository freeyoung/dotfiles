if &term =~# '^xterm'
  let &t_EI .= "\<Esc>[2 q"
  let &t_SI .= "\<Esc>[6 q"
  augroup vim_terminal_cursor
    autocmd!
    autocmd VimLeave * silent !echo -ne "\033]112\007"
  augroup END
endif
