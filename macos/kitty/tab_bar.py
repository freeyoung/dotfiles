# iTerm2-style tab bar for kitty, modeled on iTerm2 3.7 (dark mode):
# 1 rounded track across the bar, plain unselected tabs with thin dividers,
# and a lighter rounded pill for the selected tab.
# Enabled by `tab_bar_style custom` in iterm2-look.conf.
import re
from time import monotonic

from kitty.fast_data_types import Screen, get_boss, wcswidth
from kitty.tab_bar import DrawData, ExtraData, TabBarData, as_rgb

# Colors sampled from an iTerm2 3.7 screenshot.
TRACK_RGB, PILL_RGB = 0x2B2E30, 0x494C4E
TRACK = as_rgb(TRACK_RGB)    # rounded track behind the tabs
PILL = as_rgb(PILL_RGB)      # selected tab
DIVIDER = as_rgb(0x45494C)   # line between 2 unselected tabs
FG_ACTIVE = as_rgb(0xF2F2F2)
FG_INACTIVE = as_rgb(0x9A9A9A)
# Status dots. A Claude Code hook sets the `cc_status` user var on a pane:
#   printf '\e]1337;SetUserVar=cc_status=%s\a' "$(printf working | base64)"
# When panes in a tab disagree, the first status in this order wins, like iTerm2.
STATUS_DOTS = (('waiting', as_rgb(0x5774DB)), ('working', as_rgb(0xFF9F0A)), ('idle', as_rgb(0x93DF99)))
BELL_DOT = as_rgb(0xFF9F0A)
# A waiting dot blinks: it is hollow for every second half second. iterm2_watcher.py redraws on a timer.
BLINK_SECONDS = 0.5
# Claude Code puts its own glyph before the title (◐ ◑ while busy, ✳ when idle, braille in older
# versions). The status dot replaces it. The same pattern is in omarchy/kitty/claude_status.py.
LEADING_GLYPH = re.compile(r'^[\s◐◑◒◓✳✻✶✽✢·⏺⠀-⣿]+')
# While a Claude Code session in a tab works, a band of green light runs along the bottom of the tab.
# iTerm2 runs its light around the whole tab, but this tab bar is 1 row of cells: a cell can have an
# underline but no overline, so only the bottom edge has the light, drawn with the underline color.
# The light is the one in omarchy/quickshell/claude-rings: #00ff00 with alpha 0, .5, 1, 1, .5, 0, in 2
# copies around the outline, 1 turn in 3 seconds. Along the bottom edge that is 1 copy the width of the
# tab, which moves from left to right in 1.5 seconds. iterm2_watcher.py redraws on a timer.
BAND_RGB = 0x00FF00
BAND_TURN_SECONDS = 3.0

# Every tab has the same fixed width (in cells). When the bar is full, kitty gives every tab an equal share.
TAB_CELLS = 26
LEFT_CAP, RIGHT_CAP = '', ''


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


def _band_color(x: int, start: int, width: int, bg_rgb: int) -> int | None:
    """The underline color of cell x in a band of `width` cells from `start`, or None for no underline."""
    phase = monotonic() / BAND_TURN_SECONDS % 1
    along = (x - start + 0.5) / width  # distance from the left end, as the light runs to the right
    alpha = _band_profile((along - 2 * phase) % 1)
    if alpha < 0.05:
        return None
    mix = lambda shift: round(((bg_rgb >> shift) & 0xFF) * (1 - alpha) + ((BAND_RGB >> shift) & 0xFF) * alpha)
    return as_rgb((mix(16) << 16) | (mix(8) << 8) | mix(0))


def _is_working(tab: TabBarData) -> bool:
    t = get_boss().tab_for_id(tab.tab_id)
    return t is not None and any(w.user_vars.get('cc_status') == 'working' for w in t)


def _dot_glyph(status: str) -> str:
    return '○' if status == 'waiting' and not _blink_on() else '●'


def _tab_title(title: str, width: int) -> str:
    """A path title that does not fit shows only its last directory name."""
    title = LEADING_GLYPH.sub('', title).strip() or title.strip()
    # Shells may already shorten the path with a leading ellipsis, for example …/code/civey/devops-ansible.
    if wcswidth(title) > width and '/' in title and ' ' not in title:
        last = title.rstrip('/').rsplit('/', 1)[-1]
        return last or title
    return title


def _dot(tab: TabBarData) -> tuple[str, int] | None:
    """The status dot of a tab: (glyph, color)."""
    t = get_boss().tab_for_id(tab.tab_id)
    if t is not None:
        statuses = {w.user_vars.get('cc_status', '') for w in t}
        for name, color in STATUS_DOTS:
            if name in statuses:
                return _dot_glyph(name), color
    if not tab.is_active and tab.needs_attention:
        return '●', BELL_DOT
    return None


def _side_parts(tab: TabBarData, index: int) -> tuple[str, tuple[str, int] | None, str]:
    """The parts after the title: shortcut hint, status dot, and maximized marker."""
    hint = f'⌘{index}' if index < 10 else ''
    dot = _dot(tab)
    # A maximized pane (stack layout, cmd+shift+enter) hides the other panes: show how many the tab has.
    zoom = f'⤢{tab.num_windows}' if tab.layout_name == 'stack' and tab.num_windows > 1 else ''
    return hint, dot, zoom


