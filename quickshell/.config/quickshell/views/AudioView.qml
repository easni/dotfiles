import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"
import "../services"
import "../core"
import "../styles"

FocusScope {
    id: root
    property var islandContext: IslandRegistry.contextFor(parent)
    required property real availableWidth
    required property real availableHeight
    implicitWidth: Math.min(520, availableWidth)
    implicitHeight: Math.min(layout.implicitHeight + 40, availableHeight)
    focus: true
    Component.onCompleted: { forceActiveFocus(); AudioRouting.refresh() }
    Keys.forwardTo: [escapeKey]
    EscapeKeyHandler {
        id: escapeKey
        onTriggered: root.islandContext.navigation.closeDevicePage()
    }

    ColumnLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: 20
        spacing: 12
        RowLayout {
            NotificationButton {
                text: "‹"
                Accessible.name: "Back to Control Center"
                onClicked: root.islandContext.navigation.closeDevicePage()
            }
            Text {
                text: "Audio"
                Layout.fillWidth: true
                color: Theme.textPrimary
                font.pixelSize: 18
                font.weight: Font.DemiBold
            }
            NotificationButton {
                text: "×"
                Accessible.name: "Close audio settings"
                onClicked: root.islandContext.navigation.reset()
            }
        }
        Flickable {
            id: scroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            implicitHeight: sections.implicitHeight
            contentWidth: width
            contentHeight: sections.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar {}
            ColumnLayout {
                id: sections
                width: scroll.width
                spacing: 10
                DeviceSection { output: true }
                DeviceSection { output: false }
                Text {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: AudioRouting.error || AudioRouting.readError
                    color: Theme.warning
                    wrapMode: Text.Wrap
                }
            }
        }
    }

    component DeviceSection: ColumnLayout {
        id: section
        required property bool output
        readonly property var devices: output ? AudioRouting.outputs : AudioRouting.inputs
        readonly property string current: output ? AudioRouting.inventory.default_sink : AudioRouting.inventory.default_source
        readonly property var control: output ? AudioService : MicrophoneService
        Layout.fillWidth: true
        spacing: 8
        RowLayout {
            Text {
                Layout.fillWidth: true
                text: section.output ? "Output" : "Input"
                font.pixelSize: 14
                color: Theme.textPrimary
                font.weight: Font.DemiBold
            }
            Text {
                text: section.control.volume + "%"
                font.pixelSize: 12
                color: Theme.textSecondary
            }
            NotificationButton {
                text: section.control.muted ? "Unmute" : "Mute"
                enabled: !!section.current && !AudioRouting.busy
                Accessible.name: text + (section.output ? " output" : " microphone")
                onClicked: section.control.toggleMute()
            }
        }
        ControlSlider {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            enabled: !!section.current && !AudioRouting.busy
            label: section.output ? "Output volume" : "Microphone level"
            iconSource: section.output ? AudioService.volumeIcon : MicrophoneService.icon
            value: section.control.volume / 100
            onValueChangedByUser: value => section.control.setVolume(value * 100)
        }
        Repeater {
            model: section.devices
            delegate: NotificationButton {
                required property var modelData
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                enabled: !AudioRouting.busy
                text: (section.current === modelData.name ? "✓  " : "") + (modelData.description)
                onClicked: AudioRouting.select(section.output, modelData.name)
            }
        }
        Text {
            visible: !section.devices.length
            text: section.output ? "No outputs available" : "No inputs available"
            color: Theme.textSecondary
        }
    }
}
