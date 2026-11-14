"""Synthetic contract cases, never represented as an actual Android result."""
from __future__ import annotations

import copy
import hashlib
import json
from pathlib import Path
import sys
import tempfile
import unittest
import xml.etree.ElementTree as ET

from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import connect_four_android_evidence as c4


HOST = 'a' * 40
NATIVE = 'b' * 40
RUN = 43_500_000_001
ARTIFACT = 14_000_000_001
DIGEST = 'sha256:' + 'd' * 64
STUDENT = 'local-' + 'c' * 32
OWNER = hashlib.sha256(STUDENT.encode()).hexdigest()
PIXELS = (1080, 2400)


def state(columns=(), *, revision=1, ack=0, paused=False, token='a' * 32):
    board = [0] * 42
    heights = [0] * 7
    for turn, column in enumerate(columns):
        board[(5-heights[column])*7+column] = turn % 2 + 1
        heights[column] += 1
    return {'schema':1, 'game':'connect_four', 'token':token, 'roundId':'c' * 32,
            'owner':OWNER, 'revision':revision, 'recordRevision':len(columns)+1,
            'ack':ack, 'rejected':0, 'paused':paused, 'exit':False,
            'canDrop':not paused, 'reduceMotion':False, 'twoPlayers':False,
            'level':'leicht', 'phase':'playing', 'turn':1, 'columns':list(columns),
            'validColumns':[c for c in range(7) if heights[c]<6], 'board':board,
            'winningLine':[], 'rewarded':False, 'error':None}


def stored(value):
    return {'schema':1, 'owner':value['owner'], 'id':value['roundId'], 'seed':4,
            'revision':value['recordRevision'], 'twoPlayers':value['twoPlayers'],
            'level':value['level'], 'columns':value['columns'], 'rewarded':value['rewarded']}


def prefs(value):
    return {'flutter.lumo_learning_local_student_id_v1':STUDENT,
            'flutter.lumo_active_profile':json.dumps({'id':'test-child', 'name':'Synthetic Child',
                'age':8, 'grade':2, 'createdAt':'fixture'}),
            'flutter.lumo_progress_v1':'{"syntheticPreserved":1}',
            c4.ROUND_PREFIX+OWNER:json.dumps(stored(value))}


def xml_preferences(value):
    root = ET.Element('map')
    for key, item in prefs(value).items():
        ET.SubElement(root, 'string', {'name':key}).text = item
    return ET.tostring(root, encoding='unicode')


def layout(value, *, pid=200, sequence=1):
    buttons = []
    for control in ('back','pause','resume','restart','mode',
                    *('column_'+str(c) for c in range(7)),
                    'level_leicht','level_mittel','level_schlau'):
        rect = [10,10,130,130]
        text = {'back':'Zurück','pause':'Pause','resume':'Fortsetzen'}.get(control, control)
        if control.startswith('column_'):
            column = int(control[7:])
            rect = [40+column*140,2100,130,130]
            text = str(column+1)+' ↓'
        elif control == 'pause':
            rect = [900,10,130,130]
        elif control == 'resume':
            rect = [80,400,900,150]
        visible = value['paused'] if control == 'resume' else not value['paused'] if control == 'pause' else True
        buttons.append({'id':control,'text':text,'rect_px':rect,'hit_rect_px':rect[:],
                        'visible':visible,'enabled':True,'clipped':False})
    cells = []
    for row in range(6):
        for column in range(7):
            x, y = 200+100*column, 400+100*row
            cells.append({'row':row,'column':column,'piece':value['board'][row*7+column],
                          'disc_quad':[[x-40,y-40],[x+40,y-40],[x+40,y+40],[x-40,y+40]]})
    return {'schema':1,'game':'connect_four','settled':True,'ui_visible':True,
            'pending':0,'pid':pid,'layout_sequence':sequence,'ticks_msec':sequence*100,
            'observation_source':'android_window_insets','density':2.5,
            'window_px':[1080,2300],'viewport_px':[432,920], 'safe_rect':[0,0,1080,2300],
            'android_observation':{'decor_size':list(PIXELS),'view_size':[1080,2300],
                                   'render_rect':[0,70,1080,2300]},
            'buttons':buttons,'cells':cells, **{key:value[key] for key in c4.STATE_KEYS}}


