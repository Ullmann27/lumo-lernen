# Prüfmatrix Lernmodule (maschinell erzeugt)

Erzeugt von `test/qa/lernmodul_pruefmatrix_test.dart` aus der echten Oberfläche (Akademie, Tests, Schularbeit) und den Katalogen. Nicht von Hand bearbeiten; neu erzeugen mit `LUMO_UPDATE_PRUEFMATRIX=1 flutter test test/qa/lernmodul_pruefmatrix_test.dart`. Bewertung und Lehrplanbezug: `docs/qa/LERNMODUL_PRUEFBERICHT_2026-11-26.md`.

Generator-Kacheln: je 120 Aufgaben über `ExerciseFactory.nextExact`, geprüft auf Fach, Klasse, Rubrik und `TaskQualityGuard`. „Varianten“ = verschiedene Aufgaben (Text + Lösung) unter 120.

„Ebene“: Schulwissen, Vertiefung oder Lumo Expertenwelt (`lib/core/curriculum/learning_level.dart`). Tests und Schularbeiten ziehen nie aus der Expertenwelt; bei Tests und Schularbeit-Karten stehen die tatsächlich gezogenen Ebenen.

| Bereich | Zeilen |
|---|---|
| Lernhub | 260 |
| Lernatelier | 35 |
| Tests | 74 |
| Schularbeit | 6 |
| Akademie-Thema | 85 |
| Lernspiel | 50 |

