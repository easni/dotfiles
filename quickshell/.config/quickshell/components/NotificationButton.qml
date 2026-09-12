import QtQuick
import QtQuick.Controls
import "../styles"

Button {
    id: root
    property bool subtle: false
    hoverEnabled: true
    implicitHeight: 28
    implicitWidth: Math.max(28, label.implicitWidth + 20)
    padding: 6
    contentItem: Text {
        id: label
        text: root.text
        textFormat: Text.PlainText
        color: root.hovered ? Theme.textPrimary : Theme.textSecondary
        font.pixelSize: 12
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
    background: Rectangle {
        radius: Theme.radiusSmall
        color: root.down ? Theme.buttonPressed : root.hovered ? Theme.buttonHover : root.subtle ? "transparent" : Theme.buttonBackground
        border.width: root.visualFocus ? 1 : 0
        border.color: Theme.accent
    }
    HoverHandler { cursorShape: Qt.PointingHandCursor }
}
