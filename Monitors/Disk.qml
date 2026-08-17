import QtQuick
import Quickshell
import Quickshell.Io
import QtQuick.Layouts
import Quickshell.Widgets
import "../Services"
Item {
        id: root
        implicitWidth: diskRow.implicitWidth
        implicitHeight: 28
        property var rootWindow: null
        property bool popupOpen: false
        property bool popupReady: false
        property var buffer: []
        property var drawBuffer: []
        property int maxHistory: 30
        property real diskUsage: 0
        property real diskUsedGiB: 0
        property real diskTotalGiB: 0
        property real scrollOffset: 1
        property real _animStart: 0
        property bool _initial: true
        property bool pctVisible: false
        Timer {
                id: animTimer
                interval: 16
                repeat: true
                running: true
                onTriggered: {
                        if (root.scrollOffset < 1) {
                                var elapsed = Date.now() - root._animStart
                                root.scrollOffset = Math.min(1, elapsed / 500)
                        }
                        if (root.scrollOffset >= 1) {
                                var buf = root.drawBuffer.slice()
                                buf.push(buf[buf.length - 1] || 0)
                                if (buf.length > root.maxHistory) {
                                        buf.shift()
                                }
                                root.drawBuffer = buf
                                root.scrollOffset = 0
                                root._animStart = Date.now()
                        }
                        graphCanvas.requestPaint()
                }
        }
        onDiskUsageChanged: {
                root.buffer.push(diskUsage)
                if (root.buffer.length > root.maxHistory) {
                        root.buffer.shift()
                }
                var buf = root.buffer.slice()
                while (buf.length < root.maxHistory) {
                        buf.unshift(buf[0])
                }
                root.drawBuffer = buf
                if (root.scrollOffset >= 1) {
                        root.scrollOffset = 0
                        root._animStart = Date.now()
                }
                root._initial = false
        }
        Process {
                id: diskProcess
                command: [
                        "sh",
                        "-c",
                        "df -B1 / | awk 'NR==2 {u=$3; t=$2; printf \"%d %d %d\\n\", (t>0)?u*100/t:0, u/1073741824, t/1073741824}'"
                ]
                stdout: SplitParser {
                        onRead: function(data) {
                                var parts = data.trim().split(/\s+/)
                                if (parts.length >= 3) {
                                        root.diskUsage = Number(parts[0])
                                        root.diskUsedGiB = Number(parts[1])
                                        root.diskTotalGiB = Number(parts[2])
                                }
                        }
                }
                onExited: restartTimer.start()
                running: true
        }
        Timer {
                id: restartTimer
                interval: 500
                onTriggered: diskProcess.running = true
        }
        RowLayout {
                id: diskRow
                anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                }
                spacing: 0
                Text {
                        id: diskIcon
                        text: ""
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
                }
                Item {
                        id: diskPctWrap
                        Layout.preferredWidth: root.pctVisible ? diskPct.implicitWidth : 0
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
                                id: diskPct
                                anchors.verticalCenter: parent.verticalCenter
                                text: Math.round(root.diskUsage) + "%"
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
                cursorShape: Qt.PointingHandCursor
                onEntered: {
                        root.pctVisible = true
                        pctHideTimer.stop()
                }
                onExited: {
                        pctHideTimer.restart()
                }
                onClicked: {
                        diskIcon.scale = 1.25
                        diskIconReset.start()
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
                grabFocus: true
                visible: root.popupReady
                color: "transparent"
                anchor {
                        window: root.rootWindow
                        rect.x: root.x + (root.width - popup.implicitWidth) / 2
                        rect.y: root.y + root.height + 8
                }
                implicitWidth: 260
                implicitHeight: 140
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
                        MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                propagateComposedEvents: true
                                onPressed: function(mouse) {
                                        mouse.accepted = true
                                }
                        }
                        Item {
                                anchors {
                                        fill: parent
                                        topMargin: 12
                                        leftMargin: 12
                                        rightMargin: 12
                                        bottomMargin: 6
                                }
                                Item {
                                        id: header
                                        anchors {
                                                top: parent.top
                                                left: parent.left
                                                right: parent.right
                                        }
                                        height: 24
                                        Text {
                                                anchors {
                                                        left: parent.left
                                                        verticalCenter: parent.verticalCenter
                                                }
                                                 text: " " + Translation.tr("monitor.disk.popup.title")
                                                color: "#E8DBFF"
                                                font {
                                                        family: "Monocraft"
                                                        pixelSize: 14
                                                        bold: true
                                                }
                                        }
                                        Text {
                                                anchors {
                                                        right: closeBtn.left
                                                        rightMargin: 8
                                                        verticalCenter: parent.verticalCenter
                                                }
                                                text: Math.round(root.diskUsage) + "% (" + root.diskUsedGiB.toFixed(1) + "GB)"
                                                color: "#B58FFF"
                                                font {
                                                        family: "Monocraft"
                                                        pixelSize: 11
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
                                        anchors {
                                                top: header.bottom
                                                topMargin: 8
                                                left: parent.left
                                                right: parent.right
                                                bottom: parent.bottom
                                        }
                                        clip: true
                                        Canvas {
                                                id: graphCanvas
                                                anchors.fill: parent
                                                onPaint: {
                                                        var ctx = getContext("2d")
                                                        var w = width
                                                        var h = height
                                                        var gt = 8
                                                        var gb = 8
                                                        var rw = 22
                                                        var gh = h - gt - gb
                                                        ctx.clearRect(0, 0, w, h)
                                                        ctx.save()
                                                        ctx.font = "11px Monocraft"
                                                        ctx.fillStyle = "#E8DBFF"
                                                        var labels = ["100%", "75%", "50%", "25%", "0%"]
                                                        var lw = 32
                                                        for (var k = 0; k < 5; k++) {
                                                                var pct = 100 - k * 25
                                                                var y = gt + gh * (1 - pct / 100)
                                                                ctx.fillText(labels[k], 0, y + 1)
                                                                ctx.strokeStyle = Qt.rgba(0.54, 0.48, 0.66, 0.15)
                                                                ctx.beginPath()
                                                                ctx.moveTo(lw, y)
                                                                ctx.lineTo(w - rw, y)
                                                                ctx.stroke()
                                                        }
                                                        var data = root.drawBuffer
                                                        if (data.length < 2) {
                                                                ctx.restore()
                                                                return
                                                        }
                                                        var pw = (w - lw - rw) / (root.maxHistory - 1)
                                                        function py(v) {
                                                                return gt + gh * (1 - v / 100)
                                                        }
                                                        ctx.beginPath()
                                                        ctx.moveTo(lw, py(data[0]))
                                                        for (var i = 1; i < data.length; i++) {
                                                                ctx.lineTo(lw + i * pw, py(data[i]))
                                                        }
                                                        ctx.strokeStyle = "#B58FFF"
                                                        ctx.lineWidth = 3
                                                        ctx.stroke()
                                                        ctx.beginPath()
                                                        ctx.moveTo(lw, gh + gt)
                                                        for (var j = 0; j < data.length; j++) {
                                                                ctx.lineTo(lw + j * pw, py(data[j]))
                                                        }
                                                        ctx.lineTo(lw + (data.length - 1) * pw, gh + gt)
                                                        ctx.closePath()
                                                        ctx.fillStyle = Qt.rgba(0.71, 0.56, 1.0, 0.1)
                                                        ctx.fill()
                                                        ctx.restore()
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
                id: diskIconReset
                interval: 120
                repeat: false
                onTriggered: diskIcon.scale = 1
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
