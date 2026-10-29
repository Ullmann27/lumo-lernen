# Wiederaufnahme · Living Intelligence

1. Aktuellen Remote-Stand und offene PRs prüfen; keine lokale Arbeit überschreiben.
   Tutor-Kern: `feat/lumo-living-intelligence-20261029`, ab 9fdfc3f1.
   Letzter Produktionspatch: 6ac7ba9bf1ecef3a61ee91c3567628c519584780.
2. Draft-PR #414: Quellstand 5d6d7dcd, Lernkern-Job 40846028231 und
   Change-Review 40846027846 erfolgreich. 1.952 Tests, 171 übersprungen,
   43 fokussierte Fälle. Original-Artefakt und SHA liegen im Nachweiszweig.
   Weitere tatsächliche GitHub-Jobs prüfen. Der neue Workflow
   `.github/workflows/lumo-living-intelligence-core.yml` führt Analyse, alle
   Intelligence-Fälle, echte Routenaufnahmen und die vollständige Flutter-Suite
   auf dem PR-Head aus. Artefakte enthalten Source-SHA und Protokolle.
3. Lokal reproduzieren mit Flutter 3.44.9:
   `flutter pub get --enforce-lockfile`,
   `flutter analyze --no-fatal-infos --no-fatal-warnings`,
   `flutter test --no-pub --reporter=expanded --timeout=60s --concurrency=2`.
   Für neue Aufnahmen `LUMO_INTELLIGENCE_EVIDENCE` und
   `LUMO_TUTOR_BRAIN_CAPTURES` auf ein geprüftes Ausgabeverzeichnis setzen.
4. Keine erneute Erfindung des Kerns: Engine, Graph, Contract, Validator,
   Write-ahead-Beleg und echte Stellenwert-Routen existieren. Methodenfeedback
   ist keine Kompetenz; zusätzliche Hilfe im Transfer bleibt unterstützt.
   Die ursprüngliche Profil-Lease darf akzeptierte Arbeit weiter speichern,
   eine fremde Generation darf keinen Abschluss übernehmen.
5. Android-Auslieferung ist getrennt in Draft-PR #415 vorbereitet:
   feat/lumo-living-intelligence-2002-20261029, ff791642a0d28d10f89d98025fd8f5fb2c19c403.
   Läufe 40846950267 (Gesamtbuild/Tour), 40846950656 (echtes Update) und
   40846950358 (Veröffentlichung) bis zum tatsächlichen Ende prüfen. Build 2000 ist veröffentlicht,
   2001 gehört dem bisherigen Tutor-Branch. Für einen eigenen neuen Kandidaten
   Version, Pin-Policy, Tour, echtes 2000-Update und immutable Direct-APK-Gate
   separat fortschreiben. Alte Workflows/Signaturen/Assets nicht überschreiben.
   Erst nach tatsächlichen Gates einen neuen Chrome-HTTPS-Link ausgeben.
6. Weiterer Fachumfang: echte Textstellen-/Silben-/Satzbau-Szenen an vorhandene
   Module anbinden; jeder Prozess braucht einen passenden Validator. Der
   14-Knoten-Graph ist eine partielle Aufgabenlandkarte, kein vollständiger
   Lehrplannachweis. Lokale Spracheingabe erst nach echtem Gerätenachweis.

Regelmäßig `python3 tools/lumo_autosave.py once` ausführen. Checkpoints mit
`[skip ci]` sind Sicherungen, keine Qualitätsfreigabe. Vor dem nächsten PR-Head
einen regulären Commit erzeugen und dessen CI-Ausführung überprüfen.
