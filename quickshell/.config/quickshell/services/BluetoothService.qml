pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool enabled: false
    property bool connected: false

    property string deviceName: ""

    property string subtitle:
        connected
            ? deviceName
            : enabled
                ? "On"
                : "Off"

    property url icon:
        !enabled
            ? Qt.resolvedUrl("../assets/icons/bluetooth-off.svg")
            : connected
                ? Qt.resolvedUrl("../assets/icons/bluetooth-connected.svg")
                : Qt.resolvedUrl("../assets/icons/bluetooth.svg")

    Process {
        id: stateProcess

        command: [
            "bluetoothctl",
            "show"
        ]

        stdout: StdioCollector {
            onStreamFinished: {

                let output = text

                root.enabled =
                    output.indexOf("Powered: yes") !== -1
            }
        }

        onExited: {
            deviceProcess.running = true
        }
    }

    Process {
        id: deviceProcess

        command: [
            "bluetoothctl",
            "devices",
            "Connected"
        ]

        stdout: StdioCollector {
            onStreamFinished: {

                let line = text.trim()

                if (line === "") {

                    root.connected = false
                    root.deviceName = ""

                    return
                }

                let parts = line.split(" ")

                root.connected = true

                root.deviceName =
                    parts.slice(2).join(" ")
            }
        }
    }

    Process {
        id: toggleProcess

        onExited: {
            update()
        }
    }

    function toggle() {

        toggleProcess.running = false

        toggleProcess.command = [
            "bluetoothctl",
            "power",
            enabled ? "off" : "on"
        ]

        toggleProcess.running = true
    }

    function update() {

        if (
            stateProcess.running ||
            deviceProcess.running
        )
            return

        stateProcess.running = true
    }

    Timer {
        interval: 5000

        running: true
        repeat: true

        onTriggered: {
            root.update()
        }
    }

    Component.onCompleted: {
        update()
    }
}