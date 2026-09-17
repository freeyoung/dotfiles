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
