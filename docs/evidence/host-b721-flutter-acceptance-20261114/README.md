# Host b721: tatsächlicher Flutter-Abschluss

Der neue Job **132517423810** in [Run 43618076296](https://github.com/Ullmann27/lumo-lernen/actions/runs/43618076296), Attempt 1, hat am 14. November 2026 um **17:04:52 UTC** den Status **completed / success** erreicht. Die Originalmetadaten und der tatsächliche Checkout binden ihn an Host `b7210db3f53361987fd33592de438fd7984d991a`.

## Tatsächlich gemeldetes Ergebnis

| Bereich | Aktueller Originalbefund | Originaljoblog |
|---|---:|---|
| Vollständige Flutter-Suite | **2.608 bestanden, 0 fehlgeschlagen, 0 übersprungen**; Exit 0 | Zeile 834 |
| Runner-/Capturefehler | Keine in der Zusammenfassung | Zeile 834 |
| Erzeugte Bilder | **546 PNGs laut Runner** | Zeile 834 |
| Wallet-/Profilgruppe | 30 bestanden | Zeile 630 |
| Quiz-UI-Gruppe | 46 bestanden | Zeile 744 |
| Memory-UI-Gruppe | 36 bestanden | Zeile 800 |
| Echter Dart-Englischproducer | 10 Fälle, 2.955 Prüfungen | Zeile 650 |
| Quiz-Dart-Authority | 28 Fälle, 1.786 Prüfungen, 0 Fehler/Skips | Zeile 679 |

Die drei gezielten Fluttergruppen überschneiden sich mit der vollständigen Suite. Ihre Zahlen werden **nicht zu 2.608 addiert**. Der Englischproducer prüft Aufgaben und Deskriptoren, keine Sprachinferenz.

## Verbleibende Analysebefunde

Der unveränderte Befehl `flutter analyze --no-fatal-infos --no-fatal-warnings` meldet **214 Befunde: 209 info, fünf warning, null error**. Er ist aufgrund dieser bestehenden Konfiguration erfolgreich, aber nicht befundfrei. Sämtliche 214 Originalmeldungen mit Code, Quellpfad und Logzeile stehen in `analyzer-observations.json`. Die fünf Warnungen betreffen:

- `_capturePhoto` unbenutzt: `lib/features/live/lumo_live_pro_screen.dart:343:16`.
- Unbenutzter Import: `lib/features/magic_hub/lumo_magic_hub_screen.dart:16:8`.
- `_ink` unbenutzt: `lib/features/story/widgets/lumo_story_scene.dart:150:16`.
- Unbenutzter Import: `test/design/denkprofil_knobel_before_after_capture_test.dart:11:8`.
- Unbenutzter Import: `test/iq/iq_extended_adventure_test.dart:5:8`.

Außerdem meldet der Actions-Upload zwei Node-Deprecations (`punycode`, `url.parse()`); am Jobende folgt der Hinweis auf Node-20-Actions, die mit Node 24 ausgeführt werden. Diese Meldungen bleiben erhalten. Sie werden weder als neue Produktfehler noch ohne weiteren Beleg als harmlos eingestuft. Testnamen wie „Failed game write …“ bezeichnen bestandene Gegenfälle und sind keine fehlgeschlagenen Testergebnisse.

## Quellen und Sicherung

`original-flutter-job.log` enthält die vollständige einmalig abgerufene UTF-8-Jobausgabe: **120.661 Bytes**, 935 Zeilen, SHA256 `4192247ed86ddb17fa3a5d558eee665acbbb4f408fcc6e199ab8e9e1699bbab7`. `run-terminal-original.json` und `jobs-terminal-original.json` liefern den Terminalstatus; das Ergebnis folgt nicht allein aus PASS-Texten. Die spätere Prüfung `git diff --exit-code HEAD --` war erfolgreich.

Der Actions-Upload und die originale Artefaktmetadatenliste stimmen für Artefakt **14123036723**, `lumo-nextgen-feature-flutter-evidence`, **343.154.361 Bytes**, SHA256 `f95c63dcc363d515c1268046289f9a3a012afdc66f79c9f27795e32f69f9223f` überein. Dieses ZIP wurde hier bewusst **nicht heruntergeladen**, nicht entpackt und nicht per CRC geprüft. Die 593 Dateien sind die Uploadmeldung; die 546 PNGs sind der Runnerbefund. Keine dieser neuen Bilder wurde für diesen Abschluss persönlich gesichtet.

`full-flutter-summary-from-original-job.json` ist ausdrücklich aus der einen gedruckten JSON-Zeile extrahiert. Es wird nicht als aus dem Artefakt gelesene Datei ausgegeben. Der vollständige Maschinen-Eventstream bleibt im Artefakt; hier wird kein unabhängiger Event-Neuzähler behauptet.

## Reichweite

Dieser Abschluss belegt die aktuellen Flutter- und aufgeführten Dartprüfungen. Er prüft die neue Java/Kotlin-Sprachfunktion nicht; Hostkompilierung und strikte Speech-Verträge gehören zum getrennten Job. Er belegt keine gehörte englische Aussprache, echte Modellinferenz, Android-Wiedergabe, API35/37-Tour, Updateabnahme, physische 48-dp-Bedienung oder 60 FPS. Es wurden keine Produktquellen geändert, keine lokalen Fluttertests gestartet und kein Gitref oder Workflowlauf verändert.
