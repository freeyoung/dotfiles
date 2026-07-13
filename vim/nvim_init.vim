" Neovim entry point: reuse the same vimscript config as ~/.vimrc. Neovim's
" default runtimepath doesn't include ~/.vim, so add it before sourcing.
let s:vim_root = fnamemodify(resolve(expand('<sfile>:p')), ':h')
execute 'set runtimepath^=' . fnameescape(s:vim_root)
execute 'source' fnameescape(s:vim_root . '/vimrc')
