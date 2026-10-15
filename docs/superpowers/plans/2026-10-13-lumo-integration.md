# Lumo Integration Implementation Plan

**Goal:** Vorhandene 1938-Produktlinie anhand überprüfbarer Deltas vervollständigen.
**Architecture:** Geschützte Basis plus PR284/285; kleine gestapelte Draft-PRs. Keine alten Komplettdateien über neuere Architektur legen.
**Tech Stack:** Flutter 3.44.9, Dart 3.12.2, Godot 4.6.3 (Pin unverändert).
**Spec:** Heinz' Master-Fortsetzungsauftrag vom 13.10.2026; Zusammenfassung und Befunde in `docs/audit/2026-10-13/README.md`.

## Global Constraints

- Ausgangspunkt `d7440beaba78992ee36c8f4be1513e6b5006c1f6`, geschützt `5fe56eb111f5d44a69ba98ef5424033afa6f417b`.
- Godot `ec96515a2e359d21e9591120fc81dfd15116e81e` unverändert.
- Kein Main-Push, Merge, Force-Push, Release, APK-Build oder kostenpflichtiger Dienst.
- Profile, gespeicherte Hefte, native Offline-Stimmen, Bundle, Lernmodule und Belohnungen erhalten.
- Jeder Block: Regression RED, minimale Reparatur, vollständige Analyse/Tests, Draft-PR.
- Lokaler Flutter-Aufruf von automatischer Sicherheitsprüfung blockiert; vorhandenen reinen GitHub-Reviewworkflow nutzen. Keine Umgehung.

## Review Focus

- Langsames oder fehlgeschlagenes Speichern: kein vorzeitiger Erfolg, keine doppelte Story beim Wiederholen.
- Navigation während Speichern: Reader bleibt geöffnet; bestehende Hefte unverändert.
- Profile ohne Antworten: keine erfundenen Stärken oder Zeitbehauptungen.
- Profilwechsel während asynchroner Elternanalyse: keine Daten des vorherigen Kindes anzeigen.
- Kleines Fold-Außendisplay/große Schrift: Ergebnis und Wiederholungsaktion erreichbar.

### Task 1: Geschichtenabschluss

**Files:** `lib/core/lumo_story_library.dart`, `lib/features/story/lumo_story_reader_screen.dart`, `lib/features/story/lumo_story_setup_screen.dart`, `test/story_completion_storage_test.dart`, `test/story_completion_navigation_test.dart`.
**Interfaces:** Bestehendes `Future<StoredStory> addStory(LumoStory)` bleibt erhalten; JSON-Format/Schlüssel bleiben erhalten.

- [x] Tests mit kontrollierter SharedPreferences-Verzögerung vor Produktion schreiben.
- [ ] RED im vorhandenen GitHub-Reviewworkflow; vor Storage-Abschluss darf kein Erfolgsdialog erscheinen.
- [ ] Reader wartet auf `addStory`; Wiederholung/Zurück während Speichern sperren; Fehler sichtbar und wiederholbar.
- [ ] `save` prüft bool-Ergebnis; bei gescheitertem `addStory` nur die neue Story aus Speicherliste entfernen.
- [ ] GREEN plus unveränderte Profilklasse-/Lernpfad-/Filtertests und vollständige Suite.
- [ ] Eigener Commit und Draft-PR gegen PR285-Branch.

**Ruling:** Setup als dritte Produktionsdatei ergänzt: Der echte Navigationsregressionstest auf `ada82abc` bestätigt, dass erfolgreicher Abschluss sonst in Setup statt Bibliothek endet. Explizites Reader-Ergebnis entfernt ausschließlich die alte Setup-Route, ohne einen neu geöffneten Wortcoach zu schließen. Abbruch behält Setup. Kein Speicherformatwechsel.

**Prüfkorrektur:** Flutter3.44.9 verwendet450ms Android-Rücknavigation; neue Tests warten500ms plus Disposalframe statt der falschen400ms. Keine Produktionsänderung allein für diese Timingkorrektur. Speichertest prüft echte kontrollierte Plattformdaten statt nur SharedPreferences-Cache; false und throw bleiben Pflichtfälle. Erfolgs-/Fehlerbilder werden unter `.ci-results/story-storage` erzeugt.

**Ruling:** Derselbe echte Mehrseitentest bestätigt bei jedem Weiterlesen `PageController.page cannot be accessed before a PageView is built with it`. Der Reader rendert tatsächlich `_buildPage` per Seitenindex und besitzt keinen PageView. Ungenutzten PageController entfernen, den bestehenden Seitenrenderer und seine Inhalte erhalten. Der Test muss sämtliche Seiten ohne Flutter-Ausnahme lesen.

### Task 2: Geschichten-Einstiege und Antwortdaten

**Files:** Nach Task1 separat: Home, Deutsch, Lesen, Akademie, Story-Reader und passende Widgettests.
**Interfaces:** `LumoStoryLibraryScreen(appState:, gradeLevel:)`, `LumoStorySetupScreen(initialGrade:)`, bestehende `recordLearningAnswer`-ProfileLease.

- [ ] Spender-Deltas #282/Auditzweig prüfen, vollständige Navigationsketten testen.
- [ ] Verständnisantworten fachlich trennen; heuristisches Zusammenfassungs-Stammmatching nicht als objektive Antwortkorrektheit speichern.
- [ ] Doppeltippen-/Profilwechsel-/Sternregressionen vor Änderung.
- [ ] Gezielt testen, Gesamtprüfung, separater Draft-PR.

### Task 3: Lern-DNA/Insight

**Files:** `learning_dna.dart`, `learning_dna_engine.dart`, `learning_dna_card.dart`, `lumo_insight_dashboard.dart`, Heatmap und Tests.
**Interfaces:** Profilgebundene `learningSkills()`/`SkillRecord`, keine Speicherformatänderung.

- [ ] RED: Null Antworten, 1/2 Antworten, 7/10, Thema ohne Daten, gleiche Namen/verschiedene Profile.
- [ ] Echte Antwortquote und Antwortanzahl; kleine Stichprobe explizit; keine künstliche Sicherheit.
- [ ] Gesamtwerte klar benennen, keine Wochenbehauptungen aus `lastSeen`/Gesamtsummen; bestehende Elternfreigabe erhalten.
- [ ] Profilwechsel-/Prompt-/Persistenztests, Gesamtprüfung und separater Draft-PR.

### Folgende eigenständige Blöcke

Unterrichtsrouten ohne Chat-Ersatz; Schreibcoach S/C/H/O; 20-Fragen-Meister samt 5.000-Sterne-Regel; Kompetenz-Heatmap; Offline-Stimmepipeline; Godot-Szenen/Assetanschluss; Android-Abnahmeplan. Vor jedem Block konkretes Delta und Abnahmefälle festlegen. Keine Runtime- oder Grafikfreigabe aus bloßer statischer Inventur ableiten.
