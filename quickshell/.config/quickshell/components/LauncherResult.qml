import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "../styles"

ItemDelegate {
    id: root
    required property var entry
    property bool selected: false
    property bool clipboard: false
    implicitHeight: 52
    leftPadding: 12
    rightPadding: 12
    hoverEnabled: true
    focusPolicy: Qt.NoFocus
    background: Rectangle {
        radius: Theme.radiusMedium
        color: root.selected ? Theme.surfaceVariant : root.hovered ? Theme.surface : "transparent"
        border.width: root.selected ? 1 : 0
        border.color: Theme.accent
    }
    contentItem: RowLayout {
        spacing: 12
        Rectangle {
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32
            radius: 9
            color: Theme.surface
            Image {
                id: appIcon
                anchors.fill: parent
                anchors.margins: 3
                source: !root.entry.icon ? "" : root.entry.icon.startsWith("/") || root.entry.icon.includes(":/")
                    ? root.entry.icon : Quickshell.iconPath(root.entry.icon, true)
                fillMode: Image.PreserveAspectFit
                visible: status === Image.Ready
            }
            Text {
                anchors.centerIn: parent
                visible: !appIcon.visible
                text: root.clipboard ? "󰅍" : root.entry.name.slice(0, 1).toUpperCase()
                font.family: root.clipboard ? Theme.iconFont : ""
                font.pixelSize: root.clipboard ? 17 : 14
                font.weight: Font.Medium
                color: Theme.accent
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3
            Text {
                Layout.fillWidth: true
                visible: !root.clipboard
                text: root.entry.name
                textFormat: Text.PlainText
                font.pixelSize: 13
                font.weight: Font.DemiBold
                color: Theme.textPrimary
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                text: root.entry.description || (root.clipboard ? "Empty text" : root.entry.genericName || root.entry.id)
                textFormat: Text.PlainText
                font.pixelSize: root.clipboard ? 13 : 11
                color: root.clipboard ? Theme.textPrimary : Theme.textSecondary
                wrapMode: root.clipboard ? Text.Wrap : Text.NoWrap
                maximumLineCount: root.clipboard ? 2 : 1
                elide: Text.ElideRight
            }
        }
        Text {
            visible: root.selected
            text: "↵"
            font.pixelSize: 16
            color: Theme.textMuted
        }
    }
    HoverHandler { cursorShape: Qt.PointingHandCursor }
}
