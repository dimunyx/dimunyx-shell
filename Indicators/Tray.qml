import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Services.SystemTray
Item {
        id: root
        property var rootWindow: null
        property int iconSize: 22
        implicitWidth: trayRow.implicitWidth + 7.5
        implicitHeight: trayRow.implicitHeight + 10
        Row {
                id: trayRow
                anchors {
                        left: parent.left
                        leftMargin: 2
                        verticalCenter: parent.verticalCenter
                }
                spacing: -3
                Repeater {
                        id: trayRepeater
                        model: SystemTray.items
                        delegate: Item {
                                required property var modelData
                                width: root.iconSize + 4
                                height: root.iconSize + 4
                                Image {
                                        id: trayIcon
                                        anchors.centerIn: parent
                                        width: root.iconSize
                                        height: root.iconSize
                                        source: {
                                                var icon = modelData && modelData.icon ? modelData.icon : ""
                                                if (icon.indexOf("?path=") !== -1) {
                                                        var parts = icon.split("?path=")
                                                        var name = parts[0]
                                                        var path = parts[1]
                                                        var file = name.substring(name.lastIndexOf("/") + 1)
                                                        return "file://" + path + "/" + file
                                                }
                                                return icon
                                        }
                                        sourceSize: Qt.size(64, 64)
                                        cache: false
                                        smooth: true
                                        fillMode: Image.PreserveAspectFit
                                }
                                QsMenuAnchor {
                                        id: menuAnchor
                                        menu: modelData && modelData.hasMenu ? modelData.menu : null
                                        anchor {
                                                window: rootWindow
                                        }
                                        anchor {
                                                item: trayIcon
                                        }
                                }
                                MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                                        onPressed: function(mouse) {
                                                if (mouse.button === Qt.LeftButton) {
                                                        if (modelData && modelData.onlyMenu && modelData.hasMenu) {
                                                                menuAnchor.open()
                                                        } else {
                                                                if (modelData && modelData.activate) {
                                                                        modelData.activate()
                                                                }
                                                        }
                                                } else if (mouse.button === Qt.MiddleButton) {
                                                        if (modelData && modelData.secondaryActivate) {
                                                                modelData.secondaryActivate()
                                                        }
                                                } else if (mouse.button === Qt.RightButton) {
                                                        if (modelData && modelData.hasMenu) {
                                                                menuAnchor.open()
                                                        }
                                                }
                                        }
                                        onWheel: function(wheel) {
                                                if (modelData && modelData.scroll) {
                                                        modelData.scroll(wheel.angleDelta.y, false)
                                                }
                                        }
                                }
                                ToolTip.visible: parent.containsMouse
                                ToolTip.text: (modelData && (modelData.tooltipTitle || modelData.title)) ? (modelData.tooltipTitle || modelData.title) : ""
                                ToolTip.delay: 500
                                ToolTip.timeout: 5000
                        }
                }
        }
        Connections {
                target: SystemTray
                function onItemAdded(item) {
                        var menu = item.menu
                        if (menu) {
                                menu.palette = Quickshell.palette
                                menu.delegate = Qt.createQmlObject('
                                        import QtQuick
                                        import QtQuick.Controls
                                        MenuItem {
                                                background: Rectangle {
                                                        color: parent.highlighted ? "#1a1225" : "transparent"
                                                        radius: 4
                                                }
                                                contentItem: Text {
                                                        text: parent.text
                                                        color: "#E8DBFF"
                                                        font.family: "Monocraft"
                                                        font.pixelSize: 12
                                                        leftPadding: 12
                                                        rightPadding: 12
                                                }
                                        }
                                ', menu)
                                menu.background = Qt.createQmlObject('
                                        import QtQuick
                                        Rectangle {
                                                color: "#000000"
                                                radius: 10
                                                border { color: "#4c3a70"; width: 1 }
                                        }
                                ', menu)
                        }
                }
        }
        Component.onCompleted: {
                var items = SystemTray.items
                for (var i = 0; i < items.length; i++) {
                        var item = items[i]
                        var menu = item.menu
                        if (menu) {
                                menu.palette = Quickshell.palette
                                menu.delegate = Qt.createQmlObject('
                                        import QtQuick
                                        import QtQuick.Controls
                                        MenuItem {
                                                background: Rectangle {
                                                        color: parent.highlighted ? "#1a1225" : "transparent"
                                                        radius: 4
                                                }
                                                contentItem: Text {
                                                        text: parent.text
                                                        color: "#E8DBFF"
                                                        font.family: "Monocraft"
                                                        font.pixelSize: 12
                                                        leftPadding: 12
                                                        rightPadding: 12
                                                }
                                        }
                                ', menu)
                                menu.background = Qt.createQmlObject('
                                        import QtQuick
                                        Rectangle {
                                                color: "#000000"
                                                radius: 10
                                                border { color: "#4c3a70"; width: 1 }
                                        }
                                ', menu)
                        }
                }
        }
}
