# Host 8e64: vollständige Flutter-Suite mit einem C4-Fehler

**Tatsächlicher Stand:** Host `8e64f27c86e1704fa65dfe9ef9c8b2217f9f0a11`, Feature-Run **43634307306**, Attempt 1, Flutterjob **132567623144**. Der originale Jobstatus ist `completed/failure`; der Job endete am 14.11.2026 um 20:03:11 UTC. Die vollständige Suite lief tatsächlich. Eine Studio-Übernahme oder Gesamtfreigabe folgt daraus nicht.

## Ergebnis aus den Originalen

| Prüfbereich | Bestanden | Fehlgeschlagen | Übersprungen | Beleg |
|---|---:|---:|---:|---|
| Frühe bestehende Wallet-/Memory-Fokusgruppe | 30 | 0 | 0 | Eigenständiger Aufruf, Originaljob Zeile 670 |
| Vollständige Flutter-Suite | 2.676 | 1 | 0 | Originalsummary und vollständiger Maschinenstream stimmen überein |
| Darin: neue Memoryverträge | 25 | 0 | 0 | 25 konkrete Start-/Endpaare |
| Darin: neue Walletverträge | 14 | 0 | 0 | 14 konkrete Start-/Endpaare |
| Darin: neue C4-Verträge | 5 | 1 | 0 | 6 konkrete Start-/Endpaare |

Die 45 neuen Fälle ergeben **44 bestandene und einen fehlgeschlagenen Fall**. Jede Zuordnung enthält Suite-ID, Test-ID, vollständigen Namen und Originalzeilen von `testStart` und `testDone` in `actual-new-cases-review.json`; keine Anzahl wurde aus der Differenz zweier Gesamtsummen abgeleitet.

Die älteren zehn ASR- und 14 Memory-Durabilitätsfälle sind separat mit ihren aktuellen Originalpaaren als bestanden belegt. Auch die sechs bestehenden Memory-Profilfälle einschließlich der drei zuvor roten Fälle sind in `memory-profile-cases-review.json` einzeln bestätigt. Wiederholte Fokus- und Gesamtaufrufe werden nicht addiert.

## Ein konkret fehlgeschlagener C4-Fall

**„Lifecycle pause during reward retry defers the settled result“**, Test-ID 56, Suite 27, in `test/games/connect_four_bot_save_retry_test.dart`.

Der originale Frameworkbericht nennt Zeile **261:5**: erwartet `true`, tatsächlich `false`. Der Start steht in Maschinenzeile 115; Frameworkausgabe und Stack in 123, Fehlerereignis in 124, Abschluss `result=error`, `skipped=false` in 125. Die vollständigen zugehörigen Originalereignisse sind unter `failure-test-original-events.json` gebunden; die ausgewählten ursprünglichen JSONL-Zeilen liegen daneben. Die Ursache wird hier nicht weiter behauptet: Der Produkt-/Testeigentümer hat den unveränderten Fehler für die getrennte Diagnose erhalten.

Die finale Maschinenmeldung in Zeile 8480 lautet `done.success=false`. Auch der originale Runnerbericht meldet Exit 1 und genau diesen einen fehlgeschlagenen Fall.

## Quellen und unveränderte Grenzen

Der Commit nach 0d7e ändert exakt drei vorhandene Testdateien. Die zwei Wallet-Schlussprüfungen und die Memory-Profilfixture wurden angepasst; Produktdateien blieben unverändert. Die fünf Dateien der neuen bzw. älteren Einzeltestgruppen wurden am direkten Vorgänger gebunden und sind laut vollständiger aktueller Commitantwort unverändert geerbt. `source-binding.json` enthält die konkreten Gitblob- und SHA256-Werte.

Der Analyzer-Schritt ist erfolgreich, meldet aber weiterhin **0 Fehler, 5 Warnungen, 236 Hinweise** unter der bestehenden nichtfatalen Warnungs-/Hinweispolicy. Die nachgelagerte Prüfung auf unveränderte getrackte Arbeitskopie wurde nach dem Fullsuitefehler übersprungen. Ein positiver nachträglicher Arbeitskopiecheck wird nicht behauptet.

## Originale und Bereichsdownload

Das Joblog wurde genau einmal vollständig geholt: **127.983 Bytes**, SHA256 `b0db024d5f285c773bf580bdeca817e2657a6c7931370dc8e7f792aa7c256cd0`.

Das originale Flutter-Artefakt **14129347799** ist laut GitHub 342.973.028 Bytes groß und trägt den veröffentlichten Digest `8e3b3ef1f4967e4dbdfb507d8672b9e9f776e571d13030b4deee5a010a017d0a`. Dieser Gesamtarchivdigest ist **Metadatum, keine lokal nachgerechnete Gesamtarchivprüfung**.

Statt des großen Archivs wurden 15 streng begrenzte HTTP-Bereiche mit jeweils Status 206, exakt passendem `Content-Range`/`Content-Length` und unverändertem Encoding gelesen: insgesamt **241.057 Bytes**. Die vollständige zentrale Liste enthält 593 Einträge. Vier vollständige Originalmitglieder wurden CRC- und SHA-geprüft: Hoststempel, Flutterversion, Acceptance-Summary und Maschinenstream. Dessen **1.790.959 Bytes** haben SHA256 `a54cec8154dd7090740e0ef1c469bc9ae17b0ceb7884d01860b4f73de76adf21`. Der Hoststempel nennt exakt 8e64. Rohbereiche, zentrale Liste und Prüfbericht bleiben erhalten; temporäre Download-URLs werden nicht gespeichert.

Der Runner meldet 546 erzeugte PNGs. Sie wurden hier weder heruntergeladen noch visuell beurteilt. Der Bericht liefert keine Geräte-, Audio-/Modellinferenz-, Bildqualitäts- oder FPS-Abnahme.

[Originaljob](https://github.com/Ullmann27/lumo-lernen/actions/runs/43634307306/job/132567623144) · [Exakter Quellcommit](https://github.com/Ullmann27/lumo-lernen/commit/8e64f27c86e1704fa65dfe9ef9c8b2217f9f0a11).

Keine lokale Dart-/Flutter-Ausführung, keine neuen Produkt-/Workflowänderungen, kein CI-Rerun und keine Tree-/Refmutation durch diesen Review. Die beiden früheren fehlgeschlagenen Läufe bleiben getrennte Originalbelege.
