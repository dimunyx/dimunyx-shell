import QtQuick 6.0
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
PanelWindow {
        id: lockScreen
        visible: false
        anchors {
                top: true
                left: true
                bottom: true
                right: true
        }
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "lockscreen"
        WlrLayershell.exclusiveZone: -1
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        property string errorMessage: ""
        property string errorType: ""
        property int attempts: 0
        property int maxAttempts: 3
        property bool isLocked: false
        property int lockRemaining: 0
        property string displayText: ""
        Component.onCompleted: {
                console.log("🔒 LockScreen activated!")
                lockScreen.forceActiveFocus()
                passwordInput.forceActiveFocus()
        }
        Keys.onPressed: {
                if (!isLocked && passwordInput) {
                        if (event.text && event.text.length > 0) {
                                passwordInput.text += event.text
                                passwordInput.forceActiveFocus()
                                updateDisplay()
                        }
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                checkPassword()
                        }
                        if (event.key === Qt.Key_Backspace) {
                                if (passwordInput.text.length > 0) {
                                        passwordInput.text = passwordInput.text.slice(0, -1)
                                        updateDisplay()
                                }
                        }
                        if (event.key === Qt.Key_Escape && !isLocked) {
                                Qt.quit()
                        }
                }
                if (event.key === Qt.Key_Escape) {
                        Qt.quit()
                }
        }
        function updateDisplay() {
                if (passwordInput.text === "") {
                        displayText = Translation.tr("lockscreen.placeholder")
                        return
                }
                var stars = ""
                for (var i = 0; i < passwordInput.text.length; i++) {
                        stars += "●"
                }
                displayText = stars
        }
        MouseArea {
                anchors.fill: parent
                hoverEnabled: false
                cursorShape: Qt.ArrowCursor
                acceptedButtons: Qt.AllButtons
                onPressed: function(mouse) { mouse.accepted = true }
                onReleased: function(mouse) { mouse.accepted = true }
                onClicked: function(mouse) { mouse.accepted = true }
                onDoubleClicked: function(mouse) { mouse.accepted = true }
                onWheel: function(wheel) { wheel.accepted = true }
        }
        Rectangle {
                anchors.fill: parent
                color: "#000000"
                opacity: 0.3
        }
        Column {
                anchors {
                        top: parent.top
                        horizontalCenter: parent.horizontalCenter
                        topMargin: parent.height * 0.08
                }
                spacing: 5
                Text {
                        id: timeText
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.pixelSize: 96
                        font.weight: Font.Light
                        color: "white"
                        font.family: "Monocraft"
                        text: {
                                var now = new Date()
                                var hours = String(now.getHours()).padStart(2, '0')
                                var minutes = String(now.getMinutes()).padStart(2, '0')
                                return hours + ":" + minutes
                        }
                }
                Text {
                        id: dateText
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.pixelSize: 24
                        color: "#aaaaaa"
                        font.family: "Monocraft"
                        text: {
                                var now = new Date()
                                var day = String(now.getDate()).padStart(2, '0')
                                var month = String(now.getMonth() + 1).padStart(2, '0')
                                var year = now.getFullYear()
                                return day + "." + month + "." + year
                        }
                }
                Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: isLocked ? "⏳" : ""
                        font {
                                family: "Nerd Fonts"
                                pixelSize: 48
                        }
                        color: isLocked ? "#ff6b6b" : "#B58FFF"
                }
                Rectangle {
                        id: inputContainer
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 226
                        height: 70
                        color: "#1a1a2a"
                        radius: 16
                        border {
                                 color: isLocked ? "#ff6b6b" : (errorType === "incorrect" ? "#ff6b6b" : "#4c3a70")
                                width: 2
                        }
                        MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                        if (!isLocked) {
                                                passwordInput.forceActiveFocus()
                                        }
                                }
                        }
                        Text {
                                id: inputText
                                anchors.fill: parent
                                anchors.leftMargin: 15
                                verticalAlignment: Text.AlignVCenter
                                color: isLocked ? "#ff6b6b" : "white"
                                font {
                                        family: "Monocraft"
                                        pixelSize: 22
                                }
                                text: {
                                        if (isLocked) {
                                                var mins = Math.floor(lockRemaining / 60)
                                                var secs = lockRemaining % 60
                                                return "⏳ " + mins + ":" + String(secs).padStart(2, '0')
                                        }
                                        return displayText
                                }
                        }
                }
                Text {
                        id: errorText
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: inputContainer.bottom
                        anchors.topMargin: 8
                        text: errorMessage
                         color: isLocked ? "#ff6b6b" : (errorType === "unlocked" ? "#4CAF50" : "#ff6b6b")
                        font {
                                family: "Monocraft"
                                pixelSize: 14
                        }
                        opacity: (errorMessage === "" && !isLocked) ? 0 : 1
                        Behavior on opacity {
                                NumberAnimation { duration: 200 }
                        }
                }
        }
        Item {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: parent.height * 0.1
                Column {
                        anchors.centerIn: parent
                        spacing: 8
                        enabled: !isLocked
                        Row {
                                spacing: 8
                                Repeater {
                                        model: ["1", "2", "3"]
                                        Rectangle {
                                                width: 70
                                                height: 70
                                                radius: 16
                                                color: "#2a2a4a"
                                                property bool hovered: false
                                                property bool pressed: false
                                                opacity: isLocked ? 0.3 : 1
                                                border {
                                                        color: hovered ? "#B58FFF" : "#4c3a70"
                                                        width: hovered ? 2 : 1
                                                }
                                                scale: pressed ? 0.92 : 1
                                                Behavior on scale {
                                                        NumberAnimation { duration: 100; easing.type: Easing.OutQuad }
                                                }
                                                Behavior on border.color {
                                                        ColorAnimation { duration: 150 }
                                                }
                                                Text {
                                                        anchors.centerIn: parent
                                                        text: modelData
                                                        color: parent.hovered ? "#B58FFF" : "#E8DBFF"
                                                        font {
                                                                family: "Monocraft"
                                                                pixelSize: 26
                                                        }
                                                }
                                                MouseArea {
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: isLocked ? Qt.ArrowCursor : Qt.PointingHandCursor
                                                        enabled: !isLocked
                                                        onPressed: parent.pressed = true
                                                        onReleased: parent.pressed = false
                                                        onEntered: parent.hovered = true
                                                        onExited: parent.hovered = false
                                                        onClicked: {
                                                                passwordInput.text += modelData
                                                                passwordInput.forceActiveFocus()
                                                                updateDisplay()
                                                                if (errorMessage !== "") {
                                                                        errorMessage = ""
                                                                        errorType = ""
                                                                        inputContainer.border.color = "#4c3a70"
                                                                }
                                                        }
                                                }
                                        }
                                }
                        }
                        Row {
                                spacing: 8
                                Repeater {
                                        model: ["4", "5", "6"]
                                        Rectangle {
                                                width: 70
                                                height: 70
                                                radius: 16
                                                color: "#2a2a4a"
                                                property bool hovered: false
                                                property bool pressed: false
                                                opacity: isLocked ? 0.3 : 1
                                                border {
                                                        color: hovered ? "#B58FFF" : "#4c3a70"
                                                        width: hovered ? 2 : 1
                                                }
                                                scale: pressed ? 0.92 : 1
                                                Behavior on scale {
                                                        NumberAnimation { duration: 100; easing.type: Easing.OutQuad }
                                                }
                                                Behavior on border.color {
                                                        ColorAnimation { duration: 150 }
                                                }
                                                Text {
                                                        anchors.centerIn: parent
                                                        text: modelData
                                                        color: parent.hovered ? "#B58FFF" : "#E8DBFF"
                                                        font {
                                                                family: "Monocraft"
                                                                pixelSize: 26
                                                        }
                                                }
                                                MouseArea {
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: isLocked ? Qt.ArrowCursor : Qt.PointingHandCursor
                                                        enabled: !isLocked
                                                        onPressed: parent.pressed = true
                                                        onReleased: parent.pressed = false
                                                        onEntered: parent.hovered = true
                                                        onExited: parent.hovered = false
                                                        onClicked: {
                                                                passwordInput.text += modelData
                                                                passwordInput.forceActiveFocus()
                                                                updateDisplay()
                                                                if (errorMessage !== "") {
                                                                        errorMessage = ""
                                                                        errorType = ""
                                                                        inputContainer.border.color = "#4c3a70"
                                                                }
                                                        }
                                                }
                                        }
                                }
                        }
                        Row {
                                spacing: 8
                                Repeater {
                                        model: ["7", "8", "9"]
                                        Rectangle {
                                                width: 70
                                                height: 70
                                                radius: 16
                                                color: "#2a2a4a"
                                                property bool hovered: false
                                                property bool pressed: false
                                                opacity: isLocked ? 0.3 : 1
                                                border {
                                                        color: hovered ? "#B58FFF" : "#4c3a70"
                                                        width: hovered ? 2 : 1
                                                }
                                                scale: pressed ? 0.92 : 1
                                                Behavior on scale {
                                                        NumberAnimation { duration: 100; easing.type: Easing.OutQuad }
                                                }
                                                Behavior on border.color {
                                                        ColorAnimation { duration: 150 }
                                                }
                                                Text {
                                                        anchors.centerIn: parent
                                                        text: modelData
                                                        color: parent.hovered ? "#B58FFF" : "#E8DBFF"
                                                        font {
                                                                family: "Monocraft"
                                                                pixelSize: 26
                                                        }
                                                }
                                                MouseArea {
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: isLocked ? Qt.ArrowCursor : Qt.PointingHandCursor
                                                        enabled: !isLocked
                                                        onPressed: parent.pressed = true
                                                        onReleased: parent.pressed = false
                                                        onEntered: parent.hovered = true
                                                        onExited: parent.hovered = false
                                                        onClicked: {
                                                                passwordInput.text += modelData
                                                                passwordInput.forceActiveFocus()
                                                                updateDisplay()
                                                                if (errorMessage !== "") {
                                                                        errorMessage = ""
                                                                        errorType = ""
                                                                        inputContainer.border.color = "#4c3a70"
                                                                }
                                                        }
                                                }
                                        }
                                }
                        }
                        Row {
                                spacing: 8
                                Rectangle {
                                        width: 70
                                        height: 70
                                        radius: 16
                                        color: "#2a2a4a"
                                        property bool hovered: false
                                        property bool pressed: false
                                        opacity: isLocked ? 0.3 : 1
                                        border {
                                                color: hovered ? "#ff6b6b" : "#4c3a70"
                                                width: hovered ? 2 : 1
                                        }
                                        scale: pressed ? 0.92 : 1
                                        Behavior on scale {
                                                NumberAnimation { duration: 100; easing.type: Easing.OutQuad }
                                        }
                                        Behavior on border.color {
                                                ColorAnimation { duration: 150 }
                                        }
                                        Text {
                                                anchors.centerIn: parent
                                                text: "⌫"
                                                color: parent.hovered ? "#ff6b6b" : "#E8DBFF"
                                                font {
                                                        family: "Monocraft"
                                                        pixelSize: 24
                                                }
                                        }
                                        MouseArea {
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: isLocked ? Qt.ArrowCursor : Qt.PointingHandCursor
                                                enabled: !isLocked
                                                onPressed: parent.pressed = true
                                                onReleased: parent.pressed = false
                                                onEntered: parent.hovered = true
                                                onExited: parent.hovered = false
                                                onClicked: {
                                                        if (passwordInput.text.length > 0) {
                                                                passwordInput.text = passwordInput.text.slice(0, -1)
                                                                passwordInput.forceActiveFocus()
                                                                updateDisplay()
                                                        }
                                                }
                                        }
                                }
                                Rectangle {
                                        width: 70
                                        height: 70
                                        radius: 16
                                        color: "#2a2a4a"
                                        property bool hovered: false
                                        property bool pressed: false
                                        opacity: isLocked ? 0.3 : 1
                                        border {
                                                color: hovered ? "#B58FFF" : "#4c3a70"
                                                width: hovered ? 2 : 1
                                        }
                                        scale: pressed ? 0.92 : 1
                                        Behavior on scale {
                                                NumberAnimation { duration: 100; easing.type: Easing.OutQuad }
                                        }
                                        Behavior on border.color {
                                                ColorAnimation { duration: 150 }
                                        }
                                        Text {
                                                anchors.centerIn: parent
                                                text: "0"
                                                color: parent.hovered ? "#B58FFF" : "#E8DBFF"
                                                font {
                                                        family: "Monocraft"
                                                        pixelSize: 26
                                                }
                                        }
                                        MouseArea {
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: isLocked ? Qt.ArrowCursor : Qt.PointingHandCursor
                                                enabled: !isLocked
                                                onPressed: parent.pressed = true
                                                onReleased: parent.pressed = false
                                                onEntered: parent.hovered = true
                                                onExited: parent.hovered = false
                                                onClicked: {
                                                        passwordInput.text += "0"
                                                        passwordInput.forceActiveFocus()
                                                        updateDisplay()
                                                        if (errorMessage !== "") {
                                                                errorMessage = ""
                                                                inputContainer.border.color = "#4c3a70"
                                                        }
                                                }
                                        }
                                }
                                Rectangle {
                                        width: 70
                                        height: 70
                                        radius: 16
                                        color: "#2a2a4a"
                                        property bool hovered: false
                                        property bool pressed: false
                                        opacity: isLocked ? 0.3 : 1
                                        border {
                                                color: hovered ? "#4CAF50" : "#4c3a70"
                                                width: hovered ? 2 : 1
                                        }
                                        scale: pressed ? 0.92 : 1
                                        Behavior on scale {
                                                NumberAnimation { duration: 100; easing.type: Easing.OutQuad }
                                        }
                                        Behavior on border.color {
                                                ColorAnimation { duration: 150 }
                                        }
                                        Text {
                                                anchors.centerIn: parent
                                                text: "✓"
                                                color: parent.hovered ? "#4CAF50" : "#E8DBFF"
                                                font {
                                                        family: "Monocraft"
                                                        pixelSize: 26
                                                }
                                        }
                                        MouseArea {
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: isLocked ? Qt.ArrowCursor : Qt.PointingHandCursor
                                                enabled: !isLocked
                                                onPressed: parent.pressed = true
                                                onReleased: parent.pressed = false
                                                onEntered: parent.hovered = true
                                                onExited: parent.hovered = false
                                                onClicked: {
                                                        passwordInput.forceActiveFocus()
                                                        checkPassword()
                                                }
                                        }
                                }
                        }
                }
        }
        TextInput {
                id: passwordInput
                visible: false
                focus: true
                enabled: !isLocked
                onTextChanged: updateDisplay()
        }
        function checkPassword() {
                if (isLocked) return
                if (passwordInput.text === "") {
                        errorMessage = Translation.tr("lockscreen.enterPassword")
                        errorType = "incorrect"
                        passwordInput.forceActiveFocus()
                        return
                }
                if (passwordInput.text === programs.dimunyx-qs.password) {
                        errorMessage = Translation.tr("lockscreen.unlocked")
                        errorType = "unlocked"
                        attempts = 0
                        closeTimer.start()
                } else {
                        attempts++
                        var remaining = maxAttempts - attempts
                        errorMessage = Translation.trf("lockscreen.attemptsRemaining", remaining)
                        errorType = "incorrect"
                        inputContainer.border.color = "#ff6b6b"
                        passwordInput.text = ""
                        updateDisplay()
                        passwordInput.forceActiveFocus()
                        if (attempts >= maxAttempts) {
                                isLocked = true
                                lockRemaining = 300
                                 errorMessage = Translation.tr("lockscreen.tooManyAttempts")
                                errorType = "locked"
                                passwordInput.enabled = false
                                lockTimer.start()
                        }
                }
        }
        Timer {
                id: lockTimer
                interval: 1000
                running: false
                repeat: true
                onTriggered: {
                        lockRemaining--
                        if (lockRemaining <= 0) {
                                isLocked = false
                                lockTimer.stop()
                                attempts = 0
                                errorMessage = ""
                                errorType = ""
                                passwordInput.enabled = true
                                passwordInput.text = ""
                                updateDisplay()
                                inputContainer.border.color = "#4c3a70"
                                passwordInput.forceActiveFocus()
                                 console.log("🔓 Lock removed!")
                        }
                }
        }
        Timer {
                id: closeTimer
                interval: 500
                running: false
                repeat: false
                onTriggered: {
                        lockScreen.visible = false
                        passwordInput.text = ""
                        errorMessage = ""
                        errorType = ""
                        attempts = 0
                        isLocked = false
                        passwordInput.enabled = true
                        inputContainer.border.color = "#4c3a70"
                        if (lockTimer.running) lockTimer.stop()
                }
        }
        Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: {
                        var now = new Date()
                        var hours = String(now.getHours()).padStart(2, '0')
                        var minutes = String(now.getMinutes()).padStart(2, '0')
                        timeText.text = hours + ":" + minutes
                        var day = String(now.getDate()).padStart(2, '0')
                        var month = String(now.getMonth() + 1).padStart(2, '0')
                        var year = now.getFullYear()
                        dateText.text = day + "." + month + "." + year
                }
        }
}
