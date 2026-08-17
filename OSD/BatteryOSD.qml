import QtQuick
import Quickshell
import Quickshell.Services.UPower
import "../Services"
OSDWindow {
    id: root
    property int percent: 0
    property bool charging: false
    property bool pluggedIn: false
    property bool shown20: false
    property bool shown10: false
    property bool ready: false
    property bool prevCharging: false
    property bool prevPluggedIn: false
    iconText: charging ? "󰂄" : "󱐋"
    labelText: charging ? Translation.trf("osd.battery.charging", percent) : (pluggedIn ? Translation.tr("osd.battery.fully.charged") : percent + "%")
    value: percent / 100
    accentColor: percent <= 10 ? "#ff0000" : (percent <= 20 ? "#ff6b6b" : "#B58FFF")
    showProgress: true
    Timer {
        interval: 1000
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
        var dev = UPower.displayDevice
        if (!dev || !dev.isPresent) return
        var newPercent = Math.round((dev.percentage || 0) * 100)
        var newCharging = dev.state === UPowerDeviceState.Charging
        var newPluggedIn = dev.state === UPowerDeviceState.FullyCharged || dev.state === UPowerDeviceState.PendingCharge
        percent = newPercent
        var chargingChanged = newCharging !== prevCharging
        var pluggedInChanged = newPluggedIn !== prevPluggedIn
        charging = newCharging
        pluggedIn = newPluggedIn
        if (newCharging || newPluggedIn) {
            shown20 = false
            shown10 = false
        }
        if (ready && (chargingChanged || pluggedInChanged)) {
            root.show()
        } else if (!newCharging && !newPluggedIn) {
            if (percent <= 20 && !shown20) {
                shown20 = true
                if (ready) root.show()
            }
            if (percent <= 10 && !shown10) {
                shown10 = true
                if (ready) root.show()
            }
        }
        prevCharging = newCharging
        prevPluggedIn = newPluggedIn
    }
}
