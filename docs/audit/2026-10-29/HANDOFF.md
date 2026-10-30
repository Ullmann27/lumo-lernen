# Verbindliche Übergabe für die nächste Weiterarbeitungs-KI

Aktualisiert am 30.10.2026: Build 2002 ist veröffentlicht und unabhängig
nachgeprüft. Auch bei späterer Wiederaufnahme zuerst GitHub-Status und
Release-Existenz frisch prüfen.

## Nutzerauftrag und letzte Steuerung

Lumo soll als geduldiger lokaler Nachhilfelehrer aus echten Lernereignissen
entscheiden, passende Erklärungen wechseln und selbstständiges Verständnis
nachvollziehbar prüfen. Grundbetrieb offline ohne bezahlte KI-API. Original-
Lumo erhalten, Profile strikt trennen, Testmodus ohne unzulässige Hilfe,
Schreibtrainer/Journal/Wallet/Kart und veröffentlichte APKs schützen.

Am 29.10. lautete die Nutzersteuerung: nur noch ungefähr 20 Prozent
Restbudget; fertigmachen, committen, pushen und eine belastbare Übergabe mit
Regeln, offenen Punkten und nächsten Schritten sichern. Daraufhin wurde der gesamte Stand gesichert. Am 30.10. hat der Nutzer mit
„Weiter“ die Fortsetzung beauftragt. Neue Funktionsblöcke sind wieder möglich,
aber ausschließlich auf eigenem Branch unter Schutz des veröffentlichten 2002.

## Welche Zweige und Quellen existieren?

| Zweck | Branch / Quelle |
|---|---|
| Unveränderte Ausgangsarbeit | `feat/lumo-tutor-brain-2001-20261028`, `9fdfc3f17e640ade0912411167d4af2f73be8720` |
| Geprüfter Tutor-Kern | `feat/lumo-living-intelligence-20261029`, `5d6d7dcd0ebbff48b7c7850b0e392a9086ea1ecc`, Draft-PR #414 |
| Separater 2002-Kandidat | `feat/lumo-living-intelligence-2002-20261029`, `ff791642a0d28d10f89d98025fd8f5fb2c19c403`, Draft-PR #415 |
| Vollständiger Handoff inklusive beider Arbeiten und Nachweise | `docs/lumo-living-intelligence-verification-20261029` |

Dieser Handoff-Zweig hat beide Arbeitszweige zusammengeführt. Seine produktiven
Quellen entsprechen dem 2002-Kandidaten; spätere Änderungen betreffen nur
Anleitung/Nachweise. Die GitHub-Builds beziehen sich ausdrücklich auf ff791642,
nicht auf einen nachträglichen Dokumentations-Commit. Beide PRs bleiben Drafts;
kein Merge nach `main` wurde vorgenommen. PR #411–413 und Opus-Arbeiten wurden
nicht überschrieben. Alle genannten Arbeiten sind auf GitHub gesichert.

## Was ist tatsächlich fertig?

1. Deterministische `LumoIntelligenceEngine` und partieller 14-Knoten-Graph mit
   tatsächlichen Aufgabenlinks. Unit-Erfolg allein bestätigt keinen Prozess.
2. `LessonSceneEngine` und Learning Scene Contract v1 mit vier Methoden,
   unveränderlichen Daten, geprüften Regeln und vollständiger Zehner/Einer-Referenz.
3. Produktive Route: erste Erklärung ablehnen → Alternative → andere Zahl
   selbst bauen → Einer-Rückfrage → profilgebundener Beleg → Neustart/Wiederladen.
4. Richtiges Ergebnis bei falscher Zerlegung zählt nicht. Hilfe während neuer
   Konstruktion/Rückfrage sowie Korrektur/Raten bleiben unterstützt.
5. Bestehendes Journal plus lokales Szenengedächtnis mit dauerhaftem
   Zwischenbeleg. Teil-Schreibfehler, fehlende Bestätigung und Neustart werden
   ohne doppelte Evidenz wiederaufgenommen. Fremde Profil-Leases werden verworfen.
6. Elternbegründungen, abwechslungsreiche echte Tagesplan-Einstiege und echte
   Laufzeitbilder bei 360dp, 280dp/2× Schrift und 880dp.
7. Eigene 2002-Update-/Veröffentlichungsgates; alte 2000/2001-Gates erhalten.

Wichtige Implementierungsdateien:

- `lib/domain/learning_intelligence/`: Graph, Engine, Contract, Session, Memory.
- `lib/core/learning_profile_engine.dart`, `progress_repository.dart`:
  persistenter Beleg, Recovery, bestehende profilgetrennte Speichergrenze.
