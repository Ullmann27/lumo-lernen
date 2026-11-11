"""Synthetic negative delivery fixtures; these are never Android acceptance evidence."""
import copy
from functools import lru_cache
import hashlib
import importlib.util
import json
from pathlib import Path
import struct
import subprocess
import sys
import tempfile
import unittest
import zlib

SOURCE = Path(__file__).resolve().parents[1] / 'verify_lumo_2015_garage_delivery.py'
SPEC = importlib.util.spec_from_file_location('garage_delivery', SOURCE)
gate = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(gate)
PCK = '1' * 64


def metadata():
    repo = {'id': gate.REPOSITORY_ID, 'full_name': gate.REPOSITORY}
    run = {'id': gate.QA_RUN, 'head_sha': gate.QA_SOURCE, 'run_attempt': gate.QA_ATTEMPT,
           'workflow_id': gate.QA_WORKFLOW_ID, 'path': gate.QA_WORKFLOW,
           'name': 'Lumo 2015 existing APK Garage Android QA', 'event': 'pull_request',
           'head_branch': gate.QA_BRANCH, 'status': 'completed', 'conclusion': 'success',
           'repository': repo.copy(), 'head_repository': repo.copy(),
           'run_started_at': '2026-11-11T17:00:00Z'}
    jobs = [{'id': 777, 'name': 'existing-apk-garage', 'run_id': gate.QA_RUN,
             'head_sha': gate.QA_SOURCE, 'run_attempt': gate.QA_ATTEMPT, 'status': 'completed',
             'conclusion': 'success', 'started_at': '2026-11-11T17:00:03Z',
             'completed_at': '2026-11-11T17:30:00Z'}]
    artifacts = [{'id': 888, 'name': gate.ARTIFACT_NAME, 'digest': 'sha256:' + '2' * 64,
                  'size_in_bytes': 123456, 'expired': False,
                  'created_at': '2026-11-11T17:29:00Z', 'updated_at': '2026-11-11T17:29:10Z',
                  'workflow_run': {'id': gate.QA_RUN, 'head_sha': gate.QA_SOURCE,
                                   'head_branch': gate.QA_BRANCH,
                                   'repository_id': gate.REPOSITORY_ID,
                                   'head_repository_id': gate.REPOSITORY_ID}}]
    return run, jobs, artifacts


@lru_cache(maxsize=3)
def synthetic_png(width, height):
    def chunk(kind, data):
        return struct.pack('>I', len(data)) + kind + data + struct.pack('>I', zlib.crc32(kind + data))
    # Solid test fixture, deliberately not a rendered-game screenshot.
    rows = (b'\x00' + b'\xff\xff\xff' * width) * height
    return b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', width, height, 8, 2, 0, 0, 0)) + chunk(b'IDAT', zlib.compress(rows)) + chunk(b'IEND', b'')


