# Lumo Lernen – Prüfbericht Deutsch, Sachunterricht, Englisch (Klasse 1–4)

Stand: 17.11.2026 · Nur gelesen und ausgewertet, im Repository wurde nichts geändert. Einzige Nebenwirkung: `dart run` hat den von Git ignorierten Build-Cache `.dart_tool/` berührt (`git status` ist sauber).

## 1. Ergebnis in Kürze

- **Deutsch (mit Lesen, Rechtschreibung, Schreiben, Geschichten): 5 schwere, 24 mittlere, 13 leichte Befunde.** Die Grammatik-Einheiten der Klassen 2–4 sind sprachlich sauber. Die schweren Fehler liegen in den Laut- und Reimaufgaben der 1. Klasse, in einem Wortdetektiv-Eintrag und in kindersichtbaren Texten mit falscher Rechtschreibung.
- **Sachunterricht: 1 schwerer, 17 mittlere, 12 leichte Befunde.** Fast alle Fakten stimmen. Schwach sind alberne Ablenker, Dubletten, einzelne unklare Fragen und fehlende Österreich-Bezüge im Verkehr.
- **Englisch: 0 schwere, 4 mittlere, 8 leichte Befunde.** Alle Übersetzungen stimmen, die Schreibung ist einheitlich britisch. Es gibt aber nur ein einziges Aufgabenformat (englisches Wort lesen, deutsche Bedeutung antippen).
- **Steigerung über die Klassen:** Rechtschreibung, Lesen und Schreiben bieten in allen vier Klassen dieselben Einheiten mit weitgehend denselben Inhalten.

## 2. Was geprüft wurde

| Quelle | Umfang | Art der Prüfung |
|---|---|---|
| `ExerciseFactory` (Deutsch, Lesen, Rechtschreibung, Schreiben, Sachunterricht, Englisch) | 281 Einheit-Klasse-Kombinationen (166 davon als Stoff der jeweiligen Klasse, 115 als Wiederholung) | Eigener Sampler: 480 Ziehungen je Kombination, alle unterschiedlichen Aufgaben ausgegeben. Zusätzlich je 20 000–30 000 Seeds für Reime, Anfangs-/Endlaute, Silben, Artikel, Wortarten und 3 200 Ziehungen je Abenteuer-, Englisch-, Rechtschreib- und Lese-Einheit, um alle Ablenker-Kombinationen zu sehen (23 798 unterschiedliche Aufgaben). |
| Sachfragen (3 Dateien) | 249 Fragen: Kl. 1: 69, Kl. 2: 46, Kl. 3: 75, Kl. 4: 59 | jede Frage einzeln gelesen |
| Englisch-Vokabular | 325 Einträge: Kl. 1: 77, Kl. 2: 68, Kl. 3: 82, Kl. 4: 98 | jeder Eintrag gelesen, Auswahlmöglichkeiten maschinell auf Dopplungen geprüft |
| Deutsch-Vorlagen und Wortdaten | 32 Vorlagen, 20 Einträge je Datenbank, 101 Nomen, 50 Verben, 30 Adjektive, 65 Reimpaare, alle Silbentrennungen | vollständig gelesen |
| Lesetexte | 48 Kurztexte mit 96 Fragen, 12 Reihenfolgen, 24 Lese-Buddy-Texte mit 24 Fragen, 20 Lückensätze | vollständig gelesen |
| Rechtschreib-Kontexte | 96 Sätze, 29 Verlängerungswörter | vollständig gelesen |
| Abenteuer-Aufgaben Deutsch/Sach | 45 Nomen, 28 Wortdetektiv-Wörter, 18 Zusammensetzungen, 36 Rätsel, 8 Österreich-Fakten | vollständig gelesen und gesampelt |
| Weitere Quellen | Kartenspiel-Fragen (100 Deutsch-Fragen), Quiz-Bank (63 Deutsch-/Sachfragen), Lernmodule Verkehr (30 Fragen), Wetter, Tiere, Jahreszeiten (30 Hinweise), Artikel, Mehrzahl, Wortarten, Zeitformen, Wortdiktat, Schreib-Wortbank (36 Wörter), Ersatzaufgaben (`safe_fallback_pool.dart`), Tagestipps, 60 Aktivitätskarten | Daten gelesen |
| Vorhandener Helfer `tools/audit_learning_tasks_all_grades.dart` | 236 Familien, 7 552 Stichproben | gelesen und mit Ausgabe ins Scratch-Verzeichnis ausgeführt: 0 Vertragsfehler. Er prüft nur leere Felder, fehlende und doppelte Antworten, keine Inhalte. |

Technisch fand ich in allen Stichproben keine Aufgabe mit fehlender oder doppelter richtiger Antwort.

## 3. Alle Einheiten je Fach und Klasse

Urteil je Einheit: **in Ordnung**, **Mängel** (mittlere Befunde) oder **schwerer Fehler**. Die Kürzel verweisen auf Abschnitt 4. Die Zahl ist die Anzahl unterschiedlicher Aufgaben (Frage + Antwort), die der Sampler in 480 Ziehungen erzeugt hat; bei festen Banken ist das die ganze Bank.

### Deutsch

Quelle: german_task_templates.dart (+ german_curriculum_extensions.dart, primary_school_word_data.dart); Abenteuer-Einheiten (A) aus adventure/lumo_adventure_tasks.dart + adventure_word_data.dart. Format: Auswahl (3–4).

| Kl. | Einheit | geprüfte unterschiedliche Aufgaben | Urteil | Verweis |
|---|---|---|---|---|
| 1 | Buchstaben-Lautierung | 6 | Mängel | nur 6 Aufgaben; D-L1 |
| 1 | Reime | 65 | schwerer Fehler | D-S1 |
| 1 | Anfangslaute | 35 | Mängel | D-M1 |
| 1 | Endlaute | 23 | schwerer Fehler | D-S2 |
| 1 | Wort-Bild-Zuordnung | 20 | in Ordnung |  |
| 1 | Erste Sätze | 12 | in Ordnung |  |
| 1 | Silben | 73 | in Ordnung |  |
| 1 | Artikel | 73 | Mängel | D-M2 |
| 1 | Wortdetektiv (A) | 8 | in Ordnung | nur 8 Wörter |
| 1 | Silbenrätsel (A) | 20 | in Ordnung |  |
| 1 | Begleiter-Rätsel (A) | 152 | in Ordnung | D-L6 |
| 1 | Gegenteil-Geschichten (A) | 221 | Mängel | D-M15 |
| 1 | *Wiederholung aus früheren Klassen (1 Einheiten, gleiche Pools)* | – | siehe Ursprungsklasse | – |
| 2 | Wortfamilien | 20 | in Ordnung |  |
| 2 | Einzahl und Mehrzahl | 20 | in Ordnung | D-L2 |
| 2 | Verkleinerungsform | 20 | Mängel | D-M6 |
| 2 | Gegenteile | 20 | in Ordnung |  |
| 2 | Oberbegriffe | 20 | in Ordnung |  |
| 2 | Namenwoerter | 87 | in Ordnung |  |
| 2 | Tunwoerter | 50 | in Ordnung |  |
| 2 | Wiewoerter | 30 | in Ordnung |  |
| 2 | Wörter zusammensetzen (A) | 36 | Mängel | D-M16 |
| 2 | Wortarten-Jagd (A) | 477 | in Ordnung |  |
| 2 | Satzbaustelle (A) | 464 | in Ordnung |  |
| 2 | *Wiederholung aus früheren Klassen (13 Einheiten, gleiche Pools)* | – | siehe Ursprungsklasse | – |
| 3 | Synonyme | 20 | Mängel | D-M23 |
| 3 | Wortarten | 159 | Mängel | D-M17 |
| 3 | Zeitformen | 20 | in Ordnung | D-L3 |
| 3 | Steigerung | 20 | in Ordnung |  |
| 3 | Verbformen | 20 | in Ordnung | D-L4 |
| 3 | Wer-Fall und Wen-Fall | 20 | in Ordnung |  |
| 3 | Großschreibung | 20 | Mängel | D-M5 |
| 3 | ie oder i | 20 | in Ordnung |  |
| 3 | *Wiederholung aus früheren Klassen (24 Einheiten, gleiche Pools)* | – | siehe Ursprungsklasse | – |
| 4 | Satzglieder | 20 | in Ordnung |  |
| 4 | Direkte Rede | 20 | in Ordnung |  |
| 4 | Kommas in Aufzählungen | 20 | in Ordnung |  |
| 4 | Zusammensetzungen | 20 | in Ordnung |  |
| 4 | Die 4 Fälle | 20 | in Ordnung |  |
| 4 | dass oder das | 20 | Mängel | D-M4 |
| 4 | Umstandswörter | 20 | Mängel | D-M3 |
| 4 | Vorvergangenheit | 20 | Mängel | D-M7 |
| 4 | *Wiederholung aus früheren Klassen (32 Einheiten, gleiche Pools)* | – | siehe Ursprungsklasse | – |

### Lesen

Quelle: school_exercise_generator.dart `_reading` + reading_comprehension_data.dart; Abenteuer-Einheiten (A) aus adventure/lumo_adventure_tasks.dart + adventure_word_data.dart. Format: Auswahl (3–4).

