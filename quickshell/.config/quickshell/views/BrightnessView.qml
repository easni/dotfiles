import QtQuick
import QtQuick.Layouts
import "../components"
import "../styles"

DeviceSettingsPage {
    id: root
    title: "Brightness"
    readonly property var display: islandContext.displayBrightness ?? null
    Component.onCompleted: display?.update()
    Timer {
        interval: 10000
        running: !!root.display
        repeat: true
        onTriggered: root.display.update()
    }

    RowLayout {
        Layout.fillWidth: true
        Text {
            Layout.fillWidth: true
            text: root.display?.connector || "Display"
            color: Theme.textPrimary
            font.pixelSize: 14
            font.weight: Font.DemiBold
        }
        Text {
            visible: brightnessSlider.enabled
            text: Math.round(brightnessSlider.displayValue * 100) + "%"
            color: Theme.textSecondary
            font.pixelSize: 12
        }
    }

    ControlSlider {
        id: brightnessSlider
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        label: "Display brightness"
        commitOnRelease: true
        enabled: root.display?.available ?? false
        opacity: enabled ? 1 : 0.45
        iconSource: root.display?.brightnessIcon ?? "../assets/icons/brightness-half.svg"
        value: (root.display?.brightness ?? 0) / 100
        onValueChangedByUser: value => root.display.setBrightness(value * 100)
    }

    Text {
        Layout.fillWidth: true
        visible: text !== ""
        text: root.display?.error ?? ""
        color: Theme.warning
        wrapMode: Text.Wrap
        font.pixelSize: 12
    }
}
