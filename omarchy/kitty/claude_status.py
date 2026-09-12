# What each Claude Code session in this kitty is doing, shared by the two
# things that show it: tab_bar.py, which draws kitty's own tab bar, and
# claude_title.py, which puts the same state into the OS window title so a
# Hyprland group's tab bar shows it too.
#
# The states come from the records bin/claude-tab-status writes, one per
# session. This module only reads them. Both consumers import it by name
# rather than through runpy, so kitty holds one copy: one directory scan and
# one timer however many things are watching. A change to this file therefore
# needs a kitty restart; a config reload re-runs the two consumers but not an
# already-imported module.

import json
import os
import re
from typing import Any, Callable

from kitty.boss import get_boss
from kitty.fast_data_types import add_timer, monotonic, remove_timer
from kitty.utils import log_error

STATE_DIR = os.path.join(
    os.environ.get('XDG_RUNTIME_DIR') or f'/tmp/claude-tabs-{os.getuid()}', 'claude-tabs'
)

# The timer runs this fast only while something animates. kitty's tab bar is
# redrawn on every tick; the OS window title is rewritten only when its text
# actually changes, which only the waiting blink does.
FRAME_SECONDS = 0.125
IDLE_POLL_SECONDS = 1.0
TAB_SPINNER_SECONDS = 0.125
BLINK_SECONDS = 0.5
SPINNER = '◐◓◑◒'
# iTerm2's cc-status colours. The tab bar draws the dot in them; a window title
# is plain text, so it carries the same colours as emoji instead.
COLORS = {'working': 0xff9500, 'waiting': 0x5f87ff, 'idle': 0x00d75f}
EMOJI = {'working': '🟠', 'waiting': '🔵', 'idle': '🟢'}
BLINK_OFF_EMOJI = '⚪'
PRIORITY = {'waiting': 0, 'working': 1, 'idle': 2}
# Claude puts its own glyph in front of the title (◐/◑ while busy, ✳ idle,
# braille in older versions). The badge replaces it.
LEADING_GLYPH = re.compile(r'^[\s◐◑◒◓✳✻✶✽✢·⏺⠀-⣿]+')


class _State:
    records: dict[int, dict[str, Any]] = {}
    signature: tuple[Any, ...] = ()
    scanned_at: float = -1.0
    listeners: dict[str, Callable[[], None]] = {}
    timer_id: int | None = None
    timer_interval: float = 0.0


def scan() -> None:
    now = monotonic()
    if now - _State.scanned_at < 0.1:
        return
    _State.scanned_at = now
    records: dict[int, dict[str, Any]] = {}
    me = os.getpid()
    try:
        entries = list(os.scandir(STATE_DIR))
    except OSError:
        entries = []
    for entry in entries:
        if not entry.name.endswith('.json'):
            continue
        try:
            with open(entry.path) as f:
                record = json.load(f)
        except (OSError, ValueError):
            continue
        if not isinstance(record, dict):
            continue
        pid = record.get('pid')
        # The hook sweeps dead sessions at the next start; until then a
        # crashed session's record is dropped here so its badge goes away.
        if isinstance(pid, int) and not os.path.isdir(f'/proc/{pid}'):
            try:
                os.remove(entry.path)
            except OSError:
                pass
            continue
        if record.get('kitty_pid') != me:
            continue
        wid = record.get('kitty_window_id')
        if not isinstance(wid, int):
            continue
        # Two sessions in one window can only be one after another; the
        # newest record is the live one.
        previous = records.get(wid)
        if previous is None or record.get('updated', 0) >= previous.get('updated', 0):
            records[wid] = record
    _State.records = records
    _State.signature = tuple(sorted(
        (wid, r.get('state'), r.get('detail'), r.get('updated')) for wid, r in records.items()
    ))


def records() -> dict[int, dict[str, Any]]:
    return _State.records


def signature() -> tuple[Any, ...]:
    return _State.signature


def animated() -> bool:
    return any(r.get('state') in ('working', 'waiting') for r in _State.records.values())


def listen(name: str, callback: Callable[[], None]) -> None:
    # Keyed by name so a consumer that kitty re-runs on a config reload
    # replaces its old callback instead of adding a second one.
    _State.listeners[name] = callback
    ensure_timer()


def ensure_timer() -> None:
    wanted = FRAME_SECONDS if animated() else IDLE_POLL_SECONDS
    if _State.timer_id is not None and _State.timer_interval == wanted:
        return
    boss = get_boss()
    old = getattr(boss, '_claude_status_timer', None)
    if old is not None:
        try:
            remove_timer(old)
        except Exception:
            pass
    _State.timer_id = add_timer(_tick, wanted, True)
    _State.timer_interval = wanted
    boss._claude_status_timer = _State.timer_id


def _tick(timer_id: int | None = None) -> None:
    scan()
    for name, callback in list(_State.listeners.items()):
        try:
            callback()
        except Exception as e:
            log_error(f'claude_status listener {name} failed: {e}')
    ensure_timer()


def display_title(title: str, record: dict[str, Any]) -> str:
    title = LEADING_GLYPH.sub('', title or '').strip()
    return title or os.path.basename(str(record.get('cwd', ''))) or 'claude'


def spinner(period: float) -> str:
    return SPINNER[int(monotonic() / period) % len(SPINNER)]


def blink_on() -> bool:
    return int(monotonic() / BLINK_SECONDS) % 2 == 0


def waiting_ask(record: dict[str, Any]) -> str:
    # A tool name reads as a question ("Bash?"); a notification's sentence
    # does not fit a tab, so it is left out.
    detail = str(record.get('detail', ''))
    return detail if detail and ' ' not in detail and len(detail) <= 16 else ''
