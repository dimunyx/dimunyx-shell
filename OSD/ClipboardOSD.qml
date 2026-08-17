import QtQuick
import Quickshell
import Quickshell.Io
import "../Services"
OSDWindow {
    id: root
    property bool wasEmpty: true
    property bool ready: false
    iconText: "\uf0ea"
    labelText: Translation.tr("osd.clipboard.cleared")
    value: 1
    accentColor: "#B58FFF"
    showProgress: false
    Process {
        id: pollProc
        command: ["sh", "-c", "wl-paste --no-newline 2>/dev/null || true"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: function() {
                var content = text.trim()
                var isEmpty = content === ""
                if (!root.ready) {
                    root.wasEmpty = isEmpty
                    return
                }
                if (isEmpty && !root.wasEmpty) {
                    root.wasEmpty = true
                    root.show()
                } else if (!isEmpty) {
                    root.wasEmpty = false
                }
            }
        }
        onExited: pollTimer.start()
    }
    Timer {
        id: pollTimer
        interval: 100
        onTriggered: pollProc.running = true
    }
    Timer {
        interval: 300
        running: true
        onTriggered: root.ready = true
    }
}
