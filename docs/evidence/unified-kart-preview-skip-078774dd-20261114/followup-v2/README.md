# Kart-Vorschau: frische OCR-Zeugen innerhalb der bestehenden Frist

## Quellen und Umfang

Dieser Nachtrag ersetzt ausschließlich die zwei QA-Dateien des vorherigen
Pakets. Die APK bleibt unverändert Host
`078774ddaf64808addaa4c6406f6a3c85b1f239a` mit Native
`785413d395292a243eaa0a0748671eb15d3f80ff`. Der neue Quellmanifest ist
`source-upload-manifest.json`; v1 und dessen 19er-Protokoll bleiben unverändert
als historische, anschließend beanstandete Fassung erhalten.

Der ursprüngliche Unified-Androidlauf bleibt fehlgeschlagen. Die neue Probe ist
noch kein Android-Nachweis. Ein Erfolg des Überspringen-Schritts ersetzt weder
Countdown und gespeicherte Rennzeit noch Fahren, Pause, Speicherung, Rückkehr,
Lern-/Profildaten und die ursprünglichen Identitätsprüfungen.

## Konkreter Befund und Korrektur

Der erste Entwurf gab `image_lines` eine nicht normalisierte Suchbeschriftung.
Der echte Helper erwartet bereits normalisiertes `wanted` für seine
Wortspannensuche und die frühe Beendigung. Außerdem machte dieser Entwurf einen
einmaligen, möglicherweise noch eingeblendeten Anfangsframe zur Voraussetzung
für den eigentlichen Touch-Helfer.

Der korrigierte Code ruft unmittelbar den vorhandenen, unveränderten
`native_tap` auf. Dieser normalisiert die Beschriftung selbst, liest neue
Screenshots und erlaubt den einen ADB-Touch erst nach zwei stabilen aktuellen
Zielbeobachtungen. Es werden keine Zielkoordinaten oder OCR-Texte vorgegeben.
Die ursprüngliche absolute 55-Sekunden-Frist wird weitergereicht und vor/nach
den Operationen geprüft. Der ursprüngliche 150-Sekunden-Rennzeitvertrag bleibt
unverändert. Der bestehende zusätzliche Zehn-Sekunden-Screenshot ist nur nach
bereits feststehendem Rennzeitfehler zulässig und kann kein PASS erzeugen.

`cue` wird aus dem letzten tatsächlich verwendeten Readinessframe und dessen
unverändertem `<frame.stem>-ocr.json` gebildet. `cue_witnesses` enthält beide
finalen Zeugen. PNG-Hash, tatsächlich gelesene Wortzeilen und deren Bounds
müssen zum jeweiligen Target passen. Es gibt keine zusätzliche OCR nach dem
Touch. Eine fehlende Cue bleibt ein Fehler mit `NOT_ISOLATED`, auch wenn das
Intro theoretisch von selbst enden könnte.

## Ausgeführte Gegenprüfungen

Die finalen identischen zwei neuen Fälle scheitern gegen v1 jeweils mit
`CUE_NOT_OBSERVED` statt `TOUCH_SENT`. Mit v2 bestehen alle **23 Tests**, ohne
Skip; unittest meldet **0,768 s**, Prozess-Exit **0**. Die beiden Rotfälle und
der volle Grünlauf sind in `evidence/execution.json` mit exakten Argumenten,
Umgebung, Laufzeiten und unveränderten Vorher-/Nachherhashes gebunden.

Die Tests führen die echten Funktionen `native_tap`, `image_lines`,
`normalized` und `target_observation` aus. Nur Rastertransport, TSV-Ausgabe,
ADB-Grenze und Uhr werden kontrolliert nachgebildet. Eine Textzeile enthält
absichtlich Nachbarwörter; der tatsächliche normalisierte Spannenalgorithmus
muss die exakte Beschriftung mit eigenen Bounds auswählen. Ein weiterer Fall
liest erst einen verblassten Frame und danach zwei frische passende Frames.
Die Tests prüfen außerdem fehlende/manipulierte OCR-Dateien, Bildhashwechsel,
falschen Vordergrund, einen statt zwei Zeugen und späte Rückgaben nach der
ursprünglichen Frist. Dies ist **kein echter Tesseract-, Pixel- oder
Androidlauf**.

Das erste Laden des erweiterten Testharness scheiterte an einem nicht
bereitgestellten `time`-Namen für einen tatsächlichen Helper-Defaultparameter.
Diese Setup-Logs bleiben unter `initial-loader-*` erhalten. Der nächste
Rotlauf hatte neben einer Assertion noch einen nachfolgenden KeyError, weil
die Testdiagnose vor der Statusassertion auf den fehlenden Erfolgsbericht
zugriff; auch dieser Stand bleibt unter `first-contract-*` erhalten. Die
finale Testfassung prüft zuerst den tatsächlichen Status und liefert die zwei
eindeutigen Rotassertions. Keiner dieser Zwischenstände wird als abschließender
Erfolg ausgegeben.

Root hat zusätzlich ein getrenntes reales Originalbild-Replay durchgeführt:
lokales Tesseract 5.5.0 nur mit `eng`, nicht die CI-Konfiguration 5.3.4 mit
`deu+eng`. Das erste historische Vorschau-PNG lieferte dort keinen exakten
Hinweis. Dieser Nachtrag wiederholt den Lauf nicht und behauptet keine
Erkennbarkeit der späteren Androidframes vor deren tatsächlicher Ausführung.

## Erhalt der ursprünglichen Prüfungen

Gegen v1 ändert sich nur `_skip_observed_kart_preview`; alle anderen
Top-Level-Definitionen sind AST-identisch. Gegen die ursprüngliche 078-Quelle
belegen die weiterhin ausgeführten Erhaltverträge insbesondere APK-Identität,
Session-/HUD-/Fahrprüfungen, den unveränderten Hauptablauf abgesehen vom
ausdrücklich aktivierten Flag sowie die ursprüngliche Rennzeitbedingung.
`--skip-observed-kart-preview` bleibt standardmäßig ausgeschaltet. Root führt
den getrennten Same-APK-Gegencheck mit dem Flag aus; ein unbeobachteter Touch
darf dessen Binder niemals bestehen.

Es wurden keine Produktdateien, APKs, Git-Refs oder laufenden CI-Jobs verändert.
