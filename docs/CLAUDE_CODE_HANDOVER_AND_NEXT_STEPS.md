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

---

## 9. Session 2026-05-20 – Was Claude (Opus 4.7) gemacht hat

Heinz' Auftrag: "Total Perfektion" – Phase 1-5 starten, autonom arbeiten.

### Gepushte Phasen (28 Commits auf `claude/continue-previous-chat-KtY7p`, PR #50)

**Phase 5/6 Schreibcoach (frühere Session-Hälfte):**
- `ca7241e` Phase 6: `WritingProgress` + `WritingProgressRepository` + Single-Letter-Coach-Integration
- `462b5d3` Phase 5: Wortdiktat mit Buchstabenfeldern (`LumoWritingWordCoachScreen`, 12 Klasse-1-Wörter)
- `673ea07` Phase 6b: `WritingReportCard` im Elternbereich
- `f3b0ce5`, `35f9cf7`, `96b768e`, `75054ed`, `054a6cb`, `004aeb6`, `08d71b1` – sieben Codex P1/P2 Bugfixes:
  Race-Conditions im Repo-Lock, Row-Overflow bei langen Diktatwörtern, prozess-weiter
  Lock (Singleton-Pattern via static), Double-Tap-Guard in beiden Coaches, ehrliche
  Sterne (`_firstTryLetters`), Final-Slot-Rebuild, Reset durch Lock.

**Phase 1 – Cartoon-Fuchs raus:**
- `c3bef26` Neues `LumoIdleFox`-Widget (8-Frame-Animation aus
  `assets/lumo_jump/fox/idle`). Alte `lumo_fox.png/.jpg` + `lumo_main.png`
  in 5+ Widgets ersetzt: `LumoFreeCompanion`, `LumoHeroHeader`,
  `LumoEncourageCard`, `EmbeddedLumoFox`, `LumoOnboardingScreen`,
  `LumoAkademieScreen`, `LumoTeacherScreen`.
- `7c81f6e` Agent + Level-Map Marker → Idle-Fox.
- `080216b` Lumo-Erklärt + Hint-Bubble → Idle-Fox.
- `b24fcd8` Profil-Avatar → Idle-Fox.
- Alle aktiven `Image.asset('lumo_fox.png/.jpg')` und `'lumo_main.png'`
  weg. Nur Asset-Dateien bleiben (für späteren Cleanup).

**Phase 2A – Aufgaben/Antworten größer (zentraler Renderer):**
- `931fd2c` `AdaptiveTaskRenderer` dynamisch:
    * Labels ≤3 Zeichen (Mathe-Zahlen): **38pt**, padding 24
    * Labels ≤8 (kurze Wörter): **28pt**, padding 20
    * Lange Sätze: 20pt, padding 16, max 2 lines
  Frage-Prompt 30→34pt, Subject-Label 13→15pt, Helper 14→16pt.
  Wirkt automatisch in allen 20 Modulen.

**Phase 2B – Mathe-Bilder satter:**
- `9b587c5` `_ObjectGroup`: 34x34 → 44x44, emoji 22→28pt, sanfter Orange-Schatten.

**Phase 2D – Glow auf richtiger Antwort:**
- `f99d40d` `_AnswerButton` Stateless→Stateful, eigener Glow-Controller.
  Nach 2 Fehlern leuchtet die korrekte Option grün-pulsierend
  (konsistent mit dem bestehenden `_LocalHelpBanner` ab demselben Schwellwert).

**Phase 3 – Lumo reagiert live + Lösungsweg sichtbar:**
- `ee45831` Neues `LumoReactionCompanion`-Widget mit 3 Stimmungen
  (idle, cheer mit 8-Frame Cheer-Sprite, think mit Kopf-Tilt).
  Eingebaut im `AdaptiveTaskRenderer`: bei richtiger Antwort → cheer,
  bei falscher → think. Auto-Reset nach 2 s.
- `47053f1` Companion auch in Single-Letter- und Word-Coach
  – beide reagieren jetzt mit Lumo-Mood.
