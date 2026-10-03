import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Bluetooth
import "../components"
import "../services"
import "../styles"
import "../core"

FocusScope {
    id: root
    property real availableWidth: 520
    property real availableHeight: 560
    implicitWidth: Math.min(520, availableWidth)
    implicitHeight: Math.min(560, availableHeight)
    focus: true
    Component.onCompleted: forceActiveFocus()
    Keys.onEscapePressed: IslandController.closeBluetooth()

    function symbol(kind) {
        return /keyboard/i.test(kind) ? "󰌌" : /mouse/i.test(kind) ? "󰍽"
            : /audio|headset|headphone|speaker/i.test(kind) ? "󰓃" : "󰂯"
    }
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 12
        RowLayout {
            Layout.fillWidth: true
            NotificationButton {
                text: "‹"
                Accessible.name: "Back to control center"
                onClicked: IslandController.closeBluetooth()
            }
            Text {
                Layout.fillWidth: true
                text: root.width < 380 ? "Devices" : "Bluetooth & Devices"
                font.pixelSize: 18; font.weight: Font.DemiBold
                color: Theme.textPrimary
                elide: Text.ElideRight
            }
            NotificationButton {
                visible: NotificationService.unreadCount > 0
                text: String(NotificationService.unreadCount)
                Accessible.name: "Unread notifications"
                onClicked: IslandController.openNotifications()
            }
            NotificationButton {
                text: "×"
                Accessible.name: "Close devices"
                onClicked: IslandController.reset()
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Text { text: "Bluetooth"; color: Theme.textSecondary; font.pixelSize: 13; Layout.fillWidth: true }
            NotificationButton {
                text: BluetoothService.powerOperation ? "Updating…" : BluetoothService.enabled ? "On" : "Off"
                enabled: BluetoothService.available && !BluetoothService.powerOperation
                Accessible.name: "Toggle Bluetooth power"
                onClicked: BluetoothService.toggle()
            }
            NotificationButton {
                text: DeviceInfoService.loading ? "Loading…" : "Refresh"
                enabled: !DeviceInfoService.loading && !DeviceInfoService.audioLoading
                onClicked: { DeviceInfoService.refresh(); DeviceInfoService.refreshAudio() }
            }
        }
        ComboBox {
            visible: BluetoothService.adapters.length > 1
            Layout.fillWidth: true
            model: BluetoothService.adapters.map(a => a.name)
            currentIndex: BluetoothService.adapterIndex
            onActivated: index => BluetoothService.adapterIndex = index
            Accessible.name: "Bluetooth adapter"
        }
        Text {
            visible: text !== ""
            Layout.fillWidth: true
            text: BluetoothService.powerError
            color: Theme.warning; wrapMode: Text.Wrap; font.pixelSize: 12
        }
        Flickable {
            id: scroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: width
            contentHeight: rows.implicitHeight
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar {}
            ColumnLayout {
                id: rows
                width: scroll.width
                spacing: 10
                Text {
                    Layout.fillWidth: true
                    visible: !BluetoothService.available || !BluetoothService.enabled || BluetoothService.devices.length === 0
                    text: !BluetoothService.available ? "No Bluetooth adapter available."
                        : !BluetoothService.enabled ? "Bluetooth is off. Turn it on to connect devices."
                        : "No saved devices. Pair devices in your Bluetooth settings first."
                    color: Theme.textSecondary; font.pixelSize: 13; wrapMode: Text.Wrap
                }
                Repeater {
                    model: BluetoothService.devices
                    delegate: DeviceRow {
                        required property var modelData
                        readonly property var output: DeviceInfoService.outputFor(modelData.address)
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        Layout.preferredWidth: scroll.width
                        Layout.maximumWidth: scroll.width
                        deviceName: modelData.name || modelData.address
                        symbol: root.symbol(modelData.icon || "")
                        detail: BluetoothService.busy(modelData)
                            ? (modelData.connected ? "Disconnecting…" : "Connecting…")
                            : modelData.blocked ? "Blocked in Bluetooth settings"
                            : modelData.connected ? "Connected" : "Disconnected"
                        batteryText: modelData.connected && modelData.batteryAvailable
                            ? "Battery · " + Math.round(modelData.battery * 100) + "%" : "Battery unavailable"
                        lowBattery: modelData.connected && modelData.batteryAvailable && modelData.battery <= 0.2
                        error: BluetoothService.deviceError(modelData)
                        actions: [
                            NotificationButton {
                                text: BluetoothService.busy(modelData) ? "Please wait…" : modelData.connected ? "Disconnect" : "Connect"
                                enabled: !BluetoothService.busy(modelData) && !!modelData.adapter && modelData.adapter.enabled && !modelData.blocked
                                onClicked: BluetoothService.toggleDevice(modelData)
                            },
                            NotificationButton {
                                visible: modelData.connected && output !== null
                                text: DeviceInfoService.audioAction === modelData.address ? "Switching…" : output && output.default ? "Use for audio ✓" : "Use for audio"
                                enabled: !DeviceInfoService.audioLoading
                                onClicked: DeviceInfoService.refreshAudio(modelData.address)
                            }
                        ]
                    }
                }
                Text {
                    Layout.fillWidth: true
                    visible: DeviceInfoService.audioError !== ""
                    text: DeviceInfoService.audioError
                    color: Theme.warning; font.pixelSize: 12; wrapMode: Text.Wrap
                }
                NotificationButton {
                    visible: DeviceInfoService.audioError !== ""
                    text: "Retry audio"
                    enabled: !DeviceInfoService.audioLoading
                    onClicked: DeviceInfoService.refreshAudio()
                }
                Text {
                    Layout.topMargin: 8
                    text: "Logitech receiver devices"
                    color: Theme.textPrimary; font.pixelSize: 14; font.weight: Font.DemiBold
                }
                Text {
                    Layout.fillWidth: true
                    visible: DeviceInfoService.devices.length === 0
                    text: DeviceInfoService.loading ? "Reading receiver batteries…"
                        : DeviceInfoService.error ? DeviceInfoService.error : "No receiver devices found."
                    color: DeviceInfoService.error ? Theme.warning : Theme.textSecondary
                    font.pixelSize: 12; wrapMode: Text.Wrap
                }
                Repeater {
                    model: DeviceInfoService.devices
                    delegate: DeviceRow {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        Layout.preferredWidth: scroll.width
                        Layout.maximumWidth: scroll.width
                        deviceName: modelData.name
                        symbol: root.symbol(modelData.kind)
                        detail: modelData.online ? "Connected via receiver" : "Sleeping or unavailable"
                        batteryText: (modelData.stale ? "Last known battery · " : "Battery · ")
                            + (modelData.battery !== null ? modelData.battery + "%" : modelData.batteryLabel || "Unavailable")
                            + (modelData.charging ? " · Charging" : "")
                        lowBattery: modelData.battery !== null && modelData.battery <= 20
                    }
                }
                Text {
                    Layout.fillWidth: true
                    visible: DeviceInfoService.devices.length > 0 && DeviceInfoService.error !== ""
                    text: DeviceInfoService.error
                    color: Theme.warning; font.pixelSize: 12; wrapMode: Text.Wrap
                }
                NotificationButton {
                    visible: DeviceInfoService.error !== ""
                    text: "Retry batteries"
                    enabled: !DeviceInfoService.loading
                    onClicked: DeviceInfoService.refresh()
                }
            }
        }
    }
}
