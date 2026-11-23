"""Diagnose „native-starts“: Filter, Startweg und Unabhängigkeit vom Rundgang."""
import importlib.util
import json
from pathlib import Path
import re
import shlex
import subprocess
import sys
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[3]
MODULE = ROOT / '.github/probes/native_start_diagnostics.py'
TOUR = ROOT / '.github/probes/modernization_android_tour.py'
MAIN_ACTIVITY = ROOT / 'tools/auto_install/MainActivity.kt'
WORKFLOW = ROOT / '.github/workflows/lumo-unified-integration-2026.yml'
PACKAGE = 'dev.example.app'

spec = importlib.util.spec_from_file_location('native_start_diagnostics_under_test', MODULE)
diag = importlib.util.module_from_spec(spec)
spec.loader.exec_module(diag)


def line(tag, text, level='I'):
    return f'11-18 15:00:00.000  1234  1234 {level} {tag}: {text}'


class FilterTests(unittest.TestCase):
    def test_keeps_game_tags_and_package_activity_lines_only(self):
        text = '\n'.join([
            line('godot', '[Router] loaded:run (res://scenes/games/lumo_run.tscn)'),
            line('chatty', 'noise'),
            line('ActivityManager', f'Start proc 99:{PACKAGE}:lumo_game'),
            line('ActivityManager', 'Start proc 77:com.other'),
            line('libc', 'Fatal signal 11 (SIGSEGV)', 'F'),
            line('lowmemorykiller', 'Kill dev.example.app:lumo_game'),
        ])
        kept = diag.filter_log(text, PACKAGE)
        self.assertEqual(len(kept), 4)
        self.assertFalse(any('com.other' in k or 'noise' in k for k in kept))
        found = diag.issues(kept)
        self.assertEqual(found['fatal_signal'], 1)
        self.assertEqual(found['lowmemorykiller'], 1)
        self.assertEqual(found['script_error'], 0)

    def test_log_is_capped_to_400_lines_with_head_and_tail(self):
        text = '\n'.join(line('godot', f'n{i}') for i in range(1000))
        kept = diag.filter_log(text, PACKAGE)
        self.assertEqual(len(kept), 400)
        self.assertTrue(kept[0].endswith('n0'))
        self.assertTrue(kept[-1].endswith('n999'))
        self.assertIn('ausgelassen', kept[100])

    def test_android_runtime_start_noise_is_not_a_crash(self):
        kept = [line('AndroidRuntime', '>>>>>> START com.android.internal.os.RuntimeInit uid 0', 'D'),
                line('AndroidRuntime', 'FATAL EXCEPTION: main', 'E')]
        self.assertEqual(diag.issues(kept)['android_runtime'], 1)


class PlanTests(unittest.TestCase):
    def test_plan_scenes_come_from_the_main_activity_whitelist(self):
        source = MAIN_ACTIVITY.read_text()
        allowed = set(re.findall(r'"(\w+)"', re.search(
            r'val game = if \(requested in setOf\(([^)]*)\)', source).group(1)))
        planned = {scene for _, scene, *_ in diag.PLAN}
        self.assertTrue({'run', 'quiz', 'cards', 'settlement', 'build', 'kart', 'chess', 'world'} <= planned)
        self.assertEqual(planned | set(diag.NOT_COVERED), allowed)
        self.assertEqual(diag.PLAN[0][1], 'run')

    def test_intent_extras_match_launch3d_fields(self):
        options = diag.launch_options('settlement')
        source = MAIN_ACTIVITY.read_text()
        for key in ('game', 'grade', 'subject', 'sessionId', 'stars', 'lifetimeStars',
                    'childKey', 'reduceAnimations', 'livingVillage', 'settlementMode'):
            self.assertIn(key, options)
            self.assertIn(f'"{key}"', source)
        self.assertNotIn('tableToken', diag.launch_options('run'))
        for _, scene, path, *_ in diag.PLAN:
            if path == 'intent':
                self.assertIn(scene, diag.INTENT_SCENES)

    def test_portal_labels_follow_the_hub_semantics(self):
        self.assertEqual(diag.portal_label('Lumo Lauf', 'Spring. Laufe. Sei mutig!'),
                         'Lumo Lauf. Spring. Laufe. Sei mutig! Spielen')
        self.assertEqual(diag.portal_label('Auf ins Abenteuer!', None), 'Auf ins Abenteuer!')
        chess = next(entry for entry in diag.PLAN if entry[0] == 'chess')
        self.assertEqual(diag.portal_label(chess[3], chess[4]),
                         'Lumo Schach. Schach lernen mit Lumo – oder gegen ihn spielen Spielen')
        hub = (ROOT / 'lib/features/games/spielwelt/spielwelt_routes.dart').read_text()
        self.assertIn("semanticTitle: 'Lumo Schach'", hub)
        self.assertIn(f"tagline: '{chess[4]}'", hub)
        world = next(entry for entry in diag.PLAN if entry[0] == 'world')
        self.assertEqual(world[2], 'ui')
        self.assertIn(f"semanticTitle: '{world[3]}'", hub)
        portal = (ROOT / 'lib/features/games/spielwelt/spielwelt_hub.dart').read_text()
        self.assertIn(f"'world' => '{world[4]}'", portal)
        self.assertEqual(diag.portal_label(world[3], world[4]),
                         'Lumo World. Dein Dorf, deine Freunde und neue Abenteuer Spielen')