| Kl. | Einheit | geprüfte unterschiedliche Aufgaben | Urteil | Verweis |
|---|---|---|---|---|
| 1 | Woerter lesen | 5 | Mängel | nur 5–6 Aufgaben; D-M12 |
| 1 | Sätze lesen | 24 | in Ordnung | D-L9 |
| 1 | Lesesinn | 24 | Mängel | identisch mit „Sätze lesen“; D-M12 |
| 1 | Bild und Wort | 8 | Mängel | D-M12 |
| 1 | Reihenfolge | 36 | Mängel | D-M12 |
| 2 | Woerter lesen | 6 | Mängel | nur 5–6 Aufgaben; D-M12 |
| 2 | Sätze lesen | 24 | in Ordnung | D-L9 |
| 2 | Lesesinn | 24 | Mängel | identisch mit „Sätze lesen“; D-M12 |
| 2 | Bild und Wort | 8 | Mängel | D-M12 |
| 2 | Reihenfolge | 36 | Mängel | D-M12 |
| 3 | Woerter lesen | 6 | Mängel | nur 5–6 Aufgaben; D-M12 |
| 3 | Sätze lesen | 24 | in Ordnung | D-L9 |
| 3 | Lesesinn | 24 | Mängel | identisch mit „Sätze lesen“; D-M12 |
| 3 | Bild und Wort | 8 | Mängel | D-M12 |
| 3 | Reihenfolge | 36 | Mängel | D-M12 |
| 4 | Woerter lesen | 6 | Mängel | nur 5–6 Aufgaben; D-M12 |
| 4 | Sätze lesen | 24 | Mängel | D-M13 |
| 4 | Lesesinn | 24 | Mängel | identisch mit „Sätze lesen“; D-M12 |
| 4 | Bild und Wort | 8 | Mängel | D-M12 |
| 4 | Reihenfolge | 36 | Mängel | D-M12 |

### Rechtschreibung

Quelle: school_exercise_generator.dart `_spelling` + spelling_context_data.dart; Abenteuer-Einheiten (A) aus adventure/lumo_adventure_tasks.dart + adventure_word_data.dart. Format: Auswahl (3–4).

| Kl. | Einheit | geprüfte unterschiedliche Aufgaben | Urteil | Verweis |
|---|---|---|---|---|
| 1 | Haeufige Woerter | 30 | in Ordnung |  |
| 1 | Gross und klein | 73 | Mängel | D-M10 |
| 1 | Doppelmitlaut | 34 | in Ordnung |  |
| 1 | Dehnungen | 24 | in Ordnung | D-L8 |
| 1 | Satzzeichen | 25 | in Ordnung |  |
| 1 | Wortende | 28 | Mängel | D-M8 |
| 1 | St oder Sp | 20 | Mängel | D-M11 |
| 2 | Haeufige Woerter | 32 | Mängel | D-M9 |
| 2 | Gross und klein | 87 | Mängel | D-M10 |
| 2 | Doppelmitlaut | 35 | in Ordnung |  |
| 2 | Dehnungen | 30 | in Ordnung | D-L8 |
| 2 | Satzzeichen | 25 | in Ordnung |  |
| 2 | Wortende | 29 | Mängel | D-M8 |
| 2 | St oder Sp | 20 | Mängel | D-M11 |
| 3 | Haeufige Woerter | 33 | Mängel | D-M9 |
| 3 | Gross und klein | 95 | Mängel | D-M10 |
| 3 | Doppelmitlaut | 36 | Mängel | D-M9 |
| 3 | Dehnungen | 30 | Mängel | D-M9 |
| 3 | Satzzeichen | 25 | Mängel | D-M9 |
| 3 | Wortende | 29 | Mängel | D-M8 |
| 3 | St oder Sp | 20 | Mängel | D-M11 |
| 4 | Haeufige Woerter | 34 | Mängel | D-M9 |
| 4 | Gross und klein | 101 | Mängel | D-M10 |
| 4 | Doppelmitlaut | 36 | Mängel | D-M9 |
| 4 | Dehnungen | 30 | Mängel | D-M9 |
| 4 | Satzzeichen | 25 | Mängel | D-M9 |
| 4 | Wortende | 29 | Mängel | D-M8 |
| 4 | St oder Sp | 20 | Mängel | D-M11 |

### Schreiben

Quelle: school_exercise_generator.dart `_writing`; Abenteuer-Einheiten (A) aus adventure/lumo_adventure_tasks.dart + adventure_word_data.dart. Format: Handschrift, Selbstkontrolle „Fertig“.

| Kl. | Einheit | geprüfte unterschiedliche Aufgaben | Urteil | Verweis |
|---|---|---|---|---|
| 1 | Buchstaben nachspuren | 26 | in Ordnung |  |
| 1 | Wort schreiben | 73 | in Ordnung |  |
| 1 | Satz abschreiben | 12 | in Ordnung | lange Sätze ab Kl. 3; D-M18 |
| 1 | Schwunguebung | 4 | Mängel | D-M18 |
| 1 | Zahlen schreiben | 21 | in Ordnung |  |
| 2 | Buchstaben nachspuren | 26 | Mängel | D-M18 |
| 2 | Wort schreiben | 87 | in Ordnung |  |
| 2 | Satz abschreiben | 12 | in Ordnung | lange Sätze ab Kl. 3; D-M18 |
| 2 | Schwunguebung | 4 | Mängel | D-M18 |
| 2 | Zahlen schreiben | 21 | Mängel | D-M18 |
| 3 | Buchstaben nachspuren | 26 | Mängel | D-M18 |
| 3 | Wort schreiben | 94 | in Ordnung |  |
| 3 | Satz abschreiben | 12 | in Ordnung | lange Sätze ab Kl. 3; D-M18 |
| 3 | Schwunguebung | 4 | Mängel | D-M18 |
| 3 | Zahlen schreiben | 21 | Mängel | D-M18 |
| 4 | Buchstaben nachspuren | 26 | Mängel | D-M18 |
| 4 | Wort schreiben | 100 | in Ordnung |  |
| 4 | Satz abschreiben | 12 | in Ordnung | lange Sätze ab Kl. 3; D-M18 |
| 4 | Schwunguebung | 4 | Mängel | D-M18 |
| 4 | Zahlen schreiben | 21 | Mängel | D-M18 |

### Sachunterricht

Quelle: school_exercise_generator.dart `_scienceQuestions` + science_task_data.dart + science_quality_extension.dart; Abenteuer-Einheiten (A) aus adventure/lumo_adventure_tasks.dart + adventure_word_data.dart. Format: Auswahl (4).

| Kl. | Einheit | geprüfte unterschiedliche Aufgaben | Urteil | Verweis |
|---|---|---|---|---|
| 1 | Verkehr | 8 | in Ordnung |  |
| 1 | Familie und Gemeinschaft | 8 | in Ordnung | S-L3 |
| 1 | Zeit und Kalender | 8 | Mängel | S-M12 |
| 1 | Körper | 8 | in Ordnung |  |
| 1 | Tag und Nacht | 8 | in Ordnung |  |
| 1 | Pflanzen | 8 | Mängel | S-M11 |
| 1 | Wetter | 8 | in Ordnung | S-L4 |
| 1 | Jahreszeiten | 6 | in Ordnung |  |
| 1 | Tiere | 7 | Mängel | S-M8 |
| 1 | Wer bin ich? (A) | 18 | in Ordnung | S-L8 |
| 1 | Monate und Wochentage (A) | 26 | in Ordnung |  |
| 2 | Zeit und Kalender | 12 | in Ordnung |  |
| 2 | Verkehr | 7 | Mängel | S-M5 |
| 2 | Berufe | 8 | Mängel | S-M7 |
| 2 | Körper | 12 | in Ordnung | nur 4 eigene Fragen |
| 2 | Familie und Gemeinschaft | 11 | in Ordnung | nur 3 eigene Fragen |
| 2 | Wetter | 11 | in Ordnung | nur 3 eigene Fragen |
| 2 | Pflanzen | 6 | Mängel | S-M2, S-M6 |
| 2 | Tiere | 9 | Mängel | S-M11 |
| 2 | Jahreszeiten | 7 | Mängel | nur 1 eigene Frage; S-M15 |
| 2 | *Wiederholung aus früheren Klassen (3 Einheiten, gleiche Pools)* | – | siehe Ursprungsklasse | – |
| 3 | Wasserkreislauf | 7 | Mängel | S-M1 |
| 3 | Ernährung | 8 | Mängel | S-M11 |
| 3 | Bundesländer Österreichs | 9 | in Ordnung | S-L1 |
| 3 | Verkehr | 7 | Mängel | S-M10 |
| 3 | Pflanzen | 6 | Mängel | S-M4 |
| 3 | Körper | 7 | Mängel | S-M3 |
| 3 | Zeit und Kalender | 7 | in Ordnung | S-L6 |
| 3 | Wetter | 6 | schwerer Fehler | S-S1 |
| 3 | Familie und Gemeinschaft | 6 | in Ordnung |  |
| 3 | Berufe | 6 | in Ordnung | S-L2 |
| 3 | Tiere | 21 | in Ordnung | nur 5 eigene Fragen |
| 3 | Österreich-Reise (A) | 22 | in Ordnung |  |
| 3 | *Wiederholung aus früheren Klassen (4 Einheiten, gleiche Pools)* | – | siehe Ursprungsklasse | – |
| 4 | Stromkreise | 10 | in Ordnung |  |
| 4 | Ökosysteme | 10 | in Ordnung |  |
| 4 | Geschichte | 10 | in Ordnung | inhaltlich schmal |
| 4 | Geografie Österreich | 15 | Mängel | S-M12, S-L5 |
| 4 | Kontinente und Ozeane | 7 | Mängel | S-M9 |
| 4 | Diagramme lesen | 6 | Mängel | S-M14 |
| 4 | *Wiederholung aus früheren Klassen (16 Einheiten, gleiche Pools)* | – | siehe Ursprungsklasse | – |

