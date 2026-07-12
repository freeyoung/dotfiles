let s:vim_root = fnamemodify(resolve(expand('<sfile>:p')), ':h')
call plug#begin(s:vim_root . '/plugged')

"-----------------
" Code Completion
"-----------------
" Replaced by vim-lsp + asyncomplete; do not load competing completion engines.
" Plug 'ervandew/supertab'
" Plug 'Shougo/neocomplete'
Plug 'prabirshrestha/vim-lsp'
Plug 'mattn/vim-lsp-settings'
Plug 'prabirshrestha/asyncomplete.vim'
Plug 'prabirshrestha/asyncomplete-lsp.vim'
" Plug 'scrooloose/nerdcommenter'
" Plug 'Shougo/neosnippet'

"-----------------------
" Surrounding Operation
"-----------------------
Plug 'Raimondi/delimitMate'
Plug 'vim-scripts/matchit.zip'
Plug 'tpope/vim-surround'

"--------------
" Code Reading
"--------------
Plug 'scrooloose/nerdtree'
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'
" Plug 'majutsushi/tagbar'
" Plug 'mileszs/ack.vim'
" Plug 'kien/ctrlp.vim'
Plug 'w0rp/ale'

"-------------
" Other Utils
" ------------
" Plug 'xolox/vim-session'
" Plug 'vim-scripts/sessionman.vim'
" Plug 'tpope/vim-fugitive'
" Plug 'powerline/powerline', {'rtp': 'powerline/bindings/vim'}
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
" Plug 'sjl/gundo.vim'
" Plug 'vim-scripts/mru.vim'
Plug 'airblade/vim-gitgutter'

"----------------------------------------
" Syntax/Indent for language enhancement
"----------------------------------------
Plug 'tpope/vim-markdown', {'For': 'markdown'}
Plug 'pangloss/vim-javascript'
Plug 'othree/html5.vim'
" Plug 'kchmck/vim-coffee-script'
" Plug 'rodjek/vim-puppet'
" Plug 'nvie/vim-flake8'
" Plug '2072/PHP-Indenting-for-VIm'
" Plug 'tpope/vim-haml'
Plug 'stephpy/vim-yaml'

"--------------
" Color Scheme
"--------------
" Plug 'altercation/vim-colors-solarized'
" Plug 'tomasr/molokai'
" Plug 'rickharris/vim-monokai'
" Plug 'tpope/vim-vividchalk'
Plug 'chriskempson/vim-tomorrow-theme'
call plug#end()
unlet s:vim_root
