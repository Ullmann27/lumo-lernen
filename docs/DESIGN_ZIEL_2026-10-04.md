# Lumo: verbindliches App-Design nach Heinz' Vorlagen (4. Oktober 2026)

**Auftrag von Heinz:** Die komplette App soll genau so aussehen wie die elf Bilder in
`docs/design_targets/2026-10-04/`. Keine Abweichung. Copilot (GPT-6 Luna) setzt um,
Claude koordiniert, prüft jede Etappe gegen die Bilder und gibt Folgeanweisungen.
Gearbeitet wird so lange, bis jeder Bildschirm abgenommen ist.

Diese Bilder **gehen vor** älteren Designvorgaben, auch vor der Shell-Regel in
`CLAUDE.md` (linke Navigation und rechte Lumo-Bühne). Heinz hat das neue Layout
ausdrücklich so vorgegeben: auf dem Handy eine untere Leiste, auf dem Tablet/Fold
eine linke Leiste mit rechter Fortschrittsspalte (Bild 10).

Die zwölf ChatGPT-Bilder aus `docs/COPILOT_GRAFIK_2026-10-04.md` bleiben Ziel für die
**Godot-Kart-Welten** (Garage, Fahrerauswahl, Strecken). Für **alle Flutter-Bildschirme**
gelten die Bilder hier. Wo sich beide widersprechen (Farben, Fuchs-Outfit), gilt dieses Dokument.

## 1. Die elf Vorlagen

| Datei | Bildschirm | Flutter-Einstieg (Stand ed2450f) |
|---|---|---|
| `01_start_home.png` | Start (Handy) | `lib/features/home/home_content.dart`, `lib/app/app_shell.dart` |
| `02_lernen_mathe_aufgabe.png` | Mathe-Aufgabe mit Hilfe | `lib/features/learning_modules/plus_bis_10/…` und `lib/features/learning/learning_content.dart` |
| `03_lernen_uebersicht.png` | Lernen: Klasse + 6 Fächer | `lib/features/teacher_mode/lumo_akademie_screen.dart`, `subject_selection_content.dart` |
| `04_deutsch_lesen.png` | Deutsch: Lückensatz + 4 Bereiche | `lib/features/reading/**`, Deutsch-Module |
| `05_tests.png` | Tests | Test-/Schularbeit-Bereich (vorhandene Test-Route) |
| `06_spielewelt.png` | Spielewelt | `lib/features/games/games_content.dart` |
| `07_profil.png` | Profil | Profil-/Belohnungsbereich (`lib/features/rewards/**`) |
| `08_kart_rennen_hud.png` | Kart-Rennen mit Lern-Challenge | Godot-Kart (`lumo-godot`), HUD dort |
| `09_kart_menue.png` | Kart-Hauptmenü | Flutter-Einstieg vor dem Godot-Start (`games_content.dart`, `lumo3d_launcher.dart`) |
| `10_fold_tablet_home.png` | Start auf Tablet/Fold (breit) | `app_shell.dart` Breit-Layout |
| `11_zukunft_funktionen.png` | 10 spätere Funktionen | **Nicht jetzt bauen.** Erst nach Abnahme von 01–10. |

## 2. Gemeinsames Design-System (gilt für jeden Bildschirm)

Gemessene Farben aus `01_start_home.png` (Pixelproben, ±5 % Toleranz):

| Rolle | Farbe |
|---|---|
| Hintergrund dunkel (Nachthimmel) | `#03193F` |
| Glas-Karte Füllung | `#063556`, halbtransparent, darunter die Szene leicht sichtbar |
| Zeile in Glas-Karte | `#1F3F6C` |
| Untere Navigation | `#061839` |
| Aktiv / Cyan-Leuchten / XP-Balken | `#37D2FD` bzw. `#53DDFD` |
| Kachel Lernen (orange) | `#D67920` |
| Kachel Spielen (violett) | `#5F2FBE` |
| Kachel Tests (petrol) | `#167A84` |
| Kachel Belohnungen (magenta) | `#B52E73` |
| Sterne / Pokale | Gold, warm glänzend |

