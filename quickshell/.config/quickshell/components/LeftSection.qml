import QtQuick

import "../styles"
import "../core"

Item {
    id: root

    property bool interactive: true

    implicitWidth: Theme.leftSectionWidth
    implicitHeight: nowPlaying.implicitHeight

    NowPlayingWidget {
        id: nowPlaying

        anchors.left: parent.left
        anchors.leftMargin: Theme.sectionGap
        anchors.verticalCenter: parent.verticalCenter
    }

    Item {
        // The song text can extend past the layout's fixed section width.
        width: Math.max(root.width, nowPlaying.x + nowPlaying.width)
        height: root.height

        HoverHandler {
            enabled: root.interactive
            cursorShape: Qt.PointingHandCursor
        }

        TapHandler {
            enabled: root.interactive

            acceptedButtons: Qt.LeftButton
            gesturePolicy: TapHandler.ReleaseWithinBounds

            onTapped: function(event) {
                event.accepted = true

                IslandController.openMediaFromLeftSection()
            }
        }
    }
}