### Englisch

Quelle: school_exercise_generator.dart `_baseEnglishVocabulary` + english_vocabulary_extensions.dart; Abenteuer-Einheiten (A) aus adventure/lumo_adventure_tasks.dart + adventure_word_data.dart. Format: Auswahl (4), nur EN→DE.

| Kl. | Einheit | geprüfte unterschiedliche Aufgaben | Urteil | Verweis |
|---|---|---|---|---|
| 1 | Farben | 11 | in Ordnung |  |
| 1 | Tiere | 12 | in Ordnung |  |
| 1 | Begruessung | 13 | in Ordnung |  |
| 1 | Familie | 11 | in Ordnung |  |
| 1 | Zahlen | 10 | in Ordnung |  |
| 1 | Körper | 10 | in Ordnung |  |
| 1 | Schulsachen | 10 | Mängel | E-M3, E-M4 |
| 2 | Zahlen | 20 | in Ordnung |  |
| 2 | Körper | 16 | in Ordnung |  |
| 2 | Spielzeug | 13 | in Ordnung | E-M3 |
| 2 | Tiere | 19 | in Ordnung |  |
| 2 | *Wiederholung aus früheren Klassen (4 Einheiten, gleiche Pools)* | – | siehe Ursprungsklasse | – |
| 3 | Schulsachen | 20 | Mängel | E-M2 |
| 3 | Wetter | 16 | Mängel | E-M2 |
| 3 | Essen | 19 | Mängel | E-M2 |
| 3 | Tageszeit | 15 | Mängel | E-M3 |
| 3 | Alltagssätze | 12 | in Ordnung | E-L2 |
| 3 | *Wiederholung aus früheren Klassen (7 Einheiten, gleiche Pools)* | – | siehe Ursprungsklasse | – |
| 4 | Verben | 27 | in Ordnung |  |
| 4 | Wochentage | 17 | in Ordnung | E-M3 |
| 4 | Hobbys | 19 | in Ordnung |  |
| 4 | Länder | 20 | in Ordnung | E-L4 |
| 4 | Alltagssätze | 15 | in Ordnung | E-L2 |
| 4 | *Wiederholung aus früheren Klassen (11 Einheiten, gleiche Pools)* | – | siehe Ursprungsklasse | – |

Hinweise zu den Tabellen:

- „St oder Sp“ ist im Fach Deutsch nur als Wiederholung wählbar und hat deshalb keine eigene Zeile; Urteil wie in Rechtschreibung (D-M11).
- Der schwere Wortdetektiv-Fehler (D-S3) betrifft ein Klasse-2-Wort. Er erscheint ab Klasse 2, wo die Einheit als Wiederholung läuft.
- Lesen, Rechtschreibung und Schreiben bieten in jeder Klasse dieselben Einheiten (`Curriculum.unitsForGrade` gibt für diese Fächer immer die ganze Liste zurück).
- Wiederholungs-Einheiten aus Deutsch-Vorlagen nutzen immer den Wortpool der Ursprungsklasse: „Silben“, „Artikel“ und „Reime“ haben in Klasse 4 genau dieselben 73 bzw. 65 Aufgaben wie in Klasse 1.

## 4. Befunde

Schweregrade: **schwer** = falsch oder irreführend für das Kind · **mittel** = mehrdeutig, ungeeignet oder ohne Lernwert · **leicht** = Formulierung und Feinschliff. Pfade relativ zu `/home/user/lumo-lernen/`.

### 4.1 Deutsch – schwer

**D-S1 · Reime: zweites Reimwort steht als „falsche“ Antwort zur Wahl**
- Ort: `lib/core/primary_school_word_data.dart:52, 75, 94, 99` (Reimpaare) und `lib/core/german_task_templates.dart:322–337` (Ablenker aus der Nomenliste).
- Aufgaben: „Was reimt sich auf Rose?“ → richtig „Dose“, Ablenker „Hose“ · „… auf See?“ → „Tee“, Ablenker „Schnee“ · „… auf Fluss?“ → „Kuss“, Ablenker „Bus“ · „… auf Brille?“ → „Grille“, Ablenker „Marille“. In allen vier Klassen nachgewiesen.
- Problem: Das Kind tippt ein echtes Reimwort an und bekommt „falsch“.
- Korrektur: In `rhymePairs` ergänzen: `['Rose', 'Hose']`, `['See', 'Schnee']`, `['Fluss', 'Bus']`, `['Brille', 'Marille']`. Die vorhandene Gruppenbildung schließt diese Wörter dann als Ablenker aus.

**D-S2 · Endlaute: „D“ wird bei Hund, Hand, Kind, Mond, Pferd, Rad, Wind als falsch gewertet**
- Ort: `lib/core/primary_school_word_data.dart:184–199` (`'Hand': 'T'`, `'Hund': 'T'`, `'Kind': 'T'`, `'Mond': 'T'`, `'Pferd': 'T'`, `'Rad': 'T'`, `'Wind': 'T'`), Auswahl aus `german_task_templates.dart:637–669`.
- Aufgabe: „Mit welchem Laut endet Hund?“ → richtig „T“; „D“ kommt als Ablenker vor. Erklärung: „Sprich Hund langsam. Der letzte Laut ist T.“
- Problem: Lautlich korrekt, aber das Wort steht geschrieben in der Frage, und die Rechtschreib-Einheit „Wortende“ lehrt gleichzeitig „Hun_ → d“. Ein Erstklässler lernt so „Hunt“.
- Korrektur: Diese sieben Wörter aus `_finalSounds` nehmen. Falls sie bleiben sollen: „D“ nicht als Ablenker anbieten und erklären: „Am Ende von Hund hörst du ein t. Geschrieben wird aber d. Verlängere das Wort: Hun-de.“

**D-S3 · Wortdetektiv: zwei richtig geschriebene Wörter**
- Ort: `lib/core/adventure/adventure_word_data.dart:125` – `AdventureSpelling('Bett', ['Bet', 'Bed', 'Beet'], 2, …)`.
- Problem: Die Frage nennt das gesuchte Wort nicht („Welches Wort ist richtig geschrieben?“). „Beet“ ist ein richtig geschriebenes Wort.
- Korrektur: `AdventureSpelling('Bett', ['Bet', 'Bed', 'Bettt'], 2, 'Nach kurzem e kommt tt.')`.

**D-S4 · Quest-Geschichten ohne Umlaute und ß**
- Ort: `lib/core/lumo_quest_library.dart`, u. a. Zeilen 72, 78, 82, 89, 100, 104, 123, 127, 194, 198, 231, 242, 246. Die Texte werden im Geschichten-Leser unverändert angezeigt (`lumo_story_reader_screen.dart:203–208`; keine Umwandlung gefunden).
- Beispiele: „Lumo steht im grossen Apfelgarten. Die Aeste haengen voller roter Aepfel.“ · Titel „Lumo in der Baeckerei“, „Lumo und die Schatzhoehle“ · „Haelfte von 24 = ?“.
- Problem: Lesetexte für Kinder in falscher Rechtschreibung.
- Korrektur: „Lumo steht im großen Apfelgarten. Die Äste hängen voller roter Äpfel. „So viele!“, staunt Lumo. „Heute brauche ich Hilfe beim Zählen.““ · „Lumo in der Bäckerei“ · „Lumo und die Schatzhöhle“ · „Was wäre ihr Wert in blauen Steinen?“ · „Lumo will von den 24 blauen Steinen die Hälfte zurück in die Höhle legen … Wie viele Steine bleiben für Lumo?“ · „Hälfte von 24 = ?“ · „3 Äpfel + 4 Äpfel = ?“ · „Hasi und Lumo schauen auf zwei Bäume. Am linken Baum hängen 8 Äpfel, am rechten 5. Wo sind mehr Äpfel?“

**D-S5 · Tagestipps mit Grammatik- und Rechtschreibfehlern**
- Ort: `lib/features/shared/widgets/lumo_tagestipp_card.dart:170, 178, 190, 196, 202, 224, 226, 238`.
- Ist → Soll:
  - „MAX RAET“ → „MAX RÄT“; „pruefen“ → „prüfen“; „BRUECHE“ → „BRÜCHE“
  - „Sprich jeden Buchstaben langsam. Auch Silben helfen dir lange Woerter zu lesen.“ → „Sprich jeden Laut langsam. Auch Silben helfen dir, lange Wörter zu lesen.“
  - „Namenswoerter (Tisch, Hund, Mama) schreibst du immer GROSS.“ → „Namenwörter (Tisch, Hund, Mama) schreibst du immer groß.“
  - „Ein Frosch fuehlt sich kalt an. Er ist ein Wechselwarmer Tier.“ → „Ein Frosch fühlt sich kalt an. Er ist ein wechselwarmes Tier.“
  - „Schau dir Pizza-Stuecke vor!“ → „Stell dir Pizzastücke vor!“
  - „Die kleine Zeiger zeigt die Stunde, die grosse die Minute.“ → „Der kleine Zeiger zeigt die Stunde, der große die Minute.“

### 4.2 Deutsch – mittel

