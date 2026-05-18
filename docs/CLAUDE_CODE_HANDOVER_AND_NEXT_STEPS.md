# Claude Code Übergabe – Lumo Lernen

<!-- Zuletzt aktualisiert: 17. Mai 2026 — Build-Trigger für APK #54 -->

Dieses Dokument ist die direkte Übergabe an Claude Code / Opus 4.7 für das Repository:

```text
Ullmann27/lumo-lernen
```

Arbeite ausschließlich am aktuellen `main`. Lies zuerst den echten Code. Verlasse dich nicht auf alte Zusammenfassungen.

---

## 1. Was zuletzt gemacht wurde

In den letzten Entwicklungsschritten wurden mehrere neue Architektur- und Stabilitätsblöcke eingebaut.

### 1.1 Stabilitäts- und Schutzfixes

Relevante Dateien:

```text
lib/app/app_shell.dart
lib/features/sections/section_content.dart
lib/core/app_update_service.dart
lib/domain/reading/reading_domain.dart
lib/features/reading/reading_content.dart
```

Gemacht:

- Scanner-Schutzlücke geschlossen: Wenn `scannerEnabled == false`, darf nicht mehr direkt `SettingsContent` sichtbar werden.
- Stattdessen zeigt `app_shell.dart` eine Sperrseite mit Elternbereich-Button.
- Elternbereich bleibt über `ParentalGate` geschützt.
- `_loadSettings()` und `_navigateTo()` wurden mit `mounted`-Guards stabilisiert.
- `section_content.dart` bekam einen null-safety-sauberen `_StartSession` typedef.
- `app_update_service.dart` wurde sicherer gemacht:
  - keine falsche Update-Meldung nur wegen `latest.apk`,
  - Update nur bei neuer Buildnummer,
  - URL-Öffnung nur für GitHub/GitHub-Assets.
- `reading_domain.dart` nutzt jetzt deterministische `isComplete`-Logik.
- `completedSentenceIds` werden dedupliziert.
- Leere Storys crashen nicht mehr.
- `reading_content.dart` nutzt `isComplete` statt fragiler Indexlogik.

### 1.2 Aktiver Lesemodus

Relevante Dateien:

```text
lib/domain/reading/reading_domain.dart
lib/features/reading/reading_content.dart
lib/core/reading_progress_repository.dart
lib/domain/analysis/lumo_analysis_domain.dart
lib/domain/analysis/daily_recommendation_engine.dart
```

Gemacht:

- Story-Domain mit `Story`, `StorySentence`, `WordToken`.
- Silben-Colorizer.
- einfacher Pronunciation-/Transcript-Analyzer.
- ReadingMonitor mit 3-Versuche-Logik über Lumo-Orchestrator.
- ReadingContent UI mit Storykarte, aktuellem Satz, Mikrofon, Problemwörtern und Abschlusskarte.
- Persistente Lesedaten über `ReadingProgressRepository`.
- Lesedaten fließen in Tagesplan und Elternbericht.

### 1.3 Tagesplan und Elternbericht

Relevante Dateien:

```text
lib/domain/analysis/lumo_analysis_domain.dart
lib/domain/analysis/daily_recommendation_engine.dart
lib/features/home/home_content.dart
lib/features/settings/parent_report_card.dart
lib/features/settings/settings_content.dart
```

Gemacht:

- Analysemodelle für Lesen, Mathe, Deutsch/Lesen.
- `DailyRecommendationEngine` erstellt Tagesplan:
  - Förderblock,
  - Lesefuchs-Runde,
  - Erfolgsblock,
  - Mini-Wiederholung.
- Home zeigt adaptive Tagesplan-Karte.
- Elternbereich zeigt `ParentReportCard` mit:
  - Stärken,
  - Förderbedarf,
  - Problemwörtern,
  - nächsten Schritten.

### 1.4 Deutsch-/Rechtschreib-Qualitätsfix

Relevante Datei:

```text
lib/features/learning/adapters/legacy_lumo_task_adapter.dart
```

Gemacht:

- Der Adapter besitzt jetzt eine Sicherheitsprüfung `_sanitizeTask()`.
- Falsche Endlaut-Aufgaben werden korrigiert.
- Beispiel: Frage `Welches Wort endet mit t?` darf nicht mehr `Hund` als richtige Antwort zeigen.
- Antwortoptionen werden dedupliziert.
- Groß-/Kleinschreib-Duplikate werden verhindert.
- Wort-Bild-Aufgaben bekommen unterschiedliche Wörter.
- Schreibziel wird aus Prompt extrahiert:
  - `Schreibe das Wort: Mama` -> `Mama`,
  - `Schreibe: Lumo lernt.` -> `Lumo lernt.`,
  - `Schreibe die Zahl 7` -> `7`,
  - `Buchstaben A` -> `A`.

### 1.5 Touch-Writing-Canvas

Relevante Dateien:

```text
lib/features/learning/widgets/lumo_writing_canvas.dart
lib/features/learning/renderers/writing_task_renderer.dart
lib/domain/writing/writing_domain.dart
lib/domain/writing/expanded_writing_template_repository.dart
```

