# LUMO Studio 2019 – geprüfter Implementierungs- und Lieferzwischenstand

**Stand: 13. November 2026, vor Abschluss der vollständigen Native- und Android-Abnahme.** Der aktuelle Quellstand enthält produktiv angeschlossene Funktionen, echte Blender-Assets, ausgeführte Tests und neue Godot-Rendererbilder. Er ist **keine vollständige Abnahme des Masterauftrags**, keine erreichte AAA-Qualitätszusage und noch keine getestete Android-17-/Fold7-Auslieferung.

Die Host-Versionsdatei nennt `0.13.7+2019`. Der vollständige lokale Flutter-Lauf nach dem Profilpatch ist bestanden. Die neun Studio-Gates auf `64f75eb7` waren ebenfalls grün; eine anschließende echte Bildprüfung verwarf diesen Gesamtstand dennoch wegen einer Hunderterbeschriftung mit Parallaxefehler. Der reparierte Native-Stand lautet jetzt `b5bc6e7cdb03b190cb46f886301cf7bf3cb02928`; der Host-Pin ist aktualisiert. Die neue vollständige Native-CI `43434198014` läuft noch. Für diesen Stand ist keine abschließend geprüfte APK mit öffentlichem Download nachgewiesen. Der Integrator ergänzt den späteren endgültigen Lieferbefund; frühere APKs, grüne Teiltests und ältere Bilder ersetzen diesen Nachweis nicht.

## 1. Geprüfte Quellen, Branches und tatsächliche Arbeitsteilung

Vor der Studio-Entwicklung wurden die tatsächlichen GitHub-Stände über Connector und frischen Fetch abgeglichen. Die vom Auftrag genannten PRs #459/#156 waren bereits Vorfahren des neueren Nextgen-Stands und wurden nicht erneut als Entwicklungsbasis verwendet.

| Repository | Tatsächlich übernommene Studio-Basis | Aktueller Studio-Arbeitsstand |
| --- | --- | --- |
| `Ullmann27/lumo-lernen` | PR #461, `3c712129fef8f144d8946fad567b9ed11c628a60` | [PR #466](https://github.com/Ullmann27/lumo-lernen/pull/466); zuletzt gemeldeter Host-Checkpoint-Kurzstand `a73b`, danach bestätigte Aktualisierung des Native-Pins auf `b5bc6e7c`; endgültiger Host-SHA vom Integrator nachzutragen |
| `Ullmann27/lumo-godot` | PR #157, `ada5ed81ad62339f15289da62670c0a4f9f7f2b9` | [PR #158](https://github.com/Ullmann27/lumo-godot/pull/158); aktueller reparierter Prüfstand `b5bc6e7cdb03b190cb46f886301cf7bf3cb02928`, bereits in GitHub gesichert; neue Renderer-Abnahme offen |

Beide neuen Arbeitszweige heißen `chatgpt/lumo-studio-20261113`. Der produktive Main-Branch wird durch diese Arbeit nicht zusammengeführt. Bestehende Nextgen-/2018-Arbeitskopien bleiben erhalten. Ein Quellcheckpoint ist keine Test-, Grafik- oder Releasefreigabe.

Es arbeiten tatsächlich drei Entwicklungsagenten neben dem Integrator: Agent A bearbeitet Lernvisualisierung und Aufgabenadapter; Agent B das Originalrig, Blender-Bewegungsclips und Charakterprüfungen; Agent C Puzzle, Schatzsuche und anschließend die bestätigte native Profil-ID-Reparatur. Der Integrator verantwortet das Blender-Lernatelier, GitHub-Sicherung, Zusammenführung und Abnahme. Gemeinsame Dateien haben jeweils einen Besitzer. Die spätere Puzzle-Kamera-/Eingabekorrektur wurde ausdrücklich an A übertragen und von C unabhängig anhand der neuen Bilder geprüft.

Die vorhandenen Autosave-Skripte wurden zunächst lesend geprüft. CLI-Push besitzt in dieser Verbindung keine nutzbare Authentifizierung; die Sicherung erfolgt deshalb über den GitHub-Connector mit konkreten Dateien und erwarteter vorheriger Commit-ID. Es wird kein erfolgreich laufender CLI-Autosave-Wächter behauptet.

## 2. Fähigkeitsmatrix der tatsächlich verfügbaren Umgebung

| Fähigkeit | Einstufung | Tatsächlich verfügbarer Weg und Grenze |
| --- | --- | --- |
| Godot-Szenen, GDScript, Shader, Materialien und vorhandene GLBs bearbeiten | direkt umsetzbar | Godot 4.6.3, aktueller Quellcode und Originalassets; produktive Szenen und Modellressourcen wurden bearbeitet und ausgeführt. |
| Neue räumliche Geometrie und editierbare Animationsquellen herstellen | mit vorhandenen Werkzeugen umsetzbar | Blender 4.3.2, Python-Authoring, GLB-Export, tatsächliche Quaternion-Keyframes und CPU-Renderings. |
| Bewegung, Kollisionen, Kamera und Animationszustände anschließen | direkt umsetzbar | Echte SceneTree-/CharacterBody-/Skeleton3D-Instanzen und Eingabeereignisse; keine alleinige Bildsimulation. |
| Flutter-Lernaufgaben und native Godot-Ansicht verbinden | direkt umsetzbar | Flutter 3.44.9 / Dart 3.12.2, bestehender Launcher, Kotlin-Host und Prozessbrücken; Aufgaben- und Profilverträge getestet. |
| Lokale Logik-, Widget-, Speicher- und Profilprüfungen | direkt umsetzbar | Ausgeführte Flutter- und Godot-Läufe mit kontrollierten Testdaten, realen Repository-Instanzen und Wiederaufnahme. |
| Echte Godot-Rasterbilder prüfen | mit vorhandenen Werkzeugen umsetzbar | GitHub-Runner mit X11 und Mesa; lokal kein nutzbarer Xorg-Socket. Die neuen Bilder wurden einzeln tatsächlich geöffnet. |
| Android kompilieren, signieren und im Emulator prüfen | mit vorhandenen Werkzeugen umsetzbar | Vorhandene CI-/Provenienz-/Updatekette; eine verfügbare Buildkette ist noch kein bestandener Studio-Android-Lauf. |
| 60 FPS, GPU-Zeit, Temperatur und Touchlatenz auf Galaxy Z Fold7 / Android 17 messen | derzeit blockiert | Kein physisches Zielgerät angebunden. Linux-Software-Rendering und Headless-Tests ersetzen das Gerät nicht. |
| Authentisches Blinzeln, Augen-/Lid- und Kiefer-Lip-Sync des Originalfuchses | mit vorhandenen Werkzeugen grundsätzlich umsetzbar | Blender steht für die zusätzliche Modellierungs-/Rigarbeit zur Verfügung. Das Originalmesh besitzt noch keine entsprechenden Gesichtsmorphs oder Kiefer-/Augen-/Lidknochen; im Kandidaten sind diese Erweiterung und ihre Animationen noch nicht umgesetzt und validiert. |
| GitHub-Zugriff, CI und unterstützende Agenten nutzen | direkt umsetzbar | Connector-Sicherung, tatsächliche PRs, reale CI-Artefakte und drei gestartete Entwicklungsagenten. |
| Game-Development-Studio-CLI ausführen | derzeit blockiert | `game-dev` ist nicht installiert. Die tatsächlich verfügbaren Blender-/Godot-Werkzeuge wurden verwendet. |

