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
    property string iconSource: "niri.svg"

    Process {
        id: workspaceProcess
        command: ["niri", "msg", "--json", "workspaces"]
        running: root.active
        stdout: SplitParser {
            onRead: function(data) {
                try {
                    var json = JSON.parse(data)
                    json.sort(function(a,b) { return a.idx - b.idx })
                    var mapped = []
                    for (var i = 0; i < json.length; i++) {
                        var ws = json[i]
                        mapped.push({
                            idx: ws.idx,
                            focused: ws.is_focused,
                            occupied: ws.active_window_id !== null
                        })
                    }
                    root.workspaces = mapped
                } catch(e) {
                    console.warn("Niri workspaces parse error:", e)
                }
            }
        }
    }

    Timer {
        interval: 150
        running: root.active
        repeat: true
        onTriggered: {
            workspaceProcess.running = false
            workspaceProcess.running = true
        }
    }

    Process {
        id: windowsProcess
        command: ["sh", "-c", "niri msg -j windows 2>/dev/null || echo '[]'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var parsed = JSON.parse(this.text)
                    root.windows = Array.isArray(parsed) ? parsed : []
                } catch(e) {
                    root.windows = []
                    console.warn("Niri windows parse error:", e)
                }
            }
        }
    }

    function refreshWindows() {
        windowsProcess.running = true
    }

    Process {
        id: kbProcess
        command: ["niri", "msg", "--json", "keyboard-layouts"]
        running: root.active
        stdout: SplitParser {
            onRead: function(data) {
                try {
                    var json = JSON.parse(data)
                    root.keyboardLayouts = {
                        names: json.names,
                        current_idx: json.current_idx
                    }
                } catch(e) {
                    console.warn("Niri kblayout parse error:", e)
                }
            }
        }
        onExited: kbRestartTimer.start()
    }

    Timer {
        id: kbRestartTimer
        interval: 100
        onTriggered: kbProcess.running = true
    }

    Process {
        id: verProcess
        command: ["sh", "-c", "niri --version | awk '{print $2}'"]
        running: root.active
        stdout: SplitParser {
            onRead: function(data) {
                root.version = data.trim()
            }
        }
    }

    Process {
        id: wsSwitchProcess
        command: ["niri", "msg", "action", "focus-workspace", ""]
        running: false
    }

    Process {
        id: kblSwitchProcess
        command: ["niri", "msg", "action", "switch-layout", ""]
        running: false
    }

    Process {
        id: winFocusProcess
        command: ["sh", "-c", "true"]
        running: false
    }

    function switchWorkspace(idx) {
        wsSwitchProcess.command = ["niri", "msg", "action", "focus-workspace", String(idx)]
        wsSwitchProcess.running = true
    }

    function switchLayout(idx) {
        kblSwitchProcess.command = ["niri", "msg", "action", "switch-layout", String(idx)]
        kblSwitchProcess.running = true
    }

    function focusWindow(id) {
        winFocusProcess.command = ["sh", "-c", "niri msg action focus-window --id " + id + " 2>/dev/null"]
        winFocusProcess.running = true
    }
}
