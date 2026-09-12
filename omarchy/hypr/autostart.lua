-- Extra autostart processes.
-- o.launch_on_start("my-service")

-- XWayland reports 96 DPI whatever the compositor's scale is, and Hyprland's
-- xwayland:force_zero_scaling leaves X11 clients to size themselves from it.
-- Loading Xft.dpi is what lets them: a Qt client reads it through
-- QT_AUTO_SCREEN_SCALE_FACTOR, and fcitx5 sizes the candidate window it draws
-- for an X11 client from it too. Merged rather than loaded so anything else
-- that has put resources on the display survives.
o.launch_on_start("xrdb -merge " .. os.getenv("HOME") .. "/.Xresources")

-- Both the ring below and the bar widget watch this directory for the records
-- claude-tab-status writes. A reboot empties $XDG_RUNTIME_DIR, and the first
-- hook of the first session would otherwise create the directory long after
-- they started watching for it.
o.exec_on_start("mkdir -p \"${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/claude-tabs\"")

-- The running green ring around a Hyprland group tab whose Claude Code session
-- is working, and the band along that terminal's top edge, drawn by their own
-- Quickshell instance rather than inside Omarchy's shell, so it can be
-- restarted without taking the bar down. -n makes a second launch, from a
-- config reload, a no-op. Started only where the configuration is installed,
-- which `install` does on an Omarchy host and nowhere else: this file is read
-- by any Hyprland, and Quickshell asked for a configuration that is not there
-- exits with an error at every login.
o.exec_on_start(
  '[ -d "$HOME/.config/quickshell/claude-rings" ] && ' .. o.launch("quickshell -n -c claude-rings")
)
