# Guided und LearningContent: konkrete Restintegration

Basis: `afb6aadd3fb3e1ff2c5220603c86478a31e531be`.
Owner-HEAD: `573eb1a14045eb2e7071f250107d6b9a4fb3bf96`.
Die benötigten WIP-Dateien wurden mit ausdrücklicher Autorisierung in
`8d612f074254548ef8e9296423222832c61f0375` eingefroren. Sie sind keine
ursprünglich vom Owner als fertig committete Lieferung. Pfade, SHA-256,
Originalblob und Zustand stehen im Freeze-Manifest. Eine Dreiwegeintegration
mit der aktuellen Root-Basis bewahrt deren Native-Factory und Bus.

## Ergebnis

- Adaptive Lernaufgaben und Guided konsumieren echte kanonische Busaktionen.
  Sprachkandidaten werden sichtbar, sind bearbeitbar und werden erst nach
  ausdrücklichem Bestätigen durch die bestehende Fachlogik bewertet.
- Stopp, Aufgabenwechsel, gewöhnlicher Hintergrund und überdeckte Routen
  verwerfen alte Vorschläge und Identitäten. Wiederholen/Tempoänderung
  erhöhen die Hilfestufe nicht. Ausgeblendete Hilfe bleibt Hilfe in der Wertung.
- Native Lernansichten behalten die konkrete Aufgabenbindung über Flutter-Pause
  und Android-Rückkehr. Auch eine Rückmeldung vor Flutter-Resume verliert
  keinen unbestätigten Vorschlag. Die native Ansicht kann keine Wertung buchen.
- LearningContent verwendet Roots `NativeLearningActivity.forTask`; damit ist
  der native Einstieg auch für fachlich geprüfte, nicht spezialisierte Familien
  erreichbar. Guided nutzt die spezialisierte Darstellung oder den vorhandenen
  begrenzten `fromCompanionContext`-Adapter.
- Prüfungen/Schularbeiten erlauben explizit nur Stopp und das Wiederholen oder
  langsamere Vorlesen des sichtbaren Aufgabenwortlauts. Hilfe, Sprachantwort
  und native Lösungsansicht bleiben dort gesperrt.
- Geführte Animationen reagieren auf tatsächliche Abbruchsignale.

## Ausgeführte Prüfung

`core_tests.log`: 59/59 bestanden in den fünf Dateien
`learning_content_commands_test`, `guided_coach_binding_test`,
`native_learning_launch_test`, `guided_lesson_runtime_test` und
`guided_ten_frame_playback_test`. Enthalten sind echte Widget-Routen,
Antwortbestätigung, Hilfe/Stop, Pause/Resume/Resize, Überdeckung, native
Payload-/Scope-Übertragung und Fortsetzung ohne doppelte Wertung.
`core_analyze.log`: separate Analyse der sieben Kern-/Testdateien.

Das belegt Flutter-Verhalten und die Plattformkanalgrenze mit kontrollierter
Android-Antwort. Es ersetzt keine reale Godot-/Mikrofon-/Geräteprüfung.
Ein generisches natives task_card ist kein Nachweis einer fachlich
spezialisierten räumlichen Manipulation für jede Inventarfamilie.
Die 18 Fachmodule werden in einer getrennten nächsten Lieferung angeschlossen.
Geschützte Schreibtrainer-/Journalinternals, C5-Module, Host und Kotlin
bleiben von dieser Lieferung unberührt.
