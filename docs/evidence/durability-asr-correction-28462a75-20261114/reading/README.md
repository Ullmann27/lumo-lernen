# ASR-Beobachtungen und Elternbericht – enger Fix auf b721

**Stand: 14. November 2026. Vorbereitet und statisch geprüft; die neuen Dart-Tests wurden nicht ausgeführt.**

## Quellen und Umfang

Basis ist [Host b7210db3f53361987fd33592de438fd7984d991a](https://github.com/Ullmann27/lumo-lernen/commit/b7210db3f53361987fd33592de438fd7984d991a), Tree `c65558a13e4dd2950eda7a685583e5484d9b9959`. `original-source-binding.json` bindet 19 vollständig gelesene Originaldateien mit Gitblob, SHA256 und Größe.

Das Quellmanifest enthält genau zwei Dateien:

- `lib/domain/analysis/daily_recommendation_engine.dart`: ein Produktdelta in den beiden vorhandenen Bericht-/Empfehlungsengines.
- `test/reading_asr_evidence_boundary_test.dart`: zehn vorbereitete Regressionen.

Die öffentliche Signatur mit `readingSummaries` bleibt kompatibel. Die Rohdaten werden weiter gespeichert; Schema, Profile, Schreibtrainer, Journal, Mikrofon-, Abbruch- und Lernantwortpfade werden durch dieses Paket nicht verändert.

## Belegter Fehler und produktive Korrektur

[ReadingContent](https://github.com/Ullmann27/lumo-lernen/blob/b7210db3f53361987fd33592de438fd7984d991a/lib/features/reading/reading_content.dart) schreibt bei Spracherkennungsabweichungen bereits keinen negativen SkillRecord: `_logReadingAttempt` akzeptiert nur eine tatsächlich akzeptierte positive Antwort. Der zweite Pfad speichert trotzdem Textabgleich, Hilfen und mutmaßliche Problemwörter in [ReadingProgressRepository](https://github.com/Ullmann27/lumo-lernen/blob/b7210db3f53361987fd33592de438fd7984d991a/lib/core/reading_progress_repository.dart). Dessen `SharedPreferences.getInstance()`-Eintrag `lumo_reading_sessions_v1` enthält keine Bestätigung oder Providerfehler-/Confidence-Herkunft. Beim Aktualisieren bleiben frühere Wörter durch eine Mengenvereinigung erhalten.

[ParentReportCard](https://github.com/Ullmann27/lumo-lernen/blob/b7210db3f53361987fd33592de438fd7984d991a/lib/features/settings/parent_report_card.dart) lädt diese Liste ohne Kindfilter und reicht sie an `ParentReportEngine` weiter. Der bisherige Enginecode machte daraus unter anderem „Problemwoerter“, „Lumo-Hilfen benoetigt“, `weaknesses`, `errorPatterns` und eine angebliche prozentuelle „Lesesicherheit“. Die Oberfläche zeigt `weaknesses` tatsächlich als „Förderbedarf“.

Der Fix lässt **alle** Summary-abgeleiteten Aussagen im Elternbericht weg, auch neutrale Zählungen: Die aktuelle Signatur besitzt keine belastbare Bindung der unfiltrierten Liste an das gerade geöffnete Kind. Lesen und Deutsch werden aus den bereits übergebenen SkillRecords ausgewertet. Wirklich bewertete Verständnisfehler bleiben übungsrelevant; akzeptierte positive Lernantworten und deren gespeicherte Zähler bleiben erhalten. Fehlende Leserunden werden nicht mehr als Leseschwäche ausgegeben.

Auch `DailyRecommendationEngine` leitet weder Problemwörter, Defizitprioritäten noch Prozenturteile aus der ASR-Liste ab. Eine kurze Leserunde bleibt eine neutrale Routine. Die vorhandenen SkillRecord-basierten Förder- und Erfolgsblöcke bleiben erhalten. Ein tatsächlicher UI-Aufrufer dieser öffentlichen Engine wurde im engen Ausgangsaudit nicht nachgewiesen; der produktive ParentReportCard-Aufruf ist dagegen direkt gebunden.

## Vorbereitete Regressionen und Erhalt der Daten

Vier Fälle variieren ausschließlich unbestätigte ASR-Daten: initialer Nullwert, niedriger Textabgleich, wiederholte Abweichungen/Hilfen und perfekter Textabgleich ohne bewertete Antworten. Sie dürfen Bericht und Tagesplan gegenüber fehlenden ASR-Beobachtungen nicht verändern.

Weitere sechs Fälle prüfen: fremdes Profil, positive akzeptierte SkillRecords, echte unabhängige Verständnisfehler, begleitete Übung ohne unabhängige Evidenz, unverändertes Lesen des historischen SharedPreferences-JSON und ein im realen Repository weiterhin gespeichertes altes Problemwort nach einer späteren akzeptierten Antwort. Die Tests führen keine Migration durch und erfinden keine Provider-Confidence-Daten. Sie verwenden synthetische Daten und den bestehenden lokalen Repository-Code.

Die 19 nach Namen ausgewählten Bestands-Testdateien sind in `existing-test-inventory.json` gebunden. Darin fand sich keine erwartete alte ASR-Prozent-/Problemwortaussage. Das ist keine behauptete Volltextinventur sämtlicher Tests. Keine bestehende Assertion wurde angepasst.

Für die spätere CI ist beispielsweise der gezielte Aufruf vorgesehen:

```sh
flutter test --no-pub test/reading_asr_evidence_boundary_test.dart test/reading_buddy_assessment_test.dart test/lumo_speech_privacy_test.dart test/story_entry_navigation_test.dart test/parents/parent_report_request_privacy_test.dart
```

**Dieser Aufruf wurde hier nicht ausgeführt.** Auch kein `dart format`, `flutter` oder `pub get` wurde lokal aufgerufen. Die bestehende b721-Gesamtsuite mit 2608/0/0 ist ausschließlich ein Beleg für die unveränderte Basis; sie bestätigt diesen neuen Fix nicht.

## Grenzen

Der Listener reicht weiterhin nur Text weiter. Providerfehler mit schon vorhandenem Teiltext können diesen Text finalisieren; ein echter Cancel verwirft ihn. Provider-Confidence wird nicht übertragen. Das Paket führt weder eine neue Zuverlässigkeitsschwelle noch eine Diagnose ein und behauptet keine verbesserte Spracherkennung. Die beiden gelesenen Leseoberflächen besitzen keine manuelle Transkriptkorrektur; erneutes Lesen und explizite Verständnisantworten sind getrennte Vorgänge.

Die vollständige Ausgangsbeobachtung einschließlich direkter und sekundärer Pfade liegt unverändert in `initial-readonly-audit.json`. Die neue Änderung verhindert die automatische negative Deutung dieser Beobachtungen in den beiden Engines; eine reale CI-Ausführung und spätere Geräteprüfung bleiben offen.
