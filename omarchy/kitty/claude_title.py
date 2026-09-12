# Puts each Claude Code session's state into its kitty window's title, so that
# anything showing window titles shows it too. The one this is for is a
# Hyprland group: its tab bar draws nothing but each member's title, and every
# member is a separate kitty OS window. A working session reads "🟠 <title>",
# a session waiting on a prompt blinks "🔵 Bash? · <title>", a finished turn
# reads "🟢 <title>". The colours are emoji because a title is plain text:
# Hyprland draws group tabs in one colour for all of them. The motion while a
# session works is the ring quickshell/claude-rings draws around the tab, so
# the title itself stays still.
#
# kitty loads this through the watcher line in kitty.conf. The state itself
# comes from claude_status.py; this file only turns it into titles.
#
# The badge goes in as kitty's title override, the same slot `set-window-title`
# and the rename action use, so Claude's own title stays untouched underneath
# as the window's child title and comes back when the session ends. A title
# someone else put there is left alone for as long as it stays.

import os
import sys
from typing import Any

from kitty.boss import Boss, get_boss
from kitty.utils import sanitize_title
from kitty.window import Window

_here = os.path.dirname(os.path.realpath(__file__))
if _here not in sys.path:
    sys.path.insert(0, _here)
import claude_status as cs  # noqa: E402

# The override each window was last given here, as kitty stored it.
_ours: dict[int, str] = {}

_BADGES = tuple(cs.EMOJI.values()) + (cs.BLINK_OFF_EMOJI,)


def _badged(title: str) -> bool:
    # A title that starts with one of the badges was written by this watcher,
    # even when this copy of it did not write it: kitty saves the override into
    # a session and restores it, and a watcher loaded again starts with an
    # empty _ours. Treating those as someone's rename would freeze them.
    return title.startswith(_BADGES)


def compose(window: Window, record: dict[str, Any]) -> str:
    state = record.get('state')
    title = cs.display_title(window.child_title, record)
    if state == 'working':
        return f"{cs.EMOJI['working']} {title}"
    if state == 'waiting':
        dot = cs.EMOJI['waiting'] if cs.blink_on() else cs.BLINK_OFF_EMOJI
        ask = cs.waiting_ask(record)
        return f'{dot} {ask}? · {title}' if ask else f'{dot} {title}'
    return f"{cs.EMOJI['idle']} {title}"


def update_titles() -> None:
    records = cs.records()
    for wid, window in list(get_boss().window_id_map.items()):
        ours = _ours.get(wid)
        current = window.override_title
        if current is not None and current != ours and not _badged(current):
            # Renamed by hand or by another program: theirs wins until it is
            # cleared again.
            _ours.pop(wid, None)
            continue
        record = records.get(wid)
        if record is None:
            if ours is not None:
                _ours.pop(wid, None)
                window.set_title(None)
            continue
        title = compose(window, record)
        if sanitize_title(title) != current:
            window.set_title(title)
            if window.override_title is not None:
                _ours[wid] = window.override_title


def on_load(boss: Boss, data: dict[str, Any]) -> None:
    cs.listen('os_window_title', update_titles)


def on_close(boss: Boss, window: Window, data: dict[str, Any]) -> None:
    _ours.pop(window.id, None)