- `lib/app/app_state.dart`: Lease-/Generationsschutz für Abschlussbelege.
- `lib/features/learning/learning_content.dart` und dessen Widgets:
  echte Hilfe, Alternativszene und Stellenwert-Werkstatt.
- `lib/core/lumo_personal_daily_tutor_planner.dart` sowie Eltern-Evidenzkarte.

## Was ist wirklich geprüft?

Auf **beiden** oben genannten GitHub-Quellen:

- 1.952 Flutter-Tests bestanden, 171 vorhandene optionale Fälle übersprungen.
- Zusätzlich 43 fokussierte Unit-/Widget-/Profil-/Speicher-/Routenfälle bestanden.
- Vollanalyse: 0 Fehler, 6 bestehende Warnungen, 106 Hinweise.
- Kern-CI und bestehende vollständige Change-Review-Prüfung erfolgreich.

Tutor-Kern: Runs `40846028231` und `40846027846`.
2002-Kandidat: Runs `40846950258` und `40846950262`.
Original-Artefakte heruntergeladen und deren ZIP-SHA-256 geprüft; dauerhafte
Prüfdaten liegen unter `docs/evidence/living-intelligence/github-core/`.
Lokal zusätzlich 208 Skripttests (einer übersprungen) und 656 Android-Probe-/
OCR-/Preservation-Tests bestanden. Das sind keine erfundenen Gerätetests.

Ein frischer unabhängiger Review fand keine kritischen, drei wichtige und zwei
kleinere Befunde. Alle fünf wurden korrigiert; 19 gezielte Regressionstests und
die vollständigen GitHub-Läufe bestätigen die Korrekturen. Die Einzelbefunde
und Entscheidungen stehen in `STATUS.md`; keinen zweiten Review erfinden.

## Android-Auslieferung abgeschlossen

Alle nachfolgenden Gates sind **erfolgreich**. Die ARM64-Haupt-App wurde am
29.10.2026 um 09:48:56 UTC unveränderlich veröffentlicht. Am 30.10. wurden
anonymer HTTPS-Download, Dateigröße, SHA-256 und alle Prüfungen aus
`scripts/verify_unified_apk.py` unabhängig erneut bestätigt.
[Release-Bericht](../2026-10-30/RELEASE_2002_VERIFICATION.md).

| Lauf | Zweck |
|---|---|
| `40846950267` | vollständiger Gesamtbuild und echte Android-/native Kart-Tour |
| `40846950656` | tatsächlich erzeugter 2000-Lernstand, install-r 2002, Datenerhalt, Offline-Kart, Neustart, Fold-Geometrien |
| `40846950358` | nur nach erfolgreichen Gates neues direktes Chrome-Release |

```bash
gh run view 40846950267 --repo Ullmann27/lumo-lernen
gh run view 40846950656 --repo Ullmann27/lumo-lernen
gh run view 40846950358 --repo Ullmann27/lumo-lernen
gh release view lumo-0.12.90-2002 --repo Ullmann27/lumo-lernen --json url,isDraft,assets
```

Release-Identität: Version `0.12.90`, versionCode `2002`, Paket
`dev.ullmann.lumo.lumo_lernen.coachpreview`, Signatur-SHA-256
`a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702`,
Godot `adcce3093caa42bf3da47262f70bdf03cdefa347`, Engine 4.6.3.
Das ist dieselbe installierte Haupt-App-Testserie wie Build 2000, keine Demo.

