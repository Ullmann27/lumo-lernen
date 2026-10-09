# Lumo 1908 · selektiver App-Integrationsentwurf vom 9. Oktober 2026 UTC

Status: **SOURCE CHECKPOINT / FINAL PIN PENDING / VISUAL_GAP / NOT FINISHED**.
Dieser Quellabschluss wird auf dem Recoverybranch gesichert; er ist noch nicht
gebaut oder als Android-Runtime abgenommen. Eine einzige lokale Integration führt die beiden tatsächlich
aktuellen Quelllinien zusammen; neue fremde Arbeit wird dabei erhalten.

| Eingabe | Exakter Quellstand | Rolle |
| --- | --- | --- |
| Aktuelle App | `36391b2d2a332e93f3bac46bf21afb83fad15d8a` | Version 1907, neue IQ-/Analyze-Arbeit, FleetStats-/Workshop-CI |
| Gesicherte Recovery | `4458590063b9e59fc7f36fe9dea4e798b95a192a` | Ressourcen-PASS-Gate und Lifecycle10-Quellanschluss |
| Gemeinsamer Vorfahr | `8abb01a6bf470e46bd279f637ba84f850d98fab0` | Source20; spätere Recovery-Gates waren noch nicht enthalten |
| Unveränderter Ausgangspin | `99cdb776df10e8cc719d19792c17074c887b5112` | Godot-Ausgangsquelle; noch kein endgültiger gemeinsamer Pin |

Arbeitsbranch: `codex/lumo-integrated-1908-local`. Die neue Quellversion
`0.12.5+1908` liegt über der aktuellen 1907; die separate Recovery1906 ersetzt
keinen jüngeren App-Stand. Der ursprüngliche Recoverycheckout bleibt unverändert.

## Erhaltener und ergänzter Umfang

Die neuen IQ-Dart-Dateien, Tests und Bilder sowie Analyze-Bereinigungen bleiben
bytegleich zum aktuellen App-Stand. Der Workflow behält die 17 vorhandenen
GL-Schleifenproben und alle 24 Marker: die ursprünglichen 21, Zeitformat29,
FleetStats und Workshop. Der 45-Minuten-Androidjob, SDK-/Runner-/Abhängigkeiten,
Renn-/ACK-/Wallet-/Fold-/Video-Gates, Modal37/14 und Countdown9 bleiben erhalten.
Keine zusätzliche native Probe wird für Lifecycle10 erfunden.

Aus Recovery werden die beiden bestehenden Ressourcenphasen `first-driving`
und `completed-before-fold` vor dem endgültigen Kart-PASS verbindlich geprüft.
Beide benötigen PASS, passende Source-/Pin-/APK-/API-/Serialidentität und die
drei vorhandenen rohen Reads. Legitimes RSS-UNAVAILABLE bleibt erlaubt. Es gibt
keine neuen Geräteaufrufe, Messwerte oder Performance-Konversionen.

Der getrennte Lifecycle-Reader, seine ausdrücklich synthetische Fixture und
30 kontrollierten Guards werden übernommen. Der Workflow ergänzt die fünf
Summaryfelder `handoff_lifecycle_checks`, `handoff_lifecycle_evidence_sha256`,
`handoff_lifecycle_source_sha256`, `handoff_lifecycle_probe_sha256` und
`handoff_lifecycle_helper_sha256` sowie `exports/race-bridge/` als Artefaktpfad.
Die ursprünglichen 48 Android-QA-Tests/Fixtures und sechs Script-Testdateien
werden gegen den echten f6-Gitbestand bytegenau geprüft.

## Noch offene Quellbindungen

Die historische Lap-Fixture stammt aus `7e600`/`a984`. Ihre Unit-Tests benennen
und setzen diese historischen Konstanten ausschließlich für diese unveränderte
Schema-/Semantik-Replay. Das beweist keine aktuelle Bindung des neuen Pins.
Der CI-Reader wird weiterhin in einem frischen eigenen Prozess mit seinen
Produktionskonstanten geladen; eine globale Unit-Test-Änderung ist kein
Runtime-Freigabenachweis.

Der übernommene Lifecycle-Reader bindet zunächst den gesicherten Source25-Entwurf
`7247`/`f82`/`fb78`. Der gemeinsame geprüfte Godot-Stand soll den neuen Kartkern
und die leakfreie Main8129-/Helper16e-Testquelle verbinden. Diese Bindungen
werden erst gegen den tatsächlichen endgültigen Quellstand und frisch
geschlossene JSON-/PNG-/Lognachweise fortgeschrieben. Der gegenwärtige Drift
bleibt ein strenger Blocker; kein Wert wird nur zum Erzwingen grüner CI geändert.

## Nachweise und Grenzen

Der read-only Eingangsvergleich bestätigt App363, 1245 Git-Blobs und alle
48 ursprünglichen Android-QA-Dateien bytegleich zum echten f6. App und Recovery
divergieren ab Source20; die fehlenden späteren Gates waren kein belegter
bewusster Rollback. Historische Recovery-Suitezahlen werden nicht auf diesen
neuen Entwurf übertragen.

Aktuell geschlossen:579Android-QA+36Scripts PASS,0FAIL/ERROR/SKIP.
Unabhängig68Quell-/AST-Prüfungen PASS;22Bashsteps/sechs Pythonblöcke syntaktisch
geprüft.1240nicht ausgewählte fremde Einträge,48Original-QA/sechs Scripts,
17GL-Proben/24Native-Marker bleiben byte-/modegleich.

Godot-Recoverycheckpoint `a6c4d69b864feb476398ad18bd69f4ab8aea7b57` enthält
Profilbudget, exakte Main8129/Helper16e-Cleanups und gemessene HIGH-Lichtkorrektur.
Sein vollständiger gemeinsamer Runtime-Freeze ist noch offen; daher bleibt der
App-Pin99cdb bis zu den tatsächlichen finalen positiven Nativebelegen erhalten.
Endgültiger Godot-Pin, neue24Native-CI-Abnahme,1908APK,Android-Rennen,physischesFold,
Geräteperformance und Referenzabnahme: **PENDING / NOT EXECUTED**. Nach dem dritten Workspaceverlust verlorene frühere
Belegdateien werden nicht als lokal vorhanden behauptet. Neue Runtimebelege
besitzen eigene Abschluss- und Byteprüfungen.

Nächster Integrationsschritt: endgültigen gemeinsamen Godot-Commit und echte
Fixtures binden, aktuelle Produktionsreader ohne historischeOverrides positiv
prüfen; anschließend QA/Quellenpeer für diese geänderten Bindungen ausführen.
Erst danach den finalen Pin auf dem aktiven Integrationsbranch veröffentlichen
und einen neuen APK-Lauf starten. Main und Releases bleiben unverändert.
