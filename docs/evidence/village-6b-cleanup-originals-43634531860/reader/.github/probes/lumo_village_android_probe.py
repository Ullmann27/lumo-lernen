#!/usr/bin/env python3
"""Actual API35 Flutter Village entry and visible direct return on the toured APK."""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import shutil
import subprocess
import sys
import time
import traceback
import xml.etree.ElementTree as ET

from lumo_connect_four_android_probe import Probe, ROOT, write
from flutter_surface_readiness import inspect_flutter_frame
import connect_four_android_evidence as c4
import village_android_evidence as village


class VillageProbe(Probe):
    def remaining(self, maximum=45):
        left = self.deadline-time.monotonic()
        if left <= 0:
            raise TimeoutError('The actual Village Android roundtrip exceeded 900 seconds')
        observed_until = getattr(self, '_flutter_observation_deadline', None)
        if observed_until is not None:
            left = min(left, observed_until-time.monotonic())
            if left <= 0:
                raise TimeoutError('The actual visible Flutter return exceeded its 90-second observation budget')
        return min(left, maximum)

    def processes(self, tag, *, native):
        row = {}
        for key, arguments in (
            ('host_pid', ('shell', 'pidof', c4.PACKAGE)),
            ('native_pid', ('shell', 'pidof', c4.PACKAGE+':lumo_game')),
            ('activity', ('shell', 'dumpsys', 'activity', 'activities')),
        ):
            _, row[key] = self.original(tag+'-'+key, *arguments,
                                        check=key != 'native_pid' or native)
        village.process(self.out, row, native=native)
        return row

    def await_processes(self, tag, *, native, timeout=90):
        deadline = time.monotonic()+self.remaining(timeout)
        failures = []
        while time.monotonic() < deadline:
            try:
                observed = self.processes(tag+'-'+str(len(failures)), native=native)
                if time.monotonic() >= deadline:
                    raise TimeoutError('The actual Village/Flutter process arrived at or after its observation deadline: '+tag)
                return observed
            except (ValueError, RuntimeError) as error:
                failures.append(str(error))
                time.sleep(min(.5, max(0, deadline-time.monotonic())))
        write(self.out/(tag+'-wait-failure.json'), failures)
        raise TimeoutError('The actual Village/Flutter process did not arrive: '+tag)

    def observe_village(self):
        deadline = time.monotonic()+self.remaining(180)
        failures = []
        while time.monotonic() < deadline:
            tag = 'village-ready-'+str(len(failures))
            try:
                row = self.processes(tag, native=True)
                _, pid = village.process(self.out, row, native=True)
                prefs, row['preferences'] = self.read_preferences(tag)
                raw, row['logcat'] = self.original(tag+'-logcat', 'logcat', '-b', 'all',
                    '--pid', str(pid), '-d', '-v', 'threadtime', bound=64*1024*1024)
                row['marker'] = village.ready(raw, pid, prefs)
                c4.demand(not c4.runtime_errors(raw), 'Native Village initialization reports an error')
                row['frame'] = self.ui.capture(self.out, tag, timeout=self.remaining())
                image = village.capture(self.out, row['frame'], native=True)
                row['hud_ocr'] = []
                for number, wanted in enumerate(village.HUD):
                    ocr_tag = tag+'-hud-'+str(number)
                    self.ui.image_lines(self.out, ocr_tag, self.ui.normalized(wanted),
                                        source_path=image, timeout=min(self.remaining(60),
                                        max(.1, deadline-time.monotonic())), exact=True)
                    village.caption(self.out, image, ocr_tag, wanted)
                    row['hud_ocr'].append(ocr_tag)
                c4.demand(time.monotonic() < deadline, 'Village rendering exceeded its observation deadline')
                return row
            except (ValueError, RuntimeError, json.JSONDecodeError) as error:
                failures.append(str(error))
                time.sleep(min(.7, max(0, deadline-time.monotonic())))
        write(self.out/'village-ready-wait-failure.json', failures)
        raise TimeoutError('No actual initialized Village scene and rendered HUD were observed')

    def visible_return(self, native_pid):
        current = self.processes('village-before-return', native=True)
        c4.demand(village.process(self.out, current, native=True)[1] == native_pid,
                  'Village process changed before its visible return')
        commands = []
        old_adb = self.base.adb

        def observed_touch(*arguments, **kwargs):
            c4.demand(len(arguments) == 8 and arguments[:3] == ('shell', 'input', 'swipe')
                      and arguments[-1] == '120', 'Unexpected action during visible Village return')
            raw, name = self.original('village-visible-return-touch', *arguments)
            commands.append(name)
            return raw

        try:
            self.base.adb = observed_touch
            self.ui.native_tap(self.out, 'Spiele', 'village-return', timeout=self.remaining(120),
                               exact=True, orientation='responsive')
        finally:
            self.base.adb = old_adb
        c4.demand(len(commands) == 1, 'Village return did not use exactly one actual visible touch')
        row = self.await_processes('returned-flutter', native=False, timeout=60)
        row.update(touch_journal='village-return-surface-readiness.json',
                   command_original=commands[0], native_before_return=current)
        _, row['preferences'] = self.read_preferences('returned-flutter')
        return self.observe_flutter_return(row)

    def observe_flutter_return(self, returned):
        """Observe the real host surface after ACK; never act on the app again.

        Activity/PID return can precede Android's closing/rotation surface. The
        previous 30s capture + 60s OCR allowance is one shared 90s budget. Every
        rejected PNG, TSV and live hierarchy keeps its own original filename.
        """
        accepted = self.out/'returned-flutter-frame.png'
        if accepted.exists() or accepted.is_symlink():
            raise FileExistsError('Refusing to overwrite the original returned Flutter frame')
        started = time.monotonic()
        deadline = started+self.remaining(90)
        host, _ = village.process(self.out, returned, native=False)
        journal = {'schema': 'lumo-village-flutter-return-observation', 'version': 1,
                   'status': 'FAIL', 'timeout_seconds': 90, 'attempts': [],
                   'scope': 'Fresh PNG/TSV and live Flutter semantics after the single visible return touch'}
        self._flutter_observation_deadline = deadline
        try:
            while time.monotonic() < deadline:
                index = len(journal['attempts'])+1
                tag = 'returned-flutter-visible-'+str(index)
                directory = self.out/'returned-flutter-observations'/('attempt-'+str(index))
                directory.mkdir(parents=True, exist_ok=False)
                attempt = {'status': 'REJECTED', 'started_after_seconds': time.monotonic()-started}
                journal['attempts'].append(attempt)
                try:
                    self.remaining()
                    current = self.processes(tag+'-before', native=False)
                    attempt['process_before'] = current
                    c4.demand(village.process(self.out, current, native=False)[0] == host,
                              'Flutter process changed during visible return observation')
                    self.remaining()
                    frame = self.ui.capture(directory, 'returned-flutter-frame', timeout=self.remaining(30))
                    c4.demand(frame['file'] == accepted.name, 'Unexpected original return screenshot filename')
                    image = village.capture(directory, frame)
                    frame = {**frame, 'file': image.relative_to(self.out).as_posix()}
                    attempt['frame'] = frame
                    self.remaining()
                    attempt['render_readiness'] = inspect_flutter_frame(image)
                    c4.demand(attempt['render_readiness']['visually_ready'],
                              'Current returned Flutter frame is not rendered')
                    self.remaining()
                    attempt['visible_ocr'] = tag
                    self.ui.image_lines(self.out, tag, 'spielen', source_path=image,
                                        timeout=self.remaining(60), exact=True)
                    self.remaining()
                    village.caption(self.out, image, tag, 'Spielen')
                    self.remaining()
                    ui_tag = 'returned-flutter-ui-'+str(index)
                    self.ui.read_live_nodes(self.out, ui_tag)
                    attempt['ui'] = ui_tag+'.xml'
                    self.remaining()
                    tree = ET.fromstring(c4.safe_member(self.out, attempt['ui']).read_text())
                    c4.demand(tree.tag == 'hierarchy' and any(node.get('package') == c4.PACKAGE
                              and node.get('enabled') == 'true'
                              and any(value == 'Spielen' or village.PORTAL in value for value in
                                      (node.get('text', ''), node.get('content-desc', '')))
                              for node in tree.iter('node')), 'Actual Flutter Spielewelt did not return')
                    self.remaining()
                    current = self.processes(tag+'-after', native=False)
                    attempt['process_after'] = current
                    c4.demand(village.process(self.out, current, native=False)[0] == host,
                              'Flutter process changed after visible return observation')
                    self.remaining()
                    _, current['preferences'] = self.read_preferences(tag)
                    self.remaining()
                    village.capture(self.out, frame)
                    self.remaining()
                    # Keep the accepted attempt as well as the established
                    # exporter filename. Same basename also preserves strict
                    # component/tile OCR source-name and pixel-hash replay.
                    with image.open('rb') as original, accepted.open('xb') as target:
                        shutil.copyfileobj(original, target)
                    c4.demand(c4.sha256(accepted) == frame['sha256'], 'Accepted original return copy differs')
                    self.remaining()
                    attempt.update(status='PASS', completed_after_seconds=time.monotonic()-started)
                    journal['status'] = 'PASS'
                    return {**returned, **current, 'frame': {**frame, 'file': accepted.name},
                            'visible_ocr': tag, 'ui': attempt['ui'],
                            'observation_journal': 'returned-flutter-observation.json'}
                except (ValueError, RuntimeError, TimeoutError, subprocess.TimeoutExpired, ET.ParseError) as error:
                    attempt.update(error=f'{type(error).__name__}: {error}',
                                   completed_after_seconds=time.monotonic()-started)
                    if time.monotonic() >= deadline:
                        break
                    time.sleep(min(.5, max(0, deadline-time.monotonic())))
            raise TimeoutError('No actual Flutter Spielen pixels and live Spielewelt returned within 90 seconds')
        finally:
            del self._flutter_observation_deadline
            journal['elapsed_seconds'] = time.monotonic()-started
            write(self.out/'returned-flutter-observation.json', journal)

    def run(self):
        result = {'schema': 1, 'status': 'FAIL',
                  'scope': 'Actual API35 direct Flutter Village roundtrip; no physical ARM64/FPS claim'}
        try:
            source = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip()
            sys.path.insert(0, str(ROOT/'scripts'))
            from verify_legacy_release_pin import verify as verify_pin
            build, native = verify_pin((ROOT/'pubspec.yaml').read_text(), (ROOT/'config/godot-source.json').read_text())
            c4.demand(build == 2020 and source == self.args.expected_source
                      and native == self.args.expected_native, 'Actual Village QA source/native pin differs')
            subprocess.run(['git', 'diff', '--exit-code', 'HEAD', '--'], cwd=ROOT, check=True)
            identity = self.main.verify_apk_identity(self.args.apk, self.args.provenance, self.args.sums)
            c4.demand(identity['versionCode'] == 2020 and identity['godot_revision'] == native
                      and identity['flutter_source_commit'] == source,
                      'Wrong actual Village candidate identity')
            result['identity'] = identity
            metadata = [json.loads((self.args.metadata_dir/(name+'.json')).read_text())
                        for name in ('run', 'artifacts', 'jobs')]
            result['binding'] = c4.artifact_binding(*metadata, source=source,
                run_id=self.args.build_run, attempt=self.args.run_attempt,
                artifact_id=self.args.artifact_id, digest=self.args.artifact_digest,
                native=native, version_name=identity['versionName'])
            prior = json.loads(self.args.prior_tour.read_text())
            c4.demand(prior.get('status') == 'PASS' and prior.get('apk_sha256') == identity['apk_sha256']
                      and prior.get('fatal_crashes') == 0
                      and all(any(s.get('step') == name and s.get('ok') is True
                                  for s in prior.get('steps', [])) for name in self.main.HARD_STEPS),
                      'The unchanged complete main Android tour must pass before Village')
            result['prior_tour'] = {'path': str(self.args.prior_tour), 'sha256': c4.sha256(self.args.prior_tour)}
            result['root_readiness'] = self.ui.ensure_rooted_emulator(self.base.adb, self.out)
            api, result['android_sdk_original'] = self.original('village-sdk', 'shell', 'getprop', 'ro.build.version.sdk')
            c4.demand(api.strip() == '35', 'Village Android proof requires the actual API35 device')
            self.await_processes('initial-flutter', native=False)
            self.ui.device_rotation(self.out, 'village-responsive-portrait', 0)
            c4.demand(self.main.try_tap(self.out, ['Spielen', 'Spiele'], 'village-games') is not None,
                      'Actual Flutter Spielewelt navigation is unavailable')
            result['before'] = self.await_processes('before-village', native=False)
            _, result['before']['preferences'] = self.read_preferences('before-village')
            result['entry_touch'] = self.flutter_touch(village.PORTAL, 'open-village')
            result['native'] = self.observe_village()
            _, pid = village.process(self.out, result['native'], native=True)
            result['returned'] = self.visible_return(pid)
            subprocess.run(['git', 'diff', '--exit-code', 'HEAD', '--'], cwd=ROOT, check=True)
            result['status'] = 'PASS'
        except Exception as error:
            result.update(error=f'{type(error).__name__}: {error}', traceback=traceback.format_exc())
        finally:
            try:
                raw, result['original_logcat'] = self.original('village-final-all-buffer-logcat',
                    'logcat', '-b', 'all', '-d', '-v', 'threadtime', bound=256*1024*1024)
                result['fatal_entries'] = c4.runtime_errors(raw)
                if result['fatal_entries']:
                    result.update(status='FAIL', error='Actual Android/engine failure in original Village logcat')
            except Exception as error:
                result.update(status='FAIL', final_log_error=f'{type(error).__name__}: {error}')
            self.base.command = self.old_command
            result['originals'] = []
            for path in sorted(self.out.rglob('*')):
                c4.demand(not path.is_symlink(), 'Village original evidence cannot contain symlinks')
                if path.is_file():
                    result['originals'].append({'path': path.relative_to(self.out).as_posix(),
                        'bytes': path.stat().st_size, 'sha256': c4.sha256(path)})
            write(self.out/village.REPORT, result)
        if result['status'] == 'PASS':
            village.verify_report(self.out, result['binding'], result['identity'])
        print('[VillageAndroid]', json.dumps({'status': result['status'], 'error': result.get('error')}), flush=True)
        return 0 if result['status'] == 'PASS' else 1


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ('apk', 'provenance', 'sums', 'metadata-dir', 'prior-tour', 'out'):
        parser.add_argument('--'+name, type=Path, required=True)
    for name in ('expected-source', 'expected-native', 'artifact-digest'):
        parser.add_argument('--'+name, required=True)
    for name in ('build-run', 'run-attempt', 'artifact-id'):
        parser.add_argument('--'+name, type=int, required=True)
    return VillageProbe(parser.parse_args()).run()


if __name__ == '__main__':
    raise SystemExit(main())
