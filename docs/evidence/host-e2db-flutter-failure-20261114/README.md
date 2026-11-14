# Feature e2db0d60: Flutter vor Teststart abgebrochen

Der [tatsächliche Featurelauf 43632642356](https://github.com/Ullmann27/lumo-lernen/actions/runs/43632642356) auf [Host e2db0d60](https://github.com/Ullmann27/lumo-lernen/commit/e2db0d60af51266caa9b54ffd08eb0947ae99ac6) enthält einen abgeschlossenen, fehlgeschlagenen Flutterjob 132562421770. Maßgeblich sind die originalen REST-Metadaten für Versuch 1. Die Vollsuite wurde in diesem Job nicht gestartet.

## Konkreter Abbruch

Schritt 6, `Analyze all Flutter sources`, endet nach berichteten 18,2 Sekunden mit Exit 1. Das Original meldet zwei Fehler in [memory_round.dart](https://github.com/Ullmann27/lumo-lernen/blob/e2db0d60af51266caa9b54ffd08eb0947ae99ac6/lib/features/games/memory/memory_round.dart):

| Quelle | Fehler | Stelle im Originaljoblog |
|---|---|---|
|268:26| `confirmRoundReadback` ist für den statischen Typ `MemoryStore` nicht definiert (`undefined_method`).|459|
|277:26| `confirmStatsReadback` ist für den statischen Typ `MemoryStore` nicht definiert (`undefined_method`).|460|

Der unveränderte Analyzeraufruf lautet `flutter analyze --no-fatal-infos --no-fatal-warnings`. Seine 243 Meldungen sind exakt **2 Fehler, 5 Warnungen und 236 Informationen**. Die fünf Warnungen und ihre Dateistellen sind vollständig in `analyzer-diagnostics.json` dokumentiert. Sie werden nicht als zusätzliche Testfehler gezählt. Die folgende Exitmeldung steht im Originaljoblog auf Zeile 624.

## Keine Ausführungsabnahme der 45 neuen Fälle

Die Workflow-Schritte 7–12 sind übersprungen. Damit gibt es in diesem Lauf keine ausgeführten Ergebnisse für die 25 neuen Memory-, 14 Wallet- oder 6 C4-Fälle. Auch die vollständige Flutter-Suite hat kein Ergebnis. Das ist weder ein 45-facher Framework-Skip noch ein Test-PASS aus der bloßen Abwesenheit von Analyzerfehlern in den Testdateien.

Die alten 10 ASR- und 14 Memory-Fälle sowie ihre tatsächlich früher beobachteten Ergebnisse bleiben dem vorherigen 28462-Lauf zugeordnet. Sie werden hier nicht als neue Ausführung übernommen. Der nächste korrigierte Hostlauf muss die 45 neuen `testStart`-/`testDone`-Paare erst tatsächlich liefern.

## Vollständig gesicherte kleine Originale

Der abgeschlossene Joblog wurde genau einmal abgerufen und vollständig als UTF-8 einschließlich BOM gesichert: **91.649 Bytes**, SHA256 `049df35c0b103f01009f3190fd26498e36ea2e1014c9da53dc5784319e2fbfac`.

Das tatsächliche Flutterartefakt 14128393124 wurde ebenfalls genau einmal beschafft: **4.776 Bytes**, SHA256 `31f1c98d5c12cd07132a86aa5444318824f4d5722aef806f27e07c31bb5dde44`. Vollständiger Archivhash und alle drei CRCs sind geprüft. Alle Mitglieder sind unverändert extrahiert: `HOST-SOURCE.txt`, `flutter-analyze.log` und `flutter-version.txt`. Der Quellenstempel ist exakt e2db0d60; die Versionen lauten Flutter 3.44.9 und Dart 3.12.2. Das Archiv enthält weder einen Maschinenstream noch Bilder. Deshalb war kein großer Capture-ZIP-Download und auch kein HTTP-Range-Verfahren nötig.

Dieser Bericht ist negative Evidenz vor Teststart. Keine Produktdatei, kein Test, kein Workflow und kein Git-Ref wurde dafür geändert; kein lokaler Dart-/Flutterlauf oder CI-Rerun wurde gestartet. Root und der verantwortliche Memory-Owner erhielten die konkreten Originalfehler unmittelbar.
