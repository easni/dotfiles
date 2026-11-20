pragma Singleton
import QtQuick
import Quickshell
import "../island"
import "../services"

IslandNotifications {
    state: IslandState
    navigation: IslandController
    receiving: IslandRegistry.sessions.length === 0
    Binding { target: NotificationService; property: "pausedId"; value: pausedId }
}
