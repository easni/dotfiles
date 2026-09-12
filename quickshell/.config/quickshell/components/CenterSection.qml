import QtQuick
import "../views"
import "../styles"
import "../components"
import "../services"

Item {
    id: root

    property bool expanded: false

    implicitWidth: row.implicitWidth
    implicitHeight: expanded
        ? column.implicitHeight
        : row.implicitHeight


    Column {
        id: column

        anchors.centerIn: parent

        spacing: Theme.clockSpacing


        Row {
            id: row

            spacing: 8

            anchors.horizontalCenter: parent.horizontalCenter


            Cava {
                visible: MediaService.hasPlayer && !root.expanded
                
                anchors.verticalCenter: parent.verticalCenter
            }


            ClockView {
                id: clock
                objectName: "expandedClock"
                anchors.verticalCenter: parent.verticalCenter
            }

            NotificationBadge {
                visible: root.expanded && NotificationService.unreadCount > 0
                anchors.verticalCenter: parent.verticalCenter
            }
        }


        DateView {
            visible: root.expanded

            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
}