class FakeDevice:
    def __init__(self, loads=True):
        self.loads = loads
        self.commands = []
        self.cleared = False
        self.state = 'native'
        self.native_activity = 'LumoGameActivity'
        self.launches = 0

    def adb(self, *args, timeout=60, check=True):
        if not check or len(args) != 2 or args[0] != 'shell':
            raise AssertionError('Collector must use checked, framed shell commands')
        script = args[1].splitlines()
        begin = shlex.split(script[0])[-1]
        end = shlex.split(script[-2])[2]
        command = script[1]
        tokens = tuple(shlex.split(command))
        if tokens[0] == 'logcat':
            command_args = tokens
        elif tokens[:2] == ('am', 'start'):
            command_args = ('shell', command)
        else:
            command_args = ('shell', *tokens)
        self.commands.append(command_args)
        output = self.execute(*command_args, timeout=timeout, check=check)
        return f'{begin}\n{output}\n{end}:0'.strip()

    def launch(self, *args):
        self.launches += 1
        self.state = 'host'
        return '5678'

    def tap(self, out, label, tag, **kwargs):
        if label in ('Spielen', 'Spiele'):
            return
        if label.startswith(('Memory.', 'Wer wird Lumo-Meister?.')):
            return  # The optional native table has a separate real UI action.
        self.state = 'native'
        self.native_activity = ('TableGameActivity' if label.startswith('3D-')
                                else 'LumoGameActivity')

    def live_nodes(self, *args):
        if self.state == 'host':
            return [{'package': PACKAGE, 'content-desc': 'Spielen\nSpielen',
                     'enabled': 'true', 'clickable': 'true', 'bounds': '[0,0][100,60]'}]
        return [{'package': PACKAGE, 'text': 'Das Spiel konnte nicht starten.'}]

    def execute(self, *args, timeout=60, check=True):
        if args[:2] == ('shell', 'pm'):
            return 'package:/data/app/base.apk'
        if args[:3] == ('shell', 'am', 'force-stop'):
            self.state = 'stopped'
            return ''
        if len(args) == 2 and args[0] == 'shell' and args[1].startswith('am start '):
            self.state = 'intent'
            return 'Status: ok'
        if args[:2] == ('logcat', '-c'):
            self.cleared = True
            return ''
        if args[:1] == ('logcat',):
            return '\n'.join([
                line('godot', '[Router] loaded:run (x)') if self.loads else line('godot', 'boot'),
                line('godot', 'SCRIPT ERROR: boom', 'E'),
            ])
        if args[:2] == ('shell', 'ps'):
            rows = ['PID NAME', '1 init']
            if self.state in ('host', 'native'):
                rows.append(f'5678 {PACKAGE}')
            if self.state in ('native', 'intent'):
                rows.append(f'1234 {PACKAGE}:lumo_game')
            return '\n'.join(rows)
        if args[:3] == ('shell', 'dumpsys', 'activity'):
            activity = 'MainActivity' if self.state == 'host' else self.native_activity
            return f'  topResumedActivity=ActivityRecord{{abc u0 {PACKAGE}/dev.example.{activity} t10}}'
        if args[:3] == ('shell', 'dumpsys', 'package'):
            return f'  {PACKAGE}/dev.example.LumoGameActivity filter'
        return ''


