# The tab bar iTerm2 3.7 draws, in kitty's character cells: 1 rounded track
# across the bar, plain tabs with a thin divider between 2 of them, and a
# lighter rounded pill for the tab that is open.
#
# The look belongs to no host in particular, so both kitty setups here can draw
# it: macos/kitty/tab_bar.py does, and omarchy/kitty/tab_bar.py can be told to.
# What differs between them is passed in: the colors, where the state of a
# Claude Code session comes from, and what a tab's shortcut looks like.
#
# A tab that holds a working session carries a band of green light along its
# bottom edge. iTerm2 runs its light around the whole tab, but a tab bar is 1
# row of cells: a cell has an underline and no outline, so only the bottom edge
# can carry it. The light is iTerm2's own, #00ff00 at alpha
# 0, .5, 1, 1, .5, 0, crossing the tab in 1.5 seconds. Something has to
# redraw the bar for it to move: macos/kitty/iterm2_watcher.py does on a timer,
# and claude_status.py does on Omarchy.
import re
from time import monotonic
from typing import Callable, NamedTuple

from kitty.fast_data_types import Screen, get_boss, wcswidth
from kitty.tab_bar import DrawData, ExtraData, TabBarData, as_rgb

# When panes in a tab disagree, the first of these wins, as in iTerm2.
STATES = ('waiting', 'working', 'idle')
# A waiting dot is hollow for every second half second.
BLINK_SECONDS = 0.5
BAND_TURN_SECONDS = 3.0
# Claude Code puts a glyph of its own before the title (◐ ◑ while busy, ✳ when
# idle, braille in older versions). The dot says the same thing, better.
LEADING_GLYPH = re.compile(r'^[\s◐◑◒◓✳✻✶✽✢·⏺⠀-⣿]+')
LEFT_CAP, RIGHT_CAP = '', ''


class Palette(NamedTuple):
    """Everything the bar is drawn with, as 0xRRGGBB."""

    track: int
    pill: int
    divider: int
    fg_active: int
    fg_inactive: int
    band: int
    dots: dict  # state name -> color
    bell: int


def _fit(text: str, width: int) -> str:
    """Cut text to at most `width` cells, counting CJK characters as 2 cells."""
    if width <= 0:
        return ''
    if wcswidth(text) <= width:
        return text
    out, used = [], 0
    for ch in text:
        w = max(0, wcswidth(ch))
        if used + w > width - 1:
            break
        out.append(ch)
        used += w
    return ''.join(out) + '…'


def _blink_on() -> bool:
    return int(monotonic() / BLINK_SECONDS) % 2 == 0


def _band_profile(v: float) -> float:
    x = min(max(v, 0.0), 1.0) * 5
    if x < 1:
        return 0.5 * x
    if x < 2:
        return 0.5 + 0.5 * (x - 1)
    if x < 3:
        return 1.0
    if x < 4:
        return 1.0 - 0.5 * (x - 3)
    return 0.5 - 0.5 * (x - 4)


def _band_color(x: int, start: int, width: int, bg_rgb: int, band_rgb: int) -> int | None:
    """The underline color of cell x in a band of `width` cells from `start`, or None for no underline."""
    phase = monotonic() / BAND_TURN_SECONDS % 1
    along = (x - start + 0.5) / width  # distance from the left end, as the light runs to the right
    alpha = _band_profile((along - 2 * phase) % 1)
    if alpha < 0.05:
        return None
    mix = lambda shift: round(((bg_rgb >> shift) & 0xFF) * (1 - alpha) + ((band_rgb >> shift) & 0xFF) * alpha)
    return as_rgb((mix(16) << 16) | (mix(8) << 8) | mix(0))


def _title(title: str, width: int) -> str:
    """A path title that does not fit shows only its last directory name."""
    title = LEADING_GLYPH.sub('', title).strip() or title.strip()
    # Shells may already shorten the path with a leading ellipsis, for example …/code/civey/devops-ansible.
    if wcswidth(title) > width and '/' in title and ' ' not in title:
        last = title.rstrip('/').rsplit('/', 1)[-1]
        return last or title
    return title


def _dot(tab: TabBarData, state: str | None, palette: Palette) -> tuple[str, int] | None:
    """The status dot of a tab: (glyph, color)."""
    if state in palette.dots:
        glyph = '○' if state == 'waiting' and not _blink_on() else '●'
        return glyph, palette.dots[state]
    if not tab.is_active and tab.needs_attention:
        return '●', palette.bell
    return None


