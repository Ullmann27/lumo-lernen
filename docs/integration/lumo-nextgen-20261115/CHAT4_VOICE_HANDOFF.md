# Übergabe Chat 4 · Hören, Sprechen und freie Rückfragen

Arbeit auf \`feature/lumo-nextgen-voice-20261115\`, Ausgangspunkt \`integration/lumo-learning-nextgen-20261115\`. Maßgeblich: \`docs/integration/lumo-nextgen-20261115/PROTOCOL_V1.md\` und \`COVERAGE_BASELINE.json\`.

## Bestehende, belegte Bauteile
- \`lib/core/lumo_conversation_controller.dart\`: vorhandener Task-/Profil-Revision-Guard, begrenzte History, Anfrageabbruch; keine Bewertungsautorität.
- \`lib/core/lumo_speech_listener.dart\`: lokale \`speech_to_text\`-Android-ASR, Generation/Abbruch.
- \`lib/core/lumo_voice.dart\`: aktive lokale Stimme, tatsächliche \`startedPlaybackCount\`/\`completedPlaybackCount\`, Status und Mundamplitude. Das vorhandene Offline-/Lizenz-/Kinderschutzkonzept bleibt erhalten.
- \`lib/features/lumo3d/lumo3d_launcher.dart\`: vorhandener Host-Start für die Godot-Lern-Activity.
- Godot \`scripts/learning/learning_world.gd\` nutzt \`LumoHost.speakLearning\`/\`stopLearningSpeech\`/\`getLearningSpeechStatus\`. Dieser bestehende **einseitige Audio-Rückkanal** ist kein Nachweis eines freien Gesprächs in Godot.

## Eigene Dateien
- \`lib/core/lumo_conversation_controller.dart\`, \`lib/core/lumo_speech_listener.dart\`, \`lib/core/lumo_voice.dart\` und zugehörige \`lib/core/lumo_*speech*\`, \`lib/core/lumo_*voice*\`-Helper.
- Eigene Brücken-Erweiterungen nur in neuen klar abgegrenzten \`lib/features/lumo3d/learning_conversation_*.dart\` und erforderlichen Android-\`LumoHost\`-Sprachmethoden; vorhandene Spiellauncher-/Reward-/Profilpfade nicht eigenmächtig verändern.
- Präzise Unit-/Host-Tests \`test/*speech*\`, \`test/*conversation*\` und Integrationstests in eigenem Namespace.

## Verbindlich
1. Das Kind darf **während** einer gestarteten 3D-Lernszene mit LUMO sprechen und nachfragen; belege den vollständigen Live-Transport Android ASR → aktuelle Aufgabe/Kontext → geprüfter Erklärtext → echter Audioplayer → hörbar-Status → Godot-Mund/Geste/Untertitel. Keine reine Vorlesedemo als Gespräch ausgeben.
2. Rückfrage \`Warum zuerst zwei?\` führt zu korrekter Darstellung 8+5, \`langsam\` bei Banane wirklich andere Wiedergabe, \`Stopp\` beendet ASR/TTS/Mund/Geste. Zahlenverhörung niemals als falsche Lernantwort speichern.
3. Aktionsempfehlungen nur aus v1-Allowlist. KI darf niemals Ergebnis, XP, neue Aufgabe oder Profil ändern. Nicht erreichbare/gesperrte Dienste verständlich anzeigen; vorhandene Offline-Fallbacks erhalten. Keine ungefragt kostenpflichtigen Dienste.
4. Pro Turn Aufgaben-ID, Generation, Revision und Voice-Playback-ID sichern. Verspätete ASR/LLM/TTS-Callbacks und App-Pause dürfen keinen neuen Vorgang beeinflussen. Bestehende Audio-/Clip-Lizenzregeln beachten.
5. Tatsächliche Playback-Markierungen/Mund-Zeiten statt geschätzter Phonem-Markierungen. Audio/Video auf Android und Fold separat belegen.

## Übergabe an Chat 1
Konkrete Methoden-/Transport-Verträge, Commit-SHA, echte Testlogs (Java/Kotlin/Dart/Android), Interaktionsfilm und verbleibende Fähigkeiten. Nur isolierter Branch, keine Änderung an \`main\`, geschützte Schreibtrainer- und Journalmodule unangetastet. 
