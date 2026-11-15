# LUMO – vollständiger Lernbestand und Anschlussabdeckung

**Stand: 15.11.2026, Chat2.** Diese Liste trennt tatsächlich erreichbare Lernwege, nur deklarierte Typen und noch offene Integrationsprüfungen. „Im Code vorhanden“ bedeutet nicht „fachlich und auf jedem Gerät abgenommen“. Die Übergabe wird erst nach den unten genannten Restprüfungen als vollständig bezeichnet.

## Basis und Zuständigkeiten

- Repository: `Ullmann27/lumo-lernen`, vereinbarte Basis `6f4a8c4753f4d06d0b392da0789b8162b2faa71b`; Arbeitszweig `feature/lumo-nextgen-learning-20261115`.
- Projektanweisungen: `AGENTS.md` und `docs/agent-network/LUMO_PLAYSTORE_AGENT_TREE_20261114.md`; MiniGames zusätzlich verbindlich über `CHAT1_MINIGAMES_OWNER.md`.
- Gemeinsamer Vertrag: `lib/core/lumo_learning_session_contract.dart` und `lib/widgets/fox/lumo_companion_requests.dart`; keine konkurrierende Bus-API.
- `Ullmann27/lumo-godot` wurde zusätzlich auf Szenen, Router und Aufgabenmodelle untersucht. Kart und Dschungel bleiben außerhalb dieses Arbeitsbereichs.
- Geschützte Schreibtrainer und Journal bleiben intern unverändert. Der praktische Lernpfad öffnet das vorhandene Journal über dessen öffentlichen Screen.

## Tatsächlicher Umfang

| Bestand | Anzahl / Einordnung |
|---|---|
| Aktuell zum jeweiligen Jahrgang gehörige Fach/Einheit-Kombinationen | 236 |
| Kombinationen einschließlich Wiederholung früherer Jahrgänge | 447 |
| Mathematik | 60 Templates, 37 Generatorarten; mehrere Templates teilen eine Einheit |
| Deutsch | 32 Templates, 29 Generatorarten |
| Direkte Akademie-Module | 20 Topic-IDs → 19 Screens; bei aktivem Wortmodus übernimmt für `d1_woerter` zuerst der geschützte Wortcoach |
| Lernlabor | 6 Modi, 35 konkrete Probleme; Muster ergänzt den bisherigen Bestand |
| Geführte Lektionen | 7 Konzepte,16 Arten geprüfter Antworten |
| Lesebegleiter | 24 Texte in 4 Jahrgängen; zusätzlich separate Verständnisfragen |
| Praktische Aktivitäten | 60 Aufträge in 8 Fächern; der Fachwähler macht auch vorhandene Sprach-/Forscheraufträge erreichbar |
| Spielewelt | 50 Level, 7 GameMiniTypes über 5 Screens; Level 50 öffnet die eigene Quizshow |
| Weitere getrennte Generatoren | Denkprofil 50 Fragen; IQ-Rätsel 6 Bereiche mit Stufen 1–8; Board-/Karten-Lernfragen, Quizshow, Story und Foto-Lernstunde |

**Zählregel:** 447 Curriculum-Kombinationen decken weder die 50 Spiellevel noch Denkprofil, IQ-Rätsel, Storyfragen oder Native-Godot-Spiele ab. Diese Wege stehen ausdrücklich als eigene Prüfbereiche in `coverage.json`.

## Ablaufabdeckung je aktivem Lernpfad

Alle nachfolgenden Typ-/Einheit-Tabellen verweisen auf diese vollständigen Abläufe. Die maschinenlesbare Datei enthält dieselben sechs Pflichtfelder unter `flow_definitions`, einzelne Aufgaben unter `task_groups` und konkrete Status-/Owner-Felder.

### `regular`

**Einstieg:** Home / Lernen / Tests / Lehrerauftrag → LearningContent; exakt gewähltes Fach, Einheit und Jahrgang.

**Eingabe und Bewertung:** Auswahlantwort; tatsächliches interaktives Lernobjekt; Zahl-/Wort-/Textmarkierung. Das angezeigte geprüfte LumoTask und dessen eindeutige Lösung bestimmen die Bewertung. Generierung und Fallback passieren QualityGuard/Adapter.

**Hilfe:** TaskHintService, adaptive lokale Hilfen, alternative konkrete Darstellung; Hilfe bleibt im Versuch als Hilfe erhalten. Prüfungen sperren Hinweise.

**Abschluss und Speicherung:** Aufgabe prüfen → konkrete Rückmeldung → nächste Aufgabe → Sitzungsabschluss; Folgeplanung nutzt beobachtete Antworten. LumoAppState.recordLearningAnswer; LearningProfileEngine / ProgressRepository, AttemptLog und RewardWallet über bestehende Besitzergrenzen.

**Owner / Status:** Chat2 Hauptintegration + Logic + Interactions · `shared_rendering_implemented_integration_pending`.

Quellen: `lib/features/learning/learning_content.dart`, `lib/features/learning/adapters/legacy_lumo_task_adapter.dart`, `lib/core/school_exercise_generator.dart`, `lib/core/task_quality_guard.dart`, `lib/features/learning/renderers/adaptive_task_renderer.dart`, `lib/features/learning/widgets/interactive_task_workspace.dart`.

### `writing`

**Einstieg:** Schreiben im regulären Lernpfad; Akademie Schreibcoach / Wörter / Buchstaben A–Z.

**Eingabe und Bewertung:** Echte Stift-/Fingerstriche; Nachspuren, geführt, frei; ergänzende Texteingabe über den bestehenden Adapter. Trainer bewertet nur seine tatsächlich beobachteten Striche. Eine geübte Handschrift wird nicht als erfundene Fachlösung ausgegeben; eingegebene Vorlagen separat vergleichen.

**Hilfe:** Startpunkt, Richtung, Reihenfolge, Linienlage; bestehende Trainerhilfen; Anbindung von außen.

**Abschluss und Speicherung:** Echter Versuch / Wiederholen / Wechsel; reine Übung und bewertete Antwort unterscheiden. Bestehender WritingProgressRepository/Trainer. Adapterantworten im jeweiligen Lernpfad; interne Formate unverändert.

**Owner / Status:** geschützt; nur äußere Anbindung Chat2 · `protected_internal_unchanged`.

Quellen: `lib/features/writing/lumo_writing_coach_screen.dart`, `lib/features/writing/lumo_writing_word_coach_screen.dart`, `lib/domain/writing/writing_domain.dart`, `lib/features/teacher_mode/letter_writing_screen.dart`, `lib/features/learning/renderers/writing_task_renderer.dart`.

### `shape_trace`

**Einstieg:** Formen Nachzeichnen im bestehenden Mathematikpfad, Jahrgänge 1–2.

**Eingabe und Bewertung:** Form-Demo und tatsächliche freie Kontur; alternative Wiederholung. ShapeTraceTaskRenderer verarbeitet tatsächlichen Trace; keine Bewertung aus dem Demo-Timer.

**Hilfe:** Kontur ansehen / wiederholen / nachzeichnen; ruhiger Modus.

**Abschluss und Speicherung:** Form prüfen, konkrete Rückmeldung, weiterer Versuch oder nächste Aufgabe. Bestehende reguläre Lernspeicherung; CrossGrade gesonderte Zähler.

**Owner / Status:** Chat2 gemeinsame Renderer · `existing_renderer_connected_to_cross_grade`.

Quellen: `lib/features/learning/renderers/shape_trace_task_renderer.dart`, `lib/features/learning/widgets/lumo_shape_trace_canvas.dart`.

