# Pädagogische Qualitätsprüfung der Lernmodule (Klasse 1–4)

Stand: 26.11.2026 · Team A1 „Curriculum und Aufgabenqualität“ · Zweig
`opus/agent-a1-curriculum` (Basis `3bdfeeb9`). Auftrag Heinz, Abschnitt 4.

## 1. Ergebnis in Kürze

- **Inventar:** Jede Lernkachel ist in `docs/qa/lernmodul_pruefmatrix.csv` erfasst
  (510 Zeilen): 260 Lernhub-Kacheln der Klassen 1–4 (220 öffnen den
  Aufgabengenerator, 40 ein eigenes Modul, den Lesebereich oder einen
  Aktivitätenkatalog), 35 Lernwerkzeuge, 74 Test-Einstiege (Kategorie × Stufe ×
  Klasse), 6 Schularbeit-Karten, 85 Akademie-Themen, 50 Lernspiel-Stufen. Die
  Matrix wird von `test/qa/lernmodul_pruefmatrix_test.dart` aus der echten
  Oberfläche erzeugt (Akademie auf 412 dp, jede Kachel wird angetippt). Eine neue
  oder umgeleitete Kachel lässt den Test scheitern.
- **Aufgaben geprüft:** 447 Rubrik-Klassen-Kombinationen mit 150 Aufgabenmustern,
  je 300 Startwerte (134 100 Aufgaben) in der Erkundung; dauerhaft als Tests:
  Mathematik 43 500 Aufgaben, davon 33 936 mit eigenen Lösern unabhängig
  nachgerechnet (0 falsche Lösungen), dazu Fachreinheit, Bewertung, Lage der
  Lösung, Kartenlänge, Lernspiel-Runden.
- **Gefunden und behoben: 11 Fehler** (je ein Commit mit Regressionstest, alle
  Tests vor der Korrektur rot). **Offen: 12 Punkte** (Abschnitt 6), meist
  Lehrplan- oder Gestaltungsentscheidungen.

## 2. Lehrplanbezug

Referenz ist der **Lehrplan der Volksschule, Anlage A, BGBl. II Nr. 1/2023**
(ausgegeben am 2. Jänner 2023), als PDF über
`https://rundschreiben.bmbwf.gv.at/download/2023-09_anlagen_0001_vs_bds.pdf`
geladen und gelesen (SHA-256 `da57025dec79ac33eb33c80f196cbd07db2c7c480580fcda0e3a52cb7429cde8`). Die RIS-Seite der geltenden
Fassung (Gesetzesnummer 10009275) antwortete am 26.11.2026 mit HTTP 503; spätere
Änderungen (laut RIS-Suche bis BGBl. II Nr. 178/2025) sind deshalb **nicht**
gegengeprüft. Verwendet wurden nur wörtlich nachgelesene Stellen:

| Schulstufe | Mathematik (Auszug Kompetenzbeschreibungen) |
|---|---|
| 1. | Zahlen bis mindestens 20; additiv bis 20; Strichlisten/Tabellen; Größen kg, m, ℓ, h, €, c; **Uhrzeiten mit vollen Stunden**; ebene Figuren, Körper, Symmetrie |
| 2. | Zahlen bis 100 (bis 1000 darstellen); additiv und **multiplikativ im Zahlenraum 100**; Säulen-/Balkendiagramme und Piktogramme; dag, dm, cm, min, s; halbe und Viertelstunden |
| 3. | Zahlen bis 1000, runden; **schriftlich** Addition, Subtraktion, Multiplikation mit einstelligem Multiplikator, Division mit einstelligem Divisor; t, g, km, mm, mℓ; Stunden und Minuten; Umfang von Quadrat und Rechteck |
| 4. | Zahlen bis 1 000 000; **Brüche mit kleinen Nennern (insbesondere 2, 4, 8)**; schriftlich mit ein- und zweistelligem Multiplikator/Divisor; **Flächeninhalt**; Zeitpunkte und Zeitspannen |