## 3. Vollständiger erfasster Produktbestand

### 3.1 Lernen und schützenswerte Daten

Die übernommene App enthält Klassen 1 bis 4, individuelle Lernprofile, Fehler-/Kompetenzverläufe, adaptive Aufgaben, Tagesaufgaben, Belohnungen, Eltern-/Lehrkraftansichten, Offline-Lernabläufe, Lese-/Sprachfunktionen, Schreibtrainer, Wort-Schreibcoach und Journal. Der Studio-Schnitt ersetzt diese Systeme nicht.

`lib/features/learning_modules/learning_module_registry.dart` registriert 20 Themen mit 19 Screens: Zahlen bis 10, Plus bis 10, Minus bis 10, Formen, Tiere, Farben, Uhr, Geld, Zahlen bis 100, Artikel, Mehrzahl, Jahreszeiten, Wetter, Verkehr, Wortarten, Zeitformen, Wortdiktat, kleines Einmaleins, vollständiges Einmaleins und Brüche. Die beiden Einmaleinsvarianten teilen einen Screen. Ein registriertes Thema bedeutet nicht, dass dafür in diesem Auftrag eine neue native 3D-Welt fertiggestellt wurde.

Bereits aus Nextgen übernommen sind die geführten Anschauungen Zehnerübergang, gleiche Gruppen, Subtraktion über den Zehner, Silben, Pflanzenbestandteile, Hunderterübergang und Bruchteile samt produktiver Godot-Lernroute. Insbesondere die 8+5-Erklärung ist Bestand. Neu in Studio ist die unten beschriebene gleichmäßige Division sowie der korrekte Anschluss aktueller Multiplikations-/Bruchaufgaben.

Ebenfalls übernommen: Die Lesebewertung verwendet ausdrückliche Verständnisantworten mit Belegzeilen aus den 24 bestehenden Geschichten. Die frühere Gleichsetzung von ASR-Genauigkeit mit richtiger/falscher Lernantwort wurde bereits im Nextgen-Schnitt repariert. Studio beansprucht diese Reparatur nicht erneut als Neuentwicklung. Die genaue Bestandsaufnahme steht in [NEXTGEN_AUDIT_20261113.md](NEXTGEN_AUDIT_20261113.md).

### 3.2 Alle Spieleportale, zusätzlichen Modi und älteren Routen

Die zehn kanonischen Portale sind in `lib/features/games/spielwelt/spielwelt_routes.dart` festgelegt. Zusätzliche Spiele und Lernlevel sind über `lib/features/games/games_content.dart` erreichbar. Native Ziele registriert Godot in `scripts/app/scene_router.gd`. Die folgende Inventur unterscheidet ausdrücklich übernommenen Bestand und neue Studio-Arbeit.

