import QtQuick
import QtQuick.Controls
import "../styles"

Button {
    id: root
    property string symbol: ""
    property string hint: ""
    implicitWidth: 32
    implicitHeight: 32
    hoverEnabled: true
    HoverHandler { cursorShape: Qt.PointingHandCursor }
    Accessible.name: hint
    ToolTip.visible: hovered
    ToolTip.text: hint
    ToolTip.delay: 500
    contentItem: Text {
        text: root.symbol
        font.family: Theme.iconFont
        font.pixelSize: 18
        color: root.enabled ? Theme.textPrimary : Theme.textMuted
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
    background: Rectangle {
        radius: Theme.radiusSmall
        color: root.down ? Theme.buttonPressed : root.hovered ? Theme.buttonHover : "transparent"
    }
}
