#!/usr/bin/env python3
"""Diagnose-Abschnitt „native-starts“ des Android-Rundgangs.

Startet nach dem eigentlichen Rundgang jede native Spielszene, die die App
öffnen kann, so wie ein Kind es tut (Spielewelt-Kachel in der echten
Flutter-Oberfläche). Nur wo das nicht geht, wird LumoGameActivity direkt mit
denselben Extras gestartet, die MainActivity.launch3D erzeugt; das steht dann
als ``path: "intent"`` im Bericht.

Reine Beobachtung: Der Abschnitt ändert weder ``tour-result.json`` noch den
Exit-Code des Rundgangs. Jede Szene wird mit 45–60 s Wartezeit beobachtet;
gefiltertes logcat je Szene liegt in ``native-starts/<id>.log``, die
Zusammenfassung in ``native-starts.json``. Ins Job-Log geht je Szene eine Zeile.
"""
from __future__ import annotations

import json
import re
import shlex
import time
import traceback
import uuid
from pathlib import Path

# Tags/Muster, die ins Szenen-Log kommen (logcat -v threadtime).
LOG_TAGS = ('godot', 'Godot', 'LumoHost', 'AndroidRuntime', 'DEBUG', 'libc',
            'lowmemorykiller', 'lmkd', 'GodotLib', 'GodotPlugin')
MAX_LOG_LINES = 400
ISSUE_PATTERNS = {
    'script_error': re.compile(r'SCRIPT ERROR'),
    'godot_error': re.compile(r'\bERROR:'),
    'fatal': re.compile(r'FATAL'),
    'android_runtime': re.compile(r'\sE AndroidRuntime|FATAL EXCEPTION'),
    'fatal_signal': re.compile(r'Fatal signal'),
    'lowmemorykiller': re.compile(r'lowmemorykiller|lmkd.*[Kk]ill'),
    'loading_too_long': re.compile(r'Das Laden dauert'),
    'boot_load_error': re.compile(r'\[BootLoad\] error'),
    'process_died': re.compile(r'ActivityManager.*(Process .* has died|Killing .*lumo)'),
}

# (Kennung, Szene, Weg, Kachel-Beschriftungen). Die Beschriftungen sind die
# Semantics-Labels aus lib/features/games/spielwelt/spielwelt_hub.dart
# ('<semanticTitle>. <tagline> <Status>') bzw. sichtbare Knopftexte.
# Szenen laut Whitelist in tools/auto_install/MainActivity.kt (launch3D):
# kart jump run puzzle build settlement rhythm treasure learning cards
# connect_four games memory quiz.
PLAN = (
    ('run', 'run', 'ui', 'Lumo Lauf', 'Spring. Laufe. Sei mutig!'),
    ('quiz', 'quiz', 'ui', 'Wer wird Lumo-Meister?', '20 Fragen · 3 Joker · bis 5.000 Sterne'),
    ('memory', 'memory', 'ui', 'Memory', 'Finde die Paare!'),
    ('chess', 'chess', 'ui', 'Lumo Schach',
     'Schach lernen mit Lumo – oder gegen ihn spielen'),
    ('kart', 'kart', 'ui', 'Lumo Kart', 'Fahre mit Lumo um die Wette!'),
    ('run-intent', 'run', 'intent', None, None),
    ('cards', 'cards', 'ui', 'Lumo Karten', 'Sammeln. Spielen. Staunen!'),
    ('settlement', 'settlement', 'ui', 'Dorf & Wirtschaft',
     'Versorge dein Dorf, baue Häuser und hilf deinen Nachbarn!'),
    ('build', 'build', 'ui', 'Bauwelt',
     'Bauen. Gestalten. Deiner Fantasie sind keine Grenzen gesetzt!'),
    ('run-abenteuer', 'run', 'ui-button', 'Auf ins Abenteuer!', None),
    ('puzzle', 'puzzle', 'ui', 'Puzzle', 'Stück für Stück die Welt entdecken!'),
    ('rhythm', 'rhythm', 'ui', 'Rhythm Party', 'Fühl den Beat!'),
    ('treasure', 'treasure', 'ui', 'Schatzsuche', 'Rätsel. Hinweise. Schätze!'),
    ('world', 'world', 'ui', 'Lumo World', 'Dein Dorf, deine Freunde und neue Abenteuer'),
    ('games', 'games', 'ui-button', 'Magische 3D-Spielewelt betreten', None),
    ('jump-intent', 'jump', 'intent', None, None),
)
NOT_COVERED = {
    'learning': 'braucht eine Lernaufgabe aus einem Lernmodul (launch3D learning=…)',
    'connect_four': 'braucht ein Vier-gewinnt-Token aus der Flutter-Runde',
    'skypost': 'eigener Freiflug- und Rückkehrtest im Hauptrundgang',
}
INTENT_SCENES = {'kart', 'jump', 'run', 'puzzle', 'build', 'settlement', 'rhythm',
                 'treasure', 'cards', 'games'}
