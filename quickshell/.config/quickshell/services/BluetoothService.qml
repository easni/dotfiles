pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Bluetooth

Singleton {
    id: root
    // Injectable source models also let the UI tests run without touching hardware.
    property var adapters: Bluetooth.adapters.values
    property var sourceDevices: Bluetooth.devices.values
    property int adapterIndex: 0
    readonly property var adapter: adapters[Math.min(adapterIndex, adapters.length - 1)] || null
    readonly property bool available: adapter !== null
    readonly property bool enabled: adapter ? adapter.enabled : false
    readonly property var devices: sourceDevices.filter(d => d.paired || d.bonded || d.connected)
        .sort((a, b) => Number(b.connected) - Number(a.connected) || a.name.localeCompare(b.name))
    readonly property var connectedDevices: devices.filter(d => d.connected)
    readonly property bool connected: connectedDevices.length > 0
    readonly property string deviceName: connectedDevices.map(d => d.name).join(", ")
    readonly property string subtitle: !available ? "Unavailable" : connectedDevices.length > 1
        ? connectedDevices.length + " connected" : connected ? deviceName : enabled ? "On" : "Off"
    readonly property url icon: Qt.resolvedUrl(!enabled && !connected ? "../assets/icons/bluetooth-off.svg"
        : connected ? "../assets/icons/bluetooth-connected.svg" : "../assets/icons/bluetooth.svg")
    property var operations: ({})
    property var errors: ({})
    property var powerOperation: null
    property string powerError: ""

    function busy(device) { return !!operations[device.dbusPath] }
    function deviceError(device) { return errors[device.dbusPath] || "" }
    function toggleDevice(device) {
        if (busy(device) || !device.adapter || !device.adapter.enabled || device.blocked) return
        const key = device.dbusPath
        const nextErrors = Object.assign({}, errors)
        delete nextErrors[key]
        errors = nextErrors
        const next = Object.assign({}, operations)
        next[key] = {device: device, target: !device.connected, deadline: Date.now() + 15000, sawBusy: false}
        operations = next
        if (device.connected) device.disconnect()
        else device.connect()
    }
    function toggle() {
        if (!adapter || powerOperation) return
        powerError = ""
        powerOperation = {adapter: adapter, target: !adapter.enabled, deadline: Date.now() + 15000}
        adapter.enabled = powerOperation.target
    }
    function reconcile() {
        const next = Object.assign({}, operations)
        const nextErrors = Object.assign({}, errors)
        for (const key of Object.keys(next)) {
            const op = next[key]
            const device = sourceDevices.find(d => d.dbusPath === key)
            if (device && device.connected === op.target) { delete next[key]; continue }
            const transitioning = device && (device.state === BluetoothDeviceState.Connecting || device.state === BluetoothDeviceState.Disconnecting)
            if (!device || Date.now() >= op.deadline || (op.sawBusy && !transitioning)) {
                nextErrors[key] = op.target ? "Could not connect. Retry." : "Could not disconnect. Retry."
                delete next[key]
            } else if (transitioning) op.sawBusy = true
        }
        operations = next
        errors = nextErrors
        if (powerOperation) {
            if (!adapters.includes(powerOperation.adapter)) {
                powerError = "Bluetooth adapter removed."
                powerOperation = null
            } else if (powerOperation.adapter.enabled === powerOperation.target) powerOperation = null
            else if (Date.now() >= powerOperation.deadline) {
                powerError = "Could not change Bluetooth power. Retry."
                powerOperation = null
            }
        }
    }
    Timer {
        interval: 200
        repeat: true
        running: Object.keys(root.operations).length > 0 || root.powerOperation !== null
        onTriggered: root.reconcile()
    }
}
