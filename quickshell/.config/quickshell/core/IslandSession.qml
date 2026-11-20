import QtQuick
import Quickshell
import "../island"

Scope {
    id: root
    required property string screenName
    readonly property alias state: state
    readonly property alias navigation: navigation
    readonly property alias launcher: launcher
    readonly property alias notifications: notifications

    IslandViewState {
        id: state
        onModalChanged: if (modal) IslandRegistry.claimModal(root)
    }
    IslandNavigation { id: navigation; state: root.state }
    IslandLauncher { id: launcher; state: root.state }
    IslandNotifications {
        id: notifications
        state: root.state
        navigation: root.navigation
        receiving: IslandRegistry.target === root
    }
    Component.onCompleted: IslandRegistry.registerSession(root)
    Component.onDestruction: IslandRegistry.unregisterSession(root)
}
