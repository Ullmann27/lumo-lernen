# Studio 2020: angeschlossene 3D-Funktionen und überprüfbare Integration

Dieser getrennte Entwicklungskandidat baut auf Host `86445f53af5d573549fc8cf03405261611f3cb7e` und Native `803e7a626ea6ef0aeeda9c37010e844033d3a8e3` auf. Die tatsächlich geprüfte neue Native-Quelle `785413d395292a243eaa0a0748671eb15d3f80ff` ist für Version `0.13.8+2020` ausdrücklich durch `config/godot-source.json` gebunden. Die bisherigen Studio-2019-Quellen, ihre Versionszuordnung und Main werden durch diesen Kandidaten nicht ersetzt.

Die Beschreibung einer implementierten Funktion ist keine pauschale Abnahme. Die tatsächlich erfolgreichen Ausführungen stehen in den zugehörigen Originalprotokollen. Insbesondere sind lokale Rendererläufe, Android-Emulatorprüfungen und Messungen auf einem physischen Fold7 unterschiedliche Nachweise.

## Tatsächlich verfügbare Fähigkeiten

| Bereich | Einordnung | Tatsächliche Grundlage und Grenze |
|---|---|---|
| Godot-Szenen, GDScript, GLB und Shader bearbeiten | direkt umsetzbar | Godot 4.6.3 und die vorhandenen Originalquellen sind verfügbar. Änderungen werden in erreichbare produktive Szenen eingebunden. |
| Echte Geometrie und exportierbare Animationen erzeugen | mit vorhandenen Werkzeugen umsetzbar | Blender 4.3.2, programmatische Meshbearbeitung und GLB-Export; Originalmodelle werden quellengebunden erhalten. |
| Charaktersteuerung, Skelettanimation und Kameras integrieren | direkt umsetzbar | Vorhandener 65-Bone-Lumo, Godot-Physik, bestehende Zustände und tatsächliche Laufzeitszenen. |
| Flutter/Godot unter Android verbinden | mit vorhandenen Werkzeugen umsetzbar | Flutter 3.44.9, Dart 3.12.2, Kotlin-Hostvorlagen und GitHub-Android-Prüfläufe. Die neue gemeinsame APK benötigt eine eigene Abnahme. |
| Szenen rendern und Bilder/Filme prüfen | mit vorhandenen Werkzeugen umsetzbar | Echte Godot- und Blender-Renderer; FFmpeg für vollständige Decodierung und Formatprüfung. Eine Aufnahmerate misst keine Geräte-FPS. |
| GitHub-Branches, Draft-PRs und unabhängige Entwicklungsarbeit | direkt umsetzbar | Root und drei tatsächlich eingesetzte Agenten; getrennte Dateiverantwortung, Quellmanifeste und explizite Git-Tree-Änderungen. |
| 60 FPS, Temperatur und physische Touchlatenz auf Galaxy Z Fold7 | derzeit blockiert | Kein physisches Zielgerät angeschlossen. Emulator- und Headless-Ergebnisse ersetzen diese Messungen nicht. |

## Neue produktive Funktionen dieses Kandidaten

### Vier Gewinnt: echter Spielraum mit bestehender Regelautorität

Die vorhandene Dart-Engine bleibt für legale Züge und die drei Botstärken verantwortlich. Der neue Godot-Spielraum stellt das Brett als tatsächliche Geometrie mit Dicke und 42 durchbrochenen Feldern dar. Spielsteine fallen mit sichtbarer Landebewegung; vier Ringe markieren einen gewonnenen Zug. Die Szene ist über den normalen Spieleinstieg und die bestehende Flutter/Godot-Verbindung erreichbar.

`connect_four_round.dart` und `connect_four_table_session.dart` verbinden den Spielraum mit legaler Zuggeschichte, revisionsgebundenen Zustandsänderungen, einer getrennten Kindzuordnung und idempotenter Belohnungsvergabe. Der Native-Client bestätigt keine eigene erfundene Runde. Der Host speichert den Zustand vor der Bestätigung; veraltete oder fremde Sitzungsanfragen werden abgewiesen.

