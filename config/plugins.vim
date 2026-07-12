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
let g:airline_theme = 'powerlineish'
" These auto-enable under has('nvim') regardless of whether their backing
" library is present; diagnostics come from ALE/vim-lsp, not native vim.lsp,
" and there's no IME-switcher library configured.
let g:airline#extensions#xkblayout#enabled = 0
let g:airline#extensions#nvimlsp#enabled = 0
