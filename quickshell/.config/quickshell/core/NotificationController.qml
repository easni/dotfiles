pragma Singleton
import QtQuick
import Quickshell
import "../services"
import "../island"

Singleton {
    id: root
    property var current: null
    property var pending: null
    property bool hovered: false
    property real remaining: 0
    readonly property bool eligible: IslandState.mode === IslandState.defaultMode && !FocusService.enabled
    readonly property bool visible: current !== null && eligible && !StatusManager.visible
    readonly property int moreUnread: Math.max(0, NotificationService.unreadCount - (current && current.unread && !current.isTransient ? 1 : 0))

    function initialize() {}
    function hide() {
        current = null
        pending = null
        remaining = 0
        hovered = false
    }
    function show(entry) {
        current = entry
        remaining = entry.critical ? 10000 : 5000
    }
    function receive(entry) {
        if (!eligible) return
        if (hovered && current) pending = entry
        else show(entry)
    }
    function dismiss() {
        if (current) NotificationService.dismiss(current.savedId)
    }
    function openHistory() {
        hide()
        IslandController.openNotifications()
    }
    onEligibleChanged: { if (!eligible) hide() }
    onHoveredChanged: {
        if (!hovered && pending) {
            const entry = pending
            pending = null
            show(entry)
        }
    }
    // Pause protocol expiry as well as preview time while reading or while
    // a short system-status overlay temporarily occupies the capsule.
    Binding {
        target: NotificationService
        property: "pausedId"
        value: root.current && (root.hovered || StatusManager.visible) ? root.current.savedId : -1
    }
    Connections {
        target: NotificationService
        function onArrived(entry) { root.receive(entry) }
        function onEntryClosed(notificationId) {
            if (root.pending && root.pending.savedId === notificationId) root.pending = null
            if (root.current && root.current.savedId === notificationId) {
                const next = root.pending
                root.hide()
                if (next && root.eligible) root.show(next)
            }
        }
    }
    Timer {
        interval: 100
        running: root.visible && !root.hovered
        repeat: true
        property real previous: Date.now()
        onRunningChanged: previous = Date.now()
        onTriggered: {
            const now = Date.now()
            root.remaining -= now - previous
            previous = now
            if (root.remaining <= 0) root.hide()
        }
    }
}
