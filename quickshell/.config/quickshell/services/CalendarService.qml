pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "CalendarUtils.js" as Dates

Singleton {
    id: root
    // The desktop session's PATH does not include the locally installed IPC client.
    property string ipcExecutable: Quickshell.env("HOME") + "/.local/bin/dcal"
    property bool active: false
    property var events: []
    property var calendars: []
    property bool loading: false
    property string error: ""
    property var loadedStart: null
    property var loadedEnd: null
    property var rangeStart: new Date()
    property var rangeEnd: new Date()
    property string rangeKey: ""
    property var requestStart: null
    property var requestEnd: null
    property int generation: 0
    property int requestGeneration: 0
    property string stage: ""
    property var pendingCalendars: []
    property var pendingEvents: []
    property int offset: 0
    property bool queued: false
    property bool awaitingExit: false
    property int commandSerial: 0
    readonly property bool hasData: loadedStart !== null && loadedEnd !== null &&
        loadedStart <= rangeStart && loadedEnd >= rangeEnd

    function setRange(start, end) {
        rangeStart = start;
        rangeEnd = end;
        const key = start.toISOString() + "/" + end.toISOString();
        if (rangeKey === key) return;
        rangeKey = key;
        if (hasData) {
            if (loading && (requestStart > start || requestEnd < end)) generation++;
            if (error) error = "Events may be out of date";
            if (!loading && (Dates.addDays(start, -14) < loadedStart || Dates.addDays(end, 14) > loadedEnd))
                refresh();
            return;
        }
        if (loading && requestStart <= start && requestEnd >= end) return;
        generation++;
        refresh();
    }
    function refresh() {
        if (!active || !rangeKey) return;
        if (loading || request.running) { queued = true; return; }
        queued = false;
        // Keep adjacent months (and many nearby weeks/days) ready for navigation.
        requestStart = Dates.addDays(rangeStart, -42);
        requestEnd = Dates.addDays(rangeEnd, 42);
        requestGeneration = generation;
        loading = true;
        error = "";
        pendingEvents = [];
        offset = 0;
        stage = "calendars";
        launch([ipcExecutable, "ipc", "calendars.list"]);
    }
    function launch(command) {
        commandSerial++;
        request.command = command;
        awaitingExit = true;
        // Arm before starting: a failed launch does not emit Process.exited.
        timeout.restart();
        request.running = true;
        checkStoppedCommand();
    }
    function checkStoppedCommand() {
        const serial = commandSerial;
        Qt.callLater(function() {
            if (root.awaitingExit && serial === root.commandSerial && !request.running)
                root.fail("Calendar IPC client unavailable");
        });
    }
    function fail(message) {
        awaitingExit = false;
        timeout.stop();
        loading = false;
        queued = false;
        error = hasData ? "Events may be out of date" : message;
        if (request.running) request.signal(9);
    }
    function fetchPage() {
        if (!active || requestGeneration !== generation) {
            loading = false;
            if (active) refresh();
            return;
        }
        stage = "events";
        // Pad the query to also cover UTC-encoded all-day dates in local ranges.
        launch([ipcExecutable, "ipc", "events.list",
            "from=" + Dates.addDays(requestStart, -1).toISOString(),
            "to=" + Dates.addDays(requestEnd, 1).toISOString(),
            "limit=250", "offset=" + offset]);
    }
    function finish(code, output) {
        if (!awaitingExit) {
            if (active && queued) Qt.callLater(refresh);
            return;
        }
        awaitingExit = false;
        timeout.stop();
        if (!active || requestGeneration !== generation) {
            loading = false;
            if (active) Qt.callLater(refresh);
            return;
        }
        try {
            if (code !== 0) throw new Error("IPC failed");
            const data = JSON.parse(output);
            if (stage === "calendars") {
                if (!Array.isArray(data)) throw new Error("Invalid calendars");
                pendingCalendars = data;
                Qt.callLater(fetchPage);
                return;
            }
            if (!data || !Array.isArray(data.events) || !Number.isInteger(data.total) || data.total < 0)
                throw new Error("Invalid events");
            pendingEvents = pendingEvents.concat(data.events);
            offset += data.events.length;
            if (offset < data.total) {
                if (!data.events.length) throw new Error("Incomplete events");
                Qt.callLater(fetchPage);
                return;
            }
            calendars = pendingCalendars;
            events = Dates.normalize(pendingEvents, calendars);
            loadedStart = requestStart;
            loadedEnd = requestEnd;
        } catch (err) {
            error = hasData ? "Events may be out of date" : "Events unavailable";
        }
        loading = false;
        if (queued) Qt.callLater(refresh);
    }
    onActiveChanged: {
        generation++;
        if (active) refresh();
        else {
            queued = false;
            loading = false;
            awaitingExit = false;
            commandSerial++;
            timeout.stop();
            if (request.running) request.signal(9);
        }
    }
    Process {
        id: request
        stdout: StdioCollector { id: output }
        stderr: StdioCollector {}
        onRunningChanged: if (!running) root.checkStoppedCommand()
        onExited: (code, status) => root.finish(code, output.text)
    }
    Timer { id: timeout; interval: 10000; onTriggered: root.fail("Calendar request timed out") }
    Timer { interval: 30000; repeat: true; running: root.active; onTriggered: root.refresh() }
}
