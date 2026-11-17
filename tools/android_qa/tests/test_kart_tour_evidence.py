"""Real Android screenshots and real save formats for the full Kart tour checks."""
import io
import json
from pathlib import Path
import sys
import unittest

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from kart_tour_evidence import (driving_progress, garage_replaced, labels_still_present,  # noqa: E402
                                learning_preserved, paused_unchanged, race_running,
                                rendered_race_frame, world_moved)

FIXTURES = Path(__file__).resolve().parent / 'fixtures'
RACE_LAP_ONE = FIXTURES / 'kart-37121358107' / '022-race.png'
RACE_LAP_TWO = FIXTURES / 'kart-37121358107' / '033-race.png'
RACE_HUD = FIXTURES / 'drift-cover-1909-api35.png'
GARAGE = FIXTURES / 'kart-garage-api35' / 'garage-step1-640x320.png'


def png(image: Image.Image) -> bytes:
    buffer = io.BytesIO()
    image.save(buffer, format='PNG')
    return buffer.getvalue()


def resized(path: Path, size) -> bytes:
    with Image.open(path) as image:
        return png(image.convert('RGB').resize(size))


def session(**changes):
    state = {'result_id': 'kart-1', 'mode': 'race', 'track_id': 'sonnenhafen',
             'finished': False, 'completed_race': False, 'countdown': 0.0,
             'elapsed': 1.2, 'distance': 0.4, 'checkpoint_index': 0}
    state.update(changes)
    return state


class RenderedFrameTests(unittest.TestCase):
    def test_actual_android_race_frames_are_rendered_3d_scenes(self):
        for path in (RACE_HUD, RACE_LAP_ONE, RACE_LAP_TWO):
            with self.subTest(path=path.name):
                report = rendered_race_frame(path.read_bytes())
                self.assertTrue(all(value >= .65 for value in report['visible_fractions']))

    def test_black_flat_and_portrait_frames_are_rejected(self):
        for image, reason in ((Image.new('RGB', (800, 480)), 'Black'),
                              (Image.new('RGB', (800, 480), (90, 120, 160)), 'Blank'),
                              (Image.new('RGB', (480, 800), (90, 120, 160)), 'landscape')):
            with self.subTest(reason=reason):
                with self.assertRaisesRegex(RuntimeError, reason):
                    rendered_race_frame(png(image))


class GarageAndMotionTests(unittest.TestCase):
    def test_the_real_garage_is_not_accepted_as_the_race(self):
        garage = resized(GARAGE, (800, 480))
        with self.assertRaisesRegex(RuntimeError, 'still shows the garage'):
            garage_replaced(garage, garage)
        report = garage_replaced(garage, RACE_LAP_ONE.read_bytes())
        self.assertGreaterEqual(report['changed_fraction'], .22)

    def test_world_must_move_between_frames_of_one_race(self):
        frame = RACE_LAP_ONE.read_bytes()
        with self.assertRaisesRegex(RuntimeError, 'did not move'):
            world_moved(frame, frame)
        report = world_moved(frame, RACE_LAP_TWO.read_bytes())
        self.assertGreaterEqual(report['changed_fraction'], .08)

    def test_different_viewports_are_never_compared(self):
        with self.assertRaisesRegex(RuntimeError, 'differ in size'):
            world_moved(RACE_LAP_ONE.read_bytes(), RACE_HUD.read_bytes())


