#!/usr/bin/env python3
"""Package only the exact 1937 ARM64 APK with matching actual Android proof."""
import argparse
import hashlib
import json
from pathlib import Path
import zipfile


def digest(p):
    with p.open('rb') as stream:
        return hashlib.file_digest(stream,'sha256').hexdigest()


def main():
    a=argparse.ArgumentParser()
    a.add_argument('--arm64',type=Path,required=True)
    a.add_argument('--runtime',type=Path,required=True)
    a.add_argument('--artifact-id',type=int,required=True)
    a.add_argument('--qa-run',type=int,required=True)
    a.add_argument('--out',type=Path,required=True)
    args=a.parse_args()
    prov=json.loads((args.arm64/'BUILD-PROVENANCE.json').read_text())
    proof=json.loads((args.runtime/'APK-AND-SCREENSHOT-PROOF.json').read_text())
    apk=args.arm64/'Lumo-Lernen-Neu.apk'
    assert prov['versionCode']==1937 and prov['versionName']=='0.12.30' and prov['abis']==['arm64-v8a']
    assert prov['tracked_source_clean'] is True
    assert proof['status']=='PASS' and proof['education']['status']=='PASS' and proof['race']['status']=='PASS'
    assert proof['flutter_commit']==prov['flutter_source_commit'] and proof['godot_commit']==prov['godot']['revision']
    assert proof['arm64_apk_sha256']==prov['sha256']==digest(apk)
    assert prov['package']=='dev.ullmann.lumo.lumo_lernen.coachpreview'
    assert prov['signingCertificateSha256']=='a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702'
    assert {s['role'] for s in proof['screenshots']}=={'learning_phone','learning_fold','games_overview','kart_menu','kart_race','additional_learning'}
    with zipfile.ZipFile(apk) as z:
        assert z.testzip() is None
        assert any(n.startswith('lib/arm64-v8a/') for n in z.namelist())
        assert any(n.endswith('.pck') for n in z.namelist()),'Missing actual embedded Godot runtime'
    build=proof['build_run']
    meta={'version':'0.12.30+1937','flutter_commit':proof['flutter_commit'],'godot_commit':proof['godot_commit'],
          'unified_build_run':build,'unified_build_url':f'https://github.com/Ullmann27/lumo-lernen/actions/runs/{build}',
          'arm64_artifact_id':args.artifact_id,'arm64_artifact_url':f'https://github.com/Ullmann27/lumo-lernen/actions/runs/{build}/artifacts/{args.artifact_id}',
          'android_qa_run':args.qa_run,'android_qa_url':f'https://github.com/Ullmann27/lumo-lernen/actions/runs/{args.qa_run}',
          'arm64_apk_sha256':digest(apk),'status':'tested-development-version','public_release':False}
    files={'Lumo-Lernen-0.12.30-1937-ARM64.apk':apk,'BUILD-PROVENANCE.json':args.arm64/'BUILD-PROVENANCE.json',
           'APK-VERIFICATION.json':args.arm64/'APK-VERIFICATION.json','APK-AND-SCREENSHOT-PROOF.json':args.runtime/'APK-AND-SCREENSHOT-PROOF.json',
           'education-android-result.json':args.runtime/'education-android-result.json','kart-complete-race-result.json':args.runtime/'complete-race/result.json'}
    for shot in proof['screenshots']:
        p=args.runtime/shot['file']
        assert p.resolve().is_relative_to(args.runtime.resolve()) and digest(p)==shot['sha256']
        assert shot['flutter_commit']==meta['flutter_commit'] and shot['godot_commit']==meta['godot_commit']
        assert shot['build_run']==build and shot['installed_apk_sha256']==proof['emulator_apk_sha256']
        files['Screenshots/'+shot['role']+'.png']=p
    args.out.parent.mkdir(parents=True,exist_ok=True)
    assert not args.out.exists(),'Refuse to overwrite an existing delivery'
    instructions=f'''Lumo Lernen1937 – Android-Testversion0.12.30+1937

1. ZIP vollständig herunterladen und entpacken.
2. Lumo-Lernen-0.12.30-1937-ARM64.apk auf einem Android-Gerät mit ARM64 öffnen.
3. Falls nötig, Installation aus dieser Download-/Dateien-App erlauben.
4. Als Update installieren. Die bestehende App nicht deinstallieren; dabei könnten lokale Daten verloren gehen.

Paketkennung und kompatible Signatur bleiben erhalten. Ist auf deinem Gerät eine anders signierte App installiert, wird Android ein Update ablehnen. Vor Änderungen dann den tatsächlichen Paket-/Signaturstand klären.

Dies ist eine geprüfte Entwicklungs-Testversion, keine endgültige Store-Freigabe.
Version:0.12.30+1937
Flutter:{meta['flutter_commit']}
Godot:{meta['godot_commit']}
APK-SHA256:{meta['arm64_apk_sha256']}
Unified-Build:{meta['unified_build_url']}
ARM64-Artefakt:{meta['arm64_artifact_url']}
Android-Abnahme:{meta['android_qa_url']}
'''
    report='''Prüfbericht1937

Nachgewiesen: erfolgreicher Unified-Bau aus den angegebenen Flutter-/Godot-Commits; vollständige Flutter-Tests; relevante Godot-Regressionen; echtes1936→1937Update mit gleicher Installationsidentität; lokale Stimme mit technischen Wiedergabe-/Pause-/Fortsetzen-/Stoppbestätigungen; fünf vollständig bediente Lern-/Entdeckungskurse; Speicherung/Neustart; echtes Kart-Rennen mit Ergebnis/Host-Bestätigung und Schutz vor doppelter Belohnung.

Alle sechs Pflichtbilder stammen aus der tatsächlichen Android16-x86_64-APK desselben Unified-Buildruns wie die ARM64-Datei. Die SHA256 jedes Bilds und der Emulator-APK steht im Screenshot-Nachweis. Kein Konzeptbild, kein älterer APK-Stand. Smartphone/Fold sind echte Emulator-Runtime-Aufnahmen mit entsprechenden Displaygrößen, keine Prüfung auf einem physischen SamsungFold.

Lernvielfalt:78.800 synthetische Aufgaben vor/nach Änderung geprüft;48Lesetexte mit96Verständnisfragen,84zusätzliche Sachunterrichtsfragen. Automatische Inhaltsprüfung ist keine menschliche pädagogische Abnahme. Vollständige Lehrplanabdeckung ist weiterhin offen.

Nicht nachgewiesen: menschliche Sprachqualitätsabnahme, physische ARM64-/Fold-Hardware, sämtliche Fahrzeuge/Strecken, flächendeckende60FPS, vollständiger GooglePlay-/Lizenz-/Datenschutzrelease. CPU-/Speichermessungen im Rennbericht beziehen sich auf den Emulator. Keine öffentliche Veröffentlichung oder kostenpflichtige Sprachaufrufe.
'''
    sums=''.join(f'{digest(p)}  {name}\n' for name,p in files.items())
    with zipfile.ZipFile(args.out,'x',compression=zipfile.ZIP_STORED,allowZip64=True) as z:
        for name,p in files.items():z.write(p,name)
        z.writestr('INSTALLATION-DE.txt',instructions)
        z.writestr('TESTBERICHT-DE.txt',report)
        z.writestr('DELIVERY.json',json.dumps(meta,ensure_ascii=False,indent=2)+'\n')
        z.writestr('SHA256SUMS.txt',sums)
    with zipfile.ZipFile(args.out) as z:
        assert z.testzip() is None
        assert not any(x.endswith('.zip') for x in z.namelist())
        for name,p in files.items():
            with z.open(name) as stream:assert hashlib.file_digest(stream,'sha256').hexdigest()==digest(p)
        assert len(z.read('Screenshots/kart_race.png'))>100000
    verified={**meta,'zip':str(args.out),'zip_bytes':args.out.stat().st_size,'zip_sha256':digest(args.out),'zip_opened_and_crc_checked':True,'all_members_sha256_checked':True}
    args.out.with_suffix('.verified.json').write_text(json.dumps(verified,indent=2)+'\n')
    print(json.dumps(verified,indent=2))

if __name__=='__main__':main()
