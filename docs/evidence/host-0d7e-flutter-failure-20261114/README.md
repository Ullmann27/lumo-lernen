# Host 0d7e: Analyzer geschlossen, frühe Regression fehlgeschlagen

**Momentaufnahme des tatsächlichen Flutterjobs 132564402577 in Run 43633267932, Attempt 1, auf Host `0d7e6e5efb1fe8cd2e9a7f92cdd4034b81173304`.** Der Job ist laut gespeicherter originaler REST-Antwort `completed/failure` (Ende 2026-11-14 19:41:01 UTC).

## Tatsächlich erreicht

Die Analyzerprüfung (Schritt 6) ist erfolgreich. Das unveränderte Verfahren meldet 0 Fehler, 5 Warnungen und 236 Hinweise. Die beiden vorherigen `undefined_method`-Fehler aus e2db sind im aktuellen Original nicht mehr vorhanden. Der aktuelle Commit ändert ausschließlich zwei bewachte Typumwandlungen in `memory_round.dart`.

Danach lief die bestehende frühe Wallet-/Memory-Testgruppe (Schritt 7) tatsächlich: **23 bestanden, 7 fehlgeschlagen**, Prozessende 1. Das ist die Konsolensumme dieser drei Testdateien, keine Gesamtsuite und kein Maschinenstream-Nachweis der 45 neuen Fälle.

## Sieben belegte Fehler

| Quelle | Fälle | Konkreter Originalbefund |
|---|---:|---|
| `test/reward_wallet_queue_zone_test.dart:219/293` | 2 | Am Ende des Doppelaufrufs 3 statt 2 bzw. 4 statt 3 Schreibvorgänge. Der zusätzliche vollständige Snapshot ist identisch zur zuvor bestätigten Wallet. |
| `test/reward_wallet_transaction_test.dart:209` | 2 | Für `falseResult` und `exception` 5 statt 4 Schreibvorgänge; die beiden letzten Snapshots enthalten unverändert 9 Sterne, 25 XP und einmal `race-1`. |
| `test/games/memory_profile_storage_test.dart:175` | 1 | Zwei statt eines Stats-Schreibvorgangs: zunächst die geladene `leicht`/Bestwert-7-Bestätigung, anschließend `profi` mit demselben Bestwert. |
| `test/games/memory_profile_storage_test.dart:233/254` | 2 | Beim tatsächlichen Tippen fehlt das Widget `memory-diff-mittel` bzw. `memory-diff-leicht`. Der Quell-/Fixturebefund gehört zur getrennten Memory-Diagnose. |

Die vier Wallet-Schlusszählungen berücksichtigen die absichtlich neue positive Bestätigung einer schon bekannten Ergebnis-ID noch nicht. Die passende enge Korrektur muss alle bisherigen Zonen-/Reihenfolge-/Saldoassertions erhalten und den zusätzlichen **inhaltlich identischen** bestätigten Snapshot ohne zusätzliche Gutschrift/Emission prüfen. Dieser Bericht ändert keine Tests oder Produktdateien. Die drei Memoryfälle sind an deren Eigentümer übergeben; aus dem fehlenden Finder allein wird kein Produktgrund abgeleitet.

## Nicht ausgeführt

Schritte 8 bis 12 sind übersprungen, insbesondere tatsächliche Dart-Autoritäten und vollständige Flutter-Suite. Die **25 neuen Memory-, 14 Wallet- und 6 C4-Fälle** haben hier keinen `testStart`/`testDone`-Nachweis. Auch die älteren ASR10/Memory14 erhalten keinen übertragenen neuen PASS. Ein übersprungener Workflow-Schritt ist keine Anzahl übersprungener Frameworktests.

## Originalbindung

Das vollständige Joblog wurde genau einmal geholt: 121.892 Bytes, SHA256 `730624ed6be190ce6305d6b8c90e4d8eddb96c9a25ac22c5c4b4139c5e1b4ab2`. Die eindeutigen Fehler stehen in dessen Zeilen 650, 691, 747, 808, 913, 941 und 968; Schlusszählung Zeile 972, Exit 1 Zeile 980.

Artefakt `14128997674` wurde einmal vollständig geladen: 7.443 Bytes, SHA256 `874d49ace00e066c12e45c328c57e94a8fcc58b774b7f0d7a7bb44e8d597aa92`. Alle vier Dateien sind vollständig gelesen und CRC-geprüft. `HOST-SOURCE.txt` nennt exakt 0d7e. Enthalten sind außerdem Flutterversion, Analyzerlog und Fokusgruppenlog; kein Gesamtsuiten-JSONL und keine neuen Bilder. Ein großer Capture-Download war nicht nötig.

[Originaljob](https://github.com/Ullmann27/lumo-lernen/actions/runs/43633267932/job/132564402577) · [Quellcommit](https://github.com/Ullmann27/lumo-lernen/commit/0d7e6e5efb1fe8cd2e9a7f92cdd4034b81173304). Einzelne SHA-/Gitblob-Bindungen stehen in `diagnosis-source-bindings.json`, Originalmetadaten unter `metadata/`.

Keine lokale Dart-/Flutter-Ausführung, keine Paketinstallation, keine Produktänderung und keine Git-Ref-Änderung. Historische e2db-Negativevidenz bleibt unverändert.
