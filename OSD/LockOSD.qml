import QtQuick
import Quickshell
import "../Services"
OSDWindow {
    id: root
    property bool ready: false
    iconText: "󰌾"
    labelText: Translation.tr("osd.lock.screen")
    value: 1
    accentColor: "#89b4fa"
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
