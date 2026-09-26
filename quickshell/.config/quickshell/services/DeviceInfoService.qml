pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../island"

Singleton {
    id: root
    property bool active: IslandState.mode === IslandState.bluetoothMode
    property var devices: []
    property var outputs: []
    property string error: ""
    property string audioError: ""
    property bool loading: false
    property bool audioLoading: false
    property string audioAction: ""
    property double lastRefresh: 0

    function refresh() {
        if (loading) return
        loading = true
        error = ""
        receiver.command = ["python3", Quickshell.shellPath("scripts/device-info.py"), "receiver"]
        receiver.running = true
        receiverTimeout.restart()
    }
    function refreshAudio(address) {
        if (audioLoading) return
        audioLoading = true
        audioAction = address || ""
        audioError = ""
        audio.command = ["python3", Quickshell.shellPath("scripts/device-info.py"), "audio"]
        if (address) audio.command = audio.command.concat([address])
        audio.running = true
        audioTimeout.restart()
    }
    function outputFor(address) {
        const key = address.replace(/[^a-f0-9]/gi, "").toUpperCase()
        return outputs.find(o => o.address === key) || null
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
    function finishAudio(code, text) {
        if (!audioLoading) return
        audioTimeout.stop()
        audioLoading = false
        audioAction = ""
        try {
            const result = JSON.parse(text)
            audioError = result.error || (code !== 0 ? "Could not update audio. Retry." : "")
            if (result.outputs) outputs = result.outputs
        } catch (_) { audioError = "Could not read audio outputs. Retry." }
    }
    onActiveChanged: if (active) { refresh(); refreshAudio() }
    Process {
        id: receiver
        stdout: StdioCollector { id: receiverOutput }
        stderr: StdioCollector {}
        onExited: code => root.finishReceiver(code, receiverOutput.text)
        onRunningChanged: if (!running) Qt.callLater(() => {
            if (root.loading && !receiver.running) root.finishReceiver(1, '{"error":"Battery helper could not start. Retry."}')
        })
    }
    Process {
        id: audio
        stdout: StdioCollector { id: audioOutput }
        stderr: StdioCollector {}
        onExited: code => root.finishAudio(code, audioOutput.text)
        onRunningChanged: if (!running) Qt.callLater(() => {
            if (root.audioLoading && !audio.running) root.finishAudio(1, '{}')
        })
    }
    Timer {
        id: receiverTimeout
        interval: 22000
        onTriggered: { root.finishReceiver(1, '{"error":"Battery query timed out. Retry."}'); receiver.signal(9) }
    }
    Timer {
        id: audioTimeout
        interval: 15000
        onTriggered: { root.finishAudio(1, '{"error":"Audio request timed out. Retry."}'); audio.signal(9) }
    }
    Timer { interval: 60000; running: root.active; repeat: true; onTriggered: root.refresh() }
    Timer { interval: 3000; running: root.active; repeat: true; onTriggered: if (!root.audioError) root.refreshAudio() }
    Component.onCompleted: if (active) { refresh(); refreshAudio() }
}