| Spiel / tatsächlicher Zugang | Übernommener Bestand, einschließlich Nextgen | Neu in Studio / aktuelle Grenze |
| --- | --- | --- |
| **LUMO Kart**, Portal → native Route `kart` | Zwölf Strecken; Einzelrennen, zwölfteiliger Cup, Zeitfahren/Ghost, Training, 90-Sekunden-Arena. Vorhandenes hohes Tempo, Extrem-Gegner, Lasso, Schanzen und Loops. Nextgen ergänzte Werkstatt mit stehendem Original-Lumo, Auswahlgesten, Pinch-Zoom und kindbezogene Streckenziele. | Keine erneute Entwicklung der zwölf Strecken, Fahrphysik oder KI in Studio. Gemeinsame Charakteränderungen und native Integration werden regressionsgeprüft. Gerätelauf und vollständige neue Bildabnahme bleiben notwendig. |
| **LUMO Cards**, Cards-Portal / Flutter-Regelinstanz und native Route `cards` | 112-Karten-Deck, Farb-/Lern-/Übergabephasen, KI-Stile, gespeicherte Runde. Nextgen: echter Godot-Tisch mit Kartenkörpern, 59 Originaltexturen, private Kommunikation mit Dart-Regeln und dreirundiger Sternenpokal. | Kein neuer Cards-Regelkern oder weiterer Tischumbau in Studio. Endgültiger Android-Prozesswechsel, Wiederaufnahme und UI-Tour dieses Kandidaten stehen aus. |
| **Bauwelt – frei**, Portal → `build` | 41 Bauteile, 49×49 Raster, bis 1536 Teile, sechs Projekte je Kind, Bauaufträge, Undo/Redo, Füllen/Kopieren/Spiegeln. Nextgen: einzelne Teile atomar versetzen/drehen; Original-Lumo läuft und springt mit Kollisionen durch eigene Bauten. | Neue gemeinsame Original-Lumo-Clips werden vom vorhandenen `build_explorer.gd` tatsächlich angesteuert. Bauwerkzeuge und Datenformat werden nicht neu erfunden. Frische vollständige Native-Bilder noch in Abnahme. |
| **Bauwelt – Siedlung und Wettbau**, Bauwelt-Auswahl → `settlement` | Nextgen-Modi mit sechs Gebäudetypen, Holz/Stein/Essen/Münzen, Handel, Bevölkerung, Produktion, 9/16/25 Grundstücken und lokalem KI-Rivalen nach denselben Kostenregeln. Rückbau und bestätigter Umzug beheben bekannte wirtschaftliche Sackgassen. Eigene Dateien pro Kind/Slot/Modus. | Keine neue Wirtschaft im Studio-Schnitt. Gemeinsame Originalfigur verbessert; aktueller Komplettlauf und neue Bilder müssen die Integration bestätigen. |
| **Jump & Run / Wolkeninseln**, Portal → `jump` | Zwölf kollidierende Inseln, Bonusplattformen, Federn, Kristalle, Lernstopps und drei Expeditionen. Nextgen: Analogstick, Sprung beim Drücken, variable Höhe, Sprungpuffer, Kantentoleranz, echte Flugphase und isolierte Saves. | Sechs Blender-Bewegungsclips mit korrekter Ruheachsenumrechnung, geschwindigkeitsabhängiger Überblendung, Flug-/Lande- und Bremsreaktion. Keine neue vollständige Kampagne oder neu gemessene Fold7-Steuerung behauptet. |
| **Puzzle**, Portal → `puzzle` | Fünf Originalmotive, 6/12/24/48/96 echte räumliche Teile, Raypicking, Drag/Snap und Save-v1. | Echter Drehmodus, orientierungsabhängiges Einrasten, Drehhilfe, optionale kompatible Drehfelder; nach echtem Bildbefund korrigierter Kamera-/Eingabebereich bei 640×360. |
| **Rhythm Party**, Portal → `rhythm` | Vier Originallieder, drei Schwierigkeits-/Timingstufen, Tap/Hold/Slide/Star, Combo und Bestwerte. Nextgen: eigene Noten-/Melodiefolgen, zwölf Tourstufen, Mehrfingersteuerung und additive Tour-Speicherung. | Keine neue Musik-/Tourmechanik in Studio. Endgültige Android-Audio-/Eingabesynchronität und Bildabnahme sind getrennte Aufgaben. |
| **Schatzsuche**, Portal → `treasure` | Begehbare Insel, sieben ortsgebundene Hinweise, Inventar-/Torregeln, drei Nebenentdeckungen, gespeicherter Kapitelstand. | Nach der Brücke Garten und Kristalle in beiden Reihenfolgen lösbar, reale Abzweige/Wegweiser und zwei aktive Zielmarker; kompatible Speicherung. Weiterhin eine Insel und der bestehende vereinfachte Begleitfuchs, nicht der neue Original-GLB-Studio-Actor. |
| **Memory**, Portal → `LumoMemoryScreen` | Vier Themenpakete, fünf Größen von 4–12 Paaren, KI mit Erinnerung nur an gesehene Karten und Fehlerrate. Nextgen trennte Bestwerte/Schwierigkeit nach stabiler Kindidentität. | Bestehende Flutter-Darstellung. Kein neuer nativer 3D-Spielraum und keine neue Rundenspeicherung in Studio. |
| **Vier gewinnt**, Portal → `LumoConnectFourScreen` | 7×6-Brett, drei KI-Stufen. Nextgen ergänzte begrenzte iterative Alpha-Beta-Suche bis sechs Halbzüge und Taktikprüfungen. | Bestehendes Flutter-Spiel; kein neu entwickeltes Godot-Brett oder neue Physik in Studio. |
| **Quizshow / Lumo-Meister**, Portal → `QuizShowContent` | Alters-/klassenbezogene Fragen, Kategorien, 20-Fragen-Show und drei Joker. | Bestehendes Flutter-Studio. Ein vollständig neues natives Quizstudio mit Kameraregie ist offen. |
| **Würfel-Wettlauf**, zusätzliche klassische Spielekarte | 30 Felder, Würfelbewegung und Zurücksetzen bei Treffern; `lib/features/games/dice_race/lumo_dice_race_game.dart`. | Übernommen; keine neue strategische KI, Kampagne oder 3D-Szene. |
| **Sternenpfad · Kartenabenteuer**, eigene zusätzliche Karte | Kooperativer Ressourcen-/Kartenpfad; Ziel zwölf Weg und sechs Sterne in 16 Runden; `lib/features/games/star_trail/star_trail_screen.dart`. | Eigenständiges vorhandenes Spiel, nicht mit LUMO Cards gleichgesetzt. Keine neue 3D-Umsetzung. |
| **Flame-Abenteuer**, zusätzliche Abenteuerkarte | `GamesContent._launchAdventure()` öffnet `LumoJumpFlameScreen` aus `lib/features/games/flame/lumo_jump_game.dart`. Dieser zweite Plattform-Abenteuerpfad ist neben dem nativen Jump tatsächlich angeschlossen. | Als eigener bestehender Ausführungspfad inventarisiert; keine neue Studio-Funktion und keine Gleichsetzung mit dem Godot-Jump. |
| **Lernspiel-Levelkatalog**, zusätzliche Levelkarte | 50 Level je Klassenkatalog; `GameMiniType` enthält `starsPath`, `numberHouse`, `colorBoxes`, `letterFill`, `numberPath`, `wordForest`, `mixedQuiz`. Gemeinsame Trail-Ansichten und der gesonderte Lumo-Meister-Einstieg bleiben erhalten. | Keine 50 neuen 3D-Szenen behauptet; vorhandene Lernziele und Freischaltungen bleiben zuständig. |
| **Weitere native Lern-/Spielrouten** | `learn`/`reading_hub`, `alphabet`, `word_picture_match`, `sound_letter_match`, `word_build`, `learn_old`, `stars`; zusätzlich Elterneinstellungen `parent`. | Im `SceneRouter` registrierter Altbestand. Keine neue Studio-Welt und keine gesonderte vollständige neue Android-Abnahme jeder älteren Route. |

