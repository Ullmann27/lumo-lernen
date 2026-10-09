"""Execute the actual shared exit tail against controlled read-only frames.

These are host I/O controls, not an Android rerun or a genuine Flutter capture.
The existing two-frame readiness validator runs unchanged. Invalid pixel and
hierarchy observations are deliberately fault-injected; a real native pause
PNG is reused for stale-compositor cases.
"""
import ast
import copy
import hashlib
from io import BytesIO
import json
from pathlib import Path
import sys
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import flutter_return_readiness as readiness
from test_visible_flutter_return import PACKAGE, observed

ROOT = Path(__file__).resolve().parents[3]
PROBE_PATH = ROOT / '.github/probes/creative_android_probe.py'
FIXTURES = Path(__file__).with_name('fixtures')
REAL_WAIT = readiness.wait_flutter_return


class ControlledExit:
    def __init__(self, root, *, rows=None, foreground=None, native_pid='',
                 budget=1.5, after_wait=None, late_read=False):
        self.out = root
        self.rows = rows or [observed(), observed(1)]
        self.foreground_text = foreground or observed()['foreground']
        self.native_pid = native_pid
        self.budget = budget
        self.after_wait = after_wait
        self.late_read = late_read
        self.now = 0.0
        self.inputs = []
        self.pid_reads = 0
        self.captures = []
        self.observations = []
        self.sleeps = []
        self.base = SimpleNamespace(adb=self.adb, foreground=lambda: self.foreground_text)
        self.time = SimpleNamespace(sleep=self.sleep, monotonic=lambda: self.now)
        image = root / 'controlled-host.png'
        Image.new('RGB', tuple(self.rows[0]['surface']['pixels']), (14,47,72)).save(image)
        self.host_bytes = image.read_bytes()
        if not self.rows[0]['pixel_captions']:
            self.host_bytes = (FIXTURES /
                'kart-compact-pause/godot-kart-pause-800x480.png').read_bytes()

    def sleep(self, seconds):
        self.sleeps.append(seconds)
        self.now += seconds

    def adb(self, *args, **kwargs):
        if args[:2] == ('shell', 'pidof'):
            self.pid_reads += 1
            return self.native_pid
        self.inputs.append((args, kwargs))
        return ''

    def native_text(self, out, label, tag, **kwargs):
        self.inputs.append(('native_text', label, tag, kwargs))

    def capture(self, out, tag, timeout=None):
        self.captures.append((str(out), tag, timeout))
        path = out / (tag+'.png')
        path.write_bytes(self.host_bytes)
        with Image.open(BytesIO(self.host_bytes)) as image:
            width, height = image.size
        return {'file':path.name,'width':width,'height':height,
                'sha256':hashlib.sha256(self.host_bytes).hexdigest()}

    def observe(self, base, capture_api, out, package, index, *, timeout):
        assert base is self.base and package == PACKAGE
        row = copy.deepcopy(self.rows[min(index, len(self.rows)-1)])
        buffer = BytesIO()
        Image.new('RGB', tuple(row['surface']['pixels']), (14,47,72)).save(buffer, format='PNG')
        source = buffer.getvalue()
        if not row['pixel_captions']:
            source = (FIXTURES / 'kart-compact-pause/godot-kart-pause-800x480.png').read_bytes()
        tag = f'13-flutter-return-{index:02d}'
        self.host_bytes = source
        capture = capture_api.capture(out, tag, timeout=timeout)
        xml = out / (tag+'.xml')
        xml.write_text((FIXTURES/'home-api35-37121358107.xml').read_text())
        if row.pop('reuse_first_paths', False) and index:
            row['capture'] = {'file':'13-flutter-return-00.png'}
            row['xml_file'] = '13-flutter-return-00.xml'
        else:
            row['capture'] = capture
            row['xml_file'] = xml.name
        digest = hashlib.sha256(source).hexdigest()
        old = row['surface']['source_sha256']
        row['surface']['source_sha256'] = digest
        row['surface']['pixels'] = [capture['width'],capture['height']]
        for entry in row['pixel_captions'].values():
            if entry['source_png_sha256'] == old:
                entry['source_png_sha256'] = digest
        self.now += timeout if self.late_read else .1
        self.observations.append(copy.deepcopy(row))
        return row

    def wait(self, observe, record, package, **kwargs):
        result = REAL_WAIT(observe, record, package, timeout=self.budget,
                           clock=lambda:self.now, sleep=self.sleep)
        if self.after_wait:
            self.after_wait(self, result)
        return result

    def leave(self, *, tag='exit', already_menu=False):
        module = ast.parse(PROBE_PATH.read_text())
        actual = next(node for node in module.body
                      if isinstance(node, ast.FunctionDef) and node.name == 'leave')
        namespace = {'Path':Path,'time':self.time,'base':self.base,
                     'native_text':self.native_text,'capture':self.capture,
                     'PACKAGE':PACKAGE,'json':json,'hashlib':hashlib}
        exec(compile(ast.Module(body=[actual],type_ignores=[]), str(PROBE_PATH), 'exec'),
             namespace)
        with patch.object(readiness, 'observe_flutter_return', self.observe), \
                patch.object(readiness, 'wait_flutter_return', self.wait):
            namespace['leave'](self.out, tag, already_menu=already_menu)

    def journal(self, tag='exit'):
        return json.loads((self.out/(tag+'-flutter-return.json')).read_text())


