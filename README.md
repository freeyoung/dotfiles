Eric's dotfiles
===============

One repository for shared Vim/Neovim, Zsh, Starship, tmux, and SSH
configuration.
Machine- and organisation-specific shell settings stay in
`~/.config/zsh/local.zsh`, outside Git.
Git follows the same pattern: shared defaults live in `git/config`, while
credentials and host-specific overrides stay in `~/.config/git/local.gitconfig`.
SSH defaults live in `ssh/config`; private hosts and per-machine overrides stay
in `~/.ssh/config.local`.

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
shared [`Brewfile`](Brewfile). A Linux host that already has Linuxbrew takes
the same path.

Without Homebrew, a Linux host is bootstrapped from its own package manager;
Arch (`pacman`) is mapped today, and other distributions still ask for
Linuxbrew. The native path also installs `zsh`, which macOS provides as the
login shell but Arch does not install by default, and clones
[antidote](https://github.com/mattmc3/antidote) into `~/.antidote` so no AUR
helper becomes a bootstrap dependency. Node is deliberately not installed:
mise provides the versions projects pin. Where mise itself is packaged under
another name — Omarchy and the AUR ship `mise-bin`, which conflicts with the
official `mise` — the installer detects it through `pacman -T` and leaves the
existing package alone.

Either way the installer verifies the GNU userland this configuration relies
on and stops if it is incomplete. macOS needs Homebrew's `gls`, `ggrep`,
`gsed`, and `gawk` because its own userland is BSD; on Linux the unprefixed
tools are accepted once their `--version` output confirms they are GNU builds
rather than BSD or busybox ones. The installer never changes the login shell.

Copy `zsh/local.zsh.example` to `~/.config/zsh/local.zsh` to add private
machine settings. The installer does this once automatically and preserves it
on later runs.

Shared Zsh settings are loaded in a deliberate order from `zsh/modules/`:
environment, runtimes, prompt, commands, completion, Node/tool integrations,
plugins, then interactive bindings. `zsh/zshrc` is only the interactive guard
and loader; keep machine-specific settings in `~/.config/zsh/local.zsh`.

### Language runtimes

[mise](https://mise.jdx.dev/) resolves every pinned runtime version, replacing
the per-language managers this configuration used before (pyenv,
pyenv-virtualenv, and fnm). [`mise/config.toml`](mise/config.toml) is linked to
`~/.config/mise/config.toml` and lists the tools every host gets; a
repository's own `mise.toml` takes precedence over it. One `mise activate` in
[`zsh/modules/runtimes.zsh`](zsh/modules/runtimes.zsh) covers all of them
through a single precmd hook, so the deferred-initialisation machinery those
tools needed — pyenv's own hook cost roughly 80 ms per shell — is gone.

mise reads its own `mise.toml` by default and ignores `.python-version`,
`.nvmrc`, and similar files unless the owning tools are named in
`MISE_IDIOMATIC_VERSION_FILE_ENABLE_TOOLS`; `runtimes.zsh` sets it to
`python,node`.

A project virtualenv replaces `pyenv-virtualenv` and is declared in the
project's `mise.toml`:

```toml
[tools]
python = "3.13"

[env]
_.python.venv = { path = ".venv", create = true }
```

mise creates the virtualenv on first entry and exports `VIRTUAL_ENV` and
`PATH`, leaving `PROMPT` untouched. With `uv` installed, setting
`python.uv_venv_auto` routes creation through it; without uv, mise falls back
to the standard library's `venv` silently.

Note that a `.python-version` naming a pyenv *virtualenv* rather than a
version — pyenv-virtualenv accepts both — has no mise equivalent. Replace those
files with a `mise.toml`; mise otherwise treats the name as a version string
and reports it as uninstalled.

On first run, an existing `~/.gitconfig` is moved to
`~/.config/git/local.gitconfig`, then replaced with a link to the shared Git
defaults. This keeps credential helpers and private URL rewrites out of Git.

[`git/ignore`](git/ignore) is linked to `~/.config/git/ignore`, which Git reads
with no `core.excludesFile` pointing at it. It holds only what is never worth
committing anywhere — Claude Code's `.claude/`, and the `.DS_Store` files that
arrive in repositories synced from a Mac. A pattern specific to one project
belongs in that project's `.gitignore`, where its other contributors can see
it.

Tools that write to `~/.gitconfig` directly do not know it is a link into this
repository, so their changes land in the shared file. `gh auth login` is the
one to watch: it writes a `credential.helper` naming the absolute path of the
`gh` binary it was run from, which is both machine-specific and wrong on any
other host. Check `git -C ~/dotfiles status` after running it, and move
anything it added to `~/.config/git/local.gitconfig`. Authenticating through
`GH_TOKEN` instead avoids the problem entirely.

The installer links [`ssh/config`](ssh/config) to `~/.ssh/config` and keeps
machine-specific settings in `~/.ssh/config.local`. On first installation, an
existing SSH config is copied there before the original is backed up; otherwise
it is created from `ssh/config.local.example`. The local file is loaded before
the shared `Host *` defaults and preserved on later runs. Installer-managed
regular files are kept at mode `600`; an existing symlink remains under the
user's control. Missing local include paths are ignored by OpenSSH.

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

### Shell commands

Beyond the aliases in [`zsh/modules/commands.zsh`](zsh/modules/commands.zsh),
a few helpers are worth calling out. Several were adapted from
[Omarchy](https://omarchy.org/), whose Bash configuration is where the ideas
came from; they are reimplemented here in Zsh and without its machine-specific
dependencies.

`ssh` is wrapped. A remote tmux, pager, or editor arms terminal modes over the
connection — mouse tracking, focus reporting, the alternate screen — that only
it can disarm. When the connection dies instead of exiting cleanly those modes
stay armed locally, and every mouse move then floods the prompt with escape
junk. The wrapper always disarms them, and reconnects when an *interactive*
session drops: exit status 255, a session that lasted at least 30 seconds, a
terminal on stdin, and no remote command. That last condition is checked
against `ssh -G`, so a `RemoteCommand` from `ssh_config` cannot have its side
effects replayed either. Ctrl-C stops the retry loop.

`fip host port...` forwards ports over SSH in the background, `dip port...`
stops them, and `lip` lists what is currently forwarded.

`gwa branch` creates a Git worktree as a sibling directory named
`<repo>--<branch>` and moves into it; `gwr` removes the worktree and its branch
from inside one, recovering the branch name from that directory name and
refusing to run anywhere else. They are not called `ga` and `gd` — `gd` is
already the abbreviation for `git diff`.

`man` renders through `bat` when it is installed, which colours the synopsis
and options.

`ff` picks a file with fzf and previews it with bat on the way — inline images
too, under Kitty. `eff` opens what it picked in `$EDITOR`, and `sff dest:/path`
copies it to a remote host, newest files first.

`ls` is rendered by `eza` where it is installed — colour-coded permission
bits, Git status, human sizes — but keeps GNU `ls`'s flags, because the same
hands type `ls` on servers that will never have eza, and a half-learned habit
is worse than none. Where the two disagree the GNU meaning wins: `-t` and `-S`
sort (eza reads `-t` as which timestamp to *show*, and sorts ascending where
`ls` puts newest and largest first), `-F` appends type indicators, and `-a`
lists `.` and `..` as eza's `-aa` does. `-r` reverses whatever sort is in
effect, so it composes with the rest — `-lt`, `-ltr`, and `-lrt` all order
exactly as GNU `ls` does. Without eza, `ls` is GNU `ls`.

One difference remains: eza collates byte-wise, so dotfiles sort ahead of
everything instead of under their letter. eza has no collation setting, and no
habit depends on it.

`e`, `ea`, `et`, and `eta` reach for eza's own flags directly, in long and
tree form, each with and without dotfiles.

`tdl <command> [second]` builds a tmux dev layout — editor left, the command
on the right, a shell along the bottom — `tdlm` opens one such window per
subdirectory, and `tsl <n> <command>` tiles the same command across n panes.
`hdl`, `hdlm`, and `hsl` are the same three layouts under
[herdr](https://github.com/herdrdev/herdr). All take the command as an argument
rather than hard-coding a particular editor or agent.

Every command in this group carries the guard that makes it safe on both
platforms. `open` and `iso2sd` are defined only on Linux: macOS has its own
`open(1)`, a full utility this one-line `xdg-open` wrapper would shadow, and
writing an image to a block device has no macOS counterpart.

### Fonts

[`fontconfig/fonts.conf`](fontconfig/fonts.conf) is linked to
`~/.config/fontconfig/fonts.conf` on Linux. macOS renders through Core Text,
so even where a Homebrew package pulls fontconfig in these rules would name
faces that host does not have; linking there would create the directory and
stand ready to displace a `fonts.conf` written for something else, for no
effect. Noto Sans CJK ships SC, TC, JP, KR and HK
under one family name, and left to itself fontconfig picks between them by
whatever the ordering leaves first — which is how Chinese ends up rendered in
Japanese glyph forms. These rules put the Simplified Chinese faces first for
Chinese, and each region's own face first for Japanese, Korean and Traditional
Chinese.

Chromium and Electron resolve a missing glyph one character at a time, on a
pattern carrying neither a family nor a language, so language rules never fire
for them. A weakly bound last-resort family covers that path; all three SC
faces are named, because a monospace pattern carries a spacing requirement the
proportional face cannot satisfy.

Everything here adds to the generic families rather than replacing them, so a
distribution that assigns its own faces to `sans-serif` and the rest keeps
them.

Fonts that exist only to cover the CJK extension blocks — BabelStone Han,
HanaMin — claim enough of Unicode besides that fontconfig will otherwise hand
them ordinary text and even emoji. The language they declare is reassigned so
they stay what they are for: a last resort for a codepoint nothing else has.

### tmux

[`tmux.conf`](tmux.conf) is linked to `~/.tmux.conf`. It enables true color,
mouse support, large scrollback, and system clipboard integration. Splits
preserve the current directory; `h/j/k/l` navigate panes and `prefix + r`
reloads the configuration. Ctrl-B stays the prefix, because that is what an
unconfigured tmux on a server answers to; Ctrl-Space is a secondary prefix.

tmux applies every configuration file it finds rather than stopping at the
first, in the order `/etc/tmux.conf`, `~/.tmux.conf`,
`$XDG_CONFIG_HOME/tmux/tmux.conf`. A file at the XDG path therefore does not
supplement this one -- it overrides every setting the two have in common.
Omarchy installs one, so the installer moves it into the backup directory.
What was worth keeping from it is here instead: the no-prefix Alt layer
(`Alt+Enter` to split, `Alt+1`..`Alt+9` for windows, `Ctrl+Alt+arrows` for
panes), the uppercase session controls, `prefix + ?` for the searchable
keybinding popup, and a note on every binding so `list-keys -N` reads as
documentation.

The status line names colors instead of giving hex values, so it follows
whatever palette the terminal is themed with -- Omarchy's theme switcher
repaints it for free, and a 16-color terminal on a server still renders it. It
shows the session on the left, and copy/prefix/zoom flags, host, date, and time
on the right, refreshed every second.

### Performance

* Files over 5MB (`g:vim_large_file_bytes` in `vim/config/autocmds.vim`) skip
  undo history and syntax highlighting on open.
* `synmaxcol=500` caps syntax scanning on very long lines (minified JS, data
  dumps).
* `NERDTree` and the filetype-specific syntax plugins
  (`vim-markdown`, `vim-javascript`, `html5.vim`, `vim-yaml`, `ansible-vim`)
  are lazy-loaded via vim-plug's `on`/`for`, not sourced at startup unless
  actually used.
* LSP diagnostics keep their signs and highlights quiet during Insert mode,
  then refresh when you return to Normal mode.
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

`vim-lsp` supplies diagnostics, navigation, completion, code actions, and
formatting. The configured servers are Pyright and Ruff (Python), gopls (Go),
TypeScript Language Server (JavaScript/TypeScript), YAML Language Server,
vscode-json-language-server (JSON/JSONC), and
ansible-language-server. Language servers are deliberately not bootstrap
dependencies: when a catalogued server is missing, opening its file type
suggests `:LspInstallServer`; run that command to download it. Ruff is used for
both Python diagnostics and formatting (`uv tool install ruff@latest`).

ansible-language-server is not in vim-lsp-settings' catalog. Opening an
Ansible buffer without it shows the corresponding on-demand command:
`npm install -g @ansible/ansible-language-server`.

`ansible-vim` detects Ansible YAML by path (`tasks/`, `roles/`, `handlers/`,
`group_vars/`, `host_vars/`) and by filename (`playbook.yml`, `site.yml`,
`main.yml`, etc.); a supplemental rule in `vim/config/filetypes.vim` also covers a
generic `playbooks/` directory with arbitrary filenames. It sets
`filetype=yaml.ansible` under Vim and plain `filetype=ansible` under Neovim
(ansible-vim's own upstream difference); both are handled everywhere they
matter (LSP allowlist, plugin lazy-loading).

### Completion

Completion functions live in [`zsh/completions/`](zsh/completions), which
`completion.zsh` puts on `fpath`. zsh autoloads each only when something asks
to complete the command it names, so an entry costs nothing at startup and
needs no guard for a command the host may not have.

`_omarchy` completes [Omarchy](https://omarchy.org/)'s dispatcher, which
Omarchy itself ships only for Bash. `omarchy a b` runs the `omarchy-a-b`
executable, so the command tree is read out of the names in its bin directory,
and the values after the last subcommand come from the `# omarchy:args=`
header each executable carries.

Completion lists take their filename colours from `LS_COLORS`, which
`completion.zsh` fills in through `dircolors` — nothing on Arch sets it
otherwise, and eza reads the same variable.

### Desktop and input

Three things here only make sense on a Linux desktop, so the installer guards
each on what actually reads it rather than on the platform alone.

These raise the cost of a branch switch inside this repository. Everything is
linked rather than copied, so a checkout that does not contain one of these
files leaves a dangling link where the live configuration used to be -- and
unlike a shell or editor file, that takes the keyboard layout, the touchpad,
and the input method down with it, on the desktop being used at the time.
Hyprland reports it as `hypr.input not found`. Keep the working tree on a
branch that has these files, or checkout them back afterwards:

```bash
git -C ~/dotfiles checkout master -- hypr fcitx5 mise xcompose
```

[`hypr/input.lua`](hypr/input.lua) and
[`hypr/looknfeel.lua`](hypr/looknfeel.lua) are linked into `~/.config/hypr/`
where a Hyprland binary exists. Omarchy loads these two after its own defaults
and after the theme, and says so in the `hyprland.lua` it ships -- they are the
files it sets aside for personal overrides, so it can keep improving its
defaults without this repository having to track them. `input.lua` maps
CapsLock to Escape, selects the `mac` variant so right Alt is Option and the
German umlauts sit where macOS puts them, moves Compose to right Ctrl (right
Alt being spoken for), and turns on natural scrolling and three-finger drag.
`looknfeel.lua` carries the border and gap settings ported from the old
`hyprland.conf`.

[`fcitx5/wubi-large.conf`](fcitx5/wubi-large.conf) is linked to
`~/.config/fcitx5/table/wubi-large.conf` where fcitx5 exists -- `table/`, not
`inputmethod/`, which registers the input method rather than configures it. It
sets four values and leaves the rest to fcitx5's defaults: a four-code
character that is the only match still waits for the space bar, a fifth
keystroke commits what is pending, and a phrase is learned after three uses
instead of ten. Changing any setting through fcitx5's configuration tool
rewrites the file in full -- the symlink survives, but every default is written
out explicitly and the comments are lost, so trim it back afterwards.

[`xcompose`](xcompose) is linked to `~/.XCompose` on Linux. It includes the
locale's own table, adds identification sequences, and vendors Omarchy's emoji
shortcuts so they work on a host without Omarchy.

### Tracking Omarchy

Several of the commands above came from
[Omarchy](https://omarchy.org/)'s own Bash configuration, which keeps growing.
[`omarchy/ledger.tsv`](omarchy/ledger.tsv) records the verdict on every alias,
function and export it defines — ported, renamed, or skipped with the reason —
and [`scripts/omarchy-review.sh`](scripts/omarchy-review.sh) subtracts that
ledger from what Omarchy currently ships:

```bash
bash ~/dotfiles/scripts/omarchy-review.sh
```

Run it after `omarchy update`. The output is only ever what is new, with the
line that defines it; add a row for each and the next run is quiet. The script
exits cleanly on a host without Omarchy.