Die Android-Vorlagen ergänzen eine eigene `ConnectFourGameActivity`, `ConnectFourBridge` und `ConnectFourAuthorityService`. Pause, Hintergrundwechsel und erneutes Öffnen verwenden eine begrenzte Sitzungslaufzeit. Vorhandene Cards-Mechaniken und deren Speicherprotokoll bleiben getrennt erhalten.

Die Touchspalten werden aus dem tatsächlichen projizierten Brett abgeleitet. Kleine Ansichten konzentrieren sich auf das Brett; breite Ansichten zeigen zusätzlich Lumo. Der kleine Hochkantmodus stellt noch keinen neben dem Brett stehenden Lumo dar.

### Original-Lumo: Lid-, Blick- und Sprachbewegung

Der gemeinsame native `LumoRiggedActor` verwendet eine mobile Gesichtsableitung des vorhandenen Originalmodells. Originalkörper, Skelett, neun Originalclips und sechs vorhandene Studio-Bewegungsclips bleiben erhalten. Hinzu kommen echte skinned Lid- und Faltengeometrie, Blickbewegung und eine dezente Schnauzen-/Kieferbewegung.

Im Lernraum folgt die Sprachbewegung dem lokalen Sprachzustand. Die Android-Komponente `LumoSpeechEnvelope.kt` ermittelt eine PCM-Amplitudenhülle; `LumoLearningSpeech.kt` verwendet die tatsächliche Wiedergabeposition des MediaPlayer. Stummschaltung, Stopp und veralteter Zustand schließen die Sprachbewegung. Dies ist amplitudenbasierte Artikulation. Ein phonemgenaues Visemsystem oder ein vollständiger animierter Mundinnenraum wird nicht behauptet.

Die Android-Installation kopiert die neue Hüllkurvenklasse mit den übrigen Hostvorlagen. Die echte Host-Kompilierung verlangt zusätzlich deren Bytecode sowie die drei neuen Vier-Gewinnt-Komponenten.

### Verständliche Rückmeldungen und zuverlässige Wiederaufnahme

Die deutschen Cards-Rückmeldungen verwenden eine passende Ansprache und die bereits vorhandenen angezeigten Farbnamen. Spielregeln, gespeicherte Farbwerte und das Wire-Format werden dafür nicht geändert.

Der Treasure-Titel erhält einen festen Hintergrund, damit heller Himmel nach dem Wiederaufnehmen die weiße Schrift nicht verdeckt. Questlogik, Weltzustand und Eingaben bleiben erhalten. Kompakte OCR und die bestehende Hochkantellipse sind weiterhin gesondert dokumentierte Grenzen.

Die tatsächliche Sichtprüfung des erfolgreichen Native-Laufs `43565059832` deckte zusätzlich auf, dass das große Aufgabenfeld Lumo am Start in kurzem Querformat verdeckte. Dort ersetzt ein großer Hinweisbutton das dauerhafte Feld. Der vollständige vorhandene Text öffnet in einem scrollbaren Dialog; Schließen führt ohne Änderung des Queststands zurück. In hohen Ansichten bleibt das direkte Hinweisfeld erhalten. Auch die allgemeine Erkundungsmeldung erhält einen kontrastfesten Hintergrund und hält Abstand zu den tatsächlichen Touchflächen. Die Kamera, Welt, Physik und Speicherdaten werden dafür nicht neu implementiert.

Die neue gezielte Prüfung bindet die tatsächlich projizierten Meshgrenzen der Spielfigur, HUD- und Touchrechtecke sowie echte Dialogeingaben in fünf Formaten, jeweils bei Frischstart und Wiederaufnahme eines ausdrücklich deklarierten Altstands. Die zusätzliche Querformat-Aufnahme mit seitlichem Displayausschnitt ist im Host-Bildvertrag verpflichtend; die bisherigen vier Titelbilder können sie nicht ersetzen.

