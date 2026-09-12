import QtQuick
import QtQml
import Quickshell
import Quickshell.Io
import Qt.labs.folderlistmodel
import qs.Commons
import qs.Ui

// The bar's view of every Claude Code session on the machine: one dot per
// state, in the same colours the kitty tab bar and iTerm2's cc-status use.
// Orange spins while a session works, blue blinks while one waits for the
// user, green sits still for a finished turn. A click raises the window and
// tab of the session that needs attention most.
//
// The records are the ones bin/claude-tab-status writes for each session.
// Reading them is the whole job here; nothing in this file knows about Claude.
BarWidget {
  id: root
  moduleName: "eric.claude"

  readonly property string stateDir: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/claude-tabs"
  readonly property var colors: ({ working: "#ff9500", waiting: "#5f87ff", idle: "#00d75f" })
  // The tooltip is one plain-text label in one colour, so the state colours
  // travel as emoji there, the same ones the kitty window titles use.
  readonly property var emoji: ({ working: "🟠", waiting: "🔵", idle: "🟢" })
  readonly property var order: ["waiting", "working", "idle"]
  // One size for every state. A spinning glyph was bigger than the dots beside
  // it however the font size was set, since it is drawn from a different part
  // of the font; these are drawn, not typeset, so they match exactly. The
  // motion a working session used to carry here is the ring around its tab.
  readonly property int dotSize: Style.space(8)
  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  // Records sorted most urgent first, so [0] is what a click goes to.
  property var sessions: []

  // The bar shows a tooltip only for a target that says it is hovered, and
  // tells a press on a widget from a press that starts dragging the bar by
  // the targets registered with it. Omarchy's WidgetButton does both; this
  // widget is not built on it, so it does them itself.
  readonly property bool tooltipHovered: visible && hoverArea.containsMouse
  readonly property bool interactive: true
  readonly property bool pressable: true
  property var registeredBar: null

  // What the bar calls when a press it intercepted lands on this widget.
  function triggerPress(button) {
    if (bar) bar.hideTooltip(root)
    focusTop()
  }

  function syncClickRegistration() {
    if (registeredBar && registeredBar.unregisterClickTarget) registeredBar.unregisterClickTarget(root)
    registeredBar = root.bar
    if (registeredBar && registeredBar.registerClickTarget) registeredBar.registerClickTarget(root)
  }

  onBarChanged: syncClickRegistration()
  onVisibleChanged: if (!visible && bar) bar.hideTooltip(root)
  Component.onCompleted: syncClickRegistration()
  Component.onDestruction: if (registeredBar && registeredBar.unregisterClickTarget) registeredBar.unregisterClickTarget(root)

  readonly property int waitingCount: count("waiting")
  readonly property int workingCount: count("working")
  readonly property int idleCount: count("idle")

  visible: sessions.length > 0
  implicitWidth: vertical ? barSize : pills.implicitWidth + 12
  implicitHeight: vertical ? pills.implicitHeight + 12 : barSize

  function rank(record) {
    var index = order.indexOf(record.state)
    return index < 0 ? order.length : index
  }

  function count(state) {
    var n = 0
    for (var i = 0; i < sessions.length; i++) if (sessions[i].state === state) n++
    return n
  }

  function refresh() {
    var list = []
    for (var i = 0; i < records.count; i++) {
      var item = records.objectAt(i)
      if (item && item.record && item.record.state) list.push(item.record)
    }
    list.sort(function(a, b) {
      return rank(a) - rank(b) || (b.updated || 0) - (a.updated || 0)
    })
    sessions = list
  }

  function focusTop() {
    if (!bar || sessions.length === 0) return
    bar.run("claude-tab-status focus " + Util.shellQuote(String(sessions[0].session_id)))
  }

  function label(record) {
    var where = String(record.cwd || "").split("/").filter(Boolean).pop() || "~"
    var detail = String(record.detail || "")
    var line = record.state + " · " + where
    if (record.state === "waiting" && detail) line += " · " + detail
    return line
  }

  function tooltipText() {
    var lines = []
    for (var i = 0; i < sessions.length; i++) lines.push((emoji[sessions[i].state] || "⚪") + " " + label(sessions[i]))
    return lines.join("\n")
  }

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

  // One watcher per record file. The hook replaces a record atomically, so
  // the file watch sees a rename rather than a write; the timer below covers
  // whichever of the two the watcher misses.
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
          item.parse(text())
          root.refresh()
        }
        onLoadFailed: {
          item.record = null
          root.refresh()
        }
      }

      function parse(content) {
        try {
          var parsed = JSON.parse(String(content || ""))
          record = parsed && typeof parsed === "object" ? parsed : null
        } catch (e) {
          record = null
        }
      }
    }
    onObjectAdded: root.refresh()
    onObjectRemoved: root.refresh()
  }

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

  Grid {
    id: pills
    anchors.centerIn: parent
    columns: root.vertical ? 1 : 3
    rowSpacing: 2
    columnSpacing: 8

    Repeater {
      model: root.order
      delegate: Row {
        id: pill
        required property string modelData
        readonly property int n: root.count(modelData)
        visible: n > 0
        spacing: 3

        Rectangle {
          id: dot
          anchors.verticalCenter: parent.verticalCenter
          implicitWidth: root.dotSize
          implicitHeight: root.dotSize
          radius: root.dotSize / 2
          color: root.colors[pill.modelData]
          antialiasing: true

          SequentialAnimation on opacity {
            running: pill.modelData === "waiting" && pill.n > 0
            loops: Animation.Infinite
            NumberAnimation { to: 0.25; duration: 500 }
            NumberAnimation { to: 1; duration: 500 }
            onRunningChanged: if (!running) dot.opacity = 1
          }
        }

        Text {
          anchors.verticalCenter: parent.verticalCenter
          visible: pill.n > 1
          text: String(pill.n)
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }
      }
    }
  }

  MouseArea {
    id: hoverArea
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton
    cursorShape: Qt.PointingHandCursor
    onEntered: if (root.bar) root.bar.showTooltip(root, root.tooltipText())
    onExited: if (root.bar) root.bar.hideTooltip(root)
    onClicked: function(mouse) { root.triggerPress(mouse.button) }
  }
}
