import json, os, pathlib, subprocess, time
import dbus
ROOT=pathlib.Path(__file__).parent
CONFIG=ROOT.parent/'ui-harness.qml'
bus=dbus.SessionBus()
log=open(ROOT/'ui-test.log','w')
p=subprocess.Popen(['qs','-p',str(CONFIG),'--no-color'],stdout=log,stderr=log)
def ipc(method,*args):
    result=subprocess.check_output(['qs','ipc','-p',str(CONFIG),'call','test',method,*map(str,args)],text=True,stderr=subprocess.STDOUT)
    return json.loads(result) if method in ('state', 'notificationState') else result
try:
    for _ in range(60):
        if p.poll() is not None: raise RuntimeError((ROOT/'ui-test.log').read_text())
        if bus.name_has_owner('org.freedesktop.Notifications'): break
        time.sleep(.05)
    if not bus.name_has_owner('org.freedesktop.Notifications'):
        raise RuntimeError((ROOT/'ui-test.log').read_text())
    server=dbus.Interface(bus.get_object('org.freedesktop.Notifications','/org/freedesktop/Notifications'),'org.freedesktop.Notifications')
    def send(title,body,actions=(),icon='dialog-information',**hints):
        return server.Notify('Messages',0,icon,title,body,dbus.Array(actions,signature='s'),dbus.Dictionary(hints,signature='sv'),0)
    ipc('move',5,500)
    baseline=ipc('state')
    base_padding=(baseline['width']-baseline['content']['width'])/2
    send('A small update, right here','Your notifications now live in the island. Hover to read, or click to see your history.', ['open','Open','reply','Reply'])
    time.sleep(.6)
    print('UI',ipc('state'),flush=True)
    ipc('grab',str(ROOT/'preview-dark.png')); time.sleep(.3)
    ipc('theme','true'); time.sleep(.2)
    ipc('grab',str(ROOT/'preview-light.png')); time.sleep(.3)
    ipc('move',360,80); time.sleep(.3)
    assert ipc('state')['hovered'],ipc('state')
    time.sleep(5.1)
    assert ipc('state')['visible'],ipc('state')
    print('PASS actual hover pauses preview',flush=True)
    ipc('click',360,100); time.sleep(.6)
    s=ipc('state'); assert s['mode']==3 and not s['pinned'] and s['unread']==1,s
    print('PASS card click opens unpinned history and preserves unread state',flush=True)
    ipc('grab',str(ROOT/'history-light.png')); time.sleep(.3)
    assert ipc('notificationState') == {'border': 1, 'cursor': 'hand'}
    ipc('clickNotification'); time.sleep(.2)
    s=ipc('state'); assert s['unread']==0 and s['mode']==3 and not s['pinned'] and s['history']==1,s
    assert ipc('notificationState') == {'border': 0, 'cursor': 'arrow'}
    ipc('clickNotification'); time.sleep(.2)
    s=ipc('state'); assert s['unread']==0 and s['mode']==3 and not s['pinned'] and s['history']==1,s
    print('PASS unread clicks mark read, clear border and change cursor; read clicks do nothing',flush=True)
    ipc('move',5,600); time.sleep(.6)
    s=ipc('state'); assert s['mode']==0 and not s['pinned'] and s['unread']==0,s
    print('PASS notification panel closes on pointer leave',flush=True)

    ipc('quiet','true'); send('Unread message','A badge with room to breathe.'); ipc('quiet','false')
    time.sleep(.4)
    s=ipc('state')
    padding=(s['width']-s['content']['width'])/2
    assert s['width']>baseline['width'] and abs(padding-base_padding)<.6,(baseline,s)
    ipc('grab',str(ROOT/'compact-badge.png')); time.sleep(.2)
    print('PASS unread badge preserves compact side padding',flush=True)

    ipc('move',360,36); time.sleep(.5)
    ipc('click',110,55); time.sleep(.2)
    s=ipc('state'); assert s['mode']==1 and s['pinned'],s
    assert abs(s['height']-75)<1 and s['badge']['x']>=s['clock']['x']+s['clock']['width'],s
    assert abs(s['badge']['y']+s['badge']['height']/2-s['clock']['y']-s['clock']['height']/2)<1,s
    ipc('grab',str(ROOT/'expanded-badge.png')); time.sleep(.2)
    print('PASS pinned expanded badge sits beside time without extra height',flush=True)
    ipc('clickBadge'); time.sleep(.5)
    s=ipc('state'); assert s['mode']==3 and not s['pinned'],s
    ipc('move',5,600); time.sleep(.6)
    s=ipc('state'); assert s['mode']==1 and s['pinned'],s
    print('PASS badge opens unpinned history and restores explicitly pinned island',flush=True)

    ipc('reset'); ipc('quiet','true'); send('One more','Click the empty header to pin.'); ipc('quiet','false')
    time.sleep(.4); ipc('clickBadge'); time.sleep(.5)
    s=ipc('state'); assert s['mode']==3 and not s['pinned'],s
    ipc('move',360,50); ipc('click',360,50); time.sleep(.2)
    ipc('move',5,600); time.sleep(.5)
    s=ipc('state'); assert s['mode']==3 and s['pinned'],s
    ipc('move',360,50); ipc('click',360,50); ipc('move',5,600); time.sleep(.5)
    s=ipc('state'); assert s['mode']==0 and not s['pinned'],s
    print('PASS empty-area clicks toggle control-center pinning',flush=True)
    ipc('theme','false')
    send('A long notification title that should wrap gracefully instead of overflowing the island','A message with <b>literal markup</b> and a verylongunbrokenword'*8, icon='missing-luci-test-icon')
    time.sleep(.6); ipc('narrow'); time.sleep(.6)
    s=ipc('state'); assert s['width']<=300,s
    ipc('grab',str(ROOT/'preview-narrow.png')); time.sleep(.3)
    print('PASS narrow-screen preview width',flush=True)
finally:
    p.terminate(); p.wait(timeout=5); log.close()
