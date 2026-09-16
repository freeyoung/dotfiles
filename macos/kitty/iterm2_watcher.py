# Kitty watcher for the iTerm2-like look. Loaded by `watcher` in iterm2-look.conf.
# 1. Dim the background of inactive split panes, like iTerm2 "Dim inactive split panes".
#    Runs when focus changes and when panes resize (a pane opens or closes).
# 2. Redraw the tab bar and the pane title bar when the Claude Code hook changes the status user vars.
# 3. On a timer: blink the dot of a waiting Claude Code session, move the band of light under the tab
#    of a working session (tab_bar.py), and remove the status of a session that ended without its
#    SessionEnd hook, for example when Claude Code crashed or was killed.
# The status is only ever drawn on the tab, so a redraw here is a redraw of the tab bar.
import os
from time import monotonic
from typing import Any

from kitty.boss import Boss
from kitty.colors import patch_colors
from kitty.fast_data_types import add_timer, get_boss, get_options, remove_timer, wakeup_main_loop
from kitty.window import Window

# iTerm2 mixes 20% white into the background of inactive panes: #000000 becomes #333333.
DIM_AMOUNT = 0.2

# Window id -> background color this watcher applied last, and the theme background it was based on.
_applied: dict[int, int] = {}
_theme_background = -1

TICK_SECONDS = 0.25
# While a session works, the tab bar is drawn this often, so the band of light moves about 1 cell at a time.
FRAME_SECONDS = 1 / 15
# The same value as in tab_bar.py and window_title_bar.py, which choose the dot from the clock.
BLINK_SECONDS = 0.5
ENDED_CHECK_SECONDS = 2.0
CC_VARS = ('cc_status', 'cc_dot', 'cc_text', 'cc_detail', 'cc_bg_tasks')
SHELLS = {'zsh', 'bash', 'fish', 'sh', 'dash', 'ksh', 'tcsh', 'nu'}


class _Timer:
    blink_phase = -1
    checked_at = 0.0
    interval = 0.0


def _dimmed(color: int) -> int:
    r, g, b = (color >> 16) & 0xFF, (color >> 8) & 0xFF, color & 0xFF
    mix = lambda c: round(c * (1 - DIM_AMOUNT) + 255 * DIM_AMOUNT)
    return (mix(r) << 16) | (mix(g) << 8) | mix(b)


def _refresh(tab: Any) -> None:
    global _theme_background
    if tab is None:
        return
    normal = int(get_options().background)
    if normal != _theme_background:
        # The theme changed (for example with `kitten themes`), so forget colors based on the old one.
        _theme_background = normal
        _applied.clear()
    dim = _dimmed(normal)
    active = tab.active_window
    split = len(tab) > 1
    for w in tab:
        want = dim if split and w is not active else normal
        if _applied.get(w.id) != want:
            patch_colors({'background': want}, windows=[w])
            _applied[w.id] = want


def _names(processes: list[dict[str, Any]]) -> set[str]:
    names = set()
    for p in processes:
        cmdline = p.get('cmdline') or []
        # A login shell is "-zsh". Claude Code installed with npm is "node …/claude".
        names.update(os.path.basename(arg).lstrip('-') for arg in cmdline[:2])
    return names


def _claude_ended(window: Window) -> bool:
    """True when the pane is back at its shell prompt and no Claude Code process is left in it."""
    foreground = window.child.foreground_processes
    if not foreground or not _names(foreground) <= SHELLS:
        # Claude Code, or a program it started, or tmux or ssh is in the foreground.
        return False
    # Claude Code stopped with ctrl+z is still alive in the background.
    return 'claude' not in _names(window.child.background_processes)


def _tick(timer_id: int | None = None) -> None:
    now = monotonic()
    phase = int(now / BLINK_SECONDS) % 2
    blink = phase != _Timer.blink_phase
    _Timer.blink_phase = phase
    check = now - _Timer.checked_at >= ENDED_CHECK_SECONDS
    if check:
        _Timer.checked_at = now
    redraw = working = False
    for window in list(get_boss().window_id_map.values()):
        status = window.user_vars.get('cc_status')
        if not status:
            continue
        if check and _claude_ended(window):
            for key in CC_VARS:
                window.set_user_var(key, None)  # on_set_user_var redraws
            continue
        tab = window.tabref()
        if tab is None:
            continue
        if status == 'working':
            working = redraw = True
            tab.mark_tab_bar_dirty()
        elif blink and status == 'waiting':
            tab.mark_tab_bar_dirty()
            redraw = True
    if redraw:
        # kitty draws a frame only after its main loop wakes up, and a timer does not wake it.
        wakeup_main_loop()
    _start_timer(FRAME_SECONDS if working else TICK_SECONDS)


def _start_timer(interval: float) -> None:
    boss = get_boss()
    old = getattr(boss, '_iterm2_watcher_timer', None)
    if old is not None and _Timer.interval == interval:
        return
    if old is not None:
        try:
            remove_timer(old)
        except Exception:
            pass
    boss._iterm2_watcher_timer = add_timer(_tick, interval, True)
    _Timer.interval = interval


def on_load(boss: Boss, data: dict[str, Any]) -> None:
    # A config reload loads this file again, and the timer of the old copy must stop.
    _Timer.interval = 0.0
    _start_timer(TICK_SECONDS)


def on_focus_change(boss: Boss, window: Window, data: dict[str, Any]) -> None:
    _refresh(window.tabref())


def on_close(boss: Boss, window: Window, data: dict[str, Any]) -> None:
    _applied.pop(window.id, None)


def on_set_user_var(boss: Boss, window: Window, data: dict[str, Any]) -> None:
    if data.get('key') == 'cc_status':
        tab = window.tabref()
        if tab is not None:
            tab.mark_tab_bar_dirty()


def on_resize(boss: Boss, window: Window, data: dict[str, Any]) -> None:
    # A new or closed pane resizes the others, so this also covers panes opened without a focus change.
    _refresh(window.tabref())
