import QtQuick
import Quickshell
import Quickshell.Io
import "../services"
import "../core"
import "../island"

ShellRoot {
    Component.onCompleted: {
        NotificationController.initialize()
        NotificationService.initialize()
    }
    IpcHandler {
        target: "test"
        function state(): string {
            return JSON.stringify({
                count: NotificationService.history.length,
                unread: NotificationService.unreadCount,
                live: NotificationService.liveCount,
                visible: NotificationController.visible,
                current: NotificationController.current ? NotificationController.current.savedId : 0,
                pending: NotificationController.pending ? NotificationController.pending.savedId : 0,
                remaining: NotificationController.remaining,
                mode: IslandState.mode,
                pinned: IslandState.islandPinned,
                entries: NotificationService.history.map(e => ({id:e.savedId,summary:e.summary,body:e.body,live:e.live,unread:e.unread,remaining:e.remaining,actions:e.actions.length}))
            })
        }
        function hover(value: bool) { NotificationController.hovered = value }
        function focus(value: bool) { FocusService.enabled = value }
        function mode(value: int) { IslandState.mode = value }
        function overlay(value: bool) { StatusManager.visible = value }
        function clear() { NotificationService.clear() }
        function dismiss() { NotificationController.dismiss() }
        function invoke(id: int, action: string) { NotificationService.invoke(id, action) }
        function read() { NotificationService.markRead() }
        function open() { NotificationController.openHistory() }
    }
}

