import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
PanelWindow {
        id: root
        screen: Quickshell.screens[0]
        anchors {
                top: true
                bottom: true
                left: true
                right: true
        }
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.namespace: "wallpaper"
        WlrLayershell.exclusiveZone: -1
        Image {
                id: currentImage
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                horizontalAlignment: Image.AlignHCenter
                verticalAlignment: Image.AlignVCenter
                asynchronous: true
                cache: true
                smooth: true
                mipmap: true
                sourceSize.width: 1920
                sourceSize.height: 1080
                opacity: 1
        }
        Image {
                id: nextImage
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                horizontalAlignment: Image.AlignHCenter
                verticalAlignment: Image.AlignVCenter
                asynchronous: true
                cache: true
                smooth: true
                mipmap: true
                sourceSize.width: 1920
                sourceSize.height: 1080
                opacity: 0
                Behavior on opacity {
                        NumberAnimation {
                                duration: 1500
                                easing.type: Easing.InOutCubic
                        }
                }
        }
        Process {
                id: wallpaperPicker
                command: [
                        "bash",
                        "-c",
                        "find -L $HOME/.config/wallpapers/wallpapers -type f \\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \\) | shuf -n 1"
                ]
                stdout: StdioCollector {
                        onStreamFinished: {
                                var path = this.text.trim()
                                if (path.length > 0) {
                                        nextImage.source = ""
                                        nextImage.source = "file://" + path
                                        preloadTimer.start()
                                }
                        }
                }
        }
        Timer {
                id: preloadTimer
                interval: 200
                onTriggered: {
                        if (nextImage.status === Image.Ready) {
                                startFade()
                        } else {
                                preloadTimer.restart()
                        }
                }
        }
        function startFade() {
                if (currentImage.source === "") {
                        currentImage.source = nextImage.source
                        currentImage.opacity = 1
                        nextImage.opacity = 0
                        return
                }
                nextImage.opacity = 1
                swapTimer.start()
        }
        Timer {
                id: swapTimer
                interval: 1500
                onTriggered: {
                        currentImage.source = nextImage.source
                        nextImage.opacity = 0
                }
        }
        Timer {
                id: changeTimer
                interval: 300000
                running: true
                repeat: true
                onTriggered: wallpaperPicker.running = true
        }
        Component.onCompleted: wallpaperPicker.running = true
}
