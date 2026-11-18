# Lumo Gesamtmatrix – dauerhaft gepflegte Produktübersicht

Angelegt am 17.11.2026 im Auftrag von Heinz („Gesamtprodukt – alles bedeutet alles").
Diese Datei ist die verbindliche Liste aller Produktbereiche mit Status und Nachweis.
Sie ersetzt keine Übergaben, sondern sagt je Bereich: was gibt es, was fehlt, was ist geprüft.

**Regeln für diese Datei**

- Kein pauschales „Rest fertig". Jeder Bereich hat einen eigenen Status.
- Status: `OFFEN` · `IN ARBEIT` · `TEILWEISE` · `PASS (lokal)` · `PASS (Android-Emulator)` · `PASS (Gerät)` · `NOT_RUN`.
- „PASS (lokal)" heißt: Test in dieser Sitzung auf Linux mit Godot 4.6.3 bzw. Flutter 3.44.9 selbst ausgeführt. Das ist keine Geräteprüfung.
- Wer etwas ändert, trägt Datum, Commit und Nachweis ein.

## 1. Quellstand (17.11.2026)

| Repo | Arbeitsbranch | Basis | Bemerkung |
|---|---|---|---|
| lumo-lernen (Flutter) | `ccr-54af69f2-4uged4` | `lumo-nullpunkt/integration-20261117` @ `d7930240` | Version 0.13.25+2037, Godot-Pin `bb478880` (noch alt) |
| lumo-godot (Godot 4.6.3) | `ccr-54af69f2-4uged4` | `lumo-nullpunkt/integration-20261117` @ `ebd3401` | plus 2 Kart-Reparaturen und 6 Streams (Integration‑2), siehe Abschnitt 6 |

`main` steht in beiden Repos auf dem Stand vom 16.10.2026 (1951) und ist nicht die Arbeitsgrundlage.
Zuletzt öffentlich belegte APK laut Repo-Dokumenten: 0.13.19+2031 (16.11.). Stände 2032–2037 sind gebaut bzw. vorbereitet, deren Abnahme habe ich nicht selbst geprüft.

## 2. Entscheidungen von Heinz am 17.11.2026

1. **UNO ist raus.** „Lumo Cards" ist im Code UNO mit umbenannten Karten (siehe 4.2). Es wird durch 2–3 eigene Lumo-Kartenspiele ersetzt.
2. **Kartenspiele am echten 3D-Tisch:** runder Tisch, Lumo-Figuren sitzen rundherum, Karten werden sichtbar auf den Tisch gelegt.
3. **Lumo Kart bleibt 3D und hat höchste Priorität:** alle Strecken, Landschaft, Pausenmenü; lange, aufregende Strecken mit Sprüngen, Fallen, Abkürzungen.
4. **Jump‑and‑Run in 3D** mit Lumo von hinten gesehen, sauber animiert, lange aufwendige Strecken mit Aufgaben, mehrere Welten.
5. **Bauwelt / Dorf:** klug ausgearbeitet, schöne Grafik, lange und sinnvolle Kampagne.
6. **Lern-App:** jede Sparte, 1.–4. Klasse Volksschule, jedes Fach, jede Aufgabe ansehen und modernisieren.
7. **Messlatte:** Eltern sollen 14,99 €/Monat als gerechtfertigt empfinden.

8. **Zielbilder sind verbindlich** („genau diese Gestaltung, genau dieses Layout"): `docs/design_targets/2026-11-17/` in beiden Repos (Kart-Menü hoch/quer, Zieleinlauf Platz 1–3, Profil, Startseite auf dem Fold, dazu Boards für Spielwelt, Jump & Run, Schatzsuche, Bauwelt, Memory, Rhythm Party, Puzzle, Cards). Gewünscht sind in Blender gerenderte Knöpfe, Rahmen und Symbole.
9. **Umsetzung mit mehreren Agenten parallel.**

10. **Freischalten durch Lernen, Werkstatt wie in einem Rennspiel mit Bauteilen:** Wer lernt, schaltet schnellere Karts und Bauteile frei. Bestand: 14 Karts mit Sternschwellen (`kart_fleet.gd`), Tuning-Werkstatt mit Motor, Bremsen, Reifen, Turbo (je Stufe 0–5), Lacken, Felgen und Neon, bezahlt mit Lern-Sternen (`kart_tuning.gd`). Ziel: mehr und sichtbare Bauteile, Werkstatt als eigener hochwertiger Bereich, freigeschaltete Karts auch im Profil-Regal der App.
11. **Dorf-/Strategiemodus:** sehr große Karte mit Hügeln und Bergen (dort kann man nicht bauen), Kampagne mit Logik, Freibau, KI-Gegner, die eigene Städte sichtbar auf derselben Karte aufbauen und denen man zusehen kann. Kindgerecht, mit deutlich besserer Grafik. Bestand: `build_settlement_*` (Wirtschaft, Bewohner, sichtbare KI, 22-Tage-Kampagne) auf flachem Gelände.
12. **Jump & Run als 3D-Lauf von hinten gesehen** (wie Lumo Kart, nur dass Lumo läuft): lange Strecken durch Wald, Dschungel und andere Welten, Tempo, Sprünge, Sammeln. Eigene Figuren, Strecken und Gestaltung; kein Nachbau eines bestehenden Spiels. Bestand: `jump_islands.gd` (12 kleine schwebende Inseln, 3 Kurse, Blick von hinten oben) und ein 2D-Spiel in Flutter.

13. **Freie Hand (17.11.2026, abends):** Heinz erteilt ausdrücklich die Einwilligung für alles, was zum Fertigstellen nötig ist, einschließlich des Vereinfachens der selbst auferlegten Build- und Versions-Sperren. Arbeitsweise: autonom, erst die Spiele, dann die Lern-App auf demselben Niveau; jede Lösung zweimal durchdenken.

Daraus von Claude entschieden (kein weiteres Nachfragen):
- **Kart-Items:** Das Katalog-System des Streams `lumo-kart/gameplay-items` (Rakete, Falle, Schild, Glück nach Platz) wird das einzige Item-System; die Resonanz-Ringe werden darin aufgehen.
- **Memory:** Der Flutter-Look ist die Untergrenze; der Optik-Commit `5a79c14c` bleibt draußen.
- **Kartenspiele:** UNO entfällt. Drei eigene Spiele am 3D-Tisch mit traditionellen, gemeinfreien Grundregeln und eigener Lumo-Gestaltung: ein Stichspiel („Sternenstich"), ein Anlegespiel („Sternenleiter") und ein Sammel-Fragespiel („Lumo-Quartett").
- **Profil-Regal:** zeigt die durch Lernen freigeschalteten Karts.
- **Test-APK:** Die Pin-Sperre verlangt keinen handgeschriebenen Eintrag je Buildnummer mehr; Version 0.13.27+2039, Godot-Pin `2b1fd30`; Bau über `.github/workflows/lumo-test-apk.yml`, ausgelöst durch `config/test-apk-request.json`.

Bewusst beibehalten, weil es Kinder schützt und nichts blockiert: Kamera, Mikrofon und Datenweitergabe bleiben standardmäßig aus und hinter der Elternfreigabe; keine Käufe, keine fremde Kommunikation.

Einschränkungen zu den Zielbildern, damit nichts vorgetäuscht wird:
- Es sind Konzeptbilder. Übernommen werden Aufbau und Aussehen; gezeigt werden nur echte Funktionen und echte Zahlen.
- Mehrspieler, Münzen mit „+", Saisonpass Premium, tägliche Challenges, Lokal-Koop und Teilen gibt es im Produkt nicht. Sie werden nicht als Attrappe gebaut.
- Das Cards-Board zeigt UNO-Kartentypen. Wegen Entscheidung 1 wird nur die Tischszene übernommen.

Grenze, offen ausgesprochen: Fotorealismus wie in Konsolen-Großproduktionen ist auf Android mit dieser Engine nicht erreichbar. Ziel ist ein hochwertiger, stilisierter 3D-Look.

## 2a. Abnahmeschwelle für jedes Spiel (Heinz, 17.11.2026)

Ein Spiel gilt erst als fertig, wenn man es grafisch, spielerisch und in Sinn und Logik
guten Gewissens einem Haus wie Nintendo vorlegen **könnte**. Das wird nicht behauptet,
sondern je Spiel an acht Punkten geprüft. Jeder Punkt bekommt 1 bis 5 und einen Nachweis.
Fertig heißt: alle acht mindestens 4, Punkt 8 auf einem echten Gerät gemessen.

| Nr. | Punkt | Woran es geprüft wird |
|---|---|---|
| 1 | Sofort verständlich | Ein Kind versteht in 30 Sekunden ohne Lesen, was zu tun ist |
| 2 | Steuerung | Direkt, präzise, verzeiht kleine Fehler; nichts fühlt sich träge oder zufällig an |
| 3 | Spieltiefe | Echte Entscheidungen, sichtbares Besserwerden, Grund zum Wiederkommen |
| 4 | Inhalt | Genug unterschiedliche Strecken, Level oder Aufgaben; keine umgefärbten Kopien |
| 5 | Grafik und Animation | Einheitlicher Stil, Tiefe, Licht, lebendige Figuren, auf einen Blick lesbar |
| 6 | Feinschliff | Jede Aktion hat Rückmeldung in Bild und Ton; saubere Übergänge; nichts ruckt oder überlappt |
| 7 | Zuverlässigkeit | Pause, Wiederaufnahme, Speichern, Fehlerfälle; keine Sackgassen; Belohnung genau einmal |
| 8 | Leistung | Flüssig auf dem Zielgerät, gemessen (Bildzeiten, Speicher, Wärme) |

Zusätzlich für ein Lernprodukt: Der Lernbezug muss Sinn ergeben und darf den Spielfluss nicht zerstören.

### Ausgangslage am 17.11.2026 – nur Punkt 5, nur aus Renderbildern

Bewertet ist ausschließlich, was ich an echten Engine-Bildern gesehen habe (Software-Renderer,
kein Gerät). Steuerung, Spieltiefe, Ton und Leistung sind **nicht bewertet**, weil ich die Spiele
nicht gespielt und nicht auf einem Gerät gemessen habe.

| Bereich | Punkt 5 heute | Begründung |
|---|---|---|
| Lumo Kart, Rennen | 2–3 | Echtes 3D, brauchbare Karts und Fahrer. Fahrbahn kahl und grau, Licht flach (Vulkan fast schwarz), Streckenrand dünn, kaum Effekte, eine Tastatur-Hilfezeile im Bild |
| Lumo Kart, Hauptmenü | 3 | Aufbau nach Zielbild, lebender Lumo im Kart; Kacheln noch flach gezeichnet (Blender-Kit wird gerade eingebaut) |
| Memory, 3D-Tisch | 2 | Flaches Brett von oben, Lumo klein am Rand; das Flutter-Memory wirkt moderner |
| Jump & Run (Inseln) | 2 | Kleine schwebende Inseln, einfache Bäume, viel Text im Bild; kein langer Lauf |
| Bauwelt | 2–3 | Echtes Bauen in 3D, aber flaches Gelände und schlichte Blöcke |
| Profil (App) | 3–4 | Nach Zielbild neu gebaut; Belohnungs-Regal mangels echter Sammelstücke dünn |

Schatzsuche, Rhythmus, Puzzle, Cards-Tisch, 4 Gewinnt, Quiz, Lernszenen: nicht angesehen, nicht bewertet.

## 3. Navigation und App-Rahmen (Flutter)

| Bereich | Einstieg | Stand | Lücken | Status |
|---|---|---|---|---|
| Start / Onboarding | `lib/main.dart`, `features/onboarding/lumo_onboarding_holo_screen.dart`, `features/home/home_content.dart` | vorhanden | 12 Funktionen stecken in einer eingeklappten Kachel „Mehr mit Lumo entdecken" | OFFEN |
| Shell, 14 Sektionen | `app/app_shell.dart`, `widgets/shell/left_navigation.dart` | vorhanden | Telefonleiste zeigt 5, Rest unter „Mehr" | OFFEN |
| Profil / Belohnungen | `widgets/profile_screen.dart`, `features/rewards/` | vorhanden | Wallet ist ein globaler Schlüssel, nicht je Profil (siehe 5.3) | OFFEN |
| Einstellungen / Elternbereich | `features/settings/settings_content.dart` | vorhanden | Ohne PIN und ohne Rechenfrage direkt erreichbar – ausdrückliche Entscheidung von Heinz vom 3.10.2026 (`docs/PIN_FREI_2026-10-03.md`), kein Mangel. Kamera, Mikrofon und Online-KI sind in frischen Einstellungen aus. Datenschutz nur als Infokarte | ENTSCHIEDEN (PIN-frei); Datenschutzdarstellung OFFEN |
| Lehrerbereich | `features/teacher/*` | vorhanden | ungeprüft | NOT_RUN |

`flutter analyze` auf `d7930240`: 0 Fehler, 278 Hinweise (17.11., selbst ausgeführt). Volle `flutter test`-Suite: NOT_RUN.

## 4. Spiele

Start in der App über `features/games/games_content.dart` und `features/games/spielwelt/spielwelt_routes.dart`.
Godot-Spiele starten über `features/lumo3d/lumo3d_launcher.dart` (nur Android), Ziele in `scripts/app/scene_router.gd`.

### 4.1 Lumo Kart (Godot, `scenes/games/kart_island.tscn`, `scripts/games/kart_*.gd`)

- Stand: 3D, 13 Strecken, 5 Modi (Einzelrennen, Sternen-Cup, Zeitfahren, Training, Kristall-Arena), 14 Karts, Speichern/Fortsetzen, Rückgabe an die App mit einmaliger Belohnung.
- Ziel: Heinz' Punkt 3. Abnahme je Strecke: Orientierungspunkte, Sprung/Falle/Abkürzung, lesbare Fahrbahn, Landschaft mit Tiefe, Pausen- und Ergebnismenü vollständig bedienbar.

| Punkt | Status | Nachweis |
|---|---|---|
| Vollständiger Rennablauf (Menü, 16 Checkpoints, Speichern, Ergebnis, Rückgabe) | PASS (lokal) | `kart_complete_flow_regression.gd` grün nach `8eb2493`; vorher rot |
| Ergebnisdialog: alle 4 Aktionen ohne Scrollen erreichbar | PASS (lokal) | neu `kart_result_reachability_regression.gd`, 5 Displaygrößen; ohne Korrektur rot |
| Himmelsinseln-Sprung | PASS (lokal) | `kart_jump_regression.gd` grün nach `a5061c7`, Flug 0,75 s (vorher 0,48 s) |
| Fahrphysik, Wände, Drift | PASS (lokal) | `kart_physics_regression.gd`, `kart_regression.gd` |
| Rivalen-Flug, Stunt-Kontinuität, Sonnenhafen-Stunt | PASS (lokal) | drei Tests grün unter echtem Renderer (Xvfb, Software-GL); im reinen Headless-Modus verweigern sie den Start absichtlich |
| Items (Stream `lumo-kart/gameplay-items` @ `17b63b4`) | OFFEN – **Designkonflikt** | Stand hat bereits Resonanz-Ringe (Items nur durch Fahrkönnen, nie nach Platz). Der Stream bringt ein zweites System (9 Items, Rakete, Falle, Glück nach Platz) auf einmonatsaltem `main`: 24 Konfliktblöcke in 5 Dateien. Zusammenführen als eigenes Paket, mit einem Item-System als alleiniger Quelle. Vorschlag: Katalog des Streams wird führend (entspricht Heinz' Auftrag Abschnitt 9), Resonanz bleibt als Zusatzregel |
| Menü/Strecken-Dramaturgie (Stream `lumo-kart/menu-strecken`) | PASS (lokal) | Merge `9f5e30b`; `kart_neon_home_regression` (38), `kart_neon_readability_regression` (1180), `kart_adventure_drama_regression` (874 Prüfungen) grün |
| Streckenbauteile (Stream `lumo-2040/kart`) | PASS (lokal) | Merge `a1587ff`; `kart_track_pieces_regression`, `kart_loop_seam_regression` grün |
| Grafikqualität aus Rennkamera, alle 13 Strecken | NOT_RUN | keine Bilder in dieser Sitzung |
| Framezeiten auf Zielgerät | NOT_RUN | kein Gerät |

### 4.2 Kartenspiele

- Bestand: `lib/features/games/lumo_cards/` (Regeln in Dart), 3D-Tisch `scripts/games/cards/cards_table.gd` (zeigt die Dart-Partie an, keine eigenen Regeln).
- Befund: 112 Karten, 4 Farben, Aussetzen/+2/Richtungswechsel/Farbwahl/+4, 7 Startkarten, „LUMO!"-Ruf bei ≤ 2 Karten. Eigen ist nur die Denkpause-Karte. Nur 2 Spieler.
- Weiteres Kartenspiel: „Sternenpfad" (`features/games/star_trail/`), kooperativ, eigene Regeln, bleibt.
- Ziel: Heinz' Punkte 1 und 2. Konzept für 2–3 eigene Spiele steht noch aus und braucht Heinz' Zustimmung, bevor UNO entfernt wird (laufende Partien, Cup-Fortschritt `lumo.cards.cup.v1.*`).

- Zielbild: `board_cards.jpg` (runder Steintisch, Tierfreunde rundherum, eigene Hand unten).

| Punkt | Status |
|---|---|
| UNO-Regeln entfernen | OFFEN |
| 2–3 eigene Spiele (Regeln, Gegner-KI ohne verdeckte Information) | OFFEN |
| 3D-Tisch mit sitzenden Figuren und Kartenwurf | OFFEN (Tisch-Szene vorhanden, Qualität ungeprüft) |

### 4.3 Memory

- Flutter `features/games/memory/`, 3D-Tisch `scripts/games/memory/memory_table.gd`.
- **Zwei Fassungen nebeneinander.** Das Flutter-Memory (nachtblaue Welt, großer Lumo) ist das, was Heinz kennt, und der Maßstab. Der Godot-3D-Tisch ist eine zweite, schlichtere Fassung (flaches Brett von oben, Lumo klein am Rand) und derzeit nur optional.
- Integriert am 17.11.: Godot-Stream `lumo-2040/memory-godot` (Tisch-Look mit Qualitätsstufen), `memory_table_regression` grün mit CI-Parametern (7.020 Prüfungen, 8 Renderbilder).
- App: Fehler-Fix `b93aef5b` aus `lumo-2040/memory-20261117` übernommen; `memory_result_frame_test.dart` wieder grün.
- **Bewusst nicht übernommen:** `5a79c14c` „align Flutter board … with the 3D table". Er gleicht das Flutter-Memory optisch an den schlichteren 3D-Tisch an. Heinz hat am 17.11. gesagt, das bekannte Memory sei moderner – Übernahme nur nach seiner Sichtprüfung.
- Ziel: ein Memory, in echtem 3D mit dem Flutter-Look als Untergrenze. Status OFFEN.

### 4.4 Bauwelt und Dorf

- Godot `scripts/creative/build_world.gd` (Bauen), `build_settlement_world.gd` (Dorfwirtschaft).
- Integriert am 17.11.: Stream `lumo-2040/bauwelt` (Kampagnenkarte, Dorfverteidigung, HUD). 9 Bauwelt-/Dorf-Tests grün (lokal), u. a. `build_defense_regression` (162), `build_campaign_map_regression` (54), `build_village_economy_regression` (339 Prüfungen).
- Befund App: „Dorfwirtschaft" (`settlement`) steht nicht in der Belohnungsliste von `core/embedded_game_service.dart` – Ergebnisse werden in Flutter nicht gebucht.
- Ziel: Heinz' Punkte 5 und 11. Gelände mit Höhen (Hügel und Berge unbebaubar), große Karte, Kampagne, Freibau, sichtbar bauende KI-Städte. Heute ist das Gelände flach. Status OFFEN.

### 4.5 Schatzsuche, Rhythmus, Puzzle

- Godot `scripts/creative/treasure_world.gd`, `rhythm_world.gd`, `puzzle_world.gd`.
- Integriert am 17.11.: Stream `lumo-2040/kreativ` (Schatzsuche mit Karte/Kompass, Rhythmus-UI). 4 Schatzsuche- und 3 Rhythmus-Tests grün (lokal). Puzzle: NOT_RUN.

### 4.6 Jump‑and‑Run

- 3D: `scripts/games/jump_islands.gd` („Wolkeninseln", in der App nur unter „Zusätzliche Spielmodi").
- 2D: `lib/features/games/flame/lumo_jump_game.dart` („Lumos Jump Adventure 2D"), bucht Belohnung ohne Ergebnis-ID.
- Ziel: Heinz' Punkte 4 und 12. Das 2D-Spiel entspricht nicht dem Ziel; das 3D-Spiel ist ein kurzer Insel-Parcours, kein langer Lauf. Geplant: Lauf-Modus auf den vorhandenen langen Kart-Welten (Streckenbau, Landschaft und Lumo-Laufanimation sind vorhanden). Status OFFEN.

### 4.7 Weitere Spiele

| Spiel | Ort | Status |
|---|---|---|
| 4 Gewinnt | Flutter `connect_four/`, 3D `connect_four_table.gd` | NOT_RUN |
| Quiz „Wer wird Lumo-Meister?" | Flutter `features/quiz/`, 3D `quiz_studio.gd` | NOT_RUN |
| Würfel-Wettlauf | Flutter `dice_race/` | NOT_RUN; bucht Sterne und XP in zwei Schritten ohne ID |
| Sternenpfad | Flutter `star_trail/` | NOT_RUN; Doppelbuchung nur bildschirmlokal verhindert |
| 50-Level-Karte (5 Minispiele) | Flutter `mini_games/` | NOT_RUN |
| Sterne sammeln | Godot `star_collect_game.gd` | NOT_RUN |

## 5. Lernen, Tutor, Daten

### 5.1 Lerninhalte (Flutter)

Katalog in `core/school_exercise_generator.dart` mit Vorlagen in `math_task_templates.dart`, `german_task_templates.dart`, Sachunterricht und Englisch. Gezählte Generator-Einheiten je Klasse (Code-Inventur 17.11., per Suche gezählt, nicht fachlich geprüft):

| Fach | Kl. 1 | Kl. 2 | Kl. 3 | Kl. 4 |
|---|---|---|---|---|
| Mathematik | 13 | 14 | 13 | 16 |
| Deutsch | 8 | 8 | 8 | 8 |
| Sachunterricht | 9 | 9 | 11 | 6 |
| Englisch | 7 | 4 | 5 | 5 |
| Logik | 2 | 1 | 1 | 1 |

- Dünn: Logik ab Kl. 2, Englisch Kl. 2–4, Sachunterricht Kl. 4. Musik, Kunst, Technik, Sport haben keine Aufgaben.
- Fachliche Durchsicht (Heinz' Punkt 6): **durchgeführt am 17.11. am Code, nicht am Gerät**; Berichte in `docs/fachpruefung/`. Mathematik/Logik: 49 800 erzeugte Aufgaben, 43 800 unabhängig nachgerechnet, 0 falsche Lösungen; 65 Befunde im Umfeld der Aufgaben (12 schwer: u. a. richtige Antwort immer an zweitkleinster Stelle, Bilder verraten die Lösung, falsche Rechentricks bei Brüchen/Dezimalzahlen). Deutsch/Sachunterricht/Englisch: 84 Befunde (6 schwer: u. a. Reim-Ablenker, die selbst reimen; Endlaut „Hund → T“; Geschichten ohne Umlaute). Korrektur läuft (Pakete L4a Mathematik, L4b Deutsch/Sach/Englisch). Kein Abgleich mit dem amtlichen Lehrplantext; es wird keine Lehrplanabdeckung behauptet.
- Lücken laut Prüfung: Sachunterricht Kl. 2 (fünf Einheiten mit nur 1–5 eigenen Fragen), Englisch nur „Wort lesen → Bedeutung antippen“, Musik/Kunst/Technik/Sport ohne überprüfbare Aufgaben (je 8 offene Aktivitätskarten).
- 3D-Lernszene: Godot `scripts/learning/learning_world.gd`. Nachhilfe-Szene (Stream `lumo-2040/tutor-godot`, WIP ohne Test): Quelltext integriert (Merge `55c0135`), nur über einen Lern-Aufruf mit `kind: tutor` erreichbar; der Einstieg in der App bleibt verborgen. Status: NOT_RUN.

### 5.2 Lumo als Tutor, Sprache, Kamera

| Teil | Dateien | Stand |
|---|---|---|
| Gespräch lokal | `core/lumo_conversation_controller.dart`, `lumo_brain.dart` | lokal lauffähig; KI-Proxy nur bei `aiProxyEnabled` |
| Sprachausgabe | `core/lumo_voice.dart`, Offline-Stimme nach Elternfreigabe | Cloud-Stimme im Code vorhanden, aber fest abgeschaltet |
| Spracherkennung | `core/lumo_speech_listener.dart` (auf dem Gerät) | Mikrofon standardmäßig aus |
| Kamera / OCR | `widgets/scan_screen.dart`, `features/photo_lesson/` | standardmäßig aus, Auswertung lokal |
| Bilder vom KI-Lehrer | `core/lumo_image_generator.dart` | **sendet bei aktivem KI-Modus an einen Drittanbieter (pollinations.ai)** – gehört vor Freigabe in den Elternbereich erklärt oder entfernt |

Abnahme laut Auftrag (Begrüßung → Aufgabe → falsche Antwort → Hinweis → Unterbrechung → andere Erklärung → Fortschritt): NOT_RUN.

### 5.3 Fortschritt und Belohnungen

- Wallet `core/reward_wallet_repository.dart`, Schlüssel `lumo_reward_wallet_v1`, serialisierte Schreibfolge, Ergebnis-IDs gegen Doppelbuchung bei Godot-Spielen, Memory, Cards, Quiz.
- Lücken: Wallet global statt je Kind; Lernaufgaben, 2D-Jump, Würfel, Sternenpfad, LIVE, Geschichte, Schreiben und IQ buchen ohne Ergebnis-ID.

## 6. Integration (Abschnitt 5 des Auftrags)

Grundlage ist Groks Inventur `docs/handover/BRANCH-INVENTUR-20261117.md` (784 Branches: 321 enthalten, 25 gemergt, 300 nicht gemergt mit Grund, 137 ersetzt). Darauf aufbauend:

| Entwicklung | Einordnung | Stand |
|---|---|---|
| Godot `lumo-2040/memory-godot` @ `e10b74f` | jetzt integriert | Merge `90f0c4e` |
| Godot `lumo-2040/kreativ` @ `27265b1` | jetzt integriert | Merge `f6a2b44` |
| Godot `lumo-2040/bauwelt` @ `e47f05a` | jetzt integriert | Merge `6005586` |
| Godot `lumo-2040/tutor-godot` @ `24bcb48` | jetzt integriert, bewusst experimentell (WIP ohne Test, in der App nicht erreichbar) | Merge `55c0135` |
| Godot `lumo-2040/kart` @ `f957466` | jetzt integriert | Merge `a1587ff` |
| Godot `lumo-kart/menu-strecken` @ `b5956d3` | jetzt integriert; 2 Konflikte gelöst (`kart_world.gd` beide Seiten, `kart_neon_layout.gd` neue Fassung) | Merge `9f5e30b` |
| Godot `lumo-kart/gameplay-items` @ `17b63b4` | blockiert: zweites Item-System neben dem vorhandenen, siehe 4.1 | Merge abgebrochen, nichts übernommen |
| App `lumo-2040/memory` @ `e5dbe5ca` | teilweise übernommen: nur Fix `b93aef5b`, Optik-Commit `5a79c14c` nicht | Cherry-Pick auf dem Arbeitsbranch |
| App `lumo-2040/tutor` @ `58549eae` | WIP, Einstieg verborgen | offen |
| App `delivery/lumo-2037-memory-werkstatt` @ `e2a8e9fe` | 11 Commits nicht im Nullpunkt | offen, prüfen |
| Godot-Pin in `config/godot-source.json` | umgestellt auf `a363de2` (Importabsturz behoben; Godot-CI auf `2e1aed6` vollständig grün, auf `a363de2` noch offen) | Commit `b39d8ec9` |

Die unveränderten Testberichte der Streams liegen im Godot-Repo unter `docs/integration-2/`.

## 7. Technik und Abnahme

| Punkt | Status |
|---|---|
| Godot-Import ohne Fehler | PASS (lokal), 17.11. |
| Vollständige Godot-Testsuite (ca. 350 Skripte) | NOT_RUN |
| `flutter analyze` | PASS (lokal), 0 Fehler |
| `flutter test` vollständig | NOT_RUN |
| Gemeinsame APK (Flutter + Godot) | GEBAUT und signiert (CI, nicht auf einem Gerät geprüft): Lauf 4 von `lumo-test-apk.yml` (44207725478) auf `287bc29c`, Version 0.13.27+2039, Godot `2b1fd30`, nur ARM64, rund 539 MB. Download als Entwurf-Release „Lumo Test-APK 0.13.27+2039 (Entwurf)“ (GitHub verweigert dem Lauf-Token eine öffentliche Vorabversion, HTTP 403) oder als Actions-Artefakt `LUMO-TEST-APK-44207725478`. Vorher: Läufe 1–2 Godot-Importabsturz (Ursache behoben in Godot `a363de2`), Lauf 3 gebaut (0.13.26+2038, 588 MB Universal). Offen: Größe (Spielpaket allein 282 MB), Installation und Bedienung auf dem Gerät |
| App-Skripttests (`scripts/tests`, 1006 Tests) | PASS in CI auf `0315c801` (`full-app-script-regression`); lokal 1005 PASS, 1 nur mit Android-SDK lauffähig |
| Android-Emulator, echtes Gerät, Fold | NOT_RUN |
| Framezeiten, Speicher, Akku | NOT_RUN |

Keine Signierung, keine Veröffentlichung, kein Merge nach `main` ohne Heinz.
