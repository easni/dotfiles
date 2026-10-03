pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {

    id: root

    property int brightness: 0

    readonly property url brightnessIcon: {

        if (brightness <= 25)
            return "../assets/icons/brightness-down.svg"

        if (brightness <= 65)
            return "../assets/icons/brightness-half.svg"

        return "../assets/icons/brightness-full.svg"
    }

    Process {
        id: queryProcess

        command: [
            "brightnessctl",
            "info"
        ]

        stdout: StdioCollector {

            onStreamFinished: {
                if (setProcess.running || root.pendingValue >= 0) return

                let output = this.text.trim()

                let match = output.match(/\((\d+)%\)/)

                if (match)
                    root.brightness = parseInt(match[1])
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

    function setBrightness(value) {
        pendingValue = Math.max(0, Math.min(100, Math.round(value)))
        brightness = pendingValue
        flushValue()
    }

    function flushValue() {
        if (setProcess.running || pendingValue < 0) return
        const percent = pendingValue
        pendingValue = -1
        setProcess.command = [String(Qt.resolvedUrl("../scripts/brightness.sh")).replace("file://", ""), percent + "%"]
        setProcess.running = true
    }

    function increase(step) {

        let amount = step === undefined ? 5 : step

        setBrightness(
            Math.min(100, brightness + amount)
        )
    }

    function decrease(step) {

        let amount = step === undefined ? 5 : step

        setBrightness(
            Math.max(0, brightness - amount)
        )
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
