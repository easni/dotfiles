import QtQuick

import "../styles"
import "../core"

Rectangle {
    id: root

    property real availableWidth: 420

    clip: true

    radius: Theme.capsuleRadius
    color: Theme.background

    width: implicitWidth
    height: implicitHeight

    implicitWidth: viewHost.implicitWidth
    implicitHeight: viewHost.implicitHeight

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
            NotificationController.hovered = hovered && NotificationController.visible
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

        anchors.centerIn: parent
    }
}