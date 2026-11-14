# Vier-gewinnt-Fixture: tatsächlichen Retry vor Lifecyclepause starten

Im tatsächlichen Featurelauf43634307306 auf Host8e64f27c86e1704fa65dfe9ef9c8b2217f9f0a11 bestand die Vollsuite 2.676 Fälle; ein Fall scheiterte, ohne Skips. Der Originalmaschinenstream bindet den Fehler an Test56, Assertion261 im sechsten Fall von connect_four_bot_save_retry_test.dart: held.entered.isCompleted war false. Die anschließende inactive-/Pauseprüfung wurde noch nicht erreicht.

Die Produktionsuhr startet einen aufgehobenen Retry über Timer(Duration.zero). Das alte nackte tester.pump() führt im tatsächlich gepinnten Flutter3.44.9 keine FakeAsync.elapse-Zeitfortschaltung aus. Der enge Testnachtrag pumpt deshalb eine Millisekunde, bevor er die bereits vorhandene Eintrittsassertion verlangt. Zusätzlich prüft er ein weiterhin ungelöstes ACK-Gate, null Sterne und keinen Ergebnisdialog. Erst danach folgt die unveränderte eigentliche Lifecycleprüfung. Ein finally gibt ein gegebenenfalls noch gehaltenes Gate frei, stellt resumed her und räumt innerhalb derselben Testzone auf.

Die ersten fünf Fälle und sämtliche Helpers bleiben bytegleich; alle elf alten Assertions des sechsten Falls bleiben in ihrer Reihenfolge erhalten. Keine Produktdatei wird verändert. Der bestehende frühe CI-Aufruf nimmt zusätzlich genau diese sechs Fälle auf; der komplette Flutterlauf, weitere Gates, Budgets und Artefakte bleiben unverändert. Dadurch wird ein erneuter Fehler dieses konkreten Pfades früh sichtbar.

Die unabhängige Review bindet den vollständigen Originalstream, die Auswahlereignisse, die beiden aktuellen Gitbaselines, die gepinnte Flutter-Implementierung und den vollständigen Diff. Kein lokaler Dart-/Flutterlauf und kein neuer PASS werden behauptet. Die neue tatsächliche CI muss den Fall schließen.
