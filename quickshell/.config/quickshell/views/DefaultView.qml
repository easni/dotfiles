import QtQuick
import "../views"
import "../services"
import "../components"

Item {
    // Add the badge to the normal capsule width instead of consuming its padding.
    implicitWidth: Math.max(160, clockGroup.implicitWidth + 28)
        + (unreadBadge.visible ? unreadBadge.implicitWidth + row.spacing : 0)
    implicitHeight: 33

    Row {
        id: row
        objectName: "compactContent"
        spacing: 8
        anchors.centerIn: parent

        Row {
            id: clockGroup
            spacing: 8
            anchors.verticalCenter: parent.verticalCenter

            Cava {
                visible: MediaService.hasPlayer
                anchors.verticalCenter: parent.verticalCenter
            }

            ClockView { anchors.verticalCenter: parent.verticalCenter }
        }

        NotificationBadge {
            id: unreadBadge
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
