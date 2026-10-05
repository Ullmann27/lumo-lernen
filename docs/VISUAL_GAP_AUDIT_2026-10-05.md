# Visual-Gap-Audit – 2026-10-05

Basis: Heinz' Referenzbild „Mathe-Abenteuer“ vs. aktueller Build 0.10.6/1286.

## Sofort korrigiert in diesem Durchlauf

- `lib/features/learning/renderers/adaptive_task_renderer.dart`
  - papier-/cremefarbene Hauptkarte durch dunkelblaue Cyan-Hologlas-Karte ersetzt
  - Antwortkarten von weißen Standardkarten auf blaues Glas mit Cyan-Glow umgestellt
  - Mathe-Mengenbild als eigener dunkler Abenteuer-Block statt Schulbuchpapier
  - lokale Lumo-Hilfe von gelb/creme auf dunkles Glas umgestellt
  - sichtbare Fach- und Prompt-Hierarchie an Referenzbild angenähert
- `lib/features/learning/learning_content.dart`
  - Lumo im Fortschrittsbereich deutlich größer
  - Lehrer-Pose + motivierende Sprechblase
  - Mathematik-Fortschritt als „Mathe-Abenteuer“ bezeichnet
- `lib/features/learning/renderers/shape_trace_task_renderer.dart`
  - altes cremefarbenes Kartenlayout entfernt
- `lib/features/learning/renderers/writing_task_renderer.dart`
  - altes gelb/cremefarbenes Kartenlayout entfernt

## Weitere gefundene visuelle Altlasten

Priorität A – nächste Bildschirmrunde:
1. `lib/features/settings/settings_content.dart`
   - noch warme Orange-/Creme-Hauptflächen; passt nicht zur aktuellen Midnight-/Cyan-App.
2. `lib/features/settings/parent_report_card.dart`
   - weiße/orange Elternbericht-Karten und helle KI-Analysebox.
3. `lib/app/app_shell.dart`
   - einzelne alte helle Karten/Modalflächen; Laufzeitpfad je Dialog einzeln prüfen.
4. `lib/widgets/scan_screen.dart`
   - Scanner-/Aufgabenfoto-Karte noch im alten warmen Design.

Priorität B – Lern-/Nebenbereiche:
5. `lib/features/learning/learning_dna_card.dart`
   - warmes Creme-/Gold-Design.
6. `lib/features/agent/lumo_agent_content.dart`
   - alte helle Agenten-/KI-Karten.
7. `lib/features/learning/widgets/lumo_shape_trace_canvas.dart`
   - Canvas selbst hat noch helle Papierfläche; äußere Karte ist jetzt dunkel, Canvas folgt separat.

Priorität C – Spiele/Overlays:
8. `lib/features/games/lumo_cards/widgets/lumo_learning_card_overlay.dart`
   - gelb/cremefarbenes Overlay, stilistisch nicht auf neuem Glasniveau.
9. `lib/features/games/dice_race/lumo_dice_race_game.dart`
   - mehrere weiße Standard-Spielkarten.
10. `lib/features/games/lumo_cards/widgets/lumo_result_dialog.dart`
    - Ergebnisdialog noch hell.

## Arbeitsregel

Nicht alles pauschal umfärben. Bildschirm für Bildschirm:
1. echten Build-Screenshot nehmen
2. gegen Referenzbild / Zielsystem vergleichen
3. Layout + Hierarchie + Lumo + Glasflächen korrigieren
4. Compact/Phone/Fold/Tablet prüfen
5. Tests laufen lassen
6. erst dann zum nächsten Bildschirm

Keine reine „Farbe austauschen“-Aktion über die ganze App; Funktionslogik und Lesbarkeit bleiben erhalten.