Bausteine, die auf **allen** Bildschirmen gleich aussehen müssen:

1. **Hintergrund:** Vollflächige gemalte Nachtszene (schwebende Inseln, Stadt, Rennstrecke mit Leuchtpfeilen, Sterne). Kein flacher Farbverlauf. Pro Bereich eigenes Motiv (Bibliothek bei Lernen/Deutsch, Pokal-Arena bei Tests, Spielewelt bei Spielen).
2. **Kopfzeile:** Links Schriftzug **LUMO** (weiß, leuchtend, Stern im O) mit Unterzeile „Lernen. Spielen. Weiterkommen.“ in Cyan. Rechts Glas-Pille: rundes Fuchs-Avatar mit Cyan-Ring, „Level N“, Klasse, Stern + Sternzahl, XP-Balken „X / Y XP“, Pfeil.
3. **Fuchs Lumo:** Großer gerenderter 3D-Fuchs (Pixar-Stil) im oberen Drittel: oranges Fell, weißer Bauch/Schweifspitze, **Fliegerbrille auf der Stirn**, **dunkelblaue Rennjacke mit leuchtendem „L“**, Handschuhe. Pose je Bildschirm wie im Bild (Kart fahren, Daumen hoch, mit Tablet, mit Pokal, Arme offen, zwinkernd). Kein Emoji, kein flacher Sticker.
4. **Sprechblasen:** Glas-Blasen mit Cyan-Rand. Links handschriftliche Botschaft des Fuchses, rechts schräg gestellt „Kleine Schritte Große Zukunft! ♡“. Texte wie im Bild.
5. **Glas-Karten:** Abgerundet (ca. 24 px), dunkelblau halbtransparent, dünner Cyan-Leuchtrand, weiße Schrift.
6. **Farbkacheln:** Vier Kacheln mit Verlauf, 3D-Symbol oben (Buch, Controller, Klemmbrett, Stern), Titel fett, Unterzeile, runder Pfeil-Button unten rechts.
7. **Untere Navigation (Handy):** 5 Einträge **Start · Lernen · Spielen · Tests · Profil**, aktiver Eintrag Cyan leuchtend, Rest grau-blau.
8. **Tablet/Fold (Bild 10):** Linke Leiste Start/Lernen/Spielen/Tests/Belohnungen/Profil, Mitte wie Handy-Start, rechts Spalte „Dein Lernfortschritt“ (4 Fortschrittsringe), Tägliche Aufgaben, Deine Belohnungen.
9. **Schrift:** Rund und fett (wie Nunito Black) für Titel, normale Stärke für Unterzeilen. Handschrift-Stil nur in Sprechblasen.

## 2b. Die App lebt (Heinz: „die Balken leben, Lumo lebt, die ganze App lebt“)

Pflicht für jeden Bildschirm, nicht optional:

