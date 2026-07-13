" Keymap overview (leader is \):
"   Save:       <F1>, \w
"   Quit:       <F2> or <C-Q>; save and quit with <F3>
"   Paste mode: <F12>
"   File tree:  <F5>
"   Windows:    <C-H/J/K/L> switch; \+/-/_/=/[/] resize
"   Tabs:       <S-H>/<S-L> previous/next
"   LSP:        gd, gr, \rn, \ca, \f (see config/lsp.vim)

" Paste mode
" F12: Toggle Vim's paste mode in Normal or Insert mode.
nnoremap <F12> :set paste!<CR>
inoremap <F12> <C-o>:set paste!<CR>

" Files
" F5: Toggle file tree.
nnoremap <F5> :NERDTreeToggle<CR>

" Saving
" \w: Save.
nnoremap <leader>w :write<CR>

" Windows and tabs
" Ctrl-H/J/K/L: Focus left/below/above/right split.
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-h> <C-w>h
nnoremap <C-l> <C-w>l
" Shift-H / Shift-L: Previous / next tab.
nnoremap <S-H> gT
nnoremap <S-L> gt
" \+ / \- / \_ / \= / \[ / \]: Resize the active split.
nnoremap <leader>+ <C-w>+
nnoremap <leader>- <C-w>-
nnoremap <leader>_ <C-w>_
nnoremap <leader>= <C-w>=
nnoremap <leader>[ <C-w><
nnoremap <leader>] <C-w>>

" Move through screen lines when wrapping is enabled.
nnoremap j gj
nnoremap k gk

" Save and quit
" F1: Save. In Insert mode, resume inserting afterwards.
nnoremap <F1> :write<CR>
inoremap <F1> <Esc>:write<CR>a
" F2 / Ctrl-Q: Quit the current window.
nnoremap <F2> :quit<CR>
inoremap <F2> <Esc>:quit<CR>
nnoremap <C-Q> :quit<CR>
inoremap <C-Q> <Esc>:quit<CR>
" F3: Save if changed, then quit.
nnoremap <F3> :xit<CR>
inoremap <F3> <Esc>:xit<CR>

" Command-line conveniences (apply while typing a : command)
" :w!! writes the current buffer through sudo.
cnoremap w!! w !sudo tee > /dev/null %
