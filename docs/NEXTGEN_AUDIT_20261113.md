# LUMO Next Generation: geprüfter Bestand und Integrationsstand

Arbeitsdatum: 13. November 2026. Dies ist ein Entwicklungsprotokoll, keine Abnahme des gesamten Masterauftrags. Änderungen bleiben in `chatgpt/lumo-nextgen-20261113`, außerhalb von Main.

## Tatsächlich geprüfte Ausgangsquellen

| Repository | Ausgangs-PR | Tatsächlicher Commit |
|---|---|---|
| Ullmann27/lumo-lernen | #459 | `47889f74a651b073965def70743417cf320b1eb9` |
| Ullmann27/lumo-godot | #156 | `1d5c5cb45a323228f627ec529e6ff1ddd86f1c57` |

Diese Quellen wurden über GitHub überprüft, bevor Änderungen entstanden. Flutter-Basis: 0.13.5+2017. Neue PRs: Flutter #461 und Godot #157. Die abgeschlossenen Einzelstände und CI-Läufe müssen an ihren jeweiligen Commit gebunden werden; der lokale Basis-HEAD allein beschreibt nicht den noch uncommitteten Arbeitsbaum.

## Fähigkeitenmatrix

| Tätigkeit | Einstufung | Tatsächlicher Weg / Grenze |
|---|---|---|
| Godot-Szenen, GDScript, Materialien und Shader bearbeiten | direkt umsetzbar | Vorhandener Quellcode, Godot 4.6.3 und Szenenpfade lokal vorhanden |
| Original-GLB und Animationen untersuchen | direkt umsetzbar | Originalrig, Skin und Clips geprüft; Assets bleiben erhalten |
| Neue echte Geometrie erzeugen | mit vorhandenen Werkzeugen umsetzbar | Godot-Meshes/Instancing und Blender 4.3.2 verfügbar; keine Bildattrappen als Geometrie |
| Bewegung, Kollision, Kameras, Skeletalanimation integrieren | direkt umsetzbar | Produktionsszenen mit tatsächlicher Physik und Input-Ereignissen testbar |
| Flutter/Godot/Android verbinden | mit vorhandenen Werkzeugen umsetzbar | Flutter 3.44.9, Dart 3.12.2, Gradle 9.1.0, vorhandene Android-Activities und private Prozessbrücken |
| Lokale Headless-/Widget-/Datenprüfungen | direkt umsetzbar | Ausgeführte Tests, separate Testdatenordner, echte Datenwiederaufnahme |
| Echte Godot-Rendererbilder | mit vorhandenen Werkzeugen umsetzbar | GitHub-Linux-Runner mit X11/Mesa; lokale Shell besitzt keinen freigegebenen X11-Socket |
| APK bauen und im Emulator prüfen | mit vorhandenen Werkzeugen umsetzbar | Bestehende signierte CI-Buildkette plus neue Quelle-/Update-/Oberflächengates |
| Physische Fold7-Messung von FPS, Wärme und Eingabelatenz | derzeit blockiert | Kein Zugriff auf das physische Gerät; Desktop/Emulator ersetzt diesen Nachweis nicht |
| Neues anatomisch korrektes Lip-Sync/Blinzeln auf Originalrig | derzeit blockiert | Originalmodell hat keine Kiefer-/Lid-/Augen-/Ohrknochen und keine Gesichtsmorphs; Körpergesten sind kein Lip-Sync |
| GitHub-Sicherung und parallele Entwicklungsagenten | direkt umsetzbar | Tatsächlich gestartete getrennte Bereiche Lernen, Originalfigur/Jump, Kart, Bauwelt, Cards und Integration/QA |

## Inventur Lernen

Die App enthält bestehende Klassen-1-bis-4-Profile, Fehler-/Kompetenzverläufe, Tagesaufgaben, Belohnungen, adaptive Aufgaben, geführte Lernsequenzen, ein Offline-Lernatelier, Lehrkraft-/Elternansichten sowie Schreibtrainer, Wortschreibtrainer und Journal. Diese Systeme werden über bestehende Schnittstellen erweitert; kein Ersatz der Datenhaltung.

