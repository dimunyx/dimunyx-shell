import QtQuick
import Quickshell
import Quickshell.Io
import "../Services"
import "../Services/WM"
OSDWindow {
    id: root
    property var layouts: WM.keyboardLayouts.names
    property int currentIdx: WM.keyboardLayouts.current_idx
    property int prevCurrentIdx: -1
    property string currentLayout: ""
    property bool ready: false
    iconText: "󰌌"
    labelText: currentLayout || Translation.tr("osd.kblayout")
    value: 1
    accentColor: "#89b4fa"
    showProgress: false
    property var shortNames: ({
        "English (US)": "US",
        "Russian": "RU",
        "us": "US",
        "ru": "RU"
    })
    function shortName(name) {
        return shortNames[name] ?? name.substring(0, 2).toUpperCase()
    }
    onCurrentIdxChanged: {
        if (root.currentIdx >= 0 && root.currentIdx < root.layouts.length) {
            root.currentLayout = shortName(root.layouts[root.currentIdx])
            if (root.ready && root.currentIdx !== root.prevCurrentIdx) {
                root.prevCurrentIdx = root.currentIdx
                root.show()
            }
        }
    }
    Timer {
        interval: 300
        running: true
        onTriggered: root.ready = true
    }
}
