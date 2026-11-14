"""Execute the proposed source/update contracts; no APK or device is fabricated."""
from __future__ import annotations

import importlib.util
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import textwrap
import unittest
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]
REFERENCE = Path(os.environ.get('LUMO_C4_REFERENCE_HOST', str(ROOT)))
sys.path.insert(0,str(ROOT/'scripts'))
sys.path.insert(0,str(ROOT/'tools/android_qa'))
import verify_connect_four_candidate as final


def job(source,name):
    match=re.search(r'^  '+re.escape(name)+r':\n(.*?)(?=^  [a-z][\w-]*:\n|\Z)',source,re.M|re.S)
    if match is None:
        raise AssertionError('Missing actual workflow job: '+name)
    return match[1]


def step(source,name):
    return source.split('      - name: '+name+'\n',1)[1].split('\n      - ',1)[0]


def condition(source,values):
    text=source.split('    if: >-\n',1)[1].split('    runs-on:',1)[0]
    text=text.replace('\n',' ').replace('&&','and').replace('||','or').strip()
    for key in sorted(values,key=len,reverse=True):
        text=text.replace(key,repr(values[key]))
    return eval(text,{'__builtins__':{}},{})


class WorkflowTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.workflow=(ROOT/'.github/workflows/lumo-connect-four-2020.yml').read_text()

    def test_only_exact_same_repository_c4_pull_request_starts(self):
        values={'github.repository':'Ullmann27/lumo-lernen', 'github.event_name':'pull_request',
                'github.event.pull_request.head.repo.full_name':'Ullmann27/lumo-lernen',
                'github.head_ref':'integration/lumo-c4-connections-20261114'}
        for name in ('connect-four-runtime','android-host-compile','verify-and-build'):
            block=job(self.workflow,name)
            self.assertTrue(condition(block,values))
            self.assertTrue(condition(block,{**values,
                'github.head_ref':'work/lumo-play-quality-20261114'}))
            self.assertTrue(condition(block,{**values,
                'github.head_ref':'integration/lumo-agent-execution-20261114'}))
            self.assertTrue(condition(block,{**values,
                'github.head_ref':'integration/lumo-live-connections-20261114'}))
            for key,value in (('github.event_name','push'),('github.event_name','workflow_dispatch'),
                              ('github.event.pull_request.head.repo.full_name','outside/fork'),
                              ('github.head_ref','integration/lumo-connections-20261113'),
                              ('github.head_ref','integration/lumo-agent-execution-20261114-copy')):
                with self.subTest(job=name,key=key,value=value):
                    self.assertFalse(condition(block,{**values,key:value}))

    def test_source_pin_guard_executes_real_existing_policy(self):
        block=step(job(self.workflow,'connect-four-runtime'),
                   'Bind the approved 2020 host and exact native source')
        code=textwrap.dedent(re.search(r"python3 - <<'PYCODE'\n(.*?)^          PYCODE$",block,re.M|re.S)[1])
        current=json.loads((REFERENCE/'config/godot-source.json').read_text())
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory);(root/'config').mkdir();(root/'scripts').mkdir()
            (root/'scripts/verify_legacy_release_pin.py').write_bytes((REFERENCE/'scripts/verify_legacy_release_pin.py').read_bytes())
            cases=[('version: 0.13.8+2020\n',current,True),
                   ('version: 0.13.8+2020\n',{**current,'revision':'f'*40},False),
                   ('version: 0.13.7+2019\n',current,False)]
            for i,(pubspec,pin,expected) in enumerate(cases):
                (root/'pubspec.yaml').write_text(pubspec)
                (root/'config/godot-source.json').write_text(json.dumps(pin))
                output=root/f'output-{i}'
                env={**os.environ,'GITHUB_OUTPUT':str(output),'PYTHONDONTWRITEBYTECODE':'1'}
                result=subprocess.run([sys.executable,'-c',code],cwd=root,env=env,
                                      capture_output=True,text=True,timeout=20)
                with self.subTest(i=i):
                    self.assertEqual(result.returncode==0,expected,result.stdout+result.stderr)
                    if expected:
                        self.assertEqual(output.read_text(),'revision='+current['revision']+'\n')
                    else:
                        self.assertFalse(output.exists())

    def test_return_recovery_runs_between_import_and_the_two_process_gate(self):
        runtime=job(self.workflow,'connect-four-runtime')
        label='Retry the acknowledged native exit after a transient Android refusal'
        positions=[runtime.index(name) for name in (
            'Import the exact configured native source in its own directory', label,
            'Require the actual production Dart and rendered Godot two-process gate')]
        self.assertEqual(positions,sorted(positions))
        block=step(runtime,label)
        self.assertIn('set -euo pipefail',block)
        self.assertIn('timeout 60s godot --headless --audio-driver Dummy --path native-source '
                      '--script res://scripts/tests/connect_four_return_regression.gd',block)
        self.assertIn('2>&1 | tee c4-runtime/return-recovery.log',block)
        self.assertIn("if grep -En 'ERROR:|SCRIPT ERROR:|Parse Error:' c4-runtime/return-recovery.log; then",block)
        self.assertIn('exit 1',block)
        self.assertIn("grep -Fx 'CONNECT_FOUR_RETURN_PASS checks=21' c4-runtime/return-recovery.log",block)

    def test_real_runtime_compile_and_existing_build_gates_remain_mandatory(self):
        runtime=job(self.workflow,'connect-four-runtime')
        self.assertIn('scripts/run_connect_four_runtime.py --host "$GITHUB_WORKSPACE"',runtime)
        self.assertIn('--native "$GITHUB_WORKSPACE/native-source"',runtime)
        self.assertIn('command -v xvfb-run',runtime)
        self.assertIn('flutter pub get --enforce-lockfile',runtime)
        self.assertIn('cd native-source && timeout 300s godot --headless',runtime)
        self.assertIn("if grep -En 'ERROR:|SCRIPT ERROR:|Parse Error:'",runtime)
        compile=job(self.workflow,'android-host-compile')
        self.assertIn('run: bash scripts/compile_android_host.sh',compile)
        for name in ('ConnectFourGameActivity','ConnectFourAuthorityService','ConnectFourBridge'):
            self.assertIn(name,compile)
        build=job(self.workflow,'verify-and-build')
        self.assertIn('needs: [android-host-compile, connect-four-runtime]',build)
        original=job((REFERENCE/'.github/workflows/lumo-kart-graphics-2019.yml').read_text(),'verify-and-build')
        preserved=(
            'Full Flutter regression suite including every capture',
            'Verify all build and preservation contracts',
            'Code-level Android probe regression with verified image dependencies',
            'Reject unreadable Ahem-font captures before issuing visual proof',
            'Require actual gameplay gates on the exact pinned native source',
            'Build unified real Android APK',
            'Verify APK archive and collect reproducible source hashes')
        for name in preserved:
            expected=step(original,name)
            if name == 'Require actual gameplay gates on the exact pinned native source':
                expected=expected.replace('install -y xvfb libgl1-mesa-dri libglx-mesa0\n',
                                          'install -y xvfb libgl1-mesa-dri libglx-mesa0 ffmpeg\n')
                command='LUMO_NEXTGEN_LOG_DIR="$native_logs/nextgen" bash tools/validate_nextgen.sh'
                self.assertEqual(expected.count(command),1)
                expected=expected.replace(command,
                                          command+' 2>&1 | tee "$native_logs/nextgen-runner.log"')
            with self.subTest(step=name): self.assertEqual(step(build,name),expected)
        self.assertNotIn('continue-on-error',self.workflow)

    def test_both_abis_and_real_android_c4_update_are_bound_to_exact_upload(self):
        build=job(self.workflow,'verify-and-build')
        self.assertIn("LUMO_SPLIT_PER_ABI: '1'",build)
        self.assertIn('${{ steps.upload-candidate.outputs.artifact-id }}',build)
        self.assertIn('${{ steps.upload-candidate.outputs.artifact-digest }}',build)
        android=job(self.workflow,'android-c4')
        self.assertIn('artifact-ids: ${{ needs.verify-and-build.outputs.candidate-artifact-id }}',android)
        self.assertIn('api-level: 35',android)
        script=android.split('          script: |\n',1)[1]
        self.assertLess(script.index('modernization_android_tour.py'),script.index('lumo_connect_four_android_probe.py'))
        for flag in ('--prior-tour tour/main/tour-result.json','--expected-source "$SOURCE_SHA"',
                     '--expected-native "$NATIVE_REVISION"','--artifact-id "$CANDIDATE_ARTIFACT_ID"',
                     '--artifact-digest "$CANDIDATE_ARTIFACT_DIGEST"','--run-attempt "$GITHUB_RUN_ATTEMPT"'):
            self.assertIn(flag,script)
        update=job(self.workflow,'update-2020-from-2017')
        self.assertIn("artifact-ids: '13948686178'",update)
        self.assertIn('run-id: 43220602252',update)
        self.assertIn('lumo_2020_update_android_probe.py --baseline baseline/dist/x86_64/Lumo-Lernen-Neu.apk',update)
        verify=job(self.workflow,'verify-c4-candidate')
        self.assertIn('needs: [verify-and-build, android-host-compile, connect-four-runtime, android-c4, update-2020-from-2017]',verify)
        self.assertIn('scripts/verify_connect_four_candidate.py',verify)
        self.assertNotIn('    if: always()',verify.split('    steps:',1)[0])

    def test_dedicated_2020_delivery_keeps_every_gate_and_no_2019_receipt_path(self):
        names=re.findall(r'^  ([a-z][\w-]*):\s*$',self.workflow.split('jobs:\n',1)[1],re.M)
        self.assertEqual(names,['connect-four-runtime','android-host-compile','verify-and-build',
                                'android-c4','update-2020-from-2017','verify-c4-candidate','prepare-c4-delivery'])
        publisher=job(self.workflow,'prepare-c4-delivery')
        self.assertIn('needs: [verify-and-build, android-host-compile, connect-four-runtime, android-c4, update-2020-from-2017, verify-c4-candidate]',publisher)
        self.assertNotIn('contents: write',self.workflow)
        self.assertIn('contents: read',publisher)
        self.assertIn('scripts/verify_connect_four_delivery.py prepare',publisher)
        for forbidden in ('gh release','workflow_dispatch:','publish-reviewed',
                          'verify_kart_graphics_delivery.py','studio_creative_android_probe.py',
                          'lumo_studio_surfaces_android_probe.py'):
            self.assertNotIn(forbidden,self.workflow)
        self.assertNotIn('27ae4270',self.workflow)

    def test_only_c4_branch_is_added_to_existing_unified_exclusions(self):
        unified=(ROOT/'.github/workflows/lumo-unified-integration-2026.yml').read_text()
        block=job(unified,'verify-and-build')
        c4='integration/lumo-c4-connections-20261114'
        self.assertFalse(condition(block,{'github.head_ref':c4,'github.ref_name':'123/merge'}))
        self.assertFalse(condition(block,{'github.head_ref':'','github.ref_name':c4}))
        quality='work/lumo-play-quality-20261114'
        self.assertFalse(condition(block,{'github.head_ref':quality,'github.ref_name':'123/merge'}))
        self.assertFalse(condition(block,{'github.head_ref':'','github.ref_name':quality}))
        agent='integration/lumo-agent-execution-20261114'
        self.assertFalse(condition(block,{'github.head_ref':agent,'github.ref_name':'123/merge'}))
        self.assertFalse(condition(block,{'github.head_ref':'','github.ref_name':agent}))
        live='integration/lumo-live-connections-20261114'
        self.assertFalse(condition(block,{'github.head_ref':live,'github.ref_name':'123/merge'}))
        self.assertFalse(condition(block,{'github.head_ref':'','github.ref_name':live}))
        self.assertTrue(condition(block,{'github.head_ref':'unrelated-existing-branch','github.ref_name':'123/merge'}))
        self.assertIn("assert int(version[1]) != 2018",block)
        self.assertIn("assert int(version[1]) != 2019",block)


