#!/usr/bin/env bash

# Register bin/claude-tab-status with Claude Code, event by event, in
# ~/.claude/settings.json. That file is Claude's, not this repository's: it
# also holds the model choice, permissions and whatever else the user set from
# inside Claude, so it is merged into rather than linked. Only the hook entries
# named in omarchy/claude/hooks.json are touched, and an entry that is already
# is left alone, so running this again changes nothing.
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
hooks="$repo_dir/omarchy/claude/hooks.json"
settings="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json"

# Omarchy only. Nothing off it reads the records this hook writes, and every
# Claude install has its own settings file: a Mac sharing this repository has
# hooks of its own there, which this has no business adding to. Guarded here as
# well as in `install`, so running this script by hand on such a host is a no-op
# rather than a surprise.
if [[ ! -d "$HOME/.config/omarchy" ]] && ! command -v omarchy >/dev/null 2>&1; then
  printf 'Not an Omarchy host; skipped Claude Code hook registration.\n'
  exit 0
fi

if ! command -v jq >/dev/null 2>&1; then
  printf 'Warning: jq is unavailable; skipped Claude Code hook registration.\n' >&2
  exit 0
fi

mkdir -p "$(dirname "$settings")"
[[ -s $settings ]] || printf '{}\n' >"$settings"

# For each event in hooks.json, append its hook groups to the same event in
# settings.json unless a group with the same command is already registered
# there. Everything else in settings.json passes through untouched.
merged=$(jq --slurpfile add "$hooks" '
  .hooks = ((.hooks // {}) as $have
    | reduce ($add[0].hooks | to_entries[]) as $event ($have;
        .[$event.key] = ((.[$event.key] // []) as $groups
          | $groups + [$event.value[]
              | select(.hooks[0].command as $cmd
                       | ($groups | map(.hooks[]?.command) | index($cmd)) == null)])))
' "$settings")

if [[ $merged == "$(cat "$settings")" ]]; then
  printf 'Claude Code hooks already registered: %s\n' "$settings"
  exit 0
fi

cp "$settings" "$settings.bak.$(date +%s)"
printf '%s\n' "$merged" >"$settings.new"
mv "$settings.new" "$settings"
printf 'Registered Claude Code hooks in %s\n' "$settings"
