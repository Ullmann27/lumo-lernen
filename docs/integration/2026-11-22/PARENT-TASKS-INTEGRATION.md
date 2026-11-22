# Integration der frei formulierten Elternaufgaben

## Herkunft und Entscheidung

Der hochgeladene HTML-Prototyp `09-lumo_lernen_menu_pro_app.html` enthielt einen
tatsächlich angeschlossenen Elternaufgaben-Pfad: Das Formular erzeugte eigene
Fragen mit Antwortoptionen, `addCustomTask()` speicherte sie in `st.customTasks`
und ergänzte die Aufgabenbank; `addCustomTasksToBank()` stellte diese Verbindung
nach erneutem Laden wieder her. Die früher untersuchte HTML-App 05 speicherte
ebenfalls `customTasks`, hatte dafür aber keinen lesenden Lernverbraucher.

Die vorhandenen Flutter-Lehreraufträge wählten dagegen Lehrplanfach, Thema,
Aufgabenanzahl und Termin. Sie enthielten keinen frei formulierbaren
Frage-/Antworteditor. Eine ausdrückliche neuere Ablösungsentscheidung für den
angeschlossenen HTML-09-Pfad wurde im Quellenabgleich nicht gefunden. Deshalb
wurde die Funktion für die Integration 2067 modular ergänzt.

## Erreichbarer Eltern- und Kindpfad

Im bestehenden Elternbereich steht `ParentTasksEditorCard(appState: ...)` neben
den Lehreraufgaben. Eltern können für das aktuell ausgewählte Kinderprofil eine
Frage, die richtige Antwort, insgesamt zwei bis sechs unterschiedliche
Antwortmöglichkeiten, eine freiwillige Erklärung, ein Fach und eine Klasse
von 1 bis 4 speichern. Die richtige Antwort wird im Editor automatisch in die
Auswahl aufgenommen. Anlegen, Bearbeiten und Entfernen verwenden dasselbe
profilgebundene Repository. Veraltete Bearbeitungsstände überschreiben keine
inzwischen geänderte Aufgabe.

Die Startseite zeigt „Aufgaben von deinen Eltern“ erst, wenn das ausgewählte
Kind gespeicherte Aufgaben oder einen fortsetzbaren Versuch besitzt. Der
Zugang hat eine Mindesthöhe von 72 dp; die neuen Aktionsknöpfe mindestens
48 dp. Er öffnet die tatsächliche Aufgabenliste und anschließend den vorhandenen
`AdaptiveTaskRenderer`. Die Aufgaben werden unverändert aus dem Elterntext
übergeben und nicht durch generierte Lehrplanaufgaben ersetzt. Die optionale
Erklärung erscheint nach der Antwort.

## Speicherung, Auswertung und Isolation

- Speicher: `LearningDataNamespace.keyFor('lumo_parent_tasks_v1', studentId)`.
  Die Sicherungsfunktion übernimmt damit das Präfix `lumo_parent_tasks_v1::`.
- Sammlung: `version`, `studentId`, `tasks` und `activeAttempt`. Die Aufgabe hat
  eine stabile, an den Profilinhaber gebundene ID, Revision und Zeitstempel.
- Ein begonnener Versuch wird **vor seiner Darstellung** dauerhaft gespeichert.
  Sein eigener Aufgabenschnappschuss bleibt bei einer späteren Änderung der
  Elternaufgabe unverändert.
- Die bestehende Antwortprüfung liefert das Ergebnis. `RewardEngine` berechnet
  die bisherige Lernbelohnung: beim hier verwendeten selbständigen richtigen
  Versuch 6 Sterne und 25 XP, bei einer falschen Antwort keinen Abzug.
- Das vorhandene `AttemptLogRepository` protokolliert das Ergebnis unter dem
  Fach **„Elternaufgaben“**; das ursprüngliche Fach und die Klasse bleiben als
  Kontext erhalten. Der Pfad ruft keine Curriculum-, Prüfungs-, Kompetenz- oder
  Tagesmissionsbuchung auf.
- Die Wallet wird über `LumoAppState.awardParentTaskResult(...)` und den
  vorhandenen dauerhaft deduplizierten Reward-Writer gebucht. Die Versuch-ID
  `parent:<SHA-256 des Profilinhabers>:<32 Hexzeichen>` bleibt bis zur bestätigten
  Protokoll- und Walletbuchung gleich.
