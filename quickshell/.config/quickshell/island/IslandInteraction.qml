import QtQuick

import "../core"

Item {
    property var islandContext: IslandRegistry.contextFor(parent)

    id: root

    anchors.fill: parent

    property bool hovered: false

    function handleHoverChanged(isHovered) {

        root.hovered = isHovered

        if (islandContext.notifications.visible) {
            expandTimer.stop()
            collapseTimer.stop()
            return
        }

        if (islandContext.state.modal)
            return

        if (isHovered) {

            collapseTimer.stop()

            if (
                islandContext.state.mode === islandContext.state.mediaControlsMode ||
                islandContext.state.mode === islandContext.state.controlCenterMode ||
                islandContext.state.devicePage
            )
                return

            expandTimer.restart()

        } else {

            expandTimer.stop()

            if (
                islandContext.state.mode === islandContext.state.mediaControlsMode ||
                islandContext.state.mode === islandContext.state.controlCenterMode ||
                islandContext.state.devicePage
            ) {

                if (!islandContext.state.islandPinned)
                    collapseTimer.restart()

                return
            }

            if (!islandContext.state.islandPinned)
                collapseTimer.restart()
        }
    }

    Connections {
        target: islandContext.state
        function onModeChanged() {
            expandTimer.stop()
            collapseTimer.stop()
        }
    }

    Connections {
        target: islandContext.notifications
        function onVisibleChanged() {
            if (islandContext.notifications.visible) {
                expandTimer.stop()
                collapseTimer.stop()
                islandContext.notifications.hovered = root.hovered
            }
        }
    }

    MouseArea {
        enabled: !islandContext.notifications.visible
        anchors.fill: parent

        acceptedButtons: Qt.LeftButton

        onClicked: {

            if (islandContext.state.modal || islandContext.notifications.visible)
                return

            if (islandContext.state.ignoreNextIslandTap) {

                islandContext.navigation.clearIgnoredTap()

                expandTimer.stop()
                collapseTimer.stop()

                return
            }

            islandContext.navigation.togglePin()

            if (islandContext.state.islandPinned) {

                expandTimer.stop()
                collapseTimer.stop()

                if (islandContext.state.mode === islandContext.state.defaultMode) {
                    islandContext.navigation.openExpanded()
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

            if (islandContext.notifications.visible || islandContext.state.modal) return

            if (
                islandContext.state.mode === islandContext.state.mediaControlsMode ||
                islandContext.state.mode === islandContext.state.controlCenterMode ||
                islandContext.state.devicePage
            )
                return

            islandContext.navigation.openExpanded()
        }
    }

    Timer {
        id: collapseTimer

        interval: 250
        repeat: false

        onTriggered: {

            if (islandContext.notifications.visible || islandContext.state.modal) return

            if (
                islandContext.state.mode === islandContext.state.mediaControlsMode ||
                islandContext.state.mode === islandContext.state.controlCenterMode ||
                islandContext.state.devicePage
            ) {

                if (islandContext.state.returnToExpanded) {

                    islandContext.navigation.restoreExpanded()

                } else {

                    islandContext.navigation.reset()
                }

                return
            }

            islandContext.navigation.reset()
        }
    }
}