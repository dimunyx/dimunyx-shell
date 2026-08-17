import Quickshell
import Quickshell.Io
import QtQuick
import "../Components" as MD3
import QtQuick.Layouts
import "../Services/WM"
Item {
        id: niriVer
        implicitHeight: 24
        implicitWidth: row.implicitWidth + 6
        property var rootWindow: null
        property alias containsMouse: niriMouseArea.containsMouse
        property bool pctVisible: false
        Row {
                id: row
                anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                }
                spacing: 0
                Image {
                        id: wmIcon
                        source: "../icons/" + WM.iconSource
                        sourceSize: Qt.size(20, 20)
                        fillMode: Image.PreserveAspectFit
                        anchors {
                                verticalCenter: parent.verticalCenter
                        }
                }
                Item {
                        id: versionWrap
                        width: niriMouseArea.containsMouse ? versionText.implicitWidth + 4 : 0
                        height: parent.height
                        clip: true
                        Behavior on width {
                                NumberAnimation {
                                        duration: 200
                                        easing.type: Easing.OutQuad
                                }
                        }
                        Text {
                                id: versionText
                                anchors.verticalCenter: parent.verticalCenter
                                text: WM.version
                                color: "#cdd6f4"
                                opacity: niriMouseArea.containsMouse ? 1 : 0
                                font {
                                        family: "Monocraft"
                                        pixelSize: 14
                                }
                                verticalAlignment: Text.AlignVCenter
                                visible: text !== ""
                                Behavior on opacity {
                                        NumberAnimation {
                                                duration: 150
                                                easing.type: Easing.OutQuad
                                        }
                                }
                        }
                }
        }
        MD3.Pressable {
                id: niriMouseArea
                anchors.fill: parent
                hoverEnabled: true
                onContainsMouseChanged: {
                        if (containsMouse) {
                                niriVer.pctVisible = true
                        } else {
                                niriVer.pctVisible = false
                        }
                }
        }
}