### `cross_grade`

**Einstieg:** Lernen → anderen Jahrgang → bestehende Einheit; praktische Aufgaben → passende digitale Ergänzung.

**Eingabe und Bewertung:** Geprüfte Auswahl, echte Workspace-Handlung, bestehender Schreib-/Formrenderer. Sprachantwort erscheint bearbeitbar und zählt erst nach Bestätigung. qualityCheckedTask(nextExact()) für dieselbe angezeigte und bewertete Aufgabe. Erster falscher Auswahlversuch bleibt offen; identisches wiederholtes Tippen zählt nicht doppelt.

**Hilfe:** Drei TaskHint-Stufen, Darstellung wechseln, Wiederholen, langsamer, Stopp/selbst versuchen, ruhiger Modus. Kanonischer Vertrag enthält aktuelle Ziel-IDs und Hilfe/Ergebnis.

**Abschluss und Speicherung:** Erklärung, zweite Chance, gesicherte Antwort, nächste Aufgabe. Modell-Reset verändert weder Ergebnis noch Hilfenhistorie. Unveränderte cross_grade_practice_v1:*:answered/correct. Additives pending_answer-Recovery-Journal schließt nur den bereits akzeptierten Schreibvorgang ab; kein reguläres XP/Profiljahrgang.

**Owner / Status:** Chat2 Inventory · `targeted_tests_passed`.

Quellen: `lib/features/learning/cross_grade_practice_screen.dart`, `lib/core/lumo_learning_session_contract.dart`, `lib/widgets/fox/lumo_companion_requests.dart`.

### `specialist`

**Einstieg:** Akademie → registrierte Topic-ID desselben Jahrgangs; Sonderfall d1_woerter wird bei Wortmodus zuerst im geschützten Wortcoach geöffnet.

**Eingabe und Bewertung:** Modulspezifische Mengen/Zeiger/Münzen/Bilder/Wörter und Antwortauswahl; Wort-Diktat mit tatsächlicher Eingabe. Unveränderte konkrete Modul-Lösungslogik. Methodenhilfe ist beim nächsten saveAnswer ausdrücklich assisted; keine falsche Selbstständigkeit.

**Hilfe:** Gemeinsame Frame: Ziel, drei Methodenschritte, selbst weiterarbeiten, ruhiger Modus. Exakte Zahlen-/Objekt-Hilfen vom jeweiligen Aufgabenbesitzer.

**Abschluss und Speicherung:** Modul-Rückmeldung → nächste Aufgabe; Ergebnisdialog und echter Neustart. SaveRetry verhindert Fortsetzen vor erfolgreicher Speicherung. LearningModuleProgress mit erfasstem Profilbesitzer; Plus hat eigene bestehende Besitzer-/Retry-Grenze. IDs, Einheiten, Rewards unverändert.

**Owner / Status:** Chat2 Inventory (Frame/Progress); paralleler Chat2 2f607 (18 genaue Kontexte) · `frame_and_storage_tested_exact_context_integration_pending`.

Quellen: `lib/features/learning_modules/learning_module_registry.dart`, `lib/widgets/design/lumo_learning_module_frame.dart`, `lib/features/learning_modules/learning_module_progress.dart`.

### `lab`

**Einstieg:** Home / Lernen → Lernlabor → vorhandenes Thema.

**Eingabe und Bewertung:** Konkretes Beispiel, Mengen bewegen, Tokens/Silben ordnen, Pflanzenteile zuordnen, Bruchteile und Muster. LabProblem.isValid vor Anzeige; accepts/modelAccepts aus lokalen Regeln. Geführtes Legen ist Beobachtung, unabhängige Antwort separat.

**Hilfe:** Fünf explizite Hinweise, Darstellungswechsel; genaue gemeinsame Szenen 8+5/Banane/Formenmuster.

**Abschluss und Speicherung:** Beispiel → Bauen → Abrufen → Übertragen → Reflexion; Wiederholen und Fortsetzen. LearningModuleProgress.saveObservation/saveAnswer und bestehendes LearningEvidence.

**Owner / Status:** Chat2 Root Katalog; paralleler Chat2 2f607 Screen/Resume/Commands · `catalog_validated_screen_integration_pending`.

Quellen: `lib/features/learning/lab/learning_lab_catalog.dart`, `lib/features/learning/lab/learning_lab_screen.dart`, `lib/features/learning/lab/learning_manipulatives.dart`.

### `guided`

**Einstieg:** Geführtes Lernen / passende Einführung vor einem regulären Thema.

**Eingabe und Bewertung:** Zähl- und Teilhandlungen, Auswahl, Silben, Pflanzenteil, Zehner-/Hunderterbrücke, Bruchbild. GuidedLessonStep.expected/accepts; 16 Antwortarten, eigene local evidence.

**Hilfe:** Gestufte Hilfen und leichtere Übung; visuelle/native Modelle.

**Abschluss und Speicherung:** Einführung → Beispiel → begleitet → selbstständig → Check → Rückblick. LearningModuleProgress; freiwilliges Entdecken nutzt bestehendes DiscoveryProgress ohne erfundene Schulantwort.

**Owner / Status:** paralleler Chat2 2f607 · `existing_flow_new_contract_integration_pending`.

Quellen: `lib/domain/tutoring/guided_lesson_catalog.dart`, `lib/features/tutoring/guided_lesson_screen.dart`.

### `reading`

**Einstieg:** App-Sektion Lesen → bestehender ReadingContent.

**Eingabe und Bewertung:** Vorlesen über echte Spracherkennung; Berührung/Alternative; abschnittsweise Textansicht. ReadingAttemptDecision/Monitor. Nicht bestätigte oder nicht passende ASR zählt ausdrücklich nicht als falsche Fachantwort.

**Hilfe:** Wiederholung, langsam lesen, Silben-/Satzansicht und lokale Begleitung.

**Abschluss und Speicherung:** Abschnitt bearbeiten → Wiederholung / nächster Satz → Lesesitzung. ReadingProgressRepository/AttemptHistory; recordLearningAnswer nur akzeptierte erfolgreiche Lesepraxis, ohne Rohtranskript.

**Owner / Status:** Chat2 Lesen / Chat4 Sprache · `source_reviewed_end_to_end_voice_pending`.

Quellen: `lib/features/reading/reading_content.dart`, `lib/domain/reading/reading_domain.dart`, `lib/domain/reading/reading_attempt_history.dart`, `lib/core/reading_progress_repository.dart`.

### `reading_buddy`

**Einstieg:** Home / Akademie → Lesebegleiter.

**Eingabe und Bewertung:** 24 Jahrgangstexte; Wort-für-Wort-Anzeige, echtes Mikrofon oder selbst lesen; Verständnisfragen per Auswahl. VoiceReadingEvaluator liefert tentative matched/partial/pending. Fachlich gespeicherte Verständnisfragen werden gegen question.correctIndex geprüft.

**Hilfe:** Vorlesen, einzelne Wörter/Silben hervorheben; Wiederholen.

**Abschluss und Speicherung:** Text lesen → Verständnisfragen → nächster Text / Wiederholung. Verständnisfragen über LearningModuleProgress; keine automatisch falschen Fachantworten aus unsicherer Worterkennung.

**Owner / Status:** Chat2 Lesen / Chat4 Sprache · `source_reviewed_runtime_capture_pending`.

Quellen: `lib/features/reading/lumo_reading_buddy_screen.dart`, `lib/features/reading/voice_reading_evaluator.dart`, `lib/features/reading/reading_text_library.dart`, `lib/features/reading/reading_comprehension.dart`.