Die zwölf vorhandenen Kart-Strecken sind `sonnenhafen`, `zauberwald`, `bergwelt`, `holo_city`, `crystal_canyon`, `jungle_temple`, `candy_cloud`, `volcano_night`, `winter_sprint`, `galaxy_ringway`, `desert_drift` und `learning_lab`. Die vorhandenen Grafikmodule und früheren Kart-Prüfungen sind in Godot `docs/NEXTGEN_KART_20261113.md` dokumentiert. Studio behauptet keine neue einheitliche AAA-Produktion aller zwölf Strecken.

## 4. In diesem Studio-Schnitt tatsächlich neu implementiert

### 4.1 Exakte aktuelle Lernaufgabe und gleichmäßige Verteilung

**Vorher:** Die native Gruppenansicht füllte Gruppen nacheinander; Division fehlte. Der Flutter-Adapter lieferte für Multiplikation/Division keine passenden Operanden und konnte vollständige Bruchausdrücke falsch als Ganzzahl-Plus lesen. Bei rationalen Antworten konnte der Schrägstrich verloren gehen.

**Neue Funktion:** `12 : 3` verteilt echte Würfel im Rundlauf. Nach jeder vollständigen Runde besitzen alle drei Gruppen gleich viele Objekte; Vorrat, Gruppenzähler und sichtbare Menge bleiben konsistent. Ziehen, Antippen und Aktionsknopf benutzen denselben Modellweg. Layoutwechsel behalten den Zustand, Pause sperrt Eingaben, Neustart stellt die gleiche Aufgabe wieder her. Unterstützt sind 2–6 Gruppen mit je 1–6 Würfeln, höchstens 36 Objekte. Unpassende oder größere Aufgaben bleiben in ihrer bisherigen Ansicht und werden nicht still vereinfacht.

Aktuelle Multiplikationen erreichen das bestehende Gruppenmodell; gleichnamige Bruchadditionen das bestehende Bruchmodell. `1/4 + 2/4` bleibt eine Bruchaufgabe und `3/4` eine rationale Antwort. `DivisionGroupsVisual` zeigt alle 1–12 unterstützten Gruppen und größere Mengen mit exakten 100er-/10er-/1er-Bündeln. `FractionPizzaVisual` zeigt bei Addition das tatsächliche Pluszeichen.

**Produktive Dateien:** Godot `scripts/learning/learning_activity.gd`, `scripts/learning/learning_world.gd`; Host `lib/domain/tutoring/native_learning_activity.dart`, `lib/features/learning/adapters/legacy_lumo_task_adapter.dart`, `lib/features/learning/renderers/lumo_premium_visuals.dart`, `tools/auto_install/MainActivity.kt`.

**Erreichbarkeit und Bewertung:** Die bestehende Schaltfläche „Mit Lumo in 3D ausprobieren“ startet die aktuelle Aufgabe über den vorhandenen Launcher in Route `learning`. Der Host markiert Hilfe vor dem Start; Godot meldet nur `illustrated`. Die Rückkehr behält die Aufgabe und erzeugt keine richtige Antwort, Kompetenz oder Sterne. Bewertet wird erst die tatsächliche anschließende Antwort. Details und Rohbelege: [STUDIO_LEARNING_HOST_20261113.md](STUDIO_LEARNING_HOST_20261113.md), [Host-RESULT.json](evidence/studio-learning-20261113/RESULT.json) und Godot `docs/STUDIO_LEARNING_20261113.md`.

### 4.2 Blender-Lernatelier in der Produktionsszene

`tools/art/build_learning_studio.py` erzeugt echte Architektur und Requisiten. `assets/learning/studio/learning_studio.glb` enthält laut Assetprovenienz elf Meshes, elf Materialien und 29.424 Dreiecke bei 1.522.224 Byte. SHA-256: `e5b33abceaba8df76b6475efc04454aac3db353a1b40005267d2986be718a034`. Die editierbare Blender-Quelle liegt in Godot `docs/design/studio-20261113/Learning-Studio.blend`.

`scripts/learning/learning_atelier.gd` lädt dieses GLB tatsächlich in die benutzte Lernwelt; die ursprünglichen Laternen bleiben. Wiederholte Garten-/Bodengeometrie nutzt gemeinsame Meshes und MultiMesh. `studio_leaf_motion.gdshader` bewegt zwei importierte Blattoberflächen und beachtet reduzierte Bewegung. Der Atelierknoten braucht dafür keinen eigenen laufenden Skripttick. Geometrie- und Materialzahlen sind Assetwerte, keine gemessenen Gesamt-Draw-Calls oder GPU-Zeiten.

Ein tatsächlicher Rendererbefund zeigte zu wenig Kontrast bei räumlicher Stellenwertbeschriftung. Eine dunkle reale Beschriftungsplatte verbesserte den Kontrast, genügte jedoch noch nicht: Integrator und unabhängiger Reviewer sahen in den Hunderterbildern von `64f75eb7` die unteren Buchstaben außerhalb der Platte. Die Projektionsprobe maß bei 1280×720 für die unterste Glyphengrenze 544,8219 px und für die Plattenkante 543,6897 px. Lokale Geometriegrenzen hatten diesen perspektivischen Fehler übersehen. Deshalb bleibt auch `64f75eb7` als Gesamtstand visuell verworfen.

