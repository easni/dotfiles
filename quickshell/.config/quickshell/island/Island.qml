import QtQuick

import "../styles"
import "../core"

Rectangle {
    property var islandContext: IslandRegistry.contextFor(parent)

    id: root

    property real availableWidth: 420
    property real availableHeight: 480

    clip: true

    radius: Theme.capsuleRadius
    color: Theme.background

    width: implicitWidth
    height: implicitHeight

    implicitWidth: viewHost.implicitWidth
    readonly property real targetHeight: viewHost.implicitHeight
    implicitHeight: targetHeight

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Theme.animationNormal
            easing.type: Theme.animationHorizontal
        }
    }

    Behavior on implicitHeight {
        NumberAnimation {
            duration: Theme.animationNormal
            easing.type: Theme.animationVertical
        }
    }

    HoverHandler {
        id: islandHover

        onHoveredChanged: {
            islandContext.notifications.hovered = hovered && islandContext.notifications.visible
            islandInteraction.handleHoverChanged(hovered)
        }
    }

    IslandInteraction {
        id: islandInteraction

        anchors.fill: parent
    }

    ViewHost {
        id: viewHost
        availableWidth: root.availableWidth
        availableHeight: root.availableHeight

        anchors.centerIn: parent
    }
}
