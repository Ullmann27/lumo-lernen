#!/usr/bin/env python3
"""Package an actually tested ARM64 APK, not a release/physical-device claim."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re
import zipfile

CERTIFICATE = "a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702"
GODOT = "853175c634dcb62c325fbd9b272e2ebc791830ad"


def digest(path: Path) -> str:
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def validate(provenance: dict, android: dict, outcomes: dict, run: dict, log: str,
             *, version_code: int = 1930, version_name: str = "0.12.23",
             godot_revision: str = GODOT) -> dict:
    source = provenance["flutter_source_commit"]
    if (not re.fullmatch(r"[a-f0-9]{40}", source)
            or provenance["versionCode"] != version_code or provenance["versionName"] != version_name
            or provenance["package"] != "dev.ullmann.lumo.lumo_lernen.coachpreview"
            or provenance["abis"] != ["arm64-v8a"]
            or provenance["tracked_source_clean"] is not True
            or provenance["signingCertificateSha256"] != CERTIFICATE
            or not re.fullmatch(r"[a-f0-9]{40}", godot_revision)
            or provenance["godot"]["revision"] != godot_revision
            or provenance["elf16KiBAligned"] is not True
            or provenance["resourcesArscAligned"] is not True):
        raise ValueError("ARM64 APK does not match the declared integrated test delivery")
    if (android.get("status") != "PASS" or android.get("candidate_source") != source
            or android.get("voice_update_kart", {}).get("status") != "PASS"
            or android.get("school_course", {}).get("status") != "PASS"
            or android.get("discovery_course", {}).get("status") != "PASS"
            or android.get("restart_school_discovery_wallet") != "PASS"):
        raise ValueError("Actual complete Android acceptance of this APK source is required")
    if version_code >= 1931 and android.get("subtraction_course", {}).get("status") != "PASS":
        raise ValueError("Complete real Android subtraction course acceptance is required")
    if version_code >= 1932:
        help_result = android.get("subtraction_course", {}).get("active_help", {})
        if (help_result.get("status") != "PASS"
                or help_result.get("real_wrong_taps") != 2
                or help_result.get("no_hint_before_acceptance") is not True
                or help_result.get("actual_accept_button_tapped") is not True):
            raise ValueError("Actual accepted task-bound active help is required")
    if version_code >= 1933:
        for name, subject, unit in [('syllables_course', 'Deutsch', 'Silben'),
                                    ('plant_parts_course', 'Sachunterricht', 'Pflanzen')]:
            course = android.get(name, {})
            record = course.get('school_record', {})
            if (course.get('status') != 'PASS'
                    or any(course.get(key) is not True for key in (
                        'complete_eight_step_course', 'actual_wrong_tap',
                        'different_child_requested_help',
                        'correct_answer_feedback_enabled_continue_in_same_frame',
                        'existing_skills_preserved', 'other_profiles_unchanged',
                        'discovery_unchanged', 'wallet_unchanged'))
                    or course.get('daily_correct_delta') != 2
                    or course.get('actual_attempts_added') != 3
                    or record.get('skillId') != subject.lower() + '::' + unit.lower()
                    or record.get('subject') != subject or record.get('unit') != unit
                    or record.get('correct') != 2 or record.get('wrong') != 1
                    or record.get('hintCount') != 1):
                raise ValueError('Complete real Android pilot and exact subject-specific storage required: ' + name)
    if (outcomes.get("SOURCE_SHA") != source
            or any(outcomes.get(key) != "success" for key in
                   ("DEPENDENCIES", "ANALYSIS", "TESTS"))
            or run.get("head_sha") != source or run.get("status") != "completed"
            or run.get("conclusion") != "success"):
        raise ValueError("Successful complete Flutter CI of this exact source is required")
    count = re.search(r"\+(\d+)\s+~(\d+): All tests passed!", log)
    if count is None:
        raise ValueError("No actual complete Flutter test count observed")
    return {"source": source, "passed": int(count[1]), "skipped": int(count[2]),
            "failed": 0, "ci_run_url": run["html_url"]}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--arm64", type=Path, required=True)
    parser.add_argument("--android-proof", type=Path, required=True)
    parser.add_argument("--ci-proof", type=Path, required=True)
    parser.add_argument("--ci-run", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--version-code", type=int, default=1930)
    parser.add_argument("--version-name", default="0.12.23")
    parser.add_argument("--godot-revision", default=GODOT)
    args = parser.parse_args()
    provenance = json.loads((args.arm64 / "BUILD-PROVENANCE.json").read_text())
    android = json.loads((args.android_proof / "education-android-result.json").read_text())
    outcomes = json.loads((args.ci_proof / "outcomes.json").read_text())
    run = json.loads(args.ci_run.read_text())
    log = (args.ci_proof / "tests.log").read_text()
    checked = validate(provenance, android, outcomes, run, log,
                       version_code=args.version_code, version_name=args.version_name,
                       godot_revision=args.godot_revision)
    apk = args.arm64 / "Lumo-Lernen-Neu.apk"
    if apk.stat().st_size != provenance["bytes"] or digest(apk) != provenance["sha256"]:
        raise ValueError("Downloaded ARM64 APK size/digest differs from the verified build")
    with zipfile.ZipFile(apk) as archive:
        if archive.testzip() is not None:
            raise ValueError("Actual APK integrity failed before packaging")
        actual_abis = {name.split("/")[1] for name in archive.namelist()
                       if name.startswith("lib/") and name.endswith(".so")}
        if actual_abis != {"arm64-v8a"}:
            raise ValueError("Actual downloaded APK is not the verified ARM64 variant")
    args.output.mkdir(parents=True, exist_ok=True)
    source = checked["source"]
    version_name, version_code = args.version_name, args.version_code
    new_course = (' sowie „Minus über den Zehner“' if version_code >= 1931 else '')
    if version_code >= 1933:
        new_course += ', „Wörter in Silben hören“ (Deutsch) und „Eine Blütenpflanze entdecken“ (Sachunterricht)'
    baseline_code = android['voice_update_kart']['baseline']['versionCode']
    course_count = 'fünf' if version_code >= 1933 else 'drei' if version_code >= 1931 else 'beide'
    instructions = f"""# Lumo Lernen Neu {version_name} ({version_code})

