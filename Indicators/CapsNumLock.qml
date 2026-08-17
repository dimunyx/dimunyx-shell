import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
Item {
        id: root
        implicitHeight: 24
        implicitWidth: row.implicitWidth + 6
        property color activeColor: "#B58FFF"
        property color inactiveColor: "#4c3a70"
        property bool capsOn: false
        property bool numOn: false
        Process {
                id: ledsProcess
                command: ["sh", "-c", "CAPS=$(cat /sys/class/leds/input*::capslock/brightness 2>/dev/null || echo 0); NUM=$(cat /sys/class/leds/input*::numlock/brightness 2>/dev/null || echo 0); echo \"CAPS:$CAPS|NUM:$NUM\""]
                stdout: SplitParser {
                        onRead: function(data) {
                                if (data.includes("CAPS:")) {
                                        root.capsOn = data.includes("CAPS:1")
                                }
                                if (data.includes("NUM:")) {
                                        root.numOn = data.includes("NUM:1")
                                }
                        }
                }
        }
        Timer {
                interval: 100
                repeat: true
                running: true
                onTriggered: ledsProcess.running = true
        }
        Row {
                id: row
                anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                }
                spacing: 4
                Text {
                        text: "C"
                        color: root.capsOn ? root.activeColor : root.inactiveColor
                        font {
                                family: "Monocraft"
                                pixelSize: 16
                                bold: root.capsOn
                        }
                }
                Text {
                        text: "N"
                        color: root.numOn ? root.activeColor : root.inactiveColor
                        font {
                                family: "Monocraft"
                                pixelSize: 16
                                bold: root.numOn
                        }
                }
        }
}
