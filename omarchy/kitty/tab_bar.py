# kitty's own slanted powerline tab bar, plus what iTerm2 3.7 shows for a tab
# running Claude Code: a status dot in the cc-status colours (orange working,
# blue waiting for the user, green idle), a spinner while the model works, and
# a blink while a prompt is waiting to be answered. iTerm2's running ring needs
# pixels, and this bar draws in character cells, so the spinner stands in.
#
# The state comes from claude_status.py, shared with claude_title.py. A tab
# with no Claude session draws exactly as kitty's powerline style would.
#
# kitty loads this through tab_bar_style custom. Its tab bar otherwise redraws
# only when something in a tab changes, so the shared timer is what makes the
# animation move.

import os
import sys
from typing import Any

from kitty.boss import get_boss
from kitty.fast_data_types import Screen
from kitty.tab_bar import (
    DrawData,
    ExtraData,
    TabBarData,
    as_rgb,
    draw_tab_with_powerline,
    powerline_symbols,
)
from kitty.window import Window

_here = os.path.dirname(os.path.realpath(__file__))
if _here not in sys.path:
    sys.path.insert(0, _here)
import claude_status as cs  # noqa: E402


class _Drawn:
    signature: tuple[Any, ...] = ()


def _on_tick() -> None:
    if cs.animated() or cs.signature() != _Drawn.signature:
        for tm in get_boss().os_window_map.values():
            tm.mark_tab_bar_dirty()


def _session_for_tab(tab: TabBarData) -> tuple[Window, dict[str, Any]] | None:
    records = cs.records()
    if not records:
        return None
    tab_obj = get_boss().tab_for_id(tab.tab_id)
    if tab_obj is None:
        return None
    best: tuple[Window, dict[str, Any]] | None = None
    for window in tab_obj:
        record = records.get(window.id)
        if record is None:
            continue
        if best is None or cs.PRIORITY.get(record.get('state'), 9) < cs.PRIORITY.get(best[1].get('state'), 9):
            best = (window, record)
    return best


def _draw_claude_title(
    draw_data: DrawData, screen: Screen, tab: TabBarData, window: Window, record: dict[str, Any], before_draw: int
) -> None:
    state = str(record.get('state', ''))
    # The child title, not the tab's: claude_title.py puts its own badge in
    # the window's title override, and this draws a badge of its own.
    title = cs.display_title(window.child_title, record)

    if state == 'working':
        badge = cs.spinner(cs.TAB_SPINNER_SECONDS)
        body = title
        tag = ''
    elif state == 'waiting':
        badge = '●' if cs.blink_on() else '○'
        body = title
        ask = cs.waiting_ask(record)
        tag = f' ⏵ {ask}?' if ask else ' ⏵ ?'
    else:
        badge = '●'
        body = title
        tag = ''

    fg = screen.cursor.fg
    bold = screen.cursor.bold
    screen.cursor.fg = as_rgb(cs.COLORS.get(state, 0x888888))
    screen.draw(badge + ' ')
    screen.cursor.fg = fg
    if state == 'waiting':
        screen.cursor.bold = True
    screen.draw(body)
    if tag:
        screen.cursor.fg = as_rgb(cs.COLORS['waiting'])
        screen.draw(tag)
        screen.cursor.fg = fg
    screen.cursor.bold = bold
    if tab.num_windows > 1:
        screen.draw(f' :{tab.num_windows}:')

    if draw_data.max_tab_title_length > 0:
        x_limit = before_draw + draw_data.max_tab_title_length
        if screen.cursor.x > x_limit:
            screen.cursor.x = x_limit - 1
            screen.draw('…')


def draw_tab(
    draw_data: DrawData,
    screen: Screen,
    tab: TabBarData,
    before: int,
    max_tab_length: int,
    index: int,
    is_last: bool,
    extra_data: ExtraData,
) -> int:
    cs.listen('tab_bar', _on_tick)
    cs.scan()
    _Drawn.signature = cs.signature()
    session = _session_for_tab(tab)
    if session is None:
        return draw_tab_with_powerline(draw_data, screen, tab, before, max_tab_length, index, is_last, extra_data)
    window, record = session

    # From here on this is kitty's draw_tab_with_powerline with the title
    # replaced, so the separators and truncation match the other tabs.
    tab_bg = screen.cursor.bg
    tab_fg = screen.cursor.fg
    default_bg = as_rgb(int(draw_data.default_bg))
    if extra_data.next_tab:
        next_tab_bg = as_rgb(draw_data.tab_bg(extra_data.next_tab))
        needs_soft_separator = next_tab_bg == tab_bg
    else:
        next_tab_bg = default_bg
        needs_soft_separator = False

    separator_symbol, soft_separator_symbol = powerline_symbols.get(draw_data.powerline_style, ('', ''))
    min_title_length = 1 + 2
    start_draw = 2

    if screen.cursor.x == 0:
        screen.cursor.bg = tab_bg
        screen.draw(' ')
        start_draw = 1

    screen.cursor.bg = tab_bg
    if min_title_length >= max_tab_length:
        screen.draw('…')
    else:
        _draw_claude_title(draw_data, screen, tab, window, record, screen.cursor.x)
        extra = screen.cursor.x + start_draw - before - max_tab_length
        if extra > 0 and extra + 1 < screen.cursor.x:
            screen.cursor.x -= extra + 1
            screen.draw('…')

    if not needs_soft_separator:
        screen.draw(' ')
        screen.cursor.fg = tab_bg
        screen.cursor.bg = next_tab_bg
        screen.draw(separator_symbol)
    else:
        prev_fg = screen.cursor.fg
        if tab_bg == tab_fg:
            screen.cursor.fg = default_bg
        elif tab_bg != default_bg:
            c1 = draw_data.inactive_bg.contrast(draw_data.default_bg)
            c2 = draw_data.inactive_bg.contrast(draw_data.inactive_fg)
            if c1 < c2:
                screen.cursor.fg = default_bg
        screen.draw(f' {soft_separator_symbol}')
        screen.cursor.fg = prev_fg

    end = screen.cursor.x
    if end < screen.columns:
        screen.draw(' ')
    return end
