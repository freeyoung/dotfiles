source ~/.vim/plugs.vim

" encoding utf-8
set encoding=utf-8

" Reduce the delay when switching from insert to normal
if ! has('gui_running')
  set ttimeoutlen=10
  augroup FastEscape
    autocmd!
    au InsertEnter * set timeoutlen=0
    au InsertLeave * set timeoutlen=1000
  augroup END
endif

" encoding dectection
set fileencodings=utf-8,gb2312,gb18030,gbk,ucs-bom,cp936,latin1

" enable filetype dectection and ft specific plugin/indent
filetype plugin indent on

" enable syntax hightlight and completion 
syntax enable
syntax on

" color theme
" set background=dark
" color solarized 
color Tomorrow-Night-Bright

" highlight current line
au WinLeave * set nocursorline nocursorcolumn
au WinEnter * set cursorline cursorcolumn
set cursorline cursorcolumn

" search operations
set incsearch
"set highlight 	" conflict with highlight current line
set ignorecase
set smartcase

" editor settings
set nocompatible
set confirm                                                       " prompt when existing from an unsaved file
set history=1000
set backspace=indent,eol,start                                    " More powerful backspacing
set updatecount=0                                                 " dont use swapfile 

" persistent_undo
set undofile
set undodir=~/.vim/undodir
set undolevels=1000
set undoreload=10000

" display settings
set t_Co=256                                                      " Explicitly tell vim that the terminal has 256 colors "
" set mouse=a                                                       " use mouse in all modes
set report=0                                                      " always report number of lines changed"
set wrap                                                          " wrap lines
set scrolloff=5                                                   " 2 lines above/below cursor when scrolling
set number                                                        " show line numbers
set showmatch                                                     " show matching bracket (briefly jump)
set showmode                                                      " show mode in status bar (insert/replace/...)
set showcmd                                                       " show typed command in status bar
set ruler                                                         " show cursor position in status bar
set title                                                         " show file in titlebar
set laststatus=2                                                  " use 2 lines for the status bar
set matchtime=2                                                   " show matching bracket for 0.2 seconds
set matchpairs+=<:>                                               " specially for html
set list listchars=tab:<+                                         " display TAB as <+++

" paste mode
set pastetoggle=<F12>

 " When editing a file, always jump to the last cursor position
autocmd BufReadPost *
      \ if ! exists("g:leave_my_cursor_position_alone") |
      \     if line("'\"") > 0 && line ("'\"") <= line("$") |
      \         exe "normal g'\"" |
      \     endif |
      \ endif

" Default Indentation
set autoindent
set smartindent     " indent when
set tabstop=8       " tab width
set softtabstop=4   " backspace & 
set shiftwidth=4    " indent width
" set textwidth=79
set expandtab       " expand tab to space
autocmd FileType html,htmldjango,xhtml,haml,sass,scss,ruby,javascript,php,css setlocal tabstop=4 shiftwidth=2 softtabstop=2
autocmd FileType python set textwidth=0 wrap
autocmd Syntax javascript set syntax=jquery   " JQuery syntax support
" js
let g:html_indent_inctags = "html,body,head,tbody"
let g:html_indent_script1 = "inc"
let g:html_indent_style1 = "inc"

" Keybindings for plugin toggle
nmap <F4> :PyLintAuto<cr>
nmap <F5> :NERDTreeToggle<cr>
nmap <F6> :TagbarToggle<cr>

" easier navigation between split windows
nnoremap <c-j> <c-w>j
nnoremap <c-k> <c-w>k
nnoremap <c-h> <c-w>h
nnoremap <c-l> <c-w>l

" easier navigation between tabs
map <S-H> gT
map <S-L> gt

nnoremap <leader>+ <c-w>+
nnoremap <leader>- <c-w>-
nnoremap <leader>_ <c-w>_
nnoremap <leader>= <c-w>=
nnoremap <leader>[ <c-w><
nnoremap <leader>] <c-w>>

" Wrapped lines goes down/up to next row, rather than next line in file.
nnoremap j gj
nnoremap k gk

