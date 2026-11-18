# Lumo Lernen – Prüfbericht Mathematik und Logik (Klasse 1–4)

Stand: 17.11.2026. Nur gelesen und ausgeführt, nichts im Repository geändert.
Alle Pfade beziehen sich auf `/home/user/lumo-lernen/`.

## 1. Ergebnis in Kürze

- **Keine falsch hinterlegte Lösung im Aufgabengenerator.** 49 800 Aufgaben wurden erzeugt (300 je Einheit und Klasse). 43 800 davon habe ich unabhängig nachgerechnet: 0 Abweichungen, die richtige Antwort fehlte nie, keine doppelten Antwortkarten. Die übrigen 6 000 stammen aus festen Listen (Formen, Zeit, Zahlwörter, „Was passt nicht?“, Nachzeichnen). Diese Listen habe ich vollständig gelesen.
- **Die schweren Fehler liegen rund um die Aufgabe:** Antwortkarten mit erkennbarem Muster, Bilder, die das Ergebnis zeigen, Tipps und „Rechentricks“ mit falschem Inhalt, zwei sachlich falsche Texte.
- **Zählung:** 12 schwer, 35 mittel, 18 leicht (65 Befunde).

Die fünf wichtigsten:

1. Bei allen Zahl-Aufgaben aus den Mathe-Vorlagen ist die richtige Antwort immer die zweitkleinste der vier Karten (S1).
2. Das Bild zur Division zeigt das Ergebnis („Gruppe 1 · 19“), die Bilder zu kg/g, l/ml und m/cm zeigen die Umrechnung (S2, S3).
3. Im Schularbeits- und Testmodus steht unter dem Zahlenstrahl das Ergebnis der Minusaufgabe, bei Zahlen über 20 sogar eine falsche Gleichung („62 - 24 = 20“) (S4).
4. Der „Rechentrick“ beim dritten Hilfe-Tipp liefert bei Bruch- und Kommaaufgaben falsche Rechnungen („Also: 9 + 3 = 49“) (S5).
5. Tipps werden nach Stichwörtern gewählt und sind dadurch falsch: Plus-Geschichten bekommen einen Minus-Tipp, eine Sachaufgabe einen Zehner-Einer-Tipp (S7, S8).

## 2. Was geprüft wurde und wie

| Quelle | Vorgehen |
|---|---|
| `lib/core/math_task_templates.dart` (64 Vorlagen), `lib/core/adventure/lumo_adventure_tasks.dart`, Logik in `lib/core/school_exercise_generator.dart` | Code vollständig gelesen. Über `ExerciseFactory.nextExact` 300 Aufgaben je Einheit und Klasse erzeugt (6 Startwerte), Lösungen in einem eigenen Skript nachgerechnet, Verteilungen ausgewertet, je Einheit 12–22 verschiedene Aufgaben wie eine Lehrkraft gelesen. |
| Tipps (`lib/core/task_hint_service.dart`) und Bilddaten (`lib/features/learning/adapters/legacy_lumo_task_adapter.dart`) | Für 6 972 Aufgaben ausgeführt, je Einheit alle drei Tippstufen und die Bilddaten gelesen. |
| Bilder (`lib/features/learning/renderers/*.dart`, `lib/features/schoolbook/widgets/schoolbook_task_widgets.dart`, `lib/features/learning/widgets/interactive_task_workspace.dart`) | Nur Code gelesen, nicht am Gerät angesehen. |
| Rechentricks (`lib/core/math/lumo_rechentricks.dart`) | Mit 26 Beispielaufgaben ausgeführt. |
| Denk-Test (`lib/core/cognitive_profile_generator.dart`) | Alle 200 Fragen (50 je Klasse) erzeugt und gelesen. |
| IQ-Rätsel (`lib/core/iq/iq_puzzle_generator.dart`) | 1 600 Zahlenreihen und 4 800 weitere Rätsel erzeugt (alle bestehen die eingebaute Prüfung, keine doppelten Optionen), 48 Zahlenreihen gelesen. Figurenrätsel nur im Code geprüft. |
| Lernmodule `lib/features/learning_modules/` (Plus/Minus bis 10, Zahlen bis 10/100, Formen, Uhr, Geld, Einmaleins, Bruchrechnen) | Nur die Erzeugungslogik und die Texte gelesen, nicht ausgeführt. |
| Spiel-Rechenpfad (`lib/domain/games/game_math_tasks.dart`), Ersatzaufgaben (`lib/core/safe_fallback_pool.dart`), Quiz-Show Mathe (`lib/domain/quiz/quiz_question_bank.dart`, 33 Fragen) | Gelesen. |
| Vorhandenes Hilfsskript `tools/audit_learning_tasks_all_grades.dart` | Gelesen und ausgeführt, Ausgabe in den Arbeitsordner statt ins Repository. Ergebnis: 236 Einheiten aller Fächer, 7 552 Aufgaben, 0 Auffälligkeiten. Das Skript prüft nur die Form (leere Felder, fehlende Antwort, doppelte Karten), keine Inhalte, und findet deshalb keinen der Befunde unten. |

Arbeitsdateien: `/tmp/claude-0/-home-user/cb75b070-f2a2-5032-9193-236fe13167d8/scratchpad/agents/audit/work/` (u. a. `samples_big.jsonl`, `adapted.jsonl`, `hints.txt`, `cog.txt`, `verify.py`, `check.py`).

## 3. Alle Einheiten je Klasse

Lesehilfe: „St.“ = erzeugte Aufgaben, alle nachgerechnet, außer „gelesen“. „versch.“ = verschiedene Aufgabentexte unter 300. Format: A4/A3/A2 = Auswahl aus 4/3/2 Karten. **Q** = vom Querschnittsfehler S1 (Antwort immer zweitkleinste Karte) betroffen. Urteil bezieht sich auf die Einheit einschließlich Bild und Tipp.

Ältere Einheiten erscheinen in höheren Klassen unverändert als Wiederholung. Sie wurden dort erneut mit je 300 Aufgaben erzeugt und nachgerechnet, ohne zusätzliche Befunde, und stehen hier nur bei ihrer Stammklasse.

### Klasse 1

| Einheit | Vorlage | Format | St. | versch. | Urteil | Befunde |
|---|---|---|---|---|---|---|
| Plus bis 10 | `g1_add_10` | A4, Punktebild | 300 | 33 | Mängel | Q, M2, M32 |
| Minus bis 10 | `g1_sub_10` | A4, Zahlenstrahl | 300 | 46 | schwerer Fehler | Q, S4, M2 |
| Plus bis 20 | `g1_add_20` | A4 | 300 | 87 | Mängel | Q |
| Minus bis 20 | `g1_sub_20` | A4 | 300 | 98 | schwerer Fehler | Q, S4 |
| Zahlenstrahl | `g1_number_line` | A4 | 300 | 18 | Mängel | Q, M14, L16 |
| Mengenvergleich | `g1_quantity_compare` | A3 | 300 | 64 | Mängel | M19, L17 |
| Zahl in Worten | `g1_number_word` | A4 | 300 gelesen | 21 | in Ordnung | L15 |
| Geometrie Formen | `g1_shapes` | A3 | 300 gelesen | 20 | Mängel | M13 |
| Formen Nachzeichnen | `g1_trace_*` | Nachzeichnen | 300 gelesen | 3 | in Ordnung | Zeichenfläche nicht geprüft |
| Geld | `g1_money_more` | A3/A2 | 300 | 64 | Mängel | M16 |
| Zeit | `g1_day_hours` | A3 | 300 gelesen | 8 | Mängel | M14, M19, L4 |
| Symmetrie | `g1_symmetry` | A2 | 300 | 4 | Mängel | M13, M14, M18 |
| Textaufgaben | `g1_word_problem` | A4 | 300 | 223 | Mängel | Q, M3, L1 |
| Rechengeschichten | Abenteuer `_story` | A4 | 300 | 300 | schwerer Fehler | S7, L1 |
| Zahlenmauer | `_wall` | A4 | 300 | 259 | Mängel | M21, M19 |
| Zahlenrätsel | `_numberRiddle` | A4 | 300 | 281 | in Ordnung | M19 (Tipp nichtssagend) |
| Marktstand | `_market` | A4 | 300 | 190 | Mängel | M2, L7 |
| Platzhalter-Rätsel | `_placeholder` | A4 | 300 | 166 | schwerer Fehler | S7 |
| Größer, kleiner, gleich | `_compare` | A3 | 300 | 251 | in Ordnung | L6 |
| Logik: Muster | `_logic` | A4 | 300 | 12 | Mängel | M23 |
| Logik: Reihenfolgen | `_logic` | A3 | 300 | 153 | Mängel | M24 |
| Logik: Was passt nicht? | `_oddOneOut` | A4 | 300, Wortlisten gelesen | 298 | in Ordnung | M26, L13 |

### Klasse 2

