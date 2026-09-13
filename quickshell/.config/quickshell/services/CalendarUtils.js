.pragma library

function day(date) { return new Date(date.getFullYear(), date.getMonth(), date.getDate()); }
function addDays(date, count) { return new Date(date.getFullYear(), date.getMonth(), date.getDate() + count); }
function sameDay(a, b) { return day(a).getTime() === day(b).getTime(); }
function monthStart(date) { return new Date(date.getFullYear(), date.getMonth(), 1); }
function weekStart(date) { return addDays(date, -date.getDay()); }
function range(date, mode) {
    const start = mode === "month" ? weekStart(monthStart(date)) : mode === "week" ? weekStart(date) : day(date);
    return { start: start, end: addDays(start, mode === "month" ? 42 : mode === "week" ? 7 : 1) };
}
function eventDate(value, allDay) {
    const parsed = new Date(value);
    // dcal encodes all-day dates at UTC midnight; retain the calendar date.
    return allDay ? new Date(parsed.getUTCFullYear(), parsed.getUTCMonth(), parsed.getUTCDate()) : parsed;
}
function normalize(events, calendars) {
    const allowed = {};
    calendars.forEach(c => { if (!c.hidden && !c.syncDisabled) allowed[c.id] = c; });
    return events.filter(e => allowed[e.calendarId] && e.status !== "cancelled").map(e => {
        const c = allowed[e.calendarId];
        return Object.assign({}, e, {
            startDate: eventDate(e.start, e.allDay), endDate: eventDate(e.end, e.allDay),
            calendarName: c.name, color: c.color || "", summary: e.summary || "Untitled event"
        });
    }).filter(e => isFinite(e.startDate.getTime()) && isFinite(e.endDate.getTime()) && e.endDate >= e.startDate);
}
function onDay(events, date) {
    const start = day(date).getTime(), end = addDays(date, 1).getTime();
    return events.filter(e => e.startDate.getTime() < end &&
        (e.endDate.getTime() > start || (e.endDate.getTime() === e.startDate.getTime() && e.startDate.getTime() >= start)))
        .sort((a, b) => a.startDate - b.startDate || a.endDate - b.endDate);
}
function minutes(date) { return date.getHours() * 60 + date.getMinutes(); }
function layout(events, date, minimumMinutes) {
    if (minimumMinutes === undefined) minimumMinutes = 24;
    const start = day(date), end = addDays(date, 1);
    const items = onDay(events, date).filter(e => !e.allDay).map(e => {
        const top = e.startDate <= start ? 0 : minutes(e.startDate);
        const bottom = e.endDate >= end ? 1440 : minutes(e.endDate);
        return { event: e, top: top, bottom: Math.min(1440, Math.max(top + minimumMinutes, bottom)), column: 0, columns: 1 };
    }).sort((a, b) => a.top - b.top || b.bottom - a.bottom);
    let group = [], ends = [], groupEnd = -1;
    function finish() { group.forEach(item => { item.columns = ends.length; }); }
    items.forEach(item => {
        if (item.top >= groupEnd) { finish(); group = []; ends = []; groupEnd = -1; }
        let column = ends.findIndex(endMinute => endMinute <= item.top);
        if (column < 0) column = ends.length;
        ends[column] = item.bottom;
        item.column = column;
        group.push(item);
        groupEnd = Math.max(groupEnd, item.bottom);
    });
    finish();
    return items;
}
