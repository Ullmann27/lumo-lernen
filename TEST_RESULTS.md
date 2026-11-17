# TEST_RESULTS – lumo-2040/tutor-20261117 (Lumo-Nachhilfe, Flutter-Seite)

Stand: 17.11.2026 (Europe/Vienna), Abschluss wegen Wochenlimit (WIP M1).

## Grün
- `flutter test test/tutoring/lumo_nachhilfe_test.dart` – 13/13 grün (inkl. Volltest aller
  Plus-Aufgaben bis 20 × alle Wege × alle Stufen: Originallösung wird nie verraten,
  Zwillinge haben anderes Ergebnis, Materialzustände konsistent; JSON von `fromNachhilfe`).
- `flutter test test/tutoring/native_learning_launch_test.dart` – grün (bestehende 3D-Lern-Brücke).
- `flutter analyze` auf `lib/domain/tutoring`, `lib/features/tutoring/lumo_nachhilfe_screen.dart`,
  `lib/features/learning/learning_content.dart` – keine Befunde.

## NOT RUN
- Widget-Test für Einstieg „Nachhilfe mit Lumo“ und 2D-Fallback-Screen – NOT RUN (Zeit/Limit).
- Komplette `flutter test`-Suite – NOT RUN (Laufzeit; nur betroffene Tests gelaufen).
- APK-Build und Gerätetest – NOT RUN.
- Godot-Szene mit gültigem Tutor-Payload, Captures – NOT RUN (siehe Godot-Branch).

## Freischaltung
Einstieg in der Lernansicht ist **verborgen**: `lumoNachhilfeFreigeschaltet = false`
(`lib/features/tutoring/lumo_nachhilfe_screen.dart`). Freischalten erst nach Widget-Test,
Gerätetest und Godot-Captures.

## Offene Punkte
1. Widget-Tests für Einstieg/Fallback (Rückkehr zur Aufgabe, Hilfe zählt als Hilfe, kein Fortschritt geschrieben).
2. Godot-Seite mit gültigem Payload headless testen + Captures (Branch `lumo-2040/tutor-godot-20261117`).
3. M2/M3 laut `docs/nachhilfe/KONZEPT.md`.
4. `MainActivity.kt` erlaubt `tutor` bereits; solange die Godot-Szene nicht im Build ist, wird die 3D-Route nicht angeboten (Einstieg verborgen).
