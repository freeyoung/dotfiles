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
sh ~/.vim/init.sh
```

The script creates timestamped backups before replacing conflicting dotfiles,
keeps an existing `~/.oh-my-zsh` directory, and does not change your login shell.
It prints the `chsh` command if you want to make zsh your login shell.

## Features

* Need to be described in detail ..

### vim

The Vim configuration is split into `config/` by responsibility: options,
file types, plugin settings, LSP, mappings, autocmds, and GUI/terminal settings.

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
| `gd`, `gD`, `gr`, `gi`, `K` | Normal | LSP definition, declaration, references, implementation, hover |
| `\rn`, `\ca`, `\f` | Normal | LSP rename / code action / manual format |
| `Tab`, `Shift-Tab`, `Enter`, `Ctrl-Space` | Insert | Select, accept, or manually trigger LSP completion |
| `<` / `>` | Visual | Indent while keeping the selection |

`j` and `k` move by screen line when wrapping is enabled. `config/keymaps.vim`
contains general mappings; `config/lsp.vim` contains LSP and formatting mappings.
`\f` formats Python with Ruff and formats other supported buffers through LSP. It
never formats automatically on save.

### Language tooling

ALE is the sole diagnostics provider; LSP supplies navigation, completion, code
actions, and formatting. The configured servers are Pyright (Python), gopls
(Go), TypeScript Language Server (JavaScript/TypeScript), and YAML Language
Server. Install npm-managed servers with `:LspInstallServer`; install gopls and
Ruff separately. Ruff is used for Python formatting (`uv tool install ruff@latest`).
The legacy YAPF Vim plugin has been replaced; run `:PlugClean` after updating
plugins to remove its local checkout.

### oh-my-zsh

### tmux

## References

* [humiaozuzu/dot-vimrc](https://github.com/humiaozuzu/dot-vimrc)
* [klen/python-mode](https://github.com/klen/python-mode)
* [spf13/spf13-vim](https://github.com/spf13/spf13-vim)
* [grml/grml-zsh-config](http://git.grml.org/f/grml-etc-core/etc/zsh/zshrc)
