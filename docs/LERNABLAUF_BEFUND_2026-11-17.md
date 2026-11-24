# Wie ein Kind in Lumo heute lernt – Befund und Umbauplan (17.11.2026)

Grundlage: Code-Durchsicht von `lib/` (nur lesend), Stand `1a5550c8`. Kein Gerätetest,
keine Beobachtung echter Kinder. Pfade relativ zu `lib/`.

## Was gut ist und bleibt

- Trennung „allein gelöst" / „mit Hilfe gelöst" in den Lerndaten
  (`domain/learning/independent_evidence.dart`, `core/learning_journey.dart`).
- Wiederholung in wachsenden Abständen (1/3/7/14 Tage) mit Transferaufgabe
  (`core/learning_journey.dart`) und ein Tagesplan mit Voraussetzungs-Prüfung
  (`core/lumo_personal_daily_tutor_planner.dart`).
- Sieben geführte Lektionen: erklären → Beispiel → gemeinsam → allein → Rückblick
  (`domain/tutoring/guided_lesson_catalog.dart`) und das Lernlabor mit Transferphase.
- Anschauungsmittel: Zehnerfelder, Zahlenstrahl, Stellenwert-Werkstatt, Äpfel in „Plus bis 10".
- Protokoll jeder Antwort mit gegebener und erwarteter Lösung (`lumo_attempt_log_v1`).
- Hinweisleiter in drei Stufen, die die Lösung nicht verrät (`core/task_hint_service.dart`).

## Was pädagogisch nicht trägt

| Nr. | Befund | Stelle |
|---|---|---|
| 1 | **Durchtippen statt Denken:** Bei falscher Antwort wird die Option grau, das Kind tippt weiter. Mit 3–4 Optionen kommt es immer ans Ziel; nach einem Fehlversuch zählt die richtige Antwort trotzdem als „allein gelöst" | `features/learning/renderers/adaptive_task_renderer.dart:491-516` |
| 2 | **Rückmeldung passt nicht zum Fehler:** Sätze aus Stimmungs-Listen. Die vorhandene Fehlererkennung berechnet eine kindgerechte Erklärung, zeigt sie aber nie an. Bei Plus/Minus wird fast jeder Fehler als „Zeichen verwechselt" gewertet | `domain/learning/lumo_learning_feedback_engine.dart`, `domain/learning/error_detective.dart:74-92`, `features/learning/learning_content.dart:1837` |
| 3 | **Fehler kommen nie wieder:** Keine ähnliche Aufgabe später; die Wiederholsperre hält frühere Aufgaben sogar fern. Das Protokoll dient nur dem Bericht | `features/learning/learning_content.dart:1276-1370` |
| 4 | **Keine Anpassung:** Die Schwierigkeit ist fest die Klassenstufe. Die Bausteine für Anpassung haben keinen Aufrufer. „Wir dürfen bald schwerer werden" und „drei leichte Aufgaben" sind Versprechen ohne Wirkung | `domain/learning/adaptive_learning_engine.dart`, `core/recommendation_engine.dart:47` |
| 5 | **Lösung zu früh oder gar nicht erarbeitet:** In Tests steht sofort „Richtige Antwort: X" ohne Erklärung. Hilfe-Stufe 3 in Mathe nennt das Ergebnis. „Minus bis 10" springt nach zwei Fehlern einfach weiter | `learning_content.dart:3564`, `core/math/lumo_rechentricks.dart:199-262`, `features/learning_modules/minus_bis_10/minus_bis_10_screen.dart:181` |
| 6 | **Zu lange Einheiten:** 30 Aufgaben in neun Modulen, kein Wiedereinstieg an der Stelle, kein automatisches Vorlesen der Aufgabe | `learning_content.dart:260-273` |
| 7 | **Fast nur Auswahlaufgaben:** selbst eingegebene Antworten gibt es kaum | `features/learning/adapters/legacy_lumo_task_adapter.dart:618-628` |
| 8 | **Fortschritt ohne Beleg:** „Können 100 %" nach einer Antwort, „82 % sicher" und eine Eltern-„Stärke" nach einer richtigen Antwort | `learning_content.dart:1660`, `core/progress_repository.dart:291-298`, `domain/analysis/daily_recommendation_engine.dart:190` |
| 9 | **Hilfe spiegelt sich nicht in der Belohnung:** mit Hilfe 5 Sterne, allein rund 6. In Tests kosten Fehler 2 Sterne | `domain/learning/reward_engine.dart:164-314` |
| 10 | **Wenig Führung im Lernbereich:** Klasse → Fach → Thema frei wählbar, ohne Reihenfolge; Führung gibt es nur auf der Startseite | `features/sections/lumo_learning_hub.dart` |

## Umbau in Paketen (Reihenfolge festgelegt)

Leitlinie: Das Kind soll selbst denken, bei einem Fehler genau die Hilfe bekommen, die zu
diesem Fehler passt, es danach noch einmal allein schaffen und nur für echtes Können
„sicher" lesen. Kein Druck, keine Strafe.

**L1 – Ehrlich üben (zuerst):**
1. „Allein gelöst" gilt nur beim ersten Versuch ohne Hilfe.
2. Nach einem Fehler: die Erklärung der Fehlererkennung, wenn der Fehler erkannt ist, sonst
   ein neutraler Satz; Hinweis Stufe 1 wird angeboten. Nach dem zweiten Fehler ein
   Lösungsweg in Schritten; die Aufgabe gilt als „gemeinsam gelöst". Nie weiterspringen.
3. Jede gemeinsam gelöste oder falsch begonnene Aufgabe kommt zwei bis drei Aufgaben später
   als ähnliche Aufgabe wieder („Zwillingsaufgabe"). Gelingt sie allein, wird das gesagt.
4. Anzeige des Könnens nur mit Beleg: unter fünf Aufgaben „am Anfang", „sicher" erst nach
   genügend allein gelösten Aufgaben an mindestens zwei Tagen; Eltern-„Stärke" entsprechend.
5. Belohnung: allein gelöst deutlich mehr als mit Hilfe; kein Sternabzug mehr.
6. Rechentricks ohne Ergebnis, „Minus bis 10" ohne Weiterspringen, Plus/Minus-Fehler richtig benannt.
7. Länge nach Alter (1. Klasse 6, 2. Klasse 8, 3./4. Klasse 10 Aufgaben), lange Module in
   Runden mit Wiedereinstieg; Aufgabe in Klasse 1–2 automatisch vorlesen, wenn die Stimme an ist.

**L2 – Anpassen und selbst eingeben:** drei Stufen je Thema im Aufgabengenerator, Wechsel
nach Leistung; Zahleneingabe statt Auswahl bei Rechenaufgaben.

**L3 – Lernweg:** je Fach ein geordneter Weg (neu → üben → sicher → wiederholen) im Lernbereich.

**L4 – Inhalte:** Korrekturen aus den Fachprüfungen (Mathematik; Deutsch, Sachunterricht,
Englisch), danach Lücken füllen.
