import QtQuick
import QtTest
import Quickshell
import Quickshell.Io
import "../island"
import "../core"
import "../services"
import "../styles"
import "../styles/themes/githublight" as Light
import "../styles/themes/monochrome" as Dark

ShellRoot {
    id: root
    function findItem(item, name) {
        if (item.objectName === name) return item
        for (const child of item.children) {
            const result = findItem(child, name)
            if (result) return result
        }
        return null
    }
    FloatingWindow {
        id: window
        visible: true
        implicitWidth: 720
        implicitHeight: 620
        Item {
            id: canvas
            anchors.fill: parent
            Rectangle { anchors.fill: parent; color: "#252a33" }
            Island {
                id: capsule
                anchors.horizontalCenter: parent.horizontalCenter
                y: 15
                availableWidth: 680
                availableHeight: 590
            }
            TestCase { id: keys; name: "LauncherInput"; when: false }
        }
    }
    IpcHandler {
        target: "test"
        function apps() { LauncherController.openApps() }
        function clipboard() { LauncherController.openClipboard() }
        function close() { LauncherController.close() }
        function pin() { IslandState.mode = IslandState.expandedMode; IslandState.islandPinned = true }
        function query(text: string) { root.findItem(capsule, "launcherSearch").text = text }
        function key(name: string) {
            const input = root.findItem(capsule, "launcherSearch")
            input.forceActiveFocus()
            if (name === "down") keys.keyClick(Qt.Key_Down)
            if (name === "up") keys.keyClick(Qt.Key_Up)
            if (name === "next") keys.keyClick(Qt.Key_N, Qt.ControlModifier)
            if (name === "previous") keys.keyClick(Qt.Key_P, Qt.ControlModifier)
            if (name === "enter") keys.keyClick(Qt.Key_Return)
            if (name === "escape") keys.keyClick(Qt.Key_Escape)
            if (name === "a") keys.keyClick(Qt.Key_A)
        }
        function activate() { root.findItem(capsule, "launcherPanel").activateSelection() }
        function state(): string {
            const panel = root.findItem(capsule, "launcherPanel")
            const input = root.findItem(capsule, "launcherSearch")
            return JSON.stringify({mode: IslandState.mode, modal: IslandState.modal, pinned: IslandState.islandPinned,
                active: LauncherController.active, notificationPreview: NotificationController.visible, notifications: NotificationService.history.length, session: LauncherController.session,
                width: capsule.width, height: capsule.height,
                query: input ? input.text : "", focused: input ? input.activeFocus : false,
                selected: panel ? panel.selectedIndex : -1,
                results: panel ? panel.results : [], loading: ClipboardService.loading,
                busy: panel ? panel.busy : false, error: panel ? panel.error : ""})
        }
        function grab(path: string) { canvas.grabToImage(result => result.saveToFile(path)) }
        function narrow() { capsule.availableWidth = 320; capsule.availableHeight = 360 }
        function theme(light: bool) {
            const source = light ? Light.Theme : Dark.Theme
            for (const name of ['background','surface','surfaceVariant','card','textPrimary','textSecondary','textMuted','icon','accent','warning','border','buttonBackground','buttonHover','buttonPressed']) Theme[name] = source[name]
        }
    }
}
