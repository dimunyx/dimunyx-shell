import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import QtQuick.Layouts
Item {
        id: root
        implicitHeight: 24
        implicitWidth: root.barCount * (barWidth + barSpacing) + 16
        property var values: []
        property int barCount: 36
        property int barWidth: 3
        property int barSpacing: 1
        property int maxBarHeight: 20
        property var rootWindow: null
        property bool popupOpen: false
        property bool popupReady: false
        property var player: Mpris
        property string trackTitle: ""
        property string trackArtist: ""
        property string trackAlbum: ""
        property string trackArtUrl: ""
        property string playerName: ""
        property bool isPlaying: false
        property int position: 0
        property int length: 0
        property bool usePlayerctl: false
        property int _refresh: 0
        property string videoId: ""
        property bool isYouTube: false
        property string _lastArtUrl: ""
        property real glowPulse: 0.5
        NumberAnimation on glowPulse {
                running: root.player && root.player.hasPlayer && root.player.isPlaying || root.isPlaying
                from: 0.3
                to: 0.7
                duration: 1500
                loops: Animation.Infinite
                easing.type: Easing.InOutSine
        }
        IpcHandler {
                id: mediaIpc
                target: "media"
                enabled: true
                function playPause() {
                        root.playPause()
                }
                function play() {
                        root.doPlay()
                }
                function pause() {
                        root.doPause()
                }
                function next() {
                        root.nextTrack()
                }
                function previous() {
                        root.prevTrack()
                }
        }
        Process {
                id: cava
                command: [
                        "cava",
                        "-p",
                        Quickshell.env("HOME") + "/.config/quickshell/configs/cava/config"
                ]
                running: true
                stdout: SplitParser {
                        splitMarker: "\n"
                        onRead: function(data) {
                                var parsed = data.trim().split(";").map(Number).filter(function(n) { return !isNaN(n) })
                                if (parsed.length > 0) {
                                        root.values = parsed
                                }
                        }
                }
                onExited: restartTimer.start()
        }
        Timer {
                id: restartTimer
                interval: 1000
                onTriggered: {
                        cava.running = true
                }
        }
        Canvas {
                id: barsCanvas
                anchors {
                        left: parent.left
                        leftMargin: 6
                        verticalCenter: parent.verticalCenter
                }
                width: root.barCount * (root.barWidth + root.barSpacing)
                height: root.maxBarHeight
                Connections {
                        target: root
                        function onValuesChanged() {
                                barsCanvas.requestPaint()
                        }
                }
                onPaint: {
                        var ctx = getContext("2d")
                        var w = width
                        var h = height
                        var bw = root.barWidth
                        var bs = root.barSpacing
                        ctx.clearRect(0, 0, w, h)
                        var count = Math.min(root.values.length, root.barCount)
                        for (var i = 0; i < count; i++) {
                                var val = root.values[i] || 0
                                var barHeight = Math.max(2, (val / 100) * h)
                                var x = i * (bw + bs)
                                ctx.fillStyle = "#B58FFF"
                                ctx.fillRect(x, h - barHeight, bw, barHeight)
                        }
                }
        }
        Process {
                id: playerctlStatus
                command: ["sh", "-c", "playerctl status 2>/dev/null || echo 'No players found'"]
                stdout: SplitParser {
                        onRead: function(data) {
                                var status = data.trim()
                                if (status === "No players found") {
                                        root.usePlayerctl = false
                                        root.isPlaying = false
                                        root.isYouTube = false
                                        root.playerName = ""
                                        root.trackTitle = ""
                                        return
                                }
                                root.usePlayerctl = true
                                root.isPlaying = status === "Playing"
                        }
                }
                onRunningChanged: {
                        if (!running && root.usePlayerctl) {
                                playerctlMetadata.running = true
                        }
                }
        }
        Process {
                id: playerctlMetadata
                command: ["sh", "-c", "playerctl metadata --format '{{playerName}}||{{title}}||{{artist}}||{{album}}||{{mpris:artUrl}}||{{position}}||{{mpris:length}}||{{xesam:url}}' 2>/dev/null || echo '|||||||'"]
                stdout: SplitParser {
                        splitMarker: "\n"
                        onRead: function(data) {
                                var parts = data.trim().split("||")
                                if (parts.length >= 8) {
                                        root.playerName = parts[0] || ""
                                        var title = parts[1] || ""
                                        root.trackArtist = parts[2] || ""
                                        root.trackAlbum = parts[3] || ""
                                        var artUrl = parts[4] || ""
                                        var pos = parseInt(parts[5]) || 0
                                        var len = parseInt(parts[6]) || 0
                                        if (pos > 1000000) {
                                                pos = Math.floor(pos / 1000000)
                                        }
                                        if (len > 1000000) {
                                                len = Math.floor(len / 1000000)
                                        }
                                        if (title !== root.trackTitle && title !== "") {
                                                root.trackTitle = title
                                        }
                                        if (pos > 0) {
                                                root.position = pos
                                        }
                                        if (len > 0) {
                                                root.length = len
                                        }
                                        var url = parts[7] || ""
                                        root.isYouTube = url.indexOf("youtube.com") !== -1 || url.indexOf("youtu.be") !== -1
                                        if (root.isYouTube) {
                                                var vid = ""
                                                if (url.indexOf("watch?v=") !== -1) {
                                                        vid = url.split("watch?v=")[1].split("&")[0]
                                                } else if (url.indexOf("youtu.be/") !== -1) {
                                                        vid = url.split("youtu.be/")[1].split("?")[0]
                                                }
                                                if (vid && vid.length > 0 && vid !== root.videoId) {
                                                        root.videoId = vid
                                                        root.trackArtUrl = "https://img.youtube.com/vi/" + vid + "/hqdefault.jpg"
                                                        root._lastArtUrl = root.trackArtUrl
                                                }
                                        } else {
                                                if (artUrl !== "" && artUrl !== root._lastArtUrl) {
                                                        root.trackArtUrl = artUrl
                                                        root._lastArtUrl = artUrl
                                                }
                                        }
                                }
                        }
                }
                onRunningChanged: {
                        if (!running) {
                                if (root.trackTitle === "" && root.playerName === "") {
                                        root.isPlaying = false
                                        root.isYouTube = false
                                }
                        }
                }
        }
        Process {
                id: playerctlPlayPause
                command: ["playerctl", "play-pause"]
        }
        Process {
                id: playerctlNext
                command: ["playerctl", "next"]
        }
        Process {
                id: playerctlPrevious
                command: ["playerctl", "previous"]
        }
        Process {
                id: playerctlPlay
                command: ["playerctl", "play"]
        }
        Process {
                id: playerctlPause
                command: ["playerctl", "pause"]
        }
        Timer {
                id: refreshTimer
                interval: 500
                repeat: true
                running: true
                onTriggered: {
                        root._refresh++
                        if (!root.player || !root.player.hasPlayer) {
                                playerctlStatus.running = true
                        }
                }
        }
        Component.onCompleted: {
                playerctlStatus.running = true
        }
        function formatTime(seconds) {
                var s = Math.floor(seconds)
                var h = Math.floor(s / 3600)
                var m = Math.floor((s % 3600) / 60)
                var sec = s % 60
                if (h > 0) {
                        return String(h).padStart(2, "0") + ":" + String(m).padStart(2, "0") + ":" + String(sec).padStart(2, "0")
                }
                return String(m).padStart(2, "0") + ":" + String(sec).padStart(2, "0")
        }
        function getTrackTitle() {
                if (root.player && root.player.hasPlayer && root.player.trackTitle) {
                        return root.player.trackTitle
                }
                if (root.usePlayerctl && root.trackTitle) {
                        return root.trackTitle
                }
                return ""
        }
        function getTrackArtist() {
                if (root.player && root.player.hasPlayer && root.player.trackArtist) {
                        return root.player.trackArtist
                }
                if (root.usePlayerctl && root.trackArtist) {
                        return root.trackArtist
                }
                return ""
        }
        function getTrackAlbum() {
                if (root.player && root.player.hasPlayer && root.player.trackAlbum) {
                        return root.player.trackAlbum
                }
                if (root.usePlayerctl && root.trackAlbum) {
                        return root.trackAlbum
                }
                return ""
        }
        function getTrackArtUrl() {
                if (root.isYouTube && root.videoId !== "") {
                        return "https://img.youtube.com/vi/" + root.videoId + "/hqdefault.jpg"
                }
                if (root.trackArtUrl !== "" && root.trackArtUrl.indexOf("http") === 0) {
                        return root.trackArtUrl
                }
                if (root.player && root.player.hasPlayer && root.player.trackArtUrl) {
                        var url = root.player.trackArtUrl
                        if (url !== "" && url.indexOf("http") === 0) {
                                return url
                        }
                }
                return ""
        }
        function getPlayerName() {
                if (root.player && root.player.hasPlayer && root.player.identity) {
                        return root.player.identity
                }
                if (root.usePlayerctl && root.playerName) {
                        return root.playerName
                }
                return ""
        }
        function getIsPlaying() {
                if (root.player && root.player.hasPlayer) {
                        return root.player.isPlaying
                }
                if (root.usePlayerctl) {
                        return root.isPlaying
                }
                return false
        }
        function getPosition() {
                if (root.position > 0) {
                        return root.position
                }
                if (root.player && root.player.hasPlayer && root.player.position > 0) {
                        return root.player.position
                }
                return 0
        }
        function getLength() {
                if (root.length > 0) {
                        return root.length
                }
                if (root.player && root.player.hasPlayer && root.player.length > 0) {
                        return root.player.length
                }
                return 0
        }
        function playPause() {
                if (root.player && root.player.hasPlayer) {
                        root.player.togglePlaying()
                        return
                }
                if (root.usePlayerctl) {
                        playerctlPlayPause.running = true
                        refreshTimer.restart()
                }
        }
        function doPlay() {
                if (root.player && root.player.hasPlayer) {
                        if (typeof root.player.play === "function") {
                                root.player.play()
                        } else if (!root.player.isPlaying) {
                                root.player.togglePlaying()
                        }
                        return
                }
                if (root.usePlayerctl) {
                        playerctlPlay.running = true
                        refreshTimer.restart()
                }
        }
        function doPause() {
                if (root.player && root.player.hasPlayer) {
                        if (typeof root.player.pause === "function") {
                                root.player.pause()
                        } else if (root.player.isPlaying) {
                                root.player.togglePlaying()
                        }
                        return
                }
                if (root.usePlayerctl) {
                        playerctlPause.running = true
                        refreshTimer.restart()
                }
        }
        function nextTrack() {
                if (root.player && root.player.hasPlayer) {
                        root.player.next()
                        return
                }
                if (root.usePlayerctl) {
                        playerctlNext.running = true
                        refreshTimer.restart()
                }
        }
        function prevTrack() {
                if (root.player && root.player.hasPlayer) {
                        root.player.previous()
                        return
                }
                if (root.usePlayerctl) {
                        playerctlPrevious.running = true
                        refreshTimer.restart()
                }
        }
        MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                        if (!root.popupOpen) {
                                closeTimer.stop()
                                root.popupReady = true
                                root.popupOpen = true
                        } else {
                                root.popupOpen = false
                        }
                }
                onWheel: function(event) {
                        if (event.angleDelta.y > 0) {
                                nextTrack()
                        } else {
                                prevTrack()
                        }
                }
        }
        PopupWindow {
                id: popup
                visible: root.popupReady && root.rootWindow !== null
                grabFocus: true
                color: "transparent"
                anchor {
                        window: root.rootWindow
                        rect.x: root.x + (root.width - popup.implicitWidth) / 2
                        rect.y: root.y + root.height + 8
                }
                implicitWidth: 320
                implicitHeight: 400
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
                                PropertyAnimation {
                                        duration: 200
                                        easing.type: Easing.OutQuad
                                }
                        }
                        Behavior on scale {
                                PropertyAnimation {
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
                                anchors.fill: parent
                                anchors.margins: 12
                                Column {
                                        id: popupColumn
                                        anchors {
                                                left: parent.left
                                                right: parent.right
                                                top: parent.top
                                        }
                                        spacing: 8
                                        Item {
                                                width: parent.width
                                                height: 28
                                                RowLayout {
                                                        anchors.fill: parent
                                                        spacing: 8
                                                        Text {
                                                                 text: Translation.tr("cava.popup.title")
                                                                color: "#E8DBFF"
                                                                font {
                                                                        family: "Monocraft"
                                                                        pixelSize: 14
                                                                        bold: true
                                                                }
                                                        }
                                                        Item {
                                                                Layout.fillWidth: true
                                                        }
                                                        Rectangle {
                                                                id: closeBtn
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
                                        }
                                        Column {
                                                width: parent.width
                                                spacing: 8
                                                Item {
                                                        anchors.horizontalCenter: parent.horizontalCenter
                                                        width: 190
                                                        height: 190
                                                        property real artRatio: 1
                                                        property bool ratioDetected: false
                                                        readonly property real baseW: 190
                                                        readonly property real baseH: 190
                                                        Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutQuad } }
                                                        Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutQuad } }
                                                        Rectangle {
                                                                id: glowRing
                                                                anchors.centerIn: parent
                                                                width: parent.width + 8
                                                                height: parent.height + 8
                                                                radius: 14
                                                                color: "transparent"
                                                                border { color: "#B58FFF"; width: 2 }
                                                                opacity: root.player && root.player.hasPlayer && root.player.isPlaying || root.isPlaying ? root.glowPulse : 0
                                                                scale: root.player && root.player.hasPlayer && root.player.isPlaying || root.isPlaying ? 1.04 : 1
                                                                Behavior on opacity {
                                                                        NumberAnimation { duration: 300; easing.type: Easing.OutQuad }
                                                                }
                                                                Behavior on scale {
                                                                        NumberAnimation { duration: 300; easing.type: Easing.OutQuad }
                                                                }
                                                        }
                                                        Rectangle {
                                                                anchors.centerIn: parent
                                                                width: parent.width
                                                                height: parent.height
                                                                radius: 10
                                                                color: "#110d1a"
                                                                Image {
                                                                        id: artImg
                                                                        anchors.fill: parent
                                                                        anchors.margins: 2
                                                                        source: getTrackArtUrl()
                                                                        fillMode: Image.PreserveAspectFit
                                                                        visible: source !== ""
                                                                        clip: true
                                                                        asynchronous: true
                                                                        onStatusChanged: {
                                                                                if (status === Image.Ready) {
                                                                                        var ratio = implicitWidth / implicitHeight
                                                                                        parent.parent.artRatio = ratio
                                                                                        parent.parent.ratioDetected = true
                                                                                        if (ratio >= 1.4) {
                                                                                                parent.parent.width = 240
                                                                                                parent.parent.height = 170
                                                                                        } else {
                                                                                                parent.parent.width = 190
                                                                                                parent.parent.height = 190
                                                                                        }
                                                                                }
                                                                        }
                                                                }
                                                                Text {
                                                                        anchors.centerIn: parent
                                                                        text: root.isYouTube ? "\udb80\udf8a" : "\uf03d"
                                                                        color: "#4c3a70"
                                                                        font {
                                                                                family: "Monocraft"
                                                                                pixelSize: 44
                                                                        }
                                                                        visible: getTrackArtUrl() === ""
                                                                }
                                                        }
                                                }
                                                Text {
                                                        anchors.horizontalCenter: parent.horizontalCenter
                                                        width: parent.width - 16
                                                        text: getTrackTitle()
                                                        color: "#E8DBFF"
                                                        font {
                                                                family: "Monocraft"
                                                                pixelSize: 13
                                                                bold: true
                                                        }
                                                        horizontalAlignment: Text.AlignHCenter
                                                        maximumLineCount: 2
                                                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                                                        elide: Text.ElideRight
                                                }
                                        }
                                        Text {
                                                width: parent.width
                                                 text: getTrackTitle() !== "" ? "" : Translation.tr("cava.no.player")
                                                color: "#4c3a70"
                                                font {
                                                        family: "Monocraft"
                                                        pixelSize: 12
                                                }
                                                horizontalAlignment: Text.AlignHCenter
                                                visible: getTrackTitle() === ""
                                        }
                                        Item {
                                                width: parent.width
                                                height: 20
                                                visible: getTrackTitle() !== ""
                                                RowLayout {
                                                        anchors.fill: parent
                                                        spacing: 6
                                                        Text {
                                                                text: formatTime(getPosition())
                                                                color: "#6b5a8f"
                                                                font {
                                                                        family: "Monocraft"
                                                                        pixelSize: 10
                                                                }
                                                                Layout.preferredWidth: 40
                                                        }
                                                        Rectangle {
                                                                Layout.fillWidth: true
                                                                height: 4
                                                                radius: 2
                                                                color: "#110d1a"
                                                                Rectangle {
                                                                        width: parent.width * (getLength() > 0 ? Math.min(1, getPosition() / getLength()) : 0)
                                                                        height: parent.height
                                                                        radius: 2
                                                                        color: "#B58FFF"
                                                                        Behavior on width {
                                                                                PropertyAnimation {
                                                                                        duration: 500
                                                                                }
                                                                        }
                                                                }
                                                        }
                                                        Text {
                                                                text: formatTime(getLength())
                                                                color: "#6b5a8f"
                                                                font {
                                                                        family: "Monocraft"
                                                                        pixelSize: 10
                                                                }
                                                                Layout.preferredWidth: 40
                                                                horizontalAlignment: Text.AlignRight
                                                        }
                                                }
                                        }
                                        Row {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                spacing: 12
                                                enabled: getPlayerName() !== ""
                                                Rectangle {
                                                        id: prevBtn
                                                        width: 40
                                                        height: 40
                                                        radius: 20
                                                        color: "transparent"
                                                        border { color: "#4c3a70"; width: 1 }
                                                        clip: true
                                                        Rectangle {
                                                                id: prevHoverFill
                                                                anchors.centerIn: parent
                                                                width: 0
                                                                height: 0
                                                                radius: 20
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
                                                                text: "\uf04a"
                                                                color: getPlayerName() !== "" ? "#B58FFF" : "#4c3a70"
                                                                font {
                                                                        family: "Monocraft"
                                                                        pixelSize: 20
                                                                }
                                                        }
                                                        MouseArea {
                                                                id: prevArea
                                                                anchors.fill: parent
                                                                hoverEnabled: true
                                                                cursorShape: Qt.PointingHandCursor
                                                                onEntered: {
                                                                        prevHoverFill.width = parent.width
                                                                        prevHoverFill.height = parent.height
                                                                }
                                                                onExited: {
                                                                        prevHoverFill.width = 0
                                                                        prevHoverFill.height = 0
                                                                }
                                                                onClicked: prevTrack()
                                                        }
                                                }
                                                Rectangle {
                                                        id: playBtn
                                                        width: 40
                                                        height: 40
                                                        radius: 20
                                                        color: "transparent"
                                                        border {
                                                                color: getIsPlaying() ? "#B58FFF" : "#4c3a70"
                                                                width: getIsPlaying() ? 2 : 1
                                                        }
                                                        clip: true
                                                        Rectangle {
                                                                id: playHoverFill
                                                                anchors.centerIn: parent
                                                                width: 0
                                                                height: 0
                                                                radius: 20
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
                                                                text: getIsPlaying() ? "\uf04b" : "\uf04c"
                                                                color: getIsPlaying() ? "#B58FFF" : "#4c3a70"
                                                                font {
                                                                        family: "Monocraft"
                                                                        pixelSize: 22
                                                                }
                                                        }
                                                        MouseArea {
                                                                id: playArea
                                                                anchors.fill: parent
                                                                hoverEnabled: true
                                                                cursorShape: Qt.PointingHandCursor
                                                                onEntered: {
                                                                        playHoverFill.width = parent.width
                                                                        playHoverFill.height = parent.height
                                                                }
                                                                onExited: {
                                                                        playHoverFill.width = 0
                                                                        playHoverFill.height = 0
                                                                }
                                                                onClicked: playPause()
                                                        }
                                                }
                                                Rectangle {
                                                        id: nextBtn
                                                        width: 40
                                                        height: 40
                                                        radius: 20
                                                        color: "transparent"
                                                        border { color: "#4c3a70"; width: 1 }
                                                        clip: true
                                                        Rectangle {
                                                                id: nextHoverFill
                                                                anchors.centerIn: parent
                                                                width: 0
                                                                height: 0
                                                                radius: 20
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
                                                                text: "\uf04e"
                                                                color: getPlayerName() !== "" ? "#B58FFF" : "#4c3a70"
                                                                font {
                                                                        family: "Monocraft"
                                                                        pixelSize: 20
                                                                }
                                                        }
                                                        MouseArea {
                                                                id: nextArea
                                                                anchors.fill: parent
                                                                hoverEnabled: true
                                                                cursorShape: Qt.PointingHandCursor
                                                                onEntered: {
                                                                        nextHoverFill.width = parent.width
                                                                        nextHoverFill.height = parent.height
                                                                }
                                                                onExited: {
                                                                        nextHoverFill.width = 0
                                                                        nextHoverFill.height = 0
                                                                }
                                                                onClicked: nextTrack()
                                                        }
                                                }
                                        }
                                        Text {
                                                width: parent.width
                                                text: {
                                                         var name = getPlayerName() !== "" ? getPlayerName() : "No player"
                                                        if (name.length > 24) {
                                                                return name.substring(0, 24) + "..."
                                                        }
                                                        return name
                                                }
                                                color: "#4c3a70"
                                                font {
                                                        family: "Monocraft"
                                                        pixelSize: 10
                                                }
                                                horizontalAlignment: Text.AlignHCenter
                                        }
                                }
                                Rectangle {
                                        anchors {
                                                right: parent.right
                                                top: parent.top
                                                bottom: parent.bottom
                                        }
                                        width: 4
                                        color: "#3a3255"
                                        radius: 2
                                        visible: popupColumn.height > parent.height
                                        Rectangle {
                                                width: 4
                                                height: Math.max(20, parent.height * (parent.height / popupColumn.height))
                                                radius: 2
                                                color: "#B58FFF"
                                                y: Math.max(0, (parent.parent ? (parent.parent.contentY || 0) / (popupColumn.height - parent.parent.height) : 0) * (parent.height - height))
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
