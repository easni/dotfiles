#!/usr/bin/env python3
"""Opt-in real Wayland test: create/remove virtual outputs, restoring monitor focus.

Requires a running Hyprland session. Never disconnects physical outputs, but
briefly moves keyboard focus to virtual monitors. Do not type during the test.
"""
import argparse
import json, os, shutil, subprocess, tempfile, time
from pathlib import Path
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--live-virtual-outputs', action='store_true', required=True,
                    help='Allow temporary virtual outputs and keyboard-focus changes')
parser.parse_args()
work = tempfile.TemporaryDirectory(prefix='luci-wayland-monitors-')
source = Path(__file__).resolve().parents[1]
config_dir = Path(work.name) / 'config'
shutil.copytree(source, config_dir)
config = config_dir / 'wayland-monitors-harness.qml'
config.write_text((config_dir/'tests/wayland-monitors-harness.qml').read_text().replace('import "../', 'import "'))
log_path = Path('/tmp/luci-wayland-monitors.log')
prefix = 'luci-test-' + str(os.getpid()) + '-'
env = dict(os.environ, LUCI_MONITOR_TEST_PREFIX=prefix)
def run(*args): return subprocess.check_output(args,text=True).strip()
def ctl(*args): return run('hyprctl',*args)
def ipc(target,method): return run('qs','ipc','-p',str(config),'call',target,method)
def state(): return json.loads(ipc('monitorTest','state'))
def wait_for(predicate,label):
    deadline=time.monotonic()+8
    last=None
    while time.monotonic()<deadline:
        try:
            last=state()
            if predicate(last): print('PASS',label,flush=True); return last
        except (subprocess.CalledProcessError, json.JSONDecodeError): pass
        time.sleep(.1)
    raise AssertionError((label,last))
monitors=json.loads(ctl('-j','monitors'))
original=next(m['name'] for m in monitors if m['focused'])
names=[prefix+'a',prefix+'b']
assert all(m['name'] not in names for m in monitors)
created=[]
process=None
with log_path.open('w') as log:
 try:
    for name in names:
        ctl('output','create','headless',name); created.append(name)
    process=subprocess.Popen(['dbus-run-session','--','qs','-p',str(config),'--no-color'],stdout=log,stderr=log,env=env)
    wait_for(lambda s:len(s['windows'])==2 and all(w['visible'] for w in s['windows']), 'real layer windows on two virtual outputs')
    for name in names:
        ctl('dispatch','hl.dsp.focus({monitor = '+json.dumps(name)+'})')
        wait_for(lambda s:s['target']==name,'shortcuts target '+name)
        ipc('luci','openAppLauncher')
        wait_for(lambda s:any(w['name']==name and w['focused'] for w in s['windows']) and sum(x['modal'] for x in s['sessions'])==1,'launcher receives keyboard focus on '+name)
    ctl('output','remove',names[1]); created.remove(names[1])
    wait_for(lambda s:len(s['windows'])==1 and len(s['sessions'])==1,'disconnect removes window and session')
    ctl('output','remove',names[0]); created.remove(names[0])
    wait_for(lambda s:len(s['windows'])==0 and len(s['sessions'])==0,'all managed outputs removed')
    ctl('output','create','headless',names[0]); created.append(names[0])
    wait_for(lambda s:len(s['windows'])==1 and s['windows'][0]['visible'],'window returns after reconnect')
    ctl('dispatch','hl.dsp.focus({monitor = '+json.dumps(names[0])+'})')
    wait_for(lambda s:s['target']==names[0],'focus routing returns after reconnect')
    for method in ['openAppLauncher','openClipboard','openThemeSelector','openWallpaperSelector','openPowerMenu']:
        ipc('luci',method)
        wait_for(lambda s:s['sessions'][0]['modal'] and s['windows'][0]['focused'], method+' remains focused')
        ipc('luci',method)
        wait_for(lambda s:not s['sessions'][0]['modal'],method+' toggles closed')
 finally:
    if process:
        process.terminate()
        try: process.wait(timeout=5)
        except subprocess.TimeoutExpired: process.kill(); process.wait()
    for name in created: subprocess.run(['hyprctl','output','remove',name],capture_output=True)
    subprocess.run(['hyprctl','dispatch','hl.dsp.focus({monitor = '+json.dumps(original)+'})'],capture_output=True)

work.cleanup()
print("Wayland log:", log_path)
