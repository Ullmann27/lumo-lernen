# Spielwelt – Bestandsaufnahme und Plan (2026-10-07)

Quelle: Auftrag von Heinz. Die Bildtafeln (Spielwelt-Übersicht, Cards, Rhythm Party,
Jump & Run, Bauwelt, Kart-Strecken) liegen **nicht** im Repo
(`docs/design_targets/2026-10-04/` enthält nur Home, Lernen, Tests, Profil, Kart-HUD/-Menü,
Fold). Die Beschreibungen unten stammen deshalb aus dem Auftragstext, nicht aus gesehenen Bildern.
Bildgleichheit wird nicht behauptet. Status: VISUAL_GAP / NOT FINISHED.

## Bestand im Repo
| Spiel | Status |
|---|---|
| Memory | `lib/features/games/memory/` vorhanden |
| Cards | `lumo_cards/` spielbar (Bot, Pause, Spielstand speichern seit 7c531f6) |
| Jump & Run | `flame/lumo_jump_game.dart` vorhanden |
| Puzzle, Rhythm Party, Schatzsuche, Bauwelt | kein Code, keine „Bald“-Kachel im Repo gefunden |
| Lumo Kart | Godot-Repo, hier nicht baubar (kein Godot) |

## Regeln je neues Spiel (aus dem Auftrag, verbindlich)
- **Puzzle:** Drag-and-drop, einstellbare Schwierigkeit, Hilfe, Belohnungssterne.
- **Rhythm Party:** Taktfelder; Noten Tap, Halten, Stern, Slide, Kreis; Treffer-Bewertung;
  Combo-Zähler; 3 Stufen; Soundfeedback.
- **Bauwelt:** Bausteine setzen, drehen, einrasten, entfernen, Rückgängig, Speichern/Laden,
  Kamera Orbit/Zoom/Pan.
- **Schatzsuche:** Rätsel, Hinweise, Schatztruhen.
- Kart: keine Lernfragen während der Fahrt. Lernfortschritt schaltet Spiele frei.

## Gemeinsamer Stil
Nachtblau mit Mond, Sternen, Laternen; Cyan-/Gold-Konturen; runde Glaskarten; orange
Lumo-Fuchs mit cyan Schal; runde, fröhliche Schrift.

## Blockiert / Anforderungen
- ASSET_REQUEST (an Issue #177): Rohbilder aller Tafeln mit Manifest (Name, Zweck, Zielpfad,
  Größe, SHA-256, Herkunft). Ohne Quelle keine Zerlegung mit Alpha.
- BLOCKED_3D_ASSET: Lumo mit Skelett und Animationen (Idle, Laufen, Springen, Tanzen, Jubeln),
  Bausteine, Karts, Streckenmodule, Bühnen als glTF 2.0. Kein Modellier-/Rigging-Werkzeug
  in dieser Umgebung.
- Godot 4.6.3 und Android-Gerät fehlen: Renderer-Vergleich (Mobile/Vulkan vs. Compatibility),
  ASTC, Frame-Zeiten = NOT EXECUTED.

## Reihenfolge
Puzzle (reines Flutter, ohne 3D) → Schatzsuche → Rhythm Party → Bauwelt (3D-pflichtig).
Freischaltung erst, wenn der Kernablauf funktioniert.