**D-M1 · Anfangslaute: „Stift“ → „Sch“, „Vogel“ → „F“** · `primary_school_word_data.dart:169, 172`
- „Mit welchem Laut beginnt Stift?“ wertet „S“ als falsch; „… Vogel?“ verlangt „F“, ein „V“ wird nie angeboten. Die Erklärung „Der erste Laut ist F.“ führt zur Schreibung „Fogel“, die im Wortdetektiv als Fehler gilt.
- Korrektur: beide Wörter aus `_initialSounds` nehmen, oder Erklärung: „Vogel klingt am Anfang wie f. Geschrieben wird V.“ / „Stift klingt am Anfang wie scht. Geschrieben wird St.“

**D-M2 · Artikel: „Erdäpfel“ ist Mehrzahl** · `primary_school_word_data.dart:679`
- „Welcher Artikel passt zu Erdäpfel?“ → „die“. Zwischen lauter Einzahl-Wörtern lernt das Kind einen Mehrzahl-Artikel als Geschlecht.
- Korrektur: `_NounSeed('Erdapfel', 'der', 'Gemüse', 'österreichisch', 'kochen', 1)` mit Silben `'Erd-ap-fel'`. Nebenbei: „Lego“ (Markenname, Zeile 728) und „Mama“/„Papa“ sind als Artikel-Übungswörter wenig geeignet.

**D-M3 · Umstandswörter: Ablenker stehen nicht im Satz** · `german_curriculum_extensions.dart:547–548, 556, 557–558`
- „Bereits im Frühling blüht diese Blume.“ mit Ablenkern „wächst“, „eine“ · „Wir vergessen dich nie.“ mit „üben“ · „Im Garten wachsen überall Blumen.“ mit „Das“, „Team“, „trainiert“.
- Korrektur: `['Frühling', 'blüht', 'Blume']` · `['Wir', 'vergessen', 'dich']` · `['Garten', 'wachsen', 'Blumen']`.

**D-M4 · dass/das: Erklärung passt nicht zur Antwort** · `german_task_templates.dart:613`
- Bei 12 von 20 Sätzen ist „dass“ richtig, die Erklärung beginnt aber immer mit „„Das“ kannst du hier durch „dieses“ oder „welches“ ersetzen.“
- Korrektur: bei Antwort „dass“: „Hier passt weder „dieses“ noch „welches“. „Dass“ verbindet zwei Sätze.“ Bei Antwort „das“: „Probe: „dieses“ oder „welches“ passt. Darum „das“ mit einem s.“

**D-M5 · Großschreibung: Antwort ist die einzige großgeschriebene Wahl** · `german_task_templates.dart:1179–1186`
- Betrifft „Wir gehen heute in die schule.“ (gehen, heute, in), „Papa kocht die suppe für uns.“ (kocht, für, uns), „Ich male einen schönen baum.“ (male, einen, schönen).
- Korrektur: je einen großgeschriebenen Ablenker aufnehmen: `['gehen', 'heute', 'Wir']`, `['kocht', 'für', 'Papa']`, `['male', 'schönen', 'Ich']`.

**D-M6 · Verkleinerungsform: Lösung am Wortende erkennbar** · `german_curriculum_extensions.dart:109–128`
- In allen 15 Einträgen endet nur die richtige Antwort auf -chen; die Ablenker sind Mehrzahl oder Unsinn („Baumung“, „Sternig“).
- Korrektur: falsche Verkleinerungen anbieten, z. B. Baum: `['Baumchen', 'Bäumechen', 'Bäume']`, Blume: `['Blumchen', 'Blümechen', 'Blumen']`, Topf: `['Topfchen', 'Töpfechen', 'Töpfe']`.

**D-M7 · Vorvergangenheit: Lösung an „hatte/war“ erkennbar** · `german_task_templates.dart:1253–1266`, `german_curriculum_extensions.dart:565–594`
- Alle Ablenker sind andere Zeiten („liest“, „las“, „wird lesen“). Ob „hatte“ oder „war“ passt, wird nie geprüft.
- Korrektur: je Verb das falsche Hilfszeitwort und ein falsches Mittelwort anbieten, z. B. gehen: `['hatte gegangen', 'war gegeht', 'ging']`, lesen: `['war gelesen', 'hatte gelest', 'las']`.

**D-M8 · Wortende: der naheliegende Verwechslungsbuchstabe fehlt** · `school_exercise_generator.dart:708` (und Altpfad 925)
- „Ber_“ → g mit Ablenkern b, d, t; „Schran_“ → k mit b, d, t. Das Paar g/k wird nie gegeneinander gestellt.
- Korrektur: Ablenker paarweise wählen: d↔t, g↔k, b↔p, plus ein weiterer Buchstabe.

**D-M9 · Rechtschreibung steigt nicht mit der Klasse** · `school_exercise_generator.dart:710–719`, `lib/core/spelling_context_data.dart`
- Kontextsätze nach Klasse: Häufige Wörter 24/2/1/1, Doppelmitlaut 24/1/1/0, Dehnungen 20/2/0/0, Satzzeichen 20/0/0/0. Der Filter `q.grade <= grade` und die 75-%-Quote führen dazu, dass in Klasse 4 bei „Häufige Wörter“ 28 von 34 Aufgaben Kontextsätze sind, 24 davon mit Klasse-1-Wörtern (Hund, Katze, Sonne).
- Korrektur: je Klasse und Einheit mindestens 20 eigene Sätze (Kl. 2: Fahrrad, Schlüssel, Frühstück …; Kl. 3: Geschichte, nämlich, Straße …; Kl. 4: Bibliothek, Rhythmus, ziemlich …) und in der Zielklasse nur diese ziehen.

**D-M10 · „Groß und klein“ hat immer dieselbe Lösung** · `school_exercise_generator.dart:721–739`
- „Wie schreibt man das Namenwort „schule“ normalerweise im Satz?“ → immer „Großer Anfang: …“.
- Korrektur: Satz zeigen und fragen: „Welches Wort muss groß geschrieben werden? „wir gehen in die schule.““ mit Auswahl `gehen · in · schule`, später Sätze mit zwei Namenwörtern.

**D-M11 · „St oder Sp“: Lösung steht in der Frage** · `school_exercise_generator.dart:998`
- „Welche Buchstaben stehen am Anfang von Stuhl?“
- Korrektur: „Was fehlt am Wortanfang? __uhl“ mit Bild oder Vorlesen des Wortes.

**D-M12 · Lesen: vier der fünf Einheiten ohne echten Leseanspruch** · `school_exercise_generator.dart:1055–1131`
- „Sätze lesen“ und „Lesesinn“ ziehen aus demselben Pool (Zeile 1118 ff.) und sind inhaltsgleich.
- „Bild und Wort“: 8 Emojis; die Ablenker sind durch `.take(3)` fast immer Katze, Hund, Frosch (Zeile 1079). Unverändert in Klasse 1–4.
- „Wörter lesen“: 6 Rätsel (Klasse 1: 5).
- „Reihenfolge“: Die drei Sätze stehen schon in der richtigen Reihenfolge da; „Was passiert zuerst?“ ist immer der erste Satz (Zeile 1113).
- Korrektur: „Lesesinn“ auf eigene Schlussfolgerungs-Fragen umstellen; Ablenker in „Bild und Wort“ mischen und ähnlich klingende Wörter nehmen; in „Reihenfolge“ die Sätze gemischt zeigen und ordnen lassen.

**D-M13 · Lesetexte Klasse 4 in Erwachsenensprache** · `lib/core/reading_comprehension_data.dart` (Block `4:`)
- Beispiele: „Die dort beschriebene Beobachtung unterstützt nur eine der Angaben.“ · „Warum ist eine Verallgemeinerung auf alle Straßen unsicher?“ · „Was fehlt Ali für einen Vergleich?“ → „prüfbare Angaben“.
- Korrektur am Beispiel: Text „Lumo liest in zwei Büchern etwas Verschiedenes über Igel. Darum schaut er in ein neues Tierlexikon. Dort steht, was Forscher beobachtet haben. Nur eines der beiden Bücher hat recht.“ Frage: „Wie findet Lumo heraus, welches Buch recht hat?“ → „Er schaut in einem dritten Buch nach.“

**D-M14 · Lückensätze: zwei passende Wörter, Klasse 3–4 zu leicht** · `lib/features/deutsch/deutsch_gap_sentences.dart:35, 68, 113–200`
- „Der Hund spielt im ___.“ – „Haus“ passt ebenso wie „Garten“. „Der Vogel sitzt auf dem ___.“ – „Tisch“ und „Teller“ sind grammatisch möglich.
- Klasse 3–4: „Der Bäcker backt frisches ___.“ (Brot/Gras/Eis/Papier), „Eine Woche hat sieben ___.“ Das ist Niveau Klasse 1. Nur 10 Sätze je Stufe.
- Korrektur: `options: ['Wasser', 'Garten', 'Ball', 'Baum']` und `['Wasser', 'Ast', 'Fisch', 'Himmel']`; für Klasse 3–4 Sätze mit Bindewörtern und Fällen, z. B. „Wir bleiben zu Hause, ___ es stark regnet.“ (weil/aber/oder/und).

