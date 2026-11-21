import QtQuick
import Quickshell
import Quickshell.Io
import "../windows"
import "../services"
import "../core"
ShellRoot {
    IslandWindows {
        id: panels
        model: IslandRegistry.screens.filter(s => s.name.startsWith(Quickshell.env("LUCI_MONITOR_TEST_PREFIX")))
    }
    IslandIPC {}
    IpcHandler {
        target: "monitorTest"
        function state(): string {
            return JSON.stringify({target: IslandRegistry.target ? IslandRegistry.target.screenName : "",
                sessions: IslandRegistry.sessions.map(s => ({name:s.screenName, mode:s.state.mode, modal:s.state.modal})),
                windows: panels.instances.map(w => ({name:w.screen.name, visible:w.backingWindowVisible,
                    focused:w.contentItem.Window.active, height:w.height, width:w.width}))})
        }
    }
}