def original_metadata():
    run = {'id':RUN,'run_attempt':1,'head_sha':HOST,'head_branch':c4.BRANCH,
           'event':'pull_request','path':c4.WORKFLOW,
           'repository':{'full_name':'Ullmann27/lumo-lernen'}}
    artifacts = {'artifacts':[{'name':c4.CANDIDATE,'id':ARTIFACT,'digest':DIGEST,
                    'size_in_bytes':648_000_000,'expired':False,
                    'workflow_run':{'id':RUN,'head_sha':HOST}}]}
    jobs = {'jobs':[{'name':name,'run_id':RUN,'run_attempt':1,'head_sha':HOST,
                    'status':'completed','conclusion':'success'} for name in
                    ('android-host-compile','connect-four-runtime','verify-and-build')]}
    return run, artifacts, jobs


def bind(metadata=None):
    return c4.artifact_binding(*(metadata or original_metadata()),source=HOST,run_id=RUN,
                              attempt=1,artifact_id=ARTIFACT,digest=DIGEST,
                              native=NATIVE,version_name='0.13.8')


class SyntheticEvidence:
    """Create explicitly synthetic files to execute the actual offline verifier."""
    def __init__(self, root):
        self.root = root
        self.count = 0
        self.observations = []
        self.transitions = []
        self.returns = []
        self.binding = bind()
        self.identity = {'synthetic':'contract input, not an APK verification'}

    def write(self, name, data):
        path = self.root / name
        path.parent.mkdir(parents=True,exist_ok=True)
        if isinstance(data, (dict,list)):
            data = json.dumps(data,sort_keys=True)
        path.write_bytes(data.encode() if isinstance(data,str) else data)
        return name

    def original(self, tag, command, raw, rc=0):
        name = 'commands/'+tag
        data = raw.encode() if isinstance(raw,str) else raw
        self.write(name+'.stdout',data)
        self.write(name+'.stderr',b'')
        self.write(name+'.json',{'command':command,'returncode':rc,
                   'stdout_bytes':len(data),'stderr_bytes':0,
                   'stdout_sha256':hashlib.sha256(data).hexdigest(),
                   'stderr_sha256':hashlib.sha256(b'').hexdigest()})
        return name+'.stdout'

    def screenshot(self, name, value=None, geometry=None):
        image = Image.new('RGB',PIXELS,(20,32,56))
        if value is not None:
            draw = ImageDraw.Draw(image)
            for cell in geometry['cells']:
                piece = value['board'][cell['row']*7+cell['column']]
                if piece:
                    x,y = cell['disc_quad'][0][0]+40,cell['disc_quad'][0][1]+110
                    draw.ellipse((x-35,y-35,x+35,y+35),fill=(83,221,253) if piece==1 else (255,209,102))
        path = self.root / (name+'.png')
        path.parent.mkdir(parents=True,exist_ok=True)
        image.save(path)
        return {'file':name+'.png','width':PIXELS[0],'height':PIXELS[1],'sha256':c4.sha256(path)}

    def observe(self, name, value, control=None, pid=200):
        self.count += 1
        geometry = layout(value,pid=pid,sequence=self.count)
        now = 1_700_000_000_000+self.count*700
        life = {'active':True,'stamp':now-50,'pauseEpoch':0}
        raw = {}
        mailbox = f'/data/user/0/{c4.PACKAGE}/files/lumo_connect_four_session_v1/{value["token"]}'
        for key, data in (('state',value),('state_after',value),('layout',geometry),('layout_after',geometry),('lifecycle',life)):
            actual = key.removesuffix('_after')
            source = (f'/data/user/0/{c4.PACKAGE}/files/connect_four_layout_v1.json' if actual=='layout'
                      else mailbox+'/'+actual+'.json')
            raw[key] = self.original(name+'-'+key,['adb','exec-out','cat',source],json.dumps(data))
        fields = {
            'clock':(['adb','shell','date','+%s%3N'],str(now)+'\n'),
            'native_pid':(['adb','shell','pidof',c4.PACKAGE+':lumo_game'],str(pid)+'\n'),
            'host_pid':(['adb','shell','pidof',c4.PACKAGE],'100\n'),
            'activity':(['adb','shell','dumpsys','activity','activities'],
                        'mResumedActivity: '+c4.PACKAGE+'/.ConnectFourGameActivity\n'),
            'authority':(['adb','shell','dumpsys','activity','services',c4.PACKAGE],
                         'ConnectFourAuthorityService\n'),
            'density':(['adb','shell','wm','density'],'Physical density: 420\nOverride density: 400\n'),
            'preferences':(['adb','exec-out','cat',f'/data/user/0/{c4.PACKAGE}/shared_prefs/FlutterSharedPreferences.xml'],xml_preferences(value)),
        }
        for key,(command,text) in fields.items():
            raw[key] = self.original(name+'-'+key,command,text)
        frame = self.screenshot(name,value,geometry)
        item = {'id':name,'state':copy.deepcopy(value),'layout':geometry,'lifecycle':life,
                'device_clock_ms':now,'pid':pid,'host_pid':100,'density':2.5,'pixels':list(PIXELS),
                'frame':frame['file'],'frame_sha256':frame['sha256'],'raw':raw,
                'observed_monotonic':10+self.count*.7,
                'surface':c4.inspect_surface(self.root/frame['file'],orientation='responsive'),
                'visual':c4.board_pixels(self.root/frame['file'],geometry,value,pid,2.5)}
        if control:
            item['target'] = c4.touch_target(geometry,value,PIXELS,pid,2.5,control)
        self.observations.append(name)
        self.write('observations/'+name+'.json',item)
        return item

    def native_touch(self, name, value, control, pid=200):
        first = self.observe(name+'-first',value,control,pid)
        second = self.observe(name+'-second',value,control,pid)
        target = c4.stable_target(first,second)
        x,y = map(str,target['point'])
        command = self.original(name+'-touch',['adb','shell','input','swipe',x,y,x,y,'120'],'')
        touch = self.write(name+'-touch.json',{'first':first['id'],'second':second['id'],
                                            'target':target,'command_original':command})
        return second,touch

    def transition(self, name, before, after, action, control, pid=200):
        current,touch = self.native_touch(name,before,control,pid)
        finished = self.observe(name+'-after',after,pid=pid)
        request = {'token':before['token'],'roundId':before['roundId'],'revision':before['revision'],
                   'sequence':before['ack']+1,'action':action}
        if action=='drop':
            request['column'] = int(control[7:])
        source = self.original(name+'-request',['adb','exec-out','cat','synthetic/request.json'],json.dumps(request))
        self.transitions.append({'action':action,'before':current['id'],'after':finished['id'],
                                 'request':source,'touch':touch})
        return finished

    def flutter_touch(self, name, label):
        frames=[]
        for number in (1,2):
            tag=name+'-'+str(number)
            tree=ET.Element('hierarchy')
            ET.SubElement(tree,'node',{'text':label,'package':c4.PACKAGE,'enabled':'true',
                                      'clickable':'true','bounds':'[100,300][980,500]'})
            ui=self.write(tag+'.xml',ET.tostring(tree))
            density=self.original(tag+'-density',['adb','shell','wm','density'],'Physical density: 400\n')
            frames.append({'ui':ui,'capture':self.screenshot(tag),'density':density,'observed_monotonic':number})
        target=c4.flutter_control(list(tree.iter('node')),label,PIXELS,2.5)
        x,y=map(str,target['point'])
        command=self.original(name+'-dispatch',['adb','shell','input','swipe',x,y,x,y,'120'],'')
        return self.write(name+'.json',{'first':frames[0],'second':frames[1],
                                     'target':target,'command_original':command})

    def returned(self, name, value, pid=200):
        before,touch=self.native_touch(name,value,'back',pid)
        pidfile=self.original(name+'-exit',['adb','shell','pidof',c4.PACKAGE+':lumo_game'],'',rc=1)
        closed=self.original(name+'-closed',['adb','shell','find','synthetic'],'')
        activity=self.original(name+'-activity',['adb','shell','dumpsys','activity','activities'],
                               'mResumedActivity: '+c4.PACKAGE+'/.MainActivity\n')
        preference=self.original(name+'-prefs',['adb','exec-out','cat','synthetic/prefs'],xml_preferences(value))
        ui=ET.Element('hierarchy')
        ET.SubElement(ui,'node',{'text':'Spiel pausiert','content-desc':'Fortsetzen'})
        self.returns.append({'before':before['id'],'touch':touch,'native_exit':pidfile,
            'closed_mailbox':closed,'activity':activity,'preferences':preference,'round':stored(value),
            'returned_ui':self.write(name+'.xml',ET.tostring(ui)),'frame':self.screenshot(name+'-flutter'),
            'to_games_touch':self.flutter_touch(name+'-games','Zur Spieleauswahl')})
        return before

    def build(self):
        a=state()
        b=state([3,0],revision=4,ack=1)
        c=state([3,0],revision=5,ack=2,paused=True)
        d=state([3,0],revision=6,ack=3)
        e=state([3,0,2,6],revision=9,ack=4)
        f=state([3,0,2,6],revision=10,ack=5,paused=True)
        g=state([3,0,2,6],token='b'*32)
        h=state([3,0,2,6],revision=2,ack=1,paused=True,token='b'*32)
        entry=self.flutter_touch('entry',c4.PORTAL)
        initial=self.observe('initial',a)
        self.transition('first-drop',a,b,'drop','column_3')
        pause=self.transition('first-pause',b,c,'pause','pause')
        self.count += 2
        held=self.observe('held',c)
        self.transition('first-resume',c,d,'resume','resume')
        self.transition('second-drop',d,e,'drop','column_2')
        self.transition('second-pause',e,f,'pause','pause')
        closed=self.returned('return-one',f)
        reopen_touch=self.flutter_touch('reopen',c4.PORTAL)
        reopened=self.observe('reopened',g,pid=201)
        self.transition('third-pause',g,h,'pause','pause',pid=201)
        self.returned('return-two',h,pid=201)
        before=self.original('before-prefs',['adb','exec-out','cat','synthetic/prefs'],xml_preferences(a))
        after=self.original('after-prefs',['adb','exec-out','cat','synthetic/prefs'],xml_preferences(h))
        log=self.original('all-logcat',['adb','logcat','-b','all','-d','-v','threadtime'],
                           'Synthetic contract log, not an Android execution\n')
        sdk=self.original('sdk',['adb','shell','getprop','ro.build.version.sdk'],'35\n')
        report={'schema':1,'status':'PASS','binding':self.binding,'identity':self.identity,
                'synthetic_fixture':True,'entry_touch':entry,'initial':initial['id'],
                'observations':self.observations,'transitions':self.transitions,'returns':self.returns,
                'pause_hold':{'first':pause['id'],'second':held['id'],
                              'elapsed':held['observed_monotonic']-pause['observed_monotonic']},
                'reopen':{'closed':closed['id'],'opened':reopened['id'],'touch':reopen_touch},
                'preferences_before':before,'preferences_after':after,
                'original_logcat':log,'fatal_entries':[],'android_sdk_original':sdk}
        self.report=report
        self.refresh()
        return report

    def refresh(self):
        self.report['originals']=[{'path':path.relative_to(self.root).as_posix(),
                                  'bytes':path.stat().st_size,'sha256':c4.sha256(path)}
                                 for path in sorted(self.root.rglob('*'))
                                 if path.is_file() and path!=self.root/'c4-result.json']
        self.write('c4-result.json',self.report)


