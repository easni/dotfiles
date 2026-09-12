import QtQuick
import "../components"
import "../core"
import "../services"

Item {
    id: root
    property real availableWidth: 420
    implicitWidth: Math.max(1, Math.min(420, availableWidth))
    implicitHeight: card.implicitHeight

    NotificationCard {
        id: card
        width: root.implicitWidth
        height: implicitHeight
        entry: NotificationController.current
        preview: true
        moreUnread: NotificationController.moreUnread
        onOpenRequested: NotificationController.openHistory()
        onDismissRequested: NotificationController.dismiss()
        onActionRequested: identifier => {
            if (entry) NotificationService.invoke(entry.savedId, identifier)
        }
    }
}
