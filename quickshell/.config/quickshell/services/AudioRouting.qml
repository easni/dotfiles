pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

Singleton {
    id: root
    property var inventory: ({sink: [], source: [], default_sink: "", default_source: ""})
    readonly property var outputs: inventory.sink
    readonly property var inputs: inventory.source
    property string readError: ""
    Connections {
        target: Pipewire.nodes
        function onValuesChanged() { refreshTimer.restart() }
    }
    Connections {
        target: Pipewire
        function onDefaultAudioSinkChanged() { refreshTimer.restart() }
        function onDefaultAudioSourceChanged() { refreshTimer.restart() }
    }
    Timer {
        id: refreshTimer
        interval: 100
        onTriggered: root.refresh()
    }
    function refresh() {
        if (reader.running) refreshTimer.restart()
        else reader.running = true
    }
    Process {
        id: reader
        command: ["python3", Quickshell.shellPath("scripts/route-audio.py")]
        stdout: StdioCollector { id: snapshot }
        onExited: code => {
            try {
                if (code !== 0) throw Error()
                root.inventory = JSON.parse(snapshot.text)
                root.readError = ""
            } catch (_) {
                root.readError = "Could not read audio devices."
            }
        }
    }
    readonly property bool busy: route.running
    property string error: ""

    function select(output, name) {
        if (busy) return
        error = ""
        route.command = ["python3", Quickshell.shellPath("scripts/route-audio.py"), output ? "sink" : "source", name]
        route.running = true
    }

    Process {
        id: route
        stdout: StdioCollector { id: result }
        onExited: code => {
            if (code !== 0) root.error = result.text.trim() || "Could not switch devices."
            root.refresh()
            MicrophoneService.update()
            AudioService.update()
        }
    }
}