**D-M15 · Gegenteil-Geschichten: sinnlose und kränkende Sätze** · `lumo_adventure_tasks.dart:596–597`, `adventure_word_data.dart:190–196`
- Jedes Wortpaar wird auf eine Figur oder das Kind selbst bezogen: „Ivo ist heute gar nicht hell“, „Pip ist heute gar nicht leer“, „{Name des Kindes} ist heute gar nicht dünn … Was ist {Name}?“ → „dick“.
- Korrektur: je Paar ein passendes Ding, z. B. „Lumos Tee ist nicht mehr heiß. Er ist jetzt …“ (kalt), „Der Korb ist nicht voll. Er ist …“ (leer). `dick/dünn`, `alt/jung` nur für Dinge (Buch, Ast).

**D-M16 · Wörter zusammensetzen: vertauschte Reihenfolge gilt als falsch** · `lumo_adventure_tasks.dart:625`
- „Aus welchen zwei Wörtern ist Sonnenblume zusammengesetzt?“ → richtig „Sonne + Blume“, falsch „Blume + Sonne“. Gefragt ist nach den Wörtern, nicht nach der Reihenfolge.
- Korrektur: den vertauschten Ablenker streichen oder fragen: „In welcher Reihenfolge stehen die Wörter in Sonnenblume?“

**D-M17 · Wortarten Klasse 3 ist dieselbe Aufgabe wie in Klasse 2** · `german_task_templates.dart:114–119, 469–513`
- „Wortarten“ stellt dieselben drei Fragen wie „Namenwörter/Tunwörter/Wiewörter“, mit denselben Wörtern (alle Verben und Adjektive haben Klasse 1).
- Korrektur: in Klasse 3 Begleiter und Fürwörter ergänzen und Wörter im Satz bestimmen lassen (wie „Wortarten-Jagd“).

**D-M18 · Schreiben ohne Steigerung** · `school_exercise_generator.dart:1004–1053`
- Alle vier Klassen: dieselben fünf Einheiten. Klasse 4 bekommt „Spure den Buchstaben A nach.“ und „Schreibe die Zahl 7 schön und langsam.“ Nur Großbuchstaben A–Z, keine Kleinbuchstaben, Umlaute, ß. „Schwungübung“ besteht aus den Buchstaben S, C, O, U.
- „Satz abschreiben“ nimmt den ersten Satz eines Lesetextes, in Klasse 3/4 bis rund 70 Zeichen (z. B. „Ein Museum zeigt ein altes Waschbrett und eine moderne Waschmaschine“).
- Korrektur: Kl. 1 Groß- und Kleinbuchstaben, Kl. 2 Wörter mit Umlaut/ß, Kl. 3 kurze Sätze bis 40 Zeichen, Kl. 4 Sätze mit Satzzeichen und wörtlicher Rede.

**D-M19 · Kartenspiel-Fragen: Dubletten** · `assets/learning_questions/grade2_german.json` (Einträge 26, 46–50), `grade1_german.json` (46–50)
- Klasse 2: „Was reimt sich auf Haus?“ steht sechsmal in der Datei, fünfmal wortgleich. Klasse 1: Einträge 46–50 wiederholen 2, 4, 7, 9, 11. Reim-Ablenker sind zehnmal „Katze, Auto, Blume“.
- Korrektur: Dubletten durch neue Fragen ersetzen (Silben, Artikel, Gegenteile) und Ablenker je Frage wechseln.

**D-M20 · Quiz Deutsch: Großschreibung und Begriffe** · `lib/domain/quiz/quiz_question_bank.dart:902–935`
- „Welches Wort ist ein Adjektiv (Wie-Wort)?“ mit `['Laufen', 'Hund', 'Schnell', 'Tisch']`: Verb und Adjektiv sind großgeschrieben. → `['laufen', 'Hund', 'schnell', 'Tisch']`.
- „Ein Tu-Wort“, „Ein Name-Wort“ → „Ein Tunwort“, „Ein Namenwort“ (so heißt es im Rest der App).
- „Welcher Fischname ist richtig geschrieben?“ (Schtohr/Stohr/Stoa/Stör): unbekanntes Wort. → „Welches Wort ist richtig geschrieben?“ `['Schtern', 'Stern', 'Stärn', 'Sternn']`.

**D-M21 · Lernmodule Mehrzahl und Artikel** · `lib/features/learning_modules/mehrzahl/mehrzahl_screen.dart:64`, `artikel_lernen/artikel_lernen_screen.dart:43`
- „Mann → Männer“ mit Ablenker „Maenner“: dieselbe Form in Ersatzschreibung wird als falsch gewertet. → `['Mannes', 'Mannen', 'Männe']`.
- `['der', 'Tisch', '🪑']`: Das Bild zeigt einen Sessel. → anderes Bild oder `['der', 'Sessel', '🪑']`.

**D-M22 · Lese-Buddy und Journal: Oberflächentexte ohne Umlaute** · `lib/features/reading/lumo_reading_buddy_screen.dart:419, 484, 618, 700`; `lib/features/journal/lumo_journal_screen.dart:809–950`
- „Lumo hoert dir zu.“, „Woerter · Saetze“, „Ich hoere dir zu...“, „Eine richtig schoene Geschichte!“, „beim naechsten Mal“.
- Korrektur: „Lumo hört dir zu.“, „Wörter · Sätze“, „Ich höre dir zu …“, „Eine richtig schöne Geschichte!“, „beim nächsten Mal“. Ebenso `lumo_photo_lesson_screen.dart:348, 376` („Uebungen“, „aehnliche“).

**D-M23 · Synonyme: „fröhlich“ – „lustig“** · `german_task_templates.dart:960`
- Die Wörter bedeuten nicht dasselbe (fröhlich = gut gelaunt, lustig = zum Lachen).
- Korrektur: `_PairItem('fröhlich', 'heiter', <String>['wütend', 'hart', 'gerade'])`.

**D-M24 · „Bibliothek“ mit zwei verschiedenen Silbenzahlen** · `primary_school_word_data.dart:422` („Bi-blio-thek“, 3) gegen `adventure_word_data.dart:95` und `lib/domain/writing/writing_word_bank.dart:250` („Bi-bli-o-thek“, 4)
- Im Silbenrätsel ist 4 richtig und 3 ein Ablenker. Der Dreier-Eintrag wird derzeit in keiner Frage gezogen, widerspricht aber den anderen beiden.
- Korrektur: in den Wortdaten `'Bi-bli-o-thek'`; das Wort wegen der unsicheren Sprechsilbe „li-o“ besser nicht zum Silbenzählen verwenden.

### 4.3 Deutsch – leicht

- **D-L1** · `german_task_templates.dart:317, 865–872` · „Welche Buchstaben passen zum Laut „mmmm“?“ bei einem einzelnen Buchstaben; nur 6 Laute. → „Welcher Buchstabe passt zum Laut „mmmm“?“; Bank auf alle eingeführten Laute erweitern.
- **D-L2** · `german_task_templates.dart:432` · „Welche Mehrzahl ist richtig: der Hund?“ → „Wie heißt die Mehrzahl von „der Hund“?“
- **D-L3** · `german_task_templates.dart:517` · Person fehlt. → „Wie heißt „gehen“ in der Mitvergangenheit? Er …“
- **D-L4** · `german_curriculum_extensions.dart:269` („Oma backt“) gegen `german_task_templates.dart:1169` („Mama bäckt“) und Lesetext „Mama backt“. Beide Formen sind richtig; eine wählen. → überall „backt“.
- **D-L5** · `primary_school_word_data.dart:67` · „Bär – Meer“ ist kein reiner Reim (ä/e). → `['Meer', 'Speer']`.
- **D-L6** · Österreichische Wörter uneinheitlich (nichts davon ist falsch): „Mütze“ (`primary_school_word_data.dart:709`, Wetter-Modul) neben „Haube“ (`school_exercise_generator.dart:1398`); „Erdäpfel“ (Wortdaten) neben „Kartoffel“ und „Tomate“ (`adventure_word_data.dart:72, 89`); „Pflaume“ (`adventure_word_data.dart:262`); „Kassenbon“ (`reading_comprehension_data.dart:262–264`); „Schrank“ (`german_curriculum_extensions.dart:148`) neben „Kasten“; „Gehweg“ neben „Gehsteig“. → eine Wortliste festlegen, z. B. Haube, Erdapfel, Paradeiser oder Tomate, Zwetschke, Rechnung, Kasten, Gehsteig.
- **D-L7** · `lib/domain/writing/writing_word_bank.dart:56, 80` · „Mama beginnt mit M wie M wie Mond.“ → „Mama beginnt mit M wie Mond.“ · „… zwei Striche und eine Bruecke.“ → „… zwei Striche und eine Brücke.“
- **D-L8** · `spelling_context_data.dart:184` · „Der Ball ist mein ___.“ (Spiel) ist kein natürlicher Satz. → „Fangen ist mein liebstes ___.“ · Zeile 289: „Stad_“ → t ist wegen „dt“ ein Sonderfall; besser streichen.
- **D-L9** · `reading_comprehension_data.dart:48–50` · Text „im Sand“, Frage „Womit baut Lea?“ → Text: „Lea baut aus Sand einen Turm.“ · Zeile 239: „Lea findet beim Radfahren eine kaputte Lampe.“ → „Lea bemerkt beim Radfahren, dass ihre Lampe kaputt ist.“ · Zeile 365: „denselben Samen“ → „die gleichen Samen“.
- **D-L10** · `lib/features/reading/reading_text_library.dart`, `reading_comprehension.dart` · Lese-Buddy: 6 Texte je Klasse; Klasse 4 hat nur 4 Sätze (rund 45 Wörter) und je Text eine einzige wörtliche Frage. → ab Klasse 3 Texte mit 8–12 Sätzen und drei Fragen.
- **D-L11** · `quiz_question_bank.dart:489, 534, 949` · „Welche Jacke schützt dich vor Regen?“ nennt die Lösung (Regenjacke). → „Was ziehst du bei Regen an?“ · „Was fällt vom Himmel wenn es regnet?“ → Komma: „… vom Himmel, wenn es regnet?“ · „Zwölf“ → „zwölf“.
- **D-L12** · `lib/core/task_hint_service.dart:108–148` · Hinweise sind allgemeine Strategien, verraten nichts, helfen aber auch nicht am Inhalt; Zeile 126 ist für Klasse 1 zu schwer („ab dem letzten betonten Vokal“). → „Sprich beide Wörter laut. Klingen sie am Ende gleich?“
- **D-L13** · Begriffe wechseln: Namenwort / Nomen / Hauptwort (`safe_fallback_pool.dart`, Klasse 4) / Name-Wort (Quiz); Begleiter / Artikel. → je Klasse ein Begriff, der Fachbegriff in Klammern. Kartenspiel Klasse 1: Hinweis „Schau auf den ersten geschriebenen Buchstaben.“ verrät die Lösung der Frage „Mit welchem Buchstaben beginnt „Apfel“?“.

