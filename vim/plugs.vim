call plug#begin(g:dotfiles_vim_data_dir . '/plugged')

"-----------------
" Completion & LSP
"-----------------
Plug 'prabirshrestha/vim-lsp'
Plug 'mattn/vim-lsp-settings'
Plug 'prabirshrestha/asyncomplete.vim'
Plug 'prabirshrestha/asyncomplete-lsp.vim'

"----------
" UI
"----------
Plug 'vim-airline/vim-airline'
" Fork of the original pre-refactor theme with two fixes upstream never
" made: &termguicolors is checked alongside the legacy &t_Co gate (so Vim
" and Neovim render identically), and it ships its own airline theme
" (tomorrow_bright) with full mode coverage including commandline.
Plug 'freeyoung/vim-tomorrow-theme'

"-------
" Other
"-------
" Automatically close pairs, quotes, and blocks in insert mode.
Plug 'cohama/lexima.vim'
Plug 'scrooloose/nerdtree', {'on': ['NERDTreeToggle', 'NERDTree', 'NERDTreeFind']}
Plug 'airblade/vim-gitgutter'

"-----------------
" Language Support
"-----------------
Plug 'tpope/vim-markdown', {'for': 'markdown'}
Plug 'pangloss/vim-javascript', {'for': 'javascript'}
Plug 'othree/html5.vim', {'for': 'html'}
Plug 'stephpy/vim-yaml', {'for': 'yaml'}
" ansible-vim's ftdetect sets ft=yaml.ansible under Vim but plain ft=ansible
" under Neovim (its own deliberate difference); its ftplugin/syntax/indent
" files target the 'ansible' component either way.
Plug 'pearofducks/ansible-vim', {'for': ['yaml.ansible', 'ansible', 'ansible_hosts']}
call plug#end()
