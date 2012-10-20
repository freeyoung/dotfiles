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
Bundle 'Shougo/neosnippet'
Bundle 'mattn/zencoding-vim'
Bundle 'honza/snipmate-snippets'

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
Bundle 'scrooloose/nerdcommenter'
Bundle 'majutsushi/tagbar'
" Bundle 'humiaozuzu/TabBar'
Bundle 'godlygeek/tabular'
Bundle 'mileszs/ack.vim'
Bundle 'kien/ctrlp.vim'

"-------------
" Other Utils
" ------------
Bundle 'tpope/vim-fugitive'
Bundle 'Lokaltog/vim-powerline'
" Bundle 'humiaozuzu/fcitx-status'
Bundle 'sjl/gundo.vim'
Bundle 'vim-scripts/mru.vim'
Bundle 'scrooloose/syntastic'
" Bundle 'nvie/vim-togglemouse'
Bundle 'xolox/vim-session'

"----------------------------------------
" Syntax/Indent for language enhancement
"----------------------------------------
Bundle 'tpope/vim-markdown'
Bundle 'nono/jquery.vim'
Bundle 'pangloss/vim-javascript'
Bundle '2072/PHP-Indenting-for-VIm'
Bundle 'tpope/vim-haml'
Bundle 'othree/html5.vim'
Bundle 'kchmck/vim-coffee-script'
Bundle 'rodjek/vim-puppet'

"--------------
" Color Scheme
"--------------
" Bundle 'rickharris/vim-blackboard'
Bundle 'altercation/vim-colors-solarized'
" Bundle 'rickharris/vim-monokai'
" Bundle 'tpope/vim-vividchalk'

filetype plugin indent on     " required!
