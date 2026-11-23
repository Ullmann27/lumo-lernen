# Grafiken für Logikspiele und Lumo World

Stand: 23. November 2026.

## Logikspiele

`assets/lumo_design/spielwelt/cover_logic.webp` ist eine eigens für diesen
Arbeitsstand erzeugte dekorative Rastergrafik. Das Bild wurde mit dem verfügbaren
Bildgenerator hergestellt und auf 960 × 640 Pixel als WebP für die App
aufbereitet. Die tatsächlichen Rätselraster entstehen aus den jeweiligen
Aufgabendaten als Flutter-Oberfläche. Zahlen und Buchstaben im Titelbild sind
Dekoration und keine Aufgabenquelle.

Verwendeter vollständiger Prompt:

> Use case: stylized-concept. Asset type: landscape 3D game selection cover for LUMO children's learning app ages 6–10, matching a premium colorful adventure world, no text or logos. Build an inviting magical logic atelier in a lush little forest school: three elegant floating beveled glass puzzle boards above round dark-blue podiums, cyan edge lights, rich violet ambient reflections, fresh neon green success lines, softly glowing amber wooden architecture. One board represents a clean four-by-four mini Sudoku with a few raised numeral blocks, a second a crossword with letter blocks, a third arithmetic with small number and plus blocks. These are decorative visual motifs, not a complete solved puzzle. A single friendly orange-and-white fox explorer with blue aviator goggles and a dark navy jacket stands at the edge admiring the boards; polished appealing original stylized character with real paws, expressive eyes, plush fur, no extra characters. Premium detailed 3D animated feature render, pleasing material roughness, rounded handcrafted wood, gentle PBR glass, depth, cinematic bounced lighting, sunbeams through leaves, uplifting and calm rather than chaotic. Composition landscape 3:2 cover, puzzle group dominant in center, clear silhouettes legible at thumbnail size. No menus, no UI labels, no game logos, no dice, no casino objects, no gold coin rain, no phones, no watermark. High-quality finished bitmap art.

## Open World

Die Welt verwendet den vorhandenen Original-Lumo, die Schatzsuche-Umgebung,
das bestehende Kart und die vorhandenen Dorfmodelle. Die vier zusätzlichen
Verkehrsmodelle entstehen aus nachvollziehbarer Blender-Geometrie durch
`tools/lumo_world_art/build_world_vehicles.py` im Godot-Repository. Dort hält
`assets/creative/lumo_world/vehicles/manifest.json` Größe, Generator und
SHA-256 jedes exportierten GLB fest. Die Modelle sind Auto, Schulbus, Fahrrad
und Scooter. Das steuerbare Fahrzeug dieses Kapitels ist das vorhandene Kart.

Das Welt-Titelbild wird mit Blender aus vorhandenen Originalmodellen gerendert.
Es ist eine Kachelgrafik. Tatsächliche Spielansichten werden getrennt mit
`scripts/tests/lumo_world_capture.gd` aus dem laufenden Godot-Viewport erfasst.
Die Belege benennen Renderer, Engine, Quellstand und synthetisches Testprofil;
sie behaupten keine Messung auf einem physischen Android-Gerät.
