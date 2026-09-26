#!/usr/bin/env python3
"""Opt-in live audio check: briefly lower default volume by 1%, then restore it.

Requires active playback. Runs a disposable shell containing only the audio
services, checks both CAVA feeds and reconnection, and restores volume on exit.
"""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time

source = Path(__file__).resolve().parents[1]
def command(*args):
    return subprocess.check_output(args, text=True, stderr=subprocess.STDOUT).strip()
def volume():
    return float(command('wpctl', 'get-volume', '@DEFAULT_AUDIO_SINK@').split()[1])
original = volume()
sink = command('pactl', 'get-default-sink')
assert original > .01, 'Play audio at a nonzero volume before running this check'
with tempfile.TemporaryDirectory(prefix='luci-live-audio-') as directory:
    config = Path(directory)/'config'
    shutil.copytree(source, config)
    harness = config/'audio-harness.qml'
    harness.write_text((config/'tests/audio-harness.qml').read_text().replace('import "../', 'import "'))
    env = dict(os.environ, QT_QPA_PLATFORM='offscreen', QT_QUICK_BACKEND='software')
    env.pop('WAYLAND_DISPLAY', None)
    with (Path(directory)/'audio.log').open('w+') as log:
        process = subprocess.Popen(['qs', '-p', str(harness), '--no-color'], env=env, stdout=log, stderr=log)
        def ipc(method, *args):
            return subprocess.check_output(['qs', 'ipc', '-p', str(harness), 'call', 'audioTest', method, *map(str,args)], env=env, text=True, stderr=subprocess.STDOUT).strip()
        def samples():
            large, mini = set(), set()
            deadline = time.monotonic()+4
            while time.monotonic()<deadline:
                state = json.loads(ipc('state'))
                large.add(tuple(state['large']))
                mini.add(tuple(state['mini']))
                time.sleep(.1)
            assert len(large)>3 and any(any(frame) for frame in large), large
            assert len(mini)>3 and any(any(frame) for frame in mini), mini
            return len(large), len(mini)
        changed_volume = False
        try:
            time.sleep(1)
            print('Changing frames (large, mini):', samples(), flush=True)
            ipc('reconnect')
            time.sleep(1)
            print('After reconnection:', samples(), flush=True)
            target = max(0, round(original*100)-1)
            changed_volume = True
            ipc('volume', target)
            time.sleep(.4)
            actual = volume()
            assert abs(actual-target/100)<.005, (actual,target)
            assert command('pactl','get-default-sink')==sink
            print('PASS AudioService changed Bluetooth/default output to',actual,flush=True)
        except subprocess.CalledProcessError as error:
            print('IPC failure:', error.output, 'Shell status:', process.poll(), flush=True)
            raise
        finally:
            process.terminate()
            process.wait(timeout=5)
            if changed_volume:
                subprocess.run(['pactl','set-sink-volume',sink,str(round(original*100))+'%'],check=True)
            log.seek(0)
            print(log.read())
            print('Restored volume:', volume())
