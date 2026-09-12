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
