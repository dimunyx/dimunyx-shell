import QtQuick
import Quickshell
import Quickshell.Io
import "../Services"
OSDWindow {
    id: root
    property string currentProfile: "balanced"
    property bool ready: false
    property string prevProfile: ""
    readonly property var profiles: ({
        "performance": { label: Translation.tr("power.performance"), icon: "\udb81\udcc5" },
        "balanced": { label: Translation.tr("power.balanced"), icon: "\udb83\udf85" },
        "power-saver": { label: Translation.tr("power.power-saver"), icon: "\udb83\udf86" }
    })
    iconText: profiles[currentProfile]?.icon ?? "\udb83\udf85"
    labelText: profiles[currentProfile]?.label ?? currentProfile
    value: 1
    accentColor: "#89b4fa"
    showProgress: false
    Process {
        id: pollProc
        command: ["powerprofilesctl", "get"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: function() {
                var prof = text.trim()
                if (prof && prof !== root.currentProfile) {
                    root.currentProfile = prof
                    if (root.ready && root.prevProfile !== "") {
                        root.show()
                    }
                    root.prevProfile = prof
                } else if (root.prevProfile === "") {
                    root.prevProfile = prof
                }
            }
        }
    }
    Timer {
        interval: 250
        repeat: true
        running: true
        onTriggered: pollProc.running = true
    }
    Timer {
        interval: 300
        running: true
        onTriggered: root.ready = true
    }
}
