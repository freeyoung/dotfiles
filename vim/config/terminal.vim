if &term =~# '^xterm'
  let &t_EI .= "<Esc>[2 q"
  let &t_SI .= "<Esc>[6 q"
endif