Der neue Stand `b5bc6e7c` richtet die bestehende extrudierte 3D-Schrift samt echter Platte zur Kamerabasis aus; Geometrie und Tiefentest bleiben aktiv. Die neue Projektionsassertion scheiterte auf dem vorherigen Code in allen 18 Fällen aus sechs tatsächlichen Interaktionszuständen und drei Bildschirm-/Dichteformaten. Nach der Korrektur bestehen 117 Studio- und 5340 Lernweltprüfungen lokal. Der neue Lern-Capture erwartet vier zusätzliche Hunderterbilder für Phone-/Dichteformate, insgesamt 25 statt 21 in diesem Capture. Deren tatsächliche neue Renderausführung und Sichtprüfung stehen noch aus. Beleg: Godot `docs/evidence/studio-atelier-20261113/caption-parallax-correction.json`.

### 4.3 Original-Lumo: sechs echte Blender-Bewegungsclips

**Vorher:** Lokale Rotationen wurden auf unterschiedliche Ruheachsen des Originalrigs gleich angewandt; zusätzlich verschob eine Fußtranslation das Gelenk und änderte dadurch die Beinsegmentlänge. Der Originalfuchs und seine neun bisherigen Clips existierten bereits.

**Neu:** `tools/lumo_animation/author_platform_clips.py` erstellt Gehen, Sprint, Sprungaufstieg, Sprungabstieg, Landung und Bremsen auf dem vorhandenen Rig. Je Clip werden 25 Quaternion-Keyframes nach `assets/characters/lumo_animated/lumo_studio_clips.gd` exportiert. `lumo_body_space_pose.gd`, `lumo_platform_pose.gd`, `lumo_walk_locomotion.gd` und `lumo_rigged_actor.gd` unter `scripts/characters/lumo/` rechnen die Posen in die jeweiligen Ruheachsen um und steuern sie aus tatsächlicher Geschwindigkeit, Flugphase, Bodenkontakt und Verzögerung.

Die vorhandenen produktiven Aufrufer `jump_islands.gd` und `build_explorer.gd` verwenden diesen Pfad. Die Clips bestehen damit nicht nur als Studio-Demo. Ein zusätzlich gefundener Idle-Zeitversatz wurde durch Zurücksetzen der Pose vor dem Binden korrigiert. Das Original-GLB bleibt bytegleich: `3559f700784bc1006905ee3aae01e8bcfbffb95b4f621f7430ce771ba0e3efd5`.

Die 1.046 Bewegungsprüfungen vergleichen unter anderem 300 Fußendpunkte aus Blender und Godot; maximale gemessene Abweichung 0,000000733 m. Das belegt die mathematische Übertragung, nicht allein die Qualität kontinuierlicher Animation. Vier echte Blender-Cycles-Bilder und acht neue Godot-Vorher-/Nachherbilder liegen vor. Walk-/Sprint-Vergleichsbilder besitzen unterschiedliche Schrittphasen; sie sind kein identischer Phasenvergleich. Details: Godot `docs/evidence/studio-character-20261113/README.md`.

**Gesichtsgrenze:** Die zusätzliche Modellierungs- und Rigarbeit am Originalgesicht ist mit dem vorhandenen Blender grundsätzlich bearbeitbar. Im Kandidaten wurden Gesichtsmorphs, kontrollierbare Lider, Augen und Kiefer jedoch noch nicht umgesetzt und validiert. `mouth_supported` bleibt `false`; authentisches Blinzeln oder Lip-Sync wird nicht behauptet. Mundinnengeometrie, Lidabgrenzung, neue sichere Gewichte und entsprechende Animationen am Original bleiben offene Entwicklungsarbeiten. Auch nicht jeder Begleiter aller Spiele wurde durch dieses Originalrig ersetzt.

### 4.4 Drehpuzzle und nach Bildbefund reparierter Eingabebereich

**Vorher:** Echte dicke Teile, Dragging und Einrasten waren vorhanden, aber stets mit richtiger Orientierung. **Neu:** Wahl zwischen bisherigem Bilderpuzzle und Drehpuzzle; Vierteldrehungen verändern echte Geometrie und Einrastregel. Antippen behält die Auswahl. Drehknopf und Taste R benutzen dieselbe Aktion mit Quaternion-Übergang. Eine korrekt gedrehte Figur am richtigen Platz rastet ohne zusätzlichen versteckten Klick ein. Hilfe nennt Platz und nötige Drehung.

Dateien: Godot `scripts/creative/puzzle_state.gd`, `scripts/creative/puzzle_world.gd`, `scripts/tests/puzzle_rotation_regression.gd`. Die optionalen Save-v1-Felder `rotation_enabled` und `turn` fehlen in Altständen und ergeben dann exakt das bisherige Puzzle. Ungültige Daten werden vor einer Zustandsänderung abgewiesen.

Die erste tatsächliche Sichtprüfung verwarf Commit `9eb25fcb158342639badb0e953a8fe7945fda6ce`: Bei 640×360 lagen obere Ziele und Startstücke unter der Fortschrittsanzeige; echte ScreenTouch-Ereignisse wurden abgefangen. Der neue Kamera-/Inhaltsbereich von `64f75eb7` hält Teile und Ziele zwischen HUD und Werkzeugleiste, auch bei Größenänderung mit gehaltenem Teil. Alle sieben neuen Bilder wurden unabhängig tatsächlich geöffnet. Der aufgezeichnete Test wählt alle sechs Startstücke durch echte UI-Ereignisse und zieht ein Teil in den früher verdeckten oberen Zielplatz.

Frische Abnahme: [puzzle-64f75eb7-review.json](evidence/studio-2019-review-notes/puzzle-64f75eb7-review.json). Der ältere Teilbericht Godot `docs/STUDIO_PUZZLE_TREASURE_20261113.md` enthält die erste Implementierung und damaligen Quellhashes; für den späteren Kamera-Fix gilt die neue commitgebundene Review.

### 4.5 Schatzsuche mit echter Wahl der Erkundungsreihenfolge

**Vorher:** Sieben Stationen mussten streng linear besucht werden. **Neu:** Nach der Brücke sind Kristallwächter und Mondgarten gleichzeitig freigeschaltet und in beliebiger Reihenfolge lösbar. Reale MultiMesh-Wege, Wegweiser und zwei Zielmarker zeigen die Möglichkeiten. Die tatsächliche Nähe bestimmt die Frage. Schloss und Truhe verlangen weiterhin ihre bisherigen Voraussetzungen; Belohnungen werden nicht vervielfacht.