### `story`

**Einstieg:** Home / Deutsch / MagicHub / QuestHub → Bibliothek → StoryReader.

**Eingabe und Bewertung:** Leseseiten, StoryExercise-Auswahl, Hinweise im Buch, offene getippte oder gesprochene Zusammenfassung. StoryExercise.correctAnswer; offene Zusammenfassung nutzt konservative Keyword-Hilfe und darf keine vollständige semantische Bewertung behaupten.

**Hilfe:** Seite vorlesen, Fundstellen zeigen, erneut lesen, Antwort selbst ändern.

**Abschluss und Speicherung:** Seiten / Fragen / Zusammenfassung → gespeicherter Buchabschluss und Wiederlesen. Bestehende LumoStoryLibrary/StorySession und Wallet; aktuelle Reparatur schützt bestätigte Antworten und Wiederholungen.

**Owner / Status:** Chat2 Interactions · `modernization_in_progress`.

Quellen: `lib/features/story/lumo_story_reader_screen.dart`, `lib/features/story/lumo_story_library_screen.dart`, `lib/features/story/lumo_quest_hub_screen.dart`, `lib/core/lumo_story_summary_scoring.dart`.

### `photo`

**Einstieg:** Home → Foto-Lernstunde.

**Eingabe und Bewertung:** Gescannten Auftrag ansehen; daraus fünf konkrete Aufgaben. ScannedWorkAnalysis ist ein Vorschlag; generierte Aufgaben müssen vor Anzeige geprüft und anschließend real beantwortet werden.

**Hilfe:** Erklärung zur erkannten Einheit und gestufte echte Hilfe; unsichere Erkennung transparent halten.

**Abschluss und Speicherung:** Bisher nur Lösungskarten; Root ergänzt vollständige Aufgaben-/Antwortstrecke. Vorher keine Lernantwortspeicherung der fünf Karten; neue Strecke muss vorhandene Besitzer-/Rewardpfade nutzen.

**Owner / Status:** Chat2 Root · `modernization_in_progress`.

Quellen: `lib/features/photo_lesson/lumo_photo_lesson_screen.dart`, `lib/features/photo_lesson/photo_lesson_practice.dart`, `lib/core/scanned_work_analysis.dart`.

### `game_level`

**Einstieg:** Spielewelt → freigeschaltetes Level1–50. Level 50 öffnet tatsächlich QuizShow.

**Eingabe und Bewertung:** 7 GameMiniTypes über fünf Screens: Auswahl/Prüfen, Rechenhaus, zehn Kästchen, Buchstabenlücke, Zahlen-/Wortfolgen. GameMathTasks/GameLessonTasks sowie LetterFill/ColorBoxes eigene Generatoren; getrennt von den447 Curriculum-Kombinationen prüfen.

**Hilfe:** Anleitung / Rückmeldung bisher je Screen; konkrete kanonische Kontexte und Methodenschritte werden ergänzt.

**Abschluss und Speicherung:** Levelrunde → echte Ergebnissicherung → Sterne / Wiederholen / Folgelevel. GameProgressRepository mit bestehenden Child-/Level-IDs und Wallet. False-Write/Retry/Profilwechsel/Mid-round Resume werden in dieser Runde gehärtet.

**Owner / Status:** Chat2 Inventory (verbindlich CHAT1_MINIGAMES_OWNER.md) · `modernization_in_progress`.

Quellen: `lib/features/games/games_content.dart`, `lib/features/games/mini_games/stars_path_game.dart`, `lib/features/games/mini_games/number_house_game.dart`, `lib/features/games/mini_games/color_boxes_game.dart`, `lib/features/games/mini_games/letter_fill_game.dart`, `lib/features/games/mini_games/lesson_trail_game.dart`, `lib/domain/games/game_math_tasks.dart`, `lib/domain/games/game_lesson_tasks.dart`, `lib/core/game_progress_repository.dart`.

### `board_games`

**Einstieg:** Spielewelt → Memory / Vier gewinnt / Lumo Cards.

**Eingabe und Bewertung:** Regelgerechte Brett-/Kartenaktionen plus vorhandene Lernfrage-Overlays. Spielregel-Engine ist keine Fachbewertung; Fragen stammen aus LearningQuestionRepository mit echten Antwortregeln.

**Hilfe:** Spielanleitungen und vorhandene Fragenhilfe; sprachliche Integration separat nachweisen.

**Abschluss und Speicherung:** Partie → Ergebnis und Rematch; Frage und Spielzug getrennt behandeln. Vorhandene Board-/Card-/Memory-Sessions und native Tokens; bestehende Rewards/IDs erhalten.

**Owner / Status:** Main Gesamtintegration / vorhandene Spielowner · `source_reviewed_separate_generators_not_claimed_by_curriculum_tests`.

Quellen: `lib/features/games/lumo_cards/learning_question_repository.dart`, `lib/features/games/lumo_cards/lumo_cards_game_controller.dart`, `lib/features/games/connect_four/lumo_connect_four_game.dart`, `lib/features/games/memory/lumo_memory_game.dart`.

### `quiz`

**Einstieg:** Spielewelt → Quizshow; Level 50 → dieselbe QuizShowContent.

**Eingabe und Bewertung:** Bestehende Auswahlantworten, Rundenfolge und Joker. QuizQuestionBank/QuizShowController; eigene Fragenbank, keine automatische Abdeckung durch ExerciseFactory.

**Hilfe:** Bestehende Joker, Rückmeldung und Erklärung; als eigener Testpfad prüfen.

**Abschluss und Speicherung:** 20-Fragen-Finale → QuizShow-Ergebnis. QuizShowRepository und vorhandener Rewardpfad.

**Owner / Status:** Main / Quiz-Owner · `source_reviewed_separate_generator`.

Quellen: `lib/features/quiz/quiz_show_content.dart`, `lib/domain/quiz/quiz_question_bank.dart`, `lib/features/quiz/quiz_show_repository.dart`.

### `cognitive`

**Einstieg:** Tests → Denkprofil.

**Eingabe und Bewertung:** Muster-, Zahl-, Sprach-, Raum- und Merkfragen;50 konkrete Fragen,10 pro Bereich. CognitiveProfileGenerator/Scorer: tatsächlich richtige Antworten je Bereich. Keine normierte Intelligenzzahl.

**Hilfe:** Testanweisungen/Stimulus; Tests sind kein automatisch helfender Übungsmodus.

**Abschluss und Speicherung:** Fragenfolge → echte Rohleistungsübersicht → Wiederholung. CognitiveProfileRepository und AttemptLog; Besitzer-/False-Write-Reparatur in Arbeit.

**Owner / Status:** Chat2 Logic · `modernization_in_progress`.

Quellen: `lib/features/tests/cognitive_profile_screen.dart`, `lib/core/cognitive_profile_generator.dart`, `lib/core/cognitive_profile_scorer.dart`, `lib/core/cognitive_profile_repository.dart`, `lib/domain/cognitive/cognitive_profile.dart`.

### `iq_puzzles`

**Einstieg:** Tests → IQ-Rätsel / Explorer.

**Eingabe und Bewertung:** Matrix, Figurenfolge, Ausreißer, Rotation, Zahlen, Merkfolge; Klassen1–4 starten aufStufe2–5, Stufen1–8. IqPuzzle.isCorrect; konkrete sichtbare Figurenidentität. Nächstes Level aus gelöst/nicht gelöst; kein IQ-Wert.

