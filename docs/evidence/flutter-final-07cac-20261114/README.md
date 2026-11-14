# Vollständige Flutter-Abnahme auf 07cac722

## Tatsächlicher Originalbefund

Host: `07cac7225e2f7b6451665dfda9c38841f51c758b`  
Tree: `17b4d10565001b61fe1fa5012004cce4ec7642d9`  
Run: https://github.com/Ullmann27/lumo-lernen/actions/runs/43586101225, Versuch 1, Job `132421769277`.

Die vollständige Flutter-Suite ist **PASS: 2625 bestanden, 0 fehlgeschlagen, 0 übersprungen, 0 Capturefehler, 566 erzeugte PNGs**. Der Runner meldet Exitcode 0, einen erfolgreichen Abschluss und keine Watchdogfehler. Schritt 13 lief von 10:42:16 bis 10:53:06 UTC, also 650 Sekunden.

Diese Summen wurden aus dem unveränderten Originaljoblog selbst gelesen: Gitblob `c246b7ddce9d1b66db659a93b0af8abec539ee0d`, ursprüngliche UTF-8-Länge 1370502 Bytes, Zeile 808 mit Timestamp `2026-11-14T10:53:06.9680009Z`. Der tatsächliche Hostcheckout ist im selben Originalprotokoll ausdrücklich `07cac7225e2f7b6451665dfda9c38841f51c758b`. Der vollständige Log ist unverändert bei QA-Commit `a54556aef3c705af6aa42aa485bb7fec40480ddf` unter `docs/evidence/live-integration-20261114/final-07cac722/terminal-verify-and-build/job-132421769277-original.log` gespeichert. Die normale Contents-API liefert bei dieser Dateigröße keinen Inhalt; der erlaubte GitBlob-Abruf wurde deshalb für die unabhängige Textprüfung verwendet.

`original-summary-stdout-line-808.txt` bewahrt die vollständige Originalzeile. `acceptance-summary-from-original-stdout.json` enthält exakt ihren JSON-Nutzinhalt. `source-map.json` hält die vollständige Quelle und die genauen Grenzen fest.

## Bildserien und Diktat

Der Originalreport zählt unter anderem Dorf 6, Home-Premium 8, Home-Nextgen 6 und Lernabenteuer 80 PNGs. Alle Verzeichniszahlen zuzüglich der einzelnen Pokaldatei ergeben zusammen exakt die gemeldeten 566 PNGs. Die gesamte Verteilung steht unverändert im JSON-Auszug.

Die drei unveränderten Diktat-Regressionsfälle gehören zur vollständig und ohne Dateifilter aufgerufenen Suite. Der Originalgesamtbericht enthält keine Fehler oder Skips. Ihre einzelnen finalen JSONL-Abschlussereignisse wurden nach dem Umgebungsausfall nicht zusätzlich aus dem großen Archiv gelesen. Die zuvor direkt gelesenen erfolgreichen Einzelfälle auf cf2593 behalten ihre eigene Quellbindung.

Die vier echten geöffneten Home-Lernkartenbilder und sechs korrekt gerenderten Dorf-Originalbilder aus den vorausgehenden fokussierten Tests sind dauerhaft unter Evidenzcommit `34ea2eec68aa6b4e2f951d4ab4d4478961485ac7` gespeichert. Die finalen Testblobs auf 07 stimmen mit diesen zuvor getesteten Fassungen überein. Die neuen 07-PNGs wurden wegen des Umgebungsausfalls weder lokal gehasht noch visuell gegengelesen; frühere Bilder werden nicht als neue 07-Bilder ausgegeben.

## Eigenständige weitere Originalprotokolle

Der separate Home-Lauf `43586101113`, Job `132420784454`, ist SUCCESS und belegt 13 Home-Tests plus 8 Welt-Tests. Alle vier tatsächlichen Mathe-InkWells sind nach echter Expansion hit-testable. Sein Mergecheckout `f0ff3121347c99c5752438c883977d79a9823fda` hat per GitData unabhängig bestätigt exakt denselben gesamten Tree wie Host 07.

Der separate Workshop-Lauf `43586101300`, Job `132420785172`, ist SUCCESS und belegt auf direktem Hostcheckout 07 insgesamt 27 Tests. Die beiden vollständigen Originalprotokolle sind hier unverändert erhalten. Diese separat ausgeführten Tests werden nicht zur Zahl 2625 addiert.

## Grenze der gesamten Buildkette

Der übergeordnete Job endete am 14. November 2026 um 12:11:26 UTC mit `cancelled`. Die erste Native-Sammelprüfung 31 war erfolgreich (3531 Sekunden); die anschließende Live-/Discovery-Stufe 32 wurde nach 552 Sekunden abgebrochen. Der Native-Artefaktupload 33 war erfolgreich. Der APK-Build 34 und die abhängigen Android-/Delivery-Jobs wurden übersprungen. Deshalb ist dieser Flutter-PASS **keine neue APK-, Android-Runtime- oder Auslieferungsabnahme**.

## Originalarchiv und Umgebungsausfall

Artefakt `14109914601` (`lumo-candidate-all-flutter-tests-and-captures`) ist laut GitHub 363844187 Bytes groß, ZIP-SHA256 `fc254d6be40cb573559bc1a378c8f6baf469a9e09241a86c56ecd86fb2798476`. Seine Metadaten sind hier vollständig gespeichert. Während des einmaligen lokalen Transfers nach `/dev/shm/lumo-final-07cac-909ddb52fe7b` fiel die Arbeitsumgebung aus. Ein erfolgreicher lokaler Transferabschluss sowie ZIP-CRC-/PNG-Hashprüfungen wurden nicht zurückgemeldet. Es erfolgte keine lokale Wiederholung und kein zweiter Abruf des großen Originalarchivs.

Dieser Evidenzbranch verändert ausschließlich Nachweisdateien. App-, Test-, Native- und Workflowcode des geprüften Hoststands bleiben unverändert.
