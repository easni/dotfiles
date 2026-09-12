pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../styles"
import "../services"
import "../components"

Item {
    id: root
    // Keep unread messages identifiable throughout this visit to the center.
    Component.onDestruction: NotificationService.markRead()

    ColumnLayout {
        anchors.fill: parent
        spacing: 12
        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "Notifications"
                color: Theme.textPrimary
                font.pixelSize: 16
                font.weight: Font.DemiBold
                Layout.fillWidth: true
            }
            NotificationButton {
                text: "Clear all"
                enabled: NotificationService.history.length > 0
                onClicked: NotificationService.clear()
            }
        }
        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 8
            model: NotificationService.history
            ScrollBar.vertical: ScrollBar { }
            delegate: NotificationCard {
                required property var modelData
                required property int index
                entry: modelData
                width: list.width
                height: implicitHeight
                onReadRequested: NotificationService.markEntryRead(entry.savedId)
                onDismissRequested: NotificationService.remove(index)
                onActionRequested: identifier => NotificationService.invoke(entry.savedId, identifier)
            }
            Text {
                anchors.centerIn: parent
                visible: NotificationService.history.length === 0
                text: "All caught up"
                color: Theme.textMuted
                font.pixelSize: 13
            }
        }
    }
}
