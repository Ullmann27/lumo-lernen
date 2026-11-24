# Musterfrage: begrenzte OCR-Lesekorrektur

Basis: `c4e330faa61e231dd3fd44c21085c95ddcd5b7c9`. Ausschließlich QA; kein
Produkt-, Pin-, Workflow-, Fach-, Audio- oder Tap-Delta und kein neuer Androidlauf.

## Originalbefund

Diagnoselauf `43790709991`, QA `e04e29437e2c28f40e492191f430cd49ddc456fa`,
APK-Quelle `684f54a6d11cfb5eccaec30f39fe34d6c17c82cc`, bleibt **DIAGNOSTIC_ONLY /
FAILED**. Artefakt `14191988638`: 30.677.462 Bytes, ZIP-SHA-256
`2114c52f122e21fc6cc907e6a4c2bea0b4ffae0fba85ff5938a6b43435a76724`.

Die bytegleichen Originale `0114-pattern-native-question-9.png` und
`0114-pattern-native-question-9-ocr.json` liegen mit Herkunft und Einzelhashes
unter `tools/android_qa/tests/fixtures/nextgen_pattern_wrapped_43790709991/`.
Die tatsächliche OCR-Variante `raw` liest „Muster entdecken - Was“ und unmittelbar
darunter „kommt als Nächstes?“. Der 22 Zeichen lange erwartete Text wurde vom
historischen `native_see` in den einzeiligen Leser geleitet und deshalb verworfen.

## Korrekturgrenze

Nur `CurrentCandidateProbe.native_see` verwendet für den vollständigen Text
„Was kommt als Nächstes“ bei `exact=False` den neuen NextGen-Leser. Alle anderen
Aufrufe gehen unverändert an die historische Implementierung. Historische
ReferenceProbe, creative_android_probe und alle Pins sind bytegleich zur Basis.

Der Leser akzeptiert die vollständige Wortfolge in einer Zeile oder genau zwei
unmittelbar benachbarten, geordneten Zeilen derselben OCR-Variante desselben
aktuellen Bildes. Er prüft Bildbounds, vertikalen Abstand, vergleichbare Zeilenhöhe,
horizontale Überlappung und getrennte mehrdeutige Vorkommen. Der vorhandenen
Normalisierung entsprechend werden Akzente/Großschreibung gefaltet; Wörter werden
nicht gekürzt, ersetzt oder umgeordnet. Bildhash vor/nach OCR bindet jede Beobachtung.
Keine Verbindung verschiedener Bilder oder Masken; keine Koordinatentaps.

Unverändertes Budget: höchstens zehn Versuche, je 225 Sekunden einschließlich
Capture/OCR, zwei Sekunden zwischen erfolglosen Versuchen. Es entsteht zusätzlich
ein `*-wrapped-read.json` mit den tatsächlich verwendeten Zeilen, Bounds und Hashes.

## Ausgeführte gezielte Prüfungen

- `red.log`: 1 bestandene Fixtureprüfung / 1 erwarteter Fehler über den tatsächlichen
  alten `native_see`-/`native_text`-Pfad; Quellenhashes in `red-provenance.json`.
- `final-fixture-red.log` und `final-fixture-green.log`: dieselbe finale Regression
  gegen die unveränderte Basis-Entrydatei, anschließend gegen die Korrektur: **0/1**
  beziehungsweise **1/0** bestanden/fehlgeschlagen. `final-fixture-provenance.json`
  fixiert den identischen Testhash und beide Entryhashes. Der neue Reader bleibt
  beim RED unbenutzt. Diese Einzelläufe überlappen die nachfolgende Suite.
- `green.log`: **11/11 bestanden**, einschließlich Originalfixture, unverändertem
  historischen Fehler, vollständiger Wortfolge, Nachbarschaft, Varianten-/Frame-
  Trennung, Bildänderung, Mehrdeutigkeit, Budget und eng begrenztem Override.
- `current-candidate.log`: **12/12 bestehende Prüfer bestanden**, einschließlich
  Herkunft, vollständiger Originaltour, nativer Warum-Frage, aktueller Wiedergabe,
  Performance und ungewerterter Musterrückkehr als getrennten Voraussetzungen.

`setup-import.log` bewahrt den anfänglichen fehlenden lokalen uiautomator2-Import;
er ist kein Fehlernachweis für die Leselogik. Die Fixturetests laden den echten
historischen Reader mit einem leeren Android-Transportmodul und ersetzen lediglich
ADB/Tesseract-I/O sowie Wartezeiten. Es wird keine UI-Verbindung hergestellt.

Die neuen Tests prüfen gespeicherte echte OCR-Zeilen; Tesseract wurde lokal nicht
neu ausgeführt. Gezielte Negativfälle sind ausdrücklich synthetische Abwandlungen
in temporären Dateien. Originaldateien bleiben unverändert. Kein neuer Szenen-,
Audio-, Geräte-, vollständiger Tour- oder Release-PASS folgt aus diesen Tests.
