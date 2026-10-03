import QtQuick

import "../components"
import "../services"

Item {
    implicitWidth: 520
    implicitHeight: 75


    BatteryService {
        id: batteryService
    }

    Row {
        anchors.fill: parent

        anchors.leftMargin: 14
        anchors.rightMargin: 14

        spacing: 0

        LeftSection {
            width: 130

            anchors.verticalCenter: parent.verticalCenter
        }

        Item {
            width: parent.width - 130 - 130
            height: parent.height

            CenterSection {
                expanded: true

                anchors.centerIn: parent
            }
        }

        RightSection {

            width: 130

            anchors.verticalCenter: parent.verticalCenter

            batteryService: batteryService
        }
    }
}
