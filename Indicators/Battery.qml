import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import QtQuick
import "../Components" as MD3
import QtQuick.Layouts
import "../Services"
Item {
        id: root
        implicitWidth: capsule.width + 14
        implicitHeight: 32
        property var rootWindow: null
        property bool popupOpen: false
        property bool popupReady: false
        property int percent: 0
        property bool charging: false
        property bool pluggedIn: false
        property bool ready: false
        property bool low: false
        property bool critical: false
        property color accent: "#89b4fa"
        property string timeText: ""
        property string rateText: ""
        function refreshState() {
                var dev = UPower.displayDevice
                if (!dev || !dev.isPresent) {
                        root.ready = false
                        root.percent = 0
                        return
                }
                root.ready = dev.percentage !== undefined
                root.percent = Math.round((dev.percentage || 0) * 100)
                root.charging = dev.state === UPowerDeviceState.Charging
                root.pluggedIn = dev.state === UPowerDeviceState.FullyCharged || dev.state === UPowerDeviceState.PendingCharge
                root.low = !root.charging && !root.pluggedIn && root.percent <= 20 && root.percent > 10
                root.critical = !root.charging && !root.pluggedIn && root.percent <= 10
                root.accent = root.critical ? "#FF0000" : (root.low ? "#FF6B6B" : "#89b4fa")
                if (root.pluggedIn) {
                        root.timeText = Translation.tr("battery.connected")
                } else if (dev.timeToFull > 0) {
                        root.timeText = Translation.trf("battery.until.full", formatDuration(dev.timeToFull))
                } else if (dev.timeToEmpty > 0) {
                        root.timeText = Translation.trf("battery.remaining", formatDuration(dev.timeToEmpty))
                } else {
                        root.timeText = ""
                }
                if (dev.changeRate !== undefined) {
                        root.rateText = Math.abs(dev.changeRate).toFixed(2) + "W"
                } else {
                        root.rateText = ""
                }
        }
        function formatDuration(secs) {
                var h = Math.floor(secs / 3600)
                var m = Math.floor((secs % 3600) / 60)
                if (h > 0) {
                        return h + "h " + m + "m"
                }
                return m + "m"
        }
        Timer {
                interval: 500
                repeat: true
                running: true
                onTriggered: refreshState()
        }
        Component.onCompleted: refreshState()
        Rectangle {
                id: capsule
                width: 36
                height: 18
                radius: 20
                color: "#181825"
                border {
                        color: "#45475a"
                        width: 0.5
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
                Behavior on color {
                        ColorAnimation {
                                duration: 150
                                easing.type: Easing.InOutCubic
                        }
                }
                Rectangle {
                        width: parent.width * Math.max(0, Math.min(1, root.percent / 100))
                        height: parent.height
                        radius: 20
                        color: "#89b4fa"
                        opacity: 1.0
                        clip: true
                        Behavior on width {
                                NumberAnimation {
                                        duration: 300
                                        easing.type: Easing.OutQuad
                                }
                        }
                }
                Text {
                        id: centerText
                        anchors.centerIn: parent
                        text: root.ready ? root.percent + "%" : "?"
                        color: "#cdd6f4"
                        font {
                                family: "Monocraft"
                                pixelSize: 10
                                bold: true
                        }
                        opacity: {
                                if (root.charging || root.pluggedIn) {
                                        return 0
                                }
                                return 1.0
                        }
                        Behavior on opacity {
                                NumberAnimation {
                                        duration: 300
                                        easing.type: Easing.OutQuad
                                }
                        }
                }
                Text {
                        id: chargeIcon
                        anchors.centerIn: parent
                        text: "󱐋"
                        color: "#cdd6f4"
                        font {
                                family: "Monocraft"
                                pixelSize: 13
                                bold: true
                        }
                        opacity: {
                                if (root.charging || root.pluggedIn) {
                                        return 1.0
                                }
                                return 0
                        }
                        Behavior on opacity {
                                NumberAnimation {
                                        duration: 300
                                        easing.type: Easing.OutQuad
                                }
                        }
                }
                MD3.Pressable {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                                capsule.scale = 1.25
                                capsuleReset.start()
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
                        id: capsuleReset
                        interval: 120
                        repeat: false
                        onTriggered: capsule.scale = 1
                }
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
                implicitWidth: 240
                implicitHeight: popupContent.implicitHeight + 24
                Rectangle {
                        anchors.fill: parent
                        color: "#1e1e2e"
                        radius: 20
                        clip: true
                        border {
                                color: "#89b4fa"
                                width: 1
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
                        Column {
                                id: popupContent
                                anchors {
                                        left: parent.left
                                        right: parent.right
                                        top: parent.top
                                        topMargin: 12
                                        leftMargin: 12
                                        rightMargin: 12
                                }
                                spacing: 8
                                Item {
                                        width: parent.width
                                        height: 24
                                        Text {
                                                text: Translation.tr("battery.popup.title")
                                                color: "#cdd6f4"
                                                font {
                                                        family: "Monocraft"
                                                        pixelSize: 14
                                                        bold: true
                                                }
                                        }
                                        Rectangle {
                                                id: closeBtn
                                                anchors {
                                                        right: parent.right
                                                        verticalCenter: parent.verticalCenter
                                                }
                                                width: 24
                                                height: 24
                                                radius: 6
                                                color: "transparent"
                                                border { color: "#45475a"; width: 1 }
                                                clip: true
                                                Rectangle {
                                                        id: closeHoverFill
                                                        anchors.centerIn: parent
                                                        width: 0
                                                        height: 0
                                                        radius: 6
                                                        color: "#89b4fa"
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
                                                        color: "#89b4fa"
                                                        font {
                                                                family: "Monocraft"
                                                                pixelSize: 14
                                                        }
                                                }
                                                MD3.Pressable {
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
                                RowLayout {
                                        width: parent.width
                                        spacing: 8
                                        Rectangle {
                                                Layout.fillWidth: true
                                                height: 18
                                                radius: 20
                                                color: "#181825"
                                                border {
                                                        color: "#45475a"
                                                        width: 0.5
                                                }
                                                Rectangle {
                                                        id: batFill
                                                        width: parent.width * Math.max(0, Math.min(1, root.percent / 100))
                                                        height: parent.height
                                                        radius: 20
                                                        color: "#89b4fa"
                                                        Behavior on width {
                                                                NumberAnimation {
                                                                        duration: 120
                                                                        easing.type: Easing.OutQuad
                                                                }
                                                        }
                                                }
                                        }
                                        Text {
                                                text: root.ready ? root.percent + "%" : Translation.tr("battery.na")
                                                color: "#cdd6f4"
                                                font {
                                                        family: "Monocraft"
                                                        pixelSize: 11
                                                }
                                        }
                                }
                                Column {
                                        width: parent.width
                                        spacing: 0
                                        Text {
                                                width: parent.width
                                                text: root.timeText
                                                color: "#cdd6f4"
                                                font {
                                                        family: "Monocraft"
                                                        pixelSize: 12
                                                }
                                        }
                                        Text {
                                                width: parent.width
                                                text: Translation.trf("battery.power", root.rateText)
                                                color: "#cdd6f4"
                                                visible: root.rateText !== ""
                                                font {
                                                        family: "Monocraft"
                                                        pixelSize: 12
                                                }
                                        }
                                }
                        }
                }
        }
        Timer {
                id: closeTimer
                interval: 200
                running: !root.popupOpen && root.popupReady
                onTriggered: root.popupReady = false
        }
}
