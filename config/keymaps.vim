" Toggle paste mode. Neovim has no 'pastetoggle' option (E519), so map it
" directly instead; this also works identically in Vim. Mostly moot on
" terminals with bracketed-paste support, which avoid the autoindent-mangled
" paste problem without needing 'paste' at all.
nnoremap <F12> :set paste!<CR>
inoremap <F12> <C-o>:set paste!<CR>

" Files and windows
nnoremap <F11> <F12>
nnoremap <F5> :NERDTreeToggle<CR>
nnoremap <C-N> <F5>
nnoremap <leader>w :write<CR>
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-h> <C-w>h
nnoremap <C-l> <C-w>l
nnoremap <S-H> gT
nnoremap <S-L> gt
nnoremap <leader>+ <C-w>+
nnoremap <leader>- <C-w>-
nnoremap <leader>_ <C-w>_
nnoremap <leader>= <C-w>=
nnoremap <leader>[ <C-w><
nnoremap <leader>] <C-w>>

" Move through screen lines when wrapping is enabled.
nnoremap j gj
nnoremap k gk

" Function-key shortcuts. Do not override <C-W>, <C-I>, or <C-X>.
nnoremap <F1> :write<CR>
inoremap <F1> <Esc>:write<CR>a
nnoremap <F2> :quit<CR>
inoremap <F2> <Esc>:quit<CR>
nnoremap <C-Q> :quit<CR>
inoremap <C-Q> <Esc>:quit<CR>
nnoremap <F3> :xit<CR>
inoremap <F3> <Esc>:xit<CR>

" Command-line conveniences
cnoremap w!! w !sudo tee > /dev/null %
cnoremap Tabe tabe
cnoremap cwd lcd %:p:h
cnoremap cd. lcd %:p:h
cnoremap %% <C-R>=expand('%:h').'/'<CR>

" File-opening shortcuts
nnoremap <leader>ew :e %%
nnoremap <leader>es :sp %%
nnoremap <leader>ev :vsp %%
nnoremap <leader>et :tabe %%
nnoremap <leader>ff [I:let nr = input('Which one: ')<Bar>exe 'normal ' . nr . '[\t'<CR>

" fzf navigation. Keep \ff for the historical identifier lookup.
nnoremap <silent> <leader>sf :Files<CR>
nnoremap <silent> <leader>sb :Buffers<CR>
nnoremap <silent> <leader>sr :History<CR>
if executable('rg')
  nnoremap <silent> <leader>sg :Rg<Space>
else
  nnoremap <silent> <leader>sg :echoerr 'ripgrep (rg) is not installed.'<CR>
endif

" Preserve visual selection when indenting.
vnoremap < <gv
vnoremap > >gv

" Numeric keypad in insert mode
inoremap <Esc>Oq 1
inoremap <Esc>Or 2
inoremap <Esc>Os 3
inoremap <Esc>Ot 4
inoremap <Esc>Ou 5
inoremap <Esc>Ov 6
inoremap <Esc>Ow 7
inoremap <Esc>Ox 8
inoremap <Esc>Oy 9
inoremap <Esc>Op 0
inoremap <Esc>On .
inoremap <Esc>OQ /
inoremap <Esc>OR *
inoremap <Esc>Ol +
inoremap <Esc>OS -
inoremap <Esc>OM <Enter>

if has('gui_running')
  nnoremap <D-M-Left> :tabprevious<CR>
  nnoremap <D-M-Right> :tabnext<CR>
  nnoremap <D-1> 1gt
  nnoremap <D-2> 2gt
  nnoremap <D-3> 3gt
  nnoremap <D-4> 4gt
  nnoremap <D-5> 5gt
  nnoremap <D-6> 6gt
  nnoremap <D-7> 7gt
  nnoremap <D-8> 8gt
  nnoremap <D-9> 9gt
  nnoremap <D-0> :tablast<CR>
endif
