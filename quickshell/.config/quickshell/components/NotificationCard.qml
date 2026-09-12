pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../services"
import "../styles"

Rectangle {
    id: root
    required property var entry
    property bool preview: false
    property int moreUnread: 0
    signal openRequested()
    signal readRequested()
    signal dismissRequested()
    signal actionRequested(string identifier)

    implicitHeight: content.implicitHeight + 32
    radius: Theme.radiusLarge
    color: preview ? "transparent" : entry && entry.unread ? Theme.notificationUnread : Theme.notificationBackground
    border.width: !preview && entry && entry.unread ? 1 : 0
    border.color: Theme.accent

    MouseArea {
        objectName: "notificationBody"
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.preview || (root.entry && root.entry.unread)
            ? Qt.PointingHandCursor : Qt.ArrowCursor
        // Read cards still consume clicks so they cannot pin the island below.
        onClicked: {
            if (root.preview) root.openRequested()
            else if (root.entry && root.entry.unread) root.readRequested()
        }
    }

    ColumnLayout {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 16
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Rectangle {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                radius: 10
                color: Theme.surfaceVariant
                Image {
                    id: appIcon
                    anchors.fill: parent
                    anchors.margins: 6
                    source: root.entry ? root.entry.icon : ""
                    fillMode: Image.PreserveAspectFit
                    visible: status === Image.Ready && source.toString() !== NotificationService.defaultIcon.toString()
                }
                Text {
                    anchors.centerIn: parent
                    text: "󰂚"
                    font.family: Theme.iconFont
                    font.pixelSize: 18
                    color: Theme.icon
                    visible: !appIcon.visible
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text {
                    Layout.fillWidth: true
                    text: root.entry ? root.entry.app : ""
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    color: root.entry && root.entry.critical ? Theme.warning : Theme.textSecondary
                }
                Text {
                    Layout.fillWidth: true
                    text: root.preview ? "NOW" : root.entry ? root.entry.time : ""
                    textFormat: Text.PlainText
                    font.pixelSize: 10
                    font.letterSpacing: root.preview ? 1 : 0
                    color: Theme.textMuted
                }
            }
            Text {
                visible: root.preview && root.moreUnread > 0
                text: "+" + root.moreUnread + " more"
                font.pixelSize: 11
                color: Theme.textMuted
            }
            NotificationButton {
                text: "×"
                subtle: true
                Accessible.name: "Dismiss notification"
                onClicked: root.dismissRequested()
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5
                Text {
                    Layout.fillWidth: true
                    text: root.entry ? root.entry.summary : ""
                    textFormat: Text.PlainText
                    color: Theme.textPrimary
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    wrapMode: Text.Wrap
                    maximumLineCount: root.preview ? 2 : 4
                    elide: Text.ElideRight
                    visible: text.length > 0
                }
                Text {
                    Layout.fillWidth: true
                    text: root.entry ? root.entry.body : ""
                    textFormat: Text.PlainText
                    color: Theme.textSecondary
                    font.pixelSize: 12
                    lineHeight: 1.15
                    wrapMode: Text.Wrap
                    maximumLineCount: root.preview ? 2 : 12
                    elide: Text.ElideRight
                    visible: text.length > 0
                }
            }
            Image {
                Layout.preferredWidth: 48
                Layout.preferredHeight: 48
                source: root.entry ? root.entry.image : ""
                visible: source.toString() !== "" && status === Image.Ready
                fillMode: Image.PreserveAspectFit
            }
        }

        Flow {
            Layout.fillWidth: true
            spacing: 6
            visible: root.entry !== null && root.entry.actions.length > 0
            Repeater {
                model: root.entry ? (root.preview ? root.entry.actions.slice(0, 2) : root.entry.actions) : []
                NotificationButton {
                    required property var modelData
                    text: modelData.text
                    width: Math.min(implicitWidth, content.width)
                    onClicked: root.actionRequested(modelData.identifier)
                }
            }
        }
    }
}
