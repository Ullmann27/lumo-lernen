# PR486 SWANGLE: eng begrenzte Reparatur der Backend-Zuordnung

Status: **Quellen eingefroren; Reparaturtests noch nicht ausgeführt.** Root sichert zuerst den Quellencheckpoint. Der ursprüngliche Job bleibt FAILURE.

## Belegter Befund

Der aktuelle Beobachter stammt exakt aus `08e63bd32917a6672ae99b66a17c3fa57c83977a`, Baum `04859a04ad84d14120109bdc1bb27684f534a5f3`. Run `43574161418`, Versuch 1, SWANGLE-Job `132384862707` endete am 14. November 2026 mit FAILURE. Das separate APK bleibt unverändert aus Host `7b16f2f5ab16f3d913ee170aefd9807c87216260` mit Native `17f5b9d4a14c70050d4a125a8bd6bd8c68ee7845`.

Drei aktuelle Originale passen zueinander: Die tatsächlichen Startargumente enthalten genau `-gpu swangle`; der Emulator schreibt `vulkan_mode_selected:swiftshader gles_mode_selected:swangle`; die einzelne echte GLES-Zeile enthält ANGLE und SwiftShader. `hardware-qemu.ini` trägt für diese Kombination den internen Backendwert `swiftshader`. Im bestehenden Vergleichsbericht ist ausschließlich `effective_gpu_mode_matches_requested_case` falsch. Der bestehende Framework-Guard und die übrigen Konfigurationsprüfungen waren erfolgreich.

Das belegt eine falsche Gleichsetzung im Beobachter für den konkret gepinnten Emulator 37.2.13 / Build 16740729. Es begründet keinen Wechsel der Startkonfiguration. Die offizielle Android-Dokumentation beschreibt SWANGLE als Kombination aus ANGLE und SwiftShader; sie wird nicht als exakter Quellnachweis für die Serialisierung dieses installierten Builds ausgegeben. Die konkreten Originalbytes tragen diese Schlussfolgerung; Versionsgrenzen stehen in `primary-sources.json`.

## Genau drei Kandidatenpfade

1. `scripts/run_unchanged_apk_diagnostic.sh`: nur der eingebettete GPU-Berichterstatter. Für SWANGLE wird exakt der beobachtete Backendwert `swiftshader` erwartet. Zusätzlich werden die vollständigen aufgezeichneten Startargumente geprüft: konsistenter Kopf mit Argumentanzahl und ausführbarer Datei, genau ein passender `-gpu`-Wert, keine widersprechende Inlineoption. Die ursprüngliche Forderung nach genau einer GLES-Zeile mit beiden Namen bleibt unverändert.
2. `scripts/tests/test_runtime_followup_workflow.py`: die drei vorhandenen Workflow-Testmethoden sind AST-identisch; die vorhandenen Reporterfälle bleiben erhalten und werden um den tatsächlichen Originalfall sowie strikte Gegenfälle ergänzt. Geplant sind zehn Methoden. Kein Test wurde vor dem Quellencheckpoint ausgeführt.
3. `scripts/tests/fixtures/api37-swangle-08e63bd3-renderer.json.gz`: deterministisch komprimierte, hashgebundene Originalfixture mit neun unveränderten Dateien aus Artefakt `14105941453`. Auch der ursprüngliche FAIL-Bericht bleibt unverändert enthalten. Ein späterer lokaler Reporter-Replay schreibt nur in seine temporäre Testansicht.

`integration.patch` enthält die beiden Textänderungen. Die neue binäre Fixture liegt vollständig unter `final-source/` und ist separat in `source-freeze.json` und `fixture-provenance.json` gebunden. Alle drei Zielpfade behalten beziehungsweise erhalten Modus `100644`.

## Erhaltene Grenzen

Die Shellabschnitte vor und nach dem eingebetteten Reporter sind bytegleich. Unverändert bleiben das feste APK, die drei ursprünglichen Gerätefälle, Paketdatei-Hashes, Android-Fingerprint, CPU/RAM/Display/Heap, Framework-Guard, ANR-/Logger-Kette, Touraufrufe, Returncodes und Fristen. Es gibt weder eine Aliasliste noch automatischen Fallback. `swangle`, `auto`, `host` oder ältere indirekte Modi ersetzen im neuen SWANGLE-Backendfeld nicht den exakt belegten Wert. Fehlende Startmetadaten sind ein Fehler.

Dieser Pack ist kein Android-, App-, Native-, Bild-, FPS- oder Gesamtlauf-PASS. Er ändert weder den ursprünglichen roten SWANGLE-Lauf noch die getrennten Logger-/Intervallbefunde. Der separate reine SwiftShader-Lauf hat eigene Shader-/GMS-Befunde, die hier nicht als SWANGLE-Ursache verwendet werden.

## Originale und Anwendung

Der vollständige originale SWANGLE-Joblog ist verlustfrei und deterministisch gzip-komprimiert. Die Commit-/Run-/Jobs-/Artefaktantworten, ausgewählten ZIP-Mitglieder und Quellstände sind bytegenau erhalten; Herkunft und gespeicherte/dekomprimierte Hashes stehen in den Provenienzdateien. Der vollständige 2.667.674-Byte-Original-ZIP wurde nicht erneut heruntergeladen oder dupliziert. Der verwendete Run-Snapshot war noch `in_progress`; allein der hier untersuchte Job war darin bereits terminal `failure`.

Vor Übernahme beide Basisdateien anhand des Freeze prüfen, den Textpatch anwenden und die vollständige neue Fixture kopieren. Danach alle drei finalen SHA256-/Gitblobwerte kontrollieren und den Quellencheckpoint veröffentlichen. Erst anschließend ist der in `handoff.json` genannte gezielte Zehn-Methoden-Lauf vorgesehen. Ein Replay des Originals bleibt eine lokale Prüferprüfung und ersetzt keinen neuen echten API37-Lauf.