STATUS_WORDS = ('Spielen', 'Noch gesperrt', 'Kommt bald')
THREADTIME_PID = re.compile(r'^\S+\s+\S+\s+(\d+)\s+\d+\s+[VDIWEF]\s+')


def log_pid(line: str) -> int | None:
    match = THREADTIME_PID.match(line)
    return int(match.group(1)) if match else None


def is_relevant(line: str, package: str, process_pids: set[int] | None = None) -> bool:
    """Gehört die logcat-Zeile ins Szenen-Log?"""
    if process_pids is not None and log_pid(line) not in process_pids:
        # System death/start records use the system PID but identify our exact
        # package. Errors from another app's Godot/AndroidRuntime do not.
        if not re.search(re.escape(package) + r'(?=[:/\s,)}\'\"]|$)', line):
            return False
    match = re.match(r'^\S+\s+\S+\s+\d+\s+\d+\s+[VDIWEF]\s+([^:]+?)\s*:', line)
    tag = match.group(1).strip() if match else ''
    if tag in LOG_TAGS:
        return True
    if tag in ('ActivityManager', 'ActivityTaskManager', 'WindowManager') and package in line:
        return True
    return any(word in line for word in ('Fatal signal', 'lowmemorykiller', 'FATAL EXCEPTION'))


def filter_log(text: str, package: str, limit: int | None = MAX_LOG_LINES,
               process_pids: set[int] | None = None) -> list[str]:
    lines = [line for line in text.splitlines() if is_relevant(line, package, process_pids)]
    if limit is None or len(lines) <= limit:
        return lines
    head = limit // 4
    tail = limit - head - 1
    return lines[:head] + [f'… {len(lines) - head - tail} Zeilen ausgelassen …'] + lines[-tail:]


def router_lines(lines: list[str], scene: str, pid: int | None) -> list[str]:
    marker = f'[Router] loaded:{scene} '
    return [line for line in lines if pid is not None and log_pid(line) == pid and marker in line]


def issues(lines: list[str]) -> dict[str, int]:
    return {name: sum(1 for line in lines if pattern.search(line))
            for name, pattern in ISSUE_PATTERNS.items()}


def godot_error_classes(lines: list[str]) -> dict[str, int]:
    """Split ``ERROR:`` lines into GL shader link refusals and everything else.

    On the SwiftShader emulator of run 44473804677 every logged Godot error was
    a GLES3 link refusal ("Fragment shader active uniforms exceed
    GL_MAX_FRAGMENT_UNIFORM_VECTORS"), each followed by "Method/function
    failed" at ``_compile_specialization``. Those say something about the GL
    driver, not about a game script; ``other`` keeps the remaining errors.
    """
    gl = other = 0
    for index, text in enumerate(lines):
        if not ISSUE_PATTERNS['godot_error'].search(text):
            continue
        following = ' '.join(lines[index + 1:index + 3])
        if 'ShaderGLES3: Program linking failed' in text or (
                'Method/function failed' in text and '_compile_specialization' in following):
            gl += 1
        else:
            other += 1
    return {'gl_shader_link': gl, 'other': other}


def first_lines(lines: list[str], pattern: re.Pattern, count: int = 3) -> list[str]:
    return [line[-300:] for line in lines if pattern.search(line)][:count]


def launch_options(scene: str) -> dict:
    """Dieselben Felder, die MainActivity.launch3D in lumoLaunchOptions schreibt."""
    options = {'game': scene, 'grade': 1, 'subject': 'Mathematik',
               'sessionId': str(uuid.uuid4()), 'stars': 0, 'lifetimeStars': 0,
               'childKey': 'standalone'}
    if scene == 'settlement':
        options.update(livingVillage=True, settlementMode='settlement')
    if scene in ('build', 'settlement'):
        options.update(learningVoiceEnabled=False, localVoiceLicenseAccepted=False,
                       learningAutoRead=False, learningVoiceRate=1.0)
    options['reduceAnimations'] = False
    return options


def portal_label(title: str, tagline: str | None, status: str = 'Spielen') -> str:
    return title if tagline is None else f'{title}. {tagline} {status}'


