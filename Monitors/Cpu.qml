import QtQuick
import "../Components" as MD3
import Quickshell
import Quickshell.Io
import QtQuick.Layouts
import Quickshell.Widgets
import "../Services"
Item {
        id: root
        implicitWidth: cpuRow.implicitWidth
        implicitHeight: 32
        property var rootWindow: null
        property bool popupOpen: false
        property bool popupReady: false
        property var buffer: []
        property var drawBuffer: []
        property int maxHistory: 30
        property real cpuUsage: 0
        property real scrollOffset: 1
        property real _animStart: 0
        property bool _initial: true
        property bool pctVisible: false
        Timer {
                id: animTimer
                interval: 12
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
        onCpuUsageChanged: {
                root.buffer.push(cpuUsage)
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
                id: cpuProcess
                command: [
                        "sh",
                        "-c",
                        "a1=$(awk '{print $2,$3,$4,$5,$6,$7,$8}' /proc/stat); sleep 0.1; a2=$(awk '{print $2,$3,$4,$5,$6,$7,$8}' /proc/stat); awk -v a1=\"$a1\" -v a2=\"$a2\" 'BEGIN{split(a1,b); split(a2,c); for(i=1;i<=7;i++) t+=c[i]-b[i]; idle=c[4]-b[4]; printf \"%.0f\\n\", (t>0)?(1-idle/t)*100:0}'"
                ]
                stdout: SplitParser {
                        onRead: function(data) {
                                var value = parseFloat(data.trim())
                                if (!isNaN(value)) {
                                        root.cpuUsage = value
                                }
                        }
                }
                onExited: restartTimer.start()
                running: true
        }
        Timer {
                id: restartTimer
                interval: 500
                onTriggered: cpuProcess.running = true
        }
        RowLayout {
                id: cpuRow
                anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                }
                spacing: 0
                Text {
                        id: cpuIcon
                        text: "\uf4bc"
                        color: "#89b4fa"
                        scale: 1
                        font {
                                family: "Monocraft"
                                pixelSize: 22
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
                        id: cpuPctWrap
                        Layout.preferredWidth: root.pctVisible ? cpuPct.implicitWidth : 0
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
                                id: cpuPct
                                anchors.verticalCenter: parent.verticalCenter
                                text: Math.round(root.cpuUsage) + "%"
                                color: "#cdd6f4"
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
        MD3.Pressable {
                id: rootMouseArea
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
                        cpuIcon.scale = 1.25
                        cpuIconReset.start()
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
                        MD3.Pressable {
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
                                        bottomMargin: 12
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
                                                 text: Translation.tr("monitor.cpu.popup.title")
                                                color: "#cdd6f4"
                                                font {
                                                        family: "Monocraft"
                                                        pixelSize: 14
                                                        bold: true
                                                }
                                        }
                                        Item {
                                                width: parent.width - 120
                                        }
                                        Text {
                                                anchors {
                                                        right: closeBtn.left
                                                        rightMargin: 8
                                                        verticalCenter: parent.verticalCenter
                                                }
                                                text: Math.round(root.cpuUsage) + "%"
                                                color: "#89b4fa"
                                                font {
                                                        family: "Monocraft"
                                                        pixelSize: 12
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
                                                        var gb = 1
                                                        var rw = 22
                                                        var gh = h - gt - gb
                                                        ctx.clearRect(0, 0, w, h)
                                                        ctx.save()
                                                        ctx.font = "11px Monocraft"
                                                        ctx.textAlign = "left"
                                                        ctx.fillStyle = "#cdd6f4"
                                                        var labels = ["100%", "75%", "50%", "25%", "0%"]
                                                        var lw = 32
                                                        for (var k = 0; k < 5; k++) {
                                                                var pct = 100 - k * 25
                                                                var ly = gt + gh * (1 - pct / 100)
                                                                ctx.fillText(labels[k], 0, ly + 1)
                                                                ctx.strokeStyle = Qt.rgba(0.54, 0.48, 0.66, 0.15)
                                                                ctx.lineWidth = 1
                                                                ctx.beginPath()
                                                                ctx.moveTo(lw, ly)
                                                                ctx.lineTo(w - rw, ly)
                                                                ctx.stroke()
                                                        }
                                                        var data = root.drawBuffer
                                                        var len = data.length
                                                        var max = root.maxHistory
                                                        if (len < 2) { ctx.restore(); return }
                                                        ctx.beginPath()
                                                        ctx.rect(lw, 0, w - lw - rw, h)
                                                        ctx.clip()
                                                        var pw = (w - lw - rw) / (max - 1)
                                                        var s = root.scrollOffset
                                                        function py(v) { return gt + gh * (1 - v / 100) }
                                                        var pts = max + 1
                                                        function val(i) {
                                                                if (i < len) return data[i]
                                                                return data[len - 1]
                                                        }
                                                        ctx.beginPath()
                                                        ctx.moveTo(lw + (0 - s) * pw, py(val(0)))
                                                        for (var j = 1; j < pts - 1; j++) {
                                                                var xc = lw + (j + 0.5 - s) * pw
                                                                var yc = (py(val(j)) + py(val(j + 1))) / 2
                                                                ctx.quadraticCurveTo(lw + (j - s) * pw, py(val(j)), xc, yc)
                                                        }
                                                        ctx.lineTo(lw + (pts - 1 - s) * pw, py(val(pts - 1)))
                                                        ctx.strokeStyle = "#89b4fa"
                                                        ctx.lineWidth = 3
                                                        ctx.stroke()
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
                id: cpuIconReset
                interval: 120
                repeat: false
                onTriggered: cpuIcon.scale = 1
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