class BindingTests(unittest.TestCase):
    def test_real_size_identifiers_and_exact_source_contract(self):
        result=bind()
        self.assertEqual(result['run_id'],RUN)
        self.assertEqual(result['native_source'],NATIVE)

    def test_both_explicit_candidate_branches_bind_the_same_exact_evidence(self):
        expected=bind()
        for branch in ('integration/lumo-c4-connections-20261114',
                       'work/lumo-play-quality-20261114'):
            data=original_metadata()
            data[0]['head_branch']=branch
            with self.subTest(branch=branch):
                self.assertEqual(bind(data),expected)

    def test_unapproved_branch_cannot_reuse_valid_source_artifact_and_jobs(self):
        for branch in ('main','work/unapproved',
                       'work/lumo-play-quality-20261114-extra',
                       'integration/lumo-c4-connections-20261114-extra',
                       'refs/heads/work/lumo-play-quality-20261114','',None):
            data=original_metadata()
            data[0]['head_branch']=branch
            with self.subTest(branch=branch),self.assertRaises(ValueError):
                bind(data)

    def test_quality_branch_keeps_source_artifact_and_required_job_checks(self):
        alterations=(
            ('source',lambda x:x[0].update(head_sha='f'*40)),
            ('run',lambda x:x[0].update(id=RUN+1)),
            ('attempt',lambda x:x[0].update(run_attempt=2)),
            ('workflow',lambda x:x[0].update(path='.github/workflows/other.yml')),
            ('event',lambda x:x[0].update(event='workflow_dispatch')),
            ('repository',lambda x:x[0].update(repository={'full_name':'outside/fork'})),
            ('artifact',lambda x:x[1]['artifacts'][0].update(id=ARTIFACT+1)),
            ('digest',lambda x:x[1]['artifacts'][0].update(digest='sha256:'+'e'*64)),
            ('expired',lambda x:x[1]['artifacts'][0].update(expired=True)),
            ('size',lambda x:x[1]['artifacts'][0].update(size_in_bytes=0)),
            ('artifact source',lambda x:x[1]['artifacts'][0]['workflow_run'].update(head_sha='f'*40)),
            ('artifact run',lambda x:x[1]['artifacts'][0]['workflow_run'].update(id=RUN+1)),
            ('missing artifact',lambda x:x[1].update(artifacts=[])),
            ('duplicate artifact',lambda x:x[1]['artifacts'].append(copy.deepcopy(x[1]['artifacts'][0]))),
            ('missing job',lambda x:x[2]['jobs'].pop()),
            ('duplicate job',lambda x:x[2]['jobs'].append(copy.deepcopy(x[2]['jobs'][0]))),
        )
        for name,alter in alterations:
            data=original_metadata()
            data[0]['head_branch']='work/lumo-play-quality-20261114'
            alter(data)
            with self.subTest(alteration=name),self.assertRaises(ValueError):
                bind(data)
        for index in range(3):
            for field,value in (('run_id',RUN+1),('run_attempt',2),
                                ('head_sha','f'*40),('conclusion','failure'),
                                ('conclusion','skipped'),('conclusion','cancelled')):
                data=original_metadata()
                data[0]['head_branch']='work/lumo-play-quality-20261114'
                data[2]['jobs'][index][field]=value
                with self.subTest(job=index,field=field,value=value),self.assertRaises(ValueError):
                    bind(data)

    def test_actual_upload_digest_is_canonicalized_against_rest_metadata(self):
        actual=c4.artifact_binding(*original_metadata(),source=HOST,run_id=RUN,
            attempt=1,artifact_id=ARTIFACT,digest=DIGEST.removeprefix('sha256:'),
            native=NATIVE,version_name='0.13.8')
        self.assertEqual(actual,bind())

    def test_rejects_wrong_source_workflow_attempt_artifact_and_job(self):
        alterations=(lambda x:x[0].update(head_sha='f'*40),
                     lambda x:x[0].update(path='.github/workflows/lumo-kart-graphics-2019.yml'),
                     lambda x:x[0].update(run_attempt=2),
                     lambda x:x[1]['artifacts'][0].update(digest='sha256:'+'e'*64),
                     lambda x:x[2]['jobs'][0].update(conclusion='skipped'),
                     lambda x:x[2]['jobs'].append(copy.deepcopy(x[2]['jobs'][0])))
        for alter in alterations:
            data=original_metadata(); alter(data)
            with self.subTest(alter=alter),self.assertRaises(ValueError): bind(data)


