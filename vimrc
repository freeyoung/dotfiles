set nocompatible    "非兼容模式
syntax on
set background=dark "背景色
"color desert
set ruler           "在左下角显示当前文件所在行
set showcmd         "在状态栏显示命令
set showmatch       "显示匹配的括号
set ignorecase      "大小写无关匹配
set smartcase       "只能匹配，即小写全匹配，大小写混槴¢时高亮显示
set incsearch       "增量秴¢
set nohls           "秴¢时随着输入立即定位，不知什么原因会关闭结果高亮
set report=0        "显示修改次数
"set mouse=a         "控制台启用鼠标
set number          "行号
set nobackup        "无备份
"set cursorline      "高亮当前行背景
set fileencodings=ucs-bom,UTF-8,GBK,BIG5,latin1
set fileencoding=UTF-8
set fileformat=unix "换行使用unix方式
set ambiwidth=double
set noerrorbells    "不显示响铃
set visualbell      "可视化铃声
set foldmarker={,}  "缩进符号
set foldmethod=indent   "缩进作为折叠标识
set foldlevel=100   "不自动折叠
set foldopen-=search    "秴¢时不打开折叠
set foldopen-=undo  "撤销时不打开折叠
set updatecount=0   "不使用交换文件
set magic           "使用正则时，除了$ . * ^以外的元字符都要加反斜线
"set paste          "paste 会导致缩进问题
colorscheme solarized
"缩进定义
set tabstop=4
set softtabstop=4
set shiftwidth=4
set autoindent
set smartindent
set smarttab
set backspace=2     "退格键可以删除任何东西
"显示TAB字符为<+++
set list
set list listchars=tab:<+
"映射常用操作
map [r :! python % <CR>
map [o :! python -i % <CR>
map [t :! rst2html.py % %<.html <CR>

if has("gui_running")
    set lines=25
    set columns=80
    set lazyredraw  "延迟重绘
    set guioptions-=m   "不显示菜单
    set guioptions-=T   "不显示工具栏
    set guifont=consolas\ 10
endif

filetype on
filetype plugin on
filetype indent on

if has("autocmd")
    "回到上次文件打开所在行
    au BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$")
        \| exe "normal g'\"" | endif
    "自动检测文件类型，并载入相关的规则文件
    filetype plugin on
    filetype indent on
    "智能缩进，使用4空格，使用全局的了
    autocmd FileType python setlocal et | setlocal sta | setlocal sw=4
endif

"Format the statusline
"Nice statusbar
set laststatus=2
set statusline=
set statusline+=%2*%-3.3n%0*\ " buffer number
set statusline+=%f\ " file name
set statusline+=%h%1*%m%r%w%0* " flag
set statusline+=[
if v:version >= 600
set statusline+=%{strlen(&ft)?&ft:'none'}, " filetype
set statusline+=%{&encoding}, " encoding
endif
set statusline+=%{&fileformat}] " file format
if filereadable(expand("$VIM/vimfiles/plugin/vimbuddy.vim"))
set statusline+=\ %{VimBuddy()} " vim buddy
endif
set statusline+=%= " right align
"set statusline+=%2*0x%-8B\ " current char
set statusline+=0x%-8B\ " current char
set statusline+=%-14.(%l,%c%V%)\ %<%P " offset 
