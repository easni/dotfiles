import Quickshell
import Quickshell.Io
import "../core"

Scope {
    id: root
    property var targetSession: IslandRegistry.target
    IpcHandler {
        target: "luci"
        function openBluetooth() { IslandRegistry.dispatch("openBluetooth", root.targetSession) }
        function openAppLauncher() { IslandRegistry.dispatch("openAppLauncher", root.targetSession) }
        function openClipboard() { IslandRegistry.dispatch("openClipboard", root.targetSession) }
        function openNotifications() { IslandRegistry.dispatch("openNotifications", root.targetSession) }
        function openPowerMenu() { IslandRegistry.dispatch("openPowerMenu", root.targetSession) }
        function openExpandedHome() { IslandRegistry.dispatch("openExpandedHome", root.targetSession) }
        function reset() { IslandRegistry.dispatch("reset", root.targetSession) }
        function openWallpaperSelector() { IslandRegistry.dispatch("openWallpaperSelector", root.targetSession) }
        function openThemeSelector() { IslandRegistry.dispatch("openThemeSelector", root.targetSession) }
    }
}
