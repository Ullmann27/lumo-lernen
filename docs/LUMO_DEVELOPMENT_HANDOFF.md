# Lumo – Entwicklungsübergabe (laufend aktualisiert)

Stand: 22.10.2026, Claude (Opus 5.5) · Auftrag: PROMPTRIX Lumo-Master-Entwicklungsauftrag
Priorität 1 (GitHub-Actions-unabhängige Android-Buildkette) und erster Schritt Priorität 2.

## 1. Branch und Commit

- Repository: `Ullmann27/lumo-lernen`
- Branch: `claude/lumo-android-integration-m0-aloove` (PR #331, nicht gemergt; `main` unberührt)
- Basis:
  - Integrationsstand `origin/chatgpt/lumo-crystal-depth-integration-20261021` @ `9fae296a72211fc3843697932414d5119cfd51be` (0.12.84+1996), Merge `ab085e13`
  - PR #402 `review/render-first-portable-build-20261022` @ `ed0491c8`, Merge `c09334d943a2a89ccd9d77f1c15f3850d1cd41c4`
- Godot-Pin (unverändert): `Ullmann27/lumo-godot` @ `700baf49828eda693ecce15b415847818b1b56d3`, Engine 4.6.3
- Letzter Code-Commit vor dieser Aktualisierung: `41e751a5` (Tour-START-Erkennung). Der Commit, der diese Fassung enthält, folgt direkt darauf; `git log -1` nennt den vollständigen SHA.

## 2. Abgeschlossene Änderungen

1. **Render-first-Buildweg weiterentwickelt** (`scripts/portable-android.sh`, aus PR #402, keine zweite Pipeline):
   - `doctor` listet alle Blocker auf einmal: JDK, Android-SDK, `sdkmanager`, Plattform 36, SDK-Lizenz, NDK, build-tools, RAM und Platte.
   - Neuer Modus `godot-tests`: die eigene Testsuite der exakt gepinnten Godot-Revision.
   - `preview-apk` erzeugt `PORTABLE-BUILD-EVIDENCE.json` und unveränderliche Kandidaten-Dateinamen mit `SHA256SUMS.txt`. Der Gerätetest steht darin ausdrücklich als NOT EXECUTED.
   - **Behobener Fehler aus PR #402:** Der Content-Audit lief vor `flutter pub get` und scheiterte deshalb auf jedem frischen Klon.
2. **Godot-Download abgesichert**: `scripts/install_godot_for_build.sh` prüft das 4.6.3-Archiv gegen SHA-256 `d0bc2113065e481c9c2c2b2c37daa4e8be3fe9e27f0ab9ab0b6096e9a37907f3`.
3. **Reproduzierbare Toolchain** `tools/portable-android/Dockerfile` (alle Downloads per SHA-256 gepinnt). Status: **NICHT GEBAUT**.
4. **Render-Eignungsprüfung** in `docs/LUMO-RENDER-FIRST-BUILD-20261022.md`, Abschnitt „Stand nach Prüfung und Ausbau“. Es wurde kein Render-Dienst angelegt und es sind keine Kosten entstanden.
5. **Roter Flutter-Build repariert**: 20 Fehler in `test/design/learning_adventure_layout_test.dart`, schon auf dem Integrationsstand 9fae296 rot (Unified-Lauf 39661400954).
   - Ursache: `pumpAndSettle` wartet auf Lumos absichtlich endlose Schwebe- und Glüh-Animation.
   - Fix: feste Frames statt `pumpAndSettle`; „Lumo vollständig“ wird wieder in Ruhelage geprüft.
   - Alle Größen-, Antipp- und Navigationsprüfungen sind unverändert.
6. **Historisches 1970-Runtime-Gate** (`lumo-runtime-apk.yml`) läuft nicht mehr auf diesem Branch.
   - Seine Hash-Konstanten sind laut `scripts/tests/test_native_source_bindings.py` an das Build-1970-Beweismaterial gebunden und dürfen nicht umgeschrieben werden.
   - Am Pin 700baf49 weichen `kart_island.gd` (`72ca5eca…`) und `kart_complete_flow_regression.gd` (`53c1fa47…`) davon ab.
   - Geprüft habe ich den Diff 61f51b9..700baf49: Kart-Hauptmenü, Resonanz-Items, längere Testsimulation. Sitzungsspeicherung und Flutter-Rückgabe sind unverändert.
7. **1966-Vertrag** (`lumo-1966-cards-route-kart-qa.yml`) an den strengeren Tour-Aufruf `driving_progress(start, last, mode=…, track=…)` angepasst (`d0049bda`). Er war auch auf PR #400 rot.
8. **Priorität 2, erster sichtbarer Schritt – Fächerauswahl „Lernen“** (`c1ec339f`):
   - farbige Fachkacheln mit den vorhandenen gemalten Fachsymbolen (`AcademySubjectArt`)
   - echter Themen-Fortschrittsring je Fach aus `appState.learningSkills()`; nur Themen der eigenen Klasse mit mindestens einer richtigen Antwort zählen
   - der vorhandene Lumo (`fox_point.webp`) im Kopfbereich
   - „Alle Lernwege & andere Klassen“ nach oben zur Klassenangabe verschoben
   - je Kachel ein barrierefreier Knopf mit Tipp-Aktion
9. **Emulator-Tour repariert** (`41e751a5`): Der neue Kart-Hauptbildschirm von Godot 700baf49 hat den goldenen START-Knopf unten links. Die Gold-Knopf-Erkennung suchte nur unten rechts (Unified-Lauf 39720099333 scheiterte daran nach 3 Minuten). Jetzt wird die ganze Breite abgesucht; nur ein Knopf, dessen gelesener Text wirklich „START“ ist, zählt.

## 3. Geänderte Dateien

- `scripts/portable-android.sh`, `scripts/install_godot_for_build.sh`
- `scripts/tests/test_portable_android.py` (neu, 5 Tests)
- `tools/portable-android/Dockerfile` (neu)
- `docs/LUMO-RENDER-FIRST-BUILD-20261022.md`, `docs/LUMO_DEVELOPMENT_HANDOFF.md` (neu), `OPUS_NEXT.md` (Link)
- `test/design/learning_adventure_layout_test.dart`
- `.github/workflows/lumo-runtime-apk.yml` (nur der eigene Trigger-Eintrag vom 17.10. entfernt)
- `.github/workflows/lumo-1966-cards-route-kart-qa.yml` (ein String-Vertrag)
- `lib/features/sections/lumo_learning_hub.dart`, `lib/features/teacher_mode/lumo_akademie_screen.dart`
- `test/design/learning_hub_progress_test.dart` (neu), `test/design/lumo_1992_calm_navigation_test.dart` (Scrollrichtung zur verschobenen Schaltfläche)
- `docs/screenshots/learning-hub-2026-10-22/` (Vorher/Nachher-Renderings)
- `.github/probes/modernization_android_tour.py`, `tools/android_qa/tests/test_modernization_tour_identity.py`, `tools/android_qa/tests/fixtures/kart-landing-700baf49/` (echte Godot-Renderings des Kart-Menüs)

## 4. Tests und Ergebnisse (nur tatsächlich gelaufene)

| Prüfung | Umgebung | Ergebnis |
|---|---|---|
| Godot `tools/validate_project.sh` am Pin 700baf49 (frischer Klon, inkl. Renderer-Tests unter xvfb) | dieser Container | **14/14 PASS**, 3:37 min |
| `install_godot_for_build.sh` mit offiziellem Archiv / mit falschem Pin | dieser Container, leerer PATH | PASS (4.6.3.stable.official.7d41c59c4) / korrekt verweigert, Exit 1 |
| `portable-android.sh doctor` | dieser Container | Exit 3, korrekt: kein Android-SDK, keine build-tools |
| `doctor` mit Platzhalter-SDK-Struktur (nur Logikprüfung) | dieser Container | SDK-Zweig PASS, NDK als WARN |
| Beweisdatei-Schreiber mit Platzhalter-APKs | dieser Container | korrekt; verweigert Hash-Abweichung und Überschreiben eines Kandidaten |
| `scripts/tests/test_portable_android.py` | dieser Container | 5/5 OK |
| `learning_adventure_layout_test.dart` | dieser Container, Flutter 3.44.9 | vorher 20 Fehler, nachher **82/82** |
| `portable-android.sh tests` (vollständig, frischer Klon @ `7c3cb9412a062d95e15790e284d26dfdc4e5fcc0`) | dieser Container, JDK 21, kein SDK | **Exit 0**, 9:05 min: Proxy 35/35, Skripte 197 OK, Android-QA 648 OK, Content-Audit PASS (40.991 Aufgaben), Repair-Guard OK, `flutter analyze` 0 Fehler (61 Hinweise/Warnungen), Flutter **1826 bestanden / 161 übersprungen / 0 fehlgeschlagen** |
| `portable-android.sh godot-tests` (Wrapper, frischer Klon) | dieser Container | **Exit 0**, 14/14 PASS am Pin 700baf49 |
| Unified-Integration 39720099333 auf `750d790a`, Job `verify-and-build` | GitHub Actions | **grün**: volle Flutter-Suite, Verträge, echter Android-APK-Build und APK-Verifikation (APK x86_64 SHA-256 `58eb1a64e62c71853bbd0d87ae86194cdb62562f9473d826e22965264edcd987`) |
| dieselbe, Job `android-tour` (API 35, Pixel 5, exakte APK) | GitHub-Emulator | **rot** nur bei `start-kart-race` (siehe Punkt 9). Grün: APK-Identität, Onboarding, Lernen, Spielen, Rückkehr aus Kart, Lernstand und Profil erhalten, Neustart, Fold innen/außen, Querformat |
| Volle Flutter-Suite mit neuer Fächerauswahl | dieser Container | **1828 bestanden / 161 übersprungen / 0 fehlgeschlagen** |
| `learning_hub_progress_test`, Akademie-/Sachunterricht-/Story-Navigation | dieser Container | grün |
| Tour-START-Erkennung auf echten Godot-Renderings (1280×720, 2400×1080) und echter API-35-Garage | dieser Container, tesseract | gefunden bzw. korrekt abgelehnt; Test scheitert auf altem Tour-Code; Android-QA 650 OK |

**Nicht getestet:**
- `preview-apk`, also APK-Build, Signatur und Paket-ID: `dl.google.com` ist hier gesperrt.
- Emulator- oder Gerätetest: hier gibt es kein KVM.
- Docker-Build: hier läuft kein Docker-Daemon.
- Render: `render.com` ist hier nicht erreichbar.

## 5. Neue Grafiken

- Fächerauswahl „Lernen“: farbige Kacheln, Fortschrittsring, Lumo im Kopf. Eingebaut in `lib/features/sections/lumo_learning_hub.dart`; nur vorhandene Assets (`assets/lumo_design/characters/fox_point.webp`, `AcademySubjectArt`).
- Belege: `docs/screenshots/learning-hub-2026-10-22/phone_learn_vorher_nachher.jpg` und `fold_learn_vorher_nachher.jpg` (echte Flutter-Renderings, nicht auf einem Gerät geprüft).
- Lumo-Figur, Schreibtrainer und Journal sind unberührt.

## 6. APK-Artefakte und Nachweis

Aus dieser Umgebung wurde **keine** APK erzeugt.

GitHub-Actions-APK (nicht von mir lokal geprüft): Lauf 39720099333 auf `750d790a`, Artefakt mit x86_64-APK SHA-256 `58eb1a64e62c71853bbd0d87ae86194cdb62562f9473d826e22965264edcd987`. Die APK-Identität wurde dort im Emulator bestätigt; ein vollständiger Gerätetest inklusive Rennen fehlt noch.

Der portable Nachweisweg ist vorbereitet:

```bash
bash scripts/portable-android.sh preview-apk
```

Ergebnis:
- `dist/candidates/Lumo-Lernen-<version>+<code>-<commit12>-<abi>.apk`
- `dist/candidates/SHA256SUMS.txt`
- `dist/candidates/PORTABLE-BUILD-EVIDENCE.json` mit Paket-ID, versionCode, targetSdk, Zertifikats-SHA-256, Godot-Revision und Toolchain
- dazu `build/portable-evidence/<zeit>-<commit>-preview-apk/` mit allen Logs

## 7. Offene Fehler und Risiken

- **CI auf c09334d (vor den Fixes):**
  - 1955-Workflow (39717000132) und Runtime-APK (39717000086) rot wegen derselben 20 Layout-Tests. Behoben in `7c3cb941`; in CI bestätigt (Unified-Lauf 39720099333, volle Flutter-Suite grün).
  - Games-Visual-QA (39716985344) rot. Der Workflow ist fest auf den Versionsvergleich 1989→1990 verdrahtet und scheitert bei jedem anderen Versionsstand. Nicht geändert.
- **Signatur:** `tools/lumo-debug.keystore` (Passwort `android`) ist öffentlich und nur ein Testschlüssel. Für Updates einer installierten App oder für Google Play ist ein eigener, geheimer Schlüssel nötig. Das ist Heinz' Entscheidung.
- **Render offen:**
  - Kontingent und Plan
  - Image-Größe gegen Build-Grenzen
  - Weg, die APK herauszubringen (Token = sicherheitsrelevant)
  - Emulatortests sind dort nicht möglich
- 14 Dateien in `lib/` sind von `main.dart` aus nicht erreichbar (CLAUDE.md-Regel 8), noch nicht bereinigt.
- Lumo Kart: Wunsch „Gegner schwieriger, jeder will Erster werden, realistisch aussehende Fahrer“ ist **noch nicht umgesetzt** (Priorität 3).
- Godot-PCK ist nicht byte-reproduzierbar.
- **Kart-Hauptmenü (Godot 700baf49), Befunde aus echten Renderings:**
  - Im Querformat zeigen die unteren drei Kacheln (Sonnenhafen, Garage, Einstellungen) keine sichtbare Beschriftung.
  - Auf dem Fold innen (2176×1812) ist der START-Balken nur etwa 2 % der Bildhöhe hoch.
  - Beides gehört zu Priorität 3 und ist noch nicht geändert.

## 8. Exakter nächster Schritt

1. Den Unified-Lauf für den Push-Stand prüfen. Erwartet: Die Tour findet jetzt START und fährt das Rennen. Falls nicht, zeigen die neuen Log-Vorschauen `21_lumo_kart_20s` und `21_kart_premium_start`, was der Emulator sah.
2. Auf einem Rechner mit Android-SDK (oder Docker-Host):
   ```bash
   bash scripts/portable-android.sh doctor
   bash scripts/portable-android.sh preview-apk
   ```
   Danach die Kandidaten-APK aus `dist/candidates/` auf Emulator bzw. Samsung-Gerät installieren und die Tour `.github/probes/modernization_android_tour.py` ausführen.
3. Erst danach: Render-Dienst nach Heinz' Freigabe. Priorität 2 fortsetzen: Themenliste eines Fachs, Belohnungen und Startbildschirm nach Vorgabe `docs/design_targets/2026-10-04/`; Integration von Schreibtrainer und Journal ohne Verlust.
