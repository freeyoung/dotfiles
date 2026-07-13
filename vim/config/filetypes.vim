" Detect file types, load their plugins, and enable indentation rules.
filetype plugin indent on
" Turn on syntax highlighting.
syntax enable

" Vim ships a newer, actively maintained matchit than vim-scripts/matchit.zip.
" Enable % matching for HTML tags and other paired constructs.
packadd! matchit

" Treat these HTML tags as indentation containers.
let g:html_indent_inctags = 'html,body,head,tbody'
" Use the included indentation rules inside script blocks.
let g:html_indent_script1 = 'inc'
" Use the included indentation rules inside style blocks.
let g:html_indent_style1 = 'inc'

augroup vim_filetype_settings
  autocmd!
  " Use two-space indentation with four-column tab stops for web languages.
  autocmd FileType html,htmldjango,xhtml,haml,sass,scss,ruby,javascript,php,css setlocal tabstop=4 shiftwidth=2 softtabstop=2
  " Use two-space indentation for data and template files.
  autocmd FileType json,eruby,yaml setlocal tabstop=2 shiftwidth=2 softtabstop=0
  " Keep Python paragraphs unwrapped while allowing normal line wrapping.
  autocmd FileType python setlocal textwidth=0 wrap
  " Use Vim's CSS-aware completion function.
  autocmd FileType css setlocal omnifunc=csscomplete#CompleteCSS
  " Use built-in tag completion for HTML and Markdown.
  autocmd FileType html,markdown setlocal omnifunc=htmlcomplete#CompleteTags
  " Use built-in JavaScript completion.
  autocmd FileType javascript setlocal omnifunc=javascriptcomplete#CompleteJS
  " Use built-in Python completion when LSP completion is unavailable.
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
