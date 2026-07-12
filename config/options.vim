" Editing and search behavior
set fileencodings=utf-8,gb2312,gb18030,gbk,ucs-bom,cp936,latin1
set confirm
set history=1000
set backspace=indent,eol,start
set incsearch
set ignorecase
set smartcase

" Keep swap, backup, and undo files out of project directories.
let s:config_dir = fnamemodify(resolve(expand('<sfile>:p')), ':h')
let s:state_dir = fnamemodify(s:config_dir, ':h') . '/state'
for s:subdirectory in ['undo', 'swap', 'backup']
  call mkdir(s:state_dir . '/' . s:subdirectory, 'p')
endfor
execute 'set undodir=' . fnameescape(s:state_dir . '/undo//')
execute 'set directory=' . fnameescape(s:state_dir . '/swap//')
execute 'set backupdir=' . fnameescape(s:state_dir . '/backup//')
unlet s:config_dir s:state_dir s:subdirectory
set undofile
set undolevels=1000
set undoreload=10000
set updatecount=200
set backup
set writebackup

" Display
if exists('+termguicolors')
  set termguicolors
endif
set report=0
set wrap
set scrolloff=5
set number
set showmatch
set showmode
set showcmd
set ruler
set title
set laststatus=2
set matchtime=2
set matchpairs+=<:>
set list
set listchars=tab:<+
set wildignore+=*/tmp/*,*.so,*.swp,*.zip,*.pyc,.DS_Store
set sessionoptions=blank,buffers,curdir,folds,tabpages,winsize

" Indentation defaults
set autoindent
set smartindent
set tabstop=8
set softtabstop=4
set shiftwidth=4
set expandtab

" Keep the legacy paste toggle without overriding jump-list navigation.
set pastetoggle=<F12>