Dateien: Godot `scripts/creative/treasure_state.gd`, `scripts/creative/treasure_world.gd`, `scripts/tests/treasure_exploration_regression.gd`. Das alte `chapter` bleibt der längste vollständig gelöste lineare Präfix. Das optionale `solved_clues` bewahrt Garten-vor-Kristallen, während alte Saves ohne Feld unverändert verstanden werden.

Beide Reihenfolgen, Fragen-/Antwortbuttons, eine echte Touch-Stick-Bewegung und Wiederaufnahme wurden geprüft. Für weitere Frageorte setzt die Probe die Spielerposition direkt; sie ist keine vollständig manuell durchwanderte Insel. Drei neue Produktbilder zeigen Wahl, Garten zuerst und Abschluss. Weiterhin wird dort die vorhandene vereinfachte Figur aus `kart_vehicle.gd` verwendet. Die Bilder belegen keine Original-GLB- oder Studio-Clip-Integration in Schatzsuche.

### 4.6 Stabile native Profil-ID und ausdrückliche Altstand-Wiederaufnahme

Die unabhängige Lernprüfung reproduzierte einen bestehenden Hostfehler: Der native `childKey` hing an Name und Klasse. Zwei echte verschiedene gleichnamige Schüler konnten denselben Schlüssel erhalten; ein Klassenwechsel desselben Kindes änderte ihn.

Neu speichert `lib/core/native_profile_key_repository.dart` eine dauerhafte eindeutige Bindung von `captureLearningProfile().studentId` an den nativen Hauptschlüssel. `lib/features/lumo3d/lumo3d_launcher.dart` erfasst die Identität vor asynchroner Arbeit und prüft zusätzlich Lease-/Generationsgrenzen, auch beim Rücklauf. Neue Schulprofile bekommen immer ihre eigene ID-basierte Identität. Name, Klasse und Neustart verändern eine vorhandene Bindung nicht.

Ein eindeutiges lokales Einzelprofil ohne Schulprofile und mit vorhandenem Salt darf seinen exakten bisherigen 2017-Schlüssel fest behalten. Mehrdeutige Altstände werden keinem Kind automatisch zugeordnet. `lib/features/settings/native_game_saves_card.dart` und `lib/features/lumo3d/native_game_saves_screen.dart` bieten unter Einstellungen → „3D-Spielstände“ eine getrennte Altstand-Wiederaufnahme mit dem vorhandenen Erwachsenen-Bestätigungsmuster. Es gibt keinen neuen PIN-/Authentifizierungsstack. Abbrechen weist nichts zu; ein bereits gebundener Schlüssel wird nicht nochmals vergeben.

Alte native Dateien werden weder kopiert noch gelöscht noch pauschal migriert. Der normale Hauptstand bleibt getrennt. Da die vorhandene Brücke kein Dateiinventar bereitstellt, sagt die Oberfläche ausdrücklich, dass der alte Schlüssel allein keine existierende Datei beweist. Globale Wallet-/EmbeddedGameService-Daten sind durch diese Reparatur nicht als vollständig kindgetrennt neu nachgewiesen.

Belegt sind zwei reale gleichnamige Schulprofile, Klassen-/Namenswechsel, Neustart, exakter Solo-2017-Schlüssel, abgebrochene Elternzuordnung, Schreibfehler/Retry, konkurrierende Bindung und Leasewechsel vor/nach asynchroner Arbeit. Die echte Widgetkette umfasst Elternkarte, Dialog, getrennten Altstart und normalen Hauptstart. Android-MethodChannel-Antworten sind dabei kontrollierte Testdoubles. Bericht: [STUDIO_NATIVE_PROFILE_KEYS_20261113.md](STUDIO_NATIVE_PROFILE_KEYS_20261113.md).

### 4.7 Quellengebundene Android-17-Prüfkette vorbereitet

Die Host-Dateien `.github/workflows/lumo-studio-2019.yml`, `scripts/verify_studio_delivery.py` und `.github/probes/lumo_studio_surfaces_android_probe.py` verlangen getrennte Belege für API 35 und API 37. Die Probe liest tatsächliche Werte für SDK, Release, Fingerprint und Modell aus; eine Workflow-Einstellung allein genügt nicht. Beide Originaltouren und Oberflächenproben müssen zum selben unveränderlichen x86_64-APK und PCK gehören. API-35-Belege dürfen die getrennte Android-17-Ablage nicht ersetzen.

Das unabhängige Review meldet 32 bestandene Delivery- und sechs bestandene Probe-Tests sowie AST-Parität. Dies sind ausgeführte Quell-/Verifikationsprüfungen mit synthetischen Fällen, keine abgeschlossene Emulator-Tour. Der tatsächliche Android-17-Lauf bleibt offen. Beleg: [android17-verifier-review.json](evidence/studio-2019-review-notes/android17-verifier-review.json).

## 5. Tatsächlich ausgeführte Abnahme und ihre Reichweite

Testzahlen verschiedener Zeilen überlappen. Sie werden nicht zu einer künstlichen Gesamtsumme addiert. Ältere Nextgen-Tests bleiben historische Bestandsbelege und werden nicht als neue Studio-Funktionen ausgegeben.