**Hilfe:** Bereichsanleitung, Rückblick mit wirklichen Aufgaben und Erklärungen.

**Abschluss und Speicherung:** Aktiver Explorer36Rätsel;24-Konfiguration im Sessionmodell. Ergebnis/Rückblick. IqTestRepository, bestehende Version/IDs/Profilidentität; Logic prüft Generatoren und Schreibschäden.

**Owner / Status:** Chat2 Logic · `modernization_in_progress`.

Quellen: `lib/features/tests/iq_test_screen.dart`, `lib/core/iq/iq_test_session.dart`, `lib/core/iq/iq_puzzle_generator.dart`, `lib/core/iq/iq_test_repository.dart`, `lib/domain/iq/iq_puzzle.dart`.

### `practical`

**Einstieg:** Home / Lernen → praktisches Fach; neuer Fachwähler erreicht alle60 vorhandenen Aktivitäten in8Fächern.

**Eingabe und Bewertung:** Reale Beobachtung/Gestaltung/Bewegung; konkrete Material-/Arbeits-/Erklärschritte. Passende vorhandene digitale Ergänzungen. Offene Ergebnisse anhand des vorhandenen Evidence-/Kompetenzauftrags mit erwachsener Rückmeldung; kein erfundenes Richtig/Falsch.

**Hilfe:** Auftrag in3Schritten, erforderliche Begleitung klar; Journal als tatsächlicher bestehender Dokumentationsweg.

**Abschluss und Speicherung:** Auftrag ausführen → eigene Beobachtung erklären → im bestehenden Journal festhalten; native Ergänzung bescheinigt keine körperliche Leistung. Geschütztes Journal über bestehenden Screen; kein neuer falscher Schul-/Rewardzähler. Strukturierter Lehrer-Nachweis bleibt gesonderte offene Integration.

**Owner / Status:** Chat2 Inventory; Main ergänzt zusätzliche Werkzeug-Einstiege · `links_implemented_route_test_pending`.

Quellen: `lib/core/curriculum/primary_activity_catalog.dart`, `lib/features/learning/curriculum_activities_screen.dart`, `lib/features/journal/lumo_journal_screen.dart`.

### `cross_grade_writing`

**Einstieg:** Akademie → andere Klasse4 → Aufsatz.

**Eingabe und Bewertung:** Eigener Text zu vier vorhandenen Schreibaufträgen. Eigene Gliederungs-/Sprachcheckliste; keine automatisch behauptete semantische Benotung.

**Hilfe:** Schreibanregung und Anfang/Hauptteil/Schluss bzw. passende Brief-/Sachtextregeln.

**Abschluss und Speicherung:** Entwurf speichern, nächsten Auftrag wählen, wieder öffnen. Bestehende cross_grade_writing_v1:-Entwürfe; reguläre Klasse/XP unverändert.

**Owner / Status:** Chat2 äußere Anbindung; bestehender Editor · `existing_route_unchanged`.

Quellen: `lib/features/learning/cross_grade_writing_screen.dart`.

### `live`

**Einstieg:** Home / MagicHub → LUMO Live → Wort-Magie / Foto-Quiz / Tier-Safari.

**Eingabe und Bewertung:** Echte Spracherkennung, Foto und sichtbare Tierbilder. Wort-/Fotoantworten sind Teilnahme; Safari benutzt derzeit unbestätigte ASR contains/Editdistanz. Das braucht Bestätigungs-/Unsicherheitsweg.

**Hilfe:** Wiederholen, Sprechen, Bild/Foto; keine Fachfehler aus unbestätigter ASR ableiten.

**Abschluss und Speicherung:** Modus-/Aufgabenwechsel sind bereits revisionsgeschützt; fachlicher Bestätigungsschritt offen an Sprachowner gemeldet. Bestehende Wallet/Cosmos-Teilnahmebelohnungen; keine neue Diagnose.

**Owner / Status:** Chat4 über Chat1; keine fremden Sprachdateien durch Inventory · `asr_confirmation_gap_escalated`.

Quellen: `lib/features/live/lumo_live_pro_screen.dart`.

### `native_learning`

**Einstieg:** Flutter LearningContent / GuidedLesson / English-Lektion → launchLumo3D(scene:learning).

**Eingabe und Bewertung:** 10 geprüfte NativeLearningActivity-Arten mit echten räumlichen Objekten. Native Ansicht ist eine begleitet beobachtete Handlung; die Flutter-Aufgabenlogik bleibt Antwortbesitzer.

**Hilfe:** Mengen, Zehner/Hunderter, Gruppen, Brüche, Silben, Pflanzenteile, Englischobjekte.

**Abschluss und Speicherung:** Native Handlung / Rückkehr zur unveränderten Flutter-Aufgabe. Vorhandener HostBridge-Vertrag, Besitzer-/Generation-/Token-Grenzen; keine doppelte fachliche Belohnung.

**Owner / Status:** paralleler Chat2 2f607 / Chat3 Assetowner / Chat1 Integration · `native_runtime_not_executed_by_inventory`.

Quellen: `lib/domain/tutoring/native_learning_activity.dart`, `lib/features/lumo3d/lumo3d_launcher.dart`, `lumo-godot:scripts/learning/learning_activity.gd`, `lumo-godot:scripts/learning/learning_world.gd`, `lumo-godot:scenes/learning/learning_world.tscn`.

### `native_standalone_reading`

**Einstieg:** Godot SceneRouter learn/reading_hub im Standalone; eingebettetes goto(learn) kehrt nach Flutter zurück. Kein direkter Flutter-Aufrufer dieser vier Szenen gefunden.

**Eingabe und Bewertung:** Alphabet drehen/antippen; Wort-Bild-Auswahl; Anlaut-Buchstabe; Wort bauen. Eigene Godot-Logik/ProgressStore; getrennt von Flutter-Curriculum.

**Hilfe:** Vorhandene Wort-/Lautausgabe und LUMO-Behaviour; keine neue Abdeckung behauptet.

**Abschluss und Speicherung:** Mini-Spiel → ReadingHub → Home. Godot ProgressStore, native Formate unverändert.

**Owner / Status:** Chat1/3 native Integrationsowner · `standalone_route_source_reviewed_host_route_not_active`.

Quellen: `lumo-godot:scripts/app/scene_router.gd`, `lumo-godot:scripts/games/reading_hub.gd`, `lumo-godot:scripts/games/alphabet_carousel.gd`, `lumo-godot:scripts/games/multi_choice_game.gd`, `lumo-godot:scripts/games/word_build_game.gd`.

## Sämtliche aktuell jahrgangsbezogenen Einheiten

Diese Liste wird direkt aus `Curriculum.exerciseSubjectsForGrade` und `Curriculum.unitsForGrade(..., currentGradeOnly: true)` erzeugt. Dadurch werden zusätzliche Adventure-Einheiten mitgezählt und unbenutzte statische Katalogüberschriften nicht als fertige Aufgaben ausgegeben.