Sachunterricht: 1. Schulstufe Anwendungsbereich „Jahr und Zeit“ (Zeiteinteilung,
Begriffe für Zeiträume), 2. Schulstufe „Kalender und Uhr“. Begriffe wie
„Dezimalzahl“, „Mittelwert“ oder „Brüche erweitern“ kommen im Volksschul-Lehrplan
nicht vor. Lebende Fremdsprache: Grundstufe I verbindliche Übung, Grundstufe II
Pflichtgegenstand (bereits in `docs/AUSTRIA_VOLKSSCHULE_CURRICULUM_2026.md`).

## 3. Prüfinventar und automatische Prüfungen

| Datei | Prüft | Umfang |
|---|---|---|
| `test/qa/lernmodul_pruefmatrix_test.dart` | echte Navigation: jede Fach-, Themen- und Werkzeugkachel, Tests-Bildschirm, Schularbeit; je Generator-Kachel Fach/Klasse/Rubrik/Qualitätsprüfung | 510 Zeilen, je 120 Aufgaben pro Generator-Kachel |
| `test/qa/mathe_loesung_unabhaengig_test.dart` | unabhängige Löser (Rechnen, Umrechnen, Umfang/Fläche, Brüche, Runden, Zahlenmauer, Rätsel, Uhr, Markt, Rechengeschichten, Sachaufgaben 1–3 Schritte, Diagramme, Mittelwert); Lösung genau einmal; keine doppelten Karten; Zahlenraum der Klasse; Lage der Lösung unter den Karten; neue Muster ohne Löser fallen auf | alle Mathe-Rubriken Kl. 1–4 × 300 |
| `test/qa/fach_reinheit_test.dart` | kein Sachunterrichts-Kalenderwissen in Mathematik (auch Mathe-Tests); gleichnamige Schwächen wechseln nicht das Fach | 300 / 1500 Startwerte |
| `test/qa/test_bewertung_integritaet_test.dart` | Tests und Schularbeiten enthalten nur bewertbare Aufgaben (Generator und echter Lernbildschirm) | 4 × 120 Sitzungen, 2 × 28 Bildschirmstarts |
| `test/qa/kachel_ziel_test.dart` | Quizkacheln öffnen ihre Übung, Schreibmodule bleiben erreichbar | Widget-Test |
| `test/qa/ablenker_hinweis_test.dart` | Lösung nicht an der Kartenlänge erkennbar | 600 je Rubrik |
| `test/qa/lernspiel_runden_test.dart` | Lernspiele: Fach der Stufe, keine Wiederholung in der Runde, Runden unterscheiden sich | 49 Stufen × 60 Samen |
| `test/content_audit/adventure_language_test.dart` (ergänzt) | Artikel bei Steiermark/Burgenland, Dativ-n, Geheimcode-Länge | 600–2400 Startwerte |

Zusätzlich einmalig (Arbeitsdateien im Agentenordner, nicht im Repo): Englisch
beide Übersetzungsrichtungen widerspruchsfrei, kein Ablenker ist eine gültige
Übersetzung (0 Befunde); keine Aufgabe, deren Lösung bei derselben Frage an anderer
Stelle als falsche Karte erscheint (0); Wortarten-Lösungen richtig groß/klein
(0); Logik unabhängig gelöst (Muster, Zahlenmuster, Reihenfolgen, Schlussfolgern,
Regeln, Geheimcode: 0 falsche Lösungen); Quizshow 318 Fragen (Lösungslage
gleichverteilt, 13 % längste Karte, keine Fachdurchmischung).

## 4. Behobene Fehler

