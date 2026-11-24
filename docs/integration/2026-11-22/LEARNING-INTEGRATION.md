# Lern-, Dialog- und Spieleintegration am 22.11.2026

## Geprüfte Ausgangspunkte

- Flutter: `52c2c57016813566bc258df35ccba1d14e9009b2`.
- Godot: `25fc4ff1f43c0adeb2c56b67ad4a9611922aac8a`.
- Arbeitszweig in beiden Repositories: `integration/lumo-complete-20261122`.
- Der geschützte Hauptzweig wird durch diese Integration nicht geändert.

Eine offene Pull Request oder eine abweichende Git-Historie ist allein kein Nachweis einer fehlenden Funktion. Die Entscheidungen unten beruhen auf Vorfahrprüfung, Patchvergleich und den tatsächlich aufgerufenen Implementierungen.

## Entscheidungen zu vorhandenen Entwicklungen

| Entwicklung | Nachweis und Entscheidung |
| --- | --- |
| Chat2, Nextgen-Lernen | [`7f555aa6d2e8fe1e2013a3f7c879f4566a800a12`](https://github.com/Ullmann27/lumo-lernen/commit/7f555aa6d2e8fe1e2013a3f7c879f4566a800a12) ist ein echter Vorfahr der Flutter-Ausgangsbasis. Der Legacy-Aufgabenadapter erhält vollständige Dezimal-/Zeitangaben, statt Ziffern aus beliebigen Zeichenfolgen zusammenzusetzen. Keine erneute Übernahme des alten Zweigs. |
| Neuer Sprachzweig | `agent/sprache` bei `42bbb2fa74ebd941b44964954c24428b141602aa`: `git log --cherry-pick --right-only --no-merges BASE...HEAD` ist leer. Die zentralen Dialog-/Agent-Dateien entsprechen zudem unmittelbar der Ausgangsbasis. Keine fehlenden Nicht-Merge-Patches. |
| Neuer 3D-Nachhilfezweig | `agent/tutor3d` bei `9b49a2d65b898230acac80a70e54928f0f351555`: derselbe Patchvergleich ist leer. `_openNachhilfe3D` ist im Flutter-UI verdrahtet, bindet Aufgaben- und Profilkontext und verarbeitet die zurückgegebene Zusammenfassung. Der getrennt gefundene Android-Zulassungsfehler wird unten behoben; die vorhandene Flutter-Verdrahtung allein belegte keinen erfolgreichen Android-Start. Keine erneute Übernahme des alten Zweigs. |
| Frühere Chat4-Architektur | [`9df3cef1dbea915d22b8913c3f8016e6316100ec`](https://github.com/Ullmann27/lumo-lernen/commit/9df3cef1dbea915d22b8913c3f8016e6316100ec) und `4fa88ee2635d0a7f56161c9778040aca268c1e99` enthalten eine ältere parallele Dialogarchitektur. Die aktuelle Aufgabenbus-/Konversationsarchitektur ist maßgeblich. Fehlende Formulierungen und begrenzte Erklärvarianten werden selektiv ergänzt. |
| Englische Aussprache im nativen Lernraum | Die Ausgangsbasis verwendete auch für englische Wörter die deutsche Synthese. Die produktiven Änderungen aus [`3a5b2241b7a329a8b36ee655bceedd874ae50268`](https://github.com/Ullmann27/lumo-lernen/commit/3a5b2241b7a329a8b36ee655bceedd874ae50268) wurden selektiv auf die aktuelle Fehlerdiagnostik, Lebenszyklussteuerung und Sprechgeschwindigkeit übertragen. Der ursprüngliche Wortumfang wurde an den aktuellen Katalog mit 20 Wörtern angepasst. |
| Zusätzliche Kartfahrer | Flutter und der Android-Host führen keine zweite Fahrer-Whitelist. Der Godot-Katalog entscheidet über Auswahl und Start. Die Integration von `badger` und `cat` braucht daher keine zusätzliche Flutter-Fahrerliste. |

## Umgesetzte Ergänzungen

### Android-Zulassung für Nachhilfe und Holo-Lernräume

Die Ausgangsbasis bot die 3D-Nachhilfe sowie Holo-Mathe- und Deutschaufgaben im Flutter-UI an, aber `MainActivity.launchGame` wies deren tatsächliche Deskriptoren zurück. `prepare_android.py` kopiert diese Vorlage unverändert und ergänzte die drei fehlenden Werte nicht. Die Kind-Freigabe enthält jetzt zusätzlich `tutor`, `holo_word_problem` und `holo_sentence`; `holo_lesson` ist lediglich ein Godot-Szenenname und kein versendeter Kind-Wert.

Der vorhandene Generatorvertrag wurde auf die indirekt aus den Holo-/Vokabelkatalogen übernommenen Deskriptoren erweitert. Vor der Reparatur scheiterte er exakt an den drei genannten Werten, danach besteht er. Er erfasst alle 15 aktuell angebotenen Lern-Kinds. Die zusätzliche historische Freigabe für `task_card` bleibt erhalten.

Die Godot-Seite besaß bereits eigene strenge Tutor- und Holo-Planprüfungen. Ein neuer Lauf durch den tatsächlichen Produktions-Boot prüft jetzt die normale Lernroute und alle drei zuvor blockierten Kinds: richtige Szenenressource, Titel, unveränderte Aufgabe, Profil und Host-Session. Unvollständige Pläne und unbekannte Kinds werden weiterhin abgelehnt. Die Nachhilfe verwendet bereits das gemeinsame `holo`-Zusammenfassungsformat für ihre Rückgabe an Android und Flutter.

### Gebundene englische Aussprache

Der native Lernraum spricht zuerst das vom Host geprüfte aktuelle englische Wort mit dem englischen Sprachkennzeichen, danach die deutsche Erklärung. Beide Teile verwenden das vorhandene lokale Supertonic-3-Modell und das bestehende F2-Stimmprofil. Die PCM-Teile werden mit 250 ms Abstand zu einer einzigen WAV-Datei verbunden; ein MediaPlayer und eine daraus abgeleitete Hüllkurve steuern die tatsächliche Wiedergabe.

Die bestehende deutschsprachige Synthese bleibt auf ihrem bisherigen Pfad. Eine native Anfrage kann das beim Start gebundene englische Wort, seine Bedeutung oder die drei angezeigten Objekte nicht ersetzen. Akzeptiert werden genau die 20 Wörter aus `NativeEnglishVocabulary.meanings`, einschließlich der bestehenden deutschen Aliase für `pen` und `desk`. Die Formateigenschaften und die kombinierte 30-Sekunden-Grenze werden geprüft. Abbruch, pausierte Szene, veraltete Rückrufe und falsche Ergebnisidentität verhindern Wiedergabe.

### Stimme der vorhandenen Dorf-Einführung

`MainActivity` übermittelt die Sprachfreigaben auch für `settlement`, `LumoGameActivity` erstellt dafür bereits einen Sprecher, und `build_village_voice.gd` sendet die gebundenen Einführungssätze. Der Sprecher selbst ließ jedoch nur `learning` und `build` zu. Der neue Dorfvertrag reproduzierte die Ablehnung eines gültigen Auftrags.

`LumoLearningSpeech` akzeptiert nun zusätzlich den bereits ausdrücklich gewählten Dorfmodus, und zwar nur gemeinsam mit `livingVillage=true`, `settlementMode=settlement` sowie beiden bestehenden Eltern-/Lizenzfreigaben. Die tatsächliche Synthese bleibt deutschsprachig. Der enge JVM-Vertrag prüft 19 Eigenschaften: Syntheseaufruf, genau einen Player, gemessene Hüllkurve, Abbruch beim Verlassen, ausbleibende Wiederbelebung durch späte Rückrufe sowie Ablehnung fehlender Freigaben oder einer falschen Moduswahl.

### Chat4 auf der aktuellen Dialogarchitektur

Die Ergänzungen erlauben „Nicht so schnell bitte“, eine andere Erklärung des sichtbaren Zehnerfeldbeispiels und die Nachfrage nach dessen zweitem Schritt. „Ich habe gesagt …“ erzeugt einen bearbeitbaren Antwortvorschlag. Die Mathematik wird aus dem aktuellen begrenzten Beispiel berechnet; die neue Variante nennt nicht automatisch dessen Endergebnis. Aufgabenberechtigungen und die bestehende Bestätigung vor einer Bewertung bleiben maßgeblich.

Auch die vorhandene native Java-Dialoglogik erhält die begrenzten Erklärvarianten. Unbenannte Verweise wie „die zwei da“ führen zu einer Rückfrage. Der ausdrückliche Wunsch, allein zu arbeiten, beendet die Erzählung; „Ich kann es nicht allein“ wird nicht als solcher Wunsch behandelt. Keine dieser Ergänzungen schreibt Lernpunkte, Sterne oder Antworten.

## Behebung des Lumo-Lauf-Buildblockers

Der zuvor fehlgeschlagene Test berechnete Sprungweite aus Bildschirmframes und unskalierter Geschwindigkeit. Die reale Bewegung verwendet jedoch `ROAD_TIME_SCALE = 1.5`. Bei derselben ausgeführten Sprungbewegung ergeben 35 Bildschirmframes deshalb 7,583 m in der alten Schätzung, während der tatsächliche Spielerfortschritt 11,375 m beträgt.

`lumo_run_regression.gd` misst nun die reale Änderung von `player.s`. Die bestehende Anforderung von mehr als 8 m bleibt bestehen; zusätzlich wird die erfolgte Landung geprüft. Sprungphysik und Schwellenwert wurden nicht abgeschwächt. Der Messunterschied wurde sowohl mit Godot 4.7.2 als auch mit der Projektversion 4.6.3 reproduziert; die abschließenden Projektprüfungen verwenden 4.6.3.

## Durchgeführte Prüfungen

| Prüfung | Ergebnis und Reichweite |
| --- | --- |
| Generierter Android-Host | `test_studio_learning_contract.py` bestanden. Der reale `prepare_android`-Ausgang lässt alle 15 von Flutter angebotenen Lern-Kinds zu. Rot/Grün-Nachweis für die drei zuvor abgewiesenen Kinds. Kein Android-IPC-Lauf. |
| `native_learning_boot_regression.gd` | 41 Prüfungen bestanden, Exit 0, Godot 4.6.3. Reale Produktions-Boot-Szene und Ressourcenauflösung; gültige und unvollständige Tutor-/Holo-Pläne sowie Aufgaben-/Sessionerhalt. |
| `learning_tutor_regression.gd --part=validation,invalid,return,voice` | 107 Prüfungen, 0 Fehler, Exit 0, Godot 4.6.3. Darunter 24/24 abgelehnte fehlerhafte Pläne, Rückkehr nach eigenständigem Üben und die bestehenden Sprach-/Abbruchverträge. Dies ist der genannte gezielte Teillauf. |
| Java-Synthesevertrag | 11 Tests bestanden. Der vollständige produktive Java-Engine-Code läuft mit synthetischer ONNX-Grenze. Geprüft werden Sprachkennzeichen, PCM-Verbindung, Format-/Längengrenzen und Abbruchpunkte. |
| Kotlin-Sprache und Lebenszyklus | 11 Tests bestanden. Die Englischbindung umfasst 66 Assertions für alle 20 Wörter und die zusätzlichen deutschen Aliase; weitere Fälle prüfen fehlerhafte Deskriptoren, spätere Rückrufe, Ergebnisidentität, Elternfreigaben und genau einen Player. Der zusätzliche Dorfvertrag umfasst 19 Assertions. |
| Nativer Dialog | Ein JVM-Test mit 34 Assertions bestanden. Der zusätzliche Test für eine alternative Erklärung scheiterte zunächst am unveränderten Produktivcode und besteht nach der Ergänzung. |
| Gemeinsamer abschließender nativer Vertragslauf | 24 Tests (23 JVM-Tests und ein Android-Generatorvertrag), 8,462 s, Exit 0. Offizielles JDK 17.0.21.1+2; Kotlin-Bibliotheken aus dem verifizierten Gradle 9.1.0. |
| Flutter-Kernpaket plus Chat2/Coach | 216 Tests aus 27 Dateien bestanden, Exit 0, 37,842 s, Nebenläufigkeit 2. Das gesamte Kernpaket mit Memory, Quiz, Lernstart, Englisch, Holo, Nachhilfe und Dialog sowie sechs zusätzliche Nextgen-/Coach-Dateien. Die veraltete Erwartung eines fehlenden 3D-Knopfs wurde durch die Prüfung des verdrahteten Knopfs ersetzt; Rückkehr, Originalaufgabe und XP bleiben geprüft. Der gesonderte 3D-Vertrag prüft den echten Dart-Launch und die einmalige Ergebnisverarbeitung an einer explizit simulierten Android-Kanalgrenze. |
| `lumo_run_regression.gd` | 510 Prüfungen bestanden, Exit 0, Godot 4.6.3. Einschließlich aller 30 Dschungel-Läufe. |
| `lumo_run_stunt_relay_regression.gd` | Alle drei Parcours mit realen Szenen und Eingaben bestanden, Exit 0, Godot 4.6.3. |
| `learning_holo_lesson_regression.gd` | 1.328 Prüfungen, 0 Fehler, Exit 0, Godot 4.6.3. Beim Beenden meldet Godot weiterhin `ObjectDB instances leaked at exit`; diese Warnung wird nicht als behoben ausgegeben. |

Die JVM-Prüfungen belegen keine tatsächliche Android-Audiowiedergabe und keine Hörqualität. Die Godot-Prüfungen laufen ohne Android-Gerät. Ergebnisse der neuen APK, der Android-Emulator-Tour und eines tatsächlichen Fold7 sind gesonderte Nachweise; sie werden durch diese Tests nicht vorweggenommen.

Die endgültigen APK-Nachweise werden im Integrations- und Buildbericht erfasst. Ein abgebrochener erster Flutter-Aufruf vor der Paketauflösung führte keine Tests aus und wird nicht als Produktfehler oder bestandenes Ergebnis gezählt.