class FramedAdbTests(unittest.TestCase):
    """Run the actual generated remote command with /bin/sh, not a frame mock."""

    def setUp(self):
        self.folder = tempfile.TemporaryDirectory()
        self.addCleanup(self.folder.cleanup)
        self.log = '\n'.join(line('godot', f'line {i}') for i in range(200))
        self.transform = lambda text: text
        self.remote_status = 0
        self.adb_status = 0
        self.ignore_remote_status = False
        self.runner = diag.Runner(Path(self.folder.name), base=self, live=None, probe=None,
                                  package=PACKAGE)

    def adb(self, *args, timeout=60, check=True):
        self.assertEqual(args[0], 'shell')
        self.assertEqual(len(args), 2)  # One remote script, not split sh -c arguments.
        self.assertTrue(check)
        # Only logcat is substituted; framing, quoting, printf, status and exit
        # execute in a real POSIX shell exactly as generated by the collector.
        stub = (f'logcat() {{ printf %s {shlex.quote(self.log)}; '
                f'return {self.remote_status}; }}\n')
        result = subprocess.run(['/bin/sh', '-c', stub + args[1]], capture_output=True,
                                timeout=timeout, text=True)
        output = (result.stdout + result.stderr).strip()
        status = self.adb_status or (0 if self.ignore_remote_status else result.returncode)
        if check and status:
            raise RuntimeError(f'Command failed ({status}): {output}')
        return self.transform(output)

    def test_valid_complete_log_preserves_all_payload_and_exit_evidence(self):
        self.assertEqual(self.runner.logcat(), self.log)
        check = self.runner.summary['adb_checks'][-1]
        self.assertEqual(check['shell_exit_code'], 0)
        self.assertTrue(check['complete'])
        self.assertTrue(check['adb_exit_ok'])

    def test_empty_output_and_shell_metacharacters_round_trip_without_execution(self):
        self.assertEqual(self.runner.adb('shell', 'true'), '')
        payload = "spaces ' ; $(printf injected) \" $value\nnext line"
        self.assertEqual(self.runner.adb('shell', 'printf', '%s', payload), payload)

    def test_nonzero_adb_exit_rejects_even_a_complete_success_frame(self):
        self.adb_status = 7
        with self.assertRaisesRegex(RuntimeError, r'Command failed \(7\)'):
            self.runner.logcat()
        check = self.runner.summary['adb_checks'][-1]
        self.assertFalse(check['adb_exit_ok'])
        self.assertTrue((self.runner.root / check['evidence']).is_file())

    def test_nonzero_remote_exit_is_rejected_even_if_adb_returns_zero(self):
        self.remote_status = 9
        self.ignore_remote_status = True
        with self.assertRaisesRegex(RuntimeError, r'Remote command failed \(9\)'):
            self.runner.logcat()
        self.assertEqual(self.runner.summary['adb_checks'][-1]['shell_exit_code'], 9)

    def test_zero_exit_with_only_first_4096_bytes_is_incomplete(self):
        self.transform = lambda text: text[:4096]
        with self.assertRaisesRegex(RuntimeError, 'Incomplete ADB response'):
            self.runner.logcat()
        check = self.runner.summary['adb_checks'][-1]
        self.assertTrue(check['adb_exit_ok'])
        self.assertFalse(check['complete'])
        self.assertEqual(check['response_bytes'], 4096)
        self.assertEqual((self.runner.root / check['evidence']).stat().st_size, 4096)

    def test_zero_exit_with_only_last_4096_bytes_is_incomplete(self):
        self.transform = lambda text: text[-4096:]
        with self.assertRaisesRegex(RuntimeError, 'Incomplete ADB response'):
            self.runner.logcat()

    def test_wrong_duplicate_or_nonfinal_frame_is_rejected(self):
        for transform in (
                lambda text: text.replace('__LUMO_ADB_BEGIN_', '__OTHER_BEGIN_'),
                lambda text: text.splitlines()[0] + '\n' + text,
                lambda text: text + '\nunexpected trailing output'):
            with self.subTest(transform=transform):
                self.transform = transform
                with self.assertRaisesRegex(RuntimeError, 'Incomplete ADB response'):
                    self.runner.logcat()


