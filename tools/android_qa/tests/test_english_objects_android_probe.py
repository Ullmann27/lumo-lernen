"""Pure contracts using declared local Godot observations, never an Android run."""
from copy import deepcopy
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parents[3]
SPEC = importlib.util.spec_from_file_location(
    'english_objects_probe', ROOT/'.github/probes/lumo_english_objects_android_probe.py')
PROBE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(PROBE)
FIXTURES = Path(__file__).with_name('fixtures')/'english_objects'


def fixture(name='english-ball-960x540-start.layout.json'):
    return PROBE.parse_json((FIXTURES/name).read_bytes())


def task_for(layout):
    item = layout['launch']['learning']
    return {'word': item['word'], 'meaning': item['meaning']}


def check(layout, *, allow_fixture=True, size=None, owner=None):
    return PROBE.check_layout(layout, task_for(layout), owner or {
        'child_key': layout['launch']['childKey'], 'grade': 1},
        size or layout['android_observation']['decor_size'], layout['density'],
        layout['pid'], allow_fixture=allow_fixture)


def preferences():
    student = 'local-'+'b'*32
    return {
        'flutter.lumo_learning_local_student_id_v1': student,
        'flutter.lumo_active_profile': json.dumps({'id': 'fixture', 'name': 'LumoTest', 'grade': 1,
                                                  'age': 7, 'createdAt': 'fixture'}),
        'flutter.lumo_3d_profile_keys_v1': json.dumps({'version': 1, 'owners': {student: 'p_'+'a'*32}}),
        'flutter.lumo_progress_v1': '{"answers":1}',
        'flutter.lumo_reward_wallet_v1': '{"stars":1,"xp":5}',
        'flutter.lumo_app_settings_v1': '{"voiceEnabled":false}',
    }