### 4.4 Sachunterricht – schwer

**S-S1 · „Was ist Frost?“ – falsche Erklärung**
- Ort: `lib/core/school_exercise_generator.dart:1451`.
- Ist: Antwort „gefrorene Feuchtigkeit bei Kälte“, Erklärung „Frost entsteht bei Kälte.“
- Problem: Das beschreibt Reif. Frost heißt, dass die Temperatur unter 0 Grad liegt.
- Korrektur: Antwort „Temperaturen unter 0 Grad“, Ablenker „heißer Regen“, „starker Wind“, „dichter Nebel“, Erklärung „Bei Frost ist es kälter als 0 Grad. Wasser gefriert dann zu Eis.“

### 4.5 Sachunterricht – mittel

**S-M1 · Wolken bestehen nicht aus Wasserdampf** · `school_exercise_generator.dart:1426`
- „Was sammelt sich zu Wolken?“ → „Wasserdampf“. Das Rätsel „die Wolke“ sagt richtig: „Ich bestehe aus winzigen Wassertröpfchen.“
- Korrektur: Frage „Woraus bestehen Wolken?“ → „aus winzigen Wassertröpfchen“, Ablenker „aus Rauch“, „aus Watte“, „aus Staub“.

**S-M2 · „Welcher Teil trägt Blätter und Blüten?“ → „Stamm“** · `school_exercise_generator.dart:1392`
- Bei Blumen ist es der Stängel; die Ablenker sind Schuh, Kabel, Topf.
- Korrektur: Antwort „Stängel“, Ablenker „Wurzel“, „Samen“, „Frucht“, Erklärung „Der Stängel trägt Blätter und Blüten. Beim Baum heißt er Stamm.“

**S-M3 · „Was schützt unsere inneren Organe außen?“** · `school_exercise_generator.dart:1450`
- Unklarer Satzbau; „Organe schützen“ lässt an Knochen denken.
- Korrektur: „Was bedeckt und schützt deinen ganzen Körper?“ → „die Haut“, Ablenker „die Haare“, „die Knochen“, „die Muskeln“.

**S-M4 · Humus** · `school_exercise_generator.dart:1440`
- „Was schützt den Boden und wird aus Pflanzenresten?“ ist unvollständig, und Humus ist Teil des Bodens.
- Korrektur: „Was entsteht im Boden aus abgestorbenen Pflanzenresten?“ → „Humus“, Ablenker „Sand“, „Kies“, „Lehm“.

**S-M5 · Unverständliche Verkehrsfrage** · `school_exercise_generator.dart:1412`
- „Auf welcher Seite geht man am Gehsteig besonders aufmerksam?“ → „weg von der Fahrbahn“.
- Korrektur: „Wo gehst du auf dem Gehsteig am sichersten?“ → „auf der Seite bei den Häusern“, Ablenker „ganz am Randstein“, „auf der Fahrbahn“, „zwischen parkenden Autos“.

**S-M6 · Marille** · `school_exercise_generator.dart:1410`
- „Welche Frucht ist typisch österreichisch als Marille bekannt?“ mit der Antwort „Aprikose heißt in Österreich Marille“.
- Korrektur: „Wie heißt die Aprikose in Österreich?“ → „Marille“, Ablenker „Ribisel“, „Zwetschke“, „Weichsel“.

**S-M7 · Berufe: richtige Antwort an der Form erkennbar** · `school_exercise_generator.dart:1400–1402`
- Nur die richtige Antwort hat die Doppelform („Bäckerin oder Bäcker“ gegen „Ärztin“, „Postler“, „Tischler“).
- Korrektur: alle vier Möglichkeiten gleich bauen, z. B. „Bäckerin oder Bäcker“, „Ärztin oder Arzt“, „Tischlerin oder Tischler“, „Postlerin oder Postler“.

**S-M8 · Grausame Ablenker in Klasse 1** · `lib/core/science_task_data.dart:424–431`
- „Wie behandeln wir ein kleines Tier beim Beobachten?“ mit „wir reißen ihm Beine aus“, „wir treten darauf“.
- Korrektur: „wir nehmen es mit nach Hause“, „wir schütteln das Glas“, „wir lassen es lange in der Sonne stehen“.

**S-M9 · Kontinente** · `school_exercise_generator.dart:1468`
- „Wie viele Kontinente lernen viele Schulkarten?“ ist kein richtiger Satz.
- Korrektur: „Wie viele Kontinente werden meistens gezählt?“ → „7“, Erklärung „Meist zählt man sieben: Europa, Asien, Afrika, Nordamerika, Südamerika, Australien und die Antarktis.“

**S-M10 · Verkehr ohne österreichische Regeln** · `lib/core/science_quality_extension.dart:15`, `science_task_data.dart:455–472`, `school_exercise_generator.dart:1397`
- Klasse 2–3 fragt, wie man mit dem Rad abbiegt, ohne zu sagen, dass Kinder in Österreich unter 12 Jahren nur in Begleitung auf der Straße fahren dürfen (Ausnahme: Radfahrausweis nach der freiwilligen Radfahrprüfung). Überall „Zebrastreifen“; der Begriff „Schutzweg“ fehlt. Notrufnummern (122, 133, 144) kommen in keiner Frage vor.
- Korrektur: Erklärung ergänzen: „Auf der Straße fährst du mit dem Rad nur mit einer erwachsenen Begleitung, bis du den Radfahrausweis hast.“ · „Zebrastreifen (Schutzweg)“ · neue Fragen: „Welche Nummer hat die Rettung?“ → „144“.

**S-M11 · Alberne Ablenker** · durchgehend in `school_exercise_generator.dart:1359–1494`
- Beispiele: Zeile 1420 „Was gehört zur Obstgruppe?“ (Hammer, Schuh, Kabel) · 1422 (Steine, Plastik, Batterien) · 1373–1375 (Auto, Hund, Sackerl; Rad, Schuh, Ball; Fernseher, Schere, Helm) · 1388–1389 („im Topfen“, „im Federpennal“) · 1476 („Semmel, Topfen und Saft“).
- Problem: Die Lösung ist ohne Wissen klar.
- Korrektur am Beispiel: Obst: `['Apfel', 'Karotte', 'Semmel', 'Käse']` · Vitamine: `['Gemüse und Obst', 'Zuckerl', 'Limonade', 'Chips']` · Pflanzenteil: `['Blatt', 'Wurzel', 'Blüte', 'Frucht']` · Nest: `['im Baum', 'im Wasser', 'unter der Erde', 'im Schnee']`.

**S-M12 · Dubletten** · `school_exercise_generator.dart`, `science_task_data.dart`, `science_quality_extension.dart`
- Klasse 1: „Welcher Tag kommt nach Montag?“ (1382) und „… direkt nach Montag?“ (`science_task_data.dart:178`). Klasse 2: „Wer löscht Brände?“ (1399) und „Wer hilft, einen Brand zu löschen?“ (476). Klasse 3: Herz zweimal (1415, `science_task_data.dart:632`); „Ein Kalenderjahr beginnt mit welchem Monat?“ wiederholt Klasse 2; Wasserleitung wiederholt Klasse 2. Klasse 4: Donau zweimal (1456, `science_task_data.dart:774`), Zeitleiste zweimal (1486, 752), Bundeshauptstadt und Zahl der Bundesländer aus Klasse 3.
- Korrektur: je Paar eine Frage streichen und durch ein neues Thema ersetzen.

**S-M13 · Monat und Jahreszeit** · `lumo_adventure_tasks.dart:774–787`
- „In welcher Jahreszeit liegt der Dezember bei uns in Österreich meistens?“ → „Winter“. Nach dem Kalender beginnt der Winter am 21. Dezember; der größere Teil des Monats ist Herbst. Dasselbe gilt für März, Juni und September.
- Korrektur: diese vier Monate nicht fragen oder umformulieren: „Welche Jahreszeit beginnt im Dezember?“

