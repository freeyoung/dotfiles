#!/usr/bin/env bash

set -euo pipefail

# kitty reads its configuration once, at startup, and a file it cannot parse
# does not degrade to defaults: it replaces the window with an error screen.
# That makes a broken kitty.conf worse than most config mistakes here, because
# the terminal is where the mistake would otherwise be noticed and fixed.
#
# The failure this exists for arrived from a commit that looked obviously safe.
# globinclude was chosen over include so a host without Omarchy would skip the
# theme rather than error, but the pattern given was ~-prefixed, and globinclude
# takes relative patterns only -- so the line raised at parse time in every new
# window, on every host, which is the opposite of what it was reaching for.
# Nothing in the bootstrap noticed, because nothing here had ever asked kitty
# what it thought of the file.
#
# Asking kitty is the whole check. Its own loader is the only thing that agrees
# with kitty in every case, and it runs headless: no display is needed to parse
# a file.

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# A configuration rewritten in place stops being this repository's without
# saying so, the way `sed -i` does it. Nothing touches kitty's this way today,
# but the same check costs nothing.
live="$HOME/.config/kitty/kitty.conf"
if [[ -e $live && ! -L $live ]]; then
  echo "$live is a file, not a link into this repository." >&2
  echo "Keep whatever changed it, then run ./install to link it again." >&2
  exit 1
fi
config="$repo_dir/kitty/kitty.conf"

if [[ ! -f "$config" ]]; then
  echo "No kitty/kitty.conf to check." >&2
  exit 1
fi

if ! command -v kitty >/dev/null 2>&1; then
  echo "kitty is not installed, so its configuration was not checked."
  exit 0
fi

# A relative include is resolved against the directory holding the config file,
# which in a checkout is this repository rather than a home directory, so the
# theme pattern matches nothing here. That is the case globinclude is for and
# it loads silently, which is what makes this safe to run anywhere; the check is
# that the file parses, not that the theme was found.
kitty +runpy "
from kitty.config import load_config
load_config('$config')
"

echo "kitty parsed $config."

# The custom tab bar is Python that kitty runs inside itself, and a file it
# cannot load falls back to kitty's fade style with one line in a log nobody
# reads. Running it under kitty's own interpreter catches a syntax error or a
# renamed kitty internal before a new window does. Only the load is checked;
# drawing needs a running kitty.
# The watcher is loaded the same way and fails the same quiet way. Both import
# claude_status.py by name from the directory they live in, which is what a
# missing or renamed module would break.
tab_bar="$repo_dir/omarchy/kitty/tab_bar.py"
watcher="$repo_dir/omarchy/kitty/claude_title.py"
if [[ -f "$tab_bar" && -f "$watcher" ]]; then
  kitty +runpy "
import runpy
module = runpy.run_path('$tab_bar')
assert callable(module.get('draw_tab')), 'tab_bar.py defines no draw_tab'
module = runpy.run_path('$watcher')
assert callable(module.get('on_load')), 'claude_title.py defines no on_load'
"
  echo "kitty loaded $tab_bar and $watcher."
fi

# The smart selection rules kitty.conf names, on every host. They need only the
# standard library, so any kitty can load them, and a sample line must get a mark
# for each rule.
hints="$repo_dir/kitty/smart_hints.py"
kitty +runpy "
import runpy
module = runpy.run_path('$hints')
text = 'git@github.com:owner/repo.git ssh://git@example.com:22/owner/repo owner/repo#12'
urls = [m[4]['url'] for m in module['mark'](text, None, lambda *m: m, None)]
assert urls == ['https://github.com/owner/repo', 'https://example.com/owner/repo', 'https://github.com/owner/repo/issues/12'], urls
"
echo "kitty loaded $hints."

# The settings those two files need, which kitty.conf pulls in by glob on an
# Omarchy host only. Parsed on its own, since the glob matches nothing here.
fragment="$repo_dir/omarchy/kitty/claude-status.conf"
if [[ -f "$fragment" ]]; then
  kitty +runpy "
from kitty.config import load_config
opts = load_config('$fragment')
assert opts.tab_bar_style == 'custom', opts.tab_bar_style
assert 'claude_title.py' in opts.watcher, opts.watcher
"
  echo "kitty parsed $fragment."
fi

# The macOS layer, which kitty.conf pulls in by glob on macOS only. Its includes
# name files in its own directory, so parsing it in place also parses them.
# kitty skips an option it does not know with a warning, so a Linux kitty older
# than the Mac one still parses the file.
# The Python files of the macOS layer. They import kitty internals that a Linux
# kitty from apt can lack, so they are only compiled here, and each is checked
# for the function kitty calls by name. On a Mac they are also loaded, under the
# kitty they are written for.
macos_dir="$repo_dir/macos/kitty"
if [[ -d "$macos_dir" ]]; then
  kitty +runpy "
import ast, pathlib
wanted = {
    'tab_bar.py': 'draw_tab',
    'window_title_bar.py': 'draw_window_title',
    'iterm2_watcher.py': 'on_focus_change',
    'tmux_or_kitty.py': 'handle_result',
    'toggle_transparency.py': 'handle_result',
    'cc_status.py': 'main',
}
root = pathlib.Path('$macos_dir')
for name, function in wanted.items():
    tree = ast.parse((root / name).read_text(), filename=name)
    defined = {node.name for node in tree.body if isinstance(node, ast.FunctionDef)}
    assert function in defined, f'{name} defines no {function}'
"
  echo "kitty compiled the Python files in $macos_dir."

  if [[ $(uname -s) == Darwin ]]; then
    kitty +runpy "
import runpy
for name in ('tab_bar.py', 'window_title_bar.py', 'iterm2_watcher.py', 'tmux_or_kitty.py', 'toggle_transparency.py'):
    runpy.run_path('$macos_dir/' + name)
"
    echo "kitty loaded the Python files in $macos_dir."
  fi
fi

# The macOS configuration is written for the kitty on that Mac, which is newer
# than the one apt ships. An unknown option is only a warning, but a value a
# kitty does not know is a parse error -- `placement_strategy top` needs 0.35 --
# so an older kitty is asked to skip the file. What it would report is its age.
macos_minimum=0.35.0
kitty_version="$(kitty --version | awk '{print $2}')"
macos_config="$macos_dir/macos.conf"
if [[ ! -f "$macos_config" ]]; then
  :
elif [[ "$(printf '%s\n' "$macos_minimum" "$kitty_version" | sort -V | head -1)" != "$macos_minimum" ]]; then
  echo "kitty $kitty_version is older than $macos_minimum, so $macos_config was not parsed."
else
  kitty +runpy "
from kitty.config import load_config
opts = load_config('$macos_config')
assert opts.tab_bar_style == 'custom', opts.tab_bar_style
assert 'iterm2_watcher.py' in opts.watcher, opts.watcher
"
  echo "kitty parsed $macos_config."
fi
