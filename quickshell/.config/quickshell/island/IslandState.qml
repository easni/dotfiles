pragma Singleton

import QtQuick

QtObject {

    // =========================================================
    // MODES
    // =========================================================

    readonly property int defaultMode: 0
    readonly property int expandedMode: 1
    readonly property int powerMenuMode: 2
    readonly property int controlCenterMode: 3
    readonly property int themeSelectorMode: 4
    readonly property int wallpaperSelectorMode: 5
    readonly property int mediaControlsMode: 6
    readonly property int appLauncherMode: 7
    readonly property int clipboardMode: 8

    // =========================================================
    // STATE
    // =========================================================

    property int mode: defaultMode

    property bool islandPinned: false
    property bool returnToExpanded: false
    property bool ignoreNextIslandTap: false

    // =========================================================
    // DERIVED STATE
    // =========================================================

    readonly property bool launcher: mode === appLauncherMode || mode === clipboardMode

    readonly property bool modal:
        launcher ||
        mode === powerMenuMode ||
        mode === themeSelectorMode ||
        mode === wallpaperSelectorMode
}