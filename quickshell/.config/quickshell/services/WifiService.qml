pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool enabled: false
    property bool connected: false
    // Keep an operation pending until a fresh read confirms its outcome.
    property int pendingRadio: -1
    readonly property bool connecting: pendingRadio !== -1
    readonly property bool processBusy: radioReader.running || wifiReader.running || wifiToggle.running
    readonly property bool busy: connecting || processBusy
    readonly property bool displayEnabled: connecting ? pendingRadio === 1 : enabled
    property bool settling: false
    property bool available: false
    property string error: ""
    property int strength: 0
    property string ssid: ""
    readonly property string subtitle: error !== "" ? error
        : connecting ? (pendingRadio === 1 ? "Turning on…" : "Turning off…")
        : !available ? "Unavailable"
        : !enabled ? "Off"
        : connected ? ssid : "Not connected"
    readonly property string icon: !connected ? "󰤮"
        : strength >= 80 ? "󰤨" : strength >= 60 ? "󰤥"
        : strength >= 40 ? "󰤢" : strength >= 20 ? "󰤟" : "󰤯"
    readonly property url svgIcon: Qt.resolvedUrl(displayEnabled
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
            if (!root.available) {
                root.finishToggle("Could not read Wi-Fi state")
                return
            }
            root.enabled = state === "enabled"
            // A successful command can precede NetworkManager's state change.
            if (root.connecting && root.enabled !== (root.pendingRadio === 1)) return
            if (root.enabled) wifiReader.running = true
            else {
                root.connected = false
                root.ssid = ""
                root.strength = 0
                root.handleStateChange()
                root.finishToggle("")
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
                root.finishToggle("Could not read Wi-Fi state")
                return
            }
            const line = wifiOutput.text.split("\n").find(line => line.startsWith("yes:")) || ""
            const parts = line.split(":")
            root.connected = line !== ""
            root.strength = root.connected ? Number(parts[1]) : 0
            root.ssid = root.connected ? parts.slice(2).join(":").replace(/\\(.)/g, "$1") : ""
            root.handleStateChange()
            root.finishToggle("")
        }
    }

    Process {
        id: wifiToggle
        onExited: function(code) {
            if (code !== 0) root.finishToggle("Could not change Wi-Fi")
            root.update()
        }
    }

    function update() {
        if (!processBusy) radioReader.running = true
    }

    function toggle() {
        if (busy || !available) return
        error = ""
        pendingRadio = enabled ? 0 : 1
        operationTimeout.restart()
        wifiToggle.command = ["nmcli", "-w", "3", "radio", "wifi", enabled ? "off" : "on"]
        wifiToggle.running = true
    }

    function finishToggle(message) {
        if (!connecting) return
        if (pendingRadio === 1 && !message) { settling = true; settleTimer.restart() }
        operationTimeout.stop()
        pendingRadio = -1
        error = message
    }

    Timer { id: settleTimer; interval: 10000; onTriggered: root.settling = false }
    Timer {
        id: operationTimeout
        interval: 10000
        onTriggered: {
            root.finishToggle("Wi-Fi change timed out. Retry.")
            if (wifiToggle.running) wifiToggle.signal(9)
            if (radioReader.running) radioReader.signal(9)
            if (wifiReader.running) wifiReader.signal(9)
        }
    }
    Timer {
        interval: root.connecting || root.settling ? 500 : 5000
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
