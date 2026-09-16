#!/usr/bin/env bash

set -euo pipefail

# Ghostty reads its configuration once, at startup, and reports a bad line in a
# window of its own rather than falling back to defaults, so a typo here costs
# the same as one in kitty.conf. Its own loader is asked, the same way
# check-kitty-config.sh asks kitty's.
#
# The config names a theme and a shader by name, and Ghostty looks for both
# under its configuration directory. In a checkout they are not there yet, so
# the check builds a configuration directory in a temporary place and points
# Ghostty at it: what is checked is that the files in this repository work
# together, not that this host has installed them.

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
config_dir="$repo_dir/ghostty"

if [[ ! -f "$config_dir/config" ]]; then
  echo "No macos/ghostty/config to check." >&2
  exit 1
fi

# The hook and what it shares with kitty's. Python is everywhere this runs, and
# a syntax error or a renamed name would only show up when Claude next fired a
# hook, which is silent.
python3 - "$repo_dir" <<'PY'
import sys
repo = sys.argv[1]
sys.path.insert(0, f'{repo}/claude')
from session_state import END, IDLE, WAITING, WORKING, classify
cases = [
    ({'hook_event_name': 'SessionStart'}, IDLE),
    ({'hook_event_name': 'PreToolUse'}, WORKING),
    ({'hook_event_name': 'PreToolUse', 'agent_id': 'a'}, None),
    ({'hook_event_name': 'PermissionRequest', 'tool_name': 'Bash', 'tool_input': {'command': 'make test'}}, WAITING),
    ({'hook_event_name': 'SessionEnd'}, END),
]
for event, wanted in cases:
    state, _ = classify(event)
    assert state == wanted, f'{event} gave {state}, wanted {wanted}'
detail = classify(cases[3][0])[1]
assert detail == 'Allow Bash: make test?', detail
import ast
ast.parse(open(f'{repo}/ghostty/cc-status').read())
print('The Claude Code hook and claude/session_state.py are in order.')
PY

if ! command -v ghostty >/dev/null 2>&1 && [[ -x /Applications/Ghostty.app/Contents/MacOS/ghostty ]]; then
  ghostty() { /Applications/Ghostty.app/Contents/MacOS/ghostty "$@"; }
elif ! command -v ghostty >/dev/null 2>&1; then
  echo "Ghostty is not installed, so its configuration was not checked."
  exit 0
fi

tmp_home="$(mktemp -d)"
trap 'rm -rf "$tmp_home"' EXIT
mkdir -p "$tmp_home/ghostty/themes"
cp "$config_dir/config" "$tmp_home/ghostty/"
cp "$config_dir/themes/My iTerm2" "$tmp_home/ghostty/themes/"

# The shared config pulls in whichever of these is beside it. Each is checked
# on its own, and then with the shared one, because a desktop only ever has 1.
for overlay in "$repo_dir/macos/ghostty/macos.conf" "$repo_dir/omarchy/ghostty/linux.conf"; do
  name="$(basename "$overlay")"
  rm -f "$tmp_home/ghostty/macos.conf" "$tmp_home/ghostty/linux.conf"
  cp "$overlay" "$tmp_home/ghostty/$name"
  XDG_CONFIG_HOME="$tmp_home" ghostty +validate-config --config-file="$tmp_home/ghostty/config"
  echo "Ghostty parsed the shared config with $name."
done
