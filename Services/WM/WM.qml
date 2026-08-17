pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property string type: ""

    property Item _backend: null

    property var workspaces: _backend ? _backend.workspaces : []
    property var windows: _backend ? _backend.windows : []
    property var keyboardLayouts: _backend ? _backend.keyboardLayouts : ({names: [], current_idx: -1})
    property string version: _backend ? _backend.version : ""
    property string iconSource: _backend ? _backend.iconSource : ""

    function switchWorkspace(idx) {
        console.warn("WM.switchWorkspace: idx=" + idx + " type=" + root.type + " backend=" + (root._backend ? "set" : "null"))
        if (_backend) _backend.switchWorkspace(idx)
    }
    function switchLayout(idx) { if (_backend) _backend.switchLayout(idx) }
    function focusWindow(id) { if (_backend) _backend.focusWindow(id) }
    function refreshWindows() { if (_backend) _backend.refreshWindows() }

    Niri { id: niriBackend }
    Hyprland { id: hyprlandBackend }

    Process {
        id: probeProcess
        command: ["sh", "-c", "niri msg --json workspaces 2>/dev/null && echo NIRI_OK || (hyprctl workspaces -j 2>/dev/null && echo HYPR_OK || echo UNKNOWN)"]
        stdout: StdioCollector {
            onStreamFinished: {
                var out = text.trim()
                if (out.indexOf("NIRI_OK") >= 0) {
                    root.type = "niri"
                    niriBackend.active = true
                    root._backend = niriBackend
                } else if (out.indexOf("HYPR_OK") >= 0) {
                    root.type = "hyprland"
                    hyprlandBackend.active = true
                    root._backend = hyprlandBackend
                }
            }
        }
        running: true
    }
}