| Einheit | Vorlage | Format | St. | versch. | Urteil | Befunde |
|---|---|---|---|---|---|---|
| Plus bis 20 | `g2_add_20` | A4 | 300 | 135 | Mängel | Q, M2 |
| Minus bis 20 | `g2_sub_20` | A4 | 300 | 136 | schwerer Fehler | Q, S4, M2 |
| Plus bis 100 | `g2_add_100` | A4 | 300 | 269 | Mängel | Q, M1 |
| Minus bis 100 | `g2_sub_100` | A4 | 300 | 276 | schwerer Fehler | Q, S4 |
| Einmaleins | `g2_tables` | A4 | 300 | 80 | Mängel | Q, M1, M33 |
| Einmaleins Vorbereitung | `g2_times_prep` | A4 | 300 | 36 | Mängel | Q, M5 |
| Textaufgaben | `g2_sub_story`, `g2_word_problem` | A4 | 300 | 270 | Mängel | Q, M3 |
| Geld wechseln | `g2_money_change` | A3 | 300 | 29 | Mängel | M17 |
| Uhrzeit | `g2_clock` | A4, Uhr | 300 | 48 | Mängel | M4 |
| Längen | `g2_length` | A4, Lineal | 300 | 60 | schwerer Fehler | Q, S3, M12 |
| Gerade und ungerade | `g2_even_odd` | A3 | 300 | 97 | in Ordnung | L14 |
| Verdoppeln und Halbieren | `g2_half_double` | A4 | 300 | 50 | Mängel | Q |
| Zehner und Einer | `g2_tens_ones` | A4, Stangen | 300 | 150 | Mängel | Q, M1, L1 |
| Formen Nachzeichnen | `g2_trace_rectangle`, `g2_trace_star` | Nachzeichnen | 300 gelesen | 5 | schwerer Fehler | S9 |
| Uhr-Abenteuer | `_clock` | A4 | 300 | 24 | schwerer Fehler | S7, L6 |
| Rechengeschichten | `_story` | A4 | 300 | 299 | schwerer Fehler | S7 |
| Zahlenmauer | `_wall` | A4 | 300 | 299 | in Ordnung | M19 |
| Zahlenrätsel | `_numberRiddle` | A4 | 300 | 291 | schwerer Fehler | S7 |
| Marktstand | `_market` | A4 | 300 | 257 | in Ordnung | L7 |
| Platzhalter-Rätsel | `_placeholder` | A4 | 300 | 263 | schwerer Fehler | S7 |
| Größer, kleiner, gleich | `_compare` | A3 | 300 | 299 | in Ordnung | L6 |
| Logik: Zahlenmuster | `_logic` | A4 | 300 | 161 | Mängel | Q, M25 |
| Logik: Geheimcode | `_secretCode` | A4 | 300 | 20 | Mängel | M26, M19 |
| Logik: Muster (drei Formen) | `_logic` | A4 | 300 | 24 | Mängel | M23 |

### Klasse 3

| Einheit | Vorlage | Format | St. | versch. | Urteil | Befunde |
|---|---|---|---|---|---|---|
| Einmaleins | `g3_tables` | A4 | 300 | 80 | Mängel | Q, M33 |
| Schriftliche Addition | `g3_written_add` | A4, Stellenbild | 300 | 283 | Mängel | Q, M1, M2 |
| Schriftliche Subtraktion | `g3_written_sub` | A4 | 300 | 293 | Mängel | Q, M1, L5 |
| Brüche Vorbereitung | `g3_fraction_half` | A4, Pizza | 300 | 20 | Mängel | Q, M8 |
| Sachaufgaben zwei Schritte | `g3_two_step` | A4 | 300 | 290 | Mängel | Q, M3, M9 |
| Umfang | `g3_perimeter` | A4, Rechteck | 300 | 191 | Mängel | Q, M35 |
| Plus bis 100 | `g3_add_100` | A4 | 300 | 250 | Mängel | Q, M2 |
| Minus bis 100 | `g3_sub_100` | A4 | 300 | 273 | schwerer Fehler | Q, S4, M2 |
| Plus bis 1000 | `g3_add_1000` | A4 | 300 | 294 | Mängel | Q, M1, M34 |
| Minus bis 1000 | `g3_sub_1000` | A4 | 300 | 293 | schwerer Fehler | Q, S4, M2, M34 |
| Division einstellig | `g3_division_basic` | A4, Gruppenbild | 300 | 127 | schwerer Fehler | Q, S2 |
| Geld bis 100 Euro | `g3_money_change_100` | A3 | 300 | 68 | Mängel | M17 |
| Massen Kilogramm und Gramm | `g3_mass` | A4 | 300 | 36 | schwerer Fehler | Q, S3 |
| Rechengeschichten | `_story` | A4 | 300 | 297 | schwerer Fehler | S7, M22 |
| Zahlenmauer | `_wall` | A4 | 300 | 300 | in Ordnung | M19 |
| Zahlenrätsel | `_numberRiddle` | A4 | 300 | 291 | schwerer Fehler | S7 |
| Marktstand | `_market` | A4 | 300 | 270 | in Ordnung | L2 |
| Platzhalter-Rätsel | `_placeholder` | A4 | 300 | 266 | schwerer Fehler | S7 |
| Größer, kleiner, gleich | `_compare` | A3 | 300 | 300 | in Ordnung | L6 |
| Uhr-Abenteuer | `_clock` | A4 | 300 | 264 | Mängel | M19 |
| Logik: Schlussfolgern | `_logic` | A3 | 300 | 153 | Mängel | M24 |

### Klasse 4

| Einheit | Vorlage | Format | St. | versch. | Urteil | Befunde |
|---|---|---|---|---|---|---|
| Schriftliche Multiplikation | `g4_written_mul` | A4 | 300 | 289 | Mängel | Q, M1, M15, M19 |
| Schriftliche Division | `g4_written_div` | A4, Gruppenbild | 300 | 224 | schwerer Fehler | Q, S2, M2, M15 |
| Bruchrechnen einfach | `g4_fraction_add` | A3, Pizza | 300 | 113 | schwerer Fehler | S5 |
| Dezimalzahlen | `g4_decimal` | A3 | 300 | 291 | schwerer Fehler | S5 |
| Sachaufgaben drei Schritte | `g4_three_step` | A4 | 300 | 293 | schwerer Fehler | Q, S8, M3, M9 |
| Diagramme lesen | `g4_chart` | A4, Balken | 300 | 274 | Mängel | Q, M6 |
| Vergleichen | `g4_compare` | A3 | 300 | 294 | schwerer Fehler | S11, M7 |
| Plus bis 10000 | `g4_add_10000` | A4 | 300 | 295 | Mängel | Q, M1, M34 |
| Minus bis 10000 | `g4_sub_10000` | A4 | 300 | 295 | schwerer Fehler | Q, S4, M34 |
| Zahlenraum bis 1 Million | `g4_compare_1mio` | A3 | 300 | 294 | schwerer Fehler | S11, M7 |
| Zeit Minuten und Stunden | `g4_time_minutes` | A4 | 300 | 20 | Mängel | Q, M14, L4 |
| Hohlmaße Liter und Milliliter | `g4_volume` | A4 | 300 | 36 | schwerer Fehler | Q, S3 |
| Brüche erweitern | `g4_fraction_expand` | A3, Pizza | 300 | 59 | schwerer Fehler | S6, M11 |
| Mittelwert | `g4_average` | A4, Balken | 300 | 191 | schwerer Fehler | Q, S12, M10 |
| Flächeninhalt | `g4_area` | A4, Rechteck | 300 | 118 | Mängel | Q, M35 |
| Symmetrieachsen | `g4_symmetry_lines` | A4 | 300 | 4 | Mängel | Q, M14, M18 |
| Rechengeschichten | `_story` | A4 | 300 | 300 | schwerer Fehler | S7, M20, M22 |
| Zahlenmauer | `_wall` | A4 | 300 | 300 | in Ordnung | M19 |
| Zahlenrätsel | `_numberRiddle` | A4 | 300 | 294 | schwerer Fehler | S7 |
| Marktstand | `_market` | A4 | 300 | 287 | Mängel | M19, L2 |
| Platzhalter-Rätsel | `_placeholder` | A4 | 300 | 266 | schwerer Fehler | S7 |
| Größer, kleiner, gleich | `_compare` | A3 | 300 | 300 | in Ordnung | L6 |
| Uhr-Abenteuer | `_clock` | A4 | 300 | 274 | Mängel | M19 |
| Logik: Regeln kombinieren | `_logic` | A4 | 300 | 90 | Mängel | M25 |

### Weitere Mathe- und Logikinhalte

| Inhalt | Geprüft | Urteil | Befunde |
|---|---|---|---|
| Lernmodul Plus bis 10 | Code gelesen | Mängel | M32 |
| Lernmodul Minus bis 10 | Code gelesen | in Ordnung | – |
| Lernmodule Zahlen bis 10, Zahlen bis 100, Formen | Code gelesen | in Ordnung | – |
| Lernmodul Uhr | Code gelesen | in Ordnung | L11 |
| Lernmodul Geld | Code gelesen | Mängel | L8 |
| Lernmodul Einmaleins | Code gelesen | schwerer Fehler | S10, M33 |
| Lernmodul Bruchrechnen | Code gelesen | in Ordnung | L9 |
| Rechentricks (Hilfe Stufe 3, Poster) | 26 Aufgaben ausgeführt | schwerer Fehler | S5, L10 |
| Spiel-Rechenpfad und Rechenhaus | Code gelesen | Mängel | S1 (gleiche Ablenker), M33 |
| Ersatzaufgaben Mathe/Logik | 17 Aufgaben gelesen | in Ordnung | – |
| Quiz-Show Mathe | 33 Fragen gelesen, alle richtig | Mängel | M31 |
| Denk-Test | 200 Fragen gelesen | Mängel | M27–M30, L12 |
| IQ-Zahlenreihen | 1 600 erzeugt, 48 gelesen | in Ordnung | – |
| IQ-Figurenrätsel, Dreh- und Merkrätsel | 4 800 erzeugt, nur Code gelesen | keine Mängel im Code gefunden | Bilder nicht angesehen |

---

## 4. Befunde – schwer (falsch oder irreführend)

