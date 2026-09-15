"""The question a Claude Code permission prompt asks, as 1 line of text.

For example "Allow Bash: make test?" or "Allow Read: ~/notes.md?". The wording
follows iTerm2 3.7's cc-status hook, found by replaying events through it.

2 hooks use it:
  macos/kitty/cc_status.py imports it, and kitty shows the text on macOS.
  bin/claude-tab-status runs it as a script, and the Omarchy bar shows the text.

As a script, it reads a PermissionRequest hook event on stdin and prints the text.
"""
import json
import re
import sys
from urllib.parse import urlsplit

MAX_DETAIL = 180
MAX_VALUE = 174

FILE_TOOLS = {'Read': 'file_path', 'Edit': 'file_path', 'Write': 'file_path', 'MultiEdit': 'file_path', 'NotebookEdit': 'notebook_path'}
TEXT_TOOLS = {'Bash': 'command', 'Glob': 'pattern', 'WebSearch': 'query', 'Agent': 'description', 'Task': 'description'}


def one_line(text: object, limit: int) -> str:
    s = ' '.join(str(text or '').split())
    return s if len(s) <= limit else s[:limit - 1].rstrip() + '…'


def spaced(name: str) -> str:
    return re.sub(r'(?<=[a-z])(?=[A-Z])', ' ', name)


def permission_detail(tool: str, args: dict) -> str:
    if tool == 'ExitPlanMode':
        return 'Review proposed plan?'
    if tool == 'AskUserQuestion':
        questions = [q.get('question', '') for q in args.get('questions') or [] if isinstance(q, dict)]
        text = one_line(' '.join(q for q in questions if q), MAX_DETAIL)
        return text or f'Allow {spaced(tool)}?'
    if tool.startswith('mcp__'):
        server, _, name = tool[len('mcp__'):].partition('__')
        return f'Allow {server}/{name}?' if name else f'Allow {server}?'
    if tool == 'Grep':
        pattern, path = args.get('pattern', ''), args.get('path', '')
        return f'Allow Grep “{one_line(pattern, MAX_VALUE)}”' + (f' in {one_line(path, MAX_VALUE)}?' if path else '?')
    if tool == 'WebFetch':
        parts = urlsplit(str(args.get('url', '')))
        segment = next((p for p in parts.path.split('/') if p), '')
        value = (parts.hostname or '') + (f'/{segment}' if segment else '')
    elif tool in FILE_TOOLS:
        path = str(args.get(FILE_TOOLS[tool], ''))
        value = path if len(path) <= MAX_VALUE else '…' + path[-(MAX_VALUE - 1):]
    elif tool in TEXT_TOOLS:
        value = one_line(args.get(TEXT_TOOLS[tool], ''), MAX_VALUE)
    else:
        return f'Allow {spaced(tool)}?'
    return f'Allow {tool}:' + (f' {value}' if value else '') + '?'


if __name__ == '__main__':
    try:
        event = json.load(sys.stdin)
    except ValueError:
        sys.exit(1)
    args = event.get('tool_input')
    print(permission_detail(str(event.get('tool_name') or ''), args if isinstance(args, dict) else {}))
