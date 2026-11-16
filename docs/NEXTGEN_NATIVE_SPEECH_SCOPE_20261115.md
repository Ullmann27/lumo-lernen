# Nativer Sprachanschluss · Kontext und Audiofokus

`tools/auto_install/LumoLearningSpeech.kt` bleibt die vorhandene kostenlose,
lokale Sprachausgabe der nativen Lern-/Bauwelt. Die ursprünglichen Eltern-
und Lizenzfreigaben bleiben erforderlich; andere Spiele erhalten dadurch
keine Sprachausgabe. Lösungen, Bewertungen und Profilfortschritte werden
von diesem Anschluss nicht geändert.

## Ergänzungen

- `getLearningSpeechStatus()` enthält jetzt `scopeVersion: 1`.
- Ein vollständig übergebener optionaler Scope aus `sessionId`, `taskId`,
  `turnId`, `utteranceId` und ganzzahliger `contextRevision` wird mit jeder
  tatsächlichen Wiedergabemeldung unverändert zurückgegeben.
- Fremde Startsitzungen, unvollständige/ungültige Scopes, frühere
  Kontextstände und wiederholte Kennungen werden abgewiesen. Die letzten
  64 Kennungen sind nur in RAM vorhanden. Bestehende `id`-Aufrufe ohne Scope
  bleiben unterstützt.
- Ein Audiofokusverlust stoppt Wiedergabe und ausstehende Arbeit. Der Status
  wird `interrupted`, Lautstärke-/Mundhüllkurve werden geschlossen. Ein
  späterer Fokusgewinn setzt die alte Äußerung nicht automatisch fort.
- Callbacks einer alten Wiedergabe können die neue nicht abbrechen.
- Der Status benutzt die wirkliche MediaPlayer-Position und die PCM-
  Hüllkurve der genau dazugehörenden WAV.

Die optionale Gegenstelle in `Ullmann27/lumo-godot` liegt in
`scripts/learning/lumo_dialogue_avatar.gd` und `learning_world.gd`.
Dies ist kein behaupteter, bereits freigegebener Ersatz des gemeinsamen
Chat-1-Lernvertrags. Insbesondere bezeichnet der dortige `activity:`-Hash den
geprüften nativen Erklärdeskriptor, nicht eine erfundene Flutter-Aufgaben-ID.

## Prüfbelege

`docs/evidence/conversation-avatar-20261115/native-speech-contracts.log`:

- vorhandener PCM-Vertrag: 23 Prüfungen;
- vorhandener Lifecycle-Vertrag: 17 Prüfungen;
- vorhandene Bauwelt-/Freigabe-/Geschwindigkeitsprüfungen: 30;
- neuer Scope-/Fokusvertrag: 27 Prüfungen.

Alle vier Tests sind bestanden. Sie kompilieren die tatsächlichen Kotlin-
Quellen gegen ausdrücklich synthetische Android/JVM-Testgrenzen. Zusätzlich
wurde der neue Code gegen das echte Android-36-`android.jar` kompiliert;
`android-api-compilation.log` bezeichnet die dabei verbliebene synthetische
Flutter-/Synthesegrenze ausdrücklich. Keines dieser Protokolle wird als
Android-Gerätewiedergabe, Mikrofonbeleg oder fertige APK ausgegeben.

Die Godot-Gegenstelle hat zusätzlich eine tatsächliche Desktopaufnahme mit
Originalmodell und der erhaltenen Original-WAV „Apfel“. Sie belegt den
Avatar-Wiedergabeanschluss, kein freies Gespräch mit einem Kind.

Die Audiofokus-API wurde gegen die offizielle Android-Dokumentation und das
lokale API-36-JAR geprüft:

- https://developer.android.com/media/optimize/audio-focus
- https://developer.android.com/reference/android/media/AudioFocusRequest.Builder

Reproduktion mit dem vorhandenen JDK und `LUMO_KOTLIN_LIB_DIR` auf das
bestehende Gradle-`lib`-Verzeichnis:

```sh
python3 -m unittest scripts.tests.test_speech_envelope_contract -v
```
