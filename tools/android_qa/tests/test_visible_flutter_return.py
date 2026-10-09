"""A dead Godot process and an old PNG cannot prove a visible host return."""
import copy
from pathlib import Path
import sys
import unittest
import xml.etree.ElementTree as ET

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from flutter_return_readiness import SHELL_CAPTIONS, return_observation, shell_bounds, wait_flutter_return

PACKAGE = 'dev.ullmann.lumo.lumo_lernen.coachpreview'


def observed(index=0):
    boxes = {caption: [20+i*120, 700, 120+i*120, 780] for i, caption in enumerate(SHELL_CAPTIONS)}
    return {'foreground': 'mResumedActivity: ActivityRecord{123 '+PACKAGE+'/dev.ullmann.lumo.lumo_lernen.MainActivity t42}',
            'native_process': '', 'capture': {'file': f'fresh-{index}.png'}, 'xml_file': f'fresh-{index}.xml',
            'surface': {'complete_png': True, 'pixels': [1080, 1920], 'source_sha256': 'c'*64,
                        'blank_edge_columns': {'left': 0, 'right': 0}},
            'semantics': boxes, 'pixel_captions': {caption: {'matches': [box], 'source_png_sha256': 'c'*64}
                                                  for caption, box in boxes.items()}}


class VisibleFlutterReturnTests(unittest.TestCase):
    def test_one_current_full_host_frame_is_insufficient_but_two_fresh_frames_pass(self):
        first = return_observation(observed(), PACKAGE)
        self.assertTrue(first['valid'])
        self.assertFalse(first['stable'])
        self.assertTrue(return_observation(observed(1), PACKAGE, first)['stable'])

    def test_stopped_native_process_with_native_activity_foreground_is_not_host_return(self):
        row = observed()
        row['foreground'] = row['foreground'].replace('MainActivity', 'LumoGameActivity')
        self.assertFalse(return_observation(row, PACKAGE)['valid'])

    def test_foreign_or_ambiguous_resumed_activity_does_not_pass_package_substring_check(self):
        for extra in ('\ntopResumedActivity: ActivityRecord{abc other.package/.MainActivity t2}',
                      '\ntopResumedActivity: null'):
            row = observed()
            row['foreground'] += extra
            with self.subTest(extra=extra):
                self.assertFalse(return_observation(row, PACKAGE)['valid'])

    def test_foreign_package_prefix_cannot_impersonate_the_expected_host(self):
        row = observed()
        row['foreground'] = row['foreground'].replace(PACKAGE+'/', 'evil.'+PACKAGE+'/')
        self.assertFalse(return_observation(row, PACKAGE)['valid'])

    def test_relative_component_must_resolve_to_the_real_android_namespace_class(self):
        row = observed()
        row['foreground'] = row['foreground'].replace('/dev.ullmann.lumo.lumo_lernen.MainActivity', '/.MainActivity')
        self.assertFalse(return_observation(row, PACKAGE)['valid'])
        root_package = PACKAGE.removesuffix('.coachpreview')
        row['foreground'] = row['foreground'].replace(PACKAGE+'/', root_package+'/')
        self.assertTrue(return_observation(row, root_package)['valid'])

    def test_live_flutter_semantics_with_stale_godot_pixels_cannot_pass(self):
        row = observed()
        row['pixel_captions'] = {}
        result = return_observation(row, PACKAGE)
        self.assertFalse(result['valid'])
        self.assertIn('current screenshot pixels do not confirm the live Flutter captions', result['reasons'])

    def test_previous_frame_ocr_cannot_confirm_a_new_capture(self):
        row = observed()
        row['pixel_captions']['start']['source_png_sha256'] = 'd'*64
        self.assertFalse(return_observation(row, PACKAGE)['valid'])

    def test_live_native_process_partial_png_or_blank_compositor_frame_do_not_pass(self):
        rows = [observed(), observed(), observed()]
        rows[0]['native_process'] = '9171'
        rows[1]['surface']['complete_png'] = False
        rows[2]['surface']['blank_edge_columns']['right'] = 250
        for row in rows:
            with self.subTest(row=row):
                self.assertFalse(return_observation(row, PACKAGE)['valid'])

    def test_same_saved_xml_or_png_cannot_be_reused_as_the_second_observation(self):
        first = return_observation(observed(), PACKAGE)
        for key in ('xml_file', 'capture'):
            row = observed(1)
            row[key] = copy.deepcopy(observed()[key])
            with self.subTest(key=key):
                self.assertFalse(return_observation(row, PACKAGE, first)['stable'])

    def test_orientation_or_caption_geometry_change_requires_two_new_stable_frames(self):
        first = return_observation(observed(), PACKAGE)
        for kind in ('pixels', 'bounds'):
            row = observed(1)
            if kind == 'pixels':
                row['surface']['pixels'] = [1920, 1080]
            else:
                row['semantics']['start'][0] += 13
            with self.subTest(kind=kind):
                self.assertFalse(return_observation(row, PACKAGE, first)['stable'])

    def test_invalid_frame_interrupts_the_stable_sequence(self):
        first = return_observation(observed(), PACKAGE)
        bad = observed(1)
        bad['pixel_captions'] = {}
        previous = return_observation(bad, PACKAGE, first)
        self.assertFalse(return_observation(observed(2), PACKAGE, previous)['stable'])

    def test_shell_semantics_require_current_package_enabled_clickable_and_actual_in_surface_bounds(self):
        root = ET.Element('hierarchy')
        for i, caption in enumerate(SHELL_CAPTIONS):
            ET.SubElement(root, 'node', {'package': PACKAGE, 'enabled': 'true', 'clickable': 'true',
                'content-desc': caption+'\n'+caption, 'bounds': f'[{20+i*120},700][{120+i*120},780]'})
        self.assertEqual(set(shell_bounds(root, PACKAGE, [1080, 1920])), set(SHELL_CAPTIONS))
        first = next(root.iter('node'))
        for key, value in (('package', 'other.package'), ('enabled', 'false'), ('clickable', 'false'),
                           ('visible-to-user', 'false'),
                           ('bounds', '[20,1900][120,2100]')):
            changed = copy.deepcopy(root)
            next(changed.iter('node')).set(key, value)
            with self.subTest(key=key):
                self.assertNotIn('start', shell_bounds(changed, PACKAGE, [1080, 1920]))

    def test_distinct_duplicate_semantics_are_ambiguous(self):
        root = ET.Element('hierarchy')
        for box in ('[20,700][120,780]', '[200,700][300,780]'):
            ET.SubElement(root, 'node', {'package': PACKAGE, 'clickable': 'true',
                                       'content-desc': 'Start', 'bounds': box})
        self.assertNotIn('start', shell_bounds(root, PACKAGE, [1080, 1920]))

    def test_bounded_poll_preserves_waiting_frames_and_accepts_only_two_actual_observations(self):
        clock = [0.0]
        rows = [observed(), observed(1), observed(2)]
        rows[0]['pixel_captions'] = {}
        records, calls = [], []

        def observe(index, timeout):
            calls.append((index, timeout))
            return rows[index]

        result = wait_flutter_return(observe, lambda value: records.append(copy.deepcopy(value)), PACKAGE,
                                     timeout=10, clock=lambda: clock[0], sleep=lambda value: clock.__setitem__(0, clock[0]+value))
        self.assertEqual(result['status'], 'PASS')
        self.assertEqual([row['valid'] for row in result['observations']], [False, True, True])
        self.assertEqual([row['stable'] for row in result['observations']], [False, False, True])
        self.assertEqual(calls, [(0, 10), (1, 9.5), (2, 9)])
        self.assertEqual(records[-1], result)

    def test_permanent_stale_pixels_fail_without_navigation_or_restart(self):
        clock, records, calls = [0.0], [], []

        def observe(index, timeout):
            calls.append((index, timeout))
            row = observed(index)
            row['pixel_captions'] = {}
            return row

        with self.assertRaisesRegex(TimeoutError, 'Two fresh visible Flutter frames'):
            wait_flutter_return(observe, lambda value: records.append(copy.deepcopy(value)), PACKAGE,
                                timeout=1, clock=lambda: clock[0], sleep=lambda value: clock.__setitem__(0, clock[0]+value))
        self.assertEqual(clock[0], 1)
        self.assertEqual(records[-1]['status'], 'FAIL')
        self.assertEqual(len(calls), 2)

    def test_late_successful_read_cannot_extend_the_total_deadline(self):
        clock, records = [0.0], []

        def observe(index, timeout):
            clock[0] += timeout
            return observed(index)

        with self.assertRaisesRegex(TimeoutError, 'total deadline'):
            wait_flutter_return(observe, lambda value: records.append(copy.deepcopy(value)), PACKAGE,
                                timeout=10, clock=lambda: clock[0], sleep=lambda value: None)
        self.assertEqual(clock[0], 10)
        self.assertEqual(records[-1]['status'], 'FAIL')


if __name__ == '__main__':
    unittest.main()
