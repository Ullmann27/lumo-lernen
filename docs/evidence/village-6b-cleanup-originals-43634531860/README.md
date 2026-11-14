# Unabhängige Originalprüfung: Diagnose 43634531860, Versuch 1

## Ergebnis und Geltungsbereich

Die unveränderten vollständigen Dorf- und C4-Leser bestehen auf den neuen Originalen dieses erfolgreichen Diagnose-Laufs. Die Haupttour meldet 21 erfolgreiche Schritte; die unabhängige Nachprüfung bindet ihre 18 Pflichtschritte, die APK-Identität und die danach ausgeführten Dorf-/C4-Proben. Dorf PASS, C4 PASS mit **25 Beobachtungen, sechs Übergängen, zwei Kind-/Bot-Paaren, einem wieder geöffneten gespeicherten Spielstand und zwei abgeschlossenen Rückwegen**.

Dies ist die getrennte Diagnose der unveränderten **alten 6b-APK**, gesteuert durch die neuere QA-Quelle **3cae**. Sie ersetzt weder die sieben Pflichtjobs auf dem zentralen Host **ec936873** noch eine Veröffentlichungsfreigabe. Es wurde kein Sieg gespielt, keine Belohnung abgeholt und kein vollständiges Zwei-Runden-Rennen abgeschlossen. Es gibt keine Aussage zu 60 FPS, einem physischen Gerät, ARM64 oder API 37.

Der erste frühe C4-Rückkehrframe zeigt noch die native Pause. Die späteren Originale desselben Rückwegs zeigen dagegen die tatsächliche Flutter-Pause vor dem protokollierten Touch und anschließend die Spielewelt. Diese wichtige Einschränkung und die zunächst falsche Einordnung der späteren Zielbilder werden unten vollständig dokumentiert.

## Exakte Bindungen

| Gegenstand | Gesicherter Wert |
|---|---|
| Diagnose | Run `43634531860`, Versuch `1` |
| Vertragsjob | `132568308161`, erfolgreich; Root hat dessen 155 PASS / 0 Skip aus dem Original gelesen |
| Androidjob | `132568698911`, erfolgreich, Ende 20:22:15 UTC |
| QA-Commit / Baum | `3cae9c407a6eef1970e24bc9a61516b13fe0af52` / `16dbaa5024c0bba79c9ab8a9d23b9025a0c2f5d7` |
| QA-Baum | 5.010 Blob-Dateien; vollständiger, nicht abgeschnittener Baum gespeichert |
| APK-Host / Baum | `6b3047b7979dfb86d837e74a21b0fd890e4f9e66` / `8b0c31a26207068c28658e14c6535c39a51cf95b` |
| Native-Pin | `84789d0c2c6fb4b6ecd2897ce1951b89f958b604` |
| Ursprünglicher APK-Build | Run `43616038272/1`, Job `132512734271` |
| x86-APK SHA-256 | `9c64ae2f866c1eee832a96baba56d8d3dc314cec79c69c7c1781bb803111a765` |
| PCK SHA-256 | `99c68b1d68e4c8701c7e7e69f13137ff2b7f4d4a204c1a4a8f1bb0766e2720a4` |
| Version | `0.13.8+2020` |
| Aktuelles Diagnoseartefakt | `14130249406`, `lumo-6b-roundtrip-diagnostic-main-api35` |
| ZIP | 173.452.037 Bytes; SHA-256 `4177ce50b507c715d0fe4285859e6380aa8a1380ce68f263964e0587f4c210e8` |

Alle 79 im Original protokollierten Beobachterquellen wurden unabhängig mit dem vollständigen tatsächlichen QA-Baum verglichen. Vor- und Nachbindung enthalten dieselben Quellen und dieselbe APK-Identität. Die lokale kleine Leserkopie enthält zwölf bytegenaue QA-Dateien und ein separates, unverändertes ZIP-Prüfwerkzeug. Sie ist **kein Git-Checkout**; ein lokaler Git-HEAD- oder Index-PASS wird nicht behauptet.