class LayoutContracts(unittest.TestCase):
    def test_four_original_desktop_observations_pass_only_explicit_fixture_mode(self):
        for path in sorted(FIXTURES.glob('*.layout.json')):
            with self.subTest(path=path.name):
                layout = PROBE.parse_json(path.read_bytes())
                self.assertEqual(len(check(layout)), 3)
                with self.assertRaisesRegex(RuntimeError, 'actual Android'):
                    check(layout, allow_fixture=False)

    def test_actual_camera_matrix_independently_matches_all_original_corners(self):
        layout = fixture()
        errors = []
        for item in layout['objects']:
            for mesh in item['meshes']:
                for world, actual in zip(mesh['world_corners'], mesh['projected_corners_px']):
                    projected = PROBE.project(layout, world)
                    errors.extend(abs(a-b) for a, b in zip(projected, actual))
        self.assertTrue(errors)
        self.assertLess(max(errors), .001)

    def test_foreign_task_owner_or_session_is_rejected(self):
        layout = fixture()
        with self.assertRaisesRegex(RuntimeError, 'existing learning child'):
            check(layout, owner={'child_key': 'p_'+'b'*32, 'grade': 1})
        for field, value in [('sessionId', 'not-an-actual-session'), ('grade', 2), ('scene', 'cards')]:
            changed = deepcopy(layout)
            changed['launch'][field] = value
            with self.subTest(field=field), self.assertRaises(RuntimeError):
                check(changed)
        with self.assertRaisesRegex(RuntimeError, 'Native task differs'):
            PROBE.check_layout(layout, {'word': 'book', 'meaning': 'Buch'},
                {'child_key': layout['launch']['childKey'], 'grade': 1}, [960, 540], 1, layout['pid'], allow_fixture=True)

    def test_duplicate_unknown_or_missing_objects_fail_closed(self):
        for words in (['ball', 'ball', 'car'], ['ball', 'cat', 'car'], ['book', 'ruler', 'car']):
            changed = fixture()
            changed['launch']['learning']['objects'] = words
            with self.subTest(words=words), self.assertRaises(RuntimeError):
                check(changed)

    def test_private_free_text_and_unlicensed_voice_are_rejected(self):
        changed = fixture()
        changed['launch']['childName'] = 'fixture-private-name'
        with self.assertRaisesRegex(RuntimeError, 'private/free-text'):
            check(changed)
        changed = fixture()
        changed['launch']['localVoiceLicenseAccepted'] = False
        with self.assertRaisesRegex(RuntimeError, 'license assent'):
            check(changed)

    def test_unsettled_hidden_wrong_pid_and_non_finite_values_are_rejected(self):
        for field, value in [('settled', False), ('ui_visible', False), ('pid', True),
                             ('density', float('nan')), ('attempts', 0.0)]:
            changed = fixture()
            changed[field] = value
            with self.subTest(field=field), self.assertRaises(RuntimeError):
                check(changed)
        changed = fixture()
        with self.assertRaisesRegex(RuntimeError, 'another process'):
            PROBE.check_layout(changed, task_for(changed), {'child_key': changed['launch']['childKey'], 'grade': 1},
                               [960, 540], 1, changed['pid']+1, allow_fixture=True)

    def test_screenshot_and_real_insets_must_match(self):
        layout = fixture('english-pen-1080x2400-start.layout.json')
        with self.assertRaisesRegex(RuntimeError, 'Screenshot'):
            check(layout, size=[1080, 2340])
        changed = deepcopy(layout)
        changed['android_observation']['insets'][1] = 32
        with self.assertRaisesRegex(RuntimeError, 'actual View overlap'):
            check(changed)
        changed = deepcopy(layout)
        changed['safe_rect_px'][1] = 0
        with self.assertRaisesRegex(RuntimeError, 'Safe rectangle'):
            check(changed)

    def test_already_padded_view_maps_to_decor_without_duplicate_insets(self):
        layout = fixture()
        layout['android_observation'] = {'view_size': [960, 540], 'decor_size': [1000, 600],
            'render_rect': [10, 20, 960, 540], 'system_insets': [10, 20, 30, 40], 'insets': [0, 0, 0, 0]}
        self.assertEqual(len(check(layout)), 3)
        self.assertEqual(PROBE.to_decor(layout, [0, 0]), [10, 20])
        layout['android_observation']['insets'][1] = 20
        with self.assertRaises(RuntimeError):
            check(layout)

    def test_clipped_or_under48dp_actual_controls_are_rejected(self):
        for mutate in (lambda c: c['hit_rect_px'].__setitem__(2, 47.99),
                       lambda c: c['hit_rect_px'].__setitem__(0, -2),
                       lambda c: c.__setitem__('visible', False),
                       lambda c: c.__setitem__('enabled', False)):
            layout = fixture()
            mutate(layout['controls'][0])
            with self.assertRaises(RuntimeError):
                check(layout)

    def test_wrong_completed_state_and_hint_ring_cannot_pass(self):
        layout = fixture('english-ball-960x540-complete.layout.json')
        layout['selection'] = 1
        with self.assertRaisesRegex(RuntimeError, 'Completion'):
            check(layout)
        layout = fixture('english-ball-960x540-hint.layout.json')
        layout['objects'][1]['hint_visible'] = True
        with self.assertRaisesRegex(RuntimeError, 'Hint ring'):
            check(layout)

    def test_tampered_projection_and_missing_recognizable_geometry_are_rejected(self):
        layout = fixture()
        layout['objects'][0]['meshes'][0]['projected_corners_px'][0][0] += 4
        with self.assertRaisesRegex(RuntimeError, 'Independent projection'):
            check(layout)
        layout = fixture()
        layout['objects'][0]['meshes'] = [m for m in layout['objects'][0]['meshes']
                                         if not m['path'].startswith('RecognizableObject/')]
        with self.assertRaisesRegex(RuntimeError, 'recognizable object'):
            check(layout)

    def test_real_collision_volume_is_required_for_spatial_touch(self):
        layout = fixture()
        del layout['objects'][0]['collision_world_corners']
        with self.assertRaisesRegex(RuntimeError, 'collision volume'):
            check(layout)
        layout = fixture()
        layout['objects'][0]['pick_rect_px'] = [16, 116, 48, 48]
        with self.assertRaisesRegex(RuntimeError, 'spatial target'):
            check(layout)
        layout = fixture()
        layout['objects'][0]['collision_projected_corners_px'][0][0] += 2
        with self.assertRaisesRegex(RuntimeError, 'collision projection'):
            check(layout)

    def test_geometry_projected_outside_stage_is_rejected(self):
        layout = fixture()
        layout['camera']['view_origin'][0] += 100
        with self.assertRaises(RuntimeError):
            check(layout)

    def test_blank_object_pixels_are_not_visual_evidence(self):
        from PIL import Image
        layout = fixture()
        geometry = check(layout)
        with Image.new('RGB', (960, 540), (180, 180, 180)) as image:
            with self.assertRaisesRegex(RuntimeError, 'Blank/flat'):
                PROBE.check_pixels(image, geometry)

    def test_caption_needs_real_current_bounded_exact_text(self):
        good = [{'text': 'Englisch · ball', 'bounds': [20, 20, 200, 50], 'variant': 'synthetic-validator-case'}]
        self.assertEqual(PROBE.check_caption(good, 'Englisch · ball', [960, 540], [10, 10, 400, 100]), good)
        for value in ([{'text': 'Englisch book', 'bounds': [20, 20, 200, 50]}],
                      [{'text': 'Englisch ball', 'bounds': [-1, 20, 200, 50]}],
                      [{'text': 'Englisch ball', 'bounds': [20, 300, 200, 350]}]):
            with self.assertRaises(RuntimeError):
                PROBE.check_caption(value, 'Englisch ball', [960, 540], [10, 10, 400, 100])