def _side_width(hint: str, dot: tuple[str, int] | None, zoom: str) -> int:
    return (2 if dot is not None else 0) + (1 + wcswidth(zoom) if zoom else 0) + (1 + wcswidth(hint) if hint else 0)


def _single_pane_status(os_window_id: int) -> tuple[str, int, str] | None:
    """Claude Code status of the active tab when it has only 1 pane: (status, dot color, detail).

    Tabs with 2 or more panes show the status in each pane title bar instead (window_title_bar.py).
    """
    tm = get_boss().os_window_map.get(os_window_id)
    tab = tm.active_tab if tm is not None else None
    if tab is None or len(tab) != 1 or tab.active_window is None:
        return None
    user_vars = tab.active_window.user_vars
    status = user_vars.get('cc_status', '')
    color = dict(STATUS_DOTS).get(status)
    if color is None:
        return None
    return status, color, ' '.join(user_vars.get('cc_detail', '').split())


def draw_tab(
    draw_data: DrawData, screen: Screen, tab: TabBarData, before: int, max_tab_length: int, index: int, is_last: bool, extra_data: ExtraData
) -> int:
    hint, dot, zoom = _side_parts(tab, index)
    side = _side_width(hint, dot, zoom)
    if extra_data.for_layout:
        screen.cursor.x = before + min(TAB_CELLS, max_tab_length)
        return screen.cursor.x

    # Slot layout: lead cell | pill cap | content | pill cap.
    # The lead cell is the track's left end, a divider, or plain track.
    content = max_tab_length - 3
    prev = extra_data.prev_tab
    screen.cursor.bold = screen.cursor.italic = False

    screen.cursor.bg = TRACK
    first_and_active = before == 0 and tab.is_active
    if first_and_active:
        # The pill's own round end is also the left end of the track, so the two ends do not stack up.
        screen.cursor.fg, screen.cursor.bg = PILL, as_rgb(int(draw_data.default_bg))
        screen.draw(LEFT_CAP)
    elif before == 0:
        screen.cursor.fg, screen.cursor.bg = TRACK, as_rgb(int(draw_data.default_bg))
        screen.draw(LEFT_CAP)
    elif prev is not None and not prev.is_active and not tab.is_active:
        screen.cursor.fg = DIVIDER
        screen.draw('│')
    else:
        screen.draw(' ')

    if content < 1:
        screen.cursor.bg = TRACK
        screen.draw(' ' * max(0, max_tab_length - 1))
        return screen.cursor.x

    bg = PILL if tab.is_active else TRACK
    fg = FG_ACTIVE if tab.is_active else FG_INACTIVE
    if content - side < 4:
        hint, dot, zoom, side = '', None, '', 0
    title = _fit(_tab_title(tab.title, content - side), content - side)
    lpad = (content - wcswidth(title) - side) // 2
    rpad = content - wcswidth(title) - side - lpad

    if first_and_active:
        screen.cursor.bg = PILL
        screen.draw(' ')
    else:
        screen.cursor.fg, screen.cursor.bg = (PILL, TRACK) if tab.is_active else (TRACK, TRACK)
        screen.draw(LEFT_CAP if tab.is_active else ' ')
    band_start = screen.cursor.x
    band = _is_working(tab)

    def draw(text: str) -> None:
        if not band:
            screen.draw(text)
            return
        for ch in text:
            color = _band_color(screen.cursor.x, band_start, content, PILL_RGB if tab.is_active else TRACK_RGB)
            screen.cursor.decoration = 0 if color is None else 1
            if color is not None:
                screen.cursor.decoration_fg = color
            screen.draw(ch)
        screen.cursor.decoration = 0

    screen.cursor.fg, screen.cursor.bg = fg, bg
    draw(' ' * lpad + title)
    if dot is not None:
        draw(' ')
        screen.cursor.fg = dot[1]
        draw(dot[0])
        screen.cursor.fg = fg
    if zoom:
        draw(' ' + zoom)
    if hint:
        draw(' ' + hint)
    draw(' ' * rpad)
    screen.cursor.fg, screen.cursor.bg = (PILL, TRACK) if tab.is_active else (TRACK, TRACK)
    screen.draw(RIGHT_CAP if tab.is_active else ' ')
    end = screen.cursor.x

    if is_last and end < screen.columns:
        # Extend the track to the right edge and round it off. When the active tab has 1 pane,
        # show its Claude Code status on the right of the track: "● waiting  Allow Bash: make test?".
        screen.cursor.bg = TRACK
        free = max(0, screen.columns - end - 1)
        info = _single_pane_status(draw_data.os_window_id)
        room = free - 6  # keep a gap after the tabs and 1 cell before the round end
        if info is not None and room >= len(info[0]) + 2:
            status, color, detail = info
            detail = _fit(detail, room - len(status) - 4) if detail and room - len(status) - 4 >= 6 else ''
            width = 2 + len(status) + (2 + wcswidth(detail) if detail else 0)
            screen.draw(' ' * (free - width - 1))
            screen.cursor.fg = color
            screen.draw(_dot_glyph(status) + ' ')
            screen.draw(status)
            if detail:
                screen.cursor.fg = FG_INACTIVE
                screen.draw('  ' + detail)
            screen.draw(' ')
        else:
            screen.draw(' ' * free)
        screen.cursor.fg, screen.cursor.bg = TRACK, as_rgb(int(draw_data.default_bg))
        screen.draw(RIGHT_CAP)
    return end
