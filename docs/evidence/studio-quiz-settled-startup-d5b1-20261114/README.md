# Quiz: aktuellen Startzustand vor einer Resume-Eingabe prüfen

## Tatsächlicher Ausgangsfehler

Native `d5b1ed3749e332e996fa21a41d88325fad266553` und Host `ddc9d89ef1bb6fc37315fd4aff0da166ce213b67` wurden im Paarlauf `43601103353`, Job `132465820577`, zusammen ausgeführt. Der Job scheiterte an `Bounded real swipe exposes ResumeQuiz`. Das Originalartefakt `14116468839` hat 2.447.881 Bytes und SHA256 `5d0eb24a8cd4ce232fbd2c036c63234d6847c72bbb8c1897cdd77293f11a1f95`; alle 43 ZIP-Mitglieder wurden auf CRC geprüft. Das vollständige Original liegt unverändert im benachbarten Diagnosepaket `qa/studio-quiz-native-d5b1-ci-20261114/`.

Das Originaljournal enthält zwölf Wischversuche, den ersten bereits in Frame 0 mit identischem Anfangs- und Endpunkt. Es enthält keine übermittelte Quiz-Anfrage. Der abschließend gespeicherte echte Dart-Zustand ist `paused=false`, `canSelect=true`, `revision=2`, `ack=0`. Er ist als unveränderte Regressionseingabe enthalten. Ein anfänglicher Rohzustand wurde im CI-Artefakt nicht gesichert. Der lokale Gegenfall leitet seine anfängliche Pause ausdrücklich aus der gelesenen Produktionslogik `paused = !_active || _paused` bei anfangs inaktivem Lease ab. Er behauptet keinen zusätzlich beobachteten Anfangsdatensatz.

Die Ursache im Prüfer ist seine Entscheidung vor dem ersten abgeschlossenen Layout: Nach dem ersten frischen Lifecycle-Poll kann die ungelatchte Anfangspause ohne Resume-Anfrage verschwinden. Der bisherige Prüfer hielt während seiner gesamten Suche an der dann versteckten Schaltfläche fest.

## Enger Quellumfang

Genau `scripts/tests/quiz_studio_runtime.gd` wird geändert. Die Spielfigur, Szene, Spielregeln, Dart-Sitzung, Laufzeitanimationen und Speicherschnittstellen bleiben unverändert. Die veröffentlichten Baselinebytes wurden frisch gelesen und sind im Paket gebunden.

Der Start wartet auf einen tatsächlichen `settled`-Layoutbericht desselben Prozesses, Tokens, Fensters und vollständigen aktuellen Zustands. Eine bereits aktive Sitzung kann ohne zusätzliche Eingabe weitergehen. Eine weiterhin pausierte Sitzung braucht eine sichtbare, vollständig exponierte Schaltfläche mit mindestens 48 dp, einen echten Touch und anschließend den positiven ACK derselben Runde. Ein Zustandswechsel während der Suche oder vor dem Loslassen bricht nur diese noch nicht gesendete Eingabe mit einem echten abgebrochenen Pointer ab. Eine bereits gesendete Anfrage wird anschließend zwingend geprüft. Frühere Fehler werden weder entfernt noch umgedeutet.

Die optionalen Eingabeguards teilen das ursprüngliche 15-Sekunden-Startbudget. Normale spätere Spielaktionen benutzen dieselben vorhandenen Wisch- und Touchfolgen ohne diesen Startguard. Alle Funktionen außer den drei Anschlussfunktionen `_swipe_to`, `_tap` und `_run` bleiben im vollständigen Funktionskörper identisch; sechs eng begrenzte Hilfsfunktionen und ein Ergebnis-Enum kommen hinzu. Insbesondere die vollständigen Fixture- und 20-Fragen-Authority-Verträge bleiben unverändert. Das Dart-Limit von 300 Sekunden und die echte 2.500-ms-Lifecycle-Grenze werden nicht geändert.

## Tatsächlich ausgeführte Gegenprüfungen

Die Tests verwenden die produktive Godot-Szene und echte ScreenTouch-/ScreenDrag-Ereignisse mit einem ausdrücklich synthetischen Lifecycle-/ACK-Transport. Es lief hier kein Dart-Prozess und kein Androidgerät; es wurden keine neuen Rendererbilder erzeugt.

| Fall | Tatsächliches Ergebnis |
| --- | --- |
| Unveränderte d5b1-QA, natürliche Aktivierung nach erstem Frame | Exit 1, ursprünglicher Resume-Wischfehler reproduziert |
| Neue QA, natürliche Aktivierung nach erstem Frame | Exit 0, 53 Prüfungen, keine Eingabe/Anfrage |
| Bereits aktiver Start | Exit 0, 52 Prüfungen, keine Eingabe/Anfrage |
| Aktivierung während einer tatsächlich nötigen Wischsuche bei 640 × 240 | Exit 0, 57 Prüfungen, Pointer abgebrochen, keine Anfrage |
| Aktivierung nach Drücken, vor Loslassen des Resume-Knopfs | Exit 0, 57 Prüfungen, Pointer abgebrochen, keine Anfrage |
| Bleibende Pause, anschließender positiver Fixture-ACK | Exit 0, 58 Prüfungen, genau eine echte Resume-Anfrage |
| Bleibende Pause ohne ACK | Erwartetes Exit 1 am unveränderten ACK-Gate, eine Anfrage, keine Fortsetzung |
| Vollständige bestehende UI-Fixture | Exit 0, 138 Prüfungen, bestehende sieben Zustandssidecars |

Die Laufzeiten, vollständigen Rohlogs, Reports und Vorher-/Nachher-Quellhashes stehen in `evidence/final-*`. Alle gemessenen Quellbytes blieben während jedes finalen Laufs identisch. Die Prozessdauer des fehlenden ACKs enthält zusätzlich die Modell- und Testinitialisierung; sie ist kein Bildratenmaß.

Zwei lokale Zwischenfehler bleiben ausdrücklich erhalten: Der erste Layoutvergleich behandelte JSON-Zahlen fälschlich wie typidentische Godot-Arrays/Dictionaries. Ein direkter Godot-4.6.3-Befund zeigte die Typabweichung; beide Seiten werden jetzt vollständig durch dieselbe JSON-Darstellung verglichen. Außerdem benötigte der erste Wisch-Abbruchgegenfall bei 960 × 540 tatsächlich keinen Wischer. Nur dieser Test verwendet jetzt einen realen kleineren Viewport, damit er den vorgesehenen Abbruchpfad tatsächlich erreicht. Die unveränderten Fehlerlogs und vorherigen Testfassungen bleiben im Evidenzsatz.

## Abnahmegrenze und Übergabe

Der neue Source-Blob wurde unter `59cf4a16d2e53b65a97277574c6866db5a5929fb` angelegt und vollständig UTF-8-identisch zurückgelesen. SHA256: `8df756dee8e5daee17a88a8899d6189aba8acd8b9148ca3cd0c5e606fdd1d0cd`, 33.632 Bytes. Das ist ausschließlich eine Quellenübergabe; es wurden keine Trees, Commits oder Git-Refs verändert.

Der fehlgeschlagene d5b1-Lauf bleibt fehlgeschlagen. Ein neuer echter Dart/Godot-Paarlauf muss den anschließenden vollständigen 20-Fragen-, Save-, Pause-/Resume- und Einmal-Auszahlungsvertrag noch erfolgreich ausführen. Dieses Paket erteilt keine Android-, Geräte-, FPS- oder vollständige Produktfreigabe.
