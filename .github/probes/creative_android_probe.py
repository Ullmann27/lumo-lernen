#!/usr/bin/env python3
"""Exercise the digest-pinned creative-games APK and a real 1400 -> 1500 update.

Only fictional data in a disposable Android emulator is used. Flutter controls
come from live accessibility; native Godot controls from current screenshot OCR.
No game completion, score, unlock, XML or touch target is injected into the app.
"""
from __future__ import annotations

import argparse
import csv
import hashlib
import json
from pathlib import Path
import re
import sys
import time
import traceback
import unicodedata
import xml.etree.ElementTree as ET

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / 'scripts' / 'probes'))
import pr207_android_smoke as base
import pr207_android_ui_probe as live

PACKAGE = base.PACKAGE
BASE_DIGEST = 'd33b9f5f04a013bc1bcafb579758d109f511ff69e9c08bc95b68c34d9b1c6e7e'
SOURCE = '760a3afa7b0cac0d762693af37397c5516960b0e'
GODOT = '9136662953a42cd60cfe3cdf05fbd6497b13bfb1'
CERT = 'a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702'
base.ui_nodes = live.live_nodes
base.tap_label = live.live_tap_label


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


def flutter_tap(out: Path, label: str, tag: str) -> None:
    # Search both ends of the actual responsive scroll view. Named controls are
    # tapped only when their enabled live accessibility bounds have been read.
    for direction in (-1, 1):
        for attempt in range(12):
            nodes = live.live_nodes(out, f'{tag}-{direction}-{attempt}')
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
                base.adb('shell', 'input', 'tap', str((x0+x1)//2), str((y0+y1)//2))
                time.sleep(2)
                return
            width, height = live._device.window_size()
            y0, y1 = ((height*.28, height*.82) if direction == -1
                      else (height*.82, height*.28))
            base.adb('shell', 'input', 'swipe', str(width//2), str(int(y0)),
                     str(width//2), str(int(y1)), '300')
            time.sleep(.4)
    capture(out, tag+'-missing')
    raise RuntimeError('No enabled live Flutter control: '+label)


def image_lines(out: Path, tag: str) -> list[dict]:
    snapshot = capture(out, tag)
    source = out / snapshot['file']
    image = Image.open(source).convert('RGB')
    expanded = out / (tag+'-ocr-input.png')
    image.resize((image.width*2, image.height*2)).save(expanded)
    prefix = out / (tag+'-ocr')
    base.command('tesseract', str(expanded), str(prefix), '--psm', '11',
                 '-l', 'deu+eng', 'tsv', timeout=45)
    groups: dict[tuple, list[dict]] = {}
    with prefix.with_suffix('.tsv').open() as stream:
        for word in csv.DictReader(stream, delimiter='\t'):
            if not word.get('text', '').strip() or float(word['conf']) < 15:
                continue
            key = tuple(word[k] for k in ('page_num','block_num','par_num','line_num'))
            groups.setdefault(key, []).append(word)
    result = []
    for words in groups.values():
        words.sort(key=lambda w: int(w['left']))
        x0 = min(int(w['left']) for w in words)/2
        y0 = min(int(w['top']) for w in words)/2
        x1 = max(int(w['left'])+int(w['width']) for w in words)/2
        y1 = max(int(w['top'])+int(w['height']) for w in words)/2
        result.append({'text': ' '.join(w['text'] for w in words),
                       'bounds': [x0,y0,x1,y1]})
    prefix.with_suffix('.json').write_text(json.dumps(result, indent=2, ensure_ascii=False))
    return result


def native_text(out: Path, label: str, tag: str, tap: bool = False) -> None:
    wanted = normalized(label)
    for attempt in range(8):
        lines = image_lines(out, f'{tag}-{attempt}')
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


def enter(out: Path, title: str, header: str, tag: str) -> None:
    flutter_tap(out, title+' spielen', tag+'-launch')
    for _ in range(15):
        if 'LumoGameActivity' in base.foreground():
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


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--baseline',type=Path,required=True)
    parser.add_argument('--candidate',type=Path,required=True)
    parser.add_argument('--out',type=Path,required=True)
    args = parser.parse_args()
    out = args.out
    out.mkdir(parents=True,exist_ok=True)
    result = {'status':'RUNNING','source':SOURCE,'godot':GODOT,
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
            provenance['versionCode'] != 1500 or
            provenance['sha256'] != digest(args.candidate)):
            raise RuntimeError('Candidate provenance mismatch')
        result['apk_sha256'] = digest(args.candidate)
        base.adb('root')
        base.adb('wait-for-device')
        base.display(1080,2400,480)
        baseline_install = base.adb('install','-r','--no-streaming',str(args.baseline),timeout=180)
        if 'Success' not in baseline_install:
            raise RuntimeError('Baseline installation failed')
        (out/'baseline-install.txt').write_text(baseline_install)
        base.launch(out,'baseline')
        result['onboarding'] = base.onboard(out)
        before_package = package_identity(out,'baseline')
        before_profile = prefs(out,'baseline').get('flutter.lumo_active_profile')
        if not before_profile or 'LumoTest' not in before_profile:
            raise RuntimeError('Baseline profile was not actually persisted')
        base.adb('shell','am','force-stop',PACKAGE)
        update = base.adb('install','-r','--no-streaming',str(args.candidate),timeout=180)
        (out/'update-install.txt').write_text(update)
        after_package = package_identity(out,'updated')
        if ('Success' not in update or not after_package['versionCode'].startswith('1500') or
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
        start_wallet = wallet(out,'before-build')
        result['update'] = {'status':'PASS','before':before_package,'after':after_package,
                            'profile_retained':True,'offline':True}

        enter(out,'Bauwelt','LUMO BAUWELT','02_build')
        native_text(out,'Bauziele','build-goals',tap=True)
        native_text(out,'Ein Zuhause bauen','build-house-goal',tap=True)
        native_text(out,'Mein Bauwerk testen','build-test-house',tap=True)
        native_text(out,'Bauziel geschafft','build-house-passed')
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

        enter(out,'Rhythm Party','LUMO STERNENRHYTHMUS','08_rhythm')
        native_text(out,'Los geht','rhythm-start',tap=True)
        time.sleep(7)
        capture(out,'09_rhythm_notes')
        leave(out,'rhythm-exit')
        result['rhythm'] = {'status':'PASS','actual_song_started':True,'pause_return':True}

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
        if wallet(out,'after-unfinished-games') != first_wallet:
            raise RuntimeError('An unfinished creative game incorrectly awarded a reward')

        base.adb('shell','am','force-stop',PACKAGE)
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
        print('[CreativeAndroid] PASS: in-place update, profile, four native games, save recovery, reward replay',flush=True)
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
