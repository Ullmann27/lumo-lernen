# Opus-Handoff / Limit-Wechsel (Stand 5. Oktober 2026)

## Checkpoint
- Branch: `copilot/checkpoint-sichern-opus-5-5`
- CURRENT SHA: `eae063e015810935e33f08d235a4ea1f654b856b`
- BASE SHA: noch offen. Der letzte Opus-Stand ist nur über den Testzweig `codex/opus-86c5a33-test-apk` (Commit `86c5a33`) belegt; vor dem Handoff mit `git merge-base` gegen CURRENT bestimmen.
- Letzte Commits: `eae063e` Lesen/Schreiben Klasse 1–4, `91bd25b` Fold-Hard-Gate-Nachweis, `89bebcb` 3D-Spielbretter/Modell-Lanes, `f47182a` PR #182.
- Nicht gepushte lokale Opus-Arbeit ist nicht sichtbar. Opus muss sie vor dem Limit pushen oder nennen. Nichts überschreiben, kein Force-Push.

## Offene PRs (Writer-Koordination)
Aktuell: #193 Asset-Prompts, #192 Fold-Shell, #187 Aufgaben-Abenteuer, #186 Design Start/Lernen/…, #185 Mathe-Lehrplan, #183 Design-Tafeln (142 WebP), #179 Home-Lesbarkeit, #168, #167, #154, #153. Ältere PRs (#1–#150) sind vermutlich veraltet und vor Nutzung zu prüfen.
Regel: pro Aufgabe ein Branch, CLAIM mit Basis-SHA und Dateiliste; keine Datei hat zwei Writer.

## Prüfstand (nicht neu ausgeführt)
- `flutter analyze` / `flutter test`: in diesem Lauf NICHT ausgeführt. Vor jeder Erfolgsaussage neu laufen lassen.
- CI zuletzt gelesen: Run 37310376050 „Opus handoff Kart regression“ auf `codex/opus-86c5a33-test-apk` = **failure** (offene Kart-Regression). Run 37310217544 „Build unified Lumo Android APK“ lief noch. Change-review auf PR #193 = success.
- Godot-/APK-Prüfung: Engine nicht lokal vorhanden; Flutter 3.44.9 ist installiert, Godot 4.6.3 vor dem Bau gegen die Konfiguration abgleichen.

## Offene Lücken (aus docs/)
- Kart: Referenzniveau, frei fahrbare Fahrzeugphysik, weitere Strecken, ARM-FPS offen (`UNIFIED_ANDROID_2026-10-03.md`).
- Kein Test auf echtem Galaxy Z Fold, keine Handy-FPS, keine hörbare TTS-/Mikrofon-/Kameraprüfung.
- Fuchs ohne vollständiges 3D-Skelett/Phonem-Abgleich; Online-Tutor nicht aktiv (Provider-Kontingent).
- Bildwidersprüche: untere Leiste k08/k01 vs. k09, „LIMO KART“ muss LUMO KART heißen (`DESIGN_ZIEL_KART_2026-10-04.md`).
- Originalbilder-Vergleich: ohne Sicht auf Originale keine Gleichheitsbehauptung.

## Aufteilung
- **Sonnet 5.5:** Flutter, Lehrerbereich, Lernlogik, Memory/Cards/Puzzle, responsive UI, Godot-Szenen, Gameplay-Grundsysteme (Strecke, Kollision, Finish, HUD, Checkpoints, Mobile Controls), Tests, normale Bugfixes.
- **Grafik:** fehlende ASSET_REQUESTs sammeln; Assets als Dateien unter `assets/`, neue Ordner in `pubspec.yaml`.
- **Candidate:** sauberen Candidate-SHA festlegen, `bash scripts/build_unified_apk.sh`, prüfen dass die APK genau diesen SHA enthält.

## Nur für Opus (Mehrwert)
1. Offene Kart-Regression (Run 37310376050) analysieren.
2. Fahrgefühl: Lenkung, Drift/Turbo, Fahrzeugphysik.
3. Kamera (Verfolger, Finish-Sequenz).
4. Schwierige Rendering-/Performance-Probleme auf ARM.
5. Visual-Fidelity gegen `docs/design_targets/2026-10-04/`.
6. Finaler Architektur-Check Flutter↔Godot (Pins, State-Handoff).
7. Echter Fold-/Gerätetest-Plan.

## Regeln (CLAUDE.md)
Build grün (`flutter analyze`, `flutter test`), kleine Commits, keine neuen Pakete ohne Grund, Bilder nur als Dateien, echte Daten statt Beispielzahlen, kein Force-Push/Merge nach `main`/Release ohne Heinz, nur geprüfte Erfolge melden, keine toten Dateien in `lib/`.
