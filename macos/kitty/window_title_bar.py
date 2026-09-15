# Custom text for pane title bars: {custom} in window_title_template (iterm2-look.conf).
# Shows the pane title, then the Claude Code status and detail text that the cc-status hook stores
# on the pane, for example "Claude Code   ● waiting  Allow Bash: make test?".
# The pane title bar shows when a tab has 2 or more panes.
import re
from time import monotonic

from kitty.fast_data_types import get_boss

# The same values as in tab_bar.py.
BLINK_SECONDS = 0.5
LEADING_GLYPH = re.compile(r'^[\s◐◑◒◓✳✻✶✽✢·⏺⠀-⣿]+')


def _sgr_fg(hex_color: str) -> str:
    h = hex_color.lstrip('#')
    if len(h) != 6:
        return ''
    r, g, b = int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)
    return f'\x1b[38;2;{r};{g};{b}m'


def draw_window_title(data) -> str:
    # Claude Code puts its own glyph before the title. The status dot replaces it.
    title = '  ' + (LEADING_GLYPH.sub('', data.title).strip() or data.title.strip())
    window = get_boss().window_id_map.get(data.window_id)
    if window is None:
        return title
    user_vars = window.user_vars
    status = user_vars.get('cc_status', '')
    if not status:
        return title
    detail = ' '.join(user_vars.get('cc_detail', '').split())
    dot = _sgr_fg(user_vars.get('cc_dot', ''))
    text = _sgr_fg(user_vars.get('cc_text', ''))
    glyph = '○' if status == 'waiting' and int(monotonic() / BLINK_SECONDS) % 2 else '●'
    out = f'{title}   {dot}{glyph}\x1b[39m {text}{status}\x1b[39m'
    if detail:
        out += f'  {detail}'
    return out
