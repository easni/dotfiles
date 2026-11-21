import QtQuick
import Quickshell
import "../core"

Variants {
    // Qt creates an unnamed placeholder when the final physical output goes
    // away. Hyprland can also advertise its virtual FALLBACK output briefly.
    // Neither should own an island or retain a keyboard grab.
    model: IslandRegistry.screens

    IslandWindow {
        required property var modelData
        screen: modelData
    }
}
