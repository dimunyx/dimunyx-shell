import QtQuick
import "../Components" as MD3
import Quickshell
import Quickshell.Io
import QtQuick.Layouts
import Quickshell.Widgets
import QtQuick.Controls
import "WM"
Item {
        id: root
        implicitWidth: 1
        implicitHeight: 1
        property var rootWindow: null
        property bool popupOpen: false
        property bool popupReady: false
        property string query: ""
        property bool isWinList: false
        property var displayItems: []
        property int copiedIndex: -1
        property int listHoveredIndex: -1
        property string mode: "apps"
        property bool menuOpen: false
        property bool menuClosing: false
        property int hoveredIndex: -1
        property var emojiData: []
        property bool emojiLoaded: false
        property var emojiUsage: ({})
        property string emojiCategory: "people"
        property bool categoryPopupOpen: false
        property bool categoryPopupClosing: false
        property int categoryHoveredIndex: -1
        property bool windowsLoaded: false
        property var windowsList: WM.windows
        property int emojiSearchLimit: 50
        property int clipboardLimit: 50
        property int emojiUsageLimit: 200
        readonly property string emojiUsagePath: Quickshell.cacheDir + "emoji_usage.json"
readonly property var emojiCategories: [
        { key: "people", label: "People", icon: "👤" },
        { key: "animals", label: "Animals", icon: "🐾" },
        { key: "nature", label: "Nature", icon: "🌿" },
        { key: "food", label: "Food", icon: "🍕" },
        { key: "activity", label: "Activity", icon: "⚽" },
        { key: "travel", label: "Travel", icon: "✈️" },
        { key: "objects", label: "Objects", icon: "💡" },
        { key: "symbols", label: "Symbols", icon: "🔣" },
        { key: "flags", label: "Flags", icon: "🏳️" }
]
        signal closePopup()
        onClosePopup: { popupOpen = false }
        function trimEmojiUsage() {
                if (Object.keys(root.emojiUsage).length > root.emojiUsageLimit) {
                        var entries = Object.entries(root.emojiUsage)
                        entries.sort(function(a, b) { return b[1].lastUsed - a[1].lastUsed })
                        var trimmed = {}
                        for (var i = 0; i < Math.min(root.emojiUsageLimit, entries.length); i++) {
                                trimmed[entries[i][0]] = entries[i][1]
                        }
                        root.emojiUsage = trimmed
                }
        }
        FileView {
                id: emojiFile
                path: Qt.resolvedUrl("../emoji/Emoji.json")
                printErrors: true
                watchChanges: false
                onLoaded: {
                        try {
                                var content = text()
                                if (content && content.length > 0) {
                                        var parsed = JSON.parse(content)
                                        if (Array.isArray(parsed)) {
                                                root.emojiData = parsed
                                                root.emojiLoaded = true
                                        } else {
                                                root.emojiData = []
                                                root.emojiLoaded = true
                                        }
                                        if (root.mode === "emoji") {
                                                updateEmojiDisplay()
                                        }
                                } else {
                                        root.emojiData = []
                                        root.emojiLoaded = true
                                }
                        } catch (e) {
                                root.emojiData = []
                                root.emojiLoaded = true
                        }
                }
                onLoadFailed: function(error) {
                        root.emojiData = []
                        root.emojiLoaded = true
                }
        }
        FileView {
                id: usageFile
                path: root.emojiUsagePath
                printErrors: false
                watchChanges: false
                onLoaded: {
                        try {
                                var content = text()
                                if (content && content.trim() !== "") {
                                        var parsed = JSON.parse(content)
                                        if (parsed && typeof parsed === 'object') {
                                                root.emojiUsage = parsed
                                                trimEmojiUsage()
                                        }
                                }
                        } catch (e) {
                                root.emojiUsage = {}
                        }
                }
                onLoadFailed: function(error) {
                        root.emojiUsage = {}
                        Quickshell.execDetached(["sh", "-c", "mkdir -p \"$(dirname \"" + root.emojiUsagePath + "\")\" && echo '{}' > \"" + root.emojiUsagePath + "\""])
                }
        }
        Timer {
                id: saveUsageTimer
                interval: 3000
                repeat: false
                onTriggered: {
                        try {
                                trimEmojiUsage()
                                var content = JSON.stringify(root.emojiUsage)
                                Quickshell.execDetached(["sh", "-c", "mkdir -p \"$(dirname \"" + root.emojiUsagePath + "\")\" && echo '" + content + "' > \"" + root.emojiUsagePath + "\""])
                        } catch (e) {
                        }
                }
        }
        onWindowsListChanged: {
                if (WM.windows.length > 0 || root.windowsLoaded) {
                        root.windowsLoaded = true
                }
                if (root.mode === "windows") {
                        updateWindowsDisplay()
                }
        }
        function getIconForApp(appId) {
                if (!appId) return ""
                var iconMap = {
                        "firefox": "firefox",
                        "google-chrome": "google-chrome",
                        "chromium": "chromium",
                        "code": "code",
                        "code-oss": "code-oss",
                        "discord": "discord",
                        "spotify": "spotify",
                        "steam": "steam",
                        "mpv": "mpv",
                        "vlc": "vlc",
                        "thunderbird": "thunderbird",
                        "kitty": "kitty",
                        "alacritty": "alacritty",
                        "wezterm": "wezterm",
                        "foot": "foot",
                        "nemo": "nemo",
                        "nautilus": "nautilus",
                        "dolphin": "dolphin",
                        "gimp": "gimp",
                        "inkscape": "inkscape",
                        "libreoffice": "libreoffice",
                        "obsidian": "obsidian",
                        "notion": "notion",
                        "slack": "slack",
                        "telegram": "telegram",
                        "signal": "signal",
                        "whatsapp": "whatsapp",
                        "zoom": "zoom",
                        "obs": "obs",
                        "kdenlive": "kdenlive",
                        "audacity": "audacity",
                        "bitwarden": "bitwarden",
                        "keepassxc": "keepassxc",
                        "qalculate": "qalculate"
                }
                if (iconMap[appId]) return iconMap[appId]
                if (appId.includes(".")) {
                        var parts = appId.split(".")
                        var last = parts[parts.length - 1]
                        if (iconMap[last]) return iconMap[last]
                        if (iconMap[appId]) return iconMap[appId]
                }
                return appId
        }
        function getCategoryIcon(key) {
                for (var i = 0; i < root.emojiCategories.length; i++) {
                        if (root.emojiCategories[i].key === key) {
                                return root.emojiCategories[i].icon
                        }
                }
                return "🏷️"
        }
        function searchEmojis(query, category) {
                if (!root.emojiLoaded || root.emojiData.length === 0) {
                        return []
                }
                var q = (query || "").toLowerCase().trim()
                var filtered = root.emojiData
                if (category && category !== "all") {
                        filtered = filtered.filter(function(emoji) {
                                return (emoji.category || "") === category
                        })
                }
                if (q) {
                        var terms = q.split(" ").filter(function(t) { return t })
                        filtered = filtered.filter(function(emoji) {
                                for (var i = 0; i < terms.length; i++) {
                                        var term = terms[i]
                                        var emojiMatch = emoji.emoji.toLowerCase().includes(term)
                                        var nameMatch = (emoji.name || "").toLowerCase().includes(term)
                                        var keywordMatch = false
                                        if (emoji.keywords) {
                                                for (var j = 0; j < emoji.keywords.length; j++) {
                                                        if (emoji.keywords[j].toLowerCase().includes(term)) {
                                                                keywordMatch = true
                                                                break
                                                        }
                                                }
                                        }
                                        if (!emojiMatch && !nameMatch && !keywordMatch) {
                                                return false
                                        }
                                }
                                return true
                        })
                }
                if (filtered.length > root.emojiSearchLimit) {
                        filtered = filtered.slice(0, root.emojiSearchLimit)
                }
                return filtered
        }
        function getCategoryIndex(key) {
                for (var i = 0; i < root.emojiCategories.length; i++) {
                        if (root.emojiCategories[i].key === key) {
                                return i
                        }
                }
                return 0
        }
        function recordEmojiUsage(emojiChar) {
                if (emojiChar) {
                        var current = root.emojiUsage[emojiChar] || { count: 0, lastUsed: 0 }
                        root.emojiUsage[emojiChar] = {
                                count: current.count + 1,
                                lastUsed: Date.now()
                        }
                        saveUsageTimer.restart()
                }
        }
        function copyEmoji(emojiChar) {
                if (emojiChar) {
                        recordEmojiUsage(emojiChar)
                        Quickshell.execDetached(["sh", "-c", "echo -n \"" + emojiChar + "\" | wl-copy"])
                }
        }
        function updateEmojiDisplay() {
                if (!root.emojiLoaded) {
                root.displayItems = [{
                                name: Translation.tr("launcher.loading.emoji"),
                                type: "loading",
                                icon: ""
                        }]
                        root.isWinList = false
                        root.copiedIndex = -1
                        return
                        }
                var q = root.query.toLowerCase().trim()
                var results = searchEmojis(q, root.emojiCategory)
                var items = []
                for (var i = 0; i < results.length; i++) {
                        var emoji = results[i]
                        items.push({
                                name: emoji.name || "Unnamed",
                                icon: "",
                                type: "emoji",
                                emojiChar: emoji.emoji,
                                emojiData: emoji
                        })
                }
                root.displayItems = items
                root.isWinList = true
                if (root.copiedIndex >= items.length || root.copiedIndex < 0) {
                        root.copiedIndex = items.length > 0 ? 0 : -1
                }
        }
        function selectEmojiCategory(category) {
                root.emojiCategory = category
                root.categoryPopupOpen = false
                root.categoryPopupClosing = true
                categoryCloseTimer.start()
                root.copiedIndex = 0
                updateEmojiDisplay()
        }
        function truncateText(text, maxLen) {
                if (!text) return ""
                if (text.length <= maxLen) return text
                return text.substring(0, maxLen) + "..."
        }
        function updateAppDisplay() {
                var q = root.query.toLowerCase()
                var all = [...DesktopEntries.applications.values].filter(function(e) { return e.name })
                var filtered = q === "" ? all : all.filter(function(e) {
                        var name = (e.name || "").toLowerCase()
                        var comment = (e.comment || "").toLowerCase()
                        var generic = (e.genericName || "").toLowerCase()
                        return name.includes(q) || comment.includes(q) || generic.includes(q)
                })
                filtered.sort(function(a, b) { return a.name.localeCompare(b.name) })
                if (filtered.length > 50) {
                        filtered = filtered.slice(0, 50)
                }
                var items = []
                for (var i = 0; i < filtered.length; i++) {
                        items.push({
                                name: truncateText(filtered[i].name, 24),
                                icon: filtered[i].icon || "",
                                type: "app",
                                entry: filtered[i]
                        })
                }
                root.displayItems = items
                root.isWinList = true
                root.copiedIndex = items.length > 0 ? 0 : -1
        }
        function updateClipDisplay() {
                var q = root.query.toLowerCase()
                var items = []
                var count = Math.min(clipListModel.count, root.clipboardLimit)
                for (var i = 0; i < count; i++) {
                        var entry = clipListModel.get(i)
                        if (q === "" || entry.content.toLowerCase().includes(q)) {
                                items.push({ name: truncateText(entry.content, 24), type: "clip", id: entry.entryId })
                                if (items.length >= 30) break
                        }
                }
                root.displayItems = items
                root.isWinList = true
                root.copiedIndex = items.length > 0 ? 0 : -1
        }
        function updateWindowsDisplay() {
                if (!root.windowsLoaded) {
                        root.displayItems = [{
                                name: Translation.tr("launcher.loading.windows"),
                                type: "loading",
                                icon: ""
                        }]
                        root.isWinList = false
                        root.copiedIndex = -1
                        return
                }
                var q = root.query.toLowerCase().trim()
                var filtered = root.windowsList
                if (q) {
                        filtered = filtered.filter(function(win) {
                                var title = (win.title || "").toLowerCase()
                                var appId = (win.app_id || "").toLowerCase()
                                return title.includes(q) || appId.includes(q)
                        })
                }
                if (filtered.length > 50) {
                        filtered = filtered.slice(0, 50)
                }
                var items = []
                for (var i = 0; i < filtered.length; i++) {
                        var win = filtered[i]
                        var isFocused = win.is_focused || false
                        var appId = win.app_id || ""
                        var iconName = getIconForApp(appId)
                        items.push({
                                name: truncateText(win.title || "Unnamed", 30),
                                icon: iconName,
                                type: "window",
                                windowId: win.id,
                                isFocused: isFocused,
                                workspace: win.workspace_id || 0,
                                appId: appId
                        })
                }
                root.displayItems = items
                root.isWinList = true
                root.copiedIndex = items.length > 0 ? 0 : -1
        }
        function isHexColor(str) {
                return /^#([0-9A-Fa-f]{3}|[0-9A-Fa-f]{6})$/.test((str || "").trim())
        }
        function isFilePath(str) {
                var s = (str || "").trim()
                return /^\/[^\s]+$/.test(s)
        }
        function activateItem(item) {
                if (!item) return
                if (item.type === "app") {
                        item.entry.execute()
                        root.popupOpen = false
                } else if (item.type === "clip") {
                        clipCopyProcess.command = ["sh", "-c", "cliphist decode " + item.id + " | wl-copy"]
                        clipCopyProcess.running = true
                        root.popupOpen = false
                } else if (item.type === "emoji") {
                        copyEmoji(item.emojiChar)
                        root.popupOpen = false
                } else if (item.type === "window") {
                        WM.focusWindow(String(item.windowId))
                        root.popupOpen = false
                }
        }
        function selectMode(newMode) {
                root.mode = newMode
                root.menuOpen = false
                root.categoryPopupOpen = false
                root.categoryPopupClosing = false
                searchField.text = ""
                root.query = ""
                root.emojiCategory = "people"
                root.copiedIndex = 0
                if (newMode === "apps") {
                        updateAppDisplay()
                } else if (newMode === "clip") {
                        cliphistListProcess.running = true
                } else if (newMode === "emoji") {
                        if (!root.emojiLoaded) {
                                root.displayItems = [{
                                name: Translation.tr("launcher.loading.emoji"),
                                        type: "loading",
                                        icon: ""
                                }]
                                root.isWinList = false
                                root.copiedIndex = -1
                        } else {
                                updateEmojiDisplay()
                        }
                } else if (newMode === "windows") {
                        WM.refreshWindows()
                        if (!root.windowsLoaded) {
                                root.displayItems = [{
                                        name: Translation.tr("launcher.loading.windows"),
                                        type: "loading",
                                        icon: ""
                                }]
                                root.isWinList = false
                                root.copiedIndex = -1
                        } else {
                                updateWindowsDisplay()
                        }
                } else {
                        root.displayItems = []
                        root.isWinList = false
                        root.copiedIndex = -1
                }
                searchField.forceActiveFocus()
        }
        IpcHandler {
                id: ipc
                target: "appLauncher"
                enabled: true
                function apps() {
                        if (root.popupOpen && root.mode === "apps") root.popupOpen = false
                        else { root.popupOpen = true; selectMode("apps") }
                }
                function clip() {
                        if (root.popupOpen && root.mode === "clip") root.popupOpen = false
                        else { root.popupOpen = true; selectMode("clip") }
                }
                function cmd() {
                        if (root.popupOpen && root.mode === "cmd") root.popupOpen = false
                        else { root.popupOpen = true; selectMode("cmd") }
                }
                function windows() {
                        if (root.popupOpen && root.mode === "windows") root.popupOpen = false
                        else { root.popupOpen = true; selectMode("windows") }
                }
                function clipClear() { clipClearProcess.running = true }
        }
        onPopupOpenChanged: {
                if (root.popupOpen) {
                        closeTimer.stop()
                        root.popupReady = true
                        root.mode = "apps"
                        root.menuOpen = false
                        root.menuClosing = false
                        root.emojiCategory = "people"
                        root.categoryPopupOpen = false
                        root.categoryPopupClosing = false
                        root.copiedIndex = 0
                        updateAppDisplay()
                        searchField.forceActiveFocus()
                } else {
                        root.displayItems = []
                        root.isWinList = false
                        root.copiedIndex = -1
                }
        }
        Timer {
                id: closeTimer
                interval: 200
                running: !root.popupOpen && root.popupReady
                onTriggered: {
                        root.popupReady = false
                        searchField.text = ""
                        root.query = ""
                        root.isWinList = false
                        root.displayItems = []
                        root.copiedIndex = -1
                        root.menuOpen = false
                        root.menuClosing = false
                        root.categoryPopupOpen = false
                        root.categoryPopupClosing = false
                        root.emojiCategory = "people"
                }
        }
        Timer {
                id: menuCloseTimer
                interval: 200
                onTriggered: { root.menuClosing = false }
        }
        Timer {
                id: categoryCloseTimer
                interval: 200
                onTriggered: { root.categoryPopupClosing = false }
        }
        Timer {
                id: windowsUpdateTimer
                interval: 3000
                repeat: true
                running: root.popupOpen && root.mode === "windows"
                onTriggered: {
                        WM.refreshWindows()
                }
        }
        Process {
                id: runCmdProcess
                property string cmd: ""
                command: ["sh", "-c", ""]
        }
        Process {
                id: clipClearProcess
                command: ["sh", "-c", "cliphist wipe && wl-copy --clear"]
                onExited: {
                        clipListModel.clear()
                        updateClipDisplay()
                }
        }
        Process {
                id: cliphistListProcess
                command: ["sh", "-c", "cliphist list | head -50"]
                stdout: StdioCollector {
                        onStreamFinished: {
                                clipListModel.clear()
                                var lines = this.text.split("\n").filter(function(l) { return l.trim() !== "" })
                                var count = Math.min(lines.length, root.clipboardLimit)
                                for (var i = 0; i < count; i++) {
                                        var tab = lines[i].indexOf("\t")
                                        var id = tab >= 0 ? lines[i].substring(0, tab) : lines[i]
                                        var content = tab >= 0 ? lines[i].substring(tab + 1) : lines[i]
                                        clipListModel.append({ entryId: id, content: content })
                                }
                                updateClipDisplay()
                        }
                }
        }
        Process {
                id: clipCopyProcess
                command: ["sh", "-c", ""]
        }
        ListModel { id: clipListModel }
        PopupWindow {
                id: popup
                grabFocus: true
                visible: root.popupReady
                color: "transparent"
                anchor {
                        window: root.rootWindow
                        rect.x: root.x
                        rect.y: root.rootWindow ? root.rootWindow.height : 0
                }
                implicitWidth: 340
                implicitHeight: 400
                Rectangle {
                        anchors.fill: parent
                        color: "#1e1e2e"
                        radius: 20
                        clip: true
                        border { color: "#89b4fa"; width: 1 }
                        opacity: root.popupOpen ? 1 : 0
                        scale: root.popupOpen ? 1 : 0.95
                        transformOrigin: Item.Top
                        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
                        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
                        MD3.Pressable {
                                anchors.fill: parent
                                hoverEnabled: true
                                propagateComposedEvents: true
                                onPressed: function(mouse) {
                                        mouse.accepted = true
                                        searchField.forceActiveFocus()
                                }
                        }
                        Item {
                                anchors { fill: parent; margins: 12 }
                                Item {
                                        id: header
                                        anchors { top: parent.top; left: parent.left; right: parent.right }
                                        height: 24
                                        Text {
                                                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                                                text: root.mode === "emoji" ? Translation.tr("launcher.title.emoji") : (root.mode === "windows" ? Translation.tr("launcher.title.windows") : (root.mode === "clip" ? Translation.tr("launcher.title.clip") : Translation.tr("launcher.title.apps")))
                                                color: "#cdd6f4"
                                                font { family: "Monocraft"; pixelSize: 14; bold: true }
                                        }
                                        Rectangle {
                                                id: clearBtn
                                                visible: root.mode === "clip"
                                                anchors { right: closeBtn.left; rightMargin: 6; verticalCenter: parent.verticalCenter }
                                                width: clearText.implicitWidth + 14
                                                height: 24
                                                radius: 6
                                                color: "transparent"
                                                border { color: "#45475a"; width: 1 }
                                                clip: true
                                                Rectangle {
                                                        id: clearHoverFill
                                                        anchors.centerIn: parent
                                                        width: 0
                                                        height: 0
                                                        radius: 6
                                                        color: "#89b4fa"
                                                        opacity: 0.2
                                                        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuad } }
                                                        Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutQuad } }
                                                }
                                                Text {
                                                        id: clearText
                                                        anchors.centerIn: parent
                                                        text: Translation.tr("launcher.clear")
                                                        color: "#89b4fa"
                                                        font { family: "Monocraft"; pixelSize: 12 }
                                                }
                                                MD3.Pressable {
                                                        id: clearArea
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor
                                                        onEntered: { clearHoverFill.width = parent.width; clearHoverFill.height = parent.height }
                                                        onExited: { clearHoverFill.width = 0; clearHoverFill.height = 0 }
                                                        onClicked: clipClearProcess.running = true
                                                }
                                        }
                                        Rectangle {
                                                id: closeBtn
                                                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
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
                                                        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuad } }
                                                        Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutQuad } }
                                                }
                                                Text {
                                                        anchors.centerIn: parent
                                                        text: "\uf00d"
                                                        color: "#89b4fa"
                                                        font { family: "Monocraft"; pixelSize: 14 }
                                                }
                                                MD3.Pressable {
                                                        id: closeArea
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor
                                                        onEntered: { closeHoverFill.width = parent.width; closeHoverFill.height = parent.height }
                                                        onExited: { closeHoverFill.width = 0; closeHoverFill.height = 0 }
                                                        onClicked: root.popupOpen = false
                                                }
                                        }
                                }
                                Row {
                                        id: searchRow
                                        anchors { top: header.bottom; topMargin: 8; left: parent.left; right: parent.right }
                                        height: 32
                                        spacing: 6
                                        Rectangle {
                                                id: modeButton
                                                width: 32
                                                height: 32
                                                radius: 8
                                                color: "transparent"
                                                border { color: "#45475a"; width: 1 }
                                                clip: true
                                                Rectangle {
                                                        id: modeHoverFill
                                                        anchors.centerIn: parent
                                                        width: 0
                                                        height: 0
                                                        radius: 8
                                                        color: "#89b4fa"
                                                        opacity: 0.2
                                                        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuad } }
                                                        Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutQuad } }
                                                }
                                                Text {
                                                        id: modeText
                                                        anchors.centerIn: parent
                                                        text: root.mode === "apps" ? "\uf40e" :
                                                              (root.mode === "clip" ? "\uf07f" :
                                                              (root.mode === "emoji" ? "\uefa8" :
                                                              (root.mode === "windows" ? "\uf2d0" : "❯_")))
                                                        color: "#89b4fa"
                                                        font { family: "Monocraft"; pixelSize: 17 }
                                                }
                                                MD3.Pressable {
                                                        id: modeMouseArea
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor
                                                        onEntered: { modeHoverFill.width = parent.width; modeHoverFill.height = parent.height }
                                                        onExited: { modeHoverFill.width = 0; modeHoverFill.height = 0 }
                                                        onClicked: { root.menuOpen = !root.menuOpen }
                                                }
                                        }
                                        Rectangle {
                                                id: categoryButton
                                                visible: root.mode === "emoji"
                                                width: 32
                                                height: 32
                                                radius: 8
                                                color: "transparent"
                                                border { color: "#45475a"; width: 1 }
                                                clip: true
                                                Rectangle {
                                                        id: categoryHoverFill
                                                        anchors.centerIn: parent
                                                        width: 0
                                                        height: 0
                                                        radius: 8
                                                        color: "#89b4fa"
                                                        opacity: 0.2
                                                        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuad } }
                                                        Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutQuad } }
                                                }
                                                Text {
                                                        id: categoryIconText
                                                        anchors.centerIn: parent
                                                        text: getCategoryIcon(root.emojiCategory)
                                                        color: "#89b4fa"
                                                        font.pixelSize: 16
                                                }
                                                MD3.Pressable {
                                                        id: categoryMouseArea
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor
                                                        onEntered: {
                                                                categoryHoverFill.width = parent.width
                                                                categoryHoverFill.height = parent.height
                                                        }
                                                        onExited: {
                                                                categoryHoverFill.width = 0
                                                                categoryHoverFill.height = 0
                                                        }
                                                onClicked: {
                                                        if (root.categoryPopupOpen) {
                                                                root.categoryPopupOpen = false
                                                                root.categoryPopupClosing = true
                                                                categoryCloseTimer.start()
                                                        } else {
                                                                root.categoryPopupOpen = true
                                                        }
                                                        searchField.forceActiveFocus()
                                                }
                                                }
                                        }
                                        Rectangle {
                                                id: searchBox
                                                width: searchRow.width - modeButton.width - searchRow.spacing - (root.mode === "emoji" ? categoryButton.width + searchRow.spacing : 0)
                                                height: 32
                                                radius: 8
                                                color: "#1e1e2e"
                                                border { color: "#45475a"; width: 1 }
                                                TextInput {
                                                        id: searchField
                                                        anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                                                        verticalAlignment: TextInput.AlignVCenter
                                                        maximumLength: 128
                                                        font { family: "Monocraft"; pixelSize: 13 }
                                                        color: "#cdd6f4"
                                                        cursorVisible: true
                                                        cursorDelegate: Rectangle {
                                                                width: 2
                                                                color: "#89b4fa"
                                                        }
                                                        onTextChanged: {
                                                                root.query = searchField.text
                                                                if (root.mode === "apps") {
                                                                        updateAppDisplay()
                                                                } else if (root.mode === "clip") {
                                                                        updateClipDisplay()
                                                                } else if (root.mode === "emoji") {
                                                                        updateEmojiDisplay()
                                                                } else if (root.mode === "windows") {
                                                                        updateWindowsDisplay()
                                                                }
                                                        }
                                                        Keys.onReturnPressed: function(event) {
                                                                if (root.mode === "cmd") {
                                                                        var cmd = searchField.text.trim()
                                                                        if (cmd) {
                                                                                runCmdProcess.cmd = cmd
                                                                                runCmdProcess.command = ["sh", "-c", cmd]
                                                                                runCmdProcess.running = true
                                                                                root.popupOpen = false
                                                                        }
                                                                } else if (root.isWinList && root.copiedIndex >= 0 && root.copiedIndex < root.displayItems.length) {
                                                                        activateItem(root.displayItems[root.copiedIndex])
                                                                        event.accepted = true
                                                                }
                                                        }
                                                        Keys.onEscapePressed: function(event) {
                                                                if (root.menuOpen) root.menuOpen = false
                                                                else if (root.categoryPopupOpen) {
                                                                        root.categoryPopupOpen = false
                                                                        root.categoryPopupClosing = true
                                                                        categoryCloseTimer.start()
                                                                        searchField.forceActiveFocus()
                                                                } else root.popupOpen = false
                                                                event.accepted = true
                                                        }
                                                }
                                                Text {
                                                        visible: searchField.text === ""
                                                        anchors { left: searchField.left; verticalCenter: parent.verticalCenter }
                                                        text: root.mode === "apps" ? Translation.tr("launcher.search.apps") :
                                                              (root.mode === "clip" ? Translation.tr("launcher.search.clip") :
                                                              (root.mode === "emoji" ? Translation.tr("launcher.search.emoji") :
                                                              (root.mode === "windows" ? Translation.tr("launcher.search.windows") : Translation.tr("launcher.search.cmd"))))
                                                        color: "#585b70"
                                                        font { family: "Monocraft"; pixelSize: 13 }
                                                }
                                                MD3.Pressable {
                                                        id: searchBoxMouseArea
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: Qt.IBeamCursor
                                                        onClicked: {
                                                                searchField.forceActiveFocus()
                                                        }
                                                }
                                        }
                                }
                                Rectangle {
                                        id: categoryPopup
                                        visible: root.categoryPopupOpen || root.categoryPopupClosing
                                        z: 10
                                        anchors {
                                                top: searchRow.bottom
                                                topMargin: 4
                                                right: categoryButton.right
                                        }
                                        width: 160
                                        height: categoryPopupColumn.height + 8
                                        radius: 10
                                        color: "#1e1e2e"
                                        border { color: "#45475a"; width: 1 }
                                        clip: true
                                        opacity: root.categoryPopupOpen ? 1 : 0
                                        scale: root.categoryPopupOpen ? 1 : 0.95
                                        transformOrigin: Item.Top
                                        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
                                        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
                                        Item {
                                                id: categoryCapsuleContainer
                                                anchors.fill: parent
                                                clip: true
                                                Rectangle {
                                                        id: categoryCapsule
                                                        anchors { left: parent.left; right: parent.right; leftMargin: 2; rightMargin: 2 }
                                                        height: 30
                                                        radius: 6
                                                        color: "#89b4fa"
                                                        opacity: 0.15
                                                        y: {
                                                                var index = root.categoryHoveredIndex
                                                                if (index === -1) {
                                                                        for (var i = 0; i < root.emojiCategories.length; i++) {
                                                                                if (root.emojiCategories[i].key === root.emojiCategory) {
                                                                                        index = i
                                                                                        break
                                                                                }
                                                                        }
                                                                        if (index === -1) index = 0
                                                                }
                                                                return 4 + index * 32
                                                        }
                                                        Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
                                                }
                                        }
                                        Column {
                                                id: categoryPopupColumn
                                                anchors { top: parent.top; left: parent.left; right: parent.right; margins: 4 }
                                                spacing: 2
                                                Repeater {
                                                        model: root.emojiCategories
                                                        delegate: Item {
                                                                width: parent.width
                                                                height: 30
                                                                Row {
                                                                        spacing: 8
                                                                        anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
                                                                        Text {
                                                                                text: modelData.icon
                                                                                color: root.emojiCategory === modelData.key ? "#89b4fa" : "#585b70"
                                                                                font.pixelSize: 14
                                                                                width: 20
                                                                        }
                                                                        Text {
                                                                                text: Translation.tr("launcher.category." + modelData.key)
                                                                                color: root.emojiCategory === modelData.key ? "#cdd6f4" : "#585b70"
                                                                                font { family: "Monocraft"; pixelSize: 12 }
                                                                        }
                                                                }
                                                                MD3.Pressable {
                                                                        anchors.fill: parent
                                                                        hoverEnabled: true
                                                                        cursorShape: Qt.PointingHandCursor
                                                                        onEntered: {
                                                                                root.categoryHoveredIndex = index
                                                                        }
                                                                        onExited: {
                                                                                root.categoryHoveredIndex = -1
                                                                        }
                                                                        onClicked: {
                                                                                selectEmojiCategory(modelData.key)
                                                                                searchField.forceActiveFocus()
                                                                        }
                                                                }
                                                        }
                                                }
                                        }
                                }
                                Rectangle {
                                        id: modeMenu
                                        visible: root.menuOpen || root.menuClosing
                                        z: 10
                                        anchors { top: searchRow.bottom; topMargin: 4; left: searchRow.left }
                                        width: 160
                                        height: modeMenuColumn.height + 8
                                        radius: 10
                                        color: "#1e1e2e"
                                        border { color: "#45475a"; width: 1 }
                                        clip: true
                                        opacity: root.menuOpen ? 1 : 0
                                        scale: root.menuOpen ? 1 : 0.95
                                        transformOrigin: Item.Top
                                        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
                                        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
                                        Item {
                                                id: capsuleContainer
                                                anchors.fill: parent
                                                clip: true
                                                Rectangle {
                                                        id: capsule
                                                        anchors { left: parent.left; right: parent.right; leftMargin: 2; rightMargin: 2 }
                                                        height: 30
                                                        radius: 6
                                                        color: "#89b4fa"
                                                        opacity: 0.15
                                                        y: {
                                                                var index = root.hoveredIndex
                                                                if (index === -1) {
                                                                        if (root.mode === "apps") index = 0
                                                                        else if (root.mode === "clip") index = 1
                                                                        else if (root.mode === "emoji") index = 2
                                                                        else if (root.mode === "windows") index = 3
                                                                        else if (root.mode === "cmd") index = 4
                                                                }
                                                                return 4 + index * 32
                                                        }
                                                        Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
                                                }
                                        }
                                        Column {
                                                id: modeMenuColumn
                                                anchors { top: parent.top; left: parent.left; right: parent.right; margins: 4 }
                                                spacing: 2
                                                Repeater {
model: [
                                                { key: "apps", label: "launcher.menu.apps", glyph: "\uf40e" },
                                                { key: "clip", label: "launcher.title.clip", glyph: "\uf07f" },
                                                { key: "emoji", label: "launcher.title.emoji", glyph: "\uefa8" },
                                                { key: "windows", label: "launcher.title.windows", glyph: "\uf2d0" },
                                                { key: "cmd", label: "launcher.menu.cmd", glyph: "❯_" }
                                        ]
                                                        delegate: Item {
                                                                width: parent.width
                                                                height: 30
                                                                Row {
                                                                        spacing: 8
                                                                        anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
                                                                        Text {
                                                                                text: modelData.glyph
                                                                                color: root.mode === modelData.key ? "#89b4fa" : "#585b70"
                                                                                font { family: "Monocraft"; pixelSize: 12 }
                                                                                width: 16
                                                                        }
                                                                        Text {
                                                                                text: Translation.tr(modelData.label)
                                                                                color: root.mode === modelData.key ? "#cdd6f4" : "#585b70"
                                                                                font { family: "Monocraft"; pixelSize: 12 }
                                                                        }
                                                                }
                                                                MD3.Pressable {
                                                                        id: itemArea
                                                                        anchors.fill: parent
                                                                        hoverEnabled: true
                                                                        cursorShape: Qt.PointingHandCursor
                                                                        onEntered: { root.hoveredIndex = index }
                                                                        onExited: { root.hoveredIndex = -1 }
                                                                        onClicked: {
                                                                                if (root.menuOpen) { root.menuClosing = true; menuCloseTimer.start() }
                                                                                selectMode(modelData.key)
                                                                                searchField.forceActiveFocus()
                                                                        }
                                                                }
                                                        }
                                                }
                                        }
                                }
                                Rectangle {
                                        anchors { top: searchRow.bottom; topMargin: 8; left: parent.left; right: parent.right }
                                        height: 1
                                        color: "#45475a"
                                }
                                Text {
                                        visible: root.mode === "cmd"
                                        anchors { top: searchRow.bottom; topMargin: 16; left: parent.left; right: parent.right }
                                        horizontalAlignment: Text.AlignHCenter
                                                text: Translation.tr("launcher.cmd.hint")
                                        color: "#585b70"
                                        font { family: "Monocraft"; pixelSize: 12 }
                                }
                                Text {
                                        visible: root.mode === "clip" && root.displayItems.length === 0
                                        anchors { top: searchRow.bottom; topMargin: 16; left: parent.left; right: parent.right }
                                        horizontalAlignment: Text.AlignHCenter
                                        text: Translation.tr("launcher.clip.empty")
                                        color: "#585b70"
                                        font { family: "Monocraft"; pixelSize: 12 }
                                }
                                Text {
                                        visible: root.mode === "emoji" && root.displayItems.length === 0 && root.emojiLoaded && !root.query
                                        anchors { top: searchRow.bottom; topMargin: 16; left: parent.left; right: parent.right }
                                        horizontalAlignment: Text.AlignHCenter
                                        text: Translation.tr("launcher.emoji.emptyCat")
                                        color: "#585b70"
                                        font { family: "Monocraft"; pixelSize: 12 }
                                }
                                Text {
                                        visible: root.mode === "emoji" && root.displayItems.length === 0 && root.emojiLoaded && root.query
                                        anchors { top: searchRow.bottom; topMargin: 16; left: parent.left; right: parent.right }
                                        horizontalAlignment: Text.AlignHCenter
                                        text: Translation.tr("launcher.emoji.notFound")
                                        color: "#585b70"
                                        font { family: "Monocraft"; pixelSize: 12 }
                                }
                                Text {
                                        visible: root.mode === "emoji" && root.displayItems.length > 0 && root.displayItems[0].type === "loading"
                                        anchors { top: searchRow.bottom; topMargin: 16; left: parent.left; right: parent.right }
                                        horizontalAlignment: Text.AlignHCenter
                                        text: Translation.tr("launcher.loading.emoji")
                                        color: "#585b70"
                                        font { family: "Monocraft"; pixelSize: 12 }
                                }
                                Text {
                                        visible: root.mode === "windows" && root.displayItems.length === 0 && root.windowsLoaded && !root.query
                                        anchors { top: searchRow.bottom; topMargin: 16; left: parent.left; right: parent.right }
                                        horizontalAlignment: Text.AlignHCenter
                                        text: Translation.tr("launcher.windows.empty")
                                        color: "#585b70"
                                        font { family: "Monocraft"; pixelSize: 12 }
                                }
                                Text {
                                        visible: root.mode === "windows" && root.displayItems.length === 0 && root.windowsLoaded && root.query
                                        anchors { top: searchRow.bottom; topMargin: 16; left: parent.left; right: parent.right }
                                        horizontalAlignment: Text.AlignHCenter
                                        text: Translation.tr("launcher.windows.notFound")
                                        color: "#585b70"
                                        font { family: "Monocraft"; pixelSize: 12 }
                                }
                                Item {
                                        id: listContainer
                                        visible: root.mode !== "cmd"
                                        anchors {
                                                top: searchRow.bottom
                                                topMargin: 17
                                                left: parent.left
                                                right: parent.right
                                                bottom: parent.bottom
                                        }
                                        clip: true
                                        Flickable {
                                                id: listFlickable
                                                anchors.fill: parent
                                                contentHeight: listColumn.height
                                                clip: true
                                                boundsBehavior: Flickable.StopAtBounds
                                                ScrollBar.vertical: ScrollBar {
                                                        id: vbar
                                                        width: 10
                                                        policy: ScrollBar.AlwaysOn
                                                        anchors { right: parent.right; rightMargin: 2 }
                                                        opacity: 1
                                                        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
                                                        contentItem: Rectangle {
                                                                implicitWidth: 10
                                                                radius: 5
                                                                color: "#89b4fa"
                                                                border { color: "#89b4fa"; width: 1 }
                                                        }
                                                        background: Rectangle {
                                                                implicitWidth: 10
                                                                radius: 5
                                                                color: "#313244"
                                                        }
                                                }
                                                Rectangle {
                                                        id: listCapsule
                                                        x: 2
                                                        width: parent.width - 16
                                                        height: 48
                                                        radius: 8
                                                        color: "#45475a"
                                                        opacity: 0
                                                        y: {
                                                                var index = root.listHoveredIndex
                                                                if (index === -1) {
                                                                        index = root.copiedIndex
                                                                }
                                                                if (index < 0) index = 0
                                                                return index * 52
                                                        }
                                                        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
                                                        Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
                                                }
                                                Column {
                                                        id: listColumn
                                                        width: parent.width - 16
                                                        spacing: 4
                                                        Repeater {
                                                                model: root.displayItems
                                                                delegate: Rectangle {
                                                                        id: itemDelegate
                                                                        height: 48
                                                                        width: listColumn.width
                                                                        radius: 8
                                                                        color: "transparent"
                                                                        border {
                                                                                color: root.listHoveredIndex === index ? "#89b4fa" : "#45475a"
                                                                                width: root.listHoveredIndex === index ? 2 : 1
                                                                        }
                                                                        Behavior on border.color {
                                                                                ColorAnimation { duration: 150 }
                                                                        }
                                                                        MD3.Pressable {
                                                                                id: itemMouseArea
                                                                                anchors.fill: parent
                                                                                hoverEnabled: true
                                                                                cursorShape: Qt.PointingHandCursor
                                                                                propagateComposedEvents: true
                                                                                onClicked: {
                                                                                        if (modelData.type !== "loading") {
                                                                                                activateItem(modelData)
                                                                                        }
                                                                                        searchField.forceActiveFocus()
                                                                                }
                                                                                onEntered: {
                                                                                        if (vbar && vbar.pressed) return
                                                                                        if (modelData.type !== "loading") {
                                                                                                root.copiedIndex = index
                                                                                                root.listHoveredIndex = index
                                                                                                listCapsule.opacity = 0.5
                                                                                        }
                                                                                }
                                                                                onExited: {
                                                                                        root.listHoveredIndex = -1
                                                                                        listCapsule.opacity = 0
                                                                                }
                                                                        }
                                                                        states: [
                                                                                State {
                                                                                        name: "pressed"
                                                                                        when: itemMouseArea.pressed
                                                                                        PropertyChanges {
                                                                                                target: itemDelegate
                                                                                                scale: 0.98
                                                                                        }
                                                                                }
                                                                        ]
                                                                        transitions: [
                                                                                Transition {
                                                                                        from: ""
                                                                                        to: "pressed"
                                                                                        NumberAnimation {
                                                                                                property: "scale"
                                                                                                duration: 100
                                                                                                easing.type: Easing.OutQuad
                                                                                        }
                                                                                },
                                                                                Transition {
                                                                                        from: "pressed"
                                                                                        to: ""
                                                                                        NumberAnimation {
                                                                                                property: "scale"
                                                                                                duration: 100
                                                                                                easing.type: Easing.OutQuad
                                                                                        }
                                                                                }
                                                                        ]
                                                                        Row {
                                                                                spacing: 10
                                                                                anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 12; right: parent.right; rightMargin: 12 }
                                                                                Item {
                                                                                        width: 28
                                                                                        height: 28
                                                                                        anchors.verticalCenter: parent.verticalCenter
                                                                                        visible: modelData.type === "app" || modelData.type === "window"
                                                                                        IconImage {
                                                                                                id: itemIcon
                                                                                                width: 28
                                                                                                height: 28
                                                                                                anchors.centerIn: parent
                                                                                                source: {
                                                                                                        if (modelData.type === "app") {
                                                                                                                return Quickshell.iconPath(modelData.icon, true)
                                                                                                        } else if (modelData.type === "window") {
                                                                                                                if (modelData.icon) {
                                                                                                                        var iconPath = Quickshell.iconPath(modelData.icon, true)
                                                                                                                        if (iconPath) return iconPath
                                                                                                                }
                                                                                                                return ""
                                                                                                        }
                                                                                                        return ""
                                                                                                }
                                                                                        }
                                                                                        Rectangle {
                                                                                                anchors.fill: parent
                                                                                                radius: 4
                                                                                                color: "#313244"
                                                                                                border { color: "#45475a"; width: 1 }
                                                                                                visible: {
                                                                                                        if (modelData.type === "window") {
                                                                                                                return !itemIcon.source || itemIcon.source === ""
                                                                                                        }
                                                                                                        return false
                                                                                                }
                                                                                                Text {
                                                                                                        anchors.centerIn: parent
                                                                                                        text: ""
                                                                                                        font { family: "Monocraft"; pixelSize: 16 }
                                                                                                        color: "#585b70"
                                                                                                }
                                                                                        }
                                                                                }
                                                                                Text {
                                                                                        visible: modelData.type === "emoji"
                                                                                        text: modelData.emojiChar || "😊"
                                                                                        font.pixelSize: 28
                                                                                        anchors.verticalCenter: parent.verticalCenter
                                                                                        width: 28
                                                                                        height: 28
                                                                                        horizontalAlignment: Text.AlignHCenter
                                                                                        verticalAlignment: Text.AlignVCenter
                                                                                }
                                                                                Rectangle {
                                                                                        visible: modelData.type === "clip" && root.isHexColor(modelData.name)
                                                                                        width: 20
                                                                                        height: 20
                                                                                        radius: 5
                                                                                        color: modelData.type === "clip" ? modelData.name.trim() : "transparent"
                                                                                        border { color: "#45475a"; width: 1 }
                                                                                        anchors.verticalCenter: parent.verticalCenter
                                                                                }
                                                                                Text {
                                                                                        visible: modelData.type === "clip" && !root.isHexColor(modelData.name) && root.isFilePath(modelData.name)
                                                                                        text: "\uf15b"
                                                                                        width: 20
                                                                                        height: 20
                                                                                        horizontalAlignment: Text.AlignHCenter
                                                                                        verticalAlignment: Text.AlignVCenter
                                                                                        font { family: "Monocraft"; pixelSize: 18 }
                                                                                        color: "#89b4fa"
                                                                                        anchors.verticalCenter: parent.verticalCenter
                                                                                }
                                                                                Text {
                                                                                        visible: modelData.type === "clip" && !root.isHexColor(modelData.name) && !root.isFilePath(modelData.name)
                                                                                        text: "\uf07f"
                                                                                        width: 20
                                                                                        height: 20
                                                                                        horizontalAlignment: Text.AlignHCenter
                                                                                        verticalAlignment: Text.AlignVCenter
                                                                                        font { family: "Monocraft"; pixelSize: 18 }
                                                                                        color: "#89b4fa"
                                                                                        anchors.verticalCenter: parent.verticalCenter
                                                                                }
                                                                                Rectangle {
                                                                                        visible: modelData.type === "window"
                                                                                        width: 6
                                                                                        height: 6
                                                                                        radius: 3
                                                                                        color: modelData.isFocused ? "#89b4fa" : "#45475a"
                                                                                        anchors.verticalCenter: parent.verticalCenter
                                                                                        Rectangle {
                                                                                                visible: modelData.isFocused
                                                                                                anchors.centerIn: parent
                                                                                                width: 10
                                                                                                height: 10
                                                                                                radius: 5
                                                                                                color: "transparent"
                                                                                                border { color: "#89b4fa"; width: 1 }
                                                                                                opacity: 0.3
                                                                                        }
                                                                                }
                                                                                Column {
                                                                                        anchors.verticalCenter: parent.verticalCenter
                                                                                        Text {
                                                                                                text: modelData.type === "emoji" ? (modelData.emojiData ? modelData.emojiData.name || "Unnamed" : "Unnamed") :
                                                                                                      (modelData.type === "loading" ? Translation.tr("launcher.loading.generic") : (modelData.name || "Unnamed"))
                                                                                                font { family: "Monocraft"; pixelSize: 13 }
                                                                                                color: modelData.type === "loading" ? "#585b70" : "#cdd6f4"
                                                                                                maximumLineCount: 1
                                                                                                elide: Text.ElideRight
                                                                                                width: listColumn.width - (modelData.type === "emoji" ? 60 : (modelData.type === "window" ? 70 : 50))
                                                                                        }
                                                                                        Text {
                                                                                                visible: modelData.type === "window"
                                                                                                text: modelData.appId || ""
                                                                                                font { family: "Monocraft"; pixelSize: 10 }
                                                                                                color: "#585b70"
                                                                                                maximumLineCount: 1
                                                                                                elide: Text.ElideRight
                                                                                                width: listColumn.width - 70
                                                                                        }
                                                                                }
                                                                        }
                                                                }
                                                        }
                                                }
                                        }
                                }
                        }
                }
        }
        Component.onCompleted: {
                usageFile.reload()
                emojiFile.reload()
                WM.refreshWindows()
        }
}
