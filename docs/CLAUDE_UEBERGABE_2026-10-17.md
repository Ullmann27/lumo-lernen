# Übergabe Claude Opus 5.5 → nächste Sitzung (GPT-6 / Claude), 17.10.2026

Stand: Ende einer Sitzung mit knappem Budget. Diese Übergabe trennt drei Stufen:
- **GETESTET:** ausgeführt, mit Beleg.
- **STATISCH:** nur Code oder Syntax geprüft.
- **OFFEN:** nicht erledigt.

## 1. Repositories, Branches, Commits

| Repo | Branch | Basis | Letzter Commit | PR |
|---|---|---|---|---|
| lumo-lernen | `claude/lumo-android-integration-m0-aloove` | `main` b244748 → Fast-Forward auf #328-Kopf `416a734` | siehe `git log` (Übergabe-Commit nach `fe6d543`) | #331 (von Heinz geöffnet) |
| lumo-godot | `claude/sonnenhafen-harbor-crane-2026-10-17` | `b5f1989` (aktueller Flutter-Pin = #76 + #77) | `61f51b9` | [#78](https://github.com/Ullmann27/lumo-godot/pull/78) (Entwurf) |

Neuester integrierter Flutter-Stand laut Heinz:
- PR #340, `chatgpt/lumo-1966-cards-route-race-telemetry-2026-10-16`, Commit `32cd14ad`.
- Workflow 38962050421 **grün**: echtes Rennen, HUD, 14,33 m gefahren, +5,02 s Rennzeit, Weltbewegung, Pause, Rückkehr, Profil und Lernstand erhalten.
- Diese Sitzung hat das **nicht selbst nachgeprüft**.

## 2. M0.1 – Android-Buildfehler (Lauf 38896179742)

- **Fehler:** `Could not find org.jetbrains.kotlin:kotlin-gradle-plugins-bom:2.2.20` und `kotlin-gradle-plugin-api:2.2.0` beim Konfigurieren von Flutters eigenem Gradle-Build (`flutter_tools/gradle`).
- **Ursache (belegt):**
  - `flutter_tools/gradle/settings.gradle.kts` (Flutter 3.44.9) hat keine `pluginManagement`-Repositories. Die Kotlin-Plugins kommen deshalb nur über das Gradle Plugin Portal.
  - Das Portal leitet per 303 an Maven Central weiter.
  - Maven Central drosselt geteilte CI-Adressen. Vorhandene Artefakte beantwortet es dann mit **HTTP 404 + `Retry-After`** oder **429**, ein echtes Fehlen dagegen mit 404 ohne `Retry-After`.
  - Gradle wertet das 404 als „nicht gefunden“.
  - Gegenprobe: Dieselben `apk`-Job-Eingaben bauten 30 Minuten vorher grün (38892673870).
  - Lokal mit leerem Gradle-Cache reproduziert.
- **Keine Versionsänderung.** Die Reparatur ist Commit `87bb83b`:
  - `scripts/gradle/lumo-maven-central-mirror.init.gradle` stellt nur auf CI den offiziellen Google-Spiegel von Maven Central vor die deklarierten Repositories.
  - Die deklarierten Repositories bleiben als Rückfall erhalten.
  - Builds mit `FAIL_ON_PROJECT_REPOS` werden nicht angefasst.
- **GETESTET:**
  - Lokal: Flutter-Plugin-Build ohne Init-Skript FAIL, mit Init-Skript `BUILD SUCCESSFUL`.
  - Lokal: `scripts/tests/test_gradle_central_mirror.py`, 4 Tests PASS.
  - CI-Lauf 38909874763, `apk`-Job **SUCCESS**: `verifyLumoSplitVersionCodes` BUILD SUCCESSFUL in 1m 57s, `assembleRelease` 226 s.
  - Gebaut wurden zwei APKs:
    - arm64: `5324e0cd1396c7450328f0362a221bb43038023c40cec12641e6b224f9bef87b`
    - x86_64: `c31c6ac4e2b1b5e27501e14b3dc7c42eda1e8f7e98fed3c01082b814f8834315`
  - Zertifikat `a6b1ef61…0702`, Version 0.12.49+1957, Godot `b5f19890`.

## 3. M0.2 – strenge Android-Tour (lumo-lernen)

Commits:
- `dc07622`: `tools/android_qa/kart_tour_evidence.py` + Tests mit echten Android-Aufnahmen.
- `2a4c8b5`: `.github/probes/modernization_android_tour.py`.
- `fe6d543`: Onboarding-Wartezeit.

Die Tour verlangt jetzt:
1. APK-Identität (SHA, Commit, Godot-Pin, Zertifikat, Version).
2. 5 echte Garage-Taps.
3. Nicht leeres 3D-Bild statt Garage.
4. Laufende Rennuhr aus der vom Spiel gespeicherten Session.
5. HUD „RUNDE“.
6. GAS halten bewegt Welt und gespeicherte Strecke.
7. Pause mit eingefrorener Session.
8. Echte Flutter-Rückkehr.
9. Unveränderter Lernstand.
10. Lernen bedienbar.
11. Neustart erhält den Lernstand.

- **GETESTET (lokal):** 639 `tools/android_qa`- und 124 `scripts/tests`-Tests PASS.
- **CI 38912785361 (`fe6d543`):** `verify` FAIL, weil auf dem Runner `ripgrep` fehlte. Der neue QA-Schritt ist mein Fehler. Die 3 Repair-Guard-Tests verlangen echtes `rg`; alle 639 Android-QA-Tests liefen dort grün. Die Korrektur steht im Übergabe-Commit (`ripgrep` installieren).
- **NICHT selbst nachgeprüft:** ob die Tour in diesem Branch-Stand auf dem Emulator vollständig grün ist. Laut Heinz ist sie auf PR #340 grün.

## 4. Grafik-Fortschritt Sonnenhafen (lumo-godot PR #78)

**Containerterminal mit Ship-to-Shore-Portalkran** (`scripts/games/kart_harbor_crane.gd`, eingebunden in `kart_world.gd` nach den Aussichtstürmen):
- Portalbeine auf Radgestellen und Schienen, Kreuzverbände, A-Rahmen mit Abspannungen.
- Fachwerkausleger mit 30 m Auslage, Maschinenhaus, Treppe, Warn- und Flutlichter.
- Langsam fahrende Laufkatze mit Spreader und Container: nur bei voller Detailstufe, als ein kleiner Knoten.
- Kai mit Damm zur Marina, Containerstapel, festgemachtes Feederschiff.
- 253 Teile bei voller, 109 bei reduzierter Detailstufe, alles in den bestehenden instanzierten Batches.
- Keine Kollision.
- Der Standort wird nur genutzt, wenn Kai, Schiff und Ausleger über Wasser liegen und mindestens 14 m von der Fahrbahn entfernt sind.

**GETESTET (lokal, Godot 4.6.3 offizielle Binary):**
- Neu: `kart_sonnenhafen_crane_regression` PASS.
- Bestehend, alle PASS:
  - `kart_sonnenhafen_lookouts_regression`
  - `kart_harbor_regression` (Batches/Budgets)
  - `kart_harbor_pavilion_regression`
  - `kart_sonnenhafen_water_regression`
  - `kart_world_regression`
  - `kart_courses_driving_regression`
  - `kart_physics_regression`
- Der Godot-Import ist fehlerfrei.
- Später nachgeholt, alle PASS:
  - `kart_race_continuity_regression`
  - `kart_track_detail_regression` (sechs Welten)
  - `kart_coastal_terrain_extent_regression`
  - `kart_complete_flow_regression`: echtes Menü und Touch, 16 Gates, gespeicherte Fortsetzung, Ergebnis, ACK, genau eine Belohnung. Dieser Test braucht einen echten Renderer und lief unter `xvfb-run` mit `gl_compatibility`; mit `--headless` scheitert er absichtlich an `DisplayServer != headless`. Er ist mit Kran (`61f51b9`) und ohne Kran (`b5f1989`) identisch PASS.

**Echte Renderings** (gl_compatibility unter Xvfb, identische Kameraposen):
- Vorher aus `b5f1989`, nachher aus `61f51b9`.
- Ablage in lumo-godot `docs/screenshots/sonnenhafen-crane-2026-10-17/` mit `SHA256SUMS.txt` und `poses.json`.

**OFFEN:**
- Godot-CI auf PR #78 (startet durch den PR gegen `main`) auswerten.
- Android-Gerät und FPS sind nicht gemessen.

## 5. Integrationsauftrag Godot → Flutter (nicht ausgeführt)

1. Godot-CI auf PR #78 grün abwarten.
2. Im neuesten Flutter-Integrationszweig (Linie PR #340) `config/godot-source.json` → `"revision": "61f51b9…"` setzen (volle SHA mit `git ls-remote` holen) und die Version nach Konvention erhöhen.
3. `kart_world.gd` ist **nicht** hash-gebunden. Die Bindungen in `lumo-runtime-apk.yml` betreffen `kart_island.gd` und 5 Testdateien, und die bleiben unverändert.
4. Den vollständigen Android-Workflow (1955-Tour bzw. #340-Telemetrie) laufen lassen. Rennen, Pause und Rückkehr müssen grün bleiben.

## 6. Weitere Befunde (OFFEN)

- **Veraltete Hash-Bindung:** `tools/android_qa/native_*_evidence_recovery.py` erwartet `kart_island.gd` = `0120a993…`, der Pin `b5f1989` hat `0fbc8394…`. `lumo-runtime-apk.yml` scheitert deshalb am Preflight. Die Konstanten erst nach Prüfung der Lap-/Handoff-Verträge anpassen.
- **Regel 8:** 14 von 363 `lib/`-Dateien sind von `main.dart` aus nicht erreichbar, z. B. `lumo_living_world.dart` (schon auf `main` tot), `lumo_onboarding_screen.dart` und mehrere `shared/widgets/*`. Entscheiden: anschließen oder entfernen.
- **Godot-PCK nicht bytegenau reproduzierbar:** Dieselbe Revision und Größe ergaben `dac5fe2f…` bzw. `db86919e…`.
- **M1:**
  - Im Integrationsstand enthalten: #313–#317, #324–#328.
  - Nicht enthalten:
    - #320: add/add-Konflikt in `test/cross_grade_practice_storage_hardening_test.dart`, sonst konfliktfrei. Konflikt von Hand lösen und beide Testmengen erhalten.
    - #306: Geschichten, 7 Commits, früher konfliktfrei auf `claude/integration-stories-2026-10-16` zusammengeführt.
    - #310: NVIDIA, **nur mit Heinz' Freigabe**.
    - #305: ersetzt.
    - #319: alte Linie.
- **Umgebung dieser Sitzung:** `*.blob.core.windows.net` (Actions-Artefakte), `dl.google.com` und `downloads.gradle.org` waren gesperrt. Artefakte konnten nicht geladen werden.

## 7. Aufträge von Heinz, nicht umgesetzt (budgetbedingt, ausdrücklich OFFEN)

- **Lumo-Kart-Gegner schwieriger:** Jeder will Erster werden, das Kind darf gefordert sein. Ansatzpunkte in lumo-godot:
  - `scripts/games/kart_island.gd`: `opponent_distances`, Rival-Geschwindigkeit und Gummiband-Logik, `difficulty` „gemuetlich“/„flott“.
  - `scripts/games/lumo_opponent_roster.gd`
  - `kart_powertrain.gd`
  - Vorgehen: Rival-Topspeed und Kurvenlinie anheben, Item-Nutzung und Überholversuche aggressiver machen, Gummiband nur gegen Abhängen, nicht gegen Vorbeiziehen.
  - Regression: Bei „flott“ muss mindestens ein Rivale in der Testfahrt vor einem neutral fahrenden Spieler ins Ziel kommen. Ein gutes Fahren muss weiterhin gewinnen können.
- **Andere Fahrer realistisch aussehen lassen:** Rival-Modelle und Proportionen an der Lumo-Qualität ausrichten (`lumo_rival_lineup_capture.gd` liefert echte Vergleichsbilder).
- **Parallele Agenten:** In dieser Sitzung nicht eingesetzt, weil die 6-%-Anweisung Vorrang hatte.

## 8. Nächste Sitzung – präziser Startauftrag

1. Godot PR #78: CI auswerten, die 4 offenen Rennregressionen ausführen und bei Grün mergen lassen (Heinz).
2. Pin `61f51b9` in die #340-Linie übernehmen und den vollständigen Android-Workflow laufen lassen. APK-Artefakt, SHA-256 und Tour-Screenshots melden.
3. Gegner-Schwierigkeit „flott“ umsetzen (siehe 7) und mit Regression belegen.
4. Hash-Bindung `kart_island.gd` prüfen und erneuern, damit `lumo-runtime-apk.yml` wieder läuft.
5. M1: #320 (Testdatei-Konflikt) und #306 kontrolliert übernehmen, Regel-8-Liste abarbeiten.

## 9. Reparaturgang (Sitzungsende, 17.10.)

| Reparatur | Commit | Stand |
|---|---|---|
| Godot-PR #78 (Containerkran) | `61f51b9` | **CI grün:** Lumo 3D Build (inkl. Android), Kart Stage 2, Video Reference Grade |
| `ripgrep` im QA-Schritt | `71b44b5` | 1955-Tour läuft: [38993583186](https://github.com/Ullmann27/lumo-lernen/actions/runs/38993583186), Ergebnis **offen** |
| Veraltete Hash-Bindung `kart_island.gd` (blockierte `lumo-runtime-apk.yml`) | `f3c2ca9` | Geprüft: Einzige Änderung `aebfcd7`→`8473037` ist der Log-Marker `race_world_ready`, die übrigen 5 Bindungen stimmen. 639 QA-Tests PASS. |
| Runtime-Gate für den Integrationsbranch aktiviert | `2890855` | Läuft: [38995087692](https://github.com/Ullmann27/lumo-lernen/actions/runs/38995087692) (native Regressionen, volles Rennen API 35/36, 1001-Update, verifizierte APK), Ergebnis **offen** |

**Nächste Sitzung:** beide Läufe auswerten und jeweils den ersten Fehler beheben. Der Dispatch per API war hier nicht erlaubt (403), deshalb die Push-Trigger.