class ObservationTests(unittest.TestCase):
    def test_actual_complete_target_and_density(self):
        s=state(); l=layout(s)
        target=c4.touch_target(l,s,PIXELS,200,2.5,'column_3')
        self.assertEqual(target['text'],'4 ↓')
        self.assertEqual(target['size_dp'],[52,52])
        self.assertEqual(c4.device_density('Physical density: 420\nOverride density: 400\n'),2.5)

    def test_no_clipped_small_duplicate_fake_or_other_revision_target(self):
        for field,value in (('clipped',True),('visible',False),('enabled',False)):
            s=state(); l=layout(s); l['buttons'][8][field]=value
            with self.subTest(field=field),self.assertRaises(ValueError):
                c4.touch_target(l,s,PIXELS,200,2.5,'column_3')
        for change in (lambda l:l.update(observation_source='platform_fixture'),
                       lambda l:l.update(revision=999),
                       lambda l:l['buttons'].append(copy.deepcopy(l['buttons'][0])),
                       lambda l:l['buttons'][8].update(rect_px=[460,2100,100,100],hit_rect_px=[460,2100,100,100]),
                       lambda l:l['buttons'][8].update(rect_px=[460,2200,130,130],hit_rect_px=[460,2200,130,130])):
            s=state(); l=layout(s); change(l)
            with self.subTest(change=change),self.assertRaises(ValueError):
                c4.touch_target(l,s,PIXELS,200,2.5,'column_3')

    def test_ack_requires_actual_bot_and_same_round(self):
        before=state(); after=state([3,0],revision=4,ack=1)
        request={'action':'drop','token':before['token'],'roundId':before['roundId'],
                 'revision':1,'sequence':1,'column':3}
        c4.acknowledged(before,after,request,'drop')
        for change in (lambda s:s.update(ack=0),lambda s:s.update(roundId='d'*32),
                       lambda s:s.update(rejected=1),lambda s:s.update(recordRevision=2)):
            broken=copy.deepcopy(after);change(broken)
            with self.subTest(change=change),self.assertRaises(ValueError):
                c4.acknowledged(before,broken,request,'drop')
        with self.assertRaises(ValueError):
            c4.acknowledged(before,state([3],revision=3,ack=1),request,'drop')

    def test_owner_and_durable_round_must_match(self):
        s=state([3,0]); p=prefs(s)
        self.assertEqual(c4.persisted_round(p,s)['columns'],[3,0])
        p['flutter.lumo_school_active_student_v1']='another-child'
        with self.assertRaises(ValueError): c4.persisted_round(p,s)
        p=prefs(s);p[c4.ROUND_PREFIX+OWNER]=json.dumps(stored(state()))
        with self.assertRaises(ValueError): c4.persisted_round(p,s)

    def test_reopen_requires_same_round_and_new_token(self):
        previous=state([3,0,2,6],paused=True)
        current=state([3,0,2,6],token='b'*32)
        c4.reopened(previous,current)
        for change in (lambda s:s.update(token=previous['token']),lambda s:s.update(roundId='d'*32)):
            broken=copy.deepcopy(current);change(broken)
            with self.subTest(change=change),self.assertRaises(ValueError): c4.reopened(previous,broken)

    def test_pixel_evidence_rejects_missing_actual_acknowledged_disc(self):
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory); f=SyntheticEvidence(root)
            s=state([3,0]); l=layout(s)
            frame=f.screenshot('fixture',s,l)
            self.assertEqual(len(c4.board_pixels(root/frame['file'],l,s,200,2.5)['occupied_cells']),2)
            f.screenshot('fixture')
            with self.assertRaisesRegex(ValueError,'pixels do not show'):
                c4.board_pixels(root/frame['file'],l,s,200,2.5)

    def test_flutter_target_requires_actual_package_and_unambiguous_full_control(self):
        node={'text':c4.PORTAL,'package':c4.PACKAGE,'enabled':'true','clickable':'true',
              'bounds':'[100,300][980,500]'}
        self.assertEqual(c4.flutter_control([node],c4.PORTAL,PIXELS,2.5)['point'],[540,400])
        for nodes in ([node,node],[{**node,'package':'android'}],[{**node,'bounds':'[100,300][980,350]'}]):
            with self.assertRaises(ValueError): c4.flutter_control(nodes,c4.PORTAL,PIXELS,2.5)

    def test_anr_and_engine_errors_remain_rejected(self):
        for message in ('FATAL EXCEPTION: main','am_anr: [0,1,system]','SCRIPT ERROR: bad',
                        'E godot : ERROR: Shader compile error','GL_MAX_FRAGMENT_UNIFORM_VECTORS'):
            with self.subTest(message=message): self.assertTrue(c4.runtime_errors(message))


