#!/usr/bin/env python3
"""Actual API35 C4 touch/IPC/return on the already fully toured 2020 APK.

All app-private reads are observational. Only real Android UI inputs change the
round. Native reported control geometry is bound to two current original PNGs,
the actual activity/process and the production Dart mailbox before each touch.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import time
import traceback

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools/android_qa'))
import connect_four_android_evidence as contract


def write(path: Path, value: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open('x', encoding='utf-8') as stream:
        stream.write(json.dumps(value, ensure_ascii=False, indent=2) + '\n')


class Probe:
    def __init__(self, args):
        import creative_android_probe as live_probe
        import modernization_android_tour as main_tour
        self.args, self.out = args, args.out
        contract.demand(not self.out.exists() or not any(self.out.iterdir()),
                        'Refusing to overwrite existing C4 evidence')
        self.out.mkdir(parents=True, exist_ok=True)
        self.ui, self.main, self.base = live_probe, main_tour, live_probe.base
        self.deadline = time.monotonic() + 900
        self.counter = 0
        self.observations = []
        self.transitions = []
        self.returns = []
        self.old_command = self.base.command
        self.base.command = self.bounded_command
        self.mailbox = ''
        self.token = ''

    def remaining(self, maximum: float = 45) -> float:
        left = self.deadline - time.monotonic()
        if left <= 0:
            raise TimeoutError('The complete C4 Android observation exceeded 900 seconds')
        return min(left, maximum)

    def bounded_command(self, *args, timeout=60, check=True):
        return self.old_command(*args, timeout=self.remaining(timeout), check=check)

    def original(self, tag: str, *arguments: str, check=True, bound=1024*1024) -> tuple[str, str]:
        self.counter += 1
        prefix = f'commands/{self.counter:04d}-{tag}'
        stem = self.out / prefix
        stem.parent.mkdir(parents=True, exist_ok=True)
        started = time.monotonic()
        result = subprocess.run(['adb', *arguments], stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                timeout=self.remaining(45), check=False)
        for suffix, data in (('.stdout', result.stdout), ('.stderr', result.stderr)):
            with Path(str(stem) + suffix).open('xb') as stream:
                stream.write(data)
        write(Path(str(stem) + '.json'), {'command':['adb', *arguments],
              'returncode':result.returncode, 'elapsed_seconds':time.monotonic()-started,
              'stdout_bytes':len(result.stdout), 'stderr_bytes':len(result.stderr),
              'stdout_sha256':hashlib.sha256(result.stdout).hexdigest(),
              'stderr_sha256':hashlib.sha256(result.stderr).hexdigest()})
        self.remaining()
        contract.demand(len(result.stdout) <= bound, 'Original reply exceeds its stated bound: ' + tag)
        if check:
            contract.demand(result.returncode == 0 and not result.stderr,
                            'Original read failed: ' + tag + ' (see ' + prefix + ')')
        return result.stdout.decode('utf-8'), prefix + '.stdout'

    def read_json(self, name: str, path: str) -> tuple[dict, str]:
        raw, source = self.original(name, 'exec-out', 'cat', path)
        value = json.loads(raw)
        contract.demand(isinstance(value, dict), 'Original JSON is not an object: ' + path)
        return value, source

    def read_preferences(self, tag: str) -> tuple[dict, str]:
        raw, source = self.original(tag + '-preferences', 'exec-out', 'cat',
            f'/data/user/0/{contract.PACKAGE}/shared_prefs/FlutterSharedPreferences.xml')
        return contract.preferences(raw), source

    def density(self) -> tuple[float, str]:
        text, source = self.original('density', 'shell', 'wm', 'density')
        return contract.device_density(text), source

    def locate(self) -> bool:
        directory = f'/data/user/0/{contract.PACKAGE}/files/lumo_connect_four_session_v1'
        raw, _ = self.original('locate-c4-session', 'shell', 'find', directory,
                              '-maxdepth', '2', '-type', 'f', '-name', 'state.json', check=False)
        matches = [p for p in raw.splitlines() if re.fullmatch(
            re.escape(directory) + r'/[a-f0-9]{32}/state\.json', p)]
        contract.demand(len(matches) <= 1, 'Multiple actual native C4 sessions exist')
        if not matches:
            return False
        self.mailbox = str(Path(matches[0]).parent)
        self.token = Path(self.mailbox).name
        return True

    def observation(self, tag: str, control: str | None = None) -> dict:
        from PIL import Image
        contract.demand(bool(self.mailbox), 'No observed private C4 mailbox')
        state, sf = self.read_json(tag + '-state', self.mailbox + '/state.json')
        contract.demand(state.get('token') == self.token, 'Private C4 token changed')
        layout_path = f'/data/user/0/{contract.PACKAGE}/files/connect_four_layout_v1.json'
        layout, lf = self.read_json(tag + '-layout', layout_path)
        life, lif = self.read_json(tag + '-lifecycle', self.mailbox + '/lifecycle.json')
        clock, cf = self.original(tag + '-clock', 'shell', 'date', '+%s%3N')
        contract.demand(bool(re.fullmatch(r'\d{13}\s*', clock)), 'Missing actual device millisecond clock')
        contract.demand(life.get('active') is True and contract.integer(life.get('stamp'), 1, 2**63-1)
                        and 0 <= int(clock)-life['stamp'] < 2500,
                        'Actual native visible lease is stale or inactive')
        native, pf = self.original(tag + '-native-pid', 'shell', 'pidof', contract.PACKAGE + ':lumo_game')
        host, hf = self.original(tag + '-host-pid', 'shell', 'pidof', contract.PACKAGE)
        contract.demand(bool(re.fullmatch(r'\d+\s*', native)) and bool(re.fullmatch(r'\d+\s*', host))
                        and int(native) != int(host), 'Actual Flutter/native processes are not distinct')
        activity, af = self.original(tag + '-activity', 'shell', 'dumpsys', 'activity', 'activities')
        foreground = [line for line in activity.splitlines()
                      if 'mResumedActivity' in line or 'topResumedActivity' in line]
        contract.demand(foreground and all('ConnectFourGameActivity' in line for line in foreground),
                        'Actual private C4 Activity is not foreground')
        services, service_file = self.original(tag + '-authority', 'shell', 'dumpsys', 'activity',
                                               'services', contract.PACKAGE)
        contract.demand('ConnectFourAuthorityService' in services,
                        'The real private C4 authority service is not bound')
        prefs, prefs_file = self.read_preferences(tag)
        contract.persisted_round(prefs, state)
        frame = self.ui.capture(self.out, tag, timeout=self.remaining())
        png = self.out / frame['file']
        surface = self.ui.inspect_surface(png, orientation='responsive')
        contract.demand(surface['acceptable_for_target_sampling'], 'Current C4 surface is incomplete')
        with Image.open(png) as image:
            image.load()
            pixels = tuple(image.size)
        again, s2 = self.read_json(tag + '-state-after-frame', self.mailbox + '/state.json')
        layout_again, l2 = self.read_json(tag + '-layout-after-frame', layout_path)
        contract.demand(state == again and layout == layout_again,
                        'C4 state/layout changed while the original frame was captured')
        density, density_file = self.density()
        contract.validate_layout(layout, state, pixels, int(native), density)
        visual = contract.board_pixels(png, layout, state, int(native), density)
        result = {'id':tag, 'state':state, 'layout':layout, 'lifecycle':life,
                  'device_clock_ms':int(clock), 'pid':int(native), 'host_pid':int(host),
                  'density':density, 'pixels':list(pixels), 'frame':frame['file'],
                  'frame_sha256':contract.sha256(png), 'visual':visual, 'surface':surface,
                  'observed_monotonic':time.monotonic(),
                  'raw':{'state':sf, 'state_after':s2, 'layout':lf, 'layout_after':l2,
                         'lifecycle':lif, 'clock':cf, 'native_pid':pf, 'host_pid':hf,
                         'activity':af, 'authority':service_file, 'preferences':prefs_file,
                         'density':density_file}}
        if control is not None:
            result['target'] = contract.touch_target(layout, state, pixels, int(native), density, control)
        self.observations.append(result)
        write(self.out / ('observations/' + tag + '.json'), result)
        return result

    def wait_observation(self, tag: str, condition, *, control=None, timeout=90) -> dict:
        deadline = time.monotonic() + self.remaining(timeout)
        failures = []
        count = 0
        while time.monotonic() < deadline:
            name = f'{tag}-{count:03d}'; count += 1
            try:
                if not self.mailbox and not self.locate():
                    raise ValueError('Native C4 has not opened a private session')
                observed = self.observation(name, control)
                if condition(observed):
                    self.remaining()
                    return observed
                failures.append({'attempt':name, 'reason':'Actual state has not reached the required phase'})
            except (ValueError, RuntimeError, json.JSONDecodeError) as error:
                failures.append({'attempt':name, 'reason':str(error)})
            time.sleep(min(.6, max(0, deadline-time.monotonic())))
        write(self.out / (tag + '-wait-failure.json'), failures)
        raise TimeoutError('No qualifying actual C4 observation: ' + tag)

    def native_touch(self, tag: str, control: str) -> dict:
        first = self.wait_observation(tag + '-first', lambda value: True, control=control)
        time.sleep(min(.6, self.remaining()))
        second = self.wait_observation(tag + '-second', lambda value: True, control=control)
        target = contract.stable_target(first, second)
        contract.demand(contract.sha256(self.out / second['frame']) == second['frame_sha256'],
                        'Current original frame changed before dispatch')
        self.remaining(.2)
        x, y = map(str, target['point'])
        response, source = self.original(tag + '-touch', 'shell', 'input', 'swipe', x, y, x, y, '120')
        contract.demand(not response.strip(), 'Unexpected actual touch dispatch response')
        write(self.out / (tag + '-touch.json'), {'first':first['id'], 'second':second['id'],
              'target':target, 'command_original':source, 'gesture':'120ms stationary actual Android touch'})
        return second

    def transition(self, tag: str, action: str, control: str) -> dict:
        before = self.native_touch(tag, control)
        def arrived(value):
            state = value['state']
            if state['ack'] != before['state']['ack'] + 1:
                return False
            return (state['paused'] if action == 'pause' else
                    not state['paused'] and state['canDrop'] and
                    (len(state['columns']) == len(before['state']['columns']) + 2 if action == 'drop' else True))
        after = self.wait_observation(tag + '-confirmed', arrived, timeout=120)
        request, source = self.read_json(tag + '-request', self.mailbox + '/request.json')
        contract.acknowledged(before['state'], after['state'], request, action)
        item = {'action':action, 'before':before['id'], 'after':after['id'],
                'request':source, 'touch':tag + '-touch.json'}
        self.transitions.append(item)
        write(self.out / (tag + '-transition.json'), item)
        return after

    def flutter_touch(self, label: str, tag: str, *, scrolls=12) -> str:
        previous = None
        for index in range(scrolls + 1):
            self.remaining()
            name = f'{tag}-{index:02d}'
            nodes = self.ui.read_live_nodes(self.out, name)
            capture = self.ui.capture_flutter_ready(self.out, name + '-frame', timeout=self.remaining(30))
            pixels = (capture['width'], capture['height'])
            density, density_file = self.density()
            observation = {'capture':capture, 'ui':name + '.xml', 'density':density_file,
                           'observed_monotonic':time.monotonic()}
            try:
                target = contract.flutter_control(nodes, label, pixels, density)
            except ValueError:
                visible = [n for n in nodes if n.get('package') == contract.PACKAGE
                           and n.get('enabled') == 'true' and n.get('clickable') == 'true'
                           and label in (n.get('text',''), n.get('content-desc',''))]
                contract.demand(len(visible) <= 1, 'Ambiguous actual Flutter caption: ' + label)
                previous = None
                containers = []
                for node in nodes:
                    if node.get('package') != contract.PACKAGE or node.get('scrollable') != 'true':
                        continue
                    bounds = list(map(int, re.findall(r'\d+', node.get('bounds', ''))))
                    if len(bounds) == 4 and 0 <= bounds[0] < bounds[2] <= pixels[0] and 0 <= bounds[1] < bounds[3] <= pixels[1]:
                        containers.append(bounds)
                if index == scrolls or not containers:
                    raise
                rect = max(containers, key=lambda r:(r[2]-r[0])*(r[3]-r[1]))
                x = round((rect[0]+rect[2])/2)
                lo = round(rect[1]+(rect[3]-rect[1])*.25)
                hi = round(rect[1]+(rect[3]-rect[1])*.75)
                self.original(name + '-scroll', 'shell', 'input', 'swipe', str(x), str(hi), str(x), str(lo), '400')
                time.sleep(min(.6, self.remaining()))
                continue
            if previous and target == previous['target']:
                source = self.out / capture['file']
                contract.demand(contract.sha256(source) == capture['sha256'], 'Flutter frame changed before touch')
                x,y = map(str, target['point'])
                _, command = self.original(tag + '-touch', 'shell', 'input', 'swipe', x,y,x,y,'120')
                name = tag + '-flutter-touch.json'
                write(self.out / name, {'target':target,
                      'first':previous['observation'], 'second':observation, 'command_original':command})
                return name
            previous = {'target':target, 'observation':observation}
            time.sleep(min(.6, self.remaining()))
        raise RuntimeError('No two stable actual Flutter observations: ' + label)

    def return_to_flutter(self, tag: str) -> dict:
        before = self.native_touch(tag, 'back')
        contract.demand(before['state']['paused'], 'Return must follow the proved actual pause')
        deadline = time.monotonic() + self.remaining(45)
        while time.monotonic() < deadline:
            native, pf = self.original(tag + '-native-exit', 'shell', 'pidof', contract.PACKAGE + ':lumo_game', check=False)
            activity, af = self.original(tag + '-return-activity', 'shell', 'dumpsys', 'activity', 'activities')
            active = [line for line in activity.splitlines() if 'mResumedActivity' in line or 'topResumedActivity' in line]
            if not native.strip() and active and all('MainActivity' in line and contract.PACKAGE in line for line in active):
                break
            time.sleep(min(.5, max(0, deadline-time.monotonic())))
        else:
            raise RuntimeError('Native C4 did not return to the actual Flutter activity')
        closed, closed_file = self.original(tag + '-closed-mailbox', 'shell', 'find',
            self.mailbox.rsplit('/',1)[0], '-maxdepth','2','-type','f','-name','state.json')
        contract.demand(not closed.strip(), 'Closed C4 mailbox still exists')
        prefs, prefs_file = self.read_preferences(tag + '-after-return')
        record = contract.persisted_round(prefs, before['state'])
        frame = self.ui.capture_flutter_ready(self.out, tag + '-flutter', timeout=self.remaining(30))
        nodes = self.ui.read_live_nodes(self.out, tag + '-returned-ui')
        labels = '\n'.join(n.get('text','') + '\n' + n.get('content-desc','') for n in nodes)
        contract.demand('Spiel pausiert' in labels and 'Fortsetzen' in labels,
                        'Actual paused Flutter C4 return is not visible')
        item = {'before':before['id'], 'frame':frame, 'preferences':prefs_file,
                'native_exit':pf, 'activity':af, 'closed_mailbox':closed_file,
                'round':record, 'returned_ui':tag + '-returned-ui.xml',
                'touch':tag + '-touch.json'}
        item['to_games_touch'] = self.flutter_touch('Zur Spieleauswahl', tag + '-to-games', scrolls=3)
        self.returns.append(item)
        write(self.out / (tag + '-return.json'), item)
        return before

    def run(self) -> int:
        result = {'schema':1, 'status':'FAIL', 'scope':'Actual API35 C4 candidate test; no release/FPS/API37 claim',
                  'observations':[], 'transitions':[], 'returns':[]}
        try:
            source = subprocess.check_output(['git','rev-parse','HEAD'], cwd=ROOT, text=True).strip()
            pin = json.loads((ROOT / 'config/godot-source.json').read_text())
            sys.path.insert(0, str(ROOT / 'scripts'))
            from verify_legacy_release_pin import verify as verify_pin
            build, native = verify_pin((ROOT / 'pubspec.yaml').read_text(), (ROOT / 'config/godot-source.json').read_text())
            contract.demand(build == 2020 and source == self.args.expected_source
                            and self.args.expected_native == native == pin['revision'],
                            'Actual checked-out QA/APK/native identity differs')
            subprocess.run(['git','diff','--exit-code','HEAD','--'], cwd=ROOT, check=True)
            identity = self.main.verify_apk_identity(self.args.apk, self.args.provenance, self.args.sums)
            contract.demand(identity['versionCode'] == 2020 and identity['godot_revision'] == native, 'Wrong 2020 candidate identity')
            result['identity'] = identity
            meta = [json.loads((self.args.metadata_dir / (name+'.json')).read_text())
                    for name in ('run','artifacts','jobs')]
            result['binding'] = contract.artifact_binding(*meta, source=source,
                run_id=self.args.build_run, attempt=self.args.run_attempt,
                artifact_id=self.args.artifact_id, digest=self.args.artifact_digest,
                native=native, version_name=identity['versionName'])
            prior = json.loads(self.args.prior_tour.read_text())
            contract.demand(prior.get('status') == 'PASS' and prior.get('apk_sha256') == identity['apk_sha256']
                            and prior.get('fatal_crashes') == 0
                            and all(any(s.get('step') == name and s.get('ok') is True for s in prior.get('steps',[]))
                                    for name in self.main.HARD_STEPS), 'The complete existing main tour must pass first')
            result['prior_tour'] = {'path':str(self.args.prior_tour), 'sha256':contract.sha256(self.args.prior_tour)}
            result['root_readiness'] = self.ui.ensure_rooted_emulator(self.base.adb, self.out)
            api, api_file = self.original('sdk', 'shell','getprop','ro.build.version.sdk')
            contract.demand(api.strip() == '35', 'This C4 device proof is explicitly API35')
            result['android_sdk_original'] = api_file
            self.base.launch(self.out, 'c4-start')
            self.ui.device_rotation(self.out, 'c4-responsive-portrait', 0)
            contract.demand(self.main.try_tap(self.out, ['Spielen','Spiele'], 'c4-games') is not None,
                            'Actual games navigation is unavailable')
            before_prefs, before_file = self.read_preferences('before-c4')
            result['preferences_before'] = before_file
            result['entry_touch'] = self.flutter_touch(contract.PORTAL, 'open-c4')
            initial = self.wait_observation('initial', lambda o:not o['state']['paused'] and o['state']['canDrop'])
            contract.demand(initial['state']['columns'] == [] and not initial['state']['twoPlayers'],
                            'Initial actual C4 round is not the untouched single-player game')
            result['initial'] = initial['id']
            first = self.transition('child-first', 'drop', 'column_3')
            paused = self.transition('pause-first', 'pause', 'pause')
            time.sleep(min(1.2, self.remaining()))
            held = self.wait_observation('pause-held', lambda o:o['state']['paused'])
            contract.paused_unchanged(paused, held, held['observed_monotonic']-paused['observed_monotonic'])
            result['pause_hold'] = {'first':paused['id'], 'second':held['id'],
                                   'elapsed':held['observed_monotonic']-paused['observed_monotonic']}
            self.transition('resume-first', 'resume', 'resume')
            second = self.transition('child-second', 'drop', 'column_2')
            self.transition('pause-before-return', 'pause', 'pause')
            closed = self.return_to_flutter('return-first')
            old_token = self.token
            self.mailbox, self.token = '', ''
            reopen_touch = self.flutter_touch(contract.PORTAL, 'reopen-c4')
            again = self.wait_observation('reopened', lambda o:not o['state']['paused'] and o['state']['canDrop'])
            contract.reopened(closed['state'], again['state'])
            contract.demand(again['state']['token'] != old_token and again['pid'] != closed['pid'],
                            'Reopen did not create a new real private native session/process')
            result['reopen'] = {'closed':closed['id'], 'opened':again['id'], 'touch':reopen_touch}
            self.transition('pause-after-reopen', 'pause', 'pause')
            self.return_to_flutter('return-final')
            after_prefs, after_file = self.read_preferences('after-c4')
            contract.learning_unchanged(before_prefs, after_prefs)
            result['preferences_after'] = after_file
            subprocess.run(['git','diff','--exit-code','HEAD','--'], cwd=ROOT, check=True)
            self.remaining()
            result['status'] = 'PASS'
        except Exception as error:
            result.update(error=f'{type(error).__name__}: {error}', traceback=traceback.format_exc())
        finally:
            try:
                raw, log_file = self.original('final-all-buffer-logcat', 'logcat','-b','all','-d','-v','threadtime',
                                              bound=256*1024*1024)
                errors = contract.runtime_errors(raw)
                result['original_logcat'] = log_file
                result['fatal_entries'] = errors
                if errors:
                    result.update(status='FAIL', error='Actual engine/Android failure in original all-buffer logcat')
            except Exception as error:
                result.update(status='FAIL', final_log_error=f'{type(error).__name__}: {error}')
            self.base.command = self.old_command
            result.update(observations=[o['id'] for o in self.observations],
                          transitions=self.transitions, returns=self.returns)
            files = []
            for path in sorted(self.out.rglob('*')):
                if path.is_file():
                    contract.demand(not path.is_symlink(), 'Original evidence cannot contain symlinks')
                    files.append({'path':str(path.relative_to(self.out)), 'bytes':path.stat().st_size,
                                  'sha256':contract.sha256(path)})
            result['originals'] = files
            write(self.out / 'c4-result.json', result)
            print('[ConnectFourAndroid]', json.dumps({'status':result['status'], 'error':result.get('error'),
                  'observations':len(self.observations), 'transitions':len(self.transitions)}), flush=True)
        return 0 if result['status'] == 'PASS' else 1


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ('apk','provenance','sums','metadata-dir','prior-tour','out'):
        parser.add_argument('--'+name, type=Path, required=True)
    for name in ('expected-source','expected-native','artifact-digest'):
        parser.add_argument('--'+name, required=True)
    for name in ('build-run','run-attempt','artifact-id'):
        parser.add_argument('--'+name, type=int, required=True)
    args = parser.parse_args()
    return Probe(args).run()


if __name__ == '__main__':
    raise SystemExit(main())
