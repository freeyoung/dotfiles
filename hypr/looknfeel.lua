-- Personal look-and-feel overrides for Hyprland. Omarchy loads this after its
-- own defaults and after the theme, so anything here wins.
-- Its commented examples live in /usr/share/omarchy/config/hypr/looknfeel.lua.

-- Ported from the old hyprland.conf (Hyprland 0.55+ reads Lua, not hyprlang).
hl.config({
  general = {
    border_size = 1,
    -- Applied to every edge of every window, so two tiled windows sit
    -- 2 * gaps_in apart, plus one border each. At 0 the two borders meet and
    -- read as a single 2 px rule between windows.
    gaps_in = 0,
    gaps_out = 0,

    col = {
      -- Loaded after the theme, so these override the current theme's borders.
      active_border = { colors = { "rgba(33ccff33)", "rgba(00ff9933)" }, angle = 45 },
      inactive_border = "rgba(5959590d)",
    },
  },
})

-- Was: windowrulev2 = noborder,fullscreen:1
o.window({ fullscreen = true }, { border_size = 0 })
