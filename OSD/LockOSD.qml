import QtQuick
import Quickshell
import "../Services"
OSDWindow {
    id: root
    property bool ready: false
    iconText: "󰌾"
    labelText: Translation.tr("osd.lock.screen")
    value: 1
    accentColor: "#B58FFF"
    showProgress: false
    Timer {
        interval: 300
        running: true
        onTriggered: root.ready = true
    }
    function onLock() {
        if (ready) root.show()
    }
}
