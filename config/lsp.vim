" ALE remains the diagnostics provider to avoid duplicate signs and messages.
let g:lsp_diagnostics_enabled = 0
let g:lsp_document_highlight_enabled = 0
let g:lsp_settings_filetype_python = ['pyright-langserver']
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

nnoremap <silent> gd :LspDefinition<CR>
nnoremap <silent> gD :LspDeclaration<CR>
nnoremap <silent> gr :LspReferences<CR>
nnoremap <silent> gi :LspImplementation<CR>
nnoremap <silent> K :LspHover<CR>
nnoremap <silent> <leader>rn :LspRename<CR>
nnoremap <silent> <leader>ca :LspCodeAction<CR>
nnoremap <silent> <leader>f :<C-U>call <SID>format_buffer()<CR>

inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
inoremap <expr> <CR> pumvisible() ? asyncomplete#close_popup() : "\<CR>"
inoremap <C-Space> <Plug>(asyncomplete_force_refresh)
