#!/usr/bin/env python3
"""Check media timing and synchronized scrolling on a private session bus."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

with tempfile.TemporaryDirectory(prefix="quickshell-media-tests-") as directory:
    work = Path(directory)
    config = work / "config"
    shutil.copytree(Path(__file__).resolve().parents[1], config)
    harness = config / "media-harness.qml"
    harness.write_text((config / "tests/media-harness.qml").read_text().replace('import "../', 'import "'))
    runtime = work / "runtime"
    runtime.mkdir(mode=0o700)
    env = os.environ.copy()
    env.pop("WAYLAND_DISPLAY", None)
    env.update(QT_QPA_PLATFORM="offscreen", QT_QUICK_BACKEND="software",
               XDG_RUNTIME_DIR=str(runtime), QS_NO_RELOAD_POPUP="1")
    result = subprocess.run(
        ["dbus-run-session", "--", "qs", "-p", str(harness), "--no-color"],
        env=env, capture_output=True, text=True, timeout=20)
    output = result.stdout + result.stderr
    print(output)
    assert result.returncode == 0, result.returncode
    assert "PASS direct position, missing duration, and synchronized text cycles" in output
