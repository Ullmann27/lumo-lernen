"""Synthetic parser counterexamples; no emulator or release evidence is made.

Temporary layouts borrow the original desktop camera fixture, with explicitly
synthetic Android boundary data only inside these unit tests. The real CLI
still requires current immutable GitHub jobs and candidate sources.
"""
from __future__ import annotations

import copy
import hashlib
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
import xml.etree.ElementTree as ET

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location('c4_publisher_contract', ROOT/'scripts/verify_studio_connect_four_android.py')
gate = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(gate)
P = gate.probe
LAYOUT = ROOT/'tools/android_qa/tests/fixtures/connect_four_android/phone-playing.layout.json'


def dump(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False)+'\n')


def expected():
    return {'host':'a'*40,'native':'b'*40,'apk':'c'*64,'pck':'d'*64,
            'build_run':100,'artifact_id':200,'artifact_digest':'e'*64}


def identity():
    e=expected()
    return {'apk_sha256':e['apk'],'godot_pck_sha256':e['pck'],
            'flutter_source_commit':e['host'],'godot_revision':e['native'],
            'versionName':'0.13.8','versionCode':2020,'signingCertificateSha256':gate.CERT,
            'checks':{key:True for key in gate.IDENTITY_CHECKS}}


def header():
    hashes={P.SELF:'f'*64}
    binding={'host':expected()['host'],'native':expected()['native'],'apk':identity(),
             'actual_installed_apk_sha256':expected()['apk'],'source_hashes':hashes}
    report={'status':'PASS','source_binding':binding,'android_runtime':{
        'sdk':37,'release':'17','fingerprint':'synthetic test fingerprint','model':'synthetic test model'},
        'fatal_crashes':0,'physical_fold7_performance_measured':False,'new_mailbox_token':True,
        'saved_round_unchanged_after_pause_home_exit_reopen':True}
    steps=[{'step':key,'ok':True} for key in sorted(gate.TOUR_STEPS)]
    next(s for s in steps if s['step']=='apk-identity').update(identity())
    tour={'status':'PASS','apk_sha256':expected()['apk'],'android_sdk':'37','steps':steps}
    return report,binding,tour,hashes


