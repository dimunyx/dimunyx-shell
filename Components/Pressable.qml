import QtQuick

MouseArea {
    id: root

    // Shared Material 3 interaction layer for every clickable shell control.
    hoverEnabled: false

    // Press feedback is intentionally geometry-only: no background or state layer.
    transform: Scale {
        origin.x: root.width / 2
        origin.y: root.height / 2
        xScale: root.pressed ? 0.96 : 1
        yScale: root.pressed ? 0.96 : 1
    }
}
