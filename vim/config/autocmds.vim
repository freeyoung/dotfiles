" Reduce terminal key-sequence latency.
set ttimeoutlen=10
augroup vim_fast_escape
  autocmd!
  " Do not wait for a long escape sequence while entering Insert mode.
  autocmd InsertEnter * set timeoutlen=0
  " Restore normal mapping timeout after leaving Insert mode.
  autocmd InsertLeave * set timeoutlen=1000
augroup END

" Highlight the current line only in the active window.
set cursorline
augroup vim_cursorline
  autocmd!
  autocmd WinLeave * setlocal nocursorline
  autocmd WinEnter * setlocal cursorline
augroup END

augroup vim_restore_cursor_position
  autocmd!
  " Reopen files at the last known cursor position when it is still valid.
  autocmd BufReadPost * if !exists('g:leave_my_cursor_position_alone') && line("'\"") > 0 && line("'\"") <= line('$') | execute "normal! g'\"" | endif
augroup END

augroup vim_quickfix_window
  autocmd!
  " Close a quickfix window when it is the only remaining window.
  autocmd WinEnter * if winnr('$') == 1 && getbufvar(winbufnr(winnr()), '&buftype') ==# 'quickfix' | quit | endif
augroup END

" Skip undo history and syntax highlighting for large files so opening them
" doesn't stall the editor.
let g:vim_large_file_bytes = 5 * 1024 * 1024
augroup vim_large_file
  autocmd!
  " Disable expensive per-file features above the configured size threshold.
  autocmd BufReadPre * if getfsize(expand('<afile>')) > g:vim_large_file_bytes
        \ |   setlocal noundofile noswapfile
        \ |   syntax off
        \ | endif
augroup END
