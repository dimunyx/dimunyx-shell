import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property bool active: false

    property var workspaces: []
    property var windows: []
    property var keyboardLayouts: ({names: [], current_idx: -1})
    property string version: ""
    property string iconSource: "hyprland.svg"

    property string _kbDeviceName: ""
    property var _kbNames: []

    Process {
        id: workspaceProcess
        command: ["sh", "-c", "echo 'WS='; hyprctl workspaces -j 2>/dev/null; echo ''; echo 'ACTIVE='; hyprctl activeworkspace -j 2>/dev/null"]
        running: root.active
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var text = this.text.trim()
                    var wsMarker = text.lastIndexOf('WS=')
                    var activeMarker = text.lastIndexOf('ACTIVE=')
                    if (wsMarker < 0 || activeMarker < 0) return

                    var wsText = text.substring(wsMarker + 3, activeMarker).trim()
                    var activeText = text.substring(activeMarker + 7).trim()

                    var all = JSON.parse(wsText)
                    var activeId = -1
                    if (activeText) {
                        try {
                            var active = JSON.parse(activeText)
                            activeId = active ? active.id : -1
                        } catch(e) {}
                    }

                    var mapped = []
                    for (var i = 0; i < all.length; i++) {
                        var ws = all[i]
                        mapped.push({
                            idx: ws.id,
                            focused: ws.id === activeId,
                            occupied: ws.windows > 0
                        })
                    }
                    mapped.sort(function(a,b) { return a.idx - b.idx })
                    root.workspaces = mapped
                } catch(e) {
                    console.warn("Hyprland workspaces parse error:", e)
                }
            }
        }
        onExited: wsRestartTimer.start()
    }

    Timer {
        id: wsRestartTimer
        interval: 10
        onTriggered: workspaceProcess.running = root.active
    }

    Process {
        id: windowsProcess
        command: ["sh", "-c", "hyprctl clients -j 2>/dev/null || echo '[]'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var parsed = JSON.parse(this.text)
                    if (Array.isArray(parsed)) {
                        var mapped = []
                        for (var i = 0; i < parsed.length; i++) {
                            var c = parsed[i]
                            mapped.push({
                                id: c.address,
                                title: c.title || "",
                                app_id: c.class || "",
                                is_focused: c.focusHistoryID === 0,
                                workspace_id: c.workspace ? c.workspace.id : 0
                            })
                        }
                        root.windows = mapped
                    }
                } catch(e) {
                    root.windows = []
                    console.warn("Hyprland windows parse error:", e)
                }
            }
        }
    }

    function refreshWindows() {
        windowsProcess.running = true
    }

    Process {
        id: kbProcess
        command: ["sh", "-c", "hyprctl devices -j 2>/dev/null"]
        running: root.active
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var json = JSON.parse(this.text.trim())
                    var keyboards = json.keyboards || []
                    var mainKb = null
                    for (var i = 0; i < keyboards.length; i++) {
                        if (keyboards[i].main) { mainKb = keyboards[i]; break }
                    }
                    if (!mainKb && keyboards.length > 0) mainKb = keyboards[0]
                    if (mainKb) {
                        root._kbDeviceName = mainKb.name
                        var layoutStr = mainKb.layout || ""
                        var codes = layoutStr.split(",").map(function(s) { return s.trim() }).filter(function(s) { return s })
                        root._kbNames = codes

                        var activeKeymap = mainKb.active_keymap || ""
                        var parenMatch = activeKeymap.match(/\(([^)]+)\)/)
                        var currentCode = parenMatch ? parenMatch[1] : activeKeymap
                        currentCode = currentCode.toLowerCase().trim()

                        var keymapToLayout = {
                            "russian": "ru",
                            "german": "de",
                            "french": "fr",
                            "spanish": "es",
                            "ukrainian": "ua",
                            "belarusian": "by",
                            "japanese": "jp",
                            "chinese": "cn",
                            "korean": "kr",
                            "brazilian": "br"
                        }
                        if (keymapToLayout[currentCode]) {
                            currentCode = keymapToLayout[currentCode]
                        }

                        var currentIdx = 0
                        for (var j = 0; j < codes.length; j++) {
                            if (codes[j].toLowerCase() === currentCode) {
                                currentIdx = j
                                break
                            }
                        }

                        root.keyboardLayouts = {
                            names: codes,
                            current_idx: currentIdx
                        }
                    }
                } catch(e) {
                    console.warn("Hyprland kblayout parse error:", e)
                }
            }
        }
        onExited: kbRestartTimer.start()
    }

    Timer {
        id: kbRestartTimer
        interval: 100
        onTriggered: kbProcess.running = root.active
    }

    Process {
        id: verProcess
        command: ["sh", "-c", "hyprctl version 2>/dev/null | head -1 | awk '{print $2}'"]
        running: root.active
        stdout: StdioCollector {
            onStreamFinished: {
                root.version = this.text.trim()
            }
        }
    }

    Process {
        id: wsSwitchProcess
        command: ["sh", "-c", "true"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                console.warn("wsSwitchProcess stdout: " + this.text.trim())
            }
        }
        onExited: {
            console.warn("wsSwitchProcess exited: " + exitCode)
        }
    }

    Process {
        id: kblSwitchProcess
        command: ["sh", "-c", "true"]
        running: false
    }

    Process {
        id: winFocusProcess
        command: ["sh", "-c", "true"]
        running: false
    }

    function switchWorkspace(idx) {
        var cmd = 'hyprctl dispatch "hl.dsp.focus({ workspace = \\"' + String(idx) + '\\" })" 2>&1'
        console.warn("Hyprland.switchWorkspace: running " + cmd)
        wsSwitchProcess.command = ["sh", "-c", cmd]
        wsSwitchProcess.running = true
    }

    function switchLayout(idx) {
        if (root._kbDeviceName) {
            var cmd = "hyprctl switchxkblayout '" + root._kbDeviceName + "' " + String(idx) + " 2>&1"
            kblSwitchProcess.command = ["sh", "-c", cmd]
            kblSwitchProcess.running = true
        }
    }

    function focusWindow(id) {
        winFocusProcess.command = ["sh", "-c", 'hyprctl dispatch "hl.dsp.focus({ address = \\"' + id + '\\" })" 2>&1']
        winFocusProcess.running = true
    }
}
