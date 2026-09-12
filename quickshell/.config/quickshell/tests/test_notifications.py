import json, os, pathlib, subprocess, time
import dbus
from dbus.mainloop.glib import DBusGMainLoop
from gi.repository import GLib

ROOT = pathlib.Path(__file__).parent
CONFIG = ROOT.parent / 'notification-harness.qml'
DBusGMainLoop(set_as_default=True)
bus = dbus.SessionBus()
log = open(ROOT / 'test.log', 'w')
proc = subprocess.Popen(['qs', '-p', str(CONFIG), '--no-color'], stdout=log, stderr=log)

def ipc(method, *args):
    out = subprocess.check_output(['qs', 'ipc', '-p', str(CONFIG), 'call', 'test', method, *map(str,args)], stderr=subprocess.STDOUT, text=True)
    return json.loads(out) if method == 'state' else out

def pump(seconds=.15):
    end=time.monotonic()+seconds
    while time.monotonic()<end:
        while GLib.MainContext.default().pending(): GLib.MainContext.default().iteration(False)
        time.sleep(.01)

def state():
    pump(.08)
    return ipc('state')

try:
    for _ in range(60):
        if proc.poll() is not None: raise RuntimeError((ROOT/'test.log').read_text())
        if bus.name_has_owner('org.freedesktop.Notifications'): break
        time.sleep(.05)
    if not bus.name_has_owner('org.freedesktop.Notifications'):
        raise RuntimeError((ROOT/'test.log').read_text())
    server = dbus.Interface(bus.get_object('org.freedesktop.Notifications','/org/freedesktop/Notifications'), 'org.freedesktop.Notifications')
    events=[]
    bus.add_signal_receiver(lambda nid,reason: events.append(('closed',int(nid),int(reason))), signal_name='NotificationClosed', dbus_interface='org.freedesktop.Notifications')
    bus.add_signal_receiver(lambda nid,action: events.append(('action',int(nid),str(action))), signal_name='ActionInvoked', dbus_interface='org.freedesktop.Notifications')
    def send(title='Message', body='Hello from the test', timeout=-1, replace=0, actions=(), **hints):
        return int(server.Notify('Luci Test', dbus.UInt32(replace), 'dialog-information', title, body, dbus.Array(actions,signature='s'), dbus.Dictionary(hints,signature='sv'), dbus.Int32(timeout)))
    def check(label, test):
        assert test, (label, state(), events)
        print('PASS',label,flush=True)
    caps=list(server.GetCapabilities())
    check('capabilities', 'actions' in caps and 'body-markup' not in caps and 'inline-reply' not in caps)
    n=send(timeout=0)
    s=state(); check('arrival before opening any UI',s['visible'] and s['count']==1 and s['unread']==1)
    send('Updated',replace=n,timeout=0)
    s=state(); check('replacement updates in place',s['count']==1 and s['unread']==1 and s['entries'][0]['summary']=='Updated')
    ipc('hover','true'); n2=send('Second',timeout=0); n3=send('Latest',timeout=0)
    s=state(); check('hover keeps current; latest pending',s['current']==n and s['pending']==n3 and s['count']==3)
    ipc('hover','false'); check('latest shown on pointer leave',state()['current']==n3)
    ipc('dismiss'); check('dismiss keeps read snapshot',state()['count']==3 and not state()['visible'] and ('closed',n3,2) in events)
    ipc('mode',1); send('Busy',timeout=0); check('busy view preserved',not state()['visible'] and state()['mode']==1)
    ipc('mode',0); check('no busy backlog',not state()['visible'])
    ipc('focus','true'); send('Focus',timeout=0); check('focus suppresses',not state()['visible'])
    ipc('focus','false'); check('no focus backlog',not state()['visible'])
    ipc('clear'); n=send('Expires',timeout=350); pump(.6)
    check('milliseconds and close reason',('closed',n,1) in events and state()['count']==1 and not state()['entries'][0]['live'])
    ipc('clear'); n=send('Read me',timeout=400); ipc('hover','true'); pump(.65)
    check('hover pauses lifetime',state()['entries'][0]['live'])
    ipc('hover','false'); pump(.6); check('lifetime resumes',('closed',n,1) in events)
    ipc('clear'); n=send('Overlay',timeout=400); ipc('overlay','true'); pump(.6)
    check('overlay preserves notification',state()['entries'][0]['live'] and not state()['visible'])
    ipc('overlay','false'); check('preview resumes after overlay',state()['visible']); pump(.55)
    ipc('clear'); n=send('Action',timeout=0,actions=['open','Open']); ipc('invoke',n,'open'); pump()
    check('action invokes and dismisses',('action',n,'open') in events and ('closed',n,2) in events and state()['entries'][0]['actions']==0)
    ipc('clear'); n=send('Resident',timeout=0,actions=['open','Open'],resident=True); ipc('invoke',n,'open')
    check('resident survives action',state()['entries'][0]['live'])
    server.CloseNotification(n); pump(); check('app closure removes live actions',('closed',n,3) in events and state()['entries'][0]['actions']==0)
    ipc('clear'); send('Transient',timeout=300,transient=True); check('transient skips history',state()['count']==0 and state()['visible']); pump(.5)
    check('transient is cleaned up',state()['live']==0 and not state()['visible'])
    ipc('clear'); n=send('No expiry',timeout=0); pump(5.3)
    check('zero timeout hides preview but retains live notification',not state()['visible'] and state()['entries'][0]['live'])
    ipc('clear'); send('Critical',timeout=0,urgency=dbus.Byte(2)); check('critical preview duration',state()['remaining']>9000)
    ipc('clear')
    for i in range(105): send(f'History {i}',timeout=0)
    s=state(); check('bounded history and live objects',s['count']==100 and s['live']==100 and s['unread']==100)
    ipc('read'); check('mark read',state()['unread']==0)
    ipc('open'); check('history navigation does not pin control center',state()['mode']==3 and not state()['pinned'])
    ipc('clear'); check('clear closes all live objects',state()['count']==0 and state()['live']==0)
    ipc('mode',0); n=send('Survives reload',timeout=0)
    CONFIG.write_text(CONFIG.read_text()+'\n')
    pump(1)
    s=state(); check('reload restores live history without replay',s['count']==1 and s['live']==1 and not s['visible'])
    send('After reload',replace=n,timeout=0)
    s=state(); check('replacement after reload can preview',s['count']==1 and s['visible'] and s['entries'][0]['summary']=='After reload')
    ipc('clear')
finally:
    proc.terminate()
    proc.wait(timeout=5)
    log.close()
