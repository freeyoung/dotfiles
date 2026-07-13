if &term =~# '^xterm'
  " Use a steady block in Normal mode and a steady bar in Insert mode.
  let &t_EI .= "\<Esc>[2 q"
  let &t_SI .= "\<Esc>[6 q"
endif