Gemacht:

- `LumoWritingCanvas` wurde auf `GestureDetector` mit Pan-Gesten umgestellt.
- Ziel: Beim Schreiben soll der umgebende ScrollView nicht mitscrollen.
- `DragStartBehavior.down` wird über `package:flutter/gestures.dart` importiert.
- Striche werden nur aus echten Fingerbewegungen erstellt.
- Sehr große Sprünge brechen den aktiven Stroke ab, damit keine Querlinien entstehen.

---

## 2. Was sofort zu prüfen ist

Führe zuerst aus:

```bash
git pull origin main
flutter clean
flutter pub get
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter build apk --debug
```

Wenn der Build rot ist:

1. Keine Features bauen.
2. Den ersten echten Dart-/Gradle-/Flutter-Fehler reparieren.
3. Folgefehler wie „APK not found“ ignorieren, bis die echte Ursache klar ist.
4. Kleinen Commit machen.
5. Wieder Build starten.

---

## 3. Aktuelle wichtigste Baustellen

### 3.1 Deutsch-Aufgaben fachlich prüfen

Heinz hat real gesehen:

```text
Welches Wort endet mit t?
Antworten: Hase, Mama, Hund
```

Das darf niemals passieren.

Prüfe deshalb gründlich:

```text
lib/core/school_exercise_generator.dart
lib/features/learning/adapters/legacy_lumo_task_adapter.dart
lib/features/learning/renderers/adaptive_task_renderer.dart
```

Auftrag:

- Suche alle Deutsch-/Rechtschreib-/Lesen-Aufgabentypen.
- Prüfe Anfangslaut, Endlaut, Reim, Silben, Wort-Bild, Rechtschreibung.
- Stelle sicher:
  - Antwort ist fachlich korrekt.
  - Genau eine Antwort ist richtig.
  - Keine doppelten Optionen.
  - Keine identischen Optionen nach Normalisierung.
  - Keine Antwortoption ist leer.
  - Frage und Antwort passen logisch zusammen.

Wenn `_sanitizeTask()` zu sehr im Adapter steckt, erstelle sauber:

```text
lib/domain/learning/task_quality_guard.dart
```

Dann dort zentrale Qualitätsprüfung einbauen und im Adapter verwenden.

### 3.2 Wiederholungen reduzieren

Die App wiederholt Aufgaben noch zu oft.

Prüfe:

```text
lib/features/learning/learning_content.dart
lib/core/school_exercise_generator.dart
lib/domain/learning/seed_memory_service.dart
```

Auftrag:

- Keine identische Aufgabe in derselben Session.
- Keine gleiche Prompt+Antwort-Kombination direkt wiederholen.
- Task-Key muss enthalten:
  - subject,
  - unit,
  - prompt,
  - answer,
  - choices normalisiert,
  - visual,
  - visualPayload/Parameter,
  - Schreibziel.
- Keine Endlosschleifen bei Suche nach neuer Aufgabe.
- Wenn eine Unit erschöpft ist, kontrolliert Unit/Subject variieren.
- Tests und Schularbeit sollen stärker mischen.
- Nachhilfe darf wiederholen, aber mit Variation und Erklärung.

### 3.3 Writing: Aufgabe und Touchfeld synchronisieren

Prüfe:

```text
lib/features/learning/adapters/legacy_lumo_task_adapter.dart
lib/features/learning/renderers/writing_task_renderer.dart
lib/features/learning/widgets/lumo_writing_canvas.dart
lib/domain/writing/expanded_writing_template_repository.dart
```

Auftrag:

- Wenn Aufgabe `Mama` verlangt, darf nicht `A` als Vorlage erscheinen.
- Wenn Wortpfade nicht vorhanden sind, muss der Renderer in Wortmodus wechseln:
  - Zielwort klar anzeigen,
  - Schreiblinien anzeigen,
  - keine falsche Einzelbuchstaben-Vorlage anzeigen.
- Einzelbuchstaben und Zahlen sollen echte Pfadvorlagen nutzen.
- Canvas darf beim Schreiben nicht scrollen.
- Finger neu ansetzen darf keine Verbindungslinie quer durch das Feld erzeugen.
- Bewertung darf bei Wortmodus nicht so tun, als könne sie ein komplettes Wort per Einzelpfad perfekt erkennen.

### 3.4 Designaufgabe: Deutsch und Aufgaben visuell schöner machen

Heinz möchte Premium-Design. Kein Standard-Flutter, keine trockene Quizkarte.

Arbeite in kleinen Schritten an:

```text
lib/features/learning/renderers/adaptive_task_renderer.dart
lib/features/learning/renderers/writing_task_renderer.dart
lib/features/schoolbook/
lib/app/app_theme.dart
```

Ziel:

