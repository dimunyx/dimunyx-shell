import Quickshell
import Quickshell.Io
import QtQuick
import Quickshell.Widgets
Item {
        id: launcher
        implicitHeight: 20
        implicitWidth: 26
        property var rootWindow: null
        property string distroIcon: "../icons/NixOS.svg"
        signal clicked()
        Process {
                id: distroDetect
                command: ["sh", "-c", ". /etc/os-release 2>/dev/null; echo \"${ID:-unknown}\""]
                stdout: StdioCollector {
                        onStreamFinished: {
                                var id = text.trim().toLowerCase()
                                if (id === "arch") {
                                        launcher.distroIcon = "../icons/Arch.svg"
                                }
                        }
                }
        }
        Component.onCompleted: distroDetect.running = true
        Image {
                id: launcherIconImg
                source: distroIcon
                sourceSize: Qt.size(20, 20)
                scale: 1
                anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                }
                Behavior on scale {
                        NumberAnimation {
                                duration: 150
                                easing.type: Easing.OutBack
                        }
                }
        }
        MouseArea {
                id: launcherMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                        launcherIconImg.scale = 1.25
                        launcherReset.start()
                        launcher.clicked()
                }
        }
        Timer {
                id: launcherReset
                interval: 120
                repeat: false
                onTriggered: launcherIconImg.scale = 1
        }
}