### S1 – Die richtige Antwort ist immer die zweitkleinste Karte
- **Ort:** `lib/core/math_task_templates.dart:716–725` (`_numericDistractors`), verwendet von `_numberTask` Z. 575–579. Gleiches Muster: `lib/core/school_exercise_generator.dart:527–532` (Zahlenmuster), `:545–550` (Regeln kombinieren, dort immer die drittkleinste), `lib/domain/games/game_math_tasks.dart:55–59`.
- **Beleg:** In 300 von 300 Aufgaben je Einheit liegt die Lösung an zweiter Stelle der Größe nach, in allen 33 Mathe-Einheiten mit Zahlantwort aus den Vorlagen und im Logik-Zahlenmuster. Einzige Ausnahme ist die Lösung 0 (dann kleinste Karte). Beispiele: `7 × 7 = ?` → Karten 48, **49**, 50, 51. `Schriftlich: 647 + 89 = ?` → 735, **736**, 737, 738. `Wie viele Gramm sind 8 kg und 100 g?` → 8099, **8100**, 8101, 8102.
- **Warum schwer:** Die Karten sind immer Lösung −1, Lösung, +1, +2. Wer das einmal bemerkt, löst jede Aufgabe ohne zu rechnen. Sterne, XP und der gemessene Lernstand stimmen dann nicht mehr.
- **Vorschlag:** Die Lage der Lösung unter den vier Zahlen zufällig wählen (0 bis 3 kleinere Ablenker) und die Ablenker aus typischen Fehlern bilden, siehe M1. Im Qualitätsprüfer einen Test ergänzen: Über 200 Aufgaben einer Einheit muss die Lösung an jeder Größenposition vorkommen.

### S2 – Das Bild zur Division zeigt das Ergebnis
- **Ort:** `lib/features/learning/renderers/lumo_premium_visuals.dart:1647` (`Text('Gruppe ${i + 1} · $perGroup')`, dazu die Bündel Z. 1650–1657). Angezeigt über `lib/features/learning/widgets/interactive_task_workspace.dart:1340`.
- **Beleg:** `57 : 3 = ?` (Klasse 3) → Karte „57 Objekte in 3 gleich große Gruppen“ mit „Gruppe 1 · 19“, „Gruppe 2 · 19“, „Gruppe 3 · 19“. Betroffen sind alle Aufgaben mit Dividend über 36 oder Divisor über 6, also der Großteil von „Division einstellig“ und die ganze „Schriftliche Division“ (`720 : 8 = ?` → „Gruppe 1 · 90“).
- **Warum schwer:** Die Lösung steht vor dem Antworten im Bild.
- **Vorschlag:** Vor der richtigen Antwort nur die leeren Gruppen und den Dividenden als Hunderter-, Zehner- und Einerbündel zeigen, die das Kind verteilt. `perGroup` erst nach der Lösung einblenden (wie bei `NumberCompareVisual`, das ein `evaluatedSymbol` bekommt).

### S3 – Die Bilder zu Massen, Hohlmaßen und Längen zeigen die Umrechnung
- **Ort:** `lumo_premium_visuals.dart:1407` (`'${value * 1000}'` im zweiten Chip) und `:1344` (`'${meters * 100} cm'`).
- **Beleg:** `Wie viele Gramm sind 6 kg?` → Bild „6 kg = 6000 g“ (Lösung 6000). `Wie viele Milliliter sind 8 Liter und 100 Milliliter?` → „8 Liter = 8000 ml“. `Wie viele Zentimeter sind 7 Meter?` → Lineal mit „0 cm … 700 cm“. Bei einem Viertel bis einem Sechstel der Aufgaben (ganze kg, l, m) ist das genau die Lösung, sonst der Hauptteil.
- **Vorschlag:** Im Bild nur die Grundbeziehung zeigen („1 kg = 1000 g“, „1 m = 100 cm“) und die gegebene Größe als Gewichte oder Messbecher, ohne umgerechneten Wert.

### S4 – Schularbeits- und Testmodus: Zahlenstrahl nennt das Ergebnis oder eine falsche Gleichung
- **Ort:** `lib/features/schoolbook/widgets/schoolbook_task_widgets.dart:152–176` (Textzeile `'$start - $takeAway = $result'`, `result` wird auf 0–20 begrenzt). Aufruf `lib/features/learning/renderers/adaptive_task_renderer.dart:1396–1405`. Dieser Weg ist aktiv, wenn `allowRetry` falsch ist (`adaptive_task_renderer.dart:341–342`), also bei Sitzungsart Schularbeit und Test (`lib/features/learning/learning_content.dart:275–277`).
- **Beleg (aus dem Code hergeleitet):** `9 - 4 = ?` → Text „9 - 4 = 5“. `15 - 8 = ?` → „15 - 5 - 3 = 7“. `62 - 24 = ?` → „62 - 24 = 20“ (falsch, richtig 38). `978 - 263 = ?` → „978 - 263 = 20“. Die Karte trägt außerdem das Band „0–20“.
- **Warum schwer:** Ausgerechnet in der Prüfungssituation steht bei Aufgaben bis 20 die Lösung da, bei größeren Zahlen eine falsche Rechnung.
- **Vorschlag:** Die Textzeile streichen oder erst nach der Antwort zeigen. Den Zahlenstrahl-Sprung nur für Minuend bis 20 verwenden, darüber kein Bild oder einen Rechenstrich ohne Ergebnis.

### S5 – „Rechentricks“ zeigen falsche Rechnungen bei Bruch- und Kommaaufgaben
- **Ort:** `lib/core/math/lumo_rechentricks.dart:417–419` (der Ausdruck `(\d+)\s*([+\-×*·])\s*(\d+)` greift mitten in Brüche und Kommazahlen), Z. 172 (alle Nichtziffern der Lösung werden entfernt). Aufruf beim dritten Tipp für jede Mathe-Aufgabe: `lib/features/learning/learning_content.dart:823–829`.
- **Beleg (ausgeführt):**
  - `1/9 + 3/9 = ?` (Lösung 4/9) → Mira: „9 + 1 = 10 | 10 + 2 = 49 | Also: 9 + 3 = 49“.
  - `2/7 + 4/7 = ?` → „7 + 3 = 10 | 10 + 1 = 67 | Also: 7 + 4 = 67“.
  - `8,4 + 6,7 = ?` (Lösung 15,1) → Emma: „Vertausche: 6 + 4 = 151 | So muss ich nur 4 Schritte weiterzaehlen. | Antwort: 151“.
  - `9,1 + 9,3 = ?` → „Vertausche: 9 + 1 = 184“.
- **Vorschlag:** Nur zulassen, wenn die ganze Aufgabe dem Muster `^(Schriftlich: )?\d+ [+\-−×·] \d+ = \?$` entspricht und die Lösung eine ganze Zahl ist. Zusätzlich prüfen, dass `a op b` wirklich die Lösung ergibt, sonst keinen Trick zeigen.

### S6 – „Brüche erweitern“: Die Pizza zeigt einen falschen Bruch
- **Ort:** `legacy_lumo_task_adapter.dart:676` ordnet `fraction_expand` dem Pizza-Bild zu, Daten werden aber nur für `fraction_pizza` erzeugt (Z. 891). `lumo_premium_visuals.dart:459` setzt dann den Zähler auf 1.
- **Beleg:** `Erweitere den Bruch 3/6 mit 2.` → Pizza mit 1 von 6 Stücken. `Erweitere den Bruch 5/6 mit 3.` → ebenfalls 1/6. Richtig ist das Bild nur, wenn der Zähler zufällig 1 ist. In allen 42 geprüften Aufgaben waren die Bilddaten leer.
- **Vorschlag:** Im Adapter für `fraction_expand` Zähler und Nenner aus dem Text übergeben. Besser: zwei Pizzen nebeneinander (3/6 und die feiner geteilte, noch unbeschriftete Pizza).

### S7 – Minus-Tipp bei Plus-, Mal- und Platzhalteraufgaben (Auslöser ist ein Bindestrich)
- **Ort:** `lib/core/task_hint_service.dart:99–104`. Jeder Bindestrich im Text gilt als Minuszeichen, jedes „+“ als normale Plusaufgabe.
- **Beleg (Tippstufe 1, ausgeführt):**
  - `Bei Lumos Kart-Rennen fährt Ola 1 Runden und Pip 1 Runden. Wie viele Runden fahren beide zusammen?` → „Beginne bei der ersten Zahl und nimm die zweite Menge weg.“
  - `Lumos Kart-Turnier beginnt um 7 Uhr und dauert 1 Stunde. Um wie viel Uhr ist es aus?` → derselbe Minus-Tipp.
  - `Ola denkt sich eine Zahl und nimmt sie 4-mal. Das ergibt 12.` → Minus-Tipp (gefragt ist Teilen).
  - `★ − 8 = 7` → „Beginne bei der ersten Zahl und nimm die zweite Menge weg“ (richtig wäre 7 + 8).
  - `7 + ★ = 13` → „Beginne mit der ersten Menge und lege die zweite dazu“ (richtig wäre Ergänzen).
- **Vorschlag:** Tipps nicht aus Zeichen im Text ableiten, sondern aus der Einheit. Für die Abenteuer-Einheiten eigene Texte, z. B. Platzhalter Plus: „Zähle von 7 weiter bis 13. Wie viele Schritte sind es?“ Platzhalter Minus: „Rechne zurück: Lege zu 7 wieder 8 dazu.“ Zahlenrätsel: „Rechne rückwärts mit der Umkehraufgabe.“ Uhr: „Zähle die Stunden von der Startzeit weiter.“ Die Zeichenregel nur noch für reine Rechenausdrücke nutzen.

### S8 – Zehner-Einer-Tipp bei einer Sachaufgabe (Auslöser ist das Wort „einer“)
- **Ort:** `task_hint_service.dart:293–298` (`prompt.contains('einer')`).
- **Beleg:** `In einer Kiste liegen 32 Äpfel und 6 Birnen. Eine zweite Kiste enthält genau gleich viele Früchte. 4 Früchte werden gegessen. Wie viele bleiben insgesamt?` → Tipp 1: „Baue die Zahl mit Zehnerbündeln. Was nach den vollen Bündeln übrig bleibt, sind die Einer.“ Tipp 3: „Sieh 32 als 3 Zehnerstangen und 2 einzelne Würfel … Probiere danach 33.“
- **Vorschlag:** Die Stellenwerthilfe nur bei der Einheit „Zehner und Einer“ oder beim exakten Muster `Wie viele (Zehner|Einer) hat \d{2}\?` auslösen.

