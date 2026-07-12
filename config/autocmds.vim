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

" Skip undo history and syntax highlighting for large files so opening them
" doesn't stall the editor.
let g:vim_large_file_bytes = 5 * 1024 * 1024
augroup vim_large_file
  autocmd!
  autocmd BufReadPre * if getfsize(expand('<afile>')) > g:vim_large_file_bytes
        \ |   setlocal noundofile noswapfile
        \ |   syntax off
        \ | endif
augroup END
