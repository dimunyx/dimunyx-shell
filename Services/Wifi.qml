import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import QtQuick.Layouts
Item {
        id: root
        implicitWidth: wifiRow.implicitWidth
        implicitHeight: 28
        property var rootWindow: null
        property bool popupOpen: false
        property bool popupReady: false
        property bool contextMenuOpen: false
        property bool contextMenuReady: false
        property string wifiDevice: "wlp2s0"
        property string networkName: ""
        property int signalStrength: 0
        property bool connecting: false
        property var contextNetwork: null
        property var clickPosition: Qt.point(0, 0)
        property int contextHoveredIndex: -1
        readonly property var wifiDev: {
                if (!Networking.devices) return null
                for (var i = 0; i < Networking.devices.values.length; i++) {
                        var dev = Networking.devices.values[i]
                        if (dev && dev.type === 1)
                        return dev
                }
                return null
        }
        readonly property var connectedNetwork: {
                if (!wifiDev || !wifiDev.networks) return null
                var nets = wifiDev.networks.values
                for (var i = 0; i < nets.length; i++) {
                        if (nets[i] && nets[i].connected)
                        return nets[i]
                }
                return null
        }
        property var availableNetworks: []
        property bool scanning: false
        property int _refresh: 0
        property var selectedNetwork: null
        property string passwordInput: ""
        property bool pctVisible: false
        function refreshNetworks() {
                if (!wifiDev || !wifiDev.networks) {
                        availableNetworks = []
                        return
                }
                var nets = wifiDev.networks.values
                var result = []
                for (var i = 0; i < nets.length; i++) {
                        if (nets[i] && nets[i].name !== "")
                        result.push(nets[i])
                }
                availableNetworks = result
                if (root.connectedNetwork) {
                        root.networkName = root.connectedNetwork.name
                        root.signalStrength = Math.round(root.connectedNetwork.signalStrength * 100)
                        root.connecting = false
                } else {
                        root.networkName = ""
                        root.signalStrength = 0
                }
        }
        function signalIcon(strength) {
                if (strength >= 75) return "󰤨"
                if (strength >= 50) return "󰤥"
                if (strength >= 25) return "󰤢"
                return "󰤟"
        }
        function securityText(sec) {
                if (sec === 0) return ""
                if (sec === 1) return "WEP"
                if (sec === 2) return "WPA"
                if (sec === 3) return "WPA2"
                if (sec === 4) return "WPA3"
                return ""
        }
        function connectNetwork(net) {
                if (net.connected) {
                        net.disconnect()
                } else if (net.known) {
                        root.connecting = true
                        net.connect()
                } else if (net.security !== 0) {
                        root.selectedNetwork = net
                        root.passwordInput = ""
                } else {
                        root.connecting = true
                        net.connect()
                }
                root.refreshTimer.start()
        }
        function forgetNetwork(net) {
                if (net && net.known) {
                        net.disconnect()
                        net.forget()
                        root.refreshTimer.start()
                }
        }
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
                        refreshNetworks()
                }
        }
        RowLayout {
                id: wifiRow
                anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                }
                spacing: 0
                Text {
                        id: wifiIcon
                        text: root.networkName === "" ? "󰤭" : root.signalStrength >= 75 ? "󰤨" : root.signalStrength >= 50 ? "󰤥" : root.signalStrength >= 25 ? "󰤢" : "󰤟"
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
                        id: wifiPctWrap
                        Layout.preferredWidth: root.pctVisible ? wifiPct.implicitWidth : 0
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
                                id: wifiPct
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.networkName
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
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onEntered: {
                        root.pctVisible = true
                        pctHideTimer.stop()
                }
                onExited: {
                        pctHideTimer.restart()
                }
                onClicked: function(mouse) {
                        wifiIcon.scale = 1.25
                        wifiIconReset.start()
                        if (mouse.button === Qt.RightButton) {
                                if (root.connectedNetwork) {
                                        openContextMenu(root.connectedNetwork, mouse.x, mouse.y)
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
                implicitWidth: 260
                implicitHeight: popupContent.implicitHeight + 24
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
                                                        text: Translation.tr("wifi.popup.title")
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
                                                                ctx.strokeStyle = "#B58FFF"
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
                                                        border { color: "#4c3a70"; width: 1 }
                                                        clip: true
                                                        visible: !root.connecting && !root.scanning
                                                        Rectangle {
                                                                id: refreshHoverFill
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
                                                                text: "\uf021"
                                                                color: refreshArea.containsMouse ? "#B58FFF" : "#4c3a70"
                                                                font {
                                                                        family: "Monocraft"
                                                                        pixelSize: 14
                                                                }
                                                        }
                                                        MouseArea {
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
                                                                        if (root.wifiDev) {
                                                                                root.scanning = true
                                                                                root.wifiDev.scannerEnabled = true
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
                                                        border { color: "#4c3a70"; width: 1 }
                                                        clip: true
                                                        visible: root.scanning && !root.connecting
                                                        Rectangle {
                                                                id: scanHoverFill
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
                                                                text: root.scanning ? "\uf00d" : "\uf021"
                                                                color: scanArea.containsMouse ? "#B58FFF" : "#4c3a70"
                                                                font {
                                                                        family: "Monocraft"
                                                                        pixelSize: 14
                                                                }
                                                        }
                                                        MouseArea {
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
                                                                        if (root.wifiDev) {
                                                                                root.scanning = false
                                                                                root.wifiDev.scannerEnabled = false
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
                                RowLayout {
                                        width: parent.width
                                        spacing: 8
                                                Text {
                                                        text: Networking.wifiEnabled ? Translation.tr("wifi.enabled") : Translation.tr("wifi.disabled")
                                                color: "#E8DBFF"
                                                font {
                                                        family: "Monocraft"
                                                        pixelSize: 12
                                                }
                                        }
                                        Item {
                                                Layout.fillWidth: true
                                        }
                                        Rectangle {
                                                id: toggleSwitch
                                                width: 40
                                                height: 22
                                                radius: 11
                                                color: Networking.wifiEnabled ? "#B58FFF" : "#1a1225"
                                                border {
                                                        color: "#4c3a70"
                                                        width: 1
                                                }
                                                Behavior on color {
                                                        ColorAnimation {
                                                                duration: 200
                                                                easing.type: Easing.OutQuad
                                                        }
                                                }
                                                Rectangle {
                                                        id: toggleKnob
                                                        width: 16
                                                        height: 16
                                                        radius: 8
                                                        color: "#E8DBFF"
                                                        anchors {
                                                                verticalCenter: parent.verticalCenter
                                                        }
                                                        x: Networking.wifiEnabled ? 22 : 2
                                                        Behavior on x {
                                                                NumberAnimation {
                                                                        duration: 200
                                                                        easing.type: Easing.OutQuad
                                                                }
                                                        }
                                                }
                                                MouseArea {
                                                        anchors.fill: parent
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: {
                                                                Networking.wifiEnabled = !Networking.wifiEnabled
                                                        }
                                                }
                                        }
                                }
                                Text {
                                        width: parent.width
                                         text: root.connectedNetwork ? Translation.trf("wifi.connected", root.networkName) : (root.connecting ? Translation.tr("wifi.connecting") : Translation.tr("wifi.no.connections"))
                                        color: root.connectedNetwork ? "#B58FFF" : (root.connecting ? "#E8DBFF" : "#4c3a70")
                                        font {
                                                family: "Monocraft"
                                                pixelSize: 12
                                        }
                                }
                                Rectangle {
                                        width: parent.width
                                        height: 1
                                        color: "#4c3a70"
                                }
                                RowLayout {
                                        width: parent.width
                                        visible: Networking.wifiEnabled && root.selectedNetwork === null
                                        spacing: 6
                                        Text {
                                                 text: root.scanning ? Translation.tr("wifi.scanning") : Translation.tr("wifi.find.network")
                                                color: "#E8DBFF"
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
                                                        ctx.strokeStyle = "#B58FFF"
                                                        ctx.lineWidth = 2.5
                                                        ctx.lineCap = "round"
                                                        ctx.stroke()
                                                }
                                        }
                                }
                                Column {
                                        width: parent.width
                                        visible: root.selectedNetwork !== null
                                        spacing: 6
                                        Text {
                                                 text: root.selectedNetwork ? Translation.trf("wifi.password.for", root.selectedNetwork.name) : ""
                                                color: "#E8DBFF"
                                                font {
                                                        family: "Monocraft"
                                                        pixelSize: 12
                                                }
                                        }
                                        Rectangle {
                                                width: parent.width
                                                height: 28
                                                radius: 6
                                                color: "#110d1a"
                                                border {
                                                        color: pwInput.activeFocus ? "#B58FFF" : "#4c3a70"
                                                        width: 1
                                                }
                                                TextInput {
                                                        id: pwInput
                                                        anchors.fill: parent
                                                        anchors.margins: 6
                                                        color: "#E8DBFF"
                                                        echoMode: TextInput.Password
                                                        font {
                                                                family: "Monocraft"
                                                                pixelSize: 12
                                                        }
                                                        clip: true
                                                        selectByMouse: true
                                                        selectionColor: "#B58FFF"
                                                        Keys.onReturnPressed: connectArea.clicked(Qt.LeftButton)
                                                        KeyNavigation.tab: connectBtn
                                                }
                                        }
                                        RowLayout {
                                                width: parent.width
                                                spacing: 6
                                                Item { Layout.fillWidth: true }
                                                Rectangle {
                                                        width: cancelLabel.implicitWidth + 12
                                                        height: 22
                                                        radius: 6
                                                        color: cancelArea.containsMouse ? "#1a1225" : "#110d1a"
                                                        border {
                                                                color: "#4c3a70"
                                                                width: 1
                                                        }
                                                                Text {
                                                                        id: cancelLabel
                                                                        anchors.centerIn: parent
                                                                         text: Translation.tr("wifi.cancel")
                                                                        color: "#E8DBFF"
                                                                font {
                                                                        family: "Monocraft"
                                                                        pixelSize: 11
                                                                }
                                                        }
                                                        MouseArea {
                                                                id: cancelArea
                                                                anchors.fill: parent
                                                                hoverEnabled: true
                                                                cursorShape: Qt.PointingHandCursor
                                                                onClicked: {
                                                                        root.selectedNetwork = null
                                                                        root.passwordInput = ""
                                                                }
                                                        }
                                                }
                                                Rectangle {
                                                        id: connectBtn
                                                        width: connectLabel.implicitWidth + 12
                                                        height: 22
                                                        radius: 6
                                                        color: connectArea.containsMouse ? "#1a1225" : "#110d1a"
                                                        border {
                                                                color: "#B58FFF"
                                                                width: 1
                                                        }
                                                        signal clicked()
                                                                Text {
                                                                        id: connectLabel
                                                                        anchors.centerIn: parent
                                                                         text: Translation.tr("wifi.btn.connect")
                                                                        color: "#B58FFF"
                                                                font {
                                                                        family: "Monocraft"
                                                                        pixelSize: 11
                                                                }
                                                        }
                                                        MouseArea {
                                                                id: connectArea
                                                                anchors.fill: parent
                                                                hoverEnabled: true
                                                                cursorShape: Qt.PointingHandCursor
                                                                onClicked: {
                                                                        if (root.selectedNetwork) {
                                                                                root.connecting = true
                                                                                root.selectedNetwork.connectWithPsk(pwInput.text)
                                                                                root.selectedNetwork = null
                                                                                root.passwordInput = ""
                                                                                root.refreshTimer.start()
                                                                        }
                                                                }
                                                        }
                                                }
                                        }
                                }
                                Repeater {
                                        visible: root.selectedNetwork === null
                                        model: root.availableNetworks
                                        delegate: Rectangle {
                                                required property var modelData
                                                width: popupContent.width
                                                height: 32
                                                radius: 8
                                                color: netMouse.containsMouse ? "#1a1225" : "#110d1a"
                                                border {
                                                        color: modelData.connected ? "#B58FFF" : "#4c3a70"
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
                                                                text: signalIcon(Math.round(modelData.signalStrength * 100))
                                                                color: modelData.connected ? "#B58FFF" : "#4c3a70"
                                                                font {
                                                                        family: "Monocraft"
                                                                        pixelSize: 16
                                                                }
                                                        }
                                                        Text {
                                                                text: modelData.name
                                                                color: "#E8DBFF"
                                                                elide: Text.ElideRight
                                                                Layout.fillWidth: true
                                                                font {
                                                                        family: "Monocraft"
                                                                        pixelSize: 12
                                                                }
                                                        }
                                                        Text {
                                                                text: securityText(modelData.security)
                                                                color: "#4c3a70"
                                                                visible: modelData.security !== 0
                                                                font {
                                                                        family: "Monocraft"
                                                                        pixelSize: 10
                                                                }
                                                        }
                                                        Text {
                                                                 text: modelData.connected ? Translation.tr("wifi.disconnect") : Translation.tr("wifi.connect")
                                                                color: modelData.connected ? "#ff6b6b" : "#B58FFF"
                                                                font {
                                                                        family: "Monocraft"
                                                                        pixelSize: 11
                                                                }
                                                        }
                                                }
                                                MouseArea {
                                                        id: netMouse
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor
                                                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                                                        onClicked: function(mouse) {
                                                                if (mouse.button === Qt.RightButton) {
                                                                        openContextMenu(modelData, mouse.x, mouse.y)
                                                                } else {
                                                                        root.connectNetwork(modelData)
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
                        color: "#000000"
                        radius: 20
                        clip: true
                        border {
                                color: "#B58FFF"
                                width: 4
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
                        MouseArea {
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
                                                                 text: root.contextNetwork ? root.contextNetwork.name : Translation.tr("wifi.popup.title")
                                                                color: "#E8DBFF"
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
                                                        border { color: "#4c3a70"; width: 1 }
                                                        clip: true
                                                        Rectangle {
                                                                id: contextCloseHoverFill
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
                                        color: "#3a3255"
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
                                                color: "#1a1225"
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
                                                                 { action: "connect", text: Translation.tr("wifi.connect"), enabled: root.contextNetwork && !root.contextNetwork.connected },
                                                                 { action: "disconnect", text: Translation.tr("wifi.disconnect"), enabled: root.contextNetwork && root.contextNetwork.connected },
                                                                 { action: "forget", text: Translation.tr("wifi.forget"), enabled: root.contextNetwork && root.contextNetwork.known }
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
                                                                        color: "#E8DBFF"
                                                                        font {
                                                                                family: "Monocraft"
                                                                                pixelSize: 12
                                                                        }
                                                                }
                                                                MouseArea {
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
                                                                                                 connectNetwork(root.contextNetwork)
                                                                                                 root.contextMenuOpen = false
                                                                                         }
                                                                                 } else if (modelData.action === "disconnect") {
                                                                                         if (root.contextNetwork) {
                                                                                                 root.contextNetwork.disconnect()
                                                                                                 root.refreshTimer.start()
                                                                                                 root.contextMenuOpen = false
                                                                                         }
                                                                                 } else if (modelData.action === "forget") {
                                                                                         if (root.contextNetwork) {
                                                                                                 forgetNetwork(root.contextNetwork)
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
                id: wifiIconReset
                interval: 120
                repeat: false
                onTriggered: wifiIcon.scale = 1
        }
        Timer {
                id: pctHideTimer
                interval: 1200
                repeat: false
                onTriggered: {
                        root.pctVisible = false
                }
        }
        Timer {
                id: refreshTimer
                interval: 2000
                repeat: false
                onTriggered: refreshNetworks()
        }
        Timer {
                id: contextCloseTimer
                interval: 200
                running: !root.contextMenuOpen && root.contextMenuReady
                onTriggered: root.contextMenuReady = false
        }
}