### S9 – Falsche Aussage über das Rechteck
- **Ort:** `lib/core/math_task_templates.dart:556`.
- **Beleg:** Aufgabe „Zeichne ein Rechteck nach“, Erklärung: „Ein Rechteck hat 4 Ecken und 2 verschieden lange Seiten.“
- **Warum schwer:** Ein Rechteck hat 4 Seiten. Der Satz ist sachlich falsch.
- **Vorschlag:** „Ein Rechteck hat 4 Ecken und 4 Seiten. Gegenüberliegende Seiten sind gleich lang.“

### S10 – „Großes 1×1“ für die Reihen 1 bis 10
- **Ort:** `lib/features/learning_modules/einmaleins/einmaleins_screen.dart:76` und `:278` (Reihen laut Z. 67–68: 1 bis 10).
- **Warum schwer:** Die Reihen 1 bis 10 sind das kleine Einmaleins. „Großes Einmaleins“ bezeichnet die Reihen 11 bis 20. Das Kind lernt einen falschen Fachbegriff.
- **Vorschlag:** „Kleines 1×1 – alle Reihen“. Das Modul für Klasse 2 heißt bereits „Einmaleins 2/5/10“, die Einheit dort entsprechend „Kleines 1×1 – Reihen 2, 5, 10“.

### S11 – Irreführende Erklärung beim Zahlenvergleich
- **Ort:** `math_task_templates.dart:492`.
- **Beleg:** `Welches Zeichen passt? 9 ? 45` → Erklärung „Vergleiche von links nach rechts.“ Wer das befolgt, vergleicht 9 mit 4 und wählt „>“. In „Vergleichen“ hatten 59 von 300 Aufgaben verschieden viele Stellen, bei „Zahlenraum bis 1 Million“ kommen fünf- gegen sechsstellige Zahlen vor (`27441 ? 173684`).
- **Vorschlag:** „Zähle zuerst die Stellen: Die Zahl mit mehr Stellen ist größer. Bei gleich vielen Stellen vergleichst du von links, Stelle für Stelle.“

### S12 – „Mittelwert“: Das Diagramm passt nicht zur Aufgabe
- **Ort:** `lumo_premium_visuals.dart:1780–1794` (zeigt nur die ersten zwei Zahlen, beschriftet „Mo“ und „Di“), Zuordnung der Vorlage über `'chart'` in `math_task_templates.dart:543`.
- **Beleg:** `Drei Kinder sammeln Sterne: 42, 49 und 53.` → zwei Balken „Mo 42“ und „Di 49“, der dritte Wert fehlt, Wochentage statt Kinder.
- **Vorschlag:** Für den Mittelwert drei Balken mit „Kind 1/2/3“ zeichnen oder das Bild weglassen.

---

## 5. Befunde – mittel (mehrdeutig, ungeeignet, zu leicht erratbar)

### M1 – Ablenker sind Nachbarzahlen statt typischer Fehler
- **Ort:** `math_task_templates.dart:716–725`.
- **Beleg:** `Schriftlich: 435 × 8 = ?` → 3479, 3480, 3481, 3482. Es reicht, 5 · 8 = 40 zu rechnen und die Karte mit der Endziffer 0 zu nehmen. Das gilt für alle schriftlichen Verfahren und für Plus/Minus bis 10 000. `Wie viele Zehner hat 56?` → 4, 5, 6, 7: Die typische Verwechslung (Einerziffer) ist nur zufällig dabei, bei `Wie viele Einer hat 27?` (6, 7, 8, 9) fehlt sie.
- **Vorschlag je Aufgabenart:** Plus/Minus: Übertrag vergessen (±10, ±100), Operation verwechselt. Einmaleins: Nachbarn in der Reihe (a·(b±1), (a±1)·b), so macht es das Einmaleins-Modul schon. Zehner/Einer: die andere Ziffer und die ganze Zahl. Umrechnen: falscher Faktor (85, 8050, 805 statt 850). Umfang: a+b und a·b. Fläche: Umfang und a+b. Schriftliche Verfahren besser mit Zifferneingabe statt Auswahl.

### M2 – Ergebnis häuft sich an der Zahlenraumgrenze, bei 0 und bei 99
- **Ort:** `math_task_templates.dart:251` (Summand wird auf Grenze − a gekürzt), `:257` (Subtrahend auf den Minuenden), `:426`, `:460`.
- **Beleg (je 300 Aufgaben):** Schriftliche Addition Klasse 3: Lösung 1000 in 120 Fällen (40 %), z. B. `798 + 202`, `751 + 249`. Plus bis 100 Klasse 3: Lösung 100 in 101 Fällen (34 %). Plus bis 20 Klasse 2: Lösung 20 in 67 Fällen (22 %). Minus bis 100 Klasse 3: Lösung 0 in 54 Fällen (18 %), z. B. `39 - 39`. Minus bis 10: Lösung 0 in 47 Fällen (16 %). Schriftliche Division: Lösung 99 in 54 Fällen (18 %), z. B. `693 : 7`, `396 : 4`, `594 : 6`. Marktstand Klasse 1: „10 €“ in 102 Fällen (34 %).
- **Vorschlag:** Nicht kürzen, sondern passend ziehen: erst das Ergebnis im erlaubten Bereich wählen, dann zerlegen. Bei Minus `b` aus 1 bis a−1. Bei Division Quotient und Divisor wählen und multiplizieren.

### M3 – Sachaufgaben ohne Umlaute
- **Ort:** `math_task_templates.dart:821–830`, `:848–856`, `:873–880`.
- **Beleg:** „Lisa hat 4 Aepfel“, „In Omas Garten bluehen 2 Tulpen“, „4 Hupfkaestchen“, „Wuerstel“, „Gemueseteile“, „Stueck“, „uebrig“, „Fuer das Schultheater“, „Maedchen“, „Zaehle erst …“. Betroffen: jede Erklärung der Klasse-1-Textaufgaben, 67 % der Zwei-Schritt- und 63 % der Drei-Schritt-Aufgaben.
- **Warum:** Leseanfänger lernen falsche Wortbilder.
- **Vorschlag:** Alle Texte mit ä, ö, ü, ß schreiben (die neueren Geschichten in derselben Datei, Z. 804–819, zeigen, dass es geht). „Hupfkaestchen“ → „Am Schulhof spielen 4 Kinder Fangen und 4 Kinder Tempelhüpfen. Wie viele Kinder spielen zusammen?“ „Gemueseteile“ → „Wie viele Stück Gemüse“.

### M4 – „Uhrzeit“ (Klasse 2): Die Frage nennt die Lösung
- **Ort:** `math_task_templates.dart:388–394`.
- **Beleg:** `Welche Uhrzeit ist gemeint: Stunde 7 und Minute 30?` → 7:30 Uhr. Daneben zeigt die Uhr 7:30. Das Kind muss nur Zahlen abschreiben, die Uhr nicht lesen. Der Satz ist außerdem kein Kinderdeutsch.
- **Vorschlag:** Frage „Wie spät ist es?“, nur die Uhr zeigen. Karten in der Form „7:30 Uhr“ und in Worten („halb 8“). Das Uhr-Modul macht es bereits richtig.

### M5 – „Wie oft 5 ist 50?“
- **Ort:** `math_task_templates.dart:361`.
- **Warum:** Kein verständlicher Satz.
- **Vorschlag:** „Wie oft passt 5 in 50?“ oder „Wie viele Fünfer ergeben 50?“

### M6 – „Diagramme lesen“ ist eine Plusaufgabe
- **Ort:** `math_task_templates.dart:486–489`.
- **Beleg:** `Diagramm: Montag 12 Kinder, Dienstag 11 Kinder. Wie viele zusammen?` Die Werte stehen im Text und nochmals als Zahl über den Balken. Gerechnet wird bis höchstens 80, das ist Stoff der 2. Klasse in einer Einheit der 4. Klasse.
- **Vorschlag:** Werte nur aus dem Bild ablesen lassen (Balken an einer Skala mit Zweier-, Fünfer- oder Zehnerschritten, 3 bis 5 Balken). Fragen: „An welchem Tag waren die meisten Kinder da?“, „Wie viele mehr am Dienstag als am Montag?“, „Wie viele insgesamt?“

### M7 – „Vergleichen“ und „Zahlenraum bis 1 Million“ sind zu leicht und schwer lesbar
- **Ort:** `math_task_templates.dart:109`, `:116`, `:490–493`.
- **Beleg:** Zwei Zufallszahlen. Bei der Million haben nur 29 von 300 Paaren gleich viele Stellen und dieselbe erste Ziffer, sonst entscheidet der erste Blick. „=“ war in 600 Aufgaben nie richtig, es bleiben zwei Karten. Das Fragezeichen als Lücke steht neben dem Fragezeichen der Frage (`passt? 9 ? 45`). `925407 ? 945369` hat keine Gliederung.
- **Vorschlag:** Paare gezielt bauen (gleiche Stellenzahl, gleiche führende Ziffern, Zahlendreher wie 54 321 / 54 231). Lücke als ⬜ wie im Abenteuer. Zahlen ab 10 000 mit schmalem Abstand schreiben (925 407). Für die Million weitere Formate: Stellenwert einer Ziffer, Nachbartausender, Runden, Zahlwort zuordnen.

### M8 – „Brüche Vorbereitung“ (Klasse 3) ist nur Halbieren
- **Ort:** `math_task_templates.dart:72`, `:435–439`.
- **Beleg:** 300 Aufgaben, 20 verschiedene, alle „Was ist die Hälfte von X?“ mit X bis 40. Die Klasse-2-Einheit „Verdoppeln und Halbieren“ geht bis 50.
- **Vorschlag:** Halbe, Viertel und Achtel am Bild (Kreis, Rechteck, Strecke): „Welcher Teil ist gefärbt?“, „Färbe ein Viertel“, „Ein Viertel von 12 Kirschen“.

