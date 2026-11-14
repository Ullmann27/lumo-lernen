# Memory: native Commit-Bestätigung auf Host 28462

## Status und Quelle

Dieses Paket ist gegen Host `28462a7547048b75fa114e6f5832248e54c94faa` erstellt. Es enthält zwei eng geänderte Memory-Produktdateien und eine neue Testdatei. Es gibt keine Schlüssel-, Schema-, Regel-, RNG-, Rewardbetrags-, Native- oder Workflowänderung.

Die neue Fassung wurde hier **nicht mit Dart oder Flutter ausgeführt**. Lokale Dart-/Flutter-Aufrufe und Dependency-Wiederherstellung bleiben ausdrücklich gesperrt. Die 25 neuen Fälle sind implementierte Regressionen, keine behaupteten PASS-Ergebnisse. Die frühere Datei `test/games/memory_preferences_durability_test.dart` bleibt vollständig unverändert (SHA-256 `7f81307bad7da1e00f849a48d14d506df0449a35d81d498aeb3fa3afae23e4e7`). Ihre 14 tatsächlich bestandenen Fälle beziehen sich weiterhin auf ihren bisherigen Dartcache-/Backendvertrag.

## Offizieller Quellenbefund

Der frisch gelesene Lockfile pinnt `shared_preferences 2.5.5`, `shared_preferences_android 2.4.28` und `shared_preferences_platform_interface 2.4.2`. Die alte `SharedPreferences.getInstance()`-API benutzt die Legacy-Android-Implementierung; die zusätzlich registrierte Async-/DataStore-Implementierung ist ein anderer Pfad.

