"""Synthetic original-archive contracts; no renderer or visual approval is claimed."""
from __future__ import annotations

import copy
from functools import lru_cache
import hashlib
from io import BytesIO
import json
from pathlib import Path
import sys
import tempfile
import unittest
import zipfile

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
sys.path.insert(0, str(Path(__file__).resolve().parent))
import record_studio_visual_review as recorder
import test_nextgen_delivery as historical_tests
import test_studio_delivery as studio_tests
import verify_studio_delivery as delivery


PROFILE = 'nextgen-2019'
VILLAGE_CAPTURE = 'nextgen-evidence/nextgen/captures/build_village_scene_regression'
VILLAGE_PNGS = {
    'captures/build_village_scene_regression/village-overview-1280x720.png': (1280, 720),
    'captures/build_village_scene_regression/village-chapters-412x915.png': (412, 915),
    'captures/build_village_scene_regression/village-trader-2176x1812.png': (2176, 1812),
    'captures/build_village_scene_regression/village-treasury-640x360.png': (640, 360),
}
VILLAGE_PROBES = frozenset({
    ('build_village_economy_regression', 'headless'),
    ('build_village_art_regression', 'headless'),
    ('build_village_scene_regression', 'headless'),
    ('build_village_scene_regression', 'rendered'),
})


@lru_cache(maxsize=128)
def fixture_png(width, height, color):
    """Reuse deterministic synthetic PNG bytes, never production images."""
    return historical_tests.fixture_png(width, height, color)


