import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "../Services/WM"
import "../Components" as MD3
Item {
        id: root
        implicitWidth: 220
        implicitHeight: 24
        property bool scrollCooldown: false
        property int pendingIndex: -1
        ListModel {
                id: workspaceModel
        }
        property var workspaces: WM.workspaces
        onWorkspacesChanged: {
                var json = workspaces ? workspaces.slice() : []
                json.sort(function(a,b) { return a.idx - b.idx })
                while (workspaceModel.count > json.length) {
                        workspaceModel.remove(workspaceModel.count - 1)
                }
                while (workspaceModel.count < json.length) {
                        var idx = workspaceModel.count
                        workspaceModel.append({
                                idx: json[idx].idx,
                                focused: json[idx].focused,
                                occupied: json[idx].occupied
                        })
                }
                for (var i = 0; i < json.length; i++) {
                        var ws = json[i]
                        workspaceModel.setProperty(i, "idx", ws.idx)
                        workspaceModel.setProperty(i, "focused", ws.focused)
                        workspaceModel.setProperty(i, "occupied", ws.occupied)
                        if (ws.focused && pendingIndex === ws.idx)
                                pendingIndex = -1
                }
        }
        Timer {
                id: pendingResetTimer
                interval: 500
                onTriggered: root.pendingIndex = -1
        }
        function changeWorkspace(direction) {
                let current = -1
                for (let i = 0; i < workspaceModel.count; i++) {
                        if (workspaceModel.get(i).focused) {
                                current = i
                                break
                        }
                }
                if (current === -1)
                return
                let next = current + direction
                if (next < 0)
                next = workspaceModel.count - 1
                if (next >= workspaceModel.count)
                next = 0
                let ws = workspaceModel.get(next)
                if (ws) {
                        WM.switchWorkspace(ws.idx)
                }
        }
        Timer {
                id: scrollTimer
                interval: 10
                repeat: false
                onTriggered: {
                        root.scrollCooldown = false
                }
        }
        WheelHandler {
                id: wheelHandler
                target: root
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: function(event) {
                        if (root.scrollCooldown)
                        return
                        if (event.angleDelta.y > 0) {
                                root.changeWorkspace(-1)
                        } else if (event.angleDelta.y < 0) {
                                root.changeWorkspace(1)
                        } else {
                                return
                        }
                        root.scrollCooldown = true
                        scrollTimer.restart()
                        event.accepted = true
                }
        }
        Row {
                id: workspaceRow
                anchors.centerIn: parent
                spacing: 6
                Repeater {
                        model: workspaceModel
                        delegate: Rectangle {
                                required property bool focused
                                required property bool occupied
                                required property int idx
                                property bool pressed: workspaceMouse.pressed
                                width: focused || root.pendingIndex === idx ? 40 : 24
                                height: 24
                                radius: 12
                                color: {
                                if (focused)
                                        return MD3.Theme.primary
                                if (occupied)
                                        return Qt.rgba(
                                                MD3.Theme.primary.r,
                                                MD3.Theme.primary.g,
                                                MD3.Theme.primary.b,
                                                0.9
                                        )
                                        return MD3.Theme.outlineVariant
                                }
                                Behavior on width {
                                        NumberAnimation {
                                                duration: 175
                                                easing {
                                                        type: Easing.OutBack
                                                }
                                        }
                                }
                                Behavior on color {
                                        ColorAnimation {
                                                duration: 150
                                                easing {
                                                        type: Easing.InOutCubic
                                                }
                                        }
                                }
                                Behavior on scale {
                                        NumberAnimation {
                                                duration: 90
                                                easing.type: Easing.OutQuad
                                        }
                                }
                                scale: pressed ? 0.94 : 1
                                MouseArea {
                                        id: workspaceMouse
                                        anchors {
                                                fill: parent
                                        }
                                        hoverEnabled: false
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                                root.pendingIndex = idx
                                                pendingResetTimer.restart()
                                                WM.switchWorkspace(idx)
                                        }
                                }
                        }
                }
        }
}
