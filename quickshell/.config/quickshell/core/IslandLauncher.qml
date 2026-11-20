import QtQuick
import Quickshell
import "../island"
import "../services"

Scope {
    id: root
    required property var state

    readonly property bool active: root.state.launcher
    property int session: 0
    property int returnMode: root.state.defaultMode
    property bool returnPinned: false
    property bool returnExpanded: false

    function toggle(mode) {
        if (active && root.state.mode === mode) {
            close()
            return
        }
        if (!active) {
            returnPinned = root.state.islandPinned && !root.state.modal
            returnMode = returnPinned ? root.state.mode : root.state.defaultMode
            returnExpanded = returnPinned && root.state.returnToExpanded
        }
        session = IslandRegistry.nextSession()
        root.state.islandPinned = false
        root.state.returnToExpanded = false
        root.state.mode = mode
        if (mode === root.state.clipboardMode) ClipboardService.reload(session)
        else AppLauncherService.error = ""
    }
    function openApps() { toggle(root.state.appLauncherMode) }
    function openClipboard() { toggle(root.state.clipboardMode) }
    function close() {
        if (!active) return
        session = IslandRegistry.nextSession()
        root.state.ignoreNextIslandTap = false
        root.state.islandPinned = returnPinned
        root.state.returnToExpanded = returnExpanded
        root.state.mode = returnMode
    }
    Connections {
        target: AppLauncherService
        function onLaunched(session) {
            if (root.active && root.session === session) root.close()
        }
    }
    Connections {
        target: ClipboardService
        function onCopied(session) {
            if (root.active && root.session === session) root.close()
        }
    }
}
