let s:vim_root = fnamemodify(resolve(expand('<sfile>:p')), ':h')
call plug#begin(s:vim_root . '/plugged')

"-----------------
" Code Completion
"-----------------
Plug 'prabirshrestha/vim-lsp'
Plug 'mattn/vim-lsp-settings'
Plug 'prabirshrestha/asyncomplete.vim'
Plug 'prabirshrestha/asyncomplete-lsp.vim'

"-----------------------
" Surrounding Operation
"-----------------------
Plug 'Raimondi/delimitMate'
" matchit is loaded from Vim's bundled optional package instead; see
" config/filetypes.vim.
Plug 'tpope/vim-surround'

"--------------
" Code Reading
"--------------
Plug 'scrooloose/nerdtree'
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'
Plug 'w0rp/ale'

"-------------
" Other Utils
"-------------
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'airblade/vim-gitgutter'

"----------------------------------------
" Syntax/Indent for language enhancement
"----------------------------------------
Plug 'tpope/vim-markdown', {'for': 'markdown'}
Plug 'pangloss/vim-javascript'
Plug 'othree/html5.vim'
Plug 'stephpy/vim-yaml'

"--------------
" Color Scheme
"--------------
Plug 'sainnhe/sonokai'
call plug#end()
unlet s:vim_root