class TaskAndStateContracts(unittest.TestCase):
    def prior_tour(self, api=35):
        # Schema from the unchanged modernization tour, not a real Android PASS.
        names = ('apk-identity', 'launch', 'onboarding', 'navigate-start',
                 'navigate-lernen', 'atelier-roundtrip', 'navigate-spiele',
                 'open-kart', 'start-kart-race', 'race-running', 'race-hud',
                 'race-drive', 'pause-menu', 'return-from-kart',
                 'learning-state-after-kart', 'lernen-usable-after-kart',
                 'profile-after-kart', 'restart-keeps-learning-state',
                 'display-fold_offen', 'display-fold_aussen', 'display-quer')
        return {'status': 'PASS', 'apk_sha256': 'a'*64, 'android_sdk': str(api),
                'fatal_crashes': 0,
                'steps': [{'step': name, 'ok': True} for name in names]}, names

    def test_prior_tour_uses_actual_text_sdk_schema_for_both_apis(self):
        for api in (35, 37):
            prior, names = self.prior_tour(api)
            PROBE.check_prior_tour(prior, 'a'*64, api, names)

    def test_prior_tour_wrong_apk_runtime_or_status_fails(self):
        for key, value in [('apk_sha256', 'b'*64), ('android_sdk', '37'),
                           ('android_sdk', 35), ('status', 'RUNNING'),
                           ('fatal_crashes', 1)]:
            prior, names = self.prior_tour()
            prior[key] = value
            with self.subTest(key=key, value=value), self.assertRaises(RuntimeError):
                PROBE.check_prior_tour(prior, 'a'*64, 35, names)

    def test_prior_tour_cannot_pass_with_missing_duplicate_or_failed_steps(self):
        for change in ('missing', 'duplicate', 'foreign', 'failed'):
            prior, names = self.prior_tour()
            if change == 'missing':
                prior['steps'].pop()
            elif change == 'duplicate':
                prior['steps'][-1]['step'] = prior['steps'][0]['step']
            elif change == 'foreign':
                prior['steps'][-1]['step'] = 'synthetic-unrelated-step'
            else:
                prior['steps'][-1]['ok'] = False
            with self.subTest(change=change), self.assertRaises(RuntimeError):
                PROBE.check_prior_tour(prior, 'a'*64, 35, names)

    def test_actual_supported_question_and_existing_alias_are_bound(self):
        value = PROBE.check_task('Was bedeutet „pen“?', ['Buch', 'Kugelschreiber', 'Lineal', 'Tasche'], 'Aufgabe 1 / 10')
        self.assertEqual(value['meaning'], 'Kugelschreiber')
        value = PROBE.check_task('Was heißt pen auf Deutsch?', ['Buch', 'Stift', 'Lineal', 'Tasche'], 'Aufgabe 1 / 10')
        self.assertEqual(value['meaning'], 'Stift')

    def test_unsupported_actual_task_is_not_silently_replaced(self):
        with self.assertRaisesRegex(RuntimeError, 'UNSUPPORTED_CURRENT_TASK: homework'):
            PROBE.check_task('Was bedeutet „homework“?', ['Buch', 'Hausübung', 'Lineal', 'Papier'], 'Aufgabe 1 / 10')
        for prompt, options, counter in [
                ('Was bedeutet „book“?', ['Auto', 'Ball'], 'Aufgabe 1 / 10'),
                ('Was bedeutet „pen“?', ['Stift', 'Kugelschreiber'], 'Aufgabe 1 / 10'),
                ('Was bedeutet „book“?', ['Buch', 'Buch'], 'Aufgabe 1 / 10'),
                ('Das Wort book.', ['Buch', 'Tasche'], 'Aufgabe 1 / 10'),
                ('Was bedeutet „book“?', ['Buch', 'Tasche'], '')]:
            with self.subTest(prompt=prompt, options=options), self.assertRaises(RuntimeError):
                PROBE.check_task(prompt, options, counter)

    def test_all_actual_first_and_second_grade_school_words_keep_exact_meanings(self):
        # The original vocabulary extensions replace pen/Stift with this exact
        # school-unit answer. Other topics retain the old Stift alias.
        school = {
            'book': 'Buch', 'pen': 'Kugelschreiber', 'bag': 'Tasche',
            'rubber': 'Radiergummi', 'ruler': 'Lineal',
            'school bag': 'Schultasche', 'desk': 'Schreibtisch',
            'chair': 'Sessel', 'pencil case': 'Federpennal', 'paper': 'Papier',
        }
        for word, meaning in school.items():
            options = [meaning] + [value for value in school.values()
                                   if value != meaning][:3]
            for prompt in (f'Was bedeutet „{word}“?',
                           f'Was heißt {word} auf Deutsch?'):
                with self.subTest(word=word, prompt=prompt):
                    observed = PROBE.check_task(prompt, options, 'Aufgabe 1 / 10')
                    self.assertEqual((observed['word'], observed['meaning']),
                                     (word, meaning))
                    self.assertEqual(observed['options'], sorted(options))

    def test_multiword_labels_cannot_alias_bags_or_accept_unobserved_phrases(self):
        for prompt, options in [
                ('Was bedeutet „school bag“?', ['Tasche', 'Buch', 'Lineal']),
                ('Was bedeutet „pencil case“?', ['Kugelschreiber', 'Buch', 'Lineal']),
                ('Was bedeutet „school  bag“?', ['Schultasche', 'Buch', 'Lineal']),
                ('Was bedeutet „school-bag“?', ['Schultasche', 'Buch', 'Lineal']),
                ('Was bedeutet „I have a school bag.“?', ['Schultasche', 'Buch', 'Lineal'])]:
            with self.subTest(prompt=prompt), self.assertRaises(RuntimeError):
                PROBE.check_task(prompt, options, 'Aufgabe 1 / 10')

    def test_hint_and_choice_transitions_preserve_real_session(self):
        before = fixture()
        wrong = deepcopy(before)
        wrong.update(layout_sequence=before['layout_sequence']+1, selection=1, attempts=1)
        PROBE.check_transition(before, wrong, 'choice', 1)
        hint = deepcopy(wrong)
        hint.update(layout_sequence=wrong['layout_sequence']+1, hint_level=1)
        PROBE.check_transition(wrong, hint, 'hint')
        hint['complete'] = True
        with self.assertRaisesRegex(RuntimeError, 'state transition'):
            PROBE.check_transition(wrong, hint, 'hint')

    def test_old_sequence_foreign_session_or_home_progress_cannot_pass(self):
        before = fixture()
        with self.assertRaisesRegex(RuntimeError, 'old observation'):
            PROBE.check_transition(before, deepcopy(before), 'home')
        changed = deepcopy(before)
        changed['layout_sequence'] += 1
        changed['launch']['sessionId'] = '11111111-1111-4111-8111-111111111111'
        with self.assertRaisesRegex(RuntimeError, 'task/session/process'):
            PROBE.check_transition(before, changed, 'home')
        changed = deepcopy(before)
        changed.update(layout_sequence=before['layout_sequence']+1, attempts=1)
        with self.assertRaisesRegex(RuntimeError, 'state transition'):
            PROBE.check_transition(before, changed, 'home')

    def test_actual_owner_registry_and_present_save_keys_are_preserved(self):
        prefs = preferences()
        self.assertTrue(PROBE.preservation(prefs, deepcopy(prefs))['unchanged'])
        for key, value in [('flutter.lumo_reward_wallet_v1', '{"stars":2}'),
                           ('flutter.lumo_progress_v1', '{"answers":2}'),
                           ('flutter.lumo_app_settings_v1', '{"voiceEnabled":true}'),
                           ('flutter.lumo.memory.round.v1.fixture', 'new unproved save')]:
            changed = deepcopy(prefs)
            changed[key] = value
            with self.subTest(key=key), self.assertRaises(RuntimeError):
                PROBE.preservation(prefs, changed)
        changed = deepcopy(prefs)
        changed['flutter.lumo_school_active_student_v1'] = 'another-child'
        with self.assertRaisesRegex(RuntimeError, 'school-child'):
            PROBE.preservation(prefs, changed)

    def test_duplicate_and_nonfinite_json_are_rejected(self):
        for value in ('{"a":1,"a":2}', '{"a":NaN}', '{"a":Infinity}'):
            with self.assertRaises(RuntimeError):
                PROBE.parse_json(value)


