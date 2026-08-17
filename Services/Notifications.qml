import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick
import "../Components" as MD3
import QtQuick.Controls
import QtQuick.Layouts
Item {
        id: root
        implicitWidth: bellWrapper.width + (unreadCount > 0 ? dotIndicator.width + 0 : 0) + 0
        implicitHeight: 32
        property var rootWindow: null
        property bool popupOpen: false
        property bool popupReady: false
        property int unreadCount: 0
        property var recvdTimes: ({})
        property var notifications: []
        property bool hasToasts: false
        property bool doNotDisturb: false
        ListModel { id: toastModel }
        IpcHandler {
                id: ipc
                target: "notifications"
                enabled: true
                function toggle() {
                        if (root.popupOpen) {
                                root.popupOpen = false
                        } else {
                                closeTimer.stop()
                                root.unreadCount = 0
                                root.popupReady = true
                                root.popupOpen = true
                        }
                }
                function dnd() {
                        root.doNotDisturb = !root.doNotDisturb
                        if (root.doNotDisturb) {
                                toastModel.clear()
                                root.hasToasts = false
                        }
                }
        }
        NotificationServer {
                id: notifServer
                actionsSupported: true
                bodySupported: true
                onNotification: function(notif) {
                        if (root.doNotDisturb) {
                                return
                        }
                        notif.tracked = true
                        root.recvdTimes[notif.id] = new Date()
                        root.unreadCount++
                        var exists = false
                        for (var i = 0; i < root.notifications.length; i++) {
                                if (root.notifications[i].id === notif.id) {
                                        exists = true
                                        break
                                }
                        }
                        if (!exists) {
                                if (root.notifications.length >= 20) {
                                        var old = root.notifications.shift()
                                        try { old.dismiss() } catch(e) {}
                                }
                                root.notifications.push(notif)
                        }
                        root.notifications = root.notifications.slice()
                        toastModel.insert(0, { notif: notif })
                        root.hasToasts = true
                }
        }
        function clearAll() {
                for (var i = root.notifications.length - 1; i >= 0; i--) {
                        try {
                                root.notifications[i].dismiss()
                        } catch(e) {}
                }
                root.notifications = []
                toastModel.clear()
                root.unreadCount = 0
                root.hasToasts = false
                root.recvdTimes = {}
                dotIndicator.visible = false
        }
        function removeNotification(id) {
                for (var i = 0; i < root.notifications.length; i++) {
                        if (root.notifications[i].id === id) {
                                try {
                                        root.notifications[i].dismiss()
                                } catch(e) {}
                                root.notifications.splice(i, 1)
                                break
                        }
                }
                root.notifications = root.notifications.slice()
                for (var j = toastModel.count - 1; j >= 0; j--) {
                        if (toastModel.get(j).notif.id === id) {
                                toastModel.remove(j)
                        }
                }
                root.hasToasts = toastModel.count > 0
                if (root.notifications.length === 0) {
                        root.unreadCount = 0
                }
        }
        function dismissToast(nid) {
                for (var i = toastModel.count - 1; i >= 0; i--) {
                        if (toastModel.get(i).notif.id === nid) {
                                toastModel.remove(i)
                        }
                }
                root.hasToasts = toastModel.count > 0
        }
        Item {
                id: bellWrapper
                width: 22
                height: 22
                anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                }
                Text {
                        id: bellIcon
                        text: root.doNotDisturb ? "\uf056" : "\uf0f3"
                        color: "#89b4fa"
                        scale: 1
                        anchors.centerIn: parent
                        font {
                                family: "Monocraft"
                                pixelSize: 18
                        }
                        Behavior on scale {
                                NumberAnimation {
                                        duration: 150
                                        easing.type: Easing.OutBack
                                }
                        }
                        Timer {
                                id: bellScaleReset
                                interval: 120
                                repeat: false
                                onTriggered: bellIcon.scale = 1
                        }
                }
                MD3.Pressable {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: function(mouse) {
                                bellIcon.scale = 1.25
                                bellScaleReset.start()
                                if (!root.popupOpen) {
                                        closeTimer.stop()
                                        root.unreadCount = 0
                                        root.popupReady = true
                                        root.popupOpen = true
                                } else {
                                        root.popupOpen = false
                                }
                        }
                }
        }
        Rectangle {
                id: dotIndicator
                visible: root.unreadCount > 0 && !root.doNotDisturb
                anchors {
                        left: bellWrapper.right
                        leftMargin: -4
                        top: bellWrapper.top
                        topMargin: 0
                }
                width: 6
                height: 6
                radius: 3
                color: "#f38ba8"
        }
        PopupWindow {
                id: popup
                visible: root.popupReady
                grabFocus: true
                color: "transparent"
                implicitWidth: 340
                implicitHeight: 440
                anchor {
                        window: root.rootWindow
                        rect.x: root.x + (root.width - implicitWidth) / 2
                        rect.y: root.y + root.height + 8
                }
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
                                NumberAnimation { duration: 200; easing.type: Easing.OutQuad }
                        }
                        Behavior on scale {
                                NumberAnimation { duration: 200; easing.type: Easing.OutQuad }
                        }
                        ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 10
                                RowLayout {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 28
                                        spacing: 6
                                        Text {
                                                 text: Translation.tr("notifications.popup.title")
                                                color: "#cdd6f4"
                                                font {
                                                        family: "Monocraft"
                                                        pixelSize: 14
                                                        bold: true
                                                }
                                        }
                                        Item { Layout.fillWidth: true }
                                        Rectangle {
                                                id: dndBtn
                                                width: 24
                                                height: 24
                                                radius: 6
                                                color: "transparent"
                                                border {
                                                        color: "#45475a"
                                                        width: 1
                                                }
                                                clip: true
                                                Rectangle {
                                                        id: dndHoverFill
                                                        anchors.centerIn: parent
                                                        width: 0
                                                        height: 0
                                                        radius: 6
                                                        color: "#89b4fa"
                                                        opacity: 0.2
                                                        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuad } }
                                                        Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutQuad } }
                                                }
                                                Text {
                                                        anchors.centerIn: parent
                                                        text: root.doNotDisturb ? "\uf056" : "\uf0f3"
                                                        color: "#89b4fa"
                                                        font {
                                                                family: "Monocraft"
                                                                pixelSize: 14
                                                        }
                                                }
                                                MD3.Pressable {
                                                        id: dndArea
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor
                                                        onEntered: {
                                                                dndHoverFill.width = parent.width
                                                                dndHoverFill.height = parent.height
                                                        }
                                                        onExited: {
                                                                dndHoverFill.width = 0
                                                                dndHoverFill.height = 0
                                                        }
                                                        onClicked: {
                                                                root.doNotDisturb = !root.doNotDisturb
                                                                if (root.doNotDisturb) {
                                                                        toastModel.clear()
                                                                        root.hasToasts = false
                                                                }
                                                        }
                                                }
                                        }
                                        Rectangle {
                                                id: clearBtn
                                                width: clearLabel.implicitWidth - 90
                                                height: 24
                                                radius: 6
                                                color: "transparent"
                                                border {
                                                        color: "#45475a"
                                                        width: 1
                                                }
                                                clip: true
                                                Rectangle {
                                                        id: clearHoverFill
                                                        anchors.centerIn: parent
                                                        width: 0
                                                        height: 0
                                                        radius: 6
                                                        color: "#89b4fa"
                                                        opacity: 0.2
                                                        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuad } }
                                                        Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutQuad } }
                                                }
                                                Text {
                                                        id: clearLabel
                                                        anchors.centerIn: parent
                                                        text: Translation.tr("notifications.clear")
                                                        color: "#89b4fa"
                                                        font {
                                                                family: "Monocraft"
                                                                pixelSize: 11
                                                        }
                                                }
                                                MD3.Pressable {
                                                        id: clearArea
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor
                                                        onEntered: {
                                                                clearHoverFill.width = parent.width
                                                                clearHoverFill.height = parent.height
                                                        }
                                                        onExited: {
                                                                clearHoverFill.width = 0
                                                                clearHoverFill.height = 0
                                                        }
                                                        onClicked: clearAll()
                                                }
                                        }
                                        Rectangle {
                                                id: closeBtn
                                                width: 24
                                                height: 24
                                                radius: 6
                                                color: "transparent"
                                                border {
                                                        color: "#45475a"
                                                        width: 1
                                                }
                                                clip: true
                                                Rectangle {
                                                        id: closeHoverFill
                                                        anchors.centerIn: parent
                                                        width: 0
                                                        height: 0
                                                        radius: 6
                                                        color: "#89b4fa"
                                                        opacity: 0.2
                                                        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuad } }
                                                        Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutQuad } }
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
                                Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 1
                                        color: "#45475a"
                                }
                                Flickable {
                                        id: popupFlickable
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        clip: true
                                        contentHeight: popupContent.height
                                        boundsBehavior: Flickable.StopAtBounds
                                        ScrollBar.vertical: ScrollBar {
                                                id: vbar
                                                width: 10
                                                policy: ScrollBar.AlwaysOn
                                                opacity: 1
                                                contentItem: Rectangle {
                                                        implicitWidth: 10
                                                        radius: 5
                                                        color: "#89b4fa"
                                                        border {
                                                                color: "#89b4fa"
                                                                width: 1
                                                        }
                                                }
                                                background: Rectangle {
                                                        implicitWidth: 10
                                                        radius: 5
                                                        color: "#313244"
                                                }
                                        }
                                        Column {
                                                id: popupContent
                                                width: popupFlickable.width - 16
                                                spacing: 8
                                                Repeater {
                                                        id: notifList
                                                        model: root.doNotDisturb ? [] : root.notifications
                                                        delegate: Rectangle {
                                                                id: card
                                                                width: popupContent.width
                                                                radius: 12
                                                                color: modelData.urgency === 2 ? "#2a0f1a" : "#181825"
                                                                border {
                                                                        color: "#45475a"
                                                                        width: 1
                                                                }
                                                                property bool closing: false
                                                                opacity: closing ? 0 : 1
                                                                Behavior on opacity {
                                                                        NumberAnimation { duration: 300; easing.type: Easing.OutQuad }
                                                                }
                                                                height: cardContent.height + 20
                                                                onOpacityChanged: {
                                                                        if (opacity === 0 && closing) {
                                                                                removeNotification(modelData.id)
                                                                        }
                                                                }
                                                                Rectangle {
                                                                        id: notifDismiss
                                                                        width: 18
                                                                        height: 18
                                                                        radius: 4
                                                                        anchors {
                                                                                top: parent.top
                                                                                topMargin: 6
                                                                                right: parent.right
                                                                                rightMargin: 6
                                                                        }
                                                                        color: notifDismissArea.containsMouse ? "#f38ba8" : "transparent"
                                                                        border {
                                                                                color: "#45475a"
                                                                                width: 0.5
                                                                        }
                                                                        Text {
                                                                                anchors.centerIn: parent
                                                                                text: "\uf00d"
                                                                                color: "#89b4fa"
                                                                                font {
                                                                                        family: "Monocraft"
                                                                                        pixelSize: 10
                                                                                }
                                                                        }
                                                                        MD3.Pressable {
                                                                                id: notifDismissArea
                                                                                anchors.fill: parent
                                                                                hoverEnabled: true
                                                                                cursorShape: Qt.PointingHandCursor
                                                                                onClicked: {
                                                                                        card.closing = true
                                                                                }
                                                                        }
                                                                }
                                                                MD3.Pressable {
                                                                        anchors.fill: parent
                                                                        hoverEnabled: true
                                                                        cursorShape: Qt.PointingHandCursor
                                                                        onClicked: {
                                                                                if (modelData.actions && modelData.actions.length > 0) {
                                                                                        modelData.actions[0].invoke()
                                                                                }
                                                                                card.closing = true
                                                                        }
                                                                }
                                                                ColumnLayout {
                                                                        id: cardContent
                                                                        anchors {
                                                                                left: parent.left
                                                                                right: parent.right
                                                                                top: parent.top
                                                                                leftMargin: 10
                                                                                rightMargin: 30
                                                                                topMargin: 10
                                                                        }
                                                                        spacing: 4
                                                                        Column {
                                                                                Layout.fillWidth: true
                                                                                spacing: 2
                                                                                Text {
                                                                                        width: parent.width
                                                                                         text: modelData.appName || "Application"
                                                                                        color: "#89b4fa"
                                                                                        font {
                                                                                                family: "Monocraft"
                                                                                                pixelSize: 10
                                                                                        }
                                                                                }
                                                                                Text {
                                                                                        width: parent.width
                                                                                        text: modelData.summary || ""
                                                                                        color: "#cdd6f4"
                                                                                        font {
                                                                                                family: "Monocraft"
                                                                                                pixelSize: 12
                                                                                                bold: true
                                                                                        }
                                                                                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                                                                                }
                                                                                Text {
                                                                                        width: parent.width
                                                                                        text: modelData.body || ""
                                                                                        color: "#cdd6f4"
                                                                                        visible: modelData.body && modelData.body.length > 0
                                                                                        font {
                                                                                                family: "Monocraft"
                                                                                                pixelSize: 11
                                                                                        }
                                                                                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                                                                                }
                                                                        }
                                                                }
                                                        }
                                                }
                                                Rectangle {
                                                        width: parent.width
                                                        height: 60
                                                        radius: 12
                                                        color: "#181825"
                                                        border {
                                                                color: "#45475a"
                                                                width: 1
                                                        }
                                                        visible: notifList.count === 0
                                                        Text {
                                                                anchors.centerIn: parent
                                                                 text: root.doNotDisturb ? Translation.tr("notifications.dnd") : Translation.tr("notifications.empty")
                                                                color: "#585b70"
                                                                font {
                                                                        family: "Monocraft"
                                                                        pixelSize: 12
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
        PanelWindow {
                id: toastWindow
                visible: root.hasToasts && !root.doNotDisturb
                anchors {
                        top: true
                        right: true
                }
                margins {
                        top: 44
                        right: 12
                        bottom: 12
                        left: 12
                }
                color: "transparent"
                width: 384
                height: Math.min(toastColumn.height, 350)
                Item {
                        anchors.fill: parent
                        clip: true
                        Column {
                                id: toastColumn
                                spacing: 8
                                Repeater {
                                        id: toastRepeater
                                        model: toastModel
                                        delegate: Item {
                                                id: toastCard
                                                width: 384
                                                property var notif: model.notif
                                                property bool closing: false
                                                property bool shown: false
                                                opacity: shown ? (closing ? 0 : 1) : 0
                                                Behavior on opacity {
                                                        NumberAnimation { duration: 300; easing.type: Easing.OutQuad }
                                                }
                                                height: toastInner.height
                                                onOpacityChanged: {
                                                        if (opacity === 0 && closing) {
                                                                root.dismissToast(notif.id)
                                                        }
                                                }
                                                Component.onCompleted: {
                                                        shown = true
                                                        Qt.callLater(function() {
                                                                toastTimer.start()
                                                        })
                                                }
                                                Timer {
                                                        id: toastTimer
                                                        interval: 5000
                                                        repeat: false
                                                        onTriggered: toastCard.closing = true
                                                }
                                                Rectangle {
                                                        id: toastInner
                                                        anchors.top: parent.top
                                                        width: parent.width
                                                        radius: 14
                                                        color: notif.urgency === 2 ? "#2a0f1a" : "#181825"
                                                        border {
                                                                color: "#45475a"
                                                                width: 1
                                                        }
                                                        height: toastContent.height + 16
                                                        MD3.Pressable {
                                                                anchors.fill: parent
                                                                hoverEnabled: true
                                                                cursorShape: Qt.PointingHandCursor
                                                                onClicked: {
                                                                        if (notif && notif.actions && notif.actions.length > 0) {
                                                                                notif.actions[0].invoke()
                                                                        }
                                                                        toastCard.closing = true
                                                                }
                                                        }
                                                        Rectangle {
                                                                id: toastDismiss
                                                                width: 18
                                                                height: 18
                                                                radius: 4
                                                                anchors {
                                                                        top: parent.top
                                                                        topMargin: 6
                                                                        right: parent.right
                                                                        rightMargin: 6
                                                                }
                                                                color: toastDismissArea.containsMouse ? "#f38ba8" : "transparent"
                                                                border {
                                                                        color: "#45475a"
                                                                        width: 0.5
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
                                                                        id: toastDismissArea
                                                                        anchors.fill: parent
                                                                        hoverEnabled: true
                                                                        cursorShape: Qt.PointingHandCursor
                                                                        onClicked: {
                                                                                toastCard.closing = true
                                                                        }
                                                                }
                                                        }
                                                        ColumnLayout {
                                                                id: toastContent
                                                                anchors {
                                                                        left: parent.left
                                                                        right: parent.right
                                                                        top: parent.top
                                                                        leftMargin: 10
                                                                        rightMargin: 30
                                                                        topMargin: 8
                                                                        bottomMargin: 8
                                                                }
                                                                spacing: 4
                                                                Column {
                                                                        Layout.fillWidth: true
                                                                        spacing: 2
                                                                        Text {
                                                                                width: parent.width
                                                                                 text: notif.appName || "Application"
                                                                                color: "#89b4fa"
                                                                                font {
                                                                                        family: "Monocraft"
                                                                                        pixelSize: 14
                                                                                }
                                                                        }
                                                                        Text {
                                                                                width: parent.width
                                                                                text: notif.summary || ""
                                                                                color: "#cdd6f4"
                                                                                font {
                                                                                        family: "Monocraft"
                                                                                        pixelSize: 14
                                                                                        bold: true
                                                                                }
                                                                                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                                                                        }
                                                                        Text {
                                                                                width: parent.width
                                                                                text: notif.body || ""
                                                                                color: "#cdd6f4"
                                                                                visible: notif.body && notif.body.length > 0
                                                                                font {
                                                                                        family: "Monocraft"
                                                                                        pixelSize: 13
                                                                                }
                                                                                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                                                                        }
                                                                }
                                                        }
                                                }
                                        }
                                }
                        }
                }
        }
}
