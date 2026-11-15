"""Synthetic rejection cases for the new release identity, never device proof."""
import copy
import json
from pathlib import Path
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / 'tools/android_qa'))
sys.path.insert(0, str(ROOT / 'scripts'))
import connect_four_android_evidence as c4
from integrated_candidate_profile import candidate_scope, PREFIX, BRANCH, WORKFLOW
from integrated_candidate_evidence import checked_android
from update_preservation import reviewed_migration_versions, require_learning_preserved
import test_update_preservation as historical


class IntegratedIdentityTests(unittest.TestCase):
    def metadata(self, current):
        source = 'a' * 40
        run = {'id': 123, 'run_attempt': 1, 'head_sha': source,
               'head_branch': BRANCH if current else c4.BRANCH,
               'event': 'pull_request',
               'path': WORKFLOW if current else c4.WORKFLOW,
               'repository': {'full_name': 'Ullmann27/lumo-lernen'}}
        artifacts = {'artifacts': [{
            'name': PREFIX+'-candidate' if current else c4.CANDIDATE,
            'id': 321, 'digest': 'sha256:'+'c'*64, 'expired': False,
            'size_in_bytes': 1024, 'workflow_run': {'id': 123, 'head_sha': source}}]}
        jobs = {'jobs': [{'name': name, 'run_id': 123, 'head_sha': source,
                         'run_attempt': 1, 'conclusion': 'success'}
                        for name in ('android-host-compile', 'connect-four-runtime', 'verify-and-build')]}
        return run, artifacts, jobs

    def bind(self, metadata):
        return c4.artifact_binding(*metadata, source='a'*40, native='b'*40,
                                  run_id=123, attempt=1, artifact_id=321,
                                  digest='c'*64, version_name='0.13.9')

    def test_old_artifacts_cannot_be_relabelled_as_the_integrated_release(self):
        old = self.metadata(False)
        with candidate_scope():
            with self.assertRaises(ValueError):
                self.bind(old)
            forged = copy.deepcopy(old)
            forged[0].update(head_branch=BRANCH, path=WORKFLOW)
            with self.assertRaises(ValueError):
                self.bind(forged)
            current = self.bind(self.metadata(True))
            self.assertEqual(current['versionCode'], 2021)
            self.assertEqual(c4.NATIVE_ENTRY_LABEL, 'In 3D weiterspielen')

    def test_scope_restores_historical_contracts_even_after_an_error(self):
        import verify_connect_four_delivery as delivery
        before = (c4.VERSION_CODE, c4.WORKFLOW, c4.CANDIDATE,
                  delivery.VERSION_CODE, delivery.REQUIRED_STEPS, delivery.ARTIFACT_NAMES)
        with self.assertRaisesRegex(RuntimeError, 'synthetic failure'):
            with candidate_scope(delivery=True):
                self.assertEqual(delivery.VERSION_CODE, 2021)
                for activity in ('english', 'memory', 'quiz'):
                    self.assertIn('Nextgen '+activity+' actual authority', delivery.REQUIRED_STEPS)
                self.assertIn('UPDATE-2021-RESULT.json', delivery.DELIVERY_ASSETS)
                self.assertNotIn('UPDATE-2020-RESULT.json', delivery.DELIVERY_ASSETS)
                raise RuntimeError('synthetic failure')
        self.assertEqual(before, (c4.VERSION_CODE, c4.WORKFLOW, c4.CANDIDATE,
                                 delivery.VERSION_CODE, delivery.REQUIRED_STEPS, delivery.ARTIFACT_NAMES))

    def test_2021_migration_cannot_use_any_previous_opt_in(self):
        self.assertIsNone(reviewed_migration_versions(2017, 2021))
        self.assertEqual(reviewed_migration_versions(2017, 2021, allow_2021=True), (2017, 2021))
        for pair, flags in (((2017, 2020), {'allow_2021': True}),
                            ((2017, 2021), {'allow_2020': True}),
                            ((2017, 2021), {'allow_2021': True, 'allow_2020': True}),
                            ((2017, 2021), {'allow_2021': 1})):
            with self.subTest(pair=pair, flags=flags), self.assertRaises(RuntimeError):
                reviewed_migration_versions(*pair, **flags)

    def test_current_android_binary_and_both_source_snapshots_remain_mandatory(self):
        source, native, digest = 'a'*40, 'b'*40, 'c'*64
        apk = {'sha256': digest, 'versionName': '0.13.9',
               'godot': {'pck_sha256': 'd'*64}, 'signingCertificateSha256': c4.CERT}
        identity = {'apk_sha256': digest, 'flutter_source_commit': source,
                    'godot_revision': native, 'godot_pck_sha256': 'd'*64,
                    'versionCode': 2021, 'versionName': '0.13.9',
                    'signingCertificateSha256': c4.CERT}
        binding = {'host': source, 'native': native, 'apk': identity,
                   'installed_apk_sha256': digest, 'source_hashes': {'probe.py': 'e'*64}}
        report = {'status': 'PASS', 'source_binding': binding, 'android_runtime': {'sdk': 35},
                  'fatal_crashes': 0, 'not_tested': ['Synthetic fixture; no actual device'],
                  'transitions': ['synthetic'], 'same_actual_task_returned': True,
                  'no_answer_or_mastery_submitted': True}
        with tempfile.TemporaryDirectory() as temporary:
            folder = Path(temporary)
            def write():
                for name, value in [('result.json', report), ('binding-before.json', binding),
                                    ('binding-after.json', binding)]:
                    (folder/name).write_text(json.dumps(value))
            write()
            self.assertIn('result', checked_android(folder, 'english', source, native, apk))
            for old in (2020, 2019):
                identity['versionCode'] = old
                write()
                with self.assertRaisesRegex(ValueError, 'another signed APK'):
                    checked_android(folder, 'english', source, native, apk)
            identity['versionCode'] = 2021
            write()
            (folder/'binding-after.json').write_text(json.dumps(dict(binding, native='f'*40)))
            with self.assertRaisesRegex(ValueError, 'changed during'):
                checked_android(folder, 'english', source, native, apk)

    def test_current_workflow_keeps_every_inherited_gate_and_adds_three_authorities(self):
        import yaml
        import verify_connect_four_delivery as delivery
        workflow = yaml.safe_load((ROOT/WORKFLOW).read_text())
        jobs = workflow['jobs']
        self.assertIn('nextgen-authorities', jobs['verify-and-build']['needs'])
        self.assertEqual(jobs['nextgen-authorities']['strategy']['matrix']['activity'],
                         ['english', 'quiz', 'memory'])
        with candidate_scope(delivery=True):
            for name, steps in delivery.REQUIRED_STEPS.items():
                job = jobs['nextgen-authorities'] if name.startswith('Nextgen ') else jobs[name]
                actual = [step.get('name') for step in job['steps']]
                for label in steps:
                    self.assertEqual(actual.count(label), 1, name+': '+label)
        runtime = next(step for step in jobs['android-c4']['steps']
                       if step.get('name') == 'Install and tour the exact APK')['with']['script']
        for activity in ('quiz', 'memory', 'english_objects'):
            self.assertIn('lumo_'+activity+'_android_probe.py', runtime)
        self.assertIn('lumo_integrated_android_probe.py --game c4', runtime)
        self.assertIn('lumo_integrated_android_probe.py --game village', runtime)
        self.assertNotIn('lumo_2020_update_android_probe.py', (ROOT/WORKFLOW).read_text())


class Build2021LearningPreservationTests(historical.Build2018IndependentEvidenceMigrationTests):
    def require(self, after=None, before=None, versions=(2017, 2021)):
        return require_learning_preserved(self.before if before is None else before,
                                         self.after if after is None else after,
                                         migration_versions=versions)


if __name__ == '__main__':
    unittest.main()