**S-M14 · „Diagramme lesen“ ohne Diagramm** · `science_quality_extension.dart:44–47`, `school_exercise_generator.dart:1480–1481`
- Die Zahlen stehen im Text („Ein Diagramm zeigt 8 Regentage im April und 5 im Mai.“); gelesen wird nichts. Zeile 1480: „Was zeigt ein Säulendiagramm?“ → „Werte als Balken“.
- Korrektur: echtes Säulenbild zur Aufgabe; Antwort „Werte als Säulen“.

**S-M15 · Klasse 2 ist die dünnste Stufe** · alle drei Dateien
- Eigene Fragen Klasse 2: 46, davon Jahreszeiten 1, Familie 3, Wetter 3, Körper 4, Zeit 5. Diese Einheiten werden mit Klasse-1-Fragen aufgefüllt (Regel „unter 6 eigene Fragen“ in `school_exercise_generator.dart:642`).
- Korrektur: je Einheit auf mindestens 8 eigene Fragen bringen.

**S-M16 · Lernmodule Wetter, Tiere, Verkehr** · `lib/features/learning_modules/`
- `wetter/wetter_screen.dart:78`: „Was ist bei Wolken sinnvoll?“ → „Pullover“. Dafür gibt es keine richtige Antwort. → Wolken aus der Kleidungsfrage nehmen.
- `tiere/tiere_screen.dart:72`: „Wo kann man das Tier Ente bei uns häufig sehen?“ → „See“; „Bauernhof“ ist ebenso richtig. → Ente nur mit „am Teich“ fragen und „Bauernhof“ nicht anbieten.
- `verkehr/verkehr_screen.dart:80`: „Wann schaut man vor dem Überqueren?“ → „Links, rechts, links“. Falsches Fragewort. → „Wohin schaust du, bevor du die Straße überquerst?“
- `verkehr/verkehr_screen.dart:69–71`: „Wo darf man die Straße überqueren?“ → „Am Zebrastreifen“. → „Wo überquerst du die Straße am sichersten?“; „Auf der Kurve“ → „In der Kurve“.

**S-M17 · Aktivitätskarten in Lehrersprache** · `lib/core/curriculum/primary_activity_catalog.dart`
- 60 Karten, je 8 für Musik, Kunst und Gestaltung, Technik und Design, Bewegung und Sport, Verkehrsbildung, Englisch, Sachunterricht und 4 für Deutsch. Formulierungen wie „Entscheidungsmatrix“, „Mobilitätsbezogene Reflexionskompetenz“, „Analysiere drei dargestellte Verkehrssituationen“ (es wird keine dargestellt).
- Korrektur am Beispiel: „Schau dir deinen Weg zur Schule an. Womit kommst du am sichersten hin? Erzähle, warum.“

### 4.6 Sachunterricht – leicht

- **S-L1** · `school_exercise_generator.dart:1432` · „In welchem Bundesland liegt Gänserndorf?“ ist nur für Kinder aus der Gegend lösbar. → durch „In welchem Bundesland liegt Innsbruck?“ ersetzen oder den Wohnort aus dem Profil nehmen.
- **S-L2** · `school_exercise_generator.dart:1413–1414`, `science_task_data.dart:483`, `quiz_question_bank.dart:774–788` · „Maurer“, „Schlosser“, „ein Installateur“, „Arzt“, „Feuerwehrmann“ nur männlich, andere Fragen mit Doppelform. → „Maurerin oder Maurer“ usw.
- **S-L3** · `science_task_data.dart:139, 502` · „Betreuungsperson“ ist kein Kinderwort. → „einer Lehrerin oder einem Lehrer“.
- **S-L4** · Sprachliches: `science_task_data.dart:396` „Was hilft beim Regen trocken zu bleiben?“ → „Was hilft dir, bei Regen trocken zu bleiben?“ · `school_exercise_generator.dart:1446` „Welche Farbe hat die österreichische Flagge?“ → „Welche Farben …“ · `wetter_screen.dart:113` „Es ist laut wegen dem Donner“ → „Der Donner ist sehr laut“ · `verkehr_screen.dart:93` „Am Gehweg“ → „Am Gehsteig“ · `science_task_data.dart:783` „Antarktika“ neben „Antarktis“ (1491) → überall „Antarktis“ · `science_task_data.dart:534` „Wasser liegt bei Frost draußen.“ → „Ein Kübel Wasser steht bei Frost draußen.“
- **S-L5** · `school_exercise_generator.dart:1482` „Welche Hymne gehört zu Österreich?“ → „Bundeshymne“ prüft nichts. → streichen. · 1490 Erklärung „Salzburg ist Stadt und Bundesland-Hauptstadt.“ → „Die Stadt Salzburg ist die Landeshauptstadt des Bundeslandes Salzburg.“ · 1476 „Batterie, Kabel, Lampe und Schalter“: ein Schalter ist nicht nötig. → „Batterie, Kabel und Lampe“.
- **S-L6** · `science_task_data.dart:639` · „Warum dauert ein Schaltjahr einen Tag länger?“ → die Antwort nennt kein Warum. → „Was ist in einem Schaltjahr anders?“
- **S-L7** · `science_task_data.dart:561` · Ablenker „Es verschwindet ohne Stoffänderung aus der Welt.“ ist für Kinder unverständlich. → „Es verschwindet für immer.“ · Zeile 538 „Es verliert sein Gewicht vollständig.“ → „Es wird zu Dampf.“
- **S-L8** · `lumo_adventure_tasks.dart:718–721` · „Wer bin ich?“ auch bei Dingen (Lineal, Wolke); Erklärung beginnt immer mit „Gut geraten“, auch nach einer falschen Antwort. → bei Dingen „Was bin ich?“; Erklärung „Das ist … !“
- **S-L9** · Erklärungen wiederholen oft nur die Antwort oder sind zu abstrakt: 1472 „Nahrungsketten zeigen Energiefluss.“ → „Beispiel: Das Gras wird vom Hasen gefressen, der Hase vom Fuchs.“
- **S-L10** · `lib/features/learning_modules/jahreszeiten/season_question_deck.dart:49` · „Nach dem Sommer werden die Tage wieder kürzer.“ Die Tage werden schon ab Ende Juni kürzer. → „Die Tage werden kürzer, und es wird kühler.“ · Zeilen 38 und 55 nennen die Lösung im Wort (Sommerferien, Winterjacke).
- **S-L11** · Zu leicht für die Klasse: 1449 „Welche Pflanze trägt Äpfel?“ (Klasse 3, fast wortgleich in Klasse 1) · `science_task_data.dart:417` „Welches Tier trägt ein Schneckenhaus?“ · umgekehrt 1362 „Welches Tier ist ein Säugetier?“ in Klasse 1.
- **S-L12** · `lib/core/safe_fallback_pool.dart` · Ersatzaufgaben Klasse 3–4 auf Klasse-1-Niveau („Welches Tier lebt oft im Wasser?“, „Wozu dient ein Fahrradhelm?“ → „Schützen“/„Kochen“/„Lesen“).

### 4.7 Englisch – mittel

**E-M1 · Ein einziges Format, in Klasse 1–2 rein schriftlich** · `school_exercise_generator.dart:1133–1164`
- Jede Aufgabe lautet „Was bedeutet „…“?“ mit vier deutschen Wörtern. Es gibt kein Hören, kein Sprechen, keine Richtung Deutsch → Englisch, keine Bilder, keine Sätze zum Ergänzen. Ein Kind der 1. Klasse muss „grandmother“, „pencil case“ oder „good evening“ lesen, bevor es Deutsch sicher liest. Das Aufgabenmodell `LumoTask` hat kein Feld für Ton.
- Korrektur: Klasse 1–2 als Hör-Aufgabe mit Bildern („Hör zu und tippe das richtige Bild“), ab Klasse 3 zusätzlich Deutsch → Englisch und Lückensätze („I ___ hungry.“ am/is/are).

**E-M2 · Wörter und Sätze in einer Einheit gemischt** · `english_vocabulary_extensions.dart:149–197`, Ablenker-Ziehung `school_exercise_generator.dart:1154`
- In „Schulsachen“, „Wetter“ und „Essen“ (Klasse 3) können alle 45 Wortfragen ganze Sätze als Ablenker bekommen und alle 10 Satzfragen einzelne Wörter (z. B. „water“ → Wasser / „Kann ich etwas Wasser haben?“). Die Lösung ist an der Länge erkennbar.
- Korrektur: Sätze in die Einheit „Alltagssätze“ verschieben oder Ablenker nur aus derselben Art ziehen.

**E-M3 · Fast gleiche Antworten nebeneinander** · `school_exercise_generator.dart:1253, 1309`; `english_vocabulary_extensions.dart:75, 151, 205, 259–265`
- „bag“ → „Tasche“ neben „Schultasche“ (in der Einheit Schulsachen ist beides vertretbar) · „morning“ → „Morgen“ neben „am Morgen“, dazu „tomorrow“ → „morgen“ · „Monday“ → „Montag“ neben „am Montag“ (14 Aufgaben) · „car“ neben „toy car“.
- Korrektur: „bag“ aus Schulsachen streichen, weil „school bag“ vorhanden ist; „on Monday“ usw. in eine eigene kleine Einheit; „tomorrow“ und „morning“ nicht gemeinsam als Auswahl anbieten.