class MetadataContracts(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory();self.addCleanup(self.tmp.cleanup)
        self.folder=Path(self.tmp.name)
        e=expected()
        self.run={'id':100,'head_sha':e['host'],'path':gate.WORKFLOW,'run_attempt':1,
                  'status':'in_progress','repository':{'full_name':'Ullmann27/lumo-lernen'}}
        self.jobs=[{'id':1000+i,'name':name,'run_id':100,'head_sha':e['host'],
                    'run_attempt':1,'status':'completed','conclusion':'success',
                    'started_at':'2026-11-14T01:00:00Z','completed_at':'2026-11-14T01:20:00Z'}
                   for i,name in enumerate(gate.JOBS.values())]
        self.artifacts=[{'id':200+i,'name':name,'digest':'sha256:'+e['artifact_digest'],
                         'expired':False,'size_in_bytes':100,'created_at':'2026-11-14T01:19:00Z',
                         'workflow_run':{'id':100,'head_sha':e['host']}}
                        for i,name in enumerate(gate.ARTIFACTS.values())]

    def verify(self):
        for name,value in [('run.json',self.run),('jobs.json',{'jobs':self.jobs}),
                           ('artifacts.json',{'artifacts':self.artifacts})]: dump(self.folder/name,value)
        return gate.verify_metadata(self.folder,expected())

    def test_current_successful_jobs_can_be_checked_while_publisher_run_is_running(self):
        result=self.verify()
        self.assertEqual(result['run'],100);self.assertEqual(len(result['jobs']),4)

    def test_failed_missing_or_wrong_attempt_job_is_rejected(self):
        for field,value in [('conclusion','failure'),('run_attempt',2),('head_sha','9'*40)]:
            with self.subTest(field=field):
                original=self.jobs[-1].copy();self.jobs[-1][field]=value
                with self.assertRaises(RuntimeError):self.verify()
                self.jobs[-1]=original
        self.jobs.pop()
        with self.assertRaises(RuntimeError):self.verify()

    def test_api35_artifact_cannot_replace_api37_or_runtime(self):
        for index in (2,3):
            with self.subTest(index=index):
                saved=self.artifacts[index];self.artifacts[index]=copy.deepcopy(self.artifacts[1])
                with self.assertRaises(RuntimeError):self.verify()
                self.artifacts[index]=saved

    def test_foreign_source_run_workflow_or_repository_is_rejected(self):
        for field,value in [('head_sha','0'*40),('id',99),('path','.github/workflows/old.yml'),
                            ('repository',{'full_name':'other/repo'})]:
            with self.subTest(field=field):
                saved=copy.deepcopy(self.run);self.run[field]=value
                with self.assertRaises(RuntimeError):self.verify()
                self.run=saved

    def test_reused_artifact_from_older_attempt_is_rejected(self):
        self.artifacts[1]['created_at']='2026-11-13T01:19:00Z'
        with self.assertRaisesRegex(RuntimeError,'current successful attempt'):self.verify()

    def test_wrong_candidate_digest_or_foreign_artifact_origin_is_rejected(self):
        self.artifacts[0]['digest']='sha256:'+'f'*64
        with self.assertRaisesRegex(RuntimeError,'Candidate artifact'):self.verify()
        self.artifacts[0]['digest']='sha256:'+expected()['artifact_digest']
        self.artifacts[2]['workflow_run']['id']=99
        with self.assertRaisesRegex(RuntimeError,'another actual run'):self.verify()


class SourceAndIdentityContracts(unittest.TestCase):
    def test_complete_header_requires_current_sources_and_original_identity(self):
        report,binding,tour,hashes=header()
        gate.check_header(report,binding,copy.deepcopy(binding),tour,expected(),hashes,37)

    def test_apk_pck_signature_version_and_probe_source_changes_are_rejected(self):
        for key,value in [('apk_sha256','0'*64),('godot_pck_sha256','0'*64),
                          ('signingCertificateSha256','0'*64),('versionCode',2019)]:
            with self.subTest(key=key):
                report,binding,tour,hashes=header();binding['apk'][key]=value
                with self.assertRaises(RuntimeError):gate.check_header(report,binding,binding,tour,expected(),hashes,37)
        report,binding,tour,hashes=header();binding['source_hashes']={P.SELF:'0'*64}
        with self.assertRaises(RuntimeError):gate.check_header(report,binding,binding,tour,expected(),hashes,37)

    def test_missing_abi_guard_or_changed_installed_apk_cannot_pass(self):
        report,binding,tour,hashes=header();binding['apk']['checks']['x86_64_native_code']=False
        with self.assertRaises(RuntimeError):gate.check_header(report,binding,binding,tour,expected(),hashes,37)
        report,binding,tour,hashes=header();binding['actual_installed_apk_sha256']='0'*64
        with self.assertRaises(RuntimeError):gate.check_header(report,binding,binding,tour,expected(),hashes,37)

    def test_api35_tour_cannot_stand_in_for_api37(self):
        report,binding,tour,hashes=header();tour['android_sdk']='35'
        with self.assertRaises(RuntimeError):gate.check_header(report,binding,binding,tour,expected(),hashes,37)
        tour['android_sdk']='37';report['android_runtime']['release']='15'
        with self.assertRaises(RuntimeError):gate.check_header(report,binding,binding,tour,expected(),hashes,37)

    def test_duplicate_or_failed_main_tour_steps_do_not_pass(self):
        report,binding,tour,hashes=header();tour['steps'][-1]=tour['steps'][-2]
        with self.assertRaises(RuntimeError):gate.check_header(report,binding,binding,tour,expected(),hashes,37)
        report,binding,tour,hashes=header();tour['steps'][-1]['ok']=False
        with self.assertRaises(RuntimeError):gate.check_header(report,binding,binding,tour,expected(),hashes,37)

    def test_nonfinite_duplicate_or_symlinked_report_is_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            folder=Path(tmp);path=folder/'bad.json'
            for raw in ['{"status":"PASS","status":"PASS"}','{"x":NaN}']:
                path.write_text(raw)
                with self.assertRaises(RuntimeError):gate.read(path)
            path.write_text('{}');(folder/'link.json').symlink_to(path)
            with self.assertRaises(RuntimeError):gate.read(folder/'link.json')
            with self.assertRaises(RuntimeError):gate.member(folder,'../bad.json')


class OriginalObservationContracts(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory();self.addCleanup(self.tmp.cleanup)
        self.folder=Path(self.tmp.name);self.items=[]
        original=json.loads(LAYOUT.read_text())
        self.owner=original['owner'];self.token='a'*32
        histories=[[],[3,3],[3,3,2,4]]+[[3,3,2,4]]*5
        for i,(stage,columns) in enumerate(zip(gate.STAGES,histories)):
            state={k:original[k] for k in ('schema','game','owner','roundId','twoPlayers','level','rewarded')}
            state.update(token=self.token if i<7 else 'b'*32,columns=columns,revision=i+1,
                         recordRevision=min(len(columns)+1,5),ack=min(i,5),rejected=0,
                         paused=i in (3,5),canDrop=i not in (3,5))
            state.update(P.replay(columns));layout=copy.deepcopy(original);layout.update(state)
            layout['pid']=71 if i<7 else 72;layout['layout_sequence']=i+1
            layout['observation_source']='android_window_insets'  # Synthetic boundary for pure parser tests only.
            for cell in layout['cells']:cell['piece']=state['board'][cell['row']*7+cell['column']]
            for button in layout['buttons']:
                if button['id'].startswith('column_'):button['enabled']=not state['paused']
                if button['id']=='pause':button['enabled']=not state['paused']
                if button['id']=='resume':
                    button.update(visible=state['paused'],enabled=True,clipped=False,
                                  rect_px=[60,400,500,140],hit_rect_px=[60,400,500,140])
            n=10+i*10
            projection=P.check_layout(layout,state,(1080,2400),2.625,layout['pid'])
            picture=Image.new('RGB',(1080,2400),'#123555');draw=ImageDraw.Draw(picture)
            if not state['paused']:
                for cell in projection['cells']:
                    if cell['piece']:
                        x,y=cell['center'];draw.ellipse((x-40,y-40,x+40,y+40),fill='#53ddfd' if cell['piece']==1 else '#ffd166')
            name=f'{n:04d}-{stage}.png';picture.save(self.folder/name)
            pixels=P.check_pixels(picture,layout,projection) if not state['paused'] else []
            picture.close()
            shot={'file':name,'width':1080,'height':2400,'sha256':P.sha(self.folder/name)}
            rawhash=self.raw(n-2,'layout-before',P.LAYOUT,layout)
            self.raw(n-1,'state',P.SESSION+state['token']+'/state.json',state)
            self.raw(n+1,'state',P.SESSION+state['token']+'/state.json',state)
            self.raw(n+2,'layout-after',P.LAYOUT,layout)
            item={'capture':shot,'layout_sha256':rawhash,'state':state,'layout':layout,'geometry':projection,'disc_pixels':pixels}
            dump(self.folder/f'{n+3:04d}-{stage}-observation.json',item)
            self.items.append(dict(item,stage=stage,number=n+3))

    def raw(self,n,label,path,value):
        name=f'{n:04d}-{label}';raw=json.dumps(value).encode()
        (self.folder/(name+'.raw')).write_bytes(raw);(self.folder/(name+'.stderr')).write_bytes(b'')
        digest=hashlib.sha256(raw).hexdigest()
        dump(self.folder/(name+'-read.json'),{'path':path,'serial':'emulator-5554','returncode':0,
            'bytes':len(raw),'sha256':digest,'started_unix_seconds':float(n),'finished_unix_seconds':n+.1})
        return digest

    def parsed(self):return gate.observations(self.folder,gate.readbacks(self.folder),self.owner,2.625)

    def test_all_original_raw_brackets_and_actual_projected_pixels_are_rechecked(self):
        self.assertEqual(len(self.parsed()),8)

    def test_changed_original_png_or_raw_layout_is_rejected(self):
        p=self.folder/self.items[1]['capture']['file'];data=p.read_bytes();p.write_bytes(data+b'changed')
        with self.assertRaisesRegex(RuntimeError,'PNG hash'):self.parsed()
        p.write_bytes(data)
        raw=self.folder/'0018-layout-before.raw';raw.write_text('{}')
        with self.assertRaisesRegex(RuntimeError,'read bytes differ'):self.parsed()

    def test_actual_desktop_fixture_is_not_an_android_report(self):
        original=json.loads(LAYOUT.read_text())
        with self.assertRaisesRegex(RuntimeError,'actual Android'):
            P.check_layout(original,original,(1080,2400),2.625,original['pid'])

    def test_missing_disc_pixels_fail_even_when_state_and_layout_claim_success(self):
        p=self.folder/self.items[1]['capture']['file'];Image.new('RGB',(1080,2400),'#123555').save(p)
        report=self.folder/'0023-child-and-bot-observation.json';item=json.loads(report.read_text())
        item['capture']['sha256']=P.sha(p);dump(report,item)
        with self.assertRaisesRegex(RuntimeError,'disc pixels absent'):self.parsed()

    def test_illegal_or_foreign_owner_state_is_rejected(self):
        raws=gate.readbacks(self.folder)
        with self.assertRaisesRegex(RuntimeError,'another child'):
            gate.observations(self.folder,raws,'f'*64,2.625)
        state=copy.deepcopy(self.items[1]['state']);state['columns']=[3]*7
        with self.assertRaises(RuntimeError):P.check_state(state)

    def test_partial_json_read_is_preserved_but_cannot_supply_a_state(self):
        self.raw(90,'state',P.SESSION+self.token+'/state.json',{})
        path=self.folder/'0090-state.raw';path.write_text('{')
        meta=gate.read(self.folder/'0090-state-read.json');meta.update(bytes=1,sha256=P.sha(path))
        dump(self.folder/'0090-state-read.json',meta)
        raws=gate.readbacks(self.folder);self.assertIsNone(raws['0090-state']['value'])
        with self.assertRaises(RuntimeError):gate.raw_value(raws,'0090-state',P.SESSION+self.token+'/state.json')


class StateLeaseAndRuntimeContracts(unittest.TestCase):
    def test_actual_drop_summary_cannot_substitute_unacknowledged_moves(self):
        before=json.loads(LAYOUT.read_text());before.update(columns=[],ack=0,revision=1,twoPlayers=False,canDrop=True)
        before.update(P.replay([]));after=copy.deepcopy(before)
        after.update(columns=[3,3],revision=3,recordRevision=3,ack=1);after.update(P.replay(after['columns']))
        request={'action':'drop','column':3,'token':before['token'],'roundId':before['roundId'],'revision':1,'sequence':1}
        self.assertEqual(P.check_drop(before,request,after,3)['columns_after'],[3,3])
        after['ack']=0
        with self.assertRaisesRegex(RuntimeError,'acknowledged'):P.check_drop(before,request,after,3)

    def leases(self):
        token='a'*32
        def sample(stamp,epoch,active=True):
            return {'device_before_ms':stamp+50,'device_after_ms':stamp+60,
                    'lifecycle':{'active':active,'stamp':stamp,'pauseEpoch':epoch}}
        report={'leases':[sample(100000,0),sample(101000,0),sample(106000,1)],
                'home_inactive_lease':sample(102000,1,False)}
        raws={str(i):{'value':x['lifecycle'],'label':'lifecycle','metadata':{'path':P.SESSION+token+'/lifecycle.json'}}
              for i,x in enumerate(report['leases']+[report['home_inactive_lease']])}
        return report,raws,token

    def test_fresh_active_and_real_inactive_home_leases_are_mandatory(self):
        report,raws,token=self.leases();self.assertTrue(gate.check_leases(report,raws,token)['home_inactive'])
        report['leases'][-1]['device_before_ms']+=3000;report['leases'][-1]['device_after_ms']+=3000
        with self.assertRaisesRegex(RuntimeError,'Stale'):gate.check_leases(report,raws,token)

    def test_missing_inactive_lease_epoch_or_three_second_home_interval_fails(self):
        for variant in ('missing','epoch','short'):
            report,raws,token=self.leases()
            if variant=='missing':raws.pop('3')
            if variant=='epoch':report['home_inactive_lease']['lifecycle']['pauseEpoch']=0
            if variant=='short':
                sample=report['leases'][-1];sample['device_before_ms']=103000;sample['device_after_ms']=103010
                sample['lifecycle']['stamp']=102990
            with self.subTest(variant=variant),self.assertRaises(RuntimeError):gate.check_leases(report,raws,token)

    def test_runtime_visual_fixture_or_nonzero_process_is_not_real_dart_acceptance(self):
        with tempfile.TemporaryDirectory() as tmp:
            folder=Path(tmp)
            for report in ({'kind':'connect_four_visual_fixture','checks':303},
                           {'passed':True,'exit_codes':{'dart':0,'godot':1}},
                           {'passed':True,'exit_codes':{'dart':False,'godot':0}}):
                dump(folder/'runtime-gate.json',report)
                with self.assertRaisesRegex(RuntimeError,'both succeed'):
                    gate.verify_runtime(folder,folder,folder,expected())

    def test_runtime_before_after_source_change_is_rejected_before_media(self):
        with tempfile.TemporaryDirectory() as tmp:
            folder=Path(tmp);dump(folder/'runtime-gate.json',{'passed':True,'exit_codes':{'dart':0,'godot':0}})
            dump(folder/'source-before.json',{'host':{'head':'a'*40}})
            dump(folder/'source-after.json',{'host':{'head':'0'*40}})
            with self.assertRaisesRegex(RuntimeError,'source changed'):
                gate.verify_runtime(folder,folder,folder,expected())

    def test_runtime_tree_modes_missing_files_and_foreign_head_are_rejected(self):
        entry={'path':'scripts/game.gd','mode':'100644','git_blob':'1'*40,'sha256':'2'*64,'bytes':100}
        raw=b'100644 blob '+b'1'*40+b'\tscripts/game.gd\0'
        with patch.object(gate,'git',return_value=raw):
            gate.check_snapshot_tree({'head':'a'*40,'files':[entry]},Path('.'),'a'*40,('scripts',))
            for snapshot in ({'head':'b'*40,'files':[entry]}, {'head':'a'*40,'files':[]},
                             {'head':'a'*40,'files':[dict(entry,mode='100755')]}):
                with self.subTest(snapshot=snapshot),self.assertRaises(RuntimeError):
                    gate.check_snapshot_tree(snapshot,Path('.'),'a'*40,('scripts',))


class ReturnAndSaveContracts(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory();self.addCleanup(self.tmp.cleanup);self.folder=Path(self.tmp.name)
        self.tag='c4-final-flutter';self.frames=[]
        for i in (1,2):
            image=Image.new('RGB',(360,640));image.putdata([((x*3)%256,(y*5)%256,((x+y)*7)%256) for y in range(640) for x in range(360)])
            name=f'{self.tag}-return-candidate-{i}.png';image.save(self.folder/name);image.close()
            line={'text':'Spiel pausiert','bounds':[30,100,230,145],'variant':'contrast'}
            dump(self.folder/(Path(name).stem+'-caption-0-ocr.json'),[line])
            self.frames.append({'status':'CONFIRMED_FLUTTER_PIXELS','source':name,'source_sha256':P.sha(self.folder/name),
                'render_readiness':gate.readiness.inspect_flutter_frame(self.folder/name),
                'captions':[{'expected':'Spiel pausiert','ocr':line}]})
        (self.folder/(self.tag+'.png')).write_bytes((self.folder/self.frames[-1]['source']).read_bytes())
        self.report={'status':'PASS','expected_captions':['Spiel pausiert'],'frames':self.frames,
                     'elapsed_seconds':8.0,'consecutive_confirmed_frames':2,'source':self.tag+'.png',
                     'source_sha256':self.frames[-1]['source_sha256']}

    def verify(self):
        dump(self.folder/(self.tag+'-return-pixels.json'),self.report)
        return gate.check_return(self.folder,self.tag)

    def test_both_original_return_pngs_and_caption_bounds_are_rechecked(self):
        self.assertEqual(self.verify()['consecutive_frames'],2)

    def test_original_caption_normalization_preserves_case_and_punctuation_variants(self):
        for frame in self.report['frames']:
            line=frame['captions'][0]['ocr']
            line['text']='SPIEL PAUSIERT!'
            dump(self.folder/(Path(frame['source']).stem+'-caption-0-ocr.json'),[line])
        self.assertEqual(self.verify()['consecutive_frames'],2)

    def test_loading_caption_one_frame_or_extended_deadline_do_not_pass(self):
        baseline=copy.deepcopy(self.report)
        for variant in ('loading','one','deadline'):
            self.report=copy.deepcopy(baseline)
            if variant=='loading':self.report['frames'][-1]['captions'][0]['ocr']['text']='Die Spielwelt wird geöffnet'
            if variant=='one':self.report['frames']=self.report['frames'][:1]
            if variant=='deadline':self.report['elapsed_seconds']=30.01
            with self.subTest(variant=variant),self.assertRaises(RuntimeError):self.verify()

    def test_offscreen_caption_or_absent_original_ocr_is_rejected(self):
        self.report['frames'][-1]['captions'][0]['ocr']['bounds']=[400,0,500,40]
        with self.assertRaisesRegex(RuntimeError,'actual frame'):self.verify()
        self.report['frames'][-1]['captions'][0]['ocr']['bounds']=[30,100,230,145]
        (self.folder/(Path(self.frames[-1]['source']).stem+'-caption-0-ocr.json')).unlink()
        with self.assertRaisesRegex(RuntimeError,'Missing original'):self.verify()

    def test_shared_preferences_duplicate_child_or_non_map_is_rejected(self):
        path=self.folder/'preferences.xml'
        for raw in ('<map><string name="child">a</string><string name="child">b</string></map>',
                    '<unrelated><string name="child">a</string></unrelated>'):
            path.write_text(raw)
            with self.assertRaises(RuntimeError):gate.prefs(path)


if __name__=='__main__':unittest.main()
