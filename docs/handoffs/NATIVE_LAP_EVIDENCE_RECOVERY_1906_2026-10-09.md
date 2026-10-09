# Lumo 1906 · neuer Runden- und Ergebnisnachweis vom 9. Oktober 2026 UTC

Status: **DRAFT_SOURCE / NOT FINISHED**. Der App-Anschluss wurde nach dem
Workspaceverlust neu implementiert. Er ist weder die verlorene historische
103er-Probe noch deren alter Reader. Eine APK1906 wurde noch nicht gebaut.

Der neue Quellenentwurf besteht tatsächlich **534 Android-QA-Tests und36
Scriptprüfungen PASS/0 FAIL/0 SKIP**. Darin sind86 neu geschriebene Native-
Guards, die ersten74 Methoden unverändert plus12 weitere kontrollierte Fälle.
Die48 ursprünglichen f6-QA-Tests/Fixtures bleiben bytegleich. Das ist eine
neue Quellenprüfung; der Flow-ACK bleibt trotz grüner Guardtests blockiert.

## Beobachtung und Entscheidung

Die neue Continuity-Probe hat tatsächlich 104 geordnete Fälle. Sie kombiniert
eine physisch gefahrene Runde, Pause, Grafik-Rebuild, einen neuen Spielinstanz-
Start auf Runde zwei, zwei vollständige Runden, Result-Reopen und einen
completed-ACK. Zwanzig zugewiesene ConfigFile-Paare und weitere Legacy-/UI-
Fixtures sind ausdrücklich keine physisch gefahrenen Strecken.

Die echte geschlossene Continuity-GL-Aufnahme enthält 104 PASS/0 FAIL,
16 geordnete Tore, Gesamtzeit 51.217 s und beste Runde 25.100 s. Die aktuellen
Quellbindungen sind Produktionsdatei `7e600e57…`, Continuity-Probe `a9846743…`
und Fixture-Helper `b9155b5d…`. JSON-SHA256:
`6b572c4bf1258a163702fa623032d0278aef593f6f6588e8f0e26566c72970da`.
Das tatsächliche Result-Reopen-PNG hat SHA256
`44a21e16a93ac1151672454be7c88db2620e00eb8e92eae08bcd5ea3e243b7a5`.
Engine 4.6.3 official, X11 und tatsächlich gl_compatibility sind von der
Projekteinstellung forward_plus getrennt. Das ist Desktop-Software-Rendering,
keine Android- oder Performance-Abnahme.

Der erste neue vollständige Flow scheiterte an der unveränderten ursprünglichen
Assertion, dass ein bestätigter completed-ACK die dauerhafte Save-Datei entfernt.
Ein geschlossener unveränderter Rerun liefert neun neue PASS-Fälle und die alten
26 Assertions, doch weitere Wiederholungen reproduzierten den ACK-Fehler.
Dieser Rerun wird ausschließlich als Schema-Replay-Fixture verwendet:
JSON `fbab2cf1e62dc11436675081ca6569afe34fe6a889d30d0210c096ef81205b08`,
Probe `efeb2187…`. Die Runtime-Abnahme bleibt blockiert. Keine Assertion oder
Deadline wurde abgeschwächt. Ein getrennt entdeckter normaler Scene-Teardown
nach ACK wird ebenfalls tatsächlich untersucht, bevor ein finaler Pin erlaubt ist.

Die unveränderte Zeitformatprobe liefert neu tatsächlich 29 PASS/0 FAIL,
headless, nur Formatter-Aufrufe. Ihr JSON hat SHA256
`b0265280ff7f9575847811a91c416ecb1ea9508bf3a3acb53cc503297abeae1e`,
ihre Quelle `15f8b808…`. Sie weist keine Fahrphysik oder Geräteleistung nach.

## Neuer App-Vertrag

`tools/android_qa/native_lap_evidence_recovery.py` prüft die geordneten
104 Continuity- und neun Flow-Zeilen mit expliziten Semantikregeln. Feste
Legacy-Erwartungen wurden gegen den neuen Probe-/Helper-Quelltext gelesen.
Dynamische Erwartungen werden an die tatsächlich beobachteten Tore, vor/nach
Resume gespeicherten Zustände und den öffentlichen Result-Payload gebunden.
Ein bloßes `passed=true` oder pauschales `expected==actual` genügt nicht.

