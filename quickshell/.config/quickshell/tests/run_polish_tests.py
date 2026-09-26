#!/usr/bin/env python3
"""Exercise control/theme regressions with fake hardware commands and a private bus."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

source = Path(__file__).resolve().parents[1]
artifacts = Path('/tmp/luci-polish-tests')
artifacts.mkdir(exist_ok=True)
with tempfile.TemporaryDirectory(prefix='luci-polish-') as directory:
    work = Path(directory)
    config = work / 'config'
    shutil.copytree(source, config)
    (config / '.current_theme').write_text('missingtheme\n')
    harness = config / 'polish-harness.qml'
    harness.write_text((config / 'tests/polish-harness.qml').read_text().replace('import "../', 'import "'))
    home = work / 'home'
    home.mkdir()
    runtime = work / 'runtime'
    runtime.mkdir(mode=0o700)
    bindir = work / 'bin'
    bindir.mkdir()
    fixture = bindir / 'fixture'
    fixture.write_text('''#!/usr/bin/python3
import os,sys,time
from pathlib import Path
root=Path(os.environ['LUCI_TEST_WORK'])
name=Path(sys.argv[0]).name
args=sys.argv[1:]
def read(key, default):
    path=root/key
    return path.read_text() if path.exists() else default
def write(key, value): (root/key).write_text(value)
if name == 'nmcli':
    if args[-1] in ('on','off'):
        write('radio', 'enabled' if args[-1]=='on' else 'disabled')
    elif 'radio' in args: print(read('radio','enabled'))
    else: print('no:50:Test network')
elif name == 'wpctl':
    if args[0]=='set-volume':
        time.sleep(.1)
        write('volume',args[-1].rstrip('%'))
    else: print('Volume:',int(read('volume','30'))/100)
elif name == 'brightnessctl':
    if args[0]=='set':
        time.sleep(.1)
        write('brightness',args[-1].rstrip('%'))
    print('Current brightness: 42 ('+read('brightness','30')+'%)')
else:
    with (root/'external').open('a') as f: f.write(name+'\\n')
''')
    fixture.chmod(0o755)
    for name in ('nmcli', 'wpctl', 'brightnessctl', 'awww', 'bluetoothctl', 'hyprctl', 'cava'):
        (bindir / name).symlink_to(fixture)
    env = dict(os.environ, HOME=str(home), XDG_CONFIG_HOME=str(home/'.config'),
               XDG_RUNTIME_DIR=str(runtime), QT_QPA_PLATFORM='offscreen', QT_QUICK_BACKEND='software',
               QS_NO_RELOAD_POPUP='1', LUCI_TEST_WORK=str(work), LUCI_TEST_OUTPUT=str(artifacts),
               PATH=str(bindir)+os.pathsep+os.environ['PATH'],
               LUCI_SYNC_WALLPAPER='0', LUCI_SYNC_KITTY='0', LUCI_SYNC_HYPRLAND='0')
    env.pop('WAYLAND_DISPLAY', None)
    result = subprocess.run(['timeout', '25s', 'dbus-run-session', '--', 'qs', '-p', str(harness), '--no-color'],
                            env=env, capture_output=True, text=True, timeout=30)
    output = result.stdout + result.stderr
    (artifacts/'polish.log').write_text(output)
    print(output)
    assert result.returncode == 0 and 'PASS slider bindings' in output
    assert (work/'volume').read_text() == '83'
    assert (work/'brightness').read_text() == '79'
    # Explicit theme sync must preserve terminal settings and emit colors only.
    kitty = home/'.config/kitty'
    kitty.mkdir(parents=True, exist_ok=True)
    original = 'font_size 17\nmap ctrl+x close_window\n'
    (kitty/'kitty.conf').write_text(original)
    subprocess.run(['bash', str(config/'scripts/theme.sh'), 'nord'], env=env, check=True)
    assert not (kitty/'luci-colors.conf').exists()
    assert not (home/'.config/hypr/current-theme/theme.lua').exists()
    env['LUCI_SYNC_KITTY'] = '1'
    subprocess.run(['bash', str(config/'scripts/theme.sh'), 'nord'], env=env, check=True)
    assert (kitty/'kitty.conf').read_text() == original
    palette = (kitty/'luci-colors.conf').read_text()
    assert 'background ' in palette and 'font_size' not in palette
    assert (config/'.current_theme').read_text() == 'nord\n'
    print('PASS opt-in theme sync preserves kitty.conf; screenshots:', artifacts)