`LearningModuleRegistry` registriert 20 Themen mit 19 Screens: Zahlen bis 10, Plus bis 10, Minus bis 10, Formen, Tiere, Farben, Uhr, Geld, Zahlen bis 100, Artikel, Mehrzahl, Jahreszeiten, Wetter, Verkehr, Wortarten, Zeitformen, Wortdiktat, kleines Einmaleins, vollständiges Einmaleins, Brüche. Die zwei Einmaleinsvarianten teilen einen Screen. Bei aktivem Wortmodus nutzt `d1_woerter` bereits den bestehenden Wort-Schreibcoach.

Die geprüften geführten Konzepte sind Zehnerübergang, gleiche Gruppen, Subtraktion über den Zehner, Silben, Pflanzenbestandteile, Hunderterübergang und Bruchteile. `NativeLearningActivity` transportiert konkrete geprüfte Darstellungsdaten in die neue produktive Godot-Lernwelt. Der ursprüngliche Aufgabentext, Bewertungspfad, Hilfestatus und Kindbesitzer bleiben in Flutter. Ein 3D-Besuch darf keine erfundene richtige Antwort, Kompetenz oder Belohnung erzeugen.

Vorher waren die geführten Anschauungen Flutter-Darstellungen. Der neue Pfad bietet reale bewegliche Mengen, räumliche Silben und ein Pflanzenmodell mit Root-/Stem-/Leaf-/Flower-Interaktion. Die anschließende Erweiterung der sieben Konzepte und der aktuellen adaptiven Aufgaben wird mit den entsprechenden Produktions- und Starttests geprüft. Nicht jede der 20 Akademie-Übungen ist dadurch automatisch eine neue native 3D-Szene.

Lumo verwendet sein vorhandenes 65-Knochen-Modell. Der gemeinsame Lehrercontroller richtet Kopf und Körper aus und führt Zeigen, Nicken, Feiern sowie begrenzte Sprechgesten aus. Die Sprachintegration verwendet die vorhandene lokale Lumo-Sprachengine und Eltern-/Stimmfreigaben. Eine neue Cloud-Stimme oder neue Aufnahmeberechtigung wird nicht eingeführt. Tatsächliche Android-Audioausgabe muss separat im APK geprüft werden.

### Lesen: konkrete Bewertungsreparatur

Der bisherige Reading Buddy schrieb bei Abschluss direkt `accuracy >= 0.8` der Spracherkennung als richtige/falsche Lernantwort. Das kann Erkennungsfehler in einen Lernfehler verwandeln. Dieser Schreibpfad wurde entfernt.

Neue `reading_comprehension.dart`: zu allen 24 vorhandenen Geschichten gibt es eine geprüfte Verständnisfrage mit drei Auswahlantworten und einer konkreten Belegzeile aus genau diesem Text. Wird die Textgrundlage später verändert, wird eine nicht mehr passende Frage nicht angezeigt. Lesen funktioniert ohne Mikrofon; nur die ausdrückliche Antwort wird über `LearningModuleProgress` dauerhaft gespeichert. Doppeltippen, Neustart und spätes ASR nach einem Kinderwechsel sind berücksichtigt. Erkennungsmarkierungen bleiben unverbindliche Hilfen.

Tatsächlich ausgeführt: `flutter test --no-pub test/reading_buddy_assessment_test.dart --reporter expanded`, sieben Tests bestanden. Diese umfassen alle 24 Textzuordnungen, leere/falsche/vollständige Erkennung ohne Bewertung, richtige/falsche ausdrückliche Antwort mit Wiederaufnahme und genau einer Speicherung sowie Profilwechsel. Der separate Satz-für-Satz-Lesebereich wird dadurch nicht als komplett neu entwickelt ausgegeben.

