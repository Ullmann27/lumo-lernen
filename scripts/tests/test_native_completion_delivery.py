"""Synthetic Host delivery counterexamples, never engine or Android evidence.

Village PNG fixtures undergo real Pillow decoding. The existing connection
tests independently replay the pinned Live and Discovery helper boundaries.
"""
from __future__ import annotations

import copy
import hashlib
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest import mock

from PIL import Image, ImageDraw, PngImagePlugin, UnidentifiedImageError

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'scripts'))
import verify_connect_four_delivery as delivery


REVISION = 'a' * 40
TREE = 'b' * 40
SHA256 = 'c' * 64
VILLAGE_MARKERS = {
    'economy.log': '[VillageEconomy] PASS 339 checks',
    'scaling-headless.log': '[VillageScaling] PASS 42 checks: full 2178-house model, camera and explorer',
    'scaling-rendered.log': '[VillageScaling] PASS 46 checks: full 2178-house model, camera and explorer',
}
CAMERAS = ('01-home-region.png', '02-river-boundary.png')
ROSTERS = (
    'renderer-images.json', 'village-images.json', 'puzzle-menu-images.json',
    'safe-area-images.json', 'studio-2020-images.json',
)
HELPERS = (
    'validate_live_connections.sh', 'validate_discovery_connections.sh',
    'verify_discovery_rasters.py',
)
POST_PASS_ERRORS = (
    'SCRIPT ERROR: failure after the apparent success marker',
    'Parse Error: broken native script',
    'ERROR: native resource failed',
    'Assertion failed: required invariant',
    'WARNING: ObjectDB instances leaked at exit',
    'WARNING: 2 resources still in use at exit',
)


def synthetic_completion_facts(revision=REVISION, tree=TREE):
    """Complete transport shape only; these records prove no native execution."""
    def record():
        return {'bytes': 42, 'sha256': SHA256}

    connections = {'pinned_helpers': {name: record() for name in HELPERS}}
    for kind, probes, pngs in (('live', 9, 7), ('discovery', 10, 38)):
        connections[kind] = {
            'source': revision, 'tree': tree,
            'probe_count': probes, 'png_count': pngs,
            'manifest': record(), 'runner': record(),
            'probes': [
                {'path': kind + '/synthetic-' + str(index) + '.log',
                 'marker': '[Synthetic] PASS ' + str(index), **record()}
                for index in range(probes)
            ],
            'captures': {
                'captures/synthetic-' + str(index) + '.png': record()
                for index in range(pngs)
            },
        }
    return {
        'source': revision, 'tree': tree, 'core_modes': 52,
        'mode_logs': [
            {'path': 'synthetic-core-' + str(index) + '.log', **record()}
            for index in range(52)
        ],
        'complete_runner_log': record(),
        'original_rosters': {name: record() for name in ROSTERS},
        'connections': connections,
        'village_completion': {
            'source': revision, 'tree': tree,
            'physical_android_fps_measured': False,
            'mode_logs': [
                {'path': name, 'marker': marker, **record()}
                for name, marker in VILLAGE_MARKERS.items()
            ],
            'original_pngs': [
                {'path': 'captures/' + name, 'width': 1280, 'height': 720, **record()}
                for name in CAMERAS
            ],
        },
    }


class VillageCompletionTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        (self.root / 'source-sha.txt').write_text(REVISION + '\n')
        (self.root / 'source-tree.txt').write_text(TREE + '\n')
        for name, marker in VILLAGE_MARKERS.items():
            (self.root / name).write_text(marker + '\n')
        self.captures = self.root / 'captures'
        self.captures.mkdir()
        for index, name in enumerate(CAMERAS):
            self.image(self.captures / name, index)

    @staticmethod
    def image(path, variant=0, size=(1280, 720), image_format='PNG'):
        with Image.new('RGB', size, (15, 35, 65)) as image:
            draw = ImageDraw.Draw(image)
            draw.rectangle((50 + variant * 100, 30, 330 + variant * 100, 400), fill=(210, 130, 70))
            draw.line((0, size[1] - 1, size[0] - 1, 0), fill=(30, 200, 80), width=15)
            image.save(path, format=image_format)

    def check(self):
        return delivery.checked_village_completion(self.root, REVISION, TREE)

    def test_two_distinct_real_png_decodes_have_exact_source_and_desktop_scope(self):
        result = self.check()
        self.assertEqual((result['source'], result['tree']), (REVISION, TREE))
        self.assertEqual(len(result['mode_logs']), 3)
        self.assertEqual({row['path'] for row in result['original_pngs']},
                         {'captures/' + name for name in CAMERAS})
        self.assertIs(result['physical_android_fps_measured'], False)
        for row in result['original_pngs']:
            self.assertEqual((row['width'], row['height']), (1280, 720))
            self.assertEqual(row['sha256'], hashlib.sha256((self.root / row['path']).read_bytes()).hexdigest())

    def test_missing_or_wrong_native_source_and_tree_are_rejected(self):
        for name in ('source-sha.txt', 'source-tree.txt'):
            path = self.root / name
            original = path.read_bytes()
            for value in (None, '', 'd' * 40):
                with self.subTest(name=name, value=value):
                    if value is None:
                        path.unlink()
                    else:
                        path.write_text(value + '\n')
                    with self.assertRaises(ValueError):
                        self.check()
                    path.write_bytes(original)

    def test_each_economy_and_scaling_log_must_have_the_exact_success_line(self):
        for name in VILLAGE_MARKERS:
            path = self.root / name
            original = path.read_text()
            path.unlink()
            with self.subTest(name=name, missing=True), self.assertRaises(ValueError):
                self.check()
            path.write_text('prefix ' + original)
            with self.subTest(name=name, incomplete_marker=True), self.assertRaises(ValueError):
                self.check()
            path.write_text(original)

    def test_success_does_not_override_later_engine_errors_leaks_or_explicit_failure(self):
        errors = POST_PASS_ERRORS + ('[VillageScaling] FAIL after PASS', '[VillageEconomy] FAIL after PASS')
        for name in VILLAGE_MARKERS:
            path = self.root / name
            original = path.read_text()
            for error in errors:
                with self.subTest(name=name, error=error):
                    path.write_text(original + error + '\n')
                    with self.assertRaises(ValueError):
                        self.check()
            path.write_text(original)

    def test_missing_extra_or_symlinked_camera_image_is_rejected(self):
        first = self.captures / CAMERAS[0]
        original = first.read_bytes()
        first.unlink()
        with self.assertRaises(ValueError):
            self.check()
        first.write_bytes(original)
        extra = self.captures / 'unrequested.png'
        extra.write_bytes(original)
        with self.assertRaises(ValueError):
            self.check()
        extra.unlink()
        first.unlink()
        first.symlink_to(self.captures / CAMERAS[1])
        with self.assertRaisesRegex(ValueError, 'Original regular file required'):
            self.check()

    def test_uniform_png_and_identical_pixels_with_different_file_hashes_fail(self):
        second = self.captures / CAMERAS[1]
        with Image.new('RGB', (1280, 720), (80, 110, 140)) as uniform:
            uniform.save(second)
        with self.assertRaisesRegex(ValueError, 'uniform'):
            self.check()
        first = self.captures / CAMERAS[0]
        metadata = PngImagePlugin.PngInfo()
        metadata.add_text('fixture', 'same pixels, different PNG bytes')
        with Image.open(first) as image:
            image.save(second, pnginfo=metadata)
        self.assertNotEqual(first.read_bytes(), second.read_bytes())
        with self.assertRaisesRegex(ValueError, 'unchanged renderer image'):
            self.check()

    def test_wrong_dimensions_non_png_and_corrupt_png_require_real_pillow_decode(self):
        first = self.captures / CAMERAS[0]
        for size, image_format in (((640, 360), 'PNG'), ((1280, 720), 'JPEG')):
            with self.subTest(size=size, image_format=image_format):
                self.image(first, size=size, image_format=image_format)
                with self.assertRaisesRegex(ValueError, 'dimensions/format'):
                    self.check()
        first.write_bytes(b'\x89PNG\r\n\x1a\nnot a decodable image')
        with self.assertRaises((UnidentifiedImageError, OSError)):
            self.check()


