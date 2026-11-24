# Zusatzlauf 2: zwei geprüfte Fälle, nativer Fragepanel-Übergang noch offen

Run **43816667737**, Job **133130171146**, QA **25d4aa1eb3b684eb10e38b4fa7e0270d02e8f9b3**, unveränderte APK **e05a96a52aaf57e466e79831f15aaffd144284ee**. Der Gesamtlauf bleibt **FAIL**, `release_eligible=false`. Diese Zusatzprüfung ersetzt keine vollständige Original-/Referenztour.

Das vollständige Artefakt **14203032627** enthält **753 Originalmitglieder**, ZIP **29.082.573 Bytes**, SHA **663d9f34fcfbbcf12360ee03dfd889df9469bbd13f3ef7ca67dcfa11ec09411a**. Alle Pfade, Größen, CRCs und Einzelhashes wurden geprüft. Vier unveränderte ZIP-Teile erhalten sämtliche Originale; ausgewählte Ergebnis-, Bild-, Video- und XML-Dateien liegen zusätzlich unter `original/`.

## Tatsächlich abgeschlossene Fälle

- **Falsche Zahl und Korrektur:** 15 zu 9+7 wurde durch den echten Prüfknopf falsch bewertet; 16 wurde danach mit eigenem Versuch korrekt gespeichert. Profil und bisherige Daten bleiben erhalten. Die korrigierte Antwort zählt als unterstützt, weil bereits eine Fehlantwort vorlag. Es wurde keine gesprochene/verhörte Zahl eingespeist.
- **Aufgabenwechsel während aktiver Silbenanzeige:** `0239-switch-live-active-and-next.xml` enthält gleichzeitig **Silbe 1: Ba, gerade aktiv** und den aktivierten Weiterknopf. Der gesamte Erfassungsbeginn bis zum angeforderten Tap beträgt **0,132656392 Sekunden**. Nach genau einer ausdrücklich gestarteten Wiederholung erreicht die UI dieselbe Sitzung mit der neuen unbeantworteten Aufgabe **word-rakete**, ohne zusätzlichen Versuch oder Belohnung. Das ist ein Nachweis der Player-Semantik, keine akustische Messung und keine Messung des tatsächlichen Zustellzeitpunkts des Touchereignisses.
- **Ansicht und Rückstellung:** echte WM-Rohwerte und PNGs belegen unveränderte 1080×2340 Pixel, ursprüngliche 440 dpi, temporäre 320 dpi und exakt wiederhergestellte 440 dpi. Fertiger Banane-Checkpoint sowie Profil/Lerndaten bleiben bei Vorbereitung erhalten; unbeantworteter Rakete-Checkpoint und Daten bei Rückstellung ebenfalls. Kein physischer Fold7- oder Standarddichte-Wechselnachweis.

Root hat die tatsächlichen Zahlen-/Aufgaben-/Viewportdaten mit den bytegleich gebundenen Prüferquellen erneut unabhängig ausgewertet und Original-XML-/PNG-Hashes geprüft. `verified-completed-subcases.json` enthält die genaue Teilfallbindung. Ein erster lokaler Vergleich Python-Tuple gegen gespeichertes JSON-Array wurde in der abgeleiteten Prüfung auf identische JSON-Darstellung berichtigt; numerische Bounds und Originaldateien blieben unverändert. Dieser Teilcheck macht den Gesamtlauf nicht erfolgreich.

## Tatsächlicher späterer Abbruch

Die native Banane-Szene wurde erreicht. Beim Öffnen des Fragepanels wirft der gemeinsame Leser bereits auf dem ersten Screenshot 0343: **Current question-panel background not observed**. Dieses Original zeigt tatsächlich noch die unverschattete Lernszene. Der sofort folgende echte Fehler-Screenshot 0344 zeigt dagegen das vollständig geöffnete Modal **Frag Lumo** mit **Zurück**, Eingabefeld und den unten sichtbaren Schaltflächen **Noch einmal / Langsamer**.

Die unveränderte Farbmaske findet in 0343 keine Panelpixel, in 0344 jedoch 749.307 Treffer innerhalb [40,606,1040,1803], rund 62,60 Prozent der Fläche. Die Farbe funktioniert; das erste Bild ist zu früh. Es ist ein einmaliger Fragen-Tap aus zwei stabilen OCR-Frames protokolliert. Ein enger QA-Fix muss fehlende erste Renderframes innerhalb der bestehenden Versuchs-/Zeitgrenzen weiter beobachten und sämtliche echten Panel-/Überschrift-/Geometrie-/Stabilitätsbedingungen erhalten. Keine Produkt- oder Farbanpassung ist durch diese Beobachtung begründet.

**Nativer Langsamer-Tipp, dessen abgeschlossene Viersegmentwiedergabe und der nachfolgende native Stoppfall sind durch diesen Lauf nicht bestanden.** Beide vollständigen ursprünglichen PNGs, alle zugehörigen OCR-/Touch-/Sprachdaten und das originale FAIL bleiben erhalten.

Vollständiges unverändertes Joblog: **584.418 UTF-8-Bytes**, SHA **e58fca1a0ff3249fb6e3b5293a5b426f17e9b9f8c354b4f628684b15609eb347**, zusätzlich verlustfreies gzip. Einzelheiten im Joblogmanifest.
