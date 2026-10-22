# Fächerauswahl „Lernen“ – Vorher/Nachher (22.10.2026)

Echte Flutter-Renderings der vollständigen AppShell. Sie stammen aus
`test/design/app_tour_capture_test.dart` mit `LUMO_TOUR_DIR=<ordner>` und wurden
für das Repository auf 412 px Breite verkleinert. Es sind keine Konzeptbilder.

- `phone_learn_vorher_nachher.jpg`: Telefon 412×915
- `fold_learn_vorher_nachher.jpg`: Fold innen 690×829
- Vorher: Commit `7c3cb941`. Nachher: der Commit, der diesen Ordner hinzufügt.

Das Testprofil ist neu, deshalb zeigen alle Fächer „0 %“ und „Noch nicht begonnen“.
Der Ring zählt nur Themen der eigenen Klasse mit mindestens einer richtigen
Antwort aus `appState.learningSkills()`; abgesichert durch
`test/design/learning_hub_progress_test.dart`.

**Nicht geprüft:** Darstellung auf einem echten Android-Gerät oder Emulator.

## Themenliste eines Fachs (`topics_vorher_nachher.jpg`)

Echte Flutter-Renderings von `LumoLearningHub` nach dem Tippen auf Mathematik
(412×915, 2. Klasse). Vorher: `c1ec339f`. Nachher: der Commit, der dieses Bild
hinzufügt. **Testdaten:** zwei Themen mit gespeicherten Antworten (9/1 und 2/3);
in der App stammen sie aus `appState.learningSkills()`. Die Klötzchen auf
„Alle Fächer“ sind ein Artefakt dieser Einzelaufnahme, in der die
Standardschrift Roboto nicht geladen ist; die App rendert dort normalen Text.
