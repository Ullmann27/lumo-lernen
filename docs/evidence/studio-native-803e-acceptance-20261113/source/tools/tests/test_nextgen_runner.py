"""Test the actual acceptance shell's fail-closed evidence collection."""
from pathlib import Path
import hashlib
import json
import os
import re
import shutil
import struct
import subprocess
import tempfile
import unittest
import sys
import zlib


ROOT = Path(__file__).resolve().parents[2]
RUNNER = ROOT / 'tools/validate_nextgen.sh'


class NextgenRunnerTests(unittest.TestCase):
    def run_fixture(self, *, failing='', missing=''):
        """The fake engine tests orchestration, never claims rendered/gameplay proof."""
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            root.joinpath('tools').mkdir()
            root.joinpath('scripts/tests').mkdir(parents=True)
            root.joinpath('bin').mkdir()
            shutil.copyfile(RUNNER, root / 'tools/validate_nextgen.sh')
            shutil.copyfile(ROOT / 'tools/run_godot_probe.py', root / 'tools/run_godot_probe.py')
            cases = re.findall(r"^check_probe (\S+) '([^']+)' (\S+)", RUNNER.read_text(), re.M)
            markers = {name: marker for name, marker, _ in cases}
            for name in markers:
                if name != missing:
                    root.joinpath('scripts/tests', name + '.gd').write_text('# fixture only\n')
            engine = root / 'bin/fixture-godot'
            engine.write_text('#!/usr/bin/env python3\n'
                              'import pathlib, sys\n'
                              'if "--version" in sys.argv: print("fixture-engine"); sys.exit(0)\n'
                              'name=pathlib.Path(sys.argv[sys.argv.index("--script")+1]).stem\n'
                              f'if name == {failing!r}: print("ERROR: requested fixture failure"); sys.exit(1)\n'
                              f'print({markers!r}[name])\n')
            engine.chmod(0o755)
            git = root / 'bin/git'
            git.write_text('#!/bin/sh\nif [ "$1" = rev-parse ]; then echo fixture-source; fi\n')
            git.chmod(0o755)
            python = root / 'bin/python3'
            python.write_text(f'#!{sys.executable}\n'
                              'import os, pathlib, sys\n'
                              'if len(sys.argv)>1 and sys.argv[1]=="tools/run_godot_probe.py":\n'
                              '    name=pathlib.Path(sys.argv[sys.argv.index("--log")+1]).stem\n'
                              '    budget=sys.argv[sys.argv.index("--timeout")+1]\n'
                              '    with open("budgets.tsv","a") as log: log.write(name+"\\t"+budget+"\\n")\n'
                              f'os.execv({sys.executable!r}, [{sys.executable!r}, *sys.argv[1:]])\n')
            python.chmod(0o755)
            env = dict(os.environ, GODOT_BIN=str(engine), DISPLAY=':fixture',
                       LUMO_NEXTGEN_LOG_DIR=str(root / 'logs'),
                       PATH=str(root / 'bin') + os.pathsep + os.environ['PATH'])
            result = subprocess.run(['bash', 'tools/validate_nextgen.sh'], cwd=root,
                                    env=env, capture_output=True, text=True, timeout=45)
            rows = (root / 'logs/results.tsv').read_text().splitlines()[1:]
            budgets = dict(line.split('\t') for line in root.joinpath('budgets.tsv').read_text().splitlines())
            return result, rows, cases, budgets

    def test_success_requires_every_logic_and_rendered_probe(self):
        result, rows, cases, budgets = self.run_fixture()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(len(rows), len(cases))
        self.assertTrue(all(row.endswith('\tPASS') for row in rows))
        self.assertIn('[LumoNextgen] PASS', result.stdout)
        self.assertEqual(budgets['learning_world_capture-rendered'], '900')
        self.assertTrue(all(value == '420' for key, value in budgets.items()
                            if key != 'learning_world_capture-rendered'))

    def test_failure_does_not_suppress_other_module_evidence_or_emit_pass(self):
        result, rows, cases, _ = self.run_fixture(failing='jump_nextgen_regression')
        self.assertEqual(result.returncode, 1)
        self.assertEqual(len(rows), len(cases))
        self.assertIn('jump_nextgen_regression\theadless\tFAIL', rows)
        self.assertIn('cards_table_capture\trendered\tPASS', rows)
        self.assertNotIn('[LumoNextgen] PASS', result.stdout)
        self.assertIn('[LumoNextgen] FAIL', result.stderr)

    def test_missing_required_source_is_a_failure_and_other_captures_still_run(self):
        result, rows, cases, _ = self.run_fixture(missing='learning_world_regression')
        self.assertEqual(result.returncode, 1)
        self.assertEqual(len(rows), len(cases))
        self.assertIn('learning_world_regression\theadless\tFAIL', rows)
        self.assertIn('cards_table_capture\trendered\tPASS', rows)
        self.assertNotIn('[LumoNextgen] PASS', result.stdout)


