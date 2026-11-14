# Aktueller Memory-Nachweis: Native 29080 / Host 50503

Der tatsächliche Memory-Job `132498257329` im Authority-Run `43611803404` ist erfolgreich abgeschlossen. Das genau einmal geladene Originalartefakt `14121055393` umfasst **3.943.943 Bytes**, SHA256 `08c927e6f7eaa78c202c9b494abb540f8b087bc22b1990a242ae8a050e1ab948`. Alle 73 ZIP-Mitglieder sind CRC-geprüft, alle 28 PNGs vollständig dekodiert. Genau 15 aktuelle Originalbilder wurden einzeln geöffnet. Ihre Feststellungen und Hashes stehen in `review.json`; es besteht kein neuer blockierender Sichtbefund.

## Quellen und tatsächliche Ergebnisse

Native `29080ef8cd1a5b385eeeec97976fbefd31280427`, Tree `5ddbea2b1d5e76ed592a27c36079632d7f26cada`, und Host `50503fef8e93700d9a889e33c3d2c37fccb46e42`, Tree `59c469de6252d368470bb41b0bcef21151cec826`, sind vor und nach dem Lauf identisch und durch vier Originalstempel gebunden. Der frisch gelesene Workflow pinnt diesen Host ausdrücklich.

- Produktions-Dart-Verträge: 30 Fälle, 1.694 Checks, kein Skip.
- Produktionsscheduler: sieben Fälle, 13 Checks, kein Skip.
- Produktionspresenter mit Zustands- und Insetfixture: 7.020 Checks, acht Captures.
- Tatsächliches Zweiprozess-Paar: 243 Checks im Bericht, 244 im Terminal; 19 ScreenTouch-Press/Release-Paare, 19 unveränderte Requests und positive ACKs, 32 öffentliche Zustände sowie drei dauerhafte Rückkehraktionen mit drei geschlossenen Token. Beide Prozesse enden mit 0. Die aktuelle Laufzeit beträgt 112,859 Sekunden.
- Der letzte zusätzliche Check prüft das atomische QA-Ergebnisfile nach Erstellung des JSON-Berichts. Die 57 Input-Journalzeilen zählen 19 Press-, 19 Release- und 19 Request-Einträge; sie sind keine 57 Spielzüge.
- Die unfertige Runde `173dd1b942370e699b85bcec29e782de` bleibt bei Wiederöffnung mit 550 ms Restzeit pausiert erhalten. Die abgeschlossene Runde `9d9973d834867146e4d24a8449db15a2` hat `rewarded=true`. Danach entsteht die neue Runde `a7527341fa5af07c48b8b415ab91fcdd` mit denselben Einstellungen und erhaltenen Bestwerten. Genau ein QA-Ledgereintrag zahlt zwei Sterne und 16 XP.

Die acht Spielzustandsbilder zeigen Kartenrückseite und Vorderseite, Pause, Wiederöffnung, beide Bot-Aufdeckungen, Sieg und die neue Runde nach bestätigter Belohnung. Vier Formatbilder zeigen Phone, Fold, Compact und Cutout. Drei weitere Bilder zeigen Anfang, Kante und Ende des tatsächlichen Flips. Die weiteren 13 PNGs sind ausschließlich als dekodiert gekennzeichnet.

## Abnahmegrenze

Produktions-Dart und Godot sind hier über expliziten QA-Dateitransport, Uhrfixture, privaten Deckplan und QA-Rewardledger verbunden. Das ist kein Nachweis für Android-Binder, SharedPreferences, globale Wallet oder Geräte-FPS. `--fixed-fps 60` beschreibt die Testuhr. Sechs echte Rendererwarnungen bleiben erhalten; in den geprüften Engine-Originalen gibt es keine ERROR- oder SCRIPT-ERROR-Zeile. Für diesen Review wurde kein lokaler Test neu gestartet.

Beim gesicherten Abruf nach dem Memory-Abschluss lief der gemeinsame Authority-Run noch. Die vollständige Legacy-Native-Suite und die kombinierte Bildfreigabe werden von Root getrennt geprüft. Dieser Memory-PASS ersetzt diese Gates nicht.

## Separater aktueller Hostabschluss

Dieses Dokumentmanifest enthält zusätzlich die drei neuen 2e20-Flutterdokumente und deren unverändertes Manifest. Der neue terminale Originaljob `132492830056` bestätigt **2.608 PASS, 0 FAIL und 0 SKIP**. Dieser Hostlauf wird nicht als paired Host ausgegeben. Seine 546 generierten PNGs werden nicht als persönlich gesichtet bezeichnet.
