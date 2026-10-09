# A6 – Code-Verifikation (Repo b04bee5, Branch claude/continue-previous-chat-KtY7p), nur gelesen

Methode: Dateisuche/grep; Import-Erreichbarkeit von lib/main.dart per Skript (tools/reach.py, read-only).
Ergebnis Erreichbarkeit: 318 Dart-Dateien in lib/, 315 erreichbar, 3 NICHT erreichbar
(lib/core/curriculum/primary_curriculum_support.dart, lib/features/onboarding/lumo_onboarding_screen.dart,
lib/features/onboarding/widgets/lumo_step_indicator.dart) -> verletzt CLAUDE.md Regel 8 (Nebenbefund).

## Wirklich implementiert (und von main.dart erreichbar)
| Behauptung | Befund |
|---|---|
| Fehlermuster-Erkennung | lib/domain/school/error_patterns.dart: ErrorPatternDetector, ~14 Regeln (Zehner beim Übergang vergessen, Minus statt Plus, Ziffern vertauscht, um eins verzählt, kleinere Einerziffer von größerer abgezogen, Malreihe verrutscht, Mal statt Geteilt …) + Lesen: "schwieriges Wort". NUR Arithmetik+Lesen, regelbasiert (Regex auf Aufgabentext), keine Distraktor-Generierung aus Fehlermustern gefunden. |
| Kompetenzprotokoll | lib/domain/school/attempt.dart (Attempt: Aufgabe, Antwort, Dauer, Hilfe, Score), competency.dart (CompetencyClassifier "Addition mit/ohne Zehnerübergang" …) |
| Lernbericht pro Kompetenz | learning_analysis.dart: MasteryLevel (ab 5 Versuchen), Trend, wiederkehrende Fehlermuster (>=2x), Lesetempo WPM, PracticeSuggestion ("10 Minuten … mit visuellen Zehnerfeldern"), CoachMessage; UI lib/features/report/* |
| Eltern-Dashboard | lib/features/parents/lumo_insight_dashboard.dart: Heatmap Fach x Kompetenz, Top-3 Fehlertypen, DnaEngine-Empfehlung; OPTIONAL KI-Wochenanalyse über Cloud-Proxy (nur wenn Eltern freigeben) |
| Lehrerbereich | lib/features/teacher/* + domain/school/school_model.dart (Klassen, Gruppen, Zuweisung, SchoolAccess-Rollen student/teacher/parent/admin) |
| Foto-Lektion | lib/features/photo_lesson: ML Kit OCR on-device -> ScannedWorkAnalysis (Fach/Thema) -> PhotoLessonPractice.generate = 5 lokale Aufgaben aus Vorlagen (Mathe/Deutsch/Englisch/Sachunterricht) |
| Denk-/IQ-Test | lib/features/tests/iq/* (11 Dateien) + docs/DENKTEST_KONZEPT.md: ehrlich "Denk-Profil", kein IQ-Wert |
| Schreib-Engine | lib/features/writing/writing_engine.dart: LetterShapeAnalyzer = HEURISTIK (Strich-Anzahl/Richtung vertikal/horizontal/diagonal gegen Buchstabenvorlagen, A–Z, a–z, ß, Ziffern). Kommentar: "Phase 2 (deferred): ML Kit Digital Ink Recognition". Keine Österreichische Schulschrift-Spezifik (grep "Schulschrift" = 0 Treffer). |
| Lese-Buddy / Aussprache | lib/core/reading_v2_pronunciation_analyzer.dart = Wort-Alignment zwischen Soll-Satz und ASR-TRANSKRIPT (kein akustisches Phonem-Modell). Spracheingabe: speech_to_text mit localeId de_AT, ListenMode.dictation; KEIN `onDevice: true` im ganzen lib/ (grep onDevice = 0) -> Android-Standard-Spracherkennung kann Cloud (Google) nutzen; Offline nur wenn Sprachpaket installiert. |
| Sprachausgabe | assets/audio/voice/lumo: 228 m4a-Clips (vorproduziert) + flutter_tts als Fallback |
| Kart/Godot | Godot-Quelle extern (config/godot-source.json, Pin de91cc9, Engine 4.6.3); Docs: 14er-Flotte, Werkstatt mit profilbezogenem Sternebudget, Prüfstand; DESIGN_ZIEL_KART: "Kein Lernen im Kart … keine Lernfragen, keine Antworttimer, kein Turbo für richtige Antworten". RewardWallet: totalEarnedStars (lebenslang) vs. ausgegeben. Godot-Code selbst nicht im Repo, daher nur Doku-Beleg. |
| Eltern-Gate Sensoren | lumo_feature_permissions.dart: Mikrofon/Kamera standardmäßig AUS (AppSettings microphoneEnabled=false, scannerEnabled=false) |
| Spielewelt | features/games: memory, lumo_cards, spielwelt, flame, mini_games, dice_race, connect_four |
| Tablet/Fold | app_shell/app_theme etc. mit Fold-Bezug; docs/FOLD_PROGRESS, RESPONSIVE_DEVICE_MATRIX |

## NICHT vorhanden / nur Ansatz
- Teachable Agent (Kind erklärt Lumo): 0 Treffer (rollentausch/teach lumo/…). "lumo_teacher_screen" = Lumo erklärt dem Kind.
- Spaced Repetition für Kinder sichtbar: nein. Intern nur `decayScore = Tage seit lastSeenAt / 14` in AdaptiveTaskSelector.selectSkill (adaptive_learning_engine.dart) + `repetitionNeed` als Gewicht; kein Intervall-Scheduler, keine Kinderansicht.
- Mehrere Kinder pro Gerät: ProfileRepository speichert EIN 'lumo_active_profile' (+ resetProfile). Teacher-Modul kennt mehrere SchoolStudent. Kein Geschwister-/Familienmodus (grep = 0).
- Handschrift: nur Heuristik-Matcher, keine Ink-Recognition, keine Schulschrift.
- Distraktoren aus Fehlermustern: nicht gefunden (Detector wird nur für Bericht genutzt – VERMUTET; nicht in jedem Pfad geprüft).

## Datenschutz-Realität vs. PRIVACY.md (Stand 28.04.2026: "INTERNET nicht benötigt", "Kein Datentransfer an Dritte")
- scripts/prepare_android.py setzt Manifest-Rechte INTERNET, CAMERA, RECORD_AUDIO, REQUEST_INSTALL_PACKAGES.
- Optionaler OpenAI-Proxy (server/lumo-ai-proxy, Render): aiProxyEnabled default=false, Eltern-Freigabe, lokaler Child-Safety-Filter; sendet Nachricht + Klassenstufe + Verlauf (<=8 Turns).
- lib/core/lumo_image_generator.dart: Bilder per URL https://image.pollinations.ai/prompt/… (Positiv-Allowlist, safe=true) – genutzt in Lumo-Lehrer-Chat, Jahreszeiten-Modul, Live-Pro; KEIN Eltern-Gate sichtbar -> Drittanbieter-Aufruf (IP + Stichwort) ohne Freigabe.
- AppUpdateService -> api.github.com/repos/Ullmann27/lumo-lernen/releases/latest (nur auf Knopfdruck in Einstellungen) + APK-Download/Installation (REQUEST_INSTALL_PACKAGES; Play-Store-Konflikt VERMUTET).
=> "vollständig offline / kein Tracking" ist im Kern (Lernstand lokal in shared_preferences) wahr, aber PRIVACY.md muss an den Code angepasst werden, bevor es als USP beworben wird.
