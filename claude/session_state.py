"""Which state a Claude Code hook event puts a session in.

The states and the rules are iTerm2 3.7's, from the cc-status hook it ships,
found by replaying every event through it, with 3 events added from the Omarchy
hook (bin/claude-tab-status). 2 hooks share this:

  macos/kitty/cc_status.py    stores the state on the kitty pane as user vars
  macos/ghostty/cc-status     marks the Ghostty pane through its palette

The caller decides what a state looks like. This only reads the event.
"""
import sys

IDLE = 'idle'
WORKING = 'working'
WAITING = 'waiting'
END = 'end'  # the session is over: remove the state

sys.path.insert(0, __file__.rsplit('/', 1)[0])
from permission_detail import MAX_DETAIL, one_line, permission_detail  # noqa: E402


def classify(event: dict) -> tuple[str | None, str | None]:
    """The (state, detail) an event asks for.

    A state of None means the event changes nothing. A detail of None means the
    detail of the state before it stays, which is how a permission prompt keeps
    its question when the notification for it arrives.
    """
    name = event.get('hook_event_name', '')
    # Only the main conversation changes the state. A hook that fires inside an agent has
    # agent_id, and an agent can run after the turn ends: Claude runs one to write the
    # "while you were away" recap. If its hooks set working, nothing sets idle again.
    # An agent that the conversation starts needs nothing here, because the Agent tool
    # call that starts it already sets working.
    if name in ('SubagentStart', 'SubagentStop') or event.get('agent_id'):
        return None, None
    if name == 'SessionStart':
        return IDLE, ''
    if name in ('UserPromptSubmit', 'PreToolUse', 'PostToolUse', 'PostToolUseFailure', 'PermissionDenied'):
        return WORKING, ''
    if name == 'PermissionRequest':
        return WAITING, permission_detail(event.get('tool_name', ''), event.get('tool_input') or {})
    if name == 'Elicitation':
        # An MCP server asks the user for input.
        return WAITING, one_line(event.get('title') or event.get('server_name') or '', MAX_DETAIL)
    if name == 'Notification':
        kind = event.get('notification_type', '')
        if kind == 'permission_prompt':
            return WAITING, None
        if kind == 'idle_prompt':
            return IDLE, ''
        message = event.get('message')
        return WAITING, one_line(message, MAX_DETAIL) if message else None
    if name == 'Stop':
        return IDLE, one_line(event.get('last_assistant_message', ''), MAX_DETAIL)
    if name == 'StopFailure':
        return IDLE, ''
    if name == 'SessionEnd':
        return END, None
    return None, None
