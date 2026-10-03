import QtQuick
import QtQml

import "../styles"
import "../services"


Column {
    id: root

    property bool showCava: true

    property int titleWidth: Math.max(0, artistWidth
        - (miniVisualizer.visible ? miniVisualizer.width + titleRow.spacing : 0))
    property int artistWidth: 130

    property int titleFontSize: 13
    property int artistFontSize: 11

    spacing: 2

    readonly property bool hasMedia: MediaService.hasPlayer
    property real scrollElapsed: 0
    readonly property real scrollDuration: Math.max(titleText.scrollDuration, artistText.scrollDuration)

    function restartScrolling() {
        scrollCycle.stop()
        scrollElapsed = 0
        if (visible && scrollDuration > 0)
            scrollCycle.start()
    }

    function scheduleScrolling() {
        Qt.callLater(root.restartScrolling)
    }

    onVisibleChanged: scheduleScrolling()
    Component.onCompleted: scheduleScrolling()

    SequentialAnimation {
        id: scrollCycle
        loops: Animation.Infinite

        PropertyAction { target: root; property: "scrollElapsed"; value: 0 }
        PauseAnimation { duration: 2000 }
        NumberAnimation {
            target: root
            property: "scrollElapsed"
            from: 0
            to: root.scrollDuration
            duration: Math.ceil(root.scrollDuration)
            easing.type: Easing.Linear
        }
    }

    Row {
        id: titleRow
        spacing: 6

        Cava {
            id: miniVisualizer

            visible: hasMedia && root.showCava

            anchors.verticalCenter: parent.verticalCenter
        }

        ScrollingText {
            id: titleText
            elapsed: root.scrollElapsed
            onLayoutChanged: root.scheduleScrolling()

            text: hasMedia
                    ? (MediaService.title || "No Title")
                    : "Nothing"

            maxWidth: root.titleWidth

            fontSize: root.titleFontSize
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    ScrollingText {
        id: artistText
        elapsed: root.scrollElapsed
        onLayoutChanged: root.scheduleScrolling()

        text: hasMedia
                ? (MediaService.artist || "Unknown Artist")
                : "Playing"

        maxWidth: root.artistWidth

        fontSize: root.artistFontSize

        opacity: 0.7
    }

}
