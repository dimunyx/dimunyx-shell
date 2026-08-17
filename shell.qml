//@ pragma IconTheme Papirus-Dark
//@ pragma UseQApplication
import Quickshell
import QtQuick
import "Services"
import "Indicators"
import "Monitors"
import "OSD"
Scope {
        Lockscreen {
                id: lockScr
        }
        Bar {
                lockScreen: lockScr
        }
        VolumeOSD {}
        BrightnessOSD {}
        KbLayoutOSD {}
        BatteryOSD {}
        ClipboardOSD {}
        PowerProfileOSD {}
        LockOSD {
                id: lockOSD
        }
        Connections {
                target: lockScr
                function onVisibleChanged() {
                        if (lockScr.visible) lockOSD.onLock()
                }
        }
}
