# LUMO Next Generation — gemeinsamer Anschluss v1

Stand 15.11.2026. Hauptchat 1, Arbeitsbereich `4fa97167812c`.
Dies ist ein Implementierungsvertrag, keine Fertig- oder Gerätefreigabe.

## Kompatible Konkretisierung nach erster Implementierung

Der tatsächlich implementierte Vertrag von `ea41c7b116ac` aus Commit
`421a0c3261a57dd15733531058cf2291d765d38d` wird als gemeinsame Dart-API
übernommen: `lib/core/lumo_learning_session_contract.dart` und additive
Erweiterungen des bestehenden `LumoCompanionRequests`-Bus. Es entsteht
keine zweite Session- oder Aufgabenstruktur. Der erste Dokumententwurf
`567666e` hatte noch keine abweichenden produktiven Wire-Consumer.

Kanonische Versionskennung ist `protocolVersion: 1`. Die Bindung heißt
`LumoLearningIdentity(sessionId, taskId, revision, cancelEpoch, stepId)`.
Die semantische Revision enthält den Kontextstand; ein zusätzliches
`contextRevision`-Feld ist daher nicht erforderlich. `turnId` und
`utteranceId` sind die vom Besitzer erzeugten Ganzzahlkennungen.

Kanonische Aktionen: `explain`, `repeat`, `slower`, `hint`, `highlight`,
`point`, `look`, `stop`, `proposeAnswer`. „Warum“ benutzt `explain`/`hint`;
Korrektur ändert den sichtbaren Kandidaten. Bestätigung bleibt beim
bestehenden fachlichen Eingabeweg und ist keine KI-Aktion.

Der bestehende Aufgabenkontext erhält `stepId`, `objectIds`, `explanation`,
`errorType`, `answerChoices`, `allowedActions`, `isExplanation`. Der Bus
liefert `learningIdentity`, `learningAction`, `learningCancellation`,
`learningPresentation`, `learningAudio`. `requestLearningAction` prüft
Identität, erlaubte Aktion, Prüfungsgrenze und Objektkennung. Die folgenden
Abschnitte verwenden ausschließlich diese implementierten Namen. Der erste
Dokumententwurf ist ersetzt und kein zusätzlich unterstütztes Wire-Format.

## Verifizierte gemeinsame Basis

- Flutter: `6f4a8c4753f4d06d0b392da0789b8162b2faa71b`,
  `delivery/lumo-2023-complete-update-20261115`.
- Godot: `d38967f6d39bc20188afe525b0af122d80634029`,
  `integration/lumo-2023-native-complete-20261115`, Godot 4.6.3.
- Gemeinsamer neuer Zweig in beiden Repositories:
  `integration/lumo-nextgen-learning-20261115`.
- Keine Übernahme der parallelen Dschungel-/Kart-Folgearbeiten.
- Bestehende Aufgabenkennungen, Profile, Fortschritts-/Belohnungsformate,
  Paketidentität und Signaturkonfiguration bleiben erhalten. Schreibtrainer
  und Journal werden nur über äußere Adapter ergänzt.

## Zuständigkeit und beobachtete Übergabepunkte

| Team | Arbeitszweig | Besitz |
|---|---|---|
| Chat 1 | `integration/lumo-nextgen-learning-20261115` | Vertrag, übergreifende Adapter, Host-Verkabelung, Integration, Prüfung, Build/Download |
| Chat 2 | `feature/lumo-nextgen-learning-chat2-20261115` | Lernaufgaben, fachliche Hilfen, Oberflächen, Lernabdeckung; `2f607e7664ce` |
| Chat 3 | `art/lumo-nextgen-avatar-20261115-54fe` | `art/lumo_next`, `assets/lumo_next`, `scripts/lumo_next`, `tools/lumo_next`, `tests/lumo_next`, `docs/lumo_next`, additive `scripts/learning/learning_world.gd`; `54fec2798782` |
| Chat 4 | `feature/lumo-nextgen-conversation-20261115-403a` | Sprache/Gespräch, native Sprachbridge, Kontextabbruch; `403a8e21ea7b` |