class ProcessSnapshotTests(unittest.TestCase):
    def setUp(self):
        self.folder = tempfile.TemporaryDirectory()
        self.addCleanup(self.folder.cleanup)

    def runner(self, device):
        return diag.Runner(Path(self.folder.name), base=device, live=None, probe=None,
                           package=PACKAGE)

    def test_target_process_names_with_trailing_whitespace_are_not_absent(self):
        class Device(FakeDevice):
            def execute(self, *args, **kwargs):
                if args[:2] == ('shell', 'ps'):
                    return f'PID NAME\n1 init\n123 {PACKAGE} \n456 {PACKAGE}:lumo_game\t\n'
                return super().execute(*args, **kwargs)

        self.assertEqual(self.runner(Device()).process_snapshot(),
                         {PACKAGE: 123, PACKAGE + ':lumo_game': 456})

    def test_framed_valid_global_process_list_can_prove_app_absence(self):
        device = FakeDevice()
        device.state = 'stopped'
        self.assertEqual(self.runner(device).process_snapshot(), {})

    def test_existing_start_pause_precedes_exit_confirmation_without_reissuing_stop(self):
        events = []

        class Device(FakeDevice):
            def execute(self, *args, **kwargs):
                if args[:3] == ('shell', 'am', 'force-stop'):
                    events.append('force-stop')
                    return ''  # Kernel teardown is still completing.
                if args[:2] == ('shell', 'ps'):
                    events.append('ps')
                return super().execute(*args, **kwargs)

        device = Device()

        def settle(seconds):
            events.append(('sleep', seconds))
            device.state = 'stopped'

        with patch.object(diag.time, 'sleep', settle):
            self.runner(device).stop_app(settle=True)
        self.assertEqual(events, ['force-stop', ('sleep', 2), 'ps'])

    def test_empty_header_only_malformed_or_ambiguous_ps_never_proves_absence(self):
        outputs = ('', 'PID NAME', 'PID NAME\n', 'PID CMD\n1 init',
                   'PID NAME\n0 init', 'PID NAME\nbroken row', 'PID NAME\n1 init\n1 other',
                   f'PID NAME\n123 {PACKAGE}\n456 {PACKAGE}')
        for output in outputs:
            with self.subTest(output=output):
                class Device(FakeDevice):
                    def execute(self, *args, **kwargs):
                        if args[:2] == ('shell', 'ps'):
                            return output
                        return super().execute(*args, **kwargs)

                with self.assertRaisesRegex(RuntimeError, '(Invalid|Ambiguous) ps'):
                    self.runner(Device()).process_snapshot()

    def test_failed_or_truncated_ps_is_not_an_empty_snapshot(self):
        for failure in ('nonzero', 'truncated'):
            with self.subTest(failure=failure):
                class Device(FakeDevice):
                    def adb(self, *args, **kwargs):
                        output = super().adb(*args, **kwargs)
                        if 'ps -A -o PID,NAME' in args[1]:
                            if failure == 'nonzero':
                                raise RuntimeError('Command failed (1): ps')
                            return output.split(f'5678 {PACKAGE}')[0]
                        return output

                with self.assertRaisesRegex(RuntimeError, 'Command failed|Incomplete ADB'):
                    self.runner(Device()).process_snapshot()