" map F1, F2, F3 to :w, :q, :x
map <F1> :w<kEnter>
imap <F1> <Esc>:w<kEnter>a
map <F2> :q<kEnter>
imap <F2> <Esc>:q<kEnter>
map <F3> :x<kEnter>
imap <F3> <Esc>:x<kEnter>

" Tagbar
let g:tagbar_left=0
let g:tagbar_width=30
let g:tagbar_autofocus = 1
let g:tagbar_sort = 0 
let g:tagbar_compact = 1
" tag for coffee
if executable('coffeetags')
  let g:tagbar_type_coffee = {
        \ 'ctagsbin' : 'coffeetags',
        \ 'ctagsargs' : '',
        \ 'kinds' : [
        \ 'f:functions',
        \ 'o:object',
        \ ],
        \ 'sro' : ".",
        \ 'kind2scope' : {
        \ 'f' : 'object',
        \ 'o' : 'object',
        \ }
        \ }
endif

" Nerd Tree 
let NERDChristmasTree=0
let NERDTreeWinSize=30
let NERDTreeChDirMode=2
let NERDTreeIgnore=['\.vim$', '\~$', '\.pyc$', '\.swp$']
let NERDTreeSortOrder=['^__\.py$', '\/$', '*', '\.swp$',  '\~$']
let NERDTreeShowBookmarks=1
let NERDTreeQuitOnOpen=1
let NERDTreeWinPos = "left"

" ZenCoding
let g:user_zen_expandabbr_key='<C-j>'

" powerline
let g:Powerline_symbols = 'fancy'

" Sytastic Settings
" let g:syntastic_python_checkers = ["flake8"]
let g:syntastic_python_flake8_args = "--max-line-length=120"

" python-mode
let g:pymode_folding = 0
" let g:pymode_motion = 1
" let g:pymode_virtualenv = 1
" 
let g:pymode_syntax = 1
let g:pymode_syntax_all = 1
let g:pymode_syntax_print_as_function = 0
let g:pymode_syntax_indent_errors = g:pymode_syntax_all
let g:pymode_syntax_space_errors = g:pymode_syntax_all
let g:pymode_syntax_string_formatting = g:pymode_syntax_all
let g:pymode_syntax_string_format = g:pymode_syntax_all
let g:pymode_syntax_string_templates = g:pymode_syntax_all
let g:pymode_syntax_doctests = g:pymode_syntax_all
let g:pymode_syntax_builtin_objs = g:pymode_syntax_all
let g:pymode_syntax_builtin_funcs = g:pymode_syntax_all
let g:pymode_syntax_highlight_exceptions = g:pymode_syntax_all
let g:pymode_syntax_highlight_equal_operator = g:pymode_syntax_all
let g:pymode_syntax_highlight_stars_operator = g:pymode_syntax_all
let g:pymode_syntax_highlight_self = g:pymode_syntax_all
" let g:pymode_syntax_slow_sync = 0
" 
" let g:pymode_run = 1
" let g:pymode_run_key = '<leader>r'
" 
let g:pymode_lint = 1
" let g:pymode_lint_config = "$HOME/.pylintrc"
" let g:pymode_lint_cwindow = 0
" let g:pymode_lint_jump = 0
" let g:pymode_lint_hold = 0
" let g:pymode_lint_signs = 1
" let g:pymode_lint_mccabe_complexity = 8
" let g:pymode_lint_minheight = 3
" let g:pymode_lint_maxheight = 6
" let g:pymode_lint_checker = "pep8,pyflakes,mccabe"
" let g:pymode_lint_select = ""
let g:pymode_lint_ignore = "E501,E701,E731"
" let g:pymode_lint_onfly = 1
let g:pymode_lint_write = 0
" let g:pymode_lint_buffer = 1
" let g:pymode_lint_message = 1
" 
let g:pymode_rope = 0
" let g:pymode_rope_map_space = 1
" let g:pymode_rope_short_prefix = 1
" let g:pymode_rope_vim_completion = 1
" let g:pymode_rope_always_show_complete_menu = 0
" let g:pymode_rope_auto_project = 1
" let g:pymode_rope_enable_autoimport = 1
" let g:pymode_rope_autoimport_generate = 1
" let g:pymode_rope_autoimport_underlineds = 0
" let g:pymode_rope_codeassist_maxfixes = 10
" let g:pymode_rope_sorted_completions = 1
" let g:pymode_rope_extended_complete = 1
" let g:pymode_rope_autoimport_modules = ["os","shutil","datetime"]
" let g:pymode_rope_confirm_saving = 1
" let g:pymode_rope_global_prefix = "<C-x>p"
" let g:pymode_rope_local_prefix = "<C-c>r"
" let g:pymode_rope_guess_project = 1
" let g:pymode_rope_goto_def_newwin = ""
" let g:pymode_rope_always_show_complete_menu = 0
" 
" let g:pymode_breakpoint = 1
" let g:pymode_breakpoint_key = '<leader>b'
" 
" let g:pymode_utils_whitespaces = 1
" 
" let g:pymode_doc = 1
" let g:pymode_doc_key = 'K'

