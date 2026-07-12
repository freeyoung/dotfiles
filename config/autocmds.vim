if !has('gui_running')
  set ttimeoutlen=10
  augroup vim_fast_escape
    autocmd!
    autocmd InsertEnter * set timeoutlen=0
    autocmd InsertLeave * set timeoutlen=1000
  augroup END
endif

set cursorline cursorcolumn
augroup vim_cursorline
  autocmd!
  autocmd WinLeave * setlocal nocursorline nocursorcolumn
  autocmd WinEnter * setlocal cursorline cursorcolumn
augroup END

augroup vim_restore_cursor_position
  autocmd!
  autocmd BufReadPost * if !exists('g:leave_my_cursor_position_alone') && line("'\"") > 0 && line("'\"") <= line('$') | execute "normal! g'\"" | endif
augroup END

augroup vim_quickfix_window
  autocmd!
  autocmd WinEnter * if winnr('$') == 1 && getbufvar(winbufnr(winnr()), '&buftype') ==# 'quickfix' | quit | endif
augroup END