Die Creative-Android-Prüfung behebt drei tatsächlich beobachtete Erkennungsprobleme: Der Bewegungsstick wird relativ zur kurzen Bildschirmkante bewertet, der Puzzle-Rahmen anhand seiner tatsächlichen Farbe und Geometrie erkannt und eine wiederbetretene Szene muss vor der nächsten Zurück-Aktion stabil sichtbar sein. Die begrenzten Wartezeiten und die eigentlichen Spiel-, Speicher- und Rückkehrbedingungen bleiben bestehen.

Die Flutter-Rückkehrprüfung weist außerdem den nachgewiesenen Ladebildschirm als negatives Ergebnis zurück. Ein passender Text allein genügt nicht: Vordergrund, sichtbare Grenzen und zwei aufeinanderfolgende positive Bilder bleiben vorgeschrieben.

## Vorhandene Lern- und Spielsysteme

Dieser Kandidat baut auf den vorhandenen Klassen 1 bis 4, individuellen Kinderprofilen, Lernfortschritten, Fehlerprotokollen und Freischaltungen auf. Schreibtrainer, Journal, Lese-/Sprachfunktionen, Offlineinhalte und Elternfreigaben werden nicht durch neue Parallelimplementierungen ersetzt.

Die bestehenden 3D-Lernaufgaben, Jump-/Bauwelt-Bewegung, Bauprojekte, Puzzle- und Treasure-Spielabläufe, Cards-Runden sowie Kart-Strecken bleiben die Grundlage. Die Ergänzungen hier sind keine neue vollständige Produktion aller Englisch-, Geschichten-, Memory- oder Quizwelten und keine erneute grafische Fertigstellung aller zwölf Kart-Strecken.

## Verbindliche Prüfung des gemeinsamen Kandidaten

