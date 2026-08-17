import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "../Services"
OSDWindow {
    id: root
    property bool muted: false
    property real volume: 0
    property int volumePct: 0
    property bool ready: false
    property int prevVolumePct: -2
    property bool prevMuted: false
    iconText: muted ? "\ueee8" : (volumePct < 33 ? "\uf026" : (volumePct < 66 ? "\uf027" : "\uf028"))
    labelText: muted ? Translation.tr("osd.volume.muted") : volumePct + "%"
    value: volumePct / 100
    accentColor: muted ? "#f38ba8" : "#89b4fa"
    showProgress: true
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }
    Timer {
        interval: 100
        repeat: true
        running: true
        onTriggered: root.refresh()
    }
    Timer {
        interval: 300
        running: true
        onTriggered: root.ready = true
    }
    function refresh() {
        var sink = Pipewire.defaultAudioSink
        if (!sink || !sink.ready || !sink.audio) {
            muted = false
            volume = 0
            volumePct = 0
        } else {
            muted = sink.audio.muted
            volume = sink.audio.volume
            volumePct = Math.round(volume * 100)
        }
        if (volumePct !== prevVolumePct || muted !== prevMuted) {
            prevVolumePct = volumePct
            prevMuted = muted
            if (ready) root.show()
        }
    }
}
