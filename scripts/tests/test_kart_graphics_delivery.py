"""Current-version publication contracts using explicitly synthetic APK records."""
from __future__ import annotations

import ast
import copy
import json
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import verify_kart_graphics_delivery as delivery
from verify_legacy_release_pin import APPROVED
import test_nextgen_delivery as previous
import test_nextgen_workflow_contract as previous_workflow
import test_kart_graphics_review as graphics_review_tests
import test_nextgen_2019_review as native_review_tests
import test_studio_delivery as studio_tests


ROOT = Path(__file__).resolve().parents[2]
WORKFLOW = ROOT / '.github/workflows/lumo-kart-graphics-2019.yml'
BRANCH = 'chatgpt/lumo-kart-graphics-apk-20261113'
QA_BRANCH = 'integration/lumo-connections-20261113'


class KartGraphicsDeliveryTests(unittest.TestCase):
    def fixture(self):
        producer = previous.NextgenDeliveryTests()
        self.addCleanup(producer.doCleanups)
        args = producer.proof_fixture()
        args[2] = '0.13.7'
        records = [*args[5:8], args[8]['candidate'],
                   args[9]['steps'][0], args[10]['apk_identity']]
        for record in records:
            record.update(versionCode=2019, versionName='0.13.7')
        return args

    def test_current_android_and_arm64_sources_form_2019_delivery_facts(self):
        facts = delivery.verify_proofs(*self.fixture())
        self.assertEqual((facts['versionName'], facts['versionCode']), ('0.13.7', 2019))
        self.assertEqual(len(facts['cardsFrontFacePixels']['stages']), 4)

    def test_both_actual_arm64_reinspections_must_match_the_native_pck(self):
        for position in (6, 7):
            for digest in ('0' * 64, None):
                args = self.fixture()
                args[position]['godot']['pck_sha256'] = digest
                with self.subTest(position=position, digest=digest), self.assertRaisesRegex(
                        ValueError, 'Actual ARM64 PCK differs'):
                    delivery.verify_proofs(*args)

    def test_old_version_or_mixed_apk_identity_cannot_be_reused(self):
        for position in (5, 6, 7, 'update', 'tour', 'surfaces'):
            args = self.fixture()
            record = (args[position] if isinstance(position, int) else
                      args[8]['candidate'] if position == 'update' else
                      args[9]['steps'][0] if position == 'tour' else args[10]['apk_identity'])
            record['versionCode'] = 2018
            with self.subTest(position=position), self.assertRaises(ValueError):
                delivery.verify_proofs(*args)
        for position, field, value in (
            (5, 'flutter_source_commit', '0' * 40),
            (6, 'signingCertificateSha256', '0' * 64),
            (7, 'sha256', '0' * 64),
            (7, 'abis', ['x86_64']),
        ):
            args = self.fixture()
            args[position][field] = value
            with self.subTest(position=position, field=field), self.assertRaises(ValueError):
                delivery.verify_proofs(*args)

    def test_current_learning_cards_and_host_requirements_remain_mandatory(self):
        for mutation in ('learning', 'speech', 'cards-idle', 'cards-pixels', 'compiled-host', 'offline'):
            args = self.fixture()
            if mutation == 'learning':
                args[10]['learning']['moves']['moved_objects'] = 4
            if mutation == 'speech':
                args[10]['learning']['speech']['result']['completed_utterance_ids'] = []
            if mutation == 'cards-idle':
                args[10]['cards']['visible_idle_seconds'] = 1
            if mutation == 'cards-pixels':
                args[10]['cards']['front_face_pixels'].pop()
            if mutation == 'compiled-host':
                del args[11]['classes']['CardsAuthorityService']
            if mutation == 'offline':
                args[8]['offline'] = False
            with self.subTest(mutation=mutation), self.assertRaises(ValueError):
                delivery.verify_proofs(*args)

    def dual_platform_fixture(self):
        producer = studio_tests.StudioDeliveryTests()
        producer.setUp()
        self.addCleanup(producer.doCleanups)
        return producer.dual_platform_fixture()

    def test_both_actual_android_datasets_and_the_stricter_arm64_pck_checks_are_combined(self):
        args = self.dual_platform_fixture()
        facts = delivery.verify_android_acceptance(*args)
        self.assertEqual([entry['android_runtime']['sdk'] for entry in facts['androidEmulatorAcceptance']],
                         [35, 37])
        self.assertIn('physical Samsung Galaxy Z Fold7', facts['deviceScope'])
        for position in (5, 6, 7):
            changed = copy.deepcopy(args)
            changed[position]['godot']['pck_sha256'] = '0' * 64
            with self.subTest(position=position), self.assertRaises(ValueError):
                delivery.verify_android_acceptance(*changed)

    def test_api35_cannot_substitute_for_missing_wrong_or_failed_android17_evidence(self):
        for mutation in ('missing', 'api35-reused', 'failed', 'other-apk', 'missing-original-png'):
            args = self.dual_platform_fixture()
            path = args[-1] / 'nextgen/native-surfaces-result.json'
            surfaces = json.loads(path.read_text())
            if mutation == 'missing':
                path.unlink()
            else:
                if mutation == 'api35-reused': surfaces['android_runtime']['sdk'] = 35
                if mutation == 'failed': surfaces['status'] = 'FAIL'
                if mutation == 'other-apk': surfaces['apk_identity']['apk_sha256'] = '0' * 64
                if mutation == 'missing-original-png':
                    original = surfaces['cards']['front_face_pixels'][0]['frames'][-1]['source']
                    (args[-1] / 'nextgen' / original).unlink()
                path.write_text(json.dumps(surfaces))
            with self.subTest(mutation=mutation), self.assertRaises(ValueError):
                delivery.verify_android_acceptance(*args)

    def visual_fixture(self):
        graphics = graphics_review_tests.KartGraphicsReviewTests()
        self.addCleanup(graphics.doCleanups)
        root, receipt, native, graphics_proofs = graphics.fixture()
        producer = native_review_tests.Nextgen2019ReviewTests()
        producer.setUp()
        self.addCleanup(producer.doCleanups)
        original = producer.review_fixture()
        self.assertEqual(native, original[2])
        (root / 'config').mkdir()
        (root / 'config/kart-graphics-2019-visual-review.json').write_text(json.dumps(receipt))
        (root / 'config/nextgen-2019-visual-review.json').write_text(json.dumps(original[1]))
        shutil.copytree(original[0] / 'docs/evidence/nextgen-2019-reviewed',
                        root / 'docs/evidence/nextgen-2019-reviewed')
        proofs = graphics_proofs.parent
        native_proofs = proofs / 'native-nextgen'
        native_proofs.mkdir()
        for name, record in zip(('artifact', 'run', 'jobs'), original[3:6]):
            (native_proofs / (name + '.json')).write_text(json.dumps(record))
        shutil.copyfile(original[6], native_proofs / 'native-evidence.zip')
        return root, native, proofs

    def test_publisher_requires_both_four_area_graphics_and_nine_module_native_review(self):
        facts = delivery.verify_visual_acceptance(*self.visual_fixture())
        self.assertEqual(facts['visualReview']['areas'], ['crystal_canyon', 'feedback', 'home', 'winter_sprint'])
        self.assertEqual(set(facts['nativeVisualReview']['modules']),
                         {'learning', 'jump', 'build', 'settlement', 'garage', 'cards', 'rhythm', 'puzzle', 'treasure'})
        self.assertEqual(facts['nativeVisualReview']['native_probe_count'], 41)
        self.assertEqual(facts['nativeVisualReview']['native_village_raster_count'], 4)

    def test_graphics_approval_does_not_cover_missing_puzzle_treasure_village_or_different_native_sha(self):
        for mutation in ('puzzle', 'treasure', 'village', 'other-sha', 'missing-native-receipt', 'missing-native-zip'):
            args = self.visual_fixture()
            path = args[0] / 'config/nextgen-2019-visual-review.json'
            receipt = json.loads(path.read_text())
            if mutation == 'missing-native-receipt':
                path.unlink()
            elif mutation == 'missing-native-zip':
                (args[2] / 'native-nextgen/native-evidence.zip').unlink()
            else:
                if mutation == 'other-sha': receipt['native_revision'] = '0' * 40
                elif mutation == 'village':
                    receipt['images'] = [item for item in receipt['images']
                                         if str(Path(item['artifact_entry']).parent) != native_review_tests.VILLAGE_CAPTURE]
                else: receipt['images'] = [item for item in receipt['images'] if item['module'] != mutation]
                path.write_text(json.dumps(receipt))
            with self.subTest(mutation=mutation), self.assertRaises((ValueError, FileNotFoundError)):
                delivery.verify_visual_acceptance(*args)