class SharedCreativeExitTests(unittest.TestCase):
    def control(self, **kwargs):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        return ControlledExit(Path(directory.name), **kwargs)

    def assert_rejected(self, row, *, foreground=None):
        control = self.control(rows=[row], foreground=foreground)
        with self.assertRaises(TimeoutError):
            control.leave()
        self.assertFalse((control.out/'exit-returned-to-app.png').exists())
        self.assertEqual(control.journal()['status'], 'FAIL')
        return control

    def test_stopped_pid_and_host_activity_cannot_publish_existing_native_pause_pixels(self):
        row = observed()
        row['pixel_captions'] = {}
        control = self.assert_rejected(row)
        self.assertFalse(control.native_pid)
        self.assertIn('MainActivity', control.foreground_text)
        self.assertTrue(control.observations)

    def test_wrong_foreground_or_package_prefix_cannot_publish_return(self):
        for value in ('other.package/.MainActivity',
                      'evil.'+PACKAGE+'/dev.ullmann.lumo.lumo_lernen.MainActivity'):
            row = observed()
            row['foreground'] = 'mResumedActivity: ActivityRecord{abc '+value+' t2}'
            with self.subTest(value=value):
                self.assert_rejected(row, foreground=row['foreground'])

    def test_empty_or_ambiguous_live_flutter_semantics_cannot_publish_return(self):
        for semantics in ({}, {'start':[1,1,2,2]}):
            row = observed()
            row['semantics'] = semantics
            with self.subTest(semantics=semantics):
                self.assert_rejected(row)

    def test_partial_or_blank_compositor_frame_cannot_publish_return(self):
        for field in ('partial','blank'):
            row = observed()
            if field == 'partial':
                row['surface']['complete_png'] = False
            else:
                row['surface']['blank_edge_columns']['right'] = 250
            with self.subTest(field=field):
                self.assert_rejected(row)

    def test_previous_screenshot_ocr_cannot_confirm_current_pixels(self):
        row = observed()
        row['pixel_captions']['start']['source_png_sha256'] = 'd'*64
        self.assert_rejected(row)

    def test_same_xml_and_png_paths_do_not_create_a_fresh_second_frame(self):
        row = observed()
        row['reuse_first_paths'] = True
        self.assert_rejected(row)

    def test_single_valid_frame_cannot_be_published(self):
        control = self.control(budget=.2)
        with self.assertRaises(TimeoutError):
            control.leave()
        self.assertEqual(len(control.observations), 1)
        self.assertFalse((control.out/'exit-returned-to-app.png').exists())

    def test_late_valid_observation_cannot_extend_shared_wait_deadline(self):
        control = self.control(late_read=True)
        with self.assertRaisesRegex(TimeoutError, 'total deadline'):
            control.leave()
        self.assertFalse((control.out/'exit-returned-to-app.png').exists())
        self.assertEqual(control.journal()['status'], 'FAIL')

    def test_rotation_transition_requires_two_new_stable_frames(self):
        rows = [observed(), observed(1), observed(2)]
        rows[0]['surface']['pixels'] = [1920,1080]
        control = self.control(rows=rows)
        control.leave()
        journal = control.journal()
        self.assertEqual([r['stable'] for r in journal['observations']], [False,False,True])
        self.assertEqual(len(control.captures), 3)

    def test_moving_caption_geometry_requires_two_new_stable_frames(self):
        rows = [observed(), observed(1), observed(2)]
        rows[0]['semantics']['start'][0] += 13
        control = self.control(rows=rows)
        control.leave()
        self.assertEqual([r['stable'] for r in control.journal()['observations']],
                         [False,False,True])

    def test_valid_portrait_pair_reuses_inspected_png_without_third_capture(self):
        control = self.control()
        control.leave()
        journal = control.journal()
        self.assertEqual(journal['status'], 'PASS')
        self.assertEqual(len(control.captures), 2)
        self.assertEqual(journal['published_capture']['pixels'], [1080,1920])
        source = control.out / journal['published_capture']['source_file']
        published = control.out / journal['published_capture']['file']
        self.assertEqual(published.read_bytes(), source.read_bytes())
        self.assertEqual(hashlib.sha256(published.read_bytes()).hexdigest(),
                         journal['published_capture']['sha256'])
        self.assertEqual(control.inputs[0][0],
                         ('shell','input','keyevent','KEYCODE_BACK'))
        self.assertEqual(control.inputs[1][1], 'Zur Spielewelt')
        self.assertEqual(len(control.inputs), 2)

    def test_valid_landscape_pair_is_not_forced_to_portrait(self):
        rows = [observed(), observed(1)]
        for row in rows:
            row['surface']['pixels'] = [1920,1080]
        control = self.control(rows=rows)
        control.leave()
        self.assertEqual(control.journal()['published_capture']['pixels'], [1920,1080])
        self.assertEqual(len(control.captures), 2)

    def test_existing_native_pid_stop_guard_is_preserved(self):
        control = self.control(native_pid='9171')
        with self.assertRaisesRegex(RuntimeError, 'Private game process did not stop'):
            control.leave()
        self.assertEqual(control.pid_reads, 15)
        self.assertFalse(control.captures)
        self.assertFalse(control.observations)

    def test_existing_native_activity_guard_is_preserved(self):
        control = self.control(foreground=observed()['foreground'].replace(
            'MainActivity', 'LumoGameActivity'))
        with self.assertRaisesRegex(RuntimeError, 'Game activity is still foreground'):
            control.leave()
        self.assertFalse(control.captures)
        self.assertFalse(control.observations)

    def test_changed_accepted_png_before_publication_fails_with_raw_readiness_retained(self):
        def change(control, result):
            frame = result['observations'][-1]['observed']['capture']['file']
            (control.out/'exit-flutter-return'/frame).write_bytes(b'changed-after-inspection')
        control = self.control(after_wait=change)
        with self.assertRaisesRegex(RuntimeError, 'changed before publication'):
            control.leave()
        self.assertFalse((control.out/'exit-returned-to-app.png').exists())
        self.assertEqual(control.journal()['status'], 'FAIL')
        self.assertEqual(len(control.journal()['observations']), 2)

    def test_old_published_path_cannot_be_overwritten_as_new_evidence(self):
        control = self.control()
        old = control.out/'exit-returned-to-app.png'
        old.write_bytes(b'old-evidence')
        with self.assertRaisesRegex(RuntimeError, 'fresh evidence path'):
            control.leave()
        self.assertEqual(old.read_bytes(), b'old-evidence')
        self.assertEqual(control.journal()['status'], 'FAIL')

    def test_already_menu_does_not_add_another_back_action(self):
        control = self.control()
        control.leave(already_menu=True)
        self.assertEqual(len(control.inputs), 1)
        self.assertEqual(control.inputs[0][1], 'Zur Spielewelt')
        self.assertEqual(len(control.captures), 2)

    def test_distinct_shared_exit_calls_keep_unique_fresh_observation_paths(self):
        control = self.control()
        control.leave(tag='build-exit')
        control.leave(tag='puzzle-exit')
        for tag in ('build-exit','puzzle-exit'):
            self.assertEqual(control.journal(tag)['status'], 'PASS')
        self.assertEqual(len(control.captures), 4)
        self.assertEqual(len({out for out,_,_ in control.captures}), 2)


if __name__ == '__main__':
    unittest.main()
