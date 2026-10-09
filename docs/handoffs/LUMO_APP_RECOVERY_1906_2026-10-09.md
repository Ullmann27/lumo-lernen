# Lumo 1906 · neuer App-Wiederherstellungsstand vom 9. Oktober 2026 UTC

Status: **RECONSTRUCTED_NEW_SOURCE / VISUAL_GAP / NOT FINISHED**. Dieser
Anschluss ist nach dem Verlust des ursprünglichen Arbeitsbereichs neu erstellt.
Die früheren lokalen App45-/SDK576-/436-/47-Abnahmen sind historische
Ausführungen. Sie belegen diese neuen Dateibytes nicht. Main und Releases
bleiben unverändert. Eine neue APK1906 ist **NOT EXECUTED**.

Veröffentlichte App-Basis: `f6c4f3350db8153200594b52a9d82606279dc238`.
Das vollständige GitHub-Inventar enthält 1188 Blobs. Die wiederhergestellten
Prüfdateien, Originaltests und PNG-Fixtures wurden über diese exakte Revision
gelesen und gegen Git-Blob-SHA und Bytezahl geprüft. Der lokale Teilbestand
ist kein vollständiger Git-Checkout und kein Beleg für einen neuen App-HEAD.
Die unveränderten Dateien kommen bei der späteren Veröffentlichung aus dem
veröffentlichten Basistree; alle neuen Dateien benötigen ein eigenes Inventar.

Quellversion: `0.12.4+1906`. `config/godot-source.json` hält zunächst den
Originalpin `ad3ee9c9a1e2cfa60a6d2fe4970181b3150a1a1b`/Engine4.6.3.
Das ist ausdrücklich der erhaltene Baselinepin. Der finale Anschluss darf erst
den tatsächlich veröffentlichten und neu geprüften Godot-Wiederherstellungs-SHA
übernehmen. Ein Datei-SHA256 oder alter lokaler Commit ersetzt diesen Pin nicht.

## Enger neuer Anschluss und Prüfgrenzen

Der SDK-Helper wurde exakt aus dem veröffentlichten Diagnosecommit
`7cff9e0eb233b6386b51d459f8b29a2958d3e21d` gelesen: 16572 Bytes,
Git-Blob `55b5c404b9ac6822213d966f274a047401c37b26`, SHA256
`8925b7b41fada3c41fc80959c03fb71314f60530adbdc8e6614ea94e0c6a9c51`.
Die neuen eigenständigen SDK-Tests sind **58 PASS/0 FAIL/0 SKIP**, darunter
fünf echte lokale CLI-Prozessfälle gegen kontrollierte SDKmanager-Dateien.
Diese Fälle installieren kein SDK und starten keinen Emulator.
Die [neue SDK-Beschreibung](SYSTEM_IMAGE_PREPARATION_RECOVERY_1906_2026-10-09.md)
erklärt Pflichtimages, beide zulässigen Bootstrapformen und die erhaltene Frist.

Der frühe 14-Dateien-Checkpoint fügte den hashgebundenen SDK-Vorlauf vor dem
ursprünglichen Emulator-Runner hinzu: elf Minuten Step-Limit, insgesamt600
Sekunden Helper-Limit, ursprüngliches API35/36/google_apis/x86_64. Runner,
Emulatorbuild14472402, Java, Abhängigkeiten, Display, Scripts, deren45-Minuten-
Jobgrenze und die ursprünglichen Spiel-/ACK-/Wallet-/Ressourcengates bleiben.

Zwei weitere kleine QA-Reparaturen wurden neu aus den erneut gelesenen
Originaljobs von Actions37846382465: Kart35 Job113557082538 verliert den
bereits verifizierten `emulator-5554` beim Fullrace-Einstieg; Kart36
Job113557082644 verliert die sichtbare Gas-Beschriftung zwischen Vorbereitung
und sicherer Touch-Abnahme. Ihre neuen RED/GREEN-Proofs müssen die genaue
Identität, gemeinsame Fristen, frische vollständige Screens und bestehende
Touch-/Scrollgates erhalten. Alle ursprünglichen Tests bleiben unverändert.
Die identische neue15er-Handoffprobe liefert f6 RED→15/0 GREEN; dazu bestehen
die unveränderten Root23/Handoff13/Identity14/CompleteEvidence54. Die neue
[Gas-Recovery](GAS_CAPTION_SCROLL_RECOVERY_1906_2026-10-09.md) liefert einen
identischen echten Funktions-Test f6 Timeout→GREEN,33 neue Guards und82
unveränderte Native-/Kart-/OCR-/Captureguards PASS. Sie erlaubt höchstens zwei
nach frischen vollständigen Screens beobachtete Rückwärts-Scrollgesten innerhalb
der bestehenden nativen Frist. Der endgültige Tap benötigt weiterhin zwei
frische passende Zielbeobachtungen und unveränderte PNG-Bytes. Es wurden keine
Taps oder Spielzustände in eine laufende App injiziert. Die tatsächlich neue
ganze Suite besteht448 Android-QA-Prüfungen/0 FAIL/0 SKIP, dazu36 Scriptprüfungen
PASS/0 FAIL/0 SKIP. Ein erster Teilcheckout-Versuch scheiterte in einem
unveränderten Originaltest an einer noch fehlenden originalen Dart-Registry.
Der Fehler bleibt erhalten; Registry und PlusScreen wurden exakt aus dem
verifizierten vollständigen f6-Checkout ergänzt, kein Test wurde verändert.
Dieser 14-Dateien-Checkpoint ist inzwischen unabhängig mit denselben448/36
und erhaltenen48 Originaltests/Fixtures bestätigt. Er ist auf dem separaten
Recoverybranch als `4fe583ff84756250cbd85188ea56360db5672a7d`, Tree
`0bde72a889f269465c5b8e22494540826800c216`, PR221 gesichert. Das ist kein
finaler App-/Godot-Pin und löst keinen primären APK-Build aus.