| Jahrgang | Fach | Gefundene Einheiten | Ablauf |
|---|---|---|---|
| 1 | Mathematik | Textaufgaben; Plus bis 10; Minus bis 10; Plus bis 20; Minus bis 20; Zahlenstrahl; Mengenvergleich; Zahl in Worten; Geometrie Formen; Geld; Zeit; Symmetrie; Formen Nachzeichnen; Rechengeschichten; Zahlenmauer; Zahlenrätsel; Marktstand; Platzhalter-Rätsel; Größer, kleiner, gleich | regular; Formen Nachzeichnen→shape_trace; andere Klasse→cross_grade |
| 1 | Deutsch | Buchstaben-Lautierung; Reime; Anfangslaute; Endlaute; Wort-Bild-Zuordnung; Erste Sätze; Silben; Artikel; Wortdetektiv; Silbenrätsel; Begleiter-Rätsel; Gegenteil-Geschichten | regular; Formen Nachzeichnen→shape_trace; andere Klasse→cross_grade |
| 1 | Lesen | Woerter lesen; Sätze lesen; Lesesinn; Bild und Wort; Reihenfolge | regular; Formen Nachzeichnen→shape_trace; andere Klasse→cross_grade |
| 1 | Rechtschreibung | Haeufige Woerter; Gross und klein; Doppelmitlaut; Dehnungen; Satzzeichen; Wortende; St oder Sp | regular; Formen Nachzeichnen→shape_trace; andere Klasse→cross_grade |
| 1 | Schreiben | Buchstaben nachspuren; Wort schreiben; Satz abschreiben; Schwunguebung; Zahlen schreiben | writing; andere Klasse→cross_grade |
| 1 | Sachunterricht | Verkehr; Familie und Gemeinschaft; Zeit und Kalender; Körper; Tag und Nacht; Pflanzen; Wetter; Jahreszeiten; Tiere; Wer bin ich?; Monate und Wochentage | regular; Formen Nachzeichnen→shape_trace; andere Klasse→cross_grade |
| 1 | Englisch | Farben; Tiere; Begruessung; Familie; Zahlen; Körper; Schulsachen | regular; Formen Nachzeichnen→shape_trace; andere Klasse→cross_grade |
| 1 | Logik | Muster; Reihenfolgen; Was passt nicht? | regular; Formen Nachzeichnen→shape_trace; andere Klasse→cross_grade |
| 2 | Mathematik | Textaufgaben; Plus bis 20; Minus bis 20; Plus bis 100; Minus bis 100; Einmaleins; Einmaleins Vorbereitung; Geld wechseln; Uhrzeit; Längen; Gerade und ungerade; Verdoppeln und Halbieren; Zehner und Einer; Formen Nachzeichnen; Uhr-Abenteuer | regular; Formen Nachzeichnen→shape_trace; andere Klasse→cross_grade |
| 2 | Deutsch | Wortfamilien; Einzahl und Mehrzahl; Verkleinerungsform; Gegenteile; Oberbegriffe; Namenwoerter; Tunwoerter; Wiewoerter; Wörter zusammensetzen; Wortarten-Jagd; Satzbaustelle | regular; Formen Nachzeichnen→shape_trace; andere Klasse→cross_grade |
| 2 | Lesen | Woerter lesen; Sätze lesen; Lesesinn; Bild und Wort; Reihenfolge | regular; Formen Nachzeichnen→shape_trace; andere Klasse→cross_grade |
| 2 | Rechtschreibung | Haeufige Woerter; Gross und klein; Doppelmitlaut; Dehnungen; Satzzeichen; Wortende; St oder Sp | regular; Formen Nachzeichnen→shape_trace; andere Klasse→cross_grade |
| 2 | Schreiben | Buchstaben nachspuren; Wort schreiben; Satz abschreiben; Schwunguebung; Zahlen schreiben | writing; andere Klasse→cross_grade |
| 2 | Sachunterricht | Zeit und Kalender; Verkehr; Berufe; Körper; Familie und Gemeinschaft; Wetter; Pflanzen; Tiere; Jahreszeiten | regular; Formen Nachzeichnen→shape_trace; andere Klasse→cross_grade |
| 2 | Englisch | Zahlen; Körper; Spielzeug; Tiere | regular; Formen Nachzeichnen→shape_trace; andere Klasse→cross_grade |
| 2 | Logik | Zahlenmuster; Geheimcode | regular; Formen Nachzeichnen→shape_trace; andere Klasse→cross_grade |
| 3 | Mathematik | Einmaleins; Schriftliche Addition; Schriftliche Subtraktion; Brüche Vorbereitung; Sachaufgaben zwei Schritte; Umfang; Plus bis 100; Minus bis 100; Plus bis 1000; Minus bis 1000; Division einstellig; Geld bis 100 Euro; Massen Kilogramm und Gramm | regular; Formen Nachzeichnen→shape_trace; andere Klasse→cross_grade |
| 3 | Deutsch | Synonyme; Wortarten; Zeitformen; Steigerung; Verbformen; Wer-Fall und Wen-Fall; Großschreibung; ie oder i | regular; Formen Nachzeichnen→shape_trace; andere Klasse→cross_grade |
| 3 | Lesen | Woerter lesen; Sätze lesen; Lesesinn; Bild und Wort; Reihenfolge | regular; Formen Nachzeichnen→shape_trace; andere Klasse→cross_grade |
| 3 | Rechtschreibung | Haeufige Woerter; Gross und klein; Doppelmitlaut; Dehnungen; Satzzeichen; Wortende; St oder Sp | regular; Formen Nachzeichnen→shape_trace; andere Klasse→cross_grade |
| 3 | Schreiben | Buchstaben nachspuren; Wort schreiben; Satz abschreiben; Schwunguebung; Zahlen schreiben | writing; andere Klasse→cross_grade |
| 3 | Sachunterricht | Wasserkreislauf; Ernährung; Bundesländer Österreichs; Verkehr; Pflanzen; Körper; Zeit und Kalender; Wetter; Familie und Gemeinschaft; Berufe; Tiere; Österreich-Reise | regular; Formen Nachzeichnen→shape_trace; andere Klasse→cross_grade |
| 3 | Englisch | Schulsachen; Wetter; Essen; Tageszeit; Alltagssätze | regular; Formen Nachzeichnen→shape_trace; andere Klasse→cross_grade |
| 3 | Logik | Schlussfolgern | regular; Formen Nachzeichnen→shape_trace; andere Klasse→cross_grade |
| 4 | Mathematik | Schriftliche Multiplikation; Schriftliche Division; Bruchrechnen einfach; Dezimalzahlen; Sachaufgaben drei Schritte; Diagramme lesen; Vergleichen; Plus bis 10000; Minus bis 10000; Zahlenraum bis 1 Million; Zeit Minuten und Stunden; Hohlmaße Liter und Milliliter; Brüche erweitern; Mittelwert; Flächeninhalt; Symmetrieachsen | regular; Formen Nachzeichnen→shape_trace; andere Klasse→cross_grade |
| 4 | Deutsch | Satzglieder; Direkte Rede; Kommas in Aufzählungen; Zusammensetzungen; Die 4 Fälle; dass oder das; Umstandswörter; Vorvergangenheit | regular; Formen Nachzeichnen→shape_trace; andere Klasse→cross_grade |
| 4 | Lesen | Woerter lesen; Sätze lesen; Lesesinn; Bild und Wort; Reihenfolge | regular; Formen Nachzeichnen→shape_trace; andere Klasse→cross_grade |
| 4 | Rechtschreibung | Haeufige Woerter; Gross und klein; Doppelmitlaut; Dehnungen; Satzzeichen; Wortende; St oder Sp | regular; Formen Nachzeichnen→shape_trace; andere Klasse→cross_grade |
| 4 | Schreiben | Buchstaben nachspuren; Wort schreiben; Satz abschreiben; Schwunguebung; Zahlen schreiben | writing; andere Klasse→cross_grade |
| 4 | Sachunterricht | Stromkreise; Ökosysteme; Geschichte; Geografie Österreich; Kontinente und Ozeane; Diagramme lesen | regular; Formen Nachzeichnen→shape_trace; andere Klasse→cross_grade |
| 4 | Englisch | Verben; Wochentage; Hobbys; Länder; Alltagssätze | regular; Formen Nachzeichnen→shape_trace; andere Klasse→cross_grade |
| 4 | Logik | Regeln kombinieren | regular; Formen Nachzeichnen→shape_trace; andere Klasse→cross_grade |

