if has('gui_running')
  set go=aAce
  if exists('+transparency')
    set transparency=30
  endif
  set guifont=Monaco:h13
  set showtabline=2
  set columns=140
  set lines=40
endif

if &term =~# '^xterm'
  let &t_EI .= "\<Esc>[2 q"
  let &t_SI .= "\<Esc>[6 q"
  augroup vim_terminal_cursor
    autocmd!
    autocmd VimLeave * silent !echo -ne "\033]112\007"
  augroup END
endif
