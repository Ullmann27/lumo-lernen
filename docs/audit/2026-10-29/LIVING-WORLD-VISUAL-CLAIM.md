# Arbeitsclaim: Operation Living World (visuelle Spur)

- **Agentenprofil / Modell-Spur:** Claude Opus 5.5, visuelle Spur (Darstellung,
  Interaktion, Animationszustände) laut Heinz' Auftrag „Operation Living World“
  vom 29.10.2026.
- **Basis:** `feat/lumo-tutor-brain-2001-20261028` @
  `9fdfc3f17e640ade0912411167d4af2f73be8720` (0.12.89+2001, Sols Tutor-Arbeit).
- **Branch:** `claude/lumo-living-world-visual-20261029`.

## Arbeitsteilung (verbindlich)

Sol verantwortet Lernlogik, Lösungskontrolle, Lernhistorie und didaktische
Auswahl. Opus verantwortet Darstellung, Interaktion und Animationszustände.
Es gibt keine zweite Kompetenzdatenbank und keine eigene Bewertungslogik.

## Neue Dateien (nur Opus)

- `lib/features/learning/scenes/**`: Lernszenen-Vertrag, Szenen-Renderer
- `lib/widgets/fox/living/**`: lebendiger Original-Lumo (Gitter-Rig, Zustände)
- `test/scenes/**`, `test/fox_living/**`
- `docs/visual/2026-10-29-living-world/**`
- `docs/audit/2026-10-29/LIVING-WORLD-VISUAL-CLAIM.md` (diese Datei)

## Geänderte vorhandene Dateien

- `lib/features/learning/widgets/lumo_place_value_blocks.dart`: entfernt
  (Nachtrag 29.10.).
  - Nur die alte Werkstatt-Darstellung hatte es benutzt; ohne sie wäre es
    toter Code (Regel 8).
  - Ersatz ist `scenes/place_value/place_value_material.dart`.
  - Die Datei lässt sich aus der Git-Historie zurückholen.
- `LumoPlaceValueWorkshop` bekommt zusätzlich `sounds` (Standard `false`);
  die API wird nur erweitert, nichts fällt weg.
- `lib/features/learning/widgets/lumo_place_value_workshop.dart`:
  - Nur die Darstellung ändert sich.
  - Unverändert bleiben öffentliche API (`number`, `reduceMotion`,
    `onTransferChecked`, `numberForPrompt`, `LumoPlaceValueTransfer`),
    Widget-Schlüssel, Texte und Regeln.
  - Sols Regeln wandern 1:1 in einen reinen Dart-Szenendirektor.
  - Akzeptanz: Sols Tests `test/learning/lumo_place_value_*_test.dart` laufen
    unverändert grün.
- `lib/core/lumo_sound.dart`, `lib/core/lumo_asset_paths.dart`: nur additiv,
  für neue dezente Werkstatt-Töne.

## Ausdrücklich nicht berührt

- Sols Kern:
  - `lib/core/tutor_coordination_engine.dart`
  - `lib/widgets/fox/lumo_companion_requests.dart`
  - `lib/core/learning_journey.dart`
  - `lib/app/app_state.dart`
  - `lib/core/lumo_personal_daily_tutor_planner.dart`
  - `lib/features/learning/learning_content.dart`, solange nicht neu geclaimt
- Schreibtrainer, Journal, Lumo Kart (`lumo-godot`), Release-Workflows,
  Signatur, `pubspec.yaml`-Version, `main`.

## Akzeptanz

- `flutter analyze` ohne Fehler; volle Flutter-Suite ohne Fehlschläge.
- Sols Werkstatt- und Tutor-Tests unverändert grün.
- Echte gerenderte Flutter-Aufnahmen; keine Konzeptbilder.
- Ein Claim endet nur mit Ergebnis-SHA, geänderten Dateien, Testzahlen,
  NICHT AUSGEFÜHRT-Liste und nächster Review-Spur (Sol: Szenendirektor-Regeln).
