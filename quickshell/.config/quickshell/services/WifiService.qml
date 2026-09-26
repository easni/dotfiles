pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool enabled: false
    property bool connected: false
    readonly property bool connecting: wifiToggle.running
    readonly property bool busy: radioReader.running || wifiReader.running || wifiToggle.running
    property bool available: false
    property string error: ""
    property int strength: 0
    property string ssid: ""
    readonly property string subtitle: error !== "" ? error
        : connecting ? "Updating…"
        : !available ? "Unavailable"
        : !enabled ? "Off"
        : connected ? ssid : "Not connected"
    readonly property string icon: !connected ? "󰤮"
        : strength >= 80 ? "󰤨" : strength >= 60 ? "󰤥"
        : strength >= 40 ? "󰤢" : strength >= 20 ? "󰤟" : "󰤯"
    readonly property url svgIcon: Qt.resolvedUrl(enabled
        ? "../assets/icons/wifi.svg" : "../assets/icons/wifi-off.svg")

    property bool initialized: false
    property bool previousConnected: false
    property string previousSsid: ""

    Process {
        id: radioReader
        command: ["nmcli", "-w", "3", "radio", "wifi"]
        environment: ({ LC_ALL: "C" })
        stdout: StdioCollector { id: radioOutput }
        onExited: function(code) {
            const state = radioOutput.text.trim()
            root.available = code === 0 && (state === "enabled" || state === "disabled")
            if (!root.available) return
            root.enabled = state === "enabled"
            if (root.enabled) wifiReader.running = true
            else {
                root.connected = false
                root.ssid = ""
                root.strength = 0
                root.handleStateChange()
            }
        }
    }

    Process {
        id: wifiReader
        command: ["nmcli", "-w", "3", "-t", "-f", "ACTIVE,SIGNAL,SSID", "dev", "wifi", "list", "--rescan", "no"]
        environment: ({ LC_ALL: "C" })
        stdout: StdioCollector { id: wifiOutput }
        onExited: function(code) {
            if (code !== 0) {
                root.available = false
                return
            }
            const line = wifiOutput.text.split("\n").find(line => line.startsWith("yes:")) || ""
            const parts = line.split(":")
            root.connected = line !== ""
            root.strength = root.connected ? Number(parts[1]) : 0
            root.ssid = root.connected ? parts.slice(2).join(":").replace(/\\(.)/g, "$1") : ""
            root.handleStateChange()
        }
    }

    Process {
        id: wifiToggle
        onExited: function(code) {
            root.error = code === 0 ? "" : "Could not change Wi-Fi"
            root.update()
        }
    }

    function update() {
        if (!busy) radioReader.running = true
    }

    function toggle() {
        if (busy || !available) return
        error = ""
        wifiToggle.command = ["nmcli", "-w", "3", "radio", "wifi", enabled ? "off" : "on"]
        wifiToggle.running = true
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: root.update()
    }
    Component.onCompleted: update()

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


}
