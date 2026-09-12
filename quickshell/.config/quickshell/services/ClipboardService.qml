pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../lib/LauncherSearch.js" as Search

Singleton {
    id: root
    property var entries: []
    property bool loading: false
    readonly property bool busy: copyProcess.running
    property string error: ""
    property int errorSession: -1
    property int revision: 0
    property int viewSession: -1
    property bool reloadPending: false
    signal copied(int session)

    function search(query) { return Search.clipboard(entries, query) }
    function reload(session) {
        viewSession = session
        errorSession = session
        error = ""
        entries = []
        revision++
        loading = true
        if (listProcess.running) reloadPending = true
        else startScan()
    }
    function startScan() {
        reloadPending = false
        listProcess.revision = revision
        listProcess.output = ""
        listProcess.handled = false
        listProcess.running = true
    }
    function copy(id, session) {
        if (busy || loading) return
        error = ""
        errorSession = session
        if (!entries.some(entry => entry.id === id)) {
            error = "This clipboard entry is no longer available."
            return
        }
        copyProcess.session = session
        copyProcess.handled = false
        copyProcess.command = ["python3", Quickshell.shellPath("scripts/clipboard-select.py"), id]
        copyProcess.running = true
    }

    Process {
        id: listProcess
        command: ["cliphist", "list"]
        property int revision: -1
        property string output: ""
        property bool handled: true
        stdout: StdioCollector {
            onStreamFinished: listProcess.output = text
        }
        stderr: StdioCollector {}
        onExited: function(exitCode, exitStatus) {
            handled = true
            if (revision === root.revision) {
                root.loading = false
                if (exitCode === 0 && exitStatus === 0)
                    root.entries = Search.parseClipboard(output)
                else {
                    root.errorSession = root.viewSession
                    root.error = "Couldn't load clipboard history. Check that cliphist is available."
                }
            }
            if (root.reloadPending) Qt.callLater(root.startScan)
        }
        onRunningChanged: {
            if (!running) Qt.callLater(function() {
                if (!listProcess.handled) {
                    listProcess.handled = true
                    root.loading = false
                    root.errorSession = root.viewSession
                    root.error = "Couldn't start cliphist. Check that it is installed."
                }
            })
        }
    }

    Process {
        id: copyProcess
        property int session: -1
        property bool handled: true
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: function(exitCode, exitStatus) {
            handled = true
            if (exitCode === 0 && exitStatus === 0) root.copied(session)
            else if (session === root.viewSession) {
                // Refresh missing entries without clearing the operation error.
                root.reload(session)
                root.error = "Couldn't copy that entry. It may have been removed; try another."
            }
        }
        onRunningChanged: {
            if (!running) Qt.callLater(function() {
                if (!copyProcess.handled) {
                    copyProcess.handled = true
                    root.errorSession = copyProcess.session
                    root.error = "Couldn't start the clipboard helper. Check that Python 3 is installed."
                }
            })
        }
    }
}
