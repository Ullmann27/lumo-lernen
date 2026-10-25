# Lumo – Entwicklungsübergabe (laufend aktualisiert)

Stand: 25.10.2026, Claude (Opus 5.5) · Auftrag: PROMPTRIX Master Execution vom 22.10.2026
Heinz hat die Arbeit am 23.10. mit „Stop“ angehalten. Danach wurden nur noch die offenen Stände getestet, committet und gepusht, damit jede KI übernehmen kann.

## 0. Übernahme durch eine andere KI (ChatGPT, Codex, neue Opus-Sitzung)

Nichts ist gesperrt. Der Branch ist ein normaler, öffentlicher GitHub-Branch ohne Schutzregeln; jeder Stand ist gepusht (kein Arbeitsstand liegt nur in einer Sitzung). Weiterarbeiten, ohne fremde Arbeit zu überschreiben:

```bash
git clone https://github.com/Ullmann27/lumo-lernen.git && cd lumo-lernen
git fetch origin claude/lumo-android-integration-m0-aloove
git checkout -b <dein-neuer-branch> origin/claude/lumo-android-integration-m0-aloove
bash scripts/portable-android.sh doctor   # zeigt fehlende Werkzeuge
bash scripts/portable-android.sh tests    # komplette Prüfkette ohne GitHub Actions
```

Wer direkt auf diesem Branch weiterarbeiten darf, pusht normal (kein Force-Push). Offener PR: #331 (nicht gemergt; `main` unberührt). Geprüfter Rückfallstand: `dea695e2f8634d520fd8e1ef7f0bceb4f88cb40b`, Version 0.12.84+1996, Unified-Lauf 39723572595 (Build und Android-Emulator-Tour grün).

## 1. Branch und Commit