| Bereich | Klasse | Fach | Rubrik | Kachel | Oeffnet | Datenquelle | Aufgabenfach | Varianten | Schwierigkeit | Befund | Ebene |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Lernhub | 1 | Mathematik | Mengenvergleich | learning-unit-Mathematik-Mengenvergleich | ZahlenBis10Screen | eigenes Lernmodul | – | – | 1 | ok | Schulwissen |
| Lernhub | 1 | Mathematik | Zahl in Worten | learning-unit-Mathematik-Zahl in Worten | Übung Mathematik/Zahl in Worten | MathTaskTemplates g1_number_word | Mathematik | 21 | 1 | ok | Schulwissen |
| Lernhub | 1 | Mathematik | Zahlenstrahl | learning-unit-Mathematik-Zahlenstrahl | Übung Mathematik/Zahlenstrahl | MathTaskTemplates g1_number_line | Mathematik | 70 | 1 | ok | Schulwissen |
| Lernhub | 1 | Mathematik | Größer, kleiner, gleich | learning-unit-Mathematik-Größer, kleiner, gleich | Übung Mathematik/Größer, kleiner, gleich | LumoAdventureTasks (abenteuer-Größer, kleiner, gleich) | Mathematik | 112 | 1 | ok | Schulwissen |
| Lernhub | 1 | Mathematik | Plus bis 10 | learning-unit-Mathematik-Plus bis 10 | PlusBis10Screen | eigenes Lernmodul | – | – | 1 | ok | Schulwissen |
| Lernhub | 1 | Mathematik | Minus bis 10 | learning-unit-Mathematik-Minus bis 10 | MinusBis10Screen | eigenes Lernmodul | – | – | 1 | ok | Schulwissen |
| Lernhub | 1 | Mathematik | Plus bis 20 | learning-unit-Mathematik-Plus bis 20 | Übung Mathematik/Plus bis 20 | MathTaskTemplates g1_add_20 | Mathematik | 69 | 1 | ok | Schulwissen |
| Lernhub | 1 | Mathematik | Minus bis 20 | learning-unit-Mathematik-Minus bis 20 | Übung Mathematik/Minus bis 20 | MathTaskTemplates g1_sub_20 | Mathematik | 65 | 1 | ok | Schulwissen |
| Lernhub | 1 | Mathematik | Zahlenmauer | learning-unit-Mathematik-Zahlenmauer | Übung Mathematik/Zahlenmauer | LumoAdventureTasks (abenteuer-Zahlenmauer) | Mathematik | 113 | 1 | ok | Vertiefung |
| Lernhub | 1 | Mathematik | Geld | learning-unit-Mathematik-Geld | Übung Mathematik/Geld | MathTaskTemplates g1_money_more | Mathematik | 115 | 1 | ok | Schulwissen |
| Lernhub | 1 | Mathematik | Marktstand | learning-unit-Mathematik-Marktstand | Übung Mathematik/Marktstand | LumoAdventureTasks (abenteuer-Marktstand) | Mathematik | 120 | 1 | ok | Schulwissen |
| Lernhub | 1 | Mathematik | Zeit | learning-unit-Mathematik-Zeit | Übung Mathematik/Zeit | MathTaskTemplates g1_day_hours | Mathematik | 24 | 1 | ok | Schulwissen |
| Lernhub | 1 | Mathematik | Geometrie Formen | learning-unit-Mathematik-Geometrie Formen | FormenScreen | eigenes Lernmodul | – | – | 1 | ok | Schulwissen |
| Lernhub | 1 | Mathematik | Formen Nachzeichnen | learning-unit-Mathematik-Formen Nachzeichnen | Übung Mathematik/Formen Nachzeichnen | MathTaskTemplates g1_trace_square+g1_trace_circle+g1_trace_triangle | Mathematik | 3 | 1 | ok | Schulwissen |
| Lernhub | 1 | Mathematik | Symmetrie | learning-unit-Mathematik-Symmetrie | Übung Mathematik/Symmetrie | MathTaskTemplates g1_symmetry | Mathematik | 30 | 1 | ok | Schulwissen |
| Lernhub | 1 | Mathematik | Textaufgaben | learning-unit-Mathematik-Textaufgaben | Übung Mathematik/Textaufgaben | MathTaskTemplates g1_word_problem | Mathematik | 109 | 1 | ok | Schulwissen |
| Lernhub | 1 | Mathematik | Rechengeschichten | learning-unit-Mathematik-Rechengeschichten | Übung Mathematik/Rechengeschichten | LumoAdventureTasks (abenteuer-Rechengeschichten) | Mathematik | 120 | 1 | ok | Schulwissen |
| Lernhub | 1 | Mathematik | Platzhalter-Rätsel | learning-unit-Mathematik-Platzhalter-Rätsel | Übung Mathematik/Platzhalter-Rätsel | LumoAdventureTasks (abenteuer-Platzhalter-Rätsel) | Mathematik | 95 | 1 | ok | Vertiefung |
| Lernhub | 1 | Mathematik | Zahlenrätsel | learning-unit-Mathematik-Zahlenrätsel | Übung Mathematik/Zahlenrätsel | LumoAdventureTasks (abenteuer-Zahlenrätsel) | Mathematik | 116 | 1 | ok | Vertiefung |
| Lernhub | 1 | Deutsch | Buchstaben-Lautierung | learning-unit-Deutsch-Buchstaben-Lautierung | Übung Deutsch/Buchstaben-Lautierung | GermanTaskTemplates g1_letter_sound | Deutsch | 16 | 1 | ok | Schulwissen |
| Lernhub | 1 | Deutsch | Reime | learning-unit-Deutsch-Reime | Übung Deutsch/Reime | GermanTaskTemplates g1_rhyme | Deutsch | 57 | 1 | ok | Schulwissen |
| Lernhub | 1 | Deutsch | Anfangslaute | learning-unit-Deutsch-Anfangslaute | Übung Deutsch/Anfangslaute | GermanTaskTemplates g1_start_sound | Deutsch | 36 | 1 | ok | Schulwissen |
| Lernhub | 1 | Deutsch | Endlaute | learning-unit-Deutsch-Endlaute | Übung Deutsch/Endlaute | GermanTaskTemplates g1_end_sound | Deutsch | 20 | 1 | ok | Schulwissen |
| Lernhub | 1 | Deutsch | Wort-Bild-Zuordnung | learning-unit-Deutsch-Wort-Bild-Zuordnung | Übung Deutsch/Wort-Bild-Zuordnung | GermanTaskTemplates g1_word_image | Deutsch | 20 | 1 | ok | Schulwissen |
| Lernhub | 1 | Deutsch | Erste Sätze | learning-unit-Deutsch-Erste Sätze | Übung Deutsch/Erste Sätze | GermanTaskTemplates g1_sentence_order+g1_sentence_build+g1_sentence_read | Deutsch | 27 | 1 | ok | Schulwissen |
| Lernhub | 1 | Deutsch | Silben | learning-unit-Deutsch-Silben | Übung Deutsch/Silben | GermanTaskTemplates g1_syllables+g1_syllables_clap | Deutsch | 53 | 1 | ok | Schulwissen |
| Lernhub | 1 | Deutsch | Artikel | learning-unit-Deutsch-Artikel | Übung Deutsch/Artikel | GermanTaskTemplates g1_articles | Deutsch | 63 | 1 | ok | Schulwissen |
| Lernhub | 1 | Deutsch | Wortdetektiv | learning-unit-Deutsch-Wortdetektiv | Übung Deutsch/Wortdetektiv | LumoAdventureTasks (abenteuer-Wortdetektiv) | Deutsch | 16 | 1 | ok | Schulwissen |
| Lernhub | 1 | Deutsch | Silbenrätsel | learning-unit-Deutsch-Silbenrätsel | Übung Deutsch/Silbenrätsel | LumoAdventureTasks (abenteuer-Silbenrätsel) | Deutsch | 20 | 1 | ok | Schulwissen |
| Lernhub | 1 | Deutsch | Begleiter-Rätsel | learning-unit-Deutsch-Begleiter-Rätsel | Übung Deutsch/Begleiter-Rätsel | LumoAdventureTasks (abenteuer-Begleiter-Rätsel) | Deutsch | 82 | 1 | ok | Schulwissen |
| Lernhub | 1 | Deutsch | Gegenteil-Geschichten | learning-unit-Deutsch-Gegenteil-Geschichten | Übung Deutsch/Gegenteil-Geschichten | LumoAdventureTasks (abenteuer-Gegenteil-Geschichten) | Deutsch | 32 | 1 | ok | Schulwissen |
| Lernhub | 1 | Englisch | Farben | learning-unit-Englisch-Farben | Übung Englisch/Farben | Englisch-Wortschatz (englisch) | Englisch | 16 | 1 | ok | Schulwissen |
| Lernhub | 1 | Englisch | Tiere | learning-unit-Englisch-Tiere | Übung Englisch/Tiere | Englisch-Wortschatz (englisch) | Englisch | 16 | 1 | ok | Schulwissen |
| Lernhub | 1 | Englisch | Begruessung | learning-unit-Englisch-Begruessung | Übung Englisch/Begruessung | Englisch-Wortschatz (englisch) | Englisch | 17 | 1 | ok | Schulwissen |
| Lernhub | 1 | Englisch | Familie | learning-unit-Englisch-Familie | Übung Englisch/Familie | Englisch-Wortschatz (englisch) | Englisch | 16 | 1 | ok | Schulwissen |
| Lernhub | 1 | Englisch | Zahlen | learning-unit-Englisch-Zahlen | Übung Englisch/Zahlen | Englisch-Wortschatz (englisch) | Englisch | 16 | 1 | ok | Schulwissen |
| Lernhub | 1 | Englisch | Körper | learning-unit-Englisch-Körper | Übung Englisch/Körper | Englisch-Wortschatz (englisch) | Englisch | 16 | 1 | ok | Schulwissen |
| Lernhub | 1 | Englisch | Schulsachen | learning-unit-Englisch-Schulsachen | Übung Englisch/Schulsachen | Englisch-Wortschatz (englisch) | Englisch | 10 | 1 | ok | Schulwissen |
| Lernhub | 1 | Sachunterricht | Verkehr | learning-unit-Sachunterricht-Verkehr | Übung Sachunterricht/Verkehr | Sachunterricht-Fragenbank (sach-Verkehr) | Sachunterricht | 15 | 1 | ok | Schulwissen |
| Lernhub | 1 | Sachunterricht | Familie und Gemeinschaft | learning-unit-Sachunterricht-Familie und Gemeinschaft | Übung Sachunterricht/Familie und Gemeinschaft | Sachunterricht-Fragenbank (sach-Familie und Gemeinschaft) | Sachunterricht | 16 | 1 | ok | Schulwissen |
| Lernhub | 1 | Sachunterricht | Zeit und Kalender | learning-unit-Sachunterricht-Zeit und Kalender | Übung Sachunterricht/Zeit und Kalender | Sachunterricht-Fragenbank (sach-Zeit und Kalender) | Sachunterricht | 15 | 1 | ok | Schulwissen |
| Lernhub | 1 | Sachunterricht | Körper | learning-unit-Sachunterricht-Körper | Übung Sachunterricht/Körper | Sachunterricht-Fragenbank (sach-Körper) | Sachunterricht | 16 | 1 | ok | Schulwissen |
| Lernhub | 1 | Sachunterricht | Tag und Nacht | learning-unit-Sachunterricht-Tag und Nacht | Übung Sachunterricht/Tag und Nacht | Sachunterricht-Fragenbank (sach-Tag und Nacht) | Sachunterricht | 15 | 1 | ok | Schulwissen |
| Lernhub | 1 | Sachunterricht | Pflanzen | learning-unit-Sachunterricht-Pflanzen | Übung Sachunterricht/Pflanzen | Sachunterricht-Fragenbank (sach-Pflanzen) | Sachunterricht | 16 | 1 | ok | Schulwissen |
| Lernhub | 1 | Sachunterricht | Wetter | learning-unit-Sachunterricht-Wetter | Übung Sachunterricht/Wetter | Sachunterricht-Fragenbank (sach-Wetter) | Sachunterricht | 16 | 1 | ok | Schulwissen |
| Lernhub | 1 | Sachunterricht | Jahreszeiten | learning-unit-Sachunterricht-Jahreszeiten | Übung Sachunterricht/Jahreszeiten | Sachunterricht-Fragenbank (sach-Jahreszeiten) | Sachunterricht | 16 | 1 | ok | Schulwissen |
| Lernhub | 1 | Sachunterricht | Tiere | learning-unit-Sachunterricht-Tiere | TiereScreen | eigenes Lernmodul | – | – | 1 | ok | Schulwissen |
| Lernhub | 1 | Sachunterricht | Wer bin ich? | learning-unit-Sachunterricht-Wer bin ich? | Übung Sachunterricht/Wer bin ich? | LumoAdventureTasks (abenteuer-Wer bin ich?) | Sachunterricht | 18 | 1 | ok | Schulwissen |
| Lernhub | 1 | Sachunterricht | Monate und Wochentage | learning-unit-Sachunterricht-Monate und Wochentage | Übung Sachunterricht/Monate und Wochentage | LumoAdventureTasks (abenteuer-Monate und Wochentage) | Sachunterricht | 26 | 1 | ok | Schulwissen |
| Lernhub | 1 | Lesen | Mit Lumo laut lesen | learning-active-reading | Lesebereich | Lesebereich (Geschichten) | – | – | 1 | ok | – |
| Lernhub | 1 | Lesen | Woerter lesen | learning-unit-Lesen-Woerter lesen | Übung Lesen/Woerter lesen | ExerciseFactory Lesen (lese-wort) | Lesen | 17 | 1 | ok | Schulwissen |
| Lernhub | 1 | Lesen | Sätze lesen | learning-unit-Lesen-Sätze lesen | Übung Lesen/Sätze lesen | ExerciseFactory Lesen (lese-text) | Lesen | 24 | 1 | ok | Schulwissen |
| Lernhub | 1 | Lesen | Lesesinn | learning-unit-Lesen-Lesesinn | Übung Lesen/Lesesinn | ExerciseFactory Lesen (lese-text) | Lesen | 24 | 1 | ok | Schulwissen |
| Lernhub | 1 | Lesen | Bild und Wort | learning-unit-Lesen-Bild und Wort | Übung Lesen/Bild und Wort | ExerciseFactory Lesen (lese-bild) | Lesen | 20 | 1 | ok | Schulwissen |
| Lernhub | 1 | Lesen | Reihenfolge | learning-unit-Lesen-Reihenfolge | Übung Lesen/Reihenfolge | ExerciseFactory Lesen (lese-reihenfolge) | Lesen | 82 | 1 | ok | Schulwissen |
| Lernhub | 1 | Rechtschreibung | Haeufige Woerter | learning-unit-Rechtschreibung-Haeufige Woerter | Übung Rechtschreibung/Haeufige Woerter | ExerciseFactory Rechtschreibung (rs-kontext+wort) | Rechtschreibung | 30 | 1 | ok | Schulwissen |
| Lernhub | 1 | Rechtschreibung | Gross und klein | learning-unit-Rechtschreibung-Gross und klein | Übung Rechtschreibung/Gross und klein | ExerciseFactory Rechtschreibung (gross) | Rechtschreibung | 97 | 1 | ok | Schulwissen |
| Lernhub | 1 | Rechtschreibung | Doppelmitlaut | learning-unit-Rechtschreibung-Doppelmitlaut | Übung Rechtschreibung/Doppelmitlaut | ExerciseFactory Rechtschreibung (doppel+rs-kontext) | Rechtschreibung | 34 | 1 | ok | Schulwissen |
| Lernhub | 1 | Rechtschreibung | Dehnungen | learning-unit-Rechtschreibung-Dehnungen | Übung Rechtschreibung/Dehnungen | ExerciseFactory Rechtschreibung (dehnung+rs-kontext) | Rechtschreibung | 24 | 1 | ok | Schulwissen |
| Lernhub | 1 | Rechtschreibung | Satzzeichen | learning-unit-Rechtschreibung-Satzzeichen | Übung Rechtschreibung/Satzzeichen | ExerciseFactory Rechtschreibung (punkt+rs-kontext) | Rechtschreibung | 25 | 1 | ok | Schulwissen |
| Lernhub | 1 | Rechtschreibung | Wortende | learning-unit-Rechtschreibung-Wortende | Übung Rechtschreibung/Wortende | ExerciseFactory Rechtschreibung (rs-verlaengern) | Rechtschreibung | 26 | 1 | ok | Schulwissen |
| Lernhub | 1 | Rechtschreibung | St oder Sp | learning-unit-Rechtschreibung-St oder Sp | Übung Rechtschreibung/St oder Sp | ExerciseFactory Rechtschreibung (stsp) | Rechtschreibung | 18 | 1 | ok | Schulwissen |
| Lernhub | 1 | Schreiben | Buchstaben nachspuren | learning-unit-Schreiben-Buchstaben nachspuren | Übung Schreiben/Buchstaben nachspuren | ExerciseFactory Schreiben (schreiben) | Schreiben | 50 | 1 | ok | Schulwissen |
| Lernhub | 1 | Schreiben | Wort schreiben | learning-unit-Schreiben-Wort schreiben | Übung Schreiben/Wort schreiben | ExerciseFactory Schreiben (schreiben) | Schreiben | 61 | 1 | ok | Schulwissen |
| Lernhub | 1 | Schreiben | Satz abschreiben | learning-unit-Schreiben-Satz abschreiben | Übung Schreiben/Satz abschreiben | ExerciseFactory Schreiben (schreiben) | Schreiben | 18 | 1 | ok | Schulwissen |
| Lernhub | 1 | Schreiben | Schwunguebung | learning-unit-Schreiben-Schwunguebung | Übung Schreiben/Schwunguebung | ExerciseFactory Schreiben (schreiben) | Schreiben | 4 | 1 | ok | Schulwissen |
| Lernhub | 1 | Schreiben | Zahlen schreiben | learning-unit-Schreiben-Zahlen schreiben | Übung Schreiben/Zahlen schreiben | ExerciseFactory Schreiben (schreiben) | Schreiben | 21 | 1 | ok | Schulwissen |
| Lernhub | 1 | Logik | Muster | learning-unit-Logik-Muster | Übung Logik/Muster | ExerciseFactory Logik (logik-muster) | Logik | 24 | 1 | ok | Schulwissen |
| Lernhub | 1 | Logik | Reihenfolgen | learning-unit-Logik-Reihenfolgen | Übung Logik/Reihenfolgen | ExerciseFactory Logik (logik-reihenfolge) | Logik | 89 | 1 | ok | Schulwissen |
| Lernhub | 1 | Logik | Was passt nicht? | learning-unit-Logik-Was passt nicht? | Übung Logik/Was passt nicht? | LumoAdventureTasks (abenteuer-Was passt nicht?) | Logik | 120 | 1 | ok | Schulwissen |
| Lernhub | 1 | Musik | (Fach) | learning-extra-Musik | CurriculumActivitiesScreen | PrimaryActivityCatalog (2 Aktivitäten) | – | 2 | 1 | ok | – |
| Lernhub | 1 | Kunst und Gestaltung | (Fach) | learning-extra-Kunst und Gestaltung | CurriculumActivitiesScreen | PrimaryActivityCatalog (2 Aktivitäten) | – | 2 | 1 | ok | – |
| Lernhub | 1 | Technik und Design | (Fach) | learning-extra-Technik und Design | CurriculumActivitiesScreen | PrimaryActivityCatalog (2 Aktivitäten) | – | 2 | 1 | ok | – |
| Lernhub | 1 | Bewegung und Sport | (Fach) | learning-extra-Bewegung und Sport | CurriculumActivitiesScreen | PrimaryActivityCatalog (2 Aktivitäten) | – | 2 | 1 | ok | – |
| Lernhub | 1 | Verkehrs- und Mobilitätsbildung | (Fach) | learning-extra-Verkehrs- und Mobilitätsbildung | CurriculumActivitiesScreen | PrimaryActivityCatalog (2 Aktivitäten) | – | 2 | 1 | ok | – |
| Lernatelier | 1 | – | academy-stories | academy-stories | LumoStoryLibraryScreen | eigenes Modul | – | – | 1 | ok | – |
| Lernatelier | 1 | – | academy-tool-s1_farben | academy-tool-s1_farben | FarbenScreen | eigenes Modul | – | – | 1 | ok | – |
| Lernatelier | 1 | – | academy-activity-Deutsch | academy-activity-Deutsch | CurriculumActivitiesScreen | eigenes Modul | – | – | 1 | ok | – |
| Lernatelier | 1 | – | academy-activity-Englisch | academy-activity-Englisch | CurriculumActivitiesScreen | eigenes Modul | – | – | 1 | ok | – |
| Lernatelier | 1 | – | academy-activity-Sachunterricht | academy-activity-Sachunterricht | CurriculumActivitiesScreen | eigenes Modul | – | – | 1 | ok | – |
| Lernatelier | 1 | – | academy-tool-d1_schreibcoach | academy-tool-d1_schreibcoach | LumoWritingCoachScreen | eigenes Modul | – | – | 1 | ok | – |
| Lernatelier | 1 | – | academy-tool-d1_buchstaben_alle | academy-tool-d1_buchstaben_alle | LetterWritingScreen | eigenes Modul | – | – | 1 | ok | – |
| Lernatelier | 1 | – | academy-tool-d1_woerter | academy-tool-d1_woerter | LumoWritingWordCoachScreen | eigenes Modul | – | – | 1 | ok | – |
| Lernatelier | 1 | – | akademie-learning-lab | akademie-learning-lab | LearningLabHub | eigenes Modul | – | – | 1 | ok | – |
| Lernatelier | 1 | – | akademie-guided-learning | akademie-guided-learning | GuidedLearningHub | eigenes Modul | – | – | 1 | ok | – |
| Lernatelier | 1 | – | akademie-voluntary-discovery | akademie-voluntary-discovery | GuidedLearningHub | eigenes Modul | – | – | 1 | ok | – |
| Lernhub | 2 | Mathematik | Zehner und Einer | learning-unit-Mathematik-Zehner und Einer | Übung Mathematik/Zehner und Einer | MathTaskTemplates g2_tens_ones | Mathematik | 86 | 2 | ok | Schulwissen |
| Lernhub | 2 | Mathematik | Gerade und ungerade | learning-unit-Mathematik-Gerade und ungerade | Übung Mathematik/Gerade und ungerade | MathTaskTemplates g2_even_odd | Mathematik | 74 | 2 | ok | Schulwissen |
| Lernhub | 2 | Mathematik | Plus bis 20 | learning-unit-Mathematik-Plus bis 20 | Übung Mathematik/Plus bis 20 | MathTaskTemplates g1_add_20+g2_add_20 | Mathematik | 83 | 1-2 | ok | Schulwissen |
| Lernhub | 2 | Mathematik | Minus bis 20 | learning-unit-Mathematik-Minus bis 20 | Übung Mathematik/Minus bis 20 | MathTaskTemplates g1_sub_20+g2_sub_20 | Mathematik | 80 | 1-2 | ok | Schulwissen |
| Lernhub | 2 | Mathematik | Plus bis 100 | learning-unit-Mathematik-Plus bis 100 | Übung Mathematik/Plus bis 100 | MathTaskTemplates g2_add_100 | Mathematik | 117 | 2 | ok | Schulwissen |
| Lernhub | 2 | Mathematik | Minus bis 100 | learning-unit-Mathematik-Minus bis 100 | Übung Mathematik/Minus bis 100 | MathTaskTemplates g2_sub_100 | Mathematik | 119 | 2 | ok | Schulwissen |
| Lernhub | 2 | Mathematik | Verdoppeln und Halbieren | learning-unit-Mathematik-Verdoppeln und Halbieren | Übung Mathematik/Verdoppeln und Halbieren | MathTaskTemplates g2_half_double | Mathematik | 46 | 2 | ok | Schulwissen |
| Lernhub | 2 | Mathematik | Einmaleins Vorbereitung | learning-unit-Mathematik-Einmaleins Vorbereitung | EinmaleinsScreen | eigenes Lernmodul | – | – | 2 | ok | Schulwissen |
| Lernhub | 2 | Mathematik | Einmaleins | learning-unit-Mathematik-Einmaleins | Übung Mathematik/Einmaleins | MathTaskTemplates g2_tables | Mathematik | 43 | 2 | ok | Schulwissen |
| Lernhub | 2 | Mathematik | Geld wechseln | learning-unit-Mathematik-Geld wechseln | GeldScreen | eigenes Lernmodul | – | – | 2 | ok | Schulwissen |
| Lernhub | 2 | Mathematik | Uhrzeit | learning-unit-Mathematik-Uhrzeit | UhrLernenScreen | eigenes Lernmodul | – | – | 2 | ok | Schulwissen |
| Lernhub | 2 | Mathematik | Uhr-Abenteuer | learning-unit-Mathematik-Uhr-Abenteuer | Übung Mathematik/Uhr-Abenteuer | LumoAdventureTasks (abenteuer-Uhr-Abenteuer) | Mathematik | 24 | 2 | ok | Schulwissen |
| Lernhub | 2 | Mathematik | Längen | learning-unit-Mathematik-Längen | Übung Mathematik/Längen | MathTaskTemplates g2_length | Mathematik | 49 | 2 | ok | Schulwissen |
| Lernhub | 2 | Mathematik | Formen Nachzeichnen | learning-unit-Mathematik-Formen Nachzeichnen | Übung Mathematik/Formen Nachzeichnen | MathTaskTemplates g1_trace_square+g1_trace_circle+g1_trace_triangle+g2_trace_rectangle+g2_trace_star | Mathematik | 5 | 1-2 | ok | Schulwissen |
| Lernhub | 2 | Mathematik | Textaufgaben | learning-unit-Mathematik-Textaufgaben | Übung Mathematik/Textaufgaben | MathTaskTemplates g1_word_problem+g2_sub_story+g2_word_problem | Mathematik | 115 | 1-2 | ok | Schulwissen |
| Lernhub | 2 | Deutsch | Wortfamilien | learning-unit-Deutsch-Wortfamilien | Übung Deutsch/Wortfamilien | GermanTaskTemplates g2_family | Deutsch | 20 | 2 | ok | Schulwissen |
| Lernhub | 2 | Deutsch | Einzahl und Mehrzahl | learning-unit-Deutsch-Einzahl und Mehrzahl | MehrzahlScreen | eigenes Lernmodul | – | – | 2 | ok | Schulwissen |
| Lernhub | 2 | Deutsch | Verkleinerungsform | learning-unit-Deutsch-Verkleinerungsform | Übung Deutsch/Verkleinerungsform | GermanTaskTemplates g2_diminutive | Deutsch | 20 | 2 | ok | Schulwissen |
| Lernhub | 2 | Deutsch | Gegenteile | learning-unit-Deutsch-Gegenteile | Übung Deutsch/Gegenteile | GermanTaskTemplates g2_opposites | Deutsch | 20 | 2 | ok | Schulwissen |
| Lernhub | 2 | Deutsch | Oberbegriffe | learning-unit-Deutsch-Oberbegriffe | Übung Deutsch/Oberbegriffe | GermanTaskTemplates g2_categories | Deutsch | 20 | 2 | ok | Schulwissen |
| Lernhub | 2 | Deutsch | Namenwoerter | learning-unit-Deutsch-Namenwoerter | Übung Deutsch/Namenwoerter | GermanTaskTemplates g2_nouns+g2_noun_in_sentence | Deutsch | 52 | 2 | ok | Schulwissen |
| Lernhub | 2 | Deutsch | Tunwoerter | learning-unit-Deutsch-Tunwoerter | Übung Deutsch/Tunwoerter | GermanTaskTemplates g2_verbs+g2_verb_in_sentence | Deutsch | 46 | 2 | ok | Schulwissen |
| Lernhub | 2 | Deutsch | Wiewoerter | learning-unit-Deutsch-Wiewoerter | Übung Deutsch/Wiewoerter | GermanTaskTemplates g2_adjectives+g2_adjective_in_sentence | Deutsch | 35 | 2 | ok | Schulwissen |
| Lernhub | 2 | Deutsch | Wörter zusammensetzen | learning-unit-Deutsch-Wörter zusammensetzen | Übung Deutsch/Wörter zusammensetzen | LumoAdventureTasks (abenteuer-Wörter zusammensetzen) | Deutsch | 35 | 2 | ok | Schulwissen |
| Lernhub | 2 | Deutsch | Wortarten-Jagd | learning-unit-Deutsch-Wortarten-Jagd | Übung Deutsch/Wortarten-Jagd | LumoAdventureTasks (abenteuer-Wortarten-Jagd) | Deutsch | 119 | 2 | ok | Schulwissen |
| Lernhub | 2 | Deutsch | Satzbaustelle | learning-unit-Deutsch-Satzbaustelle | Übung Deutsch/Satzbaustelle | LumoAdventureTasks (abenteuer-Satzbaustelle) | Deutsch | 120 | 2 | ok | Schulwissen |
| Lernhub | 2 | Englisch | Zahlen | learning-unit-Englisch-Zahlen | Übung Englisch/Zahlen | Englisch-Wortschatz (englisch) | Englisch | 20 | 2 | ok | Schulwissen |
| Lernhub | 2 | Englisch | Körper | learning-unit-Englisch-Körper | Übung Englisch/Körper | Englisch-Wortschatz (englisch) | Englisch | 16 | 2 | ok | Schulwissen |
| Lernhub | 2 | Englisch | Spielzeug | learning-unit-Englisch-Spielzeug | Übung Englisch/Spielzeug | Englisch-Wortschatz (englisch) | Englisch | 16 | 2 | ok | Schulwissen |
| Lernhub | 2 | Englisch | Tiere | learning-unit-Englisch-Tiere | Übung Englisch/Tiere | Englisch-Wortschatz (englisch) | Englisch | 17 | 2 | ok | Schulwissen |
| Lernhub | 2 | Sachunterricht | Zeit und Kalender | learning-unit-Sachunterricht-Zeit und Kalender | Übung Sachunterricht/Zeit und Kalender | Sachunterricht-Fragenbank (sach-Zeit und Kalender) | Sachunterricht | 17 | 2 | ok | Schulwissen |
| Lernhub | 2 | Sachunterricht | Verkehr | learning-unit-Sachunterricht-Verkehr | VerkehrScreen | eigenes Lernmodul | – | – | 2 | ok | Schulwissen |
| Lernhub | 2 | Sachunterricht | Berufe | learning-unit-Sachunterricht-Berufe | Übung Sachunterricht/Berufe | Sachunterricht-Fragenbank (sach-Berufe) | Sachunterricht | 15 | 2 | ok | Schulwissen |
| Lernhub | 2 | Sachunterricht | Körper | learning-unit-Sachunterricht-Körper | Übung Sachunterricht/Körper | Sachunterricht-Fragenbank (sach-Körper) | Sachunterricht | 16 | 2 | ok | Schulwissen |
| Lernhub | 2 | Sachunterricht | Familie und Gemeinschaft | learning-unit-Sachunterricht-Familie und Gemeinschaft | Übung Sachunterricht/Familie und Gemeinschaft | Sachunterricht-Fragenbank (sach-Familie und Gemeinschaft) | Sachunterricht | 16 | 2 | ok | Schulwissen |
| Lernhub | 2 | Sachunterricht | Wetter | learning-unit-Sachunterricht-Wetter | WetterScreen | eigenes Lernmodul | – | – | 2 | ok | Schulwissen |
| Lernhub | 2 | Sachunterricht | Pflanzen | learning-unit-Sachunterricht-Pflanzen | Übung Sachunterricht/Pflanzen | Sachunterricht-Fragenbank (sach-Pflanzen) | Sachunterricht | 16 | 2 | ok | Schulwissen |
| Lernhub | 2 | Sachunterricht | Jahreszeiten | learning-unit-Sachunterricht-Jahreszeiten | JahreszeitenScreen | eigenes Lernmodul | – | – | 2 | ok | Schulwissen |
| Lernhub | 2 | Sachunterricht | Tiere | learning-unit-Sachunterricht-Tiere | Übung Sachunterricht/Tiere | Sachunterricht-Fragenbank (sach-Tiere) | Sachunterricht | 16 | 2 | ok | Schulwissen |
| Lernhub | 2 | Lesen | Mit Lumo laut lesen | learning-active-reading | Lesebereich | Lesebereich (Geschichten) | – | – | 2 | ok | – |
| Lernhub | 2 | Lesen | Woerter lesen | learning-unit-Lesen-Woerter lesen | Übung Lesen/Woerter lesen | ExerciseFactory Lesen (lese-wort) | Lesen | 22 | 2 | ok | Schulwissen |
| Lernhub | 2 | Lesen | Sätze lesen | learning-unit-Lesen-Sätze lesen | Übung Lesen/Sätze lesen | ExerciseFactory Lesen (lese-text) | Lesen | 23 | 2 | ok | Schulwissen |
| Lernhub | 2 | Lesen | Lesesinn | learning-unit-Lesen-Lesesinn | Übung Lesen/Lesesinn | ExerciseFactory Lesen (lese-text) | Lesen | 23 | 2 | ok | Schulwissen |
| Lernhub | 2 | Lesen | Bild und Wort | learning-unit-Lesen-Bild und Wort | Übung Lesen/Bild und Wort | ExerciseFactory Lesen (lese-bild) | Lesen | 20 | 2 | ok | Schulwissen |
| Lernhub | 2 | Lesen | Reihenfolge | learning-unit-Lesen-Reihenfolge | Übung Lesen/Reihenfolge | ExerciseFactory Lesen (lese-reihenfolge) | Lesen | 86 | 2 | ok | Schulwissen |
| Lernhub | 2 | Rechtschreibung | Haeufige Woerter | learning-unit-Rechtschreibung-Haeufige Woerter | Übung Rechtschreibung/Haeufige Woerter | ExerciseFactory Rechtschreibung (rs-kontext+wort) | Rechtschreibung | 22 | 2 | ok | Schulwissen |
| Lernhub | 2 | Rechtschreibung | Gross und klein | learning-unit-Rechtschreibung-Gross und klein | Übung Rechtschreibung/Gross und klein | ExerciseFactory Rechtschreibung (gross) | Rechtschreibung | 96 | 2 | ok | Schulwissen |
| Lernhub | 2 | Rechtschreibung | Doppelmitlaut | learning-unit-Rechtschreibung-Doppelmitlaut | Übung Rechtschreibung/Doppelmitlaut | ExerciseFactory Rechtschreibung (doppel+rs-kontext) | Rechtschreibung | 35 | 2 | ok | Schulwissen |
| Lernhub | 2 | Rechtschreibung | Dehnungen | learning-unit-Rechtschreibung-Dehnungen | Übung Rechtschreibung/Dehnungen | ExerciseFactory Rechtschreibung (dehnung+rs-kontext) | Rechtschreibung | 30 | 2 | ok | Schulwissen |
| Lernhub | 2 | Rechtschreibung | Satzzeichen | learning-unit-Rechtschreibung-Satzzeichen | Übung Rechtschreibung/Satzzeichen | ExerciseFactory Rechtschreibung (punkt+rs-kontext) | Rechtschreibung | 25 | 2 | ok | Schulwissen |
| Lernhub | 2 | Rechtschreibung | Wortende | learning-unit-Rechtschreibung-Wortende | Übung Rechtschreibung/Wortende | ExerciseFactory Rechtschreibung (rs-verlaengern) | Rechtschreibung | 28 | 2 | ok | Schulwissen |
| Lernhub | 2 | Rechtschreibung | St oder Sp | learning-unit-Rechtschreibung-St oder Sp | Übung Rechtschreibung/St oder Sp | ExerciseFactory Rechtschreibung (stsp) | Rechtschreibung | 18 | 2 | ok | Schulwissen |
| Lernhub | 2 | Schreiben | Buchstaben nachspuren | learning-unit-Schreiben-Buchstaben nachspuren | Übung Schreiben/Buchstaben nachspuren | ExerciseFactory Schreiben (schreiben) | Schreiben | 28 | 2 | ok | Schulwissen |
| Lernhub | 2 | Schreiben | Wort schreiben | learning-unit-Schreiben-Wort schreiben | Übung Schreiben/Wort schreiben | ExerciseFactory Schreiben (schreiben) | Schreiben | 68 | 2 | ok | Schulwissen |
| Lernhub | 2 | Schreiben | Satz abschreiben | learning-unit-Schreiben-Satz abschreiben | Übung Schreiben/Satz abschreiben | ExerciseFactory Schreiben (schreiben) | Schreiben | 18 | 2 | ok | Schulwissen |
| Lernhub | 2 | Schreiben | Schwunguebung | learning-unit-Schreiben-Schwunguebung | Übung Schreiben/Schwunguebung | ExerciseFactory Schreiben (schreiben) | Schreiben | 5 | 2 | ok | Schulwissen |
| Lernhub | 2 | Schreiben | Zahlen schreiben | learning-unit-Schreiben-Zahlen schreiben | Übung Schreiben/Zahlen schreiben | ExerciseFactory Schreiben (schreiben) | Schreiben | 18 | 2 | ok | Schulwissen |
| Lernhub | 2 | Logik | Zahlenmuster | learning-unit-Logik-Zahlenmuster | Übung Logik/Zahlenmuster | ExerciseFactory Logik (logik-zahlenmuster) | Logik | 99 | 2 | ok | Schulwissen |
| Lernhub | 2 | Logik | Geheimcode | learning-unit-Logik-Geheimcode | Übung Logik/Geheimcode | LumoAdventureTasks (abenteuer-Geheimcode) | Logik | 20 | 2 | ok | Schulwissen |
| Lernhub | 2 | Musik | (Fach) | learning-extra-Musik | CurriculumActivitiesScreen | PrimaryActivityCatalog (2 Aktivitäten) | – | 2 | 2 | ok | – |
| Lernhub | 2 | Kunst und Gestaltung | (Fach) | learning-extra-Kunst und Gestaltung | CurriculumActivitiesScreen | PrimaryActivityCatalog (2 Aktivitäten) | – | 2 | 2 | ok | – |
| Lernhub | 2 | Technik und Design | (Fach) | learning-extra-Technik und Design | CurriculumActivitiesScreen | PrimaryActivityCatalog (2 Aktivitäten) | – | 2 | 2 | ok | – |
| Lernhub | 2 | Bewegung und Sport | (Fach) | learning-extra-Bewegung und Sport | CurriculumActivitiesScreen | PrimaryActivityCatalog (2 Aktivitäten) | – | 2 | 2 | ok | – |
| Lernhub | 2 | Verkehrs- und Mobilitätsbildung | (Fach) | learning-extra-Verkehrs- und Mobilitätsbildung | CurriculumActivitiesScreen | PrimaryActivityCatalog (2 Aktivitäten) | – | 2 | 2 | ok | – |
| Lernatelier | 2 | – | academy-stories | academy-stories | LumoStoryLibraryScreen | eigenes Modul | – | – | 2 | ok | – |
| Lernatelier | 2 | – | academy-tool-m2_zahlen100 | academy-tool-m2_zahlen100 | ZahlenBis100Screen | eigenes Modul | – | – | 2 | ok | – |
| Lernatelier | 2 | – | academy-activity-Deutsch | academy-activity-Deutsch | CurriculumActivitiesScreen | eigenes Modul | – | – | 2 | ok | – |
| Lernatelier | 2 | – | academy-activity-Englisch | academy-activity-Englisch | CurriculumActivitiesScreen | eigenes Modul | – | – | 2 | ok | – |
| Lernatelier | 2 | – | academy-activity-Sachunterricht | academy-activity-Sachunterricht | CurriculumActivitiesScreen | eigenes Modul | – | – | 2 | ok | – |
| Lernatelier | 2 | – | academy-tool-d2_artikel | academy-tool-d2_artikel | ArtikelLernenScreen | eigenes Modul | – | – | 2 | ok | – |
| Lernatelier | 2 | – | akademie-learning-lab | akademie-learning-lab | LearningLabHub | eigenes Modul | – | – | 2 | ok | – |
| Lernatelier | 2 | – | akademie-guided-learning | akademie-guided-learning | GuidedLearningHub | eigenes Modul | – | – | 2 | ok | – |
| Lernatelier | 2 | – | akademie-voluntary-discovery | akademie-voluntary-discovery | GuidedLearningHub | eigenes Modul | – | – | 2 | ok | – |
| Lernhub | 3 | Mathematik | Plus bis 100 | learning-unit-Mathematik-Plus bis 100 | Übung Mathematik/Plus bis 100 | MathTaskTemplates g2_add_100+g3_add_100 | Mathematik | 117 | 2-3 | ok | Schulwissen |
| Lernhub | 3 | Mathematik | Minus bis 100 | learning-unit-Mathematik-Minus bis 100 | Übung Mathematik/Minus bis 100 | MathTaskTemplates g2_sub_100+g3_sub_100 | Mathematik | 114 | 2-3 | ok | Schulwissen |
| Lernhub | 3 | Mathematik | Plus bis 1000 | learning-unit-Mathematik-Plus bis 1000 | Übung Mathematik/Plus bis 1000 | MathTaskTemplates g3_add_1000 | Mathematik | 119 | 3 | ok | Schulwissen |
| Lernhub | 3 | Mathematik | Minus bis 1000 | learning-unit-Mathematik-Minus bis 1000 | Übung Mathematik/Minus bis 1000 | MathTaskTemplates g3_sub_1000 | Mathematik | 119 | 3 | ok | Schulwissen |
| Lernhub | 3 | Mathematik | Einmaleins | learning-unit-Mathematik-Einmaleins | EinmaleinsScreen | eigenes Lernmodul | – | – | 3 | ok | Schulwissen |
| Lernhub | 3 | Mathematik | Division einstellig | learning-unit-Mathematik-Division einstellig | Übung Mathematik/Division einstellig | MathTaskTemplates g3_division_basic | Mathematik | 83 | 3 | ok | Schulwissen |
| Lernhub | 3 | Mathematik | Schriftliche Addition | learning-unit-Mathematik-Schriftliche Addition | Übung Mathematik/Schriftliche Addition | MathTaskTemplates g3_written_add | Mathematik | 119 | 3 | ok | Schulwissen |
| Lernhub | 3 | Mathematik | Schriftliche Subtraktion | learning-unit-Mathematik-Schriftliche Subtraktion | Übung Mathematik/Schriftliche Subtraktion | MathTaskTemplates g3_written_sub | Mathematik | 118 | 3 | ok | Schulwissen |
| Lernhub | 3 | Mathematik | Brüche Vorbereitung | learning-unit-Mathematik-Brüche Vorbereitung | Übung Mathematik/Brüche Vorbereitung | MathTaskTemplates g3_fraction_half | Mathematik | 46 | 3 | ok | Lumo Expertenwelt |
| Lernhub | 3 | Mathematik | Geld bis 100 Euro | learning-unit-Mathematik-Geld bis 100 Euro | Übung Mathematik/Geld bis 100 Euro | MathTaskTemplates g3_money_change_100 | Mathematik | 47 | 3 | ok | Schulwissen |
| Lernhub | 3 | Mathematik | Massen Kilogramm und Gramm | learning-unit-Mathematik-Massen Kilogramm und Gramm | Übung Mathematik/Massen Kilogramm und Gramm | MathTaskTemplates g3_mass | Mathematik | 36 | 3 | ok | Schulwissen |
| Lernhub | 3 | Mathematik | Umfang | learning-unit-Mathematik-Umfang | Übung Mathematik/Umfang | MathTaskTemplates g3_perimeter | Mathematik | 81 | 3 | ok | Schulwissen |
| Lernhub | 3 | Mathematik | Sachaufgaben zwei Schritte | learning-unit-Mathematik-Sachaufgaben zwei Schritte | Übung Mathematik/Sachaufgaben zwei Schritte | MathTaskTemplates g3_two_step | Mathematik | 119 | 3 | ok | Vertiefung |
| Lernhub | 3 | Deutsch | Synonyme | learning-unit-Deutsch-Synonyme | Übung Deutsch/Synonyme | GermanTaskTemplates g3_synonyms | Deutsch | 20 | 3 | ok | Schulwissen |
| Lernhub | 3 | Deutsch | Wortarten | learning-unit-Deutsch-Wortarten | WortartenScreen | eigenes Lernmodul | – | – | 3 | ok | Schulwissen |
| Lernhub | 3 | Deutsch | Zeitformen | learning-unit-Deutsch-Zeitformen | ZeitformenScreen | eigenes Lernmodul | – | – | 3 | ok | Schulwissen |
| Lernhub | 3 | Deutsch | Steigerung | learning-unit-Deutsch-Steigerung | Übung Deutsch/Steigerung | GermanTaskTemplates g3_comparison | Deutsch | 20 | 3 | ok | Schulwissen |
| Lernhub | 3 | Deutsch | Verbformen | learning-unit-Deutsch-Verbformen | Übung Deutsch/Verbformen | GermanTaskTemplates g3_verb_form | Deutsch | 20 | 3 | ok | Schulwissen |
| Lernhub | 3 | Deutsch | Wer-Fall und Wen-Fall | learning-unit-Deutsch-Wer-Fall und Wen-Fall | Übung Deutsch/Wer-Fall und Wen-Fall | GermanTaskTemplates g3_case_nom_akk | Deutsch | 20 | 3 | ok | Schulwissen |
| Lernhub | 3 | Deutsch | Großschreibung | learning-unit-Deutsch-Großschreibung | Übung Deutsch/Großschreibung | GermanTaskTemplates g3_capitalization | Deutsch | 20 | 3 | ok | Schulwissen |
| Lernhub | 3 | Deutsch | ie oder i | learning-unit-Deutsch-ie oder i | Übung Deutsch/ie oder i | GermanTaskTemplates g3_ie_or_i | Deutsch | 20 | 3 | ok | Schulwissen |
| Lernhub | 3 | Englisch | Schulsachen | learning-unit-Englisch-Schulsachen | Übung Englisch/Schulsachen | Englisch-Wortschatz (englisch+englisch-de-en) | Englisch | 37 | 3 | ok | Schulwissen |
| Lernhub | 3 | Englisch | Wetter | learning-unit-Englisch-Wetter | Übung Englisch/Wetter | Englisch-Wortschatz (englisch+englisch-de-en) | Englisch | 28 | 3 | ok | Schulwissen |
| Lernhub | 3 | Englisch | Essen | learning-unit-Englisch-Essen | Übung Englisch/Essen | Englisch-Wortschatz (englisch+englisch-de-en) | Englisch | 35 | 3 | ok | Schulwissen |
| Lernhub | 3 | Englisch | Tageszeit | learning-unit-Englisch-Tageszeit | Übung Englisch/Tageszeit | Englisch-Wortschatz (englisch+englisch-de-en) | Englisch | 29 | 3 | ok | Schulwissen |
| Lernhub | 3 | Englisch | Alltagssätze | learning-unit-Englisch-Alltagssätze | Übung Englisch/Alltagssätze | Englisch-Wortschatz (englisch+englisch-de-en) | Englisch | 24 | 3 | ok | Schulwissen |
| Lernhub | 3 | Sachunterricht | Wasserkreislauf | learning-unit-Sachunterricht-Wasserkreislauf | Übung Sachunterricht/Wasserkreislauf | Sachunterricht-Fragenbank (sach-Wasserkreislauf) | Sachunterricht | 16 | 3 | ok | Schulwissen |
| Lernhub | 3 | Sachunterricht | Ernährung | learning-unit-Sachunterricht-Ernährung | Übung Sachunterricht/Ernährung | Sachunterricht-Fragenbank (sach-Ernährung) | Sachunterricht | 15 | 3 | ok | Schulwissen |
| Lernhub | 3 | Sachunterricht | Bundesländer Österreichs | learning-unit-Sachunterricht-Bundesländer Österreichs | Übung Sachunterricht/Bundesländer Österreichs | Sachunterricht-Fragenbank (sach-Bundesländer Österreichs) | Sachunterricht | 15 | 3 | ok | Schulwissen |
| Lernhub | 3 | Sachunterricht | Verkehr | learning-unit-Sachunterricht-Verkehr | Übung Sachunterricht/Verkehr | Sachunterricht-Fragenbank (sach-Verkehr) | Sachunterricht | 15 | 3 | ok | Schulwissen |
| Lernhub | 3 | Sachunterricht | Pflanzen | learning-unit-Sachunterricht-Pflanzen | Übung Sachunterricht/Pflanzen | Sachunterricht-Fragenbank (sach-Pflanzen) | Sachunterricht | 15 | 3 | ok | Schulwissen |
| Lernhub | 3 | Sachunterricht | Körper | learning-unit-Sachunterricht-Körper | Übung Sachunterricht/Körper | Sachunterricht-Fragenbank (sach-Körper) | Sachunterricht | 15 | 3 | ok | Schulwissen |
| Lernhub | 3 | Sachunterricht | Zeit und Kalender | learning-unit-Sachunterricht-Zeit und Kalender | Übung Sachunterricht/Zeit und Kalender | Sachunterricht-Fragenbank (sach-Zeit und Kalender) | Sachunterricht | 16 | 3 | ok | Schulwissen |
| Lernhub | 3 | Sachunterricht | Wetter | learning-unit-Sachunterricht-Wetter | Übung Sachunterricht/Wetter | Sachunterricht-Fragenbank (sach-Wetter) | Sachunterricht | 15 | 3 | ok | Schulwissen |
| Lernhub | 3 | Sachunterricht | Familie und Gemeinschaft | learning-unit-Sachunterricht-Familie und Gemeinschaft | Übung Sachunterricht/Familie und Gemeinschaft | Sachunterricht-Fragenbank (sach-Familie und Gemeinschaft) | Sachunterricht | 18 | 3 | ok | Schulwissen |
| Lernhub | 3 | Sachunterricht | Berufe | learning-unit-Sachunterricht-Berufe | Übung Sachunterricht/Berufe | Sachunterricht-Fragenbank (sach-Berufe) | Sachunterricht | 15 | 3 | ok | Schulwissen |
| Lernhub | 3 | Sachunterricht | Tiere | learning-unit-Sachunterricht-Tiere | Übung Sachunterricht/Tiere | Sachunterricht-Fragenbank (sach-Tiere) | Sachunterricht | 35 | 1-3 | ok | Schulwissen |
| Lernhub | 3 | Sachunterricht | Österreich-Reise | learning-unit-Sachunterricht-Österreich-Reise | Übung Sachunterricht/Österreich-Reise | LumoAdventureTasks (abenteuer-Österreich-Reise) | Sachunterricht | 22 | 3 | ok | Schulwissen |
| Lernhub | 3 | Lesen | Mit Lumo laut lesen | learning-active-reading | Lesebereich | Lesebereich (Geschichten) | – | – | 3 | ok | – |
| Lernhub | 3 | Lesen | Woerter lesen | learning-unit-Lesen-Woerter lesen | Übung Lesen/Woerter lesen | ExerciseFactory Lesen (lese-wort) | Lesen | 24 | 3 | ok | Schulwissen |
| Lernhub | 3 | Lesen | Sätze lesen | learning-unit-Lesen-Sätze lesen | Übung Lesen/Sätze lesen | ExerciseFactory Lesen (lese-text) | Lesen | 24 | 3 | ok | Schulwissen |
| Lernhub | 3 | Lesen | Lesesinn | learning-unit-Lesen-Lesesinn | Übung Lesen/Lesesinn | ExerciseFactory Lesen (lese-text) | Lesen | 24 | 3 | ok | Schulwissen |
| Lernhub | 3 | Lesen | Bild und Wort | learning-unit-Lesen-Bild und Wort | Übung Lesen/Bild und Wort | ExerciseFactory Lesen (lese-bild) | Lesen | 20 | 3 | ok | Schulwissen |
| Lernhub | 3 | Lesen | Reihenfolge | learning-unit-Lesen-Reihenfolge | Übung Lesen/Reihenfolge | ExerciseFactory Lesen (lese-reihenfolge) | Lesen | 87 | 3 | ok | Schulwissen |
| Lernhub | 3 | Rechtschreibung | Haeufige Woerter | learning-unit-Rechtschreibung-Haeufige Woerter | Übung Rechtschreibung/Haeufige Woerter | ExerciseFactory Rechtschreibung (rs-kontext+wort) | Rechtschreibung | 22 | 3 | ok | Schulwissen |
| Lernhub | 3 | Rechtschreibung | Gross und klein | learning-unit-Rechtschreibung-Gross und klein | Übung Rechtschreibung/Gross und klein | ExerciseFactory Rechtschreibung (gross) | Rechtschreibung | 100 | 3 | ok | Schulwissen |
| Lernhub | 3 | Rechtschreibung | Doppelmitlaut | learning-unit-Rechtschreibung-Doppelmitlaut | Übung Rechtschreibung/Doppelmitlaut | ExerciseFactory Rechtschreibung (doppel+rs-kontext) | Rechtschreibung | 22 | 3 | ok | Schulwissen |
| Lernhub | 3 | Rechtschreibung | Dehnungen | learning-unit-Rechtschreibung-Dehnungen | Übung Rechtschreibung/Dehnungen | ExerciseFactory Rechtschreibung (dehnung+rs-kontext) | Rechtschreibung | 20 | 3 | ok | Schulwissen |
| Lernhub | 3 | Rechtschreibung | Satzzeichen | learning-unit-Rechtschreibung-Satzzeichen | Übung Rechtschreibung/Satzzeichen | ExerciseFactory Rechtschreibung (punkt+rs-kontext) | Rechtschreibung | 25 | 3 | ok | Schulwissen |
| Lernhub | 3 | Rechtschreibung | Wortende | learning-unit-Rechtschreibung-Wortende | Übung Rechtschreibung/Wortende | ExerciseFactory Rechtschreibung (rs-verlaengern) | Rechtschreibung | 28 | 3 | ok | Schulwissen |
| Lernhub | 3 | Rechtschreibung | St oder Sp | learning-unit-Rechtschreibung-St oder Sp | Übung Rechtschreibung/St oder Sp | ExerciseFactory Rechtschreibung (stsp) | Rechtschreibung | 18 | 3 | ok | Schulwissen |
| Lernhub | 3 | Schreiben | Buchstaben nachspuren | learning-unit-Schreiben-Buchstaben nachspuren | Übung Schreiben/Buchstaben nachspuren | ExerciseFactory Schreiben (schreiben) | Schreiben | 18 | 3 | ok | Schulwissen |
| Lernhub | 3 | Schreiben | Wort schreiben | learning-unit-Schreiben-Wort schreiben | Übung Schreiben/Wort schreiben | ExerciseFactory Schreiben (schreiben) | Schreiben | 76 | 3 | ok | Schulwissen |
| Lernhub | 3 | Schreiben | Satz abschreiben | learning-unit-Schreiben-Satz abschreiben | Übung Schreiben/Satz abschreiben | ExerciseFactory Schreiben (schreiben) | Schreiben | 16 | 3 | ok | Schulwissen |
| Lernhub | 3 | Schreiben | Schwunguebung | learning-unit-Schreiben-Schwunguebung | Übung Schreiben/Schwunguebung | ExerciseFactory Schreiben (schreiben) | Schreiben | 16 | 3 | ok | Schulwissen |
| Lernhub | 3 | Schreiben | Zahlen schreiben | learning-unit-Schreiben-Zahlen schreiben | Übung Schreiben/Zahlen schreiben | ExerciseFactory Schreiben (schreiben) | Schreiben | 25 | 3 | ok | Schulwissen |
| Lernhub | 3 | Logik | Schlussfolgern | learning-unit-Logik-Schlussfolgern | Übung Logik/Schlussfolgern | ExerciseFactory Logik (logik-reihenfolge) | Logik | 116 | 3 | ok | Schulwissen |
| Lernhub | 3 | Musik | (Fach) | learning-extra-Musik | CurriculumActivitiesScreen | PrimaryActivityCatalog (2 Aktivitäten) | – | 2 | 3 | ok | – |
| Lernhub | 3 | Kunst und Gestaltung | (Fach) | learning-extra-Kunst und Gestaltung | CurriculumActivitiesScreen | PrimaryActivityCatalog (2 Aktivitäten) | – | 2 | 3 | ok | – |
| Lernhub | 3 | Technik und Design | (Fach) | learning-extra-Technik und Design | CurriculumActivitiesScreen | PrimaryActivityCatalog (2 Aktivitäten) | – | 2 | 3 | ok | – |
| Lernhub | 3 | Bewegung und Sport | (Fach) | learning-extra-Bewegung und Sport | CurriculumActivitiesScreen | PrimaryActivityCatalog (2 Aktivitäten) | – | 2 | 3 | ok | – |
| Lernhub | 3 | Verkehrs- und Mobilitätsbildung | (Fach) | learning-extra-Verkehrs- und Mobilitätsbildung | CurriculumActivitiesScreen | PrimaryActivityCatalog (2 Aktivitäten) | – | 2 | 3 | ok | – |
| Lernatelier | 3 | – | academy-stories | academy-stories | LumoStoryLibraryScreen | eigenes Modul | – | – | 3 | ok | – |
| Lernatelier | 3 | – | academy-activity-Deutsch | academy-activity-Deutsch | CurriculumActivitiesScreen | eigenes Modul | – | – | 3 | ok | – |
| Lernatelier | 3 | – | academy-activity-Englisch | academy-activity-Englisch | CurriculumActivitiesScreen | eigenes Modul | – | – | 3 | ok | – |
| Lernatelier | 3 | – | academy-activity-Sachunterricht | academy-activity-Sachunterricht | CurriculumActivitiesScreen | eigenes Modul | – | – | 3 | ok | – |
| Lernatelier | 3 | – | akademie-learning-lab | akademie-learning-lab | LearningLabHub | eigenes Modul | – | – | 3 | ok | – |
| Lernatelier | 3 | – | akademie-guided-learning | akademie-guided-learning | GuidedLearningHub | eigenes Modul | – | – | 3 | ok | – |
| Lernatelier | 3 | – | akademie-voluntary-discovery | akademie-voluntary-discovery | GuidedLearningHub | eigenes Modul | – | – | 3 | ok | – |
| Lernhub | 4 | Mathematik | Vergleichen | learning-unit-Mathematik-Vergleichen | Übung Mathematik/Vergleichen | MathTaskTemplates g4_compare | Mathematik | 120 | 4 | ok | Schulwissen |
| Lernhub | 4 | Mathematik | Zahlenraum bis 1 Million | learning-unit-Mathematik-Zahlenraum bis 1 Million | Übung Mathematik/Zahlenraum bis 1 Million | MathTaskTemplates g4_compare_1mio | Mathematik | 120 | 4 | ok | Schulwissen |
| Lernhub | 4 | Mathematik | Plus bis 10000 | learning-unit-Mathematik-Plus bis 10000 | Übung Mathematik/Plus bis 10000 | MathTaskTemplates g4_add_10000 | Mathematik | 120 | 4 | ok | Schulwissen |
| Lernhub | 4 | Mathematik | Minus bis 10000 | learning-unit-Mathematik-Minus bis 10000 | Übung Mathematik/Minus bis 10000 | MathTaskTemplates g4_sub_10000 | Mathematik | 120 | 4 | ok | Schulwissen |
| Lernhub | 4 | Mathematik | Schriftliche Multiplikation | learning-unit-Mathematik-Schriftliche Multiplikation | Übung Mathematik/Schriftliche Multiplikation | MathTaskTemplates g4_written_mul | Mathematik | 118 | 4 | ok | Schulwissen |
| Lernhub | 4 | Mathematik | Schriftliche Division | learning-unit-Mathematik-Schriftliche Division | Übung Mathematik/Schriftliche Division | MathTaskTemplates g4_written_div | Mathematik | 118 | 4 | ok | Schulwissen |
| Lernhub | 4 | Mathematik | Bruchrechnen einfach | learning-unit-Mathematik-Bruchrechnen einfach | BruchrechnenScreen | eigenes Lernmodul | – | – | 4 | ok | Schulwissen |
| Lernhub | 4 | Mathematik | Brüche erweitern | learning-unit-Mathematik-Brüche erweitern | Übung Mathematik/Brüche erweitern | MathTaskTemplates g4_fraction_expand | Mathematik | 51 | 4 | ok | Lumo Expertenwelt |
| Lernhub | 4 | Mathematik | Dezimalzahlen | learning-unit-Mathematik-Dezimalzahlen | Übung Mathematik/Dezimalzahlen | MathTaskTemplates g4_decimal | Mathematik | 120 | 4 | ok | Lumo Expertenwelt |
| Lernhub | 4 | Mathematik | Zeit Minuten und Stunden | learning-unit-Mathematik-Zeit Minuten und Stunden | Übung Mathematik/Zeit Minuten und Stunden | MathTaskTemplates g4_time_minutes | Mathematik | 59 | 4 | ok | Schulwissen |
| Lernhub | 4 | Mathematik | Hohlmaße Liter und Milliliter | learning-unit-Mathematik-Hohlmaße Liter und Milliliter | Übung Mathematik/Hohlmaße Liter und Milliliter | MathTaskTemplates g4_volume | Mathematik | 35 | 4 | ok | Schulwissen |
| Lernhub | 4 | Mathematik | Symmetrieachsen | learning-unit-Mathematik-Symmetrieachsen | Übung Mathematik/Symmetrieachsen | MathTaskTemplates g4_symmetry_lines | Mathematik | 22 | 4 | ok | Schulwissen |
| Lernhub | 4 | Mathematik | Flächeninhalt | learning-unit-Mathematik-Flächeninhalt | Übung Mathematik/Flächeninhalt | MathTaskTemplates g4_area | Mathematik | 56 | 4 | ok | Schulwissen |
| Lernhub | 4 | Mathematik | Sachaufgaben drei Schritte | learning-unit-Mathematik-Sachaufgaben drei Schritte | Übung Mathematik/Sachaufgaben drei Schritte | MathTaskTemplates g4_three_step | Mathematik | 119 | 4 | ok | Vertiefung |
| Lernhub | 4 | Mathematik | Diagramme lesen | learning-unit-Mathematik-Diagramme lesen | Übung Mathematik/Diagramme lesen | MathTaskTemplates g4_chart+g4_chart_collection | Mathematik | 71 | 4 | ok | Schulwissen |
| Lernhub | 4 | Mathematik | Mittelwert | learning-unit-Mathematik-Mittelwert | Übung Mathematik/Mittelwert | MathTaskTemplates g4_average | Mathematik | 119 | 4 | ok | Lumo Expertenwelt |
| Lernhub | 4 | Deutsch | Satzglieder | learning-unit-Deutsch-Satzglieder | Übung Deutsch/Satzglieder | GermanTaskTemplates g4_sentence_parts | Deutsch | 20 | 4 | ok | Schulwissen |
| Lernhub | 4 | Deutsch | Direkte Rede | learning-unit-Deutsch-Direkte Rede | Übung Deutsch/Direkte Rede | GermanTaskTemplates g4_direct_speech | Deutsch | 20 | 4 | ok | Schulwissen |
| Lernhub | 4 | Deutsch | Kommas in Aufzählungen | learning-unit-Deutsch-Kommas in Aufzählungen | Übung Deutsch/Kommas in Aufzählungen | GermanTaskTemplates g4_commas | Deutsch | 20 | 4 | ok | Schulwissen |
| Lernhub | 4 | Deutsch | Zusammensetzungen | learning-unit-Deutsch-Zusammensetzungen | Übung Deutsch/Zusammensetzungen | GermanTaskTemplates g4_compounds | Deutsch | 20 | 4 | ok | Schulwissen |
| Lernhub | 4 | Deutsch | Die 4 Fälle | learning-unit-Deutsch-Die 4 Fälle | Übung Deutsch/Die 4 Fälle | GermanTaskTemplates g4_four_cases | Deutsch | 20 | 4 | ok | Schulwissen |
| Lernhub | 4 | Deutsch | dass oder das | learning-unit-Deutsch-dass oder das | Übung Deutsch/dass oder das | GermanTaskTemplates g4_dass_das | Deutsch | 20 | 4 | ok | Schulwissen |
| Lernhub | 4 | Deutsch | Umstandswörter | learning-unit-Deutsch-Umstandswörter | Übung Deutsch/Umstandswörter | GermanTaskTemplates g4_adverbs | Deutsch | 20 | 4 | ok | Schulwissen |
| Lernhub | 4 | Deutsch | Vorvergangenheit | learning-unit-Deutsch-Vorvergangenheit | Übung Deutsch/Vorvergangenheit | GermanTaskTemplates g4_plusquam | Deutsch | 20 | 4 | ok | Schulwissen |
| Lernhub | 4 | Englisch | Verben | learning-unit-Englisch-Verben | Übung Englisch/Verben | Englisch-Wortschatz (englisch+englisch-de-en) | Englisch | 45 | 4 | ok | Schulwissen |
| Lernhub | 4 | Englisch | Wochentage | learning-unit-Englisch-Wochentage | Übung Englisch/Wochentage | Englisch-Wortschatz (englisch+englisch-de-en) | Englisch | 34 | 4 | ok | Schulwissen |
| Lernhub | 4 | Englisch | Hobbys | learning-unit-Englisch-Hobbys | Übung Englisch/Hobbys | Englisch-Wortschatz (englisch+englisch-de-en) | Englisch | 38 | 4 | ok | Schulwissen |
| Lernhub | 4 | Englisch | Länder | learning-unit-Englisch-Länder | Übung Englisch/Länder | Englisch-Wortschatz (englisch+englisch-de-en) | Englisch | 37 | 4 | ok | Schulwissen |
| Lernhub | 4 | Englisch | Alltagssätze | learning-unit-Englisch-Alltagssätze | Übung Englisch/Alltagssätze | Englisch-Wortschatz (englisch+englisch-de-en) | Englisch | 29 | 4 | ok | Schulwissen |
| Lernhub | 4 | Sachunterricht | Stromkreise | learning-unit-Sachunterricht-Stromkreise | Übung Sachunterricht/Stromkreise | Sachunterricht-Fragenbank (sach-Stromkreise) | Sachunterricht | 15 | 4 | ok | Schulwissen |
| Lernhub | 4 | Sachunterricht | Ökosysteme | learning-unit-Sachunterricht-Ökosysteme | Übung Sachunterricht/Ökosysteme | Sachunterricht-Fragenbank (sach-Ökosysteme) | Sachunterricht | 16 | 4 | ok | Schulwissen |
| Lernhub | 4 | Sachunterricht | Geschichte | learning-unit-Sachunterricht-Geschichte | Übung Sachunterricht/Geschichte | Sachunterricht-Fragenbank (sach-Geschichte) | Sachunterricht | 16 | 4 | ok | Schulwissen |
| Lernhub | 4 | Sachunterricht | Geografie Österreich | learning-unit-Sachunterricht-Geografie Österreich | Übung Sachunterricht/Geografie Österreich | Sachunterricht-Fragenbank (sach-Geografie Österreich) | Sachunterricht | 15 | 4 | ok | Schulwissen |
| Lernhub | 4 | Sachunterricht | Kontinente und Ozeane | learning-unit-Sachunterricht-Kontinente und Ozeane | Übung Sachunterricht/Kontinente und Ozeane | Sachunterricht-Fragenbank (sach-Kontinente und Ozeane) | Sachunterricht | 17 | 4 | ok | Schulwissen |
| Lernhub | 4 | Sachunterricht | Diagramme lesen | learning-unit-Sachunterricht-Diagramme lesen | Übung Sachunterricht/Diagramme lesen | Sachunterricht-Fragenbank (sach-Diagramme lesen) | Sachunterricht | 13 | 4 | ok | Schulwissen |
| Lernhub | 4 | Lesen | Mit Lumo laut lesen | learning-active-reading | Lesebereich | Lesebereich (Geschichten) | – | – | 4 | ok | – |
| Lernhub | 4 | Lesen | Woerter lesen | learning-unit-Lesen-Woerter lesen | Übung Lesen/Woerter lesen | ExerciseFactory Lesen (lese-wort) | Lesen | 23 | 4 | ok | Schulwissen |
| Lernhub | 4 | Lesen | Sätze lesen | learning-unit-Lesen-Sätze lesen | Übung Lesen/Sätze lesen | ExerciseFactory Lesen (lese-text) | Lesen | 24 | 4 | ok | Schulwissen |
| Lernhub | 4 | Lesen | Lesesinn | learning-unit-Lesen-Lesesinn | Übung Lesen/Lesesinn | ExerciseFactory Lesen (lese-text) | Lesen | 24 | 4 | ok | Schulwissen |
| Lernhub | 4 | Lesen | Bild und Wort | learning-unit-Lesen-Bild und Wort | Übung Lesen/Bild und Wort | ExerciseFactory Lesen (lese-bild) | Lesen | 20 | 4 | ok | Schulwissen |
| Lernhub | 4 | Lesen | Reihenfolge | learning-unit-Lesen-Reihenfolge | Übung Lesen/Reihenfolge | ExerciseFactory Lesen (lese-reihenfolge) | Lesen | 88 | 4 | ok | Schulwissen |
| Lernhub | 4 | Rechtschreibung | Haeufige Woerter | learning-unit-Rechtschreibung-Haeufige Woerter | Übung Rechtschreibung/Haeufige Woerter | ExerciseFactory Rechtschreibung (rs-kontext+wort) | Rechtschreibung | 32 | 4 | ok | Schulwissen |
| Lernhub | 4 | Rechtschreibung | Gross und klein | learning-unit-Rechtschreibung-Gross und klein | Übung Rechtschreibung/Gross und klein | ExerciseFactory Rechtschreibung (gross) | Rechtschreibung | 95 | 4 | ok | Schulwissen |
| Lernhub | 4 | Rechtschreibung | Doppelmitlaut | learning-unit-Rechtschreibung-Doppelmitlaut | Übung Rechtschreibung/Doppelmitlaut | ExerciseFactory Rechtschreibung (doppel+rs-kontext) | Rechtschreibung | 22 | 4 | ok | Schulwissen |
| Lernhub | 4 | Rechtschreibung | Dehnungen | learning-unit-Rechtschreibung-Dehnungen | Übung Rechtschreibung/Dehnungen | ExerciseFactory Rechtschreibung (dehnung+rs-kontext) | Rechtschreibung | 20 | 4 | ok | Schulwissen |
| Lernhub | 4 | Rechtschreibung | Satzzeichen | learning-unit-Rechtschreibung-Satzzeichen | Übung Rechtschreibung/Satzzeichen | ExerciseFactory Rechtschreibung (punkt+rs-kontext) | Rechtschreibung | 24 | 4 | ok | Schulwissen |
| Lernhub | 4 | Rechtschreibung | Wortende | learning-unit-Rechtschreibung-Wortende | Übung Rechtschreibung/Wortende | ExerciseFactory Rechtschreibung (rs-verlaengern) | Rechtschreibung | 28 | 4 | ok | Schulwissen |
| Lernhub | 4 | Rechtschreibung | St oder Sp | learning-unit-Rechtschreibung-St oder Sp | Übung Rechtschreibung/St oder Sp | ExerciseFactory Rechtschreibung (stsp) | Rechtschreibung | 18 | 4 | ok | Schulwissen |
| Lernhub | 4 | Schreiben | Buchstaben nachspuren | learning-unit-Schreiben-Buchstaben nachspuren | Übung Schreiben/Buchstaben nachspuren | ExerciseFactory Schreiben (schreiben) | Schreiben | 18 | 4 | ok | Schulwissen |
| Lernhub | 4 | Schreiben | Wort schreiben | learning-unit-Schreiben-Wort schreiben | Übung Schreiben/Wort schreiben | ExerciseFactory Schreiben (schreiben) | Schreiben | 71 | 4 | ok | Schulwissen |
| Lernhub | 4 | Schreiben | Satz abschreiben | learning-unit-Schreiben-Satz abschreiben | Übung Schreiben/Satz abschreiben | ExerciseFactory Schreiben (schreiben) | Schreiben | 16 | 4 | ok | Schulwissen |
| Lernhub | 4 | Schreiben | Schwunguebung | learning-unit-Schreiben-Schwunguebung | Übung Schreiben/Schwunguebung | ExerciseFactory Schreiben (schreiben) | Schreiben | 16 | 4 | ok | Schulwissen |
| Lernhub | 4 | Schreiben | Zahlen schreiben | learning-unit-Schreiben-Zahlen schreiben | Übung Schreiben/Zahlen schreiben | ExerciseFactory Schreiben (schreiben) | Schreiben | 15 | 4 | ok | Schulwissen |
| Lernhub | 4 | Logik | Regeln kombinieren | learning-unit-Logik-Regeln kombinieren | Übung Logik/Regeln kombinieren | ExerciseFactory Logik (logik-regeln) | Logik | 117 | 4 | ok | Schulwissen |
| Lernhub | 4 | Musik | (Fach) | learning-extra-Musik | CurriculumActivitiesScreen | PrimaryActivityCatalog (2 Aktivitäten) | – | 2 | 4 | ok | – |
| Lernhub | 4 | Kunst und Gestaltung | (Fach) | learning-extra-Kunst und Gestaltung | CurriculumActivitiesScreen | PrimaryActivityCatalog (2 Aktivitäten) | – | 2 | 4 | ok | – |
| Lernhub | 4 | Technik und Design | (Fach) | learning-extra-Technik und Design | CurriculumActivitiesScreen | PrimaryActivityCatalog (2 Aktivitäten) | – | 2 | 4 | ok | – |
| Lernhub | 4 | Bewegung und Sport | (Fach) | learning-extra-Bewegung und Sport | CurriculumActivitiesScreen | PrimaryActivityCatalog (2 Aktivitäten) | – | 2 | 4 | ok | – |
| Lernhub | 4 | Verkehrs- und Mobilitätsbildung | (Fach) | learning-extra-Verkehrs- und Mobilitätsbildung | CurriculumActivitiesScreen | PrimaryActivityCatalog (2 Aktivitäten) | – | 2 | 4 | ok | – |
| Lernatelier | 4 | – | academy-stories | academy-stories | LumoStoryLibraryScreen | eigenes Modul | – | – | 4 | ok | – |
| Lernatelier | 4 | – | academy-activity-Deutsch | academy-activity-Deutsch | CurriculumActivitiesScreen | eigenes Modul | – | – | 4 | ok | – |
| Lernatelier | 4 | – | academy-activity-Englisch | academy-activity-Englisch | CurriculumActivitiesScreen | eigenes Modul | – | – | 4 | ok | – |
| Lernatelier | 4 | – | academy-activity-Sachunterricht | academy-activity-Sachunterricht | CurriculumActivitiesScreen | eigenes Modul | – | – | 4 | ok | – |
| Lernatelier | 4 | – | academy-tool-d4_aufsatz | academy-tool-d4_aufsatz | LumoWritingCoachScreen | eigenes Modul | – | – | 4 | ok | – |
| Lernatelier | 4 | – | akademie-learning-lab | akademie-learning-lab | LearningLabHub | eigenes Modul | – | – | 4 | ok | – |
| Lernatelier | 4 | – | akademie-guided-learning | akademie-guided-learning | GuidedLearningHub | eigenes Modul | – | – | 4 | ok | – |
| Lernatelier | 4 | – | akademie-voluntary-discovery | akademie-voluntary-discovery | GuidedLearningHub | eigenes Modul | – | – | 4 | ok | – |
| Tests | 1 | Mathematik | Stufe -1 (Kl. 1) | test-category-Mathematik+test-level--1+tests-start | Übung Mathematik/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Mathematik | 19 Rubriken | 1-1 | ok | Schulwissen+Vertiefung |
| Tests | 1 | Mathematik | Stufe 0 (Kl. 1) | test-category-Mathematik+test-level-0+tests-start | Übung Mathematik/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Mathematik | 19 Rubriken | 1-1 | ok | Schulwissen+Vertiefung |
| Tests | 1 | Mathematik | Stufe 1 (Kl. 2) | test-category-Mathematik+test-level-1+tests-start | Übung Mathematik/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Mathematik | 26 Rubriken | 1-2 | ok | Schulwissen+Vertiefung |
| Tests | 1 | Deutsch | Stufe -1 (Kl. 1) | test-category-Deutsch+test-level--1+tests-start | Übung Deutsch/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Deutsch+Lesen+Rechtschreibung | 25 Rubriken | 1-1 | ok | Schulwissen |
| Tests | 1 | Deutsch | Stufe 0 (Kl. 1) | test-category-Deutsch+test-level-0+tests-start | Übung Deutsch/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Deutsch+Lesen+Rechtschreibung | 25 Rubriken | 1-1 | ok | Schulwissen |
| Tests | 1 | Deutsch | Stufe 1 (Kl. 2) | test-category-Deutsch+test-level-1+tests-start | Übung Deutsch/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Deutsch+Lesen+Rechtschreibung | 33 Rubriken | 1-2 | ok | Schulwissen |
| Tests | 1 | Sachunterricht | Stufe -1 (Kl. 1) | test-category-Sachunterricht+test-level--1+tests-start | Übung Sachunterricht/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Sachunterricht | 11 Rubriken | 1-1 | ok | Schulwissen |
| Tests | 1 | Sachunterricht | Stufe 0 (Kl. 1) | test-category-Sachunterricht+test-level-0+tests-start | Übung Sachunterricht/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Sachunterricht | 11 Rubriken | 1-1 | ok | Schulwissen |
| Tests | 1 | Sachunterricht | Stufe 1 (Kl. 2) | test-category-Sachunterricht+test-level-1+tests-start | Übung Sachunterricht/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Sachunterricht | 12 Rubriken | 1-2 | ok | Schulwissen |
| Tests | 1 | Englisch | Stufe -1 (Kl. 1) | test-category-Englisch+test-level--1+tests-start | Übung Englisch/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Englisch | 7 Rubriken | 1-1 | ok | Schulwissen |
| Tests | 1 | Englisch | Stufe 0 (Kl. 1) | test-category-Englisch+test-level-0+tests-start | Übung Englisch/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Englisch | 7 Rubriken | 1-1 | ok | Schulwissen |
| Tests | 1 | Englisch | Stufe 1 (Kl. 2) | test-category-Englisch+test-level-1+tests-start | Übung Englisch/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Englisch | 8 Rubriken | 1-2 | ok | Schulwissen |
| Tests | 1 | Logik | Stufe -1 (Kl. 1) | test-category-Logik+test-level--1+tests-start | Übung Logik/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Logik | 3 Rubriken | 1-1 | ok | Schulwissen |
| Tests | 1 | Logik | Stufe 0 (Kl. 1) | test-category-Logik+test-level-0+tests-start | Übung Logik/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Logik | 3 Rubriken | 1-1 | ok | Schulwissen |
| Tests | 1 | Logik | Stufe 1 (Kl. 2) | test-category-Logik+test-level-1+tests-start | Übung Logik/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Logik | 5 Rubriken | 1-2 | ok | Schulwissen |
| Tests | 1 | Alle | Stufe -1 (Kl. 1) | test-category-Alle+test-level--1+tests-start | Übung Alle/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Deutsch+Englisch+Lesen+Mathematik+Rechtschreibung+Sachunterricht | 58 Rubriken | 1-1 | ok | Schulwissen+Vertiefung |
| Tests | 1 | Alle | Stufe 0 (Kl. 1) | test-category-Alle+test-level-0+tests-start | Übung Alle/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Deutsch+Englisch+Lesen+Mathematik+Rechtschreibung+Sachunterricht | 58 Rubriken | 1-1 | ok | Schulwissen+Vertiefung |
| Tests | 1 | Alle | Stufe 1 (Kl. 2) | test-category-Alle+test-level-1+tests-start | Übung Alle/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Deutsch+Englisch+Lesen+Mathematik+Rechtschreibung+Sachunterricht | 66 Rubriken | 1-2 | ok | Schulwissen+Vertiefung |
| Tests | 2 | Mathematik | Stufe -1 (Kl. 1) | test-category-Mathematik+test-level--1+tests-start | Übung Mathematik/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Mathematik | 19 Rubriken | 1-1 | ok | Schulwissen+Vertiefung |
| Tests | 2 | Mathematik | Stufe 0 (Kl. 2) | test-category-Mathematik+test-level-0+tests-start | Übung Mathematik/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Mathematik | 26 Rubriken | 1-2 | ok | Schulwissen+Vertiefung |
| Tests | 2 | Mathematik | Stufe 1 (Kl. 3) | test-category-Mathematik+test-level-1+tests-start | Übung Mathematik/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Mathematik | 32 Rubriken | 1-3 | ok | Schulwissen+Vertiefung |
| Tests | 2 | Deutsch | Stufe -1 (Kl. 1) | test-category-Deutsch+test-level--1+tests-start | Übung Deutsch/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Deutsch+Lesen+Rechtschreibung | 25 Rubriken | 1-1 | ok | Schulwissen |
| Tests | 2 | Deutsch | Stufe 0 (Kl. 2) | test-category-Deutsch+test-level-0+tests-start | Übung Deutsch/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Deutsch+Lesen+Rechtschreibung | 33 Rubriken | 1-2 | ok | Schulwissen |
| Tests | 2 | Deutsch | Stufe 1 (Kl. 3) | test-category-Deutsch+test-level-1+tests-start | Übung Deutsch/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Deutsch+Lesen+Rechtschreibung | 37 Rubriken | 1-3 | ok | Schulwissen |
| Tests | 2 | Sachunterricht | Stufe -1 (Kl. 1) | test-category-Sachunterricht+test-level--1+tests-start | Übung Sachunterricht/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Sachunterricht | 11 Rubriken | 1-1 | ok | Schulwissen |
| Tests | 2 | Sachunterricht | Stufe 0 (Kl. 2) | test-category-Sachunterricht+test-level-0+tests-start | Übung Sachunterricht/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Sachunterricht | 12 Rubriken | 1-2 | ok | Schulwissen |
| Tests | 2 | Sachunterricht | Stufe 1 (Kl. 3) | test-category-Sachunterricht+test-level-1+tests-start | Übung Sachunterricht/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Sachunterricht | 16 Rubriken | 1-3 | ok | Schulwissen |
| Tests | 2 | Englisch | Stufe -1 (Kl. 1) | test-category-Englisch+test-level--1+tests-start | Übung Englisch/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Englisch | 7 Rubriken | 1-1 | ok | Schulwissen |
| Tests | 2 | Englisch | Stufe 0 (Kl. 2) | test-category-Englisch+test-level-0+tests-start | Übung Englisch/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Englisch | 8 Rubriken | 1-2 | ok | Schulwissen |
| Tests | 2 | Englisch | Stufe 1 (Kl. 3) | test-category-Englisch+test-level-1+tests-start | Übung Englisch/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Englisch | 12 Rubriken | 1-3 | ok | Schulwissen |
| Tests | 2 | Logik | Stufe -1 (Kl. 1) | test-category-Logik+test-level--1+tests-start | Übung Logik/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Logik | 3 Rubriken | 1-1 | ok | Schulwissen |
| Tests | 2 | Logik | Stufe 0 (Kl. 2) | test-category-Logik+test-level-0+tests-start | Übung Logik/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Logik | 5 Rubriken | 1-2 | ok | Schulwissen |
| Tests | 2 | Logik | Stufe 1 (Kl. 3) | test-category-Logik+test-level-1+tests-start | Übung Logik/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Logik | 6 Rubriken | 1-3 | ok | Schulwissen |
| Tests | 2 | Alle | Stufe -1 (Kl. 1) | test-category-Alle+test-level--1+tests-start | Übung Alle/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Deutsch+Englisch+Lesen+Mathematik+Rechtschreibung+Sachunterricht | 59 Rubriken | 1-1 | ok | Schulwissen+Vertiefung |
| Tests | 2 | Alle | Stufe 0 (Kl. 2) | test-category-Alle+test-level-0+tests-start | Übung Alle/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Deutsch+Englisch+Lesen+Mathematik+Rechtschreibung+Sachunterricht | 61 Rubriken | 1-2 | ok | Schulwissen+Vertiefung |
| Tests | 2 | Alle | Stufe 1 (Kl. 3) | test-category-Alle+test-level-1+tests-start | Übung Alle/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Deutsch+Englisch+Lesen+Mathematik+Rechtschreibung+Sachunterricht | 69 Rubriken | 1-3 | ok | Schulwissen+Vertiefung |
| Tests | 3 | Mathematik | Stufe -1 (Kl. 2) | test-category-Mathematik+test-level--1+tests-start | Übung Mathematik/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Mathematik | 28 Rubriken | 1-2 | ok | Schulwissen+Vertiefung |
| Tests | 3 | Mathematik | Stufe 0 (Kl. 3) | test-category-Mathematik+test-level-0+tests-start | Übung Mathematik/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Mathematik | 33 Rubriken | 1-3 | ok | Schulwissen+Vertiefung |
| Tests | 3 | Mathematik | Stufe 1 (Kl. 4) | test-category-Mathematik+test-level-1+tests-start | Übung Mathematik/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Mathematik | 46 Rubriken | 1-4 | ok | Schulwissen+Vertiefung |
| Tests | 3 | Deutsch | Stufe -1 (Kl. 2) | test-category-Deutsch+test-level--1+tests-start | Übung Deutsch/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Deutsch+Lesen+Rechtschreibung | 33 Rubriken | 1-2 | ok | Schulwissen |
| Tests | 3 | Deutsch | Stufe 0 (Kl. 3) | test-category-Deutsch+test-level-0+tests-start | Übung Deutsch/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Deutsch+Lesen+Rechtschreibung | 35 Rubriken | 1-3 | ok | Schulwissen |
| Tests | 3 | Deutsch | Stufe 1 (Kl. 4) | test-category-Deutsch+test-level-1+tests-start | Übung Deutsch/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Deutsch+Lesen+Rechtschreibung | 39 Rubriken | 1-4 | ok | Schulwissen |
| Tests | 3 | Sachunterricht | Stufe -1 (Kl. 2) | test-category-Sachunterricht+test-level--1+tests-start | Übung Sachunterricht/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Sachunterricht | 12 Rubriken | 1-2 | ok | Schulwissen |
| Tests | 3 | Sachunterricht | Stufe 0 (Kl. 3) | test-category-Sachunterricht+test-level-0+tests-start | Übung Sachunterricht/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Sachunterricht | 15 Rubriken | 1-3 | ok | Schulwissen |
| Tests | 3 | Sachunterricht | Stufe 1 (Kl. 4) | test-category-Sachunterricht+test-level-1+tests-start | Übung Sachunterricht/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Sachunterricht | 21 Rubriken | 1-4 | ok | Schulwissen |
| Tests | 3 | Englisch | Stufe -1 (Kl. 2) | test-category-Englisch+test-level--1+tests-start | Übung Englisch/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Englisch | 8 Rubriken | 1-2 | ok | Schulwissen |
| Tests | 3 | Englisch | Stufe 0 (Kl. 3) | test-category-Englisch+test-level-0+tests-start | Übung Englisch/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Englisch | 12 Rubriken | 1-3 | ok | Schulwissen |
| Tests | 3 | Englisch | Stufe 1 (Kl. 4) | test-category-Englisch+test-level-1+tests-start | Übung Englisch/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Englisch | 16 Rubriken | 1-4 | ok | Schulwissen |
| Tests | 3 | Logik | Stufe -1 (Kl. 2) | test-category-Logik+test-level--1+tests-start | Übung Logik/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Logik | 5 Rubriken | 1-2 | ok | Schulwissen |
| Tests | 3 | Logik | Stufe 0 (Kl. 3) | test-category-Logik+test-level-0+tests-start | Übung Logik/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Logik | 6 Rubriken | 1-3 | ok | Schulwissen |
| Tests | 3 | Logik | Stufe 1 (Kl. 4) | test-category-Logik+test-level-1+tests-start | Übung Logik/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Logik | 7 Rubriken | 1-4 | ok | Schulwissen |
| Tests | 3 | Alle | Stufe -1 (Kl. 2) | test-category-Alle+test-level--1+tests-start | Übung Alle/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Deutsch+Englisch+Lesen+Mathematik+Rechtschreibung+Sachunterricht | 61 Rubriken | 1-2 | ok | Schulwissen+Vertiefung |
| Tests | 3 | Alle | Stufe 0 (Kl. 3) | test-category-Alle+test-level-0+tests-start | Übung Alle/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Deutsch+Englisch+Lesen+Mathematik+Rechtschreibung+Sachunterricht | 69 Rubriken | 1-3 | ok | Schulwissen+Vertiefung |
| Tests | 3 | Alle | Stufe 1 (Kl. 4) | test-category-Alle+test-level-1+tests-start | Übung Alle/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Deutsch+Englisch+Lesen+Mathematik+Rechtschreibung+Sachunterricht | 78 Rubriken | 1-4 | ok | Schulwissen+Vertiefung |
| Tests | 4 | Mathematik | Stufe -1 (Kl. 3) | test-category-Mathematik+test-level--1+tests-start | Übung Mathematik/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Mathematik | 34 Rubriken | 1-3 | ok | Schulwissen+Vertiefung |
| Tests | 4 | Mathematik | Stufe 0 (Kl. 4) | test-category-Mathematik+test-level-0+tests-start | Übung Mathematik/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Mathematik | 38 Rubriken | 1-4 | ok | Schulwissen+Vertiefung |
| Tests | 4 | Mathematik | Stufe 1 (Kl. 4) | test-category-Mathematik+test-level-1+tests-start | Übung Mathematik/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Mathematik | 38 Rubriken | 1-4 | ok | Schulwissen+Vertiefung |
| Tests | 4 | Deutsch | Stufe -1 (Kl. 3) | test-category-Deutsch+test-level--1+tests-start | Übung Deutsch/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Deutsch+Lesen+Rechtschreibung | 36 Rubriken | 1-3 | ok | Schulwissen |
| Tests | 4 | Deutsch | Stufe 0 (Kl. 4) | test-category-Deutsch+test-level-0+tests-start | Übung Deutsch/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Deutsch+Lesen+Rechtschreibung | 44 Rubriken | 1-4 | ok | Schulwissen |
| Tests | 4 | Deutsch | Stufe 1 (Kl. 4) | test-category-Deutsch+test-level-1+tests-start | Übung Deutsch/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Deutsch+Lesen+Rechtschreibung | 44 Rubriken | 1-4 | ok | Schulwissen |
| Tests | 4 | Sachunterricht | Stufe -1 (Kl. 3) | test-category-Sachunterricht+test-level--1+tests-start | Übung Sachunterricht/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Sachunterricht | 16 Rubriken | 1-3 | ok | Schulwissen |
| Tests | 4 | Sachunterricht | Stufe 0 (Kl. 4) | test-category-Sachunterricht+test-level-0+tests-start | Übung Sachunterricht/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Sachunterricht | 20 Rubriken | 1-4 | ok | Schulwissen |
| Tests | 4 | Sachunterricht | Stufe 1 (Kl. 4) | test-category-Sachunterricht+test-level-1+tests-start | Übung Sachunterricht/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Sachunterricht | 20 Rubriken | 1-4 | ok | Schulwissen |
| Tests | 4 | Englisch | Stufe -1 (Kl. 3) | test-category-Englisch+test-level--1+tests-start | Übung Englisch/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Englisch | 12 Rubriken | 1-3 | ok | Schulwissen |
| Tests | 4 | Englisch | Stufe 0 (Kl. 4) | test-category-Englisch+test-level-0+tests-start | Übung Englisch/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Englisch | 16 Rubriken | 1-4 | ok | Schulwissen |
| Tests | 4 | Englisch | Stufe 1 (Kl. 4) | test-category-Englisch+test-level-1+tests-start | Übung Englisch/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Englisch | 16 Rubriken | 1-4 | ok | Schulwissen |
| Tests | 4 | Logik | Stufe -1 (Kl. 3) | test-category-Logik+test-level--1+tests-start | Übung Logik/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Logik | 6 Rubriken | 1-3 | ok | Schulwissen |
| Tests | 4 | Logik | Stufe 0 (Kl. 4) | test-category-Logik+test-level-0+tests-start | Übung Logik/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Logik | 7 Rubriken | 1-4 | ok | Schulwissen |
| Tests | 4 | Logik | Stufe 1 (Kl. 4) | test-category-Logik+test-level-1+tests-start | Übung Logik/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Logik | 7 Rubriken | 1-4 | ok | Schulwissen |
| Tests | 4 | Alle | Stufe -1 (Kl. 3) | test-category-Alle+test-level--1+tests-start | Übung Alle/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Deutsch+Englisch+Lesen+Mathematik+Rechtschreibung+Sachunterricht | 69 Rubriken | 1-3 | ok | Schulwissen+Vertiefung |
| Tests | 4 | Alle | Stufe 0 (Kl. 4) | test-category-Alle+test-level-0+tests-start | Übung Alle/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Deutsch+Englisch+Lesen+Mathematik+Rechtschreibung+Sachunterricht | 76 Rubriken | 1-4 | ok | Schulwissen+Vertiefung |
| Tests | 4 | Alle | Stufe 1 (Kl. 4) | test-category-Alle+test-level-1+tests-start | Übung Alle/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Deutsch+Englisch+Lesen+Mathematik+Rechtschreibung+Sachunterricht | 76 Rubriken | 1-4 | ok | Schulwissen+Vertiefung |
| Tests | 1-4 | Knobeln | Lumo Knobel-Test | iq-test-start | IqTestScreen | IqPuzzleGenerator | Logik | – | – | ok | – |
| Tests | 1-4 | Denken | Denkprofil | cognitive-profile-start | CognitiveProfileScreen | CognitiveProfileGenerator | Logik | – | – | ok | – |
| Schularbeit | 1-4 | Alle | Gemischter Lerncheck | Text: Gemischter Lerncheck | Übung Alle/Alle (schoolwork, 30 Fragen) | ExerciseFactory.next gradedOnly | Deutsch+Englisch+Lesen+Mathematik+Rechtschreibung+Sachunterricht | – | – | ok | Schulwissen+Vertiefung |
| Schularbeit | 1-4 | Mathematik | Mathe-Schularbeit | Text: Mathe-Schularbeit | Übung Mathematik/Alle (schoolwork, 30 Fragen) | ExerciseFactory.next gradedOnly | Mathematik | – | – | ok | Schulwissen+Vertiefung |
| Schularbeit | 1-4 | Deutsch | Deutsch-Schularbeit | Text: Deutsch-Schularbeit | Übung Deutsch/Alle (schoolwork, 30 Fragen) | ExerciseFactory.next gradedOnly | Deutsch+Lesen+Rechtschreibung | – | – | ok | Schulwissen |
| Schularbeit | 1-4 | Sachunterricht | Sachunterricht-Lerncheck | Text: Sachunterricht-Lerncheck | Übung Sachunterricht/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Sachunterricht | – | – | ok | Schulwissen |
| Schularbeit | 1-4 | Englisch | Englisch-Lerncheck | Text: Englisch-Lerncheck | Übung Englisch/Alle (test, 10 Fragen) | ExerciseFactory.next gradedOnly | Englisch | – | – | ok | Schulwissen |
| Schularbeit | 1-4 | Alle | Schnelle Wiederholung | Text: Schnelle Wiederholung | Übung Alle/Alle (exerciseSet, 20 Fragen) | ExerciseFactory.next | Deutsch+Englisch+Lesen+Mathematik+Rechtschreibung+Sachunterricht+Schreiben | – | – | ok | Schulwissen+Vertiefung |
| Akademie-Thema | 1 | Mathematik | Zahlen 1-10 | m1_zahlen10 | eigenes Lernmodul | MathTaskTemplates g1_quantity_compare | – | – | 1 | ok | Schulwissen |
| Akademie-Thema | 1 | Mathematik | Plus bis 10 | m1_plus10 | eigenes Lernmodul | MathTaskTemplates g1_add_10 | – | – | 1 | ok | Schulwissen |
| Akademie-Thema | 1 | Mathematik | Minus bis 10 | m1_minus10 | eigenes Lernmodul | MathTaskTemplates g1_sub_10 | – | – | 1 | ok | Schulwissen |
| Akademie-Thema | 1 | Mathematik | Plus bis 20 | m1_plus20 | Übung Mathematik/Plus bis 20 | MathTaskTemplates g1_add_20 | – | – | 1 | ok | Schulwissen |
| Akademie-Thema | 1 | Mathematik | Minus bis 20 | m1_minus20 | Übung Mathematik/Minus bis 20 | MathTaskTemplates g1_sub_20 | – | – | 1 | ok | Schulwissen |
| Akademie-Thema | 1 | Mathematik | Formen | m1_formen | eigenes Lernmodul | MathTaskTemplates g1_shapes | – | – | 1 | ok | Schulwissen |
| Akademie-Thema | 1 | Deutsch | ✨ Schreibcoach LIVE | d1_schreibcoach | Sonderweg (Geschichten/Schreiben/Chat) | – | – | – | 1 | ok | – |
| Akademie-Thema | 1 | Deutsch | Alle Buchstaben A-Z | d1_buchstaben_alle | Übung Deutsch/Buchstaben-Lautierung | GermanTaskTemplates g1_letter_sound | – | – | 1 | ok | Schulwissen |
| Akademie-Thema | 1 | Deutsch | Erste Wörter | d1_woerter | eigenes Lernmodul | GermanTaskTemplates g1_word_image | – | – | 1 | ok | Schulwissen |
| Akademie-Thema | 1 | Sachunterricht | Tiere | s1_tiere | eigenes Lernmodul | Sachunterricht-Fragenbank | – | – | 1 | ok | Schulwissen |
| Akademie-Thema | 1 | Sachunterricht | Pflanzen | s1_pflanzen | Übung Sachunterricht/Pflanzen | Sachunterricht-Fragenbank | – | – | 1 | ok | Schulwissen |
| Akademie-Thema | 1 | Sachunterricht | Mein Körper | s1_koerper | Übung Sachunterricht/Körper | Sachunterricht-Fragenbank | – | – | 1 | ok | Schulwissen |
| Akademie-Thema | 1 | Englisch | Farben | en1_1 | Übung Englisch/Farben | Englisch-Wortschatz | – | – | 1 | ok | Schulwissen |
| Akademie-Thema | 1 | Englisch | Tiere | en1_2 | Übung Englisch/Tiere | Englisch-Wortschatz | – | – | 1 | ok | Schulwissen |
| Akademie-Thema | 1 | Englisch | Begrüßung | en1_3 | Übung Englisch/Begruessung | Englisch-Wortschatz | – | – | 1 | ok | Schulwissen |
| Akademie-Thema | 2 | Mathematik | Zahlen bis 100 | m2_zahlen100 | eigenes Lernmodul | – | – | – | 2 | ok | – |
| Akademie-Thema | 2 | Mathematik | Plus bis 100 | m2_plus100 | Übung Mathematik/Plus bis 100 | MathTaskTemplates g2_add_100 | – | – | 2 | ok | Schulwissen |
| Akademie-Thema | 2 | Mathematik | Minus bis 100 | m2_minus100 | Übung Mathematik/Minus bis 100 | MathTaskTemplates g2_sub_100 | – | – | 2 | ok | Schulwissen |
| Akademie-Thema | 2 | Mathematik | Kleines 1×1 | m2_einmaleins | eigenes Lernmodul | MathTaskTemplates g2_times_prep | – | – | 2 | ok | Schulwissen |
| Akademie-Thema | 2 | Mathematik | Die Uhr | m2_uhr | eigenes Lernmodul | MathTaskTemplates g2_clock | – | – | 2 | ok | Schulwissen |
| Akademie-Thema | 2 | Mathematik | Geld | m2_geld | eigenes Lernmodul | MathTaskTemplates g2_money_change | – | – | 2 | ok | Schulwissen |
| Akademie-Thema | 2 | Deutsch | Sätze bilden | d2_saetze | Übung Deutsch/Erste Sätze | GermanTaskTemplates g1_sentence_order+g1_sentence_build+g1_sentence_read | – | – | 2 | ok | Schulwissen |
| Akademie-Thema | 2 | Deutsch | Der/Die/Das | d2_artikel | eigenes Lernmodul | GermanTaskTemplates g1_articles | – | – | 2 | ok | Schulwissen |
| Akademie-Thema | 2 | Deutsch | Mehrzahl | d2_mehrzahl | eigenes Lernmodul | GermanTaskTemplates g2_plural | – | – | 2 | ok | Schulwissen |
| Akademie-Thema | 2 | Sachunterricht | Jahreszeiten | s2_jahreszeiten | eigenes Lernmodul | Sachunterricht-Fragenbank | – | – | 2 | ok | Schulwissen |
| Akademie-Thema | 2 | Sachunterricht | Wetter | s2_wetter | eigenes Lernmodul | Sachunterricht-Fragenbank | – | – | 2 | ok | Schulwissen |
| Akademie-Thema | 2 | Sachunterricht | Verkehr | s2_verkehr | eigenes Lernmodul | Sachunterricht-Fragenbank | – | – | 2 | ok | Schulwissen |
| Akademie-Thema | 2 | Englisch | Zahlen | en2_1 | Übung Englisch/Zahlen | Englisch-Wortschatz | – | – | 2 | ok | Schulwissen |
| Akademie-Thema | 2 | Englisch | Körper | en2_2 | Übung Englisch/Körper | Englisch-Wortschatz | – | – | 2 | ok | Schulwissen |
| Akademie-Thema | 2 | Englisch | Spielzeug | en2_3 | Übung Englisch/Spielzeug | Englisch-Wortschatz | – | – | 2 | ok | Schulwissen |
| Akademie-Thema | 3 | Mathematik | Plus bis 1000 | m3_zahlen1000 | Übung Mathematik/Plus bis 1000 | MathTaskTemplates g3_add_1000 | – | – | 3 | ok | Schulwissen |
| Akademie-Thema | 3 | Mathematik | Minus bis 1000 | m3_minus1000 | Übung Mathematik/Minus bis 1000 | MathTaskTemplates g3_sub_1000 | – | – | 3 | ok | Schulwissen |
| Akademie-Thema | 3 | Mathematik | 1×1 – alle Reihen | m3_einmaleins_voll | eigenes Lernmodul | MathTaskTemplates g2_tables+g3_tables | – | – | 3 | ok | Schulwissen |
| Akademie-Thema | 3 | Mathematik | Umfang | m3_geometrie | Übung Mathematik/Umfang | MathTaskTemplates g3_perimeter | – | – | 3 | ok | Schulwissen |
| Akademie-Thema | 3 | Mathematik | Schriftliche Addition | m3_schrift_add | Übung Mathematik/Schriftliche Addition | MathTaskTemplates g3_written_add | – | – | 3 | ok | Schulwissen |
| Akademie-Thema | 3 | Mathematik | Schriftliche Subtraktion | m3_schrift_sub | Übung Mathematik/Schriftliche Subtraktion | MathTaskTemplates g3_written_sub | – | – | 3 | ok | Schulwissen |
| Akademie-Thema | 3 | Mathematik | Division einstellig | m3_division | Übung Mathematik/Division einstellig | MathTaskTemplates g3_division_basic | – | – | 3 | ok | Schulwissen |
| Akademie-Thema | 3 | Mathematik | Sachaufgaben zwei Schritte | m3_sachaufgaben | Übung Mathematik/Sachaufgaben zwei Schritte | MathTaskTemplates g3_two_step | – | – | 3 | ok | Vertiefung |
| Akademie-Thema | 3 | Mathematik | Massen Kilogramm und Gramm | m3_gewicht | Übung Mathematik/Massen Kilogramm und Gramm | MathTaskTemplates g3_mass | – | – | 3 | ok | Schulwissen |
| Akademie-Thema | 3 | Deutsch | Wortarten | d3_wortarten | eigenes Lernmodul | GermanTaskTemplates g3_word_types | – | – | 3 | ok | Schulwissen |
| Akademie-Thema | 3 | Deutsch | Zeitformen | d3_zeitformen | eigenes Lernmodul | GermanTaskTemplates g3_tense | – | – | 3 | ok | Schulwissen |
| Akademie-Thema | 3 | Deutsch | Geschichten | d3_geschichten | Sonderweg (Geschichten/Schreiben/Chat) | – | – | – | 3 | ok | – |
| Akademie-Thema | 3 | Deutsch | Großschreibung | d3_grossschreibung | Übung Deutsch/Großschreibung | GermanTaskTemplates g3_capitalization | – | – | 3 | ok | Schulwissen |
| Akademie-Thema | 3 | Deutsch | Wer-Fall und Wen-Fall | d3_faelle | Übung Deutsch/Wer-Fall und Wen-Fall | GermanTaskTemplates g3_case_nom_akk | – | – | 3 | ok | Schulwissen |
| Akademie-Thema | 3 | Deutsch | Verbformen | d3_verbformen | Übung Deutsch/Verbformen | GermanTaskTemplates g3_verb_form | – | – | 3 | ok | Schulwissen |
| Akademie-Thema | 3 | Deutsch | ie oder i | d3_ie | Übung Deutsch/ie oder i | GermanTaskTemplates g3_ie_or_i | – | – | 3 | ok | Schulwissen |
| Akademie-Thema | 3 | Sachunterricht | Bundesländer | s3_oesterreich | Übung Sachunterricht/Bundesländer Österreichs | Sachunterricht-Fragenbank | – | – | 3 | ok | Schulwissen |
| Akademie-Thema | 3 | Sachunterricht | Pflanzen | s3_natur | Übung Sachunterricht/Pflanzen | Sachunterricht-Fragenbank | – | – | 3 | ok | Schulwissen |
| Akademie-Thema | 3 | Sachunterricht | Tiere | s3_tiere | Übung Sachunterricht/Tiere | Sachunterricht-Fragenbank | – | – | 3 | ok | Schulwissen |
| Akademie-Thema | 3 | Sachunterricht | Wetter | s3_wetter | Übung Sachunterricht/Wetter | Sachunterricht-Fragenbank | – | – | 3 | ok | Schulwissen |
| Akademie-Thema | 3 | Sachunterricht | Verkehr | s3_verkehr | Übung Sachunterricht/Verkehr | Sachunterricht-Fragenbank | – | – | 3 | ok | Schulwissen |
| Akademie-Thema | 3 | Sachunterricht | Wasserkreislauf | s3_wasser | Übung Sachunterricht/Wasserkreislauf | Sachunterricht-Fragenbank | – | – | 3 | ok | Schulwissen |
| Akademie-Thema | 3 | Sachunterricht | Ernährung | s3_ernaehrung | Übung Sachunterricht/Ernährung | Sachunterricht-Fragenbank | – | – | 3 | ok | Schulwissen |
| Akademie-Thema | 3 | Sachunterricht | Zeit und Kalender | s3_zeit | Übung Sachunterricht/Zeit und Kalender | Sachunterricht-Fragenbank | – | – | 3 | ok | Schulwissen |
| Akademie-Thema | 3 | Sachunterricht | Berufe | s3_berufe | Übung Sachunterricht/Berufe | Sachunterricht-Fragenbank | – | – | 3 | ok | Schulwissen |
| Akademie-Thema | 3 | Englisch | Wetter | en3_1 | Übung Englisch/Wetter | Englisch-Wortschatz | – | – | 3 | ok | Schulwissen |
| Akademie-Thema | 3 | Englisch | Essen | en3_2 | Übung Englisch/Essen | Englisch-Wortschatz | – | – | 3 | ok | Schulwissen |
| Akademie-Thema | 3 | Englisch | Schulsachen | en3_3 | Übung Englisch/Schulsachen | Englisch-Wortschatz | – | – | 3 | ok | Schulwissen |
| Akademie-Thema | 3 | Englisch | Tageszeit | en3_4 | Übung Englisch/Tageszeit | Englisch-Wortschatz | – | – | 3 | ok | Schulwissen |
| Akademie-Thema | 3 | Englisch | Alltagssätze | en3_5 | Übung Englisch/Alltagssätze | Englisch-Wortschatz | – | – | 3 | ok | Schulwissen |
| Akademie-Thema | 4 | Mathematik | Zahlen bis 1 Million | m4_million | Übung Mathematik/Zahlenraum bis 1 Million | MathTaskTemplates g4_compare_1mio | – | – | 4 | ok | Schulwissen |
| Akademie-Thema | 4 | Mathematik | Brüche erkennen | m4_bruch | eigenes Lernmodul | MathTaskTemplates g4_fraction_add | – | – | 4 | ok | Schulwissen |
| Akademie-Thema | 4 | Mathematik | Textaufgaben | m4_textaufgaben | Übung Mathematik/Sachaufgaben drei Schritte | MathTaskTemplates g4_three_step | – | – | 4 | ok | Vertiefung |
| Akademie-Thema | 4 | Mathematik | Schriftliche Multiplikation | m4_multiplikation | Übung Mathematik/Schriftliche Multiplikation | MathTaskTemplates g4_written_mul | – | – | 4 | ok | Schulwissen |
| Akademie-Thema | 4 | Mathematik | Schriftliche Division | m4_division | Übung Mathematik/Schriftliche Division | MathTaskTemplates g4_written_div | – | – | 4 | ok | Schulwissen |
| Akademie-Thema | 4 | Mathematik | Dezimalzahlen | m4_dezimal | Übung Mathematik/Dezimalzahlen | MathTaskTemplates g4_decimal | – | – | 4 | ok | Lumo Expertenwelt |
| Akademie-Thema | 4 | Mathematik | Brüche erweitern | m4_bruch_erweitern | Übung Mathematik/Brüche erweitern | MathTaskTemplates g4_fraction_expand | – | – | 4 | ok | Lumo Expertenwelt |
| Akademie-Thema | 4 | Mathematik | Diagramme lesen | m4_diagramme | Übung Mathematik/Diagramme lesen | MathTaskTemplates g4_chart+g4_chart_collection | – | – | 4 | ok | Schulwissen |
| Akademie-Thema | 4 | Deutsch | Die 4 Fälle | d4_grammatik | Übung Deutsch/Die 4 Fälle | GermanTaskTemplates g4_four_cases | – | – | 4 | ok | Schulwissen |
| Akademie-Thema | 4 | Deutsch | Aufsätze | d4_aufsatz | Sonderweg (Geschichten/Schreiben/Chat) | – | – | – | 4 | ok | – |
| Akademie-Thema | 4 | Deutsch | Satzglieder | d4_satzglieder | Übung Deutsch/Satzglieder | GermanTaskTemplates g4_sentence_parts | – | – | 4 | ok | Schulwissen |
| Akademie-Thema | 4 | Deutsch | Direkte Rede | d4_direkte | Übung Deutsch/Direkte Rede | GermanTaskTemplates g4_direct_speech | – | – | 4 | ok | Schulwissen |
| Akademie-Thema | 4 | Deutsch | dass oder das | d4_dassdas | Übung Deutsch/dass oder das | GermanTaskTemplates g4_dass_das | – | – | 4 | ok | Schulwissen |
| Akademie-Thema | 4 | Deutsch | Zusammensetzungen | d4_zusammensetzung | Übung Deutsch/Zusammensetzungen | GermanTaskTemplates g4_compounds | – | – | 4 | ok | Schulwissen |
| Akademie-Thema | 4 | Sachunterricht | Kontinente und Ozeane | s4_europa | Übung Sachunterricht/Kontinente und Ozeane | Sachunterricht-Fragenbank | – | – | 4 | ok | Schulwissen |
| Akademie-Thema | 4 | Sachunterricht | Geschichte | s4_geschichte | Übung Sachunterricht/Geschichte | Sachunterricht-Fragenbank | – | – | 4 | ok | Schulwissen |
| Akademie-Thema | 4 | Sachunterricht | Ökosysteme | s4_oekosystem | Übung Sachunterricht/Ökosysteme | Sachunterricht-Fragenbank | – | – | 4 | ok | Schulwissen |
| Akademie-Thema | 4 | Sachunterricht | Stromkreise | s4_strom | Übung Sachunterricht/Stromkreise | Sachunterricht-Fragenbank | – | – | 4 | ok | Schulwissen |
| Akademie-Thema | 4 | Sachunterricht | Diagramme lesen | s4_diagramme | Übung Sachunterricht/Diagramme lesen | Sachunterricht-Fragenbank | – | – | 4 | ok | Schulwissen |
| Akademie-Thema | 4 | Sachunterricht | Geografie Österreich | s4_geografie | Übung Sachunterricht/Geografie Österreich | Sachunterricht-Fragenbank | – | – | 4 | ok | Schulwissen |
| Akademie-Thema | 4 | Englisch | Verben | en4_1 | Übung Englisch/Verben | Englisch-Wortschatz | – | – | 4 | ok | Schulwissen |
| Akademie-Thema | 4 | Englisch | Wochentage | en4_2 | Übung Englisch/Wochentage | Englisch-Wortschatz | – | – | 4 | ok | Schulwissen |
| Akademie-Thema | 4 | Englisch | Hobbys | en4_3 | Übung Englisch/Hobbys | Englisch-Wortschatz | – | – | 4 | ok | Schulwissen |
| Akademie-Thema | 4 | Englisch | Länder | en4_4 | Übung Englisch/Länder | Englisch-Wortschatz | – | – | 4 | ok | Schulwissen |
| Akademie-Thema | 4 | Englisch | Alltagssätze | en4_5 | Übung Englisch/Alltagssätze | Englisch-Wortschatz | – | – | 4 | ok | Schulwissen |
| Lernspiel | 1 | Mathe | Plus bis 5 | level-1 | starsPath | MiniGameLearningDeck | – | – | 1 | ok | – |
| Lernspiel | 1 | Mathe | Mengen anmalen | level-2 | colorBoxes | MiniGameLearningDeck | – | – | 1 | ok | – |
| Lernspiel | 1 | Mathe | Plus bis 7 | level-3 | starsPath | MiniGameLearningDeck | – | – | 1 | ok | – |
| Lernspiel | 1 | Mathe | Punkt-Gruppen | level-4 | starsPath | MiniGameLearningDeck | – | – | 1 | ok | – |
| Lernspiel | 1 | Mathe | Plus bis 10 | level-5 | numberHouse | MiniGameLearningDeck | – | – | 1 | ok | – |
| Lernspiel | 1 | Mathe | Mengen bis 10 | level-6 | starsPath | MiniGameLearningDeck | – | – | 1 | ok | – |
| Lernspiel | 1 | Mathe | Zerlege 7 | level-7 | numberHouse | MiniGameLearningDeck | – | – | 1 | ok | – |
| Lernspiel | 1 | Mathe | Zerlege 9 | level-8 | numberHouse | MiniGameLearningDeck | – | – | 1 | ok | – |
| Lernspiel | 1 | Mathe | Plus-Tricks | level-9 | starsPath | MiniGameLearningDeck | – | – | 1 | ok | – |
| Lernspiel | 1 | Mathe | Plus-Meister | level-10 | mixedQuiz | MiniGameLearningDeck | – | – | 1 | ok | – |
| Lernspiel | 1 | Mathe | Minus bis 5 | level-11 | starsPath | MiniGameLearningDeck | – | – | 1 | ok | – |
| Lernspiel | 1 | Mathe | Minus bis 10 | level-12 | starsPath | MiniGameLearningDeck | – | – | 1 | ok | – |
| Lernspiel | 1 | Mathe | Zahlenweg 1-10 | level-13 | numberPath | MiniGameLearningDeck | – | – | 1 | ok | – |
| Lernspiel | 1 | Mathe | Welche Zahl fehlt? | level-14 | numberPath | MiniGameLearningDeck | – | – | 1 | ok | – |
| Lernspiel | 2 | Mathe | Zehnerübergang | level-15 | numberHouse | MiniGameLearningDeck | – | – | 2 | ok | – |
| Lernspiel | 2 | Mathe | Plus bis 20 | level-16 | starsPath | MiniGameLearningDeck | – | – | 2 | ok | – |
| Lernspiel | 2 | Mathe | Minus bis 20 | level-17 | starsPath | MiniGameLearningDeck | – | – | 2 | ok | – |
| Lernspiel | 2 | Mathe | Zahlen vergleichen | level-18 | numberPath | MiniGameLearningDeck | – | – | 2 | ok | – |
| Lernspiel | 2 | Mathe | Verdoppeln | level-19 | numberHouse | MiniGameLearningDeck | – | – | 2 | ok | – |
| Lernspiel | 2 | Mathe | Minus-Meister | level-20 | mixedQuiz | MiniGameLearningDeck | – | – | 2 | ok | – |
| Lernspiel | 1 | Deutsch | Anfangslaute | level-21 | wordForest | MiniGameLearningDeck | – | – | 1 | ok | – |
| Lernspiel | 1 | Deutsch | Endlaute | level-22 | wordForest | MiniGameLearningDeck | – | – | 1 | ok | – |
| Lernspiel | 1 | Deutsch | Silben klatschen | level-23 | wordForest | MiniGameLearningDeck | – | – | 1 | ok | – |
| Lernspiel | 1 | Deutsch | Reime finden | level-24 | wordForest | MiniGameLearningDeck | – | – | 1 | ok | – |
| Lernspiel | 1 | Deutsch | Wort und Bild | level-25 | letterFill | MiniGameLearningDeck | – | – | 1 | ok | – |
| Lernspiel | 1 | Deutsch | Kurze Wörter | level-26 | wordForest | MiniGameLearningDeck | – | – | 1 | ok | – |
| Lernspiel | 2 | Deutsch | Artikel der/die/das | level-27 | wordForest | MiniGameLearningDeck | – | – | 2 | ok | – |
| Lernspiel | 2 | Deutsch | Einzahl - Mehrzahl | level-28 | wordForest | MiniGameLearningDeck | – | – | 2 | ok | – |
| Lernspiel | 2 | Deutsch | Wortfamilien | level-29 | wordForest | MiniGameLearningDeck | – | – | 2 | ok | – |
| Lernspiel | 2 | Deutsch | Lese-Meister | level-30 | mixedQuiz | MiniGameLearningDeck | – | – | 2 | ok | – |
| Lernspiel | 2 | Mathe | Einkaufen | level-31 | mixedQuiz | MiniGameLearningDeck | – | – | 2 | ok | – |
| Lernspiel | 2 | Mathe | Uhrzeit | level-32 | mixedQuiz | MiniGameLearningDeck | – | – | 2 | ok | – |
| Lernspiel | 2 | Sachunterricht | Tier-Logik | level-33 | mixedQuiz | MiniGameLearningDeck | – | – | 2 | ok | – |
| Lernspiel | 2 | Sachunterricht | Wetter | level-34 | mixedQuiz | MiniGameLearningDeck | – | – | 2 | ok | – |
| Lernspiel | 2 | Sachunterricht | Pflanzen | level-35 | mixedQuiz | MiniGameLearningDeck | – | – | 2 | ok | – |
| Lernspiel | 3 | Mathe | Zählen in Sprüngen | level-36 | numberPath | MiniGameLearningDeck | – | – | 3 | ok | – |
| Lernspiel | 3 | Mathe | Verdoppeln-Halbieren | level-37 | numberHouse | MiniGameLearningDeck | – | – | 3 | ok | – |
| Lernspiel | 3 | Deutsch | Wortarten | level-38 | wordForest | MiniGameLearningDeck | – | – | 3 | ok | – |
| Lernspiel | 2 | Mathe | Plus bis 100 | level-39 | starsPath | MiniGameLearningDeck | – | – | 2 | ok | – |
| Lernspiel | 3 | Mix | Logik-Meister | level-40 | mixedQuiz | MiniGameLearningDeck | – | – | 3 | ok | – |
| Lernspiel | 2 | Mathe | Einmaleins Start | level-41 | starsPath | MiniGameLearningDeck | – | – | 2 | ok | – |
| Lernspiel | 2 | Mathe | Einmaleins 3er | level-42 | starsPath | MiniGameLearningDeck | – | – | 2 | ok | – |
| Lernspiel | 3 | Deutsch | Synonyme | level-43 | wordForest | MiniGameLearningDeck | – | – | 3 | ok | – |
| Lernspiel | 3 | Deutsch | Zeitformen | level-44 | wordForest | MiniGameLearningDeck | – | – | 3 | ok | – |
| Lernspiel | 2 | Mathe | Minus bis 100 | level-45 | starsPath | MiniGameLearningDeck | – | – | 2 | ok | – |
| Lernspiel | 2 | Mathe | Einmaleins 10er | level-46 | starsPath | MiniGameLearningDeck | – | – | 2 | ok | – |
| Lernspiel | 4 | Deutsch | Satzbau | level-47 | wordForest | MiniGameLearningDeck | – | – | 4 | ok | – |
| Lernspiel | 3 | Mathe | Schriftliches Plus | level-48 | starsPath | MiniGameLearningDeck | – | – | 3 | ok | – |
| Lernspiel | 3 | Mathe | Schriftliches Minus | level-49 | starsPath | MiniGameLearningDeck | – | – | 3 | ok | – |
| Lernspiel | 4 | Mix | Lumo-Meister | level-50 | mixedQuiz | MiniGameLearningDeck | – | – | 4 | ok | – |
