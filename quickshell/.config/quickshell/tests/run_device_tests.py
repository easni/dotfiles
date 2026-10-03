#!/usr/bin/env python3
"""Run device-panel checks with private buses, fake commands and no hardware access."""
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

source = Path(__file__).resolve().parents[1]
subprocess.run([sys.executable, str(source/'tests/test_device_info.py')], check=True)
artifacts = Path('/tmp/luci-device-tests')
artifacts.mkdir(exist_ok=True)
with tempfile.TemporaryDirectory(prefix='luci-devices-') as directory:
    work=Path(directory)
    config=work/'config'
    shutil.copytree(source,config)
    harness=config/'devices-harness.qml'
    harness.write_text((config/'tests/devices-harness.qml').read_text().replace('import "../','import "'))
    runtime=work/'runtime'; runtime.mkdir(mode=0o700)
    home=work/'home'; home.mkdir()
    bindir=work/'bin'; bindir.mkdir()
    fixture=bindir/'fixture'
    fixture.write_text('''#!/usr/bin/python3
import json,os,sys
from pathlib import Path
root=Path(os.environ['LUCI_TEST_WORK'])
name=Path(sys.argv[0]).name
args=sys.argv[1:]
if name=='solaar': print((root/'config/tests/fixtures/solaar-show.txt').read_text())
elif name=='pactl':
    sink='bluez_output.AA_BB_CC_DD_EE_FF.1'
    if args[-1]=='sinks': print(json.dumps([dict(name=sink,index=10,properties={})]))
    elif args[-1]=='get-default-sink': print(sink if (root/'default').exists() else 'old')
    elif args[-1]=='sink-inputs': print('[]')
    elif args[0]=='set-default-sink': (root/'default').write_text(args[-1])
elif name=='wpctl': print('Volume: 0.2')
elif name=='brightnessctl': print('Brightness (50%)')
''')
    fixture.chmod(0o755)
    for name in ['solaar','pactl','wpctl','brightnessctl','nmcli','bluetoothctl','cava']:
        (bindir/name).symlink_to(fixture)
    env=dict(os.environ, HOME=str(home), XDG_CONFIG_HOME=str(home/'.config'), XDG_RUNTIME_DIR=str(runtime),
             DBUS_SYSTEM_BUS_ADDRESS='unix:path=/nonexistent-luci-test', QT_QPA_PLATFORM='offscreen',
             QT_QUICK_BACKEND='software', QS_NO_RELOAD_POPUP='1', LUCI_TEST_WORK=str(work),
             LUCI_TEST_OUTPUT=str(artifacts), PATH=str(bindir)+os.pathsep+os.environ['PATH'])
    env.pop('WAYLAND_DISPLAY',None)
    result=subprocess.run(['timeout','25s','dbus-run-session','--','qs','-p',str(harness),'--no-color'],
                          env=env,capture_output=True,text=True,timeout=30)
    output=result.stdout+result.stderr
    (artifacts/'devices.log').write_text(output)
    print(output)
    assert result.returncode==0 and 'PASS device models' in output and 'FAIL' not in output
    print('Screenshots:',artifacts)
