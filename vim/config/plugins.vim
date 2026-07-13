if has('nvim')
  " Neovim's built-in StatusLine/StatusLineNC default to cterm=reverse/
  " gui=reverse, which leaks into the whole statusline row (including
  " airline's own per-segment colors, and the separators airline computes
  " by reading back already-applied group colors) as an unconditional
  " reverse-video effect Vim doesn't have. Clearing it lets every airline
  " theme render identically on both editors with no per-theme workaround.
  augroup vim_nvim_statusline_reverse
    autocmd!
    autocmd ColorScheme * highlight StatusLine cterm=NONE gui=NONE term=NONE
    autocmd ColorScheme * highlight StatusLineNC cterm=NONE gui=NONE term=NONE
  augroup END
endif

" Load the preferred colorscheme when the plugin is installed.
if !empty(globpath(&runtimepath, 'colors/Tomorrow-Night-Bright.vim'))
  colorscheme Tomorrow-Night-Bright
endif

" NERDTree: close it after opening a file.
let NERDTreeQuitOnOpen = 1

" Airline: use powerline glyphs and the Tomorrow Night Bright theme.
let g:airline_powerline_fonts = 1
let g:airline_theme = 'tomorrow_bright'
" These auto-enable under has('nvim') regardless of whether their backing
" library is present; diagnostics come from vim-lsp, not native vim.lsp, and
" there's no IME-switcher library configured.
let g:airline#extensions#xkblayout#enabled = 0
let g:airline#extensions#nvimlsp#enabled = 0
