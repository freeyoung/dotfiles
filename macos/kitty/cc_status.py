"""Claude Code hook for kitty: a port of iTerm2 3.7's cc-status.

It reads the hook event JSON on stdin and stores the session status on the
kitty window as user vars, which tab_bar.py shows as a colored dot:

  cc_status    idle | working | waiting
  cc_dot       dot color, same values as iTerm2
  cc_text      status text color, same values as iTerm2
  cc_detail    detail text, for example "Allow Bash: make test?"
  cc_bg_tasks  number of background tasks still running

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

# The permission text is shared with the Omarchy hook. This file is a link into the
# dotfiles repository, and the shared module is at claude/ in the repository.
sys.path.insert(0, os.path.join(os.path.dirname(os.path.realpath(__file__)), '..', '..', 'claude'))
from permission_detail import MAX_DETAIL, one_line, permission_detail  # noqa: E402

IDLE = ('idle', '#00d75f', '#888888')
WORKING = ('working', '#ff9500', '#ff9500')
WAITING = ('waiting', '#5f87ff', '#5f87ff')
VARS = ('cc_status', 'cc_dot', 'cc_text', 'cc_detail', 'cc_bg_tasks')
def kitten() -> list[str]:
    exe = shutil.which('kitten') or '/Applications/kitty.app/Contents/MacOS/kitten'
    return [exe, '@', '--to', os.environ['KITTY_LISTEN_ON'], 'set-user-vars', '--match', f"id:{os.environ['KITTY_WINDOW_ID']}"]


def background_text(count: int) -> str:
    return '1 background task running' if count == 1 else f'{count} background tasks running'


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


def set_vars(status: tuple[str, str, str] | None, detail: str | None = None, bg_tasks: int | None = None) -> None:
    if status is None:
        args = list(VARS)  # names alone unset the vars
    else:
        name, dot, text = status
        args = [f'cc_status={name}', f'cc_dot={dot}', f'cc_text={text}']
        if detail is not None:
            args.append(f'cc_detail={detail}')
        if bg_tasks is not None:
            args.append(f'cc_bg_tasks={bg_tasks}')
    try:
        r = subprocess.run(kitten() + args, capture_output=True, text=True, timeout=2)
        if r.returncode:
            print(f'cc-status: kitten exited {r.returncode}: {r.stderr.strip()}', file=sys.stderr)
    except (OSError, subprocess.SubprocessError) as e:
        print(f'cc-status: failed to run kitten: {e}', file=sys.stderr)


def idle_or_background(detail_when_idle: str = '') -> None:
    count = stored_bg_tasks()
    if count > 0:
        set_vars(WORKING, background_text(count))
    else:
        set_vars(IDLE, detail_when_idle)


def main() -> None:
    try:
        event = json.load(sys.stdin)
    except ValueError:
        return
    name = event.get('hook_event_name', '')
    # Only the main conversation changes the status. A hook that fires inside an agent has
    # agent_id, and an agent can run after the turn ends: Claude runs one to write the
    # "while you were away" recap. If its hooks set working, nothing sets idle again.
    # An agent that the conversation starts needs nothing here, because the Agent tool
    # call that starts it already sets working.
    if name in ('SubagentStart', 'SubagentStop') or event.get('agent_id'):
        return
    if name == 'SessionStart':
        set_vars(IDLE, '', 0)
    elif name in ('UserPromptSubmit', 'PreToolUse', 'PostToolUse', 'PostToolUseFailure', 'PermissionDenied'):
        set_vars(WORKING, '')
    elif name == 'PermissionRequest':
        set_vars(WAITING, permission_detail(event.get('tool_name', ''), event.get('tool_input') or {}))
    elif name == 'Elicitation':
        # An MCP server asks the user for input.
        set_vars(WAITING, one_line(event.get('title') or event.get('server_name') or '', MAX_DETAIL))
    elif name == 'Notification':
        kind = event.get('notification_type', '')
        if kind == 'permission_prompt':
            set_vars(WAITING)
        elif kind == 'idle_prompt':
            idle_or_background()
        else:
            message = event.get('message')
            set_vars(WAITING, one_line(message, MAX_DETAIL) if message else None)
    elif name == 'Stop':
        tasks = event.get('background_tasks')
        count = len(tasks) if isinstance(tasks, list) else None
        if count:
            set_vars(WORKING, background_text(count), count)
        else:
            set_vars(IDLE, one_line(event.get('last_assistant_message', ''), MAX_DETAIL), count)
    elif name == 'StopFailure':
        idle_or_background()
    elif name == 'SessionEnd':
        set_vars(None)


if __name__ == '__main__':
    main()
