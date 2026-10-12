#!/usr/bin/env python3
import argparse
from pathlib import Path
import subprocess
import sys
import json
import os

parser=argparse.ArgumentParser()
parser.add_argument('--baseline',required=True)
parser.add_argument('--candidate',required=True)
parser.add_argument('--out',required=True)
parser.add_argument('--reuse-education-proof', action='store_true')
a=parser.parse_args()
folder=Path(__file__).resolve().parent
if a.reuse_education_proof:
    import lumo_free_voice_android_probe as voice
    import lumo_education_android_probe as education
    existing = voice.existing
    out = Path(a.out)
    prior = json.loads((out/'education-android-result.json').read_text())
    candidate = voice.delivery(Path(a.candidate), voice.CANDIDATE_VERSION,
                              os.environ['LUMO_EXPECT_SOURCE'])
    assert prior['status']=='PASS'
    assert prior['candidate_source']==candidate['flutter_source_commit']
    assert prior['candidate_apk_sha256']==candidate['sha256']
    assert prior['voice_update_kart']['candidate']['godot']['revision']==candidate['godot']['revision']
    # Retain the failed game's genuine result; never turn that attempt green.
    old = out/'games-android-result.json'
    assert json.loads(old.read_text())['status']=='FAIL'
    old.rename(out/'games-FIRST-FAILED-result.json')
    seed = out/'actual-games-learning-seed'
    seed.mkdir(exist_ok=True)
    existing.ensure_rooted_emulator(existing.base.adb, seed)
    assert int(existing.base.adb('shell','getprop','ro.build.version.sdk'))==36
    installed = existing.base.adb('install','-r','--no-streaming',a.candidate,timeout=240)
    assert 'Success' in installed
    existing.base.adb('shell','svc','wifi','disable')
    existing.base.adb('shell','svc','data','disable')
    existing.base.adb('shell','cmd','connectivity','airplane-mode','enable')
    existing.base.display(1080,2400,480)
    existing.base.launch(seed,'fresh-exact-1934-game-fixture')
    existing.onboard(seed)
    existing.base.display(1200,896,160)
    # Populate learning progress through an actual complete course, not injected prefs.
    course = education.language_nature_course(seed,plant=True)
    assert course['status']=='PASS' and course['actual_attempts_added']==3
    (out/'games-actual-learning-seed.json').write_text(json.dumps(course,indent=2)+'\n')
    existing.base.adb('shell','am','force-stop',existing.PACKAGE)
    existing.base.launch(seed,'actual-learning-before-games-restart')
    (out/'REUSED-VERIFIED-EDUCATION.json').write_text(json.dumps({
        'prior_run':38210068691,'same_apk_sha256':candidate['sha256'],
        'same_source':candidate['flutter_source_commit'],
        'scope':'Prior real update/voice/five-course PASS retained; only failed games rerun. Fresh game fixture has actual saved course progress, no save injection.'},indent=2)+'\n')
else:
    subprocess.run([sys.executable,str(folder/'lumo_education_android_probe.py'),
        '--baseline',a.baseline,'--candidate',a.candidate,'--out',a.out],check=True)
subprocess.run([sys.executable,str(folder/'lumo_games_android_probe.py'),
    '--out',a.out],check=True)