- Nach einem Abbruch zwischen Walletbuchung und Abschlussquittung verwendet
  die Fortsetzung dieselbe ID. Erst das ausdrückliche Verlassen des bisherigen
  Ergebnisses und Starten einer neuen Übung erzeugt eine neue Versuch-ID.
- Beim Profilwechsel werden die vorherigen Fragen sofort ausgeblendet. Ein
  geöffneter Editor kann nicht für das nachträglich ausgewählte Kind speichern.
  Eine bereits angenommene Antwort bleibt dem ursprünglichen Kind zugeordnet;
  ihre noch offene Walletphase wird erst wieder unter diesem Profil fortgesetzt.
- Ein entfernter, noch unbeantworteter Versuch verschwindet mit der Aufgabe.
  Ein bereits angenommenes Ergebnis behält seinen Schnappschuss, bis seine
  Speicherung vollständig abgeschlossen ist. Beschädigte oder unbekannte
  Speicherformate werden nicht als leere Sammlung überschrieben.

Die zusätzlichen `parent:`-IDs im gemeinsamen Reward-Ledger werden im
Profil-Spielzähler ausgeschlossen. Sie erzeugen keine Spieler:innen-Auszeichnung.

## Geprüfte Fälle

Der gezielte lokale Lauf enthielt **15 neue bestandene Tests**:

| Bereich | Nachweis |
| --- | --- |
| Repository, 10 Tests | 2–6 Antworten, Eindeutigkeit und enthaltene Lösung; Anlegen/Neuladen/Ändern/Löschen; stabile Identität; Profilisolation; Revisionskonflikte; parallele Repository-Instanzen; beschädigte und neuere Daten; unveränderter Versuchsschnappschuss; erste Antwort unveränderlich; echte neue Runde; abgelehnte Schreibvorgänge. |
| Flow, 5 Tests | Einmaliges Ergebnis bei Double-submit; unveränderte Lehrplan-/Missionszähler; Neustart nach Wallet-Erfolg und abgelehnter Abschlussquittung; Profilwechsel während einer gehaltenen Protokollschreibung; echter Editor→Neustart→Home→Renderer→Ergebnis bei 390 × 844; gesperrter alter Editor nach Profilwechsel. |

Zusätzlich bestanden **alle 4 vorhandenen Tests** in
`test/learning_answer_reward_test.dart` für Unterricht und freies Üben bei
Textskalierung 1,0 und 2,0. Die gezielte Dart-Analyse der sechs neuen
Produktionsdateien und zwei Testdateien meldete **keine Befunde**.

Ausgeführte Befehle:

```sh
flutter test --no-pub --concurrency=1 --reporter=expanded \
  test/parent_task_repository_test.dart test/parent_task_flow_test.dart
flutter test --no-pub --concurrency=1 --reporter=expanded \
  test/learning_answer_reward_test.dart
dart analyze lib/domain/learning/parent_authored_task.dart \
  lib/core/parent_task_repository.dart lib/features/parent_tasks \
  test/parent_task_repository_test.dart test/parent_task_flow_test.dart
```

## Dateien und Grenzen des Nachweises

Die neue Funktion liegt in `lib/domain/learning/parent_authored_task.dart`,
`lib/core/parent_task_repository.dart` und den vier Dateien unter
`lib/features/parent_tasks/`. Home enthält lediglich den zusätzlichen Import und
die Inhaltskarte. Der Settings-Anschluss und der schmale AppState-Delegator
wurden durch die jeweiligen Integrationsverantwortlichen ergänzt.

Der geschützte Schreibtrainer und Journal-Editor wurden nicht verändert. Der
Nachweis belegt den echten Flutter-Widgetpfad und dessen persistente Wirkung;
er ersetzt keine physische Android-Geräteprüfung. Die endgültige APK-Provenienz,
der Emulatorlauf und die zusätzliche echte Android-SAF-Export-/Restore-Probe
werden im Releasebeleg separat festgehalten. Ältere HTML-Exportdateien sind ein
anderes Format und werden nicht stillschweigend als neue native Sicherung
importiert. Eine automatische Migration fremder Browser-`localStorage`-Daten
ist nicht Bestandteil dieses Anschlusses.