Veröffentlichte Datei:
[Lumo-Lernen-0.12.90-2002-ARM64.apk](https://github.com/Ullmann27/lumo-lernen/releases/download/lumo-0.12.90-2002/Lumo-Lernen-0.12.90-2002-ARM64.apk),
317.179.546 Bytes; SHA-256
`17483a730bb9a1a13e4bcf5a2d733523a4da07983a0aadc38a980f5d771a9c76`.
`update-result.json` und `tour-result.json` sind PASS; Offline-Update mit
identischer Installations-ID, erhaltenem Testprofil, Lernstand und Rewards,
Neustart und drei Fold-Geometrien; null fatale Abstürze. Raw-Belege und
Original-Screenshots stehen unter `docs/evidence/living-intelligence/android-2002/`.
Die Android-Tour nutzte das x86_64-Paket desselben Quellstands; die öffentliche
ARM64-APK wurde paket- und signaturseitig geprüft. Keine physische ARM64- oder
Fold7-Bildratenmessung behaupten; dies ist die signierte Haupt-App-Testserie.

Falls ein Gate fehlschlägt: tatsächliche Joblogs und Artefakte untersuchen,
keine Prüfungen entfernen. Infrastrukturfehler können am identischen Commit
gezielt neu ausgeführt werden. Bei Produktfehlern den eigenen Kandidaten mit
neuem Commit korrigieren und alle Gates neu bestehen lassen. Bereits
veröffentlichtes 2002 nie überschreiben; dann einen neuen Versionsstand wählen.
Keine laufende erfolgreiche Tour durch reine Dokumentations-Commits abbrechen.

Artefakte der Builds sind üblicherweise 30 Tage, Kern-Nachweise 90 Tage
aufbewahrt. Bei Wiederaufnahme nach zwei Wochen sollten sie noch vorhanden
sein; trotzdem tatsächliche Verfügbarkeit prüfen. Bei lokalem CLI-403 auf
GitHub-Azure-Artefakte funktionieren die verbundenen GitHub-Tools
`fetch_workflow_run_artifacts` und `download_workflow_artifact`; danach den
gelieferten Datei-Verweis laden und den Digest prüfen. Keine Zugangsdaten loggen.

## Was ich danach als Nächstes gemacht hätte

1. Release-Abschluss ist erledigt. Die veröffentlichten Source-SHAs, Tags und
   Assets nicht verschieben. Für neue Facharbeit einen eigenen Branch anlegen.
2. Gemeinsamen echten Aufgaben-/Hilfekontext in die eigenständigen Module
   integrieren. Alle 19 Screens besitzen schon den visuellen Rahmen; neue
   Szenen sind dort noch nicht allgemein angebunden. Die statische Modulkarte
   und die bestehenden 268 Klasse/Fach/Thema-Zeilen nutzen, nichts neu erfinden.
3. Lesen: echte Aussagen mit Textstellen zuordnen, dann einen neuen Text
   unabhängig prüfen. Silben/Sätze: geordnete Bausteine mit vorhandenen fachlich
   geprüften Schlüsseln. Contract-Regeln existieren; produktive Werkstätten fehlen.
4. Weitere Konzepte nur über eigene Prozessvalidatoren bestätigen. Insbesondere
   Bündeln, Zehnerübergang, Satzbau und Textbegründung nicht aus beliebigen
   Antwortzählern als beherrscht markieren.
5. Opus kann über den dokumentierten v1-Vertrag Original-Lumo-Blick/Gesten und
   Übergänge ausbauen. Animation besitzt keine Kompetenz-/Speicherentscheidungen.
6. Vorhandene lokale Sprachressourcen nutzen; Spracheingabe erst nach echtem
   on-device-Nachweis. Kein heimliches Mikrofon, kein bezahltes Cloud-Grundsystem.

Die vollständige Referenz ist bisher Zehner/Einer. Keine vollständige
österreichische Lehrplanabdeckung oder empirische Lernwirksamkeit behaupten.
Schreibtrainer, Journal und Diktat-Selbsteinschätzung nicht vereinfachen; nach
sichtbarer Lösung ist eine Selbsteinschätzung kein unabhängiger Transfer.

## Reproduzierbare Weiterarbeit

AGENTS.md vollständig beachten. Zuerst lokalen/Remote-Stand und fremde Claims
prüfen; neue fachliche Arbeit auf eigenem Branch/Worktree beginnen. Kein
`reset --hard`, `clean -fd`, Force-Push oder Merge nach main als Reparatur.
Vor großen Schritten und ungefähr alle fünf Minuten `python3 tools/lumo_autosave.py once`.
Checkpoints sind Sicherungen und keine Qualitätsfreigabe.

Toolchain: Flutter 3.44.9. Relevante Befehle:

```bash
flutter pub get --enforce-lockfile
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test --no-pub --reporter=expanded --timeout=60s --concurrency=2 test/intelligence test/design/lumo_tutor_brain_capture_test.dart
flutter test --no-pub --reporter=expanded --timeout=60s --concurrency=2
python3 -m unittest discover -s scripts/tests -v
python3 -m unittest discover -s tools/android_qa/tests -p 'test_*.py' -v
```

Aufnahmen: `LUMO_INTELLIGENCE_EVIDENCE` und `LUMO_TUTOR_BRAIN_CAPTURES` auf ein
geprüftes Ausgabeverzeichnis setzen. Echte Fonts laden; Ahem-Blöcke sind kein
Bildnachweis. Ungeprüfte generierte `.ci-results/`-/`visual-evidence/`-Dateien
nicht pauschal einchecken. Die kuratierten Aufnahmen und Nachweise sind bereits
im Repository gesichert. Es werden keine Schlüssel oder geheimen Dateien für
diese Übergabe benötigt.
