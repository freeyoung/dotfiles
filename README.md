Not only .vimrc ...
===================
... but also:
* oh-my-zsh
* tmux.conf

## Installation

* Clone this repo

``` bash
git clone https://github.com/freeyoung/dotfiles.git ~/.vim
```

* Execute the bootstrap script

``` bash
bash ~/.vim/init.sh
```

The fzf mappings require the external `fzf` and `rg` (ripgrep) commands. On
macOS, install them with `brew install fzf ripgrep`; on other systems use the
equivalent package-manager packages. The Vim plugins provide integration but
do not silently install these system dependencies.

The script creates timestamped backups before replacing conflicting dotfiles,
keeps an existing `~/.oh-my-zsh` directory, and does not change your login shell.
It prints the `chsh` command if you want to make zsh your login shell.

Run the non-interactive configuration check after installation (this is a
configuration smoke test; it does not install language servers):

```bash
bash ~/.vim/scripts/check-vim-config.sh
```

Plugin revisions are recorded in [`plugins.lock.vim`](plugins.lock.vim), and
`init.sh` restores that snapshot during bootstrap. After updating plugins
intentionally, regenerate it from the repository directory with:

```vim
:PlugSnapshot! ~/.vim/plugins.lock.vim
```

Commit the resulting change. Sourcing the snapshot runs vim-plug's pinned
`PlugUpdate!`, so it may access the network and change plugin checkouts.

## Features

### Vim and Neovim

Both editors share one configuration: `~/.vimrc` and `~/.config/nvim/init.vim`
(the latter symlinked by `init.sh` to [`nvim_init.vim`](nvim_init.vim)) both
source `vimrc`. `nvim_init.vim` extends `runtimepath` to this repo first,
since Neovim's default runtimepath doesn't include `~/.vim`. A handful of
`has('nvim')` branches account for real differences between the two (Neovim
dropped the `paste`/`pastetoggle` options, so paste toggling is an explicit
`<F12>` mapping instead; some vim-airline extensions auto-enable under
Neovim regardless of whether their backing library is present and are
explicitly disabled in `config/plugins.vim`). Neovim is optional — `init.sh`
links its config the same way regardless of whether `nvim` is installed.

The configuration is split into `config/` by responsibility: options, file
types, plugin settings, LSP, mappings, autocmds, and terminal settings.

### Colorscheme

