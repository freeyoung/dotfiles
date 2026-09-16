# Custom text for pane title bars: {custom} in window_title_template (iterm2-look.conf).
# All it does is drop the glyph Claude Code puts before its title (◐ ◑ while busy, ✳ when
# idle), the way iTerm2 3.7 does. The state itself is the colored dot on the tab.
# The pane title bar shows when a tab has 2 or more panes.
import re

LEADING_GLYPH = re.compile(r'^[\s◐◑◒◓✳✻✶✽✢·⏺⠀-⣿]+')


def draw_window_title(data) -> str:
    return '  ' + (LEADING_GLYPH.sub('', data.title).strip() or data.title.strip())