Diese ZIP enthält die vollständige ARM64-Test-APK der bestehenden Lumo-App.
Sie ist keine zweite Ersatz-App und keine Google-Play-Produktionsfreigabe.

## Installation ohne Verlust vorhandener Daten

- **ZIP entpacken:** Öffne anschließend `Lumo-Lernen-Neu.apk`, nicht die ZIP selbst.
- **Bestehende App behalten:** Deinstalliere „Lumo Lernen Neu“ nicht. Bei passender
  Paketkennung und Signatur bietet Android das Update an.
- **Getrennte Variante:** Paket `{provenance["package"]}`. Die normale Lumo-App
  hat eine andere Paketkennung und wird durch diese Testvariante nicht ersetzt.
- **Installation zulassen:** Erlaube sie bei Bedarf ausschließlich der verwendeten
  Datei-App. Schutzmechanismen und Play Protect nicht deaktivieren.
- **Bei abweichender Signatur:** Nicht deinstallieren oder Lernstände zurücksetzen;
  den angezeigten Fehler für die gezielte Prüfung festhalten.

## Stimme und neue Lernwege

Lumo Frei F2, vorhandene Original-Sulafat-Aufnahmen und die zentrale Audioverwaltung
bleiben erhalten. Dynamische Offline-Sätze erfordern die bewusst bestätigte lokale
Modellfreigabe im Elternbereich. Online-KI, Sprachserver, Mikrofon und Kamera werden
dadurch nicht freigegeben. Es wurden keine kostenpflichtigen Sprachanfragen ausgeführt.

Unter Lernen stehen „Lumo erklärt es mir“ und „Mit Lumo Neues entdecken“ zur Verfügung.
Tatsächlich enthalten sind die Einführungen „Über den Zehner“ und
„Das Einmaleins entdecken“{new_course}. Für freiwilliges Vorlernen zuerst im Elternbereich
„Vorlernen erlauben“ und die erlaubte Schulstufe wählen. Regulärer Schulfortschritt
und Entdeckungsfortschritt bleiben getrennt. Weitere Unterrichtseinführungen fehlen
noch; es wird keine vollständige Lehrplanabdeckung behauptet.

## Tatsächliche Prüfung und Quellzuordnung

- **Version:** {version_name}+{version_code}, ARM64, minSdk 24, targetSdk 36.
- **Flutter-Quelle:** `{source}`.
- **Godot-Quelle:** `{args.godot_revision}`, Engine 4.6.3.
- **APK SHA-256:** `{provenance["sha256"]}`.
- **Testsignatur SHA-256:** `{CERTIFICATE}`.
- **Komplette Flutter-Prüfung:** {checked["passed"]} bestanden,
  {checked["skipped"]} optionale Aufnahmefälle übersprungen, 0 fehlgeschlagen.
- **Android-Laufzeit:** Android 16/API 36 x86_64-Emulator. Update {baseline_code}→{version_code}
  ohne Deinstallation, tatsächliche Offline-Synthese/Wiedergabe, Pause/Fortsetzen/Stopp,
  Elternbereich, Godot-Menü/Rückkehr, {course_count} vollständige Unterrichtskurse,
  getrennte Fortschritte und Neustart bestanden.

