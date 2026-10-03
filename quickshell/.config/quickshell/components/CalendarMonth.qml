import QtQuick
import "../styles"
import "../services/CalendarUtils.js" as Dates

Column {
    id: root
    required property date date
    required property date startDate
    required property date now
    required property var events
    signal dateSelected(date selected)
    signal firstWeekChanged(date firstWeek)
    property bool settling: false
    property int queuedRows: 0
    property bool wheelScrolling: false
    readonly property real rowHeight: Math.max(1, (height - 28) / 6)
    readonly property real rowOffset: weeks.contentY / rowHeight - 12
    function resetPosition() {
        if (!settling) { rowAnimation.stop(); queuedRows = 0; wheelIdle.stop(); wheelScrolling = false; }
        weeks.cancelFlick();
        weeks.positionViewAtIndex(12, ListView.Beginning);
    }
    function settle() {
        const offset = Math.round(rowOffset);
        if (offset === 0) return;
        settling = true;
        firstWeekChanged(Dates.addDays(startDate, offset * 7));
        settling = false;
    }
    function moveRows(count) {
        if (rowAnimation.running) { queuedRows += count; return; }
        wheelIdle.stop();
        weeks.cancelFlick();
        wheelScrolling = false;
        rowAnimation.to = (Math.round(weeks.contentY / rowHeight) + count) * rowHeight;
        rowAnimation.start();
    }
    function moveMonth(target) {
        const next = Dates.range(target, "month").start;
        const fromUTC = Date.UTC(startDate.getFullYear(), startDate.getMonth(), startDate.getDate());
        const toUTC = Date.UTC(next.getFullYear(), next.getMonth(), next.getDate());
        moveRows(Math.round((toUTC - fromUTC) / (7 * 86400000)));
    }
    onStartDateChanged: resetPosition()
    onRowHeightChanged: Qt.callLater(resetPosition)
    Component.onCompleted: Qt.callLater(resetPosition)
    Timer {
        id: wheelIdle
        interval: 500
        onTriggered: {
            weeks.cancelFlick();
            rowAnimation.to = Math.round(weeks.contentY / root.rowHeight) * root.rowHeight;
            rowAnimation.start();
            root.wheelScrolling = false;
        }
    }
    NumberAnimation {
        id: rowAnimation
        target: weeks
        property: "contentY"
        duration: 220
        easing.type: Easing.OutCubic
        onFinished: {
            root.settle();
            if (root.queuedRows !== 0) {
                const count = root.queuedRows;
                root.queuedRows = 0;
                root.moveRows(count);
            }
        }
    }
    Row {
        width: parent.width
        height: 28
        Repeater {
            model: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            Text { required property string modelData; width: parent.width / 7; text: modelData; color: Theme.textSecondary; horizontalAlignment: Text.AlignHCenter; font.pixelSize: 12 }
        }
    }
    Item {
        width: parent.width
        height: Math.max(1, parent.height - 28)
    ListView {
        id: weeks
        objectName: "calendarMonthRows"
        anchors.fill: parent
        model: 30
        clip: true
        orientation: ListView.Vertical
        snapMode: root.wheelScrolling ? ListView.NoSnap : ListView.SnapToItem
        boundsBehavior: Flickable.StopAtBounds
        cacheBuffer: root.rowHeight * 6
        onMovementEnded: if (!rowAnimation.running && !root.wheelScrolling && !root.settling) root.settle()
        onDraggingChanged: if (dragging) {
            wheelIdle.stop(); root.wheelScrolling = false;
            rowAnimation.stop(); root.queuedRows = 0;
        }
        delegate: Row {
        id: week
        required property int index
        width: weeks.width
        height: root.rowHeight
        Repeater {
            model: 7
            Rectangle {
                id: cell
                required property int index
                readonly property date modelData: Dates.addDays(root.startDate, (week.index - 12) * 7 + index)
                width: parent.width / 7
                height: parent.height
                color: cellMouse.containsMouse ? Theme.surface : "transparent"
                readonly property var dayEvents: Dates.onDay(root.events, modelData)
                Rectangle { width: parent.width; height: 1; color: Theme.border }
                Rectangle {
                    anchors.centerIn: parent
                    width: 30; height: 30; radius: 15
                    color: Dates.sameDay(cell.modelData, root.now) ? Theme.accent : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: cell.modelData.getDate()
                        font.pixelSize: 14
                        color: Dates.sameDay(cell.modelData, root.now) ? Theme.background
                            : cell.modelData.getMonth() === root.date.getMonth() ? Theme.textPrimary : Theme.textMuted
                    }
                }
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 5
                    spacing: 3
                    Repeater {
                        model: cell.dayEvents.slice(0, 3)
                        Rectangle { required property var modelData; width: 4; height: 4; radius: 2; color: modelData.color || Theme.accent }
                    }
                }
                MouseArea { id: cellMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.dateSelected(cell.modelData) }
            }
        }
        }
    }
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        scrollGestureEnabled: true
        onWheel: wheel => {
            if (wheel.angleDelta.y || wheel.pixelDelta.y) {
                root.wheelScrolling = true;
                rowAnimation.stop();
                root.queuedRows = 0;
                wheelIdle.restart();
            }
            // Preserve native wheel distance and touchpad scrolling.
            wheel.accepted = false;
        }
    }
    }
}
