import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "../Services"
Item {
        id: root
        implicitWidth: sessionIcon.implicitWidth
        implicitHeight: 28
        property var rootWindow: null
        property var lockScreen: null
        property bool popupOpen: false
        property bool popupReady: false
        property int hoveredIndex: -1
        function openLockScreen() {
                if (lockScreen) {
                        lockScreen.visible = true
                }
        }
        IpcHandler {
                id: sessionIpc
                target: "session"
                enabled: true
                function toggle() {
                        console.log("🔄 IPC toggle called")
                        if (root.popupOpen) {
                                root.popupOpen = false
                        } else {
                                closeTimer.stop()
                                root.popupReady = true
                                root.popupOpen = true
                                sessionIcon.scale = 1.25
                                scaleReset.start()
                        }
                }
                function poweroff() {
                        root.executeCommand("systemctl poweroff")
                }
                function reboot() {
                        root.executeCommand("systemctl reboot")
                }
                function suspend() {
                        root.suspendWithLock()
                }
                function lock() {
                        root.openLockScreen()
                }
        }
        Text {
                id: sessionIcon
                text: "\uf011"
                color: "#B58FFF"
                font {
                        family: "Font Awesome 6 Free"
                        pixelSize: 24
                        weight: Font.Bold
                }
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
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                        sessionIcon.scale = 1.25
                        scaleReset.start()
                        if (!root.popupOpen) {
                                closeTimer.stop()
                                root.popupReady = true
                                root.popupOpen = true
                        } else {
                                root.popupOpen = false
                        }
                }
        }
        Timer {
                id: scaleReset
                interval: 120
                repeat: false
                onTriggered: sessionIcon.scale = 1
        }
        Timer {
                id: closeTimer
                interval: 200
                running: !root.popupOpen && root.popupReady
                onTriggered: root.popupReady = false
        }
        PopupWindow {
                id: popup
                visible: root.popupReady
                grabFocus: true
                color: "transparent"
                anchor {
                        window: root.rootWindow
                        rect.x: root.x + (root.width - popup.implicitWidth) / 2
                        rect.y: root.y + root.height + 8
                }
                implicitWidth: 200
                implicitHeight: popupContent.implicitHeight + 24
                Rectangle {
                        anchors.fill: parent
                        color: "#000000"
                        radius: 16
                        clip: true
                        border {
                                color: "#B58FFF"
                                width: 3
                        }
                        opacity: root.popupOpen ? 1 : 0
                        scale: root.popupOpen ? 1 : 0.95
                        transformOrigin: Item.Top
                        Behavior on opacity {
                                NumberAnimation {
                                        duration: 200
                                        easing.type: Easing.OutQuad
                                }
                        }
                        Behavior on scale {
                                NumberAnimation {
                                        duration: 200
                                        easing.type: Easing.OutQuad
                                }
                        }
                        MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                propagateComposedEvents: true
                                onPressed: function(mouse) {
                                        mouse.accepted = true
                                }
                        }
                        Column {
                                id: popupContent
                                anchors {
                                        left: parent.left
                                        right: parent.right
                                        top: parent.top
                                        topMargin: 8
                                        leftMargin: 8
                                        rightMargin: 8
                                        bottomMargin: 8
                                }
                                spacing: 4
                                Item {
                                        width: parent.width
                                        height: 28
                                        Text {
                                                anchors {
                                                        left: parent.left
                                                        leftMargin: 8
                                                        verticalCenter: parent.verticalCenter
                                                }
                                                 text: Translation.tr("session.popup.title")
                                                color: "#E8DBFF"
                                                font {
                                                        family: "Monocraft"
                                                        pixelSize: 13
                                                        bold: true
                                                }
                                        }
                                        Rectangle {
                                                id: closeBtn
                                                anchors {
                                                        right: parent.right
                                                        rightMargin: 4
                                                        verticalCenter: parent.verticalCenter
                                                }
                                                width: 24
                                                height: 24
                                                radius: 6
                                                color: "transparent"
                                                border { color: "#4c3a70"; width: 1 }
                                                clip: true
                                                Rectangle {
                                                        id: closeHoverFill
                                                        anchors.centerIn: parent
                                                        width: 0
                                                        height: 0
                                                        radius: 6
                                                        color: "#B58FFF"
                                                        opacity: 0.2
                                                        Behavior on width {
                                                                NumberAnimation {
                                                                        duration: 300
                                                                        easing.type: Easing.OutQuad
                                                                }
                                                        }
                                                        Behavior on height {
                                                                NumberAnimation {
                                                                        duration: 300
                                                                        easing.type: Easing.OutQuad
                                                                }
                                                        }
                                                }
                                                Text {
                                                        anchors.centerIn: parent
                                                        text: "\uf00d"
                                                        color: "#B58FFF"
                                                        font {
                                                                family: "Monocraft"
                                                                pixelSize: 14
                                                        }
                                                }
                                                MouseArea {
                                                        id: closeArea
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor
                                                        onEntered: {
                                                                closeHoverFill.width = parent.width
                                                                closeHoverFill.height = parent.height
                                                        }
                                                        onExited: {
                                                                closeHoverFill.width = 0
                                                                closeHoverFill.height = 0
                                                        }
                                                        onClicked: root.popupOpen = false
                                                }
                                        }
                                }
                                Rectangle {
                                        width: parent.width
                                        height: 1
                                        color: "#3a3255"
                                }
				Repeater {
                                        id: listRepeater
                                        model: [
						{ icon: "", label: Translation.tr("session.lock"), color: "#B58FFF", cmd: "lock" },
						{ icon: "", label: Translation.tr("session.poweroff"), color: "#B58FFF", cmd: "systemctl poweroff" },
						{ icon: "", label: Translation.tr("session.reboot"), color: "#B58FFF", cmd: "systemctl reboot" },
						{ icon: "", label: Translation.tr("session.sleep"), color: "#B58FFF", cmd: "suspend" }
                                        ]
                                        delegate: Rectangle {
                                                id: itemDelegate
                                                width: parent.width
                                                height: 36
                                                radius: 8
                                                color: "transparent"
                                                border {
							color: root.hoveredIndex === index ? "#B58FFF" : "#4c3a70"
                                                        width: root.hoveredIndex === index ? 2 : 1
                                                }
                                                Behavior on border.color {
                                                        ColorAnimation { duration: 150 }
                                                }
                                                Rectangle {
                                                        id: capsule
                                                        anchors.fill: parent
                                                        radius: 8
                                                        color: "#B58FFF"
                                                        opacity: root.hoveredIndex === index ? 0.15 : 0
                                                        Behavior on opacity {
                                                                NumberAnimation { duration: 150 }
                                                        }
                                                }
                                                Row {
                                                        anchors {
                                                                left: parent.left
                                                                leftMargin: 12
                                                                verticalCenter: parent.verticalCenter
                                                        }
                                                        spacing: 10
                                                        Text {
                                                                text: modelData.icon
                                                                color: modelData.color
                                                                font {
                                                                        family: "Monocraft"
                                                                        pixelSize: 16
                                                                }
                                                                width: 22
                                                                height: 22
                                                                horizontalAlignment: Text.AlignHCenter
                                                                verticalAlignment: Text.AlignVCenter
                                                        }
                                                        Text {
                                                                text: modelData.label
                                                                color: root.hoveredIndex === index ? "#E8DBFF" : "#aaaaaa"
                                                                font {
                                                                        family: "Monocraft"
                                                                        pixelSize: 13
                                                                }
                                                                verticalAlignment: Text.AlignVCenter
                                                                height: 22
                                                                Behavior on color {
                                                                        ColorAnimation { duration: 150 }
                                                                }
                                                        }
                                                }
                                                MouseArea {
                                                        id: itemMouseArea
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor
                                                        onEntered: {
                                                                root.hoveredIndex = index
                                                        }
                                                        onExited: {
                                                                root.hoveredIndex = -1
                                                        }
                                                        onClicked: {
                                                                if (modelData.cmd === "lock") {
                                                                        root.openLockScreen()
                                                                } else if (modelData.cmd === "suspend") {
                                                                        root.suspendWithLock()
                                                                } else {
                                                                        root.executeCommand(modelData.cmd)
                                                                }
                                                                root.popupOpen = false
                                                        }
                                                }
                                                states: [
                                                        State {
                                                                name: "pressed"
                                                                when: itemMouseArea.pressed
                                                                PropertyChanges {
                                                                        target: itemDelegate
                                                                        scale: 0.96
                                                                }
                                                        }
                                                ]
                                                transitions: [
                                                        Transition {
                                                                from: ""
                                                                to: "pressed"
                                                                NumberAnimation {
                                                                        property: "scale"
                                                                        duration: 100
                                                                        easing.type: Easing.OutQuad
                                                                }
                                                        },
                                                        Transition {
                                                                from: "pressed"
                                                                to: ""
                                                                NumberAnimation {
                                                                        property: "scale"
                                                                        duration: 100
                                                                        easing.type: Easing.OutQuad
                                                                }
                                                        }
                                                ]
                                        }
                                }
                        }
                }
                Keys.onPressed: {
                        if (event.key === Qt.Key_Escape) {
                                root.popupOpen = false
                                event.accepted = true
                        }
                        if (event.key === Qt.Key_Up) {
                                if (root.hoveredIndex > 0) {
                                        root.hoveredIndex--
                                } else {
                                        root.hoveredIndex = listRepeater.count - 1
                                }
                                event.accepted = true
                        }
                        if (event.key === Qt.Key_Down) {
                                if (root.hoveredIndex < listRepeater.count - 1) {
                                        root.hoveredIndex++
                                } else {
                                        root.hoveredIndex = 0
                                }
                                event.accepted = true
                        }
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                if (root.hoveredIndex >= 0 && root.hoveredIndex < listRepeater.count) {
                                        var item = listRepeater.model[root.hoveredIndex]
                                        if (item.cmd === "lock") {
                                                root.openLockScreen()
                                        } else if (item.cmd === "suspend") {
                                                root.suspendWithLock()
                                        } else {
                                                root.executeCommand(item.cmd)
                                        }
                                        root.popupOpen = false
                                }
                                event.accepted = true
                        }
                }
        }
        function executeCommand(cmd) {
                Quickshell.execDetached(["sh", "-c", cmd])
                if (cmd.includes("systemctl reboot") || cmd.includes("systemctl poweroff")) {
                        Qt.callLater(function() {
                                Qt.quit()
                        }, 1000)
                }
        }
        function suspendWithLock() {
                root.openLockScreen()
                suspendTimer.start()
        }
        Timer {
                id: suspendTimer
                interval: 300
                repeat: false
                onTriggered: {
                        Quickshell.execDetached(["systemctl", "suspend"])
                }
        }
        Component.onCompleted: {
                Ipc.registerObject("session", root)
                console.log("✅ SessionMenu registered in IPC as 'session'")
        }
        Component.onDestruction: {
                Ipc.unregisterObject("session")
        }
}
