import QtQuick
import Quickshell
import Quickshell.Io
OSDWindow {
    id: root
    property int brightness: 0
    property int brightnessPct: 0
    property int maxBrightness: 100
    property bool ready: false
    property int prevBrightnessPct: -1
    iconText: brightnessPct === 0 ? "\udb80\udcde" : (brightnessPct < 33 ? "\udb80\udcdd" : (brightnessPct < 66 ? "\udb80\udcdf" : "\udb80\udce0"))
    labelText: brightnessPct + "%"
    value: brightnessPct / 100
    accentColor: "#89b4fa"
    showProgress: true
    Process {
        id: maxProc
        command: ["brightnessctl", "max"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: function() {
                var mx = parseInt(text.trim())
                if (!isNaN(mx) && mx > 0) {
                    root.maxBrightness = mx
                }
                getProc.running = true
            }
        }
    }
    Process {
        id: getProc
        command: ["brightnessctl", "get"]
        stdout: StdioCollector {
            onStreamFinished: function() {
                var cur = parseInt(text.trim())
                if (!isNaN(cur)) {
                    root.brightness = cur
                    root.brightnessPct = Math.round(cur / root.maxBrightness * 100)
                }
            }
        }
    }
    Timer {
        interval: 100
        repeat: true
        running: true
        onTriggered: getProc.running = true
    }
    Timer {
        interval: 300
        running: true
        onTriggered: root.ready = true
    }
    onBrightnessPctChanged: {
        if (brightnessPct !== prevBrightnessPct) {
            prevBrightnessPct = brightnessPct
            if (ready) root.show()
        }
    }
}