Der folgende neue Entwurf ergänzt die Zeitformatprobe als22. native Prüfung,
einen eigenständigen typisierten Runden-/Result-Guard und die tatsächlichen
JSON-/PNG-Artefaktbindungen. Die ursprüngliche native15er-GL-Schleife und alle
21 alten Marker/Modalgates bleiben erhalten. Die [neue Native-Übergabe](NATIVE_LAP_EVIDENCE_RECOVERY_1906_2026-10-09.md)
trennt die geschlossene Continuity104-/Formatter29-Prüfung vom weiterhin
blockierten Flow-ACK. Neue App-Tests prüfen derzeit den Quellenvertrag und
ausschließlich eine geschlossene Flow-Schema-Fixture. Das ist keine finale
Runtime-Abnahme. Der neue Entwurf besteht neu tatsächlich534 Android-QA- und36
Scriptprüfungen PASS/0 FAIL/0 SKIP, darunter86 neue Native-Guards. Alte48 f6-
Originaltests/Fixtures bleiben bytegenau erhalten. Die ursprünglichen21 Marker
werden vor dem ergänzten22. Marker separat geprüft. Alle22 Bashsteps und sechs
Inline-Python-Blöcke haben neue Syntaxprüfungen bestanden.

Historische tatsächliche Runtime: APK1905 aus Actions37846382465,
201691346 Bytes/SHA256
`f06140353caa1f2d4c0038287b05918402324b26cc9dc5454ca1c13e9597f14c`.
Der unveränderte spätere Bauen-Diagnoselauf Actions37861486692 auf7cff war
tatsächlich sichtbar erfolgreich: Haus161 Teile, einmal3 Sterne/24XP,
Replay und abschließender Offline-Neustart mit erhaltenem Profil und Wallet.
Ein unfertiger Spielabbruch wurde in diesem Build-only-Lauf nicht ausgeführt.
Expliziter Host-ACK-Payload, installierter PM-APK-Bytehash, separate rohe
Foregrounddatei und Bootstrap-Input-Contenthashes wurden nicht unabhängig
archiviert/gemessen. Dieser Erfolg bleibt auf die alte identische APK1905
begrenzt und ist keine APK1906-, Kart-, Fold- oder Performance-Abnahme.

## Nächste konkrete Integration

1. Den neuen Native-App-Entwurf schließen und unabhängig prüfen; alle
   ursprünglichen Android-QA- und36 Scriptprüfungen ohne Abschwächung erhalten.
2. Godot-Wiederherstellung einschließlich der verlorenen zwei Proben neu
   prüfen, tatsächlich veröffentlichen und erst dessen exakten SHA pinnen.
3. Den ergänzten Zeitformat-/Runden-Guard nach dem tatsächlichen ACK-Fix erneut
   prüfen; die ursprünglichen21 Marker, Modal37/sechs Drags/14 PNGs und neun
   Countdownbilder erhalten. Neue Runden-
   und Result-Reopen-Belege strikt an tatsächliche Quelle, Proben, JSONs und
   PNGs binden. Keine historischen103-/29-/47-Werte übertragen.
4. Neues f6..RESULT-Inventar mit Dateibytes/SHA256/Git-Blob/Modus/Tree und
   unabhängigem Sourcepeer schließen. Erst danach frische APK bauen, deren
   APK/PCK/Manifest/Signatur/ABI lesen und den vollständigen Androidablauf testen.

Sichtbare Lücken bleiben: Lumo-Gesicht/Schnauze, Stoffwirkung, Garagenlicht,
Sonnenhafen-Materialtiefe, Iris-Fern-LOD sowie Bewegungsabgleich zur YouTube-
Referenz. Geräte-FPS/GPU-Framezeit/Soak, physisches Fold und Audioabnahme sind
**NOT EXECUTED**. Reversible QA-Anschlüsse ersetzen diese Produktabnahme nicht.
