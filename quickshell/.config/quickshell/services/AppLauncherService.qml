pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../lib/LauncherSearch.js" as Search

Singleton {
    id: root
    readonly property var applications: DesktopEntries.applications.values
        .filter(entry => !entry.noDisplay)
        .map(entry => ({id: entry.id, name: entry.name,
            genericName: entry.genericName, description: entry.comment,
            keywords: Array.from(entry.keywords), icon: entry.icon}))
    readonly property bool busy: launchProcess.running
    property string error: ""
    property int errorSession: -1
    signal launched(int session)

    function search(query) { return Search.applications(applications, query) }
    function launch(id, session) {
        if (busy) return
        error = ""
        errorSession = session
        if (!applications.some(entry => entry.id === id)) {
            error = "This application is no longer available."
            return
        }
        launchProcess.session = session
        launchProcess.handled = false
        launchProcess.command = ["gtk-launch", id]
        launchProcess.running = true
    }

    Process {
        id: launchProcess
        property int session: -1
        property bool handled: true
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: function(exitCode, exitStatus) {
            handled = true
            root.errorSession = session
            if (exitCode === 0 && exitStatus === 0) root.launched(session)
            else root.error = "Couldn't launch this app. Check its desktop entry and try again."
        }
        onRunningChanged: {
            if (!running) Qt.callLater(function() {
                if (!launchProcess.handled) {
                    launchProcess.handled = true
                    root.errorSession = launchProcess.session
                    root.error = "Couldn't start gtk-launch. Check that it is installed."
                }
            })
        }
    }
}
