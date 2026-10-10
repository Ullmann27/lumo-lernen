# APK 1919: gezielte Reparatur der Android-Gas-Suche

## Reproduzierter Ausgangsfehler

Im [ursprünglichen API-36-Kart-Job](https://github.com/Ullmann27/lumo-lernen/actions/runs/37975946198/job/113988997647) wurde die APK tatsächlich installiert. Der vollständige Rennprobe scheiterte vor dem Fahren bei der Suche nach „Gas: GAS-Taste halten“ im Pausenmenü. Der globale Renntimeout von 2400 Sekunden wurde nicht geändert; abgelaufen war das vorhandene 180-Sekunden-Budget der sichtbaren Aktionssuche.

Die Originalbilder und OCR-/Scroll-JSONs zeigen einen Sprung vom oberen zum unteren Listenbereich. Dort scrollte der Reader weiter abwärts, obwohl „Neue Fahrt auswählen“ und „Rennen abbrechen“ sichtbar waren. Der bisherige Gas-Recovery-Hook wurde erst nach einem ersten exakten Treffer aktiv und konnte diese initiale Suche nicht korrigieren.

[Gesicherte unveränderte Fehleraufnahmen](https://github.com/Ullmann27/lumo-lernen/blob/5d872dd89228c42cc1414ffeb47137175f27d5b8/docs/evidence/lumo-1919-api36/README.md).

## Begrenzte Änderung

Nur bei der initialen Kombination aus exakter Beschriftung „Gas: GAS-Taste halten“, Suchrichtung „down“ und Kontext „pause“:

- Eine aus den aktuellen Beschriftungen abgeleitete Geste verwendet die halbe sichtbare Strecke und 900 ms.
- Die beiden bereits durch Footer und Geometrie geprüften unteren Beschriftungen schalten die Suche dauerhaft nach oben.
- Zwei aktuelle stabile Bilder, Bild-Hashprüfung, die exakte finale Beschriftung, alle Zehn-Versuche- und Zeitgrenzen bleiben erhalten.
- Andere Beschriftungen, Richtungen und Menükontexte behalten ihr bisheriges Verhalten.

Es gibt keine festen Gas-Button-Koordinaten und keine Änderungen an App, Godot, Strecke, Fahrphysik oder Speicherdaten.

## Reproduzierbare Reader-Regression

`.github/probes/prepare_lumo_1919_gas_replay.py` lädt ausschließlich das unveränderte Fehlerartefakt **11641916981** aus Run **37975946198**. Es prüft Quellzuordnung, 136.961.576 ZIP-Bytes und SHA-256 `a1543a51c0d5782f011b6ca6fb944d22c9efc33000299c3f21470f8602e4df2e`, extrahiert Original-PNG/OCR/Scroll-Daten und erstellt deren Hashmanifest.

`.github/probes/replay_lumo_1919_gas_search.py` extrahiert die tatsächlich geprüften Funktionen per AST. Android-Capture, OCR, ADB und Uhr erhalten dokumentierte Replay-Adapter. Die Oberfläche, Hashprüfung, Scrollgeometrie und Stabilitätsgates bleiben echte Funktionen.

Die ersten sechs Fehlerbilder werden in Originalreihenfolge gelesen. Der alte Quellstand muss beim erneuten Abwärtsscrollen am Listenende mit dem spezifischen erwarteten RED fehlschlagen. Der Kandidat muss dieselbe Regression bestehen. Weitere Reader-Fälle prüfen die dauerhafte Richtungsumkehr und unveränderte andere Suchfälle. Die dafür umgeordneten Originalbilder werden ausdrücklich als zusammengesetztes Policy-Szenario bezeichnet.

**Ein bestandener Reader-Replay ist kein Android-Rennnachweis.** Es wird kein Gas-Treffer und kein Rennergebnis erfunden. Anschließend startet der Workflow einen separaten echten API-36-Emulatorlauf.

## Unveränderte APK, getrennte Quellidentität

| Gegenstand | Fester Stand |
| --- | --- |
| App-Quelle der APK | `d07b2b48593b939a2a0446fcb83a25a2b2a59db6` |
| Godot im APK-Paket | `d140e5b05cb5afacfe675559b78da4254cb1daed` |
| Version | `0.12.12+1919` |
| APK | 205.316.096 Bytes |
| APK-SHA-256 | `8e2ea31fed333fd8e89becd073b100c53ce9449017badb43ab4bc28022cc51aa` |
| APK-Artefakt | `11639898022` aus Run `37975946198` |
| Test-Harness | Tatsächlicher separater Git-Checkout des neuen Nachprüflaufs |

Der neue Lauf baut keine weitere APK. Er prüft Kandidatenbytes, Signatur und ursprüngliche Provenienz, installiert die alte Testbasis 1602, aktualisiert auf diese exakte APK 1919 und führt die vorhandenen Offline-/Profil-/Kart-Probes aus. Der vollständige Renntest behält seine Anforderungen an zwei Runden, 16 Kontrollpunkte, Pause, Ergebnis, Offline-Wiederaufnahme, Host-Bestätigung und eindeutige Belohnung bei.

Die Ergebnisdateien protokollieren `source` als ursprüngliche App-Quelle und `harness` als tatsächlichen neuen Test-Commit. Der installierte Binärstand wird per Hash und Größe zurückgeprüft.

## Abnahme

Die tatsächlichen Ausgänge stehen in den Artefakten und Logs des Workflows `lumo-1919-gas-recovery.yml`. Diese Beschreibung enthält keine vorweggenommene Erfolgsmeldung. Ein später erfolgreicher Nachprüflauf macht den historischen Gesamtworkflow **37975946198** nicht rückwirkend erfolgreich. Seine API-36-Fehlermeldung und der übersprungene Packaging-Job bleiben erhalten.

Die bereits erfolgreiche ursprüngliche API-35-Rennprüfung steht [separat dokumentiert mit echten Android-Aufnahmen](https://github.com/Ullmann27/lumo-lernen/blob/a5a8e25add924896ae4d5513303ee496f86f3267/docs/evidence/lumo-1919-api35/README.md). Es wurde kein physisches Fold7 geprüft.

## Recorder-Abschluss: tatsächlich beobachteter Fehler vom 9. Oktober

Der Nachprüflauf [37987900281, Android-Job 114014576709](https://github.com/Ullmann27/lumo-lernen/actions/runs/37987900281/job/114014576709) mit Harness `d40519d011500246bb4c7ad5a39ad684aa9477bd` blieb insgesamt **FAILURE**. Die sichtbare Gas-Auswahl funktionierte. Der tatsächliche Rennablauf erreichte 16 Kontrollpunkte und zwei Runden; Pause/Wiederaufnahme, Ergebnis, Offline-Wiederaufnahme, Host-ACK und Schutz vor doppelter Belohnung bestanden. Der Abschluss scheiterte anschließend bei der Sammlung des Videos:

`Actual Android footage collection failed: Cannot safely identify the owned screenrecord process`

Das unveränderte Fehlerartefakt **11645193524** umfasst 261.443.909 Bytes, ZIP-SHA-256 `1560e0abaa807a6be31c52165c983ddf788c25b6fbb2a208ab82f6233a78b865`. Fünf Videoabschnitte waren gesammelt; der letzte Abschnitt wurde nicht übernommen. Die alte Implementierung speicherte die betreffende `pidof`-Antwort nicht. Daher ist aus diesem Lauf keine eindeutige Unterscheidung zwischen einem zeitlichen Prozessübergang und einer Transportdiagnose möglich. Die Ressourcen-Rohdaten liegen vor, aber ihr abschließendes Gate hinter der Videosammlung wurde in diesem Lauf nicht ausgeführt.

### Kleine, gesondert geprüfte Recorder-Korrektur

Nur die Klasse `VideoRecorder` wird gegenüber d405 geändert:

- Jeder Recorder erhält einen eindeutigen Remote-Dateinamen. Ein Signal ist nur für eine einzelne positive PID mit exakt passender, NUL-getrennter Befehlszeile und genau dieser Zieldatei erlaubt.
- stdout, stderr und Rückgabecode der Prozessabfragen werden getrennt gespeichert; zusätzlich werden ihre Hexbytes verlustfrei erhalten.
- Meldet `pidof` ohne Ausgabe und ohne stderr den Status 1, wird kein fremder Prozess gesucht oder beendet. Innerhalb derselben 20-Sekunden-Frist muss der eigene ADB-Prozess erfolgreich enden.
- Erst tatsächlicher Exit 0 und eine erfolgreich geladene Videodatei von mindestens 1024 Bytes erlauben einen gesammelten Abschnitt.
- Ein Fehler beim Start eines späteren ADB-Prozesses wird erfasst und kann nicht durch frühere Aufnahmen zu einem falschen PASS werden.
- Aufnahmegröße 960 × 540, Bitrate, 180-Sekunden-Abschnitte sowie die bisherigen Grenzen 200/20/90/115 Sekunden bleiben erhalten. Die getrennte cmdline-Prüfung und Signalzustellung stellen keine atomare PID-Reuse-Garantie dar.

`tools/android_qa/tests/test_kart_video_recorder.py` führt die echte Recorder-Implementierung mit **19 konstruierten, deterministischen Prozessabläufen** aus. Dieselben Testbytes laufen gegen die exakten Originalbytes von d405 (54.526 Bytes, SHA-256 `4e19fed0117bbb878b1b79c0fa3e3e2c0e72da53380d5402b31d8370d9bb3b7f`) und den Kandidaten. Die Tests ersetzen ausschließlich Betriebssystem- und ADB-Grenzen. Ihre synthetischen Dateibytes sind kein Videonachweis und gelangen nicht in die Android-Belegsammlung.

Die CI verlangt zuerst das spezifische erwartete RED des Originals, anschließend GREEN des Kandidaten, Hashgleichheit der Tests und Bytegleichheit aller Probe-Bereiche außerhalb der Recorder-Klasse. Prozessfehler, fremde oder mehrdeutige PIDs, nicht erfolgreiche Beendigung und Zeitüberschreitungen müssen weiterhin scheitern.

Der neue Android-Lauf prüft danach **dieselbe unveränderte APK**. Es wird erst nach einem tatsächlichen erfolgreichen Emulatorlauf ein Gesamtnachweis erstellt. Die Fehlerrunden 37975946198, 37987154620 und 37987900281 bleiben als Historie sichtbar.
