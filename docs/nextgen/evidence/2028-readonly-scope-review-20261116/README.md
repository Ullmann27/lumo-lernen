# Unabhängiger Quellenabgleich für Kandidat 2028

Zwei getrennte Read-only-Durchsichten bestätigen den Lernumfang und die Sprach-/Figurenanschlüsse der unveränderten APK-Quelle `fc5f6403cb8fb5e26a103ec2deeaa3662c5fa242` mit Native `678cb38fea3a83a7f5841e71fba9bb2f3bfa2eef`. Der beobachtete Root-Stand `79354ef545100f574041f11584f594c9172e2f69` ändert weder Flutter-Produktquellen noch Android-Hostvorlagen gegenüber der gebauten APK. Die Reviews führen keine neuen Tests aus und leiten keinen Android-PASS aus Quellcode ab.

## Lernumfang

Die verbindliche Matrix `docs/nextgen/COVERAGE.json` enthält 61 Einträge und 55 Screen-Dateien, darunter Navigation, geschützte sowie inaktive Pfade. Das sind keine 61 eigenständig bewerteten Aufgaben. 236 Klassen-/Fach-/Einheitsfamilien sind angeschlossen, aber nicht sämtlich als individuelle 3D-Szene ausgearbeitet oder auf Android durchgespielt.

19 aktive Fachmoduleinstiege führen in 18 Oberflächen: sechs in Klasse 1, neun in Klasse 2, drei in Klasse 3 und einer in Klasse 4. Die beiden Einmaleins-Einstiege teilen einen Screen; `d1_woerter` wird vom geschützten Wortcoach abgefangen. Die vorhandenen Modulprüfungen und Fortschrittswege bleiben die fachliche Autorität. Die native Erweiterung dieser Einstiege ist jeweils die generische Aufgabenkarte.

Die sechs Labs (Zehnerbrücke, Wortwerkstatt, English-Welt, Weg des Wassers, Bruchatelier, Formenwerkstatt) behalten ihre interaktiven Flutter-Fachmodelle und 35 feste Problem-IDs. Ihre nativen Einstiege verwenden ebenfalls die aktuelle Aufgabenkarte. Sieben geführte Lektionen binden aktuelle Schritte an Spezialmodell oder Kartenrückfall. Lesen, Reading Buddy, Story, Foto-Lektion, 49 MiniGame-Level, Quiz/Level 50, Cards, Live und 2D Flame verfügen über ihre bestehenden bewertenden Controller mit hinzugefügtem Coach/Native-Einstieg; in Tests bleiben Lösungshilfen gesperrt. Bei 60 Praxisaktivitäten ist menschliche Journalbeobachtung bewusst keine automatische Fachbewertung.

Elf spezielle native Darstellungen ergänzen die Aufgabenkarte: addition, bridge_hundred, bridge_ten, english_objects, equal_groups, equal_sharing, fraction_parts, pattern, plant_parts, subtract_ten und syllables. Ihre geprüften Parameterbereiche sind keine Vollabdeckung ganzer Fächer. Alte mehrdeutige Deutsch-Lückensätze bleiben inaktiv; der alte Teacher-Themenchat ist kein aktuell erreichbarer bewerteter Lernweg.

## Sprache und Figur

Die tatsächlich geroutete `scenes/learning/learning_world.tscn` benutzt `scripts/lumo_next/learning_world_next.gd` und den importierten Lernfuchs mit Rig, AnimationPlayer, Director und Zielregister. Blick und Pfote beziehen sich auf registrierte Mengenobjekte, Feldplätze, Silben und Musteranker. Der vorhandene Präsentationsweg bleibt die separate Godot-Activity.

Native Sprache entsteht lokal über Supertonic-3/F2 und ONNX, WAV und Android MediaPlayer. Die Mundbewegung verwendet eine aus tatsächlichen PCM-Daten berechnete 20-ms-RMS-Hüllkurve an der echten Abspielposition. Produktive Phonem-Cues fehlen, ebenso Wort-Timestamps; lautgenaue Lippenbewegung und wortweise Untertitel werden nicht behauptet. Banane verwendet getrennte tatsächliche Wort-/Silbensegmente und Playbackzustände.

Die native Gesprächslogik ist ein lokaler, auf freigegebene Aufgabenaktionen begrenzter Router. Der optionale konfigurierte KI-Proxy gehört zum Flutter-Pfad und bleibt von Eltern-/Bereichsfreigaben, Sicherheit und Aufgabenautorität abhängig. Uneingeschränktes generatives Gespräch ist nicht nachgewiesen. Native Spracheingabe verlangt ausdrücklichen Start und On-Device-Erkennungsfähigkeit; das finale Transkript bleibt vor dem Senden editierbar. Antwortkandidaten werden erst über den vorhandenen Aufgabenbesitzer gewertet. Kein Gesprächscontroller vergibt eigenständig XP oder Sterne.

Identität, Revision, Abbruchepoche, Gesprächs- und Audio-ID verhindern veraltete Änderungen. Stopp, Aufgaben-/Profilwechsel und Pause beenden eigene Aufnahme/Wiedergabe und Darbietung. Alte Flutter-Controller dürfen keinen neuen Audioauftrag stoppen. Wiederaufnahme startet eine durch inactive abgebrochene Mikrofonvorbereitung nicht automatisch.

## Freigabegrenzen

`fullModernizationComplete=false` bleibt zutreffend. Gemeinsamer Coach und native Karte erfüllen noch keine individuelle räumliche Modernisierung jeder Variante. Physischer Fold7, tatsächliche gesprochene Erkennung/Korrektur, akustische Qualität, umfassende Varianten-/Barrierefreiheitsprüfung und dauerhafte Hardwareleistung brauchen eigene Nachweise. 18 Schreib-/Journalinternas bleiben bytegleich; Kart und nativer Dschungel sind ausgeschlossen.

Quellen: `docs/nextgen/COVERAGE.json`, `COVERAGE.md`, `INTEGRATION_V1.md`; `lib/domain/tutoring/native_learning_activity.dart`, `lib/features/learning/nextgen/module_task_scope.dart`, `lib/features/learning/widgets/learning_question_coach.dart`, `lib/core/lumo_conversation_controller.dart`, `lib/core/lumo_learning_dialogue_intent.dart`; `tools/auto_install/LumoLearningSpeech.kt`, `LumoOfflineSpeechEngine.java`, `LumoSpeechEnvelope.kt`, `LumoLearningConversation.kt`, `LumoLearningDialogLogic.java`; im nativen Repository `scripts/lumo_next/learning_lumo_actor.gd`, `avatar_director.gd`, `learning_world_next.gd` und `scripts/learning/learning_world.gd`.
