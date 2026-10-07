#!/usr/bin/env python3
"""Exercise a source/digest-pinned APK and preserve an actual baseline profile.

Only fictional data in a disposable Android emulator is used. Flutter controls
come from live accessibility; native Godot controls from current screenshot OCR.
No game completion, score, unlock, XML or touch target is injected into the app.
"""
from __future__ import annotations

import argparse
import csv
import hashlib
from http.client import RemoteDisconnected
import json
import os
from pathlib import Path
import re
import sys
import time
import traceback
import unicodedata
import xml.etree.ElementTree as ET

from PIL import Image, ImageChops

# Keep screenshot recognition from oversubscribing the same software-rendered
# emulator host. This changes only the independent OCR reader, not the app.
os.environ.setdefault('OMP_THREAD_LIMIT','1')

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / 'scripts' / 'probes'))
import pr207_android_smoke as base
import pr207_android_ui_probe as live

PACKAGE = base.PACKAGE
BASE_DIGEST = os.environ.get('LUMO_BASE_DIGEST', 'd33b9f5f04a013bc1bcafb579758d109f511ff69e9c08bc95b68c34d9b1c6e7e')
SOURCE = os.environ.get('LUMO_EXPECT_SOURCE', '53e294c9a057c0f15012a35c00dcaf666b6f37b4')
GODOT = os.environ.get('LUMO_EXPECT_GODOT', '148decd2b34af7bfb5f1504c166d42411f8e99e1')
EXPECTED_VERSION = int(os.environ.get('LUMO_EXPECT_VERSION', '1502'))
CERT = 'a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702'
base.ui_nodes = live.live_nodes
base.tap_label = live.live_tap_label
_original_live_nodes = live.live_nodes


def digest(path: Path) -> str:
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def normalized(value: str) -> str:
    plain = unicodedata.normalize('NFKD', value).encode('ascii', 'ignore').decode()
    return re.sub('[^a-z0-9]', '', plain.lower())


def capture(out: Path, name: str) -> dict:
    result = base.capture(out, name)
    print('[AndroidCapture]', result['file'], flush=True)
    return result


def device_rotation(out: Path, tag: str, quarter_turns: int) -> None:
    """Turn the disposable device; app state and screenshots stay unmodified."""
    if quarter_turns not in (0, 1):
        raise ValueError('This probe uses upright and landscape device positions')
    before = base.adb('shell', 'wm', 'user-rotation')
    base.adb('shell', 'wm', 'user-rotation', 'lock', str(quarter_turns))
    after = base.adb('shell', 'wm', 'user-rotation')
    (out / f'{tag}-device-rotation.json').write_text(json.dumps({
        'requested_quarter_turns': quarter_turns,
        'before': before, 'after': after,
        'note': 'Actual display size and controls are independently checked by screencap/OCR',
    }, indent=2) + '\n')
    time.sleep(3)


def read_live_nodes(out: Path, name: str) -> list:
    # Retry only a dropped connection to the independent accessibility reader.
    # Keep the app and its data untouched and still require a fresh hierarchy.
    for attempt in range(3):
        try:
            return _original_live_nodes(out, name)
        except (RemoteDisconnected, json.JSONDecodeError):
            if attempt == 2:
                raise
            record = out / 'ui-reader-recovery.json'
            events = json.loads(record.read_text()) if record.exists() else []
            events.append({'read':name, 'attempt':attempt+1,
                           'reason':'accessibility reader returned an incomplete response'})
            record.write_text(json.dumps(events, indent=2)+'\n')
            live._device = None
            time.sleep(1)
    raise RuntimeError('Live accessibility retry exhausted')


live.live_nodes = read_live_nodes
base.ui_nodes = read_live_nodes


