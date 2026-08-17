import Quickshell
import QtQuick
import "../Components" as MD3
import QtQuick.Layouts
import "../Services"
Item {
        id: root
        implicitWidth: clockText.implicitWidth + 10
        implicitHeight: 32
        property var rootWindow: null
        property bool popupOpen: false
        property bool popupReady: false
        property date now: new Date()
        property int viewMonth: 0
        property int viewYear: 0
        property real calOpacity: 1
        // WEATHER_BLOCK
        property string apiKey: "@WEATHER_API_KEY@"
        property string city: "@WEATHER_CITY@"
        property string units: "metric"
        property real temperature: 0
        property string weatherDescription: ""
        property string weatherIcon: ""
        property bool weatherLoaded: false
        // /WEATHER_BLOCK
        function pad(n) {
                return n < 10 ? "0" + n : "" + n
        }
        function timeText() {
                return Qt.formatDateTime(root.now, "HH:mm")
        }
        function monthName(m) {
                var keys = ["clock.month.0", "clock.month.1", "clock.month.2", "clock.month.3", "clock.month.4", "clock.month.5", "clock.month.6", "clock.month.7", "clock.month.8", "clock.month.9", "clock.month.10", "clock.month.11"]
                return Translation.tr(keys[m])
        }
        function dateText() {
                return monthName(root.now.getMonth()) + " " + root.now.getDate() + ", " + root.now.getFullYear()
        }
        function changeMonth(delta) {
                calOpacity = 0
                fadeTimer.start()
                root.viewMonth += delta
                if (root.viewMonth < 0) {
                        root.viewMonth = 11
                        root.viewYear--
                } else if (root.viewMonth > 11) {
                        root.viewMonth = 0
                        root.viewYear++
                }
        }
        // WEATHER_BLOCK
        function updateWeather() {
                var xhr = new XMLHttpRequest();
                var url = "https://api.openweathermap.org/data/2.5/weather?q=" + city +
                          "&appid=" + apiKey +
                          "&units=" + units +
                          "&lang=en"
                xhr.open("GET", url, true);
                xhr.onreadystatechange = function() {
                        if (xhr.readyState === XMLHttpRequest.DONE) {
                                if (xhr.status === 200) {
                                        try {
                                                var response = JSON.parse(xhr.responseText);
                                                temperature = response.main.temp;
                                                weatherDescription = response.weather[0].description;
                                                weatherIcon = response.weather[0].icon;
                                                weatherLoaded = true;
                                                console.log("Weather loaded:", temperature, weatherDescription);
                                        } catch (e) {
                                                console.error("Weather parse error:", e);
                                        }
                                } else {
                                        console.error("Weather API error:", xhr.status);
                                }
                        }
                };
                xhr.send();
        }
        // /WEATHER_BLOCK
        // WEATHER_BLOCK
        function getWeatherIcon(iconCode) {
                var iconMap = {
                        "01d": "",
                        "01n": "",
                        "02d": "",
                        "02n": "",
                        "03d": "",
                        "03n": "",
                        "04d": "",
                        "04n": "",
                        "09d": "",
                        "09n": "",
                        "10d": "",
                        "10n": "",
                        "11d": "",
                        "11n": "",
                        "13d": "",
                        "13n": "",
                        "50d": "",
                        "50n": ""
                };
                return iconMap[iconCode] || "";
        }
        // /WEATHER_BLOCK
        Timer {
                id: fadeTimer
                interval: 150
                repeat: false
                onTriggered: calOpacity = 1
        }
        Timer {
                interval: 1000
                repeat: true
                running: true
                onTriggered: {
                        root.now = new Date()
                }
        }
        // WEATHER_BLOCK
        Timer {
                interval: 1800000
                repeat: true
                running: true
                onTriggered: updateWeather()
        }
        // /WEATHER_BLOCK
        Component.onCompleted: {
                root.now = new Date()
                root.viewMonth = root.now.getMonth()
                root.viewYear = root.now.getFullYear()
                calOpacity = 1
                // WEATHER_BLOCK
                updateWeather()
                // /WEATHER_BLOCK
        }
        Text {
                id: clockText
                text: timeText()
                color: "#cdd6f4"
                anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                        leftMargin: 2
                }
                font {
                        family: "Monocraft"
                        pixelSize: 14
                }
        }
        MD3.Pressable {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: function(mouse) {
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
                implicitWidth: 240
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
                        Column {
                                id: popupContent
                                anchors {
                                        left: parent.left
                                        right: parent.right
                                        top: parent.top
                                        topMargin: 12
                                        bottomMargin: 12
                                        leftMargin: 12
                                        rightMargin: 12
                                }
                                spacing: 8
                                Item {
                                        width: parent.width
                                        height: 24
                                        RowLayout {
                                                anchors.fill: parent
                                                spacing: 6
                                                Text {
                                                        text: Translation.tr("clock.popup.title")
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
                                                        id: prevBtn
                                                        width: 20
                                                        height: 20
                                                        opacity: prevArea.containsMouse ? 1 : 0.6
                                                        Behavior on opacity {
                                                                NumberAnimation {
                                                                        duration: 150
                                                                        easing.type: Easing.OutQuad
                                                                }
                                                        }
                                                        onPaint: {
                                                                var ctx = getContext("2d")
                                                                ctx.clearRect(0, 0, width, height)
                                                                ctx.strokeStyle = "#89b4fa"
                                                                ctx.lineWidth = 2.5
                                                                ctx.lineCap = "round"
                                                                ctx.lineJoin = "round"
                                                                ctx.beginPath()
                                                                ctx.moveTo(width * 0.7, height * 0.2)
                                                                ctx.lineTo(width * 0.3, height * 0.5)
                                                                ctx.lineTo(width * 0.7, height * 0.8)
                                                                ctx.stroke()
                                                        }
                                                        MD3.Pressable {
                                                                id: prevArea
                                                                anchors.fill: parent
                                                                hoverEnabled: true
                                                                cursorShape: Qt.PointingHandCursor
                                                                onClicked: {
                                                                        changeMonth(-1)
                                                                }
                                                        }
                                                }
                                                Canvas {
                                                        id: nextBtn
                                                        width: 20
                                                        height: 20
                                                        opacity: nextArea.containsMouse ? 1 : 0.6
                                                        Behavior on opacity {
                                                                NumberAnimation {
                                                                        duration: 150
                                                                        easing.type: Easing.OutQuad
                                                                }
                                                        }
                                                        onPaint: {
                                                                var ctx = getContext("2d")
                                                                ctx.clearRect(0, 0, width, height)
                                                                ctx.strokeStyle = "#89b4fa"
                                                                ctx.lineWidth = 2.5
                                                                ctx.lineCap = "round"
                                                                ctx.lineJoin = "round"
                                                                ctx.beginPath()
                                                                ctx.moveTo(width * 0.3, height * 0.2)
                                                                ctx.lineTo(width * 0.7, height * 0.5)
                                                                ctx.lineTo(width * 0.3, height * 0.8)
                                                                ctx.stroke()
                                                        }
                                                        MD3.Pressable {
                                                                id: nextArea
                                                                anchors.fill: parent
                                                                hoverEnabled: true
                                                                cursorShape: Qt.PointingHandCursor
                                                                onClicked: {
                                                                        changeMonth(1)
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
                                Text {
                                        width: parent.width
                                        text: monthName(root.viewMonth) + " " + root.viewYear
                                        color: "#cdd6f4"
                                        horizontalAlignment: Text.AlignLeft
                                        font {
                                                family: "Monocraft"
                                                pixelSize: 14
                                        }
                                }
                                Item {
                                        width: parent.width
                                        height: calGrid.implicitHeight
                                        opacity: root.calOpacity
                                        Behavior on opacity {
                                                NumberAnimation {
                                                        duration: 150
                                                        easing.type: Easing.OutQuad
                                                }
                                        }
                                        GridLayout {
                                                id: calGrid
                                                width: parent.width
                                                columns: 7
                                                columnSpacing: 4
                                                rowSpacing: 4
                                                Repeater {
                                                        model: [Translation.tr("clock.cal.day.mon"), Translation.tr("clock.cal.day.tue"), Translation.tr("clock.cal.day.wed"), Translation.tr("clock.cal.day.thu"), Translation.tr("clock.cal.day.fri"), Translation.tr("clock.cal.day.sat"), Translation.tr("clock.cal.day.sun")]
                                                        Text {
                                                                text: modelData
                                                                color: "#45475a"
                                                                horizontalAlignment: Text.AlignHCenter
                                                                font {
                                                                        family: "Monocraft"
                                                                        pixelSize: 11
                                                                }
                                                        }
                                                }
                                                Repeater {
                                                        id: calRepeater
                                                        model: {
                                                                var first = new Date(root.viewYear, root.viewMonth, 1)
                                                                var startDay = (first.getDay() + 6) % 7
                                                                var daysInMonth = new Date(root.viewYear, root.viewMonth + 1, 0).getDate()
                                                                var cells = []
                                                                for (var i = 0; i < startDay; i++) {
                                                                        cells.push(0)
                                                                }
                                                                for (var d = 1; d <= daysInMonth; d++) {
                                                                        cells.push(d)
                                                                }
                                                                return cells
                                                        }
                                                        Text {
                                                                text: modelData === 0 ? "" : modelData
                                                                color: {
                                                                        if (modelData === 0) return "transparent"
                                                                        if (modelData === root.now.getDate() && root.viewMonth === root.now.getMonth() && root.viewYear === root.now.getFullYear()) {
                                                                                return "#89b4fa"
                                                                        }
                                                                        return "#cdd6f4"
                                                                }
                                                                font.bold: modelData === root.now.getDate() && root.viewMonth === root.now.getMonth() && root.viewYear === root.now.getFullYear()
                                                                horizontalAlignment: Text.AlignHCenter
                                                                font {
                                                                        family: "Monocraft"
                                                                        pixelSize: 12
                                                                }
                                                        }
                                                }
                                        }
                                }
                                // WEATHER_BLOCK
                                RowLayout {
                                        width: parent.width
                                        spacing: 0
                                        Text {
                                                Layout.preferredWidth: 40
                                                Layout.preferredHeight: 40
                                                horizontalAlignment: Text.AlignHCenter
                                                verticalAlignment: Text.AlignVCenter
                                                font {
                                                        family: "Monocraft"
                                                        pixelSize: 40
                                                }
                                                color: "#89b4fa"
                                                text: weatherLoaded ? getWeatherIcon(weatherIcon) : ""
                                        }
                                        ColumnLayout {
                                                spacing: 2
                                                Layout.fillWidth: true
                                                Text {
                                                        text: weatherLoaded ? Math.round(temperature) + (units === "metric" ? "°C" : "°F") : "--°C"
                                                        color: "#cdd6f4"
                                                        font {
                                                                family: "Monocraft"
                                                                pixelSize: 20
                                                                bold: true
                                                        }
                                                }
                                                Text {
                                                        text: weatherLoaded ? weatherDescription : Translation.tr("clock.loading")
                                                        color: "#a6adc8"
                                                        font {
                                                                family: "Monocraft"
                                                                pixelSize: 12
                                                        }
                                                        elide: Text.ElideRight
                                                }
                                        }
                                }
                                // /WEATHER_BLOCK
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
