import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../styles"
import "../services/CalendarUtils.js" as Dates

Item {
    id: root
    required property date startDate
    required property int dayCount
    required property var events
    required property date now
    property real scrollPosition: 0
    property bool currentPage: true
    property bool restoringScroll: false
    readonly property real contentY: scroller.contentY
    signal scrollPositionEdited(real position)
    signal zoomRequested(real factor, real anchorY, real viewportHeight)
    signal eventSelected(var event)
    readonly property real gutter: 46
    readonly property real dayWidth: Math.max(70, (width - gutter) / dayCount)
    property real hourHeight: 60
    readonly property var days: {
        const result = [];
        for (let i = 0; i < dayCount; i++) result.push(Dates.addDays(startDate, i));
        return result;
    }
    function restoreScroll() {
        restoringScroll = true;
        scroller.contentY = Math.max(0, Math.min(scroller.contentHeight - scroller.height, scrollPosition));
        restoringScroll = false;
    }
    onScrollPositionChanged: restoreScroll()
    Component.onCompleted: Qt.callLater(restoreScroll)

    Flickable {
        id: horizontal
        anchors.fill: parent
        contentWidth: root.gutter + root.dayWidth * root.dayCount
        contentHeight: height
        clip: true
        flickableDirection: Flickable.HorizontalFlick
        interactive: contentWidth > width
        ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AsNeeded }

        Row {
            id: headings
            x: root.gutter
            height: 34
            Repeater {
                model: root.days
                Text {
                    required property var modelData
                    width: root.dayWidth
                    height: 34
                    text: Qt.formatDate(modelData, root.dayCount === 1 ? "dddd, MMM d" : "ddd d")
                    color: Dates.sameDay(modelData, root.now) ? Theme.accent : Theme.textSecondary
                    font.pixelSize: 12
                    font.bold: Dates.sameDay(modelData, root.now)
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
        Text { x: 0; y: 41; width: root.gutter; text: "All day"; color: Theme.textMuted; font.pixelSize: 10 }
        Row {
            id: allDay
            x: root.gutter
            y: 34
            height: 72
            Repeater {
                model: root.days
                Flickable {
                    required property var modelData
                    width: root.dayWidth
                    height: allDay.height
                    contentHeight: allDayColumn.implicitHeight
                    clip: true
                    Column {
                        id: allDayColumn
                        width: parent.width - 4
                        spacing: 3
                        Repeater {
                            model: Dates.onDay(root.events, modelData).filter(e => e.allDay)
                            Rectangle {
                                required property var modelData
                                width: allDayColumn.width
                                height: 22
                                radius: 3
                                color: Theme.surfaceVariant
                                Rectangle { width: 3; height: parent.height; color: modelData.color || Theme.accent }
                                Text { anchors.fill: parent; anchors.leftMargin: 7; text: modelData.summary; color: Theme.textPrimary; font.pixelSize: 11; elide: Text.ElideRight; verticalAlignment: Text.AlignVCenter }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.eventSelected(modelData) }
                            }
                        }
                    }
                    ScrollBar.vertical: ScrollBar {}
                }
            }
        }
        Flickable {
            id: scroller
            objectName: "calendarHours"
            y: 112
            width: horizontal.contentWidth
            height: Math.max(1, horizontal.height - y - 10)
            contentHeight: root.hourHeight * 24
            clip: true
            flickableDirection: Flickable.VerticalFlick
            onHeightChanged: Qt.callLater(root.restoreScroll)
            onContentYChanged: {
                if (root.currentPage && !root.restoringScroll)
                    root.scrollPositionEdited(Math.max(0, Math.min(contentHeight - height, contentY)));
            }
            ScrollBar.vertical: ScrollBar {}
            Repeater {
                model: 24
                Item {
                    required property int index
                    y: index * root.hourHeight
                    width: scroller.width
                    height: root.hourHeight
                    Text { text: (index < 10 ? "0" : "") + index + ":00"; color: Theme.textMuted; font.pixelSize: 10 }
                    Rectangle { x: root.gutter; width: parent.width - x; height: 1; color: Theme.border }
                }
            }
            Repeater {
                model: root.days
                Item {
                    id: column
                    required property var modelData
                    required property int index
                    x: root.gutter + index * root.dayWidth
                    width: root.dayWidth
                    height: scroller.contentHeight
                    Rectangle { width: 1; height: parent.height; color: Theme.border }
                    Repeater {
                        model: Dates.layout(root.events, column.modelData, 24 * 60 / root.hourHeight)
                        Rectangle {
                            id: eventBlock
                            required property var modelData
                            x: modelData.column * column.width / modelData.columns + 3
                            y: modelData.top * root.hourHeight / 60
                            width: Math.max(1, column.width / modelData.columns - 5)
                            height: (modelData.bottom - modelData.top) * root.hourHeight / 60 - 1
                            radius: 3
                            color: eventMouse.containsMouse ? Theme.buttonHover : Theme.surfaceVariant
                            clip: true
                            Rectangle { width: 3; height: parent.height; color: modelData.event.color || Theme.accent }
                            Column {
                                x: 7; y: 3; width: Math.max(1, parent.width - 10); spacing: 2
                                Text { width: parent.width; text: eventBlock.modelData.event.summary; color: Theme.textPrimary; font.pixelSize: 11; elide: Text.ElideRight }
                                Text { visible: eventBlock.height >= 36; width: parent.width; text: Qt.formatTime(eventBlock.modelData.event.startDate, "HH:mm") + " - " + Qt.formatTime(eventBlock.modelData.event.endDate, "HH:mm"); color: Theme.textSecondary; font.pixelSize: 10; elide: Text.ElideRight }
                            }
                            MouseArea { id: eventMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.eventSelected(modelData.event) }
                            ToolTip.visible: eventMouse.containsMouse
                            ToolTip.text: modelData.event.summary
                        }
                    }
                    Rectangle {
                        visible: Dates.sameDay(column.modelData, root.now)
                        y: Dates.minutes(root.now) * root.hourHeight / 60
                        width: parent.width
                        height: 2
                        color: Theme.danger
                    }
                }
            }
        }
    }

    // Intercept modified wheel gestures before nested Flickables consume them.
    MouseArea {
        id: zoomInput
        anchors.fill: parent
        z: 10
        enabled: root.currentPage
        acceptedButtons: Qt.NoButton
        scrollGestureEnabled: true
        onWheel: wheel => {
            if (!(wheel.modifiers & Qt.ControlModifier)) {
                wheel.accepted = false;
                return;
            }
            const delta = wheel.angleDelta.y || wheel.pixelDelta.y;
            if (delta !== 0) {
                scroller.cancelFlick();
                const point = zoomInput.mapToItem(scroller, wheel.x, wheel.y);
                const anchorY = Math.max(0, Math.min(scroller.height, point.y));
                root.zoomRequested(Math.pow(1.15, delta / 120), anchorY, scroller.height);
            }
            wheel.accepted = true;
        }
    }
}