| Prüfung / Beleg | Tatsächlich vorliegender Stand | Aussage und Grenze |
| --- | --- | --- |
| Vollständiger lokaler Flutter-Runner nach dem Profilpatch | **2510 PASS, 0 FAIL, 0 SKIP**, Exit 0; **546 PNG-Ausgaben**, keine gemeldeten Capture-Fehler | [Zusammenfassung](evidence/studio-2019-review-notes/full-flutter-local-acceptance-summary.json). Die Anzahl umfasst verschiedene Widget-/Render-/Asset-Captures; sie ist keine Behauptung, alle 546 Bilder seien einzeln visuell abgenommen oder auf Android entstanden. |
| Pflichtprüfungen unter `scripts/tests` | **350 PASS, 0 SKIP**, Laufzeit **61,382 s** | Neu abgeschlossener Pflichtlauf laut Integrator; Quell-/Skriptprüfungen, kein Android-Gerätelauf. |
| Android-Probe-Unit-Tests | **730 PASS, 0 SKIP**, Laufzeit **41,117 s** | Neu abgeschlossener Unit-Testlauf für die Android-Probes. **Kein Emulatornachweis** und keine ausgeführte Android-17-/Fold7-Tour. |
| Lernaufgaben/Adapter/Host | 47 gezielte Flutter-Tests, darunter neun neue; vier Hostvorbereitungsprüfungen; gezielte Analyse ohne Befund | Reale Aufgaben, rationale Antworten, Hilfestatus und Profilgrenzen. Hostvorbereitung ist kein APK-Compile. |
| Native Profil-ID / Elternkarte / Launcher | 53 kombinierte gezielte Tests, darunter zwölf neue Repository- und sieben neue UI-Tests; abschließender UI-Lauf 7/7; Analyse ohne Befund | [RESULT.json](evidence/studio-native-profiles-20261113/RESULT.json), echte Phone-/Fold-/Dialog-Widgetbilder; Android-Grenze gemockt. |
| `learning_sharing_regression.gd` | **1811 PASS** im frischen 64f-Artefakt | Mengeninvarianz, faire Verteilung, ungültige Daten, echte Touchereignisse, Pause, Neustart und Layout. |
| `learning_studio_regression.gd` | **99 PASS** im später visuell verworfenen 64f-Artefakt; **117 PASS lokal** nach Parallaxekorrektur | Zusätzliche Projektionsassertionen erkannten alle 18 vorher fehlerhaften Fälle. Neue b5b-Renderer-Abnahme weiterhin offen. |
| `lumo_studio_motion_regression.gd` | **1046 PASS** im frischen 64f-Artefakt | Blender-/Godot-Posen, Knochenlängen, Bodenbezug, Pause, Gesten und ursprüngliche Clips. |
| `puzzle_rotation_regression.gd` | **4558 PASS headless / 4565 PASS rendered** im frischen 64f-Artefakt | Drehlogik, Altstände, tatsächliche UI-Touches, Zielbereiche, gehaltenes Resize; sieben zusätzliche Prüfungen betreffen geschriebene Rendererbilder. |
| `treasure_exploration_regression.gd` | **87 PASS headless / 90 PASS rendered** im frischen 64f-Artefakt | Beide Routen, Produktionsinteraktion, kompatible Saves; drei zusätzliche Bildschreibprüfungen. |
| Bereits geprüfte Studio-Captures aus 64f | Sechs Verteilbilder, acht Motion-Studiobilder, sieben Puzzle- und drei Schatzsuchebilder | Alle 24 Bilder einzeln geöffnet. Diese Teilreviews bleiben belegt; die zusätzliche Hunderterprüfung verwirft dennoch den Gesamtstand. Motionbilder sind technische Posen, keine vollständigen Jump-/Bauwelt-Produktbilder. |
| Bestehende Lern-/Spielregressionen | Beispielsweise Lernwelt nach Beschriftungskorrektur 5340 PASS, Puzzle-Bestand 1103 PASS und Touchlayout 300 PASS lokal dokumentiert | Ergänzende gezielte Regressionen; kein Ersatz für den vollständigen aktuellen Native-Lauf. |
| Aktuelle Native-CI `43434198014` auf b5b | **Zum Berichtsstand noch laufend** | Vorheriger Lauf `43431630901` und neun grüne Studio-Gates auf 64f sind keine Freigabe des reparierten b5b-Stands. |
| Native-Pin und Android-Beweisverifikation | **23 Pin-Tests PASS** laut Integrationslauf; **32 Delivery- und sechs Probe-Tests PASS** laut unabhängigem Review | Die Tests prüfen Quellen-/Beweisverträge und synthetische Fälle. Noch keine tatsächliche API-37-Emulator-Abnahme. |
| Signierte Studio-APK, Updateprobe, Android-17-Tour | **Noch kein abschließender PASS-/Liefernachweis** | Version, Signatur, Host-/Godot-SHA, APK-SHA, Installation und öffentlicher direkter Download müssen am fertigen Kandidaten bestätigt werden. |
| Physischer Fold7-Lauf | **Nicht ausgeführt** | Keine gemessenen 60 FPS, GPU-/CPU-Framezeiten, Temperatur oder Touchlatenz auf dem Zielgerät. |

### 5.1 Herkunft der bereits geprüften Godot-Bilder und ihre Grenze

Die bereits geprüften 24 Studio-Bilder stammen aus Artefakt **14039579366**, Quellcommit **64f75eb7725ebef898d0f259049bddef7021532f**, mit leerem `source-dirty.txt`. ZIP-SHA-256: `c20c2f575bf9690b6a7f70487a22509d2e9a737058d00a40599a3e37b7cb8c56`. Die unabhängigen Reviews prüfen Dateihashes und tatsächliche Bildinhalte; Puzzle- und Motion-/Schatzsuche-Review vergleichen die Bildbytes zusätzlich mit den Original-ZIP-Einträgen. Diese Herkunft bleibt gültig, ist aber keine finale 64f-Freigabe: Die zusätzliche Hunderterprüfung desselben Quellstands fand den oben beschriebenen Fehler. Neue b5b-Bilder und deren Artefakthashes müssen separat ergänzt werden.

Die Rendererprotokolle nennen Godot 4.6.3, X11, OpenGL Compatibility und Mesa llvmpipe. Das sind echte Enginebilder mit Software-Rendering, keine Konzeptillustrationen und keine Android-Aufnahmen. Relevante dateigebundene Teilreviews aus 64f:

- [Lernen / gleichmäßige Verteilung](evidence/studio-2019-review-notes/learning-sharing-64f75eb7-review.json)
- [Original-Lumo und Schatzsuche](evidence/studio-2019-review-notes/studio-64f-motion-treasure-review.json)
- [Puzzle nach Kamera-/Inputkorrektur](evidence/studio-2019-review-notes/puzzle-64f75eb7-review.json)