class StudioPuzzleMenuContractTests(unittest.TestCase):
    """Synthetic fixtures test gate rejection; they are never renderer evidence."""

    def setUp(self):
        self.source = (ROOT / 'tools/validate_studio.sh').read_text()
        self.roster = self.source.split("<<'PY'\n", 1)[1].split('\nPY\n', 1)[0]

    def test_existing_probes_and_budgets_survive_two_required_menu_modes(self):
        cases = re.findall(r"^check_probe (\S+) '([^']+)' (\S+) (\d+)", self.source, re.M)
        added_names = {'cards_safe_area_android_contract', 'cards_safe_area_regression',
                       'mobile_safe_area_regression'}
        legacy = [row for row in cases if row[0] not in added_names]
        previous = [
            ('learning_sharing_regression', '[LearningSharing] PASS', 'headless', '180'),
            ('learning_studio_regression', '[LearningStudio] PASS', 'headless', '180'),
            ('lumo_studio_motion_regression', '[LumoStudioMotion] PASS', 'headless', '180'),
            ('puzzle_rotation_regression', '[PuzzleRotation] PASS', 'headless', '180'),
            ('treasure_exploration_regression', '[TreasureExploration] PASS', 'headless', '180'),
            ('learning_sharing_capture', '[LearningSharingCapture] PASS', 'rendered', '600'),
            ('lumo_studio_motion_capture', '[LumoStudioCapture] PASS', 'rendered', '420'),
            ('puzzle_rotation_regression', '[PuzzleRotation] PASS', 'rendered', '600'),
            ('treasure_exploration_regression', '[TreasureExploration] PASS', 'rendered', '600'),
        ]
        self.assertEqual(len(legacy), 11)
        self.assertEqual([row for row in legacy if row[0] != 'puzzle_menu_lifecycle_regression'], previous)
        self.assertEqual([row for row in legacy if row[0] == 'puzzle_menu_lifecycle_regression'], [
            ('puzzle_menu_lifecycle_regression', '[PuzzleMenuLifecycle] PASS', 'headless', '180'),
            ('puzzle_menu_lifecycle_regression', '[PuzzleMenuLifecycle] PASS', 'rendered', '600'),
        ])
        self.assertIn("check_probe puzzle_menu_lifecycle_regression '[PuzzleMenuLifecycle] PASS' "
                      'rendered 600 -- --capture', self.source)
        self.assertEqual([row for row in cases if row[0] in added_names], [
            ('cards_safe_area_android_contract', 'CARDS_ANDROID_INSETS_PASS', 'headless', '180'),
            ('cards_safe_area_regression', 'CARDS_SAFE_AREA_PASS', 'headless', '180'),
            ('mobile_safe_area_regression', 'MOBILE_SAFE_AREA_PASS', 'headless', '240'),
            ('cards_safe_area_regression', 'CARDS_SAFE_AREA_PASS', 'rendered', '600'),
            ('mobile_safe_area_regression', 'MOBILE_SAFE_AREA_PASS', 'rendered', '900'),
        ])
        self.assertEqual(len(cases), 16)
        self.assertIn("check_probe cards_safe_area_regression 'CARDS_SAFE_AREA_PASS' "
                      'rendered 600 -- --capture', self.source)
        self.assertIn("check_probe mobile_safe_area_regression 'MOBILE_SAFE_AREA_PASS' "
                      'rendered 900 -- --capture', self.source)

    @staticmethod
    def fixture_layout(width, height):
        return {'schema': 1, 'settled': True, 'ui_visible': True, 'pending': 0,
                'observation_source': 'fixture', 'window_px': [width, height],
                'hand': [{'id': 'fixture-card',
                          'quad': [[100, 400], [220, 400], [220, 580], [100, 580]]}],
                'discard': {'quad': [[360, 400], [480, 400], [480, 580], [360, 580]]}}

    @staticmethod
    def fixture_png(width, height):
        def chunk(kind, data):
            return (struct.pack('>I', len(data)) + kind + data
                    + struct.pack('>I', zlib.crc32(kind + data) & 0xffffffff))
        return (b'\x89PNG\r\n\x1a\n'
                + chunk(b'IHDR', struct.pack('>IIBBBBB', width, height, 8, 2, 0, 0, 0))
                + chunk(b'IDAT', zlib.compress(bytes(width * 3 + 1) * height))
                + chunk(b'IEND', b''))

    def roster_fixture(self, mutation=''):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for probe, count in {'learning_sharing_capture': 6, 'lumo_studio_motion_capture': 8,
                                 'puzzle_rotation_regression': 7, 'treasure_exploration_regression': 3}.items():
                folder = root / 'captures' / probe
                folder.mkdir(parents=True)
                for index in range(count):
                    (folder / f'fixture-{index}.png').write_bytes(self.fixture_png(360, 360))
            folder = root / 'captures/puzzle_menu_lifecycle_regression'
            folder.mkdir()
            for width, height in ((960, 540), (640, 360)):
                for phase in ('rotation-menu', 'rotation-play', 'classic-play'):
                    (folder / f'{width}x{height}-{phase}.png').write_bytes(self.fixture_png(width, height))
            cards = root / 'captures/cards_safe_area_regression'
            cards.mkdir()
            for name, width, height in (
                    ('android35_portrait-playing', 1080, 2400),
                    ('android35_portrait-paused', 1080, 2400),
                    ('landscape_cutout_fixture-playing', 2400, 1080)):
                (cards / f'{name}.png').write_bytes(self.fixture_png(width, height))
                (cards / f'{name}.layout.json').write_text(
                    json.dumps(self.fixture_layout(width, height), sort_keys=True) + '\n')
            mobile = root / 'captures/mobile_safe_area_regression'
            mobile.mkdir()
            mobile_report = {
                'failures': [],
                'targets': [{'name': f'fixture-{index}', 'fully_inside_true_safe_area': True,
                             'exposed_dp': [48.0, 48.0]} for index in range(15)],
                'images': [],
            }
            for module in ('jump', 'build', 'puzzle', 'treasure'):
                path = mobile / f'{module}-landscape-cutout.png'
                data = self.fixture_png(2400, 1080)
                path.write_bytes(data)
                mobile_report['images'].append({'path': path.name,
                                               'sha256': hashlib.sha256(data).hexdigest()})
            selected = folder / '640x360-rotation-menu.png'
            if mutation == 'missing':
                selected.unlink()
            elif mutation == 'renamed':
                selected.rename(folder / 'wrong-scene.png')
            elif mutation == 'dimensions':
                selected.write_bytes(self.fixture_png(640, 361))
            card_png = cards / 'landscape_cutout_fixture-playing.png'
            card_layout = card_png.with_suffix('.layout.json')
            layout_changes = {
                'cards-schema-bool': {'schema': True},
                'cards-schema-version': {'schema': 2},
                'cards-unsettled': {'settled': False},
                'cards-hidden': {'ui_visible': False},
                'cards-pending': {'pending': 1},
                'cards-wrong-source': {'observation_source': 'android'},
                'cards-window-mismatch': {'window_px': [2400, 1081]},
                'cards-no-hand': {'hand': []},
                'cards-no-discard-quad': {'discard': {'quad': []}},
            }
            if mutation == 'cards-missing-image':
                card_png.unlink()
            elif mutation == 'cards-missing-layout':
                card_layout.unlink()
            elif mutation == 'cards-malformed-layout':
                card_layout.write_text('{')
            elif mutation in layout_changes:
                layout = json.loads(card_layout.read_text())
                layout.update(layout_changes[mutation])
                card_layout.write_text(json.dumps(layout))
            mobile_image = mobile / 'treasure-landscape-cutout.png'
            if mutation == 'mobile-missing-image':
                mobile_image.unlink()
            elif mutation == 'mobile-renamed-image':
                mobile_image.rename(mobile / 'wrong-scene.png')
            elif mutation == 'mobile-dimensions':
                mobile_image.write_bytes(self.fixture_png(2400, 1081))
            elif mutation == 'mobile-reported-failure':
                mobile_report['failures'].append('fixture unsafe target')
            elif mutation == 'mobile-missing-target':
                mobile_report['targets'].pop()
            elif mutation == 'mobile-unsafe-target':
                mobile_report['targets'][-1]['fully_inside_true_safe_area'] = False
            elif mutation == 'mobile-small-target':
                mobile_report['targets'][-1]['exposed_dp'] = [48.0, 47.94]
            elif mutation == 'mobile-wrong-hash':
                mobile_report['images'][-1]['sha256'] = '0' * 64
            elif mutation == 'mobile-missing-roster-entry':
                mobile_report['images'].pop()
            elif mutation == 'mobile-extra-roster-entry':
                mobile_report['images'].append({'path': 'extra.png', 'sha256': '0' * 64})
            if mutation != 'mobile-missing-report':
                (mobile / 'mobile-safe-area.json').write_text(
                    '{' if mutation == 'mobile-malformed-report' else json.dumps(mobile_report))
            result = subprocess.run([sys.executable, '-', str(root)], input=self.roster,
                                    text=True, capture_output=True, timeout=15)
            report = root / 'renderer-images.json'
            return result, json.loads(report.read_text()) if report.exists() else None

    def test_all_thirty_seven_required_rasters_and_named_menu_views_are_enforced(self):
        result, report = self.roster_fixture()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(len(report['images']), 37)
        counts = {}
        for image in report['images']:
            probe = Path(image['path']).parts[1]
            counts[probe] = counts.get(probe, 0) + 1
            if probe == 'cards_safe_area_regression':
                layout_data = (json.dumps(self.fixture_layout(image['width'], image['height']),
                                          sort_keys=True) + '\n').encode()
                self.assertEqual(image['native_layout'], {
                    'path': str(Path(image['path']).with_suffix('.layout.json')),
                    'bytes': len(layout_data), 'sha256': hashlib.sha256(layout_data).hexdigest(),
                })
        self.assertEqual(counts, {
            'learning_sharing_capture': 6, 'lumo_studio_motion_capture': 8,
            'puzzle_rotation_regression': 7, 'treasure_exploration_regression': 3,
            'puzzle_menu_lifecycle_regression': 6,
            'cards_safe_area_regression': 3, 'mobile_safe_area_regression': 4,
        })
        for mutation in ('missing', 'renamed', 'dimensions'):
            with self.subTest(mutation=mutation):
                result, report = self.roster_fixture(mutation)
                self.assertNotEqual(result.returncode, 0)
                self.assertIsNone(report)

    def test_cards_require_each_raster_and_settled_matching_layout_sidecar(self):
        for mutation in (
                'cards-missing-image', 'cards-missing-layout', 'cards-malformed-layout',
                'cards-schema-bool', 'cards-schema-version', 'cards-unsettled', 'cards-hidden',
                'cards-pending', 'cards-wrong-source', 'cards-window-mismatch',
                'cards-no-hand', 'cards-no-discard-quad'):
            with self.subTest(mutation=mutation):
                result, report = self.roster_fixture(mutation)
                self.assertNotEqual(result.returncode, 0)
                self.assertIsNone(report)

    def test_mobile_requires_all_named_images_and_safe_hash_bound_target_report(self):
        for mutation in (
                'mobile-missing-image', 'mobile-renamed-image', 'mobile-dimensions',
                'mobile-missing-report', 'mobile-malformed-report', 'mobile-reported-failure',
                'mobile-missing-target', 'mobile-unsafe-target', 'mobile-small-target',
                'mobile-wrong-hash', 'mobile-missing-roster-entry', 'mobile-extra-roster-entry'):
            with self.subTest(mutation=mutation):
                result, report = self.roster_fixture(mutation)
                self.assertNotEqual(result.returncode, 0)
                self.assertIsNone(report)

    def test_native_menu_error_rejects_even_a_success_marker_and_zero_exit(self):
        with tempfile.TemporaryDirectory() as directory:
            fixture = ('print("[PuzzleMenuLifecycle] PASS fixture only", flush=True); '
                       'print("ERROR: Condition !is_inside_tree() is true. Returning: false", flush=True)')
            result = subprocess.run([
                sys.executable, str(ROOT / 'tools/run_godot_probe.py'),
                '--log', str(Path(directory) / 'native-error.log'), '--timeout', '10',
                '--required', '[PuzzleMenuLifecycle] PASS', '--', sys.executable, '-c', fixture,
            ], capture_output=True, text=True, timeout=15)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn('[PuzzleMenuLifecycle] PASS', result.stdout)
            self.assertIn('ERROR:', result.stdout)
            self.assertIn('[ProbeRunner] FAIL', result.stderr)


if __name__ == '__main__':
    unittest.main()
