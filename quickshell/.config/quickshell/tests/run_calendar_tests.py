#!/usr/bin/env python3
"""Run calendar fixtures and screenshot checks in a disposable Quickshell config."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import time

if "CALENDAR_PRIVATE_BUS" not in os.environ:
    with tempfile.TemporaryDirectory(prefix="calendar-runtime-") as runtime:
        env = dict(os.environ, CALENDAR_PRIVATE_BUS="1", XDG_RUNTIME_DIR=runtime)
        sys.exit(subprocess.call(["dbus-run-session", "--", sys.executable, __file__], env=env))

source = Path(__file__).resolve().parents[1]
artifacts = Path("/tmp/quickshell-calendar-tests")
artifacts.mkdir(exist_ok=True)
with tempfile.TemporaryDirectory(prefix="calendar-tests-") as directory:
    work = Path(directory)
    config = work / "config"
    shutil.copytree(source, config)
    harness = config / "calendar-harness.qml"
    harness.write_text((config / "tests/calendar-harness.qml").read_text().replace('import "../', 'import "'))
    binary = work / "bin"
    binary.mkdir()
    shutil.copy(source / "tests/calendar-dcal.py", binary / "dcal")
    (binary / "dcal").chmod(0o755)
    mode = work / "mode"
    mode.write_text("online")
    env = dict(os.environ, QT_QPA_PLATFORM="offscreen", QT_QUICK_BACKEND="software", TZ="America/New_York",
               PATH="/usr/bin", CALENDAR_TEST_DCAL=str(binary / "dcal"), CALENDAR_TEST_MODE=str(mode))
    env.pop("WAYLAND_DISPLAY", None)
    log_path = artifacts / "calendar.log"
    with log_path.open("w") as log:
        process = subprocess.Popen(["qs", "-p", str(harness), "--no-color"], env=env, stdout=log, stderr=log)
        def ipc(method, *args):
            result = subprocess.check_output(["qs", "ipc", "-p", str(harness), "call", "test", method, *args], env=env, text=True, stderr=subprocess.STDOUT)
            return json.loads(result) if method == "state" else result.strip()
        def wait_for(predicate, timeout=8):
            deadline = time.monotonic() + timeout
            while time.monotonic() < deadline:
                if process.poll() is not None:
                    raise RuntimeError(log_path.read_text())
                try:
                    state = ipc("state")
                    if predicate(state): return state
                except subprocess.CalledProcessError:
                    pass
                time.sleep(0.05)
            raise AssertionError(str(ipc("state")) + "\n" + log_path.read_text())
        def grab(name):
            time.sleep(0.4)
            ipc("grab", str(artifacts / (name + ".png")))
            time.sleep(0.2)
        try:
            wait_for(lambda s: True)
            assert ipc("dates") == "passed"
            ipc("open")
            time.sleep(0.4)
            ipc("clickClock")
            assert ipc("state")["mode"] != 9
            ipc("open")
            time.sleep(0.4)
            ipc("clickDate")
            wait_for(lambda s: s["hasData"] and not s["loading"])
            assert ipc("state")["count"] == 3
            ipc("date", "2026-09-13T12:00:00-04:00")
            wait_for(lambda s: not s["loading"])
            ipc("wheel", "-120", "false")
            time.sleep(0.3)
            s = ipc("state")
            assert s["wheelPending"] and s["firstWeek"] == "2026-08-30", s
            assert abs(s["rowOffset"] - round(s["rowOffset"])) > 0.01, s
            ipc("wheel", "-120", "false")
            time.sleep(0.3)
            s = ipc("state")
            assert s["wheelPending"] and s["firstWeek"] == "2026-08-30", s
            wait_for(lambda s: not s["wheelPending"] and abs(s["rowOffset"]) < 0.01)
            ipc("date", "2026-09-13T12:00:00-04:00")
            mode.write_text("offline")
            ipc("arrow", "1")
            assert ipc("state")["firstWeek"] == "2026-08-30"
            ipc("rowArrow", "1")
            wait_for(lambda s: s["firstWeek"] == "2026-09-06" and abs(s["rowOffset"]) < 0.01)
            assert ipc("state")["hasData"] and ipc("state")["error"] != "Events unavailable"
            ipc("rowArrow", "-1")
            wait_for(lambda s: s["firstWeek"] == "2026-08-30" and abs(s["rowOffset"]) < 0.01)
            ipc("monthJump", "1")
            wait_for(lambda s: s["firstWeek"] == "2026-09-27" and abs(s["rowOffset"]) < 0.01)
            mode.write_text("online")
            ipc("date", "2026-09-13T12:00:00-04:00")
            ipc("unread", "3")
            grab("month")
            badge = json.loads(ipc("badgePosition"))
            assert abs(badge["center"] - badge["width"] / 2) < 0.6 and badge["top"] == 18, badge
            ipc("holdMonthDrag")
            s = ipc("state")
            assert s["rowOffset"] > 0.5 and s["shift"] == 0, s
            grab("month-half-drag")
            ipc("releaseMonthDrag")
            wait_for(lambda s: s["firstWeek"] == "2026-09-06" and abs(s["rowOffset"]) < 0.01)
            ipc("date", "2026-12-13T12:00:00-05:00")
            ipc("monthJump", "1")
            wait_for(lambda s: s["firstWeek"] == "2026-12-27" and abs(s["rowOffset"]) < 0.01)
            ipc("monthJump", "-1")
            wait_for(lambda s: s["firstWeek"] == "2026-11-29" and abs(s["rowOffset"]) < 0.01)
            ipc("date", "2026-03-08T12:00:00-04:00")
            ipc("rowArrow", "1")
            ipc("rowArrow", "1")
            wait_for(lambda s: s["firstWeek"] == "2026-03-15" and abs(s["rowOffset"]) < 0.01)
            ipc("date", "2026-09-13T12:00:00-04:00")
            for view in ("week", "day"):
                ipc("view", view)
                wait_for(lambda s: s["hasData"] and not s["loading"])
                ipc("scrollTimeline", "615")
                wait_for(lambda s: all(abs(p["y"] - 615) < 0.1 for p in s["pages"]))
                ipc("holdDrag")
                grab(view + "-half-drag")
                assert all(abs(p["y"] - 615) < 0.1 for p in ipc("state")["pages"])
                ipc("releaseDrag")
                expected = "2026-09-20" if view == "week" else "2026-09-14"
                wait_for(lambda s: s["date"] == expected and abs(s["shift"]) < 0.1)
                assert all(abs(p["y"] - 615) < 0.1 for p in ipc("state")["pages"])
                ipc("arrow", "-1")
                wait_for(lambda s: s["date"] == "2026-09-13" and abs(s["shift"]) < 0.1)
                assert all(abs(p["y"] - 615) < 0.1 for p in ipc("state")["pages"])
                grab(view)
            before = ipc("state")
            ipc("wheel", "120", "true")
            after = wait_for(lambda s: s["zoom"] > 60)
            assert all(abs(p["hourHeight"] - after["zoom"]) < 0.1 for p in after["pages"])
            assert abs((before["pages"][1]["y"] + 100) / 60 - (after["pages"][1]["y"] + 100) / after["zoom"]) < 0.01, (before, after)
            grab("day-zoomed")
            ipc("wheel", "-120", "false")
            wait_for(lambda s: abs(s["pages"][1]["y"] - after["pages"][1]["y"]) > 1)
            assert ipc("state")["zoom"] == after["zoom"]
            ipc("wheel", "-120", "true")
            assert abs(ipc("state")["zoom"] - 60) < 0.01
            ipc("modifiedHeaderWheel", "120")
            assert ipc("state")["zoom"] > 60
            ipc("modifiedHeaderWheel", "-120")
            assert abs(ipc("state")["zoom"] - 60) < 0.01
            ipc("details")
            grab("details")
            ipc("pressEscape")
            assert not ipc("state")["details"]
            mode.write_text("malformed")
            ipc("refresh")
            wait_for(lambda s: bool(s["error"]) and not s["loading"])
            assert ipc("state")["hasData"]
            mode.write_text("offline")
            ipc("date", "2027-10-13T12:00:00-04:00")
            wait_for(lambda s: s["error"] == "Events unavailable")
            assert not ipc("state")["hasData"]
            mode.write_text("slow")
            ipc("refresh")
            ipc("view", "week")
            ipc("date", "2026-09-13T12:00:00-04:00")
            wait_for(lambda s: s["hasData"] and not s["loading"] and not s["error"])
            ipc("narrow")
            grab("week-narrow")
            ipc("swipe", "-1", "true")
            wait_for(lambda s: s["date"] == "2026-09-20" and abs(s["shift"]) < 0.1)
            ipc("view", "month")
            wait_for(lambda s: s["hasData"] and not s["loading"])
            grab("month-narrow")
            badge = json.loads(ipc("badgePosition"))
            assert abs(badge["center"] - badge["width"] / 2) < 0.6, badge
            ipc("view", "day")
            ipc("wheel", "120000", "true")
            assert ipc("state")["zoom"] == 180
            ipc("wheel", "-120000", "true")
            assert ipc("state")["zoom"] == 24
            # QProcess fails before an exit signal when an executable's interpreter is missing.
            (binary / "dcal").write_text("#!/calendar-test-missing-interpreter\n")
            ipc("refresh")
            wait_for(lambda s: not s["loading"] and bool(s["error"]))
            shutil.copy(source / "tests/calendar-dcal.py", binary / "dcal")
            (binary / "dcal").chmod(0o755)
            mode.write_text("online")
            ipc("refresh")
            wait_for(lambda s: not s["loading"] and not s["error"])
            mode.write_text("hang")
            ipc("refresh")
            wait_for(lambda s: not s["loading"] and bool(s["error"]), timeout=15)
            mode.write_text("offline")
            ipc("refresh")
            wait_for(lambda s: not s["loading"] and bool(s["error"]))
            mode.write_text("online")
            # The production timer must recover without a shell restart or manual refresh.
            wait_for(lambda s: not s["loading"] and not s["error"], timeout=35)
            print("PASS failed launch, hung request, and automatic daemon recovery", flush=True)
            ipc("pressEscape")
            assert ipc("state")["mode"] == 1 and ipc("state")["pinned"]
            ipc("clickDate")
            time.sleep(0.4)
            assert ipc("state")["zoom"] == 60
            ipc("clickBadge")
            assert ipc("state")["mode"] == 3, ipc("state")
            print("PASS date-only opening, badge, arrows, swipes, prefetch, layout, pagination, recovery and Escape")
        finally:
            process.terminate()
            process.wait(timeout=5)
    print(log_path.read_text())
    print("Screenshots:", artifacts)
