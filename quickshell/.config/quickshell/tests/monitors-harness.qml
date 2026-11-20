import QtQuick
import QtTest
import Quickshell
import "../core"
import "../island"
import "../services"

ShellRoot {
    id: root
    property var outputs: ["DP-1", "HDMI-A-1"]
    Variants {
        model: root.outputs
        IslandSession { required property var modelData; screenName: modelData }
    }
    FloatingWindow {
        visible: true
        implicitWidth: 1300
        implicitHeight: 650
        Row {
            Repeater {
                model: IslandRegistry.sessions
                Item {
                    required property var modelData
                    width: 640; height: 620
                    Island { islandContext: modelData; availableWidth: 600; availableHeight: 600 }
                }
            }
        }
    }
    TestCase {
        id: checks
        when: false
        function check(value, message) { if (!value) throw new Error(message); console.log("PASS " + message) }
        function settle() { wait(100) }
        function run() {
            settle()
            check(IslandRegistry.sessions.length === 2, "two outputs create independent sessions")
            const a = IslandRegistry.sessions.find(s => s.screenName === "DP-1")
            const b = IslandRegistry.sessions.find(s => s.screenName === "HDMI-A-1")
            IslandRegistry.focusedScreenName = "DP-1"
            IslandRegistry.dispatch("openExpandedHome")
            a.state.islandPinned = true
            check(a.state.mode === a.state.expandedMode && b.state.mode === b.state.defaultMode, "navigation and pinning are local")
            IslandRegistry.dispatch("openAppLauncher")
            settle()
            const firstToken = a.launcher.session
            check(a.state.launcher && !b.state.modal, "keyboard launcher targets focused display")
            IslandRegistry.focusedScreenName = "HDMI-A-1"
            IslandRegistry.dispatch("openAppLauncher")
            settle()
            check(b.state.launcher && !a.state.modal && a.state.islandPinned, "modal transfer restores previous pinned display")
            check(b.launcher.session !== firstToken, "launcher tokens are unique across displays")
            AppLauncherService.launched(firstToken)
            check(b.state.launcher, "stale launch completion cannot close another display")
            IslandRegistry.dispatch("openAppLauncher")
            check(!b.state.modal, "repeated shortcut closes focused popup")
            for (const action of ["openPowerMenu", "openThemeSelector", "openWallpaperSelector"]) {
                IslandRegistry.dispatch(action)
                settle()
                check(b.state.modal && !a.state.modal, action + " opens only on target")
                IslandRegistry.dispatch(action)
                check(!b.state.modal, action + " toggles closed")
            }
            b.navigation.openPowerMenu()
            // An empty action exercises the collapse path without locking or suspending.
            PowerService.resetThenRun("", b.navigation)
            check(!b.state.modal && a.state.islandPinned, "power action collapses its own island")
            a.navigation.openCalendar()
            settle()
            b.navigation.openCalendar()
            settle()
            check(!a.state.modal && b.state.mode === b.state.calendarMode, "pointer-opened modals also transfer ownership")
            check(CalendarService.active, "calendar refresh remains active after modal transfer")
            b.navigation.reset()
            settle()
            // Notifications have one receiving display; hover lifetime stays local.
            const entry = {savedId: 123, critical: false, unread: true, isTransient: false,
                icon: "", app: "Test", summary: "Test", body: "", image: "", actions: []}
            NotificationService.arrived(entry)
            check(a.notifications.current === null && b.notifications.current && b.notifications.current.savedId === 123, "notifications route to focused display")
            b.notifications.hovered = true
            check(IslandRegistry.pausedIds.indexOf(123) !== -1, "notification pause is aggregated across displays")
            IslandRegistry.dispatch("openAppLauncher")
            settle()
            const removedToken = b.launcher.session
            root.outputs = ["DP-1"]
            settle()
            check(IslandRegistry.sessions.length === 1 && IslandRegistry.sessions[0] === a, "disconnect destroys only removed session")
            check(a.state.islandPinned && a.state.mode === a.state.expandedMode, "remaining monitor keeps state")
            check(IslandRegistry.target === a, "stale compositor focus falls back to connected monitor")
            check(IslandRegistry.pausedIds.length === 0, "removed monitor releases notification pause")
            root.outputs = ["DP-1", "HDMI-A-1"]
            settle()
            const reconnected = IslandRegistry.sessions.find(s => s.screenName === "HDMI-A-1")
            check(reconnected && reconnected.state.mode === reconnected.state.defaultMode, "reconnected monitor gets fresh usable state")
            IslandRegistry.dispatch("openAppLauncher")
            settle()
            ClipboardService.copied(removedToken)
            check(reconnected.state.launcher, "old completion cannot affect reconnected monitor")
            root.outputs = []
            settle()
            check(IslandRegistry.sessions.length === 0 && IslandRegistry.target === null, "all outputs can disappear")
            IslandRegistry.dispatch("openPowerMenu")
            root.outputs = ["DP-1"]
            settle()
            IslandRegistry.dispatch("openPowerMenu")
            settle()
            check(IslandRegistry.target.state.mode === IslandRegistry.target.state.powerMenuMode, "shortcuts work after all outputs return")
            console.log("PASS multi-monitor lifecycle and routing")
            Qt.quit()
        }
    }
    Component.onCompleted: Qt.callLater(checks.run)
}
