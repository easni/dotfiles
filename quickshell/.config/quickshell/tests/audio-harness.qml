import QtQuick
import Quickshell
import Quickshell.Io
import "../services"

ShellRoot {
    IpcHandler {
        target: "audioTest"
        function state(): string {
            return JSON.stringify({volume: AudioService.volume,
                large: CavaService.bars, mini: MiniCavaService.bars})
        }
        function volume(value: int) { AudioService.setVolume(value) }
        function reconnect() {
            // Exercise the same lifecycle as a default sink disappearing and returning.
            audioRoute.sink = CavaService.audioSink
            CavaService.audioSink = null
            MiniCavaService.audioSink = null
            reconnectTimer.start()
        }
    }
    Timer {
        id: reconnectTimer
        interval: 400
        onTriggered: {
            CavaService.audioSink = Qt.binding(() => audioRoute.sink)
            MiniCavaService.audioSink = Qt.binding(() => audioRoute.sink)
        }
    }
    QtObject {
        id: audioRoute
        property var sink: null
    }
    Component.onCompleted: {
        const mini = MiniCavaService.bars
        AudioService.update()
    }
}
