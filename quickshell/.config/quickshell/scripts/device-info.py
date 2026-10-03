#!/usr/bin/env python3
"""Read receiver batteries or explicitly select a Bluetooth audio output."""
import json
import os
import re
import subprocess
import sys


def run(*args, timeout=4):
    return subprocess.run(args, capture_output=True, text=True, timeout=timeout,
                          env=dict(os.environ, LC_ALL='C'), check=True).stdout


def parse_solaar(text):
    devices, current, receiver = [], None, None
    for line in text.splitlines():
        if line and not line[0].isspace():
            receiver = line.strip() if 'Receiver' in line else None
            current = None
        match = re.match(r'^  (\d+): (.+)$', line)
        if match and receiver:
            current = dict(id=f'{receiver}:{match[1]}', name=match[2], kind='device',
                           online=True, battery=None, batteryLabel='', charging=False, stale=False)
            devices.append(current)
        if current is None:
            continue
        if 'Device is offline' in line or 'device is offline' in line:
            current['online'] = False
        match = re.match(r'^     Kind\s*:\s*(.+)', line)
        if match:
            current['kind'] = match[1].strip()
        # Receiver+slot remains stable even when a sleeping device omits its serial.
        match = re.search(r'Battery: ([^,]+)(?:,\s*(.*))?', line)
        if match:
            level, status = match.groups()
            percent = re.match(r'^(\d+)%', level)
            if percent and 0 <= int(percent[1]) <= 100:
                current['battery'] = int(percent[1])
            elif level.lower() not in ('n/a', 'unknown (device is offline).'):
                current['batteryLabel'] = level.strip().rstrip('.')
            current['charging'] = bool(status and re.search(r'(?<!DIS)CHARGING|RECHARGING', status.upper()))
    return devices


def receiver_info():
    text = run('solaar', 'show', timeout=20)
    return {'devices': parse_solaar(text), 'error': ''}


def address(value):
    return re.sub(r'[^0-9A-F]', '', value.upper())


def sink_address(sink):
    props = sink.get('properties', {})
    for key in ('api.bluez5.address', 'device.string'):
        candidate = props.get(key, '')
        if re.fullmatch(r'(?:[0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}', candidate):
            return address(candidate)
    match = re.match(r'^bluez_output\.([0-9a-fA-F_]{17})(?:\.|$)', sink.get('name', ''))
    return address(match[1]) if match else ''


def audio_info(target=None):
    sinks = json.loads(run('pactl', '-f', 'json', 'list', 'sinks'))
    default = run('pactl', 'get-default-sink').strip()
    error = ''
    if target:
        matched = [s for s in sinks if sink_address(s) == address(target)]
        if not matched:
            raise ValueError('This device has no audio output yet. Try again after it connects.')
        sink = next((s for s in matched if s['name'] == default), matched[0])
        run('pactl', 'set-default-sink', sink['name'])
        default = sink['name']
        inputs = json.loads(run('pactl', '-f', 'json', 'list', 'sink-inputs'))
        failures = []
        for stream in inputs:
            try:
                run('pactl', 'move-sink-input', str(stream['index']), sink['name'])
            except subprocess.CalledProcessError:
                failures.append(stream['index'])
        if failures:
            remaining = {s['index'] for s in json.loads(run('pactl', '-f', 'json', 'list', 'sink-inputs'))
                         if s['sink'] != sink['index']}
            if remaining.intersection(failures):
                error = 'Default output changed, but some apps could not be moved. Retry.'
    return {'outputs': [{'address': sink_address(s), 'default': s['name'] == default}
                        for s in sinks if sink_address(s)], 'error': error}


def main():
    try:
        result = receiver_info() if sys.argv[1] == 'receiver' else audio_info(sys.argv[2] if len(sys.argv) > 2 else None)
    except FileNotFoundError as error:
        result = {'error': 'Install Solaar to read receiver batteries.' if error.filename == 'solaar' else 'Audio tools unavailable.'}
    except subprocess.TimeoutExpired:
        result = {'error': 'Device query timed out. Wake the device and retry.'}
    except subprocess.CalledProcessError as error:
        detail = (error.stderr or '').lower()
        if 'permission' in detail or 'access' in detail:
            message = 'Receiver access denied. Check Solaar device permissions, then retry.'
        elif 'no supported device' in detail:
            result = {'devices': [], 'error': ''}
            print(json.dumps(result))
            return
        else:
            message = 'Could not read or update devices. Retry.'
        result = {'error': message}
    except (ValueError, KeyError, IndexError) as error:
        result = {'error': str(error) if isinstance(error, ValueError) and not isinstance(error, json.JSONDecodeError)
                  else 'Unexpected device response. Retry.'}
    print(json.dumps(result))


if __name__ == '__main__':
    main()
