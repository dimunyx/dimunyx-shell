import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import QtQuick
import "../Components" as MD3
import QtQuick.Layouts
Item {
        id: root
        implicitWidth: btRow.implicitWidth
        implicitHeight: 32
        property var rootWindow: null
        property bool popupOpen: false
        property bool popupReady: false
        property bool connecting: false
        readonly property var adapter: Bluetooth.defaultAdapter
        readonly property bool btEnabled: adapter !== null && adapter.enabled
        readonly property bool scanning: adapter !== null && adapter.discovering
        property int _refresh: 0
        property var connectedDevices: []
        property string connectedDeviceName: ""
        property var pairedDevices: []
        property var discoveredDevices: []
        property bool pctVisible: false
        property bool contextMenuOpen: false
        property bool contextMenuReady: false
        property var contextNetwork: null
        property var clickPosition: Qt.point(0, 0)
        property int contextHoveredIndex: -1
        function openContextMenu(net, mouseX, mouseY) {
                root.contextNetwork = net
                root.clickPosition = Qt.point(mouseX, mouseY)
                root.contextMenuOpen = true
                root.contextMenuReady = true
        }
        Timer {
                interval: 1000
                repeat: true
                running: true
                onTriggered: {
                        root._refresh++
                        refreshDevices()
                }
        }
        function refreshDevices() {
                if (!adapter || !adapter.devices) {
                        connectedDevices = []
                        connectedDeviceName = ""
                        pairedDevices = []
                        discoveredDevices = []
                        root.connecting = false
                        return
                }
                var all = adapter.devices.values
                var connected = []
                var paired = []
                var discovered = []
                var cName = ""
                for (var i = 0; i < all.length; i++) {
                        var dev = all[i]
                        if (!dev) continue
                        if (dev.connected) {
                                connected.push(dev)
                                if (cName === "")
                                cName = dev.name !== "" ? dev.name : dev.deviceName
                                root.connecting = false
                        }
                        if (dev.paired || dev.bonded) {
                                paired.push(dev)
                        } else if (dev.name !== "") {
                                discovered.push(dev)
                        }
                }
                connectedDevices = connected
                connectedDeviceName = cName
                pairedDevices = paired
                discoveredDevices = discovered
        }
        onAdapterChanged: refreshDevices()
        Component.onCompleted: refreshDevices()
        signal closePopup()
        onClosePopup: {
                popupOpen = false
                if (adapter)
                adapter.discovering = false
        }
        RowLayout {
                id: btRow
                anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                }
                spacing: 0
                Text {
                        id: btIcon
                        text: !root.btEnabled ? "\udb80\udcb2" : "\uf294"
                        color: "#89b4fa"
                        scale: 1
                        font {
                                family: "Monocraft"
                                pixelSize: 17
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
                        id: btPctWrap
                        Layout.preferredWidth: root.pctVisible ? btPct.implicitWidth : 0
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
                                id: btPct
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.connectedDeviceName !== "" ? root.connectedDeviceName : ""
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
                onClicked: function(mouse) {
                        btIcon.scale = 1.25
                        btIconReset.start()
                        if (mouse.button === Qt.RightButton) {
                                if (root.connectedDevices.length > 0) {
                                        openContextMenu(root.connectedDevices[0], mouse.x, mouse.y)
                                }
                        } else {
                                if (!root.popupOpen) {
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
                implicitWidth: 260
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
                                hoverEnabled: true
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
                                                anchors {
                                                        fill: parent
                                                }
                                                spacing: 8
                                                Text {
                                                        text: Translation.tr("bluetooth.popup.title")
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
                                                Canvas {
                                                        id: connectSpinner
                                                        width: 16
                                                        height: 16
                                                        visible: root.connecting
                                                        property real angle: 0
                                                        Timer {
                                                                interval: 16
                                                                repeat: true
                                                                running: root.connecting
                                                                onTriggered: {
                                                                        connectSpinner.angle = (connectSpinner.angle + 6.1) % 360
                                                                        connectSpinner.requestPaint()
                                                                }
                                                        }
                                                        onPaint: {
                                                                var ctx = getContext("2d")
                                                                var cx = width / 2
                                                                var cy = height / 2
                                                                var r = 5.5
                                                                ctx.clearRect(0, 0, width, height)
                                                                var start = angle * Math.PI / 180
                                                                var end = start + Math.PI / 2
                                                                ctx.beginPath()
                                                                ctx.arc(cx, cy, r, start, end)
                                                                ctx.strokeStyle = "#89b4fa"
                                                                ctx.lineWidth = 2.5
                                                                ctx.lineCap = "round"
                                                                ctx.stroke()
                                                        }
                                                }
                                                Rectangle {
                                                        id: refreshBtn
                                                        width: 24
                                                        height: 24
                                                        radius: 6
                                                        color: "transparent"
                                                        border { color: "#45475a"; width: 1 }
                                                        clip: true
                                                        visible: !root.connecting && !root.scanning
                                                        Rectangle {
                                                                id: refreshHoverFill
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
                                                                text: "\uf021"
                                                                color: refreshArea.containsMouse ? "#89b4fa" : "#45475a"
                                                                font {
                                                                        family: "Monocraft"
                                                                        pixelSize: 14
                                                                }
                                                        }
                                                        MD3.Pressable {
                                                                id: refreshArea
                                                                anchors.fill: parent
                                                                hoverEnabled: true
                                                                cursorShape: Qt.PointingHandCursor
                                                                onEntered: {
                                                                        refreshHoverFill.width = parent.width
                                                                        refreshHoverFill.height = parent.height
                                                                }
                                                                onExited: {
                                                                        refreshHoverFill.width = 0
                                                                        refreshHoverFill.height = 0
                                                                }
                                                                onClicked: {
                                                                        if (root.adapter) {
                                                                                root.adapter.discovering = true
                                                                                refreshDevices()
                                                                        }
                                                                }
                                                        }
                                                }
                                                Rectangle {
                                                        id: scanBtn
                                                        width: 24
                                                        height: 24
                                                        radius: 6
                                                        color: "transparent"
                                                        border { color: "#45475a"; width: 1 }
                                                        clip: true
                                                        visible: root.scanning && !root.connecting
                                                        Rectangle {
                                                                id: scanHoverFill
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
                                                                color: scanArea.containsMouse ? "#89b4fa" : "#45475a"
                                                                font {
                                                                        family: "Monocraft"
                                                                        pixelSize: 14
                                                                }
                                                        }
                                                        MD3.Pressable {
                                                                id: scanArea
                                                                anchors.fill: parent
                                                                hoverEnabled: true
                                                                cursorShape: Qt.PointingHandCursor
                                                                onEntered: {
                                                                        scanHoverFill.width = parent.width
                                                                        scanHoverFill.height = parent.height
                                                                }
                                                                onExited: {
                                                                        scanHoverFill.width = 0
                                                                        scanHoverFill.height = 0
                                                                }
                                                                onClicked: {
                                                                        if (root.adapter) {
                                                                                root.adapter.discovering = false
                                                                        }
                                                                }
                                                        }
                                                }
                                                Rectangle {
                                                        id: closeBtn
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
                                }
                                RowLayout {
                                        width: parent.width
                                        spacing: 8
                                        Text {
                                                 text: root.btEnabled ? Translation.tr("bluetooth.enabled") : Translation.tr("bluetooth.disabled")
                                                color: "#cdd6f4"
                                                font {
                                                        family: "Monocraft"
                                                        pixelSize: 12
                                                }
                                        }
                                        Item {
                                                Layout.fillWidth: true
                                        }
                                        Rectangle {
                                                width: 40
                                                height: 22
                                                radius: 11
                                                color: root.btEnabled ? "#89b4fa" : "#313244"
                                                border {
                                                        color: "#45475a"
                                                        width: 1
                                                }
                                                Behavior on color {
                                                        ColorAnimation {
                                                                duration: 200
                                                                easing.type: Easing.OutQuad
                                                        }
                                                }
                                                Rectangle {
                                                        width: 16
                                                        height: 16
                                                        radius: 8
                                                        color: "#cdd6f4"
                                                        anchors {
                                                                verticalCenter: parent.verticalCenter
                                                        }
                                                        x: root.btEnabled ? 22 : 2
                                                        Behavior on x {
                                                                NumberAnimation {
                                                                        duration: 150
                                                                        easing.type: Easing.OutQuad
                                                                }
                                                        }
                                                }
                                                MD3.Pressable {
                                                        anchors.fill: parent
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: {
                                                                if (root.adapter)
                                                                root.adapter.enabled = !root.btEnabled
                                                        }
                                                }
                                        }
                                }
                                Text {
                                        width: parent.width
                                         text: root.connectedDeviceName !== "" ? Translation.trf("bluetooth.connected", root.connectedDeviceName) : (root.connecting ? Translation.tr("bluetooth.connecting") : Translation.tr("bluetooth.no.connections"))
                                        color: root.connectedDeviceName !== "" ? "#89b4fa" : (root.connecting ? "#cdd6f4" : "#45475a")
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
                                RowLayout {
                                        width: parent.width
                                        visible: root.btEnabled
                                        spacing: 6
                                        Text {
                                                 text: root.scanning ? Translation.tr("bluetooth.scanning") : Translation.tr("bluetooth.find.devices")
                                                color: "#cdd6f4"
                                                font {
                                                        family: "Monocraft"
                                                        pixelSize: 12
                                                }
                                        }
                                        Item {
                                                Layout.fillWidth: true
                                        }
                                        Canvas {
                                                id: spinnerCanvas
                                                width: 16
                                                height: 16
                                                visible: root.scanning
                                                property real angle: 0
                                                Timer {
                                                        interval: 16
                                                        repeat: true
                                                        running: root.scanning
                                                        onTriggered: {
                                                                spinnerCanvas.angle = (spinnerCanvas.angle + 6.1) % 360
                                                                spinnerCanvas.requestPaint()
                                                        }
                                                }
                                                onPaint: {
                                                        var ctx = getContext("2d")
                                                        var cx = width / 2
                                                        var cy = height / 2
                                                        var r = 5.5
                                                        ctx.clearRect(0, 0, width, height)
                                                        var start = angle * Math.PI / 180
                                                        var end = start + Math.PI / 2
                                                        ctx.beginPath()
                                                        ctx.arc(cx, cy, r, start, end)
                                                        ctx.strokeStyle = "#89b4fa"
                                                        ctx.lineWidth = 2.5
                                                        ctx.lineCap = "round"
                                                        ctx.stroke()
                                                }
                                        }
                                }
                                Repeater {
                                        model: root.discoveredDevices
                                        delegate: Rectangle {
                                                required property var modelData
                                                property string devName: modelData.name !== "" ? modelData.name : modelData.deviceName
                                                property string devMac: modelData.address
                                                width: popupContent.width
                                                height: 32
                                                radius: 8
                                                color: discMouse.containsMouse ? "#313244" : "#181825"
                                                border {
                                                        color: "#45475a"
                                                        width: 1
                                                }
                                                RowLayout {
                                                        anchors {
                                                                fill: parent
                                                                leftMargin: 8
                                                                rightMargin: 8
                                                        }
                                                        spacing: 6
                                                        Text {
                                                                text: "\uf021"
                                                                color: "#45475a"
                                                                font {
                                                                        family: "Monocraft"
                                                                        pixelSize: 16
                                                                }
                                                        }
                                                        Text {
                                                                text: devName
                                                                color: "#cdd6f4"
                                                                elide: Text.ElideRight
                                                                Layout.fillWidth: true
                                                                font {
                                                                        family: "Monocraft"
                                                                        pixelSize: 12
                                                                }
                                                        }
                                                        Rectangle {
                                                                width: pairLabel.implicitWidth + 12
                                                                height: 20
                                                                radius: 6
                                                                color: pairArea.containsMouse ? "#313244" : "#181825"
                                                                border {
                                                                        color: "#89b4fa"
                                                                        width: 1
                                                                }
                                                                Text {
                                                                        id: pairLabel
                                                                        anchors.centerIn: parent
                                                                         text: modelData.pairing ? Translation.tr("bluetooth.pairing") : Translation.tr("bluetooth.pair")
                                                                        color: "#89b4fa"
                                                                        font {
                                                                                family: "Monocraft"
                                                                                pixelSize: 11
                                                                        }
                                                                }
                                                                MD3.Pressable {
                                                                        id: pairArea
                                                                        anchors.fill: parent
                                                                        hoverEnabled: true
                                                                        cursorShape: Qt.PointingHandCursor
                                                                        onClicked: {
                                                                                pairProcess.command = ["sh", "-c", "bluetoothctl pairable on && bluetoothctl pair " + devMac]
                                                                                pairProcess.startDetached()
                                                                        }
                                                                }
                                                        }
                                                }
                                                MD3.Pressable {
                                                        id: discMouse
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor
                                                        acceptedButtons: Qt.LeftButton
                                                }
                                        }
                                }
                                Repeater {
                                        model: root.pairedDevices
                                        delegate: Rectangle {
                                                required property var modelData
                                                width: popupContent.width
                                                height: 32
                                                radius: 8
                                                color: devMouse.containsMouse ? "#313244" : "#181825"
                                                border {
                                                        color: modelData.connected ? "#89b4fa" : "#45475a"
                                                        width: modelData.connected ? 2 : 1
                                                }
                                                RowLayout {
                                                        anchors {
                                                                fill: parent
                                                                leftMargin: 8
                                                                rightMargin: 8
                                                        }
                                                        spacing: 6
                                                        Text {
                                                                text: "\uf116"
                                                                color: modelData.connected ? "#89b4fa" : "#45475a"
                                                                font {
                                                                        family: "Monocraft"
                                                                        pixelSize: 16
                                                                }
                                                        }
                                                        Text {
                                                                text: modelData.name !== "" ? modelData.name : modelData.deviceName
                                                                color: "#cdd6f4"
                                                                elide: Text.ElideRight
                                                                Layout.fillWidth: true
                                                                font {
                                                                        family: "Monocraft"
                                                                        pixelSize: 12
                                                                }
                                                        }
                                                        Text {
                                                                 text: modelData.connected ? Translation.tr("bluetooth.disconnect") : Translation.tr("bluetooth.connect")
                                                                color: modelData.connected ? "#f38ba8" : "#89b4fa"
                                                                font {
                                                                        family: "Monocraft"
                                                                        pixelSize: 11
                                                                }
                                                        }
                                                }
                                                MD3.Pressable {
                                                        id: devMouse
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor
                                                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                                                        onClicked: function(mouse) {
                                                                if (mouse.button === Qt.RightButton) {
                                                                        openContextMenu(modelData, mouse.x, mouse.y)
                                                                } else {
                                                                        if (modelData.connected) {
                                                                                actionProcess.command = ["sh", "-c", "bluetoothctl disconnect " + modelData.address]
                                                                                actionProcess.startDetached()
                                                                        } else {
                                                                                root.connecting = true
                                                                                actionProcess.command = ["sh", "-c", "bluetoothctl trust " + modelData.address + " && bluetoothctl connect " + modelData.address]
                                                                                actionProcess.startDetached()
                                                                        }
                                                                        refreshTimer.start()
                                                                }
                                                        }
                                                }
                                        }
                                }
                        }
                }
        }
        PopupWindow {
                id: contextPopup
                visible: root.contextMenuReady && root.rootWindow !== null
                grabFocus: true
                color: "transparent"
                anchor {
                        window: root.rootWindow
                        rect.x: {
                                var x = root.x + root.clickPosition.x - contextPopup.implicitWidth / 2
                                if (x + contextPopup.implicitWidth > root.rootWindow.width) x = root.rootWindow.width - contextPopup.implicitWidth - 10
                                if (x < 10) x = 10
                                return x
                        }
                        rect.y: {
                                var y = root.y + root.clickPosition.y + 20
                                if (y + contextPopup.implicitHeight > root.rootWindow.height) {
                                        y = root.rootWindow.height - contextPopup.implicitHeight - 10
                                }
                                if (y < 10) y = 10
                                return y
                        }
                }
                implicitWidth: 180
                implicitHeight: 160
                Rectangle {
                        anchors.fill: parent
                        color: "#1e1e2e"
                        radius: 20
                        clip: true
                        border {
                                color: "#89b4fa"
                                width: 1
                        }
                        opacity: root.contextMenuOpen ? 1 : 0
                        scale: root.contextMenuOpen ? 1 : 0.95
                        transformOrigin: Item.Top
                        Behavior on opacity {
                                NumberAnimation {
                                        duration: 150
                                        easing.type: Easing.OutQuad
                                }
                        }
                        Behavior on scale {
                                NumberAnimation {
                                        duration: 150
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
                                        RowLayout {
                                                anchors.fill: parent
                                                spacing: 8
                                                Text {
                                                                 text: root.contextNetwork ? (root.contextNetwork.name !== "" ? root.contextNetwork.name : root.contextNetwork.deviceName) : Translation.tr("bluetooth.popup.title")
                                                        color: "#cdd6f4"
                                                        font {
                                                                family: "Monocraft"
                                                                pixelSize: 13
                                                                bold: true
                                                        }
                                                        maximumLineCount: 1
                                                        elide: Text.ElideRight
                                                        Layout.fillWidth: true
                                                }
                                                Rectangle {
                                                        id: contextCloseBtn
                                                        width: 24
                                                        height: 24
                                                        radius: 6
                                                        color: "transparent"
                                                        border { color: "#45475a"; width: 1 }
                                                        clip: true
                                                        Rectangle {
                                                                id: contextCloseHoverFill
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
                                                                id: contextCloseArea
                                                                anchors.fill: parent
                                                                hoverEnabled: true
                                                                cursorShape: Qt.PointingHandCursor
                                                                onEntered: {
                                                                        contextCloseHoverFill.width = parent.width
                                                                        contextCloseHoverFill.height = parent.height
                                                                }
                                                                onExited: {
                                                                        contextCloseHoverFill.width = 0
                                                                        contextCloseHoverFill.height = 0
                                                                }
                                                                onClicked: root.contextMenuOpen = false
                                                        }
                                                }
                                        }
                                }
                                Rectangle {
                                        width: parent.width
                                        height: 1
                                        color: "#45475a"
                                }
                                Item {
                                        width: parent.width
                                        height: 92
                                        clip: true
                                        Rectangle {
                                                id: contextCapsule
                                                x: 2
                                                width: parent.width - 4
                                                height: 28
                                                radius: 4
                                                color: "#313244"
                                                opacity: 0
                                                y: root.contextHoveredIndex * 30
                                                Behavior on y {
                                                        NumberAnimation {
                                                                duration: 200
                                                                easing.type: Easing.OutQuad
                                                        }
                                                }
                                                Behavior on opacity {
                                                        NumberAnimation {
                                                                duration: 200
                                                                easing.type: Easing.OutQuad
                                                        }
                                                }
                                        }
                                        Column {
                                                anchors.fill: parent
                                                spacing: 2
                                                Repeater {
                                                        model: [
                                                                 { action: "connect", text: Translation.tr("bluetooth.connect"), enabled: root.contextNetwork && !root.contextNetwork.connected },
                                                                 { action: "disconnect", text: Translation.tr("bluetooth.disconnect"), enabled: root.contextNetwork && root.contextNetwork.connected },
                                                                 { action: "forget", text: Translation.tr("bluetooth.forget"), enabled: root.contextNetwork && (root.contextNetwork.paired || root.contextNetwork.bonded) }
                                                        ]
                                                        delegate: Rectangle {
                                                                width: parent.width
                                                                height: 28
                                                                radius: 4
                                                                color: "transparent"
                                                                opacity: modelData.enabled ? 1 : 0.4
                                                                Text {
                                                                        anchors {
                                                                                left: parent.left
                                                                                leftMargin: 8
                                                                                verticalCenter: parent.verticalCenter
                                                                        }
                                                                        text: modelData.text
                                                                        color: "#cdd6f4"
                                                                        font {
                                                                                family: "Monocraft"
                                                                                pixelSize: 12
                                                                        }
                                                                }
                                                                MD3.Pressable {
                                                                        anchors.fill: parent
                                                                        hoverEnabled: true
                                                                        cursorShape: modelData.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                                                        enabled: modelData.enabled
                                                                        onEntered: {
                                                                                root.contextHoveredIndex = index
                                                                                contextCapsule.opacity = 1
                                                                        }
                                                                        onExited: {
                                                                                root.contextHoveredIndex = -1
                                                                                contextCapsule.opacity = 0
                                                                        }
                                                                        onClicked: {
                                                                                 if (modelData.action === "connect") {
                                                                                         if (root.contextNetwork) {
                                                                                                 root.connecting = true
                                                                                                 actionProcess.command = ["sh", "-c", "bluetoothctl trust " + root.contextNetwork.address + " && bluetoothctl connect " + root.contextNetwork.address]
                                                                                                 actionProcess.startDetached()
                                                                                                 root.refreshTimer.start()
                                                                                                 root.contextMenuOpen = false
                                                                                         }
                                                                                 } else if (modelData.action === "disconnect") {
                                                                                         if (root.contextNetwork) {
                                                                                                 actionProcess.command = ["sh", "-c", "bluetoothctl disconnect " + root.contextNetwork.address]
                                                                                                 actionProcess.startDetached()
                                                                                                 root.refreshTimer.start()
                                                                                                 root.contextMenuOpen = false
                                                                                         }
                                                                                 } else if (modelData.action === "forget") {
                                                                                         if (root.contextNetwork) {
                                                                                                 actionProcess.command = ["sh", "-c", "bluetoothctl remove " + root.contextNetwork.address]
                                                                                                 actionProcess.startDetached()
                                                                                                 root.refreshTimer.start()
                                                                                                 root.contextMenuOpen = false
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
        }
        Timer {
                id: closeTimer
                interval: 200
                running: !root.popupOpen && root.popupReady
                onTriggered: root.popupReady = false
        }
        Timer {
                id: contextCloseTimer
                interval: 200
                running: !root.contextMenuOpen && root.contextMenuReady
                onTriggered: root.contextMenuReady = false
        }
        Timer {
                id: refreshTimer
                interval: 2000
                repeat: false
                onTriggered: refreshDevices()
        }
        Process {
                id: pairProcess
                property string targetMac: ""
                command: ["sh", "-c", ""]
                stdout: SplitParser {
                        splitMarker: "\n"
                        onRead: function(data) { console.log("[bt pair stdout]: " + data) }
                }
                stderr: SplitParser {
                        splitMarker: "\n"
                        onRead: function(data) { console.log("[bt pair stderr]: " + data) }
                }
                onRunningChanged: {
                        if (!running && targetMac !== "") {
                                refreshDevices()
                        }
                }
        }
        Process {
                id: actionProcess
                property string targetMac: ""
                property string actionType: ""
                command: ["sh", "-c", ""]
                stdout: SplitParser {
                        splitMarker: "\n"
                        onRead: function(data) { console.log("[bt action stdout]: " + data) }
                }
                stderr: SplitParser {
                        splitMarker: "\n"
                        onRead: function(data) { console.log("[bt action stderr]: " + data) }
                }
                onRunningChanged: {
                        if (!running) {
                                refreshDevices()
                        }
                }
        }
        Timer {
                id: btIconReset
                interval: 120
                repeat: false
                onTriggered: btIcon.scale = 1
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
