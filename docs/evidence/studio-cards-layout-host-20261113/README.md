# Host-Prüfvertrag für sichere Cards-Anordnung und Flutter-Rückkehr

Dieser eingefrorene Patch bindet die neue Cards-Anordnung an tatsächlich gelesene Fensterdaten und unveränderte Bildschirmaufnahmen. Er ist ein lokaler Prüf- und Integrationsnachweis. Ein neuer Android-Lauf ist damit noch nicht bestanden.

## Belegte Fehler und Änderungen

Der alte Projektor lag bei der echten neuen Portraitaufnahme um **63,152 Pixel** daneben. Der unabhängige Projektor berücksichtigt jetzt den tatsächlichen RenderView-Versatz und den von Systemleisten überdeckten Bereich. Seine Berechnung stimmt mit den echten Godot-Eckpunkt-Readbacks im Portraitfall auf **0,000167 Pixel** überein; Portrait und Querformat werden im Vertrag gegen die Originaldateien geprüft. Die gelieferten Eckpunkte dienen ausschließlich als Gegenprüfung, nicht als Koordinatenquelle für die Pixelmessung.

Die Aufnahme verlangt vor und nach jedem Originalbild dieselbe atomare Layoutdatei. Sitzung, Rundenzustand, Seite, Animation, Auswahl, Bildschirmgröße und Messwerte müssen übereinstimmen. Erst zwei aufeinanderfolgende passende Bilder können bestehen. Fehlende, veraltete, gedrehte, zwischenzeitlich geänderte oder erfundene Layoutangaben werden abgewiesen. Die bestehenden Karten-Pixelschwellen und die exakten OCR-Anforderungen bleiben erhalten.

Die tatsächliche Android-17-Aufnahme aus Host318 zeigte nach semantisch bereits erfolgter Rückkehr noch die native Lernszene. Der neue Rückkehrvertrag verlangt zusätzlich zwei frische Bilder mit sichtbaren Flutter-Merkmalen. Beide unveränderten Originalbilder – falsches API37-Bild und echtes API35-Flutter-Bild – bleiben als getrennt bezeichnete Testbelege erhalten.

Auch der gemeinsame Publisher liest im ausdrücklich aktivierten Studio-Pfad beide ursprünglichen Layoutdateien pro Bild und prüft Geometrie und Pixel erneut. Sein Standardpfad für Version2018 bleibt unverändert. Die neue Testhilfsfunktion `attach_synthetic_layouts` konstruiert ausschließlich temporäre Parser-Fixtures; sie bearbeitet keine echten Releasebelege.

## Tatsächlich ausgeführte Prüfungen

- **44/44** Capture-, Geometrie-, Flutter-Rückkehr-, Lifecycle- und bisherige Pixelverträge: 7,489s, Exit0.
- **14/14** Publisherverträge einschließlich aller acht vorhandenen Legacytests: 23,148s, Exit0.
- Die roten Originalprotokolle bleiben neben den grünen Protokollen erhalten. Ein zusätzlich entdeckter verspäteter OCR-Erfolg wird jetzt abgewiesen; die bestehenden Fristen wurden nicht erhöht.
- Die echte lokale OCR hat auf den unveränderten Renderbildern `Pause`, `1/3` und `1/1` gelesen. Die lokal fehlende deutsche Sprachdatei und der verwendete englische Fallback stehen ausdrücklich im Rohprotokoll.

Die unabhängige Native-Sichtprüfung und der unabhängige Publisher-Review liegen im angegebenen Nachweisordner des Haupt-Hosts. Die drei Native-Bilder wurden tatsächlich geöffnet. Der danach von Root/A erweiterte gemeinsame Inset-Cache benötigt seine eigene endgültige Quell- und Geräteprüfung.

## Abnahmegrenze

Diese Tests liefern keine neue Android- oder Fold7-Abnahme. Es wurden keine Spielstände repariert, keine Kartenregeln geändert, keine Bildinhalte als erfolgreiche Laufzeit erfunden und keine GitHub- oder CI-Mutation ausgeführt. `host-source-freeze.json` nennt alle Code- und Fixturedateien mit SHA256, Gitblob und exaktem lokalen Pfad. Root führt die endgültige Integration und den erneuten vollständigen Kandidatenlauf aus.
