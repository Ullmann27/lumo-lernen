# Lumo – aktuelle Modul- und Abnahmematrix

**Beobachtungsstand: 14. November 2026, 16:03:38 UTC. Diese Übersicht dokumentiert implementierte Funktionen und vorhandene Belege; sie ist keine Gesamt-, APK- oder Leistungsfreigabe.**

Memory und Quiz besitzen inzwischen produktive native 3D-Ansichten mit gemeinsamem Dart-Spielzustand. Englisch hat eine begrenzte, tatsächlich gerenderte Objektgalerie. Damit sind die früheren Aussagen „Memory/Quiz nur Flutter“ und „keine native Englisch-Hilfe“ überholt. Die vollständige neue Kombination muss ihre eigenen Native-, Android-, Update- und Veröffentlichungsgates noch bestehen.

## 1. Quellen und tatsächlicher Abnahmestand

Der aktuelle Host ist **`2e20f5f24cee7a696296e6bea5618cc130a40ce2`**. Die unten beschriebenen neuen Native-Funktionen wurden auf **`47ca642aad9290c9ba274b08e7dadfc953854d4f`** geprüft. Der Nachfolger **`29080ef8cd1a5b385eeeec97976fbefd31280427`** korrigiert ausschließlich den alten Branch-Vertragstest; die Produktdateien bleiben gleich. Seine neuen Ergebnisse werden separat erhoben. Die neue Authority-Matrix ist inzwischen vollständig erfolgreich; ihre aktuellen Bilder wurden separat geöffnet. Die vollständige neue Native-Abnahme bleibt offen.

