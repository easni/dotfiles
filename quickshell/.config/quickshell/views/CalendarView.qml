import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../styles"
import "../components"
import "../services"
import "../core"
import "../services/CalendarUtils.js" as Dates

FocusScope {
    id: root
    property real availableWidth: 900
    property real availableHeight: 640
    implicitWidth: Math.min(900, availableWidth)
    implicitHeight: Math.min(640, availableHeight)
    property string mode: "month"
    property date selectedDate: new Date()
    property date monthStart: Dates.range(new Date(), "month").start
    property bool movingMonth: false
    onSelectedDateChanged: if (!movingMonth) monthStart = Dates.range(selectedDate, "month").start
    property date now: new Date()
    property var selectedEvent: null
    property real pageShift: 0
    property int navigationDirection: 1
    property int queuedSteps: 0
    property real timelineY: -1
    property real timelineHourHeight: 60
    property bool zooming: false
    function zoomTimeline(factor, anchorY, viewportHeight) {
        const nextHeight = Math.max(24, Math.min(180, timelineHourHeight * factor));
        const nextY = (Math.max(0, timelineY) + anchorY) * nextHeight / timelineHourHeight - anchorY;
        zooming = true;
        timelineHourHeight = nextHeight;
        timelineY = Math.max(0, Math.min(nextHeight * 24 - viewportHeight, nextY));
        zooming = false;
    }
    readonly property var visibleRange: mode === "month"
        ? {start: monthStart, end: Dates.addDays(monthStart, 42)} : Dates.range(selectedDate, mode)
    readonly property var events: CalendarService.hasData ? CalendarService.events : []
    function updateRange() { CalendarService.setRange(visibleRange.start, visibleRange.end); }
    function navigate(direction) {
        if (mode === "month") {
            if (monthLoader.item) monthLoader.item.moveMonth(dateAt(direction));
            return;
        }
        if (transition.running) { queuedSteps += direction; return; }
        snapBack.stop();
        navigationDirection = direction;
        selectedEvent = null;
        transition.start();
    }
    function changeDate(direction) {
        selectedDate = dateAt(direction);
    }
    function dateAt(direction) {
        return mode === "month"
            ? new Date(selectedDate.getFullYear(), selectedDate.getMonth() + direction, 1)
            : Dates.addDays(selectedDate, direction * (mode === "week" ? 7 : 1));
    }
    function dragPage(distance) {
        pageShift = Math.max(-pageViewport.width, Math.min(pageViewport.width, distance));
    }
    function finishSwipe(distance) {
        if (Math.abs(distance) >= 60) navigate(distance < 0 ? 1 : -1);
        else snapBack.restart();
    }
    function cancelNavigation() {
        queuedSteps = 0;
        transition.stop();
        snapBack.stop();
        pageShift = 0;
    }
    onModeChanged: {
        cancelNavigation();
        if (mode !== "month" && timelineY < 0) {
            const range = Dates.range(selectedDate, mode);
            const includesToday = now >= range.start && now < range.end;
            timelineY = Math.max(0, ((includesToday ? now.getHours() : 8) - 1) * 60);
        }
    }
    onVisibleRangeChanged: updateRange()
    Component.onCompleted: { updateRange(); CalendarService.active = true; forceActiveFocus(); }
    Component.onDestruction: CalendarService.active = false
    Keys.onEscapePressed: event => {
        if (selectedEvent) selectedEvent = null;
        else IslandController.closeCalendar();
        event.accepted = true;
    }
    Timer { interval: 30000; repeat: true; running: true; onTriggered: root.now = new Date() }
    Shortcut { sequence: "Left"; enabled: root.visible && root.mode !== "month" && !root.selectedEvent; onActivated: root.navigate(-1) }
    Shortcut { sequence: "Right"; enabled: root.visible && root.mode !== "month" && !root.selectedEvent; onActivated: root.navigate(1) }
    Shortcut { sequence: "Up"; enabled: root.visible && root.mode === "month" && !root.selectedEvent; onActivated: monthLoader.item.moveRows(-1) }
    Shortcut { sequence: "Down"; enabled: root.visible && root.mode === "month" && !root.selectedEvent; onActivated: monthLoader.item.moveRows(1) }
    NumberAnimation { id: snapBack; target: root; property: "pageShift"; to: 0; duration: 150; easing.type: Easing.OutCubic }
    SequentialAnimation {
        id: transition
        NumberAnimation { target: root; property: "pageShift"; to: -root.navigationDirection * pageViewport.width; duration: 240; easing.type: Easing.OutCubic }
        // Rebase all three pages in the same frame, keeping the arriving page in place.
        ScriptAction { script: { root.changeDate(root.navigationDirection); root.pageShift = 0; } }
        onFinished: {
            if (root.queuedSteps !== 0) {
                const direction = root.queuedSteps > 0 ? 1 : -1;
                root.queuedSteps -= direction;
                root.navigate(direction);
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10
        Item {
            id: header
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            NotificationBadge {
                id: calendarBadge
                anchors.centerIn: parent
            }
            RowLayout {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: calendarBadge.visible ? (header.width - calendarBadge.width) / 2 - 8 : header.width - closeButton.width - 8
            spacing: 6
            CalendarIconButton { symbol: root.mode === "month" ? "\u2191" : "\u2190"; hint: "Previous " + root.mode; onClicked: root.navigate(-1) }
            CalendarIconButton { symbol: root.mode === "month" ? "\u2193" : "\u2192"; hint: "Next " + root.mode; onClicked: root.navigate(1) }
            Text {
                id: dateHeading
                objectName: "calendarHeading"
                Layout.fillWidth: true
                text: root.mode === "month" ? Qt.formatDate(root.selectedDate, "MMMM yyyy")
                    : root.mode === "day" ? Qt.formatDate(root.selectedDate, "ddd, MMM d, yyyy")
                    : Qt.formatDate(root.visibleRange.start, "MMM d") + " - " + Qt.formatDate(Dates.addDays(root.visibleRange.end, -1), "MMM d, yyyy")
                color: Theme.textPrimary
                font.pixelSize: 17
                font.bold: true
                elide: Text.ElideRight
                DragHandler {
                    target: null
                    enabled: root.mode !== "month" && !transition.running && !root.selectedEvent
                    yAxis.enabled: false
                    property real distance: 0
                    onTranslationChanged: { if (active) { distance = activeTranslation.x; root.dragPage(distance); } }
                    onActiveChanged: {
                        if (active) { snapBack.stop(); distance = 0; }
                        else root.finishSwipe(distance);
                    }
                }
            }
            }
            CalendarIconButton {
                id: closeButton
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                symbol: "\u00d7"
                hint: "Close calendar"
                onClicked: IslandController.closeCalendar()
            }
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: 4
            Repeater {
                model: ["month", "week", "day"]
                Button {
                    required property string modelData
                    text: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                    implicitHeight: 30
                    implicitWidth: 60
                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                    onClicked: { root.mode = modelData; root.selectedEvent = null; }
                    contentItem: Text { text: parent.text; color: root.mode === modelData ? Theme.background : Theme.textPrimary; font.pixelSize: 12; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    background: Rectangle { radius: 4; color: root.mode === modelData ? Theme.accent : parent.hovered ? Theme.buttonHover : Theme.surface }
                }
            }
            Item { Layout.fillWidth: true }
            Button {
                text: "Today"
                implicitWidth: 54
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                implicitHeight: 30
                onClicked: { root.cancelNavigation(); root.selectedDate = new Date(); root.selectedEvent = null; }
                contentItem: Text { text: parent.text; color: Theme.textPrimary; font.pixelSize: 12; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                background: Rectangle { radius: 4; color: parent.hovered ? Theme.buttonHover : Theme.surface }
            }
            CalendarIconButton { symbol: "\u21bb"; hint: "Refresh events"; enabled: !CalendarService.loading; onClicked: CalendarService.refresh() }
        }
        Text {
            Layout.fillWidth: true
            Layout.preferredHeight: 16
            text: CalendarService.error || (CalendarService.loading && !CalendarService.hasData ? "Loading events..." : "")
            color: CalendarService.error ? Theme.warning : Theme.textMuted
            font.pixelSize: 11
            elide: Text.ElideRight
        }
        Item {
            id: pageViewport
            objectName: "calendarPages"
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !root.selectedEvent
            clip: true
            DragHandler {
                target: null
                // A narrow week needs horizontal scrolling within the timeline.
                enabled: root.mode !== "month" && !transition.running && (root.mode !== "week" || pageViewport.width >= 536)
                yAxis.enabled: false
                property real distance: 0
                onTranslationChanged: { if (active) { distance = activeTranslation.x; root.dragPage(distance); } }
                onActiveChanged: {
                    if (active) { snapBack.stop(); distance = 0; }
                    else root.finishSwipe(distance);
                }
            }
            Loader {
                id: monthLoader
                anchors.fill: parent
                active: root.mode === "month"
                sourceComponent: Component {
                    CalendarMonth {
                        date: root.selectedDate
                        startDate: root.monthStart
                        now: root.now
                        events: root.events
                        onDateSelected: selected => { root.selectedDate = selected; root.mode = "day"; }
                        onFirstWeekChanged: firstWeek => {
                            root.movingMonth = true;
                            root.selectedDate = Dates.addDays(firstWeek, 6);
                            root.monthStart = firstWeek;
                            root.movingMonth = false;
                        }
                    }
                }
            }
            Repeater {
                model: root.mode === "month" ? 0 : 3
                Item {
                    id: page
                    required property int index
                    objectName: "calendarPage" + index
                    readonly property date date: root.dateAt(index - 1)
                    width: pageViewport.width
                    height: pageViewport.height
                    x: (index - 1) * width + root.pageShift
                    clip: true
                    enabled: index === 1 && !transition.running
                    Loader {
                        anchors.fill: parent
                        active: root.mode !== "month"
                        sourceComponent: Component {
                            CalendarTimeline {
                                startDate: Dates.range(page.date, root.mode).start
                                dayCount: root.mode === "week" ? 7 : 1
                                events: root.events
                                now: root.now
                                currentPage: page.index === 1
                                hourHeight: root.timelineHourHeight
                                scrollPosition: Math.max(0, root.timelineY)
                                onScrollPositionEdited: position => { if (!root.zooming) root.timelineY = position; }
                                onZoomRequested: (factor, anchorY, viewportHeight) => root.zoomTimeline(factor, anchorY, viewportHeight)
                                onEventSelected: event => root.selectedEvent = event
                            }
                        }
                    }
                }
            }
        }
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.selectedEvent !== null
            clip: true
            contentWidth: availableWidth
            ColumnLayout {
                width: parent.width
                spacing: 14
                CalendarIconButton { symbol: "\u2190"; hint: "Back to calendar"; onClicked: root.selectedEvent = null }
                Repeater {
                    model: root.selectedEvent ? [root.selectedEvent.summary, root.selectedEvent.calendarName,
                        root.selectedEvent.allDay
                            ? Qt.formatDate(root.selectedEvent.startDate, "ddd, MMM d, yyyy") + " - " + Qt.formatDate(Dates.addDays(root.selectedEvent.endDate, -1), "ddd, MMM d, yyyy") + " (All day)"
                            : Qt.formatDateTime(root.selectedEvent.startDate, "ddd, MMM d, yyyy HH:mm") + " - " + Qt.formatDateTime(root.selectedEvent.endDate, "ddd, MMM d, yyyy HH:mm"),
                        root.selectedEvent.location || "", root.selectedEvent.description || ""] : []
                    Text {
                        required property string modelData
                        required property int index
                        Layout.fillWidth: true
                        visible: text !== ""
                        text: modelData
                        textFormat: Text.PlainText
                        wrapMode: Text.Wrap
                        color: index === 0 ? Theme.textPrimary : Theme.textSecondary
                        font.pixelSize: index === 0 ? 20 : 13
                        font.bold: index === 0
                    }
                }
            }
        }
    }
}
