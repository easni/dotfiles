import QtQuick
import Quickshell
import "windows"
import "services"
import "core"

ShellRoot {
    Component.onCompleted: {
        NotificationController.initialize()
        NotificationService.initialize()
    }
    StatusWatcher {}
    WorkspaceService {}
    KeyboardService {}

    IslandIPC {}

    RoundedCorners {}
    IslandWindows {}
    Binding { target: NotificationService; property: "pausedIds"; value: IslandRegistry.pausedIds }
}
