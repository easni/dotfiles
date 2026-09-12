import QtQuick
import QtTest
import Quickshell
import Quickshell.Io
import "../services"
import "../core"
import "../island"
import "../styles"
import "../styles/themes/githublight" as Light
import "../styles/themes/monochrome" as Dark

ShellRoot {
    id: testRoot
    function findItem(item, name) {
        if (!item.visible) return null
        if (item.objectName === name) return item
        for (const child of item.children) {
            const found = findItem(child, name)
            if (found) return found
        }
        return null
    }
    function itemRect(name) {
        const item = findItem(capsule, name)
        if (!item) return null
        const point = item.mapToItem(canvas, 0, 0)
        return {x: point.x, y: point.y, width: item.width, height: item.height}
    }
    Component.onCompleted: {
        NotificationController.initialize()
        NotificationService.initialize()
    }
    FloatingWindow {
        id: window
        visible: true
        implicitWidth: 720
        implicitHeight: 650
        color: "#252a33"
        Item {
            id: canvas
            anchors.fill: parent
            Rectangle { anchors.fill: parent; color: "#252a33" }
            Island {
                id: capsule
                availableWidth: window.width - 20
                anchors.horizontalCenter: parent.horizontalCenter
                y: 20
            }
        }
    }
    TestCase { id: mouse; name: "NotificationInteraction"; when: false }
    IpcHandler {
        target: "test"
        function state(): string {
            return JSON.stringify({visible:NotificationController.visible,current:NotificationController.current ? NotificationController.current.savedId : 0,hovered:NotificationController.hovered,mode:IslandState.mode,pinned:IslandState.islandPinned,width:capsule.width,height:capsule.height,history:NotificationService.history.length,unread:NotificationService.unreadCount,content:testRoot.itemRect("compactContent"),badge:testRoot.itemRect("notificationBadge"),clock:testRoot.itemRect("expandedClock")})
        }
        function grab(path: string) { canvas.grabToImage(result => result.saveToFile(path)) }
        function theme(light: bool) {
            const source = light ? Light.Theme : Dark.Theme
            for (const key of ['background','surface','surfaceVariant','card','textPrimary','textSecondary','textMuted','icon','accent','warning','buttonBackground','buttonHover','buttonPressed','notificationBackground','notificationUnread']) Theme[key] = source[key]
        }
        function move(x: int, y: int) { mouse.mouseMove(canvas,x,y) }
        function notificationState(): string {
            const body = testRoot.findItem(capsule, "notificationBody")
            return JSON.stringify({
                border: body.parent.border.width,
                cursor: body.cursorShape === Qt.PointingHandCursor ? "hand" : "arrow"
            })
        }
        function clickNotification() {
            const body = testRoot.findItem(capsule, "notificationBody")
            mouse.mouseClick(body, 100, 80)
        }
        function click(x: int, y: int) { mouse.mouseClick(canvas,x,y) }
        function quiet(value: bool) { FocusService.enabled = value }
        function reset() { IslandController.reset() }
        function clickBadge() {
            const item = testRoot.findItem(capsule, "notificationBadge")
            mouse.mouseClick(item, item.width / 2, item.height / 2)
        }
        function mode(value: int) { IslandState.mode = value }
        // The offscreen window does not resize; constrain the production island directly.
        function narrow() { capsule.availableWidth = 300 }
    }
}
