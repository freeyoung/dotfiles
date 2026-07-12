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

colorscheme Tomorrow-Night-Bright

" NERDTree
let NERDChristmasTree = 0
let NERDTreeWinSize = 30
let NERDTreeChDirMode = 2
let NERDTreeIgnore = ['\.vim$', '\~$', '\.pyc$', '\.swp$']
let NERDTreeSortOrder = ['^__\.py$', '\/$', '*', '\.swp$', '\~$']
let NERDTreeShowBookmarks = 1
let NERDTreeQuitOnOpen = 1
let NERDTreeWinPos = 'left'

" fzf.vim uses the system fzf binary; ripgrep supplies the file list and grep.
if executable('rg')
  let $FZF_DEFAULT_COMMAND = 'rg --files'
endif
let g:fzf_layout = {'window': {'width': 0.9, 'height': 0.8}}

" ALE
let g:ale_python_flake8_options = '--max-line-length=119'
" Default lints on every keystroke; only re-lint on normal-mode edits and
" leaving insert mode to avoid linter churn while typing.
let g:ale_lint_on_text_changed = 'normal'
let g:ale_lint_on_insert_leave = 1

" Airline
let g:airline_powerline_fonts = 1
let g:airline_theme = 'tomorrow_bright'
" These auto-enable under has('nvim') regardless of whether their backing
" library is present; diagnostics come from ALE/vim-lsp, not native vim.lsp,
" and there's no IME-switcher library configured.
let g:airline#extensions#xkblayout#enabled = 0
let g:airline#extensions#nvimlsp#enabled = 0
