# Reine Pfadtrennung der Sprachverträge

Dieser abgeleitete Freeze ersetzt nur die beiden bisher unveröffentlichten Zielpfade der Test-Driver: `scripts/tests/test_english_lesson_speech.py` und `scripts/tests/test_learning_english_speech_lifecycle.py` werden ausschließlich unter `scripts/speech_contracts/` integriert. Es wird kein `__init__.py` angelegt. Die ursprüngliche allgemeine Discovery unter `scripts/tests` erreicht diesen benachbarten Ordner nicht.

Alle zehn Datei-Bytes und Gitblobs bleiben identisch zum Freeze `465eb8e570ef8ca79ef862a635ac526188ccc4eef875573e59deef998198efab`: drei Produktdateien, zwei Driver und fünf Fixtures. Der historische Freeze und seine alten lokalen Dateien bleiben unverändert als Nachweis. Root muss die zwei alten Zielpfade bei der Erstintegration weglassen.

`ROOT = Path(__file__).resolve().parents[2]` zeigt nach beiden Pfadzuordnungen auf dieselbe Repositorywurzel. Der Fixturepfad bleibt `scripts/tests/fixtures/learning_english_speech/`; die einzige originale WAV bleibt `apfel-original.wav`.

Alle 19 Fälle werden ausschließlich vom separaten strikten Speech-Runner explizit aufgerufen: 11 Javafälle und 8 Kotlinfälle, `REQUIRE_ALL_TESTS=true`, keine Skips. Der Runner gehört B. Für diesen reinen Pfadnachtrag wurden keine Java-/Kotlin-/Androidtests wiederholt; die statisch gezählten Methoden sind keine neuen Ausführungsergebnisse. Die bisherigen 11/11 mit 103 Javaassertions bleiben an identische Bytes gebunden. Kotlin und tatsächlicher Android-Hostcompile bleiben verpflichtende CI-Grenzen.

`confirmed-source-tree-inputs.json` verwendet nur bereits zuvor erfolgreich erstellte Gitblobs. Für die Pfadtrennung sind keine neuen Sourceblobs, Trees, Commits oder Refänderungen ausgeführt worden.
