" Keep generated Vim data outside the dotfiles checkout. Vim and Neovim share
" these paths so their vim-plug checkouts and persistent state are reusable.
if exists('g:dotfiles_vim_paths_loaded')
  finish
endif
let g:dotfiles_vim_paths_loaded = 1

let s:data_home = empty($XDG_DATA_HOME) ? expand('~/.local/share') : $XDG_DATA_HOME
let s:state_home = empty($XDG_STATE_HOME) ? expand('~/.local/state') : $XDG_STATE_HOME
let g:dotfiles_vim_data_dir = s:data_home . '/vim'
let g:dotfiles_vim_state_dir = s:state_home . '/vim'

call mkdir(g:dotfiles_vim_data_dir, 'p')
call mkdir(g:dotfiles_vim_state_dir, 'p')
execute 'set runtimepath^=' . fnameescape(g:dotfiles_vim_data_dir)

unlet s:data_home s:state_home
