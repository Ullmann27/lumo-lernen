# MovieMaker-Auflösung: enger Folgefix zu Native 8be3

## Tatsächlicher Fehler

Der verpflichtende Studiojob 132347187651 im Run 43561885899 scheiterte am unveränderten 640×640-Filmvertrag. Die ursprünglichen GitHub-Sidecars des Artefakts 14100974125 zeigen H264 in 720×1280, 148 Frames, 24/1 Aufnahmebilder/s sowie AAC. Encoding, vollständiger Decode und ffprobe hatten Exit 0. Dies war ein Aufnahmegrößenfehler, kein fehlender Gesichts-/Audiozustand.

Die produktive `project.godot` setzt 720×1280. In Godot 4.6.3 liest MovieMaker die Projektwerte vor dem deferred Capture-Start. Die schon vorhandene CLI-Option `--resolution 640x640` änderte diese MovieMaker-Werte nicht. Der frühere isolierte Gesichts-Projektaufbau hatte bereits 640×640 als Default und konnte diese konkrete Integrationslücke deshalb nicht zeigen.

## Schmale Korrektur

Genau zwei Quellpfade ändern sich: `scripts/tests/lumo_facial_capture.gd` setzt in `_init()` die beiden Window-Override-Werte auf 640, bevor der Writer startet. `tools/tests/test_nextgen_runner.py` ergänzt die ausdrücklich falsche Filmgröße 720×1280 als negativen Rosterfall. Die produktive Projektkonfiguration, sämtliche Assets, Schauspieler-/Lehrerlogik, der vollständige Studioharness und seine bestehenden Codec-, Frame-, Audio-, Hash-, Seitenbericht- und Budgetbedingungen bleiben unverändert.

Das Quellmanifest bindet beide Deltas an die tatsächlichen Gitblobs von 8be3a95d5d948d457c4c39bc6694138d60b70027. Kein Gitref wurde hier geändert.

## Ausgeführter Nachweis

- Privater Runtime-Abhängigkeitsbaum: 56 veröffentlichte Quellen exakt gegen den 8be3-Tree gebunden; 15 wiederverwendete generierte Import-/Texturdateien separat inventarisiert. Kein behaupteter vollständiger sauberer Gitcheckout.
- Ein echter neuer lokaler Software-GL-Lauf mit der unveränderten produktiven Hochformat-Projektkonfiguration: Exit 0, 22,559 Sekunden Prozessdauer, `LUMO_FACIAL_CAPTURE_PASS frames=144`.
- Neuer echter Film: H264 640×640, 148 Frames, 24/1, 6,166667 Sekunden; AAC, vollständiger Decode Exit 0. MP4-SHA256: 498f3670e0148ffdd0bd581147b5d312c0dac82d3cd4e3b4fab58747c87765d0.
- Der aus dem unveränderten Harness extrahierte vollständige `face_report` akzeptiert die neuen realen Dateien. Das identische Größenprädikat weist die unveränderten ursprünglichen CI-ffprobe-Daten weiterhin ab.
- Alle 13 einschlägigen Python-Vertragstests bestehen, 0 Skip, Prozessdauer 29,691 Sekunden. Der erste isolierte Testaufruf hatte wegen einer nicht mitkopierten unveränderten Workflowdatei 12 bestandene Fälle und einen Setupfehler. Dieser Rohlog bleibt erhalten. Nach Ergänzung exakt der veröffentlichten Fixture-Abhängigkeit wurde die vollständige Gruppe erneut ausgeführt.
- Alle acht Original-PNGs wurden einzeln geöffnet. Alle 148 dekodierten Filmframes wurden über 13 durchnummerierte Kontaktbögen tatsächlich angesehen. Die letzten drei Frames zeigen die bewusst abgeräumte Szene; davor keine ungewollte Leerphase. Die Nahaufnahme zeigt Blinzeln und dezente geschlossene Schnauzenartikulation, keinen offenen Mund oder phonembasierten Lippenabgleich.

## Wiederholung und Grenzen

Der tatsächliche Rendereraufruf steht unverändert in `green-render-run.json`. `replay-unchanged-movie-helper.py` ist der unveränderte Encoding-/Decode-Block aus dem veröffentlichten Harness. `runtime-setup.json` und `runtime-source-after.json` belegen die genaue lokale Quelle vor/nach dem Lauf.

Das lokale Roh-AVI bleibt unter `green-capture/facial-runtime.avi` mit SHA e12b636171923d8668692a3c4039dfa4e995e4a5721667fceef1bd177e19c166 erhalten. Das kleine Git-Evidenzpaket enthält den vollständigen MP4-Film, Original-PNGs, alle dekodierten Kontaktbögen und die gehashten Rohberichte; es dupliziert das reproduzierbare 7,68-MB-AVI nicht. Der unveränderte CI-Harness nimmt AVI und MP4 weiterhin zusammen in sein Artefakt auf.

24 Bilder/s sind ausschließlich das Aufnahmeformat. Es gibt hier keinen Android-, Fold7-, 60-FPS-, vollständigen Gameplay- oder Phonemnachweis. Die ursprüngliche CI-Gesamtquelle 8be3 bleibt fehlgeschlagen; die vollständige CI des Folgecommits steht noch aus. Die Original-CI-Videobytes wurden für diese Diagnose nicht erneut heruntergeladen oder visuell geprüft; die ursprünglichen Rohsidecars und der vollständige Joblog sind getrennt gebunden.
