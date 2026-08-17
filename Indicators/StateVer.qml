import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
Item {
        id: stateVer
        implicitHeight: 24
        implicitWidth: row.implicitWidth + 5
        property var rootWindow: null
        property alias containsMouse: stateVerMouseArea.containsMouse
        property string nixProfile: ""
        property bool tooltipOpen: false
        property bool tooltipReady: false
        onTooltipOpenChanged: {
                if (tooltipOpen) {
                        tooltipReady = true
                }
        }
        Timer {
                id: stateTooltipTimer
                interval: 400
                onTriggered: stateVer.tooltipOpen = stateVerMouseArea.containsMouse
        }
        Timer {
                id: stateTooltipCloseTimer
                interval: 200
                running: !stateVer.tooltipOpen && stateVer.tooltipReady
                onTriggered: stateVer.tooltipReady = false
        }
        Process {
                id: readlinkProcess
                command: ["sh", "-c", "readlink /nix/var/nix/profiles/system"]
                stdout: SplitParser {
                        onRead: function(data) {
                                stateVer.nixProfile = data.trim()
                        }
                }
        }
        Timer {
                interval: 60000
                repeat: true
                running: true
                triggeredOnStart: true
                onTriggered: readlinkProcess.running = true
        }
        Row {
                id: row
                anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                }
                spacing: 4
                Image {
                        source: "../icons/settings.svg"
                        sourceSize: Qt.size(20, 20)
                        anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                        text: stateVer.nixProfile
                        color: "#E8DBFF"
                        font {
                                family: "Monocraft"
                                pixelSize: 14
                        }
                        verticalAlignment: Text.AlignVCenter
                        visible: text !== ""
                }
        }
        MouseArea {
                id: stateVerMouseArea
                anchors.fill: parent
                hoverEnabled: true
                onContainsMouseChanged: {
                        if (containsMouse) {
                                stateTooltipTimer.restart()
                        } else {
                                stateTooltipTimer.stop()
                                stateVer.tooltipOpen = false
                        }
                }
        }
}
