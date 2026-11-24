# Aufgaben-Audit Lumo Lernen – 24.11.2026

Basis: `repair/lumo-device-bugs-2078` @ 94cabcff. Branch: `lumo-hauptbot/lernen-modernisierung-20261124`. Nur gelesen, keine Kategorie geändert.

## Methode

- Generator `ExerciseFactory.nextExact` (lib/core/school_exercise_generator.dart) für jedes Fach in `Curriculum.subjects`, Klasse 1–4, jede Einheit aus `Curriculum.unitsForGrade`.
- 60 Aufgaben je Einheit. Lauf A: `currentGradeOnly: true` (236 Einheiten). Lauf B: `currentGradeOnly: false` (447 Klasse×Einheit-Kombinationen).
- Geprüft: zurückgegebene Einheit = gewählte Einheit, Fach = gewähltes Fach, Klasse = gewählte Klasse. Bei `Plus/Minus bis N`: jede Rechnung im Text hat die richtige Rechenart, keine Zahl und kein Ergebnis über N, nichts negativ, mindestens eine Rechnung im Text.
- Zusätzlich: JSON-Fragen `assets/learning_questions/*.json`, Akademie-Zuordnung `lib/core/curriculum/academy_topic_units.dart`.

## Ergebnis

- **Generator: 0 Fehlzuordnungen** in beiden Läufen (0 falsche Einheit, 0 falsches Fach, 0 falsche Klasse, 0 falsche Rechenart, 0 Zahlen über der Grenze, 0 Ausnahmen).
- JSON-Fragen: grade1_math 50 Fragen (nur + und −, max. 20; 17 ohne Rechenausdruck), grade2_math 50 Fragen (nur + und −, max. 100; 20 ohne Rechenausdruck). Keine Kategorie-Felder vorhanden, daher keine Rubrikprüfung möglich.
- **Akademie-Kacheln mit abweichendem Ziel (Titel ≠ geübte Einheit)**, Quelle `academy_topic_units.dart` Z. 8–33 und `lumo_akademie_screen.dart`:

| Kachel-ID | Titel (Akademie) | geübte Einheit | Bewertung |
|---|---|---|---|
| m1_zahlen10 | Zahlen 1-10 | Mengenvergleich | Teilmenge des Titels |
| m2_zahlen100 | Zahlen bis 100 | Plus bis 100 | Titel verspricht Zahlenraum, geübt wird nur Plus |
| m3_zahlen1000 | Zahlen bis 1000 | Plus bis 1000 | Titel verspricht Zahlenraum, geübt wird nur Plus |
| m3_geometrie | Geometrie | Umfang | nur ein Teilgebiet |
| s3_natur | Natur | Pflanzen | nur ein Teilgebiet |
| d4_grammatik | Grammatik | Die 4 Fälle | nur ein Teilgebiet |
| m4_textaufgaben | Textaufgaben | Sachaufgaben drei Schritte | passt |
| d1_schreibcoach | Schreibcoach LIVE | Buchstaben-Lautierung | Schreiben vs. Lauttraining |

Nicht geprüft (offen): KI-erzeugte Aufgaben (ChatGPT-Pfad mit `topic_curriculum.dart`), Holo-Lektionen, Abenteuer-Aufgaben außerhalb von `nextExact`, Spiele-Aufgaben. Die von Heinz beobachtete Mischung (z. B. Deutsch in „Plus bis 100“) ist im Offline-Generator **nicht reproduzierbar**; Verdacht: KI-Pfad oder Kachel-Zuordnung oben (unbestätigt).

## Geringe Vielfalt (< 10 verschiedene Aufgaben bei 60 Ziehungen, Lauf A)