Typen bleiben strikt: insbesondere bool ist keine Zahl, public solved ist
integer 0, Checkcounts sind integers und Fahrbuttonzustände sind booleans.
Die dokumentierte 1e-9-Toleranz betrifft nur ausdrücklich ausgewählte interne
Timing-/Restore-Beobachtungen. Öffentliche Millisekunden, echte Textzeilen,
IDs, Gates und Rewards bleiben strikt. Beim aufgezeichneten Host-ACK sind
JSON-int/float-Normalisierung und ausschließlich die dokumentierte leere
sessionId → recovered-lap-continuity-Normalisierung zulässig.
Ein vorhandenes lokales Sternkonto bleibt zwischen vor/nach Reopen unverändert;
es wird nicht fälschlich auf den Fixture-Ausgangswert drei festgelegt.

Result-UI wird sofort und nach einem Physikschritt geprüft: Controls verborgen,
alle fünf Aktionen deaktiviert, Resulttitel passend und tatsächlicher HUD-Text
mit genau `0 km/h`. Der Text wird erneut geparst; der gemeldete Zahlenwert
ersetzt ihn nicht. raw_speed bleibt vor/nach dem Schritt unverändert.
Die tatsächlich gefahrenen Raw-Werte sind dynamisch, typisiert und nichtnegativ;
nur das ausdrücklich im Zeitfahren zugewiesene12.0 bleibt eine feste Erwartung.
Signierte, eingebettete oder angehängte Ziffern und zusätzliche km/h-Tokens
werden auch bei konsistent gespiegelten JSON-Feldern verworfen. Eine unabhängig
entdeckte schwächere Parser-Vorstufe und deren74er-Abnahme bleiben historische
Proofs, der neue kanonische Parser ist mit neuen negativen Fällen geprüft.

Die fünf Produktions-/Probe-/Helper-Dateien müssen den freigegebenen SHA256
besitzen. JSON akzeptiert weder doppelte Schlüssel noch nichtendliche Zahlen.
Die sieben echten PNG-Rollen benötigen reguläre Dateien, passende SHA256,
1280×720-IHDR, vollständige CRC-geprüfte Chunks, IEND und vollständig begrenzt
dekomprimierte Bilddaten. Das prüft Bildintegrität, keine visuelle Referenztreue.

Der Workflow erhält seine ursprüngliche native 15er-GL-Schleife, alle 21 alten
Marker und die bestehenden Modal37/sechs Drags/14 PNGs/neun Countdownbilder.
Eine separate headless-Zeitformatprüfung wird als 22. Marker hinzugefügt.
Die Summary erhält 15 ausdrücklich neue Lap-/Flow-Bindungen sowie
time_format_checks=29 und den SHA256 der tatsächlich erzeugten Formatter-JSON.
Die alten Summary-Felder bleiben erhalten. Die neuen Runden-/Formatter-
Artefaktordner werden mit hochgeladen.

## Abbruchkriterium und nächste Schritte

Der Flow bleibt blockiert, solange ACK- oder Teardown-Reproduktion offen ist.
Ein künftig geänderter Probe-/Produkt-SHA erfordert neue echte Runtime-Belege,
aktualisierte geprüfte Bindungen, neue Tests und unabhängige Quellenprüfung.
Erst danach darf config/godot-source.json den tatsächlichen veröffentlichten
Godot-Commit übernehmen. Gegenwärtig bleibt der veröffentlichte Baselinepin
ad3 erhalten. Kein Datei-SHA256 ersetzt einen Commit-Pin.

Neue kontrollierte App-Guardtests und Replays belegen ausschließlich diesen
neu implementierten Quellenvertrag. Frühere 436-/47-/236-Abnahmen werden
nicht übertragen. Die hier neu ausgeführten534/36 und Syntaxprüfungen brauchen
eine eigene unabhängige Quellenprüfung. Nach dem tatsächlichen ACK-Fix sind
aktualisierte Quellenbindungen, passende neue Runtime-Fixtures, Sourcepeer,
finaler f6..RESULT-Tree und APK-Build erneut abzuschließen.
