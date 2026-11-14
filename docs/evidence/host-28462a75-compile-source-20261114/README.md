# Aktueller Feature-Compile- und Source-Beleg 28462a75

Diese additive Auswahl sichert die bereits einmal geladenen und von der zentralen Integration geprüften Originale aus Feature-Run **43624674585** auf Host **28462a7547048b75fa114e6f5832248e54c94faa**. Die vorhandenen Originaldateien werden unverändert verwendet; weder Jobs/Logs noch Artefakte wurden für diesen Upload erneut abgerufen. Der frühere b721-Beleg bleibt eingefroren und wird nicht ersetzt.

## Explizite Auswahl

- Hostcompile-Job **132537752431**: alle **13 Originaldateien** aus Artefakt **14125213414**, 29633 Bytes, SHA256 `0dbc4e9b3556d65784f07ec05d823025f071ca4ce947d5c1ef58ad9079177288`.
- Memory-/Quiz-Source-Job **132537752710**: alle **5 Originaldateien** aus Artefakt **14125063257**, 3103 Bytes, SHA256 `830616d729de0953920fc75271fc901affa89fc5af1e84a962ec1fe4f29031fd`.
- Die zwei vollständigen terminalen Originaljoblogs, der unveränderte zentrale Quellenreview, diese README und das explizite Uploadmanifest. Gesamt: **23 Dokumentationsziele**, keine ZIPs oder Produktdateien.

## Bereits geprüfter Umfang und Grenze

Der erhaltene Quellenreview bindet **18 Android-Klassengruppen** und **15 identische Source-before/after-Einträge** an den aktuellen Hostbaum. Er dokumentiert **11 Java-/8 Kotlin-Verträge**, **28 Table-Verträge**, **Memory 30 Fälle/1694 Checks**, **Scheduler 7/13** und **Quiz 28/1786**, jeweils ohne ausgewiesene Fehler oder Skips. Diese Ergebnisse stammen aus den bezeichneten aktuellen Featurejobs.

Die **24 neuen Flutter-Regressionsfälle sind in diesem Beleg noch nicht abgeschlossen**. Aus dem hier gesicherten Compile-/Source-Ergebnis folgt keine Freigabe dieser Fälle, des späteren Studio-Laufs, einer APK oder eines Geräts. Die Sprachverträge haben dokumentierte synthetische Android-/ONNX-Grenzen; tatsächliche Modellinferenz, gehörte englische Aussprache und physische FPS werden nicht behauptet. Originale Warnungen bleiben in den Logs erhalten.

## Integrität und Übergabe

Alle 18 Artefaktmitglieder und beide Logs werden gegen die vorhandenen Byte-/SHA-Bindungen erneut geprüft. Jede ausgewählte UTF-8-Datei wird vollständig als Gitblob zurückgelesen und bytegenau verglichen; nach Upload werden sämtliche lokalen Quelldateien erneut gehasht. Nur unveränderliche Blobobjekte werden angelegt. Tree, Commit, Ref und PR bleiben Aufgabe der zentralen Integration.
