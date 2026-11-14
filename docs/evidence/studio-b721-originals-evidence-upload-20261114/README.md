# Ergänzte b721-Originalbelege und begrenztes Leistungsaudit

Dieses Paket ergänzt die bereits gesicherten historischen Textberichte um ausdrücklich ausgewählte, unveränderte Originaldateien. Es ersetzt keinen früheren Review oder Receipt und enthält keine Produktdateien, APKs, ZIPs oder Build-Caches.

## Herkunft und Umfang

- Quiz: alle 35 ursprünglichen Artefaktmitglieder, darunter die sechs bereits persönlich geprüften PNGs, sowie zwei vorhandene Bindungs-/Metadatendateien. Run 43619285124, Job 132521067495, Host b7210db3f53361987fd33592de438fd7984d991a, Native 29080ef8cd1a5b385eeeec97976fbefd31280427. Artefakt 14124000432: 501399 Bytes, SHA256 ac00a40ffb8215e6e50b6f17a5aaedf346f1ed3c40f7a05224549f195c332a8d. Die ursprüngliche Prüfung aller 35 ZIP-CRCs und Einzelhashes ist im unveränderten Bindungsbericht dokumentiert. Hier werden die ausgewählten lokalen Originalbytes erneut gegen diese Hashes gebunden. Es wurde kein neues Bild erzeugt und keine weitere Bildsichtung behauptet.
- Aktueller Studio-Hostcompile: 18 exakt manifestierte Dateien plus unverändertes Originalmanifest, insgesamt 19. Run 43619285124, Job 132521067290, Artefakt 14123896298: 28897 Bytes, SHA256 d663f3ec1d3065aa6e1a1d4435003fd4cd7ee8d2553214b73425930201e93e24. Die vorhandene Abnahme bindet 18 kompilierte Android-Klassengruppen und 11 Java-/8 Kotlin-Verträge an die tatsächlichen Quellen. Die 28 Table-Verträge aus dem früheren Feature-Job werden diesem Studiojob nicht zugeschrieben.
- Leistung: zwei vorhandene Dokumente plus deren unverändertes Manifest. Dies ist ein begrenzter Quellenaudit der vorhandenen Instrumentierung; keine neue Messung oder Instrumentierungsimplementierung.

## Abnahmegrenzen

Die Quizdateien stammen aus dem realen Dart/Godot-Paarlauf. Dessen Test-Ledger ist keine AppState-Wallet- oder Androidfreigabe. Die Sprachverträge verwenden dokumentierte synthetische Android-/ONNX-Grenzen und belegen keine gehörte Aussprache oder ausgeführte Modellinferenz. Standbilder und Aufzeichnungsraten belegen keine physische Geräte-FPS, GPU-Zeit oder Fold7-Temperatur. Die zuvor veröffentlichten Remote-only-Reviews bleiben als damalige Sicherungsstände erhalten.

## Uploadvertrag

Alle Zielpfade stehen ausdrücklich im Uploadmanifest. Vor und nach dem Blobupload werden die Originalbytes gehasht. UTF-8-Dateien werden vollständig zurückgelesen und mit dem Original verglichen; PNGs werden über lokale Byte-/SHA256-/Gitblobbindung und den bestätigten Create-Blob-SHA belegt. Für PNGs wird kein UTF-8-Readback behauptet. Nur unveränderliche Gitblobs werden angelegt; Tree, Commit, Ref und PR bleiben Eigentum der zentralen Integration.
