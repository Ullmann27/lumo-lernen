# Angeschlossene native Lernwerkstatt

Die aktuelle konkrete Aufgabe kann über **Mit Lumo in 3D ausprobieren** in
der enthaltenen Godot-Engine bearbeitet werden. Die ursprüngliche Lernaufgabe
bleibt bei der Rückkehr erhalten. Geführte Lektionen unterstützen nun alle
sieben vorhandenen Konzepte; der adaptive Lernpfad unterstützt validierte
Addition/Subtraktion bis 20, tatsächliche Hunderterübergänge mit ganzen Zehnern
und bekannte Silbenwörter. Andere Aufgaben werden
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
- `lib/app/app_state.dart`: begleitete Fehlversuche behalten Rückmeldung und
  Versuchsanzahl, erhöhen aber nicht den alten Schwächenzähler. Der Caller
  erstellt dafür auch keine Fehlerklassifikation. Die tatsächliche Antwort
  bleibt im vorhandenen Protokoll mit `hintUsed: true` erhalten.
- `lib/core/error_breakdown_repository.dart`: neue Diagnosezählungen werden
  unter dem SHA-256 der tatsächlich erfassten Student-ID gespeichert. Der
  vor dem ersten `await` festgehaltene Profileigentümer bleibt bei verzögerten
  Schreibvorgängen erhalten. Alte Name/Klasse-Schlüssel werden weder verändert
  noch einem Kind zugerechnet. Unbekannte neue Datenformate bleiben bytegenau
  erhalten; ein Elternreset löscht nur das Histogramm des gewählten Kindes.
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
  test/learning_test_session_result_test.dart \
  test/tutoring/learning_profile_boundaries_test.dart
```

**71 Tests bestanden**, davon zehn in der neuen nativen Lernstart-Datei und
sieben in der Profilgrenzen-Datei.
Die neue Testdatei prüft echte GuidedLessonScreen- und
LearningContent-Widgets, passende aktuelle Mengen, Aufgabenfortsetzung,
Hilfe-Markierung, Profilwechsel, Lizenz-/Mute-/Voicewahl und gesperrte
Schularbeiten. Echte falsche Antworttaps nach der 3D-Hilfe belegen, dass
Versuchsanzahl und persistiertes Antwortprotokoll erhalten bleiben, während
`weakSkills` und vorhandenes Fehlerhistogramm nicht verändert werden. Der
Kontrollfall Schularbeit speichert einen selbstständigen Fehler weiterhin.
Der native MethodChannel ist im Widgettest ein Testdouble.

Die zusätzlichen echten Widgetprüfungen verwenden zwei unterschiedliche
Student-IDs bei identischem Namen und gleicher Klasse. Tatsächliche falsche
Antworttaps erzeugen getrennte Histogrameinträge und Antwortprotokolle, auch
wenn die erste Identitätsauflösung erst nach dem zweiten Kind zurückkehrt.
Eine verspätete KI-Antwort des ersten Kindes wird verworfen. Der lokale
Übungs-/Hilfestand beginnt beim neuen Kind frisch. Alte Schreib-, Überspring-,
Übungs- und Form-Callbacks werden vor und nach dem nächsten Frame abgewiesen.
Ein weiterer Test widerruft während einer offenen KI-Anfrage die
Elternfreigabe bei unverändertem Task: Die Antwort wird nicht übernommen,
der reale lokale Tipp bleibt erhalten. Der KI-Transport ist dabei ein
kontrolliertes Testdouble; es erfolgt kein Cloudaufruf.

Nur diese Laufzeitgrenzen und das neue Fehlerhistogramm wurden auf die
eindeutige Identität umgestellt. Ältere Aufgaben-/KI-Caches und sonstige
Name/Klasse-Schlüssel werden hier ausdrücklich nicht migriert. Die übrigen
vorhandenen Daten bleiben unberührt.

Analyse der sieben geänderten Dart-Produktionsdateien plus zwei Testdateien:
**keine Befunde**. Hostvorbereitung: **4 Python-Tests bestanden** einschließlich
Kopieren der tatsächlichen Kotlin-Quellen in alternative Namespaces und
Erhalt vorhandener Dateien. Echte Logs:
`docs/evidence/nextgen-learning-20261113/`.

Echter Debug-Host-Compile von `2d36496d5ed3684d52dab633b6e9a5d24cef0456`:
Lauf `43351542336`, Job `131643514999` erfolgreich. Die endgültige APK muss
den aktuellen Stand nochmals im Release-Modus inklusive R8 kompilieren.
Die abschließenden Profilkorrekturen sind im Host-Checkpoint
`e2980be9c73f86e104af546c38c8c52db6bc922b` gesichert. Das ist keine
Releasefreigabe.

Alle 21 echten Lernrendererbilder des nativen Commits
`c5c71145ffaa9ca90b501c5020967b8d5062c387` wurden tatsächlich geöffnet und
manuell geprüft. Der fokussierte CI-Job `131667187053` war erfolgreich.
Die konkreten vorherigen Silben-, Bruch-, Hunderter- und Phone-Sichtfehler
sind darin behoben; SHA-256 und Bildbefunde stehen in
`docs/evidence/nextgen-learning-20261113/renderer-review.json`.
Eine endgültige APK, hörbare Wiedergabe, Android-Tour und Fold7-60-FPS-
Messung sind damit noch nicht nachgewiesen.