class DeadlineContracts(unittest.TestCase):
    def test_slow_successful_wait_observation_cannot_pass_after45_seconds(self):
        clock = [0.0]
        probe = object.__new__(PROBE.AndroidProbe)
        with tempfile.TemporaryDirectory() as directory:
            probe.out, probe.count = Path(directory), 0
            def observe():
                clock[0] = 46.0
                return True
            with mock.patch.object(PROBE.time, 'monotonic', side_effect=lambda: clock[0]), mock.patch.object(PROBE.time, 'sleep'):
                with self.assertRaisesRegex(RuntimeError, 'within budget'):
                    probe.wait('slow', observe, bool, 45)
            report = json.loads(next(probe.out.glob('*-failure.json')).read_text())
            self.assertEqual(report['budget_seconds'], 45)
            self.assertIn('completed after', report['errors'][0])

    def test_slow_post_capture_reads_cannot_turn_into_snapshot_pass(self):
        from PIL import Image
        clock, reads = [0.0], [0]
        layout = fixture()
        probe = object.__new__(PROBE.AndroidProbe)
        probe.task, probe.owner, probe.density = task_for(layout), {'child_key': layout['launch']['childKey'], 'grade': 1}, 1
        with tempfile.TemporaryDirectory() as directory:
            probe.out, probe.count = Path(directory), 0
            Image.new('RGB', (960, 540), 'white').save(probe.out/'synthetic-clock-only.png')
            probe.probe = mock.Mock()
            probe.probe.capture.return_value = {'file': 'synthetic-clock-only.png'}
            probe.probe.image_lines.return_value = []
            def read():
                reads[0] += 1
                if reads[0] == 2:
                    clock[0] = 46.0
                return layout, 'synthetic-clock-only-hash'
            with mock.patch.object(probe, 'read_layout', side_effect=read), mock.patch.object(probe, 'foreground'), \
                    mock.patch.object(probe, 'pid', return_value=layout['pid']), \
                    mock.patch.object(PROBE, 'check_layout', return_value=[]), \
                    mock.patch.object(PROBE, 'check_pixels', return_value=[]), \
                    mock.patch.object(PROBE, 'check_caption', return_value=[]), \
                    mock.patch.object(PROBE.time, 'monotonic', side_effect=lambda: clock[0]), \
                    mock.patch.object(PROBE.time, 'sleep'):
                with self.assertRaisesRegex(RuntimeError, 'bounded deadline'):
                    probe.snapshot('slow')
            self.assertFalse(list(probe.out.glob('*-observation.json')))
            rejected = json.loads(next(probe.out.glob('*-rejected.json')).read_text())
            self.assertIn('completed after', rejected['error'])


if __name__ == '__main__':
    unittest.main()
