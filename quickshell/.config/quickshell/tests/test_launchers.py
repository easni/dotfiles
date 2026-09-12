"""Private-session launcher integration tests; invoked by run_launcher_tests.py."""
import json
import os
from pathlib import Path
import subprocess
import time

ROOT = Path(__file__).parent
CONFIG = ROOT.parent / 'launcher-harness.qml'
WORK = Path(os.environ['LUCI_TEST_WORK'])
log = open(ROOT / 'launcher-test.log', 'w')
process = subprocess.Popen(['qs', '-p', str(CONFIG), '--no-color'], stdout=log, stderr=log)


def ipc(method, *args):
    output = subprocess.check_output(['qs', 'ipc', '-p', str(CONFIG), 'call', 'test', method, *map(str, args)], text=True, stderr=subprocess.STDOUT)
    return json.loads(output) if method == 'state' else output


def wait_for(predicate, label, timeout=5):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        if process.poll() is not None:
            raise AssertionError(log.name + '\n' + Path(log.name).read_text())
        try:
            state = ipc('state')
            if predicate(state):
                print('PASS', label, flush=True)
                return state
        except (subprocess.CalledProcessError, json.JSONDecodeError):
            pass
        time.sleep(.05)
    raise AssertionError((label, ipc('state'), Path(log.name).read_text()))


def store(data):
    subprocess.run(['cliphist', 'store'], input=data, check=True)


