-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Change an existing binding by unbinding it first, then binding the key again.
-- This example changes SUPER+SPACE from the launcher to the Omarchy root menu.
-- hl.unbind("SUPER + SPACE")
-- o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle root")

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "omarchy-capture-screenshot")
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, "omarchy-shell shell toggle omarchy.emojis")

-- Omarchy binds SUPER+ALT+1..5 to the first five windows in a tab group.
-- Extend that to 9; SUPER+ALT+6..9 are otherwise unbound. The keycodes match
-- upstream's own loop (code:10 is the "1" key), so these stay on the physical
-- number row regardless of the active xkb layout.
for index = 6, 9 do
  o.bind(
    "SUPER + ALT + code:" .. tostring(index + 9),
    "Switch to group window " .. index,
    hl.dsp.group.active({ index = index })
  )
end

-- Explicit splits, the way iTerm2's Cmd+D works. The dwindle layout picks the
-- split direction from the focused window's aspect ratio, so the same key
-- splits sideways next to a wide window and downwards next to a tall one.
-- preselect overrides that for the next window only, which puts the direction
-- back in the hands of the key being pressed.
local function split_into_terminal(direction)
  return function()
    hl.dispatch(hl.dsp.layout("preselect " .. direction))
    -- The same launcher SUPER+RETURN uses, so this follows the configured
    -- terminal and opens in the active terminal's directory.
    hl.dispatch(hl.dsp.exec_cmd("omarchy-launch-terminal"))
  end
end

-- SUPER+SHIFT+D was Omarchy's Docker TUI. It moves to SUPER+ALT+D below, and
-- is reachable from the Omarchy menu either way.
hl.unbind("SUPER + SHIFT + D")

o.bind("SUPER + D", "Split right into a terminal", split_into_terminal("r"))
o.bind("SUPER + SHIFT + D", "Split down into a terminal", split_into_terminal("d"))
o.bind("SUPER + ALT + D", "Docker", { tui = "omarchy-launch-docker-tui" })
