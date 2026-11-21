import QtQuick

Item {
    id: root

    signal triggered()
    property bool pressed: false

    // Keep keyboard focus in the popup until the complete keystroke is consumed.
    enabled: parent.activeFocus
    onEnabledChanged: if (!enabled) pressed = false

    Keys.onEscapePressed: event => {
        event.accepted = true
        if (!event.isAutoRepeat) root.pressed = true
    }
    Keys.onReleased: event => {
        if (event.key !== Qt.Key_Escape) return
        event.accepted = true
        if (event.isAutoRepeat || !root.pressed) return
        root.pressed = false
        root.triggered()
    }
}
