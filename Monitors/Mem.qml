import QtQuick
import Quickshell
import Quickshell.Io
import QtQuick.Layouts
import Quickshell.Widgets
import "../Services"
Item {
        id: root
        implicitWidth: memRow.implicitWidth
        implicitHeight: 28
        property var rootWindow: null
        property bool popupOpen: false
        property bool popupReady: false
        property bool swapPopupOpen: false
        property bool swapPopupReady: false
        property var buffer: []
        property var drawBuffer: []
        property var swapBuffer: []
        property var swapDrawBuffer: []
        property int maxHistory: 30
        property real memUsage: 0
        property real memUsedGiB: 0
        property real memTotalGiB: 0
        property real swapUsedGiB: 0
        property real swapTotalGiB: 0
        property real swapUsage: 0
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
                                var sbuf = root.swapDrawBuffer.slice()
                                sbuf.push(sbuf[sbuf.length - 1] || 0)
                                if (sbuf.length > root.maxHistory) {
                                        sbuf.shift()
                                }
                                root.swapDrawBuffer = sbuf
                                root.scrollOffset = 0
                                root._animStart = Date.now()
                        }
                        graphCanvas.requestPaint()
                }
        }
        function pushData() {
                root.buffer.push(root.memUsage)
                if (root.buffer.length > root.maxHistory) {
                        root.buffer.shift()
                }
                root.swapBuffer.push(root.swapUsage)
                if (root.swapBuffer.length > root.maxHistory) {
                        root.swapBuffer.shift()
                }
                var buf = root.buffer.slice()
                while (buf.length < root.maxHistory) {
                        buf.unshift(buf[0])
                }
                var sbuf = root.swapBuffer.slice()
                while (sbuf.length < root.maxHistory) {
                        sbuf.unshift(sbuf[0])
                }
                root.drawBuffer = buf
                root.swapDrawBuffer = sbuf
                if (root.scrollOffset >= 1) {
                        root.scrollOffset = 0
                        root._animStart = Date.now()
                }
                root._initial = false
        }
        onMemUsageChanged: root.pushData()
        onSwapUsageChanged: root.pushData()
        Process {
                id: memProcess
                command: [
                        "sh",
                        "-c",
                        "awk '/^MemTotal:/{t=$2} /^MemAvailable:/{a=$2} /^SwapTotal:/{st=$2} /^SwapFree:/{sf=$2} END {swap=0; if(st>0) swap=(st-sf)*100/st; used=(t-a)/1024/1024; total=t/1024/1024; swapUsed=(st-sf)/1024/1024; swapTotal=st/1024/1024; printf \"%d %d %.2f %.2f %.2f %.2f\\n\", (t-a)*100/t, swap, used, total, swapUsed, swapTotal}' /proc/meminfo"
                ]
                stdout: SplitParser {
                        onRead: function(data) {
                                var parts = data.trim().split(/\s+/)
                                if (parts.length >= 6) {
                                        root.memUsage = Number(parts[0])
                                        root.swapUsage = Number(parts[1])
                                        root.memUsedGiB = Number(parts[2])
                                        root.memTotalGiB = Number(parts[3])
                                        root.swapUsedGiB = Number(parts[4])
                                        root.swapTotalGiB = Number(parts[5])
                                }
                        }
                }
                onExited: restartTimer.start()
                running: true
        }
        Timer {
                id: restartTimer
                interval: 500
                onTriggered: memProcess.running = true
        }
        RowLayout {
                id: memRow
                anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                }
                spacing: 0
                Text {
                        id: memIcon
                        text: ""
                        color: "#B58FFF"
                        scale: 1
                        font {
                                family: "Monocraft"
                                pixelSize: 32
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
                        id: memPctWrap
                        Layout.preferredWidth: root.pctVisible ? memPct.implicitWidth : 0
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
                                id: memPct
                                anchors.verticalCenter: parent.verticalCenter
                                text: Math.round(root.memUsage) + "%"
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
                id: rootMouseArea
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: {
                        root.pctVisible = true
                        pctHideTimer.stop()
                }
                onExited: {
                        pctHideTimer.restart()
                }
                onClicked: function(mouse) {
                        memIcon.scale = 1.25
                        memIconReset.start()
                        if (mouse.button === Qt.RightButton) {
                                if (!root.swapPopupOpen) {
                                        root.swapPopupReady = true
                                        root.swapPopupOpen = true
                                } else {
                                        root.swapPopupOpen = false
                                }
                        } else {
                                if (!root.popupOpen) {
                                        closeTimer.stop()
                                        root.popupReady = true
                                        root.popupOpen = true
                                } else {
                                        root.popupOpen = false
                                }
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
                implicitHeight: 170
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
                                        bottomMargin: 5
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
                                                 text: " " + Translation.tr("monitor.mem.popup.title")
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
                                                text: Math.round(root.memUsage) + "% (" + root.memUsedGiB.toFixed(1) + "GB)"
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
                                        id: swapItem
                                        anchors {
                                                bottom: parent.bottom
                                                left: parent.left
                                                right: parent.right
                                        }
                                        height: 24
                                        Row {
                                                anchors.fill: parent
                                                spacing: 6
                                                Text {
                                                        text: "Swap:"
                                                        color: "#E8DBFF"
                                                        font {
                                                                family: "Monocraft"
                                                                pixelSize: 11
                                                        }
                                                }
                                                Text {
                                                        text: Math.round(root.swapUsage) + "%"
                                                        color: "#C79AFF"
                                                        font {
                                                                family: "Monocraft"
                                                                pixelSize: 11
                                                        }
                                                }
                                                Text {
                                                        text: "(" + root.swapUsedGiB.toFixed(1) + "GB)"
                                                        color: "#8B7AB8"
                                                        font {
                                                                family: "Monocraft"
                                                                pixelSize: 10
                                                        }
                                                        visible: root.swapTotalGiB > 0
                                                }
                                                Text {
                                                         text: "(not used)"
                                                        color: "#6B5A8A"
                                                        font {
                                                                family: "Monocraft"
                                                                pixelSize: 10
                                                        }
                                                        visible: root.swapTotalGiB === 0
                                                }
                                        }
                                }
                                Item {
                                        anchors {
                                                top: header.bottom
                                                topMargin: 8
                                                left: parent.left
                                                right: parent.right
                                                bottom: swapItem.top
                                                bottomMargin: 8
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
                                                        ctx.fillStyle = "#E8DBFF"
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
                                                        function val(arr, i) {
                                                                if (i < arr.length) return arr[i]
                                                                return arr[arr.length - 1]
                                                        }
                                                        ctx.beginPath()
                                                        ctx.moveTo(lw + (0 - s) * pw, py(val(data, 0)))
                                                        for (var j = 1; j < pts - 1; j++) {
                                                                var xc = lw + (j + 0.5 - s) * pw
                                                                var yc = (py(val(data, j)) + py(val(data, j + 1))) / 2
                                                                ctx.quadraticCurveTo(lw + (j - s) * pw, py(val(data, j)), xc, yc)
                                                        }
                                                        ctx.lineTo(lw + (pts - 1 - s) * pw, py(val(data, pts - 1)))
                                                        ctx.strokeStyle = "#B58FFF"
                                                        ctx.lineWidth = 3
                                                        ctx.stroke()
                                                        ctx.beginPath()
                                                        ctx.moveTo(lw + (0 - s) * pw, gh + gt)
                                                        for (var j2 = 0; j2 < pts - 1; j2++) {
                                                                ctx.lineTo(lw + (j2 - s) * pw, py(val(data, j2)))
                                                        }
                                                        ctx.lineTo(lw + (pts - 1 - s) * pw, gh + gt)
                                                        ctx.closePath()
                                                        ctx.fillStyle = Qt.rgba(0.71, 0.56, 1.0, 0.1)
                                                        ctx.fill()
                                                        var sdata = root.swapDrawBuffer
                                                        if (sdata.length >= 2) {
                                                                ctx.beginPath()
                                                                ctx.moveTo(lw + (0 - s) * pw, py(val(sdata, 0)))
                                                                for (var jj = 1; jj < pts - 1; jj++) {
                                                                        var xc2 = lw + (jj + 0.5 - s) * pw
                                                                        var yc2 = (py(val(sdata, jj)) + py(val(sdata, jj + 1))) / 2
                                                                        ctx.quadraticCurveTo(lw + (jj - s) * pw, py(val(sdata, jj)), xc2, yc2)
                                                                }
                                                                ctx.lineTo(lw + (pts - 1 - s) * pw, py(val(sdata, pts - 1)))
                                                                ctx.strokeStyle = "#C79AFF"
                                                                ctx.lineWidth = 2
                                                                ctx.stroke()
                                                        }
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
                id: memIconReset
                interval: 120
                repeat: false
                onTriggered: memIcon.scale = 1
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
