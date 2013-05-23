source ~/.vim/bundles.vim

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
color tomorrow-night-bright

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

" display settings
set t_Co=256                                                      " Explicitly tell vim that the terminal has 256 colors "
" set mouse=a                                                       " use mouse in all modes
set report=0                                                      " always report number of lines changed"
set wrap                                                          " dont wrap lines
set scrolloff=2                                                   " 2 lines above/below cursor when scrolling
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

nnoremap <leader>+ <c-w>+
nnoremap <leader>- <c-w>-
nnoremap <leader>_ <c-w>_
nnoremap <leader>= <c-w>=
nnoremap <leader>[ <c-w><
nnoremap <leader>] <c-w>>

map <F1> :w<kEnter>
imap <F1> <Esc>:w<kEnter>a

" tabbar
" let g:Tb_MaxSize = 2
" let g:Tb_TabWrap = 1

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
" let g:pymode_lint = 1
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
" let g:pymode_lint_ignore = ""
" let g:pymode_lint_onfly = 1
let g:pymode_lint_write = 0
" let g:pymode_lint_buffer = 1
" let g:pymode_lint_message = 1
" 
" let g:pymode_rope = 1
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
let g:session_autosave = 'no'

" NeoComplCache
set completeopt-=preview
let g:neocomplcache_enable_at_startup=1
"let g:neoComplcache_disableautocomplete=1
let g:neocomplcache_enable_smart_case=1
let g:neocomplcache_min_syntax_length = 3
let g:neocomplcache_lock_buffer_name_pattern = '\*ku\*'
imap <C-k> <Plug>(neocomplcache_snippets_force_expand)
smap <C-k> <Plug>(neocomplcache_snippets_force_expand)
"imap <C-l> <Plug>(neocomplcache_snippets_expand)
"smap <C-l> <Plug>(neocomplcache_snippets_expand)
"imap <C-t> <Plug>(neocomplcache_snippets_jump)
"smap <C-t> <Plug>(neocomplcache_snippets_jump)
imap <C-l> <Plug>(neocomplcache_snippets_force_jump)
smap <C-l> <Plug>(neocomplcache_snippets_force_jump)

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

" eggcache vim
:command W w
:command WQ wq
:command Wq wq
:command Q q
:command Qa qa
:command QA qa

" show syntax highlighting groups for word under cursor
nmap <C-P> :call <SID>SynStack()<CR>
function! <SID>SynStack()
  if !exists("*synstack")
    return
  endif
  echo map(synstack(line('.'), col('.')), 'synIDattr(v:val, "name")')
endfunc

" quick quickfix
aug QFClose
  au!
  au WinEnter * if winnr('$') == 1 && getbufvar(winbufnr(winnr()), "&buftype") == "quickfix"|q|endif
aug END

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
