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

    IslandWindow {}
}