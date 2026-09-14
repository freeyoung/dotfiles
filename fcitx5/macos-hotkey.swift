// Global Cmd+Space hotkey that toggles fcitx5 (keyboard-us <-> wbx).
//
// iTerm2 drops Cmd+key events before they reach the input method, so the
// fcitx5 TriggerKeys binding does not work there. A Carbon hotkey fires
// before any app sees the key, so it works in every app.
//
// The dotfiles installer builds this into ~/.local/bin/fcitx5-hotkey and runs
// it from ~/Library/LaunchAgents/com.eric.fcitx5-hotkey.plist.

import AppKit
import Carbon

let remote = "/Library/Input Methods/Fcitx5.app/Contents/bin/fcitx5-remote"

func log(_ message: String) {
    FileHandle.standardError.write("\(Date()) \(message)\n".data(using: .utf8)!)
}

func toggle() {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: remote)
    process.arguments = ["-t"]
    do {
        try process.run()
    } catch {
        log("cannot run fcitx5-remote: \(error)")
    }
}

var pressed = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                            eventKind: UInt32(kEventHotKeyPressed))
InstallEventHandler(GetApplicationEventTarget(), { _, _, _ in
    toggle()
    return noErr
}, 1, &pressed, nil, nil)

var hotKey: EventHotKeyRef?
let hotKeyID = EventHotKeyID(signature: OSType(0x4643_5458), id: 1) // "FCTX"
let status = RegisterEventHotKey(UInt32(kVK_Space), UInt32(cmdKey), hotKeyID,
                                 GetApplicationEventTarget(), 0, &hotKey)
guard status == noErr else {
    log("RegisterEventHotKey failed (\(status)); another app may own Cmd+Space")
    exit(1)
}
log("registered Cmd+Space")

let app = NSApplication.shared
app.setActivationPolicy(.prohibited)
app.run()
