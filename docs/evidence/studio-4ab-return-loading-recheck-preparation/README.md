# Getrennter Rückkehr-Nachtest am unveränderten 4ab-APK

Dieser eingefrorene Entwurf setzt die bestehende QA-Quelle `3e08c7953b84aed6fff30e9e55665de75f79ec77` auf PR478 fort. Er prüft weiterhin ausschließlich die bereits gebauten Bytes aus Host `4ab96666f954baf258422d6ed277fc297b7ddeef` mit Native `803e7a626ea6ef0aeeda9c37010e844033d3a8e3`. Der laufende reguläre Studio-Kandidat wird dadurch nicht verändert.

## Enger Unterschied

Nur die bereits geprüfte `image_lines`-Erweiterung wird auf den alten Helper übertragen. Die `leave`-Implementierung bleibt exakt 3e08; die beiden `image_lines`-ASTs aus dieser Fassung und dem geprüften 86445-Patch sind identisch. Nur die Flutter-Rückkehrprüfung verwendet die negative Stoppliste. Ein tatsächlich erkannter Ladehinweis mit gültigen Bildgrenzen verwirft den aktuellen Frame frühzeitig. Die bestehenden 30 Sekunden, höchstens zwölf Beobachtungen, zwei positiven Bildnachweise sowie Prozess-, Zustands- und Speicherbedingungen bleiben unverändert.

## Quellenbindung und Ausführung

`source-upload-manifest.json` nennt alle 26 erlaubten Quellpfade mit Dateigröße, SHA256, Gitblob, Modus und Unterschied zu 3e08. Elf Dateien bleiben identisch, fünf werden geändert und zehn neue Test-/Fixturedateien ergänzt. Alle Dateien haben den geprüften Modus 100644. Das Manifest und sämtliche Berichte gehören **nicht** auf die strikt gebundene QA-Branchliste. Nur die expliziten Quelldateien dürfen dort integriert werden.

Die unveränderte Android-Matrix läuft weiter auf API35 und API37. QA-HEAD und sauberer 4ab-Produktcheckout werden getrennt geprüft; die Originaltouren laufen über absolute QA-Pfade im Produkt-CWD. Die Modernisierungstour bleibt unverändert. Der Studio-Prüfer erhält den ausdrücklich gehashten Rückkehr-Zusatz. Original-Run/Artefakt/Builder, APK, PCK, Zertifikat, Quellen und Laufzeit werden weiterhin vor und nach der Tour gebunden. Es gibt keinen Build- oder Publisherjob.

## Tatsächlich neu ausgeführte Prüfungen

Die 18 angepassten Binder-Verträge bestanden ohne Skip in 1,090 Sekunden (Prozessdauer siehe JSON). Darunter befinden sich getrennte Gegenfälle für falsch committete Surface-, Helper-, Test- und PNG-Bytes. Actionlint endete mit Exit 0; alle elf Bashblöcke bestanden `bash -n`. Die vollständige Android-Matrix ist strukturell identisch zu 3e08. `binder-contracts.log`, `binder-contracts-execution.json` und `workflow-source-comparison.json` enthalten die Originalergebnisse.

Die bereits identischen OCR-Replays wurden hier nicht wiederholt. Der nächste CI-Prerequisit führt zwingend die bisherigen 12 Caption-, 6 Cards- und 18 Binder-Fälle sowie zusätzlich 6 echte OCR-Replays und 6 Grenzverträge aus. Vorher werden die tatsächlich installierte Tesseract-Version 5.3.4 und `deu`/`eng` verlangt. Fehlende Programme oder Modelle werden nicht übersprungen.

## Ehrliche Ergebnisgrenze

Es wurde kein neuer Androidlauf gestartet. Der historische 3e08-Lauf bleibt auf API35 erfolgreich und auf API37 am ersten Cards-Rückkehrbild fehlgeschlagen. Seine Ergebnisdateien wurden nicht verändert. Die lokale Vorbereitung und die früheren Tesseract-5.5.0-Replays ersetzen weder die kommende 5.3.4-CI noch den tatsächlichen Androidnachtest. Physische Fold7-Messungen liegen daraus nicht vor.