### M9 – Sachaufgaben mit zwei und drei Schritten: immer dieselbe Rechnung
- **Ort:** `math_task_templates.dart:441` (immer a + b − 3), `:481` (immer (a + b) · 2 − 4).
- **Beleg:** In jeder Zwei-Schritt-Aufgabe werden genau 3 weggenommen, in jeder Drei-Schritt-Aufgabe genau 4. Die Zahlen liegen bei 5–30 und 2–12 (Klasse 3) und ergeben höchstens 156 (Klasse 4). Kontext fragwürdig: „Im Schwimmbad sind 15 Kinder … 3 gehen in die Sauna.“
- **Vorschlag:** Den dritten Wert zufällig wählen, Strukturen mischen (plus/plus, minus/minus, mal/plus, geteilt/minus, Vergleich „wie viele mehr“), Zahlen an die Klasse anpassen, gelegentlich eine überflüssige Angabe einbauen. „Sauna“ → „3 Kinder gehen zur Rutsche.“

### M10 – „Mittelwert“: Lösung ablesbar, Frage holprig, Stoff nicht Volksschule
- **Ort:** `math_task_templates.dart:530–544`.
- **Beleg:** In 300 von 300 Aufgaben ist die Lösung die zweite Zahl minus 1 (`42, 49 und 53` → 48). Frage: „Wie viele Sterne im Mittelwert?“ Der Mittelwert ist üblicherweise Stoff nach der Volksschule.
- **Vorschlag:** Werte frei wählen (Summe durch 3 teilbar) und mischen. Frage: „Wie viele Sterne hat jedes Kind, wenn sie gerecht teilen?“ Als Knobelaufgabe kennzeichnen.

### M11 – „Brüche erweitern“ geht über den Volksschulstoff hinaus
- **Ort:** `math_task_templates.dart:122`, `:516–529`.
- **Warum:** Formales Erweitern mit Zähler und Nenner wird üblicherweise erst nach der 4. Klasse verlangt. In der Volksschule geht es um Bruchteile am Bild und von Größen.
- **Vorschlag:** Als freiwillige Knobel-Einheit kennzeichnen oder ersetzen durch „Gleich viel Pizza? 1/2 und 2/4“ am Bild.

### M12 – „Längen“ (Klasse 2) rechnet im Zahlenraum bis 1050
- **Ort:** `math_task_templates.dart:57`, `:395–400`.
- **Beleg:** 293 von 300 Lösungen liegen über 100 (`8 Meter und 50 Zentimeter` → 850).
- **Vorschlag:** Klasse 2: 1 m = 100 cm, halber Meter, Längen bis 100 cm messen, vergleichen, schätzen. Umrechnungen mit mehreren Metern in Klasse 3.

### M13 – Formen und Symmetrie in Klasse 1: Sprache zu schwer
- **Ort:** `lib/core/shape_question_data.dart:23`, `:47`, `:65`, `:71`, `:95`; `math_task_templates.dart:351–355`.
- **Beleg:** „Du verbindest drei Punkte, die nicht auf einer Geraden liegen, zu einer geschlossenen Form mit drei geraden Seiten. Welche Form entsteht?“ „Welche Form passt zu einem Zifferblatt, dessen Rand überall gleich weit vom Mittelpunkt entfernt ist?“ „Hat ein gleichseitiges Dreieck eine Spiegelachse?“ Begriffe wie „rechte Winkel“, „gleichseitig“, „Mittelpunkt“ und Sätze mit über 20 Wörtern sind für Sechsjährige nicht lesbar.
- **Vorschlag:** Klasse 1: kurze Fragen am Bild („Welche Form hat 3 Ecken?“, „Welche Form ist rund?“, „Welches Ding sieht aus wie ein Kreis?“). Die langen Fragen in Klasse 3/4 verschieben. Symmetrie in Klasse 1 nur mit gezeichneten Figuren („Passen beide Hälften aufeinander?“).

### M14 – Sehr kleine feste Aufgabenlisten
- **Beleg (verschiedene Aufgaben unter 300):** Symmetrie 4 (224-mal „ja“, 76-mal „nein“), Symmetrieachsen 4, Zeit 8, Zahlenstrahl 18, Zeit Minuten und Stunden 20, Formen Nachzeichnen 3 bzw. 5.
- **Ort:** `math_task_templates.dart:286–338`, `:339–358`, `:22`, `:118`.
- **Vorschlag:** Je Einheit mindestens 30 verschiedene Aufgaben. Symmetrie mit Buchstaben, Bildern und Figuren (ja/nein ausgewogen). Zahlenstrahl mit wechselnder Lücke und Schritten 1, 2, 5, 10. Zeit um Wochentage, Monate, volle Stunden erweitern.

### M15 – Schriftliche Multiplikation und Division: Faktor 10/11/12, nie ein Rest, falscher Rechenweg
- **Ort:** `math_task_templates.dart:97`, `:99`, `:454–463`.
- **Beleg:** 82 von 300 Malaufgaben haben den Faktor 10, 11 oder 12 (`Schriftlich: 691 × 10 = ?`, `818 × 11`). Erklärung dazu: „Multipliziere jede Stelle von 818 mit 11“ beschreibt nicht das Verfahren mit zweistelligem Faktor. 94 von 300 Divisionen haben den Divisor 10–12. Es gibt nie einen Rest. Die Einheit heißt „Schriftliche Division“, die Aufgabe trägt aber kein „Schriftlich:“ und kein Stellenbild.
- **Vorschlag:** Stufen bilden: einstelliger Faktor, dann Zehnerzahl, dann zweistelliger Faktor mit Teilprodukten. Division: ohne Rest, dann mit Rest („Rest 3“ als Antwortteil), dann zweistelliger Divisor. Erklärung als Schrittfolge mit Teilergebnissen.

### M16 – „Geld“ (Klasse 1) ist ein Zahlenvergleich ohne Geld
- **Ort:** `math_task_templates.dart:280–285`; Bilddaten `legacy_lumo_task_adapter.dart:913–927`.
- **Beleg:** `Was kostet mehr: 6 € oder 6 €?` → „gleich viel“ bei nur zwei Karten (31 von 300 Aufgaben haben gleiche Preise). Das Bild legt nur den ersten Betrag in Münzen und Scheinen, den zweiten nicht.
- **Vorschlag:** Zwei Dinge mit Preisschild zeigen („Der Ball kostet 6 €, das Buch 8 €. Was kostet mehr?“), gleiche Preise vermeiden, beide Beträge darstellen. Zusätzlich Münzen erkennen und Beträge bis 10 € legen.

### M17 – „Geld wechseln“ und „Geld bis 100 Euro“: Bild zeigt eine andere Stückelung
- **Ort:** `legacy_lumo_task_adapter.dart:913–927`, `lumo_premium_visuals.dart:292–385`.
- **Beleg:** `Wie viele 1-€-Münzen ergeben 7 €?` → Bild: ein 5-€-Schein und eine 2-€-Münze. `Wie viele 2-€-Münzen ergeben 20 €?` → ein 20-€-Schein. Gefragt ist das Gegenteil des Gezeigten.
- **Vorschlag:** Den Betrag in der gefragten Stückelung aufbauen lassen (Münzen antippen, bis der Betrag erreicht ist), oder nur den Zielbetrag als Preisschild zeigen.

### M18 – Symmetrie-Aufgaben zeigen eine leere „Formenhilfe“
- **Ort:** `legacy_lumo_task_adapter.dart:677`, `adaptive_task_renderer.dart:1477–1520`.
- **Beleg (aus dem Code):** Die Karte „Formenhilfe – Schau genau: Welche Form passt?“ zeichnet nur Formen, die als Antwortkarte vorkommen. Bei „ja/nein“ und bei Zahlen bleibt sie leer. Die Figur, um die es geht, wird nie gezeichnet.
- **Vorschlag:** Die genannte Figur groß zeichnen, mit einer verschiebbaren Faltlinie.

### M19 – Unpassende oder unsinnige Tipps
- **Ort und Beleg:**
  - `task_hint_service.dart:47–49`: Einheit „Zeit“ (Klasse 1), Frage `Welche Tageszeit folgt auf den Nachmittag?` → „Eine Stunde besteht aus 60 Minuten. Wandle zuerst die ganzen Stunden um …“.
  - `:369–371`: `Schriftlich: 390 × 9 = ?` → Tipp 2 „Lege 390 gleich große Gruppen mit je 9 Dingen.“ Tipp 3 „Zähle in Schritten von 9. Mache genau 390 Schritte.“
  - `:20–24`, `:385–387`: „Was passt nicht?“ und „Geheimcode“ → „Lege für jede Figur eine Karte … Bei geraden Zahlen bleibt beim Bilden von Paaren nichts übrig.“
  - `:77–79`: Mengenvergleich mit Äpfeln (Klasse 1) → „Bei Zahlen beginnst du mit der größten Stelle. Die offene Seite des Vergleichszeichens …“.
  - `:105`: Rechengeschichten (Sammeln), Zahlenmauer, Zahlenrätsel, Marktstand, Diagramme, Million → nur „Lies, was genau gesucht wird. Prüfe Zahlen, Form oder Reihenfolge …“.
  - `:47–49`: Uhr-Abenteuer Klasse 3/4 (Ankunftszeit) → „Wandle zuerst die ganzen Stunden um“ (gefragt ist Weiterzählen über die volle Stunde).
- **Vorschlag:** Pro Einheit drei geschriebene Tippstufen (Einstieg, Teilschritt, fast gelöst) statt Stichwortsuche. Beispiele: Was passt nicht? → „Finde das Gemeinsame von drei Dingen. Was gehört nicht in diese Gruppe?“ Geheimcode → „Zähle im Alphabet: A ist 1, B ist 2 … Beginne mit der ersten Zahl.“ Zahlenmauer → „Rechne zuerst die zwei Steine in der Mitte: links plus Mitte, Mitte plus rechts.“ Schriftliche Multiplikation → „Beginne bei den Einern. Schreibe die Einer an und merke dir die Zehner.“

