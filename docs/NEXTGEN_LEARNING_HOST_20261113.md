# Angeschlossene native Lernwerkstatt

Die aktuelle konkrete Aufgabe kann über **Mit Lumo in 3D ausprobieren** in
der enthaltenen Godot-Engine bearbeitet werden. Die ursprüngliche Lernaufgabe
bleibt bei der Rückkehr erhalten. Geführte Lektionen unterstützen nun alle
sieben vorhandenen Konzepte; der adaptive Lernpfad unterstützt validierte
Addition/Subtraktion bis 20 und bekannte Silbenwörter. Andere Aufgaben werden
nicht durch ein beliebiges 3D-Beispiel ersetzt.

Die neue Szene schreibt selbst keine Bewertung, Kompetenz, Sterne oder
Kinderprofile. Sie meldet nur `illustrated`; Flutter behandelt die angeforderte
Darstellung als Hilfe. Die vorhandenen Schularbeiten-/Test-Grenzen bleiben
geschlossen. Die Child-Key-/Profilgeneration-Prüfungen des Launchers schützen
Start und Rückkehr. Die vorhandenen sieben geführten Konzepte, Offline-Systeme,
Schreibtrainer, Journal und Speicherformate bleiben erhalten.

## Änderungen

- `lib/domain/tutoring/native_learning_activity.dart`: begrenzter Vertrag aus
  den tatsächlichen Operanden/Wörtern des aktuellen Lernschritts.
- `lib/features/tutoring/guided_lesson_screen.dart`: aktuelle Lektion starten,
  Hilfe markieren, anschließend denselben Schritt wieder aufnehmen.
- `lib/features/learning/learning_content.dart`: gleicher Weg aus erlaubten
  adaptiven Übungssitzungen; kein Lösungsweg während Schularbeit oder Test.
- `lib/features/lumo3d/lumo3d_launcher.dart`: vorhandene native Startpipeline,
  gültiges Lerndeskript erforderlich, gesonderte Lern-/Spiel-Zulassung,
  unveränderte Profilsicherung und geprüfter Rücklauf.
- `lib/features/lumo3d/lumo_game_entry_overlay.dart`: Lerntext und vorhandener
  Lernhintergrund statt Rennspiel-Beschriftung beim Übergang.
- `tools/auto_install/MainActivity.kt`, `LumoGameActivity.kt`: typisierte
  Lernoptionen, im selben APK enthaltene Szene, Lebenszyklus und Rückkehr.
- `tools/auto_install/LumoLearningSpeech.kt`, `LumoOfflineSpeechBridge.kt`:
  dieselbe vorhandene lizenzierte Offline-F2-Stimme im isolierten Godot-Prozess;
  echte MediaPlayer-Zustände und Äußerungs-IDs, kein Mikrofon oder neuer
  Cloudanbieter. Bei gewählter Sulafat-Stimme erfolgt kein heimlicher Wechsel.
- `scripts/prepare_android.py`: reproduzierbares Kopieren des neuen Hosts.

Die Godot-Implementierung und Grenzen stehen im anderen Repository in
`docs/NEXTGEN_LEARNING_20261113.md`. Die Originalfigur nutzt echte vorhandene
Clips und neue Blick-/Erklärgesten. Es werden keine neu implementierten
Lippen- oder Blinzelanimationen behauptet.

## Ausgeführte Prüfungen

```
flutter --no-version-check test --no-pub \
  test/tutoring/native_learning_launch_test.dart \
  test/lumo3d_launcher_lifecycle_test.dart \
  test/tutoring/guided_lesson_runtime_test.dart \
  test/tutoring/language_nature_runtime_test.dart \
  test/learning_answer_reward_test.dart \
  test/learning_test_session_result_test.dart
```

**63 Tests bestanden**. Die neue Testdatei prüft echte GuidedLessonScreen- und
LearningContent-Widgets, passende aktuelle Mengen, Aufgabenfortsetzung,
Hilfe-Markierung, Profilwechsel, Lizenz-/Mute-/Voicewahl und gesperrte
Schularbeiten. Der native MethodChannel ist im Widgettest ein Testdouble.

Analyse der fünf geänderten Dart-Produktionsdateien plus Testdatei:
**keine Befunde**. Hostvorbereitung: **4 Python-Tests bestanden** einschließlich
Kopieren der tatsächlichen Kotlin-Quellen in alternative Namespaces und
Erhalt vorhandener Dateien. Echte Logs:
`docs/evidence/nextgen-learning-20261113/`.

Echter Debug-Host-Compile von `2d36496d5ed3684d52dab633b6e9a5d24cef0456`:
Lauf `43351542336`, Job `131643514999` erfolgreich. Die endgültige APK muss
den aktuellen Stand nochmals im Release-Modus inklusive R8 kompilieren.
Hörbare Wiedergabe, finale Rendererbilder, Android-Tour und Fold7-60-FPS-
Messung werden erst nach tatsächlicher Durchführung als bestanden gemeldet.