class KartGraphicsWorkflowTests(unittest.TestCase):
    def test_only_the_dedicated_producer_and_internal_integration_qa_branches_build(self):
        source = WORKFLOW.read_text()
        triggers = source.split('on:\n', 1)[1].split('\npermissions:', 1)[0]
        self.assertEqual(set(re.findall(r'^  ([a-z_]+):', triggers, re.M)),
                         {'pull_request', 'workflow_dispatch'})
        self.assertIn('group: lumo-kart-graphics-2019-' + '$' + '{{ github.head_ref || github.ref_name }}', source)
        for name in ('android-host-compile', 'verify-and-build'):
            job = source.split('  ' + name + ':\n', 1)[1]
            expression = job.split('    if: >-\n', 1)[1].split('    runs-on:', 1)[0]
            expression = expression.replace('\n', ' ').replace('&&', 'and').replace('||', 'or').strip()
            base = {'github.repository': 'Ullmann27/lumo-lernen',
                    'github.event_name': 'pull_request',
                    'github.event.pull_request.head.repo.full_name': 'Ullmann27/lumo-lernen',
                    'github.head_ref': BRANCH, 'github.ref_name': 'fixture/merge'}
            cases = [({}, True), ({'github.event_name': 'push'}, False),
                     ({'github.head_ref': QA_BRANCH}, True),
                     ({'github.head_ref': 'main'}, False),
                     ({'github.event.pull_request.head.repo.full_name': 'other/fork'}, False),
                     ({'github.head_ref': QA_BRANCH,
                       'github.event.pull_request.head.repo.full_name': 'other/fork'}, False),
                     ({'github.event_name': 'workflow_dispatch', 'github.head_ref': '',
                       'github.ref_name': BRANCH}, True),
                     ({'github.event_name': 'workflow_dispatch', 'github.head_ref': '',
                       'github.ref_name': QA_BRANCH}, True),
                     ({'github.event_name': 'workflow_dispatch', 'github.head_ref': '',
                       'github.ref_name': 'main'}, False)]
            for changes, expected in cases:
                executable = expression
                values = dict(base, **changes)
                for key in sorted(values, key=len, reverse=True):
                    executable = executable.replace(key, repr(values[key]))
                with self.subTest(job=name, changes=changes):
                    self.assertIs(eval(executable, {'__builtins__': {}}, {}), expected)

    def test_old_candidate_is_rejected_and_old_pipeline_cannot_build_2019(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / 'scripts').symlink_to(ROOT / 'scripts', target_is_directory=True)
            (root / 'config').mkdir()
            (root / 'config/godot-source.json').write_text(json.dumps({
                'repository': 'https://github.com/Ullmann27/lumo-godot.git',
                'engine': '4.6.3', 'revision': APPROVED[2018],
            }))
            (root / 'pubspec.yaml').write_text('version: 0.13.6+2018\n')
            result = subprocess.run([sys.executable, '-c', previous_workflow.initial_pincheck(WORKFLOW)],
                                    cwd=root, text=True, capture_output=True, check=False)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn('Kart graphics workflow requires build 2019', result.stderr)
            (root / 'pubspec.yaml').write_text('version: 0.13.7+2019\n')
            result = subprocess.run(
                [sys.executable, '-c', previous_workflow.initial_pincheck(previous_workflow.LEGACY)],
                cwd=root, text=True, capture_output=True, check=False)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn('Build 2019 requires the dedicated Kart graphics workflow', result.stderr)

    def test_all_compile_flutter_native_android_update_and_publication_gates_remain(self):
        source = WORKFLOW.read_text()
        for gate in (
            'bash scripts/compile_android_host.sh', 'flutter pub get --enforce-lockfile',
            'flutter analyze --no-fatal-infos --no-fatal-warnings',
            'python3 scripts/run_full_flutter_acceptance.py',
            'unittest discover -s scripts/tests -v',
            "unittest discover -s tools/android_qa/tests -p 'test_*.py' -v",
            'python3 tools/validate_project.py', 'bash tools/validate_project.sh',
            'bash tools/validate_2014.sh', 'bash tools/validate_technical_art.sh',
            'bash tools/validate_action_stage.sh', 'bash tools/validate_nextgen.sh',
            'bash scripts/build_unified_apk.sh',
            'python .github/probes/modernization_android_tour.py --apk',
            'python .github/probes/lumo_studio_surfaces_android_probe.py --apk',
            'python .github/probes/lumo_2019_update_android_probe.py --baseline',
            "artifact-ids: '13948686178'", 'run-id: 43220602252',
        ):
            with self.subTest(gate=gate):
                self.assertIn(gate, source)
        verifier_job = source.split('  verify-reviewed-2019:\n', 1)[1].split('  publish-reviewed-2019:\n', 1)[0]
        publisher = source.split('  publish-reviewed-2019:\n', 1)[1]
        self.assertIn('needs: [verify-and-build, android-host-compile, android-tour, update-2019-from-2017]', verifier_job)
        self.assertIn('needs: [verify-and-build, android-host-compile, android-tour, update-2019-from-2017, verify-reviewed-2019]', publisher)
        for name in ('verify-and-build', 'android-host-compile', 'android-tour', 'update-2019-from-2017'):
            self.assertIn("needs." + name + ".result == 'success'", verifier_job)
            self.assertIn("needs." + name + ".result == 'success'", publisher)
        verifier = 'python scripts/verify_kart_graphics_delivery.py --source-sha "$SOURCE_SHA"'
        self.assertIn(verifier, verifier_job)
        self.assertIn("needs.verify-reviewed-2019.result == 'success'", publisher)
        self.assertIn('name: lumo-kart-graphics-2019-delivery-verified', verifier_job)
        self.assertIn('name: lumo-kart-graphics-2019-delivery-verified', publisher)
        self.assertLess(publisher.index('Recheck accepted artifact bytes'), publisher.index('gh release create'))
        self.assertIn("facts['flutterSourceCommit'] == os.environ['SOURCE_SHA']", publisher)
        self.assertIn("hashlib.sha256(apk.read_bytes()).hexdigest() == facts['apkSha256']", publisher)
        self.assertIn("Public download bytes differ", publisher)
        self.assertIn('Existing release is preserved.', publisher)
        self.assertIn("ref['object']['sha'] == os.environ['SOURCE_SHA']", publisher)
        self.assertNotIn('--clobber', publisher)

    def test_graphics_metadata_transfer_requires_no_foreign_token_or_graphics_archive_access(self):
        source = WORKFLOW.read_text()
        fetch = source.split('      - name: Fetch public identities', 1)[1].split(
            '      - name: Fetch exact native learning', 1)[0]
        self.assertIn('review_identity(receipt, native)', fetch)
        self.assertIn('config/kart-graphics-2019-visual-review.json', fetch)
        self.assertIn('for area, entry in sorted(artifacts.items())', fetch)
        self.assertIn('"$api/artifacts/$artifact_id"', fetch)
        self.assertNotIn('GH_TOKEN', fetch)
        self.assertNotIn('/zip', fetch)
        self.assertNotIn('nextgen-2018-visual-review', source)

    def test_publisher_downloads_the_exact_native_archive_and_keeps_the_separate_receipt(self):
        source = WORKFLOW.read_text()
        fetch = source.split('      - name: Fetch exact native learning', 1)[1].split(
            '      - name: Reverify actual ARM64 bytes', 1)[0]
        for required in ('config/nextgen-2019-visual-review.json', 'native_workflow_run_id',
                         'native_artifact_id', "receipt.get('native_revision') == native",
                         'native_artifact_sha256', 'proofs/native-nextgen/native-evidence.zip',
                         'integration-evidence-$native-$reviewed_artifact',
                         'https://github.com/Ullmann27/lumo-godot/releases/download/$archive_tag/native-evidence.zip',
                         'sha256sum -c proofs/native-nextgen/archive-sha256.txt',
                         'proofs/native-nextgen/artifact.json', 'proofs/native-nextgen/run.json',
                         'proofs/native-nextgen/jobs.json'):
            with self.subTest(required=required):
                self.assertIn(required, fetch)
        self.assertIn('cp config/nextgen-2019-visual-review.json dist/NATIVE-VISUAL-REVIEW.json', source)

    def test_android17_runs_the_producer_surface_probe_and_has_its_own_original_artifact(self):
        source = WORKFLOW.read_text()
        tour = source.split('  android-tour:\n', 1)[1].split('  update-2019-from-2017:', 1)[0]
        for required in ('fail-fast: false', 'api: [35, 37]', 'api-level: ${{ matrix.api }}',
                         'lumo_studio_surfaces_android_probe.py --apk', '--expected-api ${{ matrix.api }}',
                         'lumo-kart-graphics-2019-android-17-tour', 'lumo-kart-graphics-2019-android-tour'):
            with self.subTest(required=required):
                self.assertIn(required, tour)
        verifier_job = source.split('  verify-reviewed-2019:\n', 1)[1].split('  publish-reviewed-2019:\n', 1)[0]
        self.assertIn('name: lumo-kart-graphics-2019-android-17-tour\n          path: proofs/android17/', verifier_job)

    def test_combined_final_verification_runs_on_integration_without_release_write_access(self):
        verifier_job = WORKFLOW.read_text().split('  verify-reviewed-2019:\n', 1)[1].split(
            '  publish-reviewed-2019:\n', 1)[0]
        expression = verifier_job.split('    if: >-\n', 1)[1].split('    runs-on:', 1)[0]
        expression = expression.replace('\n', ' ').replace('&&', 'and').replace('||', 'or').strip()
        values = {
            'github.event_name': 'pull_request', 'github.repository': 'Ullmann27/lumo-lernen',
            'github.event.pull_request.head.repo.full_name': 'Ullmann27/lumo-lernen',
            'github.event.pull_request.head.ref': QA_BRANCH,
            'needs.verify-and-build.result': 'success', 'needs.android-tour.result': 'success',
            'needs.android-host-compile.result': 'success', 'needs.update-2019-from-2017.result': 'success',
        }

        def allowed(overrides):
            actual = dict(values, **overrides)
            executable = expression
            for key in sorted(actual, key=len, reverse=True):
                executable = executable.replace(key, repr(actual[key]))
            return eval(executable, {'__builtins__': {}}, {})

        for branch in (QA_BRANCH, BRANCH):
            with self.subTest(branch=branch):
                self.assertTrue(allowed({'github.event.pull_request.head.ref': branch}))
        cases = [(key, 'failure') for key in values if key.startswith('needs.')]
        cases.extend([('github.event_name', 'workflow_dispatch'),
                      ('github.repository', 'other/fork'),
                      ('github.event.pull_request.head.ref', 'main'),
                      ('github.event.pull_request.head.repo.full_name', 'other/fork')])
        for key, value in cases:
            with self.subTest(key=key, value=value):
                self.assertFalse(allowed({key: value}))
        self.assertIn('contents: read', verifier_job)
        self.assertNotIn('contents: write', verifier_job)
        self.assertNotIn('gh release', verifier_job)
        self.assertNotIn('GH_TOKEN', verifier_job)
        self.assertIn('name: lumo-2019-reviewed-acceptance-receipt', verifier_job)

    def test_no_failure_manual_run_or_foreign_pr_can_publish(self):
        publisher = WORKFLOW.read_text().split('  publish-reviewed-2019:\n', 1)[1]
        expression = publisher.split('    if: >-\n', 1)[1].split('    runs-on:', 1)[0]
        expression = expression.replace('\n', ' ').replace('&&', 'and').strip()
        values = {
            'github.event_name': 'pull_request', 'github.repository': 'Ullmann27/lumo-lernen',
            'github.event.pull_request.head.repo.full_name': 'Ullmann27/lumo-lernen',
            'github.event.pull_request.head.ref': BRANCH,
            'needs.verify-and-build.result': 'success', 'needs.android-tour.result': 'success',
            'needs.android-host-compile.result': 'success', 'needs.update-2019-from-2017.result': 'success',
            'needs.verify-reviewed-2019.result': 'success',
        }
        positive = expression
        for key in sorted(values, key=len, reverse=True):
            positive = positive.replace(key, repr(values[key]))
        self.assertTrue(eval(positive, {'__builtins__': {}}, {}))
        cases = [(key, 'failure') for key in values if key.startswith('needs.')]
        cases.extend([('github.event_name', 'workflow_dispatch'),
                      ('github.event.pull_request.head.ref', 'main'),
                      ('github.event.pull_request.head.ref', QA_BRANCH),
                      ('github.event.pull_request.head.repo.full_name', 'other/fork')])
        for field, changed in cases:
            executable = expression
            candidate = dict(values, **{field: changed})
            for key in sorted(candidate, key=len, reverse=True):
                executable = executable.replace(key, repr(candidate[key]))
            with self.subTest(field=field, changed=changed):
                self.assertFalse(eval(executable, {'__builtins__': {}}, {}))

    def test_2019_wrapper_uses_explicit_new_opt_in_and_old_surface_default_remains(self):
        update = (ROOT / '.github/probes/lumo_2019_update_android_probe.py').read_text()
        self.assertIn('candidate_version=2019', update)
        self.assertIn('allow_2019_independent_evidence_migration=True', update)
        self.assertNotIn('allow_2018_independent_evidence_migration=True', update)
        surface = ast.parse((ROOT / '.github/probes/lumo_nextgen_surfaces_android_probe.py').read_text())
        main = next(node for node in surface.body if isinstance(node, ast.FunctionDef) and node.name == 'main')
        self.assertEqual(main.args.kwonlyargs[0].arg, 'expected_version')
        self.assertEqual(ast.literal_eval(main.args.kw_defaults[0]), 2018)
        current = (ROOT / '.github/probes/lumo_2019_surfaces_android_probe.py').read_text()
        self.assertIn('main(expected_version=2019)', current)


if __name__ == '__main__':
    unittest.main()
