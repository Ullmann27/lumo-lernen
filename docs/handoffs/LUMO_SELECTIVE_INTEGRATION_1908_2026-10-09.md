# Lumo 1908 · selektiver App-Integrationsentwurf vom 9. Oktober 2026 UTC

Status: **SOURCE READY / LINUX RUNTIME PASS / VISUAL_GAP / NOT FINISHED**.
Dieser Quellabschluss wird auf dem Recoverybranch gesichert; er ist noch nicht
gebaut oder als Android-Runtime abgenommen. Eine einzige lokale Integration führt die beiden tatsächlich
aktuellen Quelllinien zusammen; neue fremde Arbeit wird dabei erhalten.

| Eingabe | Exakter Quellstand | Rolle |
| --- | --- | --- |
| Aktuelle App | `36391b2d2a332e93f3bac46bf21afb83fad15d8a` | Version 1907, neue IQ-/Analyze-Arbeit, FleetStats-/Workshop-CI |
| Gesicherte Recovery | `4458590063b9e59fc7f36fe9dea4e798b95a192a` | Ressourcen-PASS-Gate und Lifecycle10-Quellanschluss |
| Gemeinsamer Vorfahr | `8abb01a6bf470e46bd279f637ba84f850d98fab0` | Source20; spätere Recovery-Gates waren noch nicht enthalten |
| Ausgangspin | `99cdb776df10e8cc719d19792c17074c887b5112` | Historische Godot-Ausgangsquelle |
| Endgültiger Godot-Pin | `3f9ff57b15e27b373e4baf696c43af3fa0ef9ca0` | 915 exakte Quellpfade; 24 aktuelle Linux-Native-Einträge geschlossen PASS |

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

## Aktuelle Quellbindungen

Die historische Lap-Fixture stammt aus `7e600`/`a984`. Ihre Unit-Tests benennen
und setzen diese historischen Konstanten ausschließlich für diese unveränderte
Schema-/Semantik-Replay. Das beweist keine aktuelle Bindung des neuen Pins.
Der CI-Reader wird weiterhin in einem frischen eigenen Prozess mit seinen
Produktionskonstanten geladen; eine globale Unit-Test-Änderung ist kein
Runtime-Freigabenachweis.

Die beiden Produktionsreader binden jetzt den endgültigen Kartkern `00e4`,
Main8129 und Lifecycle-Helper16e. Ihre frisch ausgeführten GL104-/Lifecycle10-
JSONs, sieben PNGs, Flow9, Time29 und strengen Producerlogs wurden direkt aus
dem finalen Freeze akzeptiert. Dafür wurden keine historischen Unit-Validatoren
importiert oder Produktionskonstanten überschrieben. 22 zusätzliche aktuelle
Kontrollen prüfen echte positive Rohdaten und kontrollierte fehlerhafte
Quellbindungen, Reihenfolge, Beobachtungen, Rewardduplikate, PNGs und Logs.
Die zehn ausdrücklich synthetischen Lifecycle-Beobachtungen bleiben bytegleich
in ihrem Inhalt; nur ihre drei Quellmetadaten wurden angepasst.

Der CI-Workflow installiert Tesseract einschließlich Deutsch vor den
OCR-gebundenen Quelltests. Lokal ist nur Englisch/OSD vorhanden; die neue
Deutschinstallation ist kein lokal ausgeführter Erfolg. Nach dem exakten Import
laufen Profile24 und der getrennte headless Finish16-Test einmal mit dem
vorhandenen strengen Runner. Der neue Finish16-Reader bindet sechs Quellen,
das offizielle Enginebinary, 16 geordnete typisierte Beobachtungen, numerische
Grenzen, rohe Bewegungsframes und Fehler-/Leakfreiheit. 94 Kontrollen inklusive
echter positiver Daten, echter roter Basis und gespiegelter falscher PASS-Werte
sind bestanden. Das sind Zustandsfixtures auf echter Geometrie; sie ersetzen
kein gefahrenes Rennen. Die bestehenden 17 GL-/24 Native-Verträge bleiben
unverändert, alle Ausgaben liegen unter dem vorhandenen Fold-Artefaktpfad.

## Nachweise und Grenzen

Der read-only Eingangsvergleich bestätigt App363, 1245 Git-Blobs und alle
48 ursprünglichen Android-QA-Dateien bytegleich zum echten f6. App und Recovery
divergieren ab Source20; die fehlenden späteren Gates waren kein belegter
bewusster Rollback. Historische Recovery-Suitezahlen werden nicht auf diesen
neuen Entwurf übertragen.

Aktuell geschlossen: 579 Android-QA + 36 Scripts PASS, 0 FAIL/ERROR/SKIP.
Die ursprünglichen 68 unabhängigen Quell-/AST-Prüfungen gehören zum vorherigen
selektiven Checkpoint. Die finalen 24 Bashsteps und sieben eingebetteten
Pythonblöcke sind syntaktisch geprüft. Alle 1242 nicht ausgewählten Einträge
gegen App-HEAD `afa7d80c937bd8d660551d49e78bbc0915599623` sind bytegleich.
48 Original-QA-Dateien/sechs Scripts und alle 86 historischen Lapguards
bleiben erhalten; ihre Zahlen werden nicht als neue Runtimeausführung gezählt.

