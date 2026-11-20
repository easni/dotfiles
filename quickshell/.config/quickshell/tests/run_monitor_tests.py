#!/usr/bin/env python3
"""Exercise multiple island sessions and hotplug without changing desktop outputs."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

source = Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory(prefix='luci-monitors-') as directory:
    work = Path(directory)
    config = work / 'config'
    shutil.copytree(source, config)
    harness = config / 'monitors-harness.qml'
    harness.write_text((config / 'tests/monitors-harness.qml').read_text().replace('import "../', 'import "'))
    runtime = work / 'runtime'
    runtime.mkdir(mode=0o700)
    home = work / 'home'
    home.mkdir()
    env = dict(os.environ, HOME=str(home), XDG_CONFIG_HOME=str(home/'.config'),
               XDG_RUNTIME_DIR=str(runtime), QT_QPA_PLATFORM='offscreen', QT_QUICK_BACKEND='software',
               QS_NO_RELOAD_POPUP='1')
    env.pop('WAYLAND_DISPLAY', None)
    env.pop('HYPRLAND_INSTANCE_SIGNATURE', None)
    result = subprocess.run(['timeout', '30s', 'dbus-run-session', '--', 'qs', '-p', str(harness), '--no-color'],
                            env=env, capture_output=True, text=True, timeout=35)
    output = result.stdout + result.stderr
    print(output)
    assert result.returncode == 0 and 'PASS multi-monitor lifecycle and routing' in output
    assert 'ReferenceError' not in output and 'TypeError' not in output and 'Binding loop' not in output
