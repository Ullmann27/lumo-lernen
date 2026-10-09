# Lumo1906 · neuer Lifecycle-Quellanschluss, 9. Oktober2026 UTC

**DRAFT_SOURCE / SYNTHETIC_TESTS_ONLY / VISUAL_GAP / NOT FINISHED**.
Die neue APK1906 und Android-/Fold-/Performance-Abnahmen sind **NOT EXECUTED**.
Der zweite lokale Workspaceverlust hat auch die vorherigen lokalen Reports
entfernt. App21 wurde vollständig und sauber aus dem tatsächlich veröffentlichten
Recoverycommit `1c5300267b5689d450f67bcf59d700f1c3d6d0d8`, Tree
`4b92e0531c23c0bf93a75b95179b2353cae4b01a`, wiederhergestellt. Frühere
549/36-Ausführungen bleiben historische Ausführungen derselben gesicherten
Quellbytes; ihre verlorenen lokalen Reports werden nicht als neu vorhanden
ausgegeben. Der neue Anschluss benötigt eigene neue Prüfungen und Nachweise.

## Tatsächlicher Quellvertrag

`native_handoff_evidence_recovery.py` liest den eigenen JSON-Export
`exports/race-bridge/handoff-lifecycle-evidence.json`. Trotz dieses historischen
Ordnernamens ist der Producer die aktive Continuity-Probe. Der unveränderte
Bridge-Test ist kein zusätzlicher CI-Einstieg. Der Helper wird nach den bisherigen
104 Continuity-Fällen, ihrem JSON/Screenshot und dem ursprünglichen Aufräumen
ausgeführt. Sein Urteil ergänzt den bestehenden PASS; das native Inventar bleibt
22. Die zehn Fälle weisen zugewiesene Zustände und echte Methoden-/Teardown-
Aufrufe nach, keine physisch gefahrenen Runden.

Der persönlich gelesene Godot-Recoverycommit ist
`4b63ec27cb423e600c3ded182f57a795dc357579`. Vorläufige SHA256-Bindungen:

| Datei | SHA256 |
| --- | --- |
| scripts/games/kart_island.gd | 7247dd551b900194936d60d31e4436d0e2a9dc74fb4c91e2306d94f6d8689c8c |
| scripts/tests/kart_race_continuity_regression.gd | f82c717207786cf666f66ff33dbbda5992e11b17623f5481ab58750dc263441f |
| scripts/tests/kart_handoff_lifecycle_fixtures.gd | fb78dcba3a212ef8b540a2b125fe7baabe123d1f85975451ebaddde9a3d96cef |

Die zehn geordneten Labels und festen erwarteten Werte stammen direkt aus
diesem Helper. Erwartung und tatsächliche Beobachtung werden separat gebunden;
`passed=true` allein genügt nicht. Boolean und Integer bleiben getrennt.
Der dynamische Result-ID-Fall benötigt genau eine Belohnung, einen Return und
dieselbe ID in Erwartung/Beobachtung. Die ID muss dem in HostBridge erzeugten
`natural-ack-state-fixture-<epochMillis>-<ticksUsec>` entsprechen. Der tatsächliche
Continuity-Log muss genau eine Rewardzeile für diese ID, genau eine vollständige
Lifecycle10-PASS-Zeile und den ursprünglichen Continuity-PASS enthalten. Fehler,
Timeout oder Exit-Ressourcenleaks sperren die Summary trotz vorhandener PASS-Zeilen.

Zusätzliche Summary-Schlüssel:

- `handoff_lifecycle_checks`
- `handoff_lifecycle_evidence_sha256`
- `handoff_lifecycle_source_sha256`
- `handoff_lifecycle_probe_sha256`
- `handoff_lifecycle_helper_sha256`

Der Probehash bindet ausdrücklich Continuity. Das neue Artefaktprefix lädt den
Lifecycle-JSON zusammen mit den bisherigen Artefakten hoch. Die fünf Felder
ergänzen die bisherigen17 neuen Lap-/Flow-/Formatterfelder; diese Zahl22 ist
unabhängig von der ebenfalls22 großen nativen Probenliste.

## Blocker und Abbruchkriterium

Aktuell fehlt eine strikte, leakfreie aktuelle Lifecycle10-GL-Abnahme. Funktionale
PASS-Zeilen ersetzen keinen sauberen Engine-Abschluss. Die neue Unitfixture ist
ausdrücklich `SYNTHETIC_SOURCE_CONTRACT_NOT_RUNTIME`; sie enthält kein behauptetes
Runtimebild und wird vom Workflow nicht als Export verwendet. Ihre Mutationen
prüfen ausschließlich den Readervertrag.

Der vorhandene Lap-/Flow-Reader bleibt bis zur neuen tatsächlichen Closure an
seine vorherigen Quellen gebunden. Zusammen mit dem neuen Lifecycle-Reader
blockiert er deshalb bewusst die aktuelle, noch nicht geschlossene Kombination.
Nach jeder Änderung an Produktion oder Producer sind die Bindungen und echten
Fixturen erneut zu prüfen. Erst tatsächlicher neuer Godot-Sourcefreeze, unabhängige
Abnahme und Veröffentlichung erlauben den finalen Commit-Pin. Der Pin bleibt
hier unverändert `ad3ee9c9a1e2cfa60a6d2fe4970181b3150a1a1b`.

Nächster Schritt: neue gezielte Unitguards, vollständige QA-/Scripts-/Syntaxprüfung,
früher separater Recoverycheckpoint und unabhängiger Quellpeer. Danach aktuelle
104/10-/Flow9-/Formatter29-Quellen und echte Artefakte verbinden; anschließend
finale Appquelle und erst dann eine neue APK bauen und tatsächlich auswerten.

## Neue tatsächliche Quellenprüfung

Die vor der ersten Ausführung eingefrorenen neuen30 Lifecycle-Unitguards
bestehen mit0 Fehlern/0 Skips. Für diese neue Funktion wird kein künstliches
RED→GREEN behauptet. Die neue synthetische JSONfixture besitzt SHA256
`1c0a2e3eac5600102c984295308781b55c7a8df139dfda37eaa3609013ba1e3c`.
Positive temporäre Summaryfälle mocken nur die drei Quellenbyteprüfungen und
prüfen deren tatsächliche Pfade/erwartete Hashes. Negative Quellenfälle verwenden
die unveränderte echte Hashprüfung; fehlende/fehlerhafte JSONs, Marker, IDs,
Ressourcen-/Timeoutfehler und bool/int-Verwechslungen werden verworfen.

Die neu nach dem zweiten Verlust ausgeführte ganze Suite besteht tatsächlich
**579 Android-QA-Tests und36 Scriptprüfungen,0 FAIL/0 ERROR/0 SKIP**.
Die alten549 sind darin enthalten, deren ursprüngliche48 f6-Dateien sowie die
vorherigen86 Lap-Guards/Fixtures werden in dieser Vorstufe nicht geändert.
Der frühere NDK-Scriptausreißer mit null statt einer kontrollierten Fake-SDK-
Ausführung bleibt als historischer erster Fehlversuch dokumentiert; der jetzige
36er-Lauf wurde erneut unverändert erfolgreich ausgeführt. Kein aktueller
Runtime-/GPU-/APK-Erfolg wird aus diesen Quellenprüfungen abgeleitet.
