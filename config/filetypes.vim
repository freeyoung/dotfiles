filetype plugin indent on
syntax enable

" Vim ships a newer, actively maintained matchit than vim-scripts/matchit.zip.
packadd! matchit

let g:html_indent_inctags = 'html,body,head,tbody'
let g:html_indent_script1 = 'inc'
let g:html_indent_style1 = 'inc'

augroup vim_filetype_settings
  autocmd!
  autocmd FileType html,htmldjango,xhtml,haml,sass,scss,ruby,javascript,php,css setlocal tabstop=4 shiftwidth=2 softtabstop=2
  autocmd FileType json,eruby,yaml setlocal tabstop=2 shiftwidth=2 softtabstop=0
  autocmd FileType python setlocal textwidth=0 wrap
  autocmd FileType css setlocal omnifunc=csscomplete#CompleteCSS
  autocmd FileType html,markdown setlocal omnifunc=htmlcomplete#CompleteTags
  autocmd FileType javascript setlocal omnifunc=javascriptcomplete#CompleteJS
  autocmd FileType python setlocal omnifunc=pythoncomplete#Complete
augroup END

" ansible-vim's own ftdetect covers tasks/roles/handlers/ paths and
" group_vars/host_vars, plus playbook.yml-style filenames, but not a generic
" playbooks/ directory with arbitrary filenames. It sets ft=yaml.ansible under
" Vim but plain ft=ansible under Neovim; match that per editor.
augroup vim_ansible_playbooks_dir
  autocmd!
  autocmd BufNewFile,BufRead */playbooks/*.yml,*/playbooks/*.yaml
        \ execute 'set filetype=' . (has('nvim') ? 'ansible' : 'yaml.ansible')
augroup END