Der endgültige Godot-Stand enthält Profilbudget, Main8129/Helper16e-Cleanups,
die gemessene HIGH-Lichtkorrektur und den gegen die rote Basis geprüften und
als grüne V3 übernommenen physischen Zielauslauf. Der exakte Freeze wurde für alle
24 Linux-Native-Einträge erneut ausgeführt: geschlossen PASS, einschließlich
der ursprünglichen 17 GL-Schleifenproben. Profile24 ist separat geschlossen.
Das Linux/Mesa-Ergebnis beweist weder Android-Leistung noch Referenztreue.
Finish16 wurde außerdem nach Veröffentlichung auf dem vollständigen kanonischen
915-Quellstand erneut headless ausgeführt: 16 Kontrollen, 1759 rohe Posen,
Engineexit 0 und sämtliche 915 Quellbytes/-modes vorher/nachher exakt. Der aktuelle
Reader akzeptiert diesen eigenen Nachweis; die Zahl der 24 Native-Einträge steigt
dadurch nicht.
1908-APK, neue Android-Rennen, physisches Fold, CPU-/GPU-Framezeiten und
Referenzbewegungsabnahme: **PENDING / NOT EXECUTED**. Nach dem dritten Workspaceverlust verlorene frühere
Belegdateien werden nicht als lokal vorhanden behauptet. Neue Runtimebelege
besitzen eigene Abschluss- und Byteprüfungen.

Der Android-Vollrennenlauf der fremden Version1907 überschritt auf API36 seinen
bestehenden 1200-Sekunden-Grenzwert. Wiederholte Aufnahmen/OCR und Readiness wurden
unterschiedlich protokolliert; unprotokollierte Zeit wird keiner Physik oder PCK-
Kostenstelle zugeschrieben. Der kleine reversible Versuch wurde nach 20 UI-,
14 Timing- und 15 unveränderten Ressourcen-Tailkontrollen sowie unabhängiger
Quell- und Rohdatenprüfung übernommen. Direkte Aktionen ohne Scrollen verwenden
weiterhin den vorhandenen Touchguard; die zusätzliche Voraufnahme entfällt.
Alle erforderlichen Fold-Beschriftungen und Abmessungen werden aus einem
aktuellen vollständigen Frame gelesen; echte neue Retryframes bleiben erhalten.
Im stabilen vollständigen Ablauf spart das 35 Aufnahmen und sieben OCR-
Helperaufrufe. Diese Zählung ist anhand kontrollierter gleicher Inputs und der
echten alten Aufnahmemuster belegt; neue Android-Wallzeit wurde nicht gemessen.

Der fehlende Captionpfad hat einen ausdrücklichen Tradeoff: in der kontrollierten
Modelluhr zehn Aufnahmen/10,21 Sekunden zuvor gegenüber 78/120,03 Sekunden im
vorhandenen gemeinsamen Guard. Beide Wege verweigern die Eingabe. Das ist keine
beschleunigte Fehlerbehandlung und keine echte Android-Zeitmessung.

Die optionale monotone JSONL-Protokollierung umfasst Aufnahmen, OCR, UI2,
Sessionreads, Aktionen und Phasen einschließlich Readiness. Verschachtelte
Intervalle überlappen und ergeben keine CPU-/GPU-/FPS-Messung. Schreibfehler
lassen Rückgabe und ursprüngliche Ausnahme erhalten und melden separat
NOT_MEASURED. Der echte bestehende SIGALRM wird auch während eines Journalwrites
weitergereicht; ein eigener FIFO-/Alarmtest reproduzierte den alten Fehler und
bestätigt die Korrektur. Der ursprüngliche Ressourcen-PASS-Tail blieb unverändert;
seine 15 vorhandenen Tests wurden nicht angepasst. Die Readiness-/Autosave-Kriterien, zwei aktuellen
Touchframes, tatsächlichen 16 Tore sowie ACK-/Wallet-/Offline-Gates bleiben
verbindlich. Keine Android-Lösung wird aus Mockkontrollen abgeleitet.

Nächster Integrationsschritt: diesen finalen App-Pin und die geprüften
Produktionsreader auf dem aktiven Integrationsbranch sichern, dann eine neue
1908-APK bauen und den tatsächlichen vollständigen API35-/API36-Ablauf prüfen.
Die verbleibende Referenzbewegungs- und Hardwareabnahme bleibt offen.
Main und Releases bleiben unverändert.

Parallel wurde danach eine eigene Action-Linie entdeckt:
`codex/lumo-action-apk-2026-10-09` bei `aa651` auf Elternstand `afa7`,
Version `0.12.6+1909`, Godot-Pin `a377b9e2db3337ae46f9439200ef0af17af06cb5`.
Ihr Lauf `37888592898` ist noch in Arbeit. Diese Linie mit zusätzlicher Action-
Probe und verändertem Laufzeitlimit wird bewahrt und ersetzt keine Belege dieses
separat geprüften 1908-Pakets mit unverändertem 1200-Sekunden-Limit. Ein fertiger
1909-Build oder eine Android-Abnahme wird hier nicht behauptet. Nach Abschluss
beider Linien folgt ein selektiver Vergleich; keine parallele Arbeit wird
überschrieben und keine Versionsrückstufung daraus abgeleitet.
