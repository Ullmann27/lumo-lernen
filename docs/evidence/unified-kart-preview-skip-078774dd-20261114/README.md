# Enger QA-Gegenversuch: sichtbare Kart-Vorschau bedienen

## Quelle und Umfang

Basis ist der veröffentlichte Host `078774ddaf64808addaa4c6406f6a3c85b1f239a` mit Native `785413d395292a243eaa0a0748671eb15d3f80ff`. Die ursprüngliche Probe hat Gitblob `c04397ae8e99e0d02cefa341dcf4523deb464d99` und SHA-256 `2cd4f2af109d8bd91da573eea2cd8b8555a4bbe2f9cf65294045ebf23c32f69b`. `source-upload-manifest.json` enthält genau zwei QA-Dateien. Keine App-, Godot-, Speicher-, Regel- oder APK-Datei wurde geändert; dieses Paket bewegt keine Git-Referenz.

Der reale rote Ausgangslauf ist der zusätzliche Unified-Workflow `43580229005`, Job `132408947901`, Artefakt `14108983381`. Er ist vom parallel laufenden Studio-Workflow `43580228966` zu unterscheiden. Die installierte x86-APK hatte SHA-256 `51af20ad5f0ac6a7196e1f703877805509b39a0ac27303619bc8adde5e0d00fe`; die Originalberichte und die unabhängige Quellenanalyse liegen unter `qa/studio-2020-host-078774dd-ci-20261114/unified-failure/`.

## Tatsächliche Änderung

Die neue Option `--skip-observed-kart-preview` ist standardmäßig **aus**. Bestehende Aufrufer und ihr bisheriger START-Pfad bleiben kompatibel. Der isolierte Gegenversuch muss die Option ausdrücklich setzen.

Nach dem bereits vorhandenen Weltmarker und den bisherigen Bildprüfungen liest die neue Funktion die exakte vorhandene Beschriftung „Tippen zum Überspringen“ aus der aktuellen Aufnahme. Nur ein tatsächlich erkannter Text erlaubt den Aufruf des **unveränderten** `creative_android_probe.native_tap`. Dieser erzeugt zwei neue vollständige Surface-Aufnahmen, prüft die exakte Beschriftung und stabile aktuelle Textgrenzen und sendet eine echte ADB-Berührung an deren Mittelpunkt. Weder Koordinaten noch Spielzustände werden vorgegeben. Der danach gespeicherte Screenshot ist ein Beobachtungsbeleg; er ersetzt keinen Rennzustandsnachweis.

Die komplette Ergänzung erhält die **bereits laufende absolute 55-Sekunden-Frist** des bisherigen Weltbereitschaftsschritts. OCR, Touchhelper und Nachaufnahme erhalten nur die Restzeit. Späte Rückgaben werden abgewiesen. Es gibt keinen neuen 55-Sekunden-Timer.

Bei fehlender tatsächlich erkannter Beschriftung lautet das Ergebnis `CUE_NOT_OBSERVED` und `countercheck_scope=NOT_ISOLATED`; es erfolgt keine Berührung. Die ursprüngliche Tour darf ihre unveränderten Kriterien weiter prüfen. Der unabhängige QA-Binder darf diesen Fall jedoch **nicht als erfolgreichen isolierten Gegenversuch** ausgeben. Er muss `TOUCH_SENT` und sämtliche bisherigen Tourkriterien verlangen.

Die bisherige 150-Sekunden-Prüfung bleibt inhaltlich unverändert: derselbe echte Spielstand muss `countdown <= 0` und `elapsed >= 1.0` zeigen. Die vorhandenen Fahr-, HUD-, Pause-, Speicher-, Profil- und Flutter-Rückkehrprüfungen bleiben erhalten. Erst nach einem bereits feststehenden Timeout wird zusätzlich ein aktuelles Bild mit höchstens zehn Sekunden reinem Capturebudget versucht. Es gibt dabei keine weitere Zustandsabfrage, keine Eingabe und keinen nachträglichen PASS; ein Capturefehler verdeckt den ursprünglichen Rennzeitfehler nicht.

## Ausgeführte lokale Verträge

Der identische gezielte Gegenfall wurde zuerst gegen die unveränderte veröffentlichte Probe ausgeführt. Er scheitert tatsächlich daran, dass der vorhandene Startpfad **keine** Vorschau-Berührung ausführt. Er scheitert nicht bloß an einem unbekannten neuen Funktionsargument. Das unveränderte Originalprotokoll liegt in `evidence/red-original-078.log`.

Der anschließende vollständige neue Vertrag bestand **19/19 Fälle, 0 übersprungen**, unittest-Laufzeit **0,274 Sekunden**, Prozess-Exitcode 0. `evidence/green-contracts.log` und `evidence/execution.json` enthalten die Originalausgabe, tatsächliche Argumente, Umgebungsvariablen, Prozesslaufzeiten sowie Quellhashes vor und nach beiden Läufen.

Die Fälle umfassen echte Ausführung der neuen Controllerfunktionen mit verdoppelten Screenshot-, OCR-, ADB- und Uhrgrenzen: fehlender/falscher Text, geänderte Bildbytes, falscher Vordergrund, fehlender Zweibildnachweis, Restbudget nach langsamer Aufnahme, späte OCR-/Touch-/Capture-Rückgabe, unveränderte Rennzustandsbedingung und rein diagnostische Timeoutaufnahme. Der reine bestehende Spielstandsprüfer wird direkt aus seiner unveränderten Quelldatei geladen. Dafür waren weder Flutter noch ein Emulator, Tesseract oder zusätzliche Pythonpakete nötig.

Zusätzlich binden ausgeführte AST-Verträge die vorhandenen Identitäts-, RaceSession-, HUD- und Fahrfunktionen an exakt078. Nach Entfernen ausschließlich der neuen Option ist auch der komplette ursprüngliche `main`-Ablauf identisch, einschließlich Pause, Speichervergleich, Rückkehr und Lerndatenerhalt. Nach Entfernen ausschließlich der terminalen Diagnostik ist `wait_race_running` identisch. Die vollständige Definitionenliste steht in `evidence/ast-preservation.json`.

## Ergebnisvertrag und Grenzen

`runtime-report-contract.json` beschreibt die konkreten Dateinamen und verschachtelten Felder. `preview_skip.readiness` ist das unveränderte originale Touchjournal; es kann frühere verworfene Frames enthalten. Maßgeblich sind die letzten zwei gültigen Targetbeobachtungen und der tatsächlich stabile letzte Targetbefund. Die neuen Rohbilder werden vom bisherigen Tour-Artefaktupload mitgesichert.

Es wurde hier **kein neuer Androidlauf** ausgeführt und kein neues Renn-, Leistungs- oder Geräteergebnis behauptet. Die Python-Doppel sind keine Bildsichtung oder Gerätetests. Der neue Gegenversuch muss dieselben bereits gebauten APK-Bytes separat installieren und die tatsächlichen Eingaben sowie alle nachfolgenden Originalgates belegen. Der rote Ausgangslauf bleibt unverändert erhalten.
