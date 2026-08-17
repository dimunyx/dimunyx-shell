import Quickshell
import Quickshell.Io
import QtQuick
import "../Components" as MD3
import Quickshell.Widgets
import "../Services"
import "../Services/WM"
Item {
        id: root
        implicitWidth: 60
        implicitHeight: 32
        property var rootWindow: null
        property bool popupOpen: false
        property bool popupReady: false
        property var layouts: WM.keyboardLayouts.names
        property int current: WM.keyboardLayouts.current_idx
        property int hoveredIndex: -1
        property var shortNames: ({
                "English (US)": "US",
                "Russian": "RU",
                "us": "US",
                "ru": "RU"
        })
        function shortName(name) {
                return shortNames[name] ?? name.substring(0, 2).toUpperCase()
        }
        Text {
                id: icon
                text: "󰌌"
                color: "#89b4fa"
                scale: 1
                anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                }
                font {
                        family: "Monocraft"
                        pixelSize: 32
                }
                Behavior on scale {
                        NumberAnimation {
                                duration: 150
                                easing.type: Easing.OutBack
                        }
                }
        }
        Text {
                id: layoutText
                anchors {
                        left: icon.right
                        leftMargin: 5
                        verticalCenter: parent.verticalCenter
                }
                text: root.shortName(root.layouts[root.current] ?? "")
                color: "#cdd6f4"
                font {
                        family: "Monocraft"
                        pixelSize: 14
                }
        }
        MD3.Pressable {
                id: rootMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                        icon.scale = 1.25
                        iconReset.start()
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
                implicitWidth: 126
                implicitHeight: 88
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
                        Column {
                                anchors {
                                        fill: parent
                                        margins: 12
                                }
                                spacing: 6
                                Item {
                                        width: parent.width
                                        height: 24
                                        Text {
                                                anchors {
                                                        left: parent.left
                                                        verticalCenter: parent.verticalCenter
                                                }
                                                 text: Translation.tr("kblayout.popup.title")
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
                                Item {
                                        width: parent.width
                                        height: 34
                                        Row {
                                                spacing: 4
                                                Repeater {
                                                        model: root.layouts
                                                        delegate: Rectangle {
                                                                id: layoutBtn
                                                                width: 48
                                                                height: 34
                                                                radius: 8
                                                                color: "transparent"
                                                                border {
                                                                        color: index === root.current ? "#89b4fa" : "#45475a"
                                                                        width: index === root.current ? 2 : 1
                                                                }
                                                                clip: true
                                                                Rectangle {
                                                                        id: layoutHoverFill
                                                                        anchors.centerIn: parent
                                                                        width: 0
                                                                        height: 0
                                                                        radius: 8
                                                                        color: "#89b4fa"
                                                                        opacity: 0.15
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
                                                                        text: root.shortName(modelData)
                                                                        color: index === root.current ? "#89b4fa" : "#cdd6f4"
                                                                        font {
                                                                                family: "Monocraft"
                                                                                pixelSize: 13
                                                                        }
                                                                }
                                                                MD3.Pressable {
                                                                        id: capsuleArea
                                                                        anchors.fill: parent
                                                                        hoverEnabled: true
                                                                        cursorShape: Qt.PointingHandCursor
                                                                        onEntered: {
                                                                                root.hoveredIndex = index
                                                                                layoutHoverFill.width = parent.width
                                                                                layoutHoverFill.height = parent.height
                                                                        }
                                                                        onExited: {
                                                                                root.hoveredIndex = -1
                                                                                layoutHoverFill.width = 0
                                                                                layoutHoverFill.height = 0
                                                                        }
                                                                        onClicked: {
                                                                                WM.switchLayout(index)
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
                id: iconReset
                interval: 120
                repeat: false
                onTriggered: icon.scale = 1
        }
        Connections {
                target: root.rootWindow
                onPressed: function(mouse) {
                        if (root.popupOpen) {
                                var pos = root.mapFromItem(null, mouse.x, mouse.y)
                                if (pos.x < 0 || pos.x > root.width || pos.y < 0 || pos.y > root.height) {
                                        root.popupOpen = false
                                }
                        }
                }
        }
}
