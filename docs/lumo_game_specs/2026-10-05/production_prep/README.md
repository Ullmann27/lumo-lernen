# Lumo: grafische Produktionsvorbereitung

**Vorbereitung, nicht fertige Spiele und kein Release.** Ergänzung zu den bereits vorhandenen neun Technical Boards, acht Key-Arts und `00_master/MASTER_IMPLEMENTATION_PROMPT.md`. Keine zweite App, Engine oder Figurenimplementierung.

## Tatsächlich geprüfte Ausgangsstände

- Flutter main: `89bebcb09995a6eed64038c5445c33a08f8eca5c`.
- Godot main: `ee4d932e59cf304c3ff249631a1f8133dbba2079`.
- Separater Kart-PR #4: `a369da2dc208fcd9d5451c7007d8b1f9e7bf52a1`.
- Design-PR #186: `0850158b2907418e73173a783ad51d1fd1d09657`.
- Aufgaben-PR #187: `d7282f35a5355612278582beacbfe7fd5cda8e11`.

Diese Stände sind eine Momentaufnahme. Vor jedem Schreiben aktuelle Heads, neue Kommentare und CLAIMs in #170 und den Lane-Issues lesen. Branch-Inhalt ist nicht automatisch in main enthalten. Die bestehenden #183–#187 nicht blind zusammenführen. Die gemeinsame `lib/features/learning/learning_content.dart` aus #186/#187 muss unabhängig geprüft werden.

## Befunde aus gelesenen Quellen

| Quelle im Godot-Kandidaten | Tatsächlicher Befund | Konsequenz |
|---|---|---|
| `scripts/games/kart_vehicle.gd`, Blob `716c649c6ff42563a741cfd7169c3c0de3797837`, Anfang/Companion-API | Echte prozedurale 3D-Geometrie, Gelenklisten, `configure_companion`, `set_companion_pose`; Atmung, Blinzeln, Arme, Beine, Ohren, Schwanz, Kiefer | Nicht behaupten, es gäbe überhaupt kein 3D-Modell. Bestehende technische Arbeit erhalten. Das beweist noch keine referenztreue Figur oder hochwertige Deformation. |
| `scripts/characters/lumo/lumo_character_controller.gd`, Blob `0e7a6bc3b5c63408ad13c4b35edd62425ccf99b8` | Bestehende öffentliche API für Verhalten, Augen, Brauen, Mund und Sprechen; ausdrücklich austauschbares Visual vorgesehen | Adapter an diese API anschließen, nicht alle Aufrufer neu schreiben. |
| `scripts/characters/lumo/lumo_behavior_controller.gd`, Blob `b8ef1a5b4d3f8212a7fc3988c63075f2ba060521`, Anfang/Verhaltensauswahl | Aliase und Tween-basierte Bewegungen vorhanden | Bestehende Zustände erfassen; `jump_hop` nicht als fertige Luft-/Fall-/Landungssequenz ausgeben. |
| `scenes/characters/lumo/lumo_character.tscn`, Blob `6244b2a134e1f385bd77f8ec21c1b2d72557bb05`, Ressourcen/VisualRoot | Primitive Mesh-Ressourcen und violettes Hoodie-Material | Die neue Bildreferenz zeigt Cyan-Halstuch/Rucksack. Konkrete Art-Lücke, kein Beweis eines in diesem Lauf gemessenen Darstellungsfehlers. |
| `scripts/games/jump_islands.gd`, Blob `910597998214b64caddb9dee7f96fd739f82f610`, Anfang/Weltaufbau | Lädt die vorgenannte Figur, CharacterBody3D, echte Plattformkollisionen, Coyote-/Jump-Buffer-Felder; heller Tageshintergrund; Lernfragenzustände | Keine neue Jump-Engine anfangen. Nachtwelt-/Figurenlücken isoliert bearbeiten. Die vorhandenen Jump-Lernfragen sind ein gesonderter Produktabgleich, nicht still löschen; Kart-Lernfragen bleiben verboten. |

Quelllektüre ist kein Laufzeittest. In dieser Vorbereitung wurden Godot, Flutter, Blender und Fold7 nicht ausgeführt. Es wurde kein vollständiger Repository-weiten GLB-/Skin-Audit behauptet.

