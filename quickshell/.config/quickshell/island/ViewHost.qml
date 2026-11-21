import QtQuick

import "../views"
import "../core"
import "../components"
import "../services"

Item {
    property var islandContext: IslandRegistry.contextFor(parent)

    id: root

    property real availableWidth: 420
    property real availableHeight: 480

    implicitWidth: viewLoader.item ? viewLoader.item.implicitWidth : 0
    readonly property bool showBadge: !islandContext.state.devicePage && islandContext.state.mode !== islandContext.state.calendarMode && islandContext.state.mode !== islandContext.state.defaultMode && islandContext.state.mode !== islandContext.state.expandedMode && islandContext.state.mode !== islandContext.state.powerMenuMode && islandContext.state.mode !== islandContext.state.controlCenterMode && !islandContext.notifications.visible && NotificationService.unreadCount > 0
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
            if (islandContext.notifications.visible) return notificationView


            if (
                islandContext.state.mode === islandContext.state.defaultMode &&
                StatusManager.visible
            )
                return overlayView

            switch (islandContext.state.mode) {
            case islandContext.state.brightnessMode:
                return brightnessView
            case islandContext.state.audioMode:
                return audioView
            case islandContext.state.bluetoothMode:
                return bluetoothView
            case islandContext.state.calendarMode:
                return calendarView
            case islandContext.state.appLauncherMode:
                return appLauncherView
            case islandContext.state.clipboardMode:
                return clipboardView


            case islandContext.state.expandedMode:
                return expandedView

            case islandContext.state.powerMenuMode:
                return powerMenuView

            case islandContext.state.controlCenterMode:
                return controlCenterView

            case islandContext.state.themeSelectorMode:
                return themeSelectorView

            case islandContext.state.wallpaperSelectorMode:
                return wallpaperSelectorView

            case islandContext.state.mediaControlsMode:
                return mediaView

            default:
                return defaultView
            }
        }
    }

    Component {
        id: brightnessView
        BrightnessView { availableWidth: root.availableWidth; availableHeight: root.availableHeight }
    }

    Component {
        id: audioView
        AudioView { availableWidth: root.availableWidth; availableHeight: root.availableHeight }
    }

    Component {
        id: bluetoothView
        BluetoothView { availableWidth: root.availableWidth; availableHeight: root.availableHeight }
    }

    Component {
        id: calendarView
        CalendarView { availableWidth: root.availableWidth; availableHeight: root.availableHeight }
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
        ControlCenterView { availableWidth: root.availableWidth; availableHeight: root.availableHeight }
    }

    Component {
        id: themeSelectorView
        ThemeSelectorView { availableWidth: root.availableWidth; availableHeight: root.availableHeight }
    }

    Component {
        id: wallpaperSelectorView
        WallpaperSelectorView { availableWidth: root.availableWidth; availableHeight: root.availableHeight }
    }

    Component {
        id: mediaView
        MediaView { }
    }
}