class PreparedCompletionFactsTests(unittest.TestCase):
    def check(self, facts):
        return delivery.checked_completion_facts(facts, REVISION)

    @staticmethod
    def at(facts, path):
        for name in path:
            facts = facts[name]
        return facts

    def test_complete_current_core_connections_and_village_shape_is_accepted(self):
        self.assertIsNone(self.check(synthetic_completion_facts()))

    def test_missing_completion_branches_and_wrong_native_source_or_tree_fail(self):
        branches = (('connections',), ('connections', 'live'),
                    ('connections', 'discovery'), ('village_completion',))
        for path in branches:
            facts = synthetic_completion_facts()
            self.at(facts, path[:-1]).pop(path[-1])
            with self.subTest(missing=path), self.assertRaises(ValueError):
                self.check(facts)
        for path in ((), *branches[1:]):
            for field, value in (('source', None), ('source', 'd' * 40),
                                 ('tree', None), ('tree', 'invalid-tree')):
                facts = synthetic_completion_facts()
                target = self.at(facts, path)
                if value is None:
                    target.pop(field)
                else:
                    target[field] = value
                with self.subTest(path=path, field=field, value=value), self.assertRaises(ValueError):
                    self.check(facts)

    def test_counts_require_integers_and_the_full_52_9_7_10_38_rosters(self):
        fields = [((), 'core_modes', 52)]
        for kind, probes, pngs in (('live', 9, 7), ('discovery', 10, 38)):
            fields += [(('connections', kind), 'probe_count', probes),
                       (('connections', kind), 'png_count', pngs)]
        for path, field, count in fields:
            for value in (None, True, float(count), count - 1):
                facts = synthetic_completion_facts()
                self.at(facts, path)[field] = value
                with self.subTest(path=path, field=field, value=value), self.assertRaises(ValueError):
                    self.check(facts)

    def test_every_required_log_and_png_record_must_be_unique_complete_and_hashed(self):
        rows_at = (
            ('mode_logs',), ('connections', 'live', 'probes'),
            ('connections', 'discovery', 'probes'),
            ('village_completion', 'mode_logs'), ('village_completion', 'original_pngs'),
        )
        for path in rows_at:
            for mutation in ('missing', 'duplicate', 'empty_path', 'bad_hash', 'boolean_bytes'):
                facts = synthetic_completion_facts()
                rows = self.at(facts, path)
                if mutation == 'missing':
                    rows.pop()
                elif mutation == 'duplicate':
                    rows[-1] = copy.deepcopy(rows[0])
                elif mutation == 'empty_path':
                    rows[0]['path'] = ''
                elif mutation == 'bad_hash':
                    rows[0]['sha256'] = True
                else:
                    rows[0]['bytes'] = True
                with self.subTest(path=path, mutation=mutation), self.assertRaises(ValueError):
                    self.check(facts)

    def test_all_five_original_rosters_and_three_pinned_helpers_remain_mandatory(self):
        for path in (('original_rosters',), ('connections', 'pinned_helpers')):
            for mutation in ('absent', 'missing_entry', 'renamed_entry', 'invalid_record'):
                facts = synthetic_completion_facts()
                parent = self.at(facts, path[:-1])
                rows = parent[path[-1]]
                name = next(iter(rows))
                if mutation == 'absent':
                    parent.pop(path[-1])
                elif mutation == 'missing_entry':
                    rows.pop(name)
                elif mutation == 'renamed_entry':
                    rows['unrelated.py'] = rows.pop(name)
                else:
                    rows[name]['bytes'] = True
                with self.subTest(path=path, mutation=mutation), self.assertRaises(ValueError):
                    self.check(facts)

    def test_missing_manifest_runner_and_invalid_records_are_rejected(self):
        fields = [('complete_runner_log',)]
        for kind in ('live', 'discovery'):
            fields += [('connections', kind, 'manifest'), ('connections', kind, 'runner')]
        for path in fields:
            for value in (None, {'bytes': True, 'sha256': SHA256},
                          {'bytes': 0, 'sha256': SHA256}, {'bytes': 1, 'sha256': 'z' * 64}):
                facts = synthetic_completion_facts()
                self.at(facts, path[:-1])[path[-1]] = value
                with self.subTest(path=path, value=value), self.assertRaises(ValueError):
                    self.check(facts)

    def test_connection_logs_keep_their_scope_and_nonempty_recorded_marker(self):
        for kind in ('live', 'discovery'):
            for field, value in (('path', 'outside.log'), ('path', kind + '/probe.json'),
                                 ('marker', None), ('marker', '')):
                facts = synthetic_completion_facts()
                facts['connections'][kind]['probes'][0][field] = value
                with self.subTest(kind=kind, field=field, value=value), self.assertRaises(ValueError):
                    self.check(facts)

    def test_connection_captures_cannot_be_missing_unhashed_or_outside_their_root(self):
        for kind in ('live', 'discovery'):
            for mutation in ('missing', 'bad_hash', 'boolean_bytes'):
                facts = synthetic_completion_facts()
                captures = facts['connections'][kind]['captures']
                first = next(iter(captures))
                if mutation == 'missing':
                    captures.pop(first)
                elif mutation == 'bad_hash':
                    captures[first]['sha256'] = ''
                else:
                    captures[first]['bytes'] = True
                with self.subTest(kind=kind, mutation=mutation), self.assertRaises(ValueError):
                    self.check(facts)
            for name in ('../outside.png', '/tmp/outside.png', 'captures/../outside.png',
                         'captures\\outside.png', 'captures//outside.png', 'captures/./outside.png'):
                facts = synthetic_completion_facts()
                captures = facts['connections'][kind]['captures']
                captures[name] = captures.pop(next(iter(captures)))
                with self.subTest(kind=kind, path=name), self.assertRaises(ValueError):
                    self.check(facts)

    def test_wrong_pin_or_nested_tree_cannot_relabel_prepared_proofs(self):
        with self.assertRaises(ValueError):
            delivery.checked_completion_facts(synthetic_completion_facts(), 'd' * 40)
        for path in (('connections', 'live'), ('connections', 'discovery'), ('village_completion',)):
            facts = synthetic_completion_facts()
            self.at(facts, path)['tree'] = 'd' * 40
            with self.subTest(path=path), self.assertRaises(ValueError):
                self.check(facts)

    def test_village_names_markers_dimensions_and_desktop_scope_cannot_change(self):
        cases = (
            ('mode_logs', 'path', 'unrelated.log'),
            ('mode_logs', 'marker', '[VillageEconomy] PASS 1 checks'),
            ('original_pngs', 'path', 'captures/another-camera.png'),
            ('original_pngs', 'width', 1279), ('original_pngs', 'height', 721),
            ('original_pngs', 'width', True),
        )
        for field, key, value in cases:
            facts = synthetic_completion_facts()
            facts['village_completion'][field][0][key] = value
            with self.subTest(field=field, key=key), self.assertRaises(ValueError):
                self.check(facts)
        for claim in (True, 0, None):
            facts = synthetic_completion_facts()
            facts['village_completion']['physical_android_fps_measured'] = claim
            with self.subTest(claim=claim), self.assertRaises(ValueError):
                self.check(facts)