## Die Bilder richtig verwenden

Die lokal verfügbaren **17 Original-PNGs** sind vollständig dekodiert und gehasht. Alle sind **RGB ohne transparente Pixel**. Es sind neun statische Boards und acht statische Key-Arts: weder Animationen noch Skinned Meshes, Texturatlanten oder reale Runtime-Aufnahmen. Aufdrucke wie „RUNTIME MOCKUP“ ändern das nicht.

`source_inventory.json` ordnet die Originale den bereits vorhandenen WebP-Referenzen im Repository zu. Unterschiedliche Encodings haben unterschiedliche Hashes; der Original-PNG-Hash gilt nicht für das WebP. Die Originale bleiben bytegleich. Zwölf separat zugeschnittene Detailreferenzen werden durch `crop_manifest.json` dokumentiert; sie sind ebenfalls **keine freigestellten Spielobjekte und keine Animationsframes**.

**Priorität:** verbindliche Produkt-/Sicherheits-/Persistenzregeln, dann Master-Charakter für Identität, jeweiliges Board für visuelle Anordnung, Key-Art für Atmosphäre. Beispielzahlen, Preise, neue Währungen, Lebensanzeigen oder Schaltflächen in generierten Bildern sind keine genehmigte Geschäftslogik. Texte/Labels als echte UI setzen. Keine Pixelgleichheit zwischen einem ganzen Beschriftungsboard und einem andersformatigen Spielfenster vortäuschen.

## Werkzeuge statt weiterer Gesamtplanung

`visual_tools.py` arbeitet ohne Netzwerk und ändert keine Produktionsdatei:

```sh
python -m unittest -v test_visual_tools.py
python visual_tools.py verify <paketwurzel> <paketwurzel>/PACKAGE_MANIFEST.json
python visual_tools.py verify <repo>/docs/lumo_game_specs/2026-10-05 <repo>/docs/lumo_game_specs/2026-10-05/manifest.json
python visual_tools.py compare <zielpanel.png> <echter_screen.png> <neuer_ausgabeordner> --source-sha <40-stelliger-SHA> --runtime-kind android
python visual_tools.py glb <tatsaechliche_datei.glb>
python visual_tools.py pack <paketwurzel> <paketwurzel>/PACKAGE_MANIFEST.json <neuer_paketordner> --max-bytes 28000000
```

Python >= 3.10 und Pillow für Bildoperationen. Abhängigkeiten nicht still in App/pubspec/CI eintragen. Vergleich erhält die Seitenverhältnisse, schneidet nichts heimlich ab und vergibt **keinen automatischen Visual-PASS**. Herkunftsangaben eines Screens sind ausdrücklich vom Aufrufer angegeben, nicht vom Tool authentifiziert. GLB-Funktion liest Header/JSON-Inventar; sie ersetzt weder Khronos-Validator noch Engineimport, Skin-/Animations-/Lizenzprüfung. Ein prozedurales Modell braucht diese GLB-Funktion nicht.

Pakete sind eigenständige ZIP-Dateien unter 28.000.000 Bytes, keine `.z01`-Teilarchive. Alle in denselben lokalen Ordner entpacken. `REFERENZEN.html` ist eine lokale **Referenzbibliothek**, keine App-Vorschau. PNGs werden nicht künstlich verkleinert oder inhaltlich ergänzt.

## Nächste Arbeit

`WORK_ORDERS.md` enthält die abgegrenzten Aufgaben für Sonnet, Luna/Codex und später Opus. `render_contract.json` enthält aufzunehmende Zustände, Sichtprüfungen und fehlende Belege. Der nächste praktische Schritt ist eine reale Vergleichsszene mit vorhandener Figur und dokumentierten APIs — nicht noch ein allgemeines Design-Moodboard.

Keine neu gestartete Modell-Session durch dieses Paket. Die exakte Profil-/Modellwahl muss belegt sein; Auto bleibt ausgeschlossen. Kein Schluss, ein Modell sei generell besser als Opus. Qualität wird am abgegrenzten Ergebnis geprüft.