@lru_cache(maxsize=8)
def village_fixture_png(width, height, color):
    """Two-color parser input, never a production scene or visual finding."""
    from PIL import Image
    image = Image.new('RGB', (width, height), (color, 20, 30))
    image.paste((20, color, 160), (width // 2, 0, width, height))
    output = BytesIO()
    image.save(output, format='PNG')
    return output.getvalue()


class Nextgen2019ReviewTests(unittest.TestCase):
    archive_change = staticmethod(studio_tests.StudioDeliveryTests.archive_change)
    selection = staticmethod(studio_tests.StudioDeliveryTests.selection)

    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix='nextgen-2019-review-unit-')
        self.addCleanup(temporary.cleanup)
        self.base = Path(temporary.name)

    def review_fixture(self):
        base = Path(tempfile.mkdtemp(dir=self.base))
        root, native, tree = base / 'images', 'b' * 40, 'c' * 40
        profile = delivery.native_review_profile(PROFILE)
        prefix = delivery.NEXTGEN_PREFIX
        members = {
            prefix + '/source-sha.txt': (native + '\n').encode(),
            prefix + '/source-tree.txt': (tree + '\n').encode(),
            prefix + '/source-dirty.txt': b'',
            prefix + '/engine.txt': b'4.6.3.stable.synthetic-parser-fixture\n',
            prefix + '/results.tsv': ('probe\tmode\tresult\n' + ''.join(
                f'{probe}\t{mode}\tPASS\n'
                for probe, mode in sorted(delivery.NEXTGEN_REQUIRED_PROBES))).encode(),
        }
        roster = []
        for index, relative in enumerate(sorted(delivery.NEXTGEN_STUDIO_PNGS)):
            dimensions = (412, 915) if '412x915' in relative else (640, 360)
            data = fixture_png(*dimensions, index + 10)
            members[prefix + '/' + relative] = data
            roster.append({'path': relative, 'bytes': len(data),
                           'sha256': hashlib.sha256(data).hexdigest(),
                           'width': dimensions[0], 'height': dimensions[1]})
        members[prefix + '/renderer-images.json'] = json.dumps({'images': roster}).encode()
        village_roster = []
        for index, (relative, dimensions) in enumerate(sorted(VILLAGE_PNGS.items())):
            data = village_fixture_png(*dimensions, index + 180)
            members[prefix + '/' + relative] = data
            village_roster.append({'path': relative, 'bytes': len(data),
                                   'sha256': hashlib.sha256(data).hexdigest(),
                                   'width': dimensions[0], 'height': dimensions[1]})
        members[prefix + '/village-images.json'] = json.dumps({'images': village_roster}).encode()
        color = 50
        for touch_prefix, probe in delivery.NEXTGEN_TOUCH_PROBES.items():
            members.update({
                touch_prefix + '/source-sha.txt': (native + '\n').encode(),
                touch_prefix + '/source-tree.txt': (tree + '\n').encode(),
                touch_prefix + '/source-dirty.txt': b'',
                touch_prefix + '/source-dirty-after.txt': b'',
                touch_prefix + '/engine.txt': b'4.6.3.stable.synthetic-parser-fixture\n',
                touch_prefix + '/results.tsv': (
                    f'probe\tmode\tresult\n{probe}\theadless\tPASS\n{probe}\trendered\tPASS\n').encode(),
            })
            touch_roster = []
            for relative, dimensions in sorted(delivery.NEXTGEN_TOUCH_PNGS[touch_prefix].items()):
                data = fixture_png(*dimensions, color)
                color += 1
                members[touch_prefix + '/' + relative] = data
                touch_roster.append({'path': relative, 'bytes': len(data),
                                     'sha256': hashlib.sha256(data).hexdigest(),
                                     'width': dimensions[0], 'height': dimensions[1]})
            members[touch_prefix + '/renderer-images.json'] = json.dumps({'images': touch_roster}).encode()
        receipt = {
            'schema': 1, 'status': 'approved', 'versionCode': 2019, 'native_profile': PROFILE,
            'native_revision': native, 'native_workflow_run_id': 100, 'native_artifact_id': 200,
            'reviewed_by': 'Synthetic unit-test reviewer',
            'reviewed_at': '2026-11-13T00:00:00+00:00',
            'notes': 'Synthetic parser fixture, never renderer or visual acceptance', 'images': [],
        }
        for index, (probe, module) in enumerate(sorted(profile.capture_modules.items())):
            existing = sorted(name for name in members if name.startswith(probe + '/') and name.endswith('.png'))
            entry = existing[0] if existing else probe + '/actual.png'
            if not existing:
                dimensions = (412, 915) if module == 'learning' else (640, 360)
                members[entry] = fixture_png(*dimensions, index + 100)
            data = members[entry]
            digest = hashlib.sha256(data).hexdigest()
            relative = delivery.reviewed_relative_path(digest, module, entry, native_profile=PROFILE)
            path = root / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(data)
            receipt['images'].append({
                'path': relative, 'module': module, 'artifact_entry': entry,
                'dimensions': delivery.png_dimensions(data), 'sha256': digest,
                'findings': 'Synthetic original-image parser fixture only',
            })
        archive = base / 'native-fixture.zip'
        with zipfile.ZipFile(archive, 'w') as zipped:
            for name, data in members.items():
                zipped.writestr(name, data)
        digest = hashlib.sha256(archive.read_bytes()).hexdigest()
        receipt['native_artifact_sha256'] = digest
        artifact = {'id': 200, 'name': profile.artifact, 'expired': False, 'digest': 'sha256:' + digest,
                    'workflow_run': {'id': 100, 'head_sha': native}}
        run = {'id': 100, 'head_sha': native, 'path': profile.workflow, 'status': 'completed',
               'conclusion': 'success', 'head_commit': {'id': native, 'tree_id': tree}}
        jobs = {'jobs': [{'name': name, 'run_id': 100, 'head_sha': native,
                          'status': 'completed', 'conclusion': 'success'}
                         for name in sorted(profile.jobs)]}
        return [root, receipt, native, artifact, run, jobs, archive]

    def verify(self, args):
        return delivery.verify_visual_review(*args, native_profile=PROFILE)

    def record(self, args, root=None, selection=None):
        return recorder.record_review(
            root or self.base / 'recorded', args[6], args[3], args[4], args[5],
            self.selection(args) if selection is None else selection,
            'Synthetic unit-test reviewer', 'Synthetic parser test; never production approval',
            native_profile=PROFILE)

    def test_exact_combined_archive_keeps_41_core_24_studio_4_village_and_all_touch_evidence(self):
        args = self.review_fixture()
        before = copy.deepcopy(args[:6]), args[6].read_bytes()
        facts = self.verify(args)
        self.assertEqual(facts['modules'], sorted(delivery.REVIEW_MODULES))
        self.assertEqual(facts['native_acceptance_jobs'], [
            'bundle-evidence', 'gameplay', 'learning-preview', 'new-worlds',
            'touch-build', 'touch-treasure', 'touch-workshop'])
        self.assertEqual(facts['native_probe_count'], 41)
        self.assertEqual(facts['native_studio_raster_count'], 24)
        self.assertEqual(facts['native_village_raster_count'], 4)
        self.assertEqual(facts['reviewed_village_capture_probes'], [VILLAGE_CAPTURE])
        self.assertEqual(dict(delivery.NEXTGEN_VILLAGE_PNGS), VILLAGE_PNGS)
        self.assertTrue(VILLAGE_PROBES.issubset(delivery.NEXTGEN_REQUIRED_PROBES))
        self.assertEqual(facts['native_capture_tree'], 'c' * 40)
        self.assertEqual(facts['native_capture_sources'], {
            'nextgen-evidence/nextgen': args[2], 'touch-evidence/workshop': args[2],
            'touch-evidence/treasure': args[2], 'touch-evidence/build': args[2]})
        self.assertEqual(facts['native_touch_capture_trees'], {
            'touch-evidence/workshop': 'c' * 40, 'touch-evidence/treasure': 'c' * 40,
            'touch-evidence/build': 'c' * 40})
        self.assertEqual(facts['native_touch_probe_count'], 6)
        self.assertEqual(facts['native_touch_raster_count'], 32)
        self.assertEqual(set(facts['reviewed_touch_capture_probes']), delivery.TOUCH_CAPTURE_PROBES)
        self.assertEqual((args[:6], args[6].read_bytes()), before)

    def test_legacy_37_gate_results_cannot_satisfy_the_additional_village_contract(self):
        args = self.review_fixture()
        key = delivery.NEXTGEN_PREFIX + '/results.tsv'
        with zipfile.ZipFile(args[6]) as zipped:
            rows = zipped.read(key).decode().splitlines()
        rows = [row for row in rows if tuple(row.split('\t')[:2]) not in VILLAGE_PROBES]
        self.assertEqual(len(rows), 38, 'The previously accepted 37-pair result is retained as a negative fixture')
        self.archive_change(args, {key: ('\n'.join(rows) + '\n').encode()})
        with self.assertRaisesRegex(ValueError, '41-probe'):
            self.verify(args)

    def test_existing_nine_modules_do_not_replace_the_additional_village_review(self):
        args = self.review_fixture()
        args[1]['images'] = [item for item in args[1]['images']
                             if str(Path(item['artifact_entry']).parent) != VILLAGE_CAPTURE]
        self.assertEqual({item['module'] for item in args[1]['images']}, delivery.REVIEW_MODULES)
        with self.assertRaisesRegex(ValueError, 'current Village production capture'):
            self.verify(args)
        destination = self.base / 'missing-village-review'
        with self.assertRaisesRegex(ValueError, 'current Village production capture'):
            self.record(args, destination)
        self.assertFalse(destination.exists(), 'Missing Village review must not publish any receipt or PNG')

    def test_each_original_village_image_is_required_even_when_not_selected_for_review(self):
        for relative in VILLAGE_PNGS:
            args = self.review_fixture()
            self.archive_change(args, {delivery.NEXTGEN_PREFIX + '/' + relative: None})
            with self.subTest(image=relative), self.assertRaises(ValueError):
                self.verify(args)

    def test_village_roster_rejects_missing_duplicate_corrupt_uniform_and_wrong_sized_originals(self):
        prefix = delivery.NEXTGEN_PREFIX
        for mutation in ('missing-roster', 'short-roster', 'duplicate', 'renamed', 'digest',
                         'bytes', 'metadata-size', 'pixel-size', 'truncated', 'uniform',
                         'transparent', 'extra-png'):
            args = self.review_fixture()
            key = prefix + '/village-images.json'
            with zipfile.ZipFile(args[6]) as zipped:
                roster = json.loads(zipped.read(key))
                item = roster['images'][0]
                original = zipped.read(prefix + '/' + item['path'])
            changes = {}
            if mutation == 'missing-roster': changes[key] = None
            if mutation == 'short-roster': roster['images'].pop()
            if mutation == 'duplicate': roster['images'][-1] = copy.deepcopy(item)
            if mutation == 'renamed': item['path'] = item['path'].replace('.png', '-invented.png')
            if mutation == 'digest': item['sha256'] = '0' * 64
            if mutation == 'bytes': item['bytes'] += 1
            if mutation == 'metadata-size': item['width'] += 1
            data = None
            if mutation == 'pixel-size':
                data = village_fixture_png(640, 360, 230)
                item['width'], item['height'] = 640, 360
            if mutation == 'truncated': data = original[:40]
            if mutation == 'uniform': data = fixture_png(item['width'], item['height'], 230)
            if mutation == 'transparent':
                from PIL import Image
                output = BytesIO()
                Image.new('RGBA', (item['width'], item['height']), (200, 40, 90, 0)).save(output, format='PNG')
                data = output.getvalue()
            if data is not None:
                changes[prefix + '/' + item['path']] = data
                item['bytes'], item['sha256'] = len(data), hashlib.sha256(data).hexdigest()
            if mutation == 'extra-png': changes[VILLAGE_CAPTURE + '/unrequested.png'] = original
            if mutation != 'missing-roster': changes[key] = json.dumps(roster).encode()
            self.archive_change(args, changes)
            with self.subTest(mutation=mutation), self.assertRaises(ValueError):
                self.verify(args)

    def test_village_capture_does_not_extend_the_producer_studio_default(self):
        entry = VILLAGE_CAPTURE + '/village-overview-1280x720.png'
        with self.assertRaises(ValueError):
            delivery.reviewed_relative_path('a' * 64, 'settlement', entry)
        with self.assertRaises(ValueError):
            delivery.reviewed_relative_path('a' * 64, 'build', entry, native_profile=PROFILE)

    def test_existing_module_review_never_replaces_any_repaired_touch_surface(self):
        for probe in sorted(delivery.TOUCH_CAPTURE_PROBES):
            args = self.review_fixture()
            args[1]['images'] = [item for item in args[1]['images']
                                 if str(Path(item['artifact_entry']).parent) != probe]
            self.assertEqual({item['module'] for item in args[1]['images']}, delivery.REVIEW_MODULES)
            with self.subTest(probe=probe), self.assertRaisesRegex(ValueError, 'current workshop, treasure and build'):
                self.verify(args)
            destination = self.base / ('missing-touch-' + Path(probe).name)
            with self.assertRaisesRegex(ValueError, 'current workshop, treasure and build'):
                self.record(args, destination)
            self.assertFalse(destination.exists(), 'No failed touch review may leave an approved receipt or PNG')

    def test_each_independent_touch_source_must_match_and_remain_clean(self):
        for prefix in delivery.NEXTGEN_TOUCH_PROBES:
            for relative, value in (
                ('source-sha.txt', b'0' * 40), ('source-sha.txt', None),
                ('source-tree.txt', b'0' * 40), ('source-tree.txt', None),
                ('source-dirty.txt', b' M scripts/changed.gd\n'), ('source-dirty.txt', None),
                ('source-dirty-after.txt', b' M scripts/changed.gd\n'), ('source-dirty-after.txt', None),
                ('engine.txt', b'4.5.stable.wrong\n'),
            ):
                args = self.review_fixture()
                self.archive_change(args, {prefix + '/' + relative: value})
                with self.subTest(prefix=prefix, relative=relative, value=value), self.assertRaises(ValueError):
                    self.verify(args)

    def test_every_touch_probe_requires_both_original_modes_once(self):
        for prefix, probe in delivery.NEXTGEN_TOUCH_PROBES.items():
            for mutation in ('missing-results', 'headless-only', 'rendered-only', 'duplicate', 'wrong-probe', 'failed'):
                args = self.review_fixture()
                rows = ['probe\tmode\tresult', f'{probe}\theadless\tPASS', f'{probe}\trendered\tPASS']
                if mutation == 'headless-only': rows.pop()
                if mutation == 'rendered-only': rows.pop(1)
                if mutation == 'duplicate': rows[2] = rows[1]
                if mutation == 'wrong-probe': rows[2] = 'invented_regression\trendered\tPASS'
                if mutation == 'failed': rows[2] = f'{probe}\trendered\tFAIL'
                value = None if mutation == 'missing-results' else ('\n'.join(rows) + '\n').encode()
                self.archive_change(args, {prefix + '/results.tsv': value})
                with self.subTest(prefix=prefix, mutation=mutation), self.assertRaises(ValueError):
                    self.verify(args)

    def test_all_32_original_touch_rasters_have_fixed_paths_pixels_and_digests(self):
        self.assertEqual({prefix: len(images) for prefix, images in delivery.NEXTGEN_TOUCH_PNGS.items()}, {
            'touch-evidence/workshop': 6, 'touch-evidence/treasure': 14, 'touch-evidence/build': 12})
        goal_images = {
            'captures/build_dialog_density_regression/build-dialog-2400x1080-current-goal.png': (2400, 1080),
            'captures/build_dialog_density_regression/build-dialog-1080x2400-current-goal.png': (1080, 2400),
            'captures/build_dialog_density_regression/build-dialog-2176x1812-current-goal.png': (2176, 1812),
            'captures/build_dialog_density_regression/build-dialog-640x360-current-goal.png': (640, 360),
        }
        self.assertEqual({path: size for path, size in delivery.NEXTGEN_TOUCH_PNGS[
            'touch-evidence/build'].items() if path.endswith('-current-goal.png')}, goal_images)
        for prefix in delivery.NEXTGEN_TOUCH_PROBES:
            for mutation in ('missing-roster', 'missing-png', 'short', 'duplicate', 'renamed',
                             'digest', 'bytes', 'dimensions', 'substituted-size', 'corrupt-unreviewed'):
                args = self.review_fixture()
                key = prefix + '/renderer-images.json'
                with zipfile.ZipFile(args[6]) as zipped:
                    roster = json.loads(zipped.read(key))
                changes, item = {}, roster['images'][0]
                if mutation == 'missing-png': changes[prefix + '/' + item['path']] = None
                if mutation == 'short': roster['images'].pop()
                if mutation == 'duplicate': roster['images'][-1] = copy.deepcopy(item)
                if mutation == 'renamed': item['path'] = item['path'].replace('.png', '-invented.png')
                if mutation == 'digest': item['sha256'] = '0' * 64
                if mutation == 'bytes': item['bytes'] += 1
                if mutation == 'dimensions': item['width'] += 1
                if mutation == 'substituted-size':
                    data = fixture_png(640, 360, 230)
                    changes[prefix + '/' + item['path']] = data
                    item.update(width=640, height=360, bytes=len(data), sha256=hashlib.sha256(data).hexdigest())
                if mutation == 'corrupt-unreviewed':
                    reviewed = {image['artifact_entry'] for image in args[1]['images']}
                    item = next(row for row in roster['images'] if prefix + '/' + row['path'] not in reviewed)
                    entry = prefix + '/' + item['path']
                    with zipfile.ZipFile(args[6]) as zipped:
                        data = zipped.read(entry)[:40]
                    changes[entry] = data
                    item.update(bytes=len(data), sha256=hashlib.sha256(data).hexdigest())
                changes[key] = None if mutation == 'missing-roster' else json.dumps(roster).encode()
                self.archive_change(args, changes)
                with self.subTest(prefix=prefix, mutation=mutation), self.assertRaises(ValueError):
                    self.verify(args)

        prefix = 'touch-evidence/build'
        for missing in ('historical-eight-build-images', *goal_images):
            args = self.review_fixture()
            key = prefix + '/renderer-images.json'
            with zipfile.ZipFile(args[6]) as zipped:
                roster = json.loads(zipped.read(key))
            if missing == 'historical-eight-build-images':
                changes = {prefix + '/' + path: None for path in goal_images}
                roster['images'] = [item for item in roster['images']
                                    if item['path'] not in goal_images]
                self.assertEqual(len(roster['images']), 8)
                changes[key] = json.dumps(roster).encode()
            else:
                # Retain the complete declared roster and all other bytes so
                # each new original must actually exist inside the ZIP.
                changes = {prefix + '/' + missing: None}
            self.archive_change(args, changes)
            with self.subTest(missing=missing), self.assertRaises(ValueError) as caught:
                self.verify(args)
            if missing == 'historical-eight-build-images':
                self.assertIn('complete original touch raster roster', str(caught.exception))
            else:
                self.assertIn(missing, str(caught.exception))

    def test_every_touch_job_and_bundle_is_required_at_the_same_source_and_run(self):
        original = self.review_fixture()
        for name in ('touch-workshop', 'touch-treasure', 'touch-build', 'bundle-evidence'):
            for mutation in ('missing', 'duplicate', 'source', 'run', 'failed'):
                args = copy.deepcopy(original)
                jobs = args[5]['jobs']
                job = next(item for item in jobs if item['name'] == name)
                if mutation == 'missing': jobs.remove(job)
                if mutation == 'duplicate': jobs.append(copy.deepcopy(job))
                if mutation == 'source': job['head_sha'] = '0' * 40
                if mutation == 'run': job['run_id'] = 99
                if mutation == 'failed': job['conclusion'] = 'failure'
                with self.subTest(name=name, mutation=mutation), self.assertRaises(ValueError):
                    self.verify(args)

    def test_missing_puzzle_or_treasure_review_fails_even_with_all_24_original_rasters(self):
        for module in ('puzzle', 'treasure'):
            args = self.review_fixture()
            args[1]['images'] = [item for item in args[1]['images'] if item['module'] != module]
            with self.subTest(module=module), self.assertRaisesRegex(ValueError, 'all nine'):
                self.verify(args)
            destination = self.base / ('missing-' + module)
            with self.assertRaisesRegex(ValueError, 'all nine'):
                self.record(args, destination)
            self.assertFalse(destination.exists(), 'Failed approval must not write any destination files')

    def test_original_nextgen_source_tree_and_clean_stamp_are_mandatory(self):
        prefix = delivery.NEXTGEN_PREFIX
        for relative, value in (
            ('source-sha.txt', b'0' * 40), ('source-sha.txt', None),
            ('source-dirty.txt', b' M scripts/changed.gd\n'), ('source-dirty.txt', None),
            ('source-tree.txt', b'0' * 40), ('source-tree.txt', None),
            ('engine.txt', b'4.5.stable.wrong\n'),
        ):
            args = self.review_fixture()
            self.archive_change(args, {prefix + '/' + relative: value})
            with self.subTest(relative=relative, value=value), self.assertRaises(ValueError):
                self.verify(args)

    def test_other_sha_job_run_workflow_or_profile_cannot_be_relabelled(self):
        original = self.review_fixture()
        for mutation in ('receipt-source', 'artifact-source', 'workflow-source', 'job-source',
                         'job-run', 'missing-job', 'duplicate-job', 'failed-job', 'tree',
                         'studio-artifact', 'studio-workflow', 'profile', 'version', 'date'):
            args = copy.deepcopy(original)
            receipt, artifact, run, jobs = args[1], args[3], args[4], args[5]['jobs']
            if mutation == 'receipt-source': receipt['native_revision'] = '0' * 40
            if mutation == 'artifact-source': artifact['workflow_run']['head_sha'] = '0' * 40
            if mutation == 'workflow-source': run['head_sha'] = '0' * 40
            if mutation == 'job-source': jobs[0]['head_sha'] = '0' * 40
            if mutation == 'job-run': jobs[0]['run_id'] = 99
            if mutation == 'missing-job': jobs.pop()
            if mutation == 'duplicate-job': jobs.append(copy.deepcopy(jobs[0]))
            if mutation == 'failed-job': jobs[0]['conclusion'] = 'failure'
            if mutation == 'tree': run['head_commit']['tree_id'] = '0' * 40
            if mutation == 'studio-artifact': artifact['name'] = delivery.NATIVE_ARTIFACT
            if mutation == 'studio-workflow': run['path'] = delivery.NATIVE_WORKFLOW
            if mutation == 'profile': receipt.pop('native_profile')
            if mutation == 'version': receipt['versionCode'] = 2018
            if mutation == 'date': receipt['reviewed_at'] = '2026-11-13T00:00:00'
            with self.subTest(mutation=mutation), self.assertRaises(ValueError):
                self.verify(args)

    def test_each_of_the_41_probe_modes_must_be_present_once_and_pass(self):
        for mutation in ('old-32-probe-run', 'missing-treasure', 'missing-village-headless',
                         'missing-village-rendered', 'duplicate', 'wrong-mode', 'failed'):
            args = self.review_fixture()
            key = delivery.NEXTGEN_PREFIX + '/results.tsv'
            with zipfile.ZipFile(args[6]) as zipped:
                rows = zipped.read(key).decode().splitlines()
            if mutation == 'old-32-probe-run': rows = rows[:33]
            if mutation == 'missing-treasure': rows.remove('treasure_exploration_regression\trendered\tPASS')
            if mutation == 'missing-village-headless':
                rows = [row for row in rows if row != 'build_village_scene_regression\theadless\tPASS']
            if mutation == 'missing-village-rendered':
                rows = [row for row in rows if row != 'build_village_scene_regression\trendered\tPASS']
            if mutation == 'duplicate': rows.append(rows[-1])
            if mutation == 'wrong-mode': rows[1] = rows[1].replace('\theadless\t', '\trendered\t')
            if mutation == 'failed': rows[1] = rows[1].replace('\tPASS', '\tFAIL')
            self.archive_change(args, {key: ('\n'.join(rows) + '\n').encode()})
            with self.subTest(mutation=mutation), self.assertRaises(ValueError):
                self.verify(args)

    def test_complete_raster_roster_cannot_hide_missing_renamed_or_corrupt_originals(self):
        prefix = delivery.NEXTGEN_PREFIX
        for mutation in ('missing-puzzle', 'missing-treasure', 'missing-motion', 'missing-roster',
                         'short-roster', 'duplicate-roster', 'renamed-roster', 'wrong-digest', 'wrong-bytes',
                         'wrong-dimensions', 'corrupt-unreviewed-pose'):
            args = self.review_fixture()
            key = prefix + '/renderer-images.json'
            with zipfile.ZipFile(args[6]) as zipped:
                roster = json.loads(zipped.read(key))
            changes = {}
            names = {
                'missing-puzzle': 'captures/puzzle_rotation_regression/puzzle_rotation_hint.png',
                'missing-treasure': 'captures/treasure_exploration_regression/treasure_route_complete.png',
                'missing-motion': 'captures/lumo_studio_motion_capture/before_walk.png',
            }
            if mutation in names: changes[prefix + '/' + names[mutation]] = None
            if mutation == 'missing-roster': changes[key] = None
            if mutation == 'short-roster': roster['images'].pop()
            if mutation == 'duplicate-roster': roster['images'][-1] = copy.deepcopy(roster['images'][0])
            if mutation == 'renamed-roster': roster['images'][0]['path'] = 'captures/puzzle_rotation_regression/invented.png'
            if mutation == 'wrong-digest': roster['images'][0]['sha256'] = '0' * 64
            if mutation == 'wrong-bytes': roster['images'][0]['bytes'] += 1
            if mutation == 'wrong-dimensions': roster['images'][0]['width'] += 1
            if mutation == 'corrupt-unreviewed-pose':
                item = next(row for row in roster['images'] if row['path'].endswith('/before_walk.png'))
                entry = prefix + '/' + item['path']
                with zipfile.ZipFile(args[6]) as zipped:
                    data = zipped.read(entry)[:40]
                changes[entry] = data
                item['sha256'], item['bytes'] = hashlib.sha256(data).hexdigest(), len(data)
            if mutation != 'missing-roster': changes[key] = json.dumps(roster).encode()
            self.archive_change(args, changes)
            with self.subTest(mutation=mutation), self.assertRaises(ValueError):
                self.verify(args)

    def test_pose_capture_or_wrong_module_never_replaces_production_scene(self):
        for entry, module in (
            ('nextgen-evidence/nextgen/captures/lumo_studio_motion_capture/after_walk.png', 'jump'),
            ('nextgen-evidence/nextgen/captures/puzzle_rotation_regression/puzzle_rotation_table.png', 'treasure'),
            ('studio-evidence/captures/treasure_exploration_regression/treasure_choose_route.png', 'treasure'),
        ):
            with self.subTest(entry=entry, module=module), self.assertRaises(ValueError):
                delivery.reviewed_relative_path('a' * 64, module, entry, native_profile=PROFILE)
        with self.assertRaisesRegex(ValueError, 'Unknown fixed'):
            delivery.native_review_profile({'artifact': 'arbitrary-caller-choice'})

    def test_downloaded_zip_is_rehashed_and_committed_pngs_must_match_original_members(self):
        args = self.review_fixture()
        args[6].write_bytes(args[6].read_bytes() + b'changed-after-review')
        with self.assertRaisesRegex(ValueError, 'archive digest differs'):
            self.verify(args)
        args = self.review_fixture()
        item = args[1]['images'][0]
        (args[0] / item['path']).write_bytes(b'not-original-pixels')
        with self.assertRaisesRegex(ValueError, 'bytes changed'):
            self.verify(args)

    def test_explicit_nextgen_recorder_preserves_historical_2018_and_studio_paths(self):
        args = self.review_fixture()
        root = self.base / 'recorded'
        historical = root / 'config/nextgen-2018-visual-review.json'
        historical.parent.mkdir(parents=True)
        historical.write_bytes(b'Historical receipt sentinel, not test approval\n')
        historical_bytes = historical.read_bytes()
        original_zip = args[6].read_bytes()
        receipt = self.record(args, root)
        self.assertEqual(receipt['native_profile'], PROFILE)
        self.assertEqual(historical.read_bytes(), historical_bytes)
        self.assertEqual(args[6].read_bytes(), original_zip)
        self.assertFalse((root / delivery.REVIEW_RECEIPT).exists())
        self.assertFalse((root / delivery.REVIEW_DIRECTORY).exists())
        self.assertTrue((root / 'config/nextgen-2019-visual-review.json').is_file())
        self.verify([root, receipt, *args[2:]])


if __name__ == '__main__':
    unittest.main()
