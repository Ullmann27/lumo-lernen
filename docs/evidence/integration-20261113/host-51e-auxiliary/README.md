# Host PR465: frische Auxiliary-CI auf 51e92fb5

## Quelle und Umfang

Veröffentlichter Head: **51e92fb5afab232a29850ffefef5637359af08f7**. Tree: **a13ab981d917c7788f35318cf10d962c1bf657f7**. Parent: 38a49f7dda404923da3955592ccb213871f2027d. Lokaler Tree-Zwilling: 488ef9b11f6d3c2e3164953ea82f445ef09b72ac.

Die tatsächlich in mehreren Jobs ausgecheckte PR-Merge-Revision **3b9309ddf6b209a02f3e41b4b72bbc1e060518bd** hat laut vollständigem Original-Git-Commit-JSON denselben Tree. Andere Jobs checken den Source-Head direkt aus. Koordinations-/Statusjobs ohne Checkout sind ausdrücklich als Metadatenjobs gekennzeichnet.

Der separat betreute Android-Hauptlauf **43502594333** bleibt von dieser Bewertung ausgeschlossen. Die vollständigen REST-Listen enthalten seinen damaligen Originalzustand; daraus wird hier keine Aussage zur tatsächlichen Emulator-/APK-Abnahme abgeleitet.

## Tatsächlicher neuer Abschluss

**Alle neun aktiven Auxiliary-Workflows erfolgreich; acht ganze Workflows erwartungsgemäß übersprungen.** Es wurden für diesen Source-Head keine ersetzten, abgebrochenen oder wiederholten Runs beobachtet. Alle erfassten Runs sind Attempt 1. Elf ausgeführte Jobs und sämtliche 89 ausgeführten Jobschritte sind SUCCESS. Die 26 übersprungenen Jobs haben keine ausgeführten Schritte.

| Run | Workflow | Tatsächlicher Nachweis aus dem neuen Original |
| --- | --- | --- |
| 43502593875 | Script recovery | **472 Tests bestanden**, 172,732 s, Footer OK; keine Fehler oder Skips. |
| 43502593799 | Change review | Drei Jobs SUCCESS; volle Flutter-Suite 2316 bestanden, 196 übersprungen. |
| 43502594257 | Living intelligence core | 48 fokussierte Flutter-Tests; danach volle Suite 2316 bestanden, 196 übersprungen. |
| 43502593749 | Living workshop | 27 Flutter-Tests bestanden. |
| 43502594007 | Cards reference hub | 15 Flutter-Tests bestanden. |
| 43502594046 | Cards route | Ein Flutter-Test bestanden; gezielte Analyse ohne Befund. |
| 43502593983 | Tour identity | Vier Python-Vertragstests bestanden. |
| 43502594148 | Cropped HUD OCR | Drei Python-Tests bestanden. |
| 43502594139 | Family draft | Neun Python-Vertragstests bestanden; Build und Upload bleiben auf workflow_dispatch begrenzt. |

Die vier gespeicherten umfassenden Analyseausgaben melden jeweils **103 Infos, fünf Warnungen und null Fehler**; die bestehenden Befehle erlauben nichtfatale Infos/Warnungen. Dies wird nicht als hinweisfreie Analyse ausgegeben. Die beiden aktuellen Flutter-Gesamtsuites enthalten jeweils tatsächlich 196 Skips. Deren vollständige Fortschrittszeilen bleiben im Original und in den abgeleiteten Skip-Indizes sichtbar. Bei parallelem Reporteroutput kann die daneben gedruckte Testbezeichnung zu einem anderen Test gehören; die Indizes behaupten keine eindeutige Namenszuordnung.

## Neue Script-Abnahme und erwarteter negativer Gegenfall

Der zuvor auf 38a fehlgeschlagene Default-Scroll-Vertrag steht im neuen Original ausdrücklich auf ok. Ebenso bestehen die neuen API37-Workflow-/AVD-Gegenverträge. Die frühere rote CI wird nicht umetikettiert; die aktuelle Abnahme stammt vollständig aus dem neuen 51e-Run.

Originalartefakt **14075845335**: lumo-astra-app-script-full-log-43502593875, ZIP 15.220 Bytes. Offizieller und lokal verifizierter SHA256: **c0d6de764c8c9c270ae087999fa8112978e344a6d2381218fecddb69d08977e9**. Enthaltene vollständige app-script-tests.log: 96.363 Bytes, SHA256 0fb18cfb1afbe57c032ccb6de5d0c590da89426fe20c4cd2a7d3f94e090be3ad.

Die gedruckte JSON-Zeile status FAIL mit reason actual_cli22_avd_binding_not_verified gehört zum absichtlich negativen Unit-Fixture test_failed_actual_avd_binding_cannot_reach_framework_acceptance. Dieser Test besteht und verlangt, dass eine fehlgeschlagene AVD-Bindung nicht zur Frameworkfreigabe führt. Wegen gepuffertem stdout erscheint die JSON-Zeile später neben einer anderen Testzeile. Sie ist kein tatsächlicher SDK-/Android-Lauf und kein unterdrückter CI-Fehler. Der vollständige Lauf endet mit 472 Tests und OK.

## Unveränderte SDK-Originalbytes

input-source/ enthält die tatsächliche Git-Datei scripts/tests/fixtures/android37_image_43494312623/source.properties einschließlich ihrer ursprünglichen zusätzlichen LF-Leerzeile am Dateiende. Es wurde nichts normalisiert. Blob: **8e0a9ce9cb7af106a9e8f55c06e83bfccbb67085**; 359 Bytes; SHA256 **1f50787fdc2c40508ba14e4bfb1e402c8a71bf435a59f9301e0f841807a07f8e**. Die letzten beiden Bytes sind 0a0a. In diesen Auxiliary-Läufen entstand daraus kein fehlgeschlagener Test.

## Skips und Originalaufbewahrung

Die acht ganzen Skips betreffen die bestehenden historischen 1999/2000/2001/2002/2003-Update-/Releasepfade, den auf unserer Branch ausgeschlossenen Unified-Workflow und den ausschließlich producergebundenen Studio-Workflow. Die exakten Bedingungen stehen unverändert in workflow-source/ und im Blob-/SHA256-Index. Die beiden Family-Draft-Nachfolgejobs erfordern workflow_dispatch.

- workflow-runs-final.json.gz: komplette abschließende Original-REST-Liste; initial/ enthält frühere Originalzustände.
- jobs-*.json.gz: vollständige finale Job-/Stepdaten aller siebzehn Auxiliary-Runs.
- job-*.log.gz: alle elf tatsächlich erzeugten vollständigen Joblogs. Keine erfundenen Logs für Jobs ohne ausgeführte Schritte.
- source-commit, source-ref, pull-465-initial/final und pr-merge-commit: vollständige Originalbindung an Source und Tree.
- workflow-source/: siebzehn Workflowdateien bytegleich aus dem bestätigten lokalen Tree-Zwilling.
- verification-summary.json: abgeleitete Bewertung mit tatsächlichen Checkout-SHAs, Markern, Skips und Warnungen.
- manifest.json: Größen und SHA256 aller Dateien; GZIP-Dateien zusätzlich mit vollständigen dekomprimierten Originalhashes.

Die Sammlung schreibt ausschließlich diesen neuen Evidenzordner. Keine Tests lokal gestartet, keine Sources/Fixtures, Pins, Receipts, Indizes, Commits oder Refs verändert. Alte 38a-Nachweise bleiben getrennt und unverändert. Dieser Auxiliary-Abschluss ersetzt weder den aktuellen Android-Hauptlauf noch eine APK-Veröffentlichungsfreigabe.
