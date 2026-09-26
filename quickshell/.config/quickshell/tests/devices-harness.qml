import QtQuick
import QtTest
import Quickshell
import Quickshell.Bluetooth
import "../services"
import "../island"
import "../core"
import "../styles"
import "../styles/themes/githublight" as Light

ShellRoot {
    QtObject { id: adapter; property bool enabled: true; property string name: "Test adapter" }
    QtObject {
        id: speaker
        property string name: "SW-208"
        property string address: "AA:BB:CC:DD:EE:FF"
        property string dbusPath: "/test/speaker"
        property bool paired: true
        property bool bonded: true
        property bool connected: true
        property bool blocked: false
        property bool batteryAvailable: false
        property real battery: 0
        property string icon: "audio-speakers"
        property var adapter: null
        property int state: BluetoothDeviceState.Connected
        function connect() { state = BluetoothDeviceState.Connecting }
        function disconnect() { state = BluetoothDeviceState.Disconnecting }
    }
    QtObject {
        id: unsaved
        property string name: "Nearby stranger"
        property bool paired: false
        property bool bonded: false
        property bool connected: false
    }
    FloatingWindow {
        id: window
        visible: true
        implicitWidth: 620; implicitHeight: 640
        color: "#252a33"
        Item {
            id: canvas
            anchors.fill: parent
            Island {
                id: island
                availableWidth: 520; availableHeight: 560
                anchors.horizontalCenter: parent.horizontalCenter
                y: 20
            }
        }
    }
    TestCase {
        id: test
        when: false
        function check(value, message) { if (!value) throw new Error(message) }
        function until(predicate, message) {
            for (let i=0; i<100 && !predicate(); ++i) wait(50)
            check(predicate(), message)
        }
        function grab(name) {
            let saved = false
            canvas.grabToImage(result => saved = result.saveToFile(Quickshell.env("LUCI_TEST_OUTPUT")+"/"+name+".png"))
            until(() => saved, "Screenshot")
        }
        function run() {
            speaker.adapter = adapter
            BluetoothService.adapters = [adapter]
            BluetoothService.sourceDevices = [unsaved, speaker]
            DeviceInfoService.active = false
            IslandController.openControlCenter()
            IslandState.islandPinned = true
            IslandController.openBluetooth()
            check(IslandState.mode === 10 && IslandState.islandPinned, "Open/pin")
            check(!IslandState.modal, "Must remain non-modal")
            check(BluetoothService.devices.length === 1, "Unpaired discovery leaked")
            DeviceInfoService.refresh()
            DeviceInfoService.refreshAudio()
            until(() => !DeviceInfoService.loading && !DeviceInfoService.audioLoading, "Helpers timed out")
            check(DeviceInfoService.devices.length === 2, "Receiver devices missing: "+DeviceInfoService.error)
            check(DeviceInfoService.devices[0].battery === 35, "Battery parsing")
            wait(400)
            grab("devices-dark")
            BluetoothService.toggleDevice(speaker)
            check(BluetoothService.busy(speaker), "Disconnect pending")
            speaker.connected = false
            speaker.state = BluetoothDeviceState.Disconnected
            BluetoothService.reconcile()
            check(!BluetoothService.busy(speaker), "Disconnect completion")
            BluetoothService.toggleDevice(speaker)
            BluetoothService.operations[speaker.dbusPath].deadline = 0
            BluetoothService.reconcile()
            check(BluetoothService.deviceError(speaker) !== "", "Timeout error")
            BluetoothService.toggleDevice(speaker)
            speaker.connected = true
            speaker.state = BluetoothDeviceState.Connected
            BluetoothService.reconcile()
            check(!BluetoothService.deviceError(speaker), "Retry clears error")
            BluetoothService.toggle()
            BluetoothService.reconcile()
            check(!BluetoothService.enabled, "Power off")
            BluetoothService.toggle()
            BluetoothService.reconcile()
            DeviceInfoService.refreshAudio(speaker.address)
            until(() => !DeviceInfoService.audioLoading, "Audio action stuck")
            check(DeviceInfoService.outputFor(speaker.address).default, "Audio default")
            DeviceInfoService.loading = true
            DeviceInfoService.finishReceiver(1, '{"error":"Receiver access denied. Retry."}')
            check(DeviceInfoService.devices[0].stale, "Failure loses last known reading")
            DeviceInfoService.error = ""
            IslandController.closeBluetooth()
            check(IslandState.mode === 3 && IslandState.islandPinned, "Back restores pin")
            IslandController.openBluetooth()
            wait(300)
            mouseMove(canvas, 310, 70)
            mouseMove(canvas, 5, 620)
            wait(400)
            check(IslandState.mode === 10, "Pinned panel collapsed")
            IslandState.islandPinned = false
            mouseMove(canvas,310,70)
            mouseMove(canvas,5,620)
            wait(500)
            check(IslandState.mode === 0, "Unpinned panel did not collapse")
            IslandController.openBluetooth()
            wait(300)
            keyClick(Qt.Key_Escape)
            check(IslandState.mode === 3, "Escape returns to controls")
            IslandController.openBluetooth()
            island.availableWidth = 300
            wait(400)
            check(island.width <= 300.1, "Narrow width")
            grab("devices-narrow")
            for (const key of ['background','surface','surfaceVariant','textPrimary','textSecondary','textMuted','icon','accent','warning','buttonBackground','buttonHover','buttonPressed','borderSubtle']) Theme[key]=Light.Theme[key]
            island.availableWidth = 520
            wait(400)
            grab("devices-light")
            BluetoothService.adapters = []
            BluetoothService.sourceDevices = []
            wait(50)
            check(!BluetoothService.available, "Adapter removal")
            console.log("PASS device models, actions, batteries, audio routing, navigation, hover and layouts")
        }
    }
    Timer {
        running: true
        interval: 300
        onTriggered: {
            try { test.run() } catch (e) { console.error("FAIL", e.message, e.stack) }
            Qt.quit()
        }
    }
}
