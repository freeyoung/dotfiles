"""Claude Code hook for kitty: a port of iTerm2 3.7's cc-status.

It reads the hook event JSON on stdin and stores the session status on the
kitty window as user vars, which tab_bar.py shows as a colored dot:

  cc_status    idle | working | waiting

The event rules match iTerm2's cc-status, found by replaying every event
through it. The differences, most of them learned from the Omarchy hook
(bin/claude-tab-status):
- SessionEnd removes the vars instead of setting idle, so a pane does not keep
  a dot after Claude Code exits.
- Hooks that fire inside an agent do not change the status.
- PostToolUseFailure and PermissionDenied set working, and Elicitation sets waiting.
- A session that stops is idle even when it leaves background tasks running, as
  the Ghostty hook has it. iTerm2 counts those tasks as working, which leaves a
  pane looking busy when the model is waiting for the next thing to be said.
"""
import json
import os
import shutil
import subprocess
import sys

# Which state an event asks for is shared with the Ghostty hook. This file is a
# link into the dotfiles repository, and the shared module is at claude/ there.
sys.path.insert(0, os.path.join(os.path.dirname(os.path.realpath(__file__)), '..', '..', 'claude'))
from session_state import END, IDLE, WAITING, WORKING, classify  # noqa: E402

VARS = ('cc_status',)


def kitten() -> list[str]:
    exe = shutil.which('kitten') or '/Applications/kitty.app/Contents/MacOS/kitten'
    return [exe, '@', '--to', os.environ['KITTY_LISTEN_ON'], 'set-user-vars', '--match', f"id:{os.environ['KITTY_WINDOW_ID']}"]


def set_vars(status: str | None) -> None:
    if status is None:
        args = list(VARS)  # names alone unset the vars
    else:
        args = [f'cc_status={status}']
    try:
        r = subprocess.run(kitten() + args, capture_output=True, text=True, timeout=2)
        if r.returncode:
            print(f'cc-status: kitten exited {r.returncode}: {r.stderr.strip()}', file=sys.stderr)
    except (OSError, subprocess.SubprocessError) as e:
        print(f'cc-status: failed to run kitten: {e}', file=sys.stderr)


def main() -> None:
    try:
        event = json.load(sys.stdin)
    except ValueError:
        return
    # Which state the event asks for is the same question in every terminal, so
    # claude/session_state.py answers it. What a state looks like is kitty's own.
    state, _ = classify(event)
    if state is None:
        return
    if state == END:
        set_vars(None)
    else:
        set_vars(state)


if __name__ == '__main__':
    main()
