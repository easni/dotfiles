
import QtQuick

import "../island"

QtObject {
    id: root
    required property var state


    // =========================================================
    // NAVIGATION
    // Open a specific island view/mode.
    // =========================================================

    property bool deviceReturnPinned: false
    property bool deviceReturnExpanded: false

    function openBluetooth() {
        if (root.state.mode === root.state.bluetoothMode) { closeBluetooth(); return }
        openDevicePage(root.state.bluetoothMode)
    }

    function openBrightness() { openDevicePage(root.state.brightnessMode) }

    function openAudio() { openDevicePage(root.state.audioMode) }

    function openDevicePage(mode) {
        ignoreNextIslandTap()
        deviceReturnPinned = root.state.mode === root.state.controlCenterMode && root.state.islandPinned
        deviceReturnExpanded = root.state.returnToExpanded || (root.state.mode === root.state.expandedMode && root.state.islandPinned)
        root.state.returnToExpanded = deviceReturnExpanded
        root.state.islandPinned = deviceReturnPinned
        root.state.mode = mode
    }

    function closeBluetooth() { closeDevicePage() }

    function closeDevicePage() {
        ignoreNextIslandTap()
        root.state.islandPinned = deviceReturnPinned
        root.state.returnToExpanded = deviceReturnExpanded
        root.state.mode = root.state.controlCenterMode
    }

    function openNotifications() {
        openControlCenterFromRightSection()
    }

    function openCalendar() {
        ignoreNextIslandTap()
        root.state.returnToExpanded = root.state.islandPinned
        root.state.islandPinned = false
        root.state.mode = root.state.calendarMode
    }

    function closeCalendar() {
        if (root.state.returnToExpanded) restoreExpanded()
        else reset()
    }

    function openDefault() {
        root.state.mode =
            root.state.defaultMode
    }

    function openExpanded() {
        root.state.mode =
            root.state.expandedMode
    }

    function openPowerMenu() {
        root.state.mode =
            root.state.powerMenuMode
    }

    function openControlCenter() {
        root.state.mode =
            root.state.controlCenterMode
    }

    function openThemeSelector() {
        root.state.mode =
            root.state.themeSelectorMode
    }

    function openWallpaperSelector() {
        root.state.mode =
            root.state.wallpaperSelectorMode
    }

    function openMediaControls() {
        ignoreNextIslandTap()

        root.state.returnToExpanded =
            root.state.islandPinned || root.state.returnToExpanded
        root.state.islandPinned = false

        root.state.mode =
            root.state.mediaControlsMode
    }

    // =========================================================
    // CONTEXTUAL NAVIGATION
    // Open views from specific parts of the island while
    // preserving the current interaction state.
    // =========================================================

    function openMediaFromLeftSection() {
        ignoreNextIslandTap()

        root.state.returnToExpanded =
            root.state.islandPinned

        root.state.islandPinned = false

        root.state.mode =
            root.state.mediaControlsMode
    }

    function openControlCenterFromRightSection() {
        ignoreNextIslandTap()

        root.state.returnToExpanded =
            root.state.islandPinned || root.state.returnToExpanded

        root.state.islandPinned = false

        root.state.mode =
            root.state.controlCenterMode
    }


    // =========================================================
    // INTERACTION
    // Small state changes caused by direct island interaction.
    // =========================================================

    function ignoreNextIslandTap() {
        root.state.ignoreNextIslandTap = true

        Qt.callLater(function() {
            root.state.ignoreNextIslandTap = false
        })
    }

    function clearIgnoredTap() {
        root.state.ignoreNextIslandTap = false
    }

    function togglePin() {
        root.state.islandPinned =
            !root.state.islandPinned
    }

    function restoreExpanded() {
        root.state.islandPinned = true
        root.state.returnToExpanded = false

        openExpanded()
    }


    // =========================================================
    // RESET
    // Return the island to its normal initial state.
    // =========================================================

    function reset() {
        root.state.ignoreNextIslandTap = false
        root.state.returnToExpanded = false
        root.state.islandPinned = false
        root.state.mode =
            root.state.defaultMode
    }
}
