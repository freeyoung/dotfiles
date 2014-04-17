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
" Bundle 'mattn/zencoding-vim'
" Bundle 'scrooloose/nerdcommenter'
" Bundle 'Shougo/neosnippet'

"-----------------------
" Surrounding Operation
"-----------------------
Bundle 'Raimondi/delimitMate'
Bundle 'vim-scripts/matchit.zip'
Bundle 'tpope/vim-surround'

"--------------
" Code Reading
"--------------
Bundle 'scrooloose/nerdtree'
" Bundle 'majutsushi/tagbar'
" Bundle 'mileszs/ack.vim'
" Bundle 'kien/ctrlp.vim'
Bundle 'scrooloose/syntastic'

"-------------
" Other Utils
" ------------
" Bundle 'xolox/vim-session'
" Bundle 'vim-scripts/sessionman.vim'
" Bundle 'tpope/vim-fugitive'
Bundle 'Lokaltog/vim-powerline'
" Bundle 'bling/vim-airline'
" Bundle 'sjl/gundo.vim'
" Bundle 'vim-scripts/mru.vim'
" Bundle 'carlobaldassi/ConqueTerm'

"----------------------------------------
" Syntax/Indent for language enhancement
"----------------------------------------
Bundle 'tpope/vim-markdown'
" Bundle 'nono/jquery.vim'
Bundle 'pangloss/vim-javascript'
Bundle 'othree/html5.vim'
" Bundle 'kchmck/vim-coffee-script'
Bundle 'rodjek/vim-puppet'
" Bundle 'nvie/vim-flake8'
Bundle 'klen/python-mode'
" Bundle '2072/PHP-Indenting-for-VIm'
" Bundle 'tpope/vim-haml'

"--------------
" Color Scheme
"--------------
" Bundle 'altercation/vim-colors-solarized'
" Bundle 'tomasr/molokai'
" Bundle 'rickharris/vim-monokai'
" Bundle 'tpope/vim-vividchalk'
Bundle 'chriskempson/vim-tomorrow-theme'

filetype plugin indent on     " required!
