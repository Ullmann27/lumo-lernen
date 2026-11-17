# LUMO Nächste Generation – gemeinsamer Lern-/Figur-/Sprachvertrag v1

Stand: 15.11.2026 · **Integrationsvertrag, keine Behauptung über fertige Laufzeitverdrahtung**.

## Verifizierte Ausgangsarchitektur
- Flutter-Host: \`lib/features/learning/learning_content.dart\` → \`LegacyLumoTaskAdapter\` → \`TaskInstance\`; \`NativeLearningActivity.fromTask/fromLesson\` erzeugt bereits einen streng begrenzten Godot-Lernaufruf über \`launchLumo3D(scene: 'learning', learning: ...)\`.
- Bestehender Godot-Pin der Ausgangsbasis: \`d38967f6d39bc20188afe525b0af122d80634029\`. Godot: \`scripts/learning/learning_world.gd\`, \`scripts/learning/learning_activity.gd\`, \`scripts/characters/lumo/lumo_rigged_actor.gd\`, \`scripts/systems/host_bridge.gd\`.
- Flutter besitzt \`LumoConversationController\`, \`LumoSpeechListener\` und \`LumoVoice\`; Godot nutzt vorhandene \`LumoHost\`-Methoden \`speakLearning\`, \`stopLearningSpeech\`, \`getLearningSpeechStatus\`. **Ein voll-duplexer Live-Gesprächskanal Flutter ↔ Godot ist damit noch nicht belegt.** Es darf kein alternatives LLM-Belohnungssystem eingeführt werden.
- Vorhandener \`LumoLearningScene\`-Serializer trägt \`version: 1\` und bleibt unverändert. Das folgende zusätzliche Nachrichtenprotokoll heißt unabhängig davon \`lumo.learning.round\` v1. Eine Umdeutung vorhandener Payloads ist verboten.

## Unveränderliche Verantwortung
1. **Flutter-Aufgabenautorität:** ausgewählte Klasse/Fach/Unit, exakte Aufgaben-ID, richtige Antwort, Fehlerklasse, adaptiver Hinweis, Lernstand, Sterne/XP und persistente Quittung. Quelle sind die bisherigen Generator-, Aufgaben-, Lernprofil- und Wallet-Services. Native Illustrationen sind niemals selbst bewertete Leistungen.
2. **Godot-Präsentation:** Objekt-IDs, Zehnerfeld, 3D-LUMO, Blick/Pfote/Mimik, visuelle Erklärschritte, ruhiger Modus. Godot darf Vorschläge senden; es darf weder Antworterfolg noch Lernstand oder Sterne selbst festlegen.
3. **Sprache/Gespräch:** transkribiertes Kindersprechen, Kontext, sichere Hilfsabsicht, tatsächliche Audio-Wiedergabe und Untertitel. KI-Text ist **kein** Beleg für eine korrekte Antwort und darf ausschließlich eine gültige Aktion anfordern.
4. **Host/Android:** vorhandener \`lumo_lernen/bridge\`-Start-/Rückkehrweg, Lebenszyklus, Audio-Lizenz/Geräteverfügbarkeit und Profileigentümer. Keine neue konkurrierende Engine und keine zweite App.

## Nachrichtenumschlag
Jede neue Nachricht trägt folgende Felder; unbekannte Pflichtfelder, ungültige Versionen oder veraltete Eigentümer werden verworfen. **JSON, keine Dart-Objekte oder Godot-Varianten über die Grenze**.

\`\`\`json
{
  "protocol": "lumo.learning.round",
  "version": 1,
  "messageId": "unique-opaque-id",
  "sessionId": "opaque-session-id",
  "ownerGeneration": 7,
  "taskId": "existing-task-instance-id",
  "taskRevision": 12,
  "turnId": "opaque-conversation-turn",
  "sequence": 17,
  "kind": "presentation.step",
  "payload": {}
}
\`\`\`

- \`sessionId\`: beim Lern-Start neu; nur innerhalb dieser laufenden Sitzung gültig. Kein Klarname oder unnötiger Kinderprofilinhalt.
- \`ownerGeneration\`: aktueller Generation-/Lease-Schutz aus \`LumoAppState\`; der Host prüft vor jeder Änderung, dass Profil/Reset zugeordnet bleiben.
- \`taskId\`: **exakte** ID der aktuell geprüften Aufgabe bzw. Lektion, keine allein aus Aufgabentext geratene ID.
- \`taskRevision\`: monoton steigender Aufgabenkontext-Zähler; Wechsel, Retry mit neuem Aufgabenobjekt, Unterbrechung oder Reset invalidieren alte Antworten.
- \`turnId\`: zugehöriger Sprach-/Erklärvorgang (bei reinem Rendering leer zulässig).
- \`sequence\`: pro Sitzung streng steigende Ausgabesequenz; Duplikate werden idempotent behandelt, veraltete Sequenzen verworfen.
- Antwortbezogene Nachrichten sind nur zulässig, wenn alle fünf Werte (session, ownerGeneration, taskId, taskRevision, turnId sofern Gespräch) zu einem live offenen Vorgang passen. Beim Wiederaufnehmen wird ein frischer Turn/Revision vergeben.

## Nachrichtenarten und Payloads (v1)

| Art | Pflichtdaten | Autorität |
|---|---|---|
| \`session.started\` | \`grade\`, \`subject\`, \`unit\`, \`calmMode\`, \`voiceAllowed\`, \`sceneVersion\` | Flutter |
| \`task.activated\` | \`taskType\`, \`objectIds[]\`, \`stepId\`, \`checkedVisual\`, \`allowedHints[]\` | Flutter |
| \`presentation.step\` | \`stepId\`, \`objectId\`, \`operation\`, \`durationMs\` | Flutter/validierter Szenenregisseur |
| \`answer.proposed\` | \`inputId\`, \`inputKind\`, \`raw\` | Kind/Native UI |
| \`answer.assessed\` | \`inputId\`, \`correct\`, \`errorKind\`, \`nextAllowedHint\`, \`receiptId\` optional | **Flutter-Fachlogik** |
| \`hint.requested\` | \`level\`, \`objectId\`, \`reason\` | KI als Vorschlag, Flutter prüft |
| \`speech.transcript\` | \`recognitionId\`, \`text\`, \`isFinal\`, \`locale\`, \`confidence\` optional | ASR mit Bestätigung |
| \`conversation.reply\` | \`text\`, \`requestAction\` optional, \`contextRevision\` | validierter Gesprächsdienst |
| \`avatar.cue\` | \`gazeObjectId\`, \`gesture\`, \`expression\`, \`animationState\` | validierter Regisseur |
| \`audio.status\` | \`playbackId\`, \`state\`, \`audible\`, \`offsetMs\`, \`durationMs\`, \`subtitle\`, \`mouthFrames[]\` optional | **echter Playerstatus** |
| \`turn.cancel\` | \`reason\` (\`stop|taskChange|profileChange|lifecycle|dispose\`) | Kind/Host |
| \`turn.cancelled\` | \`playbackId\` optional, \`stopped\` | native Stimme/Fuchs bestätigt |
| \`session.resumed\` | \`taskId\`, \`taskRevision\`, \`stepId\` | Flutter aus gespeichertem Zustand |

Gültige \`requestAction\`-Namen: \`focusObject\`, \`showAllowedHint\`, \`repeatExplanation\`, \`slowExplanation\`, \`pause\`, \`stop\`. \`grantReward\`, \`markCorrect\`, \`changeGrade\`, \`changeTask\` und freie Tool-Namen sind **nicht erlaubt**. Jede Objekt-/Schritt-Referenz wird gegen \`task.activated.objectIds\` und den zugelassenen Schritt geprüft. Keine aus Text frei erzeugten IDs akzeptieren.

\`errorKind\`: \`none|placeValue|counting|numberTranscription|syllableOrder|patternRule|other\`. Eine verhörte Zahl wird zunächst nachgefragt, nicht als falsch bewertet. Freie Kinderfrage \`Warum zuerst zwei?\` löst eine **Erklärung zur aktiven Aufgabe**, keine Antwortbuchung aus.

\`avatar.cue.gesture\`: \`idle|look|point|count|think|encourage|celebrate|stop\`. \`expression\`: \`attentive|thoughtful|encouraging|joyful|neutral\`. Nur vorhandene reale Rig-/Animationszustände ausführen; fehlende Morphs dürfen einen ehrlichen Fallback haben. Ziel \`gazeObjectId\` muss existieren. Bei fehlendem Objekt neutral blicken, niemals in irrelevante Richtung zeigen.

\`audio.status.state\`: \`preparing|playing|completed|stopped|error\`. \`audible=true\` **erst** nach bestätigtem Playerstart; \`mouthFrames\` sind Zeit-/Gewichtspaare relativ zum realen Audiostart, höchstens 30 fps. Fehlen echte Wort-/Phonemzeiten, verwenden wir gemessene Amplituden, nicht erfundene Zeitmarken. Untertitel folgen dem tatsächlich gewählten Text/Tempo. Nicht hörbar abgespielter Text darf keine aktive Mundbewegung auslösen.

## Besitz-/Abbruchautomat
- \`start\` → \`listening\` oder \`thinking\` → \`speaking\` → \`idle\`; \`pause\`, \`taskChange\`, \`appBackground\` und \`stop\` invalidieren **zuerst** Aufgabengeneration und Turn-ID.
- Danach gemeinsam: ASR abbrechen, TTS stoppen, noch nicht gestartete Audiojobs verwerfen, \`audio.status: stopped\` senden, Mundgewicht auf null, Zeigegeste/Anlauftween stoppen und Fuchs auf neutralen Zustand. **Keine** verspätete \`completed\`-/\`answer.assessed\`-Nachricht darf danach den neuen Zustand verändern.
- Bei Wiedereintritt: aus dem **bestehenden** Host-Speicher lesen, zuletzt bestätigte Aufgabe/Schritt aktivieren, neue \`taskRevision\` und frischen \`turnId\` vergeben. Keine doppelte Vergabe von XP/Sternen. Bindende Quittung nur über bisherigen Wallet-/Progress-Pfad.
- Bei offline/nicht verfügbarer Sprache bleibt die Aufgabe vollständig tipp- und antippbar; \`voiceAllowed=false\` und ein verständlicher Statustext. Keinen kostenpflichtigen Cloud-Fallback hinzufügen.

## Drei erste gemeinsame Prüfszenen
- \`math.bridgeTen.8plus5\`: 8 Zehnerfeldobjekte, rechts 5. Explizite Objektkennungen \`ten.slot.0..9\` und \`extra.0..4\`. Zuerst \`extra.0, extra.1\` in \`ten.slot.8, ten.slot.9\` bewegen; drei außen; geprüfte Lösung 13. Zur Frage \`Warum zuerst zwei?\` spricht LUMO: „Weil zur Zehn noch zwei fehlen. Danach bleiben drei übrig.“ Blick/Geste müssen auf genau die zwei umgesetzten Steine zeigen. Hilfen dürfen nicht als selbst gelöste Antwort zählen.
- \`de.syllables.banane\`: geprüfte Segmente \`Ba\`, \`na\`, \`ne\` und \`word.syllable.0..2\`. Beim Wort \`langsam\` tatsächliche TTS-Rate reduzieren oder längere Pausen *aus echtem Audio*; gleichzeitige Anzeige nacheinander. Reine Wiederholung vergibt keine Leistung.
- \`logic.pattern.repeat\`: ausdrücklich definierten wiederkehrenden Gruppenblock markieren, ein regelkonformes nächstes Objekt nur als erlaubten Hinweis vorschlagen; Bewertung ausschließlich mit vorhandener Aufgabenlogik. Muster ohne geprüfte Sollfolge dürfen nicht bewertet werden.

## Integrationsentscheidung
**Kein zweiter Content-Generator.** Die Chat-2-Szenendaten werden über den vorhandenen \`TaskInstance\`-/\`NativeLearningActivity\`-Weg eingespeist. Chat 3 realisiert Godot-Darstellung im bisherigen \`learning_world.gd\`-Pfad und vorhandenen Fuchs-Rig; Chat 4 ergänzt den bestehenden Sprach-Host. Erst ein auf echter Android-Laufzeit bestätigter duplexer Kanal darf als „Kind spricht während der Godot-Aufgabe mit LUMO“ bezeichnet werden. Bis dahin bleibt der Vertrag ein prüfbarer Integrationsstandard, kein Funktionsclaim.

## Abwärtskompatibilität / Änderungen
- v1 fügt einen Umschlag **neben** vorhandenen \`learning\`-Launch-/Return-Payloads hinzu. Verwendete Altversionen bleiben unverändert. Pflichtfelder/Enumwerte werden in v1 nicht rückwirkend geändert.
- Erweiterungen sind optional und dokumentiert; Breaking Changes erfordern v2 und explizite Aushandlung der unterstützten Version. Bei inkompatiblen Peers sichere Legacy-Darstellung statt blindem Parsen.
- Datenschutz: nur temporäre Turn-Daten im Gesprächskontext; keine Speicherung unbestätigter ASR als Lernkompetenz.

## Zwingende Nachweise vor „angeschlossen“
Verknüpfte Aufgabe, aktiver Actor, echter Audiostart, korrekt bestätigte Antwort, Speichern, Abbruch und Neuaufgabe in **einer** Android-Lernszene. Danach Registry-/Generator-/Lesen-/Lab-Abdeckung, Falttests und 60-FPS-Profil mit Fuchs+Audio. Separate CI-Unit-/Godot-Checks ersetzen kein Fold7-Video.
