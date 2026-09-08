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
