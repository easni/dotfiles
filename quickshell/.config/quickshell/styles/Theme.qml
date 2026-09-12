pragma Singleton

import QtQuick

QtObject {
    // =========================================================
    // COLORS
    // =========================================================

    // Backgrounds
    property color background: "#000000"
    property color surface: "#1A1A1A"
    property color surfaceVariant: "#303030"
    property color card: "#202020"

    // Overlays
    property color overlayLight: "#00000022"
    property color overlayMedium: "#00000044"
    property color overlayStrong: "#00000066"

    // Text
    property color textPrimary: "#E5E7EB"
    property color textSecondary: "#9CA3AF"
    property color textMuted: "#6B7280"

    // Icons
    property color icon: "#9CA3AF"
    property color iconActive: "#E5E7EB"
    property color iconDisabled: "#6B7280"

    // Accent
    property color accent: "#E5E7EB"
    property color accentHover: "#F3F4F6"
    property color accentPressed: "#D1D5DB"

    // Borders
    property color border: "#404040"
    property color borderHover: "#606060"
    property color borderSelected: accent
    property color borderSubtle: "#00000020"

    // Buttons
    property color buttonBackground: "#202020"
    property color buttonHover: "#2A2A2A"
    property color buttonPressed: "#404040"
    property color buttonSelected: accent
    property color buttonText: textPrimary
    property color controlButtonHover: "#404040"

    // Status / semantic colors
    property color danger: "#EF4444"
    property color dangerHover: "#DC2626"
    property color warning: "#F59E0B"
    property color success: "#22C55E"

    // Inputs / sliders
    property color sliderBackground: "#303030"
    property color sliderFill: accent
    property color inputBackground: "#202020"
    property color inputBorder: border

    // Notifications
    property color notificationBackground: card
    property color notificationUnread: surfaceVariant

    // Media
    property color progress: accent
    property color progressBackground: "#404040"

    // Wallpaper selector
    property color wallpaperOverlay: overlayStrong
    property color wallpaperSelection: accent

    // Power menu
    property color powerDanger: danger
    property color powerWarning: warning


    // =========================================================
    // TYPOGRAPHY
    // =========================================================

    property string iconFont: "JetBrainsMono Nerd Font"


    // =========================================================
    // LAYOUT & SIZING
    // =========================================================

    // General
    readonly property int outerPadding: 16
    readonly property int capsulePadding: 14
    readonly property int sectionGap: 0
    readonly property int clockSpacing: 2

    // Island
    readonly property int capsuleRadius: 23
    readonly property int leftSectionWidth: 130
    readonly property int rightSectionWidth: 90

    // Status overlays
    readonly property int statusDefaultWidth: 160
    readonly property int statusDefaultHeight: 33
    readonly property int statusWorkspaceWidth: 180
    readonly property int statusKeyboardWidth: 160
    readonly property int statusVolumeWidth: 280
    readonly property int statusBrightnessWidth: 280


    // =========================================================
    // RADIUS
    // =========================================================

    readonly property int radiusSmall: 8
    readonly property int radiusMedium: 12
    readonly property int radiusLarge: 16


    // =========================================================
    // ANIMATION
    // =========================================================

    readonly property int animationFast: 180
    readonly property int animationNormal: 300
    readonly property int animationSlow: 500

    readonly property var animationHorizontal: Easing.OutBack
    readonly property var animationVertical: Easing.OutCubic
}