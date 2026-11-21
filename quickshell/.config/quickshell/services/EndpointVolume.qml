
import QtQuick
import Quickshell
import Quickshell.Io

Scope {

    id: root

    required property string endpoint
    function defaultChanged() {
        pendingValue = -1
        update()
    }

    property int volume: 0
    property bool muted: false

    Process {
        id: queryProcess

        command: [
            "wpctl", "get-volume", root.endpoint
        ]

        stdout: StdioCollector {

            onStreamFinished: {
                if (setProcess.running || root.pendingValue >= 0) return

                let output = this.text.trim()

                if (output.length === 0)
                    return

                let parts = output.split(" ")

                let value = parseFloat(parts[1])

                if (!isNaN(value))
                    root.volume = Math.round(value * 100)

                root.muted =
                    output.includes("[MUTED]")
            }
        }
    }

    Process {
        id: setProcess
        onExited: {
            if (root.pendingValue >= 0) root.flushValue()
            else root.update()
        }
    }

    function update() {

        if (!queryProcess.running)
            queryProcess.running = true
    }

    property int pendingValue: -1

    function setVolume(value) {
        pendingValue = Math.max(0, Math.min(100, Math.round(value)))
        volume = pendingValue
        flushValue()
    }

    function flushValue() {
        if (setProcess.running || pendingValue < 0) return
        const percent = pendingValue
        pendingValue = -1
        setProcess.command = ["wpctl", "set-volume", root.endpoint, percent + "%"]
        setProcess.running = true
    }

    Process {
        id: muteProcess
        onExited: root.update()
    }

    function toggleMute() {
        if (muteProcess.running) return
        muteProcess.command = [
            "wpctl",
            "set-mute",
            root.endpoint,
            "toggle"
        ]

        muteProcess.running = true
    }

    Timer {

        interval: 1000
        repeat: true
        running: true

        onTriggered: {
            root.update()
        }
    }

    Component.onCompleted: {
        update()
    }
}
