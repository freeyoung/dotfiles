# The iTerm2 tab bar on this Mac. The drawing is in kitty/pill_tab_bar.py,
# shared with the Omarchy setup; this says what it is drawn with and where the
# state of a Claude Code session comes from.
#
# Enabled by `tab_bar_style custom` in iterm2-look.conf.
import os
import sys

from kitty.tab_bar import DrawData, ExtraData, Screen, TabBarData

# The shared module is 1 directory up in the repository, and this file is a link
# into it, so the link has to be followed to find it.
_shared = os.path.join(os.path.dirname(os.path.realpath(__file__)), '..', '..', 'kitty')
if _shared not in sys.path:
    sys.path.insert(0, _shared)
import pill_tab_bar as pill  # noqa: E402

# Colors sampled from an iTerm2 3.7 screenshot, and the status dots from its
# cc-status palette. A Claude Code hook sets the `cc_status` user var on a pane:
#   printf '\e]1337;SetUserVar=cc_status=%s\a' "$(printf working | base64)"
PALETTE = pill.Palette(
    track=0x2B2E30,
    pill=0x494C4E,
    divider=0x45494C,
    fg_active=0xF2F2F2,
    fg_inactive=0x9A9A9A,
    band=0x00FF00,
    dots={'waiting': 0x5774DB, 'working': 0xFF9F0A, 'idle': 0x93DF99},
    bell=0xFF9F0A,
)

# Every tab has the same fixed width (in cells). When the bar is full, kitty gives every tab an equal share.
TAB_CELLS = 26


def _state(tab: TabBarData) -> str | None:
    return pill.state_of_tab(tab, lambda window: window.user_vars.get('cc_status'))


def draw_tab(
    draw_data: DrawData, screen: Screen, tab: TabBarData, before: int, max_tab_length: int, index: int, is_last: bool, extra_data: ExtraData
) -> int:
    return pill.draw_tab(
        draw_data, screen, tab, before, max_tab_length, index, is_last, extra_data,
        palette=PALETTE,
        state_of=_state,
        hint_of=lambda index: f'⌘{index}' if index < 10 else '',
        tab_cells=TAB_CELLS,
    )