- Mathematik Kl. 1 – Formen Nachzeichnen: 3
- Mathematik Kl. 2 – Uhrzeit: 1
- Mathematik Kl. 2 – Formen Nachzeichnen: 5
- Deutsch Kl. 1 – Wortdetektiv: 1
- Deutsch Kl. 2 – Namenwoerter: 9
- Deutsch Kl. 2 – Satzbaustelle: 1
- Deutsch Kl. 3 – ie oder i: 1
- Deutsch Kl. 4 – Direkte Rede: 1
- Deutsch Kl. 4 – Kommas in Aufzählungen: 1
- Schreiben Kl. 1 – Schwunguebung: 4
- Schreiben Kl. 2 – Schwunguebung: 5
- Schreiben Kl. 3 – Schwunguebung: 6
- Schreiben Kl. 4 – Schwunguebung: 6
- Lesen Kl. 1 – Woerter lesen: 9
- Lesen Kl. 1 – Bild und Wort: 8
- Lesen Kl. 2 – Bild und Wort: 8
- Lesen Kl. 3 – Bild und Wort: 8
- Lesen Kl. 4 – Bild und Wort: 8
- Sachunterricht Kl. 1 – Verkehr: 8
- Sachunterricht Kl. 1 – Familie und Gemeinschaft: 8
- Sachunterricht Kl. 1 – Zeit und Kalender: 8
- Sachunterricht Kl. 1 – Körper: 8
- Sachunterricht Kl. 1 – Tag und Nacht: 8
- Sachunterricht Kl. 1 – Pflanzen: 8
- Sachunterricht Kl. 1 – Wetter: 8
- Sachunterricht Kl. 1 – Jahreszeiten: 6
- Sachunterricht Kl. 1 – Tiere: 7
- Sachunterricht Kl. 3 – Wasserkreislauf: 7
- Sachunterricht Kl. 3 – Ernährung: 8
- Sachunterricht Kl. 3 – Verkehr: 7
- Sachunterricht Kl. 3 – Pflanzen: 6
- Sachunterricht Kl. 3 – Körper: 7
- Sachunterricht Kl. 3 – Zeit und Kalender: 7
- Sachunterricht Kl. 3 – Wetter: 6
- Sachunterricht Kl. 3 – Familie und Gemeinschaft: 6
- Sachunterricht Kl. 3 – Berufe: 6
- Sachunterricht Kl. 4 – Kontinente und Ozeane: 8
- Sachunterricht Kl. 4 – Diagramme lesen: 6

## Alle Einheiten (Lauf A): Fach, Klasse, Einheit, verschiedene Aufgaben/60, Visual-Typen

