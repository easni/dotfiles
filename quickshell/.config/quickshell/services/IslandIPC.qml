import Quickshell
import Quickshell.Io

import "../core"

IpcHandler {
    target: "luci"

    function openAppLauncher() { LauncherController.openApps() }
    function openClipboard() { LauncherController.openClipboard() }

    function openNotifications() {
        IslandController.openNotifications()
    }

    function openPowerMenu() {
        IslandController.openPowerMenu()
    }

    function openExpandedHome() {
        IslandController.openExpanded()
    }

    function reset() {
        IslandController.reset()
    }

    function openWallpaperSelector() {
        IslandController.openWallpaperSelector()
    }

    function openThemeSelector() {
        IslandController.openThemeSelector()
    }
}