- [Offizieller Android-Paketstand](https://github.com/flutter/packages/tree/9854cd5607da4001f2dd3cbdcd6903202d28958c/packages/shared_preferences/shared_preferences_android): `LegacySharedPreferencesPlugin.setString` gibt das Ergebnis von `Editor.commit()` zurück. `getAllPrefs` liest dagegen `preferences.all`.
- [Offizielle Dart-Legacy-API](https://github.com/flutter/packages/blob/shared_preferences-v2.5.5/packages/shared_preferences/shared_preferences/lib/src/shared_preferences_legacy.dart): `reload()` ersetzt den Dartcache nach erfolgreichem Plattform-`getAll`.
- [AOSP Android 15, exakt gebundener Commit](https://github.com/aosp-mirror/platform_frameworks_base/blob/4e43ad12e1b211f15152e9c5b16b0fe88e6b93f3/core/java/android/app/SharedPreferencesImpl.java): `commitToMemory()` verändert zuerst `mMap`; `commit()` wartet anschließend auf das Schreibergebnis. Bei den gelesenen Datei-/Backupfehlern wird `false` ohne Rollback dieser Map gemeldet. `getAll()` liefert eine Kopie von `mMap`, keinen neuen Dateiread.
- [Offizieller Android-API-Vertrag](https://developer.android.com/reference/android/content/SharedPreferences.Editor#commit()): Ein positives Commit-Ergebnis ist die positive Persistenzbestätigung dieser Plattform-API.

Die ursprüngliche Gleichheitsprüfung nach einem Schreibfehler konnte deshalb einen noch nicht bestätigten nativen Cachewert übernehmen. Dieser konditionale Fehlerpfad ist durch die Quellen belegt; ein solcher Android-I/O-Ausfall wurde hier nicht ausgelöst. Der vollständige maschinenlesbare Nachweis steht in `official-source-audit.json`; gelesene Originalbytes mit Lizenzkopf liegen unter `official-source-binding/`. Die offiziellen Versionstags wurden an aufgelöste Commits gebunden. Kein Pub-Archiv wurde installiert oder als vollständig bytegleich geprüft. Die konkrete Framework-Binärdatei der Emulatoren und Android 17 wurden nicht untersucht.

## Enger Produktanschluss

`PreferencesMemoryStore.readRound/readStats` bleiben reine Plattform-Snapshots. Sie führen keine Schreibbarriere aus. Ein fehlgeschlagener Reload wird als `MemoryStorageUnconfirmed` weitergegeben. Ein explizites `setString == false` ist `MemoryStorageRejected`, eine fehlende Antwort bleibt `MemoryStorageUnconfirmed`. Diese Typen bewahren die Unterscheidung zwischen fehlender Bestätigung und einer bestätigten Speicheroperation.

Die optionale reine Dart-Schnittstelle `MemoryReadbackConfirmation` wird nur vom Preferences-Adapter implementiert. Der Controller validiert einen gelesenen Wert und die Profilberechtigung, bevor er die gleiche Zeichenfolge nochmals schreibt. Nur die positive Antwort dieses Schreibens bestätigt die Barriere. Das geschieht bei:

1. der erstmaligen Übernahme einer gültigen gespeicherten Runde oder Statistik;
2. einem identischen Readback nach fehlgeschlagener Initial-, Runden- oder Statistikschreibung;
3. einer späteren `_uncertain`-Wiederherstellung.

Vor und nach dem Await liegen Profilprüfungen. Ungültige/fremde Runden werden vor der Barriere verworfen. Beschädigte Altstatistik bleibt erhalten; eine ausdrücklich unbestätigte Plattform wird dagegen nicht als harmlose Altstatistik behandelt. Jeder Aufruf hat höchstens eine zusätzliche Bestätigungsbarriere; es gibt keine interne Wiederholungsschleife.

AOSP prüft Disk- und Memory-Generation getrennt. Ein identischer synchroner Put kann daher die noch ausstehende Generation tatsächlich erneut schreiben. Bei bereits erfolgreichem Commit mit verlorener Antwort bestätigt der gleiche Text dieselbe Runde und Ergebnis-ID; es wird kein neuer Spielzug erzeugt. Scheitert auch die Barriere, bleibt die Übernahme aus. Ein weiterer ausdrücklich angestoßener Versuch oder ein neuer Controller muss erneut positiv bestätigen.

## Neue Gegenfälle

Der neue Test benutzt die echte Dart-`SharedPreferences`-Cacheklasse und den Produktionsadapter/-controller. Nur die native Plattformgrenze wird kontrolliert ersetzt. Sie enthält getrennte `nativeMemory`- und `durableDisk`-Maps: ein fehlgeschlagener Commit kann die erste verändern, `getAll` liest ausschließlich diese erste Map, und ein positiver Commit bestätigt den gesamten gemeinsamen Preferences-Snapshot. Identische Werte und Generationen werden gesondert erfasst.

Die 25 Fälle decken Round/Stats, false/Exception, Initialisierung, spätere Unsicherheit, neue Dartinstanz über derselben nativen Map, einen ausdrücklich modellierten nativen Neustart aus der Diskmap, verlorene Antwort, unveränderte Ergebnis-ID/RNG, fremde Runden, korrupte Altstatistik sowie Profilwiderruf vor und während der Barriere ab. Drei Fälle führen einen vollständigen legalen Memory-Sieg durch die echte `LumoAppState.recordMemoryResult`-/Wallet-Kette. Sie prüfen nach Fehler und Wiederholung genau eine Ergebnis-ID sowie die unveränderten Werte 9 Sterne, 56 XP und 21 insgesamt verdiente Sterne bei Ausgang 7/40/19; bestehende Streakfelder bleiben erhalten.

Der letzte dieser drei Integrationsfälle benötigt zusätzlich As getrenntes Wallet-Dedup-ACK-Paket. Dessen Produktdatei `reward_wallet_repository.dart` hat SHA-256 `737ba4778054657f5cb7d3efc109ff48175f6551486e7f4040f3add057ab13d9`. Diese Datei gehört nicht zu diesem Paket und wurde hier nicht geändert. Ohne diesen gemeinsamen Fix soll der neue Integrationsfall die weiterhin fehlende Bestätigung des doppelten Wallet-Ergebnisses aufdecken.

## Aussagegrenzen

Die Bestätigung ist der positive Plattform-API-Vertrag. Sie ist kein unabhängiger physischer Diskread, keine Hardware-/fsync-Garantie und kein atomarer Vergleich über mehrere Flutter-Engines. Die vorhandene Profil-/Owner-Warteschlange ordnet die vorgesehenen Writer innerhalb der bestehenden Hostautorität; dieses Paket baut kein allgemeines Mehrprozess-Speichersystem.

Ein nativer SharedPreferences-Commit kann den gesamten Dateisnapshot einschließlich bereits darin enthaltener anderer Werte persistieren. Der Test bildet dieses Verhalten ab. Die Memory-Logik verändert weiterhin nur die bisherigen eigenen Round-/Stats-Schlüssel; historische ungebundene Daten und andere Kinder werden nicht rekonfiguriert.

Die neuen Backend-Neustarts sind Testmodelle, keine ausgeführten Android-Prozessneustarts. Die tatsächlichen bisherigen 28462-Renderer-, Authority- und Flutter-Ergebnisse bleiben getrennte historische Nachweise. Für diese neue Quellfassung sind neue echte CI-Ergebnisse erforderlich.

## Unabhängiger Quellenreview und Übergabe

B hat alle drei endgültigen Dateien sowie den gebundenen Produktdiff vollständig gelesen. Die getrennte Abschlussnote ist in `peer-review-reference.json` an SHA-256 `46d0b063584e0c6c842a7dbbf73e35a7cfa56b57f811ff9616ad14da8ca4c7fa` gebunden. Es wurde kein zusätzlicher konkreter statischer Blocker gefunden; der Review enthält keine ausgeführten neuen Tests.

`source-upload-manifest.json`, `confirmed-source-tree-inputs.json` und `source-blob-upload-proof.json` binden die drei bestätigten Gitblobs einschließlich vollständigem UTF-8-Readback. `implementation-against-exact-28462.patch` enthält auch die neue Testdatei. Die anschließende lokale Hashprüfung hat alle drei Sourcebytes sowie den unveränderten 14er-Bestand bestätigt. Die Integration und echte CI-Ausführung bleiben bei Root.
