import importlib.util
import json
import sys
sys.dont_write_bytecode = True
from pathlib import Path
import subprocess
import unittest
from unittest.mock import patch

root = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('device_info', root/'scripts/device-info.py')
helper = importlib.util.module_from_spec(spec)
spec.loader.exec_module(helper)
fixture = (root/'tests/fixtures/solaar-show.txt').read_text()

class DeviceInfoTests(unittest.TestCase):
    def test_actual_solaar_format(self):
        devices = helper.parse_solaar(fixture)
        self.assertEqual([d['name'] for d in devices], ['MX Keys S', 'MX Master 3S'])
        self.assertEqual([d['battery'] for d in devices], [35, 55])
        self.assertFalse(any(d['charging'] for d in devices))
        self.assertEqual([d['kind'] for d in devices], ['keyboard', 'mouse'])

    def test_zero_category_charging_and_offline(self):
        text = fixture.replace('35%', '0%').replace('55%', 'good').replace('BatteryStatus.DISCHARGING', 'BatteryStatus.RECHARGING')
        devices = helper.parse_solaar(text)
        self.assertEqual(devices[0]['battery'], 0)
        self.assertTrue(devices[0]['charging'])
        self.assertIsNone(devices[1]['battery'])
        self.assertEqual(devices[1]['batteryLabel'], 'good')
        sleeping = helper.parse_solaar('Bolt Receiver\n  1: MX Keys S\n     Device is offline.\n')
        self.assertFalse(sleeping[0]['online'])
        self.assertEqual(sleeping[0]['id'], devices[0]['id'])
        self.assertEqual(helper.parse_solaar('solaar version 1.1.20\n'), [])

    def test_routing_and_partial_failure(self):
        route_spec = importlib.util.spec_from_file_location('route_audio', root/'scripts/route-audio.py')
        route = importlib.util.module_from_spec(route_spec)
        route_spec.loader.exec_module(route)
        for kind, stream_type in [('sink', 'sink-input'), ('source', 'source-output')]:
            def fake(*args):
                if args[-1] == kind + 's':
                    return json.dumps([dict(name='headset', index=10), dict(name='speaker.monitor', index=11)])
                if args[-1] == stream_type + 's':
                    return json.dumps([{'index': 1, kind: 9}, {'index': 2, kind: 11}])
                if args[0].startswith('move-'):
                    raise subprocess.CalledProcessError(1, args)
            with patch.object(route, 'pactl', side_effect=fake) as command:
                with self.assertRaisesRegex(ValueError, 'some apps'):
                    route.select(kind, 'headset')
                command.assert_any_call('set-default-' + kind, 'headset')
                command.assert_any_call('move-' + stream_type, '1', 'headset')
                if kind == 'source':
                    self.assertNotIn(unittest.mock.call('move-source-output', '2', 'headset'), command.call_args_list)
                with self.assertRaisesRegex(ValueError, 'disconnected'):
                    route.select(kind, 'unplugged')

if __name__ == '__main__': unittest.main()
