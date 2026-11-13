# Host PR465: Originale Auxiliary-CI auf 38a49f7d

## Quellenbindung und Abgrenzung

Veröffentlichter Head: **38a49f7dda404923da3955592ccb213871f2027d**. Tree: **625b7940d9e8a4ddf32203126721efd97b3e8c2e**. Lokaler Zwilling: 44dfd78d8a998cccb09d20bc974fb699dddd925e. Die tatsächlich in mehreren Jobs verwendete PR-Merge-Revision e2181cdbbc94d771865763144039f82de6b996ea hat laut vollständigem Original-Git-Commit-JSON denselben Tree.

Dieses Paket enthält ausschließlich die zusätzlichen Host-Workflows. Der Android-Hauptlauf **43497829121** wird separat betreut und ist von der Bewertung ausgeschlossen. Die vollständigen REST-Abfragen enthalten seinen damaligen Zustand als unveränderten Originaldatensatz; daraus wird hier keine Aussage zu dessen Abschluss abgeleitet.

## Tatsächliches Ergebnis

Neunzehn Auxiliary-Run-Datensätze betreffen siebzehn verschiedene Workflows: acht aktuelle Workflows erfolgreich, ein aktueller Workflow fehlgeschlagen, acht durch ihre bestehenden Branch-/Versionsbedingungen vollständig übersprungen. Zwei zusätzliche Datensätze sind abgelöste Change-Review-Läufe mit unverändertem Head und tatsächlichem Status CANCELLED.

| Aktueller Run | Workflow | Tatsächlicher Nachweis |
| --- | --- | --- |
| 43498405358 | Change review | Drei Jobs SUCCESS; komplette Flutter-Suite 2316 bestanden, 196 übersprungen. |
| 43497828939 | Living intelligence core | 48 fokussierte Flutter-Tests; danach 2316 bestanden, 196 übersprungen. |
| 43497828811 | Living workshop | 27 Flutter-Tests bestanden. |
| 43497829077 | Cards reference hub | 15 Flutter-Tests bestanden. |
| 43497829178 | Cards route | Ein Flutter-Test bestanden; gezielte Analyse ohne Befund. |
| 43497829123 | Tour identity | Vier Python-Vertragstests bestanden. |
| 43497829110 | Cropped HUD OCR | Drei Python-Tests bestanden. |
| 43497828918 | Family draft | Neun Python-Vertragstests bestanden; Build und Upload korrekt auf workflow_dispatch begrenzt und hier übersprungen. |
| 43497829047 | Script recovery | 436 Tests ausgeführt; genau ein fehlgeschlagener alter Scroll-Beobachtungsvertrag. |

Die beiden vollständigen Flutter-Analysen melden jeweils **103 Infos, fünf Warnungen und null Fehler**. Die unveränderten Workflowaufrufe verwenden --no-fatal-infos --no-fatal-warnings. Erfolgreiche Actions-Schritte werden deshalb nicht als hinweisfreie Analyse dargestellt. Die vollen 196 Skip-Fortschritte je Gesamtsuite bleiben im Log und in den abgeleiteten Skip-Indizes sichtbar. Bei parallel laufenden Flutter-Tests ist die daneben gedruckte Testbezeichnung nicht zwingend der übersprungene Fall; die Indizes behaupten dies ausdrücklich nicht.

## Echter Fehler und separat belegte Reparatur

Script-Recovery-Job 132135469969 scheitert an test_existing_default_search_is_not_silently_unbounded: erwartet 24 Accessibility-Abfragen, tatsächlich 26. Der integrierte echte Helper führt unverändert höchstens zwölf Gesten je Richtung aus und beobachtet zusätzlich die nach der letzten erlaubten Geste erreichte Ansicht. Es bleiben insgesamt 24 Gesten; erforderlich sind 13 Beobachtungen je Richtung.

Der vollständige Originaljob und das unveränderte Original-ZIP **14073430687** sind vorhanden. ZIP-SHA256: d1a4b7dcb5da29a2950542af803140db1dc1ab872df859b55e349af50b5209b4. Enthalten ist die komplette app-script-tests.log mit 89.715 Bytes.

Der separat eingefrorene Ordner scroll-contract-repair/ enthält den echten lokalen Red, die eng begrenzte Korrektur ausschließlich in scripts/tests/test_android_voice_scroll.py und den danach erfolgreichen Lauf der sieben bestehenden Voice-/Return-Tests gemeinsam mit sechs unveränderten Final-Scroll-Gegenfällen. Das Ergebnis sind 13 bestandene Tests; das Gestenlimit und beide abschließenden Beobachtungen werden ausdrücklich geprüft. Der originale CI-Lauf bleibt **FAILURE**. Dieser lokale Green ist kein neu gestarteter CI-Lauf und keine Android-Freigabe.

## Ablösung und erwartete Skips

Change-Review 43497829266 wurde von 43497966045 abgelöst; auch dieser wurde abgebrochen. Der abschließende Lauf 43498405358 ist erfolgreich. Der Workflow reagiert auf pull_request.edited und nutzt cancel-in-progress. Die letzte Ablösung entspricht Roots ausdrücklich angekündigter PR-Beschreibungsänderung. Alle drei Runs tragen denselben Source-Head. Vollständige abgebrochene Joblogs, tatsächliche Job-/Stepzustände und die jeweils fehlenden ausgeführten Statusjob-Schritte bleiben erhalten.

Die acht vollständig übersprungenen Workflows sind die historischen 1999/2000/2001/2002/2003-Update-/Releasepfade, der für unsere Branch ausdrücklich ausgeschlossene Unified-Workflow und der ausschließlich für den Studio-Producer bestimmte 2019-Workflow. Exakte Bedingungen stehen bytegleich in workflow-source/ und lesbar im workflow-source-index.json. Es wurde kein Schutz geändert oder Lauf wiederholt.

## Originale und Index

- workflow-runs-final.json.gz: vollständige abschließende REST-Liste; initial/ bewahrt frühere Originalzustände.
- jobs-*.json.gz: vollständige finale Job-/Stepdaten aller 19 Auxiliary-Runs.
- job-*.log.gz: alle 15 tatsächlich erzeugten Joblogs; Jobs ohne ausgeführte Schritte werden nicht mit erfundenen Logs ergänzt.
- source-commit, source-ref, pull-465-initial/final und pr-merge-commit: Original-Quellenbindung.
- workflow-source/: die siebzehn unveränderten Workflowdateien aus dem verifizierten lokalen Tree-Zwilling, mit Blob- und SHA256-Index.
- verification-summary.json: abgeleitete Bewertung, tatsächliche Checkouts, PASS-/Failuremarker, Warnungen und Skips.
- manifest.json: SHA256 und Bytegrößen aller enthaltenen Dateien; für GZIP zusätzlich die vollständigen dekomprimierten Originalbytes.

Keine Produkt-, Workflow-, Pin-, Receipt-, Index-, Commit- oder Refänderung durch diese CI-Sammlung. Das einzige separat autorisierte Source-Delta ist der dokumentierte Testvertrag. Keine Aussage dieses Pakets ersetzt die aktuelle Android-Hauptabnahme oder eine spätere Quellenprüfung.
