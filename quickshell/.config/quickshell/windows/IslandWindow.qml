import QtQuick
import Quickshell
import Quickshell.Hyprland

import "../island"
import "../core"
import "../services"

PanelWindow {
    id: root

    visible: ThemeService.ready

    HyprlandFocusGrab {
        id: focusGrab

        active: ThemeService.ready && IslandState.modal

        windows: [ root ]

        onCleared: {
            IslandController.reset()
        }
    }

    focusable: focusGrab.active

    anchors {
        top: true
        left: true
        right: true
    }

    exclusiveZone: ThemeService.ready ? 33 : 0

    implicitHeight: capsule.implicitHeight + 20

    color: "transparent"

    Island {
        id: capsule
        availableWidth: Math.max(1, root.width - 20)

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 10
    }

    Region {
        id: capsuleMask

        item: capsule
    }

    mask: capsuleMask
}
