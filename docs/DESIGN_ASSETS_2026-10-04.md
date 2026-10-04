# Lumo: benötigte Einzelbilder für das Design (Heinz erstellt sie in ChatGPT)

Ergänzung zu `DESIGN_ZIEL_2026-10-04.md`. Heinz erzeugt diese Bilder einzeln. Claude legt sie
unter `assets/lumo_design/` ab, Copilot verdrahtet sie. **Dateinamen exakt so verwenden.**
Bis eine Datei vorhanden ist, bleibt ein gekennzeichneter Platzhalter.

## Stand 4. Oktober (geprüft von Claude)
- **Vorhanden:** alle 10 Fuchs-Posen, alle 8 Hintergründe (`bg_games` und `bg_kart` sind fast identisch mit `bg_home`, eigene Motive fehlen noch), beide Logos, Kartenbilder `deutsch_hund`, `game_kart`, `game_memory`, `kart_freunde`, `test_rechnen`, `kart_track`.
- **Echte 3D-Symbole vorhanden (Heinz, 4.10.):** `icons/book_open`, `treasure_chest`, `star_gold`, `trophy_gold`, `gamepad`, `crown`, neu `icons/crystal` (Kristall, z. B. Denk-Abenteuer), `badges/badge_sterne` (Sternmedaille), neu `badges/badge_schild` (Sternschild).
- **Noch fehlend (die gelieferten Dateien waren Platzhalter):** (außer den oben genannten echten) alle `icons/*`, `badges/*`, `rewards/*` (farbige Quadrate mit Wörtern wie „BOOK“ statt 3D-Symbolen) sowie `cards/game_cards`, `game_wortjagd`, `game_zahlenblitz`, `kart_garage`, `kart_missionen`, `kart_strecken` (Hintergrund-Ausschnitte mit Text). Bis echte Bilder kommen, Material-Icons bzw. Farbverlauf als Platzhalter verwenden, keine Text-Platzhalterbilder.

Gemeinsamer Stil (in jeden Prompt): *3D-Render im Pixar-Stil, hochwertig, weiches Licht,
nächtliche Fantasy-Welt in Dunkelblau mit Cyan-Leuchtakzenten, kindgerecht, gleiche Figur in
allen Bildern.*

Lumo (immer gleich): *junger Fuchs, oranges Fell, weißer Bauch und weiße Schweifspitze, große
braune Augen, blaue Fliegerbrille auf der Stirn, dunkelblaue Rennjacke mit orange-weißen Streifen
und leuchtend cyanfarbenem „L“ auf der Brust, schwarze Handschuhe.*

## A. Fuchs-Posen: PNG mit transparentem Hintergrund, 1024×1024, ganze Figur, kein Text
| Datei | Pose | Verwendet in |
|---|---|---|
| `fox/fox_kart_wave.png` | sitzt im blau-weißen Kart mit Leuchtfelgen und „L“, winkt mit einer Hand, Blick zum Betrachter | 01, 09, 10 |
| `fox/fox_tablet_thumb.png` | steht, hält leuchtendes Tablet, Daumen hoch | 03 |
| `fox/fox_book_point.png` | Oberkörper hinter aufgeschlagenem Buch, Zeigefinger nach oben, Tablet in der Hand | 02 |
| `fox/fox_point_side.png` | Oberkörper, zeigt mit Finger zur Seite, Rucksack | 04 |
| `fox/fox_trophy_wink.png` | zwinkert, Daumen hoch, hält goldenen Sternpokal | 05 |
| `fox/fox_arms_open.png` | ganze Figur, Arme weit offen, begrüßend | 06 |
| `fox/fox_thumb_wink.png` | Oberkörper, zwinkert, Daumen hoch | 01, 04, 07 |
| `fox/fox_teacher_stick.png` | Oberkörper, hält Zeigestab, erklärt | 02 (Hilfe) |
| `fox/fox_cheer.png` | Oberkörper, beide Hände jubelnd erhoben, kleine Sterne | 03 (Banner) |
| `fox/fox_avatar.png` | nur Kopf und Schultern, freundlich, für rundes Profilbild, 512×512 | Kopfzeile, 07 |

