pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root
    property var history: []
    property var liveEntries: ({})
    property int unreadCount: 0
    property int liveCount: 0
    property bool hasExpiring: false
    property int pausedId: -1
    readonly property url defaultIcon: Qt.resolvedUrl("../assets/icons/bell.svg")
    signal arrived(var entry)
    signal entryClosed(int notificationId)

    function initialize() {} // Explicitly instantiate the singleton at shell startup.

    function resolveIcon(icon) {
        if (!icon) return defaultIcon.toString()
        if (icon.startsWith("/") || icon.includes(":/")) return icon
        return Quickshell.iconPath(icon, true) || defaultIcon.toString()
    }

    function recount() {
        unreadCount = history.filter(entry => entry.unread).length
        hasExpiring = Object.keys(liveEntries).some(key => liveEntries[key].remaining > 0)
    }

    function updated(entry) {
        const index = history.indexOf(entry)
        if (entry.isTransient && index !== -1)
            history = history.filter(item => item !== entry)
        else if (!entry.isTransient && index === -1)
            history = [entry].concat(history)
        entry.unread = true
        trimHistory()
        recount()
        arrived(entry)
    }

    function trimHistory() {
        while (history.length > 100) remove(history.length - 1)
    }

    function closed(entry) {
        delete liveEntries[entry.savedId]
        liveCount--
        recount()
        entryClosed(entry.savedId)
        if (history.indexOf(entry) === -1) entry.destroy()
    }

    function markRead() {
        for (const entry of history) entry.unread = false
        recount()
    }

    function markEntryRead(notificationId) {
        const entry = history.find(item => item.savedId === notificationId)
        if (!entry || !entry.unread) return
        entry.unread = false
        recount()
    }

    function dismiss(notificationId) {
        const entry = liveEntries[notificationId]
        if (!entry) return
        entry.unread = false
        recount()
        entry.notification.dismiss()
    }

    function invoke(notificationId, identifier) {
        const entry = liveEntries[notificationId]
        if (!entry || !entry.notification) return
        const action = Array.from(entry.notification.actions).find(item => item.identifier === identifier)
        if (!action) return
        entry.unread = false
        recount()
        action.invoke() // Quickshell preserves resident notifications itself.
    }

    function remove(index) {
        if (index < 0 || index >= history.length) return
        const entry = history[index]
        // Close before removing the snapshot so closed() does not destroy it twice.
        if (entry.notification) entry.notification.dismiss()
        history = history.filter(item => item !== entry)
        entry.destroy()
        recount()
    }

    function clear() {
        while (history.length) remove(history.length - 1)
    }

    function send(app, summary, body) {
        Quickshell.execDetached(["notify-send", "--app-name", app, summary, body])
    }

    Component { id: entryComponent; NotificationEntry {} }

    NotificationServer {
        keepOnReload: true
        bodySupported: true
        actionsSupported: true
        imageSupported: true
        persistenceSupported: true
        bodyMarkupSupported: false
        bodyHyperlinksSupported: false
        bodyImagesSupported: false
        actionIconsSupported: false
        inlineReplySupported: false
        onNotification: function(notification) {
            notification.tracked = true
            const entry = entryComponent.createObject(root, {notification: notification}) as NotificationEntry
            entry.refresh()
            root.liveEntries[entry.savedId] = entry
            root.liveCount++
            entry.unread = !notification.lastGeneration
            if (!entry.isTransient) root.history = [entry].concat(root.history)
            root.trimHistory()
            root.recount()
            if (!notification.lastGeneration) root.arrived(entry)
        }
    }

    Timer {
        interval: 100
        running: root.hasExpiring
        repeat: true
        property real previous: Date.now()
        onRunningChanged: previous = Date.now()
        onTriggered: {
            const now = Date.now()
            const elapsed = now - previous
            previous = now
            for (const key of Object.keys(root.liveEntries)) {
                const entry = root.liveEntries[key]
                if (!entry || !entry.notification || entry.remaining <= 0 || entry.savedId === root.pausedId) continue
                entry.remaining -= elapsed
                if (entry.remaining <= 0) entry.notification.expire()
            }
        }
    }
}
