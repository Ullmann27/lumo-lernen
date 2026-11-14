# API35: tatsächlicher Fehlernachweis des Kandidaten 4ab96666

Der Originaljob **132269951320** in Run **43530667812 / Attempt 1** ist fehlgeschlagen. Getestet wurden die unveränderten Quellen Host `4ab96666f954baf258422d6ed277fc297b7ddeef` und Native `803e7a626ea6ef0aeeda9c37010e844033d3a8e3`.

Die normale Android-Tour meldet **21/21 erfolgreiche Schritte**. Danach scheitert der zusätzliche Native-Surfaces-Teil bereits vor der ersten Objektbewegung in der Lernszene. **Cards wurde nicht erreicht.** Dieses Paket ist keine Android-Gesamtfreigabe.

Die zwei tatsächlich angesehenen Originalbilder zeigen die lesbare goldene Schaltfläche „Ein Objekt zeigen“, acht blaue Würfel, fünf Reservewürfel und unverändert 0/5 bewegt. Sieben abgeschlossene OCR-Zyklen erkennen die verlangte Beschriftung nicht exakt. Beim achten Bild sind von der unveränderten 120-Sekunden-Gesamtfrist noch 0,636754 Sekunden für den zuletzt gestarteten OCR-Prozess übrig; daraus entsteht die abschließende TimeoutExpired-Ausnahme. Das belegt keinen generell hängenden Tesseract-Prozess. Es wurde kein Blindtap ausgeführt.

`review.json` bindet Originaljob, Artefakt, APK/PCK, die vollständige Readiness-Zeitreihe und die tatsächliche Reichweite der Prüfung. `original/` enthält unveränderte ZIP-Einträge einschließlich OCR-TSVs; jede übernommene Datei wurde bytegleich mit dem Originalarchiv verglichen. `tested-source/` hält die tatsächlich geprüften Quellversionen, keine Reparaturfassung. Der vollständige ursprüngliche Joblog bleibt unverändert.

Das Originalarchiv mit 93.626.609 Bytes, SHA256 `a8ef0dbf1fa44ec6bde2fdd4107067a8b842f4dd17651808bffa65bd8aaa5b7e`, liegt einmalig unter `qa/studio-final-4ab96666/api35/original-artifact.zip`; alle 803 Einträge wurden auf CRC geprüft. Es ist bewusst nicht Bestandteil des Git-Uploadmanifests.

Offline-OCR-Reparaturexperimente sind ein getrennter Nachweis und verändern weder diesen roten Originalbefund noch die getesteten APK-Bytes.
