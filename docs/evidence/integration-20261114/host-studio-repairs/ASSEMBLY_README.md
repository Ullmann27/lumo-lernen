# Host-Studio: belegte Zwischenstände für den Anschluss

**Zusammenstellung, keine neue Produkt- oder Releasefreigabe.** Dieses Paket enthält 17 eingefrorene Reparatur-/Reviewpakete, vier unveränderte kompakte Originalarchive sowie gesonderte spätere Root-Sichtungen und Folgebelege. Ein endgültiger gemeinsamer Prep-Quellenstand wird hier nicht behauptet. Native-Pin, neue Visual-Receipts und aktuelle Android-Abnahmen stehen noch aus.

## Quellen und tatsächliche Ergebnisse

| Nachweis | Gebundene Quelle | Ergebnis und Grenze |
|---|---|---|
| Main848, Run43515640224 | Host84865ce2, Tree400830eb, Native993c | **FAIL**. Build/Compile erfolgreich. API35 und Update scheitern am nicht beobachteten Garage-Rückweg; API37 am bereits vor Lumo aufgetretenen System-ANR. Verifier/Publisher übersprungen. |
| Creative d2c, Run43519068565 | QA d2c4589a, APK51e92fb5, Native993c | **FAIL**. Build ist ein begrenzter Teil-PASS; Jump, Puzzle und Treasure scheitern. Keine Übertragung auf Host848 oder spätere Native-Quellen. |
| Gemeinsame lokale Python-Suiten | 1.346 unveränderte Pfade des damaligen uncommitteten Prep-Stands | **FAIL**: 557 Scripts-Tests mit 3 FAIL + 2 ERROR; 870 Android-QA-Verträge PASS, keine Skips. Originale und Diagnose bleiben unverändert. |
| Root-Bildreviews | Originale der gescheiterten Läufe sowie getrennte ältere ee97-Frames | Diagnose, kein aktueller17f5- oder Android-Nachweis. |

Beim Update wurde vor dem Fehler ein tatsächlicher Installationswechsel mit geschützten Lern-/Profildaten beobachtet; später ausstehende Erhaltungsstufen gelten nicht als bestanden. Creative-Build belegt eine neue Sandkomponente mit Undo/Redo/Resume und einmaliger Belohnung, **nicht** den Neubau des bereits vorhandenen Starterhauses. Jump hat keine erfolgreiche Pause-/Sprung-/Video-Stufe erreicht; Puzzle kein erforderliches Candy-Motiv; Treasure trotz realer Bewegung nicht den ersten Hinweisabschluss.

## Lokale Reparaturen bleiben an ihre jeweiligen Quellen gebunden

Die Original-Red-/Green-Logs umfassen Semantics/Routing (7 Green-Fälle), Graphics-Workflow-Anschluss (6 neue +13 bestehende), Menüsteuerung (16), Default-Studio (7 gezielt ausgeführte Fälle bei36 erhaltenen Methoden), Nextgen-Safe-Area (27), additive Studio-Dateizuordnung (3), Garage-Rückkehr (10), API37-Voraussetzungen (18+12+3), Creative-Runtime/Deadline (38) und Fold-Collector (19). Einzelne Quellen wurden danach additiv weiterentwickelt; diese Zahlen sind **historische Teststände**, keine gemeinsam neu gefahrene Freigabe. Die übrigen ausgewählten Vertragsläufe, Original-Godot-JSON-Gegenfälle und unabhängigen Reviews sind vollständig im Index enthalten.

Die ursprünglichen lokalen Fehler bleiben dokumentiert: Semantics-Aktion, Menüsteuerung, exakte Meldungserwartungen, sekundärer Godot-JSON-Zahlentyp, Garage-Rückweg, Framework-/ANR-Erkennung, Creative-Eingabe/Deadline. Der gemeinsame557er-Lauf zeigte außerdem zwei veraltete Orientation-Mocks, eine veraltete43-statt48-Erwartung, eine echte Graphics-Layout-Anschlusslücke und einen lokal fehlenden unveränderten Sparse-Katalog. Die spätere Katalogmaterialisierung ist separat protokolliert und kein Quelldelta; laufende Reparaturen ändern das ursprüngliche FAIL nicht.