class Fixture:
    def __init__(self, root):
        self.root, self.runtime = root, root / 'runtime'
        self.binding = gate.validate_metadata(*metadata())
        self.write('apk-source-sha.txt', gate.APP_SOURCE + '\n')
        self.write('qa-source-sha.txt', gate.QA_SOURCE + '\n')
        self.report = {'status': 'PASS', 'source': gate.APP_SOURCE, 'godot_source': gate.NATIVE_SOURCE,
                       'source_run': gate.APP_RUN, 'apk_sha256': gate.APK_SHA256, 'steps': [], 'races': []}
        self.details = {name: {} for name in gate.REQUIRED_STEPS}
        self.report['steps'] = [{'step': name, 'status': 'PASS', 'evidence': detail, 'wall_seconds': 1}
                                for name, detail in self.details.items()]
        apk = {'package': gate.PACKAGE, 'versionCode': 2015, 'versionName': '0.13.3',
               'abis': ['x86_64'], 'sha256': gate.APK_SHA256,
               'signingCertificateSha256': gate.CERTIFICATE,
               'godot': {'revision': gate.NATIVE_SOURCE, 'pck_sha256': PCK}}
        identity = {'apk_sha256': gate.APK_SHA256, 'flutter_source_commit': gate.APP_SOURCE,
                    'godot_revision': gate.NATIVE_SOURCE, 'godot_pck_sha256': PCK,
                    'versionCode': 2015, 'versionName': '0.13.3',
                    'signingCertificateSha256': gate.CERTIFICATE, 'checks': {key: True for key in gate.IDENTITY_CHECKS}}
        self.details['apk-identity'].update(actual_apk=apk, provenance=identity)
        self.write_json('runtime/verified-actual-apk.json', apk)
        for kart, short in (('comet', 'comet'), ('gecko_velo', 'gecko')):
            folder, race_id = 'phone-' + short, 'synthetic-' + short
            state = self.state(kart, race_id)
            race = {key: state[key] for key in ('selected_kart', 'selected_driver', 'result_id',
                                               'mode', 'track_id', 'countdown', 'elapsed', 'distance')}
            self.report['races'].append(race)
            self.capture(folder, 'hud')
            self.details[folder + '-selection-confirm-start'].update(
                actual_race=copy.deepcopy(race), selection_touch=self.touch(folder, 'select', gate.KARTS[kart]),
                selection_capture=self.capture(folder, 'selected'),
                hud={'capture': 'hud', 'rendered_frame': self.frame()},
                garage_replaced={'changed_fraction': .3, 'mean_channel_delta': 30})
            self.details[folder + '-drive'].update(self.drive(state))
        paused_state = self.details['phone-comet-drive']['after']
        self.details['phone-comet-pause-freeze'].update(self.pause('phone-comet/first-pause', paused_state))
        continued = self.drive(paused_state)
        self.details['phone-comet-continue-and-drive'].update(
            touch=self.touch('phone-comet', 'continue', 'Weiterfahren'), drive=continued,
            progress={'result_id': paused_state['result_id'], 'kart': 'comet',
                      'distance_gain_after_continue': 12, 'elapsed_gain_after_continue': 3})
        self.details['phone-comet-pause-android-back'].update({
            'pause': self.pause('phone-comet/second-pause', continued['after']),
            'return': self.returned('phone-comet')})
        self.details['phone-gecko-abandon'].update({
            'pause': self.pause('phone-gecko/abandon-pause', self.details['phone-gecko-drive']['after']),
            'touch': self.touch('phone-gecko', 'abandon', 'Rennen abbrechen'),
            'return': self.returned('phone-gecko')})
        self.details['phone-garage-cancel-back'].update(self.navigation('phone-cancel'))
        for layout, (width, height, density) in gate.LAYOUTS.items():
            screen = {'layout': layout, 'requested_portrait_pixels': [width, height],
                      'requested_density_dpi': density, 'actual_screenshot_pixels': [height, width],
                      'foreground': gate.PACKAGE + '/LumoGameActivity',
                      'screenshot': self.capture(layout, 'actual-garage', height, width)}
            self.write_json('runtime/' + layout + '/actual-native-garage-display.json', screen)
            self.details[layout + '-garage-confirm-back'].update(
                screen=screen, garage={'touch': self.touch(layout, 'open', 'Garage'),
                                      'title': self.caption(layout, 'title', 'Dein Kart. Dein Stil.')},
                comet=self.caption(layout, 'comet', 'Comet'), gecko=self.caption(layout, 'gecko', 'Gecko Velo'),
                gecko_touch=self.touch(layout, 'select', 'Gecko Velo'),
                navigation=self.navigation(layout), returned=self.returned(layout))
        self.details['profile-learning-preserved'].update(learning_keys_compared=2,
                                                          profile={'id': 'synthetic-profile', 'name': 'Fixture'})
        self.details['no-native-crash']['fatal_events'] = []
        self.write('runtime/required-fatal-observation-12.log', 'I/ActivityManager: Lumo is foreground\n')
        self.save()

    def write(self, path, data):
        target = self.root / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(data)

    def write_json(self, path, value):
        self.write(path, json.dumps(value))

    def save(self):
        self.write_json('runtime/garage-result.json', self.report)

    def capture(self, folder, name, width=2400, height=1080):
        raw = synthetic_png(width, height)
        path = self.runtime / folder / (name + '.png')
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(raw)
        return {'file': path.name, 'width': width, 'height': height, 'sha256': hashlib.sha256(raw).hexdigest()}

    def caption(self, folder, name, label):
        return {'caption': label, 'observed': [{'text': label}], 'capture': self.capture(folder, name)}

    def touch(self, folder, name, label):
        path = folder + '/' + name + '-surface-readiness.json'
        self.write_json('runtime/' + path, {'status': 'TOUCH_SENT', 'label': label,
                                         'exact_caption_required': True, 'touch': [80, 80],
                                         'frames': [{}, {'target': {'stable_observed_target': True}}]})
        return {'readiness': path, 'label': label, 'touch': [80, 80]}

    @staticmethod
    def state(kart, race_id):
        return {'selected_kart': kart, 'selected_driver': 'fox', 'result_id': race_id,
                'mode': 'cup', 'track_id': 'sonnenhafen', 'countdown': 0, 'elapsed': 2,
                'distance': 10, 'finished': False, 'completed_race': False, 'checkpoint_index': 0}

    @staticmethod
    def frame():
        return {'size': [2400, 1080], 'visible_fractions': [.9] * 3,
                'detail': [{'colour_bins': 15, 'bright_fraction': .6} for _ in range(3)]}

    def drive(self, before):
        after = {**before, 'distance': before['distance'] + 12, 'elapsed': before['elapsed'] + 3}
        return {'start': copy.deepcopy(before), 'after': after,
                'movement': {'rendered_frame': self.frame(), 'gas_pulses': 1, 'hold_ms': 9000,
                             'gas_touch': [80, 80], 'world_moved': {'changed_fraction': .3, 'mean_channel_delta': 30},
                             'native_progress': {'result_id': before['result_id'], 'distance_gain': 12, 'elapsed_gain': 3}}}

    def pause(self, folder, state):
        frozen = {key: state[key] for key in ('result_id', 'distance', 'elapsed', 'checkpoint_index', 'finished')}
        raw = '[race]\n' + '\n'.join(key + '=' + json.dumps(value) for key, value in frozen.items())
        for name in ('paused-first', 'paused-second'):
            self.write('runtime/' + folder + '/' + name + '-session.cfg', raw)
        return {'state': copy.deepcopy(state), 'frozen': frozen,
                'title': self.caption(folder, 'pause', 'Eine kleine Pause')}

    def returned(self, folder):
        return {'foreground': gate.PACKAGE + '/MainActivity', 'capture': self.capture(folder, 'returned')}

    def navigation(self, folder):
        captions = {'world': 'Wohin geht die Reise?', 'kart': 'Dein Kart. Dein Stil.',
                    'driver': 'Wer fährt mit?', 'mode': 'Dein Abenteuer', 'landing': 'Garage'}
        return {'race_not_started': True, **{key: self.caption(folder, 'cancel-' + key, caption)
                                             for key, caption in captions.items()}}

    def validate(self, **changes):
        self.save()
        return gate.validate_proof(self.root, self.binding, changes.get('pck', PCK),
                                   changes.get('tour', gate.APK_SHA256), changes.get('update', gate.APK_SHA256))