## Templates und vorhandene Schwierigkeitsstufen

### Mathematik – alle60Vorlagen

| Kennung | Klasse | Einheit | Generatorart |
|---|---|---|---|
| `g1_word_problem` | 1 | Textaufgaben | `wordProblemOneStep` |
| `g2_sub_story` | 2 | Textaufgaben | `wordProblemOneStep` |
| `g1_add_10` | 1 | Plus bis 10 | `addition` |
| `g1_sub_10` | 1 | Minus bis 10 | `subtraction` |
| `g1_add_20` | 1 | Plus bis 20 | `addition` |
| `g1_sub_20` | 1 | Minus bis 20 | `subtraction` |
| `g1_number_line` | 1 | Zahlenstrahl | `numberLineMissing` |
| `g1_quantity_compare` | 1 | Mengenvergleich | `quantityCompare` |
| `g1_number_word` | 1 | Zahl in Worten | `numberWord` |
| `g1_shapes` | 1 | Geometrie Formen | `shapeRecognition` |
| `g1_money_more` | 1 | Geld | `moneyCompare` |
| `g1_day_hours` | 1 | Zeit | `dayHours` |
| `g1_symmetry` | 1 | Symmetrie | `symmetry` |
| `g2_add_20` | 2 | Plus bis 20 | `addition` |
| `g2_sub_20` | 2 | Minus bis 20 | `subtraction` |
| `g2_add_100` | 2 | Plus bis 100 | `addition` |
| `g2_sub_100` | 2 | Minus bis 100 | `subtraction` |
| `g2_tables` | 2 | Einmaleins | `multiplication` |
| `g2_times_prep` | 2 | Einmaleins Vorbereitung | `multiplicationPrep` |
| `g2_word_problem` | 2 | Textaufgaben | `wordProblemOneStep` |
| `g2_money_change` | 2 | Geld wechseln | `moneyChange` |
| `g2_clock` | 2 | Uhrzeit | `clockTime` |
| `g2_length` | 2 | Längen | `lengthConversion` |
| `g2_even_odd` | 2 | Gerade und ungerade | `evenOdd` |
| `g2_half_double` | 2 | Verdoppeln und Halbieren | `halfDouble` |
| `g2_tens_ones` | 2 | Zehner und Einer | `tensOnes` |
| `g3_tables` | 3 | Einmaleins | `multiplication` |
| `g3_written_add` | 3 | Schriftliche Addition | `writtenAddition` |
| `g3_written_sub` | 3 | Schriftliche Subtraktion | `writtenSubtraction` |
| `g3_fraction_half` | 3 | Brüche Vorbereitung | `fractionHalf` |
| `g3_two_step` | 3 | Sachaufgaben zwei Schritte | `wordProblemTwoStep` |
| `g3_perimeter` | 3 | Umfang | `perimeter` |
| `g3_add_100` | 3 | Plus bis 100 | `addition` |
| `g3_sub_100` | 3 | Minus bis 100 | `subtraction` |
| `g3_add_1000` | 3 | Plus bis 1000 | `addition` |
| `g3_sub_1000` | 3 | Minus bis 1000 | `subtraction` |
| `g3_division_basic` | 3 | Division einstellig | `division` |
| `g3_money_change_100` | 3 | Geld bis 100 Euro | `moneyChange` |
| `g3_mass` | 3 | Massen Kilogramm und Gramm | `massConversion` |
| `g4_written_mul` | 4 | Schriftliche Multiplikation | `writtenMultiplication` |
| `g4_written_div` | 4 | Schriftliche Division | `division` |
| `g4_fraction_add` | 4 | Bruchrechnen einfach | `simpleFractionAdd` |
| `g4_decimal` | 4 | Dezimalzahlen | `decimals` |
| `g4_three_step` | 4 | Sachaufgaben drei Schritte | `wordProblemThreeStep` |
| `g4_chart` | 4 | Diagramme lesen | `chartRead` |
| `g4_compare` | 4 | Vergleichen | `compare` |
| `g4_add_10000` | 4 | Plus bis 10000 | `addition` |
| `g4_sub_10000` | 4 | Minus bis 10000 | `subtraction` |
| `g4_compare_1mio` | 4 | Zahlenraum bis 1 Million | `compare` |
| `g4_time_minutes` | 4 | Zeit Minuten und Stunden | `timeMinutes` |
| `g4_volume` | 4 | Hohlmaße Liter und Milliliter | `volumeConversion` |
| `g4_fraction_expand` | 4 | Brüche erweitern | `fractionExpand` |
| `g4_average` | 4 | Mittelwert | `average` |
| `g4_area` | 4 | Flächeninhalt | `area` |
| `g4_symmetry_lines` | 4 | Symmetrieachsen | `symmetry` |
| `g1_trace_square` | 1 | Formen Nachzeichnen | `shapeTrace` |
| `g1_trace_circle` | 1 | Formen Nachzeichnen | `shapeTrace` |
| `g1_trace_triangle` | 1 | Formen Nachzeichnen | `shapeTrace` |
| `g2_trace_rectangle` | 2 | Formen Nachzeichnen | `shapeTrace` |
| `g2_trace_star` | 2 | Formen Nachzeichnen | `shapeTrace` |

Die Zahlenbereiche `range_a` und `range_b` sind pro Vorlage unverändert in `coverage.json` erfasst. Die60Vorlagen enthalten37verschiedene Generatorarten; ein Templatebereich allein garantiert noch nicht die Lösbarkeit jeder Variante. Dafür ist der separate deterministische Qualitätscheck verantwortlich.

### Deutsch – alle32Vorlagen

| Kennung | Klasse | Einheit | Generatorart |
|---|---|---|---|
| `g1_letter_sound` | 1 | Buchstaben-Lautierung | `letterSound` |
| `g1_rhyme` | 1 | Reime | `rhymeRecognition` |
| `g1_start_sound` | 1 | Anfangslaute | `startSound` |
| `g1_end_sound` | 1 | Endlaute | `endSound` |
| `g1_word_image` | 1 | Wort-Bild-Zuordnung | `wordImage` |
| `g1_sentence_order` | 1 | Erste Sätze | `sentenceOrder` |
| `g1_syllables` | 1 | Silben | `syllables` |
| `g1_articles` | 1 | Artikel | `article` |
| `g2_family` | 2 | Wortfamilien | `wordFamily` |
| `g2_plural` | 2 | Einzahl und Mehrzahl | `plural` |
| `g2_diminutive` | 2 | Verkleinerungsform | `diminutive` |
| `g2_opposites` | 2 | Gegenteile | `opposites` |
| `g2_categories` | 2 | Oberbegriffe | `categories` |
| `g2_nouns` | 2 | Namenwoerter | `wordTypes` |
| `g2_verbs` | 2 | Tunwoerter | `wordTypes` |
| `g2_adjectives` | 2 | Wiewoerter | `wordTypes` |
| `g3_synonyms` | 3 | Synonyme | `synonyms` |
| `g3_word_types` | 3 | Wortarten | `wordTypes` |
| `g3_tense` | 3 | Zeitformen | `pastTense` |
| `g3_comparison` | 3 | Steigerung | `comparison` |
| `g3_verb_form` | 3 | Verbformen | `verbForm` |
| `g3_case_nom_akk` | 3 | Wer-Fall und Wen-Fall | `caseNomAkk` |
| `g3_capitalization` | 3 | Großschreibung | `capitalization` |
| `g3_ie_or_i` | 3 | ie oder i | `ieOrI` |
| `g4_sentence_parts` | 4 | Satzglieder | `sentenceParts` |
| `g4_direct_speech` | 4 | Direkte Rede | `directSpeech` |
| `g4_commas` | 4 | Kommas in Aufzählungen | `commas` |
| `g4_compounds` | 4 | Zusammensetzungen | `compounds` |
| `g4_four_cases` | 4 | Die 4 Fälle | `fourCases` |
| `g4_dass_das` | 4 | dass oder das | `dassDas` |
| `g4_adverbs` | 4 | Umstandswörter | `adverbs` |
| `g4_plusquam` | 4 | Vorvergangenheit | `plusquamperfect` |