def draw_tab(
    draw_data: DrawData,
    screen: Screen,
    tab: TabBarData,
    before: int,
    max_tab_length: int,
    index: int,
    is_last: bool,
    extra_data: ExtraData,
    palette: Palette,
    state_of: Callable[[TabBarData], str | None],
    hint_of: Callable[[int], str],
    tab_cells: int = 26,
) -> int:
    state = state_of(tab)
    hint = hint_of(index)
    dot = _dot(tab, state, palette)
    # A maximized pane (stack layout) hides the other panes: say how many the tab has.
    zoom = f'⤢{tab.num_windows}' if tab.layout_name == 'stack' and tab.num_windows > 1 else ''
    side = (2 if dot is not None else 0) + (1 + wcswidth(zoom) if zoom else 0) + (1 + wcswidth(hint) if hint else 0)
    if extra_data.for_layout:
        screen.cursor.x = before + min(tab_cells, max_tab_length)
        return screen.cursor.x

    track, pill = as_rgb(palette.track), as_rgb(palette.pill)
    # Slot layout: lead cell | pill cap | content | pill cap.
    # The lead cell is the track's left end, a divider, or plain track.
    content = max_tab_length - 3
    prev = extra_data.prev_tab
    screen.cursor.bold = screen.cursor.italic = False

    screen.cursor.bg = track
    first_and_active = before == 0 and tab.is_active
    if first_and_active:
        # The pill's own round end is also the left end of the track, so the two ends do not stack up.
        screen.cursor.fg, screen.cursor.bg = pill, as_rgb(int(draw_data.default_bg))
        screen.draw(LEFT_CAP)
    elif before == 0:
        screen.cursor.fg, screen.cursor.bg = track, as_rgb(int(draw_data.default_bg))
        screen.draw(LEFT_CAP)
    elif prev is not None and not prev.is_active and not tab.is_active:
        screen.cursor.fg = as_rgb(palette.divider)
        screen.draw('│')
    else:
        screen.draw(' ')

    if content < 1:
        screen.cursor.bg = track
        screen.draw(' ' * max(0, max_tab_length - 1))
        return screen.cursor.x

    bg = pill if tab.is_active else track
    fg = as_rgb(palette.fg_active if tab.is_active else palette.fg_inactive)
    if content - side < 4:
        hint, dot, zoom, side = '', None, '', 0
    title = _fit(_title(tab.title, content - side), content - side)
    lpad = (content - wcswidth(title) - side) // 2
    rpad = content - wcswidth(title) - side - lpad

    if first_and_active:
        screen.cursor.bg = pill
        screen.draw(' ')
    else:
        screen.cursor.fg, screen.cursor.bg = (pill, track) if tab.is_active else (track, track)
        screen.draw(LEFT_CAP if tab.is_active else ' ')
    band_start = screen.cursor.x
    band = state == 'working'
    band_bg = palette.pill if tab.is_active else palette.track

    def draw(text: str) -> None:
        if not band:
            screen.draw(text)
            return
        for ch in text:
            color = _band_color(screen.cursor.x, band_start, content, band_bg, palette.band)
            screen.cursor.decoration = 0 if color is None else 1
            if color is not None:
                screen.cursor.decoration_fg = color
            screen.draw(ch)
        screen.cursor.decoration = 0

    screen.cursor.fg, screen.cursor.bg = fg, bg
    draw(' ' * lpad + title)
    if dot is not None:
        draw(' ')
        screen.cursor.fg = as_rgb(dot[1])
        draw(dot[0])
        screen.cursor.fg = fg
    if zoom:
        draw(' ' + zoom)
    if hint:
        draw(' ' + hint)
    draw(' ' * rpad)
    screen.cursor.fg, screen.cursor.bg = (pill, track) if tab.is_active else (track, track)
    screen.draw(RIGHT_CAP if tab.is_active else ' ')
    end = screen.cursor.x

    if is_last and end < screen.columns:
        # Extend the track to the right edge and round it off.
        screen.cursor.bg = track
        screen.draw(' ' * max(0, screen.columns - end - 1))
        screen.cursor.fg, screen.cursor.bg = track, as_rgb(int(draw_data.default_bg))
        screen.draw(RIGHT_CAP)
    return end


def state_of_tab(tab: TabBarData, state_of_window: Callable[[object], str | None]) -> str | None:
    """The state of a tab: the first of STATES that any of its panes is in."""
    tab_obj = get_boss().tab_for_id(tab.tab_id)
    if tab_obj is None:
        return None
    states = {state_of_window(window) for window in tab_obj}
    for name in STATES:
        if name in states:
            return name
    return None
