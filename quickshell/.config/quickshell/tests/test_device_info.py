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

    def test_routing_identity_and_partial_failure(self):
        sinks = [{'name':'bluez_output.AA_BB_CC_DD_EE_FF.1','index':10,'properties':{}},
                 {'name':'same-display-name','index':11,'properties':{}}]
        calls=[]
        def fake(*args, **kwargs):
            calls.append(args)
            if args[-1]=='sinks': return json.dumps(sinks)
            if args[-1]=='get-default-sink': return 'old'
            if args[-1]=='sink-inputs': return json.dumps([{'index':5,'sink':9}])
            if 'move-sink-input' in args: raise subprocess.CalledProcessError(1,args)
            return ''
        with patch.object(helper,'run',fake):
            result=helper.audio_info('AA:BB:CC:DD:EE:FF')
        self.assertIn('some apps',result['error'])
        self.assertTrue(result['outputs'][0]['default'])
        self.assertIn(('pactl','set-default-sink',sinks[0]['name']), calls)
        self.assertFalse(any('volume' in ' '.join(c) for c in calls))
        with patch.object(helper,'run',fake):
            with self.assertRaisesRegex(ValueError,'no audio output'):
                helper.audio_info('11:22:33:44:55:66')

if __name__ == '__main__': unittest.main()
