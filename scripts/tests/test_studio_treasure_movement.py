"""Controller counterexamples; fixtures are original, continuations are synthetic.

These tests never start Android or Godot and never claim a new game result.
"""
import copy
import hashlib
import importlib.util
import json
import math
from pathlib import Path
import signal
import tempfile
import time
import unittest
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location(
    'treasure_controller_probe', ROOT / '.github/probes/studio_creative_android_probe.py')
probe = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(probe)
FIXTURE = Path(__file__).parent / 'fixtures/treasure_movement_4ab'
ORIGINALS = [json.loads(path.read_text()) for path in sorted(FIXTURE.glob('*treasure-save*.json'))]
EVENTS = [row for row in json.loads((FIXTURE / 'real-input-events.json').read_text())
          if 'axis_direction' in row.get('context', {}) and row['monotonic_seconds'] > 1500]
RATES = [math.dist(a['position'], b['position']) / (int(event['arguments'][-1]) / 1000)
         for a, b, event in zip(ORIGINALS, ORIGINALS[1:], EVENTS)]


class SimulatedTour:
    """Readback/action boundary double, never a simulated Android acceptance."""

    def __init__(self, out, movement='measured_rate_model'):
        self.state = copy.deepcopy(ORIGINALS[0])
        self.movement = movement
        self.inputs, self.actions = [], []
        self.enters = self.leaves = 0
        self.tour = probe.Tour.__new__(probe.Tour)
        self.tour.out = Path(out)
        self.tour.counter = 0
        self.tour.enter = self.enter
        self.tour.leave = self.leave
        self.tour.pause_save = self.checkpoint
        self.tour.saved = self.checkpoint
        self.tour.move_stick = self.move
        self.tour.move_treasure_stick = self.move
        self.tour.native = self.native
        self.tour.shot = lambda label: self.actions.append(('capture', label))

    def enter(self, title, caption):
        self.enters += 1
        self.actions.append(('enter', title, caption))

    def leave(self):
        self.leaves += 1
        self.actions.append(('leave',))

    def checkpoint(self, kind):
        if kind != 'treasure':
            raise AssertionError(kind)
        return copy.deepcopy(self.state)

    def move(self, axis, milliseconds):
        self.inputs.append((list(axis), milliseconds))
        index = len(self.inputs) - 1
        position = self.state['position']
        distance = math.hypot(*axis)
        if self.movement == 'original_readbacks_only':
            self.state = copy.deepcopy(ORIGINALS[index + 1])
            return
        if self.movement == 'stationary':
            step = 0
        elif self.movement == 'away':
            step = -1
        elif self.movement == 'last_segment':
            target_distance = 6 if index == 0 else 6 - index * (2.8 / 11)
            step = distance - target_distance
        elif self.movement == 'bare_progress':
            step = .21
        else:
            # Deliberately synthetic response using the rates measured from
            # each original segment. Changed hold durations are not Android evidence.
            step = RATES[min(index, len(RATES) - 1)] * milliseconds / 1000
        self.state['position'] = [position[0] + axis[0] / distance * step,
                                  position[1],
                                  position[2] + axis[1] / distance * step]
        if self.movement == 'changed_identity':
            self.state['result_id'] = 'different-round'
        if self.movement == 'unearned_clue':
            self.state['solved_clues'] = ['tree']
        if self.movement == 'nonfinite':
            self.state['position'][0] = float('nan')

    def native(self, caption, tap=False, exact=False):
        self.actions.append(('native', caption, tap, exact))
        if caption == 'ANSEHEN':
            position = self.state['position']
            if math.hypot(position[0] + 12, position[2] + 8) > 3.8:
                raise AssertionError('Actual product interaction radius was not reached')
        if caption == 'Ein Tropfen Wasser':
            if not any(action[:2] == ('native', 'ANSEHEN') for action in self.actions):
                raise AssertionError('Answer without interaction')
            self.state['solved_clues'] = ['tree']
            self.state['chapter'] = 1
            self.state['streak'] = self.state['best_streak'] = 1