1. Die Native-Quelle `785413d395292a243eaa0a0748671eb15d3f80ff` hat [Studio-2020-Lauf 43570887024](https://github.com/Ullmann27/lumo-godot/actions/runs/43570887024), Versuch 1, mit allen neun Jobs einschließlich `archive-evidence` erfolgreich abgeschlossen. Auch die sechs zusätzlichen PR-Prüfläufe sind erfolgreich. Der erste Lauf am Commit `8be3a95d5d948d457c4c39bc6694138d60b70027` bleibt als fehlgeschlagen dokumentiert. Der nachfolgende Commit `acf51d3bd2997c4b731e9a48e1791e05e756a132` bestand seine CI, wurde aber wegen der tatsächlich sichtbaren Verdeckung von Lumo nicht als endgültiger Hostpin freigegeben.
2. Root hat das vollständige aktuelle Originalarchiv 14105224381 heruntergeladen: 227.410.428 Bytes, SHA-256 `31c926ae589073839dd4e89c955a0b59644c23e355e7685a4e31149d22d32c4e`, alle 5.085 ZIP-Einträge CRC-geprüft und fünf Quellstempel ohne lokale Änderungen an exakt `785413d395292a243eaa0a0748671eb15d3f80ff` gebunden. Root und die drei Agenten haben alle 49 ausgewählten Originalbilder aus zehn Modulen tatsächlich geöffnet. `config/studio-2020-visual-review.json` bindet die neuen Einzelbefunde, Originalpfade und Bildhashes an genau diesen Run und dieses Artefakt. Der tatsächliche `verify_visual_review`-Aufruf ist erfolgreich; die 49 unveränderten PNGs sind unter `docs/evidence/studio-2020-reviewed/` enthalten. Erst nach dieser Native-Abnahme wurden Versionszuordnung und Hostpin gesetzt. Alle 50 historischen Zuordnungen bleiben erhalten; die aktualisierten 26 Pin-Tests sind tatsächlich mit Exit 0 und ohne Skip gelaufen. Das ist keine Android- oder APK-Freigabe.
3. Der Host führt die erhaltenen Flutter-, Native- und Android-Hostprüfungen aus. Der neue Vier-Gewinnt-Test startet einen tatsächlichen Dart-Prozess und einen tatsächlichen Godot-Prozess vor dem APK-Bau. Lokale Test-Preferences werden dabei nicht als Android-Persistenz ausgegeben.
4. Android 35 und Android 37 verwenden jeweils dieselbe zuvor installierte und gehashte Kandidaten-APK für Haupttour, Studio-Oberflächen und Vier Gewinnt. Der zusätzliche C4-Probelauf bedient die echte Oberfläche, prüft zwei Kinderzüge mit Botantworten, Pause, Hintergrundwechsel, Wiederaufnahme, Sitzungsbindung, sichtbare Spielsteine und die Rückkehr in dieselbe Lernaufgabe.
5. Die eigene Creative-Tour und das tatsächliche Update von 2017 auf 2020 bleiben Pflicht. Der Update-Test prüft seinen konkret aufgezeichneten Testdatensatz; daraus wird keine ungemessene Vollständigkeit für alle denkbaren Datenbestände abgeleitet.
6. Vor der Veröffentlichung werden die drei vollständigen Originalartefakte erneut von GitHub gelesen. ZIP-Größe, SHA-256, Eintragsintegrität und sämtliche entpackten Dateien müssen übereinstimmen. Der C4-Publisher bindet zusätzlich Quellstände, aktuellen Run-Versuch, erfolgreiche Jobs, originale Zustände, Bilder, Laufzeitdaten und die installierte APK.
7. Eine bestehende Versionsveröffentlichung wird nicht mit anderen APK-Bytes überschrieben. Der Kandidat bleibt von einem Main-Merge getrennt.

## Grenzen der Abnahme

Ein erfolgreicher gemeinsamer Kandidat belegt genau seine ausgeführten Prüfungen. Er belegt keine stabile thermische 60-FPS-Dauerleistung auf dem Fold7, keine vollständige Mehrkind-Datenmigration außerhalb des tatsächlich geprüften Datensatzes und keine pauschale AAA-Qualität aller vorhandenen Welten. Diese Grenzen bleiben im Releasebericht sichtbar.

Der aktuelle erfolgreiche Native-Lauf `785413d` enthält im Gameplay-Originalprotokoll vier Meldungen über zwei beziehungsweise vier beim Prozessende noch verwendete Ressourcen. Die originalen Studio- und New-Worlds-Protokolle enthalten keine tatsächlichen Engine-ERROR-Zeilen. Vier gezielte lokale Kart-Prozesse wurden zusätzlich mit `--verbose` und unveränderten Zeitbudgets ausgeführt; sie bestanden, ohne die CI-Ressourcenmeldung zu reproduzieren. Die Ursache der CI-Abschlussmeldungen bleibt offen. Erfolgreicher Jobstatus wird deshalb nicht als fehlerfreies Log oder als Nachweis der Harmlosigkeit dieser Meldungen dargestellt.

Die Sichtprüfung dokumentiert außerdem dichte HUDs und horizontal scrollende Werkzeugleisten in Bauwelt und Jump, einen teilweise überlagerten obersten Kopf-/Brillenbereich in einer breiten Cards-Ansicht, die kleine Hochkantdarstellung von Vier Gewinnt ohne Lumo neben dem Brett sowie eine dünne Lidnaht und dezente Sprachartikulation. Der aktuelle Gesichtsfilm wurde vollständig decodiert und in allen 148 Frames angesehen; drei dunkle Abschlussframes bleiben benannt. Der Audiostream wurde decodiert, aber nicht angehört. Diese konkreten Grenzen werden durch die Native-Abnahme nicht verschwiegen.

Stand dieses Quellcommits: Die Native-Abnahme und die lokalen Pin-Verträge sind abgeschlossen. Der gemeinsame Host-2020-Lauf, die beiden Android-Touren, das Update 2017 → 2020 und die Creative-Tour müssen erst für diesen Hostcommit erfolgreich ausgeführt werden. Es liegt hier noch keine freigegebene Android-2020-APK vor.
