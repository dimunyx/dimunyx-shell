import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "../Services"
Item {
        id: root
        implicitWidth: brightRow.implicitWidth
        implicitHeight: 28
        property var rootWindow: null
        property bool popupOpen: false
        property bool popupReady: false
        property int brightness: 0
        property int brightnessPct: 0
        property int maxBrightness: 64764
        property real vBrightness: 0
        property bool brightDragging: false
        property bool pctVisible: false
        property string _maxOut: ""
        property string _getOut: ""
        IpcHandler {
                id: brightnessIpc
                target: "brightness"
                enabled: true
                function brightUp() {
                        root.setBrightness(root.brightnessPct + 5)
                }
                function brightDown() {
                        root.setBrightness(root.brightnessPct - 5)
                }
        }
        Process {
                id: maxProc
                command: ["brightnessctl", "max"]
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
                                        brightness = cur
                                        brightnessPct = Math.round(cur / maxBrightness * 100)
                                }
                                if (!root.brightDragging) {
                                        root.vBrightness = brightnessPct / 100
                                }
                        }
                }
        }
        Process {
                id: setProc
                stdout: StdioCollector {
                        onStreamFinished: function() { getProc.running = true }
                }
        }
        function brightnessIcon() {
                if (brightnessPct === 0) return "\udb80\udcde"
                if (brightnessPct < 33) return "\udb80\udcdd"
                if (brightnessPct < 66) return "\udb80\udcdf"
                return "\udb80\udce0"
        }
        function setBrightness(pct) {
                var target = Math.max(0, Math.min(100, Math.round(pct)))
                setProc.command = ["brightnessctl", "set", target + "%"]
                setProc.running = true
        }
        function refreshState() {
                maxProc.running = true
        }
        Timer {
                interval: 500
                repeat: true
                running: true
                onTriggered: refreshState()
        }
        Component.onCompleted: refreshState()
        RowLayout {
                id: brightRow
                anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                }
                spacing: 0
                Text {
                        id: brightIcon
                        text: brightnessIcon()
                        color: "#B58FFF"
                        scale: 1
                        font {
                                family: "Monocraft"
                                pixelSize: 28
                        }
                        Layout.preferredWidth: implicitWidth
                        Behavior on scale {
                                NumberAnimation {
                                        duration: 150
                                        easing.type: Easing.OutBack
                                }
                        }
                        Connections {
                                target: root
                                function onBrightnessPctChanged() {
                                        brightIcon.scale = 1.25
                                        brightScaleReset.start()
                                        root.pctVisible = true
                                        pctHideTimer.restart()
                                }
                        }
                        Timer {
                                id: brightScaleReset
                                interval: 120
                                repeat: false
                                onTriggered: brightIcon.scale = 1
                        }
                }
                Item {
                        id: brightPctWrap
                        Layout.preferredWidth: root.pctVisible ? brightPct.implicitWidth : 0
                        Layout.leftMargin: root.pctVisible ? 4 : 0
                        Layout.fillHeight: true
                        clip: true
                        Behavior on Layout.preferredWidth {
                                NumberAnimation {
                                        duration: 200
                                        easing.type: Easing.OutQuad
                                }
                        }
                        Behavior on Layout.leftMargin {
                                NumberAnimation {
                                        duration: 200
                                        easing.type: Easing.OutQuad
                                }
                        }
                        Text {
                                id: brightPct
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.brightnessPct + "%"
                                color: "#E8DBFF"
                                opacity: root.pctVisible ? 1 : 0
                                font {
                                        family: "Monocraft"
                                        pixelSize: 14
                                }
                                Behavior on opacity {
                                        NumberAnimation {
                                                duration: 150
                                                easing.type: Easing.OutQuad
                                        }
                                }
                        }
                }
        }
        MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                onEntered: {
                        root.pctVisible = true
                        pctHideTimer.stop()
                }
                onExited: {
                        pctHideTimer.restart()
                }
                onWheel: function(event) {
                        var step = 5
                        if (event.angleDelta.y > 0) {
                                setBrightness(brightnessPct + step)
                        } else {
                                setBrightness(brightnessPct - step)
                        }
                }
                onClicked: function(mouse) {
                        brightIcon.scale = 1.25
                        brightScaleReset.start()
                        if (!root.popupOpen) {
                                closeTimer.stop()
                                root.popupReady = true
                                root.popupOpen = true
                        } else {
                                root.popupOpen = false
                        }
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
                implicitHeight: popupContent.implicitHeight + 16
                Rectangle {
                        anchors.fill: parent
                        color: "#000000"
                        radius: 20
                        clip: true
                        border {
                                color: "#B58FFF"
                                width: 4
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
                                                 text: Translation.tr("brightness.popup.title")
                                                color: "#E8DBFF"
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
                                Item {
                                        width: parent.width
                                        height: 34
                                        RowLayout {
                                                width: parent.width
                                                spacing: 8
                                                Text {
                                                        text: root.brightnessIcon()
                                                        color: "#B58FFF"
                                                        font {
                                                                family: "Monocraft"
                                                                pixelSize: 18
                                                        }
                                                }
                                                Rectangle {
                                                        Layout.fillWidth: true
                                                        height: 18
                                                        radius: 20
                                                        color: "#110d1a"
                                                        border {
                                                                color: "#4c3a70"
                                                                width: 0.5
                                                        }
                                                        Rectangle {
                                                                id: brightFill
                                                                width: parent.width * Math.max(0, Math.min(1, root.vBrightness))
                                                                height: parent.height
                                                                radius: 20
                                                                color: "#B58FFF"
                                                                Behavior on width {
                                                                        NumberAnimation {
                                                                                duration: 120
                                                                                easing.type: Easing.OutQuad
                                                                        }
                                                                }
                                                        }
                                                        MouseArea {
                                                                id: barMouse
                                                                anchors.fill: parent
                                                                cursorShape: Qt.PointingHandCursor
                                                                property bool pressed: false
                                                                onWheel: function(event) {
                                                                        var step = 5
                                                                        if (event.angleDelta.y > 0) {
                                                                                setBrightness(root.brightnessPct + step)
                                                                        } else {
                                                                                setBrightness(root.brightnessPct - step)
                                                                        }
                                                                }
                                                                function setBrightnessFromX(x) {
                                                                        var ratio = x / width
                                                                        root.vBrightness = ratio
                                                                        setBrightness(ratio * 100)
                                                                }
                                                                onPressed: function(mouse) {
                                                                        pressed = true
                                                                        root.brightDragging = true
                                                                        setBrightnessFromX(mouse.x)
                                                                }
                                                                onPositionChanged: function(mouse) {
                                                                        if (pressed) {
                                                                                setBrightnessFromX(mouse.x)
                                                                        }
                                                                }
                                                                onReleased: function(mouse) {
                                                                        pressed = false
                                                                        root.brightDragging = false
                                                                        root.vBrightness = root.brightnessPct / 100
                                                                }
                                                        }
                                                }
                                                Text {
                                                        text: root.brightnessPct + "%"
                                                        color: "#E8DBFF"
                                                        font {
                                                                family: "Monocraft"
                                                                pixelSize: 11
                                                        }
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
        Timer {
                id: pctHideTimer
                interval: 1200
                repeat: false
                onTriggered: {
                        root.pctVisible = false
                }
        }
}