Die Bauwelt-/Jump-/Raum-Vorprüfungen aus `9eb25fcb` bleiben Vorprüfungen eines wegen Puzzle verworfenen Gesamtstands. Auch `64f75eb7` ist wegen der Hunderter-Parallaxe insgesamt visuell verworfen. Keine dieser älteren Prüfungen gibt den aktuellen Stand `b5bc6e7c` oder seine noch ausstehenden Bilder vorab frei. Der Name „PASS“ eines einzelnen Testskripts hebt einen anderen belegten Blocker nicht auf.

### 5.2 Tatsächliche Leistungsprobe statt FPS-Behauptung

Godot `docs/evidence/studio-character-20261113/performance_cpu_comparison.md` dokumentiert eine begrenzte Linux-Headless-CPU-Probe mit 480 Samples pro Pfad und Figurenanzahl. Neue Posen kosten relativ mehr: Gehen etwa das 3,14- bis 3,25-Fache, Plattformbewegung etwa das 2,67- bis 2,84-Fache des alten vereinfachten Pfads. Absolut wurden pro Plattformfigur etwa 32–33 Mikrosekunden im Median gemessen; acht Figuren zusammen 0,2615 ms Median und 0,379 ms P95.

Diese Probe umfasst Pose-Sampling und Skeleton-Update. Import, Physik, GPU-Skinning, Rendering, Sprache und Flutter sind ausgeschlossen. Sie belegt weder das gesamte 16,7-ms-Framebudget noch Fold7-Performance. Zähler zeigen keinen wachsenden Objekt-/Ressourcenbestand während der gemessenen Ticks; vorübergehende Allocator-Aktivität wurde nicht profiliert. Eine Allokationsfreiheit wird nicht behauptet.

## 6. Datenbestand, noch offene Lieferung und Master-Restarbeiten

Die neuen Puzzle-/Schatzsuche-Felder sind additive Version-1-Erweiterungen; vorhandene Daten werden nicht rückwirkend neu bewertet. Native Lernbesuche bleiben Hilfen. Schreibtrainer, Journal, Sprache, Kinderprofile und Offline-Freigaben bleiben in ihren bisherigen Modulen. Die neue native Schlüsselbindung verhindert bestätigte Profilkollisionen, ohne mehrdeutige Dateien automatisch einem Kind zuzuschreiben. Die endgültige 2017→2019-Updateprobe muss zusätzlich den tatsächlich installierten App-Datenbestand prüfen.

| Noch offene Arbeit | Warum sie durch die vorliegenden Belege nicht erledigt ist |
| --- | --- |
| Vollständigen Native-Lauf und aktuelle Produktbilder abschließen | Die neun neuen Studio-Gates decken nicht sämtliche übernommenen Kart-, Cards-, Bauwelt-, Jump-, Rhythm- und Lernpfade ab. Insbesondere aktuelle Bauwelt-/Jump-Produktbilder müssen die Originalfigur im tatsächlichen Spiel bestätigen. |
| Android-Kandidat vollständig bauen und prüfen | Es fehlt noch der endgültige signierte Kandidat mit belegter Quelle, Paketversion, Signaturfingerprint, SHA-256, Update-/Datenprobe, Prozessrückkehr und echter Emulator-/Android-Tour. Kein früheres APK wird als dieser Stand ausgegeben. |
| Physisches Galaxy Z Fold7 / Android 17 | Fold-/Cover-Wechsel, Touchgefühl, Lebenszyklus, länger laufende Spiele, CPU/GPU-P95, Speicher, Ladezeit und Erwärmung sind noch auf dem Zielgerät zu messen. 60 FPS bleiben Ziel und sind nicht bewiesen. |
| Vollständige Lernwelten für alle Fächer | Eine neue Verteilmechanik und das gemeinsame Atelier ersetzen keine eigenständigen vollständigen 3D-Szenen für sämtliche Mathematik-, Deutsch-, Lese-, Sachunterrichts- und Englischinhalte der Klassen 1–4. Größere/nicht passende Aufgaben behalten bewusst ihre bestehenden Darstellungen. |
| Originalgesicht und vollständige Emotions-/Sprechregie | Kiefer, Lippen, Augenlider und entsprechende Morphs/Bones fehlen. Körpergesten und Kopfbewegung schließen diese Anforderung nicht ab. Integration des Originalrigs in weitere derzeit vereinfachte Begleiter ist ebenfalls offen. |
| Kart-Produktionsstandard für alle Strecken | Bestehendes Tempo, Extrem-KI und Lasso bleiben vorhanden. Ein neuer systematischer Grafik-/Gameplay-Ausbau aller zwölf Strecken wurde in Studio nicht durchgeführt. Die frühere teure Streckenvorschau bleibt ein konkreter Gerätemesspunkt. |
| Cards, Bauwelt und übrige Spiele weiter ausbauen | Übernommene Mechaniken und native Räume sind real, aber nicht durch bloße Übernahme als neue vollständige AAA-Abnahme erledigt. Memory, Vier gewinnt, Quizshow, Würfel-Wettlauf, Kartenabenteuer und Lernminispiele besitzen noch keinen flächendeckenden neuen Godot-3D-Umbau. |
| Visuelle Produktionsabnahme und Zugänglichkeit | Einzelne echte Screenshots belegen konkrete Zustände. Kontinuierliche Bewegung, komplette Spielrunden, alle Auflösungen, Sprachführung und langfristige Bedienbarkeit benötigen weitere konkrete produktbezogene Abnahme. |

**Freigabestatus dieses Dokuments:** Der beschriebene Studio-Quellabschnitt ist implementiert und in den genannten Grenzen geprüft. Vollständige Masterfreigabe, Android-17-PASS, physischer Fold7-60-FPS-Nachweis und finale APK-Lieferung sind offen. Main bleibt bis zur ausdrücklichen Freigabe geschützt.
