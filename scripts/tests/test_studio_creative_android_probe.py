"""Small offline counterexamples for the new QA contracts, not app tests."""
import copy
import hashlib
import importlib.util
import json
from pathlib import Path
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch
import xml.etree.ElementTree as ET

from PIL import Image, ImageDraw

SOURCE = Path(__file__).resolve().parents[2] / '.github/probes/studio_creative_android_probe.py'
SPEC = importlib.util.spec_from_file_location('studio_creative', SOURCE)
probe = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(probe)


class NewProbeContracts(unittest.TestCase):
    def metadata(self):
        run = {'id': probe.BUILD_RUN, 'head_sha': probe.HOST,
               'repository': {'full_name': 'Ullmann27/lumo-lernen'}}
        artifact = {'id': probe.ARTIFACT_ID, 'name': probe.ARTIFACT,
                    'size_in_bytes': 648153033, 'digest': probe.ARTIFACT_DIGEST,
                    'expired': False, 'workflow_run': {'id': probe.BUILD_RUN, 'head_sha': probe.HOST}}
        jobs = {'jobs': [{'id': 132151952145, 'name': 'verify-and-build', 'conclusion': 'success'}]}
        return run, {'artifacts': [artifact]}, jobs

    def test_actual_candidate_identity_and_counterexamples(self):
        values = self.metadata()
        self.assertEqual(probe.verify_candidate_metadata(*values)['artifact']['id'], probe.ARTIFACT_ID)
        for key, bad in (('id', 14073627515), ('digest', 'sha256:' + '0' * 64), ('expired', True)):
            run, artifacts, jobs = self.metadata()
            artifacts['artifacts'][0][key] = bad
            with self.assertRaises(RuntimeError):
                probe.verify_candidate_metadata(run, artifacts, jobs)
        run, artifacts, jobs = self.metadata()
        run['head_sha'] = 'e3d161cb2f79b732ac2dbafc2764b151247f018b'
        with self.assertRaises(RuntimeError):
            probe.verify_candidate_metadata(run, artifacts, jobs)
        run, artifacts, jobs = self.metadata()
        jobs['jobs'][0]['conclusion'] = 'failure'
        with self.assertRaises(RuntimeError):
            probe.verify_candidate_metadata(run, artifacts, jobs)

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


