#!/usr/bin/env python3
"""Read actual C4 state/geometry and exercise only visible Android controls.

Requires an already installed and normally toured, source-bound candidate on a
disposable emulator. No installation, root request, save injection, IPC request
write or product-state repair is performed here. Desktop fixtures are accepted
only by explicit pure-function test arguments, never by the Android CLI.
"""
from __future__ import annotations

import argparse
import hashlib
import importlib
import json
import math
import os
from pathlib import Path
import re
import subprocess
import sys
import time
import traceback
import zipfile

PACKAGE = 'dev.ullmann.lumo.lumo_lernen.coachpreview'
FILES = '/data/user/0/' + PACKAGE + '/files'
LAYOUT = FILES + '/connect_four_layout_v1.json'
SESSION = FILES + '/lumo_connect_four_session_v1/'
SELF = '.github/probes/lumo_connect_four_android_probe.py'
PCK_PATH = 'assets/lumo_game.pck'
SOURCE_FILES = (SELF, '.github/probes/creative_android_probe.py',
                '.github/probes/modernization_android_tour.py',
                '.github/probes/lumo_studio_surfaces_android_probe.py',
                '.github/probes/studio_creative_android_probe.py',
                'scripts/probes/pr207_android_smoke.py',
                'scripts/probes/pr207_android_ui_probe.py',
                'tools/android_qa/kart_tour_evidence.py',
                'tools/auto_install/ConnectFourBridge.kt',
                'tools/auto_install/ConnectFourGameActivity.kt',
                'tools/auto_install/ConnectFourAuthorityService.kt',
                'lib/features/games/connect_four/connect_four_round.dart',
                'lib/features/games/connect_four/connect_four_table_session.dart',
                'lib/features/games/connect_four/lumo_connect_four_game.dart')


def allowed_read(path):
    return path == LAYOUT or re.fullmatch(
        re.escape(SESSION) + r'[a-f0-9]{32}/(state|request|lifecycle)\.json', path) is not None


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def sha(path):
    digest = hashlib.sha256()
    with Path(path).open('rb') as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b''):
            digest.update(block)
    return digest.hexdigest()


def verified_pck(apk, expected):
    require(type(expected) is str and re.fullmatch('[a-f0-9]{64}', expected),
            'Full expected PCK digest required')
    with zipfile.ZipFile(apk) as archive:
        require(archive.namelist().count(PCK_PATH) == 1,
                'Embedded PCK absent/ambiguous')
        digest = hashlib.sha256()
        with archive.open(PCK_PATH) as stream:
            for block in iter(lambda: stream.read(1024 * 1024), b''):
                digest.update(block)
    actual = digest.hexdigest()
    require(actual == expected, 'Actual APK PCK differs')
    return actual


