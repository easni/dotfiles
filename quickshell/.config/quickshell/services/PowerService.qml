pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import "../core"
import "../styles"

Singleton {
    id: root

    property string pendingAction: ""

    Process {
        id: commandProcess
    }

    Timer {
        id: delayedActionTimer

        interval: Theme.animationNormal + 60
        repeat: false

        onTriggered: {
            const action = root.pendingAction
            root.pendingAction = ""

            if (action === "lock")
                root.lock()
            else if (action === "suspend")
                root.suspend()
        }
    }

    function run(cmd) {
        commandProcess.command = cmd
        commandProcess.running = true
    }

    function luaString(value) {
        return value.replace(/\\/g, "\\\\").replace(/"/g, "\\\"")
    }

    function hyprExec(command) {
        run([
            "hyprctl",
            "dispatch",
            "hl.dsp.exec_cmd(\"" + luaString(command) + "\")"
        ])
    }

    function lock() {
        hyprExec(Quickshell.shellPath("scripts/power-action.sh") + " lock")
    }

    function lockAfterIslandCollapse(navigation) {
        resetThenRun("lock", navigation)
    }

    function logout() {
        run([
            "hyprctl",
            "dispatch",
            "hl.dsp.exit()"
        ])
    }

    function suspend() {
        hyprExec(Quickshell.shellPath("scripts/power-action.sh") + " suspend")
    }

    function suspendAfterIslandCollapse(navigation) {
        resetThenRun("suspend", navigation)
    }

    function resetThenRun(action, navigation = IslandController) {
        pendingAction = action
        delayedActionTimer.restart()
        navigation.reset()
    }

    function reboot() {
        run([
            "systemctl",
            "reboot"
        ])
    }

    function poweroff() {
        run([
            "systemctl",
            "poweroff"
        ])
    }
}
