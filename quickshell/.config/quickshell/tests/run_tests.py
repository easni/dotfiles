#!/usr/bin/env python3
"""Run Luci's protocol and UI tests on private buses and a disposable config.

Requires Quickshell, QtTest, dbus-run-session, python-dbus and PyGObject.
No notifications are sent to the desktop session. Optional --output saves
screenshots and logs for inspection.
"""
import argparse
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--output', type=Path, help='Save screenshots and logs here')
args = parser.parse_args()

with tempfile.TemporaryDirectory(prefix='luci-notification-tests-') as directory:
    work = Path(directory)
    config = work / 'config'
    shutil.copytree(Path(__file__).resolve().parents[1], config)
    # Quickshell treats the entrypoint's directory as its import boundary.
    # Put harness entrypoints at the root of the disposable configuration.
    for name in ('notification-harness.qml', 'ui-harness.qml'):
        template = (config / 'tests' / name).read_text()
        (config / name).write_text(template.replace('import "../', 'import "'))
    runtime = work / 'runtime'
    runtime.mkdir(mode=0o700)
    env = os.environ.copy()
    env.pop('WAYLAND_DISPLAY', None)
    env.update(QT_QPA_PLATFORM='offscreen', QT_QUICK_BACKEND='software',
               XDG_RUNTIME_DIR=str(runtime), QS_NO_RELOAD_POPUP='1')
    tests = config / 'tests'
    result = 0
    for name in ('test_notifications.py', 'test_ui.py'):
        run = subprocess.run(['dbus-run-session', '--', sys.executable, str(tests / name)], env=env)
        result = result or run.returncode
    if args.output:
        args.output.mkdir(parents=True, exist_ok=True)
        for artifact in tests.iterdir():
            if artifact.suffix in ('.png', '.log'):
                shutil.copy2(artifact, args.output / artifact.name)
        print(f'Test artifacts: {args.output.resolve()}')
    if result:
        for log in tests.glob('*.log'):
            print(f'--- {log.name} ---\n{log.read_text()}')
    sys.exit(result)
