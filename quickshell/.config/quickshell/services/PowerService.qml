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

    function lockAfterIslandCollapse() {
        resetThenRun("lock")
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

    function suspendAfterIslandCollapse() {
        resetThenRun("suspend")
    }

    function resetThenRun(action) {
        pendingAction = action
        delayedActionTimer.restart()
        IslandController.reset()
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
