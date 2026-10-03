pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

Singleton {

    id: root

    Connections {
        target: Pipewire
        function onDefaultAudioSinkChanged() {
            root.pendingValue = -1
            root.update()
        }
    }

    property int volume: 0
    property bool muted: false

    readonly property url volumeIcon: {

        if (muted)
            return "../assets/icons/volume-off.svg"

        if (volume <= 5)
            return "../assets/icons/volume-0.svg"

        if (volume <= 40)
            return "../assets/icons/volume-1.svg"

        return "../assets/icons/volume-2.svg"
    }

    Process {
        id: queryProcess

        command: [
            "wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"
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
        setProcess.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", percent + "%"]
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
            "@DEFAULT_AUDIO_SINK@",
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
