"""Synthetic negative contracts; these files are never actual Android acceptance."""
from __future__ import annotations

import copy
import csv
import hashlib
import json
from pathlib import Path
import sys
import tempfile
import unittest
import xml.etree.ElementTree as ET
from PIL import Image, ImageChops

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
sys.path.insert(0, str(Path(__file__).resolve().parent))
import connect_four_android_evidence as c4
import village_android_evidence as village
from native_surface_readiness import inspect_surface, target_observation
from native_ocr_tiles import observed_matches, tile_boxes
from test_connect_four_android_evidence import SyntheticEvidence, STUDENT, prefs, state


class SyntheticVillage(SyntheticEvidence):
    """Original-file fixture for verifier execution, not a device/scene simulator."""
    def preferences(self):
        result = prefs(state())
        result['flutter.lumo_3d_profile_keys_v1'] = json.dumps({'version': 1,
            'legacyAvailable': False, 'owners': {STUDENT: 'p_'+'d'*32}, 'legacy': {}})
        result['flutter.lumo_3d_save_salt_v1'] = 'synthetic-only-salt'
        return result

    def preferences_original(self, tag, values=None):
        tree = ET.Element('map')
        for key, value in (values or self.preferences()).items():
            ET.SubElement(tree, 'string', {'name': key}).text = value
        return self.original(tag, ['adb', 'exec-out', 'cat', village.PREFS], ET.tostring(tree))

    def process(self, tag, *, native):
        return {
            'host_pid': self.original(tag+'-host', ['adb', 'shell', 'pidof', c4.PACKAGE], '100\n'),
            'native_pid': self.original(tag+'-native', ['adb', 'shell', 'pidof', c4.PACKAGE+':lumo_game'],
                                        '200\n' if native else '', rc=0 if native else 1),
            'activity': self.original(tag+'-activity', ['adb', 'shell', 'dumpsys', 'activity', 'activities'],
                'mResumedActivity: '+c4.PACKAGE+'/.'+('LumoGameActivity' if native else 'MainActivity')+'\n'),
            'preferences': self.preferences_original(tag+'-preferences'),
        }

    def ocr(self, tag, text):
        words = text.split()
        x, y, scale = 40, 60, 2
        header = 'level\tpage_num\tblock_num\tpar_num\tline_num\tword_num\tleft\ttop\twidth\theight\tconf\ttext\n'
        rows = []
        start = x
        for i, word in enumerate(words):
            width = len(word)*12
            rows.append(f'5\t1\t1\t1\t1\t{i+1}\t{x*scale}\t{y*scale}\t{width*scale}\t60\t95\t{word}\n')
            x += width+10
        bounds = [start, y, x-10, y+30]
        self.write(tag+'-ocr-raw.tsv', header+''.join(rows))
        self.write(tag+'-ocr.json', [{'text': text, 'bounds': bounds, 'variant': 'raw'}])
        return bounds

    def marker(self):
        return {'scene': village.SCENE, 'mode': 'settlement', 'living_village': True,
                'host_entry': True, 'return_scene': 'games', 'save_blocked': False, 'slot': 1,
                'save_path': 'user://lumo_settlement_'+hashlib.sha256(('p_'+'d'*32).encode()).hexdigest()+'_1_village.json',
                'plots': 9, 'population': 2, 'visible_residents': 2, 'initialized_plot_nodes': 9}

    def fallback(self, tag, image_name, *, tiled):
        image = Image.open(self.root/image_name).convert('RGB')
        box = list(tile_boxes(*image.size)[0]) if tiled else [10, 20, 300, 140]
        scale = 3 if tiled else 1
        variant = 'white-latin-tile-0' if tiled else 'gold-component-0'
        prefix = tag+'-ocr-'+variant
        if tiled:
            red, green, blue = image.split()
            darkest = ImageChops.darker(ImageChops.darker(red, green), blue)
            lightest = ImageChops.lighter(ImageChops.lighter(red, green), blue)
            bright = darkest.point(lambda value: 255 if value >= 150 else 0)
            neutral = ImageChops.subtract(lightest, darkest).point(lambda value: 255 if value <= 45 else 0)
            pixels = ImageChops.invert(ImageChops.multiply(bright, neutral)).crop(box)
            pixels = pixels.resize((pixels.width*scale, pixels.height*scale))
        else:
            pixels = image.crop(box)
        pixels.save(self.root/(prefix+'.png'))
        tsv = ('level\tpage_num\tblock_num\tpar_num\tline_num\tword_num\tleft\ttop\twidth\theight\tconf\ttext\n'
               f'5\t1\t1\t1\t1\t1\t{20*scale}\t{30*scale}\t{72*scale}\t{30*scale}\t95\tSpiele\n')
        self.write(prefix+'.tsv', tsv)
        matches = observed_matches(csv.DictReader(tsv.splitlines(), delimiter='\t', quoting=csv.QUOTE_NONE),
                                   tuple(box), scale, image.size, 'spiele', village.normalized, variant)
        entry = {'index': 0, 'bounds': box, 'image': prefix+'.png', 'tsv': prefix+'.tsv',
                 'scale': scale, 'psm': 6, 'status': 'READ', 'matches': matches}
        journal = {'status': 'READ', 'matched': True, 'source': image_name,
                   'source_sha256': c4.sha256(self.root/image_name), 'surface': list(image.size),
                   'wanted': 'spiele', 'confidence_minimum': 15,
                   'components' if not tiled else 'tiles': [entry], 'matches': matches,
                   'observed_component_boxes': [box], 'tile_scale': 3}
        self.write(tag+('-ocr-tiles.json' if tiled else '-ocr-components.json'), journal)
        self.write(tag+'-ocr.json', matches)
        return matches[0]['bounds']

    def log(self, marker):
        return '11-14 12:34:56.123   200   201 I godot   : '+village.MARKER+json.dumps(marker)+'\n'

    def replace_original(self, name, raw, *, returncode=None):
        self.write(name, raw)
        meta = json.loads((self.root/(name[:-7]+'.json')).read_text())
        data = (self.root/name).read_bytes()
        meta.update(stdout_bytes=len(data), stdout_sha256=hashlib.sha256(data).hexdigest())
        if returncode is not None:
            meta['returncode'] = returncode
        self.write(name[:-7]+'.json', meta)

    def build(self):
        self.report = {'schema': 1, 'status': 'PASS', 'binding': self.binding, 'identity': self.identity,
                       'prior_tour': {'sha256': 'e'*64}, 'fatal_entries': []}
        self.report['android_sdk_original'] = self.original('sdk', ['adb', 'shell', 'getprop', 'ro.build.version.sdk'], '35\n')
        self.report['before'] = self.process('before', native=False)
        self.report['entry_touch'] = self.flutter_touch('entry', village.PORTAL)
        native = self.process('native', native=True)
        native['marker'] = self.marker()
        native['logcat'] = self.original('native-logcat', ['adb', 'logcat', '-b', 'all', '--pid', '200', '-d', '-v', 'threadtime'], self.log(native['marker']))
        native['frame'] = self.screenshot('actual-native-fixture')
        native['hud_ocr'] = []
        for i, wanted in enumerate(village.HUD):
            tag = 'native-hud-'+str(i)
            self.ocr(tag, wanted)
            native['hud_ocr'].append(tag)
        self.report['native'] = native
        returned = self.process('returned', native=False)
        returned['native_before_return'] = self.process('native-before-return', native=True)
        frames, previous = [], None
        for i in (1, 2):
            image = self.screenshot('return-target-'+str(i))
            frame = inspect_surface(self.root/image['file'], orientation='responsive')
            frame['captured_after_seconds'] = i
            bounds = self.ocr(Path(image['file']).stem, '‹ Spiele')
            frame['target'] = target_observation(frame, bounds, previous)
            previous = frame['target']
            frames.append(frame)
        point = [round((bounds[0]+bounds[2])/2), round((bounds[1]+bounds[3])/2)]
        returned['touch_journal'] = self.write('return-surface-readiness.json', {
            'status': 'TOUCH_SENT', 'label': 'Spiele', 'exact_caption_required': True,
            'orientation_policy': 'responsive', 'frames': frames,
            'final_observed_bounds': bounds, 'touch': point})
        x, y = map(str, point)
        returned['command_original'] = self.original('return-input', ['adb', 'shell', 'input', 'swipe', x, y, x, y, '120'], '')
        returned['frame'] = self.screenshot('returned-flutter')
        returned['visible_ocr'] = 'returned-visible'
        self.ocr(returned['visible_ocr'], 'Spielen')
        tree = ET.Element('hierarchy')
        ET.SubElement(tree, 'node', {'package': c4.PACKAGE, 'enabled': 'true', 'text': 'Spielen'})
        returned['ui'] = self.write('returned-ui.xml', ET.tostring(tree))
        self.report['returned'] = returned
        self.report['original_logcat'] = self.original('all-buffer-logcat', ['adb', 'logcat', '-b', 'all', '-d', '-v', 'threadtime'], self.log(native['marker'])+'11-14 12:35:56.123   200   201 I godot   : '+village.RETURN_MARKER+'\n')
        self.refresh()
        return self.report

    def refresh(self):
        self.report['originals'] = [{'path': p.relative_to(self.root).as_posix(),
            'bytes': p.stat().st_size, 'sha256': c4.sha256(p)} for p in sorted(self.root.rglob('*'))
            if p.is_file() and p != self.root/village.REPORT]
        self.write(village.REPORT, self.report)


class VillageOriginalEvidenceTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.fixture = SyntheticVillage(self.root)
        self.report = self.fixture.build()

    def verify(self):
        return village.verify_report(self.root, self.fixture.binding, self.fixture.identity)

    def reject(self, edit, message=None):
        edit()
        self.fixture.refresh()
        with self.assertRaises((ValueError, FileNotFoundError, KeyError, json.JSONDecodeError)):
            self.verify()

    def test_complete_original_fixture_replays_actual_gates_without_device_claim(self):
        value = self.verify()
        self.assertEqual(value['status'], 'PASS')
        self.assertEqual((value['host_pid'], value['native_pid']), (100, 200))
        self.assertTrue(value['native_process_ended'])
        self.assertEqual(value['raw_report_sha256'], c4.sha256(self.root/village.REPORT))

    def test_restored_developed_village_can_have_no_residents_in_current_camera(self):
        marker = self.report['native']['marker']
        marker.update(plots=49, population=32, visible_residents=0, initialized_plot_nodes=25)
        self.fixture.replace_original(self.report['native']['logcat'], self.fixture.log(marker))
        self.fixture.refresh()
        self.assertEqual(self.verify()['status'], 'PASS')

    def test_missing_or_failed_report_is_rejected(self):
        self.reject(lambda: self.report.update(status='FAIL'))
        (self.root/village.REPORT).unlink()
        with self.assertRaises(ValueError):
            self.verify()

    def test_other_source_native_attempt_or_apk_is_rejected(self):
        original = copy.deepcopy(self.report)
        for section, field, value in (('binding', 'host_source', 'f'*40),
            ('binding', 'native_source', 'f'*40), ('binding', 'run_attempt', 2),
            ('identity', 'apk_sha256', 'f'*64)):
            with self.subTest(section=section, field=field):
                self.report.clear(); self.report.update(copy.deepcopy(original))
                self.reject(lambda: self.report[section].update({field: value}))

    def test_exact_api35_original_is_required(self):
        self.reject(lambda: self.fixture.replace_original(self.report['android_sdk_original'], '34\n'))

    def test_native_process_must_be_absent_before_real_flutter_tap(self):
        self.reject(lambda: self.fixture.replace_original(self.report['before']['native_pid'], '200\n', returncode=0))

    def test_native_pid_must_be_distinct_and_alive(self):
        self.reject(lambda: self.fixture.replace_original(self.report['native']['native_pid'], '100\n'))

    def test_marker_pid_cannot_be_another_or_unattributed_process(self):
        original = self.fixture.log(self.report['native']['marker'])
        for raw in (original.replace('   200 ', '   999 '), original.split(': ', 1)[1]):
            with self.subTest(raw=raw[:60]):
                self.reject(lambda: self.fixture.replace_original(self.report['native']['logcat'], raw))

    def test_native_exit_without_fresh_successful_games_host_ack_is_rejected(self):
        original = (self.root/self.report['original_logcat']).read_text()
        for raw in (self.fixture.log(self.report['native']['marker']),
                    original.replace(village.RETURN_MARKER, '[LumoHost] return: build'),
                    original.replace('12:35:56.123   200', '12:35:56.123   999'),
                    original+original.splitlines()[-1]+'\n'):
            with self.subTest(log=raw[-100:]):
                self.reject(lambda: self.fixture.replace_original(self.report['original_logcat'], raw))

    def test_old_ack_before_visible_return_cannot_count_as_fresh_success(self):
        raw = (self.root/self.report['original_logcat']).read_text()
        self.reject(lambda: self.fixture.replace_original(self.report['native']['logcat'], raw))

    def test_duplicate_marker_keys_and_nonfinite_json_cannot_override_real_values(self):
        raw = self.fixture.log(self.report['native']['marker'])
        for changed in (raw.replace('"host_entry": true', '"host_entry": false, "host_entry": true'),
                        raw.replace('"plots": 9', '"unused": NaN, "plots": 9')):
            with self.subTest(log=changed):
                self.reject(lambda: self.fixture.replace_original(self.report['native']['logcat'], changed))

    def test_duplicate_report_and_registry_keys_fail_closed(self):
        raw = (self.root/village.REPORT).read_text()
        (self.root/village.REPORT).write_text(raw.replace('"status": "PASS"', '"status": "FAIL", "status": "PASS"', 1))
        with self.assertRaisesRegex(ValueError, 'Duplicate key'):
            self.verify()
        values = self.fixture.preferences()
        values['flutter.lumo_3d_profile_keys_v1'] = values['flutter.lumo_3d_profile_keys_v1'].replace('"version": 1', '"version": 2, "version": 1')
        with self.assertRaisesRegex(ValueError, 'Duplicate key'):
            village.child_key(values)

    def test_missing_or_duplicate_actual_ready_marker_is_rejected(self):
        raw = self.fixture.log(self.report['native']['marker'])
        for changed in ('11-14 12:34:56.000 200 201 I godot: unrelated\n', raw+raw):
            with self.subTest(raw=changed[:50]):
                self.reject(lambda: self.fixture.replace_original(self.report['native']['logcat'], changed))

    def test_incorrect_scene_owner_slot_host_return_and_model_are_rejected(self):
        original = copy.deepcopy(self.report['native']['marker'])
        cases = [('scene', 'res://scenes/build.tscn'), ('living_village', False),
                 ('host_entry', False), ('return_scene', 'build'), ('save_blocked', True),
                 ('slot', 2), ('save_path', original['save_path'].replace('_1_', '_2_')),
                 ('plots', 8), ('population', 1), ('visible_residents', 3),
                 ('initialized_plot_nodes', 0)]
        for key, value in cases:
            with self.subTest(key=key):
                marker = {**original, key: value}
                self.report['native']['marker'] = marker
                self.reject(lambda: self.fixture.replace_original(self.report['native']['logcat'], self.fixture.log(marker)))

    def test_raw_student_hash_cannot_replace_registered_native_child_key(self):
        marker = self.report['native']['marker']
        marker['save_path'] = 'user://lumo_settlement_'+hashlib.sha256(STUDENT.encode()).hexdigest()+'_1_village.json'
        self.reject(lambda: self.fixture.replace_original(self.report['native']['logcat'], self.fixture.log(marker)))

    def test_reported_marker_must_equal_original_json(self):
        self.reject(lambda: self.report['native']['marker'].update(plots=16))

    def test_missing_or_changed_original_png_is_rejected(self):
        path = self.root/self.report['native']['frame']['file']
        path.write_bytes(path.read_bytes()+b'changed-original')
        with self.assertRaisesRegex(ValueError, 'Original Village evidence bytes changed'):
            self.verify()
        self.fixture.refresh()
        with self.assertRaisesRegex(ValueError, 'screenshot changed'):
            self.verify()
        path.unlink()
        with self.assertRaises(ValueError):
            self.verify()

    def test_declared_hud_without_matching_original_tsv_is_rejected(self):
        self.reject(lambda: (self.root/'native-hud-0-ocr-raw.tsv').write_text('conf\ttext\n95\tInvented\n'))

    def test_wrong_visible_return_or_substituted_touch_is_rejected(self):
        journal = self.root/self.report['returned']['touch_journal']
        data = json.loads(journal.read_text()); data['label'] = 'Bauwelt'
        self.reject(lambda: self.fixture.write(journal.name, data))

    def test_native_force_stop_cannot_substitute_for_the_visible_return(self):
        meta = self.root/(self.report['returned']['command_original'][:-7]+'.json')
        data = json.loads(meta.read_text()); data['command'] = ['adb', 'shell', 'am', 'force-stop', c4.PACKAGE]
        self.reject(lambda: self.fixture.write(meta.relative_to(self.root).as_posix(), data))

    def test_a_single_stale_return_frame_cannot_establish_a_touch(self):
        journal = self.root/self.report['returned']['touch_journal']
        data = json.loads(journal.read_text()); data['frames'][-1] = data['frames'][0]
        self.reject(lambda: self.fixture.write(journal.name, data))

    def test_native_must_end_after_touch_without_replacing_host(self):
        row = self.report['returned']
        self.reject(lambda: self.fixture.replace_original(row['native_pid'], '200\n', returncode=0))

    def test_same_native_pid_must_survive_until_the_visible_return(self):
        self.reject(lambda: self.fixture.replace_original(self.report['returned']['native_before_return']['native_pid'], '201\n'))

    def test_host_pid_and_foreground_must_return_to_original_flutter(self):
        self.reject(lambda: self.fixture.replace_original(self.report['returned']['host_pid'], '999\n'))

    def test_current_flutter_pixels_and_semantics_required_after_native_exit(self):
        self.reject(lambda: (self.root/'returned-visible-ocr.json').write_text('[]'))

    def test_profile_learning_and_new_learning_keys_cannot_change(self):
        for key, value in [('flutter.lumo_progress_v1', '{"changed":true}'),
                           ('flutter.lumo_learning_added', 'new'),
                           ('flutter.lumo_active_profile', '{"name":"Another child"}')]:
            with self.subTest(key=key):
                values = self.fixture.preferences(); values[key] = value
                self.reject(lambda: self.report['returned'].update(preferences=self.fixture.preferences_original('changed-preferences', values)))

    def test_fatal_android_log_cannot_be_hidden_by_empty_reported_errors(self):
        self.reject(lambda: self.fixture.replace_original(self.report['original_logcat'], 'FATAL EXCEPTION: main\n'))

    def test_command_stderr_or_wrong_source_cannot_count_as_observation(self):
        meta = self.root/(self.report['native']['logcat'][:-7]+'.json')
        data = json.loads(meta.read_text()); data['command'][-1] = 'brief'
        self.reject(lambda: self.fixture.write(meta.relative_to(self.root).as_posix(), data))

    def test_extra_missing_symlinked_or_duplicate_originals_are_rejected(self):
        (self.root/'unlisted.txt').write_text('unlisted')
        with self.assertRaises(ValueError): self.verify()
        (self.root/'unlisted.txt').unlink()
        self.report['originals'].append(self.report['originals'][0])
        self.fixture.write(village.REPORT, self.report)
        with self.assertRaises(ValueError): self.verify()
        self.fixture.refresh()
        (self.root/'symlink').symlink_to(self.root/'native-hud-0-ocr.json')
        with self.assertRaises(ValueError): self.verify()

    def test_legitimate_component_and_tile_ocr_replay_their_original_source_offsets(self):
        image_name = self.report['native']['frame']['file']
        for tiled in (False, True):
            with self.subTest(tiled=tiled):
                tag = 'fallback-'+str(tiled)
                bounds = self.fixture.fallback(tag, image_name, tiled=tiled)
                self.assertEqual(village.caption(self.root, self.root/image_name, tag, 'Spiele'), bounds)

    def test_fallback_ocr_rejects_changed_crop_pixels_or_source_binding(self):
        image_name = self.report['native']['frame']['file']
        for tiled in (False, True):
            with self.subTest(tiled=tiled):
                tag = 'bad-fallback-'+str(tiled)
                self.fixture.fallback(tag, image_name, tiled=tiled)
                variant = 'white-latin-tile-0' if tiled else 'gold-component-0'
                crop = self.root/(tag+'-ocr-'+variant+'.png')
                with Image.open(crop) as original:
                    changed = original.copy()
                changed.putpixel((0, 0), 0 if tiled else (0, 0, 0))
                changed.save(crop)
                with self.assertRaisesRegex(ValueError, 'crop pixels differ'):
                    village.caption(self.root, self.root/image_name, tag, 'Spiele')
                self.fixture.fallback(tag, image_name, tiled=tiled)
                journal = self.root/(tag+('-ocr-tiles.json' if tiled else '-ocr-components.json'))
                value = json.loads(journal.read_text()); value['source_sha256'] = 'f'*64
                self.fixture.write(journal.name, value)
                with self.assertRaisesRegex(ValueError, 'source differs'):
                    village.caption(self.root, self.root/image_name, tag, 'Spiele')
if __name__ == '__main__':
    unittest.main()