## B. Hintergründe: PNG ohne Text, ohne Figur, ohne Bedienelemente
Hochformat 1080×1920 (Handy), dazu `bg_wide.png` 2400×1600 (Tablet/Fold).
| Datei | Motiv |
|---|---|
| `bg/bg_home.png` | Nachthimmel mit Sternen, schwebende Inseln mit Wasserfällen, futuristische Stadt, geschwungene Rennstrecke mit leuchtenden Cyan- und Gelb-Pfeilen, Tor mit „LUMO“-Schild erlaubt; untere Hälfte ruhig/dunkler für Karten |
| `bg/bg_learn.png` | wie oben, rechts Turm mit Schriftzug „WISSEN MACHT MUT“, links Bücherstapel |
| `bg/bg_library.png` | nächtliche Bibliothek mit Bücherregalen, Schreibtischlampe, Blick auf schwebende Inseln (Mathe-Aufgabe und Deutsch) |
| `bg/bg_tests.png` | leuchtende Arena „LUMO TESTS“ mit Stern über dem Eingang, Rennstrecke davor |
| `bg/bg_games.png` | Spielewelt: Schilder „SPIELEWELT“ und „SPIELEN“, Inseln, Rennbahn |
| `bg/bg_profile.png` | Sternenhimmel mit Inseln und Tor „LUMO“, ruhig |
| `bg/bg_kart.png` | Kart-Welt: Tor „LUMO KART“ mit Zielflaggen, Zeppelin, Wasserfall-Klippen, Pokal auf Insel |
| `bg/bg_wide.png` | Querformat von `bg_home.png` |

## C. Logos: PNG transparent
| Datei | Inhalt |
|---|---|
| `logo/logo_lumo.png` | Schriftzug „LUMO“, weiß mit Cyan-Leuchten, Stern im O, 1200×400 |
| `logo/logo_lumo_kart.png` | „Lumo KART“ kursiv, weiß/cyan, Zielflaggen-Muster, 1200×600 |

## D. Symbole: PNG transparent, 512×512, 3D, glänzend, ohne Text
`icons/`: `book_open.png` (oranges Buch), `gamepad.png` (violett), `clipboard_check.png` (türkis), `star_gold.png`,
`math_symbols.png` (+ − × ÷ gelb), `book_purple.png`, `books_green.png`, `pencil_pink.png`, `speech_hi.png` (Sprechblase „Hi!“ – Text erlaubt),
`globe.png`, `abc_blocks.png`, `microphone.png`, `document_pencil.png`, `flask.png`, `palette.png`, `music_notes.png`,
`calculator.png`, `lightbulb.png`, `apple_red.png`, `flame.png`, `gift_box.png`, `treasure_chest.png`, `target.png`,
`trophy_gold.png`, `trophy_silver.png`, `trophy_bronze.png`, `crown.png`, `flag_checkered.png`, `wrench.png`,
`ticket_star.png`, `tshirt.png`, `lightning.png`.

Abzeichen (Sechseck, glänzend): `badges/badge_lernprofi.png` (blau, Doktorhut), `badge_spieler.png` (violett, Controller),
`badge_tueftler.png` (grün, Haken), `badge_sterne.png` (gold, Stern), `badge_locked.png` (grau, Schloss).

Belohnungen: `rewards/reward_kart.png`, `reward_backpack.png` (Rucksack mit „L“), `reward_robot.png` (weißer Roboter „Lumo Bot“),
`reward_island.png` (Himmelsinsel mit Wasserfall), `reward_trophy.png`.

## E. Kartenbilder: PNG, Querformat 800×500, ohne Text
`cards/`: `kart_track.png` (Rennstrecke an Klippen mit Wasserfall, Tag), `game_memory.png` (Lumo mit Memory-Karten mit Pfote),
`game_cards.png` (schwebende Wissenskarten: Planet, Blatt, Hund), `game_wortjagd.png` (Holzklötze A B C im Dschungel),
`game_zahlenblitz.png` (leuchtende Zahlen 1 2 3 auf Podest), `game_kart.png` (Lumo im Kart, Neon-Strecke),
`kart_strecken.png`, `kart_garage.png` (Kart in Werkstatt mit Schraubenschlüssel), `kart_missionen.png` (Klemmbrett mit Stern),
`kart_freunde.png` (Lumo und grauer Wolf-Freund klatschen ab), `test_rechnen.png` („7+3“ leuchtend – Text erlaubt),
`deutsch_hund.png` (Hund spielt mit rotem Ball auf Wiese).
