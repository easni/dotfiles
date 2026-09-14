import QtQuick
import "../views"
import "../services"
import "../components"

Item {
    readonly property real badgeExtraWidth: unreadBadge.visible
        ? unreadBadge.implicitWidth + timeGroup.spacing : 0

    // Add the badge to the normal capsule width instead of consuming its padding.
    implicitWidth: Math.max(MediaService.hasPlayer ? 184 : 160,
        clockGroup.implicitWidth - badgeExtraWidth + (MediaService.hasPlayer ? 18 : 28))
        + badgeExtraWidth
    implicitHeight: 33

    Row {
        id: row
        objectName: "compactContent"
        spacing: 8
        anchors.centerIn: parent

        Row {
            id: clockGroup
            spacing: MediaService.hasPlayer ? 40 : 8
            anchors.verticalCenter: parent.verticalCenter

            AlbumArt {
                width: 22
                height: 22
                radius: 5
                visible: MediaService.hasPlayer
                anchors.verticalCenter: parent.verticalCenter
            }

            Row {
                id: timeGroup
                spacing: 8
                anchors.verticalCenter: parent.verticalCenter

                ClockView { anchors.verticalCenter: parent.verticalCenter }

                NotificationBadge {
                    id: unreadBadge
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Cava {
                visible: MediaService.hasPlayer
                anchors.verticalCenter: parent.verticalCenter
            }
        }

    }
}
