# Lumo Game Production Specification — 2026-10-05

Diese Ordner sind die verbindliche visuelle und technische Referenz für die neue Lumo-Spielwelt. Die Bilder sind keine bloßen Moodboards. Die Technical Boards definieren UI, Gameplay, Kamera, Animation, VFX und Asset-Sprache. Die Key-Arts definieren Stimmung, Licht, Komposition und Qualitätsziel.

## Referenzhierarchie
1. Spezifisches Technical Board des Spiels.
2. `00_master/lumo_master_asset_animation.webp` für Lumo selbst.
3. Passendes Key Art.
4. Bestehende App.
5. Eigene Interpretation.

Bei Widersprüchen hat die höhere Ebene Vorrang.

## Ordner
- `00_master`: verbindlicher Lumo-Charakter, Animation, Material, Kamera.
- `01_spielwelt`: 3D Game Hub.
- `02_memory`: Memory.
- `03_cards`: Lumo Cards.
- `04_puzzle`: Puzzle.
- `05_jump_run`: Jump & Run.
- `06_rhythm`: Rhythm Party.
- `07_schatzsuche`: Schatzsuche.
- `08_bauwelt`: Bauwelt.

## Wichtige Produktregel
Lernen ist Hauptzweck. Dauerhafter Lernfortschritt kann Spiele freischalten. Bereits freigeschaltete Spiele dürfen durch das Ausgeben von Sternen nicht wieder gesperrt werden. Im Kart keine Lernfragen, Lern-Cups, Antworttimer oder Richtig=Turbo-Mechanik.

## Keine Fake-Umsetzung
Kein Vollbild-Poster mit unsichtbaren Buttons, keine PNG-Straße als 3D-Geometrie, kein statischer Lumo-Sprite als frei drehbarer 3D-Charakter. Für echten Orbit/3D ist ein geriggtes 3D-Modell mit Skeleton und Animationen erforderlich. Fehlt es, offen als Blocker melden.

Siehe `00_master/MASTER_IMPLEMENTATION_PROMPT.md` und `00_master/MODEL_ROUTING_COPILOT_PRO.md`.
