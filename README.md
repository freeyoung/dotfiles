Eric's dotfiles
===============

One repository for shared Vim/Neovim, Zsh, Starship, and tmux configuration.
Machine- and organisation-specific shell settings stay in
`~/.config/zsh/local.zsh`, outside Git.
Git follows the same pattern: shared defaults live in `git/config`, while
credentials and host-specific overrides stay in `~/.config/git/local.gitconfig`.

## Installation

```bash
git clone git@github.com:freeyoung/dotfiles.git ~/dotfiles
bash ~/dotfiles/install
exec zsh
```

`install` is idempotent and networked by default. It installs the shared
command-line dependencies, creates symlinks, restores shell/Vim plugins, and
backs up any conflicting target under `~/.dotfiles-backups/<timestamp>/`.

Use `bash ~/dotfiles/install --links-only` when only links and local
configuration should be refreshed, or `--skip-plugins` when dependencies are
welcome but plugin downloads should wait.

The script links `~/.vim` to `vim/` for compatibility with existing Vim
tooling. Plugin files are shared under `~/.local/share/vim`, while persistent
state is separate under `~/.local/state/vim` and `~/.local/state/nvim` (or
their XDG equivalents).

On macOS, the installer installs Homebrew when necessary and applies the
shared [`Brewfile`](Brewfile). Linuxbrew uses the same path. On native Linux,
APT, DNF, and Pacman get a best-effort baseline (`zsh`, Git, curl, Vim, tmux,
fzf, ripgrep, and available `bat`/`zoxide`/`starship` packages); Linuxbrew is
the full, pinned-tooling path. The installer never changes the login shell.

Copy `zsh/local.zsh.example` to `~/.config/zsh/local.zsh` to add private
machine settings. The installer does this once automatically and preserves it
on later runs.

Shared Zsh settings are loaded in a deliberate order from `zsh/modules/`:
environment, runtimes, commands, completion, Node/tool integrations, prompt,
plugins, then interactive bindings. `zsh/zshrc` is only the interactive guard
and loader; keep machine-specific settings in `~/.config/zsh/local.zsh`.

On first run, an existing `~/.gitconfig` is moved to
`~/.config/git/local.gitconfig`, then replaced with a link to the shared Git
defaults. This keeps credential helpers and private URL rewrites out of Git.

Run the non-interactive Vim smoke test after installation:

```bash
bash ~/dotfiles/scripts/check-vim-config.sh
```

Vim plugin revisions are recorded in [`vim/plugins.lock.vim`](vim/plugins.lock.vim),
which the default installer restores after downloading vim-plug. After
updating plugins intentionally, regenerate the snapshot from the repository
directory with:

```vim
:PlugSnapshot! ~/.vim/plugins.lock.vim
```

Commit the resulting change. Restoring the snapshot accesses the network and
checks out the pinned revisions.

## Features

### Vim and Neovim

Both editors share one configuration: `~/.vimrc` and `~/.config/nvim/init.vim`
(the latter symlinked by `install` to [`vim/nvim_init.vim`](vim/nvim_init.vim)) both
source [`vim/vimrc`](vim/vimrc). `nvim_init.vim` extends `runtimepath` to the
Vim configuration directory first,
since Neovim's default runtimepath doesn't include `~/.vim`. A handful of
`has('nvim')` branches account for real differences between the two (Neovim
dropped the `pastetoggle` option, so paste toggling is an explicit
`<F12>` mapping instead; some vim-airline extensions auto-enable under
Neovim regardless of whether their backing library is present and are
explicitly disabled in `vim/config/plugins.vim`). Neovim is optional — `install`
links its config the same way regardless of whether `nvim` is installed.

The configuration is split into `vim/config/` by responsibility: options, file
types, plugin settings, LSP, mappings, autocmds, and terminal settings.

### Colorscheme

