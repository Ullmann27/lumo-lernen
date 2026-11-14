"""Original Android media/readbacks plus explicit QA boundary counterexamples.

No Android process is launched here. Synthetic continuations are never device
evidence, and the original ae1 Creative failure remains a failure.
"""
import copy
import hashlib
import importlib.util
import json
import math
from pathlib import Path
import shutil
import subprocess
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location(
    'creative_clock_calibration', ROOT / '.github/probes/studio_creative_android_probe.py')
probe = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(probe)
FIXTURES = Path(__file__).parent / 'fixtures/studio_creative_ae1'
BEFORE = json.loads(next(FIXTURES.glob('0179-treasure-save*.json')).read_text())
AFTER = json.loads(next(FIXTURES.glob('0185-treasure-save*.json')).read_text())
PAUSED = '0182-observe-original-stick.png'
PLAYING = '0183-before-real-input.png'


class StopBeforeUnobservedContinuation(Exception):
    pass


class CreativeClockAndCalibration(unittest.TestCase):
    def test_original_fixture_bytes_and_distinct_source_timestamps(self):
        provenance = json.loads((FIXTURES / 'provenance.json').read_text())
        self.assertEqual(provenance['status'], 'ORIGINAL_ANDROID_FAILURE_RETAINED')
        self.assertEqual(provenance['run_id'], 43592240598)
        for entry in provenance['files']:
            data = (FIXTURES / entry['file']).read_bytes()
            self.assertEqual(len(data), entry['bytes'])
            self.assertEqual(hashlib.sha256(data).hexdigest(), entry['sha256'])
        result = subprocess.run(
            ['ffprobe', '-v', 'error', '-select_streams', 'v:0', '-count_frames',
             '-show_streams', '-show_packets', '-of', 'json',
             str(FIXTURES / 'jump-actual-android.mp4')],
            capture_output=True, text=True, check=True, timeout=30)
        self.assertEqual(result.stderr, '')
        media = json.loads(result.stdout)
        self.assertEqual(media['streams'][0]['time_base'], '1/90000')
        self.assertEqual(int(media['streams'][0]['nb_read_frames']), 86)
        self.assertEqual(len(media['packets']), 86)
        for field in ('dts', 'pts'):
            values = [int(packet[field]) for packet in media['packets']]
            self.assertTrue(all(right > left for left, right in zip(values, values[1:])))

    def test_full_original_video_decodes_without_rewriting_and_truncation_still_fails(self):
        original = FIXTURES / 'jump-actual-android.mp4'
        digest = probe.sha(original)
        with tempfile.TemporaryDirectory() as directory:
            directory = Path(directory)
            log = directory / 'decode.log'
            probe.decode_actual_movie(original, log)
            self.assertEqual(log.read_bytes(), b'')
            self.assertEqual(probe.sha(original), digest)
            broken = directory / 'explicit-truncated-counterexample.mp4'
            data = original.read_bytes()
            broken.write_bytes(data[:len(data) // 2])
            with self.assertRaisesRegex(RuntimeError, 'failed full decode'):
                probe.decode_actual_movie(broken, log)
            self.assertTrue(log.read_bytes())
            self.assertEqual(probe.sha(original), digest)

    def test_original_small_first_step_only_requests_a_bounded_calibration_followup(self):
        inputs = []
        with tempfile.TemporaryDirectory() as directory:
            journal = Path(directory) / 'approach.json'
            def move(axis, duration):
                inputs.append((axis, duration))
                if len(inputs) == 2:
                    raise StopBeforeUnobservedContinuation('No second Android movement is available')
            with self.assertRaises(StopBeforeUnobservedContinuation):
                probe.approach_treasure(copy.deepcopy(BEFORE), move,
                                        lambda: copy.deepcopy(AFTER), journal)
            read = json.loads(journal.read_text())
        self.assertEqual([duration for _, duration in inputs], [1500, 6000])
        self.assertEqual(read['status'], 'FAIL')
        self.assertEqual(read['inputs'][0]['acceptance'], 'CALIBRATION_ONLY')
        self.assertAlmostEqual(read['inputs'][0]['progress'], .010966955559009506)
        self.assertGreater(read['observations'][-1]['distance'], 3.4)
        self.assertEqual(read['last_readback'], AFTER)

    def test_repeated_small_zero_or_away_readback_cannot_be_accepted_progress(self):
        for mode in ('stationary', 'away', 'small-again'):
            with self.subTest(mode=mode), tempfile.TemporaryDirectory() as directory:
                inputs = []
                next_state = copy.deepcopy(AFTER)
                if mode == 'away':
                    next_state['position'] = list(BEFORE['position'])
                elif mode == 'small-again':
                    next_state['position'] = [
                        2 * later - earlier for earlier, later in
                        zip(BEFORE['position'], AFTER['position'])]
                def checkpoint():
                    return copy.deepcopy(AFTER if len(inputs) == 1 else next_state)
                journal = Path(directory) / 'approach.json'
                with self.assertRaisesRegex(RuntimeError, 'progress'):
                    probe.approach_treasure(copy.deepcopy(BEFORE),
                        lambda axis, duration: inputs.append((axis, duration)), checkpoint, journal)
                self.assertEqual(len(inputs), 2)
                self.assertEqual(json.loads(journal.read_text())['status'], 'FAIL')

    def test_first_zero_away_and_changed_identity_still_stop_before_a_second_touch(self):
        for mode in ('stationary', 'away', 'identity'):
            with self.subTest(mode=mode), tempfile.TemporaryDirectory() as directory:
                result = copy.deepcopy(BEFORE if mode == 'stationary' else AFTER)
                if mode == 'away':
                    result['position'] = [
                        2 * earlier - later for earlier, later in
                        zip(BEFORE['position'], AFTER['position'])]
                elif mode == 'identity':
                    result['result_id'] = 'declared-counterexample-only'
                inputs = []
                with self.assertRaises(RuntimeError):
                    probe.approach_treasure(copy.deepcopy(BEFORE),
                        lambda axis, duration: inputs.append((axis, duration)),
                        lambda: result, Path(directory) / 'approach.json')
                self.assertEqual(len(inputs), 1)

    def test_original_playing_and_paused_caption_reads_are_distinguished(self):
        paused = json.loads((FIXTURES / (PAUSED + '.ocr.json')).read_text())
        playing = json.loads((FIXTURES / (PLAYING + '.ocr.json')).read_text())
        self.assertFalse(probe.treasure_playing_captions(paused['lines']))
        self.assertTrue(probe.treasure_playing_captions(playing['lines']))
        self.assertFalse(probe.treasure_playing_captions([]))
        self.assertFalse(probe.treasure_playing_captions([{'text': 'Rucksack'}]))
        self.assertFalse(probe.treasure_playing_captions([{'text': 'ANSEHEN'}]))
        for modal in ('Weiter erkunden', 'Dein Abenteuer wartet', 'Zur Spielewelt',
                      'Dein Abenteuer-Rucksack', 'Dein nächster Hinweis'):
            self.assertFalse(probe.treasure_playing_captions(
                playing['lines'] + [{'text': modal}]))

    def make_observed_tour(self, directory, frames, foreground=None):
        """Explicit capture/read boundary double using untouched original pixels."""
        tour = probe.Tour.__new__(probe.Tour)
        tour.out, tour.counter = Path(directory), 0
        observed = []
        for name in (PAUSED, PLAYING):
            shutil.copyfile(FIXTURES / name, tour.out / name)
        def capture(out, tag, timeout):
            self.assertGreater(timeout, 0)
            name = frames[min(len(observed), len(frames) - 1)]
            observed.append(name)
            return {'file': name, 'sha256': probe.sha(out / name),
                    'width': 1920, 'height': 1080}
        def image_lines(out, tag, source_path, timeout):
            self.assertGreater(timeout, 0)
            return json.loads((FIXTURES / (source_path.name + '.ocr.json')).read_text())['lines']
        tour.probe = SimpleNamespace(
            capture=capture, image_lines=image_lines,
            inspect_surface=lambda path, orientation: {'file': path.name},
            target_observation=lambda frame, bounds, previous: {
                'stable_observed_target': previous is not None,
                'file': frame['file'], 'bounds': bounds})
        tour.base = SimpleNamespace(foreground=lambda: foreground or (
            probe.PACKAGE + '/.LumoGameActivity'))
        return tour, observed

    def test_frame_guard_requires_two_current_playable_frames_after_the_modal(self):
        with tempfile.TemporaryDirectory() as directory:
            tour, observed = self.make_observed_tour(directory, [PAUSED, PLAYING, PLAYING])
            with patch.object(probe.time, 'sleep'):
                target = tour.current_treasure_stick()
            self.assertEqual(observed, [PAUSED, PLAYING, PLAYING])
            self.assertEqual(target['capture']['file'], PLAYING)
            self.assertGreater(target['diameter'], 100)
            journal = json.loads((tour.out / target['playable_frame_journal']).read_text())
            self.assertEqual(journal['status'], 'PLAYABLE_FRAMES_OBSERVED')
            self.assertEqual([row['visible_playing_hud'] for row in journal['observations']],
                             [False, True, True])

    def test_foreign_activity_and_a_persistent_modal_never_allow_stick_input(self):
        for mode in ('foreign', 'modal'):
            with self.subTest(mode=mode), tempfile.TemporaryDirectory() as directory:
                tour, observed = self.make_observed_tour(
                    directory, [PLAYING] if mode == 'foreign' else [PAUSED],
                    foreground='other.package/.MainActivity' if mode == 'foreign' else None)
                with patch.object(probe.time, 'sleep'), self.assertRaises(RuntimeError):
                    tour.current_treasure_stick()
                self.assertEqual(len(observed), 1 if mode == 'foreign' else 6)


if __name__ == '__main__':
    unittest.main()