| Fach | Fehler | Commit |
|---|---|---|
| Mathematik | Mathe „Zeit“ (Kl. 1) fragte Wochentage, Monate und Tageszeiten der Reihe nach (z. B. „Heute ist Dienstag. Welcher Tag war gestern?“) – Sachunterricht-Stoff, gleicher Fehlertyp wie PR #554, auch im Mathe-Test. Ersetzt durch volle Stunden und Zeitspannen. | `1f212c8c` |
| Mathematik | Uhr-Abenteuer: Lösung in 900 von 900 Aufgaben die zweitfrüheste Uhrzeit; übrige Abenteuer zu 85 % mittlere Karte. | `483d5c39` |
| Mathematik | Rechengeschichten Kl. 4: „Von allen Buntstifte/Nüsse …“ (Dativ ohne -n). | `ab5e52cb` |
| Alle (Tests) | Mini-Test und gemischte Schularbeit zogen das unbewertete Schreibtraining als Prüfungsfrage; ein fehlerfreies Kind bekam z. B. 8 von 10. | `ecb49bbd` |
| Alle (gemischt) | Schwäche in „Tiere/Körper/Wetter“ führte fast immer zu Englisch statt Sachunterricht (Kl. 1: 130 : 7). | `b5a1689e` |
| Deutsch | Kachel „Buchstaben-Lautierung“ öffnete das Buchstaben-Nachspuren, „Wort-Bild-Zuordnung“ das Wortdiktat; die eigentlichen Aufgaben waren über die Kachel nicht erreichbar. | `0e643896` |
| Deutsch | Wortfamilien: Lösung in 548/600 die einzige längste Karte (jetzt 116/600). | `cba96312` |
| Deutsch | Kommas in Aufzählungen: nur die Lösung hatte zwei Kommas, 521/600 längste Karte (jetzt 0/600). | `cba96312` |
| Sachunterricht | Österreich-Reise: „über Steiermark“, „Landeshauptstadt von Steiermark“. | `fb40cce3` |
| Logik | Geheimcode: In 327/800 Aufgaben (Kl. 2) verriet die Anzahl der Zahlen das Wort. | `9fdd4305` |
| Lernspiele | Rechenstufen: jede Runde gleich, Aufgaben innerhalb der Runde wiederholt („Plus bis 5“: 3 + 2 und 4 + 1 abwechselnd). | `9b50c27f` |

Arbeitsfehler (offen genannt): `3c6262cb` machte den bestehenden Test M20 rot
(„Davon“ statt „Von allen“), korrigiert in `ab5e52cb`; nach `483d5c39` war der
Matrixtest kurz rot (gezählte Varianten), korrigiert in `a3368a50`.

Geänderte gemeinsame Dateien (klein und gezielt): `lib/features/learning/learning_content.dart`
(eine Zeile `gradedOnly`), `lib/features/teacher_mode/lumo_akademie_screen.dart`
(Schreibthemen beim Kachelstart überspringen), `lib/domain/games/mini_game_learning_task.dart`,
`test/games/board_game_premium_test.dart` (suchte die erste Aufgabe über die alte,
samenunabhängige Reihenfolge; prüft jetzt die tatsächlich gezeigte 3er-Reihen-Aufgabe).

## 5. Was Kind und Eltern jetzt merken

- Mathe-Tests der 1. Klasse fragen keine Wochentage oder Monate mehr, sondern
  volle Stunden („Die Schule beginnt um 8 Uhr und dauert 4 Stunden …“).
- Ein fehlerfreier Mini-Test zeigt 10 von 10; das Schreibtraining kommt nur beim
  freien Üben.
- Wer im Sachunterricht bei „Tiere“ schwächelt, übt im gemischten Training auch
  Sachunterricht-Tiere, nicht nur englische Tiernamen.
- Die Kacheln „Buchstaben-Lautierung“ und „Wort-Bild-Zuordnung“ starten die
  passende Übung; Nachspuren und Wortdiktat bleiben unter „Lernwerkzeuge“.
- Bei Abenteuer-Rechnungen, Wortfamilien, Kommas und dem Geheimcode lässt sich
  die richtige Karte nicht mehr an Lage oder Länge erraten.
- Lernspiel-Rechenrunden wiederholen keine Aufgabe und sind jedes Mal anders.

## 6. Offene Punkte (mit Reproduktion)

1. **Sachunterricht „Diagramme lesen“ (Kl. 4) ist überwiegend Rechnen**, z. B.
   „Samstag 340, Sonntag 410. Wie viele Besucher zusammen?“; ebenso Kl. 3 Wetter
   („7 Grad und 14 Grad … Unterschied?“) und Zeit und Kalender („9:00 + 50 Minuten“).
   Laut Lehrplan gehören Diagramme interpretieren zur Mathematik (2. Schulstufe).
   Die Fragen kommen auch im Sachunterricht-Test. Entscheidung Heinz: Einheit in
   Mathematik verschieben oder auf Ablesen ohne Rechnen umbauen.
   Reproduktion: `ExerciseFactory(seed: s).nextExact(grade: 4, subject: 'Sachunterricht', unit: 'Diagramme lesen')`.