Die gebaute ARM64-APK und die tatsächlich installierte x86_64-Prüf-APK stammen aus
demselben sauberen Flutter-Commit und derselben Godot-Revision. ARM64-Bauprüfung
ist ausdrücklich kein physischer ARM64-Laufzeittest.

## Verbleibende Abnahmen

Physisches Samsung/Fold, echtes Scharnierverhalten, ARM64-Wiedergabe, menschliche
Klang- und Emotionalitätsabnahme, vollständiges Kart-Rennen, externe pädagogische
Fachprüfung, Datenschutz-/Erwachsenenprüfung, kommerzielle Sprachmodell-Lizenz und
Google-Play-Freigaben bleiben offen. Keine echten Zahlungen oder Veröffentlichung
wurden aktiviert.

Die beigefügten Android-Bilder stammen aus der tatsächlich laufenden App im Emulator,
nicht aus Konzeptbildern oder einem Flutter-Testbild als angeblicher Android-Aufnahme.
"""
    if version_code >= 1933:
        instructions += "\nBekannter kleiner Bedienpunkt: „Erklärung lesen“ wiederholt in den neuen Beispielen den bereits angezeigten Erklärungstext. Die Übung, unterschiedliche Tipps und gespeicherten Antworten sind davon unabhängig.\n"
    notes = args.output / "INSTALLATION-UND-PRUEFSTAND.md"
    notes.write_text(instructions)
    screenshots = [
        "00_actual_android_phone_parents.png",
        "04_actual_android_fresh_local_math.png",
        "06_preserved_kart_menu.png",
        "07_preserved_kart_return.png",
        "10_actual_android_fold_target_seven_plus_five.png",
        "11_actual_android_learning_hint_after_error.png",
        "12_actual_android_complete_school_course.png",
        "13_actual_android_discovery_parent_gate.png",
        "15_actual_android_higher_grade_equal_groups.png",
        "16_actual_android_complete_discovery_course.png",
    ]
    if version_code >= 1931:
        screenshots.extend([
            "17_actual_android_subtraction_example.png",
            "18_actual_android_subtraction_alternative_hint.png",
            "19_actual_android_complete_subtraction_course.png",
        ])
    if version_code >= 1932:
        screenshots.append("20_actual_android_active_help_offer.png")
    if version_code >= 1933:
        screenshots.extend([
            '21_actual_android_syllables_example.png',
            '22_actual_android_syllables_alternative_hint.png',
            '23_actual_android_complete_syllables_course.png',
            '24_actual_android_plant_example.png',
            '25_actual_android_plant_alternative_hint.png',
            '26_actual_android_complete_plant_course.png',
        ])
    target = args.output / f"Lumo-Lernen-Neu-{version_name}-{version_code}.zip"
    with zipfile.ZipFile(target, "w", zipfile.ZIP_DEFLATED, compresslevel=1) as archive:
        archive.write(apk, "Lumo-Lernen-Neu.apk")
        archive.write(notes, notes.name)
        for name in ("BUILD-PROVENANCE.json", "APK-VERIFICATION.json", "SHA256SUMS.txt"):
            archive.write(args.arm64 / name, "pruefbelege/" + name)
        archive.write(args.android_proof / "education-android-result.json",
                      "pruefbelege/ANDROID-LAUFZEITPRUEFUNG.json")
        archive.write(args.ci_proof / "outcomes.json", "pruefbelege/FLUTTER-CI-OUTCOMES.json")
        archive.write(args.ci_run, "pruefbelege/FLUTTER-CI-RUN.json")
        for name in screenshots:
            path = args.android_proof / name
            if not path.is_file():
                raise ValueError("Required genuine Android screenshot is absent: " + name)
            archive.write(path, "echte-android-bilder/" + name)
    with zipfile.ZipFile(target) as archive:
        if archive.testzip() is not None:
            raise ValueError("Final complete delivery ZIP failed CRC validation")
        with archive.open("Lumo-Lernen-Neu.apk") as stream:
            embedded = hashlib.file_digest(stream, "sha256").hexdigest()
        if embedded != provenance["sha256"]:
            raise ValueError("The exact verified APK was not preserved in the delivery ZIP")
    result = {
        "archive": target.name, "bytes": target.stat().st_size, "sha256": digest(target),
        "apk": {"name": apk.name, "bytes": provenance["bytes"], "sha256": embedded},
        "source": source, "godot": GODOT, "full_flutter_ci": checked,
        "actual_android_result": "PASS",
        "apk_built": True, "zip_crc": "PASS", "embedded_apk_sha256": "PASS",
        "physical_android_test": False, "production_release": False,
    }
    (args.output / "ZIP-VERIFICATION.json").write_text(
        json.dumps(result, ensure_ascii=False, indent=2) + "\n")
    print(json.dumps(result, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
