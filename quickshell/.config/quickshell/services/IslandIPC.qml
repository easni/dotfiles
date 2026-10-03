import Quickshell
import Quickshell.Io

import "../core"
import "../island"

IpcHandler {
    target: "luci"

    function openBluetooth() { IslandController.openBluetooth() }

    function openAppLauncher() { LauncherController.openApps() }
    function openClipboard() { LauncherController.openClipboard() }

    function openNotifications() {
        IslandController.openNotifications()
    }

    function openPowerMenu() {
        if (IslandState.mode === IslandState.powerMenuMode) IslandController.reset()
        else IslandController.openPowerMenu()
    }

    function openExpandedHome() {
        IslandController.openExpanded()
    }

    function reset() {
        IslandController.reset()
    }

    function openWallpaperSelector() {
        if (IslandState.mode === IslandState.wallpaperSelectorMode) IslandController.reset()
        else IslandController.openWallpaperSelector()
    }

    function openThemeSelector() {
        if (IslandState.mode === IslandState.themeSelectorMode) IslandController.reset()
        else IslandController.openThemeSelector()
    }
}
