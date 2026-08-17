import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts
Item {
        id: root
        implicitWidth: volRow.implicitWidth
        implicitHeight: 28
        property var rootWindow: null
        property bool popupOpen: false
        property bool popupReady: false
        property bool muted: false
        property real volume: 0
        property int volumePct: 0
        property bool micMuted: false
        property real micVolume: 0
        property int micVolumePct: 0
        property bool hasMic: false
        property real vVolume: 0
        property real vMicVolume: 0
        property bool volDragging: false
        property bool micDragging: false
        property bool pctVisible: false
        property bool micPctVisible: false
        IpcHandler {
                id: volumeIpc
                target: "volume"
                enabled: true
                function volUp() {
                        var sink = Pipewire.defaultAudioSink
                        if (!sink || !sink.ready || !sink.audio) return
                        sink.audio.volume = Math.min(1, sink.audio.volume + 0.05)
                        root.refreshState()
                }
                function volDown() {
                        var sink = Pipewire.defaultAudioSink
                        if (!sink || !sink.ready || !sink.audio) return
                        sink.audio.volume = Math.max(0, sink.audio.volume - 0.05)
                        root.refreshState()
                }
                function volMute() {
                        var sink = Pipewire.defaultAudioSink
                        if (!sink || !sink.ready || !sink.audio) return
                        sink.audio.muted = !sink.audio.muted
                        root.refreshState()
                }
                function micMute() {
                        var src = Pipewire.defaultAudioSource
                        if (!src || !src.ready || !src.audio) return
                        src.audio.muted = !src.audio.muted
                        root.refreshState()
                }
        }
        PwObjectTracker {
                objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
        }
        function volumeIcon() {
                if (muted) return "\ueee8"
                if (volumePct === 0) return "\uf026"
                if (volumePct < 33) return "\uf026"
                if (volumePct < 66) return "\uf027"
                return "\uf028"
        }
        function refreshState() {
                var sink = Pipewire.defaultAudioSink
                if (!sink || !sink.ready || !sink.audio) {
                        muted = false
                        volume = 0
                        volumePct = 0
                } else {
                        muted = sink.audio.muted
                        volume = sink.audio.volume
                        volumePct = Math.round(volume * 100)
                }
                if (!root.volDragging) {
                        root.vVolume = volume
                }
                var src = Pipewire.defaultAudioSource
                if (!src || !src.ready || !src.audio) {
                        micMuted = false
                        micVolume = 0
                        micVolumePct = 0
                        hasMic = false
                } else {
                        micMuted = src.audio.muted
                        micVolume = src.audio.volume
                        micVolumePct = Math.round(micVolume * 100)
                        hasMic = true
                }
                if (!root.micDragging) {
                        root.vMicVolume = micVolume
                }
        }
        Timer {
                interval: 500
                repeat: true
                running: true
                onTriggered: root.refreshState()
        }
        Component.onCompleted: refreshState()
        RowLayout {
                id: volRow
                anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                }
                spacing: 0
                Text {
                        id: volIcon
                        text: volumeIcon()
                        color: muted ? "#ff6b6b" : "#B58FFF"
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
                        Connections {
                                target: root
                                function onVolumePctChanged() {
                                        volIcon.scale = 1.25
                                        volScaleReset.start()
                                        root.pctVisible = true
                                        pctHideTimer.restart()
                                }
                                function onMutedChanged() {
                                        volIcon.scale = 1.25
                                        volScaleReset.start()
                                }
                        }
                        Timer {
                                id: volScaleReset
                                interval: 120
                                repeat: false
                                onTriggered: volIcon.scale = 1
                        }
                }
                Item {
                        id: volPctWrap
                        Layout.preferredWidth: root.pctVisible ? volPct.implicitWidth + 4 : 0
                        Layout.fillHeight: true
                        clip: true
                        Behavior on Layout.preferredWidth {
                                NumberAnimation {
                                        duration: 200
                                        easing.type: Easing.OutQuad
                                }
                        }
                        Text {
                                id: volPct
                                anchors {
                                        left: parent.left
                                        leftMargin: 4
                                        verticalCenter: parent.verticalCenter
                                }
                                text: root.volumePct + "%"
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
                Item {
                        id: micWrap
                        Layout.preferredWidth: root.micPctVisible && root.hasMic ? micIcon.implicitWidth + 4 : 0
                        Layout.fillHeight: true
                        clip: true
                        Behavior on Layout.preferredWidth {
                                NumberAnimation {
                                        duration: 200
                                        easing.type: Easing.OutQuad
                                }
                        }
                        Text {
                                id: micIcon
                                anchors {
                                        left: parent.left
                                        leftMargin: 4
                                        verticalCenter: parent.verticalCenter
                                }
                                text: root.micMuted ? "\udb80\udf6d" : "\udb80\udf6c"
                                color: root.micMuted ? "#ff6b6b" : "#B58FFF"
                                opacity: root.micPctVisible ? 1 : 0
                                font {
                                        family: "Monocraft"
                                        pixelSize: 22
                                }
                                scale: 1
                                Behavior on opacity {
                                        NumberAnimation {
                                                duration: 150
                                                easing.type: Easing.OutQuad
                                        }
                                }
                                Behavior on scale {
                                        NumberAnimation {
                                                duration: 150
                                                easing.type: Easing.OutBack
                                        }
                                }
                                Connections {
                                        target: root
                                        function onMicMutedChanged() {
                                                micIcon.scale = 1.25
                                                micScaleReset.start()
                                                root.micPctVisible = true
                                                micPctHideTimer.restart()
                                        }
                                }
                                Timer {
                                        id: micScaleReset
                                        interval: 120
                                        repeat: false
                                        onTriggered: micIcon.scale = 1
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
                        root.micPctVisible = true
                        micPctHideTimer.stop()
                }
                onExited: {
                        pctHideTimer.restart()
                        micPctHideTimer.restart()
                }
                onWheel: function(event) {
                        var sink = Pipewire.defaultAudioSink
                        if (!sink || !sink.ready || !sink.audio) return
                        var step = 0.05
                        var cur = sink.audio.volume
                        if (event.angleDelta.y > 0) {
                                sink.audio.volume = Math.min(1, cur + step)
                        } else {
                                sink.audio.volume = Math.max(0, cur - step)
                        }
                        root.refreshState()
                }
                onClicked: function(mouse) {
                        volIcon.scale = 1.25
                        volScaleReset.start()
                        if (mouse.button === Qt.RightButton) {
                                var sink = Pipewire.defaultAudioSink
                                if (sink && sink.ready && sink.audio) {
                                        sink.audio.muted = !sink.audio.muted
                                        root.refreshState()
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
                                                        text: Translation.tr("volume.popup.title")
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
                                                Rectangle {
                                                        id: muteBtn
                                                        width: 18
                                                        height: 18
                                                        radius: 20
                                                        color: muteArea.containsMouse ? "#1a1225" : "#110d1a"
                                                        border {
                                                                color: root.muted ? "#ff6b6b" : "#B58FFF"
                                                                width: 0.5
                                                        }
                                                        scale: 1
                                                        Behavior on color {
                                                                ColorAnimation {
                                                                        duration: 150
                                                                }
                                                        }
                                                        Behavior on scale {
                                                                NumberAnimation {
                                                                        duration: 150
                                                                        easing.type: Easing.OutBack
                                                                }
                                                        }
                                                        Connections {
                                                                target: root
                                                                function onMutedChanged() {
                                                                        muteBtn.scale = 1.2
                                                                        muteBtnReset.start()
                                                                }
                                                        }
                                                        Timer {
                                                                id: muteBtnReset
                                                                interval: 120
                                                                repeat: false
                                                                onTriggered: muteBtn.scale = 1
                                                        }
                                                        Text {
                                                                anchors.centerIn: parent
                                                                text: root.muted ? "\ueee8" : "\uf028"
                                                                color: root.muted ? "#ff6b6b" : "#B58FFF"
                                                                font {
                                                                        family: "Monocraft"
                                                                        pixelSize: 14
                                                                }
                                                        }
                                                        MouseArea {
                                                                id: muteArea
                                                                anchors.fill: parent
                                                                hoverEnabled: true
                                                                cursorShape: Qt.PointingHandCursor
                                                                onClicked: {
                                                                        muteBtn.scale = 1.25
                                                                        muteBtnReset.start()
                                                                        var sink = Pipewire.defaultAudioSink
                                                                        if (sink && sink.ready && sink.audio) {
                                                                                sink.audio.muted = !sink.audio.muted
                                                                                root.refreshState()
                                                                        }
                                                                }
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
                                                                id: volFill
                                                                width: parent.width * Math.max(0, Math.min(1, root.vVolume))
                                                                height: parent.height
                                                                radius: 20
                                                                color: root.muted ? "#ff6b6b" : "#B58FFF"
                                                                Behavior on width {
                                                                        NumberAnimation {
                                                                                duration: 120
                                                                                easing.type: Easing.OutQuad
                                                                        }
                                                                }
                                                                Behavior on color {
                                                                        ColorAnimation {
                                                                                duration: 150
                                                                        }
                                                                }
                                                        }
                                                        MouseArea {
                                                                id: barMouse
                                                                anchors.fill: parent
                                                                cursorShape: Qt.PointingHandCursor
                                                                property bool pressed: false
                                                                onWheel: function(event) {
                                                                        var sink = Pipewire.defaultAudioSink
                                                                        if (!sink || !sink.ready || !sink.audio) return
                                                                        var step = 0.05
                                                                        var cur = sink.audio.volume
                                                                        if (event.angleDelta.y > 0) {
                                                                                sink.audio.volume = Math.min(1, cur + step)
                                                                        } else {
                                                                                sink.audio.volume = Math.max(0, cur - step)
                                                                        }
                                                                        root.refreshState()
                                                                }
                                                                function setVolumeFromX(x) {
                                                                        var sink = Pipewire.defaultAudioSink
                                                                        if (!sink || !sink.ready || !sink.audio) return
                                                                        var ratio = x / width
                                                                        root.vVolume = ratio
                                                                        sink.audio.volume = Math.max(0, Math.min(1, ratio))
                                                                        root.refreshState()
                                                                }
                                                                onPressed: function(mouse) {
                                                                        pressed = true
                                                                        root.volDragging = true
                                                                        setVolumeFromX(mouse.x)
                                                                }
                                                                onPositionChanged: function(mouse) {
                                                                        if (pressed) {
                                                                                setVolumeFromX(mouse.x)
                                                                        }
                                                                }
                                                                onReleased: function(mouse) {
                                                                        pressed = false
                                                                        root.volDragging = false
                                                                        root.vVolume = root.volume
                                                                }
                                                        }
                                                }
                                                Text {
                                                        text: root.volumePct + "%"
                                                        color: "#E8DBFF"
                                                        font {
                                                                family: "Monocraft"
                                                                pixelSize: 11
                                                        }
                                                }
                                        }
                                }
                                Item {
                                        width: parent.width
                                        height: 34
                                        visible: root.hasMic
                                        RowLayout {
                                                width: parent.width
                                                spacing: 8
                                                Rectangle {
                                                        id: micMuteBtn
                                                        width: 18
                                                        height: 18
                                                        radius: 20
                                                        color: micMuteArea.containsMouse ? "#1a1225" : "#110d1a"
                                                        border {
                                                                color: root.micMuted ? "#ff6b6b" : "#B58FFF"
                                                                width: 0.5
                                                        }
                                                        scale: 1
                                                        Behavior on color {
                                                                ColorAnimation {
                                                                        duration: 150
                                                                }
                                                        }
                                                        Behavior on scale {
                                                                NumberAnimation {
                                                                        duration: 150
                                                                        easing.type: Easing.OutBack
                                                                }
                                                        }
                                                        Connections {
                                                                target: root
                                                                function onMicMutedChanged() {
                                                                        micMuteBtn.scale = 1.2
                                                                        micMuteBtnReset.start()
                                                                }
                                                        }
                                                        Timer {
                                                                id: micMuteBtnReset
                                                                interval: 120
                                                                repeat: false
                                                                onTriggered: micMuteBtn.scale = 1
                                                        }
                                                        Text {
                                                                anchors.centerIn: parent
                                                                text: root.micMuted ? "\ueee8" : "\uf130"
                                                                color: root.micMuted ? "#ff6b6b" : "#B58FFF"
                                                                font {
                                                                        family: "Monocraft"
                                                                        pixelSize: 14
                                                                }
                                                        }
                                                        MouseArea {
                                                                id: micMuteArea
                                                                anchors.fill: parent
                                                                hoverEnabled: true
                                                                cursorShape: Qt.PointingHandCursor
                                                                onClicked: {
                                                                        micMuteBtn.scale = 1.25
                                                                        micMuteBtnReset.start()
                                                                        var src = Pipewire.defaultAudioSource
                                                                        if (src && src.ready && src.audio) {
                                                                                src.audio.muted = !src.audio.muted
                                                                                root.refreshState()
                                                                        }
                                                                }
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
                                                                id: micFill
                                                                width: parent.width * Math.max(0, Math.min(1, root.vMicVolume))
                                                                height: parent.height
                                                                radius: 20
                                                                color: root.micMuted ? "#ff6b6b" : "#B58FFF"
                                                                Behavior on width {
                                                                        NumberAnimation {
                                                                                duration: 120
                                                                                easing.type: Easing.OutQuad
                                                                        }
                                                                }
                                                                Behavior on color {
                                                                        ColorAnimation {
                                                                                duration: 150
                                                                        }
                                                                }
                                                        }
                                                        MouseArea {
                                                                id: micBarMouse
                                                                anchors.fill: parent
                                                                cursorShape: Qt.PointingHandCursor
                                                                property bool pressed: false
                                                                onWheel: function(event) {
                                                                        var src = Pipewire.defaultAudioSource
                                                                        if (!src || !src.ready || !src.audio) return
                                                                        var step = 0.05
                                                                        var cur = src.audio.volume
                                                                        if (event.angleDelta.y > 0) {
                                                                                src.audio.volume = Math.min(1, cur + step)
                                                                        } else {
                                                                                src.audio.volume = Math.max(0, cur - step)
                                                                        }
                                                                        root.refreshState()
                                                                }
                                                                function setVolumeFromX(x) {
                                                                        var src = Pipewire.defaultAudioSource
                                                                        if (!src || !src.ready || !src.audio) return
                                                                        var ratio = x / width
                                                                        root.vMicVolume = ratio
                                                                        src.audio.volume = Math.max(0, Math.min(1, ratio))
                                                                        root.refreshState()
                                                                }
                                                                onPressed: function(mouse) {
                                                                        pressed = true
                                                                        root.micDragging = true
                                                                        setVolumeFromX(mouse.x)
                                                                }
                                                                onPositionChanged: function(mouse) {
                                                                        if (pressed) {
                                                                                setVolumeFromX(mouse.x)
                                                                        }
                                                                }
                                                                onReleased: function(mouse) {
                                                                        pressed = false
                                                                        root.micDragging = false
                                                                        root.vMicVolume = root.micVolume
                                                                }
                                                        }
                                                }
                                                Text {
                                                        text: root.micVolumePct + "%"
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
                interval: 2000
                repeat: false
                onTriggered: {
                        root.pctVisible = false
                }
        }
        Timer {
                id: micPctHideTimer
                interval: 2000
                repeat: false
                onTriggered: {
                        root.micPctVisible = false
                }
        }
}
