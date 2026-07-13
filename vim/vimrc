set nocompatible
set encoding=utf-8

" Keep the historical leader while making it explicit for every mapping file.
let mapleader = "\\"
let maplocalleader = "\\"

let s:vim_root = fnamemodify(resolve(expand('<sfile>:p')), ':h')
execute 'source' fnameescape(s:vim_root . '/config/paths.vim')
if !empty(globpath(&runtimepath, 'autoload/plug.vim'))
  execute 'source' fnameescape(s:vim_root . '/plugs.vim')
endif
execute 'source' fnameescape(s:vim_root . '/config/options.vim')
execute 'source' fnameescape(s:vim_root . '/config/filetypes.vim')
execute 'source' fnameescape(s:vim_root . '/config/plugins.vim')
execute 'source' fnameescape(s:vim_root . '/config/lsp.vim')
execute 'source' fnameescape(s:vim_root . '/config/keymaps.vim')
execute 'source' fnameescape(s:vim_root . '/config/autocmds.vim')
execute 'source' fnameescape(s:vim_root . '/config/gui.vim')
unlet s:vim_root