## Vollständige Spieleinventur

| Spiel / erreichbarer Pfad | Tatsächlich vorhandene Spielmechanik | Änderung dieses Entwicklungsschnitts / verbleibende Grenze |
|---|---|---|
| LUMO Kart | 12 Strecken, Einzelrennen, Cup über 12 Strecken, Zeitrennen/Ghost, Training, 90-Sekunden-Arena; Lasso, Sprünge, Loops, KI | Originalfuchs steht in realer Werkstatt, Auswahlgesten und Zwei-Finger-Zoom; pro Kind gespeicherte konkrete Streckenziele. Vorhandene Geschwindigkeit und Action bleiben. Keine behauptete Neugestaltung aller Strecken |
| LUMO Cards | Bestehende Dart-Regeln, 112-Karten-Deck, Lern-/Farb-/Übergabephasen, faire KI-Stile, Speicherstand | Neuer echter Godot-Spielraum mit Kartenkörpern und 59 Originaltexturen; private Prozesskommunikation zur unveränderten Regelinstanz; dreirundiger Sternenpokal. Android-IPC noch separat prüfen |
| Bauwelt frei | 41 Bauteile, 49×49 Raster, bis 1536 Teile, sechs Projekte je Kind, Aufträge, Undo/Redo, Füllen/Kopieren/Spiegeln | Bestehende Teile atomar drehen/verschieben, begehbare Original-Lumo-Figur mit Sprung und Kollision. Bestehendes Save-v1 erhalten |
| Bauwelt Siedlung / Wettbau | Neuer separater Modus | Häuser, Farmen, Holz, Stein, Markt, Schule; Produktion/Verbrauch/Handel, Bevölkerung, drei Gebietsstufen, sechs Gebäudetypen; fairer lokaler KI-Rivale nach denselben Kostenregeln. Eigene Projekte pro Kind/Slot/Modus |
| Jump / Wolkeninseln | 12 kollidierende Inseln, Bonusplattformen, Sprungfedern, Kristalle und Lernstopps | Analoger Stick, Sprung beim Drücken, variable Höhe, Puffer/Kantentoleranz, Originalrig in tatsächlicher Flugphase; drei Expeditionen und isolierte Spielstände |
| Puzzle | 5 Motive mit 6/12/24/48/96 echten räumlichen Puzzleteilen, Drag/Snap/Save | Bestehende Mechanik und Touchlayouts regressionsgeprüft; keine neue Kampagne behauptet |
| Rhythm Party | 4 Originalsongs, 3 Schwierigkeits-/Timingfenster, Tap/Hold/Slide/Star, Combo und Bestwerte | Bestehende echte Bühne und Mechanik geprüft; noch kein neuer Kampagnenpfad, Lane-Muster nicht je Song neu komponiert |
| Schatzsuche | Begehbare Insel, 7 ortsgebundene Hinweise, Gegenstände/Torlogik, 3 Nebenentdeckungen, Kapitelstand | Vorhandene Regeln getestet; noch eine Insel, keine neu gelieferten offenen Welten |
| Memory | 4 Themenpakete, 5 Größen mit 4–12 Paaren, seen-only KI mit Fehlerrate, Bestwerte | Bestehend, keine neue native 3D-Inszenierung oder laufende Rundenspeicherung behauptet |
| Vier gewinnt | Öffentliches 7×6-Brett, drei KI-Stufen | Schlaue KI nun begrenzte iterative Suche bis sechs Halbzüge mit Alpha-Beta, statt Ein-Zug-Heuristik. Echte Gewinnfallen, Spiegelungen und 40 erreichbare Brettzustände geprüft |
| Quizshow | Lokale alters-/klassenbezogene Fragen, Kategorien und drei Joker | Bestehendes Flutter-Studio; noch kein neuer nativer Studiobau oder Weltfortschritt |
| Würfel-Wettlauf | 30 Felder, Würfelbewegung, Zurücksetzen bei Treffern | Bestehend; keine neue strategische KI oder Kampagne behauptet |
| Sternenpfad · Kartenabenteuer | Kooperativer Ressourcen-/Kartenpfad, Ziel 12 Weg + 6 Sterne in 16 Runden | Bestehendes eigenes Regelziel, kein zusätzlicher 3D-Umbau behauptet |
| Lernspiel-Levelkatalog | 50 Level je Klassenkatalog mit Sternenpfad, Farbkästen, Zahlenhaus, Buchstabenfüllung, Lernpfad, Quiz und Zahlenweg | Bestehende Lernlevel bleiben erreichbar; keine 50 neuen Szenen behauptet |