### M20 – Abenteuer Klasse 4: „Davon“ ist mehrdeutig, Fall falsch
- **Ort:** `lumo_adventure_tasks.dart:262–263`.
- **Beleg:** `Mila kauft 11 Packungen mit je 31 Kirschen und bekommt noch 20 geschenkt. Davon verschenkt Mila 202.` „Davon“ bezieht sich sprachlich auf die 20 geschenkten. Weiter: „mit je 45 Kristalle“, „mit je 47 Pilze“, „mit je 30 Buntstifte“.
- **Vorschlag:** „… und bekommt noch 20 dazu. Von allen Kirschen verschenkt Mila 202.“ Für den Satzbau eine dritte Wortform (Dativ Mehrzahl: Kristallen, Pilzen, Buntstiften) in `adventureObjects` ergänzen oder umstellen: „Packungen. In jeder sind 45 Kristalle.“

### M21 – Zahlenmauer nur als Text, in Klasse 1 mit dem Wort „Summe“
- **Ort:** `lumo_adventure_tasks.dart:291–305`, Bild `auto` (kein Bild).
- **Beleg:** `Fips baut eine Zahlenmauer aus drei Reihen. Jeder Stein ist die Summe der zwei Steine darunter. Unten liegen 5, 5 und 5. Welche Zahl steht ganz oben?` Drei Sätze, kein Bild, Fachwort „Summe“.
- **Vorschlag:** Die Mauer zeichnen (Steine mit Zahlen, gesuchter Stein mit „?“). Text für Klasse 1: „Zwei Steine zusammen ergeben den Stein darüber. Welche Zahl fehlt?“ Ab Klasse 2 auch einen unteren Stein suchen lassen.

### M22 – Abenteuer: Zahlenraum Klasse 4 endet bei 10 000, Geschichten unglaubwürdig
- **Ort:** `lumo_adventure_tasks.dart:131–136`, `:198–232`.
- **Beleg:** „Hoppel hat 902 Erdbeeren“, „Bei Lumos Kart-Rennen fährt Hoppel 471 Runden und Mila 458 Runden“, „Mila sammelt 9 Erdbeeren. Dann findet Mila noch 584“. Klasse 4 rechnet sonst bis zur Million.
- **Vorschlag:** Dinge und Zahlen nach Größe koppeln (Schritte, Meter, Zuschauer, Einwohner, Euro, Punkte im Spiel). Für Klasse 4 Geschichten mit 10 000 bis 1 000 000.

### M23 – Logik „Muster“: Lösung immer das erste Bild, nur zwei Musterarten
- **Ort:** `school_exercise_generator.dart:497–513`.
- **Beleg:** Klasse 1 immer A‑B‑A‑B‑?, ab Klasse 2 immer A‑B‑C‑A‑B‑C‑?. Lösung ist stets das erste Element. 12 bzw. 24 verschiedene Aufgaben. Klasse 2, 3 und 4 sind gleich. Die Regel steht im Text („wiederholt sich immer gleich“).
- **Vorschlag:** Lücke an wechselnder Stelle, Muster AAB, ABB, ABBA, wachsende Muster, zwei Merkmale (Form und Farbe). Schwierigkeit je Klasse steigern.

### M24 – Logik „Reihenfolgen“ und „Schlussfolgern“: kein Schluss nötig
- **Ort:** `school_exercise_generator.dart:552–570`.
- **Beleg:** `Drei Figuren stehen nebeneinander. Ben steht links von Ali. Ali steht links von Mia. Wer steht ganz links?` Die Namen werden immer in der richtigen Reihenfolge genannt. Die Lösung ist der erste, zweite oder dritte genannte Name. „Reihenfolgen“ ist in allen vier Klassen gleich, „Schlussfolgern“ in Klasse 3 und 4.
- **Vorschlag:** Angaben mischen und umkehren („Mia steht rechts von Ali. Ben steht links von Ali.“), ab Klasse 4 vier Personen und Verneinungen („Lea steht nicht am Rand“). Statt „Figuren“ „Kinder“.

### M25 – Logik „Zahlenmuster“ und „Regeln kombinieren“
- **Ort:** `school_exercise_generator.dart:514–551`.
- **Beleg:** Zahlenmuster nur aufsteigend mit festem Schritt, die Regel steht in der Frage („Gehe jedes Mal gleich viele Schritte weiter“). 72 von 300 Aufgaben der Klasse 2 haben Schritt 1 (`34 – 35 – 36 – 37 – ?`). „Regeln kombinieren“ hat nur eine Schablone (`größer als X, kleiner als X+8 und gerade`), Lösung immer genau die Mitte, immer die drittkleinste Karte, 90 Varianten.
- **Vorschlag:** Absteigende Folgen, Verdoppeln, wechselnde Schritte (+2, +3, +2 …), Lücke in der Mitte, Schritt 1 ausschließen. Bei den Regeln weitere Bausteine (ungerade, Einmaleinszahl, Quersumme, Zehnerziffer) und mehrere passende Zahlen im Intervall, von denen nur eine als Karte erscheint, an wechselnder Position.

### M26 – „Was passt nicht?“ und „Geheimcode“ ohne Steigerung
- **Ort:** `lumo_adventure_tasks.dart:827–862`, Daten `lib/core/adventure/adventure_word_data.dart:261–290`.
- **Beleg:** Dieselben 10 Gruppen und dieselbe Aufgabenart in Klasse 1 bis 4 (`Banane, Zug, Bus, Auto` auch in Klasse 4). Geheimcode: 20 Wörter, 300 Aufgaben ergeben 20 verschiedene. Meist genügt der erste Buchstabe.
- **Vorschlag:** Ab Klasse 3 engere Gruppen (Säugetier/Vogel, gerade/ungerade Zahlen, Körper/Flächen), ab Klasse 4 zwei mögliche Merkmale mit Begründung. Geheimcode: mehr Wörter, Ablenker mit gleichem Anfangsbuchstaben, später verschobenes Alphabet.

### M27 – Denk-Test: „um 90° nach rechts gedreht“
- **Ort:** `cognitive_profile_generator.dart:456–457`.
- **Beleg:** Klasse 2: `Der Pfeil ↓ wird um 90° nach rechts gedreht. Wohin zeigt er danach?` → als richtig gilt ←. Klasse 1: `Der Pfeil ← wird um 90° nach rechts gedreht` → ↑. Ein Kind liest „nach rechts“ als „zeigt dann nach rechts“. Gradangaben (90°, 180°, 270°) kommen schon in Klasse 1 vor.
- **Vorschlag:** „Der Pfeil macht eine Vierteldrehung im Uhrzeigersinn (so wie sich die Zeiger der Uhr drehen).“ Dazu ein kleines Drehsymbol. Grad erst ab Klasse 4.

### M28 – Denk-Test: gleiche Fragen mehrfach im selben Test, immer derselbe Fragensatz
- **Ort:** `cognitive_profile_generator.dart:265–314`, `:441–465`.
- **Beleg:** Klasse 1 und 2 haben unter 10 Raumfragen nur 4 verschiedene (`Der Pfeil → wird um 90° nach rechts gedreht` dreimal). Das Muster `■ ◆ ■ ◆ ■ ?` kommt in Klasse 1 zweimal vor, in jeder Klasse gibt es doppelte Formmuster. Der Test ist bei jeder Wiederholung identisch.
- **Vorschlag:** Aufgaben je Durchgang aus einem größeren Vorrat ziehen und Dubletten im Test ausschließen.

### M29 – Denk-Test, Sprachaufgaben: zwei vertretbare Antworten, schwache Paare, Fachwörter
- **Ort:** `cognitive_profile_generator.dart:58–61`, `:68`, `:91–137`, Ablenker `:417–419`.
- **Beleg:**
  - Klasse 2: `Auf eine Frage folgt eine Antwort. Zu einem Problem suchen wir eine …` → Lösung. Karte „Antwort“ ist ebenfalls sinnvoll.
  - Klasse 4: `Eine These braucht Begründung. Eine Frage braucht oft eine …` → Untersuchung. „Begründung“ steht als Karte daneben, die naheliegende „Antwort“ fehlt.
  - Klasse 3: `Pflanzen können blühen. Menschen können …` → sprechen. Kein erkennbarer Zusammenhang, lösbar nur durch Ausschluss.
  - Wörter wie These, Hypothese, Konsum, Synonyme, Argument, Beleg in Klasse 3/4.
  - Zwei der drei Ablenker stammen aus den Nachbarfragen und passen nie (`Tag ist meist hell. Nacht ist meist …` → Gemüse, dunkel, hell, Kätzchen).
- **Vorschlag:** Die drei genannten Aufgaben ersetzen, z. B. „Fisch – schwimmen, Vogel – …“ (fliegen), „Auge – sehen, Nase – …“ (riechen). Ablenker aus derselben Wortart und demselben Sachfeld schreiben. Alltagswörter verwenden.

### M30 – Denk-Test, Merkaufgaben: Länge nicht altersgemäß und über die letzte Ziffer lösbar
- **Ort:** `cognitive_profile_generator.dart:467–529`.
- **Beleg:** Klasse 1 zeigt 4 bis 6 Ziffern für 3,85 s, Klasse 4 bis zu 9 Ziffern für 4,9 s, jede zweite Aufgabe rückwärts. Bei „rückwärts“ beginnt nur die richtige Karte mit der letzten gezeigten Ziffer (`8 4 9 5` → `5 – 9 – 4 – 8` gegen `8 – 4 – …`, `8 – 5 – …`, `4 – 9 – …`).
- **Vorschlag:** Längen 2–4 (Klasse 1) bis 4–6 (Klasse 4), rückwärts jeweils eine Ziffer kürzer. Ablenker mit gleicher erster und letzter Ziffer und vertauschter Mitte. „Position 3“ → „an dritter Stelle“.

