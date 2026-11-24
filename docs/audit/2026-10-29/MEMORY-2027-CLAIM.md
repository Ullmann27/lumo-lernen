# Lumo Memory 2027 – isolierter Entwicklungsclaim

- Repository: Ullmann27/lumo-lernen
- Bearbeiter: ChatGPT (Fortsetzung nach Opus-Limit, keine Übernahme ungesicherter Agentenarbeit)
- Branch: `chatgpt/lumo-2027-memory-stage-20261029`
- Ausgangspunkt: `release/lumo-2003-family-button-20261029` @ `5457b2ee1615c693009cf17e7b3dc2d1e5e88ac0` (Build 2003)
- Begründung: Opus' Koordinationsdokument nennt Memory als noch nicht begonnen. Hier wird ausschließlich eine **vorwärtskompatible, isolierte grafische** Verbesserung umgesetzt.

## Geänderte Pfade

- `lib/features/games/memory/lumo_memory_stage.dart` – statische, zustandslose 2.5D-Tischgeometrie (Flutter CustomPainter), mit `IgnorePointer`.
- `lib/features/games/memory/lumo_memory_game.dart` – nur die vorhandene Board-Oberfläche mit dem neuen Layer verbinden und den Farbverlauf der Kartenrückseiten verfeinern; keine Änderung an Spielregeln, Datenmodell, Profileinstellungen oder Aktionen.
- `test/games/memory_2027_stage_test.dart` – sichtbarer Stage-Layer und ungestörte Kartenbedienung auf Fold-Deckblatt, Fold offen und Querformat.
- `docs/visual/2026-10-29-2027/memory/HANDOFF.md` und dieser Claim – dokumentierte unabhängige Übernahme.

## Sicherheitsgrenzen und Abnahme

- Keine Änderungen an `main`, der Release-Freigabe, `config/godot-source.json`, dem Schreibtrainer, Journal, KI-Gehirn, Elternbereich oder Kart.
- Keine neue Abhängigkeit, keine neue 3D-Engine, keine erfundenen GPU- oder Fold7-Messwerte.
- Die Bühne ist eine gezeichnete **2.5D-Illusion, kein echtes polygonales 3D**.
- Painter arbeitet ohne Ticker und ohne Touch-Ereignisse; dieselbe Darstellung auch im Ruhemodus.
- Bestehende Regressionen: `test/games/memory_screen_test.dart`, `test/games/memory_match_feedback_test.dart`. Neue Regression: `test/games/memory_2027_stage_test.dart`.
- Tests und CI erst als bestanden angeben, wenn reale Protokolle vorliegen.
- Integrationsreihenfolge: erst isolierter Flutter-Check, dann eventuell in künftigen Haupt-App-Build übernehmen. Ungepushte Opus-Änderungen nicht überschreiben.

## Resultat / Übergabe

Implementierung in separaten Commits gesichert; endgültige Freigabe hängt von GitHub-CI ab. Nicht selbst auf einem Android-Gerät getestet. Keine neue APK gebaut oder veröffentlicht. Keine Integration nach `main` oder in das unveränderliche Release 2003 durchgeführt.
