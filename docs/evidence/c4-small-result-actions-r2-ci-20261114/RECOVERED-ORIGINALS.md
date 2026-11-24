# R2: unveränderte Originale nach Wiederherstellung ausgewertet

Dies ergänzt den früheren Terminal-Checkpoint cb336ebb4fa867f21692d22dd6a95f3e526763c1. Dort war das lokale Lesen des Archivs zum damaligen Zeitpunkt noch blockiert. Nach bestätigter Wiederherstellung wurde das offizielle Artefakt genau einmal heruntergeladen; der frühere Zustand bleibt als historischer Beleg erhalten.

## Exakte Quelle und tatsächliches Ergebnis

- Run 43595002861, Attempt 1, Job 132447521284: FAILURE.
- QA c082ebe02254e15ff2779b5031b118c330dcdafe; unveränderter Host aab09275ec6b5808de9be539ca4e1a7e70921249 / Native e2d15dbc5f3709306decb139eeb70a1cf30c0b73.
- Originalartefakt 14113299183: 1.507.887 Bytes, SHA-256 f769c7ae1db1b19b39d8e2944e4d2c21b341669897978bfcfcfe06c97f0b9922.
- Die vollständige Original-ZIP bleibt bytegleich erhalten. CRC, eindeutige kanonische Pfade und Dateitypen wurden vor dem Lesen geprüft: 95 Dateien, keine PNGs; kein Archivcode ausgeführt.

Native meldet 123 Checks, null abgeschlossene Zielaktionen und den Fehler `small_result_restart_before waits for the matching fresh settled layout`. Beide Prozesse endeten mit Exit 1. Dart Zeile 90:7 übernimmt den fehlgeschlagenen Native-Bericht. Tatsächlich erfolgt sind die Einrichtung des Zweispielermodus, sieben Gewinnzüge und die Pause im gewonnenen Dialog: ACK 10, Revision 18, fünf Sterne und 40 XP. Weder der Ziel-Restart noch der Zielwechsel zurück zum Solomodus wurde angefordert.

## Konkrete QA-Ursache und Grenzen

Im QA-Blob cc9ef04069bb2d73d2953a725e7ee5974e5b496f vergleichen die Zeilen 128, 129 und 131 JSON-Geometriearrays mit INT-Literalarrays. Die offizielle Godot-4.6.3-Implementierung erzeugt beim JSON-Lesen FLOAT-Werte; die Arraygleichheit verwirft unterschiedliche Variant-Typen. Diese Bedingungen bleiben damit auch bei numerisch richtigen Geometriewerten falsch. Der unabhängige Quellenreview ist separat unter `../c4-small-result-actions-qa-r2-20261114/independent-failure-review.json` gebunden.

Die temporäre Produktions-Layoutdatei ist nicht im Archiv erhalten; die Produktion entfernt sie beim Beenden. Tatsächliche konkrete Layoutwerte oder das Bestehen aller anderen Capture-Bedingungen lassen sich deshalb nachträglich nicht behaupten. Der belegte Fehler betrifft die QA-Bedingung; er belegt keinen Produktfehler. Ein erfolgreicher zukünftiger Bedienlauf ist weiterhin offen.

## Quellenbindung

`original/runtime/source-before.json` und `source-after.json` sind bytegleich. 447 Host-, 1.256 Native- und vier QA-Dateien stimmen mit den exakten Remote-Tree-Einträgen überein. Die 334 aufgezeichneten UID-Metadaten wurden gegen die Quellblobs und die aus den aufgezeichneten UID-Strings rekonstruierten Bytes/Hashes geprüft. Beide Overlay-Blobs sind identisch mit den freigegebenen QA-Dateien.

Der vollständige Dateihashindex, die unbearbeiteten Prozesslogs/Ergebnisdateien und der kompakte Befund sind Bestandteil dieses Checkpoints. Es wurde hier kein Spiel-, Renderer-, Android- oder APK-Lauf wiederholt. Eine gesonderte minimale Godot-Gegenprobe der späteren QA-Korrektur gehört in deren eigenen Nachweis.
