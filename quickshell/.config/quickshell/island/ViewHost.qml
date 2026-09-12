import QtQuick

import "../views"
import "../core"
import "../components"
import "../services"

Item {
    id: root

    property real availableWidth: 420
    property real availableHeight: 480

    implicitWidth: viewLoader.item ? viewLoader.item.implicitWidth : 0
    readonly property bool showBadge: IslandState.mode !== IslandState.defaultMode && IslandState.mode !== IslandState.expandedMode && IslandState.mode !== IslandState.powerMenuMode && IslandState.mode !== IslandState.controlCenterMode && !NotificationController.visible && NotificationService.unreadCount > 0
    implicitHeight: viewLoader.item ? viewLoader.item.implicitHeight : 0

    NotificationBadge {
        visible: root.showBadge
        z: 10
        anchors.top: parent.top
        anchors.topMargin: 21
        anchors.horizontalCenter: parent.horizontalCenter
    }

    Loader {
        id: viewLoader

        anchors.centerIn: parent

        width: item ? item.implicitWidth : 0
        height: item ? item.implicitHeight : 0

        sourceComponent: {
            if (NotificationController.visible) return notificationView


            if (
                IslandState.mode === IslandState.defaultMode &&
                StatusManager.visible
            )
                return overlayView

            switch (IslandState.mode) {
            case IslandState.appLauncherMode:
                return appLauncherView
            case IslandState.clipboardMode:
                return clipboardView


            case IslandState.expandedMode:
                return expandedView

            case IslandState.powerMenuMode:
                return powerMenuView

            case IslandState.controlCenterMode:
                return controlCenterView

            case IslandState.themeSelectorMode:
                return themeSelectorView

            case IslandState.wallpaperSelectorMode:
                return wallpaperSelectorView

            case IslandState.mediaControlsMode:
                return mediaView

            default:
                return defaultView
            }
        }
    }

    Component {
        id: appLauncherView
        AppLauncherView { availableWidth: root.availableWidth; availableHeight: root.availableHeight }
    }
    Component {
        id: clipboardView
        ClipboardView { availableWidth: root.availableWidth; availableHeight: root.availableHeight }
    }

    Component {
        id: notificationView
        NotificationPopup { availableWidth: root.availableWidth }
    }

    Component {
        id: defaultView
        DefaultView { }
    }

    Component {
        id: overlayView
        OverlayView { }
    }

    Component {
        id: expandedView
        ExpandedView { }
    }

    Component {
        id: powerMenuView
        PowerMenuView { }
    }

    Component {
        id: controlCenterView
        ControlCenterView { }
    }

    Component {
        id: themeSelectorView
        ThemeSelectorView { }
    }

    Component {
        id: wallpaperSelectorView
        WallpaperSelectorView { }
    }

    Component {
        id: mediaView
        MediaView { }
    }
}
