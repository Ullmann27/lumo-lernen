# Studio28462: tatsächliche Hostkompilation und Sprachverträge

Dieses eigenständige Paket sichert die von Root bereits einmal heruntergeladenen Originale des **Studio-Laufs 43626348519 / Jobs 132543176935**. Quelle ist **Host 28462a7547048b75fa114e6f5832248e54c94faa**. Es ergänzt historische Feature- und b721-Belege unter einem neuen Pfad.

## Tatsächlich belegtes Ergebnis

- Der Originalbericht result.json meldet PASS für die wirkliche Android-Kotlin-/Java-Kompilation mit **18 Klassengruppen**.
- Der Sprachrunner meldet **11 Javafälle und 8 Kotlinfälle**, jeweils ohne Fehler, Skips, erwartete Fehler oder unerwartete Erfolge.
- Die aktuellen Kotlinrohdaten enthalten die ursprünglichen **17 Lifecycle- und 23 Envelope-Prüfungen** sowie sechs EN/DE-Szenarien. Die Android-/Inferenzgrenzen bleiben im Log ausdrücklich benannt.
- Sämtliche **15 Quellbindungen** stimmen vor und nach dem Sprachlauf überein und sind an den Host28462 gebunden; Roots unveränderter source-binding.json bleibt erhalten.
- Die **28 Table-Verträge des früheren Feature-Jobs wurden in diesem Studiojob nicht ausgeführt** und werden hier nicht übernommen.

Artefakt **14126072166**: **28.909 Byte**, SHA256 **a78f60574d5634f32ff4fcfd80f22a2179a3d781d273ab4f8c4279142550139d**. Root hat alle CRCs geprüft und exakt zwölf Originaldateien extrahiert. Die Übergabe liest diese zwölf Dateien erneut und bestätigt Größe, SHA256 und Gitblob gegen artifact-binding.json. Sie ruft weder den Joblog noch das ZIP nochmals ab.

Der vollständige Originaljoblog bleibt **239.800 Byte**, SHA256 **18828728dc2f71cbbc145bf4afd249fea64f7b1e130210d97c8033323375a0ee**.

## Übergabe und Grenzen

Die explizite Auswahl enthält die zwölf Originale, den vollständigen Joblog, artifact-binding.json, review.json und source-binding.json sowie diese README und das Manifest: **18 Ziele**. Die Originaldateien werden nicht nachträglich verändert. ZIPs, Produktdateien und fremde Evidenceordner gehören nicht dazu.

Root führte die ursprüngliche Abnahme durch; character_animation prüft hier die unveränderten Bytes und die dokumentierten Resultate für die additive Blobübergabe. Es erfolgt kein neuer Testlauf. Kompilierte Klassen und JVM-Verträge sind kein APK-Lauf, keine reale Modellinferenz, kein gehörtes Audio und keine physische Android-/Fold7-Leistungsabnahme. Dieses Paket erteilt keine Gesamtfreigabe des Studio-Laufs.

Beobachtungszeit der Übergabe: 2026-11-14T18:39:31.345155+00:00
