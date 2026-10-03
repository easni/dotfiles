pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

Singleton {
    id: root

    property var bars: []

    property bool shouldRun: true
    property var audioSink: Pipewire.defaultAudioSink

    // CAVA can retain its old monitor connection after an output switch.
    onAudioSinkChanged: reconnect()
    onShouldRunChanged: reconnect()

    function reconnect() {
        restartTimer.stop()
        bars = []
        if (cava.running) cava.running = false
        else if (shouldRun && audioSink) restartTimer.restart()
    }

    Process {
        id: cava

        running: false

        command: [
            "cava",
            "-p",
            Quickshell.shellPath("scripts/cava-mini.conf")
        ]

        stdout: SplitParser {
            splitMarker: "\n"

            onRead: function(line) {

                if (line.trim().length === 0)
                    return

                const values = line.trim().split(";")
                const parsed = []

                for (let i = 0; i < values.length; ++i) {
                    if (values[i] !== "")
                        parsed.push(Number(values[i]))
                }

                root.bars = parsed
            }
        }

       

        onExited: function(exitCode, exitStatus) {

            root.bars = []

            if (root.shouldRun && root.audioSink)
                restartTimer.restart()
                
        }
    }

    Timer {
        id: restartTimer
        interval: 250
        repeat: false
        onTriggered: {
            if (root.shouldRun && root.audioSink && !cava.running)
                cava.running = true
        }
    }

    Component.onCompleted: reconnect()
}