| Fach | Kl. | Einheit | versch. | Visuals |
|---|---|---|---|---|
| Mathematik | 1 | Textaufgaben | 58 | story:60 |
| Mathematik | 1 | Plus bis 10 | 46 | dots:60 |
| Mathematik | 1 | Minus bis 10 | 42 | line:60 |
| Mathematik | 1 | Plus bis 20 | 51 | dots:60 |
| Mathematik | 1 | Minus bis 20 | 53 | line:60 |
| Mathematik | 1 | Zahlenstrahl | 53 | number_line:60 |
| Mathematik | 1 | Mengenvergleich | 46 | quantity:60 |
| Mathematik | 1 | Zahl in Worten | 21 | word_number:60 |
| Mathematik | 1 | Geometrie Formen | 20 | shape:60 |
| Mathematik | 1 | Geld | 60 | money_compare:60 |
| Mathematik | 1 | Zeit | 24 | time_fact:60 |
| Mathematik | 1 | Symmetrie | 30 | symmetry:60 |
| Mathematik | 1 | Formen Nachzeichnen | 3 | shape_trace:60 |
| Mathematik | 1 | Rechengeschichten | 60 | auto:60 |
| Mathematik | 1 | Zahlenmauer | 58 | auto:60 |
| Mathematik | 1 | Zahlenrätsel | 60 | auto:60 |
| Mathematik | 1 | Marktstand | 60 | auto:60 |
| Mathematik | 1 | Platzhalter-Rätsel | 59 | auto:60 |
| Mathematik | 1 | Größer, kleiner, gleich | 59 | auto:60 |
| Mathematik | 2 | Textaufgaben | 59 | story:60 |
| Mathematik | 2 | Plus bis 20 | 56 | dots:60 |
| Mathematik | 2 | Minus bis 20 | 56 | line:60 |
| Mathematik | 2 | Plus bis 100 | 59 | dots:60 |
| Mathematik | 2 | Minus bis 100 | 58 | line:60 |
| Mathematik | 2 | Einmaleins | 41 | times_table:60 |
| Mathematik | 2 | Einmaleins Vorbereitung | 34 | groups:60 |
| Mathematik | 2 | Geld wechseln | 29 | money_change:60 |
| Mathematik | 2 | Uhrzeit | 1 | clock:60 |
| Mathematik | 2 | Längen | 48 | length_fact:60 |
| Mathematik | 2 | Gerade und ungerade | 51 | parity:60 |
| Mathematik | 2 | Verdoppeln und Halbieren | 42 | half:33, double:27 |
| Mathematik | 2 | Zehner und Einer | 57 | ten_ones:60 |
| Mathematik | 2 | Formen Nachzeichnen | 5 | shape_trace:60 |
| Mathematik | 2 | Uhr-Abenteuer | 24 | auto:60 |
| Mathematik | 3 | Einmaleins | 57 | times_table:60 |
| Mathematik | 3 | Schriftliche Addition | 60 | written_add:60 |
| Mathematik | 3 | Schriftliche Subtraktion | 60 | written_sub:60 |
| Mathematik | 3 | Brüche Vorbereitung | 45 | fraction_half:60 |
| Mathematik | 3 | Sachaufgaben zwei Schritte | 60 | story_two:60 |
| Mathematik | 3 | Umfang | 57 | perimeter:60 |
| Mathematik | 3 | Plus bis 100 | 59 | dots:60 |
| Mathematik | 3 | Minus bis 100 | 60 | line:60 |
| Mathematik | 3 | Plus bis 1000 | 60 | dots:60 |
| Mathematik | 3 | Minus bis 1000 | 60 | line:60 |
| Mathematik | 3 | Division einstellig | 58 | division:60 |
| Mathematik | 3 | Geld bis 100 Euro | 43 | money_change:60 |
| Mathematik | 3 | Massen Kilogramm und Gramm | 36 | mass:60 |
| Mathematik | 4 | Schriftliche Multiplikation | 60 | written_mul:60 |
| Mathematik | 4 | Schriftliche Division | 60 | division:60 |
| Mathematik | 4 | Bruchrechnen einfach | 48 | fraction_add:60 |
| Mathematik | 4 | Dezimalzahlen | 60 | decimal:60 |
| Mathematik | 4 | Sachaufgaben drei Schritte | 60 | story_three:60 |
| Mathematik | 4 | Diagramme lesen | 60 | chart:60 |
| Mathematik | 4 | Vergleichen | 60 | compare:60 |
| Mathematik | 4 | Plus bis 10000 | 60 | dots:60 |
| Mathematik | 4 | Minus bis 10000 | 60 | line:60 |
| Mathematik | 4 | Zahlenraum bis 1 Million | 60 | none:33, compare:27 |
| Mathematik | 4 | Zeit Minuten und Stunden | 50 | time_fact:60 |
| Mathematik | 4 | Hohlmaße Liter und Milliliter | 36 | volume:60 |
| Mathematik | 4 | Brüche erweitern | 43 | fraction_expand:60 |
| Mathematik | 4 | Mittelwert | 60 | chart:60 |
| Mathematik | 4 | Flächeninhalt | 49 | area:60 |
| Mathematik | 4 | Symmetrieachsen | 22 | symmetry:60 |
| Deutsch | 1 | Buchstaben-Lautierung | 13 | letters:60 |
| Deutsch | 1 | Reime | 44 | rhyme:60 |
| Deutsch | 1 | Anfangslaute | 36 | sound:60 |
| Deutsch | 1 | Endlaute | 20 | sound:60 |
| Deutsch | 1 | Wort-Bild-Zuordnung | 20 | word_image:60 |
| Deutsch | 1 | Erste Sätze | 17 | sentence:60 |
| Deutsch | 1 | Silben | 49 | syllables:60 |
| Deutsch | 1 | Artikel | 50 | article:60 |
| Deutsch | 1 | Wortdetektiv | 1 | auto:60 |
| Deutsch | 1 | Silbenrätsel | 20 | auto:60 |
| Deutsch | 1 | Begleiter-Rätsel | 55 | auto:60 |
| Deutsch | 1 | Gegenteil-Geschichten | 32 | auto:60 |
| Deutsch | 2 | Wortfamilien | 20 | family:60 |
| Deutsch | 2 | Einzahl und Mehrzahl | 20 | plural:60 |
| Deutsch | 2 | Verkleinerungsform | 20 | diminutive:60 |
| Deutsch | 2 | Gegenteile | 20 | opposite:60 |
| Deutsch | 2 | Oberbegriffe | 20 | category:60 |
| Deutsch | 2 | Namenwoerter | 9 | word_type:44, sentence:16 |
| Deutsch | 2 | Tunwoerter | 10 | word_type:43, sentence:17 |
| Deutsch | 2 | Wiewoerter | 10 | word_type:40, sentence:20 |
| Deutsch | 2 | Wörter zusammensetzen | 36 | auto:60 |
| Deutsch | 2 | Wortarten-Jagd | 60 | auto:60 |
| Deutsch | 2 | Satzbaustelle | 1 | auto:60 |
| Deutsch | 3 | Synonyme | 20 | synonym:60 |
| Deutsch | 3 | Wortarten | 25 | word_type:60 |
| Deutsch | 3 | Zeitformen | 20 | tense:60 |
| Deutsch | 3 | Steigerung | 20 | comparison:60 |
| Deutsch | 3 | Verbformen | 20 | verb_form:60 |
| Deutsch | 3 | Wer-Fall und Wen-Fall | 20 | case:60 |
| Deutsch | 3 | Großschreibung | 20 | capitalization:60 |
| Deutsch | 3 | ie oder i | 1 | spelling:60 |
| Deutsch | 4 | Satzglieder | 20 | sentence_part:60 |
| Deutsch | 4 | Direkte Rede | 1 | direct_speech:60 |
| Deutsch | 4 | Kommas in Aufzählungen | 1 | comma:60 |
| Deutsch | 4 | Zusammensetzungen | 20 | compound:60 |
| Deutsch | 4 | Die 4 Fälle | 20 | case:60 |
| Deutsch | 4 | dass oder das | 20 | dass_das:60 |
| Deutsch | 4 | Umstandswörter | 20 | adverb:60 |
| Deutsch | 4 | Vorvergangenheit | 20 | tense:60 |
| Rechtschreibung | 1 | Haeufige Woerter | 25 | auto:60 |
| Rechtschreibung | 1 | Gross und klein | 57 | auto:60 |
| Rechtschreibung | 1 | Doppelmitlaut | 34 | auto:60 |
| Rechtschreibung | 1 | Dehnungen | 21 | auto:60 |
| Rechtschreibung | 1 | Satzzeichen | 25 | auto:60 |
| Rechtschreibung | 1 | Wortende | 27 | auto:60 |
| Rechtschreibung | 1 | St oder Sp | 18 | auto:60 |
| Rechtschreibung | 2 | Haeufige Woerter | 17 | auto:60 |
| Rechtschreibung | 2 | Gross und klein | 57 | auto:60 |
| Rechtschreibung | 2 | Doppelmitlaut | 35 | auto:60 |
| Rechtschreibung | 2 | Dehnungen | 23 | auto:60 |
| Rechtschreibung | 2 | Satzzeichen | 25 | auto:60 |
| Rechtschreibung | 2 | Wortende | 28 | auto:60 |
| Rechtschreibung | 2 | St oder Sp | 18 | auto:60 |
| Rechtschreibung | 3 | Haeufige Woerter | 17 | auto:60 |
| Rechtschreibung | 3 | Gross und klein | 57 | auto:60 |
| Rechtschreibung | 3 | Doppelmitlaut | 23 | auto:60 |
| Rechtschreibung | 3 | Dehnungen | 13 | auto:60 |
| Rechtschreibung | 3 | Satzzeichen | 25 | auto:60 |
| Rechtschreibung | 3 | Wortende | 28 | auto:60 |
| Rechtschreibung | 3 | St oder Sp | 18 | auto:60 |
| Rechtschreibung | 4 | Haeufige Woerter | 27 | auto:60 |
| Rechtschreibung | 4 | Gross und klein | 56 | auto:60 |
| Rechtschreibung | 4 | Doppelmitlaut | 22 | auto:60 |
| Rechtschreibung | 4 | Dehnungen | 13 | auto:60 |
| Rechtschreibung | 4 | Satzzeichen | 25 | auto:60 |
| Rechtschreibung | 4 | Wortende | 28 | auto:60 |
| Rechtschreibung | 4 | St oder Sp | 18 | auto:60 |
| Schreiben | 1 | Buchstaben nachspuren | 46 | writing:60 |
| Schreiben | 1 | Wort schreiben | 50 | writing:60 |
| Schreiben | 1 | Satz abschreiben | 12 | writing:60 |
| Schreiben | 1 | Schwunguebung | 4 | writing:60 |
| Schreiben | 1 | Zahlen schreiben | 21 | writing:60 |
| Schreiben | 2 | Buchstaben nachspuren | 30 | writing:60 |
| Schreiben | 2 | Wort schreiben | 51 | writing:60 |
| Schreiben | 2 | Satz abschreiben | 12 | writing:60 |
| Schreiben | 2 | Schwunguebung | 5 | writing:60 |
| Schreiben | 2 | Zahlen schreiben | 18 | writing:60 |
| Schreiben | 3 | Buchstaben nachspuren | 12 | writing:60 |
| Schreiben | 3 | Wort schreiben | 51 | writing:60 |
| Schreiben | 3 | Satz abschreiben | 10 | writing:60 |
| Schreiben | 3 | Schwunguebung | 6 | writing:60 |
| Schreiben | 3 | Zahlen schreiben | 25 | writing:60 |
| Schreiben | 4 | Buchstaben nachspuren | 12 | writing:60 |
| Schreiben | 4 | Wort schreiben | 54 | writing:60 |
| Schreiben | 4 | Satz abschreiben | 10 | writing:60 |
| Schreiben | 4 | Schwunguebung | 6 | writing:60 |
| Schreiben | 4 | Zahlen schreiben | 15 | writing:60 |
| Lesen | 1 | Woerter lesen | 9 | auto:60 |
| Lesen | 1 | Sätze lesen | 24 | auto:60 |
| Lesen | 1 | Lesesinn | 24 | auto:60 |
| Lesen | 1 | Bild und Wort | 8 | auto:60 |
| Lesen | 1 | Reihenfolge | 55 | auto:60 |
| Lesen | 2 | Woerter lesen | 14 | auto:60 |
| Lesen | 2 | Sätze lesen | 24 | auto:60 |
| Lesen | 2 | Lesesinn | 24 | auto:60 |
| Lesen | 2 | Bild und Wort | 8 | auto:60 |
| Lesen | 2 | Reihenfolge | 58 | auto:60 |
| Lesen | 3 | Woerter lesen | 16 | auto:60 |
| Lesen | 3 | Sätze lesen | 24 | auto:60 |
| Lesen | 3 | Lesesinn | 24 | auto:60 |
| Lesen | 3 | Bild und Wort | 8 | auto:60 |
| Lesen | 3 | Reihenfolge | 56 | auto:60 |
| Lesen | 4 | Woerter lesen | 16 | auto:60 |
| Lesen | 4 | Sätze lesen | 24 | auto:60 |
| Lesen | 4 | Lesesinn | 24 | auto:60 |
| Lesen | 4 | Bild und Wort | 8 | auto:60 |
| Lesen | 4 | Reihenfolge | 56 | auto:60 |
| Englisch | 1 | Farben | 10 | auto:60 |
| Englisch | 1 | Tiere | 12 | auto:60 |
| Englisch | 1 | Begruessung | 13 | auto:60 |
| Englisch | 1 | Familie | 10 | auto:60 |
| Englisch | 1 | Zahlen | 10 | auto:60 |
| Englisch | 1 | Körper | 10 | auto:60 |
| Englisch | 1 | Schulsachen | 10 | auto:60 |
| Englisch | 2 | Zahlen | 20 | auto:60 |
| Englisch | 2 | Körper | 14 | auto:60 |
| Englisch | 2 | Spielzeug | 11 | auto:60 |
| Englisch | 2 | Tiere | 17 | auto:60 |
| Englisch | 3 | Schulsachen | 37 | auto:60 |
| Englisch | 3 | Wetter | 28 | auto:60 |
| Englisch | 3 | Essen | 34 | auto:60 |
| Englisch | 3 | Tageszeit | 30 | auto:60 |
| Englisch | 3 | Alltagssätze | 24 | auto:60 |
| Englisch | 4 | Verben | 44 | auto:60 |
| Englisch | 4 | Wochentage | 34 | auto:60 |
| Englisch | 4 | Hobbys | 37 | auto:60 |
| Englisch | 4 | Länder | 36 | auto:60 |
| Englisch | 4 | Alltagssätze | 30 | auto:60 |
| Sachunterricht | 1 | Verkehr | 8 | science:60 |
| Sachunterricht | 1 | Familie und Gemeinschaft | 8 | science:60 |
| Sachunterricht | 1 | Zeit und Kalender | 8 | science:60 |
| Sachunterricht | 1 | Körper | 8 | science:60 |
| Sachunterricht | 1 | Tag und Nacht | 8 | science:60 |
| Sachunterricht | 1 | Pflanzen | 8 | science:60 |
| Sachunterricht | 1 | Wetter | 8 | science:60 |
| Sachunterricht | 1 | Jahreszeiten | 6 | science:60 |
| Sachunterricht | 1 | Tiere | 7 | science:60 |
| Sachunterricht | 1 | Wer bin ich? | 18 | science:60 |
| Sachunterricht | 1 | Monate und Wochentage | 23 | science:60 |
| Sachunterricht | 2 | Zeit und Kalender | 13 | science:60 |
| Sachunterricht | 2 | Verkehr | 13 | science:60 |
| Sachunterricht | 2 | Berufe | 13 | science:60 |
| Sachunterricht | 2 | Körper | 14 | science:60 |
| Sachunterricht | 2 | Familie und Gemeinschaft | 13 | science:60 |
| Sachunterricht | 2 | Wetter | 13 | science:60 |
| Sachunterricht | 2 | Pflanzen | 13 | science:60 |
| Sachunterricht | 2 | Jahreszeiten | 13 | science:60 |
| Sachunterricht | 2 | Tiere | 13 | science:60 |
| Sachunterricht | 3 | Wasserkreislauf | 7 | science:60 |
| Sachunterricht | 3 | Ernährung | 8 | science:60 |
| Sachunterricht | 3 | Bundesländer Österreichs | 10 | science:60 |
| Sachunterricht | 3 | Verkehr | 7 | science:60 |
| Sachunterricht | 3 | Pflanzen | 6 | science:60 |
| Sachunterricht | 3 | Körper | 7 | science:60 |
| Sachunterricht | 3 | Zeit und Kalender | 7 | science:60 |
| Sachunterricht | 3 | Wetter | 6 | science:60 |
| Sachunterricht | 3 | Familie und Gemeinschaft | 6 | science:60 |
| Sachunterricht | 3 | Berufe | 6 | science:60 |
| Sachunterricht | 3 | Tiere | 25 | science:60 |
| Sachunterricht | 3 | Österreich-Reise | 21 | science:60 |
| Sachunterricht | 4 | Stromkreise | 10 | science:60 |
| Sachunterricht | 4 | Ökosysteme | 10 | science:60 |
| Sachunterricht | 4 | Geschichte | 10 | science:60 |
| Sachunterricht | 4 | Geografie Österreich | 15 | science:60 |
| Sachunterricht | 4 | Kontinente und Ozeane | 8 | science:60 |
| Sachunterricht | 4 | Diagramme lesen | 6 | science:60 |
| Logik | 1 | Muster | 24 | pattern:60 |
| Logik | 1 | Reihenfolgen | 56 | auto:60 |
| Logik | 1 | Was passt nicht? | 60 | auto:60 |
| Logik | 2 | Zahlenmuster | 59 | auto:60 |
| Logik | 2 | Geheimcode | 20 | auto:60 |
| Logik | 3 | Schlussfolgern | 60 | auto:60 |
| Logik | 4 | Regeln kombinieren | 57 | auto:60 |

## Bilder in Textaufgaben

- Vorher: Rechengeschichten zeigen ein Emoji (`storyThemeEmoji`, lumo_premium_visuals.dart) und flache Zähl-Icons (`StoryMathWorkbench`). Einzelobjekte liegen als WebP in `assets/lumo_design/task_objects/` (z. B. bus.webp, baum.webp).
- Neu (Commit f4424142): 14 gerenderte 3D-Szenenbilder `assets/lumo_design/task_objects/story3d_*.webp` für alle 17 Ein-Schritt-Geschichten der Kl. 1–2 (13 Plus inkl. Korb, 4 Wegnehmen); Bus und Buntstifte teilen sich je ein Bild.
- Noch ohne Bild: 12 Zwei-Schritt-Geschichten (Kl. 3), 8 Drei-Schritt-Geschichten (Kl. 4), Abenteuer-Rechengeschichten.