def observed_portal_status(folder: Path, title: str) -> list[str]:
    """Beschriftungen der Kachel aus den beim Suchen gelesenen Bäumen."""
    found: set[str] = set()
    prefix = title + '. '
    for xml in sorted(folder.glob('*.xml')):
        try:
            text = xml.read_text(errors='replace')
        except OSError:
            continue
        for value in re.findall(r'(?:content-desc|text)="([^"]*)"', text):
            value = value.replace('&amp;', '&').replace('&#10;', '\n')
            if value.startswith(prefix):
                found.add(value[:200])
    return sorted(found)


class Runner:
    def __init__(self, out: Path, *, base, live, probe, package: str,
                 wait_seconds: int = 50, budget_seconds: int = 1200):
        self.root = out / 'native-starts'
        (self.root / 'work').mkdir(parents=True, exist_ok=True)
        self.summary_path = out / 'native-starts.json'
        self.base, self.live, self.probe = base, live, probe
        self.package = package
        self.wait_seconds = max(45, min(60, wait_seconds))
        self.budget = budget_seconds
        self.started = time.monotonic()
        self.summary: dict = {'section': 'native-starts', 'status': 'RUNNING', 'package': package,
                              'wait_seconds': self.wait_seconds, 'scenes': [],
                              'not_covered': NOT_COVERED,
                              'note': 'Diagnose; beeinflusst tour-result.json und den Exit-Code nicht.'}
        self.component: str | None = None

    # ------------------------------------------------------------- helpers
    def adb(self, *args: str, timeout: int = 60) -> str:
        return self.base.adb(*args, timeout=timeout, check=False)

    def write(self) -> None:
        self.summary_path.write_text(json.dumps(self.summary, indent=2, ensure_ascii=False))

    def process_snapshot(self) -> dict[str, int]:
        text = self.adb('shell', 'ps', '-A', '-o', 'PID,NAME')
        allowed = {self.package, self.package + ':lumo_game'}
        result = {}
        for line in text.splitlines():
            columns = line.split()
            if len(columns) == 2 and columns[0].isdigit() and columns[1] in allowed:
                result[columns[1]] = int(columns[0])
        return result

    def processes(self) -> list[str]:
        return list(self.process_snapshot())

    def game_processes(self) -> list[str]:
        return [name for name in self.processes() if name == self.package + ':lumo_game']

    def resumed(self) -> str:
        text = self.adb('shell', 'dumpsys', 'activity', 'activities')
        lines = [line.strip() for line in text.splitlines()
                 if 'mResumedActivity' in line or 'topResumedActivity' in line]
        return ' | '.join(lines)[:400]

    def shot(self, name: str) -> None:
        """Kleines JPEG ins Artefakt (nie ins Job-Log)."""
        try:
            self.probe.capture(self.root, name)
            source = self.root / (name + '.png')
            from PIL import Image
            image = Image.open(source).convert('RGB')
            image.thumbnail((900, 900))
            image.save(self.root / (name + '.jpg'), format='JPEG', quality=80)
            source.unlink()
        except Exception:
            pass

    def logcat(self) -> str:
        return self.adb('logcat', '-d', '-v', 'threadtime', timeout=90)

    def screen_texts(self, tag: str) -> dict:
        try:
            nodes = self.live.live_nodes(self.root / 'work', tag)
        except Exception as error:  # Der Leser ist eine Beobachtung, keine Bedingung.
            return {'error': f'{type(error).__name__}: {error}'[:200]}
        app, system = [], []
        for node in nodes:
            for value in (node.get('text', ''), node.get('content-desc', '')):
                value = value.strip()
                if not value:
                    continue
                (app if node.get('package') == self.package else system).append(value[:160])
        return {'app': list(dict.fromkeys(app))[:25], 'system': list(dict.fromkeys(system))[:10]}

    def resolve_component(self) -> str | None:
        if self.component is None:
            text = self.adb('shell', 'dumpsys', 'package', self.package)
            self.component = self.observe_component(text)
        return self.component

    def observe_component(self, text: str) -> str | None:
        """LumoGameActivity as Android itself named it.

        ``dumpsys package`` lists only activities with intent filters; the
        non-exported LumoGameActivity has none (run 44473804677: "nicht im
        installierten Paket gefunden"). The resumed-activity line of an earlier
        real start through the Flutter tile names the same component.
        """
        match = re.search(re.escape(self.package) + r'/([\w.]*LumoGameActivity)\b', text)
        return self.package + '/' + match.group(1) if match else None

    def fresh_app(self, tag: str) -> dict:
        """App neu starten und zur Spielewelt gehen, wie ein Kind."""
        self.adb('shell', 'am', 'force-stop', self.package)
        time.sleep(2)
        work = self.root / 'work'
        self.base.launch(work, tag + '-launch')
        for index in range(30):
            try:
                text = self.base.accessible_text(self.live.live_nodes(work, f'{tag}-home-{index}'))
            except Exception:
                text = ''
            if 'Spielen' in text or 'Spiele' in text:
                break
            time.sleep(1)
        for label in ('Spielen', 'Spiele'):
            try:
                self.probe.flutter_tap(work, label, f'{tag}-nav', scroll_attempts=2)
                time.sleep(2)
                return {'navigated': label}
            except Exception:
                continue
        return {'navigated': None}

    # ------------------------------------------------------------- one scene
    def observe(self, ident: str, scene: str, path: str, title, tagline) -> dict:
        entry: dict = {'id': ident, 'scene': scene, 'path': path}
        work = self.root / 'work' / ident
        work.mkdir(parents=True, exist_ok=True)
        try:
            if path.startswith('ui'):
                entry.update(self.fresh_app(ident))
                self.adb('logcat', '-c')
                label = portal_label(title, tagline)
                entry['label'] = label
                try:
                    self.probe.flutter_tap(work, label, ident, scroll_attempts=10,
                                           direction_order=(1, -1), min_visible_height_px=48)
                    entry['tapped'] = True
                except Exception as error:
                    entry['tapped'] = False
                    entry['tap_error'] = f'{type(error).__name__}: {error}'[:300]
                    if tagline is not None:
                        entry['observed_portal_labels'] = observed_portal_status(work, title)
                if scene in ('quiz', 'memory') and entry['tapped'] and 'TableGameActivity' not in self.resumed():
                    # Both portals deliberately open a usable Flutter round first.
                    # Observe the optional native table only after its real UI action.
                    native_label = ('3D-Quizstudio öffnen' if scene == 'quiz'
                                    else '3D-Memory-Tisch freiwillig öffnen')
                    self.probe.flutter_tap(work, native_label, ident + '-native-table',
                                           scroll_attempts=3, min_visible_height_px=48)
                    entry['native_table_button'] = native_label
                    entry['studio_button_tapped' if scene == 'quiz'
                          else 'memory_table_button_tapped'] = True
            else:
                self.adb('shell', 'am', 'force-stop', self.package)
                time.sleep(2)
                self.adb('logcat', '-c')
                component = self.resolve_component()
                if component is None:
                    raise RuntimeError('LumoGameActivity nicht im installierten Paket gefunden')
                options = json.dumps(launch_options(scene), separators=(',', ':'))
                entry['intent'] = {'component': component, 'lumoLaunchOptions': options}
                command = ('am start -W -n ' + shlex.quote(component) +
                           ' --es lumoLaunchOptions ' + shlex.quote(options))
                entry['am_start'] = self.adb('shell', command, timeout=90)[-600:]
                entry['tapped'] = True
            entry['resumed_after_tap'] = self.resumed()
            if self.component is None:
                self.component = self.observe_component(entry['resumed_after_tap'])
            started = time.monotonic()
            native_process_name = self.package + ':lumo_game'
            observed_pids = set(self.process_snapshot().values())
            loaded_at_by_pid: dict[int, float] = {}
            shot_taken = False
            while time.monotonic() - started < self.wait_seconds:
                time.sleep(5)
                snapshot = self.process_snapshot()
                observed_pids.update(snapshot.values())
                native_pid = snapshot.get(native_process_name)
                if native_pid is not None and native_pid not in loaded_at_by_pid:
                    if router_lines(self.logcat().splitlines(), scene, native_pid):
                        loaded_at_by_pid[native_pid] = round(time.monotonic() - started, 1)
                if not shot_taken and time.monotonic() - started >= 20:
                    shot_taken = True
                    self.shot(f'{ident}-20s')
            entry['resumed_at_end'] = self.resumed()
            entry['screen_texts'] = self.screen_texts(f'{ident}/end')
            self.shot(f'{ident}-end')
            snapshot = self.process_snapshot()
            observed_pids.update(snapshot.values())
            native_pid = snapshot.get(native_process_name)
            entry['process_snapshot_at_end'] = snapshot
            entry['observed_process_pids'] = sorted(observed_pids)
            entry['native_process_name'] = native_process_name
            entry['native_pid_at_end'] = native_pid
            entry['game_processes_at_end'] = [native_process_name] if native_pid is not None else []
            entry['game_process_alive_at_end'] = native_pid is not None
            entry['app_alive_at_end'] = self.package in snapshot
            raw = self.logcat()
            # Error counters and evidence always inspect the full relevant log.
            # Only the human-readable artifact is shortened to 400 lines.
            lines = filter_log(raw, self.package, limit=None, process_pids=observed_pids)
            view_lines = filter_log(raw, self.package, process_pids=observed_pids)
            (self.root / f'{ident}.log').write_text('\n'.join(view_lines) + '\n')
            entry['log_lines'] = len(view_lines)
            entry['full_relevant_log_lines'] = len(lines)
            matching_router = router_lines(lines, scene, native_pid)
            entry['router_loaded'] = bool(matching_router)
            entry['router_loaded_pid'] = native_pid if matching_router else None
            entry['router_loaded_line'] = matching_router[0] if matching_router else None
            entry['router_loaded_after_s'] = (
                loaded_at_by_pid.get(native_pid, round(time.monotonic() - started, 1))
                if matching_router else None)
            entry['issues'] = issues(lines)
            entry['godot_error_classes'] = godot_error_classes(lines)
            entry['markers'] = {
                'router_loaded': matching_router[:2],
                'boot_load_error': first_lines(lines, ISSUE_PATTERNS['boot_load_error']),
                'script_error': first_lines(lines, ISSUE_PATTERNS['script_error']),
                'fatal': first_lines(lines, re.compile(r'FATAL|Fatal signal|AndroidRuntime')),
                'lowmemorykiller': first_lines(lines, ISSUE_PATTERNS['lowmemorykiller']),
                'lumo_run_ready': first_lines(lines, re.compile(re.escape('[LumoRun] ready'))),
            }
            # Ungefiltertes Ende (nur im Artefakt) für Tags außerhalb des Filters.
            (self.root / 'work' / f'{ident}-logcat-tail.txt').write_text('\n'.join(raw.splitlines()[-1500:]))
        except Exception as error:
            entry['error'] = f'{type(error).__name__}: {error}'[:500]
            entry['traceback'] = traceback.format_exc()[-1500:]
        finally:
            # A hanging force-stop (run 44473804677: 60 s timeout after
            # run-abenteuer) must not discard this entry and every later scene.
            try:
                self.adb('shell', 'am', 'force-stop', self.package)
            except Exception as error:
                entry['force_stop_error'] = f'{type(error).__name__}: {error}'[:300]
        return entry

    def run(self) -> dict:
        try:
            if 'package:' not in self.adb('shell', 'pm', 'path', self.package):
                self.summary.update(status='SKIPPED', reason='App ist nicht installiert')
                return self.summary
            self.summary['android_sdk'] = self.adb('shell', 'getprop', 'ro.build.version.sdk').strip()
            self.summary['memory'] = self.adb('shell', 'cat', '/proc/meminfo')[:200]
            for ident, scene, path, title, tagline in PLAN:
                elapsed = time.monotonic() - self.started
                if elapsed + self.wait_seconds + 40 > self.budget:
                    self.summary['scenes'].append({'id': ident, 'scene': scene,
                                                   'skipped': 'Zeitbudget erschöpft'})
                    continue
                entry = self.observe(ident, scene, path, title, tagline)
                entry['seconds'] = round(time.monotonic() - self.started - elapsed, 1)
                self.summary['scenes'].append(entry)
                self.write()
                print('[NativeStart]', summary_line(entry), flush=True)
            self.summary['status'] = 'DONE'
        except Exception as error:
            self.summary.update(status='ERROR', error=f'{type(error).__name__}: {error}'[:500])
        finally:
            self.summary['seconds'] = round(time.monotonic() - self.started, 1)
            self.write()
        return self.summary


def summary_line(entry: dict) -> str:
    found = {k: v for k, v in (entry.get('issues') or {}).items() if v}
    texts = (entry.get('screen_texts') or {}).get('app') or []
    parts = [f"id={entry.get('id')}", f"weg={entry.get('path')}",
             f"getippt={entry.get('tapped')}", f"geladen={entry.get('router_loaded')}",
             f"nach_s={entry.get('router_loaded_after_s')}",
             f"spielprozess_am_ende={entry.get('game_process_alive_at_end')}",
             f"auffaellig={found}"]
    if texts:
        parts.append('app_text=' + json.dumps(texts[:3], ensure_ascii=False))
    if entry.get('error'):
        parts.append('fehler=' + entry['error'][:120])
    elif entry.get('tap_error'):
        parts.append('tippfehler=' + entry['tap_error'][:120])
    return ' '.join(parts)[:400]


def run(out: Path, *, base, live, probe, package: str, wait_seconds: int = 50,
        budget_seconds: int = 1200) -> dict:
    return Runner(out, base=base, live=live, probe=probe, package=package,
                  wait_seconds=wait_seconds, budget_seconds=budget_seconds).run()