Gegenüber QA91 ändern sich genau C4-Probe `836cf90f170545ce6d6393d5034dc149f5f6cf8c`, Deadline-Testdatei `da877b93d3ae61c54b1743f8aba006bac614cdea` und die zusätzliche Deadline-Testmodulzeile im Diagnoseworkflow `2d40651abd44b2b13f58e202ff4b747cd7e084ee`. Die übrigen Adapter, Runner und vollständigen Leser bleiben bytegleich.

## ZIP, Originalerhaltung und unveränderte Leser

Das Artefakt wurde genau einmal heruntergeladen. API-Größe und SHA-256 stimmen. Vor der Extraktion wurden der aktuelle freie Speicher und die tatsächliche Ausdehnungsgröße geprüft. Alle 2.875 Dateipfade, Dateitypen, Größen, CRCs und Original-Hashes wurden kontrolliert; doppelte oder ausbrechende Pfade, Kollisionen, Verschlüsselung und unzulässige Typen werden vom vorhandenen ZIP-Prüfwerkzeug abgewiesen. Die extrahierten Originale umfassen 210.962.413 Bytes und 393 PNG-Dateien.

Die vollständigen Leser wurden ohne Änderung ausgeführt:

| Leser | Unveränderter Gitblob | Tatsächliches Ergebnis |
|---|---|---|
| Dorf | `013fe059fdbe1dd49ded63b3378f302f10fface3` | PASS |
| C4 | `091e250702b41c8ff0a1eef2eaa554a83c2cff68` | PASS; Ergebnis exakt gleich dem originalen C4-Replaybericht |
| Diagnose-/Quellbindung | `c267eadbac17f163cd24c4c149c5640e9b32c9b7` | Bindung an QA3cae und APK6b bestätigt |

Der lokale vollständige Replay dauerte **15,115754 Sekunden**, Exit 0. Tatsächliche Umgebung: **Python 3.12.14, Pillow 13.0.0**; die originale CI verwendete Pillow **12.3.0**. Vorher-/Nachher-Snapshots und der zusätzliche Archivierungssnapshot bestätigen unveränderte Inhalte und Dateimodi aller 2.875 Originaldateien sowie aller 13 Leserdateien. Es gab keine neue Engine-, Render-, Emulator- oder Geräteausführung.

## Tatsächliche Mailboxbereinigung und Wiederöffnung

| Rückweg | Native-PID | Beobachtungsrunden | Tatsächlich zunächst nicht leere Runden | Akzeptierte letzte Originalabfrage |
|---|---:|---:|---:|---|
| Erster Rückweg | 7129 | 2 | 1 | `c4/commands/0331-return-first-closed-mailbox.stdout`: leer, Exit 0 |
| Letzter Rückweg | 8289 | 3 | 2 | `c4/commands/0454-return-final-closed-mailbox.stdout`: leer, Exit 0 |

Die tatsächliche Abfrage ist jeweils `adb shell find /data/user/0/dev.ullmann.lumo.lumo_lernen.coachpreview/files/lumo_connect_four_session_v1 -maxdepth 2 -type f -name state.json`. Es wird das gemeinsame C4-Sessionverzeichnis geprüft. Die negativen Originalausgaben nennen konkret die aktuelle Sessiondatei; die akzeptierten Ausgaben sind anschließend leer. Gleichzeitig belegen die separat protokollierten Originale das Ende der jeweiligen Native-PID und die tatsächlich wiederaufgenommene MainActivity. Die Host-PID bleibt 6350.

Beim ersten Rückweg meldet die negative Ausgabe die Session `01ce59e6bc6ae65f8f6745ff70e55e41`; beim letzten die neue Session `c7a34925a1a7164b6ee0cbf5d97d2ff9`. Der wieder geöffnete Prozess besitzt eine andere PID und einen anderen Token, aber denselben Besitzer, dieselbe gespeicherte Runde `9e8cbfb7d1dcab2c0e2f6e094548104b`, dieselbe Datensatzrevision 5 und dieselben Züge `[3,3,2,3]`. `rewarded` bleibt false.

