#!/usr/bin/env python3
"""Deterministic read-only IPC fixture for the calendar harness."""
import json
import os
import signal
from pathlib import Path
import sys
import time

mode = Path(os.environ["CALENDAR_TEST_MODE"]).read_text().strip()
if mode == "offline":
    sys.exit(1)
if mode == "malformed":
    print("not json")
    sys.exit(0)
if mode == "slow":
    time.sleep(0.3)
if mode == "hang":
    signal.signal(signal.SIGTERM, signal.SIG_IGN)
    time.sleep(60)
method = sys.argv[2]
if method == "calendars.list":
    print(json.dumps([{"id": "work", "name": "Work", "color": "#65b7df"},
                      {"id": "hidden", "hidden": True}]))
elif method == "events.list":
    params = dict(arg.split("=", 1) for arg in sys.argv[3:])
    date = "2026-09-13"
    events = [
        {"id": "1", "calendarId": "work", "summary": "Design review", "start": date + "T09:00:00-04:00", "end": date + "T10:30:00-04:00", "location": "Studio", "description": "Review the calendar layout."},
        {"id": "2", "calendarId": "work", "summary": "Planning", "start": date + "T10:00:00-04:00", "end": date + "T11:00:00-04:00"},
        {"id": "3", "calendarId": "work", "summary": "Release week", "start": date + "T00:00:00Z", "end": "2026-09-15T00:00:00Z", "allDay": True},
        {"id": "4", "calendarId": "hidden", "summary": "Hidden", "start": date + "T09:00:00-04:00", "end": date + "T10:00:00-04:00"},
    ]
    offset = int(params["offset"])
    print(json.dumps({"events": events[offset:offset + 2], "total": len(events)}))
else:
    sys.exit("Unexpected IPC mutation or method: " + method)