1. **Begrüßung beim App-Start (ca. 2 s, antippen überspringt):** Nachthimmel blendet ein, Sterne funkeln auf, der LUMO-Schriftzug leuchtet mit kurzem Schimmer auf. `fox_kart_wave` fährt von rechts ins Bild und winkt. Die Sprechblase ploppt auf mit „Hallo {Name}! Bereit für ein neues Abenteuer?“ (echter Name, Stimme spricht den Satz, wenn die Stimme an ist). Danach gleiten Kopfzeile von oben und untere Navigation von unten herein, die Kacheln erscheinen gestaffelt (je 60 ms, von unten mit leichtem Hochfedern).
2. **Fuchs:** Bewegt sich immer leicht, kein Standbild. Atmen (Skalierung 1,00 ↔ 1,02, ca. 2,5 s), sanftes Schweben (±4 px), kleiner Wipp-Ausschlag. Beim Bildschirmwechsel ein kurzes Einblenden der passenden Pose. Bei richtiger Antwort springt er kurz (Squash & Stretch), bei falscher neigt er tröstend den Kopf.
3. **Balken und Zahlen:** XP-, Fortschritts- und Segmentbalken füllen sich animiert vom alten auf den neuen Wert (ca. 900 ms, easeOutCubic), mit einem wandernden Glanzlicht. Sterne- und XP-Zahlen zählen hoch. Fortschrittsringe zeichnen sich im Uhrzeigersinn.
4. **Navigation:** Der aktive Eintrag hat einen leuchtenden Cyan-Hintergrund, der beim Wechsel weich zum neuen Eintrag gleitet. Das Symbol hüpft kurz. Seitenwechsel als Überblendung mit leichtem Schieben, kein harter Schnitt.
5. **Hintergrund:** Funkelnde Sterne, langsam ziehende Wolken, schwebende Inseln mit leichter Bewegung (Parallax beim Scrollen), über die Rennstrecke laufende Leuchtpfeile.
6. **Bedienelemente:** Jede Kachel und jeder Knopf federt beim Antippen (Skalierung 0,96 → 1,0), Glas-Karten haben einen langsam wandernden Glanzrand, „Neu!“-Abzeichen pulsieren, Sprechblasen ploppen auf.
7. **Erfolg:** Bei richtiger Antwort und Belohnung Sternregen beziehungsweise Konfetti und ein „+10 XP“, das zur XP-Pille fliegt.
8. **Grenzen:** 60 FPS anstreben, `RepaintBoundary` um Dauer-Animationen, alle Controller sauber entsorgen. Die vorhandene Einstellung „Animationen reduzieren“ schaltet Dauer-Animationen ab (nur kurze Übergänge bleiben). Animationen dürfen nie Antworten verdecken oder das Antippen verzögern.

## 3. Pro Bildschirm: Abnahmepunkte

**01 Start:** Kopfzeile · Fuchs im Kart mit Strecke · Blase „Hallo! Bereit für ein neues Abenteuer?“ · Banner „Lumo Kart – Lernen auf der Überholspur!“ mit Bild und „Neu!“ · 4 Kacheln Lernen/Spielen/Tests/Belohnungen · „Tägliche Aufgaben“ mit 3 Zeilen, Haken und „+XP“ · Motivationskarte „Du kannst das!“ mit zwinkerndem Fuchs · Navigation.

**02 Mathe-Aufgabe:** Glas-Karte „Mathe-Abenteuer“ mit Rechner-Symbol · „Aufgabe N / M“ mit Segment-Fortschritt · „+10 XP“-Pille · große Rechnung · „Wähle die richtige Antwort aus.“ · Hilfe-Karte mit Äpfeln (linke Menge + rechte Menge = ?) und Lehrer-Fuchs mit Zeigestab · 4 große Antwortknöpfe in einer Reihe · „Tipp“ links, grüner „Weiter“-Knopf rechts.

**03 Lernen:** Titel „Lernen“ + „Heute lernen. Morgen mehr können!“ · Karte „Deine Ziele“ · Klassen-Pillen 1.–4. Klasse · 6 Fach-Kacheln (Mathe, Deutsch, Lesen, Schreiben, Englisch, Sachkunde) mit Fortschrittsring %, Sternzahl, „X / Y XP“ · Banner „Super gemacht!“ mit „Weiter geht's!“.

**04 Deutsch:** Karte mit Lautsprecher, Bild, „Satz 1 von 5“, Lückensatz, 4 Wort-Knöpfe, „+10 XP“ · 4 Kacheln Lesen/Wörter/Diktat/Schreibcoach · Tägliche Aufgaben · Motivationskarte.

**05 Tests:** Fuchs mit Pokal vor „LUMO TESTS“ · „Kategorie wählen“ (5 Kacheln) · Schwierigkeit Leicht/Mittel/Schwer (Sterne) · Test-Karte mit Fragen/Dauer/XP und „Starten“ · „Letztes Ergebnis“ mit Pokal, „Bestleistung“, „Wiederholen“.

**06 Spielewelt:** Titel „Lumo Spielewelt“ · 4 Spielkarten 2×2 (Memory, Lumo Cards, Wortjagd, Zahlenblitz) mit Bild, Sternen, „Spielen“ · breite Lumo-Kart-Karte unten.

