# LUMO – Originalquellen-Integration, überprüfbarer Status (17.11.2026)

Dies ist eine Bestandsaufnahme und ausdrücklich keine APK-Veröffentlichung.

## Originalarchive aus der privaten Dateibibliothek, mit echten ZIP-Bytes geprüft

| Archiv | Bytes | SHA-256 | Prüfung |
|---|---:|---|---|
| Lumo-2037-Quellen-2af3170.zip | 237684254 | de78dbb8381a012b0ab552194705e152b684da1c56fcb69d7906f13cba943849 | ZIP-CRC und interne Git-Bundle-Prüfsummen |
| Lumo_2032_Quellen_und_Pruefnachweise.zip | 218511846 | 7b478507249b38bc3cca324a7c5fbc55948160daaa854c9efb0770802a03e281 | ZIP-CRC und interne Bundle-Prüfsummen |
| Dschungelherz_Detail_V2_Godot_dc31bbe3cf0c.zip | 200318522 | eb6a928c8f10605a97dd4d1f645a48b15b6ea266ced2cbdef83788623a2b953b | ZIP-CRC; 140 GLB-Dateien, separates Godot-Prüfprojekt |
| LUMO_Kart_Blender_10_Autos.zip | 129862148 | 3bcde525bd046718be3befbd16cde20961779dc2dab5da783a3e24db9c4e88f7 | ZIP-CRC; 10 ursprüngliche Blender-GLB-Exporte vorhanden |

Die Originalarchive werden durch die Eintragung dieser Tabelle NICHT auf GitHub veröffentlicht.

## Zuordnung der Quellstände

- Gesicherter archivierter Flutter-Commit: d48b122945e37a42c4c6b47aa86b8925d428ecb8
- Gesicherter archivierter Godot-Commit: 2af3170645dd9595cebcb234cd12f4343d621b3b
- Der auf GitHub bisher gebaute APK-2037-Kandidat verwendet dagegen den Godot-Commit bb4788803180544525b6f23540a134016a1399a8.
- Im archivierten Godot-Stand sind gemäß Provenienz 30 optimierte R02-Dateien im Verzeichnis assets/karts/r02 nachgewiesen; diese fehlen am öffentlichen APK-Quellpin.
- Der archivierte native Prüfbericht bestätigt 327 tatsächlich angebundene V2-Pflanzenplatzierungen, nicht die komplette 1.443-Platzierungen-Autorenvariante.
- Das V2-Zusatzarchiv besitzt eine eigene project.godot. Niemals dessen gesamte Projektwurzel blind über die produktive Godot-Installation entpacken.

## Der notwendige Freigabeweg

1. Beide archivierten 2037-Git-Bundles mitsamt ihren ausdrücklich benannten öffentlichen Basiskommits vollständig wiederherstellen; ohne Force-Push oder Änderung von main.
2. Den restaurierten nativen Stand mit scripts/audit_complete_native_source.py --require-ready prüfen. Fehlende GLBs, Quellidentität und V2-Einstiege blockieren den behaupteten vollständigen Stand.
3. Alle Autorenvarianten (V2, R02) gegen reale, aktuelle Kart-IDs, 3.600-m-Streckengeometrie, LOD, Kollision, Pause, Touch und Leistung technisch prüfen und konfliktfrei anbinden.
4. Den tatsächlich getesteten großen Quellstand mit einer für Git-Binärdaten geeigneten und autorisierten Verbindung nach GitHub übertragen. Der derzeitige textbasierte GitHub-Dateiconnector kann lokale Git-Bundles mit Hunderten MB nicht direkt als Git-Push verschicken.
5. Nur nach erfolgreichem Originalquellcheck eine neu signierte Flutter-Godot-APK mit exakter Provenienz und APK/PCK-SHA bauen, auf Android installieren und die reale Nutzung von Memory, Kart, Bauwelt und Lernwerkstatt bestätigen.
6. Erst nach einer vollständigen Inventur, bestandenen Tests und dokumentierten Restlücken von null behaupten, dass alles Fertige integriert ist.

## Automatisierte Prüfungen

scripts/audit_complete_native_source.py prüft schreibgeschützt native Quellidentität, alle 30 R02-Spielmodelle (GLB v2 Header und Dateilänge), erforderliche V2- und Kart-Skripte sowie deren Quellverbindungen. Ohne --require-ready erstellt es nur den JSON-Status; mit --require-ready beendet es bei Lücken mit Code 2.

.github/workflows/lumo-original-native-audit.yml erzeugt einen revisionsgebundenen Status für den aktuell gepinnten Quellstand. Der Workflow heißt bewusst Originalquellen-Prüfung und erstellt keine APK. Quellpräsenz ersetzt weder einen Godot-Spieltest noch die Installation auf dem Samsung Galaxy Z Fold7.
