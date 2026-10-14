#!/usr/bin/env python3
"""Package immutable 1939 bytes only after matching visual/update acceptance.

This limited graphical test build is not a complete curriculum, physical-device,
full-race, audible-voice or store-release certification.
"""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import zipfile

FLUTTER = 'dcc70f583f7362141811365b41dc45bf110b4e1e'
GODOT = 'd8d004141cdd606357aa1348691a39854e3af3c7'
ARM64 = 'c108c61c7d0000155ac41438ef1ad85b4e8cff44fdb01204734459390e979fc7'
X86 = '31187cd832371c6dac37eea318c19528edb69ee19474e46b98845bdb92b80415'
CERT = 'a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702'
ROLES = ['01-home-phone', '02-more-phone', '03-parents-phone', '04-learning-phone',
         '05-learning-fold', '06-home-fold', '07-library-fold', '08-games-fold',
         '09-kart-menu', '10-kart-running-race', '11-restart-phone']


def read(p):
    return json.loads(p.read_text())


def digest(p):
    with p.open('rb') as f:
        return hashlib.file_digest(f, 'sha256').hexdigest()


def require(condition, message):
    if not condition:
        raise ValueError(message)


def package(root, out):
    arm, android, proof = root/'arm64', root/'android', root/'build'
    p, r = read(arm/'BUILD-PROVENANCE.json'), read(android/'RESULT.json')
    require(r['status'] == 'PASS', 'Actual Android acceptance failed; no verified bundle')
    require(p['flutter_source_commit'] == FLUTTER and p['godot']['revision'] == GODOT,
            'Wrong product sources')
    require(p['versionCode'] == 1939 and p['versionName'] == '0.12.32' and p['abis'] == ['arm64-v8a'], 'Wrong version/ABI')
    require(p['tracked_source_clean'] is True and p['signingCertificateSha256'] == CERT, 'Wrong source/signature provenance')
    require(p['sha256'] == ARM64 == digest(arm/'Lumo-Lernen-Neu.apk'), 'Actual APK digest mismatch')
    candidate = r['candidate']
    require(candidate['flutter_source_commit'] == FLUTTER and candidate['godot'] == p['godot']
            and candidate['sha256'] == X86 and candidate['signingCertificateSha256'] == CERT,
            'Emulator evidence does not match this unified source/PCK/signature')
    require(r['update_preserved']['profile_and_progress'] is True and r['update_preserved']['wallet'] is True,
            'Update preservation missing')
    motion = r['actual_race_motion']
    require(motion['countdown'] <= 0 and motion['speed'] > 0 and motion['distance'] > 5,
            'No actually moving race')
    qa, build = read(root/'android-run.json'), read(root/'build-jobs.json')
    require(qa['status'] == 'completed' and qa['conclusion'] == 'success', 'Android Actions run not green')
    require(any(j['name'] == 'verify-build' and j['conclusion'] == 'success' for j in build['jobs']),
            'Unified build job not successful')
    log = (proof/'flutter-test.log').read_text()
    require('+1485 ~117: All tests passed!' in log, 'Expected full Flutter run not confirmed')
    shots = {s['file']: s for s in r['screenshots']}
    for role in ROLES:
        s = shots[role+'.png']
        require(s['flutter_commit'] == FLUTTER and s['godot_commit'] == GODOT and s['candidate_sha256'] == X86,
                'Screenshot sources mismatch: '+role)
        require(digest(android/s['file']) == s['sha256'], 'Screenshot bytes mismatch: '+role)
    with zipfile.ZipFile(arm/'Lumo-Lernen-Neu.apk') as z:
        require(z.testzip() is None, 'APK integrity error')
        g = read(arm/'BUILD-PROVENANCE.json')['godot']
        require(json.loads(z.read('assets/lumo_game_source.json')) == g, 'Embedded Godot source mismatch')
        require(hashlib.sha256(z.read('assets/lumo_game.pck')).hexdigest() == g['pck_sha256'], 'Embedded PCK mismatch')
    require(not out.exists(), 'Refusing to mix an existing delivery directory')
    out.mkdir(parents=True)
    for name in ('Lumo-Lernen-Neu.apk', 'BUILD-PROVENANCE.json', 'APK-VERIFICATION.json', 'SHA256SUMS.txt'):
        shutil.copy2(arm/name, out/name)
    (out/'Android-Aufnahmen').mkdir()
    for role in ROLES:
        shutil.copy2(android/(role+'.png'), out/'Android-Aufnahmen'/(role+'.png'))
    shutil.copy2(android/'RESULT.json', out/'ANDROID-PRUEFBERICHT.json')
    shutil.copytree(proof/'screenshots', out/'Flutter-Testbilder')
    shutil.copytree(Path(__file__).resolve().parents[1]/'docs/development/1939/before', out/'Vorher-Nachher')
    shutil.copy2(proof/'flutter-test.log', out/'FLUTTER-TESTS.log')
    (out/'INSTALLATION.txt').write_text('''Lumo Lernen 0.12.32+1939 — grafisch erneuerte Android-Testversion

1. Dieses GitHub-Actions-ZIP vollständig herunterladen und in „Eigene Dateien“ entpacken.
2. Lumo-Lernen-Neu.apk öffnen. Bei Bedarf dieser Dateiverwaltung die Installation erlauben.
3. Eine vorhandene kompatibel signierte Lumo-Testversion aktualisieren, NICHT vorher deinstallieren.
   Deinstallation löscht lokale Profile/Lernstände. Bei Signaturkonflikt abbrechen.
4. Nach der Installation die vorübergehende Installationsfreigabe wieder ausschalten.

ARM64, Android 7 oder neuer. Paket: dev.ullmann.lumo.lumo_lernen.coachpreview.
Keine öffentliche Releasefreigabe. Noch keine Prüfung auf einem physischen Fold.
GitHub-Anmeldung kann für den Download erforderlich sein. Artefakt-Aufbewahrung: 30 Tage.
''')
    (out/'TESTBERICHT.txt').write_text(f'''Version: 0.12.32+1939
Flutter: {FLUTTER}
Godot: {GODOT}
ARM64 SHA256: {ARM64}
Build: https://github.com/Ullmann27/lumo-lernen/actions/runs/38493854824
Buildjob: https://github.com/Ullmann27/lumo-lernen/actions/runs/38493854824/job/115625031231
Android-Nachtest: {qa['html_url']}
Godot: https://github.com/Ullmann27/lumo-godot/actions/runs/38492503611

1.485 Flutter-Tests bestanden, 117 übersprungen. Godot Stage2 erfolgreich.
ARM64 und x86_64 wurden zusammen mit identischen Flutter-/Godot-Quellen gebaut.
Der ursprüngliche Gesamtworkflow war wegen Fehlern im Android-Prüfhelfer rot.
Der separate Nachtest verwendet unveränderte APK-Bytes und ist erfolgreich.
Update 1937→1939, Profile/Lernstände/Sterne, Mehr-Menü, Elternbereich,
Smartphone-/Fold-Zielgrößen, Bibliothek, Spiele, Kart-Menü, reales fahrendes Kart,
Rückkehr und App-Neustart geprüft. Android-Bilder stammen aus der echten
x86_64-APK im Emulator; dies ist keine physische ARM64-/Fold-Hardwareprüfung.
Flutter-Testbilder verwenden fiktive Geschichten, Android-Aufnahmen zeigen
das tatsächliche leere Bibliotheksprofil des Update-Prüflaufs.

Neu: Original-Lumo-Startszene, Hologlas-Karten, Sternenbibliothek und Lesefenster;
drei echte Blender/GLB-Wellenpavillons mit PBR, LOD und Collidern in Sonnenhafen.
Keine neuen kostenpflichtigen Dienste, kein Mikrofonstart, kein main-Merge.

Offen: physisches Fold, ARM64-Geräteinstallation, vollständiges Zwei-Runden-Rennen,
mobile FPS-/Speicherabnahme, menschliche Sprachqualitätsprüfung; keine vollständige
vierjährige Lehrplanabnahme. Diese Runde prüft die grafische Integration und
Navigation, nicht erneut jeden Unterrichtsablauf. Vorhandene Stimme nicht ersetzt.
''')
    manifest = {str(f.relative_to(out)): digest(f) for f in sorted(out.rglob('*')) if f.is_file()}
    (out/'DATEI-PRUEFSUMMEN.json').write_text(json.dumps(manifest, indent=2)+'\n')
    print(json.dumps({'status': 'VERIFIED_TEST_BUNDLE', 'apk_sha256': ARM64, 'files': len(manifest)}))


if __name__ == '__main__':
    p = argparse.ArgumentParser()
    p.add_argument('--root', type=Path, required=True)
    p.add_argument('--out', type=Path, required=True)
    args = p.parse_args()
    package(args.root, args.out)
