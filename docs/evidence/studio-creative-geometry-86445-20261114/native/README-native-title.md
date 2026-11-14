# Schatzsuche: kontrastreicher bestehender Titel

Der isolierte Patch basiert auf Native803e und Host86445. Er ergänzt ausschließlich einen vorhandenen KIT.panel-Hintergrund am Titel. Text, Questregeln, Welt, Speicherformat und Touchaktionen bleiben unverändert.

Der tatsächliche Creative-Androidlauf hatte den ersten Baumfund, den Rucksack und die Rückkehr nach Flutter bereits erreicht. Erst beim zweiten Einstieg scheiterte die genaue Erkennung des Titels vor einer hellen Wolke. Die gesicherten Originalbilder/Logs bleiben unverändert; eine vollständige Androidreise wurde nicht bewiesen.

Identischer neuer Test auf ursprünglicher Quelle:121Checks/4Kontrastfehler, Exit1. Gepatcht:129Checks/0Fehler im Headlesslauf. Bestehender unveränderter Dichtetest:1085Checks/0Fehler. Echter X11-Software-Renderer:137Checks/0Fehler, Exit0, vier neue PNGs. Alle vier Bilder wurden tatsächlich geöffnet. Der Test führt echte Touchereignisse für Rucksack und Pause aus und prüft die unveränderte Questidentität sowie sichere mindestens48dp große Kopfaktionen.

Im Landschafts- und Foldbild ist der vollständige Titel sichtbar und wird vom unveränderten OCR-Leser erkannt. Am originalen Androidbild wird er weiterhin nicht erkannt. Das kleine640×320-Bild bleibt für den lokalen OCR-Leser schwierig; im Portrait bleibt die bestehende Ellipse. Lokales Tesseract5.5.0 hat kein deutsches Modell. Diese begrenzte OCR-Gegenprobe ist kein neuer Android-PASS.

Die Insets und die aus dem Original kopierte erste Baumfundposition sind ausdrücklich isolierte Testfixtures. Kein echter Androidspeicher wurde geändert. Keine Gerätebildrate oder Fold7-Abnahme. Das native Produkt/Test/Fixture-Paket ist separat im native-source-upload-manifest.json eingefroren; Root integriert die drei Dateien kontrolliert und bindet den neuen Rendercheck verpflichtend ein.
