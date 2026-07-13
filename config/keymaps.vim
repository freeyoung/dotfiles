" Keymap overview (leader is \):
"   Save: <C-W> (Normal/Insert), <F1>, \w
"   Quit: <F2> or <C-Q>; save and quit: <F3>
"   Files: <F5>/<C-N> file tree; \sf/\sb/\sr/\sg fzf pickers
"   Windows: <C-H/J/K/L> switch; \+/-/_/=/[/] resize
"   Tabs: <S-H>/<S-L> previous/next; GUI: <Cmd-Opt-Left/Right>, <Cmd-1..0>
"   LSP mappings (gd, gr, \rn, \ca, \f, etc.) live in config/lsp.vim.

" Toggle paste mode. Neovim has no 'pastetoggle' option (E519), so map it
" directly instead; this also works identically in Vim. Mostly moot on
" terminals with bracketed-paste support, which avoid the autoindent-mangled
" paste problem without needing 'paste' at all.
nnoremap <F12> :set paste!<CR>
inoremap <F12> <C-o>:set paste!<CR>

" Files, splits, and tabs
" F5: Toggle file tree.
nnoremap <F5> :NERDTreeToggle<CR>
" \w: Save.
nnoremap <leader>w :write<CR>

" Intentionally replaces Vim's window-command prefix in Normal mode and
" delete-previous-word in Insert mode. Visual mode keeps its native <C-W>.
" <nowait> consumes this deliberate single-key mapping immediately, instead of
" waiting for longer <C-W>... mappings. <Cmd> bypasses command-line mode.
" Ctrl-W: Save in Normal mode.
nnoremap <nowait> <silent> <C-W> <Cmd>write<CR>
" Ctrl-W: Save in Insert mode, keeping Insert mode active.
inoremap <nowait> <silent> <C-W> <C-O><Cmd>write<CR>

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

" Function-key shortcuts. Do not override <C-I> or <C-X>.
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
" :w!! writes through sudo; :Tabe accepts a capitalized spelling.
cnoremap w!! w !sudo tee > /dev/null %
cnoremap Tabe tabe
" :cwd and :cd. change the local cwd to the current file's directory.
cnoremap cwd lcd %:p:h
cnoremap cd. lcd %:p:h
" %% inserts the current file's directory on the command line.
cnoremap %% <C-R>=expand('%:h').'/'<CR>

" Open a path relative to the current file's directory.
" \ew / \es / \ev / \et: Open relative to the current file, respectively in
" the current window, a horizontal split, a vertical split, or a new tab.
nnoremap <leader>ew :e %%
nnoremap <leader>es :sp %%
nnoremap <leader>ev :vsp %%
nnoremap <leader>et :tabe %%
" \ff: Identifier lookup.
nnoremap <leader>ff [I:let nr = input('Which one: ')<Bar>exe 'normal ' . nr . '[\t'<CR>

" fzf navigation. Keep \ff for the historical identifier lookup above.
" \sf / \sb / \sr: Find files / switch buffers / open recent files.
nnoremap <silent> <leader>sf :Files<CR>
nnoremap <silent> <leader>sb :Buffers<CR>
nnoremap <silent> <leader>sr :History<CR>
if executable('rg')
  " \sg: Search project text with ripgrep.
  nnoremap <silent> <leader>sg :Rg<Space>
else
  nnoremap <silent> <leader>sg :echoerr 'ripgrep (rg) is not installed.'<CR>
endif

" In Visual mode, < and > indent/unindent while keeping the selection active.
vnoremap < <gv
vnoremap > >gv

" Numeric keypad escape sequences in Insert mode (for terminals that emit
" application-keypad sequences rather than literal digits).
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
  " macOS GUI: Cmd-Option-Left/Right cycles tabs; Cmd-1..0 jumps to tabs.
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
