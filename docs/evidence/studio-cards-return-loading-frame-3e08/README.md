# Begrenzte frühe Verwerfung eines tatsächlich erkannten Ladeframes

## Befund und Umfang

Der Originaldiagnoselauf [43546627017, API 37](https://github.com/Ullmann27/lumo-lernen/actions/runs/43546627017/job/132299721937) bleibt fehlgeschlagen. Die getestete APK ist Host `4ab96666f954baf258422d6ed277fc297b7ddeef` / Native `803e7a626ea6ef0aeeda9c37010e844033d3a8e3`; die ursprüngliche QA-Quelle ist `3e08c7953b84aed6fff30e9e55665de75f79ec77`.

Der erste Returnframe zeigt tatsächlich „Die Spielwelt wird geöffnet“. Bereits der erste Contrast-OCR-Durchgang erkennt diesen vollständigen Text mit gültigen Bildkoordinaten. Die alte positive Suche bearbeitet denselben ungeeigneten Frame danach weiter. Am Ende bleibt zu wenig Zeit für die nächste Aufnahme. Ein späteres Fehlerbild zeigt bereits die Pausekarte; daraus folgt keine gemessene Dauer eines Produktstillstands.

**Die Korrektur basiert auf den frisch gelesenen vollständigen GitHub-Dateien von `86445f53af5d573549fc8cf03405261611f3cb7e`.** Nur `image_lines` ist zwischen 3e08 und 86445 identisch. Die jüngere `leave`-Orientierungsbehandlung bleibt erhalten; keine alte vollständige Datei wird zurückkopiert.

## Änderung

`image_lines` erhält eine standardmäßig leere, optionale negative Captionliste. Die tatsächlichen OCR-Zeilen werden im bereits vorhandenen Variantenlauf ausgewertet. Nur ein vollständiger beobachteter Text mit dem bestehenden Konfidenzfilter und gültigen Bounds des aktuellen Bildes kann diesen Frame negativ verwerfen. Diese Verwerfung hat Vorrang, selbst wenn zugleich ein anderer gesuchter Titel sichtbar ist. Original-PNG, OCR-Zeilen und negativer Quellen-/Boundsbeleg bleiben erhalten.

Nur `capture_returned_flutter` übergibt den vorhandenen Ladehinweis. Es gibt keine vorgeschaltete separate OCR-Suche. Alle übrigen Aufrufer behalten ihren bisherigen Standardpfad. Der bereits vorhandene RuntimeError-Zweig verwirft das Bild und setzt die Folge positiver Bestätigungen zurück.

Unverändert bleiben 30 Sekunden Gesamtbudget, zwölf Beobachtungen, zwei aufeinanderfolgende positive aktuelle Frames, exakte positive Texte und ihre Bounds sowie die Prozess-/Foreground-/Save-/Quellenprüfungen. Keine Produkt-, Workflow-, APK- oder Git-Änderung wurde in den aktiven Checkouts ausgeführt.

## Tatsächlich ausgeführte Gegenproben

| Prüfung | Ergebnis | Grenze |
|---|---:|---|
| Sechs echte OCR-Replays auf der Originalfassung | 4 PASS, 2 FAIL | Die beiden negativen Ladefälle werden noch nicht früh verworfen. |
| Dieselben sechs echten OCR-Replays nach Patch | 6 PASS, 0 Skip | Tesseract 5.5.0 mit echten `deu`-/`eng`-Modellen; kein neuer Androidlauf. |
| Neue Bounds-/Konfidenz-/Framesequenz-Verträge | 6 PASS, 0 Skip | Originalbilder/-TSVs, kontrollierte Capture-/Zeitgrenze; keine erfundenen positiven OCR-Zeilen. |
| Unveränderte bestehende Flutter-Return-Verträge | 6 PASS, 0 Skip | Erhaltene Prozess-, Caption-, Reihenfolge- und Negativprüfungen. |

Beim echten lokalen Ladebild-Replay sinkt die Zahl der Tesseract-Aufrufe für denselben ungeeigneten Frame von 22 auf 1. Die drei tatsächlichen positiven Pausebilder sowie der nicht optierte Standardaufruf bleiben jeweils mit einem OCR-Durchgang erfolgreich. Das misst OCR-Arbeit auf gespeicherten Bildern, keine Geräte-FPS und keine Android-Rückkehrzeit.

Die realen Bilder und TSVs stammen unverändert aus den beiden Originalartefakten; `fixtures/flutter_loading_frame_3e08/manifest.json` bindet jedes Mitglied an ZIP, Job, Run, QA-Quelle und APK-Quelle. Vier PNGs, drei TSVs, zwei eng geänderte Prüfer und zwei neue Test-/Replaydateien bilden zusammen mit dem Fixturemanifest die zwölf ausdrücklich gelisteten Quellpfade.

## Ausführung nach kontrollierter Integration

Der normale Vertrag hat keine neue externe OCR-Abhängigkeit:

```bash
python3 -B -m unittest discover -s tools/android_qa/tests -p 'test_flutter_loading_frame_rejection.py' -v
```

Der echte Bildreplay muss ausdrücklich aufgerufen werden, sobald Tesseract mit den tatsächlichen Sprachen `deu` und `eng` vorhanden ist:

```bash
python3 -B tools/android_qa/tests/replay_flutter_loading_frame_ocr.py -v
```

Die neutrale Dateibenennung verhindert, dass allgemeine Host-Testdiscovery unerwartet einen Tesseract-Zwang erhält. Der spätere CI-Lauf mit Version 5.3.4 und der spätere Android-Lauf müssen den Befund eigenständig bestätigen. Keine vorhandene Prüfschwelle wird gesenkt und kein ursprünglicher Fehllauf wird umgedeutet.

Die Quellen stehen in `source-upload-manifest.json`; Rohlogs, Original-TSV-Replays und Vergleichsbelege sind separat in `evidence-upload-manifest.json` vorgesehen. Nur die ausdrücklich gelisteten Dateien sollen integriert werden. Read-only Testabhängigkeiten und große lokale Original-ZIPs gehören nicht zum Patch.