2. **Mathe Kl. 4 über dem Lehrplan:** „Dezimalzahlen“ („8,4 + 6,7“, nicht als
   Knobelaufgabe gekennzeichnet), „Mittelwert“ und „Brüche erweitern“ (beide als
   Knobelaufgabe gekennzeichnet). „Brüche Vorbereitung“ (Hälfte/Viertel/Achtel von
   Zahlen) liegt in Kl. 3, Brüche stehen im Lehrplan in der 4. Schulstufe.
   „Bruchrechnen einfach“ nutzt Nenner 3–10 (Lehrplan: insbesondere 2, 4, 8).
3. **Lernspiel-Stufen eine Klasse zu hoch eingestuft** (`gradeFloor` in
   `game_level_catalog.dart`): Plus bis 100 (39) und Minus bis 100 (45) Kl. 3,
   Einmaleins Start/3er (41, 42) Kl. 3, Einmaleins 10er (46) Kl. 4 – laut Lehrplan
   jeweils 2. Schulstufe; Schriftliches Plus/Minus (48, 49) Kl. 4 statt 3. Betrifft
   Freischaltung, daher nicht geändert (Spiele-Team).
4. **Layout:** `LetterWritingScreen` läuft auf 412 dp um 5, 55 und 89 px über
   (`letter_writing_screen.dart:272, 351, 375`). Reproduktion: Matrixtest gibt
   „Layout-Überläufe“ aus (Lernwerkzeug „Alle Buchstaben A-Z“, Klasse 1). Gestaltung.
5. **Fremde Klasse in den Lernwerkzeugen:** Für eine andere als die eigene Klasse
   starten die Schreibthemen „Alle Buchstaben A-Z“ und „Erste Wörter“ ein
   Lautierungs- bzw. Wort-Bild-Quiz (`_openTopic` prüft die Klassenwahl vor den
   Schreibmodulen). Nicht geändert, weil der Klassenwechsel bewusst getrennt
   speichert.
6. **Sachunterricht-Fragenbanken:** Lösung oft die einzige längste Karte –
   Ökosysteme 70 %, Stromkreise 62 %, Verkehr 61 %, Ernährung 58 %, Familie und
   Gemeinschaft 52 % (Zufall 25–33 %). Jede Frage müsste einzeln überarbeitet werden.
7. **Deutsch-Schularbeit:** Die Karte verspricht „Lesen, Sprache, Rechtschreibung
   und Schreiben“, gezogen werden nur Deutsch-Einheiten (keine Lesen-,
   Rechtschreib- oder Schreibeinheiten). Text oder Auswahl angleichen
   (`section_content.dart`).
8. **Uhr ablesen (Mathe „Uhrzeit“):** Die Lösung ist selten die späteste Uhrzeit
   (38 von 900). Karten sind typische Lesefehler; im Lagetest begründet ausgenommen.
9. **Schwächen ohne Fach gespeichert** (`weakSkills` nur nach Einheitsname). Der
   Generator wählt jetzt fair; eine echte Lösung bräuchte ein neues Datenformat
   (Rückwärtskompatibilität, nicht geändert).
10. **Lernspiel „Minus bis 10“ (12):** Karten bis 20 möglich (z. B. „15“ bei 8 − 7).
11. **Logik „Regeln kombinieren“:** Mehrere Zahlen erfüllen die Regeln, nur eine
    steht auf den Karten; Wortlaut „Welche dieser Zahlen …“ wäre genauer.
12. **Nicht geprüft:** Hilfe-, Tipp- und Erklärtexte (Team A2), Eltern- und
    Lehrkräftebereich, Gestaltung, Godot-Spiele, IQ- und Denkprofil-Inhalte (nur
    Einstieg), Lumo-Werkstatt/Lernatelier-Inhalte (nur Einstieg), Ton, Gerät.

## 7. Prüfung neu ausführen

```bash
flutter test --no-pub test/qa/ test/content_audit/adventure_language_test.dart
LUMO_UPDATE_PRUEFMATRIX=1 flutter test --no-pub test/qa/lernmodul_pruefmatrix_test.dart  # nach gewollter Kachel-Änderung
```