Weitere tatsächliche Übergaben sind inzwischen integriert: Der eingefrorene
C5-Lernstand ist mit Dateihashes und seinem damaligen Arbeitsbaumstatus in
`docs/nextgen/evidence/c5_final_candidate_20261115/source.json` belegt. EA lieferte
den oben bezeichneten kanonischen Vertrag sowie Host-/Gesprächsadapter.
Chat 4s lokale Spracherkennung wurde selektiv aus
`818096d` übernommen. Chat 3s finale Assets und editierbare Blender-Quellen
sind durch `docs/nextgen/evidence/avatar-authoring-snapshot-01.json` im
Godot-Repository belegt. Die integrierte native Revision steht verbindlich in
`config/godot-source.json`. Ein dokumentierter Arbeitsbaumsnapshot wird nicht
nachträglich als sauberer ursprünglicher Produzentencommit ausgegeben.

Änderungen an `learning_world.gd` werden mit Chat 3 abgestimmt; Änderungen
an Sprachdateien mit Chat 4. Jeder liefert Commit/Dateiliste, tatsächlich
gelaufene Prüfungen und offene Grenzen. Kein Merge nach main.

## Architektur und Autorität

Der bestehende Flutter-Host bleibt Aufgaben-, Profil- und Belohnungsautorität.
Die bestehende Godot-Activity ist der native 3D-Präsentationsweg; es gibt
gegenwärtig keine inline Godot-PlatformView im Flutter-Widgetbaum.
Deshalb darf eine optionale native Erklärung nicht als dauerhaft sichtbare
3D-Figur in jeder Flutter-Aufgabe ausgegeben werden.

Vorhandene Verträge `LearningSceneRequest`/`LearningSceneEvent`,
`LumoCompanionTaskContext`, `NativeLearningActivity` und Android
`speakLearning/getLearningSpeechStatus/stopLearningSpeech` bleiben gültig.
Der folgende Identitätsvertrag ergänzt sie. Keine zweite Aufgabenlogik
oder zweite Speicherung einführen.

## Identität und Aktionen v1

`LumoLearningIdentity.toJson()` liefert die folgende Identität. Dies ist
kein vollständiger Aktions- oder Szenenpayload:

```json
{
  "protocolVersion": 1,
  "sessionId": "opaque-session",
  "taskId": "existing-task-id",
  "revision": 1,
  "cancelEpoch": 0,
  "stepId": "explanation-1"
}
```

`sessionId` ist ein flüchtiger Besitzertoken, keine Kinderidentität.
`taskId` bleibt die vorhandene Aufgabenkennung. `revision` bezeichnet die
semantische Aufgaben-/Kontextrevision. Ein unveränderter erneut veröffentlichter
Kontext erhöht sie nicht. `stepId` ist optional und wird bei fehlendem Wert
nicht serialisiert. Der native Adapter normalisiert fehlend/null zu derselben
Identität. `cancelEpoch` wird beim semantischen Abbruch erhöht. Controller
melden insbesondere Stopp, Hintergrund sowie Aufgaben-/Profilwechsel an die
vorhandenen Abbruchwege. Ein Consumer akzeptiert ausschließlich seine aktive
vollständige Bindung; unbekannte Protokollversionen werden nativ verworfen.

`LumoLearningActionRequest` enthält `identity`, ganzzahlige `requestId`,
`action` sowie optional ganzzahlige `turnId`, `objectId` und `candidate`.
`requestId` wird vom vorhandenen Bus vergeben. `turnId` und `utteranceId`
gehören dem jeweiligen Gesprächs-/Wiedergabecontroller. Eine Aktion kann
keine Sterne, XP, Fortschritt, Richtigkeit oder Aufgabenwechsel setzen.

`LumoCompanionTaskContext` enthält den vorhandenen fachlichen Snapshot:
`subject`, `unit`, `prompt`, `isExam`, `answering`, `taskId`, `attempts`,
`helpLevel`, `lastAnswer`, `lastCorrect`, `previousHelp`, `localHelp`,
`activity`, `ownerSection`, `profileGeneration` sowie die additiven Felder
`stepId`, `objectIds`, `explanation`, `errorType`, `answerChoices`,
`allowedActions`, `isExplanation`. Der Aufgabenbesitzer erzeugt das geprüfte
Ergebnis, die Fehlerart und die nächste fachlich zulässige Hilfestufe. Es gibt
keine parallelen Felder `nextHint`, `answerState` oder `domainFeedback`.
Der ruhige Modus stammt aus den vorhandenen Einstellungen/Präsentationsadaptern.

