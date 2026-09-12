import QtQuick
import QtQuick.Layouts

import "../styles"
import "../core"

Item {
    id: root

    property bool expandedMode: false

    property int maximum: 100

    implicitWidth: {
        switch (StatusManager.mode) {

        case "workspace":
            return Theme.statusWorkspaceWidth

        case "keyboard":
            return Theme.statusKeyboardWidth

        case "volume":
            return Theme.statusVolumeWidth

        case "brightness":
            return Theme.statusBrightnessWidth

        default:
            return Theme.statusDefaultWidth
        }
    }

    implicitHeight: 33

    RowLayout {
        id: rowLayout

        anchors.fill: parent

        anchors.leftMargin:
            StatusManager.mode === "workspace" ||
            StatusManager.mode === "keyboard"
                ? 35
                : 14

        anchors.rightMargin: 14

        spacing: 10

        Text {
            text: StatusManager.icon

            color: Theme.textPrimary
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 15

            Layout.alignment: Qt.AlignVCenter
        }

        Rectangle {
            visible:
                StatusManager.mode === "volume" ||
                StatusManager.mode === "brightness"

            Layout.fillWidth: visible
            Layout.alignment: Qt.AlignVCenter

            height: 6
            radius: height / 2

            color: Theme.surface

            Rectangle {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter

                height: parent.height

                radius: height / 2

                width: Math.max(
                    0,
                    Math.min(
                        parent.width,
                        parent.width * StatusManager.value / maximum
                    )
                )

                color: Theme.accent

                Behavior on width {
                    NumberAnimation {
                        duration: 180
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }

        Text {
            visible: StatusManager.mode === "workspace"

            text: root.expandedMode
                ? StatusManager.title
                : "Workspace " + StatusManager.title

            color: Theme.textPrimary
            font.pixelSize: 13
            font.weight: Font.Medium

            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            visible: StatusManager.mode === "keyboard"

            text: StatusManager.title

            color: Theme.textPrimary
            font.pixelSize: 16
            font.weight: Font.Medium

            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            visible:
                StatusManager.mode === "volume" ||
                StatusManager.mode === "brightness"

            text: StatusManager.value >= 0
                ? StatusManager.value + "%"
                : "Muted"

            color: Theme.textPrimary
            font.pixelSize: 12
            font.weight: Font.Medium

            Layout.alignment: Qt.AlignVCenter
        }
    }
}