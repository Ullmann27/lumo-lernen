"""Diagnose „native-starts“: Filter, Startweg und Unabhängigkeit vom Rundgang."""
import importlib.util
import json
from pathlib import Path
import re
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
        self.assertTrue({'run', 'quiz', 'cards', 'settlement', 'build', 'kart'} <= planned)
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


class FakeDevice:
    def __init__(self, loads=True):
        self.loads = loads
        self.commands = []
        self.cleared = False

    def adb(self, *args, timeout=60, check=True):
        self.commands.append(args)
        if args[:2] == ('shell', 'pm'):
            return 'package:/data/app/base.apk'
        if args[:2] == ('logcat', '-c'):
            self.cleared = True
            return ''
        if args[:1] == ('logcat',):
            return '\n'.join([
                line('godot', '[Router] loaded:run (x)') if self.loads else line('godot', 'boot'),
                line('godot', 'SCRIPT ERROR: boom', 'E'),
            ])
        if args[:2] == ('shell', 'ps'):
            return f'PID NAME\n1 {PACKAGE}\n2 {PACKAGE}:lumo_game'
        if args[:3] == ('shell', 'dumpsys', 'package'):
            return f'  {PACKAGE}/dev.example.LumoGameActivity filter'
        return ''


class RunnerTests(unittest.TestCase):
    def run_plan(self, plan, loads=True):
        device = FakeDevice(loads)
        taps = []
        base = SimpleNamespace(adb=device.adb, launch=lambda *a: '1',
                               accessible_text=lambda nodes: 'Spielen')
        live = SimpleNamespace(live_nodes=lambda *a: [
            {'package': PACKAGE, 'text': 'Das Spiel konnte nicht starten.'}])
        probe = SimpleNamespace(flutter_tap=lambda out, label, tag, **k: taps.append(label),
                                capture=lambda *a: (_ for _ in ()).throw(RuntimeError('no screen')))
        with tempfile.TemporaryDirectory() as folder, \
                patch.object(diag, 'PLAN', plan), patch.object(diag.time, 'sleep', lambda s: None):
            ticks = iter(range(0, 100000, 5))
            with patch.object(diag.time, 'monotonic', lambda: next(ticks)):
                summary = diag.run(Path(folder), base=base, live=live, probe=probe,
                                   package=PACKAGE, wait_seconds=45, budget_seconds=100000)
            written = json.loads((Path(folder) / 'native-starts.json').read_text())
            log = (Path(folder) / 'native-starts' / f'{plan[0][0]}.log').read_text()
        return summary, written, log, taps, device

    def test_ui_start_reports_router_process_and_app_text(self):
        summary, written, log, taps, _ = self.run_plan(
            (('run', 'run', 'ui', 'Lumo Lauf', 'Spring. Laufe. Sei mutig!'),))
        self.assertEqual(written['status'], 'DONE')
        scene = written['scenes'][0]
        self.assertTrue(scene['router_loaded'])
        self.assertTrue(scene['game_process_alive_at_end'])
        self.assertEqual(scene['issues']['script_error'], 1)
        self.assertIn('Das Spiel konnte nicht starten.', scene['screen_texts']['app'])
        self.assertIn('Lumo Lauf. Spring. Laufe. Sei mutig! Spielen', taps)
        self.assertIn('[Router] loaded:run', log)

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