class CurrentNativePinTests(unittest.TestCase):
    """Isolate final source binding; no mocked artifact is treated as an APK."""
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.source = self.root / 'source'
        (self.source / 'config').mkdir(parents=True)
        self.bundle = self.root / 'bundle'
        (self.bundle / 'assets').mkdir(parents=True)
        self.metadata = self.root / 'metadata'
        self.metadata.mkdir()
        for name in ('run', 'jobs', 'pull', 'artifacts'):
            (self.metadata / (name + '.json')).write_text('{}')
        self.pin = {'revision': REVISION}
        self.facts = {
            'schema': 1, 'status': 'VERIFIED_TEST_BUNDLE_NOT_PUBLISHED',
            'published': False, 'release_approved': False,
            'host_source': 'd' * 40, 'host_tree': 'e' * 40,
            'native_source': REVISION, 'binding': {'host_source': 'd' * 40, 'native_source': REVISION},
            'native': synthetic_completion_facts(), 'original_artifacts': {},
            'versionCode': 2020, 'versionName': '0.13.8',
        }
        self.plan = {'host_source': 'd' * 40, 'versionCode': 2020, 'versionName': '0.13.8'}

    def check(self):
        (self.source / 'config/godot-source.json').write_text(json.dumps(self.pin))
        (self.bundle / 'assets/C4-DELIVERY-FACTS.json').write_text(json.dumps(self.facts))
        with mock.patch.object(delivery, 'ROOT', self.source), \
             mock.patch.object(delivery, 'checked_plan', return_value=self.plan), \
             mock.patch.object(delivery.subprocess, 'check_output', side_effect=['d' * 40 + '\n', 'e' * 40 + '\n']), \
             mock.patch.object(delivery.subprocess, 'run'), \
             mock.patch.object(delivery, 'checked_jobs', return_value={}), \
             mock.patch.object(delivery, 'checked_artifacts', return_value={}), \
             mock.patch.object(delivery, 'checked_bundle', return_value={}):
            return delivery.checked_current(self.bundle, self.metadata, self.root / 'unused.zip', 1, 1)

    def test_exact_pin_reaches_current_acceptance_without_publication(self):
        self.assertEqual(self.check()['status'], 'COMPLETE_CURRENT_ACCEPTANCE_VERIFIED_NOT_PUBLISHED')

    def test_saved_native_source_binding_and_actual_host_pin_must_all_agree(self):
        for target, key in ((self.facts, 'native_source'),
                            (self.facts['binding'], 'native_source'), (self.pin, 'revision')):
            for value in (None, 'f' * 40):
                before = target[key]
                target[key] = value
                with self.subTest(field=key, value=value), self.assertRaisesRegex(ValueError, 'current verified Host pin'):
                    self.check()
                target[key] = before

    def test_final_gate_cannot_skip_the_prepared_completion_facts(self):
        self.facts['native']['connections'].pop('discovery')
        with self.assertRaisesRegex(ValueError, 'connection identities or logs are incomplete'):
            self.check()


if __name__ == '__main__':
    unittest.main()