Zusätzlich existieren native Lernrouten `reading_hub`, `alphabet`, `word_picture_match`, `sound_letter_match`, `word_build`, `learn_old` sowie `stars`/Elterneinstellungen im bestehenden `SceneRouter`. Diese sind nicht mit einer neuen eigens entwickelten Welt gleichzusetzen und werden nicht aus der Inventur gestrichen.

### Bauwirtschaft: überprüfbare Regeln

Der neue Zustand startet mit begrenztem Holz/Stein/Essen/Münzen und zwei Bewohnern. Gebäude kosten Ressourcen; Farmen versorgen Bewohner, Holzfäller und Steinbruch liefern Baustoffe, Märkte erwirtschaften Münzen. Wachstum benötigt Wohnraum und Versorgung. Erweiterungen vergrößern das 3×3-Gebiet auf 4×4 und 5×5; regionale Produktionsboni geben ihnen einen tatsächlichen Nutzen. Die Ziele führen vom versorgten Weiler über Markt/Produktion zur Schule und ausgebauten Siedlung.

Der KI-Rivale nutzt dieselben Bau-, Handels-, Produktions- und Wachstumsregeln, ohne fremde Spielerdaten oder freie Ressourcen. Im Wettbau wird nach einem vollständigen Tag auch ein Gleichstand korrekt bestimmt. Im freien Siedlungsmodus läuft die Wirtschaft weiter. Tageswechsel verhindern Undo zur nachträglichen Verdopplung von Produktion. Vorhandene freie Bauprojekte werden nicht migriert oder überschrieben.

Das reine Wirtschaftsmodell besteht 124 ausgeführte Prüfungen, einschließlich vollständiger Zielerreichung, 22 Tagen unabhängig nachgespielter KI-Kostenregeln, JSON-Wiederaufnahme, ungültigen Daten, Handel und Undo/Redo. Die angeschlossene Spielszene hat zusätzliche Eingabe-, Layout-, Speicher- und Kindtrennungstests. Die endgültige Renderer-Abnahme ist davon getrennt.

## Qualitätsgrenzen und nächste Abnahme

Die neuen Native-Gates sammeln alle unabhängigen Prüfungen und tatsächlichen Renderbilder, selbst wenn ein anderes Modul scheitert. Der Gesamtstatus bleibt bei irgendeinem Fehler rot. Der erste Zwischenlauf auf `40cf9fa9584523b4fca679d74da22da5bab46471` fand einen realen Jump-Layoutfehler und lieferte deshalb keine erfolgreiche Gesamtfreigabe. Alte Garage-Bilder aus der exakten 2017-Quelle sind ausschließlich Vorher-Belege.

Neue Screenshots müssen aus den laufenden Produktionsszenen stammen. Referenzbilder des Nutzers sind keine Beweise. Ein grüner Headless-Test ist kein Beleg für Aussehen, physisches Fold7-Tempo oder Wärmeentwicklung. Der neue Android-Kandidat darf erst nach den verpflichtenden Flutter-, Daten-, Native-, Android-Oberflächen- und Updateprüfungen als getestet ausgegeben werden. Main bleibt bis zur Freigabe unverändert.
