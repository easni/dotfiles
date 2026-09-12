pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import "../services"

Singleton {

    id: root

    // =========================================================
    // STATE
    // =========================================================

    property bool connected: false
    property bool connecting: false

    property int strength: 0
    property string ssid: ""

    property string icon: "󰤮"

    property string subtitle:
        connected
            ? ssid
            : (connecting
                ? "Connecting..."
                : "Disconnected")

    property url svgIcon: !connected
        ? Qt.resolvedUrl("../assets/icons/wifi-off.svg")
        : Qt.resolvedUrl("../assets/icons/wifi.svg")


    // =========================================================
    // NOTIFICATION STATE
    // =========================================================

    // Used so Luci doesn't send a notification when
    // the service first starts and reads the current state.
    property bool initialized: false

    property bool previousConnected: false
    property string previousSsid: ""


    // =========================================================
    // WIFI READER
    // =========================================================

    Process {

        id: wifiReader

        command: [
            "bash",
            "-c",
            "nmcli -t -f ACTIVE,SIGNAL,SSID dev wifi | grep '^yes:'"
        ]

        stdout: StdioCollector {

            onStreamFinished: {

                let line = text.trim()


                // -------------------------------------------------
                // Disconnected
                // -------------------------------------------------

                if (line === "") {

                    root.connected = false
                    root.strength = 0
                    root.ssid = ""

                    root.updateIcon()
                    root.handleStateChange()

                    return
                }


                // -------------------------------------------------
                // Connected
                // -------------------------------------------------

                let parts = line.split(":")

                root.connected = true
                root.connecting = false

                root.strength = Number(parts[1])
                root.ssid = parts.slice(2).join(":")

                root.updateIcon()
                root.handleStateChange()
            }
        }
    }


    // =========================================================
    // WIFI TOGGLE
    // =========================================================

    Process {

        id: wifiToggle

        onExited: {
            root.update()
        }
    }


    // =========================================================
    // STATE CHANGE DETECTION
    // =========================================================

    function handleStateChange() {

        // First reading after Luci starts.
        // Don't send a notification.
        if (!root.initialized) {

            root.previousConnected =
                root.connected

            root.previousSsid =
                root.ssid

            root.initialized = true

            console.log(
                "Wi-Fi initial state:",
                root.connected
                    ? root.ssid
                    : "Disconnected"
            )

            return
        }


        // -------------------------------------------------
        // Disconnected → Connected
        // -------------------------------------------------

        if (
            !root.previousConnected &&
            root.connected
        ) {

            console.log(
                "Wi-Fi connected:",
                root.ssid
            )

            NotificationService.send(
                "Luci",
                "Wi-Fi connected",
                root.ssid
            )
        }


        // -------------------------------------------------
        // Connected → Disconnected
        // -------------------------------------------------

        else if (
            root.previousConnected &&
            !root.connected
        ) {

            console.log(
                "Wi-Fi disconnected"
            )

            NotificationService.send(
                "Luci",
                "Wi-Fi disconnected",
                ""
            )
        }


        // -------------------------------------------------
        // Connected → Different network
        // -------------------------------------------------

        else if (
            root.previousConnected &&
            root.connected &&
            root.previousSsid !== root.ssid
        ) {

            console.log(
                "Wi-Fi network changed:",
                root.previousSsid,
                "→",
                root.ssid
            )

            NotificationService.send(
                "Luci",
                "Wi-Fi network changed",
                root.ssid
            )
        }


        // -------------------------------------------------
        // Save current state
        // -------------------------------------------------

        root.previousConnected =
            root.connected

        root.previousSsid =
            root.ssid
    }


    // =========================================================
    // POLLING
    // =========================================================

    Timer {

        interval: 5000

        running: true
        repeat: true

        onTriggered: {
            root.update()
        }
    }


    // =========================================================
    // UPDATE
    // =========================================================

    function update() {

        wifiReader.running = false
        wifiReader.running = true
    }


    // =========================================================
    // TOGGLE WIFI
    // =========================================================

    function toggle() {

        wifiToggle.running = false


        if (connected) {

            connected = false
            connecting = false

            strength = 0
            ssid = ""

            wifiToggle.command = [
                "nmcli",
                "radio",
                "wifi",
                "off"
            ]

        } else {

            connected = false
            connecting = true

            strength = 0
            ssid = ""

            wifiToggle.command = [
                "nmcli",
                "radio",
                "wifi",
                "on"
            ]
        }


        updateIcon()

        wifiToggle.running = true
    }


    // =========================================================
    // ICON
    // =========================================================

    function updateIcon() {

        if (!connected) {

            icon = "󰤮"

            return
        }


        if (strength >= 80)
            icon = "󰤨"

        else if (strength >= 60)
            icon = "󰤥"

        else if (strength >= 40)
            icon = "󰤢"

        else if (strength >= 20)
            icon = "󰤟"

        else
            icon = "󰤯"
    }


    // =========================================================
    // STARTUP
    // =========================================================

    Component.onCompleted: {

        console.log(
            "WifiService loaded"
        )

        update()
    }
}