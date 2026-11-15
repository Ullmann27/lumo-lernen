# Übergabe Chat 2 · Lernaufgaben und Fachlogik

Arbeit auf \`feature/lumo-nextgen-learning-tasks-20261115\`. Ausgangspunkt \`integration/lumo-learning-nextgen-20261115\` mit Vertrag \`docs/integration/lumo-nextgen-20261115/PROTOCOL_V1.md\` und Abdeckung \`COVERAGE_BASELINE.json\` (36 Akademiethemen, 20 Modul-IDs, 5 Lab-Bereiche, 8 Generatorfamilien; Überschneidungen sind keine 69 verschiedenen Lernarten).

## Eigene Dateien
- \`lib/features/learning/**\`, \`lib/features/learning_modules/**\`, \`lib/features/teacher_mode/**\`, \`lib/domain/learning/**\`, \`lib/domain/learning_intelligence/**\`, \`lib/domain/tutoring/**\`, Aufgaben-Generatoren unter \`lib/core/*task*templates.dart\` und \`lib/core/school_exercise_generator.dart\`.
- Nur notwendige themenspezifische Änderungen an \`lib/app/**\` nach schriftlicher Übergabe an Chat 1.
- Eigene Tests \`test/learning/**\`, \`test/learning_modules/**\`, \`test/domain/learning/**\`, neue präzise Tests in \`test/**\` mit \`nextgen_learning_\`-Präfix.

## Verbindlich
1. Alle im JSON inventarisierten Einstiege auf echte **Klasse/Fach/Unit**-Generatoren/Module zurückführen, fehlende dynamische \`Curriculum.unitsForGrade\`-Kombinationen per laufbarem Dart-Audit ergänzen. Vorhandene Story-, Lesebuddy-, CrossGrade-, Schreib- und Testmodi ebenfalls auf Aufgabentypen prüfen. Schreibtrainer- und Journalimplementierungen intern **nicht** anfassen.
2. Geprüfte Richtigkeit ausschließlich \`TaskInstance\`, bestehenden Generatoren, \`RewardEngine\`, Progress/Wallet; KI-Text oder Godot-Mesh dürfen nicht bewerten.
3. Den bestehenden \`NativeLearningActivity\`-Kanal wiederverwenden: zuerst Brücke 8+5, Silben Ba-na-ne, logisches Muster; danach alle tatsächlich kompatiblen Taskfamilien. Für nicht verfügbare visuelle Typen einen ehrlichen, verständlichen Flutter-Fallback anbieten.
4. Jede Aufgabe: Aktion, konkrete Objekt-IDs, erlaubte Hilfen, Fehlerklasse, Korrekturweg, ruhiger Modus und mindestens 48dp-Ziel. Nicht einfach Dekoration auf Multiple Choice legen.
5. Stale-\`taskId\` / \`taskRevision\` / \`ownerGeneration\` darf Antwort oder Belohnung nicht buchen; Wechsel/Abbruch und Wiederaufnahme in Tests belegen.

## Übergabe an Chat 1
Commit-SHA, geänderte Pfade, maschinenlesbarer Abdeckungs-Delta (unveränderte IDs), Tests inklusive Fehlfälle, Android-Status und genaue Lücken. Kein Merge nach \`main\`. Andere Teams schreiben \`lib/core/lumo_voice*\` oder Godot-Lern-Rig; nur über Vertrag abstimmen. Keine Kart-/Dschungel-Dateien. 
