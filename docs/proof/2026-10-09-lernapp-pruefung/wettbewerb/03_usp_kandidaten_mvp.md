# A6 – USP-Kandidaten, Bewertung, MVP-Spezifikation

Filter: (a) Lumo-Welt, (b) offline in Flutter, (c) 6–10 nicht überfordern, (d) ethisch sauber, (e) Literaturrückhalt.
Neuheit = "im DACH-Volksschulmarkt nicht gefunden" (Websuche Okt. 2026, nicht systematisch; VERMUTET).

| # | Kandidat | Neuheit | Evidenz | Aufwand | Module | Risiken | Demo |
|---|---|---|---|---|---|---|---|
| A | Lumo macht einen Fehler (Teachable Agent + Fehlerdetektiv) | Betty's Brain/Magical Garden = Forschung/Vorschule; kein DACH-Volksschulprodukt gefunden | Protégé mittel–schwach (Chase 2009, Pareto 2012, Kobayashi g 0,35–0,56 Ältere); Selbsterklärung g 0,55 | M (MVP S) | ErrorPatternDetector (umgekehrt), MathTaskTemplates, LearningAnalysis, LumoVoice/Clips, RewardWallet | Kein echter Dialog (Skript); Fehlerbeispiele schwächer als korrekte (Barbieri) -> erst korrektes Beispiel; Überforderung -> nur Antippen | Lumo sagt 8+5=3, Kind zeigt den vergessenen Zehner am Zehnerfeld |
| B | Gedächtnis-Himmel (schlafende Sterne, Wecken in 3 Fragen) | keine Kinder-App mit sichtbarer Vergessenskurve gefunden; OLM+Decay bei Kindern ohne Studie | Spaced Retrieval stark (g 0,74 / d 0,54, Alter unklar), Anzeige ungeprüft | M | features/cosmos, AdaptiveTaskSelector (decay), Attempt.lastAt, CompetencyStat | Verlustangst -> Sterne verschwinden nie; keine Push/Streak; Mehrprofil nötig; erst ab 5 Versuchen belastbar | Drei Sterne flimmern, nach drei Fragen strahlen sie |
| C | Fehler-Reparatur-Pfad (Beispiel -> Finde den Fehler -> Aufgaben mit Fehlertyp-Distraktoren) | bettermarks (ab Kl. 3, Lizenz), Eedi (UK Sek.), Calcularis (Therapie) | Elaboriertes Feedback 0,49; Worked Examples 0,48; Eedi herstellerseitig | S–M | LearningAnalysis.patterns, school_exercise_generator | Regex nur Rechnen/Lesen; Fehlklassifikation -> "vielleicht" formulieren | Dreimal derselbe Trick: Lumo fängt ihn mit dir |
| D | Schulschrift-Lumo (Kind bringt Lumo Schrift bei, ML-Kit-Ink) | keine App mit DE/AT-Schulschrift gefunden; Dynamilis (CH) | CoWriter klein; Protégé | L | writing_engine, LetterTemplates | Vorlagen/Lizenz Schulschrift; Fehlerkennung frustriert; Finger statt Stift | Lumos wackliges a wird mit jeder Korrektur schöner |
| E | Vorlese-Coach offline | Duolingo ABC/Khan nur Englisch; DACH-Primarstufe kaum | hier nicht geprüft | M–L | ReadingV2PronunciationAnalyzer, LumoSpeechListener | Kinderstimmen-ASR, `onDevice` nicht gesetzt, Modellgröße | Lumo markiert das eine Wort, das nochmal dran ist |
| F | Ehrliche Sterne (Belohnungs-Ethik: Reparatur/Wiederholung statt Menge, Tagesdeckel, Eltern sehen Warum) | gering (Vertrauensmerkmal) | Deci 1999; Habgood 2011 | S | RewardEngine/Wallet, Eltern-Dashboard | weniger "Grind" -> Kart-Tuning langsamer | Sterne gibt's fürs Verstehen, nicht fürs Klicken |
| G | (Voraussetzung, kein USP) Datenschutz-Bereinigung + Mehrprofil/Geschwister + AT-Kompetenzraster | – | – | S–M | PRIVACY.md, lumo_image_generator, prepare_android.py, ProfileRepository | – | – |

## Favorit A (mit C-Kern)
Begründung: nutzt Lumos Figur und vorhandene Fehlerdiagnose, offline, kein Mikro/Netz, zwei Evidenzstränge, kindgerecht (Lumo braucht Hilfe = geringe Statusangst), Eltern-/Lehrerbericht bekommt "Fehler erklären"-Kompetenz.

## Reihenfolge
0 Voraussetzungen (G) -> 1 A -> 2 F -> 3 B (nach Mehrprofil) -> 4 C ausbauen (Muster für Lesen/Sachunterricht, Distraktoren) -> 5 E -> 6 D.
Werkstatt-Mathe (Lernen in die Tuning-Mechanik, intrinsische Integration) widerspricht docs/DESIGN_ZIEL_KART_2026-10-04.md ("Kein Lernen im Kart") -> nur nach Entscheidung von Heinz; Godot-Code liegt extern (lumo-godot, Pin de91cc9).

## MVP-Spezifikation A (1–2 Tage)
Umfang: eine Kompetenz "Addition mit Zehnerübergang" (CompetencyClassifier), Kl. 1–2, 3 Runden + 2 Transferaufgaben.
1. `LumoMistakeGenerator` (neu, rein Dart): Eingabe a+b; Ausgabe falsche Antwort + Musterlabel. Regeln = Umkehrung ErrorPatternDetector: expected−10 ("Zehner vergessen"), vertauschte Ziffern, ±1 ("verzählt"), |a−b| ("Minus statt Plus").
2. Screen: Aufgabe + Zehnerfeld (vorhandene Visuals), Lumo "antwortet" falsch (TTS/Clip); drei Karten "Was ist passiert?" (Musterlabels); Kind legt den Zehner im Feld; Lumo bedankt sich ("Jetzt versteh ich's!"). Kein Timer, keine Abzüge.
3. Auslöser: LearningAnalysis liefert needsHelp oder Muster ≥2× für die Kompetenz; Reihenfolge: erst 1 normale korrekt gelöste Aufgabe (Worked-Example-Logik), max. 3 Lumo-Fehler je Sitzung.
4. Protokoll: Attempt mit competency "Fehler erklären · Addition mit Zehnerübergang"; Sterne nur fürs Erklären/Reparieren (Tagesdeckel).
5. Tests: Generator (jede Regel, nie die richtige Antwort), Widget-Test für Karten, Regressions-Test Lernbericht.
6. Messen: Anteil des Musters "Zehner vergessen" vor/nach (Bericht), nicht kausal; 5 Kinder/Eltern beobachten (Verstehen von "Lumo irrt").
Ethik-Leitplanken: Lumo-Fehler klar als Spiel erkennbar; nie Kind beschämen; bei 2 Fehlversuchen Lösung zeigen; kein Netz, kein Mikrofon, keine Konten.
