import QtQuick

import "../core"

Item {
    id: root

    anchors.fill: parent

    property bool hovered: false

    function handleHoverChanged(isHovered) {

        root.hovered = isHovered

        if (NotificationController.visible) {
            expandTimer.stop()
            collapseTimer.stop()
            return
        }

        if (IslandState.modal)
            return

        if (isHovered) {

            collapseTimer.stop()

            if (
                IslandState.mode === IslandState.mediaControlsMode ||
                IslandState.mode === IslandState.controlCenterMode
            )
                return

            expandTimer.restart()

        } else {

            expandTimer.stop()

            if (
                IslandState.mode === IslandState.mediaControlsMode ||
                IslandState.mode === IslandState.controlCenterMode
            ) {

                if (!IslandState.islandPinned)
                    collapseTimer.restart()

                return
            }

            if (!IslandState.islandPinned)
                collapseTimer.restart()
        }
    }

    Connections {
        target: IslandState
        function onModeChanged() {
            expandTimer.stop()
            collapseTimer.stop()
        }
    }

    Connections {
        target: NotificationController
        function onVisibleChanged() {
            if (NotificationController.visible) {
                expandTimer.stop()
                collapseTimer.stop()
                NotificationController.hovered = root.hovered
            }
        }
    }

    MouseArea {
        enabled: !NotificationController.visible
        anchors.fill: parent

        acceptedButtons: Qt.LeftButton

        onClicked: {

            if (IslandState.modal || NotificationController.visible)
                return

            if (IslandState.ignoreNextIslandTap) {

                IslandController.clearIgnoredTap()

                expandTimer.stop()
                collapseTimer.stop()

                return
            }

            IslandController.togglePin()

            if (IslandState.islandPinned) {

                expandTimer.stop()
                collapseTimer.stop()

                if (IslandState.mode === IslandState.defaultMode) {
                    IslandController.openExpanded()
                }

            } else {

                if (!root.hovered)
                    collapseTimer.restart()
            }
        }
    }

    Timer {
        id: expandTimer

        interval: 100
        repeat: false

        onTriggered: {

            if (NotificationController.visible || IslandState.modal) return

            if (
                IslandState.mode === IslandState.mediaControlsMode ||
                IslandState.mode === IslandState.controlCenterMode
            )
                return

            IslandController.openExpanded()
        }
    }

    Timer {
        id: collapseTimer

        interval: 250
        repeat: false

        onTriggered: {

            if (NotificationController.visible || IslandState.modal) return

            if (
                IslandState.mode === IslandState.mediaControlsMode ||
                IslandState.mode === IslandState.controlCenterMode
            ) {

                if (IslandState.returnToExpanded) {

                    IslandController.restoreExpanded()

                } else {

                    IslandController.reset()
                }

                return
            }

            IslandController.reset()
        }
    }
}