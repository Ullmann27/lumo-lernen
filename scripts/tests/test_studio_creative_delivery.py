"""Offline parser/workflow counterexamples; these fixtures are not device evidence."""
import copy
import hashlib
import importlib.util
import json
from pathlib import Path
import re
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location('creative_delivery', ROOT / 'scripts/verify_studio_creative_android.py')
delivery = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(delivery)


def write(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value))


class CreativeDeliveryTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix='creative-proof-parser-')
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.tour = self.root / 'tour'
        self.tour.mkdir()
        self.expected = {'host_source': 'a' * 40, 'native_source': 'b' * 40,
                         'build_run': 100, 'artifact_id': 200, 'artifact_digest': 'sha256:' + 'c' * 64}
        run = {'id': 100, 'head_sha': 'a' * 40, 'path': '.github/workflows/lumo-studio-2019.yml',
               'repository': {'full_name': 'Ullmann27/lumo-lernen'}}
        artifact = {'id': 200, 'name': delivery.creative.ARTIFACT, 'digest': 'sha256:' + 'c' * 64,
                    'size_in_bytes': 1234, 'expired': False, 'workflow_run': {'id': 100, 'head_sha': 'a' * 40}}
        jobs = {'jobs': [{'id': 300, 'name': 'verify-and-build', 'conclusion': 'success',
                          'status': 'completed', 'run_id': 100, 'head_sha': 'a' * 40}]}
        for name, data in (('run.json', run), ('artifacts.json', {'artifacts': [artifact]}), ('jobs.json', jobs)):
            write(self.root / 'metadata' / name, data)
        binding = delivery.creative.verify_candidate_metadata(run, {'artifacts': [artifact]}, jobs, self.expected)
        write(self.root / 'candidate-artifact-binding.json', binding)
        identity = {'apk_sha256': 'd' * 64, 'flutter_source_commit': 'a' * 40,
                    'godot_revision': 'b' * 40, 'godot_pck_sha256': 'e' * 64,
                    'versionName': '0.13.7', 'versionCode': 2019,
                    'signingCertificateSha256': 'f' * 64,
                    'checks': {key: True for key in (
                        'sha256_matches_provenance', 'sha256_matches_build_sums',
                        'flutter_source_is_this_commit', 'tracked_source_clean',
                        'godot_revision_is_pinned', 'signing_certificate',
                        'version_matches_pubspec', 'x86_64_native_code')}}
        self.main = {'status': 'PASS', 'apk_sha256': identity['apk_sha256'],
                     'steps': [{'step': 'apk-identity', 'ok': True, **identity}]}
        samples = []
        for index in range(4):
            # Synthetic byte-hash inputs; no Android recording/decoding claim.
            name = f'synthetic-action-{index}.png'
            data = ('synthetic parser media ' + str(index)).encode()
            (self.tour / name).write_bytes(data)
            samples.append({'file': name, 'sha256': hashlib.sha256(data).hexdigest()})
        video = b'synthetic parser video bytes, never a gameplay recording'
        (self.tour / 'synthetic.mp4').write_bytes(video)
        (self.tour / 'jump-full-decode.log').write_bytes(b'')
        write(self.tour / 'native-engine-errors.json', [])
        self.report = {
            'status': 'RECORDED_REVIEW_REQUIRED', 'host_source': 'a' * 40,
            'native_source': 'b' * 40, 'probe_source': 'a' * 40, 'probe_sha256': '0' * 64,
            'build_run': 100, 'candidate_binding': binding, 'apk_identity': identity,
            'direct_apk_pck_read': {'sha256': 'e' * 64, 'bytes': 123},
            'runtime': {'sdk': '35', 'release': '15', 'model': 'Synthetic parser fixture',
                        'fingerprint': 'synthetic/parser/only'}, 'offline': True, 'fatal_crashes': 0,
            'games': {
                'jump': {'status': 'INPUTS_RECORDED_SAVE_RESUMED', 'fully_decoded': True,
                         'checkpoint_resume': True, 'visual_motion_review': 'REQUIRED',
                         'video': 'synthetic.mp4', 'sha256': hashlib.sha256(video).hexdigest(),
                         'samples': samples, 'separate_pointer_actions': [
                             {'type': kind, 'duration_ms': duration} for kind, duration in (
                                 ('separate-stick', 350), ('separate-stick', 350),
                                 ('short-jump', 80), ('held-jump', 650))]},
                'build': {'status': 'PASS', 'durable_resume': True, 'undo_exact_pieces': True,
                          'redo_exact_pieces': True, 'added_piece': {'part': 'sand'}},
                'puzzle': {'status': 'PASS', 'durable_resume': True, 'menu_count_touches': 4,
                           'menu_mode_touches': 3, 'actual_rotation': {'piece_id': 0}},
                'treasure': {'status': 'PASS', 'durable_resume': True, 'first_clue': 'tree',
                             'visible_inventory': 'Blattschlüssel',
                             'actual_saved_position_series': [[0, 0, 6], [-12, 0, -8]]}}}

    def verify(self, report=None):
        write(self.tour / 'creative-result.json', self.report if report is None else report)
        return delivery.verify(self.root, self.expected, self.main, '0' * 64)

    def test_current_technical_contract_does_not_become_visual_approval(self):
        original = copy.deepcopy(self.report)
        facts = self.verify()
        self.assertEqual(self.report, original)
        self.assertEqual(facts['status'], 'FUNCTIONAL_CONTRACTS_PASSED_VISUAL_REVIEW_PENDING')
        self.assertEqual(facts['visual_motion_review'], 'REQUIRED')
        self.assertEqual(set(facts['game_contracts']), {'jump', 'build', 'puzzle', 'treasure'})

    def test_source_probe_run_and_current_upload_cannot_be_reused_from_another_candidate(self):
        for field, value in (('host_source', '9' * 40), ('native_source', '9' * 40),
                             ('probe_source', '9' * 40), ('probe_sha256', '9' * 64),
                             ('build_run', 99), ('status', 'PASS')):
            report = copy.deepcopy(self.report)
            report[field] = value
            with self.subTest(field=field), self.assertRaises(RuntimeError):
                self.verify(report)
        for field, value in (('artifact_id', 199), ('artifact_digest', 'sha256:' + '9' * 64)):
            old = self.expected[field]
            self.expected[field] = value
            with self.subTest(field=field), self.assertRaises(RuntimeError):
                self.verify()
            self.expected[field] = old

    def test_wrong_apk_pck_runtime_identity_or_crashes_are_rejected(self):
        for group, key, value in (
                ('apk_identity', 'apk_sha256', '9' * 64),
                ('apk_identity', 'signingCertificateSha256', '9' * 64),
                ('direct_apk_pck_read', 'sha256', '9' * 64),
                ('runtime', 'sdk', '37'), ('runtime', 'release', '14'), ('runtime', 'fingerprint', '')):
            report = copy.deepcopy(self.report)
            report[group][key] = value
            with self.subTest(group=group, key=key), self.assertRaises(RuntimeError):
                self.verify(report)
        for field, value in (('offline', False), ('fatal_crashes', 1)):
            with self.subTest(field=field), self.assertRaises(RuntimeError):
                self.verify({**self.report, field: value})
        report = copy.deepcopy(self.report)
        report['apk_identity']['checks']['tracked_source_clean'] = False
        with self.assertRaises(RuntimeError):
            self.verify(report)
        write(self.tour / 'native-engine-errors.json', ['Synthetic engine error counterexample'])
        with self.assertRaises(RuntimeError):
            self.verify()

    def test_each_game_and_real_save_contract_remains_mandatory(self):
        for game in self.report['games']:
            report = copy.deepcopy(self.report)
            del report['games'][game]
            with self.subTest(missing=game), self.assertRaises(RuntimeError):
                self.verify(report)
        for game, key, value in (
                ('jump', 'checkpoint_resume', False), ('jump', 'fully_decoded', False),
                ('jump', 'visual_motion_review', 'APPROVED'), ('jump', 'separate_pointer_actions', []),
                ('build', 'undo_exact_pieces', False), ('build', 'redo_exact_pieces', False),
                ('puzzle', 'actual_rotation', None), ('puzzle', 'menu_count_touches', 0),
                ('treasure', 'first_clue', None), ('treasure', 'durable_resume', False)):
            report = copy.deepcopy(self.report)
            report['games'][game][key] = value
            with self.subTest(game=game, key=key), self.assertRaises(RuntimeError):
                self.verify(report)

    def test_media_bytes_decode_log_and_original_frame_presence_are_enforced(self):
        for name in ['synthetic.mp4'] + [row['file'] for row in self.report['games']['jump']['samples']]:
            path = self.tour / name
            original = path.read_bytes()
            path.write_bytes(original + b' changed')
            with self.subTest(name=name), self.assertRaises(RuntimeError):
                self.verify()
            path.write_bytes(original)
        (self.tour / 'jump-full-decode.log').write_text('Synthetic decode error')
        with self.assertRaises(RuntimeError):
            self.verify()

    def test_new_job_uses_only_current_build_outputs_and_current_checkout(self):
        text = (ROOT / '.github/workflows/lumo-studio-2019.yml').read_text()
        build = text.split('  verify-and-build:\n', 1)[1].split('  android-tour:\n', 1)[0]
        job = text.split('  creative-android:\n', 1)[1].split('  publish-reviewed-2019:\n', 1)[0]
        self.assertIn('id: upload-candidate', build)
        for field in ('artifact-id', 'artifact-digest'):
            self.assertIn('${{ steps.upload-candidate.outputs.' + field + ' }}', build)
            self.assertIn('${{ needs.verify-and-build.outputs.candidate-' + field + ' }}', job)
        self.assertIn('needs: [verify-and-build, android-host-compile]', job)
        self.assertIn('ref: ${{ github.event.pull_request.head.sha || github.sha }}', job)
        self.assertIn('ref: ${{ steps.native-pin.outputs.revision }}', job)
        self.assertIn('artifact-ids: ${{ needs.verify-and-build.outputs.candidate-artifact-id }}', job)
        self.assertIn('merge-multiple: true\n          path: candidate/dist/', job)
        self.assertNotIn('run-id:', job)
        self.assertNotIn('continue-on-error', job)
        self.assertNotIn('31883868', job)
        self.assertIn('--build-run "$GITHUB_RUN_ID"', job)
        self.assertIn('--metadata-dir creative/metadata', job)
        self.assertIn('if: always()', job)
        self.assertIn('name: lumo-studio-2019-creative-android', job)

    def test_publisher_cannot_run_without_the_extra_job_and_its_bound_evidence(self):
        text = (ROOT / '.github/workflows/lumo-studio-2019.yml').read_text()
        publisher = text.split('  publish-reviewed-2019:\n', 1)[1]
        gates = ['verify-and-build', 'android-host-compile', 'android-tour',
                 'update-2019-from-2017', 'creative-android']
        self.assertEqual(re.search(r'^    needs: \[(.*?)\]$', publisher, re.M)[1], ', '.join(gates))
        expression = publisher.split('    if: >-\n', 1)[1].split('    runs-on:', 1)[0]
        values = {'github.event_name': 'pull_request', 'github.repository': 'Ullmann27/lumo-lernen',
                  'github.event.pull_request.head.repo.full_name': 'Ullmann27/lumo-lernen',
                  'github.event.pull_request.head.ref': 'chatgpt/lumo-studio-20261113',
                  **{'needs.' + gate + '.result': 'success' for gate in gates}}
        for changed in [None] + gates:
            for state in (['success'] if changed is None else ['failure', 'skipped', 'cancelled']):
                current = dict(values)
                if changed:
                    current['needs.' + changed + '.result'] = state
                executable = expression.replace('\n', ' ').replace('&&', 'and').strip()
                for key in sorted(current, key=len, reverse=True):
                    executable = executable.replace(key, repr(current[key]))
                with self.subTest(gate=changed, state=state):
                    self.assertEqual(eval(executable, {'__builtins__': {}}, {}), changed is None)
        invocation = 'scripts/verify_studio_creative_android.py --source-sha "$SOURCE_SHA"'
        self.assertLess(publisher.index('path: proofs/creative/'), publisher.index(invocation))
        self.assertLess(publisher.index(invocation), publisher.index('gh release create'))
        self.assertIn('--artifact-id "$CANDIDATE_ARTIFACT_ID"', publisher)
        self.assertIn('--main-tour proofs/tour/tour-result.json', publisher)
        self.assertIn('dist/CREATIVE-ANDROID-FACTS.json \\', publisher)


if __name__ == '__main__':
    unittest.main()
