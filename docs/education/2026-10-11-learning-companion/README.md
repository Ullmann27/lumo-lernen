# Lumo Lernbegleiter: tatsächlich angeschlossene Aufgaben und Hilfe

Dieser Meilenstein erweitert die vorhandene App, ihren bestehenden Task-Bus, `LumoCompanionHost`, `LumoContextEngine` und die vorhandenen Profil-Leases. Es gibt keine zweite Datenbank, keinen neuen Sprachprovider und keine neue KI-Plattform. Der Android-Test der bereits gebauten Version 1929 bleibt ein getrennter Nachweis: Diese neuen Lern-App-Änderungen sind noch nicht in jener APK enthalten.

## Integrationsbasis

- **Flutter:** eigener Branch `computer/lumo-learning-companion-discovery-2026-10-11`, Basis `d7caa65591c810fa3daf343600d158ebe6fcc9ed`. Enthält die bisherigen PR #261/#262, die nachvollziehbaren PR-263-Cherry-Picks und die bisherigen QA-Reparaturen. Kein Main-Merge.
- **Grafik:** vorhandene Original-Lumo-Illustrationen und das modernisierte Plus-Modul bleiben erhalten. Die Nutzerreferenz `51024.jpg` wird als Referenz, nicht als neues Laufzeitbild, verwendet.
- **Stimme:** vorhandener zentraler `LumoVoice`-Pfad. Sulafat-Originalaufnahmen und Lumo Frei bleiben erhalten. Die Flutter-Interaktionstests verwenden keine hörbare Android-Stimme.
- **Kart:** vorhandene Integration und Godot-Pin `6063f56fd4ff13afef61509f52d1d4fdab012654` bleiben unverändert. Neuere Godot-PRs werden nicht blind übernommen.

## Tatsächliche Änderungen

- **Lernereignisse:** einheitliche Ereignisse für Aufgabenstart, Antwortabgabe, richtige und falsche Antwort, angeforderte und verwendete Hilfe, erneuten Versuch, Abschluss und sichere Kinderfrage. `explore_topic_requested` ist als Ereignistyp vorbereitet; freiwilliges Vorlernen ist durch diesen Meilenstein noch nicht implementiert.
- **Datensparsame Kurzzeitspur:** maximal 24 unveränderliche Metadateneinträge im RAM. Keine Antworttexte, Fragen, Audiodaten, Kinderidentität oder Pointer-Koordinaten werden in die Ereignisspur kopiert. Die Ereignisspur wird nicht an den bestehenden Online-Provider übertragen.
- **Echter Aufgabenkontext:** der Lernbegleiter sieht jetzt auch spezialisierte Aufgaben im Bereich `learn`, nicht nur generische Aufgaben im Bereich `exercises`. Bildschirm- und Profilgeneration müssen zum sichtbaren Kontext passen.
- **Plus bis 10:** falsche Antworten, erneute Versuche, richtige Antworten und sichtbare Hilfen sind tatsächlich mit dem vorhandenen Begleiter verbunden. Die Hilfen verwenden die echten beiden Mengen und bieten auf Wunsch eine alternative Zählstrategie, ohne beim ersten Fehler automatisch die Lösung zu verraten.
- **Bedienung:** „Anderer Tipp“ wechselt die Erklärung an derselben Aufgabe. Die globale Hilfe verlässt die Aufgabe nicht. Der in einer echten 360×800-Testlaufzeit aufgetretene Überlauf der Hilfeschaltflächen ist mit einer vertikalen Anordnung behoben; Schrift und Touchflächen werden nicht verkleinert.
- **Profilsicherheit:** beim Wechsel zu einem anderen Kind wird der alte Aufgabenkontext entfernt. Das alte Plus-Modul kann für das neu ausgewählte Kind weder weiter antworten noch Hilfen oder Belohnungen verbuchen. Bereits akzeptierte Speicheraktionen behalten ihren ursprünglichen Besitzer.
- **Vorhandene Persistenz:** Fehler beim Speichern, Wiederholung ohne doppelte Zählung, atomare Belohnungen, Hintergrundwechsel und der vorhandene vollständige 30-Aufgaben-Ablauf bleiben geschützt.

## Prüfungen und Bildnachweise

Der gemeinsame gezielte Flutter-Lauf besteht mit 114 Tests: 82 bestehende strenge Layout-/Mengenprüfungen, zwei echte Interaktions-Capturetests, drei Plus-Begleitertests, acht vorhandene Persistenztests, fünf Hosttests, sieben bestehende Kontext-/Gesprächstests und sieben neue Ereignis-/Profiltests. Die Analyse der elf geänderten Quell- und Testdateien ergibt keine Probleme. Das ist keine vollständige Flutter-Gesamtsuite und keine Android-Freigabe dieser neuen Funktionen.

Die vorherige Captureprüfung hat den tatsächlichen Überlauf auf schmalen Bildschirmen beanstandet. Nach der Layoutreparatur besteht derselbe Interaktions- und Capturepfad; kein Renderfehler wird unterdrückt und kein Test abgeschwächt. Reine Formatierungsänderungen in der großen bestehenden `LearningContent`-Datei wurden anschließend teilweise mechanisch zurückgenommen, mit identischem kanonischem Code-Fingerabdruck vor und nach der Formatbereinigung. Die verbliebene Formatierung wird nicht als fachliche Leistung gezählt.

Die Aufnahmen stammen aus der echten Flutter-Testlaufzeit mit Originalassets, geladenen Nunito-Schriften und tatsächlichen Fingerdruck-Interaktionen. Smartphone-Ziel ist 360×800; Fold-Ziel ist 2176×1812 bei Dichte 2,25, gerendert als rund 968×806 logische Bildpunkte. Dies sind keine physischen Samsung-, Android- oder Scharnieraufnahmen. Die Stimme ist in diesen Capturetests abgeschaltet.

## Abnahme bleibt offen

Freiwilliges Vorlernen mit eigener Elternfreigabe und getrenntem Fortschritt, geführter Unterricht, vollständige Lehrplanmatrix, fachliche österreichische Pädagogenprüfung, menschliche Hörabnahme, Android-Prüfung dieses neuen Codes und Google-Play-Freigabe sind noch offen. Der vorhandene Plus-Pilot ist keine Behauptung, dass bereits alle spezialisierten Lernmodule gleich tief angeschlossen oder alle Lerninhalte geprüft seien.

Als Nächstes werden Vorlernen und Unterricht auf derselben vorhandenen Fortschrittsarchitektur umgesetzt. Der reguläre Klassenfortschritt, die eingestellte Schulklasse und vorhandene Profile dürfen dabei nicht verändert oder mit höheren Lernstufen vermischt werden.
