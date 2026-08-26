-- Personal input overrides for Hyprland. Omarchy loads this after its own
-- defaults, so anything here wins without touching Omarchy's files.
-- Its commented examples live in /usr/share/omarchy/config/hypr/input.lua.

-- Natural (inverted) scrolling, and three-finger drag.
-- drag_3fg maps to libinput's 3fg-drag: 0 disables it, 1 uses three fingers,
-- 2 uses four. Holding three fingers down then moving is a held left button,
-- so text selects and windows drag without pressing the touchpad at all --
-- the same thing macOS calls Three Finger Drag.
hl.config({
  input = {
    touchpad = {
      natural_scroll = true,
      drag_3fg = 1,
    },
  },
})

-- The macOS ABC layout, where right Alt is Option: us(mac) ends with
-- include "level3(ralt_switch)", so right Alt stops producing Alt at all.
-- CapsLock becomes Esc, which leaves Compose homeless -- right Ctrl takes it,
-- since right Alt is spoken for. shift:both_capslock_cancel is deliberately
-- absent: with CapsLock remapped there is no caps lock, and that is wanted.
hl.config({
  input = {
    kb_variant = "mac",
    kb_options = "caps:escape,compose:rctrl",
  },
})