" vim-session
" let g:session_autosave = 'no'

" sessionman
" Session List {
    set sessionoptions=blank,buffers,curdir,folds,tabpages,winsize
    nmap <leader>sl :SessionList<CR>
    nmap <leader>ss :SessionSave<CR>
" }

" NeoComplCache
set completeopt-=preview
let g:neocomplcache_enable_at_startup=1
"let g:neoComplcache_disableautocomplete=1
let g:neocomplcache_enable_smart_case=1
let g:neocomplcache_enable_camel_case_completion=1
let g:neocomplcache_enable_underbar_completion=1
let g:neocomplcache_enable_auto_delimiter=1
let g:neocomplcache_min_syntax_length = 3
let g:neocomplcache_force_overwrite_completefunc=1
let g:neocomplcache_lock_buffer_name_pattern = '\*ku\*'
"imap <C-k> <Plug>(neocomplcache_snippets_force_expand)
"smap <C-k> <Plug>(neocomplcache_snippets_force_expand)
"imap <C-l> <Plug>(neocomplcache_snippets_expand)
"smap <C-l> <Plug>(neocomplcache_snippets_expand)
"imap <C-t> <Plug>(neocomplcache_snippets_jump)
"smap <C-t> <Plug>(neocomplcache_snippets_jump)
"imap <C-l> <Plug>(neocomplcache_snippets_force_jump)
"smap <C-l> <Plug>(neocomplcache_snippets_force_jump)
" Define dictionary
let g:neocomplcache_dictionary_filetype_lists = {
    \ 'default' : '',
    \ 'vimshell' : $HOME.'/.vimshell_hist',
    \ 'scheme' : $HOME.'/.gosh_completions'
    \ }
" Define keyword.
if !exists('g:neocomplcache_keyword_patterns')
    let g:neocomplcache_keyword_patterns = {}
endif
let g:neocomplcache_keyword_patterns._ = '\h\w*'

" Fugitive {
    nnoremap <leader>gc :Gcommit -v 
    nnoremap <leader>ge :Gedit 
    nnoremap <leader>gg :Ggrep 
    nnoremap <silent> <leader>gs :Gstatus<CR>
    nnoremap <silent> <leader>gd :Gdiff<CR>
    nnoremap <silent> <leader>gb :Gblame<CR>
    nnoremap <silent> <leader>gl :Glog<CR>
    nnoremap <silent> <leader>gp :Git push<CR>
    nnoremap <silent> <leader>gr :Gread<CR>
    nnoremap <silent> <leader>gw :Gwrite<CR>
"}