class MetadataGuards(unittest.TestCase):
    def test_exact_completed_run_and_original_artifact(self):
        self.assertEqual(gate.validate_metadata(*metadata())['qa_source'], gate.QA_SOURCE)

    def test_pending_failed_foreign_run_or_old_source_never_passes(self):
        mutations = [('status', 'in_progress'), ('conclusion', None), ('conclusion', 'failure'),
                     ('id', 43032732151), ('head_sha', gate.APP_SOURCE), ('workflow_id', 1),
                     ('event', 'push'), ('path', 'wrong.yml'), ('head_branch', 'main'),
                     ('run_attempt', 1), ('run_attempt', True)]
        for key, value in mutations:
            with self.subTest(key=key, value=value):
                run, jobs, artifacts = metadata()
                run[key] = value
                with self.assertRaises(RuntimeError):
                    gate.validate_metadata(run, jobs, artifacts)

    def test_wrong_job_source_attempt_skipped_or_missing_job(self):
        for key, value in [('head_sha', gate.APP_SOURCE), ('run_id', 1), ('run_attempt', 1),
                           ('status', 'in_progress'), ('conclusion', 'skipped')]:
            with self.subTest(key=key):
                run, jobs, artifacts = metadata()
                jobs[0][key] = value
                with self.assertRaises(RuntimeError):
                    gate.validate_metadata(run, jobs, artifacts)
        for jobs in ([], metadata()[1] * 2):
            with self.assertRaises(RuntimeError):
                gate.validate_metadata(metadata()[0], jobs, metadata()[2])

    def test_artifact_missing_ambiguous_expired_replaced_or_from_other_attempt(self):
        for key, value in [('expired', True), ('id', 0), ('size_in_bytes', 0), ('digest', ''),
                           ('created_at', '2026-11-11T16:00:00Z'), ('updated_at', '2026-11-11T18:00:00Z')]:
            with self.subTest(key=key):
                run, jobs, artifacts = metadata()
                artifacts[0][key] = value
                with self.assertRaises(RuntimeError):
                    gate.validate_metadata(run, jobs, artifacts)
        for key, value in [('head_sha', gate.APP_SOURCE), ('id', gate.APP_RUN),
                           ('head_branch', 'main'), ('head_repository_id', 1)]:
            with self.subTest(key=key):
                run, jobs, artifacts = metadata()
                artifacts[0]['workflow_run'][key] = value
                with self.assertRaises(RuntimeError):
                    gate.validate_metadata(run, jobs, artifacts)
        for artifacts in ([], metadata()[2] * 2):
            with self.assertRaises(RuntimeError):
                gate.validate_metadata(metadata()[0], metadata()[1], artifacts)

    def test_previous_failed_attempt_artifact_is_preserved_but_cannot_supply_current_proof(self):
        run, jobs, artifacts = metadata()
        old = copy.deepcopy(artifacts[0])
        old.update(id=887, created_at='2026-11-11T16:00:00Z', updated_at='2026-11-11T16:00:00Z')
        self.assertEqual(gate.validate_metadata(run, jobs, [old, *artifacts])['artifact_id'], 888)
        with self.assertRaises(RuntimeError):
            gate.validate_metadata(run, jobs, [old])

    def test_final_cli_recheck_rejects_changed_artifact_before_writing_approval(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder)
            run, jobs, artifacts = metadata()
            (path / 'initial.json').write_text(json.dumps(gate.validate_metadata(run, jobs, artifacts)))
            artifacts[0]['id'] += 1
            for name, value in (('run', run), ('jobs', jobs), ('artifacts', artifacts)):
                (path / ('garage-final-' + name + '.json')).write_text(json.dumps(value))
            result = subprocess.run([sys.executable, str(SOURCE), '--metadata', str(path),
                                     '--prefix', 'garage-final', '--compare', str(path / 'initial.json'),
                                     '--output', str(path / 'approved.json')], capture_output=True, text=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn('changed before publication', result.stderr)
            self.assertFalse((path / 'approved.json').exists())


class OriginalProofGuards(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.fixture = Fixture(Path(self.temporary.name) / 'original-artifact')

    def reject(self, mutate):
        mutate(self.fixture)
        with self.assertRaises((RuntimeError, KeyError)):
            self.fixture.validate()

    def test_complete_synthetic_schema_is_accepted_without_changing_original_json(self):
        before = (self.fixture.runtime / 'garage-result.json').read_bytes()
        result = self.fixture.validate()
        self.assertEqual(result['original_result_sha256'], hashlib.sha256(before).hexdigest())
        self.assertEqual(before, (self.fixture.runtime / 'garage-result.json').read_bytes())

    def test_green_colour_without_real_result_is_rejected(self):
        self.fixture.report = {'status': 'PASS'}
        with self.assertRaises(KeyError):
            self.fixture.validate()

    def test_incomplete_failed_or_error_result_is_rejected(self):
        for key, value in [('status', 'RUNNING'), ('status', 'FAIL'), ('error', 'failed')]:
            with self.subTest(key=key, value=value):
                prior = copy.deepcopy(self.fixture.report)
                self.fixture.report[key] = value
                with self.assertRaises(RuntimeError):
                    self.fixture.validate()
                self.fixture.report = prior

    def test_app_and_qa_commits_cannot_be_confused(self):
        self.reject(lambda f: f.report.update(source=gate.QA_SOURCE))

    def test_original_qa_source_file_cannot_name_apk_source(self):
        self.reject(lambda f: f.write('qa-source-sha.txt', gate.APP_SOURCE))

    def test_signature_and_embedded_pck_must_match_delivered_arm64(self):
        for pck in ('', '9' * 64):
            with self.subTest(pck=pck), self.assertRaises(RuntimeError):
                self.fixture.validate(pck=pck)
        self.reject(lambda f: f.details['apk-identity']['actual_apk'].update(signingCertificateSha256='9' * 64))

    def test_omitting_a_provenance_check_is_not_equivalent_to_all_checks_passed(self):
        self.reject(lambda f: f.details['apk-identity']['provenance']['checks'].pop('tracked_source_clean'))

    def test_tour_and_update_must_use_same_exact_x86_apk(self):
        for field in ('tour', 'update'):
            with self.subTest(field=field), self.assertRaises(RuntimeError):
                self.fixture.validate(**{field: '9' * 64})

    def test_missing_fold_step_is_rejected(self):
        self.reject(lambda f: f.report.update(steps=[item for item in f.report['steps']
                                                    if item['step'] != 'fold-open-garage-confirm-back']))

    def test_failed_and_duplicate_mandatory_steps_are_rejected(self):
        original = copy.deepcopy(self.fixture.report['steps'])
        self.fixture.report['steps'][0]['status'] = 'FAIL'
        with self.assertRaises(RuntimeError):
            self.fixture.validate()
        self.fixture.report['steps'] = original + [copy.deepcopy(original[0])]
        with self.assertRaises(RuntimeError):
            self.fixture.validate()

    def test_same_race_for_comet_and_gecko_is_rejected(self):
        self.reject(lambda f: f.report['races'][1].update(result_id=f.report['races'][0]['result_id']))

    def test_wrong_selected_car_cannot_be_replaced_by_touch_report(self):
        self.reject(lambda f: f.details['phone-gecko-selection-confirm-start']['actual_race'].update(selected_kart='comet'))

    def test_continue_with_no_new_distance_is_rejected(self):
        self.reject(lambda f: f.details['phone-comet-continue-and-drive']['drive']['after'].update(
            distance=f.details['phone-comet-pause-freeze']['state']['distance']))

    def test_continue_with_new_race_is_rejected(self):
        self.reject(lambda f: f.details['phone-comet-continue-and-drive']['drive']['after'].update(result_id='another'))

    def test_nonfinite_continue_time_is_rejected(self):
        self.reject(lambda f: f.details['phone-comet-continue-and-drive']['drive']['after'].update(elapsed=float('nan')))

    def test_stale_world_despite_moving_numbers_is_rejected(self):
        self.reject(lambda f: f.details['phone-comet-drive']['movement']['world_moved'].update(changed_fraction=0))

    def test_original_paused_sample_mismatch_is_rejected(self):
        self.reject(lambda f: f.write('runtime/phone-comet/first-pause/paused-second-session.cfg',
                                     '[race]\nresult_id="wrong"\ndistance=999\nelapsed=5\ncheckpoint_index=0\nfinished=false'))

    def test_native_fold_activity_and_original_dimensions_are_required(self):
        self.reject(lambda f: f.details['fold-open-garage-confirm-back']['screen'].update(foreground=gate.PACKAGE + '/MainActivity'))

    def test_original_image_cannot_be_missing_or_replaced(self):
        self.reject(lambda f: (f.runtime / 'fold-cover/actual-garage.png').write_bytes(b'not the original capture'))

    def test_original_touch_must_be_sent_on_two_stable_frames(self):
        path = self.fixture.details['phone-comet-selection-confirm-start']['selection_touch']['readiness']
        self.reject(lambda f: f.write_json('runtime/' + path, {'status': 'WAITING'}))

    def test_real_fatal_blocks_green_status(self):
        self.reject(lambda f: f.write('runtime/required-fatal-observation-12.log',
                                     'E/AndroidRuntime: FATAL EXCEPTION: main\nProcess: ' + gate.PACKAGE))

    def test_missing_required_log_blocks_green_status(self):
        self.reject(lambda f: (f.runtime / 'required-fatal-observation-12.log').unlink())

    def test_duplicate_original_result_cannot_be_selected_arbitrarily(self):
        self.reject(lambda f: f.write_json('another/garage-result.json', {'status': 'PASS'}))

    def test_duplicate_json_keys_and_nan_are_rejected(self):
        path = self.fixture.runtime / 'duplicate.json'
        for raw in ('{"status":"FAIL","status":"PASS"}', '{"elapsed":NaN}'):
            path.write_text(raw)
            with self.assertRaises(RuntimeError):
                gate.load_json(path)


if __name__ == '__main__':
    unittest.main()