## Direkte Module: IDs und vorhandene Speicherbezeichnungen

Die Speicherbezeichnung ist absichtlich nicht mit jedem sichtbaren Titel identisch. Beispielsweise bleiben `Zahlen 1-10`, `Der/Die/Das` und `Erste Wörter` erhalten; eine modernere Anzeige benennt keine alten Lernstände um.

| Topic-ID | Klasse | Screen | gespeichertes Fach / Einheit | Umfang |
|---|---|---|---|---|
| `m1_plus10` | 1 | `PlusBis10Screen` | Mathematik / Plus bis 10 | `30` |
| `m1_minus10` | 1 | `MinusBis10Screen` | Mathematik / Minus bis 10 | `30` |
| `m1_zahlen10` | 1 | `ZahlenBis10Screen` | Mathematik / Zahlen 1-10 | `12` |
| `m1_formen` | 1 | `FormenScreen` | Mathematik / Formen | `12` |
| `s1_tiere` | 1 | `TiereScreen` | Sachunterricht / Tiere | `30` |
| `s1_farben` | 1 | `FarbenScreen` | Sachunterricht / Farben | `30` |
| `m2_uhr` | 2 | `UhrLernenScreen` | Mathematik / Die Uhr | `8` |
| `m2_geld` | 2 | `GeldScreen` | Mathematik / Geld | `30` |
| `m2_zahlen100` | 2 | `ZahlenBis100Screen` | Mathematik / Zahlen bis 100 | `12` |
| `d2_artikel` | 2 | `ArtikelLernenScreen` | Deutsch / Der/Die/Das | `12` |
| `d2_mehrzahl` | 2 | `MehrzahlScreen` | Deutsch / Mehrzahl | `30` |
| `s2_jahreszeiten` | 2 | `JahreszeitenScreen` | Sachunterricht / Jahreszeiten | `SeasonQuestionDeck.questionCount` |
| `s2_wetter` | 2 | `WetterScreen` | Sachunterricht / Wetter | `30` |
| `s2_verkehr` | 2 | `VerkehrScreen` | Sachunterricht / Verkehr | `30` |
| `d3_wortarten` | 3 | `WortartenScreen` | Deutsch / Wortarten | `30` |
| `d3_zeitformen` | 3 | `ZeitformenScreen` | Deutsch / Zeitformen | `30` |
| `d1_woerter` | 1 | `WortDiktatScreen` | Deutsch / Erste Wörter | `> _sessionWords.length` |
| `m2_einmaleins` | 2 | `EinmaleinsScreen` | Mathematik / None | `12` |
| `m3_einmaleins_voll` | 3 | `EinmaleinsScreen` | Mathematik / None | `12` |
| `m4_bruch` | 4 | `BruchrechnenScreen` | Mathematik / Bruchrechnen einfach | `8` |

## Spiellevel: tatsächliche Navigation

| Typ | Level-IDs | Zielscreen |
|---|---|---|
| `starsPath` | 1, 3, 4, 6, 9, 11, 12, 16, 17, 39, 41, 42, 45, 46, 48, 49 | StarsPathGame |
| `colorBoxes` | 2 | ColorBoxesGame |
| `numberHouse` | 5, 7, 8, 15, 19, 37 | NumberHouseGame |
| `mixedQuiz` | 10, 20, 30, 31, 32, 33, 34, 35, 40, 50 | LessonTrailGame, QuizShowContent |
| `numberPath` | 13, 14, 18, 36 | LessonTrailGame |
| `wordForest` | 21, 22, 23, 24, 26, 27, 28, 29, 38, 43, 44, 47 | LessonTrailGame |
| `letterFill` | 25 | LetterFillGame |

**Level 50 ist ein Sonderfall vor dem Switch** in `GamesContent._launchLevel`: Es startet `QuizShowContent`, nicht `LessonTrailGame`. IDs, Reihenfolge, Freischaltung und Rewardhöhen bleiben bei der Modernisierung erhalten.

## Lernlabor und geführte Konzepte

| Pfad | ID / Konzept | Stufe | konkrete Probleme / Schritte |
|---|---|---|---|
| lab | `bridge` / bridge | ab1 | `bridge-8-5`, `bridge-7-5`, `bridge-9-7`, `bridge-6-5`, `bridge-8-6`, `bridge-7-6`, `bridge-9-5`, `bridge-6-6` |
| lab | `words` / word | ab1 | `word-banane`, `word-tomate`, `word-rakete`, `word-melone`, `word-salami`, `word-lawine` |
| lab | `english` / english | ab2 | `english-cat`, `english-dog`, `english-apple`, `english-book`, `english-ball`, `english-bird` |
| lab | `nature` / nature | ab1 | `nature-root`, `nature-stem`, `nature-leaf`, `nature-flower` |
| lab | `fractions` / fraction | ab4 | `fraction-3-4`, `fraction-2-3`, `fraction-5-6`, `fraction-3-8`, `fraction-1-4`, `fraction-2-5` |
| lab | `patterns` / pattern | ab1 | `pattern-kreis-dreieck-5`, `pattern-dreieck-kreis-5`, `pattern-quadrat-kreis-5`, `pattern-kreis-dreieck-quadrat-8`, `pattern-dreieck-quadrat-kreis-7` |
| guided | `bridge_ten` / bridgeTen | 1 | Lumo erklärt es mir; Was kannst du schon?; Acht und fünf; Gemeinsam zum Zehner; Was bleibt übrig?; Jetzt probierst du; Ein neues Beispiel; Du hast selbst gerechnet |
| guided | `equal_groups` / equalGroups | 2 | Neue Dinge entdecken; Zählen als Grundlage; Drei gleiche Gruppen; Wir zählen zusammen; Deine Gruppenaufgabe; Verstehst du die Gruppen?; Ein neues Prinzip entdeckt |
| guided | `subtract_ten` / subtractTen | 1 | Mit Lumo zurückrechnen; Unsere Startmenge; Zwölf minus fünf; Gemeinsam zurück bis zehn; Noch ein Stück zurück; Du rechnest selbst zurück; Dein neuer Minusversuch; Du kannst in zwei Schritten rechnen |
| guided | `syllables` / syllables | 1 | Wir hören genau hin; Sprechen statt Buchstaben zählen; Ba – na – ne; Gemeinsam mitklatschen; Noch ein Wort zusammen; Ein neues Wort für dich; Dein eigener Silbenversuch; Du hast Silben gehört |
| guided | `flowering_plant_parts` / plantParts | 1 | Was wächst da?; Von unten nach oben; Das Blatt nutzt Licht; Gemeinsam unter die Erde schauen; Der Weg nach oben; Du erkennst den Pflanzenteil; Eine andere Blütenpflanze; Du kennst ihre Teile |
| guided | `bridge_hundred` / bridgeHundred | 3 | Größere Zahlen, vertrauter Trick; Zehner erkennen; 240 plus 70; Gemeinsam zum Hunderter; Den zweiten Teil finden; Jetzt probierst du; Ein neuer Hunderter; Bündeln hilft |
| guided | `fraction_parts` / fractionParts | 4 | Teile müssen gleich groß sein; Eine Hälfte; Viertel zusammenlegen; Teile als Bruch schreiben; Deine Viertelrechnung; Andere Teile, gleicher Trick; Die Teilgröße bleibt gleich |