**07 Profil:** „Du machst das großartig!“ · Profil-Karte mit Avatar, Level, Titel, Sterne, XP, „Profil bearbeiten“ · 5 Abzeichen (Sechsecke) mit Fortschritt · „Lernserie N Tage“ mit Flammen · „Nächstes Ziel“ mit Geschenk · „Meine Belohnungen“ (5 Gegenstände) · „Extras freischalten“, „Dein Avatar“.

**08 Kart-Rennen (Godot):** Platz „1/6“, Runde, Sterne, Pause oben · Tacho, Turbo-Knopf rechts, Minimap links · unten Glas-Karte „Lern-Challenge!“ mit Timer, Frage, 4 Antworten, „Richtig = Turbo!“.

**09 Kart-Menü:** „Lumo KART“-Logo · Fuchs im Kart · gelber Knopf „Rennen – Jetzt starten!“ · 4 Karten Strecken/Garage/Missionen/Freunde · „Deine Erfolge“ (Gold/Silber/Bronze) · „Kart-Level“ mit „Upgrades“.

**10 Fold/Tablet:** siehe Abschnitt 2, Punkt 8.

## 4. Regeln

- **Daten bleiben echt.** Die Zahlen in den Bildern (12 Sterne, 120/300 XP, 75 %, „9/10“, „Emma“, Datum) sind Beispiele. Angezeigt wird der echte Spielstand. Nichts davon fest einprogrammieren.
- **Funktionen bleiben erhalten:** Lernmodule, Antwortprüfung, Belohnungen, Speicherstände, PIN-freie Navigation, Kart-Start, QA-Tests. Ein Bildschirm, der schön aussieht, aber eine Funktion verliert, ist nicht abgenommen.
- **Fuchs und Hintergründe sind Bild-Assets** (PNG/WebP mit Transparenz für den Fuchs), keine Emojis und keine Code-Zeichnungen. Fehlen saubere Einzel-Assets, die Figur zunächst aus den Vorlagen freistellen und als Platzhalter kennzeichnen, und das einmal im PR melden. Claude fragt dann Heinz nach den Originaldateien.
- **Funktionen ohne Gegenstück** (z. B. „Freunde“, „Garage-Upgrades“, Abzeichen-Logik) bekommen die Optik aus dem Bild und einen ehrlichen Zustand („Bald verfügbar“), keine erfundenen Werte.
- **Bild 11 nicht jetzt bauen.**
- Bestehende Regeln aus `.github/copilot-instructions.md` gelten weiter: kein Force-Push, kein automatischer Merge oder Release, keine unbelegten Erfolgsmeldungen.

## 5. Reihenfolge und Abnahme

Ein PR pro Etappe, gestapelt auf `codex/lumo-unified-android-2026-10-03`:

1. **Design-System:** Farben/Tokens, Hintergründe, Glas-Karte, Farbkachel, Kopfzeile mit Level-Pille, Sprechblasen, untere Navigation (5 Einträge), Fuchs-Asset-Widget mit Posen.
2. **Start (01) + Fold (10).**
3. **Lernen (03) + Mathe-Aufgabe (02).**
4. **Deutsch (04) + Tests (05).**
5. **Spielewelt (06) + Kart-Menü (09).**
6. **Profil (07).**
7. **Kart-Rennen-HUD (08)** im Godot-Repo.

Jede Etappe enthält auch die Animationen aus Abschnitt 2b für ihre Bildschirme.

Jeder PR muss enthalten:
- **Echte Screenshots** des laufenden Bildschirms (Handy 1080×1920 bzw. 941×1672-Verhältnis, bei Etappe 2 zusätzlich breit) **nebeneinander mit der Vorlage**.
- Eine Liste aller Abweichungen, die noch bestehen.
- Grüne Flutter-Tests (`flutter test`) und `flutter analyze` ohne neue Fehler.

Claude prüft jede Etappe Punkt für Punkt gegen Abschnitt 3 und schreibt die Folgeanweisung in den PR.