def recover_launcher_dialog(out: Path, nodes: list[dict], tag: str) -> bool:
    # The disposable emulator can show a Pixel Launcher ANR over Lumo's welcome
    # screen. Dismiss only that exact observed system dialog. A Lumo ANR must
    # remain a failure, and no application data is cleared.
    if not any(n.get('package') == 'android' and
               n.get('text') == "Pixel Launcher isn't responding" for n in nodes):
        return False
    records_path = out / 'launcher-recovery.json'
    records = json.loads(records_path.read_text()) if records_path.exists() else []
    if len(records) >= 2:
        raise RuntimeError('Disposable Pixel Launcher repeatedly stopped responding')
    buttons = [n for n in nodes if n.get('package') == 'android' and
               n.get('text') == 'Close app' and n.get('enabled') == 'true']
    if len(buttons) != 1:
        raise RuntimeError('Observed Pixel Launcher dialog lacks one enabled Close app control')
    bounds = list(map(int, re.findall(r'\d+', buttons[0].get('bounds', ''))))
    if len(bounds) != 4 or bounds[2] <= bounds[0] or bounds[3] <= bounds[1]:
        raise RuntimeError('Pixel Launcher dialog control has invalid observed bounds')
    evidence = capture(out, tag+'-pixel-launcher-dialog')
    records.append({'dialog':"Pixel Launcher isn't responding", 'action':'Close app',
                    'observed_bounds':bounds, 'capture':evidence['file']})
    records_path.write_text(json.dumps(records, indent=2)+'\n')
    x0,y0,x1,y1 = bounds
    base.adb('shell','input','tap',str((x0+x1)//2),str((y0+y1)//2))
    time.sleep(2)
    return True


def flutter_tap(out: Path, label: str, tag: str) -> None:
    # Search both ends of the actual responsive scroll view. Named controls are
    # tapped only when their enabled live accessibility bounds have been read.
    for direction in (-1, 1):
        for attempt in range(12):
            nodes = live.live_nodes(out, f'{tag}-{direction}-{attempt}')
            if recover_launcher_dialog(out, nodes, tag):
                continue
            choices = []
            for node in nodes:
                values = (node.get('text', ''), node.get('content-desc', ''))
                if not any(label == v or label in v.split('\n') for v in values):
                    continue
                bounds = list(map(int, re.findall(r'\d+', node.get('bounds', ''))))
                if len(bounds) != 4 or node.get('enabled') == 'false':
                    continue
                x0, y0, x1, y1 = bounds
                if x1 > x0 and y1 > y0:
                    choices.append(((x1-x0)*(y1-y0), x0, y0, x1, y1))
            if choices:
                _, x0, y0, x1, y1 = min(choices)
                x,y = str((x0+x1)//2),str((y0+y1)//2)
                # A brief real finger press avoids a zero-duration ADB tap
                # disappearing between busy software-rendered Flutter frames.
                base.adb('shell', 'input', 'swipe', x, y, x, y, '120')
                time.sleep(2)
                return
            # The assistant panel occupies the bottom of the window. Scroll
            # inside the actual live content viewport, rather than starting
            # a window-relative swipe on that fixed overlay or the side rail.
            scrolls = []
            for node in nodes:
                if node.get('scrollable') != 'true' or node.get('package') != PACKAGE:
                    continue
                bounds = list(map(int,re.findall(r'\d+',node.get('bounds',''))))
                if len(bounds) == 4:
                    x0,y0,x1,y1 = bounds
                    if x1>x0 and y1>y0:
                        scrolls.append(((x1-x0)*(y1-y0),x0,y0,x1,y1))
            if not scrolls:
                time.sleep(.5)
                continue
            _,x0,y0,x1,y1 = max(scrolls)
            x = (x0+x1)//2
            low,high = y0+(y1-y0)*.2, y1-(y1-y0)*.2
            start,end = (low,high) if direction == -1 else (high,low)
            base.adb('shell', 'input', 'swipe', str(x), str(round(start)),
                     str(x), str(round(end)), '400')
            time.sleep(.4)
    capture(out, tag+'-missing')
    raise RuntimeError('No enabled live Flutter control: '+label)


def image_lines(out: Path, tag: str, wanted: str = '', source_path: Path | None = None) -> list[dict]:
    if source_path is None:
        snapshot = capture(out, tag)
        source = out / snapshot['file']
    else:
        source = source_path
    image = Image.open(source).convert('RGB')
    result = []
    # White UI letters on dark glass can disappear among the detailed 3D
    # background. A second read separates their contrast, without changing
    # any screenshot used as evidence or inventing a control coordinate.
    contrast = image.convert('L').point(lambda value: 0 if value >= 170 else 255)
    # A bright cyan button outline can be grouped with its white text as one
    # unreadable glyph. Separate neutral bright letters by their colour, using
    # the entire current screenshot and retaining the observed word bounds.
    red, green, blue = image.split()
    darkest = ImageChops.darker(ImageChops.darker(red, green), blue)
    lightest = ImageChops.lighter(ImageChops.lighter(red, green), blue)
    bright = darkest.point(lambda value: 255 if value >= 150 else 0)
    neutral = ImageChops.subtract(lightest, darkest).point(
        lambda value: 255 if value <= 45 else 0)
    white_text = ImageChops.invert(ImageChops.multiply(bright, neutral))
    # The German model can miss short UI phrases that the Latin/English model
    # reads correctly. Keep both reads, with independent observed word bounds.
    variants = [('contrast',contrast,'deu+eng'),('raw',image,'deu+eng'),
                ('white-text',white_text,'deu+eng'),('white-latin',white_text,'eng')]
    for variant, pixels, language in variants:
        expanded = out / 'ocr-work.png'
        pixels.resize((image.width*2,image.height*2)).save(expanded)
        prefix = out / (tag+'-ocr-'+variant)
        base.command('tesseract',str(expanded),str(prefix),'--psm','11',
                     '-l',language,'tsv',timeout=45)
        groups: dict[tuple,list[dict]] = {}
        with prefix.with_suffix('.tsv').open() as stream:
            for word in csv.DictReader(stream,delimiter='\t'):
                if not word.get('text','').strip() or float(word['conf']) < 15:
                    continue
                key=tuple(word[k] for k in ('page_num','block_num','par_num','line_num'))
                groups.setdefault(key,[]).append(word)
        for words in groups.values():
            words.sort(key=lambda word:int(word['left']))
            spans=[words]
            # Use the exact phrase's own OCR bounds when adjacent toolbar
            # buttons appear in the same text line. Its line midpoint could
            # otherwise land on a different button.
            for start in range(len(words)):
                for end in range(start+1,min(len(words),start+8)+1):
                    span=words[start:end]
                    if normalized(' '.join(word['text'] for word in span)) == wanted:
                        spans.append(span)
            for span in spans:
                x0=min(int(word['left']) for word in span)/2
                y0=min(int(word['top']) for word in span)/2
                x1=max(int(word['left'])+int(word['width']) for word in span)/2
                y1=max(int(word['top'])+int(word['height']) for word in span)/2
                result.append({'text':' '.join(word['text'] for word in span),
                               'bounds':[x0,y0,x1,y1],'variant':variant})
        if wanted and any(wanted in normalized(line['text']) for line in result):
            break
    (out/(tag+'-ocr.json')).write_text(json.dumps(result,indent=2,ensure_ascii=False))
    return result


def native_text(out: Path, label: str, tag: str, tap: bool = False) -> None:
    wanted = normalized(label)
    for attempt in range(8):
        lines = image_lines(out, f'{tag}-{attempt}', wanted)
        matches = [line for line in lines if wanted in normalized(line['text'])]
        if matches:
            selected = min(matches, key=lambda line: len(line['text']))
            if tap:
                x0,y0,x1,y1 = selected['bounds']
                base.adb('shell','input','tap',str(round((x0+x1)/2)),
                         str(round((y0+y1)/2)))
                time.sleep(1.5)
            return
        time.sleep(2)
    raise RuntimeError('Current native screenshot lacks '+label)


def enter(out: Path, title: str, header: str, tag: str, launch_label: str = '') -> None:
    flutter_tap(out, launch_label or title+' spielen', tag+'-launch')
    for _ in range(60):
        # Android has no resumed activity during the real portrait/landscape
        # transition. Wait for the requested native foreground, keeping the
        # process/header checks below; do not abort on that transient gap.
        try:
            foreground = base.foreground()
        except RuntimeError:
            foreground = ''
        if 'LumoGameActivity' in foreground:
            break
        time.sleep(1)
    else:
        raise RuntimeError('Private game activity did not launch: '+title)
    if not base.adb('shell','pidof',PACKAGE+':lumo_game',check=False):
        raise RuntimeError('Native game process missing')
    time.sleep(4)
    native_text(out, header, tag+'-header')


def leave(out: Path, tag: str, already_menu: bool = False) -> None:
    if not already_menu:
        base.adb('shell','input','keyevent','KEYCODE_BACK')
        time.sleep(1)
    native_text(out,'Zur Spielewelt',tag+'-pause',tap=True)
    for _ in range(15):
        if not base.adb('shell','pidof',PACKAGE+':lumo_game',check=False):
            break
        time.sleep(1)
    else:
        raise RuntimeError('Private game process did not stop after returning')
    if 'LumoGameActivity' in base.foreground():
        raise RuntimeError('Game activity is still foreground')
    capture(out,tag+'-returned-to-app')


def prefs(out: Path, tag: str) -> dict:
    raw = base.adb('exec-out','cat',f'/data/user/0/{PACKAGE}/shared_prefs/FlutterSharedPreferences.xml')
    (out/(tag+'-preferences.xml')).write_text(raw)
    return {node.get('name'):node.text for node in ET.fromstring(raw)}


def wallet(out: Path, tag: str) -> dict:
    raw = prefs(out,tag).get('flutter.lumo_reward_wallet_v1','{}')
    return json.loads(raw)


def saves(out: Path, kind: str, tag: str) -> dict[str,dict]:
    paths = base.adb('shell','find',f'/data/user/0/{PACKAGE}',
                     '-maxdepth','8','-type','f','-name',f'lumo_{kind}_*.json').splitlines()
    result = {}
    for path in paths:
        name = Path(path).name
        if not re.fullmatch(r'lumo_'+kind+r'_p_[a-f0-9]{32}(?:_[1-6])?\.json',name):
            raise RuntimeError('Save identity is not an opaque per-profile key: '+name)
        data = json.loads(base.adb('exec-out','cat',path))
        result[name] = data
        (out/(tag+'-'+name)).write_text(json.dumps(data,indent=2))
    if not result:
        raise RuntimeError('No durable native save for '+kind)
    return result


def package_identity(out: Path, tag: str) -> dict:
    raw = base.adb('shell','dumpsys','package',PACKAGE)
    (out/(tag+'-package.txt')).write_text(raw)
    uid_output = base.adb('shell','cmd','package','list','packages','-U',PACKAGE)
    (out/(tag+'-package-uid.txt')).write_text(uid_output)
    uid = re.search(r'^package:'+re.escape(PACKAGE)+r'\s+uid:(\d+)',uid_output,re.M)
    if not uid:
        raise RuntimeError('Installed package UID missing from PackageManager')
    result = {'userId':uid.group(1)}
    for key in ('firstInstallTime','versionCode','versionName'):
        match = re.search(r'\b'+key+r'=([^\n]+)',raw)
        if not match:
            raise RuntimeError('Installed package metadata missing '+key)
        result[key] = match[1].strip()
    return result


def ime_character(out: Path, char: str, tag: str, ime_package: str) -> None:
    """Tap a freshly observed software key, including an observed Shift key."""
    shifted = False
    for attempt in range(20):
        nodes = live.live_nodes(out, f'{tag}-keyboard-{attempt}')
        keys = [n for n in nodes if n.get('package') == ime_package and
                n.get('clickable') == 'true' and n.get('enabled') == 'true']
        matches = [n for n in keys if n.get('content-desc') == char]
        action = char
        if not matches and not shifted and any(
                n.get('content-desc') == char.swapcase() for n in keys):
            matches = [n for n in keys if n.get('content-desc') == 'Shift']
            action = 'Shift'
        if len(matches) > 1:
            raise RuntimeError('Ambiguous visible IME key: '+action)
        if not matches:
            time.sleep(.5)
            continue
        bounds = list(map(int, re.findall(r'-?\d+', matches[0].get('bounds', ''))))
        if len(bounds) != 4:
            raise RuntimeError('Observed IME key has no touch bounds')
        x0,y0,x1,y1 = bounds
        if min(x0,y0) < 0 or x1 <= x0 or y1 <= y0:
            raise RuntimeError('Observed IME key is outside the display')
        record = out / 'profile-ime-taps.json'
        events = json.loads(record.read_text()) if record.exists() else []
        events.append({'requested_character':char, 'tapped_label':action,
                       'package':ime_package, 'observed_bounds':bounds})
        record.write_text(json.dumps(events, indent=2)+'\n')
        base.adb('shell','input','tap',str((x0+x1)//2),str((y0+y1)//2))
        if action == char:
            return
        shifted = True
        time.sleep(.5)
    raise RuntimeError('Visible IME key was not available: '+char)


def onboard(out: Path) -> dict:
    flutter_tap(out,"Los geht's!",'onboard-welcome')
    nodes = live.live_nodes(out,'onboard-name')
    fields = [n for n in nodes if n.get('class') == 'android.widget.EditText'
              and n.get('package') == PACKAGE]
    if len(fields) != 1:
        raise RuntimeError('One observed profile name field is required')
    # Flutter's virtual EditText does not accept Android ACTION_SET_TEXT here.
    # Use the observed field and real key input, confirming each character in
    # fresh accessibility before closing the IME on the slow Mesa emulator.
    bounds = list(map(int,re.findall(r'\d+',fields[0].get('bounds',''))))
    if len(bounds) != 4:
        raise RuntimeError('Observed profile field has no touch bounds')
    x0,y0,x1,y1 = bounds
    base.adb('shell','input','tap',str((x0+x1)//2),str((y0+y1)//2))
    time.sleep(2)
    android_sdk = int(base.adb('shell', 'getprop', 'ro.build.version.sdk'))
    ime_package = base.adb('shell', 'settings', 'get', 'secure',
                           'default_input_method').split('/', 1)[0]
    prefix = ''
    for char in 'LumoTest':
        # On API 36 the raw adb hardware-key path duplicated the first letter
        # in two recorded baseline runs. Use the actual visible software
        # keyboard and retain exact per-character/profile persistence checks.
        if android_sdk >= 36:
            ime_character(out, char, f'onboard-char-{len(prefix)+1}', ime_package)
        else:
            base.adb('shell','input','text',char)
        prefix += char
        for attempt in range(20):
            nodes = live.live_nodes(out,f'onboard-name-written-{len(prefix)}-{attempt}')
            if any(n.get('class') == 'android.widget.EditText' and
                   n.get('text') == prefix for n in nodes):
                break
            time.sleep(.5)
        else:
            raise RuntimeError('Real profile typing did not reach '+prefix)
    time.sleep(1)
    base.adb('shell','input','keyevent','KEYCODE_BACK')
    time.sleep(1)
    base.tap_label(out,'Weiter','onboard-name-next')
    base.tap_label(out,'Weiter','onboard-age-next')
    base.tap_label(out,'Profil speichern','onboard-grade-save')
    for attempt in range(20):
        if 'LumoTest' in base.accessible_text(live.live_nodes(out,f'onboard-home-{attempt}')):
            break
        time.sleep(1)
    else:
        raise RuntimeError('Saved full profile name missing from actual home UI')
    home = capture(out,'07_home_after_onboarding')
    base.tap_label(out,'Spiele','home-to-games')
    games = capture(out,'08_games_after_navigation')
    if not any(s in base.accessible_text(live.live_nodes(out,'onboard-games'))
               for s in ('Lumo Cards','Lumo Kart','Spielewelt')):
        raise RuntimeError('Actual games entry missing after onboarding')
    return {'status':'PASS','profile_name':'LumoTest','captures':[home,games]}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--baseline',type=Path)
    parser.add_argument('--candidate',type=Path)
    parser.add_argument('--ocr-fixture',type=Path)
    parser.add_argument('--ocr-label',action='append')
    parser.add_argument('--game-scope',choices=('all','build','puzzle','rhythm','treasure','kart'),default='all')
    parser.add_argument('--out',type=Path,required=True)
    args = parser.parse_args()
    out = args.out
    out.mkdir(parents=True,exist_ok=True)
    if args.ocr_fixture:
        for label in args.ocr_label or ('LUMO BAUWELT','Bauziele','Mein Bauwerk testen'):
            wanted=normalized(label)
            lines=image_lines(out,'fixture-'+wanted,wanted,args.ocr_fixture)
            matches=[line for line in lines if wanted in normalized(line['text'])]
            if not matches:
                raise RuntimeError('Actual APK screenshot OCR regression: '+label)
            print('[OCRPreflight] PASS:',label,min(matches,key=lambda line:len(line['text'])),flush=True)
        return 0
    if args.baseline is None or args.candidate is None:
        parser.error('--baseline and --candidate are required for actual Android play')
    selected=['build','puzzle','rhythm','treasure','kart'] if args.game_scope=='all' else [args.game_scope]
    result = {'tested_games':selected,'status':'RUNNING','source':SOURCE,'godot':GODOT,
              'harness':base.command('git','rev-parse','HEAD'),
              'scope':'Actual Android APK update, native scene launches, pause/back, saves and reward replay',
              'not_tested':['physical Samsung/Fold','60 FPS','reference-video pixel parity',
                            'full native treasure journey','full rhythm song with taps','full puzzle completion']}
    try:
        if digest(args.baseline) != BASE_DIGEST:
            raise RuntimeError('Baseline APK digest mismatch')
        provenance = json.loads((args.candidate.parent/'BUILD-PROVENANCE.json').read_text())
        if (provenance['flutter_source_commit'] != SOURCE or
            provenance['tracked_source_clean'] is not True or
            provenance['godot']['revision'] != GODOT or
            provenance['signingCertificateSha256'] != CERT or
            provenance['versionCode'] != EXPECTED_VERSION or
            provenance['sha256'] != digest(args.candidate)):
            raise RuntimeError('Candidate provenance mismatch')
        result['apk_sha256'] = digest(args.candidate)
        base.adb('root')
        base.adb('wait-for-device')
        result['android_sdk'] = int(base.adb('shell', 'getprop', 'ro.build.version.sdk'))
        expected_sdk = os.environ.get('LUMO_EXPECT_ANDROID_API')
        if expected_sdk and result['android_sdk'] != int(expected_sdk):
            raise RuntimeError('Emulator Android API does not match the requested test')
        base.display(1080,2400,480)
        baseline_install = base.adb('install','-r','--no-streaming',str(args.baseline),timeout=180)
        if 'Success' not in baseline_install:
            raise RuntimeError('Baseline installation failed')
        (out/'baseline-install.txt').write_text(baseline_install)
        base.launch(out,'baseline')
        result['onboarding'] = onboard(out)
        before_package = package_identity(out,'baseline')
        before_profile = prefs(out,'baseline').get('flutter.lumo_active_profile')
        if not before_profile or 'LumoTest' not in before_profile:
            raise RuntimeError('Baseline profile was not actually persisted')
        base.adb('shell','am','force-stop',PACKAGE)
        update = base.adb('install','-r','--no-streaming',str(args.candidate),timeout=180)
        (out/'update-install.txt').write_text(update)
        after_package = package_identity(out,'updated')
        if ('Success' not in update or not after_package['versionCode'].startswith(str(EXPECTED_VERSION)) or
            after_package['userId'] != before_package['userId'] or
            after_package['firstInstallTime'] != before_package['firstInstallTime']):
            raise RuntimeError('In-place update with unchanged installation identity failed')
        base.adb('shell','svc','wifi','disable')
        base.adb('shell','svc','data','disable')
        base.adb('shell','cmd','connectivity','airplane-mode','enable')
        if base.adb('shell','settings','get','global','airplane_mode_on') != '1':
            raise RuntimeError('Offline mode not confirmed')
        base.adb('logcat','-c')
        base.launch(out,'updated-offline')
        if prefs(out,'updated').get('flutter.lumo_active_profile') != before_profile:
            raise RuntimeError('Actual old profile changed during update')
        if 'LumoTest' not in base.accessible_text(live.live_nodes(out,'updated-profile')):
            raise RuntimeError('Old profile missing from updated home UI')
        capture(out,'01_updated_profile')
        flutter_tap(out,'Spielen','updated-games')
        base.display(1920,1080,240)
        capture(out,'02_updated_games_landscape')
        # Keep the emulator's natural surface portrait for sensor-landscape:
        # Android rotates 1080x1920 into the game's actual 1920x1080 surface.
        base.display(1080,1920,300)
        start_wallet = wallet(out,'before-build')
        result['update'] = {'status':'PASS','before':before_package,'after':after_package,
                            'profile_retained':True,'offline':True}

        first_wallet=start_wallet

        if 'build' in selected:
            enter(out,'Bauwelt','LUMO BAUWELT','02_build')
            native_text(out,'Bauziele','build-goals',tap=True)
            native_text(out,'Ein Zuhause bauen','build-house-goal',tap=True)
            native_text(out,'Mein Bauwerk testen','build-test-house',tap=True)
            # The durable goal-card state stays legible on dark glass; the
            # transient white toast can overlap the detailed landscape.
            # Persisted completion and exact wallet deltas are checked below.
            native_text(out,'Schon geschafft','build-house-passed')
            capture(out,'03_build_house_passed')
            leave(out,'build-exit')
            stored_build = saves(out,'build','build-saved')
            if not any('house' in data.get('completed',[]) for data in stored_build.values()):
                raise RuntimeError('Completed house was not in the persisted build state')
            first_wallet = wallet(out,'after-build')
            if (first_wallet.get('stars',0)-start_wallet.get('stars',0) != 3 or
                first_wallet.get('xp',0)-start_wallet.get('xp',0) != 24):
                raise RuntimeError('Completed native build reward was not exactly 3 stars / 24 XP')
            enter(out,'Bauwelt','LUMO BAUWELT','04_build_resume')
            native_text(out,'Schon geschafft','build-resumed-goal')
            native_text(out,'Mein Bauwerk testen','build-repeat-test',tap=True)
            leave(out,'build-repeat-exit')
            if wallet(out,'after-build-replay') != first_wallet:
                raise RuntimeError('Replaying the saved build goal duplicated a reward')
            result['build'] = {'status':'PASS','reward_stars':3,'reward_xp':24,
                                'save_and_relaunch':True,'replay_deduplicated':True}

        if 'puzzle' in selected:
            enter(out,'Puzzle-Atelier','LUMOS PUZZLE','05_puzzle')
            native_text(out,'Neues Puzzle beginnen','puzzle-start',tap=True)
            native_text(out,'Ein Tipp','puzzle-hint',tap=True)
            capture(out,'06_puzzle_playing')
            leave(out,'puzzle-exit')
            stored_puzzle = saves(out,'puzzle','puzzle-saved')
            original = next(iter(stored_puzzle.values()))
            if original.get('count') != 12 or original.get('hints') != 1:
                raise RuntimeError('Real puzzle choice or hint was not saved')
            enter(out,'Puzzle-Atelier','LUMOS PUZZLE','07_puzzle_resume')
            native_text(out,'Gespeichertes Puzzle fortsetzen','puzzle-continue',tap=True)
            leave(out,'puzzle-resumed-exit')
            restored = next(iter(saves(out,'puzzle','puzzle-resumed').values()))
            if any(restored.get(key) != original.get(key)
                   for key in ('count','motif','result_id','hints','pieces')):
                raise RuntimeError('Puzzle resumed a different stored state')
            result['puzzle'] = {'status':'PASS','parts':12,'hints':1,'save_and_relaunch':True}

        if 'rhythm' in selected:
            enter(out,'Rhythm Party','LUMO STERNENRHYTHMUS','08_rhythm')
            native_text(out,'Los geht','rhythm-start',tap=True)
            time.sleep(7)
            capture(out,'09_rhythm_notes')
            leave(out,'rhythm-exit')
            result['rhythm'] = {'status':'PASS','actual_song_started':True,'pause_return':True}

        if 'treasure' in selected:
            enter(out,'Schatzsuche','LUMOS STERNENSCHATZ','10_treasure')
            native_text(out,'Rucksack','treasure-inventory',tap=True)
            native_text(out,'Dein Abenteuer','treasure-inventory-visible')
            capture(out,'11_treasure_inventory')
            native_text(out,'Weiter erkunden','treasure-inventory-close',tap=True)
            leave(out,'treasure-exit')
            treasure = next(iter(saves(out,'treasure','treasure-saved').values()))
            enter(out,'Schatzsuche','LUMOS STERNENSCHATZ','12_treasure_resume')
            leave(out,'treasure-resumed-exit')
            resumed = next(iter(saves(out,'treasure','treasure-resumed').values()))
            if any(resumed.get(key) != treasure.get(key) for key in ('chapter','result_id')):
                raise RuntimeError('Treasure chapter or identity changed on relaunch')
            result['treasure'] = {'status':'PASS','inventory_visible':True,'save_and_relaunch':True}

        if 'kart' in selected:
            enter(out,'Lumo Kart','LUMO / KART','14_kart',launch_label='Losfahren')
            for step in range(4):
                native_text(out,'Weiter',f'kart-setup-{step+1}',tap=True)
            native_text(out,'Rennen starten','kart-start-race',tap=True)
            # Read all five controls on the actual 1920x1080 phone surface.
            # The tiny 640x320 surface is captured separately below: text OCR
            # is not a dependable visibility assertion for its small icons.
            for label in ('GAS','BREMSE','DRIFT','BOOST','ITEM'):
                native_text(out,label,'kart-phone-'+normalized(label))
            phone=capture(out,'15_kart_phone_race')
            if phone['width'] != 1920 or phone['height'] != 1080:
                raise RuntimeError('Native Kart did not use the 1920x1080 phone surface')
            if os.environ.get('LUMO_FOLD_PROBE') == '1':
                base.display(1812,2176,420)
                # Android 16 ignores sensorLandscape for non-game applications
                # on sw600dp displays. Resizing is not a physical device turn.
                # Turn the emulator explicitly, then keep all strict screenshot
                # size and actual control-visibility assertions below.
                device_rotation(out, 'kart-fold-landscape', 1)
                for label in ('GAS','BREMSE','DRIFT','BOOST','ITEM'):
                    native_text(out,label,'kart-fold-'+normalized(label))
                fold = capture(out,'17_kart_fold_open')
                if fold['width'] != 2176 or fold['height'] != 1812:
                    raise RuntimeError('Inner-display surface did not rotate to 2176x1812')
                base.display(904,2316,420)
                for label in ('GAS','BREMSE','DRIFT','BOOST','ITEM'):
                    native_text(out,label,'kart-cover-'+normalized(label))
                capture(out,'18_kart_fold_cover')
                base.display(1080,1920,300)
                native_text(out,'GAS','kart-phone-again')
                result['fold_resize'] = {'status':'PASS', 'inner_surface':[2176,1812],
                                         'five_action_labels_visible':True,
                                         'cover_resize_and_return':True,
                                         'explicit_device_rotation':True,
                                         'scope':'Android emulator surfaces; no physical hinge/FPS claim'}
            base.display(320,640,160)
            native_text(out,'Pause','kart-compact-hud')
            compact=capture(out,'19_kart_compact_race')
            if compact['width'] != 640 or compact['height'] != 320:
                raise RuntimeError('Compact native Kart did not rotate to 640x320')
            base.display(1080,1920,300)
            native_text(out,'GAS','kart-phone-restored')
            base.adb('shell','input','keyevent','KEYCODE_BACK')
            native_text(out,'Spiele','kart-compact-return',tap=True)
            for _ in range(30):
                if not base.adb('shell','pidof',PACKAGE+':lumo_game',check=False):
                    break
                time.sleep(1)
            else:
                raise RuntimeError('Kart private process remained after return')
            base.foreground()
            capture(out,'16_kart_returned_to_app')
            result['kart']={'status':'PASS','actual_setup_steps':5,
                            'phone_surface':[1920,1080], 'compact_surface':[640,320],
                            'five_action_labels_on_phone':True,
                            'compact_hud_and_capture':True,'pause_return':True}
        if wallet(out,'after-unfinished-games') != first_wallet:
            raise RuntimeError('An unfinished creative game incorrectly awarded a reward')

        base.adb('shell','am','force-stop',PACKAGE)
        device_rotation(out, 'final-phone-upright', 0)
        base.display(1080,2400,480)
        base.launch(out,'final-restart')
        if prefs(out,'final').get('flutter.lumo_active_profile') != before_profile:
            raise RuntimeError('Profile missing after native games and full app restart')
        if wallet(out,'final-wallet') != first_wallet:
            raise RuntimeError('Native rewards changed after a full app restart')
        capture(out,'13_final_phone_restart')
        crashes = base.adb('logcat','-d','-b','crash',check=False)
        (out/'crash-buffer.txt').write_text(crashes)
        if PACKAGE in crashes:
            raise RuntimeError('App or its native game process appears in crash buffer')
        result['status'] = 'PASS'
        print('[CreativeAndroid] PASS: in-place update, profile, selected native game, save/reward guards; scope='+args.game_scope,flush=True)
        return 0
    except Exception as error:
        result.update(status='FAIL',error=str(error),traceback=traceback.format_exc())
        try:
            capture(out,'failure')
        except Exception:
            pass
        print('[CreativeAndroid] FAIL:',error,flush=True)
        return 1
    finally:
        (out/'result.json').write_text(json.dumps(result,indent=2,ensure_ascii=False)+'\n')
        (out/'logcat.txt').write_text(base.adb('logcat','-d',check=False))


if __name__ == '__main__':
    raise SystemExit(main())
