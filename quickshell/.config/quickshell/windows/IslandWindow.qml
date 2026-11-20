import QtQuick
import Quickshell
import Quickshell.Hyprland

import "../island"
import "../core"
import "../services"

PanelWindow {
    id: root

    IslandSession { id: session; screenName: root.screen ? root.screen.name : "" }

    visible: ThemeService.ready

    readonly property bool modalOpen: ThemeService.ready && session.state.modal

    // Recreate the grab after Hyprland has focused the destination workspace.
    // A grab can remain active even after a workspace switch steals its focus.
    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (root.modalOpen && (event.name === "workspacev2"
                    || event.name === "focusedmonv2"
                    || event.name === "activespecialv2")) {
                focusGrab.active = false
                restoreGrab.restart()
            }
        }
    }

    Timer {
        id: restoreGrab
        interval: 0
        onTriggered: focusGrab.active = root.modalOpen
    }

    onModalOpenChanged: {
        restoreGrab.stop()
        focusGrab.active = modalOpen
    }

    HyprlandFocusGrab {
        id: focusGrab

        active: root.modalOpen

        windows: [ root ]

        onCleared: {
            if (session.state.launcher) session.launcher.close()
            else if (session.state.mode === session.state.calendarMode) session.navigation.closeCalendar()
            else if (session.state.modal) session.navigation.reset()
        }
    }

    // Exclusive layer focus conflicts with Hyprland's outside-click grab.
    // Keep the window focusable while the grab is being renewed, too.
    focusable: root.modalOpen || (ThemeService.ready && session.state.mode === session.state.bluetoothMode)

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
        islandContext: session
        availableWidth: Math.max(1, root.width - 20)
        availableHeight: root.screen ? Math.max(1, root.screen.height - 20) : 480

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
