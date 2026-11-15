# LUMO Next Generation — gemeinsamer Anschluss v1

Stand 15.11.2026. Hauptchat 1, Arbeitsbereich `4fa97167812c`.
Dies ist ein Implementierungsvertrag, keine Fertig- oder Gerätefreigabe.

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

Zusätzliche aktive Lernzweige in `c5a7dadab95f` und `ea41c7b116ac` wurden
beobachtet. Ihre Rollen sind noch nicht bestätigt; keine Übernahme oder
Zusammenarbeit ohne konkrete Übergabe behaupten.

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
Der folgende äußere Umschlag ergänzt sie. Keine zweite Aufgabenlogik
oder zweite Speicherung einführen.

## Umschlag v1

Alle neuen asynchronen Aktionen tragen:

```json
{
  "schema": "lumo.learning.interaction",
  "version": 1,
  "sessionId": "opaque-session",
  "taskId": "existing-task-id",
  "revision": 1,
  "contextRevision": 1,
  "cancelEpoch": 0,
  "turnId": "opaque-turn",
  "type": "explain"
}
```

`sessionId` ist ein flüchtiger Besitzertoken, keine Kinderidentität.
`taskId` bleibt die vorhandene Aufgabenkennung. `revision` bezeichnet die
aktuelle Aufgaben-/Szenenrevision, `contextRevision` den übergeordneten
Gesprächskontext. `cancelEpoch` erhöht sich bei Stopp, Hintergrund,
Aufgaben-/Profilwechsel. Ein Consumer akzeptiert nur exakt seine aktive
Bindung; unbekannte Versionen und unzulässige Aktionen werden verworfen.

Ein Aufgaben-Snapshot ergänzt `stepId`, `prompt`, `objects`, `allowedActions`,
`nextHint`, `answerState`, `reduceMotion` und optional `domainFeedback`.
Objekte besitzen stabile IDs, Typ und sichtbare Beschriftung. IDs werden
von der aktuellen Szene registriert, nicht vom Sprachmodell erfunden.
`domainFeedback` kann nur die vorhandene Fachlogik erzeugen und enthält
geprüfte Richtigkeit, Fehlerart, Versuch und nächste erlaubte Hilfe.

`allowedActions` ist eine vom Aufgabenbesitzer vorgegebene Teilmenge:
`explain`, `why`, `hint`, `repeat`, `slower`, `proposeAnswer`,
`correctCandidate`, `confirmAnswer`, `focusObject`, `stop`.
Prüfungsaufgaben erlauben keine lösungsverratende Hilfe. KI-Ausgaben sind
unverbindliche Aktionsvorschläge; es existiert keine Aktion für Sterne,
XP, Fortschritt, richtige Antwort oder Aufgabenwechsel.

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

Chat-3-Registry bleibt lesson-scoped. Zuordnung:
`lesson_id = sessionId + '/' + taskId`, `revision = revision`;
`turn_id = turnId + '/' + cancelEpoch`.

Vereinbarte Ziele: `addend_a_00..`, `addend_b_00..`,
`ten_frame_primary/slot_0..9`, `ten_frame_secondary/slot_0..9`,
`syllable_0..2`, `pattern_item_00..`, `plant_root`, `plant_stem`,
`plant_leaf`, `plant_flower`. Weitere IDs sind kompatibel ergänzbar,
sofern die aktuelle Szene sie tatsächlich registriert.

Der vorhandene Actor/Chat-3-Director erhält `listening`, `thinking`,
`explain`, `point`, `focused_input`, `interrupt`, `encourage`,
`celebrate`, `greeting`, `farewell`. `target_id` muss existieren.
Blick und Pfote beziehen sich auf dasselbe sichtbare Ziel. Ruhiger Modus
reduziert dekorative Bewegung, erhält aber fachliche Hervorhebungen.

## Audio, Untertitel und Mund

Eine Äußerung besitzt `utteranceId`, `turnId`, `text`, optional `cues`.
Untertitel bleiben als vollständiger Text zugänglich. Wiedergabestatus
enthält `state`, `positionMs`, `durationMs`, `audible`, `envelope`,
`envelopeAvailable`; Quelle ist die reale Wiedergabe, nicht eine Textuhr.
Das bisherige native `id` wird kompatibel auf die Äußerung abgebildet.

Optionale Mund-Cues: `{start_ms,end_ms,shape,weight}` mit validierten
Grenzen, auf die tatsächliche Audio-Abspielposition bezogen. Ohne
verifizierte Phonemzeitdaten bleibt die vorhandene Audiohüllkurve der
Fallback; daraus wird keine phonemgenaue Lippensynchronität behauptet.

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