[`freeyoung/vim-tomorrow-theme`](https://github.com/freeyoung/vim-tomorrow-theme)
(`Tomorrow-Night-Bright`) is the active default, a fork of
[`chriskempson/vim-tomorrow-theme`](https://github.com/chriskempson/vim-tomorrow-theme)
with fixes upstream never made:

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
  including commandline (orange, not Replace's red — less alarming for
  routine `:` commands), using the same hex values as the colorscheme
  itself.
* The colorscheme's own `StatusLine`/`StatusLineNC` used a `"reverse"`
  attribute (a 2013-era convention predating airline-style per-segment
  statuslines). Neovim's TUI leaks that into the *entire* statusline row as
  unconditional reverse video — including airline's own segment colors and
  the separator colors airline computes by reading back already-applied
  group colors — which Vim does not replicate. sonokai's colorscheme, by
  contrast, never puts `"reverse"` on `StatusLine` at all, which is why
  sonokai-based setups never hit this. Fixed at the source (dropped
  `"reverse"`, colors swapped to preserve the exact original look without
  depending on it) and defended in `vim/config/plugins.vim` (`has('nvim')` only:
  clears `StatusLine`/`StatusLineNC`'s reverse attribute on every
  `ColorScheme` event, in case some other theme has the same issue).
  Verified via raw PTY capture, not just `:highlight` introspection — the
  highlight definitions looked correct in isolation even when the actual
  rendering wasn't.

```vim
:colorscheme Tomorrow-Night-Bright | :AirlineTheme tomorrow_bright
```

Several other colorschemes (sonokai, onedark.vim, edge, everforest,
gruvbox-material, catppuccin, papercolor-theme, ayu-vim, base16-tomorrow-night
via tinted-vim) were evaluated and rejected along the way — mainly for
missing airline commandline coverage, being Neovim/Lua-only (breaks the
shared-config setup), or, for base16, having `Identifier` equal `Normal`
(no color distinction for YAML/Ansible keys). See git history on
`vim/config/plugins.vim` and `vim/plugs.vim` for the full trail.

### Performance

* Files over 5MB (`g:vim_large_file_bytes` in `vim/config/autocmds.vim`) skip
  undo history and syntax highlighting on open.
* `synmaxcol=500` caps syntax scanning on very long lines (minified JS, data
  dumps).
* `NERDTree` and the filetype-specific syntax plugins
  (`vim-markdown`, `vim-javascript`, `html5.vim`, `vim-yaml`, `ansible-vim`)
  are lazy-loaded via vim-plug's `on`/`for`, not sourced at startup unless
  actually used.
* ALE only re-lints on normal-mode edits and leaving insert mode
  (`g:ale_lint_on_text_changed`), not on every keystroke.
* `%`-matching comes from Vim's bundled `matchit` package (`packadd!` in
  `vim/config/filetypes.vim`) instead of a vim-plug-managed checkout.

## Key mappings

The leader is explicitly set to `\`.

| Keys | Mode | Action |
| --- | --- | --- |
| `F1`, `\w` | Normal / Insert | Save the current file |
| `F2`, `Ctrl-Q` | Normal / Insert | Quit the current window |
| `F3` | Normal / Insert | Save and quit |
| `F5` | Normal | Toggle NERDTree |
| `F12` | Normal / Insert | Toggle paste mode |
| `Ctrl-H/J/K/L` | Normal | Move between split windows |
| `Shift-H/L` | Normal | Previous / next tab |
| `\+`, `\-`, `\_`, `\=`, `\[`, `\]` | Normal | Resize / equalize splits |
| `gd`, `gD`, `gr`, `gi`, `K` | Normal | LSP definition, declaration, references, implementation, hover |
| `\rn`, `\ca`, `\f` | Normal | LSP rename / code action / manual format |
| `Tab`, `Shift-Tab`, `Enter`, `Ctrl-Space` | Insert | Select, accept, or manually trigger LSP completion |
| `:w!!` | Command-line | Write the current buffer through sudo |

`j` and `k` move by screen line when wrapping is enabled. `vim/config/keymaps.vim`
contains general mappings; `vim/config/lsp.vim` contains LSP and formatting mappings.
`\f` formats Python with Ruff and formats other supported buffers through LSP. It
never formats automatically on save.

NERDTree remains available through `F5` as a directory-oriented view.
`termguicolors` is enabled when supported.

### Language tooling

ALE is the sole diagnostics provider; LSP supplies navigation, completion, code
actions, and formatting. The configured servers are Pyright (Python), gopls
(Go), TypeScript Language Server (JavaScript/TypeScript), YAML Language
Server, and ansible-language-server. Install npm-managed servers with
`:LspInstallServer`; install gopls, Ruff, and ansible-language-server
separately (ansible-language-server isn't in vim-lsp-settings' catalog, so
it's registered directly in `vim/config/lsp.vim` and only activates when the
binary is on `$PATH`: `npm install -g @ansible/ansible-language-server`).
Ruff is used for Python formatting (`uv tool install ruff@latest`).

`ansible-vim` detects Ansible YAML by path (`tasks/`, `roles/`, `handlers/`,
`group_vars/`, `host_vars/`) and by filename (`playbook.yml`, `site.yml`,
`main.yml`, etc.); a supplemental rule in `vim/config/filetypes.vim` also covers a
generic `playbooks/` directory with arbitrary filenames. It sets
`filetype=yaml.ansible` under Vim and plain `filetype=ansible` under Neovim
(ansible-vim's own upstream difference); both are handled everywhere they
matter (LSP allowlist, plugin lazy-loading).
