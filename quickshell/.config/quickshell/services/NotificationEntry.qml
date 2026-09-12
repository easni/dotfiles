import QtQuick
import Quickshell.Services.Notifications

// One history snapshot plus its optional live protocol object.
QtObject {
    id: root
    required property var notification
    readonly property int notificationId: notification ? notification.id : savedId
    property int savedId: 0
    property string app: ""
    property string summary: ""
    property string body: ""
    property string icon: ""
    property string image: ""
    property string time: ""
    property bool unread: true
    property bool isTransient: false
    property bool critical: false
    property bool live: notification !== null
    property var actions: []
    property real remaining: 0
    property bool refreshPending: false

    function refresh() {
        if (!notification) return
        savedId = notification.id
        app = notification.appName || "Notification"
        summary = notification.summary
        body = notification.body
        icon = NotificationService.resolveIcon(notification.appIcon)
        image = notification.image
        time = new Date().toLocaleTimeString([], {hour: "2-digit", minute: "2-digit"})
        isTransient = notification.transient
        critical = notification.urgency === NotificationUrgency.Critical
        actions = Array.from(notification.actions, action => ({identifier: action.identifier, text: action.text || "Open"}))
        // Quickshell 0.3.x passes through the D-Bus timeout in milliseconds.
        remaining = notification.expireTimeout < 0 ? (critical ? 10000 : 5000) : notification.expireTimeout
    }

    function scheduleRefresh() {
        if (refreshPending) return
        refreshPending = true
        Qt.callLater(function() {
            refreshPending = false
            if (!notification) return
            refresh()
            NotificationService.updated(root)
        })
    }

    property Connections changes: Connections {
        target: root.notification
        function onSummaryChanged() { root.scheduleRefresh() }
        function onBodyChanged() { root.scheduleRefresh() }
        function onAppNameChanged() { root.scheduleRefresh() }
        function onAppIconChanged() { root.scheduleRefresh() }
        function onImageChanged() { root.scheduleRefresh() }
        function onActionsChanged() { root.scheduleRefresh() }
        function onHintsChanged() { root.scheduleRefresh() }
        function onExpireTimeoutChanged() { root.scheduleRefresh() }
        function onUrgencyChanged() { root.scheduleRefresh() }
        function onTransientChanged() { root.scheduleRefresh() }
        function onClosed(reason) {
            root.actions = []
            // Notification-owned image data is no longer valid after closure.
            if (root.image.startsWith("image://")) root.image = ""
            root.notification = null
            NotificationService.closed(root)
        }
    }
}