[`freeyoung/vim-tomorrow-theme`](https://github.com/freeyoung/vim-tomorrow-theme)
(`Tomorrow-Night-Bright`) is the active default, a fork of
[`chriskempson/vim-tomorrow-theme`](https://github.com/chriskempson/vim-tomorrow-theme)
with two fixes upstream never made:

* The color-setting logic was gated only on the legacy `&t_Co`, which Vim and
  Neovim can report differently, so Vim silently kept `Normal` unset while
  Neovim applied the theme correctly. The fork also checks `&termguicolors`,
  so both editors render identically (verified by diffing `:highlight`
  output directly) without a global `set t_Co=256` workaround.
* The original shipped no airline theme at all, falling back to
  `vim-airline-themes`' generic `tomorrow.vim`, which — like most
  community-contributed airline themes — has no dedicated commandline-mode
  palette and silently reuses Normal's colors. The fork adds
  `autoload/airline/themes/tomorrow_bright.vim` with full mode coverage,
  including commandline, using the same hex values as the colorscheme
  itself.

```vim
:colorscheme Tomorrow-Night-Bright | :AirlineTheme tomorrow_bright
```

Several other colorschemes (sonokai, onedark.vim, edge, everforest,
gruvbox-material, catppuccin, papercolor-theme, ayu-vim, base16-tomorrow-night
via tinted-vim) were evaluated and rejected along the way — mainly for
missing airline commandline coverage, being Neovim/Lua-only (breaks the
shared-config setup), or, for base16, having `Identifier` equal `Normal`
(no color distinction for YAML/Ansible keys). See git history on
`config/plugins.vim` and `plugs.vim` for the full trail.

### Performance

* Files over 5MB (`g:vim_large_file_bytes` in `config/autocmds.vim`) skip
  undo history and syntax highlighting on open.
* `synmaxcol=500` caps syntax scanning on very long lines (minified JS, data
  dumps).
* `NERDTree`, `fzf.vim`, and the filetype-specific syntax plugins
  (`vim-markdown`, `vim-javascript`, `html5.vim`, `vim-yaml`, `ansible-vim`)
  are lazy-loaded via vim-plug's `on`/`for`, not sourced at startup unless
  actually used.
* ALE only re-lints on normal-mode edits and leaving insert mode
  (`g:ale_lint_on_text_changed`), not on every keystroke.
* `%`-matching comes from Vim's bundled `matchit` package (`packadd!` in
  `config/filetypes.vim`) instead of a vim-plug-managed checkout.

## Key mappings

The leader is explicitly set to `\`.

| Keys | Mode | Action |
| --- | --- | --- |
| `F1`, `\w` | Normal | Save the current file |
| `F2`, `Ctrl-Q` | Normal | Quit the current window |
| `F3` | Normal | Save and quit |
| `F5`, `Ctrl-N` | Normal | Toggle NERDTree |
| `F11` / `F12` | Normal | Toggle paste mode |
| `Ctrl-H/J/K/L` | Normal | Move between split windows |
| `Shift-H/L` | Normal | Previous / next tab |
| `\+`, `\-`, `\_`, `\=`, `\[`, `\]` | Normal | Resize / equalize splits |
| `\ew`, `\es`, `\ev`, `\et` | Normal | Open a path relative to the current file |
| `\ff` | Normal | Find identifiers matching the word under the cursor |
| `\sf`, `\sb`, `\sr`, `\sg` | Normal | fzf files, buffers, history, ripgrep search |
| `gd`, `gD`, `gr`, `gi`, `K` | Normal | LSP definition, declaration, references, implementation, hover |
| `\rn`, `\ca`, `\f` | Normal | LSP rename / code action / manual format |
| `Tab`, `Shift-Tab`, `Enter`, `Ctrl-Space` | Insert | Select, accept, or manually trigger LSP completion |
| `<` / `>` | Visual | Indent while keeping the selection |

`j` and `k` move by screen line when wrapping is enabled. `config/keymaps.vim`
contains general mappings; `config/lsp.vim` contains LSP and formatting mappings.
`\f` formats Python with Ruff and formats other supported buffers through LSP. It
never formats automatically on save.

NERDTree remains available through `F5` / `Ctrl-N` as a directory-oriented view;
fzf handles quick selection and search. `termguicolors` is enabled when supported.

### Language tooling

ALE is the sole diagnostics provider; LSP supplies navigation, completion, code
actions, and formatting. The configured servers are Pyright (Python), gopls
(Go), TypeScript Language Server (JavaScript/TypeScript), YAML Language
Server, and ansible-language-server. Install npm-managed servers with
`:LspInstallServer`; install gopls, Ruff, and ansible-language-server
separately (ansible-language-server isn't in vim-lsp-settings' catalog, so
it's registered directly in `config/lsp.vim` and only activates when the
binary is on `$PATH`: `npm install -g @ansible/ansible-language-server`).
Ruff is used for Python formatting (`uv tool install ruff@latest`).

`ansible-vim` detects Ansible YAML by path (`tasks/`, `roles/`, `handlers/`,
`group_vars/`, `host_vars/`) and by filename (`playbook.yml`, `site.yml`,
`main.yml`, etc.); a supplemental rule in `config/filetypes.vim` also covers a
generic `playbooks/` directory with arbitrary filenames. It sets
`filetype=yaml.ansible` under Vim and plain `filetype=ansible` under Neovim
(ansible-vim's own upstream difference); both are handled everywhere they
matter (LSP allowlist, plugin lazy-loading).

### oh-my-zsh

### tmux

## References

* [humiaozuzu/dot-vimrc](https://github.com/humiaozuzu/dot-vimrc)
* [klen/python-mode](https://github.com/klen/python-mode)
* [spf13/spf13-vim](https://github.com/spf13/spf13-vim)
* [grml/grml-zsh-config](http://git.grml.org/f/grml-etc-core/etc/zsh/zshrc)
