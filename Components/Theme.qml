pragma Singleton
import QtQuick

QtObject {
    // Catppuccin Mocha Blue mapped to Material 3-style semantic roles.
    readonly property color primary: "#89b4fa"
    readonly property color primaryContent: "#1e1e2e"
    readonly property color primaryContainer: "#313244"
    readonly property color primaryContainerContent: "#cdd6f4"

    readonly property color secondary: "#b4befe"
    readonly property color secondaryContent: "#1e1e2e"
    readonly property color secondaryContainer: "#45475a"
    readonly property color secondaryContainerContent: "#cdd6f4"

    readonly property color surface: "#1e1e2e"
    readonly property color surfaceContainer: "#313244"
    readonly property color surfaceContainerHigh: "#45475a"
    readonly property color surfaceContainerHighest: "#585b70"
    readonly property color surfaceContent: "#cdd6f4"
    readonly property color surfaceVariantContent: "#a6adc8"
    readonly property color outline: "#6c7086"
    readonly property color outlineVariant: "#45475a"

    readonly property color error: "#f38ba8"
    readonly property color errorContent: "#1e1e2e"
    readonly property color success: "#a6e3a1"

    readonly property int barHeight: 40
    readonly property int compactHeight: 36
    readonly property int barRadius: 20
    readonly property int popupRadius: 16
    readonly property int controlRadius: 12
    readonly property int stateLayer: 10
}