| Tatsächlicher Stand | Vorliegender Beleg | Grenze |
|---|---|---|
| Host `cb85abed7c947af8e491f3d2b6488e443dc73c0a` | Vollständige Flutter-Suite **2.608 bestanden, 0 Fehler, 0 übersprungen**, Exit 0; eigener Originalbericht. [E1] | Kein Android-Spielnachweis; 546 erzeugte PNGs bedeuten keine persönliche Sichtung aller Bilder. |
| Host `2e20f5…` | Erneut **2.608/0/0**, Exit 0; [Run 43610022344](https://github.com/Ullmann27/lumo-lernen/actions/runs/43610022344) vollständig erfolgreich, einschließlich Android-Klassenkompilierung. [E1] | Quell-/Flutter-/SDK-Prüfung, noch kein neues freigegebenes APK. |
| Native `47ca…`, eigene Authority-Matrix | [Run 43607369297](https://github.com/Ullmann27/lumo-godot/actions/runs/43607369297): **Englisch, Quiz und Memory erfolgreich**. Quiz und Memory liefen als echte Dart-/Godot-Prozesspaare; Englisch verwendete den tatsächlich ausgeführten Dart-Aufgabenproduzenten. [E2–E4] | QA-Dateitransport, Test-Wallet bzw. deklarierte Plattformadapter; keine Android-Binder-/Geräteabnahme. |
| Vollständiger Native-`47ca…`-Lauf | Sechs Pflichtjobs erfolgreich. `new-worlds` scheiterte **vor seinen Spielprüfungen** am veralteten Einzweig-Test: 16 Fälle, 1 Fehler. Bundle und Archiv übersprungen. [E5] | Dieser [Run 43607369276](https://github.com/Ullmann27/lumo-godot/actions/runs/43607369276) bleibt **fehlgeschlagen**. Keine Freigabe der nicht erreichten Prüfungen. |
| Native `29080…` | [Authority-Matrix43611803404](https://github.com/Ullmann27/lumo-godot/actions/runs/43611803404) **completed/SUCCESS, alle drei Jobs erfolgreich**. Aus ihren neuen Originalen wurden **Quiz6, Memory15 und Englisch17 Bilder** tatsächlich geöffnet. [E7–E9] | [Vollständiger Native-Lauf43611803408](https://github.com/Ullmann27/lumo-godot/actions/runs/43611803408) zum angegebenen UTC-Stand weiterhin **in_progress**. Kein neuer kombinierter Gesamt-Receipt oder APK-PASS. |
| Neuer Quiz-Einzeljob auf `29080…` | Job **132498257149** erfolgreich: 28 Dartfälle/1.786 Checks, echtes Paar mit 20 Fragen, drei Jokern, 67 Requests und sechs neu einzeln geöffneten Originalbildern; beide Prozesse Exit 0. [E7] | Noch keine Gesamt-Native-/APK-/Androidfreigabe. Dieser Lauf bindet tatsächlichen Host `50503…`, dessen hier ausgewählte Produktquellen mit `2e20…` identisch sind. |
| Kombinierte Android-Auslieferung | Neuer Host enthält die Reihenfolge C4 → Quiz → Memory → Englisch für API35/37 sowie die zusätzlichen Authority-Gates. | Frischer Native-Pin, neues Gesamtarchiv mit Sichtprüfung, passender Receipt, APK-/Android-/Update-/Creative- und Publishererfolg stehen für diese Kombination noch aus. |

Main wurde nicht verändert; ein Merge bedarf weiterhin der Freigabe. Technischer Branchschutz wird damit nicht behauptet.

## 2. Die zehn Hauptportale

**Erreichbarkeit:** Die aktuelle Hostdatei `lib/features/games/spielwelt/spielwelt_routes.dart` enthält genau diese zehn Portale; `games_content.dart` bindet ihre echten Aufrufe. Memory, Cards, 4 Gewinnt und Quiz betreten zunächst ihre Flutter-Oberfläche. Memory/Quiz öffnen daraus auf Android den nativen, tokengebundenen Spielpfad; ein nicht verfügbarer optionaler Renderer lässt die vorhandene Flutter-Runde benutzbar. Ein Routeintrag allein ist kein bestandener Android-Einstieg. Die Native-Ziele sind in `scripts/app/scene_router.gd` gebunden. [S1]

In der Tabelle bedeutet **H** Host-Repository, **N** Native-Repository. „Historische Sichtbelege“ bleiben ihrem damaligen Commit zugeordnet; ein neuer Gesamt-Receipt wird daraus nicht abgeleitet.

| Modul und produktiver Einstieg | Vorbestand | Tatsächlicher Studio-/Folgeausbau | Belege und weiterhin offen |
|---|---|---|---|
| **Memory** – H `lib/features/games/memory/lumo_memory_game.dart` → `scene: memory`; N `scenes/games/memory_table.tscn` | Flutter-Motive, Schwierigkeitsstufen, Gegner und kindbezogene Bestwerte. | Gemeinsamer persistenter Dart-Controller; plastische 3D-Karten mit realer Drehung; Pause/Restzeit/Wiederaufnahme; sichere verspätete Native-Öffnung; monotone Zeitmessung; idempotenter Ergebnis-/Walletabschluss. | Aktuell `29080`: 30 reine Authorityfälle, 7 Schedulerfälle; echtes Paar mit **19 positiv bestätigten Requests, 3 Rückgaben, 8 Zustandsbildern** und einmaliger QA-Belohnung. C öffnete 15 ausgewählte aktuelle PNGs. Kleine Formate blättern Karten; Lumo ist nicht in jeder Portraitansicht sichtbar. Android, tatsächliche globale Wallet und Prozessneustart bleiben offen. [E9; früherer Lauf E3] |
| **Cards** – Portal → `LumoCardsShowcaseScreen` → Solo/lokale Runde; N `scenes/games/cards_table.tscn` | Bestehende Dart-Kartenregeln, Gegner, Speicherung, Cup und native Tischdarstellung. | Lifecycle-Heartbeat, echte Kartenfront-/Layoutbindung, Android-Safe-Area und lesbare deutsche Rückmeldungen. Die Showcase-Zwischenebene wird bei Rücknavigation berücksichtigt. | Historische echte Front-/Layout-/Returnbelege; aktueller Flutterbestand geprüft. Kein neuer Regelkatalog. Frische Android-Abnahme dieser neuen Gesamt-APK offen. |
| **Puzzle** – `launch3D(puzzle)`; N `scenes/creative/puzzle_world.tscn` | Fünf Motive, mehrere Teilzahlen, dicke Teile, Drag/Snap und Save. | Vierteldrehungen mit passender Orientierung/Speicherung, Menülifecycle und gemeinsame Insets. | Vorhandene Dreh-/Platzierungs-/Menübelege; keine neue komplette Puzzleengine. Neuer Android-Spiel-/Save-/Resume-PASS erforderlich. |
| **Jump & Run** – `launch3D(jump)`; N `scenes/games/jump_islands.tscn` | Inseln/Expeditionen, analoge Bewegung, variable Sprunghöhe, Sprungpuffer und Kollisionen. | Sechs Blender-Bewegungsclips am Original-Lumo, neutrale Pose und Landungs-/Flugübergänge; sichere Bedienelemente. | Echte historische Bewegungs-/Filmnachweise sind gebunden vorhanden. Eine Videodatei bzw. Medienbildrate belegt keine Geräte-FPS; aktuelle kombinierte Android-Steuerung/Resume offen. |
| **Rhythm Party** – `launch3D(rhythm)`; N `scenes/creative/rhythm_world.tscn` | Vier Songs, Tap/Hold/Slide, Combo und Tour. | Anschluss an gemeinsame Insets und Layout-Neuberechnung. | Kein neuer Musik-/Rhythmusregelsatz. Physische Eingabelatenz, Multitouch und Geräteleistung bleiben eigenständige offene Nachweise. |
| **Schatzsuche** – `launch3D(treasure)`; N `scenes/creative/treasure_world.tscn` | Insel, sieben Hinweise, Fundstücke, Rucksack, Tor und Speicherung. | Garten-/Kristallhinweise mit gespeicherten Fortschritten; Titelkontrast; HUD verdeckt Lumo am Spawn nicht; kompakte Hinweistaste und Abstand zwischen Meldung und Eingabezielen. | Fünf Profile mit Frischstart/Wiederaufnahme sowie 54-PNG-Gesamtroster bleiben Pflicht. Neue Eingabe-/Fund-/Rucksack-/Resume-Abnahme gehört zum passenden Android-Build. Keine reine Budgeterhöhung als Leistungsbeleg. |
| **Bauwelt** – `launch3D(build)`; N `scenes/creative/build_world.tscn` | Bauteilkatalog, Platzieren/Verschieben/Drehen, Raster/Kollision, Undo/Redo und Save. | Original-Lumo-Bewegung, bedienbare Dialoge, Kameraziele/Touchflächen und Insets. | Bestehender Editor wurde erweitert, nicht neu erfunden. Neue reale Android-Platzierungs-/Savebelege bleiben erforderlich. |
| **Lumo Kart** – `launch3D(kart)`; N `scenes/games/kart_island.tscn` | Zwölf Strecken, Rennen/Cup/Zeitfahren/Training/Arena, Gegner und Garage. | Werkstatt-/Dichte-/Wischbedienung, gemeinsame Safe-Area; QA überspringt die sichtbare Vorschau nur über einen echten beobachteten Tipp. | Kein Neuaufbau aller zwölf Strecken. Stationäre Streckenbilder belegen Themen/Geometrie, keine vollständige Fahrt, 60 FPS oder Mario-Kart-Qualitätsgleichheit. Streckenliste unten. |
| **4 Gewinnt** – H `LumoConnectFourScreen` → `connect_four`; N `scenes/games/connect_four_table.tscn` | Flutter-Regeln auf 7×6, Gegner und lokale Runde. | Echte 3D-Steine/Gewinnmarkierungen, bestätigte Speicherung/Pause/Return; gemeinsames horizontales Flutter-Brett mit zugeordneten ≥48-dp-Spaltenknöpfen und echten Wischverträgen. | Historische Native- und fünf Standard-/vier Fold-Renderings; heutige Flutter-Suite grün. Keine neue globale Android-Freigabe; breite/kleine Darstellungen zeigen nicht stets Lumo. |
| **Quizshow** – „Wer wird Lumo-Meister?“ → H `lib/features/quiz/quiz_show_content.dart` → `quiz`; N `scenes/games/quiz_studio.tscn` | 20 Fragen, vorhandene Fragebank, drei Joker und Meilensteine. | 3D-Studio mit Original-Lumo, gemeinsamem Dart-Zustand, dauerhafter ACK-Bindung, sicheren Start-/Pause-/Returnpfaden; tatsächlicher Null-Erklärungs-/Hidden-Index-Vertrag; eigener validierter Quiz-Walletpfad. | `47ca` und neu separat `29080`: **alle 20 Fragen, drei Joker, 67 Requests, je 6 tatsächlich geöffnete Originalbilder**, beide Prozesse Exit 0. 5.000 Sterne stammen im Paarlauf aus dem ausdrücklich benannten QA-Ledger. Studio ist ein schlichtes Podest-/Bogenbild; volle TV-Showinszenierung und neue Android-Abnahme offen. [E2, E7] |

Die benannten Legacy-Erweiterungen stammen aus den eingefrorenen Studio-Inventuren und Quellen, nicht aus einer neuen Ausführung dieses Dokumentationsauftrags. Der `47ca`-Studiojob war erfolgreich; wegen des fehlgeschlagenen vollständigen Laufs existiert daraus keine neue kombinierte Gesamtfreigabe. [E0, E5]

## 3. Lernzugänge und zusätzliche Spiele

| Zugang | Vorbestand und wirklich hinzugefügter Umfang | Quelle / verbleibende Grenze |
|---|---|---|
| **Mathematik → „Mit Lumo in 3D ausprobieren“** | Native Addition/Zehnerübergang, Subtraktion, Gruppen und Bruchteile waren vorhanden; **8 + 5 war bereits implementiert**. Studio ergänzte gleichmäßiges Verteilen sowie korrekte ×/÷-/Bruch-Payloads und Hunderterbeschriftung. | H `lib/domain/tutoring/native_learning_activity.dart`, N `scripts/learning/learning_activity.gd`. Begrenzte konkrete Aufgaben; keine vollständige neue 3D-Welt für Zahlenstrahl, Maße, Flächen, Uhr und Geld. [E0, S1] |
| **Englisch → aktuelle unterstützte Wortaufgabe → 3D-Hilfe** | Jetzt **14 konkrete Wörter**, darunter **alle zehn Schulsachen-Einträge der Klassen 1/2**. Tatsächliche Objektgeometrie, Auswahl, Hinweis und Rückkehr; Hilfe schreibt keine erfundene richtige Antwort und vergibt keine Belohnung. | H `native_english_vocabulary.dart` / `native_learning_activity.dart`; N `scripts/learning/learning_world.gd` und Objektgalerie. Aktuell `29080`: 10 Dartfälle/2.955 Checks, **7.633 Nativechecks**, 17 aktuelle von A geöffnete PNGs, 196 ScreenTouch-Ereignisse. Deutsche Hinweise; **englische Aussprache nicht nachgewiesen**, keine abstrakten Klassen-3/4-Inhalte. [E8, S1] |
| **Deutsch / Silben / Grammatik** | Vorhandene Silben-/Wortzuordnung und Flutter-Sprachübungen; Studioatelier und gemeinsamer Lehreranschluss. | Bestehender Lernpfad, kein neuer vollständiger Satzbau-/Grammatikraum. [E0] |
| **Sachunterricht** | Interaktives Pflanzenmodell bereits vorhanden; Studio ergänzte echtes Atelier/Gartenmaterial und Blattbewegung. Tiere/Wetter/Jahreszeiten/Verkehr bestehen als Lerninhalte. | N `scripts/learning/learning_world.gd`; kein neuer vollständiger begehbarer Themenkatalog. [E0] |
| **Schreibtrainer und Journal** | Produktive Schreibflächen, Vorlagen, Wortcoach und Journal bleiben erhalten. | H `lib/features/writing/`, `lib/features/journal/`. Kein neu entwickelter 3D-Schreibtrainer, keine pauschale neue Journal-Migrationsabnahme. [E0] |
| **Lesen / Reading Buddy** | Geschichten, Sprach-/Satzmarkierungen und Verständnisfragen bleiben Bestand. | H `lib/features/reading/`. Keine neue vollständige begehbare Geschichteninszenierung. [E0] |
| **Akademie / Lernlabor / Aufgabenplanung** | Historisch 20 registrierte Themen mit 19 Screens; heutiger Lernkatalog und adaptive Aufgaben bleiben erreichbar. Registrierung bedeutet keine eigene neue native Welt. | H `lib/features/learning/learning_content.dart`, `lib/features/learning/lab/`, `lib/domain/learning/lumo_learning_domain.dart`. Die Themenliste bleibt unten erhalten; keine neue Komplettabnahme jedes Themas. [E0, S1] |
| **Kinderprofile / Hilfen / Belohnungen** | Stabile Kindschlüssel, Lease-/Spätantwortschutz und getrennte Altstandzuweisung; nun zusätzlich dauerhafte Memory-/Quiz-Runden und sichere Wallet-Queue. | Aktuelle Flutter- und Authorityprüfungen bestätigen konkrete Verträge. Ein-Kind-Updatebelege beweisen keine vollständige Zwei-Kind-/Journal-/Altspielstandmigration. Neue APK-Datenprüfung bleibt Pflicht. [E0–E4] |

**Englischer Objektkatalog:** book/Buch, pen/Kugelschreiber bzw. Stift, ruler/Lineal, bag/Tasche, rubber/Radiergummi, school bag/Schultasche, desk/Schreibtisch, chair/Sessel, pencil case/Federpennal, paper/Papier; zusätzlich ball/Ball, car/Auto, sun/Sonne, apple/Apfel. Mehrwortnamen und Antwort-/Aufgabenbindung werden ausdrücklich geprüft; es ist keine beliebige Text-zu-3D-Erzeugung. [S1, E8]

**Fünf bestehende Flutter-Lernatelier-Themen:** Die Zehnerbrücke, Die Wortwerkstatt und Der Weg des Wassers ab Klasse 1; Lumos kleine English-Welt ab Klasse 2; Das Bruchatelier ab Klasse 4. Startseite oder Akademie → `LearningLabHub` → `LearningLabScreen`; diese Modellboards sind nicht fünf weitere neu gebaute Godotwelten. [E0]

**Akademiethemen aus der gebundenen Bestandsinventur:** Zahlen/Plus/Minus bis 10, Formen, Tiere, Farben, Uhr, Geld, Zahlen bis 100, Artikel, Mehrzahl, Jahreszeiten, Wetter, Verkehr, Wortarten, Zeitformen, Wortdiktat, kleines/vollständiges Einmaleins und Brüche. Diese Kurzfassung übernimmt die historische Registrierung, keine neu ausgeführten 20 Einzelprüfungen. [E0]

| Zusätzlicher Zugang außerhalb der zehn Hauptportale | Tatsächlicher Stand |
|---|---|
| **Siedlung**, Auswahl innerhalb der Bauwelt; N `scenes/creative/build_settlement_world.tscn` | Vorhandene Ressourcen, Gebäude, Produktion, Handel, Gegner und Save; Studio ergänzte Layoutanschlüsse und die Sprachkorrektur „1 Münze“. Keine neue Ökonomie. |
| **Würfel-Wettlauf**, eigene Zusatzkachel | H `lib/features/games/dice_race/lumo_dice_race_game.dart`; vorhandenes Brettspiel, kein neuer nativer Umbau. |
| **Sternenpfad / Kartenabenteuer**, eigene Zusatzkarte | H `lib/features/games/star_trail/star_trail_screen.dart`; kooperativer Pfad, ausdrücklich eigenständig neben Cards. |
| **Flame-Abenteuer**, Abenteuerkarte | `GamesContent._launchAdventure()` → `LumoJumpFlameScreen`; bestehender 2D-Pfad, getrennt vom Godot-Jump. |
| **Lernspiel-Levelkatalog** | `GamesContent._launchLevel()` / `game_level_catalog.dart`: vorhandene Kategorien starsPath, numberHouse, colorBoxes, letterFill, numberPath, wordForest, mixedQuiz; Level 50 öffnet die Quizshow. Keine 50 neuen 3D-Szenen pro Klassenstufe. |
| **Quest / Story / Zauberwelt**, über die Startseite | Bestehender Storyreader und Bibliothek; Zauberwelt verlinkt unter anderem Quest, Cosmos, LIVE und Mirror. Kein neuer nativer Geschichtenwelt-/Tier-Safari-/Fotoquiz-Nachweis. [E0] |
| **Meine Welt / Cosmos / Mirror / LIVE / Foto-Lektion** | Vorhandene Lern-/Begleiter-/Visualisierungsflächen; keine neu implementierten nativen Hauptspiele. Kamera-, Online- und Sprachfreigaben bleiben eigene Grenzen. [E0] |
| **Weitere native Lese-/Systemrouten** | reading_hub, alphabet, word_picture_match, sound_letter_match, word_build, learn_old, stars und parent sind registriert. Diese Übersicht behauptet daraus keine neu geprüften sichtbaren Hauptportale. |

## 4. Alle zwölf vorhandenen Kart-Strecken

Die vier Basis- und acht Erweiterungsstrecken sind im aktuellen `kart_catalog.gd` sowie `kart_tracks.gd` / `kart_expansion_tracks.gd` vorhanden. Die Tabelle beschreibt den **Bestand**, nicht zwölf neue Studio-Implementierungen oder zwölf aktuelle Gerätefahrten. [S2]

| ID | Thema / Anzeigename | ID | Thema / Anzeigename |
|---|---|---|---|
| `sonnenhafen` | Sonnenhafen | `zauberwald` | Zauberwald |
| `bergwelt` | Himmelsinseln | `holo_city` | Holo City / Hologramm-City |
| `crystal_canyon` | Kristall-Canyon | `jungle_temple` | Dschungel-Tempel |
| `candy_cloud` | Candy Cloud Circuit | `volcano_night` | Volcano Night Run |
| `winter_sprint` | Winter-Sprint | `galaxy_ringway` | Galaxy Ringway |
| `desert_drift` | Desert Dune Drift | `learning_lab` | Funkel-Labor |

Die bisherigen thematischen Standbildsichtungen ersetzen weder vollständige Rennen auf jeder Strecke noch Drift-/Gegner-/Kollisionsabnahme oder physische Fold7-Leistungsmessungen.

## 5. Original-Lumo, Blender und Animation

| Bereich | Tatsächlich angeschlossen | Noch nicht belegt bzw. nicht umgesetzt |
|---|---|---|
| **Originalidentität und Körper** | Unverändertes Original-Animated-GLB bleibt separate Quelle; 65 Bones und neun Originalclips. Sechs zusätzliche Studio-Bewegungsclips: walk, sprint, rise, fall, land, brake; neutrale Pose und gemessene Rigachsen. Historische Blender-Erstellung/Exporte sind dokumentiert. | Kein vollständig neuer Charakter und keine vollständige Gestenbibliothek für alle Lehr-/Spielsituationen. |
| **Gesicht** | Von der Originalgeometrie abgeleitetes `assets/characters/lumo_facial/Lumo-Facial-Mobile.glb`; echte skinnierte Lider, Blinzeln, begrenzte Blick-Morphs der bemalten Augenregion und dezente geschlossene Schnauzen-/Kieferartikulation. Actor und produktiver Lehrer verwenden diese Geometrie. | Keine unabhängigen anatomischen Augäpfel, offene Mundhöhle, umfassende Emotionen oder phonembasierten Viseme. |
| **Lokale Sprache** | `apply_speech_sample` und tatsächliche lokale Wiedergabezeit/Amplitude treiben die Kieferform; Stop/Mute/fehlende Freigabe bleiben getrennte Grenzen. | Amplitudenbewegung ist **keine vollständige Lippen-Synchronisation**. Keine neue Hörprüfung oder englische Aussprachebestätigung in dieser Übersicht. |
| **Renderer-/Filmbelege** | Historische Nahbilder/Animationen und die vorhandenen Facial-Regression-/Filmverträge bleiben erhalten; aktueller `47ca`-Studiojob erfolgreich. | Keine neue persönliche Sichtung des vollständigen `29080`-Films in diesem Dokument; keine Geräte-FPS aus Aufnahme-FPS oder deterministischem Testtakt. |

Die Herkunft ist in N `assets/characters/lumo_facial/ATTRIBUTION.md` und den tatsächlichen Actor-/Posequellen gebunden. Facial-GLB-SHA256: **`e14aea79eb9918f5184c8ded64e8c1343bf71f553772a4f59298ada6862d9524`**; separate Animated-Originalquelle: **`3559f700784bc1006905ee3aae01e8bcfbffb95b4f621f7430ce771ba0e3efd5`**. Kein neuer Blenderlauf wurde für diese Übersicht ausgeführt. [S3, E0]

## 6. Verantwortlichkeiten, Belegverzeichnis und offene Abnahme

**Umsetzung/Review:** A `learning_worlds`: Lernen/Englisch, deren aktuelle Bildsichtung; B `character_animation`: Körper/Gesicht, Quiz-Native und Quiz-Androidprüfer, sechs aktuelle Quizbilder und diese Zusammenführung; C `games_worlds`: Memory, dessen aktuelle Bilder und Teile der Spiel-/QA-Korrekturen. Root verantwortet gemeinsame Integration, Quellpins, Workflows, Receipt und endgültige Auslieferung. Gegenseitige Quellenreviews sind keine eigenen Testläufe.

**Offen für den Masterauftrag:** neues erfolgreiches vollständiges Native-Archiv samt frischer Sichtprüfung; exakt dazu gebautes APK mit API35/API37-, Spiele-, Save-/Resume-, Profil-/Update- und Publishergates; physische Fold7-Messungen zu stabiler Bildrate, Wärme, Energie und Eingabelatenz; die oben benannten noch nicht entwickelten Lehrwelten, Geschichten, Emotionen, Viseme und Gesten. Aus dem Bestand wird weder „AAA fertig“ noch eine neue Implementierung aller Spiele/Strecken abgeleitet.

Die vollständigen SHA256-/Gitblob-Zuordnungen und gelesenen Originalpfade stehen im begleitenden **`module-matrix-source-binding.json`**. Keine ursprünglichen Berichte wurden geändert.

- **[E0] Historische Bestands-/Studio-Inventur:** Roots unveränderte `previous-inventory-reference.md` (Host86445/Nativeacf51) mit 10/20/5/7-Zuordnungen sowie [STUDIO_NEXTGEN_SCOPE.md am aktuellen Host](https://github.com/Ullmann27/lumo-lernen/blob/2e20f5f24cee7a696296e6bea5618cc130a40ce2/docs/STUDIO_NEXTGEN_SCOPE.md), Blob `0e2ddd6f…`. Nur Umfang/Herkunft übernommen; dortige alten CI-Stände und inzwischen überholte „noch nicht implementiert“-Aussagen wurden nicht als aktuelle Ergebnisse übernommen.
- **[E1] Aktuelle Hostoriginale:** `qa/studio-memory-next-v2-20261114/evidence/{cb85-ci,2e20-ci}/acceptance-summary-from-original-job.json`; cb85-`review.json`; `qa/root-current-integration-proof-20261114/host-2e20-{run,jobs}.json`.
- **[E2] Quiz `47ca`:** `qa/studio-quiz-native-47ca-ci-20261114/{original-closure,visual-review,completion-review}.json`. Das frühere Closure vor Sichtung wird durch den späteren gesonderten Sichtbericht ergänzt, nicht umgeschrieben.
- **[E3] Memory `47ca`:** `qa/studio-memory-native-47ca-ci-20261114/{review,original-results-verification}.json`.
- **[E4] Englisch `47ca`:** `qa/studio-english-native-47ca-ci-20261114/{review,image-review,source-and-artifact-binding}.json`.
- **[E5] Fehlgeschlagener Gesamtlauf:** `qa/root-current-integration-proof-20261114/native-47ca-{full-run,full-jobs,failure-extract}.json`.
- **[E6] Enger Branch-Testfix:** `qa/native47-runner-branch-contract-fix-20261114/evidence/runner-contracts-{original.log,execution.json}`; unabhängige Note `qa/native47-runner-branch-independent-review-20261114/review.json`.
- **[E7] Neue Quizoriginale `29080`:** `qa/studio-quiz-native-29080-ci-20261114/{original-closure,visual-review,verified-original-extraction}.json`; Originalartefakt14120796271, SHA256`1eb1db04b4226df164c58b0166e0524797f96ec1b82054593e7e5001f60ae0fd`.
- **[E8] Neue Englischoriginale `29080`:** `qa/studio-english-native-29080-ci-20261114/{review,image-review,source-and-artifact-binding}.json`; Review-SHA256`060db6a88e5cc493b4a4adffc02cb07bd8a222c3705361a761a5b8207fcad751`. 17 neue Originalbilder persönlich durch A geöffnet; keine Übernahme der alten47ca-Sichtung.
- **[E9] Neue Memoryoriginale `29080`:** `qa/studio-memory-native-29080-ci-20261114/{review,original-results-verification}.json`; Review-SHA256`5721e499810dce2dc7c0a768a6b79cf2f21a632602cee55551fd1c00dfc2d7c2`. 15 aktuelle Bilder persönlich durch C geöffnet, nicht alle28PNG bzw. alle12Animationsframes.
- **[S1–S3] Quellen:** frisch gelesene Host-`2e20`-Einstiege und Kataloge; gebundener Native-`47ca`-Router, Kartkatalog und Original-/Facial-Dateien. Ausgewählte produktive Hostblobs stimmen mit der in der Authority-Matrix ausgeführten Host-`50503`-Quelle überein; die konkrete Dateiliste steht in `module-matrix-source-binding.json`.
