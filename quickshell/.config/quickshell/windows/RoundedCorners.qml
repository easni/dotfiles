import QtQuick
import Quickshell
import Quickshell.Wayland

import "../components"

Variants {
    model: Quickshell.screens

    PanelWindow {
        id: root

        required property var modelData

        property int cornerSize: 18
        property color cornerColor: "#000000"

        screen: modelData
        color: "transparent"
        focusable: false
        aboveWindows: true
        exclusiveZone: -1
        exclusionMode: ExclusionMode.Ignore

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.namespace: "luci-rounded-corners"
        WlrLayershell.exclusiveZone: -1
        WlrLayershell.exclusionMode: ExclusionMode.Ignore

        anchors {
            top: true
            left: true
            right: true
            bottom: true
        }

        InverseCorner {
            id: topLeft
            cornerSize: root.cornerSize
            fillColor: root.cornerColor
            corner: "topLeft"
            anchors.top: parent.top
            anchors.left: parent.left
        }

        InverseCorner {
            id: topRight
            cornerSize: root.cornerSize
            fillColor: root.cornerColor
            corner: "topRight"
            anchors.top: parent.top
            anchors.right: parent.right
        }

        InverseCorner {
            id: bottomLeft
            cornerSize: root.cornerSize
            fillColor: root.cornerColor
            corner: "bottomLeft"
            anchors.bottom: parent.bottom
            anchors.left: parent.left
        }

        InverseCorner {
            id: bottomRight
            cornerSize: root.cornerSize
            fillColor: root.cornerColor
            corner: "bottomRight"
            anchors.bottom: parent.bottom
            anchors.right: parent.right
        }

        mask: Region {
            Region { item: topLeft }
            Region { item: topRight }
            Region { item: bottomLeft }
            Region { item: bottomRight }
        }
    }
}
