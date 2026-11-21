#!/usr/bin/env python3
"""Select a default device and reroute existing PulseAudio-compatible streams."""
import json
import subprocess
import sys


def pactl(*args):
    return subprocess.check_output(['pactl', *args], text=True, timeout=4)


def entries(kind):
    return json.loads(pactl('-f', 'json', 'list', kind))


def select(kind, name):
    stream_kind = {'sink': 'sink-input', 'source': 'source-output'}[kind]
    devices = entries(kind + 's')
    target = next((d for d in devices if d['name'] == name), None)
    if target is None:
        raise ValueError('Device disconnected. Choose another device.')
    # Preserve desktop-audio capture when changing the microphone.
    monitors = {d['index'] for d in devices if kind == 'source' and d['name'].endswith('.monitor')}
    pactl('set-default-' + kind, name)
    failures = set()
    for stream in entries(stream_kind + 's'):
        if stream[kind] == target['index'] or stream[kind] in monitors:
            continue
        try:
            pactl('move-' + stream_kind, str(stream['index']), name)
        except subprocess.CalledProcessError:
            failures.add(stream['index'])
    if failures and any(s['index'] in failures and s[kind] != target['index']
                        for s in entries(stream_kind + 's')):
        raise ValueError('Default changed, but some apps could not be moved. Select the device to retry.')


if __name__ == '__main__':
    try:
        if len(sys.argv) == 1:
            result = {}
            for kind in ('sink', 'source'):
                devices = entries(kind + 's')
                result[kind] = [dict(name=d['name'], description=d.get('description') or d['name'])
                                for d in devices if kind == 'sink' or not d['name'].endswith('.monitor')]
                result['default_' + kind] = pactl('get-default-' + kind).strip() if result[kind] else ''
            print(json.dumps(result))
        else:
            select(*sys.argv[1:])
    except (OSError, subprocess.SubprocessError, ValueError, KeyError) as error:
        print(str(error) if isinstance(error, ValueError) else 'Audio routing failed. Select the device to retry.')
        sys.exit(1)