" ConqueTerm
let g:ConqueTerm_FastMode = 1
let g:ConqueTerm_CloseOnEnd = 1
let g:ConqueTerm_StartMessages = 1
let g:ConqueTerm_CWInsert = 1
let g:ConqueTerm_ToggleKey = '<leader><F8>'
nnoremap <F7> :ConqueTermTab zsh<CR>
inoremap <F7> <ESC>:ConqueTermTab zsh<CR>
nnoremap <F8> :ConqueTermVSplit zsh<CR>
inoremap <F8> <ESC>:ConqueTermVSplit zsh<CR>
nnoremap <F9> :ConqueTermSplit zsh<CR>
inoremap <F9> <ESC>:ConqueTermSplit zsh<CR>

" w!!
cmap w!! w !sudo tee > /dev/null %

" Enable omni completion.
autocmd FileType css setlocal omnifunc=csscomplete#CompleteCSS
autocmd FileType html,markdown setlocal omnifunc=htmlcomplete#CompleteTags
autocmd FileType javascript setlocal omnifunc=javascriptcomplete#CompleteJS
autocmd FileType python setlocal omnifunc=pythoncomplete#Complete

" SuperTab
let g:SuperTabDefaultCompletionType="<c-n>"

" ctrlp
set wildignore+=*/tmp/*,*.so,*.swp,*.zip,*.pyc,.DS_Store  " MacOSX/Linux
let g:ctrlp_custom_ignore = '\.git$\|\.hg$\|\.svn$'

" eggache vim
if has("user_commands")
    command! -bang -nargs=* -complete=file E e<bang> <args>
    command! -bang -nargs=* -complete=file W w<bang> <args>
    command! -bang -nargs=* -complete=file Wq wq<bang> <args>
    command! -bang -nargs=* -complete=file WQ wq<bang> <args>
    command! -bang Wa wa<bang>
    command! -bang WA wa<bang>
    command! -bang Q q<bang>
    command! -bang QA qa<bang>
    command! -bang Qa qa<bang>
endif

cmap Tabe tabe

" Change Working Directory to that of the current file
cmap cwd lcd %:p:h
cmap cd. lcd %:p:h

" Visual shifting (does not exit Visual mode)
vnoremap < <gv
vnoremap > >gv

" http://vimcasts.org/e/14
" for e, sp, vsp, tabe
cnoremap %% <C-R>=expand('%:h').'/'<cr>
map <leader>ew :e %%
map <leader>es :sp %%
map <leader>ev :vsp %%
map <leader>et :tabe %%

" Map <Leader>ff to display all lines with keyword under cursor
" and ask which one to jump to
nmap <Leader>ff [I:let nr = input("Which one: ")<Bar>exe "normal " . nr ."[\t"<CR>

" quick quickfix
aug QFClose
  au!
  au WinEnter * if winnr('$') == 1 && getbufvar(winbufnr(winnr()), "&buftype") == "quickfix"|q|endif
aug END

" airline
let g:airline_powerline_fonts=1
let g:airline_theme='powerlineish'

:inoremap <Esc>Oq 1
:inoremap <Esc>Or 2
:inoremap <Esc>Os 3
:inoremap <Esc>Ot 4
:inoremap <Esc>Ou 5
:inoremap <Esc>Ov 6
:inoremap <Esc>Ow 7
:inoremap <Esc>Ox 8
:inoremap <Esc>Oy 9
:inoremap <Esc>Op 0
:inoremap <Esc>On .
:inoremap <Esc>OQ /
:inoremap <Esc>OR *
:inoremap <Esc>Ol +
:inoremap <Esc>OS -
:inoremap <Esc>OM <Enter>

" for macvim
if has("gui_running")
    set go=aAce  " remove toolbar
    set transparency=30
    set guifont=Monaco:h13
    set showtabline=2
    set columns=140
    set lines=40
    noremap <D-M-Left> :tabprevious<cr>
    noremap <D-M-Right> :tabnext<cr>
    map <D-1> 1gt
    map <D-2> 2gt
    map <D-3> 3gt
    map <D-4> 4gt
    map <D-5> 5gt
    map <D-6> 6gt
    map <D-7> 7gt
    map <D-8> 8gt
    map <D-9> 9gt
    map <D-0> :tablast<CR>
endif
