import QtQuick

import "../views"
import "../core"
import "../components"
import "../services"

Item {
    id: root

    property real availableWidth: 420

    implicitWidth: viewLoader.item ? viewLoader.item.implicitWidth : 0
    readonly property bool showBadge: IslandState.mode !== IslandState.defaultMode && IslandState.mode !== IslandState.expandedMode && IslandState.mode !== IslandState.controlCenterMode && NotificationService.unreadCount > 0
    implicitHeight: (viewLoader.item ? viewLoader.item.implicitHeight : 0) + (showBadge ? 34 : 0)

    NotificationBadge {
        visible: root.showBadge
        anchors.top: parent.top
        anchors.topMargin: 4
        anchors.horizontalCenter: parent.horizontalCenter
    }

    Loader {
        id: viewLoader

        anchors.centerIn: parent
        anchors.verticalCenterOffset: root.showBadge ? 17 : 0

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
