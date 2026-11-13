"""Small offline counterexamples for the new QA contracts, not app tests."""
import copy
import importlib.util
from pathlib import Path
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch

from PIL import Image, ImageDraw

SOURCE = Path(__file__).resolve().parents[2] / '.github/probes/studio_creative_android_probe.py'
SPEC = importlib.util.spec_from_file_location('studio_creative', SOURCE)
probe = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(probe)


class NewProbeContracts(unittest.TestCase):
    def metadata(self):
        # Synthetic fresh-run identities, never a historical APK acceptance.
        expected = {'host_source': 'a' * 40, 'native_source': 'b' * 40,
                    'build_run': 100, 'artifact_id': 200, 'artifact_digest': 'sha256:' + 'c' * 64}
        run = {'id': 100, 'head_sha': expected['host_source'],
               'path': '.github/workflows/lumo-studio-2019.yml',
               'repository': {'full_name': 'Ullmann27/lumo-lernen'}}
        artifact = {'id': 200, 'name': probe.ARTIFACT,
                    'size_in_bytes': 1234, 'digest': expected['artifact_digest'],
                    'expired': False, 'workflow_run': {'id': 100, 'head_sha': expected['host_source']}}
        jobs = {'jobs': [{'id': 300, 'name': 'verify-and-build', 'conclusion': 'success',
                          'status': 'completed', 'run_id': 100, 'head_sha': expected['host_source']}]}
        return run, {'artifacts': [artifact]}, jobs, expected

    def test_actual_candidate_identity_and_counterexamples(self):
        values = self.metadata()
        self.assertEqual(probe.verify_candidate_metadata(*values)['artifact']['id'], 200)
        for key, bad in (('id', 14073627515), ('digest', 'sha256:' + '0' * 64), ('expired', True)):
            run, artifacts, jobs, expected = self.metadata()
            artifacts['artifacts'][0][key] = bad
            with self.assertRaises(RuntimeError):
                probe.verify_candidate_metadata(run, artifacts, jobs, expected)
        run, artifacts, jobs, expected = self.metadata()
        run['head_sha'] = 'e3d161cb2f79b732ac2dbafc2764b151247f018b'
        with self.assertRaises(RuntimeError):
            probe.verify_candidate_metadata(run, artifacts, jobs, expected)
        run, artifacts, jobs, expected = self.metadata()
        jobs['jobs'][0]['conclusion'] = 'failure'
        with self.assertRaises(RuntimeError):
            probe.verify_candidate_metadata(run, artifacts, jobs, expected)

    def test_current_hub_semantics_rejects_old_clipped_and_ambiguous_nodes(self):
        node = {'package': probe.PACKAGE, 'enabled': 'true', 'clickable': 'true',
                'content-desc': 'Jump & Run. Springe durch Wolkeninseln. Spielen',
                'bounds': '[10,20][410,220]'}
        self.assertEqual(probe.hub_choice([node], 'Jump & Run', (1080, 1920), 72)['bounds'],
                         [10, 20, 410, 220])
        for field, value in (('clickable', 'false'), ('enabled', 'false'),
                             ('content-desc', 'Jump & Run spielen'),
                             ('content-desc', 'Jump & Run. Wolkeninseln Noch gesperrt'),
                             ('bounds', '[10,20][410,21]'), ('bounds', '[-10,20][410,220]')):
            self.assertIsNone(probe.hub_choice([{**node, field: value}], 'Jump & Run', (1080, 1920), 72))
        with self.assertRaises(RuntimeError):
            probe.hub_choice([node, {**node, 'bounds': '[10,240][410,440]'}], 'Jump & Run', (1080, 1920), 72)

    def test_real_portal_loop_observes_after_the_tenth_permitted_downward_scroll(self):
        state = {'gestures': 0, 'observations': 0, 'pressed': False}
        scroll = {'package': probe.PACKAGE, 'scrollable': 'true', 'bounds': '[10,10][950,530]'}
        tile = {'package': probe.PACKAGE, 'enabled': 'true', 'clickable': 'true',
                'content-desc': 'Jump & Run. Wolkeninseln Spielen', 'bounds': '[50,100][450,300]'}
        def nodes(*_):
            state['observations'] += 1
            return [scroll, tile] if state['gestures'] == 20 else [scroll]
        def adb(*args):
            self.assertEqual(args[:3], ('shell', 'input', 'swipe'))
            state['gestures'] += 1
        def touch(*_):
            state['pressed'] = True
        with tempfile.TemporaryDirectory() as temporary:
            image = Path(temporary) / 'synthetic-test-only.png'
            Image.new('RGB', (960, 540), 'white').save(image)
            tour = probe.Tour.__new__(probe.Tour)
            tour.out, tour.counter, tour.context = Path(temporary), 0, {}
            tour.probe = SimpleNamespace(normalized=lambda value: value)
            tour.live = SimpleNamespace(live_nodes=nodes)
            tour.base = SimpleNamespace(adb=adb)
            tour.shot = lambda _: (image, {'file': image.name, 'width': 960, 'height': 540})
            tour.touch = touch
            with patch.object(probe.time, 'sleep'):
                tour.portal('Jump & Run')
        self.assertEqual(state, {'gestures': 20, 'observations': 22, 'pressed': True})

    def test_build_requires_one_real_addition_and_retains_existing_objects(self):
        old = {'uid': 1, 'part': 'wood', 'x': 2, 'y': 0, 'z': 3, 'turn': 0}
        added = {'uid': 7, 'part': 'sand', 'x': -8, 'y': 0, 'z': 2, 'turn': 0}
        before, after = {'pieces': [old]}, {'pieces': [old, added]}
        self.assertEqual(probe.one_added_piece(before, after), added)
        for bad in ({'pieces': [old]}, {'pieces': [added]},
                    {'pieces': [{**old, 'x': 5}, added]},
                    {'pieces': [old, added, {**added, 'uid': 8}]}):
            with self.assertRaises(RuntimeError):
                probe.one_added_piece(before, bad)
        # UID counter changes are explicitly not piece changes or undo failure.
        probe.resume_equal({**after, 'next_id': 8}, {**after, 'next_id': 9}, ('pieces',))

    def test_puzzle_requires_real_quarter_turn_and_original_resume_identity(self):
        before = {'rotation_enabled': True, 'moves': 2, 'result_id': 'actual',
                  'pieces': [{'id': 0, 'locked': False, 'tray': True, 'turn': 3, 'x': -7, 'z': -2.2}]}
        after = copy.deepcopy(before)
        after['pieces'][0]['turn'] = 0
        after['moves'] = 3
        self.assertEqual(probe.one_quarter_turn(before, after)['piece_id'], 0)
        for bad in (before, {**after, 'moves': 2}, {**after, 'rotation_enabled': False}):
            with self.assertRaises(RuntimeError):
                probe.one_quarter_turn(before, bad)
        with self.assertRaises(RuntimeError):
            probe.resume_equal(after, {**after, 'result_id': 'new'}, ('pieces', 'result_id'))

    def test_jump_scope_is_the_actual_sha256_scope_not_build_style_p_key(self):
        scope = 'a' * 64
        raw = '[jump]\nversion=1\nchild_scope="' + scope + '"\ngrade=1\nresult_id="real"\n'
        name = 'jump_' + scope[:24] + '_1_' + 'b' * 12 + '.cfg'
        self.assertEqual(probe.parse_jump_save(name, raw)['result_id'], '"real"')
        with self.assertRaises(RuntimeError):
            probe.parse_jump_save(name.replace('jump_', 'jump_p_'), raw)
        with self.assertRaises(RuntimeError):
            probe.parse_jump_save(name, raw.replace(scope, 'c' * 64))

    def test_multiline_godot_variants_remain_verbatim_and_truncation_is_rejected(self):
        raw = ('[jump]\nversion=1\ncollected={\n0: true,\n3: true\n}\n'
               'active_question={\n"question": "A={B}",\n"nested": {\n"answer": 8\n}\n}\n'
               'recent_questions=Array[String](["one", "two {escaped}\\\"quote"])\n')
        read = probe.config_variant_values(raw)
        self.assertEqual(read['collected'], '{\n0: true,\n3: true\n}')
        self.assertIn('\n"nested": {\n"answer": 8\n}', read['active_question'])
        self.assertEqual(read['recent_questions'], 'Array[String](["one", "two {escaped}\\\"quote"])')
        for broken in ('[jump]\ncollected={\n0: true\n', '[jump]\ncollected={]\n',
                       '[jump]\nversion=1\nversion=2\n', '[jump]\nvalue="unfinished\n'):
            with self.assertRaises(RuntimeError):
                probe.config_variant_values(broken)

    def test_actual_godot463_serializer_fixture(self):
        directory = Path(__file__).parent / 'fixtures/studio_creative_android'
        files = list(directory.glob('jump_*.cfg'))
        self.assertEqual(len(files), 1)
        raw = files[0].read_text()
        saved = probe.parse_jump_save(files[0].name, raw)
        self.assertEqual(saved['collected'], '{\n0: true,\n3: true\n}')
        self.assertEqual(saved['goals_completed'], '{}')
        self.assertTrue(saved['recent_questions'].startswith('Array[String](['))
        self.assertIn('\n"nested": {\n', saved['active_question'])

    def test_observed_ring_rejects_blank_sky_and_duplicate_controls(self):
        image = Image.new('RGB', (960, 540), (100, 180, 220))
        with self.assertRaises(RuntimeError):
            probe.stick_target(image)
        draw = ImageDraw.Draw(image)
        draw.ellipse((30, 340, 155, 465), fill=(0, 160, 240))
        draw.ellipse((42, 352, 143, 453), fill=(12, 30, 70))
        target = probe.stick_target(image)
        self.assertAlmostEqual(target['center'][0], 92.5, delta=2)
        draw.ellipse((215, 340, 340, 465), fill=(0, 160, 240))
        draw.ellipse((227, 352, 328, 453), fill=(12, 30, 70))
        with self.assertRaises(RuntimeError):
            probe.stick_target(image)
        with self.assertRaises(RuntimeError):
            probe.puzzle_piece_target(Image.new('RGB', (960, 540), 'white'), {'count': 6, 'motif': 1})


if __name__ == '__main__':
    unittest.main()
