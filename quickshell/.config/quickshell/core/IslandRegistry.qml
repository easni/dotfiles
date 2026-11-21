pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../island"

Singleton {
    id: root
    readonly property var screens: Quickshell.screens.filter(s => s.name !== ""
        && s.name !== "FALLBACK" && s.width > 0 && s.height > 0)
    property var sessions: []
    property int sessionSerial: 0
    // Overrideable in isolated tests; production follows compositor focus.
    property string focusedScreenName: Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""
    readonly property var target: sessions.find(s => s.screenName === focusedScreenName) || sessions[0] || null
    readonly property var defaultContext: ({state: IslandState, navigation: IslandController,
        launcher: LauncherController, notifications: NotificationController})
    readonly property var pausedIds: sessions.map(s => s.notifications.pausedId).filter(id => id >= 0)

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "fullscreen") Hyprland.refreshToplevels()
            if (event.name === "activespecialv2") Hyprland.refreshMonitors()
        }
    }

    function contextFor(item) {
        for (let node = item; node; node = node.parent) {
            if (node.islandContext !== undefined) return node.islandContext
        }
        return defaultContext
    }
    function nextSession() { return ++sessionSerial }
    function registerSession(session) {
        if (sessions.indexOf(session) === -1) sessions = sessions.concat([session])
    }
    function unregisterSession(session) {
        sessions = sessions.filter(s => s !== session)
    }
    function closeModal(session) {
        if (session.state.launcher) session.launcher.close()
        else if (session.state.mode === session.state.calendarMode) session.navigation.closeCalendar()
        else if (session.state.modal) session.navigation.reset()
    }
    function claimModal(owner) {
        for (const session of sessions) {
            if (session !== owner) closeModal(session)
        }
    }
    function dispatch(action, session = target) {
        if (!session) return
        const state = session.state
        const navigation = session.navigation
        switch (action) {
        case "openAppLauncher": session.launcher.openApps(); break
        case "openClipboard": session.launcher.openClipboard(); break
        case "openBluetooth": navigation.openBluetooth(); break
        case "openNotifications": navigation.openNotifications(); break
        case "openExpandedHome": navigation.openExpanded(); break
        case "reset": navigation.reset(); break
        case "openPowerMenu":
            if (state.mode === state.powerMenuMode) navigation.reset()
            else navigation.openPowerMenu()
            break
        case "openThemeSelector":
            if (state.mode === state.themeSelectorMode) navigation.reset()
            else navigation.openThemeSelector()
            break
        case "openWallpaperSelector":
            if (state.mode === state.wallpaperSelectorMode) navigation.reset()
            else navigation.openWallpaperSelector()
            break
        }
    }
}
