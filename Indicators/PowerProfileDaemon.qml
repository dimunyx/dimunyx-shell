import QtQuick
import "../Components" as MD3
import Quickshell
import Quickshell.Io
import QtQuick.Layouts
import "../Services"
Item {
        id: root
        implicitWidth: powerRow.implicitWidth
        implicitHeight: 32
        property var rootWindow: null
        property bool popupOpen: false
        property bool popupReady: false
        property bool pctVisible: false
        property string currentProfile: "balanced"
        property string profileLabel: "Balanced"
        property int profileIndex: 1
        property int hoveredIndex: -1
        property string pendingProfile: "balanced"
        property string profileIcon: "\udb83\udf85"
readonly property var profiles: [
        { key: "performance", label: "Performance", icon: "\udb81\udcc5" },
        { key: "balanced", label: "Balanced", icon: "\udb83\udf85" },
        { key: "power-saver", label: "Power Saver", icon: "\udb83\udf86" }
]
        function refreshProfile() {
                refreshProcess.running = true
        }
        function setProfile(profile) {
                root.pendingProfile = profile
                setProfileProcess.running = true
        }
        Component.onCompleted: refreshProfile()
        Process {
                id: refreshProcess
                command: ["sh", "-c", "powerprofilesctl get 2>/dev/null || echo 'balanced'"]
                stdout: StdioCollector {
                        onStreamFinished: {
                                var prof = this.text.trim()
                                if (prof) {
                                        root.currentProfile = prof
                                        for (var i = 0; i < root.profiles.length; i++) {
                                                if (root.profiles[i].key === prof) {
                                                        root.profileLabel = Translation.tr("power." + prof)
                                                        root.profileIcon = root.profiles[i].icon
                                                        root.profileIndex = i
                                                        break
                                                }
                                        }
                                }
                        }
                }
                running: false
        }
        Process {
                id: setProfileProcess
                command: ["powerprofilesctl", "set", root.pendingProfile]
                running: false
                onExited: {
                        if (exitCode === 0) {
                                root.currentProfile = root.pendingProfile
                                for (var i = 0; i < root.profiles.length; i++) {
                                        if (root.profiles[i].key === root.pendingProfile) {
                                                root.profileLabel = Translation.tr("power." + root.pendingProfile)
                                                root.profileIcon = root.profiles[i].icon
                                                root.profileIndex = i
                                                break
                                        }
                                }
                                root.popupOpen = false
                        }
                }
        }
        Timer {
                interval: 10000
                repeat: true
                running: true
                onTriggered: refreshProfile()
        }
        RowLayout {
                id: powerRow
                anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                }
                spacing: 0
                Text {
                        id: powerIcon
                        text: root.profileIcon
                        color: "#89b4fa"
                        scale: 1
                        font {
                                family: "Monocraft"
                                pixelSize: 24
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
                        id: powerPctWrap
                        Layout.preferredWidth: root.pctVisible ? powerPct.implicitWidth : 0
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
                                id: powerPct
                                anchors {
                                        right: parent.right
                                        verticalCenter: parent.verticalCenter
                                }
                                text: root.profileLabel
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
                id: powerArea
                anchors.fill: parent
                hoverEnabled: false
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: {
                        powerIcon.scale = 1.25
                        powerIconReset.start()
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
                implicitWidth: 220
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
                        MD3.Pressable {
                                anchors.fill: parent
                                hoverEnabled: false
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
                                        topMargin: 12
                                        leftMargin: 12
                                        rightMargin: 12
                                }
                                spacing: 8
                                Item {
                                        width: parent.width
                                        height: 24
                                        RowLayout {
                                                anchors.fill: parent
                                                spacing: 8
                                                Text {
                                                        text: Translation.tr("power.popup.title")
                                                        color: "#cdd6f4"
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
                                                        border { color: "#45475a"; width: 1 }
                                                        clip: true
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
                                                                hoverEnabled: false
                                                                cursorShape: Qt.PointingHandCursor
                                                                onClicked: root.popupOpen = false
                                                        }
                                                }
                                        }
                                }
                                Rectangle {
                                        width: parent.width
                                        height: 1
                                        color: "#45475a"
                                }
                                Text {
                                        width: parent.width
									text: Translation.trf("power.current", Translation.tr("power." + root.currentProfile))
                                        color: "#89b4fa"
                                        font {
                                                family: "Monocraft"
                                                pixelSize: 12
                                        }
                                }
                                Rectangle {
                                        width: parent.width
                                        height: 1
                                        color: "#45475a"
                                }
                                Column {
                                        id: profilesColumn
                                        width: parent.width
                                        spacing: 4
                                        Repeater {
                                                model: root.profiles
                                                delegate: Rectangle {
                                                        required property var modelData
                                                        width: parent.width
                                                        height: 32
                                                        radius: 6
                                                        color: "#181825"
                                                                border {
                                                                        color: root.currentProfile === modelData.key ? "#89b4fa" : "#45475a"
                                                                        width: root.currentProfile === modelData.key ? 2 : 1
                                                                }
                                                        RowLayout {
                                                                anchors {
                                                                        fill: parent
                                                                        leftMargin: 8
                                                                        rightMargin: 8
                                                                }
                                                                spacing: 8
                                                                Text {
                                                                        text: modelData.icon
                                                                        color: root.currentProfile === modelData.key ? "#89b4fa" : "#45475a"
                                                                        font.pixelSize: 16
                                                                }
									Text {
										text: Translation.tr("power." + modelData.key)
                                                                        color: root.currentProfile === modelData.key ? "#cdd6f4" : "#585b70"
                                                                        font {
                                                                                family: "Monocraft"
                                                                                pixelSize: 14
                                                                        }
                                                                        Layout.fillWidth: true
                                                                }
                                                                Rectangle {
                                                                        visible: root.currentProfile === modelData.key
                                                                        width: 6
                                                                        height: 6
                                                                        radius: 3
                                                                        color: "#89b4fa"
                                                                }
                                                        }
                                                        MD3.Pressable {
                                                                id: hoverArea
                                                                anchors.fill: parent
                                                                hoverEnabled: false
                                                                cursorShape: Qt.PointingHandCursor
                                                                onClicked: {
                                                                        if (root.currentProfile !== modelData.key) {
                                                                                setProfile(modelData.key)
                                                                        } else {
                                                                                root.popupOpen = false
                                                                        }
                                                                }
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
                id: powerIconReset
                interval: 120
                repeat: false
                onTriggered: powerIcon.scale = 1
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
