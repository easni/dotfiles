import QtQuick
import Quickshell
import Quickshell.Io
import "../core"

Scope {
    id: root
    required property string connector
    property int brightness: 0
    property bool available: false
    property string error: ""
    property int pendingValue: -1
    property int pendingStep: 0
    property bool busy: false
    readonly property url brightnessIcon: brightness <= 25 ? "../assets/icons/brightness-down.svg"
        : brightness <= 65 ? "../assets/icons/brightness-half.svg" : "../assets/icons/brightness-full.svg"

    property int confirmed: -1
    property bool keyPreview: false

    Component.onCompleted: update()

    function setBrightness(value) {
        debounce.stop()
        keyPreview = false
        pendingStep = 0
        pendingValue = Math.max(0, Math.min(100, Math.round(value)))
        brightness = pendingValue
        start()
    }

    function step(amount) {
        keyPreview = true
        if (confirmed >= 0 || pendingValue >= 0) {
            pendingValue = Math.max(0, Math.min(100, brightness + amount))
            brightness = pendingValue
        } else {
            pendingStep += amount
        }
        const title = pendingValue >= 0 ? brightness + "%" : (pendingStep >= 0 ? "+" : "") + pendingStep + "%"
        StatusManager.showBrightness(pendingValue, title)
        debounce.restart()
    }

    function update() {
        if (!busy && !debounce.running) start()
    }

    function start() {
        if (busy || !connector || debounce.running) return
        const args = ["python3", Quickshell.shellPath("scripts/display-brightness.py"), connector]
        if (pendingValue >= 0)
            args.push(String(pendingValue))
        else if (pendingStep)
            args.push((pendingStep > 0 ? "+" : "") + pendingStep)
        if (keyPreview && args.length === 4) args.push("--quiet")
        pendingValue = -1
        pendingStep = 0
        keyPreview = false
        busy = true
        worker.command = args
        worker.running = true
    }

    Timer { id: debounce; interval: 2000; onTriggered: root.start() }
    Process {
        id: worker
        stdout: StdioCollector { id: result }
        onExited: code => {
            let data = {}
            try { data = JSON.parse(result.text) } catch (_) {}
            root.available = code === 0 && Number.isFinite(data.percent)
            root.error = root.available ? "" : (data.error || "Brightness control unavailable.")
            if (root.available) {
                root.confirmed = data.percent
                if (root.pendingStep) {
                    root.pendingValue = Math.max(0, Math.min(100, data.percent + root.pendingStep))
                    root.pendingStep = 0
                }
            }
            root.brightness = root.pendingValue >= 0 ? root.pendingValue : Math.max(0, root.confirmed)
            root.busy = false
            if (root.pendingValue >= 0 || root.pendingStep) root.start()
        }
    }
}
