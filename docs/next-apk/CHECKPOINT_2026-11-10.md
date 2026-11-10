# LUMO nächste APK – Checkpoint 2026-11-10

Stand: 2026-11-10, Europe/Vienna. Lead: Lumo · Spiele. Kein Merge nach main ohne Heinz.

## Basis
- Flutter: `integration/lumo-2006-native-pin-review-20261105` @ 9f5b47b3973d6c4f3ff180f269624603c1698ecd (0.12.99+2011)
- Godot-Pin: `integration/lumo-2006-native-20261103` @ a81ddf12d594cc252caef7503162e89c6b26e1c7
- Zielversion: 0.13.0+2012 (noch nicht gesetzt)

## Arbeitszweige (lumo-godot, alle Draft, nicht gemergt)
- `lumo-next/kart-integration-20261110` – PR #134: #131 + Stunt-Zweig integriert, Sonnenhafen-Generation; in Arbeit: Physik, KI (Entdecken/Abenteuer/Sternen-Profi), Items, Garage, Kart-Lenktest-Flake
- `lumo-next/design-worlds-20261110` – PR #133 (Lumo · Design): Bauwelt (MultiMesh, Draw Calls high 2641→239), Puzzle-Atelier, Rhythm Party, Schatzsuche; Presets in `scripts/systems/render/lumo_environment_creative_presets.gd`

## Dieser Zweig (lumo-lernen)
- `lumo-next/integration-20261110` = 9f5b47b3 + diese Doku. Hier werden Godot-Pin und Version für 2012 angehoben, sobald die Godot-Zweige geprüft zusammengeführt sind.

## Geprüft (nur tatsächlich gelaufen)
- `flutter analyze` (CI-Flags) Exit 0; `flutter test` 2055 bestanden, 0 fehlgeschlagen, 172 übersprungen
- Probe-Build (Kette, kein Release): Paket `dev.ullmann.lumo.lumo_lernen.coachpreview`, 0.12.99+2011, Zertifikat-SHA-256 a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702, APK-SHA-256 a7891f90e483a94d6724e3e0d1a4197c47cffe7fe214f3ad1a469f1bf4a36ad3
- Nicht geprüft: Android-Emulator (in Arbeit), Fold7, Veröffentlichung

## Offen
- 11 weitere Kart-Strecken (warten auf Handoff-ZIP mit Streckenpaketen 2026-11-04/-06)
- Lumo-Lernen-Optikpass (ohne Schreibtrainer/Journal)
- Wolkeninseln, restliche Kreativwelten
- Presets an LumoEnvironment.apply() anschließen
- Godot-Pin anheben, Version 0.13.0+2012, alle Gates, ARM64-APK, Emulator-Updatetest von 2004