Der spätere Layout-Folgepack enthält seinen eigenen Red-Nachweis (5 Fälle,4 FAIL+1 ERROR), anschließend28 fokussierte PASS und einen unabhängigen Quellenreview. Die Produktionsänderung verlangt zusätzlich die originalen Layout-Sidecars; Pixel-,Quellen-,APK-/ARM64-/PCK-Prüfungen bleiben erhalten. Separat bestehen15 unveränderte historische Katalogtests nach Materialisierung des unveränderten HEAD-Blobs. Beides ersetzt ausdrücklich keinen neuen gemeinsamen Gesamtlauf.

**Creative-Zeitgrenze:** 1.200 Sekunden begrenzen Eingabe- und Ankunftsentscheidungen sowie über `audit_adb` geleitete ADB-Aufrufe. Direkte Screenshot-Aufrufe und OCR behalten eigene Einzel-Timeouts; eine bereits laufende Beobachtung kann später zurückkehren. Es besteht **keine harte Gesamtlaufzeitgarantie**. Die nachträgliche reine Kommentarklarstellung ist gesondert enthalten; ihr Python-AST ist erneut mit dem zuvor getesteten Freeze verglichen, kein neuer Test wird behauptet.

Die meisten Python-Nachweise nutzen synthetische Originalarchiv-/UI-Fixtures und prüfen reale Verifier-/Tourmethoden. Sie ersetzen kein Gerät, keinen Renderer oder menschliche Bildabnahme. Der gemeinsame Lauf verwendete lokal Pillow13.0.0 statt CI12.3.0 sowie Tesseract eng/osd ohne CI-deu; keine fehlende Abhängigkeit oder Überspringung wurde verschleiert.

## Inhalt, Deduplizierung und Grenzen

`index.json` bildet jeden der **2181 logischen Pfade** auf SHA256 und Bytezahl ab. `objects.json` nennt genau einen kanonischen Speicherort pro Inhalt: ein SHA256-Objekt oder ein überprüftes Mitglied eines unverändert erhaltenen kompakten Archivs. Die vier Container enthalten insgesamt **1791** Originalmitglieder. Bereits innerhalb der Originalcontainer vorhandene Wiederholungen bleiben wegen deren Byteidentität erhalten.

Es werden keine großen Original-ZIPs/APKs kopiert. Originalbilder außerhalb kleiner bestehender Reparaturfixtures bleiben in ihren ursprünglichen Archiven. `excluded-originals.json` enthält Artefakt-IDs, Digests, bestehende Speicherverweise und Exportgrenzen. Insbesondere fehlen die vollständigen lokalen Candidate-ZIPs14084647809 (848) und14078786114 (51e) aufgrund der dokumentierten512-MiB-Connectorgrenze. Der reproduzierbare Semantics-Testharness einschließlich seiner Live-Symlinks ist wie im ursprünglichen Manifest ausgeschlossen. Alle17 angeforderten Packs sind vorhanden.

`failures-and-limits.json` enthält die ausführlichen Ergebnisgrenzen; `source-manifest-verification.json` die erneut überprüften Pack-/gzip-/Freeze-Identitäten. Spätere Root-Reviews bleiben eigenständige Datensätze, ohne ursprüngliche Bilder oder Ergebnisse umzuschreiben. Das aktive17f5-CI wird hier nur als Root-Koordinationsstand genannt; seine Ergebnisse wurden nicht eingesammelt.

## Vollständige Archivprüfung

`archive-result.json` ist der außerhalb des Archivs erzeugte SHA256-/Rücklesebericht. Er wird erst nach dem vollständigen Lesen aller äußeren Dateien, aller SHA256-Objekte, aller vier inneren Archive und aller logischen Zuordnungen geschrieben.

```bash
python3 -B verify_assembly.py host-studio-integration-evidence.tar.gz
```

`build_assembly.py` dokumentiert die Auswahl und prüft alle ausgewählten Eingabebytes vor/nach der Zusammenstellung. Die gespeicherten Originale, Hostprep, Index/Commits/Refs, Pins, Receipts und CI-Läufe wurden durch diese Aufgabe nicht geändert.