class OriginalUpdateReplayTests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory();self.addCleanup(self.temp.cleanup)
        self.root=Path(self.temp.name)
        path=REFERENCE/'tools/android_qa/tests/test_update_preservation.py'
        spec=importlib.util.spec_from_file_location('c4_existing_update_fixture',path)
        legacy=importlib.util.module_from_spec(spec);spec.loader.exec_module(legacy)
        fixture=legacy.Build2018IndependentEvidenceMigrationTests();fixture.setUp()
        before,after=fixture.before,fixture.after
        for name,value in [('before-update',before),*[(n,after) for n in
                            ('after-update','after-kart','after-restart','fold-cover','fold-open','fold-landscape')]]:
            tree=ET.Element('map')
            for key,text in value.items(): ET.SubElement(tree,'string',{'name':key}).text=text
            (self.root/(name+'-preferences.xml')).write_bytes(ET.tostring(tree))
        identity={'userId':'10123','firstInstallTime':'synthetic-install-time','versionCode':'2017 minSdk=24'}
        for name,version in (('baseline',2017),('updated',2020)):
            # Current Android dumps need not contain userId; the original
            # PackageManager list/UID file is the production source of truth.
            (self.root/(name+'-package.txt')).write_text('  firstInstallTime=synthetic-install-time\n'
                                                    +'  versionCode='+str(version)+' minSdk=24\n')
            (self.root/(name+'-package-uid.txt')).write_text('package:'+final.c4.PACKAGE+' uid:10123\n')
        source='a'*40
        self.candidate={'sha256':'a'*64,'godot':{'revision':'b'*40,'pck_sha256':'c'*64}}
        later=final.require_post_update_learning_preserved(before,after,after,migration_versions=(2017,2020))
        self.report={'status':'PASS','offline':True,'fatal_crashes':0,'candidate_source':source,
              'baseline':{'versionCode':2017,'flutter_source_commit':'47889f74a651b073965def70743417cf320b1eb9',
                          'godot':{'revision':'1d5c5cb45a323228f627ec529e6ff1ddd86f1c57'}},
              'candidate':{**self.candidate,'versionCode':2020,'flutter_source_commit':source,
                           'signingCertificateSha256':final.c4.CERT},
              'after_update':final.require_learning_preserved(before,after,migration_versions=(2017,2020)),
              'after_kart':later,'after_restart':later,
              'fold':{name:later for name in ('cover','open','landscape')},
              'installation':final.require_in_place_update(identity,{**identity,'versionCode':'2020 minSdk=24'},2020),
              'native_tour':{name:{'synthetic':True} for name in ('race','hud','drive','pause','return')},
              'learning_journey':{'status':'PASS'},'onboarding':{'status':'PASS'}}
        self.write_report()
        (self.root/'fatal-logcat.txt').write_text('')

    def write_report(self):
        (self.root/'update-result.json').write_text(json.dumps(self.report))

    def test_existing_migration_and_all_actual_snapshot_contracts_are_replayed(self):
        result=final.update_proof(self.root,self.candidate,'a'*40)
        self.assertEqual((result['from_version'],result['to_version']),(2017,2020))

    def test_missing_restart_original_cannot_be_hidden_by_pass_report(self):
        (self.root/'after-restart-preferences.xml').unlink()
        with self.assertRaises(FileNotFoundError): final.update_proof(self.root,self.candidate,'a'*40)

    def test_different_uid_version_or_apk_is_rejected(self):
        for field,value in (('sha256','d'*64),('versionCode',2019)):
            original=self.report['candidate'][field]
            self.report['candidate'][field]=value;self.write_report()
            with self.subTest(field=field),self.assertRaises(ValueError):
                final.update_proof(self.root,self.candidate,'a'*40)
            self.report['candidate'][field]=original
        self.write_report()
        (self.root/'updated-package-uid.txt').write_text('package:'+final.c4.PACKAGE+' uid:10999\n')
        with self.assertRaises(RuntimeError): final.update_proof(self.root,self.candidate,'a'*40)


if __name__=='__main__':
    unittest.main()