def write(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n')


def parse_json(raw):
    def unique(pairs):
        result = {}
        for key, value in pairs:
            require(key not in result, 'Duplicate JSON key: ' + key)
            result[key] = value
        return result
    def invalid(_):
        raise RuntimeError('Nonfinite JSON number')
    return json.loads(raw, object_pairs_hook=unique, parse_constant=invalid)


def number(value, name):
    require(type(value) in (int, float) and math.isfinite(value), 'Invalid number: ' + name)
    return float(value)


def integer(value, name, lo=0, hi=1_000_000_000):
    n = number(value, name)
    require(n.is_integer() and lo <= n <= hi, 'Invalid integer: ' + name)
    return int(n)


def vector(value, length, name):
    require(type(value) is list and len(value) == length, 'Invalid vector: ' + name)
    return [number(v, name) for v in value]


def rectangle(value, name):
    r = vector(value, 4, name)
    require(r[2] > 0 and r[3] > 0, 'Empty rectangle: ' + name)
    return r


def same_numbers(a, b, tolerance=1e-5):
    return len(a) == len(b) and all(abs(x-y) <= tolerance for x, y in zip(a, b))


def inside(rect, outer, tolerance=.15):
    return (rect[0] >= outer[0]-tolerance and rect[1] >= outer[1]-tolerance and
            rect[0]+rect[2] <= outer[0]+outer[2]+tolerance and
            rect[1]+rect[3] <= outer[1]+outer[3]+tolerance)


def replay(columns):
    """Independent gravity/turn/win reconstruction from persisted moves."""
    require(type(columns) is list and len(columns) <= 42, 'Invalid history length')
    board = [0] * 42
    turn, phase, winning = 1, 'playing', []
    for value in columns:
        column = integer(value, 'column', 0, 6)
        require(phase == 'playing', 'Move after terminal result')
        rows = [r for r in range(5, -1, -1) if board[r*7+column] == 0]
        require(bool(rows), 'Move into full column')
        board[rows[0]*7+column] = turn
        for r in range(6):
            for c in range(7):
                for dr, dc in ((0,1),(1,0),(1,1),(1,-1)):
                    cells = [[r+k*dr,c+k*dc] for k in range(4)]
                    if (not winning and all(0 <= y < 6 and 0 <= x < 7 for y,x in cells)
                            and all(board[y*7+x] == turn for y,x in cells)):
                        winning = cells
        if winning:
            phase = 'won'
        elif all(board):
            phase = 'draw'
        else:
            turn = 3-turn
    return {'board':board, 'turn':turn, 'phase':phase, 'winningLine':winning,
            'validColumns':[c for c in range(7) if board[c] == 0]}


def check_state(state, owner=None):
    require(type(state) is dict and state.get('schema') == 1 and state.get('game') == 'connect_four', 'Wrong C4 state')
    for key, length in (('token',32),('roundId',32),('owner',64)):
        require(type(state.get(key)) is str and re.fullmatch('[a-f0-9]{'+str(length)+'}',state[key]), 'Bad '+key)
    if owner is not None:
        require(state['owner'] == owner, 'C4 belongs to another child')
    for key in ('revision','recordRevision'):
        integer(state.get(key), key, 1)
    for key in ('ack','rejected'):
        integer(state.get(key), key)
    for key in ('paused','canDrop','twoPlayers','rewarded'):
        require(type(state.get(key)) is bool, 'Bad boolean '+key)
    require(state.get('level') in ('leicht','mittel','schlau'), 'Unknown opponent level')
    require(type(state.get('board')) is list and len(state['board']) == 42 and
            all(type(piece) is int and piece in (0,1,2) for piece in state['board']),
            'Invalid public board')
    require(type(state.get('turn')) is int and state['turn'] in (1,2), 'Invalid public turn')
    expected = replay(state.get('columns'))
    for key in ('board','turn','phase','winningLine'):
        require(state.get(key) == expected[key], 'State disagrees with legal history: '+key)
    if 'validColumns' in state:
        require(state['validColumns'] == expected['validColumns'], 'Invalid public columns')
    require(not state['rewarded'] or expected['phase'] != 'playing', 'Unfinished reward')
    require(not state['canDrop'] or (not state['paused'] and expected['phase']=='playing' and
            (state['twoPlayers'] or expected['turn']==1)), 'Invalid drop permission')
    return expected


def project(layout, world):
    """Recompute orthographic projection; native reported pixels are not used."""
    camera = layout['camera']; axes = [vector(v,3,'camera axis') for v in camera['basis']]
    origin = vector(camera['origin'],3,'camera origin')
    require(len(axes)==3 and camera['projection']=='orthogonal', 'Unsupported camera')
    dot = lambda a,b: sum(x*y for x,y in zip(a,b))
    require(all(abs(dot(v,v)-1) < 1e-4 for v in axes) and
            all(abs(dot(axes[a],axes[b])) < 1e-4 for a,b in ((0,1),(0,2),(1,2))), 'Non-orthonormal camera')
    size = number(camera['size'],'camera size'); require(.5 <= size <= 100,'Unreasonable camera size')
    vp = vector(layout['viewport_px'],2,'viewport'); win = vector(layout['window_px'],2,'window')
    require(min(vp+win)>0, 'Invalid render size')
    aspect = vp[0]/vp[1]
    keep = integer(camera['keep_aspect'],'camera keep_aspect',0,1)
    width,height = (size,size/aspect) if keep == 0 else (size*aspect,size)
    relative = [world[i]-origin[i] for i in range(3)]
    require(dot(relative,axes[2]) < 0, 'Geometry behind camera')
    return [(0.5+dot(relative,axes[0])/width)*win[0],
            (0.5-dot(relative,axes[1])/height)*win[1]]


def to_decor(layout, point):
    r = layout['android_observation']['render_rect']; w = layout['window_px']
    return [r[0]+point[0]*r[2]/w[0],r[1]+point[1]*r[3]/w[1]]


def check_layout(layout, state, image_size, density, pid, *, allow_fixture=False):
    check_state(state)
    require(type(layout) is dict and layout.get('schema')==1 and layout.get('game')=='connect_four', 'Wrong layout')
    require(layout.get('settled') is True and layout.get('ui_visible') is True and layout.get('pending') == 0, 'Layout still transitioning')
    require(layout.get('observation_source') in (('android_window_insets','platform_fixture') if allow_fixture else ('android_window_insets',)), 'No actual Android inset observation')
    for key in ('token','owner','roundId','revision','recordRevision','ack','rejected','paused','canDrop','turn','phase','columns','board','winningLine','twoPlayers','level','rewarded'):
        require(layout.get(key) == state.get(key), 'Stale/different layout '+key)
    require(integer(layout.get('pid'),'pid',1)==pid, 'Layout process changed')
    integer(layout.get('layout_sequence'),'layout sequence',1); integer(layout.get('ticks_msec'),'ticks',0,2**63-1)
    require(abs(number(layout['density'],'density')-density) < .01 and .5<=density<=6, 'Actual density differs')
    obs = layout['android_observation']
    decor=vector(obs['decor_size'],2,'decor');view=vector(obs['view_size'],2,'view');window=vector(layout['window_px'],2,'window')
    require(same_numbers(decor,list(image_size)) and min(view+window)>0, 'Screenshot/decor size differs')
    render=rectangle(obs['render_rect'],'render rect')
    require(inside(render,[0,0,*decor]) and same_numbers(render[2:],view,.1), 'Render view outside decor')
    bars=vector(obs['system_insets'],4,'system insets');insets=vector(obs['insets'],4,'view insets')
    require(min(bars+insets)>=0, 'Negative inset')
    expected=[max(0,bars[0]-render[0]),max(0,bars[1]-render[1]),
              max(0,render[0]+render[2]-(decor[0]-bars[2])),max(0,render[1]+render[3]-(decor[1]-bars[3]))]
    require(same_numbers(insets,expected,.15), 'Insets do not describe actual render overlap')
    safe=[insets[0]*window[0]/view[0],insets[1]*window[1]/view[1],
          (view[0]-insets[0]-insets[2])*window[0]/view[0],(view[1]-insets[1]-insets[3])*window[1]/view[1]]
    require(same_numbers(rectangle(layout['safe_rect'],'safe rect'),safe,.2), 'Safe layout differs from real insets')
    geo=layout['geometry']
    require(geo.get('rows')==6 and geo.get('columns')==7 and abs(geo.get('spacing',0)-.86)<1e-6 and
            abs(geo.get('disc_radius',0)-.34)<1e-6 and abs(geo.get('disc_depth',0)-.22)<1e-6, 'Unknown board geometry')
    require(type(layout['cells']) is list and len(layout['cells'])==42, 'Missing board cells')
    seen=set(); projected=[]
    for cell in layout['cells']:
        row=integer(cell['row'],'row',0,5); col=integer(cell['column'],'column',0,6)
        require((row,col) not in seen,'Duplicate cell');seen.add((row,col))
        world=[(col-3)*.86,(5-row)*.86+.85,0.0]
        front=[world[0],world[1],.11]
        require(same_numbers(vector(cell['world_center'],3,'world center'),world,.0001) and
                same_numbers(vector(cell['world_front_center'],3,'front center'),front,.0001), 'Cell physical geometry changed')
        require(cell['piece']==state['board'][row*7+col] and abs(cell['disc_radius']-.34)<1e-6,'Wrong cell piece/radius')
        center=project(layout,world)
        require(math.dist(center,vector(cell['center_px'],2,'reported center')) <= 1, 'Native center disagrees with independent projection')
        quad=[project(layout,[world[0]+x,world[1]+y,.11]) for x,y in ((-.34,.34),(.34,.34),(.34,-.34),(-.34,-.34))]
        reported=cell['disc_quad'];require(type(reported) is list and len(reported)==4,'Bad disc quad')
        require(all(math.dist(a,vector(b,2,'reported corner'))<=1 for a,b in zip(quad,reported)), 'Native disc disagrees with independent projection')
        projected.append({'row':row,'column':col,'piece':cell['piece'],'world':world,'front':front,
                          'center':to_decor(layout,project(layout,front)), 'quad':[to_decor(layout,q) for q in quad]})
    require(type(layout['buttons']) is list and len({b['id'] for b in layout['buttons']})==len(layout['buttons']), 'Ambiguous buttons')
    visible=[]
    for b in layout['buttons']:
        if b['visible'] is True and b['enabled'] is True and b['clipped'] is False:
            target=button_target(layout,b['id'],density);visible.append({'id':b['id'],'size_dp':target['size_dp']})
    require(bool(visible), 'No exposed actionable controls')
    return {'cells':projected,'safe_rect':safe,'visible_targets':visible}


def button_target(layout, identifier, density):
    found=[b for b in layout['buttons'] if b['id']==identifier]
    require(len(found)==1,'Required button missing/ambiguous: '+identifier)
    b=found[0]
    require(b.get('visible') is True and b.get('enabled') is True and b.get('clipped') is False,'Button is hidden, disabled or clipped: '+identifier)
    rect=rectangle(b['rect_px'],'button');hit=rectangle(b['hit_rect_px'],'hit rectangle')
    require(inside(hit,rect) and inside(hit,layout['safe_rect']), 'Touch is outside control/safe view')
    first=to_decor(layout,hit[:2]);last=to_decor(layout,[hit[0]+hit[2],hit[1]+hit[3]])
    dp=[(last[i]-first[i])/density for i in (0,1)]
    require(min(dp)>=48-.01,'Actual exposed touch target smaller than48dp')
    return {'id':identifier,'text':b['text'],'hit_rect_px':hit,'decor_bounds':[first[0],first[1],last[0],last[1]],
            'size_dp':dp,'point':[(first[i]+last[i])/2 for i in (0,1)]}


def check_pixels(image, layout, projected):
    """Inspect independently projected central disc areas, never supplied quads."""
    rgb=image.convert('RGB');results=[]
    for cell in projected['cells']:
        if cell['piece']==0:
            continue
        world=cell['front']; samples=[]
        for dx in (-.12,-.06,0,.06,.12):
            for dy in (-.12,-.06,0,.06,.12):
                p=to_decor(layout,project(layout,[world[0]+dx,world[1]+dy,world[2]]));x,y=map(round,p)
                require(0<=x<rgb.width and 0<=y<rgb.height,'Disc outside current screenshot')
                samples.append(rgb.getpixel((x,y)))
        if cell['piece']==1:
            matching=sum(g>r*1.12 and b>r*1.15 and g>65 and b>75 for r,g,b in samples)
        else:
            matching=sum(r>b*1.2 and g>b*1.12 and r>90 and g>65 for r,g,b in samples)
        fraction=matching/len(samples)
        require(fraction>=.65,'Expected actual disc pixels absent at row/column '+str((cell['row'],cell['column'])))
        results.append({'row':cell['row'],'column':cell['column'],'piece':cell['piece'],'color_fraction':fraction,'samples':len(samples)})
    require(len(results)==len(layout['columns']), 'Visible disc count differs from legal history')
    return results


def check_saved(saved, state):
    require(type(saved) is dict and saved.get('schema')==1 and saved.get('owner')==state['owner'] and
            saved.get('id')==state['roundId'] and saved.get('revision')==state['recordRevision'], 'Persisted C4 identity differs')
    for key in ('columns','twoPlayers','level','rewarded'):
        require(saved.get(key)==state[key], 'Persisted C4 field differs: '+key)
    require(replay(saved['columns'])['board']==state['board'],'Saved board differs')


def check_drop(before, request, after, column):
    check_state(before);check_state(after,before['owner'])
    require(before['roundId']==after['roundId'] and before['token']==after['token'],'Drop changed round/session')
    require(not before['twoPlayers'] and before['turn']==1 and before['canDrop'],'No actual solo child turn')
    require(request.get('action')=='drop' and request.get('column')==column and request.get('token')==before['token'] and
            request.get('roundId')==before['roundId'] and request.get('revision')==before['revision'],'Touch did not publish the intended current drop')
    seq=integer(request.get('sequence'),'request sequence',1)
    require(after['ack']>=seq and after['rejected']<seq and after['revision']>before['revision'],'Drop not positively acknowledged')
    old=before['columns'];new=after['columns']
    require(len(new)==len(old)+2 and new[:len(old)]==old and new[len(old)]==column,'Expected one child and one bot move')
    require(after['turn']==1 and after['canDrop'] and not after['paused'],'Bot did not return child control')
    return {'child_column':column,'bot_column':new[-1],'sequence':seq,'columns_before':old,'columns_after':new}


class AndroidProbe:
    def __init__(self,args):
        self.args=args;self.out=args.out;self.count=0;self.events=[];self.out.mkdir(parents=True,exist_ok=True)
        require(not (self.out/'result.json').exists(),'Refusing to overwrite previous probe result')
        os.environ['ANDROID_SERIAL']=args.serial
        for path in (args.candidate_source/'.github/probes',args.candidate_source/'scripts/probes',args.candidate_source/'tools/android_qa'):
            sys.path.insert(0,str(path))
        self.tour=importlib.import_module('modernization_android_tour');self.probe=self.tour.probe
        self.base,self.live=self.tour.base,self.tour.live
        self.surfaces=importlib.import_module('lumo_studio_surfaces_android_probe')
        self.creative=importlib.import_module('studio_creative_android_probe')
        self.old_adb=self.base.adb
        self.base.adb=self.adb

    def tag(self,name):
        self.count+=1;return f'{self.count:04d}-{name}'

    def adb(self,*args,timeout=60,check=True):
        return self.base.command('adb','-s',self.args.serial,*args,timeout=timeout,check=check)

    def raw(self,path,label,limit=131072):
        require(allowed_read(path), 'Unapproved private read')
        started=time.time()
        result=subprocess.run(['adb','-s',self.args.serial,'exec-out','cat',path],capture_output=True,timeout=10)
        tag=self.tag(label);(self.out/(tag+'.raw')).write_bytes(result.stdout)
        (self.out/(tag+'.stderr')).write_bytes(result.stderr)
        write(self.out/(tag+'-read.json'), {'path':path,'serial':self.args.serial,
              'started_unix_seconds':started,'finished_unix_seconds':time.time(),
              'returncode':result.returncode,'bytes':len(result.stdout),
              'sha256':hashlib.sha256(result.stdout).hexdigest()})
        require(result.returncode==0 and 0<len(result.stdout)<=limit,'Missing/bounded read: '+path)
        return parse_json(result.stdout),hashlib.sha256(result.stdout).hexdigest()

    def pid(self):
        raw=self.adb('shell','pidof',PACKAGE+':lumo_game',check=False).strip()
        require(re.fullmatch(r'\d+',raw) is not None,'Actual isolated C4 process absent/ambiguous')
        return int(raw)

    def foreground(self):
        require('ConnectFourGameActivity' in self.base.foreground(),'C4 is not the real foreground activity')

    def state(self,token):
        value,_=self.raw(SESSION+token+'/state.json','state');check_state(value,self.owner)
        require(value['token']==token,'Wrong state token');return value

    def wait(self,name,observe,accept,timeout=45):
        deadline=time.monotonic()+timeout;errors=[]
        while time.monotonic()<deadline:
            try:
                value=observe()
                if accept(value):
                    require(time.monotonic()<deadline, name+' observation completed after its unchanged deadline')
                    return value
            except (RuntimeError,json.JSONDecodeError,KeyError,TypeError) as e:
                errors.append(str(e))
            time.sleep(.4)
        write(self.out/(self.tag(name)+'-failure.json'),{'last_errors':errors[-12:],'budget_seconds':timeout})
        raise RuntimeError(name+' not observed before deadline')

    def saved(self,state):
        prefs=self.probe.prefs(self.out,self.tag('saved'))
        key='flutter.lumo.connect_four.round.v1.'+self.owner
        require(key in prefs,'Existing child C4 save absent')
        saved=parse_json(prefs[key]);check_saved(saved,state);return saved

    def snapshot(self,name,board_pixels=True):
        from PIL import Image
        deadline=time.monotonic()+45
        while time.monotonic()<deadline:
            try:
                self.foreground();pid=self.pid()
                layout,raw_hash=self.raw(LAYOUT,'layout-before')
                state=self.state(layout['token'])
                shot=self.probe.capture(self.out,self.tag(name),timeout=max(.01,deadline-time.monotonic()))
                with Image.open(self.out/shot['file']) as source:image=source.convert('RGB')
                projected=check_layout(layout,state,image.size,self.density,pid)
                pixels=check_pixels(image,layout,projected) if board_pixels else []
                state_after=self.state(layout['token']);later,later_hash=self.raw(LAYOUT,'layout-after')
                require(state==state_after and raw_hash==later_hash,'State/layout changed during actual capture')
                self.foreground();require(pid==self.pid(),'Native process changed during capture')
                require(time.monotonic()<deadline,'Snapshot reads completed after the unchanged capture deadline')
                report={'capture':shot,'layout_sha256':raw_hash,'state':state,'layout':layout,'geometry':projected,'disc_pixels':pixels}
                write(self.out/(self.tag(name)+'-observation.json'),report)
                return report
            except (RuntimeError,json.JSONDecodeError,KeyError,TypeError) as e:
                write(self.out/(self.tag(name)+'-rejected.json'),{'error':str(e)})
                time.sleep(.3)
        raise RuntimeError('No stable actual geometry/pixels for '+name)

    def touch(self,observation,identifier):
        target=button_target(observation['layout'],identifier,self.density)
        latest,h=self.raw(LAYOUT,'touch-layout');self.foreground()
        require(h==observation['layout_sha256'],'Target changed before real touch')
        point=[round(v) for v in target['point']]
        event={'kind':'actual_adb_touch','target':target,'capture':observation['capture'],'layout_sha256':h,'point':point,'time_monotonic':time.monotonic()}
        self.events.append(event);write(self.out/'input-events.json',self.events)
        self.adb('shell','input','tap',*[str(x) for x in point])

    def navigate(self):
        nodes=self.live.live_nodes(self.out,self.tag('starting-flutter'))
        labels=self.tour.labels(nodes)
        if any('Spiel pausiert' in x for x in labels):
            self.surfaces.tap_flutter(self.out,['Zur Spieleauswahl'],'c4-leave-other-pause')
        self.surfaces.tap_flutter(self.out,['Spielen','Spiele'],'c4-games-tab')
        for direction in (1,-1):
            for attempt in range(11):
                tag=self.tag('actual-c4-hub');nodes=self.live.live_nodes(self.out,tag)
                shot=self.probe.capture(self.out,tag)
                from PIL import Image
                with Image.open(self.out/shot['file']) as im:size=im.size
                target=self.creative.hub_choice(nodes,'Vier gewinnt',size,48*self.density)
                if target:
                    r=target['bounds'];point=[round((r[0]+r[2])/2),round((r[1]+r[3])/2)]
                    self.events.append({'kind':'actual_hub_touch','target':target,'capture':shot,'point':point});write(self.out/'input-events.json',self.events)
                    self.adb('shell','input','tap',*[str(v) for v in point]);return
                if attempt==10:break
                rects=[self.creative.bounds(n.get('bounds','')) for n in nodes if n.get('package')==PACKAGE and n.get('scrollable')=='true']
                rects=[r for r in rects if r and 0<=r[0]<r[2]<=size[0] and 0<=r[1]<r[3]<=size[1]]
                require(rects,'No actual scroll viewport for C4 hub')
                r=max(rects,key=lambda q:(q[2]-q[0])*(q[3]-q[1]));x=round((r[0]+r[2])/2);low=round(r[1]+.25*(r[3]-r[1]));high=round(r[1]+.75*(r[3]-r[1]))
                start,end=(high,low) if direction==1 else (low,high)
                self.adb('shell','input','swipe',str(x),str(start),str(x),str(end),'450');time.sleep(.6)
        raise RuntimeError('Actual C4 hub tile never appeared')

    def lease(self,token,active):
        before=int(self.adb('shell','date','+%s%3N').strip());value,_=self.raw(SESSION+token+'/lifecycle.json','lifecycle');after=int(self.adb('shell','date','+%s%3N').strip())
        stamp=integer(value.get('stamp'),'lease stamp',1,2**63-1);integer(value.get('pauseEpoch'),'pause epoch')
        require(value.get('active') is active,'Wrong actual Activity lease state')
        require(stamp<=after+500 and (not active or before-stamp<2500),'Stale actual Activity lease')
        return {'device_before_ms':before,'device_after_ms':after,'lifecycle':value}

    def binding(self):
        a=self.args
        for root,expected in ((a.candidate_source,a.expected_source),(a.native_source,a.expected_native)):
            require(re.fullmatch('[a-f0-9]{40}',expected),'Full immutable source SHA required')
            require(subprocess.check_output(['git','-C',str(root),'rev-parse','HEAD'],text=True).strip()==expected,'Checkout source differs')
            require(not subprocess.check_output(['git','-C',str(root),'status','--porcelain','--untracked-files=no'],text=True).strip(),'Tracked candidate source is dirty')
        require(Path.cwd().resolve()==a.candidate_source and Path(__file__).resolve()==a.candidate_source/SELF,'Execute actual candidate probe from clean candidate CWD')
        hashes={}
        for relative in SOURCE_FILES:
            f=a.candidate_source/relative;expected=subprocess.check_output(['git','-C',str(a.candidate_source),'show','HEAD:'+relative])
            require(f.read_bytes()==expected,'Working helper differs: '+relative);hashes[relative]=sha(f)
        for relative in ('scripts/games/connect_four/connect_four_table.gd','scenes/games/connect_four_table.tscn'):
            f=a.native_source/relative;require(f.read_bytes()==subprocess.check_output(['git','-C',str(a.native_source),'show','HEAD:'+relative]),'Native C4 source changed');hashes['native/'+relative]=sha(f)
        identity=self.tour.verify_apk_identity(a.apk,a.provenance,a.sums)
        require(identity['flutter_source_commit']==a.expected_source and identity['godot_revision']==a.expected_native,'APK/source mismatch')
        verified_pck(a.apk,identity['godot_pck_sha256'])
        installed=self.adb('shell','pm','path',PACKAGE).strip().splitlines()
        require(len(installed)==1 and installed[0].startswith('package:/data/app/') and installed[0].endswith('/base.apk'),'Installed APK path ambiguous')
        apkpath=installed[0][8:];value=self.adb('shell','sha256sum',apkpath).split()[0]
        require(value==identity['apk_sha256'],'Installed binary is not the verified candidate')
        return {'host':a.expected_source,'native':a.expected_native,'apk':identity,'actual_installed_apk_sha256':value,'source_hashes':hashes}

    def run(self):
        a=self.args;require(re.fullmatch(r'emulator-\d+',a.serial),'Disposable emulator serial required')
        require(self.adb('get-serialno').strip()==a.serial,'Wrong actual device')
        require(self.adb('shell','getprop','ro.kernel.qemu').strip()=='1' and self.adb('shell','id','-u').strip()=='0','Pre-existing rooted disposable emulator required; probe will not root a device')
        runtime={'sdk':int(self.adb('shell','getprop','ro.build.version.sdk').strip()),'release':self.adb('shell','getprop','ro.build.version.release').strip(),'fingerprint':self.adb('shell','getprop','ro.build.fingerprint').strip(),'model':self.adb('shell','getprop','ro.product.model').strip()}
        require(runtime['sdk']==a.expected_api and runtime['release']=={35:'15',37:'17'}[a.expected_api] and runtime['fingerprint'],'Actual requested Android runtime differs')
        prior=parse_json(a.tour_result.read_text());before=self.binding()
        require(prior.get('status')=='PASS' and prior.get('apk_sha256')==before['apk']['apk_sha256'] and int(prior.get('android_sdk',0))==a.expected_api and len(prior.get('steps',[]))==21 and all(x.get('ok') is True for x in prior['steps']),'Normal real tour has not passed on this exact APK/runtime')
        density=self.adb('shell','wm','density');(self.out/'actual-density.txt').write_text(density)
        values=re.findall(r'(?:Override|Physical) density:\s*(\d+)',density);require(values,'No measured Android density');self.density=int(values[-1])/160
        self.before_prefs=self.probe.prefs(self.out,'before-c4');student=self.before_prefs.get('flutter.lumo_learning_local_student_id_v1')
        require(type(student) is str and re.fullmatch('local-[a-f0-9]{32}',student),'This probe requires the existing local test child')
        self.owner=hashlib.sha256(student.encode()).hexdigest()
        write(self.out/'binding-before.json',before);self.navigate()
        self.wait('C4 native activity',lambda:'ConnectFourGameActivity' in self.surfaces.resumed_activity(),bool,60)
        initial=self.snapshot('initial-board');state=initial['state'];token=state['token'];first_pid=self.pid()
        require(not state['columns'] and not state['twoPlayers'] and state['canDrop'],'Fixture must start in its actual fresh solo round; saves will not be cleared')
        self.saved(state);leases=[self.lease(token,True)];moves=[];current=initial
        for column in (3,2):
            before_state=current['state'];self.touch(current,'column_'+str(column))
            request=self.wait('actual drop request',lambda:self.raw(SESSION+token+'/request.json','drop-request')[0],lambda x:x.get('action')=='drop' and x.get('sequence',0)>before_state['ack'])
            self.wait('durable child and bot turns',lambda:self.state(token),lambda x:len(x['columns'])==len(before_state['columns'])+2 and x['canDrop'] and not x['paused'])
            current=self.snapshot('child-and-bot');moves.append(check_drop(before_state,request,current['state'],column));self.saved(current['state'])
        saved=self.saved(current['state']);self.touch(current,'pause')
        self.wait('native pause',lambda:self.state(token),lambda x:x['paused'] and not x['canDrop'])
        paused=self.snapshot('native-pause',board_pixels=False);time.sleep(2)
        require(self.saved(self.state(token))==saved,'Paused round changed');self.touch(paused,'resume')
        self.wait('native resume',lambda:self.state(token),lambda x:not x['paused'] and x['canDrop'])
        current=self.snapshot('resumed-board');require(self.saved(current['state'])==saved,'Resume changed saved round')
        leases.append(self.lease(token,True));self.adb('shell','input','keyevent','3')
        inactive=self.wait('real Home onPause lease',lambda:self.lease(token,False),lambda x:True)
        time.sleep(3);require(self.saved(self.state(token))==saved,'Background activity changed saved round')
        self.base.launch(self.out,'return-from-home')
        self.wait('same C4 foreground after launcher',lambda:'ConnectFourGameActivity' in self.surfaces.resumed_activity(),bool,45)
        require(self.pid()==first_pid,'Lifecycle unexpectedly recreated native process')
        leases.append(self.lease(token,True));require(leases[-1]['lifecycle']['pauseEpoch']>=inactive['lifecycle']['pauseEpoch']>leases[0]['lifecycle']['pauseEpoch'],'Actual pause epoch not preserved')
        after_home=self.snapshot('after-home',board_pixels=not self.state(token)['paused'])
        require(self.saved(after_home['state'])==saved,'Home return changed saved round')
        if after_home['state']['paused']:
            self.touch(after_home,'resume');self.wait('explicit Home resume',lambda:self.state(token),lambda x:not x['paused'] and x['canDrop'])
        current=self.snapshot('before-exit');self.touch(current,'back')
        self.surfaces.returned_to_flutter(self.out,'Spiel pausiert','c4-return-flutter')
        require(self.saved(current['state'])==saved,'Native exit changed persisted C4')
        closed=subprocess.run(['adb','-s',a.serial,'shell','test','-e',SESSION+token],capture_output=True,timeout=10)
        write(self.out/'closed-session-read.json',{'path':SESSION+token,'returncode':closed.returncode,
              'stdout':closed.stdout.decode(errors='replace'),'stderr':closed.stderr.decode(errors='replace')})
        require(closed.returncode==1 and not closed.stderr,'Closed C4 IPC still exists or device check failed')
        self.surfaces.tap_flutter(self.out,['Fortsetzen'],'c4-flutter-resume')
        self.surfaces.tap_flutter(self.out,['In 3D weiterspielen'],'c4-reopen-native')
        self.wait('reopened native C4',lambda:'ConnectFourGameActivity' in self.surfaces.resumed_activity(),bool,60)
        reopened=self.snapshot('reopened-board')
        require(reopened['state']['roundId']==state['roundId'] and reopened['state']['token']!=token and self.saved(reopened['state'])==saved,'Reopen lost round or reused session')
        self.touch(reopened,'back');self.surfaces.returned_to_flutter(self.out,'Spiel pausiert','c4-final-flutter')
        require(self.saved(reopened['state'])==saved,'Final return changed C4 save')
        preservation=self.tour.evidence.learning_preserved(self.before_prefs,self.probe.prefs(self.out,'after-c4'))
        after=self.binding();require(before==after,'Source or binary changed during C4 probe')
        fatal=self.tour.logcat_fatal();require(not fatal,'Actual app crash recorded: '+str(fatal))
        write(self.out/'binding-after.json',after)
        return {'status':'PASS','source_binding':before,'android_runtime':runtime,'actual_moves':moves,'leases':leases,'home_inactive_lease':inactive,'same_round_id':state['roundId'],'new_mailbox_token':True,'saved_round_unchanged_after_pause_home_exit_reopen':True,'learning_preservation':preservation,'fatal_crashes':len(fatal),'physical_fold7_performance_measured':False,'scope':'Real hub, two child moves and two bot replies, independently projected actual disc pixels,48dp exposed controls, pause/resume,Home lifecycle,save and reopened round; no injected moves','not_tested':['Physical Fold7/FPS/thermal/touch latency','Two-child switching','Full tournament/reward or all opponent strategies','C4 availability in any earlier APK']}


def main(argv=None):
    parser=argparse.ArgumentParser(description=__doc__)
    for name in ('candidate-source','native-source','apk','provenance','sums','tour-result','out'):
        parser.add_argument('--'+name,type=Path,required=True)
    for name in ('expected-source','expected-native','serial'):
        parser.add_argument('--'+name,required=True)
    parser.add_argument('--expected-api',type=int,choices=(35,37),required=True)
    args=parser.parse_args(argv)
    for name in ('candidate_source','native_source','apk','provenance','sums','tour_result','out'):
        setattr(args,name,getattr(args,name).resolve())
    if (args.out/'result.json').exists():
        print('Refusing to overwrite previous probe result',file=sys.stderr)
        return 2
    probe=None
    try:
        probe=AndroidProbe(args);result=probe.run();write(args.out/'result.json',result);return 0
    except Exception as error:
        args.out.mkdir(parents=True,exist_ok=True)
        write(args.out/'result.json',{'status':'FAIL','error':f'{type(error).__name__}: {error}','expected_host':args.expected_source,'expected_native':args.expected_native,'physical_fold7_performance_measured':False})
        (args.out/'failure-traceback.txt').write_text(traceback.format_exc())
        if probe:
            try:probe.probe.capture(args.out,'failure-actual-screen')
            except Exception as capture_error:(args.out/'failure-capture-error.txt').write_text(str(capture_error))
        return 1
    finally:
        if probe:probe.base.adb=probe.old_adb


if __name__=='__main__':
    raise SystemExit(main())
