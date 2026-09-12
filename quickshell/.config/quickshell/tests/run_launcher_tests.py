#!/usr/bin/env python3
"""Test launchers in a disposable config, application catalog and clipboard DB."""
import argparse
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--output', type=Path)
args = parser.parse_args()
with tempfile.TemporaryDirectory(prefix='luci-launcher-tests-') as directory:
    work = Path(directory)
    config = work / 'config'
    shutil.copytree(Path(__file__).resolve().parents[1], config)
    template = (config / 'tests/launcher-harness.qml').read_text()
    (config / 'launcher-harness.qml').write_text(template.replace('import "../', 'import "'))
    runtime = work / 'runtime'; runtime.mkdir(mode=0o700)
    catalog = work / 'data/applications'; catalog.mkdir(parents=True)
    empty = work / 'empty'; empty.mkdir()
    bindir = work / 'bin'; bindir.mkdir()
    (work / 'working directory').mkdir()
    recorder = work / 'record.py'
    recorder.write_text('import json,os,sys\nfrom pathlib import Path\nPath(os.environ["LUCI_TEST_WORK"],"launch.json").write_text(json.dumps({"args":sys.argv[1:],"cwd":os.getcwd()}))\n')
    for ident, name, command, terminal, extra in [
        ('alpha', 'Alpha Editor', f'python3 {recorder} %c "literal argument" %U', False, 'Comment=A browser of source files\n'),
        ('alpine', 'Alpine Terminal', '/usr/bin/true', True, ''),
        ('beta', 'Beta Browser', '/usr/bin/true', False, 'Keywords=web;internet;\n'),
        ('broken', 'Broken App', '/does/not/exist/luci-test', False, ''),
        ('hidden', 'Hidden App', '/usr/bin/true', False, 'NoDisplay=true\n'),
    ]:
        (catalog / f'{ident}.desktop').write_text(f'[Desktop Entry]\nType=Application\nName={name}\nExec={command}\nTerminal={str(terminal).lower()}\nPath={work / "working directory"}\n{extra}')
    ghostty = bindir / 'ghostty'
    ghostty.write_text('#!/usr/bin/python3\nimport json,os,sys\nfrom pathlib import Path\nPath(os.environ["LUCI_TEST_WORK"],"terminal.json").write_text(json.dumps(sys.argv))\n')
    ghostty.chmod(0o755)
    copy = bindir / 'wl-copy'
    copy.write_text('''#!/usr/bin/python3
import os,sys,time
from pathlib import Path
work=Path(os.environ['LUCI_TEST_WORK'])
if (work/'copy-fail').exists(): sys.exit(1)
time.sleep(.15)
(work/'copied.bin').write_bytes(sys.stdin.buffer.read())
with (work/'copy-count').open('a') as f: f.write('x')
''')
    copy.chmod(0o755)
    env = os.environ.copy()
    env.pop('WAYLAND_DISPLAY', None)
    env.update(QT_QPA_PLATFORM='offscreen', QT_QUICK_BACKEND='software', QS_NO_RELOAD_POPUP='1',
               XDG_RUNTIME_DIR=str(runtime), XDG_DATA_HOME=str(work/'data'), XDG_DATA_DIRS=str(empty),
               XDG_CACHE_HOME=str(work/'cache'), NO_AT_BRIDGE='1', LUCI_TEST_WORK=str(work), PATH=str(bindir)+os.pathsep+env['PATH'])
    env.pop('CLIPHIST_DB_PATH', None)
    env.pop('CLIPHIST_CONFIG_PATH', None)
    # Explicit database location also overrides any user-level cliphist config.
    env['CLIPHIST_DB_PATH'] = str(work/'clipboard.db')
    payload = ('  Unicode café 日本語\nsecond line\t$(touch ' + str(work/'injected') + ')\n\n').encode()
    (work/'expected.bin').write_bytes(payload)
    for data in [b'First clipboard entry', payload]:
        subprocess.run(['cliphist', 'store'], input=data, env=env, check=True)
    run = subprocess.run(['dbus-run-session', '--', sys.executable, str(config/'tests/test_launchers.py')], env=env)
    if args.output:
        args.output.mkdir(parents=True, exist_ok=True)
        for item in (config/'tests').iterdir():
            if item.suffix in ('.png', '.log'): shutil.copy2(item, args.output/item.name)
        print(f'Test artifacts: {args.output.resolve()}')
    if run.returncode and (config/'tests/launcher-test.log').exists():
        print((config/'tests/launcher-test.log').read_text())
    sys.exit(run.returncode)
