import QtQuick
import QtTest
import Quickshell
import Quickshell.Io
import "../views"
import "../core"
import "../island"
import "../services"
import "../services/CalendarUtils.js" as Dates

ShellRoot {
    id: root
    Component.onCompleted: CalendarService.ipcExecutable = Quickshell.env("CALENDAR_TEST_DCAL")
    FloatingWindow {
        id: window
        visible: true
        implicitWidth: 940
        implicitHeight: 680
        color: "#252a33"
        Island {
            id: island
            anchors.centerIn: parent
            availableWidth: window.width - 20
            availableHeight: window.height - 20
        }
    }
    function findCalendar(item) {
        if (item instanceof CalendarView) return item;
        for (const child of item.children) {
            const found = findCalendar(child);
            if (found) return found;
        }
        return null;
    }
    function findNamed(item, name) {
        if (!item || !item.visible) return null;
        if (item.objectName === name) return item;
        for (const child of item.children) {
            const found = findNamed(child, name);
            if (found) return found;
        }
        return null;
    }
    TestCase { id: input; name: "Calendar"; when: false }
    IpcHandler {
        target: "test"
        function open() {
            IslandController.reset();
            IslandState.islandPinned = true;
            IslandController.openExpanded();
        }
        function clickClock() {
            const clock = root.findNamed(island, "expandedClock") || root.findNamed(island, "clock");
            input.mouseClick(clock, clock.width / 2, clock.height / 2);
        }
        function clickDate() {
            const date = root.findNamed(island, "calendarDate");
            input.mouseClick(date, date.width / 2, date.height / 2);
        }
        function close() { IslandController.closeCalendar(); }
        function state(): string {
            const view = root.findCalendar(island);
            const rows = root.findNamed(island, "calendarMonthRows");
            const pages = [];
            if (view && !view.selectedEvent) {
                for (let i = 0; i < 3; i++) {
                    const page = root.findNamed(island, "calendarPage" + i);
                    const hours = page ? root.findNamed(page, "calendarHours") : null;
                    if (page) pages.push({x:page.x, width:page.width, children:page.children.length, y:hours ? hours.contentY : null, hourHeight:hours ? hours.contentHeight / 24 : null});
                }
            }
            return JSON.stringify({mode: IslandState.mode, pinned: IslandState.islandPinned,
                pages: pages,
                firstWeek: view ? Qt.formatDate(view.monthStart, "yyyy-MM-dd") : "",
                rowOffset: rows ? rows.contentY / (rows.height / 6) - 12 : 0,
                wheelPending: rows ? rows.parent.parent.wheelScrolling : false,
                zoom: view ? view.timelineHourHeight : 0,
                loading: CalendarService.loading, error: CalendarService.error, hasData: CalendarService.hasData,
                date: view ? Qt.formatDate(view.selectedDate, "yyyy-MM-dd") : "", shift: view ? view.pageShift : 0,
                count: CalendarService.events.length, view: view ? view.mode : "", details: view ? !!view.selectedEvent : false});
        }
        function view(mode: string) { root.findCalendar(island).mode = mode; }
        function date(value: string) {
            const view = root.findCalendar(island);
            view.now = new Date(2026, 8, 13, 9, 30);
            view.selectedDate = new Date(value);
        }
        function refresh() { CalendarService.refresh(); }
        function details() { root.findCalendar(island).selectedEvent = CalendarService.events[0]; }
        function pressEscape() { input.keyClick(Qt.Key_Escape); }
        function arrow(direction: int) { input.keyClick(direction > 0 ? Qt.Key_Right : Qt.Key_Left); }
        function rowArrow(direction: int) { input.keyClick(direction > 0 ? Qt.Key_Down : Qt.Key_Up); }
        function monthJump(direction: int) { root.findCalendar(island).navigate(direction); }
        function holdMonthDrag() {
            const rows = root.findNamed(island, "calendarMonthRows");
            input.mousePress(rows, rows.width / 2, rows.height / 2);
            for (let i = 1; i <= 10; i++)
                input.mouseMove(rows, rows.width / 2, rows.height / 2 - i * rows.height / 60, 30);
        }
        function releaseMonthDrag() {
            const rows = root.findNamed(island, "calendarMonthRows");
            input.mouseRelease(rows, rows.width / 2, rows.height / 3);
        }
        function scrollTimeline(position: int) {
            const page = root.findNamed(island, "calendarPage1");
            root.findNamed(page, "calendarHours").contentY = position;
        }
        function wheel(delta: int, control: bool) {
            const page = root.findNamed(island, "calendarPage1");
            const area = root.findNamed(page, "calendarHours") || root.findNamed(island, "calendarPages");
            input.mouseWheel(area, 100, 100, 0, delta, Qt.NoButton, control ? Qt.ControlModifier : Qt.NoModifier);
        }
        function modifiedHeaderWheel(delta: int) {
            const page = root.findNamed(island, "calendarPage1");
            input.mouseWheel(page, 100, 50, 0, delta, Qt.NoButton, Qt.ControlModifier | Qt.ShiftModifier);
        }
        function badgePosition(): string {
            const badge = root.findNamed(island, "notificationBadge");
            const point = badge.mapToItem(island, badge.width / 2, 0);
            return JSON.stringify({center:point.x, top:point.y, width:island.width});
        }
        function holdDrag() {
            const area = root.findNamed(island, "calendarPages");
            const x = area.width / 2, y = 16;
            input.mousePress(area, x, y);
            for (let i = 1; i <= 10; i++) input.mouseMove(area, x - i * area.width / 22, y, 20);
        }
        function releaseDrag() {
            const area = root.findNamed(island, "calendarPages");
            input.mouseRelease(area, area.width / 22, 16);
        }
        function swipe(direction: int, heading: bool) {
            const area = root.findNamed(island, heading ? "calendarHeading" : "calendarPages");
            const x = area.width / 2, y = area.height / 2;
            input.mousePress(area, x, y);
            for (let i = 1; i <= 8; i++) input.mouseMove(area, x + direction * i * 12, y, 20);
            input.mouseRelease(area, x + direction * 96, y);
        }
        function unread(count: int) { NotificationService.unreadCount = count; }
        function clickBadge() {
            const badge = root.findNamed(island, "notificationBadge");
            input.mouseClick(badge, badge.width / 2, badge.height / 2);
        }
        function narrow() { island.availableWidth = 360; island.availableHeight = 520; }
        function grab(path: string) { island.grabToImage(result => result.saveToFile(path)); }
        function dates(): string {
            function check(ok, message) { if (!ok) throw new Error(message); }
            const leap = Dates.range(new Date(2024, 1, 29), "month");
            check(leap.start.getDay() === 0 && Dates.addDays(leap.start, 42).getTime() === leap.end.getTime(), "Sunday grid");
            check(Dates.addDays(new Date(2024, 1, 28), 1).getDate() === 29, "leap day");
            check(Dates.addDays(new Date(2024, 11, 31), 1).getFullYear() === 2025, "year boundary");
            const dst = new Date(2026, 2, 8);
            check(Dates.addDays(dst, 1).getHours() === 0 && Dates.addDays(dst, 1).getDate() === 9, "DST date arithmetic");
            const events = Dates.normalize([
                {calendarId:"a", start:"2026-09-13T00:00:00Z", end:"2026-09-15T00:00:00Z", allDay:true},
                {calendarId:"hidden", start:"2026-09-13T00:00:00Z", end:"2026-09-15T00:00:00Z"},
                {calendarId:"a", status:"cancelled", start:"2026-09-13T00:00:00Z", end:"2026-09-15T00:00:00Z"}
            ], [{id:"a"}, {id:"hidden", hidden:true}]);
            check(events.length === 1 && events[0].startDate.getDate() === 13, "all-day dates and filters");
            check(Dates.onDay(events, new Date(2026,8,14)).length === 1 && Dates.onDay(events,new Date(2026,8,15)).length === 0, "exclusive end");
            const overlapping = [{startDate:new Date(2026,8,13,9),endDate:new Date(2026,8,13,11)},
                {startDate:new Date(2026,8,13,10),endDate:new Date(2026,8,13,12)}];
            const layout = Dates.layout(overlapping,new Date(2026,8,13));
            check(layout[0].columns === 2 && layout[1].column === 1, "overlap layout");
            return "passed";
        }
    }
}
