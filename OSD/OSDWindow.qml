import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
PanelWindow {
    id: root
    property real value: 0
    property string iconText: ""
    property string labelText: ""
    property color accentColor: "#89b4fa"
    property bool showProgress: true
    visible: false
    color: "transparent"
    focusable: false
    implicitWidth: 240
    implicitHeight: 56
    anchors {
        top: true
        right: true
    }
    margins {
        top: 50
        right: 12
    }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.namespace: "osd"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    function show() {
        hideAnim.stop()
        popup.opacity = 0
        popup.scale = 0.95
        visible = true
        showAnim.start()
        dismissTimer.restart()
    }
    function hide() {
        hideAnim.start()
    }
    Timer {
        id: dismissTimer
        interval: 1500
        onTriggered: root.hide()
    }
    ParallelAnimation {
        id: showAnim
        NumberAnimation { target: popup; property: "opacity"; from: 0; to: 1; duration: 200; easing.type: Easing.OutQuad }
        NumberAnimation { target: popup; property: "scale"; from: 0.95; to: 1; duration: 200; easing.type: Easing.OutQuad }
    }
    ParallelAnimation {
        id: hideAnim
        NumberAnimation { target: popup; property: "opacity"; from: 1; to: 0; duration: 200; easing.type: Easing.OutQuad }
        NumberAnimation { target: popup; property: "scale"; from: 1; to: 0.95; duration: 200; easing.type: Easing.OutQuad }
        onFinished: root.visible = false
    }
    Rectangle {
        id: popup
        anchors.fill: parent
        color: "#ee313244"
        radius: 16
        border { color: root.accentColor; width: 1 }
        opacity: 0
        scale: 0.95
        transformOrigin: Item.Top
        Rectangle {
            id: closeBtn
            anchors { right: parent.right; top: parent.top; margins: 6 }
            width: 18
            height: 18
            radius: 5
            color: "transparent"
            border { color: closeArea.containsMouse ? "#89b4fa" : "#45475a"; width: 1 }
            clip: true
            z: 10
            Rectangle {
                id: closeHoverFill
                anchors.centerIn: parent
                width: closeArea.containsMouse ? parent.width : 0
                height: closeArea.containsMouse ? parent.height : 0
                radius: 5
                color: "#89b4fa"
                opacity: 0.2
                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuad } }
                Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutQuad } }
            }
        }
        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            anchors.rightMargin: 28
            spacing: 10
            Text {
                text: root.iconText
                color: root.accentColor
                font { family: "Monocraft"; pixelSize: 22 }
                Layout.alignment: Qt.AlignVCenter
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text {
                    text: root.labelText
                    color: "#cdd6f4"
                    font { family: "Monocraft"; pixelSize: 12 }
                    Layout.alignment: Qt.AlignVCenter
                }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 6
                    radius: 3
                    color: "#45475a"
                    visible: root.showProgress
                    Rectangle {
                        width: parent.width * Math.max(0, Math.min(1, root.value))
                        height: parent.height
                        radius: 3
                        color: root.accentColor
                        Behavior on width { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }
                    }
                }
            }
        }
    }
}
