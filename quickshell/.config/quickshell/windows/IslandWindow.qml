import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

import "../island"
import "../core"
import "../services"
import "../styles"

PanelWindow {
    id: root

    IslandSession { id: session; screenName: root.screen ? root.screen.name : "" }

    visible: ThemeService.ready

    readonly property bool modalOpen: ThemeService.ready && session.state.modal

    readonly property var monitor: Hyprland.monitors.values.find(m => m.name === session.screenName)
    readonly property int specialWorkspaceId: monitor?.lastIpcObject.specialWorkspace?.id ?? 0
    readonly property var visibleWorkspace: specialWorkspaceId
        ? Hyprland.workspaces.values.find(ws => ws.id === specialWorkspaceId)
        : monitor?.activeWorkspace
    // Hyprland also sets hasFullscreen for maximized windows. Bit 2 of the
    // compositor's client state means the window actually covers the bar.
    readonly property bool fullscreen: !!visibleWorkspace?.toplevels.values.some(
        client => (client.lastIpcObject.fullscreen & 2) !== 0)
    readonly property bool compact: session.state.mode === session.state.defaultMode
    // Toasts and notification previews both use the default navigation mode.
    // Only the preview needs pointer input over a fullscreen client.
    readonly property bool fullscreenPassthrough: fullscreen && compact && !session.notifications.visible
    readonly property bool hideCompactIsland: fullscreenPassthrough && !StatusManager.visible
    WlrLayershell.layer: fullscreen || !compact ? WlrLayer.Overlay : WlrLayer.Top

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
    focusable: root.modalOpen || (ThemeService.ready && session.state.devicePage)

    anchors {
        top: true
        left: true
        right: true
    }

    exclusiveZone: ThemeService.ready ? 33 : 0

    // Reuse space for the tallest view opened on this monitor. Resizing the
    // Wayland buffer on the last animation frame can make the capsule jump.
    // The input mask below still follows the visible capsule on every frame.
    property int tallestView: 0
    implicitHeight: Math.min(tallestView, capsule.availableHeight) + 20
    Component.onCompleted: tallestView = Math.ceil(capsule.targetHeight)

    Connections {
        target: capsule
        function onTargetHeightChanged() {
            root.tallestView = Math.max(root.tallestView, Math.ceil(capsule.targetHeight))
        }
    }

    color: "transparent"

    Island {
        id: capsule
        property real fullscreenCloseProgress: 0
        visible: fullscreenCloseProgress < 1
        contentVisible: !root.hideCompactIsland
        // Keep the normal width and height easing underneath. Flatten the
        // closing silhouette faster than it narrows so it ends in a thin line.
        transform: Scale {
            origin.x: capsule.width / 2
            origin.y: 0
            xScale: 1 - capsule.fullscreenCloseProgress
            yScale: xScale * xScale
        }
        states: State {
            name: "fullscreenIdle"
            when: root.hideCompactIsland
            PropertyChanges { target: capsule; fullscreenCloseProgress: 1 }
        }
        transitions: Transition {
            to: "fullscreenIdle"
            NumberAnimation {
                property: "fullscreenCloseProgress"
                duration: Theme.animationNormal
            }
        }
        edgeHovered: revealEdge.visible && edgeHover.hovered
        islandContext: session
        availableWidth: Math.max(1, root.width - 20)
        availableHeight: root.screen ? Math.max(1, root.screen.height - 20) : 480

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 10
    }

    mask: Region {
        x: Math.floor(capsule.x)
        y: Math.floor(capsule.y)
        width: root.fullscreenPassthrough ? 0 : Math.ceil(capsule.width)
        height: root.fullscreenPassthrough ? 0 : Math.ceil(capsule.height)
    }

    // The compact panel sits underneath fullscreen clients. Keep a small
    // independent pointer target on the overlay so it can still be revealed.
    PanelWindow {
        id: revealEdge
        screen: root.screen
        visible: root.visible && root.fullscreen
            && (root.compact || session.state.mode === session.state.expandedMode)
        anchors.top: true
        implicitWidth: 160
        implicitHeight: root.compact ? 2 : capsule.anchors.topMargin
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "luci-reveal-edge"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        Item {
            anchors.fill: parent
            HoverHandler { id: edgeHover }
        }
    }
}
