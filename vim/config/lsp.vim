" Keep diagnostics in the LSP stack: signs and a current-line message are
" useful, while suppressing updates in Insert mode avoids visual churn while
" typing. Inline virtual text remains off to keep diagnostics unobtrusive.
let g:lsp_diagnostics_enabled = 1
let g:lsp_diagnostics_echo_cursor = 1
let g:lsp_diagnostics_signs_insert_mode_enabled = 0
let g:lsp_diagnostics_highlights_insert_mode_enabled = 0
let g:lsp_diagnostics_virtual_text_enabled = 0
let g:lsp_document_highlight_enabled = 0
let g:lsp_settings_filetype_python = ['pyright-langserver', 'ruff']
let g:lsp_settings_filetype_go = ['gopls']
let g:lsp_settings_filetype_typescript = ['typescript-language-server']
let g:lsp_settings_filetype_javascript = ['typescript-language-server']
let g:lsp_settings_filetype_typescriptreact = ['typescript-language-server']
let g:lsp_settings_filetype_javascriptreact = ['typescript-language-server']
let g:lsp_settings_filetype_yaml = ['yaml-language-server']

" The upstream default skips JS/TS unless a node_modules directory is found.
" Enable the server for standalone JS/TS files as well. Deno projects should use
" their dedicated LSP configuration instead of this TypeScript server.
let g:lsp_settings = {
      \ 'typescript-language-server': {
      \   'blocklist': [],
      \ },
      \}

" ansible-language-server isn't in vim-lsp-settings' catalog, so register it
" directly. ansible-vim sets ft=yaml.ansible under Vim but plain ft=ansible
" under Neovim; allowlist both. It stays on-demand rather than becoming a
" bootstrap dependency: opening an Ansible buffer explains how to install it.
if executable('ansible-language-server')
  autocmd User lsp_setup call lsp#register_server({
        \ 'name': 'ansible-language-server',
        \ 'cmd': {server_info -> ['ansible-language-server', '--stdio']},
        \ 'allowlist': ['yaml.ansible', 'ansible'],
        \ })
else
  augroup dotfiles_missing_ansible_language_server
    autocmd!
    autocmd FileType yaml.ansible,ansible echohl WarningMsg | echom
          \ 'Install ansible-language-server with: npm install -g @ansible/ansible-language-server' | echohl None
  augroup END
endif

function! s:format_with_ruff() abort
  if !executable('ruff')
    echoerr 'Ruff is not installed or is not on PATH.'
    return
  endif

  let l:filename = expand('%:p')
  if empty(l:filename)
    echoerr 'Save this Python buffer before formatting with Ruff.'
    return
  endif

  let l:result = systemlist(
        \ 'ruff format --stdin-filename ' . shellescape(l:filename) . ' -',
        \ getline(1, '$'))
  if v:shell_error != 0
    echoerr 'Ruff formatting failed: ' . join(l:result, "\n")
    return
  endif

  let l:view = winsaveview()
  call setline(1, empty(l:result) ? [''] : l:result)
  if line('$') > len(l:result)
    execute (len(l:result) + 1) . ',$delete _'
  endif
  call winrestview(l:view)
  echom 'Formatted with Ruff.'
endfunction

function! s:format_buffer() abort
  if &filetype ==# 'python'
    call s:format_with_ruff()
    return
  endif

  for l:server in lsp#get_allowed_servers(bufnr('%'))
    if lsp#capabilities#has_document_formatting_provider(l:server)
      LspDocumentFormatSync
      return
    endif
  endfor

  echoerr 'No document formatter is available for this buffer.'
endfunction

" LSP navigation and actions (Normal mode).
" gd / gD / gr / gi / K: Definition / declaration / references / implementation / docs.
nnoremap <silent> gd :LspDefinition<CR>
nnoremap <silent> gD :LspDeclaration<CR>
nnoremap <silent> gr :LspReferences<CR>
nnoremap <silent> gi :LspImplementation<CR>
nnoremap <silent> K :LspHover<CR>
" \rn / \ca / \f: Rename symbol / show code actions / format buffer.
nnoremap <silent> <leader>rn :LspRename<CR>
nnoremap <silent> <leader>ca :LspCodeAction<CR>
nnoremap <silent> <leader>f :<C-U>call <SID>format_buffer()<CR>

" Completion menu controls in Insert mode; otherwise retain normal Tab/Enter.
" Tab / Shift-Tab: next / previous item; Enter: accept; Ctrl-Space: request.
inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
inoremap <expr> <CR> pumvisible() ? asyncomplete#close_popup() : "\<CR>"
inoremap <C-Space> <Plug>(asyncomplete_force_refresh)