class TreasureControllerContracts(unittest.TestCase):
    def run_tour(self, simulated):
        with patch.object(probe.time, 'sleep'):
            return probe.Tour.treasure(simulated.tour)

    def test_measured_slow_response_reaches_actual_clue_without_assumed_six_units_per_second(self):
        with tempfile.TemporaryDirectory() as directory:
            simulated = SimulatedTour(directory)
            result = self.run_tour(simulated)
            self.assertEqual(result['status'], 'PASS')
            self.assertEqual(result['first_clue'], 'tree')
            self.assertTrue(result['durable_resume'])
            self.assertLessEqual(len(simulated.inputs), 12)
            self.assertTrue(any(duration > 1500 for _, duration in simulated.inputs))
            self.assertEqual((simulated.enters, simulated.leaves), (2, 2))
            self.assertIn(('native', 'Ein Tropfen Wasser', True, True), simulated.actions)
            self.assertIn(('native', 'Blattschlüssel', False, False), simulated.actions)
            self.assertIn('full treasure journey', result['not_claimed'])

    def test_target_reached_by_twelfth_allowed_segment_is_observed_before_failure(self):
        with tempfile.TemporaryDirectory() as directory:
            simulated = SimulatedTour(directory, 'last_segment')
            result = self.run_tour(simulated)
            self.assertEqual(result['status'], 'PASS')
            self.assertEqual(len(simulated.inputs), 12)
            self.assertLess(math.hypot(simulated.state['position'][0] + 12,
                                      simulated.state['position'][2] + 8), 3.4)

    def test_original_failure_is_never_relabelled_as_a_success(self):
        with tempfile.TemporaryDirectory() as directory:
            simulated = SimulatedTour(directory, 'original_readbacks_only')
            with self.assertRaisesRegex(RuntimeError, 'budget exhausted'):
                self.run_tour(simulated)
            self.assertLessEqual(len(simulated.inputs), 12)
            self.assertEqual(simulated.state['position'], ORIGINALS[len(simulated.inputs)]['position'])
            self.assertFalse(any(action[:2] == ('native', 'ANSEHEN') for action in simulated.actions))
            journal = json.loads((Path(directory) / 'treasure-approach.json').read_text())
            self.assertEqual(journal['status'], 'FAIL')
            self.assertGreaterEqual(journal['observations'][-1]['distance'], 8.4775029017)

    def test_no_progress_and_movement_away_stop_before_another_input(self):
        for mode in ('stationary', 'away'):
            with self.subTest(mode=mode), tempfile.TemporaryDirectory() as directory:
                simulated = SimulatedTour(directory, mode)
                with self.assertRaisesRegex(RuntimeError, 'progress'):
                    self.run_tour(simulated)
                self.assertEqual(len(simulated.inputs), 1)

    def test_round_and_clue_state_cannot_change_during_motion(self):
        for mode in ('changed_identity', 'unearned_clue'):
            with self.subTest(mode=mode), tempfile.TemporaryDirectory() as directory:
                simulated = SimulatedTour(directory, mode)
                with self.assertRaisesRegex(RuntimeError, 'changed during movement'):
                    self.run_tour(simulated)
                self.assertEqual(len(simulated.inputs), 1)

    def test_nonfinite_readback_is_rejected_before_further_touch(self):
        with tempfile.TemporaryDirectory() as directory:
            simulated = SimulatedTour(directory, 'nonfinite')
            with self.assertRaisesRegex(RuntimeError, 'finite'):
                self.run_tour(simulated)
            self.assertEqual(len(simulated.inputs), 1)

    def test_total_held_input_budget_stops_even_with_small_positive_progress(self):
        with tempfile.TemporaryDirectory() as directory:
            simulated = SimulatedTour(directory, 'bare_progress')
            with self.assertRaisesRegex(RuntimeError, 'held-input budget'):
                self.run_tour(simulated)
            self.assertLessEqual(len(simulated.inputs), 12)
            self.assertEqual(sum(duration for _, duration in simulated.inputs), 60000)
            self.assertTrue(all(220 <= duration <= 6000 for _, duration in simulated.inputs))

    def test_wallclock_deadline_interrupts_a_stalled_checkpoint_and_restores_signal(self):
        if not hasattr(signal, 'setitimer'):
            self.fail('The Android CI controller requires a Linux real-time timer')
        with tempfile.TemporaryDirectory() as directory:
            simulated = SimulatedTour(directory)
            previous = signal.getsignal(signal.SIGALRM)
            def stalled():
                time.sleep(2)
            started = time.monotonic()
            with self.assertRaisesRegex(TimeoutError, 'wall-clock budget'):
                probe.approach_treasure(ORIGINALS[0], simulated.move, stalled,
                                        Path(directory) / 'treasure-approach.json', timeout_seconds=.05)
            self.assertLess(time.monotonic() - started, 1)
            self.assertEqual(signal.getsignal(signal.SIGALRM), previous)
            self.assertEqual(signal.getitimer(signal.ITIMER_REAL), (0.0, 0.0))
            self.assertEqual(len(simulated.inputs), 1)

    def test_no_pending_external_alarm_is_silently_replaced(self):
        with tempfile.TemporaryDirectory() as directory:
            simulated = SimulatedTour(directory)
            signal.setitimer(signal.ITIMER_REAL, 30)
            try:
                with self.assertRaisesRegex(RuntimeError, 'existing alarm'):
                    probe.approach_treasure(ORIGINALS[0], simulated.move,
                                            lambda: simulated.checkpoint('treasure'),
                                            Path(directory) / 'treasure-approach.json')
                self.assertEqual(simulated.inputs, [])
                self.assertGreater(signal.getitimer(signal.ITIMER_REAL)[0], 20)
            finally:
                signal.setitimer(signal.ITIMER_REAL, 0)

    def test_touch_uses_fresh_observed_ring_and_bounded_hold(self):
        tour = probe.Tour.__new__(probe.Tour)
        target = {'center': [400, 500], 'diameter': 200, 'capture': {'file': 'actual-frame.png'}}
        tour.current_stick = lambda: copy.deepcopy(target)
        sent = []
        tour.touch = lambda point, context, milliseconds: sent.append((point, context, milliseconds))
        tour.move_treasure_stick([-3, -4], 6000)
        self.assertEqual(len(sent), 1)
        self.assertAlmostEqual(sent[0][0][0], 356.8)
        self.assertAlmostEqual(sent[0][0][1], 442.4)
        self.assertEqual(sent[0][1]['capture']['file'], 'actual-frame.png')
        self.assertEqual(sent[0][2], 6000)
        for duration in (0, 219, 6001):
            with self.assertRaises(RuntimeError):
                tour.move_treasure_stick([-3, -4], duration)
        self.assertEqual(len(sent), 1)

    def test_original_fixture_bytes_and_observed_progress_remain_exact(self):
        provenance = json.loads((FIXTURE / 'provenance.json').read_text())
        for row in provenance['files']:
            raw = (FIXTURE / row['file']).read_bytes()
            self.assertEqual(len(raw), row['bytes'])
            self.assertEqual(hashlib.sha256(raw).hexdigest(), row['sha256'])
        self.assertEqual(len(ORIGINALS), 13)
        self.assertEqual(len(EVENTS), 12)
        self.assertEqual(sum(int(row['arguments'][-1]) for row in EVENTS), 17126)
        distances = [math.hypot(row['position'][0] + 12, row['position'][2] + 8)
                     for row in ORIGINALS]
        self.assertTrue(all(after < before for before, after in zip(distances, distances[1:])))
        self.assertGreater(distances[-1], 3.8)


if __name__ == '__main__':
    unittest.main()
