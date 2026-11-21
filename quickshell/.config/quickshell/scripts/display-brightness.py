#!/usr/bin/env python3
"""Read or change one connector's hardware brightness, expressed as a percentage."""
import json
import re
import subprocess
import sys
from pathlib import Path


def run(*args):
    return subprocess.check_output(args, text=True, stderr=subprocess.PIPE, timeout=8)


def requested(value, current, maximum):
    percent = int(value)
    if value.startswith(('+', '-')):
        raw = current + round(percent * maximum / 100)
    else:
        raw = round(percent * maximum / 100)
    return max(0, min(maximum, raw))


def brightness(connector, value):
    if not connector:
        raise ValueError('Waiting for a display.')
    if connector.startswith(('eDP-', 'LVDS-', 'DSI-')):
        cmd = ['brightnessctl', '--class=backlight']
        devices = list(Path('/sys/class/backlight').iterdir())
        if len(devices) != 1:
            raise ValueError('No unambiguous panel backlight available.')
        cmd += ['--device', devices[0].name]
        maximum = int(run(*cmd, 'max'))
        current = int(run(*cmd, 'get'))
        if value:
            run(*cmd, 'set', str(requested(value, current, maximum)))
            current = int(run(*cmd, 'get'))
    else:
        detected = run('ddcutil', 'detect', '--brief')
        for block in re.split(r'(?m)^(?=Display \d+|Invalid display)', detected):
            if not block.startswith('Display '):
                continue
            if re.search(r'DRM connector:\s*card\d+-' + re.escape(connector) + r'\s*$', block, re.M):
                bus = re.search(r'/dev/i2c-(\d+)', block)
                if bus:
                    break
        else:
            raise ValueError('Monitor unavailable. Check DDC/CI in its display menu.')
        cmd = ['ddcutil', '--bus', bus[1]]
        def read():
            match = re.search(r'VCP 10 C (\d+) (\d+)', run(*cmd, 'getvcp', '10', '--terse'))
            if not match or int(match[2]) == 0:
                raise ValueError('Monitor brightness control unavailable.')
            return int(match[1]), int(match[2])
        current, maximum = read()
        if value:
            target = requested(value, current, maximum)
            if target != current:
                run(*cmd, 'setvcp', '10', str(target))
                current, maximum = read()
    return round(100 * current / maximum)


if __name__ == '__main__':
    try:
        value = sys.argv[2] if len(sys.argv) > 2 else ''
        percent = brightness(sys.argv[1], value)
        if value and '--quiet' not in sys.argv[3:]:
            event = Path.home() / '.cache/quickshell/status/event'
            event.parent.mkdir(parents=True, exist_ok=True)
            event.write_text(f'brightness|{percent}\n')
        print(json.dumps({'percent': percent}))
    except FileNotFoundError as error:
        print(json.dumps({'error': f'Brightness tool unavailable: {error.filename}'}))
        sys.exit(1)
    except (ValueError, OSError, subprocess.SubprocessError) as error:
        message = str(error) if isinstance(error, ValueError) else 'Cannot access brightness. Check monitor power, DDC/CI and device permissions.'
        print(json.dumps({'error': message}))
        sys.exit(1)
