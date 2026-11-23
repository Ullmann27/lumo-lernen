# APK 2071 · verbindlicher Android-Prüfhalt

Stand: 23. November2026,16:34Uhr Wien. Dieser Bericht betrifft ausschließlich Flutter **b4db287fe562893d849d1c826c9b92e8f2e44761**, Godot **e0460c0b3eda9d42e9d963eb2236dc8d9c7b5913**, Version **0.14.2+2071**, Bauauftrag48.

## Tatsächliches Ergebnis

[Originalrun45191784853](https://github.com/Ullmann27/lumo-lernen/actions/runs/45191784853) ist abgeschlossen. Baujob137751923651 erfolgreich; Androidjob137767273722 fehlgeschlagen; Veröffentlichung137795206593 übersprungen. Die APK ist gebaut, **nicht freigegeben**.

Die Originaltour besteht23 Schritte. Der SAF-Sicherungs-/Wiederherstellungsablauf besteht alle8 Pflichtschritte: APK-Identität, künstliches Profil, Export, Archivprüfung, geänderte Einstellung, SAF-Auswahl/Prüfung, Prozessschließen und Wiederherstellung.17 Einstellungs-/Lerndateneinträge und9 native Spielstandsdateien wurden berücksichtigt; die neun Dateien sind nach Wiederherstellung bytegleich. Der installierte x86_64-Digest bleibt57a48218d833a3e5114cf8ae93d7a32acd51b0aa10d1e9dad6483699e785f306.

Das verpflichtende Native-Gate beendet sich mit:
`ValueError: memory: missing positive observation for router_loaded`.

| Pflichtspiel | Tatsächlicher Startbeleg |
|---|---|
| run | UI-Klick, passender Routermarker, lebender neuer nativer Prozess |
| quiz | UI-Klick, passender Routermarker, lebender neuer nativer Prozess |
| memory | Kachel und3D-Tisch angeklickt, TableGameActivity/PID6847 vorhanden, kein aufgezeichneter Routermarker |
| chess | Kein erfolgreicher Kachelklick, weiterhin Memory-Activity undPID6847 |
| kart | UI-Klick, passender Routermarker, lebender neuer nativer Prozess |
| cards | UI-Klick, passender Routermarker, lebender neuer nativer Prozess |
| world | Kein erfolgreicher Kachelklick, weiterhin Schatzsuche-Activity/PID8937 |

Die vorangehende Schatzsuche war ebenfalls ohne aufgezeichneten Routermarker. Das abschließende NATIVE-GAME-STARTS.json wurde wegen des Fehlers nicht erzeugt.

## Originalbelege

Artefakt14831399839, **92447590Bytes**, SHA256 **61709df3558f864800a2476bed01236ede9713c45a947e2e5193611bcfae6252** wurde heruntergeladen und unabhängig gegen den GitHub-Digest geprüft. Die vier JSON-Dateien sind unverändert aus diesem Archiv unter [Androidbelege](../evidence/team-b-2071/android) gesichert. Dateihashes stehen in [ANDROID-HOLD-RECEIPT.json](../evidence/team-b-2071/ANDROID-HOLD-RECEIPT.json).

Die tatsächlich geprüften END-Bilder zeigen:
- Memory: vollständige gerenderte Memory-Szene; beim folgenden Schach-Endbild weiterhin dieselbe Szene und dieselben Host-/Native-PIDs6747/6847.
- Schatzsuche: gerenderte Insel; beim folgenden World-Endbild weiterhin dieselbe Schatzsuche und dieselben PIDs8837/8937.
- Keine dieser vier Ansichten ist leer oder zeigt einen Android-Fehlerdialog. Sie beweisen keine vollständige Bedienbarkeit und ersetzen keinen fehlenden Router-/PID-Nachweis.

Die Original-ZIP-Einträge memory-logcat-tail.txt undtreasure-logcat-tail.txt sind nach ZipInfo jeweils exakt4096Bytes und enden mitten in einer Accessibility-Zeile vor dem betreffenden Native-Start. Es handelt sich nicht um eine lokale Extraktionskürzung. Die vier gefilterten fehlgeschlagenen Szenenlogs enthalten jeweils nur einen Zeilenumbruch. Ihre Null-Fehlerzähler belegen deshalb keinen vollständigen fehlerfreien Start.

## Belegte Lücke im Collector

Der Collector, sein Pflichtgate, der ADB-Helfer und der native Router-/Memory-Code sind zwischen dem erfolgreichen Hauptteam2070 und2071 bytegleich. Der Hauptteamlauf beobachtete Memory nach5,3s, Chess5,2s, Treasure5,5s undWorld10,3s. Das45s-Wartefenster ist kein belegter Engpass.

Der Collector verwendet check=False auch für kritischeADB-Kommandos. Nach am force-stop werden Prozessende und Host-Rückkehr nicht bestätigt. Der bestehende Launcher akzeptiert irgendeine Activity desselben Pakets; eine noch laufende native Activity genügt ebenfalls. So wird ein fortbestehender Memory-/Schatzsuche-Prozess im nächsten Abschnitt als neuer Startversuch behandelt. Der Collector bewahrt zuvor beobachtete Routerzeilen außerdem nicht vollständig, sondern wertet zuletzt erneut den abschließenden Dump aus.

Die genaue server-/transportinterne Ursache der historischen4096Byte-Antwort lässt sich mangels gespeicherter Rückgabecodes nicht nachträglich beweisen. Ein Memory-Produktpatch, mehr Wartezeit oder eine gelockerte Regex ist nicht begründet.

## Nächste begrenzte Korrektur

Nur Collector und zugehörige Regressionstests werden bearbeitet: kritischeADB-Exitcodes und vollständige Antworten prüfen, vollständige Prozessabfrage sicherstellen, Altprozesse vor dem nächsten Start tatsächlich beendet bestätigen und einen echten Flutter-Host vor der nächsten Kachel verlangen. Bei verbleibendem Fehler muss der Ablauf sichtbar scheitern. Das bestehende Pflichtgate und sämtliche Produktdateien bleiben unverändert. Screenshots werden nicht anstelle von Routerbelegen alsPASS gewertet.

Danach ist ein frischer vollständiger Standardlauf erforderlich. Der historische2071-Fehler bleibt erhalten; ein zukünftiger Erfolg ersetzt seine Belege nicht rückwirkend.

## Auslieferung bleibt angehalten

Die originale ARM64-APK537231343Bytes/SHA256c7036b318ba9f3e0c0751abcc1f3745ce0fd0a96a617954501feb40b63627737 wurde nach dem Runtime-Ausfall erneut aus dem bereits vorhandenen Transfer rekonstruiert und vollständig geprüft. Der ZIP-Fallback525512427Bytes/SHA256c07827ff4e93ea0100be650f9df434d754db7b05506fc0e4a2a7e9abe63958b4 enthält nur diese unveränderte APK und ist nach vollständigem Wiederauslesen hash-/CRC-geprüft. Beide Dateien sind jetzt Diagnose-/Beweiskandidaten und keine freigegebene Nutzerlieferung.

Der eigene2071-Publisher wurde wegen des Native-Fehlers übersprungen; für diesen Run gibt es keine403-Veröffentlichungsantwort. Der tatsächlich beobachtete zusätzliche403-Berechtigungsblocker betrifft den früheren Hauptteam-Publisher. Der separate vorbereitete Publisher ist nicht aktiviert und würde den fehlgeschlagenen Original-Androidjob zurückweisen. Keine Secrets, kein Umgehen von Berechtigungen, kein Merge inMain.
