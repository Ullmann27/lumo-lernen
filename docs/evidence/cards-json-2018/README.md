# Cards: weiße Zahlenkarten nach Android-JSON-Transfer

Der tatsächliche Android-Lauf mit Native `51fb026f0b0e7a43b3aad30cc0fcdc144050c724` zeigte weiße Hand- und Ablageflächen, während Kartenrückseiten und Original-Lumo sichtbar texturiert waren. Beide Originalbilder `11_cards_real_table_before_draw.png` und `12_cards_real_table_persisted_draw.png` wurden angesehen. Der Desktop-Capture `cards-table-412x915.png` derselben Native-Fassung zeigte die korrekten Zahlenkarten mit direkt übergebenen Integer-Fixtures.

## Nachgewiesene Ursache

Die produktive `_poll()`-Funktion liest Flutter-Daten durch `JSON.parse_string`. Godot 4.6.3 dekodiert JSON-Zahlen als `float`; `str(5.0)` ergibt `"5.0"`. `_texture()` verwendete dies unverändert im Dateinamen und suchte beispielsweise `green_5.0.png`. Diese Datei existiert nicht. `ResourceLoader.exists` liefert false, `_texture()` liefert null und das tatsächliche Plane-Material bleibt ohne Albedo-Textur weiß.

Der unveränderte Quellstand wurde per GitHub-Dateiabruf des exakten Native-Commits verifiziert: Git-Blob `26c10c9da7f8795dac9322f26ef8dced8a29f068` entspricht dem lokalen Stand vor der Reparatur. Produktive Stellen: `scripts/games/cards/cards_table.gd`, `_poll()` um Zeile 619, `_texture()` um Zeile 698, Materialbindung um Zeile 735.

Mit der tatsächlichen Android-Mailbox `cards-mailbox-009-state.json` wurden die sichtbaren Karten Rot 3, Grün 1, Blau 6 und Ablage Grün 5 durch die unveränderte produktive `_texture()` aufgelöst. Alle vier ergaben zuvor null. Die grüne Ablagekarte mit demselben Wert als Integer lud sofort `green_5.png`; Sonderkarte und Rückseite luden ebenfalls. Nach dem Fix laden alle vier unveränderten JSON-Karten ihre richtigen Originaltexturen. `before.log` und `after.log` sind echte Godot-Ausgaben, keine simulierten Testergebnisse.

Ein SubViewport ist in diesem Kartenpfad nicht beteiligt. Das tatsächliche Android-Log meldet ausdrücklich `gl_compatibility`, OpenGL ES 3.1 und Android Emulator OpenGL ES Translator / llvmpipe. Der Fehler ist bereits vor dem Renderer als falsche Ressource nachgewiesen; ein Mobile-Vulkan-Unterschied erklärt diesen Befund nicht.

## Begrenzte Reparatur

- `cards_table.gd`: ausschließlich Umwandlung `str(int(card.get("number", 1)))` für nummerierte Assetnamen plus erklärender Kommentar. Spielregeln, Speicherformat, Layout und Materialparameter bleiben gleich.
- `cards_table_regression.gd`: alle vier vorhandenen Format-/Touch-/Ablaufprüfungen nutzen jetzt einen echten JSON-Roundtrip. Alle 40 Zahlentexturen (vier Farben, 0–9) müssen auf die korrekten Originalassets auflösen. Zusätzlich werden die tatsächlich an jede sichtbare Handkarte und die Ablage gebundenen Plane-Materialien geprüft.
- `cards_table_capture.gd`: die vier vorhandenen Rendererbilder verwenden ebenfalls JSON-Roundtripdaten; fehlende oder falsche Hand-/Ablagetexturen führen vor dem Bildnachweis zum Fehler. Das Capture-JSON dokumentiert diesen Vertrag.

## Tatsächliche Prüfungen

| Prüfung | Vor Reparatur | Nach Reparatur |
|---|---:|---:|
| Native Cards-Regressionslauf einschließlich neuer JSON-Verträge | 208 Prüfungen, 44 Fehler, Exit 1 | 208 Prüfungen, 0 Fehler, Exit 0 |
| Echte Android-Mailbox, produktive Texturauflösung der vier sichtbaren Zahlenkarten | viermal null | vier richtige Originaltexturen |
| Capture-Skript, Godot `--check-only` | nicht erneut geprüft | Exit 0 |
| Neue Rendererbilder nach Fix | — | zum Zeitpunkt dieses Berichts noch offen |
| Neuer Android-Build und Spielrunde nach Fix | — | zum Zeitpunkt dieses Berichts noch offen |

Die neuen Tests wurden zuerst gegen den defekten Quellstand ausgeführt und scheiterten wie erwartet; erst danach erfolgte die Ein-Zeilen-Reparatur. Der lokale Versuch des echten Xvfb-Capture-Kommandos scheiterte mit Exit 127, weil `xvfb-run` hier fehlt. Es existiert hier kein DISPLAY und kein X11-Socket. Dafür wird kein Render-Erfolg behauptet. Vorhandene Desktopbilder belegen den alten direkten Fixture-Pfad und gelten ausdrücklich nicht als Nachweis des neuen Fixes. Die reguläre native CI und anschließend der Android-Kandidat müssen die neuen Bilder erzeugen.

## Reproduktion

Vom Root des Godot-Projekts mit Godot 4.6.3:

```sh
godot --headless --path . --script docs/evidence/cards-json-2018/reproduce_cards_face.gd
godot --headless --path . --script scripts/tests/cards_table_regression.gd
godot --headless --path . --check-only --script scripts/tests/cards_table_capture.gd
xvfb-run -a -s '-screen 0 2560x2560x24' godot --path . --rendering-method gl_compatibility --audio-driver Dummy --script scripts/tests/cards_table_capture.gd -- --output=/tmp/cards-json-capture
```

`mailbox-card-faces.json` enthält unverändert nur die Hand- und Ablagekartendaten der tatsächlichen Android-Mailbox, ohne Sitzungskennung oder Profilinformationen. `proof.json` enthält Quell-/Eingabe-/Log-Hashes und trennt die tatsächlich ausgeführten Prüfungen von den noch ausstehenden Renderer-/Androidprüfungen.
