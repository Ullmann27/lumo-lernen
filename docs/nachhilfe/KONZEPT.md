# Lumo-Nachhilfe – Konzept (Stand M1, WIP)

Ziel: Lumo erklärt eine konkrete Aufgabe, bei der das Kind hängt, Schritt für Schritt,
in 3D (Godot) mit sicherem 2D-Fallback (Flutter). Lernfortschritt, Profile,
Schreibtrainer und Journal werden **nicht** verändert (nur lesend).

## Didaktik
- **Gestufte Hilfe** (Scaffolding, Wood/Bruner/Ross): Hinweis → Teilschritt → Vorzeigen → Üben.
  Startstufe kommt aus dem bestehenden `LumoTutorEngine.decideHelpLevel`.
- **Lösung der Originalaufgabe wird nie verraten.** Hinweis/Teilschritt arbeiten an der
  Originalaufgabe ohne Ergebnis; Vorzeigen/Üben nutzen eine *Zwillingsaufgabe* gleicher
  Struktur (Zehnerübergang ja/nein, ähnliche Größen) mit anderem Ergebnis.
- **Mehrere Wege** (Plus bis 20): Rechenrahmen (Kraft der Fünf), Zahlenstrahl (Hüpfen über
  die 10), Zerlegen (Zahlenhaus), Verdoppeln (Fast-Verdopplung, nur a,b ≤ 9, |a−b| = 1),
  Tauschen. Verknüpft mit `RechentricksKind` und `LumoTutorVisualType`.
- **Fehlermuster** → passender Weg + freundliche Rückmeldung: eins daneben, Rechenzeichen
  vertauscht, Zehner vergessen, Zifferndreher (gemappt auf `ErrorType`).
- **Lob für die Strategie**, nicht nur fürs Ergebnis (Mueller & Dweck).
- **Enaktiv → ikonisch → symbolisch**: Kind schiebt Perlen / hüpft selbst, dann Zahlensatz.

## Architektur
- `lib/domain/tutoring/lumo_nachhilfe.dart`: reine, getestete Logik.
- `NativeLearningActivity.fromNachhilfe`: schickt alle vorberechneten Pläne als JSON an Godot
  (`kind: 'tutor'`); Flutter bleibt Quelle der Didaktik, Godot spielt nur ab.
- `lib/features/tutoring/lumo_nachhilfe_screen.dart`: 2D-Fallback (Rechenrahmen, Zahlenstrahl,
  Zerlegen); „In 3D mit Lumo“ nur auf Android.
- Godot-Branch `lumo-2040/tutor-godot-20261117`: `scenes/learning/tutor_world.tscn`,
  `scripts/learning/tutor/*` (Plan-Validierung, 3D-Rechenrahmen, Zahlenstrahl 0–20 mit
  Hüpfbögen, Zerlege-Blöcke, Fuchs, Sprache über HostBridge).

## Meilensteine
- M1 (dieser Stand): Konzept + Plus bis 20 mit 5 Wegen, 4 Stufen, 4 Fehlermustern.
- M2 (offen): Minus bis 20, Stellenwert-Blöcke, Bruch-Pizza, Einmaleins-Gruppen.
- M3 (offen): Wiederholung (spaced repetition) aus Fortschrittsdaten, nur lesend.