class MenuBoundaryContracts(unittest.TestCase):
    """Exercise the real Tour methods against bounded synthetic UI responses."""

    def toolbar_case(self, visible_after):
        state = {'gestures': 0, 'observations': 0, 'anchors': 0, 'touches': 0}
        target = {'text': 'Rückgängig', 'bounds': [200, 40, 380, 100],
                  'capture': {'file': 'synthetic-toolbar.png', 'width': 960, 'height': 540}}

        def observe(label, exact=False):
            if label == 'Rückgängig':
                self.assertTrue(exact)
                state['observations'] += 1
                if state['gestures'] == visible_after:
                    return target
                raise RuntimeError('Synthetic target is outside the visible toolbar')
            self.assertEqual(label, 'Drehen')
            state['anchors'] += 1
            return {**target, 'text': label}

        def adb(*arguments):
            self.assertEqual(arguments, ('shell', 'input', 'swipe', '720', '70', '230', '70', '500'))
            state['gestures'] += 1

        def touch(point, observed):
            self.assertEqual(point, [290, 70])
            self.assertIs(observed, target)
            state['touches'] += 1

        tour = probe.Tour.__new__(probe.Tour)
        tour.observe, tour.touch = observe, touch
        tour.base, tour.context = SimpleNamespace(adb=adb), {}
        return tour, state

    def test_toolbar_observes_target_after_seventh_permitted_gesture(self):
        tour, state = self.toolbar_case(7)
        with patch.object(probe.time, 'sleep'):
            tour.toolbar('Rückgängig', ('Drehen',))
        self.assertEqual(state, {'gestures': 7, 'observations': 8, 'anchors': 7, 'touches': 1})

    def test_toolbar_absent_target_fails_after_final_observation_without_eighth_gesture(self):
        tour, state = self.toolbar_case(None)
        with patch.object(probe.time, 'sleep'), self.assertRaisesRegex(RuntimeError, 'Native toolbar'):
            tour.toolbar('Rückgängig', ('Drehen',))
        self.assertEqual(state, {'gestures': 7, 'observations': 8, 'anchors': 7, 'touches': 0})

    def test_toolbar_already_visible_target_uses_no_scroll(self):
        tour, state = self.toolbar_case(0)
        with patch.object(probe.time, 'sleep'):
            tour.toolbar('Rückgängig', ('Drehen',))
        self.assertEqual(state, {'gestures': 0, 'observations': 1, 'anchors': 0, 'touches': 1})

    def puzzle_menu_case(self, initial_motif, target_present=True):
        # The published993c puzzle_world.gd starts at index3, cycles these five
        # captions, and passes the actual selected index to model.setup().
        titles = ['Lumos Mondschloss', 'Candy Cloud Circuit', 'Volcano Night Run',
                  'Leuchtturm-Bucht', 'Blütenwiese']
        if not target_present:
            titles[1] = 'Candy Cloud Circuit Extra'
        state = {'motif': initial_motif, 'touches': 0, 'observations': 0, 'saved_reads': 0}
        tour = probe.Tour.__new__(probe.Tour)
        tour.enter = lambda *args: None
        tour.probe = SimpleNamespace(normalized=lambda text: text.casefold())

        def observe(label, exact=False):
            self.assertEqual(label, 'Bild:')
            state['observations'] += 1
            return {'text': 'Bild: ' + titles[state['motif']], 'bounds': [220, 100, 720, 160],
                    'capture': {'file': 'synthetic-motif.png', 'width': 960, 'height': 540}}

        def advance():
            state['motif'] = (state['motif'] + 1) % len(titles)
            state['touches'] += 1

        def touch(point, observed):
            self.assertEqual(point, [470, 130])
            self.assertEqual(observed['text'], 'Bild: ' + titles[state['motif']])
            advance()

        def native(label, tap=False, exact=False):
            # Retain the original probe's actual one-touch path in the red run.
            if label == 'Bild:' and tap:
                advance()

        def pause_save(kind):
            self.assertEqual(kind, 'puzzle')
            state['saved_reads'] += 1
            return {'count': 6, 'motif': state['motif'], 'rotation_enabled': True}

        class MenuAccepted(Exception):
            pass

        def shot(label):
            self.assertEqual(label, 'puzzle-observed-board')
            raise MenuAccepted

        tour.observe, tour.touch, tour.native = observe, touch, native
        tour.pause_save, tour.shot = pause_save, shot
        return tour, state, MenuAccepted

    def assert_puzzle_selection(self, initial_motif, expected_touches):
        tour, state, menu_accepted = self.puzzle_menu_case(initial_motif)
        with patch.object(probe.time, 'sleep'), self.assertRaises(menu_accepted):
            tour.puzzle()
        self.assertEqual(state, {'motif': 1, 'touches': expected_touches,
                                 'observations': expected_touches + 1, 'saved_reads': 1})

    def test_puzzle_selects_motif_one_from_actual_default_three(self):
        self.assert_puzzle_selection(3, 3)

    def test_puzzle_keeps_already_selected_target_without_touch(self):
        self.assert_puzzle_selection(1, 0)

    def test_puzzle_observes_target_after_fourth_and_last_motif_touch(self):
        self.assert_puzzle_selection(2, 4)

    def test_puzzle_missing_exact_target_fails_without_starting_or_reading_save(self):
        tour, state, _ = self.puzzle_menu_case(3, target_present=False)
        with patch.object(probe.time, 'sleep'), self.assertRaises(RuntimeError):
            tour.puzzle()
        self.assertEqual(state, {'motif': 2, 'touches': 4, 'observations': 5, 'saved_reads': 0})