**Beobachtungsgrenze:** Bei allen drei nicht leeren Abfragen dieses erfolgreichen Laufs lebte die jeweilige Native-PID noch. Der frühere Fehlerzustand „PID bereits weg, Datei noch vorhanden“ wurde in diesem neuen Lauf nicht erneut beobachtet. Die Originale belegen korrektes Abwarten bis zur gemeinsamen Endbedingung; sie beweisen nicht nachträglich eine bestimmte Ursache des älteren Timingfensters.

## Sichtbarer erster C4-Rückweg und transparente Korrektur

Die tatsächliche Reihenfolge lautet:

1. `originals/c4/return-first-flutter.png`, SHA-256 `ba51f3f5b757acc8975983beee9c8fede197e10c53649c2f2045ddb392f3fb4e`: **frühes stale Nativebild**, trotz des ursprünglichen Dateinamens. Es zeigt die native Pause mit „Bitte kurz warten“. Der Reader-PASS für das gesamte Verfahren macht dieses einzelne Bild nicht zum Flutter-Beleg.
2. `originals/c4/return-first-to-games-00-frame.png` und `-01-frame.png`, beide SHA-256 `b90d1e9c4715032a4990d5694e740024ce5e9a3dcfa6b8a696904540d7824beb`: spätere echte **Flutter-Pause** mit „Spiel pausiert“, „Fortsetzen“, „Zur Spieleauswahl“ und „Neu starten“. Beide Originalaufnahmen sind byteidentisch; eigene XMLs und monotone Beobachtungszeiten 1648,191522930 und 1649,359171192 sind erhalten.
3. Der anschließende Originaltouch `0335-return-first-to-games-touch` ist `input swipe 540 1440 540 1440 120`, Exit 0, innerhalb des aktuellen XML-Zielbereichs `[116,1377,964,1503]`. Keine zweite Native-Rückkehraktion wurde benötigt.
4. Die erste nachfolgende Spielebeobachtung zeigt noch die Flutter-Pause und wird abgewiesen. Erst `originals/c4/return-first-games-001-frame.png`, SHA-256 `5310fb1aaa50702f9fe321e642b4b6b9e92dd35c95562cfcd7127b18339189c9`, zeigt die tatsächliche **Spielewelt** mit 4.-Gewinnt-Kachel und aktivem Spielen-Tab. Das zugehörige XML und die monotone Zeit 1654,264608993 sind erhalten.

Der unabhängige Reviewer ordnete die späteren b90-Zielbilder zunächst vorläufig falsch als native Zwischenbilder ein. Diese zusätzliche Blockerbehauptung wurde ausdrücklich gegenüber Root und Android-QA zurückgenommen, bevor irgendeine Quellenänderung erfolgte. Erneutes Öffnen und der genaue Pixelvergleich klären den Befund: Die beiden b90-Bilder sind vollständig identisch; gegenüber dem tatsächlich gesehenen finalen Flutter-Pausenbild unterscheiden sich nur 221 Pixel in der Android-Statusleiste. Unterhalb y=100 sind die Bildinhalte exakt gleich. Root hat ba51, b90 und 5310 anschließend ebenfalls persönlich geöffnet und die Pixelbeziehung bestätigt. Es wurde kein Originalbild geändert oder ersetzt.

Der zweite C4-Rückweg zeigt bereits in `return-final-flutter.png` die tatsächliche Flutter-Pause; spätere Zielbilder, ein eigener sichtbarer Touch und `return-final-games-001-frame.png` belegen ebenfalls den vollständigen Rückweg zur Spielewelt. Beide Originalsequenzen und ihre XML-/Touch-/Prozessbezüge stehen in `visual-review.json`.

## Dorf und echte Fahrtbilder

Die tatsächliche Dorf-Native-PID ist 6686. Der PID-gebundene Ready-Marker benennt die wirkliche Szene `res://scenes/creative/build_settlement_world.tscn`, `host_entry=true`, `living_village=true`, `return_scene=games`, Slot 1, neun Grundstücke, zwei Bewohner, zwei sichtbare Bewohner und neun initialisierte Grundstücksknoten. `save_blocked=false`; der tatsächliche Speicherpfad steht unverändert im Manifest. Die zugehörige PID meldet im Original um 20:18:53.941 UTC `[LumoHost] return: games`.

