"""Claude Code hook for kitty: a port of iTerm2 3.7's cc-status.

It reads the hook event JSON on stdin and stores the session status on the
kitty window as user vars, which tab_bar.py shows as a colored dot:

  cc_status    idle | working | waiting
  cc_bg_tasks  number of background tasks still running, which iTerm2 counts
               as working; this is the only place the count survives between
               the events that carry it

The event rules match iTerm2's cc-status, found by replaying every event
through it. The differences, most of them learned from the Omarchy hook
(bin/claude-tab-status):
- SessionEnd removes the vars instead of setting idle, so a pane does not keep
  a dot after Claude Code exits.
- Hooks that fire inside an agent do not change the status.
- PostToolUseFailure and PermissionDenied set working, and Elicitation sets waiting.
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

VARS = ('cc_status', 'cc_bg_tasks')


def kitten() -> list[str]:
    exe = shutil.which('kitten') or '/Applications/kitty.app/Contents/MacOS/kitten'
    return [exe, '@', '--to', os.environ['KITTY_LISTEN_ON'], 'set-user-vars', '--match', f"id:{os.environ['KITTY_WINDOW_ID']}"]


def stored_bg_tasks() -> int:
    try:
        out = subprocess.run(kitten(), capture_output=True, text=True, timeout=2).stdout
    except (OSError, subprocess.SubprocessError):
        return 0
    for line in out.splitlines():
        key, _, value = line.partition('=')
        if key == 'cc_bg_tasks' and value.isdigit():
            return int(value)
    return 0


def set_vars(status: str | None, bg_tasks: int | None = None) -> None:
    if status is None:
        args = list(VARS)  # names alone unset the vars
    else:
        args = [f'cc_status={status}']
        if bg_tasks is not None:
            args.append(f'cc_bg_tasks={bg_tasks}')
    try:
        r = subprocess.run(kitten() + args, capture_output=True, text=True, timeout=2)
        if r.returncode:
            print(f'cc-status: kitten exited {r.returncode}: {r.stderr.strip()}', file=sys.stderr)
    except (OSError, subprocess.SubprocessError) as e:
        print(f'cc-status: failed to run kitten: {e}', file=sys.stderr)


def idle_or_background() -> None:
    # iTerm2 shows a session with background tasks as working, not idle.
    set_vars(WORKING if stored_bg_tasks() > 0 else IDLE)


def main() -> None:
    try:
        event = json.load(sys.stdin)
    except ValueError:
        return
    name = event.get('hook_event_name', '')
    # Which state the event asks for is the same question in every terminal, so
    # claude/session_state.py answers it. What a state looks like is kitty's own.
    state, _ = classify(event)
    if state is None:
        return
    if state == END:
        set_vars(None)
    elif name == 'SessionStart':
        set_vars(IDLE, 0)
    elif state in (WORKING, WAITING):
        set_vars(state)
    elif name == 'Stop':
        # The background task count is only in this event, so it is stored for
        # the events after it.
        tasks = event.get('background_tasks')
        count = len(tasks) if isinstance(tasks, list) else None
        set_vars(WORKING if count else IDLE, count)
    else:
        idle_or_background()


if __name__ == '__main__':
    main()
