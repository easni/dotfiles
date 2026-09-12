pragma Singleton
import QtQuick
import Quickshell
import "../island"
import "../services"

Singleton {
    id: root
    readonly property bool active: IslandState.launcher
    property int session: 0
    property int returnMode: IslandState.defaultMode
    property bool returnPinned: false
    property bool returnExpanded: false

    function toggle(mode) {
        if (active && IslandState.mode === mode) {
            close()
            return
        }
        if (!active) {
            returnPinned = IslandState.islandPinned && !IslandState.modal
            returnMode = returnPinned ? IslandState.mode : IslandState.defaultMode
            returnExpanded = returnPinned && IslandState.returnToExpanded
        }
        session++
        IslandState.islandPinned = false
        IslandState.returnToExpanded = false
        IslandState.mode = mode
        if (mode === IslandState.clipboardMode) ClipboardService.reload(session)
        else AppLauncherService.error = ""
    }
    function openApps() { toggle(IslandState.appLauncherMode) }
    function openClipboard() { toggle(IslandState.clipboardMode) }
    function close() {
        if (!active) return
        session++
        IslandState.ignoreNextIslandTap = false
        IslandState.islandPinned = returnPinned
        IslandState.returnToExpanded = returnExpanded
        IslandState.mode = returnMode
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