Auch die Dorf-Rückkehr bewahrt einen negativen Zwischenbefund: Der erste noch native Frame wird wegen fehlender sichtbarer Spielen-Beschriftung abgewiesen. Die zweite Beobachtung bestätigt nach insgesamt 23,346 Sekunden die tatsächliche Flutter-Spielewelt, sichtbare Semantik, unveränderte Profil-/Lernwerte, MainActivity und beendeten Native-Prozess. Der akzeptierte Originalframe `originals/village/returned-flutter-frame.png` hat SHA-256 `43ec359af33f96bd47299bb6c933c45c7269c7aa5f6cfb3fb4d2c033dff90d8b`. Der native Dorf-HUD und der abgelehnte erste Frame werden ebenfalls erhalten.

Das persönlich geöffnete Kart-Original `main/21_race_driving_late_2.png` zeigt Kart, Fuchs, Straße, Minimap und Fahrbedienelemente. Sein HUD zeigt Runde 1/2 und Platz 6/6. Der statische Screenshot ist keine Geschwindigkeits-, Rennabschluss- oder FPS-Messung. Die Haupttour nennt selbst den vollständigen Rennabschluss, physisches Gerät, GPU-Frametimes und Audioausgabe als nicht geprüft.

## Dauerhafte Belege und Grenzen

- `original-artifact-index.json`: vollständiges Inventar aller 2.875 Originaldateien.
- `original-non-png-files.zip`: **alle 2.482 Nicht-PNG-Originale**, vollständig zurückgelesen und byte-/CRC-geprüft; 6.220.150 Bytes, SHA-256 `273bf2b93211e693534a95b9a0c0c56e6137438ea07399da29c9872af8815c67`, Gitblob `6f0b2bc28de6cdcb3b1db84ae2803abc42b949d0`. Der Container wurde neu komponiert; die enthaltenen Originaldateien sind unverändert.
- `originals/`: ausgewählte Originaltexte und **40 PNG-Pfade mit 19 unterschiedlichen Bildblobs**, einschließlich aller 25 vom vollständigen C4-Leser ausgewerteten Brettbeobachtungen, beider Rückwege und der abgewiesenen Zwischenbilder. Die Auswahl ist kein Ersatz für das vollständige 173-MB-Artefakt.
- `replay/`, `reader/`, `metadata/`: tatsächliche Ausgaben, unveränderte Reader, alle 79 Quellidentitäten, vollständige QA-/Evidenzbäume und Vorher-/Nachher-Snapshots.
- Der terminale Androidjoblog wurde **ausschließlich von Root einmal aus Actions geladen**. Er wird direkt unter seinem bestehenden Gitblob `ea8be56e6a94462d2fb86ef0360fed70a5b5adf2` verknüpft; führendes U+FEFF und Originalbytes bleiben erhalten. Ursprung: Commit `ac9f524f6b446559943281a5c927f2bd0884eaf8`, `docs/evidence/current-hostec-review-20261114/c4-cleanup-diagnostic-132568698911.original.log`.
- Vorhandene Android-SurfaceSyncGroup-Warnungen bleiben in den Originalen und in ausgewählten zeilengenauen Auszügen erhalten. Es wird keine Warnungsfreiheit behauptet.
- Dieser Nachfolgecheckpoint ergänzt ausschließlich den neuen Laufpräfix im vorhandenen eigenen Evidenzzweig. Alle 5.170 Dateien des bisherigen Evidenzstandes bleiben mit identischen Blobs und Modi erhalten; weder zentrale Quellen noch Laufzeit-/Host-Pins werden verändert.

Die lokale unabhängige Auswertung öffnet die vorhandenen Originale erneut. Sie ist keine erneute Geräteausführung und keine Wiederholung der 155 Vertragsfälle. Die maßgebliche vollständige Host-Abnahme bleibt davon getrennt.
