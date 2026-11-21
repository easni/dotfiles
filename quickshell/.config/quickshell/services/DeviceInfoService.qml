pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../island"
import "../core"

Singleton {
    id: root
    property bool active: IslandState.mode === IslandState.bluetoothMode || IslandRegistry.sessions.some(s => s.state.mode === s.state.bluetoothMode)
    property var devices: []
    property string error: ""
    property bool loading: false
    property double lastRefresh: 0

    function refresh() {
        if (loading) return
        loading = true
        error = ""
        receiver.command = ["python3", Quickshell.shellPath("scripts/device-info.py"), "receiver"]
        receiver.running = true
        receiverTimeout.restart()
    }
    function finishReceiver(code, text) {
        if (!loading) return
        receiverTimeout.stop()
        loading = false
        try {
            const result = JSON.parse(text)
            if (code !== 0 || result.error) throw new Error(result.error || "Could not read batteries. Retry.")
            devices = result.devices.map(d => {
                const old = devices.find(previous => previous.id === d.id)
                if (old && (!d.online || (d.battery === null && !d.batteryLabel))) {
                    d.battery = old.battery
                    d.batteryLabel = old.batteryLabel
                    d.charging = false
                    d.stale = true
                }
                return d
            })
            lastRefresh = Date.now()
        } catch (failure) {
            error = failure.message || "Could not read batteries. Retry."
            devices = devices.map(d => Object.assign({}, d, {stale: true}))
        }
    }
    onActiveChanged: if (active) refresh()
    Process {
        id: receiver
        stdout: StdioCollector { id: receiverOutput }
        stderr: StdioCollector {}
        onExited: code => root.finishReceiver(code, receiverOutput.text)
        onRunningChanged: if (!running) Qt.callLater(() => {
            if (root.loading && !receiver.running) root.finishReceiver(1, '{"error":"Battery helper could not start. Retry."}')
        })
    }
    Timer {
        id: receiverTimeout
        interval: 22000
        onTriggered: { root.finishReceiver(1, '{"error":"Battery query timed out. Retry."}'); receiver.signal(9) }
    }
    Timer { interval: 60000; running: root.active; repeat: true; onTriggered: root.refresh() }
    Component.onCompleted: if (active) refresh()
}
