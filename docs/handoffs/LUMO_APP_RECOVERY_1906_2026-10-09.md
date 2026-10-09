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

Der Workflow fügt ausschließlich den hashgebundenen SDK-Vorlauf vor dem
ursprünglichen Emulator-Runner hinzu: elf Minuten Step-Limit, insgesamt600
Sekunden Helper-Limit, ursprüngliches API35/36/google_apis/x86_64. Runner,
Emulatorbuild14472402, Java, Abhängigkeiten, Display, Scripts, deren45-Minuten-
Jobgrenze und die ursprünglichen Spiel-/ACK-/Wallet-/Ressourcengates bleiben.

Zwei weitere kleine QA-Reparaturen entstehen neu aus den erneut gelesenen
Originaljobs von Actions37846382465: Kart35 Job113557082538 verliert den
bereits verifizierten `emulator-5554` beim Fullrace-Einstieg; Kart36
Job113557082644 verliert die sichtbare Gas-Beschriftung zwischen Vorbereitung
und sicherer Touch-Abnahme. Ihre neuen RED/GREEN-Proofs müssen die genaue
Identität, gemeinsame Fristen, frische vollständige Screens und bestehende
Touch-/Scrollgates erhalten. Alle ursprünglichen Tests bleiben unverändert.
Die Freigabe dieser Änderungen wartet deren neue geschlossene Prüfberichte.

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

1. Neue Handoff-/Gas-Reparaturen schließen und unabhängig prüfen; alle
   ursprünglichen Android-QA- und36 Scriptprüfungen ohne Abschwächung ausführen.
2. Godot-Wiederherstellung einschließlich der verlorenen zwei Proben neu
   prüfen, tatsächlich veröffentlichen und erst dessen exakten SHA pinnen.
3. Zeitformatprobe als22. native Prüfung ergänzen; die ursprünglichen21 Marker,
   Modal37/sechs Drags/14 PNGs und neun Countdownbilder erhalten. Neue Runden-
   und Result-Reopen-Belege strikt an tatsächliche Quelle, Proben, JSONs und
   PNGs binden. Keine historischen103-/29-/47-Werte übertragen.
4. Neues f6..RESULT-Inventar mit Dateibytes/SHA256/Git-Blob/Modus/Tree und
   unabhängigem Sourcepeer schließen. Erst danach frische APK bauen, deren
   APK/PCK/Manifest/Signatur/ABI lesen und den vollständigen Androidablauf testen.

Sichtbare Lücken bleiben: Lumo-Gesicht/Schnauze, Stoffwirkung, Garagenlicht,
Sonnenhafen-Materialtiefe, Iris-Fern-LOD sowie Bewegungsabgleich zur YouTube-
Referenz. Geräte-FPS/GPU-Framezeit/Soak, physisches Fold und Audioabnahme sind
**NOT EXECUTED**. Reversible QA-Anschlüsse ersetzen diese Produktabnahme nicht.