### M31 – Quiz-Show Mathe: richtige Antwort fast immer an Platz 2
- **Ort:** `lib/domain/quiz/quiz_question_bank.dart:336 ff.` (33 Mathefragen). In `lib/features/quiz/` werden die Antworten nicht gemischt.
- **Beleg:** Lösung 23-mal an Platz 2, 10-mal an Platz 3, nie an Platz 1 oder 4. Im gesamten Fragenvorrat: 62-mal Platz 2, 35-mal Platz 3, 11-mal Platz 1 oder 4. Inhaltlich sind alle 33 Mathefragen richtig.
- **Vorschlag:** Antworten beim Anzeigen mischen und den Index mitführen.

### M32 – „Plus bis 10“: Aufgaben mit großem erstem Summanden und mit 0 fehlen
- **Ort:** `math_task_templates.dart:13` (a und b je 1–6), `lib/features/learning_modules/plus_bis_10/plus_bis_10_screen.dart:170–171` (a 1–5).
- **Beleg:** Im Generator kommen 33 der 66 möglichen Aufgaben vor. Nie: 7 + 2, 8 + 1, 9 + 1, 7 + 3, 0 + 5, 5 + 0. Im Modul nie ein erster Summand über 5.
- **Vorschlag:** Alle Paare mit a + b ≤ 10 einschließlich 0 zulassen. Eigene Stufen: bis 5, bis 10, Tauschaufgaben, Zerlegungen der 10.

### M33 – Einmaleins: keine Stufen, Klasse 2 und 3 gleich, Malzeichen-Deutung uneinheitlich
- **Ort:** `math_task_templates.dart:47` und `:66` (beide 2–10 mal 2–10), `lib/domain/games/game_math_tasks.dart:112–113`, `einmaleins_screen.dart:435`, `task_hint_service.dart:370`.
- **Beleg:** Klasse 2 beginnt sofort mit `9 × 7` und `8 × 6`. Aufgaben mit 0 und 1 fehlen. Der Spiel-Rechenpfad erklärt `3 × 7` als „7 Gruppen mit je 3: 3 + 3 + …“, das Modul und der Tipp als „3-mal die 7“.
- **Vorschlag:** Reihen in Stufen freischalten (2, 5, 10 → 3, 4 → 6, 8 → 7, 9 → gemischt), danach Umkehraufgaben (`56 : 7`). Eine Deutung festlegen (a · b = a-mal die b) und überall verwenden.

### M34 – Erklärungen bei großen Zahlen unbrauchbar, Ergebnis fehlt
- **Ort:** `math_task_templates.dart:253`, `:259`.
- **Beleg:** `978 - 263 = ?` → „Starte bei 978 und gehe 263 Schritte zurück.“ `4443 + 2500 = ?` → „Lege zuerst 4443 und dann 2500 dazu.“ Bei allen Minusaufgaben fehlt das Ergebnis in der Erklärung.
- **Vorschlag:** Erklärung nach Zahlenraum: bis 20 Zählen und Zehnerübergang, bis 100 „erst die Zehner, dann die Einer“ mit Zwischenergebnis, darüber Stellen untereinander. Immer mit der fertigen Rechnung enden („978 − 263 = 715“).

### M35 – Umfang und Flächeninhalt: Antwort ohne Einheit, Maße ungewöhnlich
- **Ort:** `math_task_templates.dart:446–453`.
- **Beleg:** `Ein Rechteck ist 5 cm lang und 6 cm breit. Wie groß ist der Umfang?` → Karten 21, 22, 23, 24 ohne „cm“. Beim Flächeninhalt fehlt „cm²“. In 133 von 300 Aufgaben ist die „Länge“ kleiner als die „Breite“ (`2 cm lang und 17 cm breit`), 17-mal ist das „Rechteck“ ein Quadrat.
- **Vorschlag:** Karten als „22 cm“ und „88 cm²“. Länge ≥ Breite. Quadrat als eigene Aufgabe („Ein Quadrat hat die Seitenlänge 4 cm“). Ablenker: halber Umfang, Fläche statt Umfang und umgekehrt.

---

## 6. Befunde – leicht (Formulierung, Feinschliff)

| Nr. | Ort | Beleg | Vorschlag |
|---|---|---|---|
| L1 | `math_task_templates.dart:259`, `:419`, `:804–828`; `lumo_adventure_tasks.dart:202–232` | „In der Leseecke liegen 1 Bilderbücher“, „Tom hat 1 Kekse gebacken“, „Pip hat 1 Kirschen“, „fährt Ola 1 Runden“, „gehe 1 Schritte zurück“, „11 besteht aus 1 Zehnern und 1 Einern“. In Klasse-1-Textaufgaben 46 von 300, in Rechengeschichten 23 von 300. | Kleinste Zahl in Geschichten 2, oder Einzahl-/Mehrzahlform je nach Zahl wählen. |
| L2 | mehrere | Malzeichen „×“ (Vorlagen), „·“ (Abenteuer, Erklärungen), „mal“ (Ersatzaufgaben, Quiz). Minus „-“ und „−“. Beträge „6 €“ neben „7,90 €“ in derselben Auswahl, „1 Euro 50“ im Geld-Modul (`geld_screen.dart:190`). Zahlen wie 925407 ohne Gliederung. | Eine Schreibweise festlegen: „·“ und „:“, „−“, Beträge immer „6,00 €“ wenn Cent vorkommen, ab 10 000 mit Abstand. |
| L3 | `lumo_premium_visuals.dart:1949`, `:1921` | Das Themenbild sucht Wortteile: „Paradeiser“ enthält „rad“ → Auto. Goldfische im Aquarium und „Sauna“ → Schwimmer. | Nach ganzen Wörtern suchen oder das Bild in der Geschichte festlegen. |
| L4 | `lumo_premium_visuals.dart:201` | Bei „Was bedeutet gestern?“ oder „Wie viele Minuten sind 3 Stunden?“ erscheint „Schau auf die Zeitangaben in der Aufgabe.“ | Bei diesen Aufgaben kein Uhr-Feld zeigen. |
| L5 | `math_task_templates.dart:433` | „Rechne von rechts nach links und tausche, wenn nötig.“ „Tauschen“ ist unklar und passt nicht zum Ergänzungsverfahren, das in Österreich üblich ist. | „Beginne bei den Einern. Ergänze von der unteren zur oberen Ziffer. Reicht es nicht, ergänze auf die nächste Zehnerzahl und merke 1.“ |
| L6 | `lumo_adventure_tasks.dart:460–461`, `:483` | „10 + 10 = 20. 20 = 20 – das Krokodil-Maul frisst immer die größere Zahl.“ Uhr: „5 Uhr + 2 = 7 Uhr.“ | Bei „=“: „Beide Seiten sind gleich groß.“ Uhr: „Von 5 Uhr 2 Stunden weiter: 6 Uhr, 7 Uhr.“ |
| L7 | `lumo_adventure_tasks.dart:360–380`, `:138–150` | Klasse 1 immer „Ball und Buch“, Klasse 2 immer „Spielzeug-Rakete“. Ablenker außerhalb des Zahlenraums der 1. Klasse (16 €, 25): in 66 von 300 Rechengeschichten eine Karte über 20. | Waren aus `adventureMarketGoods` mischen. In Klasse 1 Ablenker auf 0–20 begrenzen. |
| L8 | `geld_screen.dart:48`, `:153–158`, `:190` | 30 Aufgaben pro Runde (andere Module 12). Falsche Beträge sind mit den gezeigten Münzen nicht legbar (z. B. 83 Cent bei 10/20/50-Cent-Münzen). „1 Euro 50“. | 12 Aufgaben. Ablenker in Zehnerschritten oder durch eine vergessene Münze. „1,50 €“. |
| L9 | `bruchrechnen_screen.dart:109–115`, `:285` | Die ersten beiden Aufgaben sind immer „1/2“. Titel „Bruchrechnen“, geübt wird das Benennen von Brüchen. | Eine der beiden durch 1/4 oder 3/4 ersetzen. Titel „Brüche erkennen“. |
| L10 | `lumo_rechentricks.dart:323–336`, `:377–388`; Poster `lumo_rechentricks_poster_screen.dart:589–645` | „Vereinfachen“ rundet nur auf den nächsten Zehner und wird bei fast jeder dreistelligen Plusaufgabe gewählt (`387 + 337` → „384 + 340“). Minus: „445 - 0 = 445“ als eigener Schritt. | Nur anwenden, wenn ein Summand höchstens 5 von einem vollen Hunderter entfernt ist. Schritte mit 0 auslassen. |
| L11 | `uhr_lernen_screen.dart:60–63` | „Viertel nach 3“, „Viertel vor 4“. In Ostösterreich sagt man auch „viertel vier“ und „dreiviertel vier“. | Beide Sprechweisen in der Hilfe nennen oder in den Einstellungen wählbar machen. |
| L12 | `cognitive_profile_generator.dart:12`, `:38`, `:51–53`, `:396`, `:487`, `:494` | „Hund verhält sich zu Welpe wie Katze zu …“ (Klasse 1), „Schiff fährt auf …“ (Wasser), „Arzt arbeitet in einer Praxis“ (in Österreich: Ordination), „Wie viel Wechselgeld bleibt?“, „Welche Zahl stand an Position 3?“, Erklärung „Die Merkfolge wurde nur kurz gezeigt.“ | „Ein junger Hund heißt Welpe. Eine junge Katze heißt …“, „Schiff fährt auf dem …“, „Ordination“, „Wie viel Geld bekommt man zurück?“, „an dritter Stelle“, Erklärung mit der Folge. |
| L13 | `lumo_adventure_tasks.dart:840–841` | „Kirsche, Birne, Pflaume gehören zu Obst. Kasten gehört zu Möbelstücke.“ | Gruppennamen mit Artikel im Dativ hinterlegen: „gehören zum Obst“, „gehört zu den Möbelstücken“. |
| L14 | `math_task_templates.dart:401–404` | Dritte Karte „beides“ ist nie sinnvoll. Die Erklärung beschreibt immer nur „gerade“, auch wenn „ungerade“ richtig ist. | Zwei Karten, oder dritte Karte „weiß ich nicht“. Erklärung je Fall: „63 endet auf 3. Beim Bilden von Paaren bleibt eins übrig: ungerade.“ |
| L15 | `math_task_templates.dart:273–276`, `:753–762` | Erklärung „Zahlwörter liest man wie normale Wörter.“ hilft nicht. Bei 20 nur drei Karten. | „14 = vier-zehn: erst die Einer, dann zehn.“ Vierte Karte ergänzen (z. B. „zwölf“). |
| L16 | `math_task_templates.dart:261–265` | `Welche Zahl fehlt? 17, 18, _, 20` → Karten 18, 19, 20, 21. Zwei der drei falschen Karten stehen schon in der Reihe. | Ablenker außerhalb der gezeigten Zahlen wählen, Lücke an wechselnder Stelle. |
| L17 | `math_task_templates.dart:266–272` | Frage „wo ist mehr?“ mit der Antwort „gleich“. Erklärung „Vergleiche die Menge, nicht die Länge der Zeile“, obwohl hier die längere Reihe immer mehr Äpfel hat. | „Wo sind mehr Äpfel: links, rechts oder gleich viele?“ Erklärung: „Zähle beide Seiten.“ Reihen verschieden weit auseinander legen, damit die Länge nicht verrät. |
| L18 | `adventure_word_data.dart:5` (nur Namen, keine Fürwörter) | „Mila sammelt … Dann findet Mila noch … Wie viele hat Mila jetzt?“ dreimal derselbe Name. | Geschlecht je Figur hinterlegen und „sie/er“ verwenden. |

