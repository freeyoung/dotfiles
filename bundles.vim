set nocompatible               " be iMproved
filetype off                   " required!

set rtp+=~/.vim/bundle/vundle/
call vundle#rc()

" let Vundle manage Vundle
" required! 
Bundle 'gmarik/vundle'

"-----------------
" Code Completion
"-----------------
Bundle 'ervandew/supertab'
Bundle 'Shougo/neocomplcache'
Bundle 'mattn/zencoding-vim'
Bundle 'scrooloose/nerdcommenter'

"-----------------------
" Surrounding Operation
"-----------------------
Bundle 'Raimondi/delimitMate'
Bundle 'tsaleh/vim-matchit'
Bundle 'tpope/vim-surround'

"--------------
" Code Reading
"--------------
Bundle 'scrooloose/nerdtree'
Bundle 'majutsushi/tagbar'
Bundle 'mileszs/ack.vim'
Bundle 'kien/ctrlp.vim'

"-------------
" Other Utils
" ------------
Bundle 'Lokaltog/vim-powerline'
Bundle 'xolox/vim-session'
Bundle 'vim-scripts/mru.vim'
Bundle 'scrooloose/syntastic'

"----------------------------------------
" Syntax/Indent for language enhancement
"----------------------------------------
Bundle 'tpope/vim-markdown'
Bundle 'nono/jquery.vim'
Bundle 'pangloss/vim-javascript'
Bundle 'othree/html5.vim'
Bundle 'kchmck/vim-coffee-script'
Bundle 'rodjek/vim-puppet'
" Bundle 'nvie/vim-flake8'
Bundle 'klen/python-mode'

"--------------
" Color Scheme
"--------------
Bundle 'altercation/vim-colors-solarized'
Bundle 'rickharris/vim-monokai'
Bundle 'tpope/vim-vividchalk'
Bundle 'chriskempson/vim-tomorrow-theme'

filetype plugin indent on     " required!