class CompleteEvidenceTests(unittest.TestCase):
    def setUp(self):
        self.temporary=tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root=Path(self.temporary.name)
        self.fixture=SyntheticEvidence(self.root)
        self.report=self.fixture.build()

    def verify(self):
        return c4.verify_report(self.root,self.fixture.binding,self.fixture.identity)

    def test_complete_synthetic_observation_replay(self):
        result=self.verify()
        self.assertEqual((result['actual_child_drops'],result['actual_bot_responses'],result['native_returns']),(2,2,2))
        self.assertIn('no release',result['scope'])

    def test_original_byte_change_and_unlisted_file_fail(self):
        path=self.root/'extra.txt';path.write_text('unindexed')
        with self.assertRaisesRegex(ValueError,'complete original directory'): self.verify()
        path.unlink()
        original=self.root/self.report['original_logcat'];original.write_text('tampered')
        with self.assertRaisesRegex(ValueError,'bytes changed'): self.verify()

    def test_return_cannot_omit_actual_back_touch(self):
        self.report['returns'][0]['touch']=self.report['transitions'][0]['touch']
        self.fixture.refresh()
        with self.assertRaisesRegex(ValueError,'two-frame control'): self.verify()

    def test_state_chain_cannot_skip_first_child_bot_pair(self):
        self.report['transitions'][0]['before']=self.report['transitions'][3]['before']
        self.fixture.refresh()
        with self.assertRaisesRegex(ValueError,'transition chain'): self.verify()

    def test_fresh_heartbeat_and_actual_density_are_mandatory(self):
        name=self.report['initial'];path=self.root/('observations/'+name+'.json')
        item=json.loads(path.read_text());item['density']=2.6
        self.fixture.write('observations/'+name+'.json',item);self.fixture.refresh()
        with self.assertRaisesRegex(ValueError,'device density differs'): self.verify()

    def test_failure_status_cannot_be_relabelled_with_old_binding(self):
        self.report['status']='FAIL';self.fixture.refresh()
        with self.assertRaisesRegex(ValueError,'missing, failed'): self.verify()
        self.report['status']='PASS';self.report['binding']['host_source']='e'*40
        self.fixture.refresh()
        with self.assertRaises(ValueError): c4.verify_report(self.root,bind(),self.fixture.identity)


if __name__ == '__main__':
    unittest.main()
