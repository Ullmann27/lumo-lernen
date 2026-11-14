# Jump: belegten Hochformatfehler im Android-Prüfer korrigieren

**Status: isolierter QA-Fix geprüft; neue Android-Ausführung weiterhin erforderlich.**

Basis ist der tatsächlich geprüfte Host `4ab96666f954baf258422d6ed277fc297b7ddeef` mit Native `803e7a626ea6ef0aeeda9c37010e844033d3a8e3`. Keine aktive Produktquelle, APK, Versionsbindung, CI-Konfiguration oder Git-Referenz wurde geändert.

## Originalbefund

Im tatsächlichen Run `43530667812`, Job `132269951369`, wurde Jump über die aktuelle Flutter-Semantik erreicht. Der anschließende erste Pause-Touch scheiterte jedoch vor jeder OCR-Abfrage: Alle 28 protokollierten Bilder messen 1080 × 1920 Pixel. Der Prüfer lehnte sie ausschließlich mit `native landscape surface has not arrived` ab. Das vorhandene Native-Spiel läuft hier im Hochformat; es verwendet nicht den Querformathandoff der anderen Creative-Szenen.

Der Originalbericht `original-android-pause-surface-readiness.json` behält das 120-Sekunden-Limit und den tatsächlichen Ablauf. Der letzte Screenshot-Prozesstimeout wurde mit nur noch rund 0,47 Sekunden Restbudget aufgerufen. Das ist ein Folgeereignis der vorherigen Formatverwerfung. Es ist kein Beleg für einen Jump- oder Gold-OCR-Defekt.

Das vollständige Creative-Originalartefakt `14092241868` besitzt 526.570.745 Bytes und SHA256 `bd1660a6032c9adba051f209ab3979ea1888d03ffeb902bd0403d3f813a61d40`. Es enthält kein Jump-Video und keinen Jump-Checkpoint. Der ursprüngliche Lauf kann deshalb weder reale Jump-Eingaben noch dessen Speichern oder Wiederaufnahme belegen.

Die verwendeten Originalbilder zeigen die vollständige Hochformatszene mit Original-Lumo, Stick links, Sprungknopf rechts und sichtbarem Pause-Knopf oben rechts. Die dunkle kurze Bedienhilfe überlagert einen Teil der oberen Kopfzeile. Daraus wird weder ein neuer Gameplayfehler noch eine Abnahme der Kopfzeilenqualität abgeleitet.

## Enger Patch

`jump-probe.patch` ergänzt einen optionalen Orientierungsparameter an `Tour.native`, `Tour.observe` und `Tour.leave`. Der bisherige Standard bleibt `landscape`. Ausschließlich die Jump-Aufrufe wählen die bereits vorhandene Richtlinie `responsive`.

`leave-helper.patch` ist ein getrenntes Delta: ein optionaler Parameter und seine Weitergabe in den beiden bestehenden `native_text`-Aufrufen. Das Ende des privaten Spielprozesses, der aktuelle Vordergrund, die echte Flutter-Rückkehr und das unveränderte Kinderprofil bleiben Pflichtprüfungen.

Die anschließenden Stick- und Sprungeingaben, ihre Dauer, Screenrecord, vollständige Videodekodierung, Videozeitabdeckung, Checkpoint-Identität und vollständiger Wiederaufnahmevergleich sind unverändert. `scope-preservation.json` belegt dies zusätzlich durch einen AST-Vergleich: Nach Entfernen ausschließlich der neuen Orientierungsargumente sind sämtliche veränderten Definitionen zum Original identisch. Alle 59 übrigen Definitionen der zwei Dateien bleiben unverändert.

Der gemeinsame Gold-OCR-Fix wurde separat auf `a446f3c1` veröffentlicht. Der hier gelieferte `leave`-Patch muss kontrolliert auf diesen neueren Helper angewendet werden. Diese Prüfung behauptet keine bereits erfolgte Integration darauf.

## Tatsächlicher Rot-/Grün-Nachweis

`replay_jump_orientation.py` führt den tatsächlichen Anfang von `Tour.jump()` und die tatsächlichen `native_text`-, `native_tap`- und `image_lines`-Funktionen aus. Der Hubeinstieg und der folgende Checkpoint-Leseschritt sind ausdrücklich lokale Stopppunkte; ADB ist ausschließlich ein Befehlsprotokoll ohne Geräteverbindung. Beide PNG-Dateien sind unveränderte Originalbytes. Die OCR verwendet echtes Tesseract 5.5.0 mit vorhandenen deutschen und englischen Sprachdaten. Nur die Wartepausen werden im lokalen Replay ausgelassen.

- **Original rot:** Beide vollständigen Hochformatbilder werden vor OCR abgelehnt; kein Eingabebefehl. Der begrenzte Replay endet danach mangels weiterer Originalframes. Er behauptet keine zweite 120-Sekunden-Androidausführung.
- **Patch grün:** Beide Originalbilder liefern durch echte OCR `Pause` mit Bounds `[964, 66, 1034, 83]`. Das erste Bild reicht ausdrücklich nicht. Erst das zweite stabile Ziel führt zu genau einem aufgezeichneten vorgesehenen Eingabebefehl und erreicht den unveränderten ersten Checkpoint-Leseschritt. Replay-Ausführungszeit rund 2,67 Sekunden; diese Zeit ist kein Gerätebenchmark.
- **13 von 13 enge Verträge bestanden:** vier neue Gegenfälle plus alle neun unveränderten bestehenden Creative-Verträge. Sie prüfen die tatsächliche Jump-Weitergabe, die zweite stabile Zielbeobachtung, den unveränderten Querformatstandard, unvollständige Bildflächen, ungültige Bounds sowie Prozess- und Vordergrundfehler beim Rückweg. Die regulären Offline-Verträge benutzen die separat tatsächlich gewonnenen OCR-Ergebnisse als explizite historische Fixture und benötigen kein Tesseract im normalen Testlauf.

## Grenze

Dies ist ein nachgewiesener Prüferfehler mit lokalem Gegenbeleg. Der neue vollständige Android-Lauf, tatsächliche Jump-Eingaben, ein frisches vollständig dekodiertes und visuell geprüftes Video, Speichern und Wiederaufnahme stehen noch aus. Aufnahme-Framerate, numerische Sprungphysik, Multitouch, stabile Geräte-FPS und physische Fold7-Leistung werden nicht behauptet.
