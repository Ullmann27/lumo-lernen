# Spiele- und Lernbelohnungen – 3. Oktober 2026

Ein Fehler im neuen Spiele-Import wurde mit einer verzögerten, anschließend
fehlgeschlagenen Plattformschreibung nachgestellt: Ein Renn-Award setzte den
Speicherzustand vor dem Schreiben um. Eine gleichzeitig eingehende Lernbelohnung
speicherte diesen Zwischenzustand; der Rücksetzversuch des Renn-Awards löschte
danach die Lernbelohnung im Arbeitsspeicher. Beim Wiederholen des nativen
Spielereignisses gingen die Lernsterne tatsächlich verloren.

## Korrektur

- Sterne, XP, Tagesstreak, Profilreset und native Spielergebnisse laufen über
  dieselbe Transaktionswarteschlange.
- Jede Änderung berechnet den nächsten vollständigen Snapshot. Erst nach
  erfolgreichem Speichern werden der sichtbare Repository-Zustand und dessen
  Stream aktualisiert. Es gibt keinen Rücksetzversuch auf veraltete Snapshots.
- Resultatkennung und Belohnung bleiben im selben JSON-Wert gespeichert. Eine
  native Wiederholung wird auch nach einem neuen Repository-Start nur einmal
  vergeben.
- Fehler werden an den Aufrufer gemeldet und blockieren spätere Transaktionen
  nicht. Auch fehlgeschlagene normale Lernbuchungen und Resets melden einen
  Fehler, statt einen erfolgreichen Speichervorgang vorzutäuschen.
- Alte flache Wallet-Dateien ohne Resultatkennungen bleiben kompatibel.
  Fehlgeschlagene Legacy-Migrationsschreibungen verwerfen zuvor gelesene Sterne
  nicht; die nächste tatsächliche Transaktion speichert sie mit.

## Tatsächliche Prüfung

Flutter 3.44.9 / Dart 3.12.2:

- Zehn neue Tests prüfen Plattformrückgabe `false`, echte Speicherexception,
  parallel anstehende Lernsterne/XP, atomare Resultatkennung, acht gleichzeitige
  Wiederholungen, neuen Repository-Start, Warteschlange vor/nach Reset, Resetfehler,
  Legacy-Migration und ungültige Resultate.
- Gemeinsam mit `state_persistence_regression_test`, `learning_answer_reward_test`,
  `restart_regression_test` und `games/game_round_regression_test`: 28 Tests
  bestanden.
- Analyse von Repository und neuen Tests: keine Fehler, Warnungen oder Hinweise.
- `git diff --check`: bestanden.

Die Testplattform trennt gespeicherte Werte von SharedPreferences' Arbeitsspeicher,
damit fehlgeschlagene Schreibung und anschließende Wiederholung tatsächlich
unterscheidbar sind. Auf Android verwendet das installierte Legacy-Plugin
`SharedPreferences.Editor.commit()` und meldet dessen Ergebnis.

Native Ereignisse bei vollständigem Profilreset zu löschen und laufende
Spieleimporte durch eine Reset-Generation zu entwerten gehört zur separaten
AppState-/Android-Brückenkorrektur. Diese Prüfungen sind keine APK-Installation.