class RunnerTests(unittest.TestCase):
    def run_plan(self, plan, loads=True, device=None):
        device = device or FakeDevice(loads)
        taps = []
        base = SimpleNamespace(adb=device.adb, launch=device.launch,
                               accessible_text=lambda nodes: 'Spielen')
        live = SimpleNamespace(live_nodes=device.live_nodes)

        def tap(out, label, tag, **kwargs):
            device.tap(out, label, tag, **kwargs)
            taps.append(label)

        probe = SimpleNamespace(flutter_tap=tap,
                                capture=lambda *a: (_ for _ in ()).throw(RuntimeError('no screen')))
        with tempfile.TemporaryDirectory() as folder, \
                patch.object(diag, 'PLAN', plan), patch.object(diag.time, 'sleep', lambda s: None):
            ticks = iter(range(0, 100000, 5))
            with patch.object(diag.time, 'monotonic', lambda: next(ticks)):
                summary = diag.run(Path(folder), base=base, live=live, probe=probe,
                                   package=PACKAGE, wait_seconds=45, budget_seconds=100000)
            written = json.loads((Path(folder) / 'native-starts.json').read_text())
            log_file = Path(folder) / 'native-starts' / f'{plan[0][0]}.log'
            log = log_file.read_text() if log_file.exists() else ''
        return summary, written, log, taps, device

    def test_ui_start_reports_router_process_and_app_text(self):
        summary, written, log, taps, device = self.run_plan(
            (('run', 'run', 'ui', 'Lumo Lauf', 'Spring. Laufe. Sei mutig!'),))
        self.assertEqual(written['status'], 'DONE')
        scene = written['scenes'][0]
        self.assertTrue(scene['router_loaded'])
        self.assertTrue(scene['game_process_alive_at_end'])
        self.assertEqual(scene['issues']['script_error'], 1)
        self.assertIn('Das Spiel konnte nicht starten.', scene['screen_texts']['app'])
        self.assertIn('Lumo Lauf. Spring. Laufe. Sei mutig! Spielen', taps)
        self.assertIn('[Router] loaded:run', log)
        self.assertEqual(scene['native_pid_at_end'], 1234)
        self.assertEqual(scene['router_loaded_pid'], 1234)
        self.assertIn('[Router] loaded:run', scene['router_loaded_line'])
        self.assertEqual(scene['flutter_host']['pid'], 5678)
        self.assertIn('MainActivity', scene['flutter_host']['resumed'])
        self.assertEqual(device.launches, 1)
        self.assertEqual(device.state, 'stopped')
        self.assertTrue(device.cleared)
        self.assertTrue(all(c['complete'] and c['adb_exit_ok'] and c['shell_exit_code'] == 0
                            for c in written['adb_checks']))

    def test_normal_required_ui_starts_pass_the_unchanged_verifier(self):
        gate_spec = importlib.util.spec_from_file_location(
            'native_start_gate_integration', ROOT / 'scripts/verify_native_start_diagnostics.py')
        gate = importlib.util.module_from_spec(gate_spec)
        gate_spec.loader.exec_module(gate)

        class Device(FakeDevice):
            scene = 'run'

            def live_nodes(self, *args):
                return super().live_nodes(*args) if self.state == 'host' else []

            def tap(self, out, label, tag, **kwargs):
                super().tap(out, label, tag, **kwargs)
                if label not in ('Spielen', 'Spiele'):
                    self.scene = tag.removesuffix('-native-table')

            def execute(self, *args, **kwargs):
                if args[:2] == ('logcat', '-d'):
                    return line('godot', f'[Router] loaded:{self.scene} (res://scene.tscn)')
                return super().execute(*args, **kwargs)

        plan = tuple(entry for entry in diag.PLAN if entry[0] in gate.REQUIRED)
        _, written, _, _, device = self.run_plan(plan, device=Device())
        result = gate.verify(written)
        self.assertEqual(result['status'], 'PASS')
        self.assertEqual(set(result['required_scenes']), set(gate.REQUIRED))
        self.assertEqual(device.launches, len(gate.REQUIRED))
        self.assertEqual(device.state, 'stopped')

    def test_old_processes_surviving_stop_prevent_launch_and_ui_taps(self):
        class Device(FakeDevice):
            def execute(self, *args, **kwargs):
                if args[:3] == ('shell', 'am', 'force-stop'):
                    return ''  # Exit 0 without actually stopping either old PID.
                return super().execute(*args, **kwargs)

        _, written, _, taps, device = self.run_plan(
            (('run', 'run', 'ui', 'Lumo Lauf', 'Spring. Laufe. Sei mutig!'),), device=Device())
        scene = written['scenes'][0]
        self.assertIn('survived force-stop', scene['error'])
        self.assertIn('1234', scene['error'])
        self.assertIn('5678', scene['error'])
        self.assertEqual(device.launches, 0)
        self.assertEqual(taps, [])
        self.assertNotIn('router_loaded', scene)

    def test_failed_stop_or_log_clear_aborts_instead_of_observing_a_game(self):
        for failed_command in (('shell', 'am', 'force-stop'), ('logcat', '-c')):
            with self.subTest(failed_command=failed_command):
                class Device(FakeDevice):
                    def execute(self, *args, **kwargs):
                        if args[:len(failed_command)] == failed_command:
                            raise RuntimeError('Command failed (7): critical ADB command')
                        return super().execute(*args, **kwargs)

                _, written, _, taps, _ = self.run_plan(
                    (('run', 'run', 'ui', 'Lumo Lauf', 'Spring. Laufe. Sei mutig!'),),
                    device=Device())
                scene = written['scenes'][0]
                self.assertIn('Command failed (7)', scene['error'])
                self.assertNotIn('tapped', scene)
                self.assertNotIn('router_loaded', scene)
                self.assertFalse(any(label.startswith('Lumo Lauf.') for label in taps))

    def test_native_activity_or_engine_cannot_stand_in_for_fresh_flutter_host(self):
        for stale in ('activity', 'engine'):
            with self.subTest(stale=stale):
                class Device(FakeDevice):
                    def launch(self, *args):
                        result = super().launch(*args)
                        if stale == 'engine':
                            self.state = 'native'
                        return result

                    def execute(self, *args, **kwargs):
                        if stale == 'activity' and args[:3] == ('shell', 'dumpsys', 'activity'):
                            return (f'topResumedActivity=ActivityRecord{{old u0 '
                                    f'{PACKAGE}/dev.example.TableGameActivity t13}}')
                        return super().execute(*args, **kwargs)

                _, written, _, taps, _ = self.run_plan(
                    (('run', 'run', 'ui', 'Lumo Lauf', 'Spring. Laufe. Sei mutig!'),),
                    device=Device())
                self.assertIn('Fresh Flutter host not confirmed', written['scenes'][0]['error'])
                self.assertEqual(taps, [])

    def test_relative_main_activity_component_is_a_valid_flutter_host(self):
        class Device(FakeDevice):
            def execute(self, *args, **kwargs):
                output = super().execute(*args, **kwargs)
                return output.replace('/dev.example.MainActivity', '/.MainActivity')

        _, written, _, _, _ = self.run_plan(
            (('run', 'run', 'ui', 'Lumo Lauf', 'Spring. Laufe. Sei mutig!'),), device=Device())
        self.assertNotIn('error', written['scenes'][0])
        self.assertIn('/.MainActivity', written['scenes'][0]['flutter_host']['resumed'])

    def test_foreign_disabled_or_untappable_navigation_does_not_start_a_game(self):
        for invalid in ({'package': PACKAGE + '.other'}, {'enabled': 'false'},
                        {'clickable': 'false'}, {'bounds': '[0,0][100,1]'}):
            with self.subTest(invalid=invalid):
                class Device(FakeDevice):
                    def live_nodes(self, *args):
                        nodes = super().live_nodes(*args)
                        for node in nodes:
                            node.update(invalid)
                        return nodes

                _, written, _, taps, _ = self.run_plan(
                    (('run', 'run', 'ui', 'Lumo Lauf', 'Spring. Laufe. Sei mutig!'),),
                    device=Device())
                self.assertIn('no enabled live', written['scenes'][0]['error'])
                self.assertEqual(taps, [])

    def test_partial_log_containing_router_marker_is_not_positive_evidence(self):
        class Device(FakeDevice):
            def execute(self, *args, **kwargs):
                if args[:2] == ('logcat', '-d'):
                    return line('godot', '[Router] loaded:run (x)') + '\n' + 'noise' * 1500
                return super().execute(*args, **kwargs)

            def adb(self, *args, **kwargs):
                output = super().adb(*args, **kwargs)
                return output[:4096] if 'logcat -d' in args[1] else output

        _, written, _, _, _ = self.run_plan(
            (('run', 'run', 'ui', 'Lumo Lauf', 'Spring. Laufe. Sei mutig!'),), device=Device())
        scene = written['scenes'][0]
        self.assertTrue(scene['tapped'])
        self.assertIn('Incomplete ADB response', scene['error'])
        self.assertNotIn('router_loaded', scene)

    def test_final_stop_failure_sets_error_even_after_positive_router_observation(self):
        class Device(FakeDevice):
            stops = 0

            def execute(self, *args, **kwargs):
                if args[:3] == ('shell', 'am', 'force-stop'):
                    self.stops += 1
                    if self.stops == 2:
                        raise RuntimeError('Command failed (7): final stop')
                return super().execute(*args, **kwargs)

        _, written, _, _, _ = self.run_plan(
            (('run', 'run', 'ui', 'Lumo Lauf', 'Spring. Laufe. Sei mutig!'),), device=Device())
        scene = written['scenes'][0]
        self.assertTrue(scene['router_loaded'])
        self.assertIn('Unverified app shutdown', scene['error'])
        self.assertIn('Command failed (7)', scene['force_stop_error'])

    def test_middle_of_long_log_keeps_errors_and_router_evidence_before_display_truncation(self):
        class Device(FakeDevice):
            def execute(self, *args, timeout=60, check=True):
                if args[:1] == ('logcat',) and args[:2] != ('logcat', '-c'):
                    messages = [line('godot', f'ordinary line {index}') for index in range(1000)]
                    messages[500] = line('godot', '[Router] loaded:run (res://scene.tscn)')
                    messages[550] = line('godot', 'SCRIPT ERROR: middle failure', 'E')
                    return '\n'.join(messages)
                return super().execute(*args, timeout=timeout, check=check)

        _, written, log, _, _ = self.run_plan(
            (('run', 'run', 'ui', 'Lumo Lauf', 'Spring. Laufe. Sei mutig!'),), device=Device())
        scene = written['scenes'][0]
        self.assertEqual(scene['log_lines'], 400)
        self.assertEqual(scene['full_relevant_log_lines'], 1000)
        self.assertNotIn('middle failure', log)
        self.assertNotIn('[Router] loaded:run', log)
        self.assertEqual(scene['issues']['script_error'], 1)
        self.assertEqual(scene['godot_error_classes']['other'], 1)
        self.assertIn('middle failure', scene['markers']['script_error'][0])
        self.assertTrue(scene['router_loaded'])
        self.assertEqual(scene['router_loaded_pid'], 1234)
        self.assertIn('[Router] loaded:run', scene['router_loaded_line'])

    def test_foreign_godot_pid_cannot_supply_router_or_crash_evidence(self):
        class Device(FakeDevice):
            def execute(self, *args, timeout=60, check=True):
                if args[:1] == ('logcat',) and args[:2] != ('logcat', '-c'):
                    return '\n'.join([
                        line('godot', '[Router] loaded:run (x)').replace('1234', '9999'),
                        line('godot', 'SCRIPT ERROR: foreign game', 'E').replace('1234', '9999')])
                return super().execute(*args, timeout=timeout, check=check)

        _, written, _, _, _ = self.run_plan(
            (('run', 'run', 'ui', 'Lumo Lauf', 'Spring. Laufe. Sei mutig!'),), device=Device())
        scene = written['scenes'][0]
        self.assertTrue(scene['game_process_alive_at_end'])
        self.assertFalse(scene['router_loaded'])
        self.assertIsNone(scene['router_loaded_pid'])
        self.assertEqual(scene['issues']['script_error'], 0)

    def test_similar_package_and_other_child_process_do_not_count_as_game_engine(self):
        class Device(FakeDevice):
            def execute(self, *args, timeout=60, check=True):
                if args[:2] == ('shell', 'ps') and self.state == 'native':
                    return (f'PID NAME\n5678 {PACKAGE}\n'
                            f'1234 {PACKAGE}.other:lumo_game\n4567 {PACKAGE}:helper')
                return super().execute(*args, timeout=timeout, check=check)

        _, written, _, _, _ = self.run_plan(
            (('run', 'run', 'ui', 'Lumo Lauf', 'Spring. Laufe. Sei mutig!'),), device=Device())
        scene = written['scenes'][0]
        self.assertFalse(scene['game_process_alive_at_end'])
        self.assertFalse(scene['router_loaded'])
        self.assertTrue(scene['app_alive_at_end'])

    def test_intent_start_is_labelled_and_uses_launch_extras(self):
        _, written, _, taps, device = self.run_plan((('run-intent', 'run', 'intent', None, None),),
                                                    loads=False)
        scene = written['scenes'][0]
        self.assertEqual(scene['path'], 'intent')
        self.assertFalse(scene['router_loaded'])
        self.assertEqual(taps, [])
        command = [c for c in device.commands if c[:1] == ('shell',) and len(c) == 2 and 'am start' in c[1]]
        self.assertEqual(len(command), 1)
        self.assertIn('--es lumoLaunchOptions', command[0][1])
        self.assertIn('"game":"run"', command[0][1])

    def test_memory_explicitly_opens_native_table_after_flutter_round(self):
        _, written, _, taps, _ = self.run_plan(
            (('memory', 'memory', 'ui', 'Memory', 'Finde die Paare!'),))
        label = '3D-Memory-Tisch freiwillig öffnen'
        self.assertIn(label, taps)
        scene = written['scenes'][0]
        self.assertTrue(scene['memory_table_button_tapped'])
        self.assertEqual(scene['native_table_button'], label)
        # A tap alone never fabricates the observed native router marker.
        self.assertFalse(scene['router_loaded'])
        self.assertIn(label, (ROOT / 'lib/features/games/memory/lumo_memory_game.dart').read_text())

    def test_already_open_native_table_is_not_started_twice(self):
        class Device(FakeDevice):
            def tap(self, out, label, tag, **kwargs):
                super().tap(out, label, tag, **kwargs)
                if label.startswith('Memory.'):
                    self.state = 'native'
                    self.native_activity = 'TableGameActivity'

        _, written, _, taps, _ = self.run_plan(
            (('memory', 'memory', 'ui', 'Memory', 'Finde die Paare!'),), device=Device())
        self.assertNotIn('3D-Memory-Tisch freiwillig öffnen', taps)
        self.assertNotIn('memory_table_button_tapped', written['scenes'][0])


