pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    property bool visible: false

    property string mode: ""
    property string icon: ""
    property string title: ""
    property var value

    property int statusWidth: 160
    property int statusHeight: 33

    function showBrightness(percent, title) {
        show({mode: "brightness", icon: percent < 25 ? "󰃞" : percent < 60 ? "󰃟" : "󰃠",
              title: title, value: percent, statusWidth: 300, statusHeight: 33})
    }

    function show(data) {

        mode = data.mode
        icon = data.icon
        title = data.title
        value = data.value

        statusWidth = data.statusWidth ?? 160
        statusHeight = data.statusHeight ?? 33

        visible = true

        hideTimer.restart()
    }

    Timer {
        id: hideTimer

        interval: 1000
        repeat: false

        onTriggered: {
            root.visible = false
        }
    }
}
