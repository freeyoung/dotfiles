" Keep generated Vim data outside the dotfiles checkout. Plugin data is shared,
" but persistent state is per editor: Vim and Neovim undo files are not always
" compatible with each other.
if exists('g:dotfiles_vim_paths_loaded')
  " Avoid reinitializing shared paths when the entry point is sourced twice.
  finish
endif
" Mark path initialization complete.
let g:dotfiles_vim_paths_loaded = 1

" Use XDG data/state roots, with ~/.local fallbacks on macOS and Linux.
let s:data_home = empty($XDG_DATA_HOME) ? expand('~/.local/share') : $XDG_DATA_HOME
let s:state_home = empty($XDG_STATE_HOME) ? expand('~/.local/state') : $XDG_STATE_HOME
" Keep plugin/runtime files in the editor-specific data directory.
let g:dotfiles_vim_data_dir = s:data_home . '/vim'
" Separate Vim and Neovim state because undo formats are not always compatible.
let g:dotfiles_vim_state_dir = s:state_home . '/' . (has('nvim') ? 'nvim' : 'vim')

" Create the directories before options.vim configures them.
call mkdir(g:dotfiles_vim_data_dir, 'p')
call mkdir(g:dotfiles_vim_state_dir, 'p')
" Make shared plugin/runtime files discoverable.
execute 'set runtimepath^=' . fnameescape(g:dotfiles_vim_data_dir)

unlet s:data_home s:state_home
