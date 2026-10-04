# Lumo: Lernstruktur (Anton-Prinzip) und lebendige App

Heinz' Tochter lernt am liebsten mit der Anton-App. Lumo übernimmt deshalb deren
**Struktur-Prinzip**, nicht deren Gestaltung, Namen oder Inhalte. Die Optik bleibt
Lumo (Bilder in `docs/design_targets/2026-10-04/`).

## 1. Struktur: kleine Schritte, immer sichtbarer Fortschritt

```
Lernen
 └─ Klasse (1.–4.)
     └─ Fach (Mathe, Deutsch, Lesen, Schreiben, Englisch, Sachkunde)
         └─ Themenblock (z. B. „Zahlen bis 10“, „Plus bis 10“, „Minus bis 10“)
             └─ Lektion (5–10 Aufgaben, 2–4 Minuten)
                 └─ Aufgabe
```

Regeln:
1. **Lernpfad statt Liste:** Ein Fach zeigt seine Themenblöcke als senkrechten, scrollbaren Pfad. Jede Lektion ist ein runder Knoten auf dem Pfad. Erledigte Knoten zeigen 1–3 Sterne, der nächste empfohlene Knoten pulsiert. Lumo steht neben dem aktuellen Knoten.
2. **Kurze Lektionen:** 5–10 Aufgaben pro Lektion, danach sofort ein Ergebnis-Bildschirm mit Sternen, XP und Konfetti. Kein Endlos-Üben ohne Abschluss.
3. **Sterne pro Lektion:** 3 Sterne bei 0–1 Fehlern, 2 Sterne bei 2–3, 1 Stern sonst. Wiederholen darf die Sterne verbessern, nie verschlechtern.
4. **Freie Wahl, aber Empfehlung:** Alle Lektionen sind antippbar, die empfohlene (aus `progress_recommendation_service.dart`) ist hervorgehoben. Nichts wird künstlich gesperrt.
5. **Abwechslungsreiche Aufgabentypen** in einer Lektion: Antwort antippen, Zuordnen, Ziehen, Lücke füllen, Zählen, Schreiben, Hören. Vorhandene Renderer in `lib/features/learning/renderers/` nutzen.
6. **Belohnungsschleife:** Lektion fertig → Sterne → XP-Balken füllt sich animiert → bei neuem Level eine eigene Level-Feier → Münzen/Sterne für den Belohnungsbereich (Profil).
7. **Tägliche Aufgaben** auf dem Start (wie im Zielbild): 3 kleine Ziele, die sich automatisch abhaken.
8. **Bestehende Lernmodule bleiben erhalten** (`lib/features/learning_modules/`). Sie werden als Lektionen in den passenden Themenblock eingehängt. Die Texte „Plus bis 10“ usw. bleiben sichtbar beschriftet (Tests und Android-QA suchen danach).

## 2. Lebendige App (ergänzt Abschnitt 2b in `DESIGN_ZIEL_2026-10-04.md`)

Heinz: „Wenn man die App aufdreht, springt ein Maxerl herum, Sterne fliegen, beim Anklicken fliegen die Buttons entgegen oder bewegen sich.“

- **Start:** Lumo fährt im Kart herein, springt aus dem Kart, winkt; Sterne fliegen aus dem Kart-Auspuff über den Bildschirm; die Kacheln fliegen gestaffelt von unten herein und federn nach.
- **Lumo hüpft herum:** Auf Start, Lernen und Spielen bewegt sich Lumo gelegentlich (alle 6–10 s) zu einer kleinen Aktion: hüpfen, winken, zur empfohlenen Kachel zeigen. Antippen von Lumo löst eine zufällige Reaktion und einen Satz aus.
- **Antippen:** Kacheln und Knöpfe fliegen beim Antippen kurz auf den Finger zu (Skalierung 1,0 → 1,06) und federn zurück, dann öffnet sich die Seite mit einer „Hero“-Animation aus der Kachel heraus.
- **Fliegende Sterne:** Jede verdiente Belohnung fliegt als Stern zur Sterne-Anzeige oben, die dann kurz pulsiert und hochzählt.
- **Viele Menüs, nie leer:** Jeder Bereich hat mehrere Unterbereiche (Lernpfad, Wiederholen, Lieblingsthemen, Tagesaufgaben, Belohnungen, Abzeichen, Avatar). Was noch nicht gebaut ist, zeigt einen ehrlichen „Bald“-Zustand mit Lumo, keine leere Seite.
- **Ton:** kurze Effekte zu Tippen, Sternen, Level (vorhandenes `lib/core/lumo_sound.dart`), abschaltbar.
- **Grenzen:** „Animationen reduzieren“ respektieren; Animationen nie vor Antworten oder Knöpfen; 60 FPS anstreben.

## 3. Reihenfolge

1. Fehlerfreier Stand (alle Tests grün).
2. Startseite mit echten Hintergründen/Logo und Begrüßung (Etappe 2 überarbeiten).
3. Lernpfad pro Fach mit Lektionen und Sternen (Etappe 3 erweitern).
4. Danach die übrigen Etappen wie geplant.
