import Quickshell
import QtQuick
import QtQuick.Controls
import "./Services"
import "./Indicators"
import "./Monitors"
import "./Components" as MD3
PanelWindow {
        id: root
        focusable: true
        anchors {
                left: true
                right: true
                top: true
        }
        margins {
                left: 12
                right: 12
                top: 12
        }
        implicitHeight: MD3.Theme.barHeight
        property var lockScreen: null
        color: "transparent"
        property real barOpacity: 0
        onBarOpacityChanged: {
                if (barOpacity === 1) {
                        rectOpacity = 1
                        rectTransformY = 0
                }
        }
        property real rectOpacity: 0
        property real rectTransformY: -50
        Behavior on rectOpacity {
                NumberAnimation {
                        duration: 300
                        easing.type: Easing.OutQuad
                }
        }
        Behavior on rectTransformY {
                NumberAnimation {
                        duration: 300
                        easing.type: Easing.OutQuad
                }
        }
        Component.onCompleted: {
                root.barOpacity = 1
        }
        Rectangle {
                id: barRect
                anchors.fill: parent
                color: MD3.Theme.surfaceContainer
                border {
                        color: MD3.Theme.outlineVariant
                        width: 1
                }
                radius: MD3.Theme.barRadius
                opacity: root.rectOpacity
                transform: Translate {
                        y: root.rectTransformY
                }
                Wallpaper {}
                Launcher {
                        id: launcherIcon
                        rootWindow: root
                        anchors {
                                left: parent.left
                                leftMargin: 7.5
                                verticalCenter: parent.verticalCenter
                        }
                        onClicked: appLauncher.popupOpen = !appLauncher.popupOpen
                }
                AppLauncher {
                        id: appLauncher
                        rootWindow: root
                        x: launcherIcon.x
                }
                NiriVer {
                        id: niriVerIcon
                        rootWindow: root
                        anchors {
                                left: launcherIcon.right
                                leftMargin: -5
                                verticalCenter: parent.verticalCenter
                        }
                }
                StateVer {
                        id: stateVerIcon
                        rootWindow: root
                        anchors {
                                left: niriVerIcon.right
                                leftMargin: -2
                                verticalCenter: parent.verticalCenter
                        }
                }
                Cava {
                        id: cavaIcon
                        rootWindow: root
                        anchors {
                                left: stateVerIcon.right
                                leftMargin: -5
                                verticalCenter: parent.verticalCenter
                        }
                }
                CapsNumLock {
                        id: capsNumLock
                        anchors {
                                left: cavaIcon.right
                                leftMargin: -1
                                verticalCenter: parent.verticalCenter
                        }
                }
                Tray {
                        id: tray
                        rootWindow: root
                        anchors {
                                left: capsNumLock.right
                                leftMargin: -4
                                verticalCenter: parent.verticalCenter
                        }
                }
                Workspaces {
                        id: workspaces
                        anchors {
                                horizontalCenter: parent.horizontalCenter
                                verticalCenter: parent.verticalCenter
                        }
                }
                SessionMenu {
                        id: sessionMenu
                        rootWindow: root
                        lockScreen: root.lockScreen
                        anchors {
                                right: parent.right
                                rightMargin: 8
                                verticalCenter: parent.verticalCenter
                        }
                }
                Notifications {
                        id: notifyCenter
                        rootWindow: root
                        anchors {
                                right: sessionMenu.left
                                rightMargin: 4
                                verticalCenter: parent.verticalCenter
                        }
                }
                Clock {
                        id: clock
                        rootWindow: root
                        anchors {
                                right: notifyCenter.left
                                rightMargin: -6
                                verticalCenter: parent.verticalCenter
                        }
                }
                PowerProfileDaemon {
                        id: power
                        rootWindow: root
                        anchors {
                                right: clock.left
                                rightMargin: 6
                                verticalCenter: parent.verticalCenter
                        }
                }
                Battery {
                        id: bat
                        rootWindow: root
                        anchors {
                                right: power.left
                                rightMargin: -8
                                verticalCenter: parent.verticalCenter
                        }
                }
                Brightness {
                        id: bright
                        rootWindow: root
                        anchors {
                                right: bat.left
                                rightMargin: 6
                                verticalCenter: parent.verticalCenter
                        }
                }
                Volume {
                        id: volume
                        rootWindow: root
                        anchors {
                                right: bright.left
                                rightMargin: 4
                                verticalCenter: parent.verticalCenter
                        }
                }
                Bluetooth {
                        id: bluetooth
                        rootWindow: root
                        anchors {
                                right: volume.left
                                rightMargin: 4
                                verticalCenter: parent.verticalCenter
                        }
                }
                Wifi {
                        id: wifi
                        rootWindow: root
                        anchors {
                                right: bluetooth.left
                                rightMargin: 5
                                verticalCenter: parent.verticalCenter
                        }
                }
                Disk {
                        id: disk
                        rootWindow: root
                        anchors {
                                right: wifi.left
                                rightMargin: 7
                                verticalCenter: parent.verticalCenter
                        }
                }
                Temp {
                        id: temp
                        rootWindow: root
                        anchors {
                                right: disk.left
                                rightMargin: 7
                                verticalCenter: parent.verticalCenter
                        }
                }
                Mem {
                        id: mem
                        rootWindow: root
                        anchors {
                                right: temp.left
                                rightMargin: 6
                                verticalCenter: parent.verticalCenter
                        }
                }
                Cpu {
                        id: cpu
                        rootWindow: root
                        anchors {
                                right: mem.left
                                rightMargin: 7
                                verticalCenter: parent.verticalCenter
                        }
                }
                KbLayout {
                        id: kbLayout
                        rootWindow: root
                        anchors {
                                right: cpu.left
                                rightMargin: -7
                                verticalCenter: parent.verticalCenter
                        }
                }
        }
}