class OriginalHubPortalContracts(unittest.TestCase):
    """Replay original UI observations through Tour.portal, without Android."""

    def observation(self, title):
        directory = Path(__file__).parent / 'fixtures/studio_creative_android/hub-6dcc'
        provenance = json.loads((directory / 'provenance.json').read_text())
        row = next(item for item in provenance['observations'] if item['title'] == title)
        raw = (directory / row['xml']).read_bytes()
        self.assertEqual(len(raw), row['xml_bytes'])
        self.assertEqual(hashlib.sha256(raw).hexdigest(), row['xml_sha256'])
        nodes = list(ET.fromstring(raw).iter('node'))
        matches = [node for node in nodes
                   if node.get('content-desc', '').startswith(title + '. ')]
        self.assertEqual(len(matches), 1)
        target = matches[0]
        self.assertEqual(target.get('clickable'), 'false')
        self.assertEqual(target.get('class'), 'android.widget.Button')
        for flag in ('enabled', 'focusable', 'visible-to-user'):
            self.assertEqual(target.get(flag), 'true')
        return nodes, target, row['capture']

    def assert_original_portal(self, title):
        nodes, target, shot = self.observation(title)
        state = {'observations': 0, 'scrolls': 0, 'touches': []}

        def live_nodes(*_):
            state['observations'] += 1
            return nodes

        def adb(*arguments):
            self.assertEqual(arguments[:3], ('shell', 'input', 'swipe'))
            state['scrolls'] += 1

        def touch(point, context):
            state['touches'].append((point, context))

        tour = probe.Tour.__new__(probe.Tour)
        tour.out, tour.counter, tour.context = Path('unused-offline-output'), 0, {}
        tour.probe = SimpleNamespace(normalized=lambda value: value.casefold())
        tour.live, tour.base = SimpleNamespace(live_nodes=live_nodes), SimpleNamespace(adb=adb)
        tour.shot = lambda _: (Path(shot['file']), shot)
        tour.touch = touch
        # Only image IO is stubbed: these dimensions/hash identify the matching
        # real CI PNG in provenance.json. No synthetic picture is a UI proof.
        image_size = (shot['width'], shot['height'])
        image = SimpleNamespace(size=image_size, width=image_size[0], height=image_size[1])
        with patch.object(probe, 'read_image', return_value=image), patch.object(probe.time, 'sleep'):
            tour.portal(title)
        self.assertEqual(state['observations'], 1)
        self.assertEqual(state['scrolls'], 0)
        self.assertEqual(len(state['touches']), 1)
        point, context = state['touches'][0]
        rect = probe.bounds(target.get('bounds'))
        self.assertEqual(point, [(rect[0] + rect[2]) / 2, (rect[1] + rect[3]) / 2])
        self.assertEqual(context['caption'], target.get('content-desc'))
        self.assertEqual(context['bounds'], rect)
        self.assertEqual(context['capture'], shot)
        self.assertEqual(context['actionability'], 'source-bound-game-tile-button')
        self.assertEqual(context['android_clickable'], 'false')

    def test_original_jump_portal_touches_the_observed_button_without_scrolling(self):
        self.assert_original_portal('Jump & Run')

    def test_original_build_portal_touches_the_observed_button_without_scrolling(self):
        self.assert_original_portal('Bauwelt')

    def test_original_puzzle_portal_touches_the_observed_button_without_scrolling(self):
        self.assert_original_portal('Puzzle')

    def test_original_treasure_portal_touches_the_observed_button_without_scrolling(self):
        self.assert_original_portal('Schatzsuche')

    def test_nonclickable_original_target_requires_every_specific_role_and_caption_guard(self):
        _, original, shot = self.observation('Jump & Run')
        size = (shot['width'], shot['height'])
        bad_values = (
            ('package', 'another.application'), ('enabled', 'false'),
            ('class', 'android.view.View'), ('focusable', 'false'),
            ('visible-to-user', 'false'), ('clickable', None),
            ('content-desc', 'Jump & Run. Spring. Laufe. Sei mutig! Noch gesperrt'),
            ('content-desc', 'Jump & Run. A different caption Spielen'),
            ('content-desc', 'Jump & Run spielen'),
        )
        for field, value in bad_values:
            with self.subTest(field=field, value=value):
                altered = dict(original.attrib)
                if value is None:
                    altered.pop(field)
                else:
                    altered[field] = value
                self.assertIsNone(probe.hub_choice([altered], 'Jump & Run', size, 72))
        for field in ('class', 'focusable', 'visible-to-user'):
            with self.subTest(missing=field):
                altered = dict(original.attrib)
                altered.pop(field)
                self.assertIsNone(probe.hub_choice([altered], 'Jump & Run', size, 72))

    def test_original_button_role_does_not_accept_clipped_or_undersized_targets(self):
        _, original, shot = self.observation('Bauwelt')
        for rect in ('[-1,647][656,936]', '[288,647][1081,936]',
                     '[288,1850][656,1921]', '[288,647][656,718]', '[288,647][288,936]'):
            with self.subTest(bounds=rect):
                self.assertIsNone(probe.hub_choice([{**original.attrib, 'bounds': rect}],
                                                  'Bauwelt', (shot['width'], shot['height']), 72))

    def test_two_distinct_original_role_targets_remain_a_hard_ambiguity(self):
        _, original, shot = self.observation('Puzzle')
        another = {**original.attrib, 'bounds': '[100,200][500,500]'}
        with self.assertRaisesRegex(RuntimeError, 'Ambiguous live game tile'):
            probe.hub_choice([original, another], 'Puzzle', (shot['width'], shot['height']), 72)


if __name__ == '__main__':
    unittest.main()