try:
    wait_for(lambda s: not s['active'], 'shell starts')
    ipc('apps')
    state = wait_for(lambda s: len(s['results']) == 4 and s['focused'], 'apps load and search receives focus')
    assert [e['name'] for e in state['results']] == ['Alpha Editor', 'Alpine Terminal', 'Beta Browser', 'Broken App']
    time.sleep(.4); ipc('grab', str(ROOT / 'apps-dark.png')); time.sleep(.2)
    ipc('key', 'a')
    wait_for(lambda s: s['query'] == 'a', 'typing goes directly into search')
    ipc('query', 'editor alpha')
    wait_for(lambda s: len(s['results']) == 1 and s['results'][0]['name'] == 'Alpha Editor', 'all search tokens match')
    ipc('query', 'browser')
    wait_for(lambda s: len(s['results']) == 2 and s['results'][0]['name'] == 'Beta Browser', 'name matches outrank descriptions')
    ipc('query', 'unfindable')
    wait_for(lambda s: not s['results'] and s['selected'] == -1, 'empty search is safe')
    ipc('key', 'enter')
    assert ipc('state')['active']
    ipc('query', '')
    ipc('key', 'down'); assert ipc('state')['selected'] == 1
    ipc('key', 'next'); assert ipc('state')['selected'] == 2
    ipc('key', 'previous'); ipc('key', 'up'); assert ipc('state')['selected'] == 0
    print('PASS arrow and Ctrl+N/P selection', flush=True)
    ipc('theme', 'true'); ipc('grab', str(ROOT / 'apps-light.png')); time.sleep(.2)
    ipc('key', 'enter')
    wait_for(lambda s: not s['active'], 'successful app launch closes panel')
    deadline = time.monotonic() + 5
    while not (WORK / 'launch.json').exists() and time.monotonic() < deadline: time.sleep(.05)
    launch = json.loads((WORK / 'launch.json').read_text())
    assert launch['cwd'] == str(WORK / 'working directory'), launch
    assert launch['args'] == ['Alpha Editor', 'literal argument'], launch
    print('PASS desktop field codes, quoted arguments and working directory', flush=True)

    ipc('apps'); ipc('query', 'Alpine'); ipc('activate')
    wait_for(lambda s: not s['active'], 'terminal desktop launch succeeds')
    deadline = time.monotonic() + 5
    while not (WORK / 'terminal.json').exists() and time.monotonic() < deadline: time.sleep(.05)
    assert (WORK / 'terminal.json').exists(), 'GTK did not use the terminal adapter'
    print('PASS terminal applications use Ghostty', flush=True)
    ipc('apps'); ipc('query', 'Broken'); ipc('activate')
    wait_for(lambda s: s['active'] and bool(s['error']) and not s['busy'], 'launch failure stays visible')
    ipc('apps'); assert not ipc('state')['active']
    ipc('apps')
    extra = WORK / 'data/applications/delta.desktop'
    extra.write_text('[Desktop Entry]\nType=Application\nName=Delta Utility\nExec=/usr/bin/true\n')
    wait_for(lambda s: any(e['name'] == 'Delta Utility' for e in s['results']), 'new applications appear without restarting')
    extra.unlink()
    wait_for(lambda s: not any(e['name'] == 'Delta Utility' for e in s['results']), 'removed applications disappear')
    subprocess.run(['notify-send', '--app-name', 'Launcher Test', 'A quiet notification'], check=True)
    wait_for(lambda s: s['notifications'] == 1 and not s['notificationPreview'] and s['mode'] == 7, 'notifications do not interrupt launcher')
    ipc('apps')
    ipc('pin'); ipc('apps'); ipc('query', 'alpha'); ipc('clipboard')
    wait_for(lambda s: s['mode'] == 8 and not s['loading'] and not s['query'], 'switching clears query')
    ipc('key', 'escape')
    state = ipc('state'); assert state['mode'] == 1 and state['pinned'], state
    print('PASS launcher switching preserves original pinned return state', flush=True)

    ipc('clipboard')
    wait_for(lambda s: not s['loading'] and len(s['results']) == 2, 'existing text clipboard history loads')
    time.sleep(.4); ipc('grab', str(ROOT / 'clipboard-light.png')); time.sleep(.2)
    ipc('query', 'unfindable'); assert not ipc('state')['results']
    ipc('activate'); assert ipc('state')['active']
    ipc('query', 'unicode')
    state = wait_for(lambda s: len(s['results']) == 1, 'clipboard text search')
    ipc('key', 'enter'); ipc('activate') if ipc('state')['active'] else None
    wait_for(lambda s: not s['active'], 'copy success closes picker')
    assert (WORK / 'copied.bin').read_bytes() == (WORK / 'expected.bin').read_bytes()
    assert (WORK / 'copy-count').read_text() == 'x'
    assert not (WORK / 'injected').exists()
    print('PASS clipboard bytes, Unicode, whitespace and shell-looking text preserved; no duplicate copy', flush=True)

    store(b'A newly copied entry')
    ipc('clipboard'); wait_for(lambda s: not s['loading'] and len(s['results']) == 3, 'history refreshes on reopen')
    ipc('query', 'newly')
    entry = ipc('state')['results'][0]
    subprocess.run(['cliphist', 'delete'], input=(entry['id'] + '\t\n').encode(), check=True)
    original = (WORK / 'copied.bin').read_bytes()
    ipc('activate')
    wait_for(lambda s: not s['loading'] and bool(s['error']) and not s['busy'], 'missing entry reports error and refreshes')
    assert (WORK / 'copied.bin').read_bytes() == original
    assert ipc('state')['active']
    print('PASS failed decode leaves clipboard untouched', flush=True)
    ipc('query', '')
    (WORK / 'copy-fail').touch(); ipc('activate')
    wait_for(lambda s: not s['loading'] and bool(s['error']) and not s['busy'], 'copy failure stays open')
    (WORK / 'copy-fail').unlink()
    ipc('narrow'); time.sleep(.4)
    state = ipc('state'); assert state['width'] <= 320 and state['height'] <= 360, state
    time.sleep(.4); ipc('grab', str(ROOT / 'clipboard-narrow.png')); time.sleep(.2)
    print('PASS panel respects available monitor dimensions', flush=True)
    ipc('query', '')
    ipc('activate'); ipc('apps'); time.sleep(.4)
    state = ipc('state'); assert state['mode'] == 7 and state['active'], state
    print('PASS completing an old copy does not close a newly opened panel', flush=True)
    ipc('apps')
    subprocess.run(['cliphist', 'wipe'], check=True)
    ipc('clipboard')
    wait_for(lambda s: not s['loading'] and not s['results'] and not s['error'], 'empty clipboard history is handled')
    ipc('clipboard')
    database = Path(os.environ['CLIPHIST_DB_PATH'])
    if database.exists(): database.unlink()
    database.mkdir()
    ipc('clipboard')
    wait_for(lambda s: not s['loading'] and bool(s['error']), 'clipboard database errors leave a usable panel')
    ipc('clipboard'); assert not ipc('state')['active']
finally:
    process.terminate()
    process.wait(timeout=5)
    log.close()