- Repository: `Ullmann27/lumo-lernen`
- Branch: `claude/lumo-android-integration-m0-aloove` (PR #331, nicht gemergt; `main` unberührt)
- Basis:
  - Integrationsstand `origin/chatgpt/lumo-crystal-depth-integration-20261021` @ `9fae296a72211fc3843697932414d5119cfd51be` (0.12.84+1996), Merge `ab085e13`
  - PR #402 `review/render-first-portable-build-20261022` @ `ed0491c8`, Merge `c09334d943a2a89ccd9d77f1c15f3850d1cd41c4`
- Godot-Pin: `Ullmann27/lumo-godot` @ `3a3142608f6b150ee251373ba81e6face2eed4b3` (Branch `claude/kart-landing-landscape-fit-20261022`, Engine 4.6.3), ab Version 0.12.85+1997. Vorher `700baf49`.
- Weiterer Godot-Branch, noch nicht im Pin: `claude/kart-rival-race-craft-20261022` @ `66b280a45f11c0be6e44e49a315be3f56898c1b4` (Gegner-Rennverhalten, siehe Punkt 7; dort `tools/validate_project.sh` Exit 0, 15/15, in diesem Container).
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
| Lauf 39751337580 auf `50741c69` (0.12.85+1997) | GitHub Actions | **rot** in „Verify all build and preservation contracts“: `test_unified_workflow_artifact_names` erwartete 4 statt 5 Artefakt-Downloads |
| Lauf 39755153883 auf `136f486a` (Heinz' Testkorrektur) | GitHub Actions | **grün**: Build, volle Flutter-Suite, Verträge, APK-Verifikation, x86_64-Emulator-Tour mit Rennen, danach Veröffentlichung von Release `lumo-0.12.85-1997` |
| Mathe „Was fehlt?“ (Folge-Commit auf `136f486a`) | dieser Container, Flutter 3.44.9 | Verträge 199 OK, Android-QA 650 OK, Capture-Fonts OK, `flutter analyze` 0 Fehler, Flutter **1829 bestanden / 161 übersprungen / 0 fehlgeschlagen**, alle vier Mathe-Testdateien 23 OK (davon 9 in `math_task_templates_test.dart`), Content-Audit PASS (40.991). **Nicht in Release 1997** (braucht eine neue Build-Nummer) |
| Godot `kart_reference_landing_fit_regression.gd` (3a31426) | dieser Container | vorher 20 Fehler, nachher PASS auf 4 Android-Größen |
| Godot-Rennsimulation `kart_rival_race_simulation.gd` (Gegner-Branch) | dieser Container | PASS: Abenteuer vorher Platz 1 mit 477 m Vorsprung und 5,6 % der Zeit in Reichweite; nachher Platz 2, 100 % in Reichweite, 15 Führungswechsel; Profi Platz 2; Entdecken bleibt gewinnbar |

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

Aus dieser Umgebung wurde **keine** APK erzeugt. Die veröffentlichte APK 0.12.85+1997 stammt aus GitHub Actions (Lauf 39755153883, Daten in Punkt 8).

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
- Lumo Kart, Gegner: erster Schritt auf Godot-Branch `claude/kart-rival-race-craft-20261022` (Kurven, Überholen, Windschatten, Aufschließen, nie schneller als das Kind ohne Boost; Rennsimulation `scripts/tests/kart_rival_race_simulation.gd`). **Noch nicht im Pin** und nicht im APK. Heinz' weitergehender Wunsch (jeder Gegner gleich stark wie das Kind, Vorsprung nur durch Auto-Verbesserungen, Strecke mit Brücken, Schanzen, Hindernissen, Landschaft, Items wie Turbo/Abschießen) ist offen.
- Godot-PCK ist nicht byte-reproduzierbar.
- **Kart-Hauptmenü:** Die fehlenden Kachel-Beschriftungen im Querformat sind in Godot `3a3142608f6b150ee251373ba81e6face2eed4b3` behoben (Test `kart_reference_landing_fit_regression.gd`, Pin von 0.12.85+1997). Die frühere Meldung „START auf dem Fold innen zu dünn“ war **falsch**: Sie stammte aus einer Messung mit Dichte 1.0. Mit der echten Dichte 2.625 ist START mindestens 48 dp hoch.
- **Kart-Test `kart_race_continuity_regression.gd`** scheitert („The actual pickup is consumed in lap one“) schon auf `3a31426` ohne jede Änderung von mir. Er läuft in keinem Workflow dieses Branches. Ursache nicht untersucht.
- **Heinz' Wünsche vom 22./23.10., noch nicht begonnen:** Kart-Menü modernisieren (Lumo unverändert, aber echt in 3D und drehend wie früher, kein ausgeschnittenes Bild; moderne Menüleisten; eigene Kart-Rennmusik ohne fremde Marken), Deutsch ausbauen, die 2–3 Seiten im alten Layout modernisieren, Nachhilfe-Tipps kindgerecht für Klasse 1–4 in allen Fächern neu schreiben.

## 8. Exakter nächster Schritt

1. **Release 0.12.85+1997 ist veröffentlicht** (Prerelease, Test-Schlüssel, nicht auf echtem Samsung/Fold geprüft):
   - Direkter Download: `https://github.com/Ullmann27/lumo-lernen/releases/download/lumo-0.12.85-1997/Lumo-Lernen-0.12.85-1997-ARM64.apk`
   - Paket `dev.ullmann.lumo.lumo_lernen.coachpreview`, versionName 0.12.85, versionCode 1997
   - APK-SHA-256 `0c17989d36931363716b0b8bc693ba379773ef5d07ff2c29b9a226ad82371ea8`
   - Zertifikat-SHA-256 `a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702`
   - Flutter `136f486ac3bdc4aabbd3b990e6629d2d6640c7d4`, Godot `3a3142608f6b150ee251373ba81e6face2eed4b3`, Lauf 39755153883
   - Rückfallstand bleibt 0.12.84+1996 (`dea695e2`).
2. Gegner-Branch `claude/kart-rival-race-craft-20261022` prüfen (`tools/validate_project.sh`, Rennsimulation) und als neuen Pin mit eigener Build-Nummer 0.12.86+1998 einbinden: `config/godot-source.json`, `APPROVED[1998]` in `scripts/verify_legacy_release_pin.py`, Allowlist in `scripts/export_embedded_game.py`, Publish-Job.
3. Danach Heinz' Wünsche vom 22./23.10. (Punkt 7): Kart-Menü mit drehendem 3D-Lumo, Menüleisten und Rennmusik; Strecke Sonnenhafen mit Brücken, Schanzen, Hindernissen, Landschaft und Items; gleich starke Gegner; Deutsch, alte Seiten und Nachhilfe-Tipps in der Lern-App.
4. Ohne Android-SDK hier nicht möglich: `bash scripts/portable-android.sh preview-apk` auf einem Rechner mit SDK oder Docker-Host. Der Docker-Build (`tools/portable-android/Dockerfile`) ist **nie gebaut oder getestet** worden.
