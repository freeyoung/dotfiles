# Claude Code status in the terminal

This is Omarchy's, and only Omarchy's: the installer links the hook and
registers it on a host that has Omarchy, and skips both anywhere else, since
what reads the records is the Omarchy bar widget and the Hyprland group-tab
ring, and what writes them leans on `/proc` and `$XDG_RUNTIME_DIR`. The kitty files
are linked there too and nowhere else: `kitty.conf` is one file shared across
hosts, so it names them through a glob that matches nothing off Omarchy, and a
host without them keeps kitty's own tab bar.

iTerm2 3.7 tells a tab running Claude Code apart from the rest: a band of
green light runs around the tab while the model works, and a coloured dot says
whether the session is working, waiting for the user, or idle. This is the same
thing for kitty and Hyprland groups on Omarchy, in parts that share one set of
records.

[`bin/claude-tab-status`](../../bin/claude-tab-status) is a Claude Code hook.
[`hooks.json`](hooks.json) names the events it is registered
for, and [`scripts/install-claude-hooks.sh`](../../scripts/install-claude-hooks.sh)
merges those into `~/.claude/settings.json` -- merged rather than linked,
because that file also carries choices made from inside Claude. Each event
becomes one record under `$XDG_RUNTIME_DIR/claude-tabs/<session>.json`: a
prompt or a tool call means `working`, a permission or elicitation prompt
means `waiting`, the end of a turn means `idle`, and the end of the session
removes the record. Hooks that fire inside an agent leave the state alone:
Claude runs one after a turn to write its "while you were away" recap, and
counting that as work turned finished sessions back to working. The states and
colours are iTerm2's own, from the
`cc-status` hook it ships, so the two feel alike. A waiting session does not
ring the bell: kitty turns that into an activation request, and with Omarchy's
`misc:focus_on_activate` Hyprland answers it by moving focus to the window.

[`omarchy/kitty/tab_bar.py`](../kitty/tab_bar.py) is what `tab_bar_style custom` in
`kitty.conf` loads. It draws kitty's own slanted powerline, and on a tab whose
window has a record it replaces the title: an orange spinner while the session
works, a blinking blue dot with the tool waiting for an answer, a green dot when
the turn is done. kitty's bar draws in character cells, so the running ring
cannot be drawn there and the spinner stands in for it. Claude's own title glyph
is dropped, as iTerm2 3.7 stops counting it. A tab without a record
draws exactly as before, and the file is checked by
[`scripts/check-kitty-config.sh`](../../scripts/check-kitty-config.sh) under kitty's
own interpreter, since a file kitty cannot load falls back silently.

The hook also asks Claude to write an OSC 9;4 progress report into the terminal
it runs in, which kitty draws as a thin bar along the window's top edge --
`progress_bar` and `scrollbar_handle_color` in
[`kitty/kitty.conf`](../../kitty/kitty.conf) place and colour it. Working reports
indeterminate progress, which kitty animates as a green segment sliding back
and forth, the band Claude Code shows under iTerm2; every other state clears it.
Claude sends this sequence itself under iTerm2 and Ghostty but not under kitty,
and a hook may only emit notification and title sequences, of which the 9;4
progress form is one. kitty forgets a progress report that has not been repeated
for a minute, so a long turn that makes no tool calls loses the band until the
next one.

[`omarchy/kitty/claude_title.py`](../kitty/claude_title.py) is a kitty watcher that puts
the same state into each window's title, for a Hyprland group: its tab bar
draws only titles, and every member is a kitty window of its own. A working
session reads `🟠 title`, a waiting one blinks `🔵 Bash? · title`, an idle one
reads `🟢 title`. The colours are emoji because
Hyprland draws every group tab in the same colours and a title is plain text.
The badge goes into kitty's title override, so Claude's own title survives
underneath and returns when the session ends, and a title set by hand is left
alone. Both kitty files read the records through
[`omarchy/kitty/claude_status.py`](../kitty/claude_status.py), which holds the one scan
and the one timer; a change to it needs a kitty restart rather than a reload.

[`omarchy/quickshell/claude-rings`](../quickshell/claude-rings) draws the ring. Hyprland
offers no way to decorate one group tab, so a separate Quickshell instance,
started from `omarchy/hypr/autostart.lua`, puts a click-through layer over each screen
and lays a ring over every group tab whose kitty window holds a working session.
It finds the tab from Hyprland's own layout: the group's visible member, the
order of its members, and the `group:groupbar` options, through the arithmetic
Hyprland 0.56 uses to place the bar. That arithmetic is copied, not asked for,
so a Hyprland update that changes it moves the rings off their tabs. The light
is iTerm2's own gradient, alpha 0, .5, 1, 1, .5, 0, in two copies laid end to
end along the outline, one turn every three seconds; the shader that draws it is
`ring.frag`, compiled into the `ring.frag.qsb` Quickshell loads:

```bash
/usr/lib/qt6/bin/qsb --glsl "150,330,300 es" -o ring.frag.qsb ring.frag
```

The ring follows a window's final geometry rather than its animation, so it
reaches a moving tab slightly ahead of it, and it is drawn above windows, so a
floating window over a group tab still shows the ring on top.

Both the ring and the bar widget watch the directory the records live in, which
a reboot empties and the first session's first hook recreates -- long after
either started watching. A watcher pointed at a directory that does not exist
never sees it appear, so `omarchy/hypr/autostart.lua` creates it at login and both
watchers point themselves at it again every few seconds while they have nothing
to show. Without that, a reboot left the bar with no indicator until the shell
was restarted by hand.

[`omarchy/plugins/eric.claude`](../plugins/eric.claude) is the bar's
view of the same records, one dot per state across every session, with a
count when there is more than one and a tooltip naming each. The dots are
drawn rather than typeset, so every state is the same size; the motion lives
on the tab, not here. A click raises
the window and tab of the session that needs attention most; that goes
through `claude-tab-status focus`, which is why `kitty.conf` allows remote
control over its socket. The installer links the plugin; it appears in the bar
once `shell.json` lists it:

```bash
omarchy plugin enable eric.claude --section right
```

An edit to a plugin here does not reach the running bar on its own. The shell
watches `~/.config/omarchy/plugins` without following links, and both plugins
here are links into this repository. Recreating the link or asking the shell
to rescan does make it log a reload, but it compiles the same file address
again while the old widget is still alive, and QML hands back the cached old
version. Only a restart of the shell loads the new code:

```bash
omarchy restart shell
```
