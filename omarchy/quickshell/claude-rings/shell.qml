import QtQuick
import QtQml
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

// iTerm2 3.7 draws a band of green light running around a tab whose session is
// busy. Hyprland's group tabs have no such thing and no way to be given one,
// so this draws it over them: one click-through layer surface per screen, and
// a ring laid exactly over each group tab whose kitty window is running a
// Claude Code session that is working.
//
// Which sessions are working comes from the records bin/claude-tab-status
// writes. Where their tabs are is worked out from Hyprland's own layout: the
// group's visible member, the group's order, and the groupbar options, put
// through the same arithmetic Hyprland 0.56 uses to place the bar
// (CHyprGroupBarDecoration and CDecorationPositioner).
//
// The ring follows a window's final geometry, not its animation, so it lands
// where a moving tab is going a moment before the tab does.

ShellRoot {
  id: root

  readonly property string stateDir: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/claude-tabs"
  readonly property color ringColor: "#00ff00"
  readonly property real ringThickness: 2
  readonly property int turnMilliseconds: 3000
  // The band along the top edge of the terminal itself, the other half of what
  // iTerm2 shows for a busy session. kitty draws one of its own for OSC 9;4
  // progress, but sweeps it far too fast to read and only moves it when the
  // window repaints, so it is drawn here instead: two lit stretches half a
  // sweep apart, each the same 0, .5, 1, 1, .5, 0 gradient as the ring.
  readonly property real bandThickness: 2
  readonly property real bandFraction: 0.4
  readonly property int sweepMilliseconds: 3000

  property var working: []
  property var rings: []
  property var bands: []
  property real phase: 0
  property real sweep: 0

  // Hyprland's defaults until the real values arrive.
  property var opts: ({
    borderSize: 1, enabled: true, stacked: false, height: 22, indicatorHeight: 3,
    indicatorGap: 0, gapsIn: 2, gapsOut: 2, keepUpperGap: true, renderTitles: true,
    gradients: false, rounding: 1
  })

  // ---------------------------------------------------------------- records

  FolderListModel {
    id: folder
    folder: "file://" + root.stateDir
    nameFilters: ["*.json"]
    showDirs: false
    showDotAndDotDot: false
  }

  // $XDG_RUNTIME_DIR is emptied by a reboot, and this directory is created by
  // the first hook of the first session, which can be long after login. A
  // FolderListModel pointed at a directory that does not exist yet never
  // notices it appear, so it is pointed at it again while there is nothing to
  // show. Cheap: one directory read every few seconds, and only while empty.
  Timer {
    interval: 3000
    running: folder.count === 0
    repeat: true
    onTriggered: {
      folder.folder = ""
      folder.folder = "file://" + root.stateDir
    }
  }

  Instantiator {
    id: records
    model: folder
    delegate: QtObject {
      id: item
      readonly property string filePath: model.filePath
      property var record: null
      readonly property FileView view: FileView {
        path: item.filePath
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
          try {
            var parsed = JSON.parse(String(text() || ""))
            item.record = parsed && typeof parsed === "object" ? parsed : null
          } catch (e) {
            item.record = null
          }
          root.refreshRecords()
        }
        onLoadFailed: {
          item.record = null
          root.refreshRecords()
        }
      }
    }
    onObjectAdded: root.refreshRecords()
    onObjectRemoved: root.refreshRecords()
  }

  // The hook replaces a record by rename, which a file watch can miss.
  Timer {
    interval: 1000
    running: folder.count > 0
    repeat: true
    onTriggered: {
      for (var i = 0; i < records.count; i++) {
        var item = records.objectAt(i)
        if (item && item.view) item.view.reload()
      }
    }
  }

  function refreshRecords() {
    var list = []
    for (var i = 0; i < records.count; i++) {
      var item = records.objectAt(i)
      if (item && item.record && item.record.state === "working" && item.record.kitty_pid) list.push(item.record)
    }
    working = list
    recompute()
  }

  // --------------------------------------------------------------- hyprland

  // Window geometry is not pushed by events for every move and resize, so it
  // is asked for while there is anything to draw.
  Timer {
    interval: 150
    running: root.working.length > 0
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      Hyprland.refreshToplevels()
      Hyprland.refreshMonitors()
      root.recompute()
    }
  }

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      if (event.name === "configreloaded") optionsProc.running = true
    }
  }

  readonly property var optionNames: [
    "general:border_size", "group:groupbar:enabled", "group:groupbar:stacked", "group:groupbar:height",
    "group:groupbar:indicator_height", "group:groupbar:indicator_gap", "group:groupbar:gaps_in",
    "group:groupbar:gaps_out", "group:groupbar:keep_upper_gap", "group:groupbar:render_titles",
    "group:groupbar:gradients", "group:groupbar:rounding"
  ]

  Process {
    id: optionsProc
    running: true
    command: ["bash", "-c", "for o in \"$@\"; do hyprctl -j getoption \"$o\" | tr -d '\\n'; echo; done", "options"].concat(root.optionNames)
    stdout: StdioCollector {
      onStreamFinished: {
        var values = {}
        var lines = text.split("\n")
        for (var i = 0; i < lines.length; i++) {
          if (!lines[i].trim()) continue
          try {
            var o = JSON.parse(lines[i])
            values[o.option] = o.int !== undefined ? o.int : (o.float !== undefined ? o.float : o.bool)
          } catch (e) {}
        }
        function pick(name, fallback) {
          var v = values[name]
          return v === undefined || v === null ? fallback : Number(v)
        }
        var d = root.opts
        root.opts = {
          borderSize: pick("general:border_size", d.borderSize),
          enabled: !!pick("group:groupbar:enabled", d.enabled ? 1 : 0),
          stacked: !!pick("group:groupbar:stacked", d.stacked ? 1 : 0),
          height: pick("group:groupbar:height", d.height),
          indicatorHeight: pick("group:groupbar:indicator_height", d.indicatorHeight),
          indicatorGap: pick("group:groupbar:indicator_gap", d.indicatorGap),
          gapsIn: pick("group:groupbar:gaps_in", d.gapsIn),
          gapsOut: pick("group:groupbar:gaps_out", d.gapsOut),
          keepUpperGap: !!pick("group:groupbar:keep_upper_gap", d.keepUpperGap ? 1 : 0),
          renderTitles: !!pick("group:groupbar:render_titles", d.renderTitles ? 1 : 0),
          gradients: !!pick("group:groupbar:gradients", d.gradients ? 1 : 0),
          rounding: pick("group:groupbar:rounding", d.rounding)
        }
        root.recompute()
      }
    }
  }

  // The tab of `address` in its group, in global logical coordinates, or null
  // when that tab is not on screen.
  function tabRect(windowIpc, byAddress, monitors) {
    var o = opts
    var members = windowIpc.grouped || []
    if (!o.enabled || o.stacked || members.length === 0) return null

    var shown = null
    for (var i = 0; i < members.length; i++) {
      var member = byAddress[members[i]]
      if (member && !member.hidden && member.mapped !== false) { shown = member; break }
    }
    if (!shown || (shown.fullscreen && shown.fullscreen !== 0)) return null

    var monitor = monitors[shown.monitor]
    if (!monitor) return null
    var ws = shown.workspace ? shown.workspace.id : null
    if (ws !== monitor.activeWorkspace && ws !== monitor.specialWorkspace) return null

    var barHeight = (o.gradients || o.renderTitles) ? o.height : 0
    if (barHeight <= 0) return null
    // CHyprGroupBarDecoration::getPositioningInfo, and the border decoration
    // stacked outside the window before it by CDecorationPositioner.
    var oneBar = o.gapsOut + o.indicatorHeight + o.indicatorGap + barHeight
    var extent = o.gapsOut * (1 + (o.keepUpperGap ? 1 : 0)) + o.indicatorHeight + o.indicatorGap + barHeight
    var boxX = shown.at[0] - o.borderSize
    var boxY = shown.at[1] - o.borderSize - extent
    var boxW = shown.size[0] + 2 * o.borderSize

    var index = members.indexOf(windowIpc.address)
    if (index < 0) return null
    var barWidth = (boxW - o.gapsIn * (members.length - 1)) / members.length
    return {
      monitor: monitor.name,
      x: boxX + index * (barWidth + o.gapsIn) - monitor.x,
      y: boxY + extent - oneBar - monitor.y,
      width: barWidth,
      height: barHeight,
      key: windowIpc.address
    }
  }

  // The top edge of a window that is on screen right now, or null. A session
  // whose window is the hidden member of a group has no band: the terminal in
  // front of it belongs to someone else.
  function bandRect(windowIpc, monitors) {
    if (windowIpc.hidden || windowIpc.mapped === false) return null
    var monitor = monitors[windowIpc.monitor]
    if (!monitor) return null
    var ws = windowIpc.workspace ? windowIpc.workspace.id : null
    if (ws !== monitor.activeWorkspace && ws !== monitor.specialWorkspace) return null
    return {
      monitor: monitor.name,
      x: windowIpc.at[0] - monitor.x,
      y: windowIpc.at[1] - monitor.y,
      width: windowIpc.size[0],
      height: bandThickness,
      key: windowIpc.address
    }
  }

  function recompute() {
    var next = []
    var nextBands = []
    if (working.length > 0) {
      var tops = Hyprland.toplevels.values
      var byAddress = {}
      var byPid = {}
      for (var i = 0; i < tops.length; i++) {
        var ipc = tops[i].lastIpcObject
        if (!ipc || !ipc.address) continue
        byAddress[ipc.address] = ipc
        if (!byPid[ipc.pid]) byPid[ipc.pid] = []
        byPid[ipc.pid].push(ipc)
      }
      var monitors = {}
      var mons = Hyprland.monitors.values
      for (var m = 0; m < mons.length; m++) {
        var mi = mons[m].lastIpcObject || {}
        monitors[mons[m].id] = {
          name: mons[m].name,
          x: mons[m].x,
          y: mons[m].y,
          activeWorkspace: mons[m].activeWorkspace ? mons[m].activeWorkspace.id : null,
          specialWorkspace: mi.specialWorkspace && mi.specialWorkspace.id ? mi.specialWorkspace.id : null
        }
      }

      var seen = {}
      for (var r = 0; r < working.length; r++) {
        var candidates = byPid[working[r].kitty_pid] || []
        // One kitty process can own several windows. Its Claude window carries
        // the badge claude_title.py puts in the title.
        var badged = candidates.filter(function(c) { return String(c.title || "").indexOf("🟠") === 0 })
        var targets = badged.length > 0 ? badged : candidates
        for (var c = 0; c < targets.length; c++) {
          if (seen[targets[c].address]) continue
          seen[targets[c].address] = true
          var rect = tabRect(targets[c], byAddress, monitors)
          if (rect) next.push(rect)
          var band = bandRect(targets[c], monitors)
          if (band) nextBands.push(band)
        }
      }
    }
    // Reassigning an equal list would rebuild every ring for nothing.
    if (JSON.stringify(next) !== JSON.stringify(rings)) rings = next
    if (JSON.stringify(nextBands) !== JSON.stringify(bands)) bands = nextBands
  }

  // One clock for every ring, so a ring rebuilt after a move keeps its place.
  NumberAnimation on phase {
    from: 0
    to: 1
    duration: root.turnMilliseconds
    loops: Animation.Infinite
    running: root.rings.length > 0
  }

  NumberAnimation on sweep {
    from: 0
    to: 1
    duration: root.sweepMilliseconds
    loops: Animation.Infinite
    running: root.bands.length > 0
  }

  // ---------------------------------------------------------------- drawing

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: surface
      required property var modelData
      readonly property var hyprMonitor: Hyprland.monitorFor(modelData)
      readonly property var mine: root.rings.filter(function(ring) {
        return surface.hyprMonitor && ring.monitor === surface.hyprMonitor.name
      })
      readonly property var myBands: root.bands.filter(function(band) {
        return surface.hyprMonitor && band.monitor === surface.hyprMonitor.name
      })

      screen: modelData
      visible: mine.length > 0 || myBands.length > 0
      color: "transparent"
      anchors { top: true; bottom: true; left: true; right: true }
      exclusionMode: ExclusionMode.Ignore
      mask: Region {}
      WlrLayershell.namespace: "claude-rings"
      WlrLayershell.layer: WlrLayer.Top
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

      Repeater {
        model: surface.myBands

        Item {
          required property var modelData
          x: modelData.x
          y: modelData.y
          width: modelData.width
          height: modelData.height
          clip: true

          Repeater {
            model: 2

            Rectangle {
              required property int index
              readonly property real span: parent.width * root.bandFraction
              readonly property real progress: (root.sweep + index * 0.5) % 1

              width: span
              height: parent.height
              x: -span + (parent.width + span) * progress
              gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Qt.rgba(root.ringColor.r, root.ringColor.g, root.ringColor.b, 0) }
                GradientStop { position: 0.2; color: Qt.rgba(root.ringColor.r, root.ringColor.g, root.ringColor.b, 0.5) }
                GradientStop { position: 0.4; color: root.ringColor }
                GradientStop { position: 0.6; color: root.ringColor }
                GradientStop { position: 0.8; color: Qt.rgba(root.ringColor.r, root.ringColor.g, root.ringColor.b, 0.5) }
                GradientStop { position: 1.0; color: Qt.rgba(root.ringColor.r, root.ringColor.g, root.ringColor.b, 0) }
              }
            }
          }
        }
      }

      Repeater {
        model: surface.mine

        ShaderEffect {
          required property var modelData
          x: modelData.x
          y: modelData.y
          width: modelData.width
          height: modelData.height

          property size itemSize: Qt.size(width, height)
          property real radius: Math.max(root.opts.rounding, root.ringThickness)
          property real thickness: root.ringThickness
          property real phase: root.phase
          property real baseAlpha: 0
          property color ringColor: root.ringColor

          fragmentShader: Qt.resolvedUrl("ring.frag.qsb")
        }
      }
    }
  }
}
