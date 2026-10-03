import QtQuick

import "../styles"

Item {
    id: root

    property string text: ""
    property int maxWidth: 100
    property int fontSize: 13
    property real elapsed: 0

    readonly property bool scrolling: label.width > maxWidth + 12
    readonly property real scrollDuration: scrolling ? (label.width + maxWidth) / 50 * 1000 : 0
    readonly property real textOffset: {
        if (!scrolling || elapsed <= 0 || elapsed >= scrollDuration)
            return 0
        const distance = elapsed * 50 / 1000
        return distance < label.width ? -distance : maxWidth - (distance - label.width)
    }

    signal layoutChanged()
    onTextChanged: layoutChanged()
    onScrollDurationChanged: layoutChanged()

    width: maxWidth
    implicitHeight: label.implicitHeight
    clip: true

    Text {
        id: label
        text: root.text
        color: Theme.textPrimary
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: root.fontSize
        font.bold: true
        anchors.verticalCenter: parent.verticalCenter
        x: root.textOffset
    }
}