## Offene Antworten und unsichere Erkennung

- CrossGrade: Spracherkennung liefert einen sichtbaren, änderbaren Vorschlag. Ohne Bestätigung entstehen weder ein Fachfehler noch ein gespeicherter Versuch. Ungültige Objekt- oder Aufgabenidentitäten werden vom kanonischen Bus zurückgewiesen.
- Lesen: unsichere oder nicht passende ASR-Erkennung wird im bestehenden `ReadingContent` nicht als falsche Fachleistung gespeichert. Wortmarkierungen des Lesebegleiters bleiben Erkennungshinweise.
- Schreiben: eine echte Stiftübung wird von einer tatsächlich bewerteten Texteingabe unterschieden. Der geschützte Trainer bleibt Antwortbesitzer seiner Strichregeln.
- Story-Zusammenfassungen: Keywordtreffer sind eine begrenzte Hilfe. Der zuständige Agent beseitigt Aussagen, die daraus vollständiges Textverständnis ableiten.
- Praktische Aufgaben: selbst berichtete Kunst-/Bewegungs-/Beobachtungsergebnisse werden über das bestehende Journal festgehalten; eine digitale Zusatzübung zertifiziert keine reale Durchführung.
- LUMO Live/Safari: der bestehende direkte ASR-Vergleich benötigt vor fachlicher Rückmeldung eine Bestätigung. Diese konkrete Lücke ist an Chat1/Chat4 eskaliert; fremde Sprachdateien wurden nicht geändert.

## Routen, die nicht als zusätzliche fertige Aufgaben gezählt werden

- ABC-Tafel und Rechentricks-Poster sind erreichbare Referenz-/Erkläransichten, keine unabhängigen Antwortgeneratoren.
- `LumoDeutschScreen` enthält Lückensätze, hat aber aktuell keinen Konstruktor-Aufruf außerhalb seiner Klassendatei im App-Code. Er wird nicht als aktiver Ersatz für Deutschaufgaben gezählt.
- `TaskType.imageWord`, `readingComprehension`, `dragDrop` und `trueFalse` sind deklarierte Domänenwerte. Ihre bloße Existenz belegt keine vier separaten aktiven Eingabeoberflächen. Die tatsächlichen Renderer und Workspace-Handlungen sind maßgeblich.
- Godot besitzt einen Standalone-ReadingHub mit Alphabet, Wort-Bild, Anlaut und Wortbau. Eingebettetes `goto(learn)` kehrt dagegen zu Flutter zurück. Diese vier nativen Szenen wurden nicht als in der Android-Lernroute ausgeführte Tests ausgegeben.
- Lehreraufträge starten über `StudentAssignmentsCard.onStart` den bestehenden Fach-/Einheitenpfad. Cosmos und MagicHub zeigen echte vorhandene Fortschritte bzw. verlinken zu den beschriebenen Screens; sie liefern keine zusätzlichen geprüften Schulantworten.

## Offene Integration und klare Owner

| ID | Owner | Noch konkret zu erledigen |
|---|---|---|
| G01 | Chat2 Inventory | MiniGames: guarded state, tested generators, save-false/retry, current owner, context/help and round continuation |
| G02 | parallel Chat2 2f607 | Lab/Guided/full regular context and exact18module task scopes; integrate pattern model and verify compilation |
| G03 | Chat2 Root | PhotoLesson full concrete answer pathway and quality gate |
| G04 | Chat2 Logic | Denkprofil/IQ generator, state and persistence acceptance |
| G05 | Chat2 Interactions | Story open-answer uncertainty and confirmed grading / safe retries |
| G06 | Chat4 via Chat1 | Live Safari must confirm ASR before factual wrong/correct feedback; preserve participation rewards semantics |
| G07 | Chat1/Chat3 | Exact figures/audio/assets in integrated app; Godot native and standalone routes require runtime validation |
| G08 | Chat1 | Structured teacher evidence for real physical/art activities remains separate from journal prose; no automatic success claim |
| G09 | Chat2 Inventory | Erledigt: praktische/Journal-Navigation 2/2, Capture 1/1; sechs ganze Fenster in `evidence/cross-grade/` mit Aufgabenmanifest |

## Ausgeführte Prüfungen / verbleibende Nachweise

| Prüfung | Status | Umfang / Beleg |
|---|---|---|
| `cross_grade_storage` | `passed` | 6 Fälle; `test/cross_grade_second_chance_test.dart`, `test/cross_grade_practice_storage_hardening_test.dart` |
| `cross_grade_contract_and_scene` | `passed` | 5 Fälle; `test/learning/cross_grade_contract_test.dart`, `test/cross_grade_scene_design_test.dart` |
| `module_progress` | `passed` | 10 Fälle; `test/learning_modules/learning_module_progress_test.dart` |
| `module_layout` | `passed` | 82 Fälle; `test/design/learning_adventure_layout_test.dart` |
| `practical_link_and_frame_help` | `passed` (2 Prüfungen) | `test/learning/module_frame_practical_links_test.dart` |
| `academy_navigation` | `blocked_integration_compile` | `test/curriculum_cross_grade_navigation_test.dart` |
| `whole_screen_capture` | `passed` | 1 Test, 6 ganze Ansichten; `test/learning/cross_grade_navigation_capture_test.dart` |

Die zusätzliche Frame-Zeile wurde nach tatsächlich gefundenem Platzverlust wieder entfernt: Hilfe und ruhiger Modus liegen nun als 48 dp-Bedienung in der vorhandenen Kopfzeile; die bestehenden Layouttests wurden hierfür nicht gelockert. CrossGrade hält sein Lernobjekt beim Scrollen montiert, damit gelegte Mengen und Hinweise nicht durch List-Recycling verschwinden.

Capture-Nachweise werden als echte gerenderte Flutter-Ansichten mit echten Fonts erstellt. Die Größen sind **logische Viewport-Simulationen**, keine behaupteten Tests auf einem physischen Fold7. Aufnahme von Komponenten ersetzt nicht die zusätzliche ganze Lernansicht.

## Reproduzierbarkeit und maschinenlesbare Datei

`coverage.json` enthält alle 236 aktuellen und 447 kumulativen Einheitenscopes, sämtliche 92 Mathe-/Deutsch-Templates, 20 Topic-IDs, 50 Spiellevel, 60 praktische Aufträge, 24 Lesetexte sowie Lab-/Guided-IDs. `flow_ref` verweist jeweils auf Einstieg, Eingabe, Bewertung, Hilfe, Abschluss und Speicherung.

Katalog erneut ausführen: `dart run tool/nextgen_learning_inventory.dart`. Flutter-Tests in diesem gemeinsamen Workspace immer über `flock --close /workspace/scratch/c5a7dadab95f/toolchain/lumo-flutter.lock /workspace/scratch/c5a7dadab95f/toolchain/flutter/bin/flutter test --no-pub ...`.