`allowedActions` ist eine vom Aufgabenbesitzer vorgegebene Teilmenge der neun
oben genannten Enum-Werte. Objektaktionen erfordern eine in `objectIds`
freigegebene Kennung; die Szene muss sie zusätzlich tatsächlich auflösen
können. `proposeAnswer` erfordert eine aktuell beantwortbare Aufgabe und einen
nichtleeren, begrenzten Kandidaten. In Prüfungen sind nur ausdrücklich
freigegebenes Wiederholen/Langsamerlesen sowie Stopp zulässig. Fehlender
aktiver Kontext gibt keine inhaltliche Hilfe frei. KI-Ausgaben bleiben
unverbindliche, durch diese Grenzen geprüfte Aktionsvorschläge.

## Fachliche Antwortgrenze

Spracherkennung erzeugt einen sichtbaren Antwortvorschlag. Ein verhörter
Wert und „nicht zwölf, dreizehn“ verändern nur diesen unbestätigten
Vorschlag. Erst die ausdrückliche Bestätigung wird an den gebundenen
bestehenden Fachcontroller gegeben. Ein später Callback einer älteren
Bindung verändert weder neue Aufgabe noch Fortschritt.

Wiederholen/Tempoänderung verwenden die letzte gültige Erklärung derselben
Aufgabe und erzeugen keine neue Wertung. Hilfen stammen aus der aktuellen
Fachlogik und schreiten nur innerhalb ihrer zulässigen Stufen fort.

## Figur und benannte Lernobjekte

`LumoLearningPresentation` bindet `identity`, optional `turnId` und
`utteranceId`, `gazeObjectId`, `pointObjectId`, `expression` und
`animationState`. Der Bus prüft Identität und Objektfreigabe vor Veröffentlichung.

Chat 3s Registry bleibt an die konkrete Lektion gebunden.
`LearningLumoActor.bind_interaction_context()` validiert zuerst die komplette
kanonische Identität einschließlich `stepId` und erlaubter Aktionen. Erst dann
wird intern `lesson_id = sessionId + '/' + taskId` mit `revision` gebunden.
Interne Director-Turns enthalten einen lokalen Besitzerzähler und die jeweilige
Interaktions-/Audiokennung. Ein Höchststand verwirft alte Gesprächsrunden;
`cancelEpoch` ist Teil der geprüften Identität und kein angehängter String.
Das interne Director-Format ist kein zweiter öffentlicher Gesprächsvertrag.

Tatsächlich registrierte Ziele entstehen in `LearningWorldNext._bind_targets()`
und `_sync_semantic_targets()`: unter anderem `addend_a_00..`, `addend_b_00..`,
`ten_frame_primary/slot_0..9`, `ten_frame_secondary/slot_0..9`, `ten_frame`,
`syllable_0..`, `syllable_destination_0..`, `pattern_item_00..`, `plant_` mit
dem vorhandenen Teilnamen sowie `science_banana`. Eine Kennung ist nur in der
passenden aktiven Szene verfügbar. Weitere IDs sind kompatibel ergänzbar,
wenn Aufgabenfreigabe und tatsächliche Registrierung übereinstimmen.

Der vorhandene Actor/Chat-3-Director erhält `listening`, `thinking`,
`explain`, `point`, `focused_input`, `interrupt`, `encourage`,
`celebrate`, `greeting`, `farewell`. `target_id` muss existieren.
Blick und Pfote beziehen sich auf dasselbe sichtbare Ziel. Ruhiger Modus
reduziert dekorative Bewegung, erhält aber fachliche Hervorhebungen.

## Audio, Untertitel und Mund

`LumoLearningAudioFrame` enthält `identity`, ganzzahlige `turnId` und
`utteranceId`, `state`, `subtitle`, `positionMs`, `durationMs`, `audible`,
`envelopeAvailable` und `envelope`. Quelle ist die tatsächliche Wiedergabe,
keine aus der Textlänge erfundene Uhr. `mouthTiming` ist abgeleitet
`envelope` oder `none`; `wordTimingAvailable` und `phonemeTimingAvailable`
sind in diesem Vertrag ausdrücklich `false`. Die native vorhandene
Wiedergabe-ID bleibt in ihrem Adapter erhalten. Untertitel bleiben lesbar.