- `f177fbf` Zwei Codex-P2-Fixes am Companion: Double-Mirror beim Idle-Fox,
  Reduced-Motion-Regression bei `didUpdateWidget`.
- `5aae7c3` Neue `_SolutionPath`-Karte: nach richtiger Mathe-Antwort
  zeigt Lumo den Lösungsweg visuell als grüne Premium-Karte
  ('3 + 5 = 8' + 8 Äpfel als Bild + kindgerechter Hinweis).
- `6079c4e` Lösungsweg auch als didaktische Hilfe nach 2 Fehlern.
- `f3e70f8` `showLumoRewardBurst(stars: 1)` bei jeder richtigen
  Antwort – Sterne sprudeln raus, konsistent mit Quizshow.
- `79d9da0` Lumo wechselt aktiv auf Mood `think` während das Kind
  im Schreibcoach zeichnet (Pan-Start) – visuelle Begleitung
  während des Schreibens, nicht erst beim Prüfen.
- `dff86df` Adaptive Schwierigkeit im Single-Letter-Coach: 60% Chance
  einen schwachen Buchstaben (accuracy < 0.7 nach ≥3 Versuchen) zu
  ziehen, 40% rein zufällig. Direkte Wiederholungen werden vermieden.
- `50da340` Adaptive Wort-Auswahl im Wortdiktat: Wörter mit weakLetters
  werden bevorzugt gepickt (Mama/Oma vor Papa wenn 'O'/'M' schwach).
  Async Load – wenn das Kind schon angefangen hat, kein jarring Reset.
- `891f3fb` Lesemodus: Highlight-Wort 25→32pt, aktives Wort 22→26pt,
  Header 13→15pt. Erstklässler-Augen können besser folgen.
- `77353ec` Quizshow bekommt auch den Reaction-Companion (cheer/think
  bei richtig/falsch). Damit reagiert Lumo in allen 4 Lern-Hauptbereichen.
- `340ad4d` Lokaler Hilfe-Banner (nach 2 Fehlern) mit `LumoIdleFox`
  statt statischem Emoji + größere Texte.
- `1063a5e` Letter-Writing-Screen: Buchstabe-Titel 20→24pt, CTA
  „Jetzt schreiben üben" 18→22pt.
- `36fc7d5` App-Shell Top-Avatar + Learning-DNA-Card mit `LumoIdleFox`.
- `ddbd205` `LumoSubjectTile`-Titel 16→18pt, Untertitel 12.5→14pt.
- `367ab68` Reading-Modus Abschluss-Karte „Leserunde geschafft!" satter
  (🎉 + 26pt Titel + bessere Lesbarkeit).
- `3744937`, `0117822` **Tap auf Lumo öffnet Mini-Chat-Hint** in allen
  4 Lern-Bereichen (AdaptiveTaskRenderer + 2 Schreibcoaches + Quizshow).
  Topic-spezifischer Tipp als floating SnackBar mit 🦊-Prefix, 4 s
  sichtbar, Lumo geht parallel auf Mood `think`. Heinz' Phase-3-Plan-
  Punkt „Tap auf Lumo öffnet einen Mini-Chat" damit komplett.
- `1063a5e` Letter-Writing-Screen: Titel 20→24pt, CTA 18→22pt.
- `ad8f13a` WritingReportCard-Empfehlung (Elternbereich) mit Idle-Fox.
- `5fb7a87` Quizshow `_HintBubble` premium-isiert (Idle-Fox + Schatten
  + 15pt bold Text).
- `72be014` Quizshow JokerButton lila Premium-Stil + Pill-Form.
- `d448d8f` Quizshow ResultPanel mit Premium-Schatten, Text 13→16pt.
- `6ae1386` `_ActionCard` in Sections (Tests/Schularbeit/Mission)
  satter: 230→240px, Icon 38→44, Titel +1pt, CTA-Text 15pt.
- `a8ea67b` Reading-Mikrofon-Button 72→84px, Icon 36→42, Headline 18pt.
- `9c8ea58` Reading-Mission CTA-Button mit Gradient + Schatten, 14pt.