class NativeSessionTests(unittest.TestCase):
    def test_explicit_cup_mode_keeps_all_running_and_driving_checks(self):
        start = session(mode='cup')
        self.assertTrue(race_running(start, mode='cup'))
        self.assertFalse(race_running(session(mode='cup', countdown=2), mode='cup'))
        report = driving_progress(start, session(mode='cup', distance=46, elapsed=8), mode='cup')
        self.assertGreaterEqual(report['distance_gain'], 8)
        with self.assertRaisesRegex(RuntimeError, 'did not actually drive'):
            driving_progress(start, session(mode='cup', distance=1, elapsed=8), mode='cup')
        with self.assertRaisesRegex(RuntimeError, 'not race/sonnenhafen'):
            race_running(start)

    def test_expected_mode_track_and_identity_cannot_change_during_drive_or_pause(self):
        start = session(mode='cup')
        for later in [session(mode='race'), session(mode='arena'),
                      session(mode='cup', track_id='zauberwald'),
                      session(mode='cup', result_id='other')]:
            with self.subTest(later=later):
                with self.assertRaises(RuntimeError):
                    driving_progress(start, later, mode='cup')
                with self.assertRaises(RuntimeError):
                    paused_unchanged(start, later, mode='cup')
        self.assertEqual(paused_unchanged(start, dict(start), mode='cup')['result_id'], 'kart-1')

    def test_race_counts_as_running_only_after_countdown_and_first_second(self):
        self.assertFalse(race_running(session(countdown=2.1, elapsed=0.0)))
        self.assertFalse(race_running(session(elapsed=0.4)))
        self.assertTrue(race_running(session()))

    def test_other_tracks_modes_or_finished_races_are_rejected(self):
        for state in (session(track_id='zauberwald'), session(mode='arena'), session(finished=True)):
            with self.subTest(state=state):
                with self.assertRaises(RuntimeError):
                    race_running(state)

    def test_holding_gas_must_cover_distance_in_the_same_race(self):
        start = session()
        report = driving_progress(start, session(distance=46.0, elapsed=8.1))
        self.assertEqual(report['distance_gain'], 45.6)
        with self.assertRaisesRegex(RuntimeError, 'did not actually drive'):
            driving_progress(start, session(distance=1.0, elapsed=8.1))
        with self.assertRaisesRegex(RuntimeError, 'two different races'):
            driving_progress(start, session(result_id='kart-2', distance=46.0, elapsed=8.1))

    def test_pause_must_freeze_the_saved_race(self):
        paused = session(distance=46.0, elapsed=8.1)
        self.assertEqual(paused_unchanged(paused, dict(paused))['distance'], 46.0)
        with self.assertRaisesRegex(RuntimeError, 'advanced while paused'):
            paused_unchanged(paused, session(distance=52.0, elapsed=9.0))


def prefs(profile_seen='2026-10-16T13:00:00.000', wallet='{"stars":3,"xp":24}', **extra):
    data = {
        'flutter.lumo_active_profile': json.dumps({
            'id': 'p1', 'name': 'LumoTest', 'age': 7, 'grade': 2,
            'createdAt': '2026-10-16T12:59:00.000', 'lastActiveAt': profile_seen}),
        'flutter.lumo_progress_skills::p1': '{"plus":2}',
        'flutter.lumo_reward_wallet_v1::p1': wallet,
        'flutter.lumo_kart_launch_v1': '{"launches":1}',
    }
    data.update(extra)
    return data


class LearningStateTests(unittest.TestCase):
    def test_return_keeps_profile_and_learning_data(self):
        report = learning_preserved(prefs(), prefs(profile_seen='2026-10-16T13:05:00.000',
                                                   **{'flutter.lumo_kart_launch_v1': '{"launches":2}'}))
        self.assertEqual(report['profile']['name'], 'LumoTest')
        self.assertEqual(report['learning_keys_compared'], 2)

    def test_lost_or_changed_learning_data_fails(self):
        changed = prefs(wallet='{"stars":0,"xp":0}')
        with self.assertRaisesRegex(RuntimeError, 'changed='):
            learning_preserved(prefs(), changed)
        missing = prefs()
        del missing['flutter.lumo_progress_skills::p1']
        with self.assertRaisesRegex(RuntimeError, 'missing='):
            learning_preserved(prefs(), missing)

    def test_a_different_child_profile_fails(self):
        other = prefs()
        other['flutter.lumo_active_profile'] = json.dumps({'id': 'p2', 'name': 'Andere'})
        with self.assertRaisesRegex(RuntimeError, 'profile changed'):
            learning_preserved(prefs(), other)

    def test_page_must_keep_most_of_its_controls(self):
        before = ['Mathematik', 'Deutsch', 'Englisch', 'Sachunterricht', 'Start', 'Lernen']
        self.assertEqual(labels_still_present(before, before + ['Neu'])['kept_fraction'], 1.0)
        with self.assertRaisesRegex(RuntimeError, 'lost its controls'):
            labels_still_present(before, ['Start'])


if __name__ == '__main__':
    unittest.main()
