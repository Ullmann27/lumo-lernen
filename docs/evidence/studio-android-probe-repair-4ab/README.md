# Android-Prüfreparaturen: Originalbelege und lokale Integration auf 4ab

Diese zeitgebundene Belegsammlung bewahrt unveränderte Originale und die eng geprüften QA-Reparaturen. Ausgangsprodukt ist Host `4ab96666f954baf258422d6ed277fc297b7ddeef` mit Native `803e7a626ea6ef0aeeda9c37010e844033d3a8e3`. Sie enthält ausschließlich neue Dokumentationspfade; Produkt-, Test-, Fixture- und Workflowdateien werden mit diesem Manifest nicht installiert.

## Enthaltene Pakete

| Bereich | Dokumentierte Dateien vor eigenem Paketmanifest | Inhalt |
| --- | ---: | --- |
| `ocr-ci/` | 11 | Vollständiger abgeschlossener OCR-CI-Job auf a446, Originalmetadaten und unverändertes 2.613-Byte-Artefakt |
| `creative-original/` | 66 | Kuratierte Originale des fehlgeschlagenen Creative-Jobs, Quellen-/ZIPbindung, konkrete Bild- und Save-Reviews |
| `ocr-repair/` | 40 | Lokaler Originalbild-Replay, Fehlergrenzen, OCR-Diff und Quellenbindung |
| `jump-repair/` | 22 | Tatsächliches Hochformat als Ausgangsbefund, begrenzter Orientierungspatch und Rot-/Grün-Belege |
| `treasure-repair/` | 12 | Beobachtete Eingaben und Saves, begrenzter Controller-Prüfpatch und Verträge |
| `integration/open-groups/` | 11 | Nachprüfung der drei offenen Bestandsgruppen und Actionlint nach korrigiertem Importpfadaufruf |

Jedes dieser sechs Pakete enthält zusätzlich sein **unverändertes vollständiges Originalmanifest** als `original-package-manifest.json`. Diese Manifeste bleiben Quellenreferenzen und nennen teilweise ursprüngliche `.github/`, `scripts/` oder `tools/`-Ziele. **Für diesen docs-only Upload gilt ausschließlich das äußere `upload-manifest.json`.** Die insgesamt 29 Quell-/Test-/Fixtureeinträge der Einzelpakete sind ausdrücklich ausgeschlossen. Alte vorbereitete Dokumentationsziele werden im äußeren Manifest auf die neue gemeinsame Zielwurzel abgebildet; die Originalbytes werden dabei nicht umgeschrieben.

Zusätzlich sind die vier Puzzle-Rot-/Grün-/Patch-/Erhaltungsbelege, der unabhängige Puzzle-/Treasure-Review, acht ursprüngliche Root-Integrationsdateien und drei unabhängige Integrationsbelege enthalten. Die Puzzle-Korrektur beobachtet das tatsächlich sichtbare Motiv vor jedem Tipp; die gespeicherte Bedingung `count=6`, `motif=1`, `rotation_enabled=true` und die späteren Dreh-/Drag-/Save-Prüfungen bleiben erhalten.

## Tatsächliche Ergebnisse und ihre Grenzen

Der originale Creative-Job **132269951369** aus Run **43530667812** bleibt **FAIL**. Sein Build-Bereich bestand; Jump, Puzzle und Treasure erhielten im Original keinen vollständigen PASS. Die konkrete Puzzle-Vorbedingung scheiterte an einer veralteten Standardmotivannahme der Probe. Diese Sammlung enthält keine nachträgliche Umdeutung des Originalergebnisses.

Der abgeschlossene OCR-CI-Job **132285430053** aus Run **43542310963**, QA-Quelle **a446f3c1a320ad5297e17606727d801c5e993ce1**, belegt **12 Caption-Tests und 17 Binder-Tests**, jeweils ohne Skip, mit tatsächlichem **Tesseract 5.3.4** sowie `deu` und `eng`. Vier Caption-Fälle verwenden unveränderte Originalbilder. Das ist ein OCR-/Vertragsnachweis und keine Android-Tourabnahme.

Die lokale zusammengeführte QA-Fassung wurde getrennt geprüft:

| Gruppe | Unverändertes Rohresultat |
| --- | --- |
| Root: Scripts-Reparaturverträge | 79 PASS |
| Root: beobachtete Puzzle-Menüauswahl | 6 PASS |
| Root: reale originale Caption-Replays | 12 PASS |
| Erster Root-Aufruf der bestehenden Surfacegruppe | 22 ausgeführt, 14 Importfehler wegen fehlendem `flutter_surface_readiness`-Importpfad; Originalfehlerlog erhalten |
| C: dieselbe Surfacegruppe mit vorhandenem, korrekt angegebenem Importpfad | 22 PASS, 0 Skip |
| C: bestehende OCR-Tile-Verträge | 10 PASS, 0 Skip |
| C: bestehende Dim-Caption-Verträge | 2 PASS, 0 Skip |
| C: Actionlint | Exit 0 |

Die sechs erfolgreichen lokalen Gruppen umfassen **131 unterschiedliche Tests**. Diese Zahl wird weder mit dem separaten OCR-CI-Lauf noch mit anderen CI-Suiten addiert. C hat die Quellen und die ursprünglichen Root-Protokolle vor/nach der begrenzten Nachprüfung unverändert gebunden. Es erfolgte dafür keine Produktkorrektur und kein neuer Android-/Godotlauf.

## Bewahrung und Veröffentlichung

Die 526.570.745-Byte-Creative-Original-ZIP ist hier **nicht** enthalten. Ihr fester SHA256 bleibt `bd1660a6032c9adba051f209ab3979ea1888d03ffeb902bd0403d3f813a61d40`; eine getrennte Archivierung bewahrt das vollständige Original. Bereits veröffentlichte API35-/API37-/Update-Pakete werden nicht erneut aufgenommen. Die spätere Android-Matrixauswertung und neue Cards-Befunde erhalten eigene Belege.

Für diese Zusammenstellung wurden nur Manifeste und diese kleinen Stagingnotizen neu geschrieben. Bilder und Originalprotokolle bleiben an ihren bestehenden lokalen Pfaden; es wurden keine großen Dateien kopiert, keine vorhandenen Belege überschrieben und keine Gitoperationen ausgeführt. Alle ausgewählten Dateien wurden gegen ihre Paket-Hashes geprüft. Alle neuen Zielpfade sind gegen die 4.495 veröffentlichten Blobpfade von Evidenzcommit `4c4bc5182390fc8da2f0e94324c0398596817d81`, Baum `8ea6754303811e1f55ad0a4a200d0680944ec6bd`, kollisionsfrei.

`package-index.json` hält die Originalpakete, ausgelassenen Quellreferenzen und Grenzen fest. `upload-manifest.json` ist die alleinige explizite Uploadliste mit lokalen Originalpfaden, neuen Repositorypfaden, Größen, SHA256, Git-Blob-ID und Modus. Das äußere Manifest selbst ist als zusätzliche Dokumentationsdatei aufgeführt, ohne eine unmögliche Selbsthash-Referenz zu erzeugen.
