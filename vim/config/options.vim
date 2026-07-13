" Editing and search behavior.
" Try UTF-8 first, then common Simplified Chinese encodings and Latin-1.
set fileencodings=utf-8,gb2312,gb18030,gbk,ucs-bom,cp936,latin1
" Ask before abandoning unsaved changes.
set confirm
" Keep up to 1000 command-line/history entries.
set history=1000
" Make Backspace work across indentation, line ends, and the start of insert.
set backspace=indent,eol,start
" Show search matches incrementally.
set incsearch
" Ignore case unless the search contains uppercase characters.
set ignorecase
" Restore case sensitivity automatically for mixed-case searches.
set smartcase

" Keep swap, backup, and undo files out of project directories and the
" dotfiles checkout.
let s:state_dir = g:dotfiles_vim_state_dir
for s:subdirectory in ['undo', 'swap', 'backup']
  call mkdir(s:state_dir . '/' . s:subdirectory, 'p')
endfor
execute 'set undodir=' . fnameescape(s:state_dir . '/undo//')
execute 'set directory=' . fnameescape(s:state_dir . '/swap//')
execute 'set backupdir=' . fnameescape(s:state_dir . '/backup//')
unlet s:state_dir s:subdirectory
" Persist undo history between sessions.
set undofile
" Retain up to 1000 changes in each undo tree.
set undolevels=1000
" Allow up to 10000 lines when reloading an undo file.
set undoreload=10000
" Write swap files after 200 changed characters.
set updatecount=200
" Keep a backup copy while editing.
set backup
" Keep a backup during writes until the new file is safely written.
set writebackup

" Display.
if exists('+termguicolors')
  " Use true-color highlighting when the editor supports it.
  set termguicolors
endif
" Report no changed-line count after commands.
set report=0
" Wrap long lines at the window edge.
set wrap
" Keep five screen lines visible around the cursor.
set scrolloff=5
" Show absolute line numbers.
set number
" Briefly highlight matching brackets.
set showmatch
" Show the current mode in the command area.
set showmode
" Show the current command while it is being typed.
set showcmd
" Show the cursor position in the ruler.
set ruler
" Set the terminal/window title to the current file.
set title
" Always show the status line.
set laststatus=2
" Keep matching-character highlight visible for two tenths of a second.
set matchtime=2
" Treat angle brackets as a matching pair.
set matchpairs+=<:>
" Show tabs and other invisible characters.
set list
" Render tabs as a plus sign followed by spaces.
set listchars=tab:<+
" Avoid scanning common temporary and generated files for completion.
set wildignore+=*/tmp/*,*.so,*.swp,*.zip,*.pyc,.DS_Store
" Preserve these elements when creating sessions or views.
set sessionoptions=blank,buffers,curdir,folds,tabpages,winsize

" Cap syntax highlighting scan width so very long lines (minified JS, data
" dumps) don't slow down scrolling.
" Limit syntax highlighting work on very long lines.
set synmaxcol=500

" Default updatetime (4000ms) makes gitgutter/CursorHold-driven updates feel
" sluggish; a fixed signcolumn stops LSP/gitgutter signs from shifting text
" when they appear.
" Poll for CursorHold and diagnostics frequently enough for LSP feedback.
set updatetime=250
" Reserve the sign column so diagnostics do not shift buffer text.
set signcolumn=yes

" Indentation defaults.
" Copy indentation from the previous line.
set autoindent
" Add a basic syntax-aware indentation adjustment.
set smartindent
" Interpret literal tabs as eight columns by default.
set tabstop=8
" Use four spaces when editing with Tab/Backspace.
set softtabstop=4
" Indent continuation lines by four columns.
set shiftwidth=4
" Insert spaces instead of literal tab characters.
set expandtab
