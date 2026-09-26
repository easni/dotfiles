import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import "../styles"
import "../components"
import "../core"
import "../views"
import "../services"

Item {
    id: root

    clip: true
    
    property real availableWidth: 520
    property real availableHeight: 530
    implicitWidth: Math.min(520, availableWidth)
    implicitHeight: Math.min(530, availableHeight)

    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 22
        height: 28
        Text {
            text: "Control Center"
            color: Theme.textPrimary
            font.pixelSize: 20
            font.bold: true
            Layout.fillWidth: true
        }
        NotificationButton {
            text: "×"
            subtle: true
            Accessible.name: "Close control center"
            onClicked: IslandController.reset()
        }
    }

    Flickable {
        id: scroll
        anchors.fill: parent
        anchors.margins: 22
        anchors.topMargin: 68
        clip: true
        contentWidth: width
        contentHeight: content.height
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        ColumnLayout {
            id: content
            width: scroll.width
            height: Math.max(scroll.height, controlGrid.implicitHeight + 264)
            spacing: 18

            GridLayout {
                id: controlGrid
                Layout.fillWidth: true

                columns: root.width < 330 ? 1 : root.width < 500 ? 2 : 3

                columnSpacing: 12
                rowSpacing: 12

                ControlCard {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0

                    iconSource: WifiService.svgIcon

                    title: "Wi-Fi"

                    subtitle: WifiService.subtitle

                    active: WifiService.displayEnabled
                    enabled: WifiService.available && !WifiService.busy

                    onClicked: WifiService.toggle()
                }

                ControlCard {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0

                    iconSource: BluetoothService.icon

                    title: "Bluetooth"

                    subtitle: BluetoothService.subtitle

                    active: BluetoothService.enabled

                    onClicked: IslandController.openBluetooth()
                }

                ControlCard {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0

                    iconSource: MicrophoneService.icon

                    title: "Microphone"

                    subtitle: MicrophoneService.subtitle

                    active: !MicrophoneService.muted

                    onClicked: MicrophoneService.toggle()
                }

                ControlCard {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0

                    iconSource: NightLightService.icon

                    title: "Night Light"

                    subtitle: NightLightService.subtitle

                    active: NightLightService.enabled

                    onClicked: NightLightService.toggle()
                }

                ControlCard {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0

                    iconSource: FocusService.icon

                    title: "Focus"

                    subtitle: FocusService.subtitle

                    active: FocusService.enabled

                    onClicked: FocusService.toggle()
                }

                ControlCard {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    iconSource: MediaService.icon

                    title: "Media"

                    subtitle: MediaService.subtitle

                    active: MediaService.hasPlayer

                    onClicked: {
                        IslandController.openMediaControls()
                    }
                }
            }

            ControlSlider {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                label: "Volume"
                iconSource: AudioService.volumeIcon

                value: AudioService.volume / 100

                onValueChangedByUser: function(value) {

                    AudioService.setVolume(
                        value * 100
                    )
                }
            }

            ControlSlider {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                label: "Brightness"
                iconSource: BrightnessService.brightnessIcon

                value: BrightnessService.brightness / 100

                onValueChangedByUser: function(value) {

                    BrightnessService.setBrightness(
                        value * 100
                    )
                }
            }

            Rectangle {

                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 140

                radius: 14

                color: Theme.surface

                clip: true

                NotificationView {
                    anchors.fill: parent
                    anchors.margins: 14
                }
            }
        }
    }
}