Der Actor/Director kann zusätzliche validierte Mund-Cues annehmen. Die
integrierte freie Sprachquelle liefert derzeit keine geprüften Phonemzeiten.
Deshalb wird nur hüllkurvengesteuerte Mundbewegung behauptet. Banane verwendet
tatsächlich getrennte Wiedergaben für Wort und Silben; zugehörige Ziele werden
an deren realen Wiedergabezustand gebunden.

Die gemeinsame Flutter-Wiedergabe besitzt zusätzlich `LumoVoice.requestRevision`.
Sie schützt den aktuellen Audioauftrag unabhängig von der semantischen
Aufgabenidentität: eine alte Seite darf beim späteren Aufräumen keinen neueren
Playerauftrag stoppen. Nach asynchronem Stop wird vor erneutem Start der
Besitzer nochmals geprüft. Ein temporäres langsameres Erklären benutzt den
jeweiligen `speedFactor`; es überschreibt keine globale Tempoeinstellung.

Stopp/Pause/Wechsel verwirft Erkennung und offene Antwort, stoppt Audio,
schließt den Mund und beendet zugehörige Geste gemeinsam. Aufnahme
beenden und Äußerung abbrechen sind getrennte Aktionen. Wiederaufnahme
startet weder Mikrofon noch alte Antwort automatisch.

## Abdeckung und gemeinsame Prüfungen

Die vollständige maschinenlesbare Route-/Aufgabentypmatrix wird unter
`docs/nextgen/COVERAGE.json` geführt. Ungeprüfte/unerreichbare Pfade
bleiben explizit offen. Drei Referenzszenen ersetzen diese Matrix nicht.

1. 8 + 5: acht Objekte, fünf daneben, zwei zur Zehn, drei verbleibend;
   „Warum zuerst zwei?“ bezieht sich auf die aktuelle Szene.
2. Banane: Ba–na–ne, Wiederholung und langsame Erklärung an aktuellem Audio.
3. Muster: periodische Gruppe hervorheben, Hinweis vor eigener Antwort.
4. Fehlantwort, verhörte Zahl, Korrektur, Stopp, Aufgabenwechsel während
   Antwort, Pause/Wiederaufnahme, Profilwechsel und doppelter Callback.
5. Handy, Fold-Außen/Innen, Rotation/Größenänderung, Textvergrößerung,
   48-dp-Ziele, unveränderter Lernstand.

60 FPS bleiben ein Messziel. Headless/Widget/Desktop-Prüfungen werden
nicht als Android-Geräte- oder physischer Fold7-Beleg ausgegeben.

## Kompatible Integrationskorrekturen vor Kandidat 2028

Der öffentliche Vertrag bleibt v1. Das Lab erkennt für sein Gespräch die konkret eigene `ModalBottomSheetRoute`; fremde Überlagerungen erhalten keinen Aufgabenbesitz. Die Schließgrenze reicht bis zum tatsächlichen Abschluss dieser Route. Alte Controller speichern ihre eigene Lernidentität und ihren eigenen `LumoVoice.requestRevision`; Aufräumen nach Pause/Wechsel/Dispose darf weder einen neuen Auftrag stoppen noch eine neue Abbruchepoche erzeugen. Ausdrückliches aktives Stopp bleibt eine eigene erlaubte Aktion.

Native Android-Methoden werden über die tatsächlich vorhandene JNI-Capability-Auskunft geprüft. Der geroutete Next-Szenenbesitzer verwendet denselben Weg für Sprachsegment- und Gesprächsabbruch. Der Musteradapter liest die geprüfte Gruppe aus `parameters.patternUnit`, validiert sie gegen Startsequenz/kleinste Periode und verwendet ausschließlich ein aktuell registriertes Gruppenziel. Eine fehlende oder null-`stepId` bleibt dieselbe optionale Identität; eine leere Zeichenkette darf sie nicht vertreten. Diese Konkretisierungen ändern weder Aufgabenkennungen noch Speicher- oder Belohnungsformate.

Originale und gezielte Prüfnachweise stehen in `evidence/conversation-scope-fix-20261115/`, `evidence/native-pattern-context-fix-20261115/` und im nativen Repository unter `docs/nextgen/evidence/android-capability-followup-20261115/`. Die vollständige neue Androidtour bleibt eine gesonderte Abnahme.
