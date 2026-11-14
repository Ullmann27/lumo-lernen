# Host 28462: tatsächlicher Flutter-Gegenlauf für ASR- und Memory-Korrektur

Der [Featurelauf 43624674585](https://github.com/Ullmann27/lumo-lernen/actions/runs/43624674585) ist auf exakt `28462a7547048b75fa114e6f5832248e54c94faa` abgeschlossen. Alle drei Jobmetadaten melden SUCCESS. Diese Prüfung gehört zum Flutterjob **132537752822**, beendet am **14. November 2026 um 18:15:59 UTC**.

## Ergebnis aus Originalen

Die vollständige Flutter-Suite meldet **2.632 bestanden, 0 fehlgeschlagen, 0 übersprungen**, Flutter-Exitcode 0 und ein erfolgreiches finales Machine-Event. Die eigenständige `acceptance-summary.json`, die Original-Joblog-Zeile 846 und eine erneute Auswertung aller Machine-Ereignisse stimmen überein. Die 546 erzeugten PNGs sind hier nur als Runner-Ausgabe dokumentiert; sie wurden für diese enge Regression weder heruntergeladen noch persönlich angesehen.

Die neuen Fälle sind **einzeln über Suitepfad, Testnamen, Test-ID, testStart und testDone belegt**, nicht aus einer Änderung der Gesamtzahl abgeleitet:

| Neuer Vertrag | Wirklich ausgeführte Fälle | Original-Machine-Zeilen | Ergebnis |
|---|---:|---|---|
| ASR-Beobachtungen → Elternbericht/Tagesempfehlung | 10 | 1623–1642 | alle success, nicht hidden, nicht skipped |
| Memory: bestätigte Plattformpersistenz und Profilgrenzen | 14 | 2731–2764 | alle success, nicht hidden, nicht skipped |

`actual-new-cases-review.json` enthält alle 24 vollständigen Namen und ihre unveränderten Originalereignisse. Die ASR-Fälle prüfen unter anderem unsichere/anfängliche Beobachtungen, fremde Profile, echte positive und negative SkillRecords sowie erhaltene historische Speicherdaten. Die Memory-Fälle prüfen abgewiesene und fehlgeschlagene Writes, verlorene Antworten, erneute Plattformlesung, Profilentzug und verspätete alte Ownerantworten. Die beiden Testdateien sind an die veröffentlichten Gitblobs des aktuellen Host gebunden.

## Originalbezug ohne großes ZIP

Der vollständige ursprüngliche Joblog wurde **genau einmal** abgerufen: 122.465 Byte, SHA256 `6102c286ef6baa0b4ef287775f8b9162c692d17b3fb19353cc0235f79419f4f1`.

Das Artefakt `14125828378` hat laut GitHub 343.185.779 Byte und den veröffentlichten Digest `29d6d2eb056010ed29b09dc82719acd29eb2d9a69d600f663b0ebbebc367b0bd`. Es wurde **nicht vollständig lokal heruntergeladen**. Stattdessen wurden nur strikt bestätigte HTTP-206-Bereiche mit exakten Content-Range-/Content-Length-Werten gelesen: insgesamt 238.563 Byte. Die vollständige Centraldirectory enthält 593 Mitglieder; ihre Originalbytes und SHA256 sind gesichert.

Vollständig gelesen und per Mitglieds-CRC geprüft wurden genau vier Originaldateien: `HOST-SOURCE.txt`, `flutter-version.txt`, `full-flutter/acceptance-summary.json` und `full-flutter/flutter-machine.jsonl`. Letztere hat 1.767.777 Byte und SHA256 `273c38c24fa7694f15f21ed9d2aba05a6f39e6be6591620f1a34b3c1977be939`. Der Hoststempel stimmt mit dem Run und Checkout überein. Eine vollständige lokale ZIP-SHA- oder Gesamt-CRC-Prüfung wird ausdrücklich nicht behauptet.

## Hinweise und Grenzen

Die tatsächliche Analyse meldet **214 Hinweise, 5 Warnungen und 0 Fehler**. Das bestehende Kommando behandelt Infos und Warnungen nicht als fatal. Fünf neue stilistische Hinweise betreffen den neuen Memorytest; am neuen ASR-Test meldet die Analyse keine Hinweise. Alle 219 Meldungen bleiben mit Originalzeilen in `analysis-observations.json` erhalten und werden nicht pauschal als harmlos bezeichnet.

Die ASR-Fälle sind Berichts-/Repository-Verträge, keine Mikrofonmessung. Die Memory-Fälle verwenden eine ausdrücklich simulierte Plattformgrenze, keine physische Android-Speicherausfallprüfung. Die früh wiederholten Fokusgruppen werden nicht zu den 2.632 Tests addiert. Es wurden für diesen Nachweis keine lokalen Dart-/Flutter-/pub-get-Kommandos ausgeführt. Der Flutter-Erfolg belegt keine neue Java-Modellinferenz, keine gehörte englische Aussprache und keine Android-/60-FPS-Freigabe.