class RealRunFindingsTests(unittest.TestCase):
    """Findings of run 44473804677 (native-starts.json, native-starts/*.log)."""

    def test_gl_link_refusals_are_separated_from_other_godot_errors(self):
        log = [line('godot', 'ERROR: CanvasShaderGLES3: Program linking failed:', 'E'),
               line('godot', 'Fragment shader active uniforms exceed GL_MAX_FRAGMENT_UNIFORM_VECTORS (261)', 'E'),
               line('godot', '   at: _display_error_with_code (drivers/gles3/shader_gles3.cpp:259)', 'E'),
               line('godot', 'ERROR: Method/function failed.', 'E'),
               line('godot', '   at: _compile_specialization (drivers/gles3/shader_gles3.cpp:461)', 'E'),
               line('godot', 'ERROR: Failed loading resource: res://missing.tscn', 'E'),
               line('godot', 'SCRIPT ERROR: Invalid call', 'E')]
        self.assertEqual(diag.godot_error_classes(log), {'gl_shader_link': 2, 'other': 2})
        self.assertEqual(diag.issues(log)['godot_error'], 4)  # SCRIPT ERROR counts too

    def run_with(self, device, plan):
        base = SimpleNamespace(adb=device.adb, launch=device.launch,
                               accessible_text=lambda nodes: 'Spielen')
        live = SimpleNamespace(live_nodes=device.live_nodes)
        probe = SimpleNamespace(flutter_tap=device.tap,
                                capture=lambda *a: (_ for _ in ()).throw(RuntimeError('no screen')))
        with tempfile.TemporaryDirectory() as folder, \
                patch.object(diag, 'PLAN', plan), patch.object(diag.time, 'sleep', lambda s: None):
            ticks = iter(range(0, 100000, 5))
            with patch.object(diag.time, 'monotonic', lambda: next(ticks)):
                diag.run(Path(folder), base=base, live=live, probe=probe,
                         package=PACKAGE, wait_seconds=45, budget_seconds=100000)
            return json.loads((Path(folder) / 'native-starts.json').read_text())

    def test_intent_start_uses_the_component_android_resumed(self):
        class Device(FakeDevice):
            def execute(self, *args, timeout=60, check=True):
                if args[:3] == ('shell', 'dumpsys', 'package'):
                    # Real resolver table: only activities with intent filters.
                    return f'  44e135c {PACKAGE}/dev.example.MainActivity filter 7bf5f3a'
                if args[:3] == ('shell', 'dumpsys', 'activity') and self.state in ('native', 'intent'):
                    return (f'  topResumedActivity=ActivityRecord{{7394784 u0 '
                            f'{PACKAGE}/dev.example.LumoGameActivity t10}}')
                return super().execute(*args, timeout=timeout, check=check)

        device = Device()
        written = self.run_with(device, (('run', 'run', 'ui', 'Lumo Lauf', 'Spring. Laufe. Sei mutig!'),
                                         ('run-intent', 'run', 'intent', None, None)))
        intent = written['scenes'][1]
        self.assertNotIn('error', intent)
        self.assertEqual(intent['intent']['component'], f'{PACKAGE}/dev.example.LumoGameActivity')

    def test_hanging_force_stop_keeps_the_entry_and_later_scenes(self):
        class Device(FakeDevice):
            stops = 0

            def execute(self, *args, timeout=60, check=True):
                if args[:3] == ('shell', 'am', 'force-stop'):
                    self.stops += 1
                    if self.stops == 2:
                        raise subprocess.TimeoutExpired(('adb', *args), 60)
                return super().execute(*args, timeout=timeout, check=check)

        written = self.run_with(Device(), (('run-intent', 'run', 'intent', None, None),
                                           ('jump-intent', 'jump', 'intent', None, None)))
        self.assertEqual(written['status'], 'DONE')
        self.assertEqual([scene['id'] for scene in written['scenes']], ['run-intent', 'jump-intent'])
        self.assertIn('TimeoutExpired', written['scenes'][0]['force_stop_error'])
        self.assertIn('Unverified app shutdown', written['scenes'][0]['error'])
        self.assertNotIn('force_stop_error', written['scenes'][1])


class TourIndependenceTests(unittest.TestCase):
    def test_tour_exit_code_is_computed_before_and_independent_of_diagnostics(self):
        source = TOUR.read_text()
        start = source.index("if os.environ.get('LUMO_NATIVE_START_DIAGNOSTICS') == '1':")
        block = source[start:source.index("return 0 if result['status'] == 'PASS' else 1")]
        self.assertNotIn('result[', block)
        self.assertNotIn('tour-result', block)
        self.assertIn('except BaseException', block)
        self.assertGreater(start, source.index("(out / 'tour-result.json').write_text(json.dumps(result, indent=2))\n        print("))

    def test_only_the_unified_tour_enables_it_with_time_for_it(self):
        text = WORKFLOW.read_text()
        self.assertIn("LUMO_NATIVE_START_DIAGNOSTICS: '1'", text)
        job = text[text.index('  android-tour:'):text.index('  update-from-2013:')]
        self.assertIn('timeout-minutes: 70', job)
        self.assertIn('path: tour/', job)


if __name__ == '__main__':
    unittest.main()
