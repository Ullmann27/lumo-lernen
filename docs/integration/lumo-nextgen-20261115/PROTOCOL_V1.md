# LUMO NextGen – gemeinsamer produktiver Lern-/Figuren-/Sprachvertrag v1

Stand: 15.11.2026 · Integrationszweig \`integration/lumo-learning-nextgen-20261115\`.

**Kanonische API ist die tatsächlich im Flutter-Quellcode vorhandene \`LumoLearningIdentity\` mit \`protocolVersion: 1\` aus \`lib/core/lumo_learning_session_contract.dart\`.** Eine frühe, separate JSON-Idee \`lumo.learning.round\` ist **nicht** die produktive API. \`tools/learning_nextgen/contract_reference.py\` prüft diese eigenständige JSON-Sicherheitsreferenz; seine Python-Tests sind **keine** Flutter-/Godot-Interaktion und kein Android-Gerätebeleg. Keine zweite Live-Sitzungsverwaltung neben der bestehenden Flutter-/Godot-Architektur einführen.

## Die versionierten Felder und Verantwortlichkeiten

| Tatsächlicher Dart-Typ | Enthaltene v1-Felder | Wer entscheidet? |
|---|---|---|
| \`LumoLearningIdentity\` | \`sessionId, taskId, revision, cancelEpoch, stepId\` | Flutter-Host, aktueller Lernprofil-Owner |
| \`LumoLearningActionRequest\` | \`identity, requestId, action, turnId, objectId, candidate\` | Kind/Agent schlägt vor; Flutter validiert |
| \`LumoLearningCancellation\` | \`sequence,reason,identity\` | Flutter-Host/Abbruch |
| \`LumoLearningPresentation\` | \`identity,turnId,utteranceId,gazeObjectId,pointObjectId,expression,animationState\` | abgesicherte visuelle Hinweise, Godot rendert |
| \`LumoLearningAudioFrame\` | \`identity,turnId,utteranceId,state,subtitle,positionMs,durationMs,audible,envelopeAvailable,envelope\` | tatsächlicher Audio-Playerstatus, keine Text-Zeituhr |
| \`LumoCompanionTaskContext\` | \`taskId,subject,unit,prompt,stepId,objectIds,allowedActions,dialogue\` | ausschließlich laufende Aufgabenquelle |

Die \`taskId\` bleibt die **echte bestehende** ID, keine allein aus Text erzeugte ID. \`revision\` schützt vor Wechseln innerhalb einer Aufgabe, \`cancelEpoch\` invalidiert alte asynchrone Antworten nach Stopp/Hintergrund/Profilwechsel. \`turnId\` ist die Gesprächsrunde; \`utteranceId\` gehört zu genau einem tatsächlich gestarteten Ton. Der Request-Bus heißt \`LumoCompanionRequests\` mit \`learningIdentity\`, \`learningAction\`, \`learningCancellation\`, \`learningPresentation\`, \`learningAudio\` und \`dialogueFocus\`. Die \`dialogueFocus\`-Markierung wird bei Aufgabenwechsel, Abbruch oder Scope-Ende gelöscht.

## Zulässige Aktionen und Grenzen

Der v1-Aktions-Enum ist exakt \`explain,repeat,slower,hint,highlight,point,look,stop,proposeAnswer\`. Keine \`grantReward\`-, \`markCorrect\`-, \`changeTask\`- oder sonstigen freien Modellaktionen. Die aktuelle Aufgabe gibt \`allowedActions\` vor; in Prüfungssituationen gilt die Hilfescheide. Zielobjekte müssen bei der aktuellen Aufgabe registriert sein, nicht von einem Modell erfunden werden. \`proposeAnswer\` erzeugt **nur einen editierbaren Kandidaten**. Fachliche Bewertung, Fehlertyp, Versuchsstand, XP/Sterne, Fortschritt und Speicherung bleiben bei \`TaskInstance\`/bestehendem Bewertungs-/Speichersystem. Zahlenverhörung und Korrektur ändern nicht eigenständig eine Bewertung.

\`LumoTaskDialogueSnapshot\`/\`LumoTaskDialogueReply\` sind geprüfte, befristete Text-/Objekt-Informationen: Kinder fragen „Warum zuerst zwei?“, „langsamer“, „Stopp“ oder korrigieren eine Zahl; die Antwort darf nur an die aktive Aufgabe gebunden werden. Bei unklarer Spracherkennung muss das Kind den Vorschlag sehen/bestätigen, bevor ein vorhandener Bewertungscontroller aufgerufen wird.

## Bild, Audio und Lebenszyklus

Godot benutzt weiter die **bestehende** \`NativeLearningActivity.fromTask/fromLesson\`-Startfunktion über Flutter/Android und die bisherige Lernszene. Kein zweiter Generator/Engine und keine lose durch ein HTML-Prototypenfenster ersetzte Lernlogik.

\`LumoLearningPresentation\` richtet LUMOs Blick/Pfote auf \`gazeObjectId\`/\`pointObjectId\`; nicht registrierte IDs haben keine Aktion. \`LumoLearningAudioFrame\` liefert echte \`playing\`-/\`audible\`-Meldungen, \`positionMs\` und optional die gemessene PCM-Amplitudenhüllkurve. Vor dem echten Wiedergabestart bewegt sich der Mund **nicht**. \`mouthTiming == envelope\` bedeutet **keine** verifizierten Viseme-/Phonem-Zeitstempel. Untertitel zeigen exakt den gewählten gesprochenen Text.

Bei \`stop\`, Wechsel, Hintergrund oder Profiländerung zuerst \`cancelEpoch\` invalidieren, dann ASR/LLM/TTS stoppen, Ton/Player auf \`stopped\`, Mund auf neutral, Gesten/Tweens neutralisieren. Alte \`completed\`-/Ergebnis-Callbacks werden verworfen. Bei Wiederaufnahme bestehende Aufgabe und Fortschritt neu binden, keinen alten KI-/Ton-Job fortsetzen und keine Sterne doppelt buchen. Ein offline/nicht verfügbares Mikrofon verhindert **nicht** das Tippen.

## Gemeinsame Mindestproben

1. **8+5**: 8 belegte Zehnerfelder plus 5 andere Objekte; **genau zwei** in die freien Felder ziehen, **drei** übrig. „Warum zuerst zwei?“ erklärt die tatsächlichen freien Felder und zeigt darauf, ohne Antwort zu buchen.
2. **Banane**: reale \`Ba–na–ne\`-Silben anzeigen, sprechen und auf „langsamer“ die echte Audiowiedergabe verlangsamen. Nur echte Audiotaktdaten bewegen Kiefer und Mund.
3. **Muster**: kleinste sich wiederholende Formengruppe zeigen; Hilfestellung verändert den Fortschritt nicht.

Außerdem: falsch, verhört, Korrektur, Stopp, Wechsel mitten in Audio/LLM, Fold-Verschluss/Öffnen, Unterbrechung/Resume, ruhiger Modus, mindestens 48×48 dp Bedienelemente, normale Smartphones und Fold7 außen/innen.

## Quellenstatus, der nicht überschritten werden darf

Ausgang Flutter \`6f4a8c4753f4d06d0b392da0789b8162b2faa71b\` in \`delivery/lumo-2023-complete-update-20261115\`, App \`0.13.11+2023\`. Native-Pin in \`config/godot-source.json\` bleibt zunächst \`d38967f6d39bc20188afe525b0af122d80634029\` (Godot 4.6.3), bis nativer Import + Android-Kopplung belegt sind. Quellinventar \`COVERAGE_BASELINE.json\`: 36 Akademie-Topics, 20 Module, **6** Lab-Bereiche, acht Generatorfamilien plus Spezialpfade; dynamische Generator-Aufgaben brauchen eigene Laufzeitabdeckung. Geschützte Schreibtrainer-/Journal-Interna, Kart und Dschungel bleiben unberührt.

**Stand:** Dart-Verträge und Quellbausteine sind im Integrationszweig. Ein freies Duplexgespräch **innerhalb der laufenden Godot-Lernszene**, echter Audio-/Lipsync auf einem physischen Fold7, 60-FPS-Profil und eine signierte vollständig verbundene NextGen-APK sind **nicht** belegt. Python-Vertragstests und Desktop-Widgets dürfen nicht als solche Gerätebelege gemeldet werden.

V1 bleibt abwärtskompatibel; Breaking Changes brauchen explizite V2 mit beidseitiger Versionserkennung. Kein Merge nach \`main\` ohne Freigabe.
