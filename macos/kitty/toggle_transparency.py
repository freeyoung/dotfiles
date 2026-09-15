"""Turn the background transparency off and on, like iTerm2 View > Use Transparency (cmd+u).

The transparency comes from transparent_background_colors (iterm2-profile.conf), so this sets those colors
to fully opaque in every pane of the OS window, or back to the configured opacity.
"""
from kittens.tui.handler import result_handler
from kitty.colors import patch_colors
from kitty.fast_data_types import get_options


def main(args: list[str]) -> str:
    return ''


@result_handler(no_ui=True)
def handle_result(args: list[str], answer: str, target_window_id: int, boss) -> None:
    window = boss.window_id_map.get(target_window_id) or boss.active_window
    configured = tuple(get_options().transparent_background_colors)
    if window is None or not configured:
        return
    tm = boss.os_window_map.get(window.os_window_id)
    windows = [w for tab in tm for w in tab] if tm is not None else [window]
    first = window.screen.color_profile.get_transparent_background_color(0)
    transparent_now = first is not None and first.alpha < 255
    # An empty list would leave the colors unchanged, so turn them off by making them fully opaque.
    colors = tuple((color, 1.0) for color, _ in configured) if transparent_now else configured
    patch_colors({}, colors, False, windows=windows)