**E-M4 · Dasselbe Wort mit verschiedenen Übersetzungen** · `english_vocabulary_extensions.dart:72, 76`; `school_exercise_generator.dart:1252, 1289, 1292`; `safe_fallback_pool.dart`
- „pen“: Klasse 1 „Kugelschreiber“ (die Erweiterung überschreibt „Stift“), Klasse 3 „Stift“ · „desk“: Klasse 1 „Schreibtisch“, Klasse 3 „Tisch“ · „school bag“ gegen „schoolbag“ (Ersatzaufgabe) · Farben klein („rot“) gegen groß („Rot“, Ersatzaufgabe).
- Korrektur: „pen“ → „Stift“ und „pencil“ → „Bleistift“ überall; „desk“ → „Schultisch“; „school bag“; Farben klein.

### 4.8 Englisch – leicht

- **E-L1** · `school_exercise_generator.dart:1160` · Bei Sätzen entsteht „Was bedeutet „Can I have some water?“?“. → „Was bedeutet dieser Satz? „Can I have some water?““
- **E-L2** · `english_vocabulary_extensions.dart:223, 318` · „Let us play.“, „Let us check the answer.“ → „Let's play.“, „Let's check the answer.“
- **E-L3** · `english_vocabulary_extensions.dart:155` · „whiteboard“ → „weiße Schreibtafel“. → „Whiteboard (weiße Tafel)“.
- **E-L4** · `english_vocabulary_extensions.dart:291`, `school_exercise_generator.dart:1341` · „Schweiz“ ohne Artikel, daneben „die Türkei“, „die Niederlande“. → „die Schweiz“. „England“ → „England“ prüft nichts; „Great Britain“ → „Großbritannien“ ergänzen.
- **E-L5** · `english_vocabulary_extensions.dart:182–183` · „Kartoffel“, „Tomate“ gegen „Erdäpfel“ in den Deutsch-Wortdaten. Siehe D-L6.
- **E-L6** · `school_exercise_generator.dart:1162` · Erklärung wiederholt nur die Lösung. → Beispielsatz ergänzen: „dog = Hund. The dog is brown.“
- **E-L7** · Rund 15 Wörter sind im Deutschen gleich und prüfen nichts: orange, baby, hand, arm, finger, ball, puzzle, giraffe, tiger, wind, warm, England, Portugal. → als Hör-Aufgabe nutzen, weil nur die Aussprache anders ist.
- **E-L8** · `lib/features/learning/curriculum_activities_screen.dart:365` verweist auf die Einheit „Alltag“, die es nicht gibt (sie heißt „Alltagssätze“). Die Einheit „Tageszeit“ enthält auch Mahlzeiten und today/tomorrow/yesterday. → Verweis korrigieren; Einheit in „Tag und Zeit“ umbenennen.

Geprüft und in Ordnung: alle 325 Übersetzungen, Artikel und Mehrzahlformen (feet, teeth, toes); britische Schreibung durchgehend (grey, rubber, football, skipping rope, exercise book, favourite).

## 5. Lücken (ohne Anspruch auf Lehrplan-Vollständigkeit)

| Bereich | Bestand | Was Eltern vermutlich vermissen |
|---|---|---|
| Englisch Kl. 1 | 7 Einheiten, 77 Wörter | Hören und Sprechen |
| Englisch Kl. 2 | 4 neue Einheiten, 68 Wörter (Zahlen bis 20, Körper, Spielzeug, Tiere) | Kleidung, Zuhause, Essen, Gefühle |
| Englisch Kl. 3 | 5 Einheiten, 82 Einträge, davon 22 Sätze | Monate, Zahlen bis 100, „I like / I have / I can“ |
| Englisch Kl. 4 | 5 Einheiten, 98 Einträge, davon 15 Sätze | Fragen bilden, Uhrzeit, kurze Lesetexte, Schreiben |
| Sachunterricht Kl. 2 | 46 Fragen, fünf Einheiten mit 1–5 eigenen Fragen | Notruf, Zähne und Gesundheit, Wohnort, Müll trennen |
| Sachunterricht Kl. 4 | 59 Fragen in 6 Einheiten; Geschichte 10, Kontinente 8, Diagramme 6 | Nachbarländer (nur 1 Frage), Himmelsrichtungen und Karte, Österreichs Geschichte, Magnet, Luft und Wasser, Planeten, Körper und Gesundheit, Medien |
| Deutsch Kl. 3–4 | je 8 Vorlagen, meist 20 Aufgaben je Vorlage (Kl. 3: 299, Kl. 4: 160 unterschiedliche Aufgaben) | Satzarten, Bindewörter, Fürwörter, Wörterbuch-Arbeit, Texte schreiben |
| Lesen | je Klasse 12 Kurztexte + 6 Lese-Buddy-Texte | längere Texte ab Klasse 3, Sachtexte mit Tabelle, Gedichte |
| Musik, Kunst und Gestaltung, Technik und Design, Bewegung und Sport | 0 überprüfbare Aufgaben; je 8 offene Aktivitätskarten (2 je Klasse) | – |

## 6. Die zehn wertvollsten Verbesserungen

1. **Laut- und Reimaufgaben hörbar machen und reparieren.** Wort vorlesen statt anzeigen, Bild dazu. Damit lösen sich D-S1, D-S2, D-M1 und D-M11.
2. **Englisch als Hören-Sehen-Sprechen aufbauen.** Klasse 1–2 Ton plus Bild; ab Klasse 3 beide Richtungen und Lückensätze; Wörter und Sätze trennen (E-M1, E-M2).
3. **Rechtschreibung je Klasse eigene Wortbanken geben.** Heute übt Klasse 4 zu drei Vierteln Klasse-1-Wörter (D-M9).
4. **Lesen wirklich stufen.** Reihenfolge durch Ordnen gemischter Sätze; ab Klasse 3 längere Geschichten mit drei Fragetypen (im Text finden, schließen, begründen); Klasse-4-Texte in Kindersprache (D-M12, D-M13).
5. **Ablenker aus demselben Themenfeld.** In Sachunterricht ist die Lösung oft ohne Wissen klar (S-M11). Eine Regel „alle vier Antworten aus derselben Gruppe“ hebt den Lernwert sofort.
6. **Erklärungen, die zur gewählten Antwort passen.** Regel, Beispiel, kleine Probe; bei dass/das abhängig von der Lösung (D-M4), bei Lesefragen der Beleg-Satz statt des ganzen Textes.
7. **Ein Test für Umlaute und ß in allen kindersichtbaren Texten.** Er hätte Quests, Tagestipps, Lese-Buddy und Journal gefunden (D-S4, D-S5, D-M22).
8. **Österreich-Wortliste festlegen und prüfen.** Haube/Mütze, Erdapfel/Kartoffel, Gehsteig/Gehweg, Schutzweg; dazu Radfahrregeln und Notrufnummern (D-L6, S-M10).
9. **Mehr Formate statt nur Antippen.** „Groß und klein“ als Wort im Satz antippen, Zusammensetzungen als Baupuzzle, Silben schieben, Wörter in Wortarten-Körbe sortieren, Gegenteil-Geschichten mit passenden Dingen (D-M10, D-M15, D-M16).
10. **Wiederkehrende Einheiten mit der Klasse wachsen lassen und Dubletten entfernen.** Silben, Artikel und Reime mit dem Wortpool der aktuellen Klasse; Wortarten Klasse 3 mit neuen Wortarten; Schreiben mit Kleinbuchstaben, Umlauten, Wörtern und Sätzen; Sach- und Kartenspiel-Dubletten ersetzen (D-M17, D-M18, D-M19, S-M12).

## 7. Nicht geprüft

- **Darstellung und Ton in der laufenden App.** Ob Fragen vorgelesen werden oder Wörter in Laut-Aufgaben verdeckt sind, konnte ich nicht sehen. D-M11 und E-M1 beruhen auf dem Aufgabentext.
- **Bilder.** Asset-Bilder habe ich nicht mit den Wörtern verglichen (z. B. `deutsch_hund.png` zu D-M14); geprüft sind nur Emojis im Code.
- **KI-erzeugte Inhalte** (`lumo_ai_proxy_client.dart`, `ai_tutor_service.dart`, Foto-Lektion, frei erzeugte Geschichten): nicht prüfbar ohne Dienst.
- **Nur überflogen:** `lumo_story_generator.dart` (Geschichten-Bausteine; nur die Übungen angesehen), `teacher_mode/topic_curriculum.dart` (enthält viele Beispiele ohne Umlaute; nicht geklärt, ob Kinder sie sehen).
- **Nicht gelesen:** `features/learning/learning_content.dart`, `games/games_content.dart`, `games/mini_games/mini_game_learning_screen.dart`, `sections/section_content.dart`, geführte Lektionen unter `features/tutoring/`, Schulbuch-Widgets.
- **Buchstabenformen** der Schreibvorlagen (`writing_engine.dart`, `expanded_writing_template_repository.dart`) gegen die österreichische Schulschrift: nicht geprüft.
- **Mathematik und Logik:** nicht Teil dieses Auftrags. Nebenbei gesehen: Tagestipp „Ein Rechteck hat 4 Ecken aber unterschiedliche Seiten.“ (`lumo_tagestipp_card.dart:220`).
- **Lehrplan:** kein Abgleich mit dem amtlichen Lehrplan; die Lücken in Abschnitt 5 sind eine Einschätzung aus Elternsicht.
- **Fakten ohne Nachschlagen:** Die Regeln zum Radfahren von Kindern in Österreich (S-M10) und die Flusslängen (Quizfrage „längster Fluss in Österreich“ → Donau, knapp vor der Mur) stammen aus meinem Wissen und wurden nicht online nachgeprüft.