---

## 7. Lücken gegenüber dem, was Eltern je Klasse erwarten

Ohne Anspruch auf Lehrplan-Vollständigkeit, nur aus dem Vergleich mit dem geprüften Bestand.

- **Klasse 1:** Volle Stunden an der Uhr. Münzen und Scheine erkennen, Beträge legen. Vorgänger und Nachfolger, Zahlen ordnen. Zahlen zerlegen (Zahlenhäuser gibt es nur im Spiel). Aufgaben mit 0, Tausch- und Umkehraufgaben. Verdoppeln und Halbieren bis 20. Minus-Geschichten (die Textaufgaben der 1. Klasse sind nur Plus).
- **Klasse 2:** Hunderterfeld, Nachbarzehner, Zahlen bis 100 ordnen. Geteilt als Umkehrung des Einmaleins. Uhr lesen mit Viertel- und halben Stunden (die Einheit „Uhrzeit“ verlangt kein Lesen). Geld mit Cent, Wechselgeld als eigene Einheit. Längen messen und schätzen in cm. Kalender. Körper (Würfel, Quader, Kugel).
- **Klasse 3:** Stellenwert und Zahlenstrahl bis 1000, Runden. Division mit Rest. Halbschriftliches Malnehmen (4 · 23). Schriftliche Verfahren als Rechenweg mit Übertrag, nicht nur als Auswahl. Geld mit Komma. km/m, min/s, l/dl. Rechter Winkel, parallel, Körpernetze. Sachaufgaben mit Mal und Geteilt.
- **Klasse 4:** Zahlen bis 1 000 000 lesen, zerlegen, runden (derzeit nur Vergleichen und Rechnen bis 10 000). Division mit Rest und zweistelligem Divisor als Verfahren. Bruchteile von Größen (ein Viertel von 20 kg). Kommazahlen bei Geld und Maßen (1,5 m = 150 cm). t/kg, mm, Flächenmaße. Maßstab. Zeitspannen und Fahrpläne. Echte Tabellen und Diagramme. Fläche und Umfang des Quadrats, zusammengesetzte Flächen.
- **Zuordnung in der Akademie** (`lib/core/curriculum/academy_topic_units.dart:9–20`): „Zahlen bis 10“ führt zu „Mengenvergleich“, „Zahlen bis 100“ zu „Plus bis 100“, „Zahlen bis 1000“ zu „Plus bis 1000“, „Geometrie“ (Klasse 3) zu „Umfang“. Die Kachel verspricht jeweils mehr, als die Einheit übt.

## 8. Die zehn wertvollsten Verbesserungen

1. **Antwortkarten neu bauen.** Lösung an zufälliger Größenposition, Ablenker aus typischen Fehlern je Aufgabenart (S1, M1). Das behebt den größten Einzelfehler in 33 Mathe-Einheiten mit einer Änderung an einer Funktion.
2. **Bilder zeigen nur das Gegebene.** Divisionsgruppen, Waage, Messbecher, Lineal und Zahlenstrahl dürfen das Ergebnis erst nach der Antwort zeigen (S2, S3, S4). Jedes Bild bekommt seine Zahlen aus der Vorlage und nicht aus der Textsuche (S6, S12, M16, M17).
3. **Tipps je Einheit schreiben statt nach Stichwörtern raten.** Drei Stufen: Einstieg, Teilschritt, fast gelöst. Rechentricks nur bei reinen Ganzzahl-Aufgaben (S5, S7, S8, M19).
4. **Stufen innerhalb jeder Einheit.** Zum Beispiel Plus bis 100: ohne Übergang, mit Übergang, gemischt. Einmaleins nach Reihen. Die Stufe steigt nach mehreren richtigen Antworten. Heute ist jede Einheit ein einziger Zufallstopf, und Klasse 2 und 3 teilen dieselben Einmaleins-Aufgaben (M33).
5. **Zahlen ohne Schlagseite ziehen.** Ergebnis zuerst wählen, dann zerlegen. Keine Häufung bei 1000, 100, 20, 0 oder 99 (M2), alle Paare im Zahlenraum einschließlich 0 (M32).
6. **Handeln statt nur Antippen.** Schriftliche Verfahren mit Zifferneingabe im Stellengitter und Übertragsfeldern. Uhr stellen und ablesen. Münzen legen. Zahl am Zahlenstrahl antippen. Zahlenmauer als Bild. Das Minus-bis-10-Modul mit den Bonbons ist das gute Vorbild im Bestand.
7. **Sachaufgaben überarbeiten.** Umlaute, Einzahl bei 1, wechselnde Rechenwege statt „immer minus 3“ und „immer mal 2 minus 4“, glaubwürdige Zahlen, Fragen nach „wie viele mehr“ und Aufgaben mit einer überflüssigen Angabe (M3, M9, M20, M22, L1).
8. **Erklärungen als Rechenweg mit Ergebnis.** Je Zahlenraum ein passender Weg (Zehnerübergang, Zehner und Einer getrennt, Stellen untereinander), immer mit der fertigen Rechnung am Schluss (M34, S11, L5).
9. **Logik und Denk-Test mit echtem Nachdenken.** Vermischte Angaben, Lücken an wechselnder Stelle, mehrere Regelarten, Steigerung von Klasse 1 bis 4. Im Denk-Test keine doppelten Fragen, „Vierteldrehung im Uhrzeigersinn“ statt Grad, altersgemäße Merklängen, eindeutige Wortpaare (M23–M30).
10. **Lücken füllen und kleine Listen vergrößern.** Zuerst Uhr lesen (Klasse 1/2), Münzen und Cent, Division mit Rest, Runden und Stellenwert bis zur Million, echtes Diagrammlesen. Zeit, Symmetrie und Symmetrieachsen brauchen jeweils mindestens 30 statt 4 bis 8 Aufgaben (M14, Abschnitt 7).

## 9. Was nicht geprüft werden konnte

- **Keine Ansicht am Gerät.** Alle Aussagen zu Bildern (S2, S3, S4, S6, S12, M16–M18, L3, L4) sind aus dem Code hergeleitet, nicht am laufenden Bildschirm bestätigt. Ein Flutter-Testlauf hätte Dateien im Repository angelegt und wurde deshalb unterlassen.
- **Lernmodule** (`lib/features/learning_modules/`): nur gelesen. Texte, Erzeugungslogik und Hilfeschritte sind geprüft, Darstellung und Ablauf nicht.
- **Interaktive Arbeitsflächen** (`interactive_task_workspace.dart`: Zehnerbrücke, Wegnehmen, Gruppen, Zahlenstrahl, Formen): nur die Auswahl gelesen, welche Fläche wann erscheint. Ob diese Flächen selbst Lösungen verraten, ist offen.
- **Formen nachzeichnen:** Zeichenfläche und Bewertung nicht geprüft.
- **IQ-Figurenrätsel:** Regeln und Eindeutigkeit im Code geprüft, die gezeichneten Figuren nicht gesehen.
- **Nicht untersucht:** KI-erzeugte Aufgaben und Foto-Lektionen, geführte Lektionen (`lib/domain/tutoring/guided_lesson_catalog.dart`), Lernlabor (`lib/features/learning/lab/learning_lab_catalog.dart`), Mini-Spiel-Aufgaben außer dem Rechenpfad (`lib/domain/games/mini_game_learning_task.dart`), Lumo-Karten, Quest-Bibliothek, `lib/core/legacy_learning_data.dart`, die Godot-Welt.
- **Altnamen ohne eigene Aufgaben:** „Zahlenreihe“, „Nachbarzahlen“, „Zahlen zerlegen“, „Rechenhäuser“, „Minus über 10“, „Blitzlicht“ stehen in `Curriculum.subjects` (`school_exercise_generator.dart:110–112`), werden aber nur auf vorhandene Einheiten umgeleitet (`math_task_templates.dart:203–221`) und sind über die Themenwahl nicht erreichbar. Sie wurden daher nicht eigens beprobt.
- **Lehrplanbezug:** Aussagen wie „über Volksschulstoff hinaus“ (M10, M11) beruhen auf meiner Kenntnis der üblichen Stoffverteilung, nicht auf einem Abgleich mit dem Lehrplantext.