**Phase 4 – Lehrplan-Audit:**
- Tabelle aller 20 Module gegen ÖsterreichVS-Lehrplan: **alle konform**,
  Klasse-1-Module konservativ (bis 10 statt bis 20) als Anfänger-Stärke.
  Keine Code-Änderung nötig.

**Phase 5 – Screens premium-isiert:**
- `caa3e8f` Home: `LumoFloatingActionDock` (Akademie+Tutorial) statt eigener FAB.
- `5a235c1` Quizshow: Frage 34pt, **2×2 Grid** bei 4 Optionen, Antwortbuttons
  84px min-height + 22pt, `showLumoRewardBurst` bei richtiger Antwort.
- `93e3b02` Akademie: `LumoMagicBackground` als Untergrund, Hero-Titel 32pt.
- `7d0975e` Spielewelt: `LumoIdleFox` + Titel 17→20pt + 19→22pt.
- `a565309` Schreibcoach + Word-Diktat: Prompt-Header mit `LumoIdleFox`,
  Texte größer.

**Antwort-Regel:**
- `e679dfd` CLAUDE.md erweitert: Entscheidungen immer mit `AskUserQuestion`
  als klickbare Auswahl (Heinz tippt nicht gerne lange Antworten).

### Status am Ende der Session

- PR #50 offen, head = `47053f1`.
- CI-Status: **pending** beim letzten Check – Build noch in Queue.
  Heinz hatte erwähnt, dass alte Workflow-Runs gelegentlich die Queue
  blockieren ("durch das Löschen wieder gegangen"). Falls CI sehr
  lange hängt: alte Runs unter Actions löschen.
- Working tree clean.
- Alle Codex-Reviews bis `47053f1` adressiert (10 P1/P2 Hinweise gefixt).
- Token-Limit-Bewusstsein: Claude hat vor 99% gestoppt wie von Heinz
  angewiesen, weitere Refactors auf nächste Session verschoben.

### Was noch offen ist (NICHT in dieser Session, für später)

1. **Phase 3 Live-Strich-Erkennung** – während das Kind im Schreibcoach
   einen Buchstaben zeichnet, prüft Lumo den Strich KONTINUIERLICH und
   gibt Live-Hints ("Hmm, der Strich geht hier lang!"). Aktuell nur
   beim "Fertig"-Tap. Braucht Live-Stroke-Analyse via `LetterShapeAnalyzer`
   nach jedem Pan-End-Event, plus Performance-Sicherung. Eigene Session.
2. **Phase 2C** – Module einzeln mit `LumoMagicBackground`/`LumoPremiumCard`
   wrappen. Eigentlich überflüssig, weil `AdaptiveTaskRenderer` zentral wirkt
   – aber für Module mit eigenen Screens (z.B. Lumo Jump) sinnvoll.
3. **Phase 2E** – `SemanticLabels` für Screen-Reader-Support an Antwort-Buttons
   und Reaction-Companion.
4. **Asset-Cleanup** – alte `lumo_fox.png/.jpg` und `lumo_main.png` aus
   `assets/` löschen, sobald CI mehrfach grün war. Spart APK-Größe.
5. **Modul-Vergrößerung Lehrplan-konform** – Klasse 1 könnte optional
   bis 20 erweitert werden (aktuell bis 10); Klasse 3 schriftliches Rechnen;
   Klasse 4 Sachrechnen. Neue Module wären eigene Features.

### Empfehlung für Heinz nach Rückkehr

1. **Erst CI-Status auf PR #50 prüfen.** Falls grün → Squash-Merge nach `main`,
   APK testen. Falls rot → ersten Buildfehler in Action-Logs lesen, mir
   per Chat schicken, ich fixe.
2. **Heinz' Auftrag ist nicht "fertig"** – Phase 3 Vollausbau steht noch aus.
   Aber die App ist substantiell moderner: kein Cartoon-Fuchs mehr,
   größere Aufgaben, lebendiger Lumo-Companion, premium Screens.
3. Falls Heinz weitere Iteration will: kleine Häppchen wie heute (kein
   Mega-Refactor), CLAUDE.md-konform.


Wenn Build rot bleibt, keine Designarbeit fortsetzen, sondern Fehler fixen.