- Mehr visuelle Aufgaben, weniger nur Text.
- Schulbuchnah, aber nicht 1:1 kopiert.
- Große, klare Karten.
- Endlaut-Aufgaben: letzte Buchstaben farblich markieren.
- Silben-Aufgaben: Silbenbögen oder Silbenkarten.
- Wort-Bild-Aufgaben: Icon/Bildkarte + Wortkarten.
- St/Sp-Aufgaben: zwei große Laut-Häuser.
- Rechtschreibung: Schreiblinien/Kästchenoptik.
- Mobile-tauglich ohne Overflow.

Wichtig:

- Keine urheberrechtlich geschützten Schulbuchseiten kopieren.
- Eigene didaktische Gestaltung bauen.
- Design über vorhandene Theme-Tokens oder zentrale Ergänzung in `app_theme.dart`.
- Keine Farben lokal wild verstreuen.

### 3.5 Lumo-Feedback lebendiger machen

Prüfe:

```text
lib/domain/learning/lumo_learning_feedback_engine.dart
lib/app/app_state.dart
lib/domain/agent/lumo_orchestrator.dart
```

Auftrag:

- Feedback darf nicht immer gleich sein.
- Satzpools mit Rotation/Seed einbauen.
- Feedback abhängig von:
  - richtig/falsch,
  - Fehlerfolge,
  - Fach,
  - SessionKind,
  - Nachhilfe/Test/Übung,
  - Fortschritt.
- Keine Beschämung.
- Testmodus: weniger Hilfe.
- Nachhilfe: mehr Erklärung.
- Abschluss: motivierend, aber nicht übertrieben.

---

## 4. Designrichtlinie für Claude Code

Du darfst deine Designstärke einsetzen, aber nur kontrolliert:

### 4.1 Stil

- warm,
- hochwertig,
- kindgerecht,
- digitaler Schulheft-/Arbeitsblatt-Look,
- Lumo-Fuchs als freundlicher Begleiter,
- keine generische Quiz-App.

### 4.2 UI-Regeln

- Touchflächen groß.
- Keine gequetschten Texte.
- Kein wichtiges `ellipsis`, wenn Umbruch besser ist.
- Mobile zuerst prüfen.
- Alle Inhalte scrollbar, außer Schreibfläche selbst.
- Keine RenderFlex-Overflows.
- Rechte Lumo-Bühne auf großen Screens erhalten.
- Mobile Bottom Navigation darf nicht überladen werden.

### 4.3 Visualisierungen zuerst für diese Aufgaben

Baue zuerst nur 2–3 hochwertige Visuals, nicht alles auf einmal:

1. Endlautkarte,
2. Silbenkarte,
3. Wort-Bild-/Schreiblinienkarte.

Danach erst weitere.

---

## 5. Sicherheitsregeln

- Elternbereich nicht umgehen.
- Kein offener Kinderchat.
- Keine Kinderdaten an externe Dienste senden.
- Mikrofon nur bei aktiver Interaktion.
- Scanner nur wenn freigegeben.
- TTS nur wenn freigegeben.
- Update-Service nur GitHub-Download-URLs.
- Keine neuen externen Services ohne ausdrückliche Freigabe.

---

## 6. Verbotene Aktionen

Nicht tun:

- Shell ersetzen.
- Navigation chaotisch umbauen.
- App komplett neu schreiben.
- Neue große Packages ohne Build-Grund.
- OCR/ML Kit reaktivieren, solange Build nicht stabil ist.
- Demo-Code einbauen, der nicht funktioniert.
- Falsche Aufgaben nur optisch kaschieren.
- Design bauen, bevor Build grün ist.

---

## 7. Direkter nächster Arbeitsauftrag

Arbeite jetzt exakt so:

1. Aktuellen `main` holen.
2. Build/analyze prüfen.
3. Wenn rot: Build zuerst reparieren.
4. Danach `school_exercise_generator.dart` und `legacy_lumo_task_adapter.dart` komplett auf Deutsch-/Rechtschreibfehler prüfen.
5. Einen sauberen `TaskQualityGuard` bauen oder `_sanitizeTask()` sauber erweitern.
6. Wiederholungslogik in `learning_content.dart` verbessern.
7. Writing-Ziel und Canvas mit realer App-Logik prüfen und reparieren.
8. Danach 2–3 visuelle Deutsch-Renderer hochwertig ausbauen.
9. Lumo-Feedback variabler machen.
10. Alles klein committen.
11. Build erneut prüfen.
12. Bericht an Heinz liefern:
    - was geprüft,
    - was geändert,
    - welche Commits,
    - Buildstatus,
    - was Heinz in der App testen soll.

---

## 8. Akzeptanzkriterien

Diese Punkte müssen nach deiner Arbeit stimmen:

- Keine Endlautfrage mit falscher Lösung.
- Keine doppelten Antwortoptionen.
- Keine identischen Rechtschreiboptionen nach Normalisierung.
- Schreibaufgabe und Vorlage passen zusammen.
- Canvas scrollt nicht beim Schreiben.
- Keine Querlinien durch neues Ansetzen.
- Weniger direkte Aufgabenwiederholung.
- Mobile Layout bleibt stabil.
- Build ist grün.
- GitHub Actions erzeugt APK.

Wenn Build rot bleibt, keine Designarbeit fortsetzen, sondern Fehler fixen.
