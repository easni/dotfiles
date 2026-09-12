import QtQuick
import "../services"
import "../core"

NotificationButton {
    objectName: "notificationBadge"
    visible: NotificationService.unreadCount > 0
    text: "󰂚 " + (NotificationService.unreadCount > 99 ? "99+" : NotificationService.unreadCount)
    Accessible.name: NotificationService.unreadCount + " unread notifications"
    onClicked: IslandController.openNotifications()
}
