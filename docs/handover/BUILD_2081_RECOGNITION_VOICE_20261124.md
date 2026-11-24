# Build 2081 – direkte Spracheingabe bei „Aufgabe erkennen“

## Auftrag, Quelle und geprüfte Grenze

Der ergänzende, rein lesende Abgleich älterer Projektquellen fand einen konkreten
noch nicht übernommenen Eingabeweg: Im HTML-Prototyp
`05-lumo_lernen_agent_playready_prototype_app.html` ist `recognizeVoiceBtn` mit
`recognizeVoice()` verbunden. Ein endgültiges Sprachergebnis wird in
`recognizeInput` übernommen und durch `recognizeNow()` geprüft.

SHA-256 dieser tatsächlich gelesenen HTML-Datei:
`d3f679e808199467124a4726150700266c80600f92ebd1b231071fd71ef91f24`.

Ausgangspunkt dieses Patches ist exakt Flutter
`5c086af2fa967f743d5801b4be23c15efbbb88ba`, Baum
`45bca796b1b6c05908aad39b1536a485e91102f3`.
Der laufende Zwischenbau wurde durch diesen isolierten Patch nicht verändert.
Die Gesamtintegration, neue Bauanforderung und Veröffentlichung gehören zum
anschließenden, separat geprüften Build des Koordinators.

## Tatsächliche Änderung

`LumoTaskRecognitionScreen` verwendet den bereits vorhandenen
`LumoSpeechListener`; dessen Standardinstanz verwendet weiterhin den zentralen
gemeinsamen Recognizer. Es gibt keine zweite Sprachpipeline, neue Cloud-API oder
Änderung an der Spracherkennung des übrigen Projekts.

- „Aufgabe sprechen“ startet erst nach einem bewussten Tippen und geladener
  Elternfreigabe. Der bestehende Dienst prüft auf Android die lokale
  Verfügbarkeit, fordert `onDevice: true` an und beendet vorher Lumo-Wiedergabe.
- Zwischenstände erscheinen als gehörte Worte. Nur ein echtes finales Ergebnis
  ersetzt den editierbaren Entwurf und durchläuft die vorhandene Erkennungslogik.
- Die vorhandene Vorschau verlangt weiterhin „Genau diese Aufgabe starten“.
  Sprache startet keine Übung, bewertet keine Antwort und vergibt keine Punkte.
- „Fertig gesprochen“ wartet über `stopListening()` auf das echte finale
  Ergebnis. „Aufnahme abbrechen“ verwendet `cancel()` und erhält den vorherigen
  Textentwurf. Tippen, Beispielwahl, Erkennen und Übungsstart verwerfen ebenfalls
  alte Aufnahmen.
- Die Aufnahme ist an ihre Generation, Profilgeneration, konkrete Profil-Lease
  und aktuelle Route gebunden. Profilwechsel, Navigation, Hintergrundwechsel,
  entzogene Elternfreigabe und Dispose entwerten verspätete Rückmeldungen.
- Ohne lokalen Dienst oder Mikrofonfreigabe bleibt Texteingabe benutzbar; der
  vorhandene Dienst startet keine Cloud-Aufnahme als Ersatz.
- Die neuen Aufnahme-/Abschluss-Touchziele sind mindestens 48 dp groß. Die
  AppBar heißt nun „Aufgabe erkennen“.

Die Grammatik bleibt unverändert. Ein natürlich sprechbarer unterstützter Fall
ist „Anfangsbuchstabe Mama“. Ein Transkript „12 + 7“ funktioniert ebenfalls.
Ausgeschriebene Rechenoperatoren wie „zwölf plus sieben“ wurden schon von der
HTML-Erkennungsgrammatik nicht unterstützt; sie bleiben sichtbar korrigierbar
und erhalten die vorhandene Fehlermeldung. Es wurde kein beliebiger Text in eine
andere Rechnung umgedeutet.

## Tatsächlich ausgeführte Prüfung

Flutter 3.44.9 / Dart 3.12.2; echte Projektassets und die bestehende Lockdatei,
`flutter pub get --offline --enforce-lockfile` erfolgreich.

```bash
flutter test --no-pub --reporter expanded \
  test/recognized_task_speech_test.dart \
  test/recognized_task_flow_test.dart \
  test/recognized_task_parser_test.dart \
  test/lumo_speech_listener_runtime_test.dart \
  test/lumo_speech_listener_plugin_boundary_test.dart \
  test/lumo_speech_privacy_test.dart

flutter analyze --no-pub \
  lib/features/recognition/lumo_task_recognition_screen.dart \
  test/recognized_task_speech_test.dart
```

Ergebnis am finalen Produkt-/Teststand: **74 Tests bestanden, 0 fehlgeschlagen,
0 übersprungen**. Darin sind die **11 neuen Widgettests bereits enthalten**;
die Zahlen werden nicht addiert. Analyse: **keine Befunde**. `git diff --check`
ist erfolgreich. Die Änderungen der vorherigen automatischen Formatierung im
unveränderten Renderer-/Ergebnisbereich wurden vor diesem finalen Lauf entfernt.

Die neuen Fälle prüfen die Vorschau ohne Bewertung, echte finale Ergebnisse
nach „Fertig“, beibehaltene Parserfehler, Abbruch mit verspäteter Rückmeldung,
fehlenden lokalen Dienst, beide Freigabeebenen sowie Entwertung bei Profil-,
Hintergrund-, Routen- und Einstellungswechsel. Auch die erst nach Dispose
beantwortete Berechtigungsanfrage darf keine Aufnahme starten.

Die Tests benutzen kontrollierte native Callbacks mit dem echten
`LumoSpeechListener`. Sie sind kein Nachweis einer physischen Mikrofonaufnahme,
Erkennungsqualität auf einem bestimmten Telefon oder eines bereits fertig
gebauten neuen APK-Artefakts.

Nachweise einschließlich Dateiidentitäten:
`docs/evidence/build-2081-flutter-20261124/recognition-voice/`.
Das vorhandene Integrations-Belegarchiv nimmt diesen Ordner rekursiv auf.

## Erhalt der vorhandenen Module

Der vorausgehende Abgleich bestätigte die bestehenden Kernmodule aus den
Berichten 03/14 und den vorhandenen Prototypen im aktuellen Dateibaum. Die
Schreibtrainer, Journalansicht/-repository, Profilrepository/UserProfile,
Profilansicht und Schreibpersistenz sind gegenüber dem 2080-Ausgangsstand
`a0fdd4031ba9a5637d9b943729a5f0df794071bc` unverändert; ihre sichtbaren Aufrufe
bleiben vorhanden. Dieser Patch berührt ausschließlich den Erkennen-Bildschirm
und dessen neue Tests sowie Nachweisdokumente.

Die alten Quellen mischen funktionierenden HTML-Code, ausdrücklich ungetesteten
Flutter-MVP-Code, OCR-Stubs und Zukunftsbriefings. Daraus folgt keine Behauptung,
jede historische Codezeile oder jede Zukunftsidee sei als fertige Funktion
übernommen. Insbesondere wird keine professionelle OCR oder freie gesprochene
Rechengrammatik aus einer damaligen Demo abgeleitet.
