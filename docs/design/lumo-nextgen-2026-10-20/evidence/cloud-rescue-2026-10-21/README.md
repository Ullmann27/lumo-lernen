# Unveränderte Nachweise aus der ursprünglichen Cloud-Sitzung

Die PNGs wurden direkt aus `/workspace/scratch/lumo-first-render` und
`/workspace/scratch/lumo-second-render` übernommen. Es sind echte Flutter-
Widget-Render der Produktions-AppShell mit Testprofil, keine Geräteaufnahmen.
Iteration 1 dokumentiert Fehler; Iteration 2 ist ein noch nicht abgenommener
Zwischenstand. Keine Bilder wurden bearbeitet oder neu erzeugt.

Die Protokolle wurden unverändert von `.log` nach `.txt` kopiert, damit die
geprüfte Dateitypliste des Sicherungsskripts sie erfasst. `evidence-manifest.json`
enthält SHA-256 und Größen der übernommenen Nachweise. Das separate
`original-manifest.json` erfasst alle elf ursprünglich uncommitteten Dateien
vor jeder Branchänderung; dieser Inhalt muss im Rettungscommit identisch sein.

Die sechs früheren Baseline-PNGs bleiben unter `../before/` im Git-Verlauf.
Die Testdatei aus PR #394 enthält absichtlich synthetische Schlüssel-Testwerte;
sie wird nach Prüfung separat versioniert, weil der Sicherheitsfilter darauf
korrekt anspricht. Cache-/Builddateien werden nicht veröffentlicht.
