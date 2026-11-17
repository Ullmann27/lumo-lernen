# Lumo-Nachhilfe – Bestandsnotiz (Strang tutor, 17.11.2026, ~13:10 Europe/Vienna)

Nur gelesen; Basis Flutter `4af64ec5` (integration/lumo-playready-20261117, 2036), Godot `bb478880`.

## Was es schon gibt (wird wiederverwendet, keine Parallelstruktur)

| Bereich | Datei(en) | Nutzung im Tutor |
|---|---|---|
| Tutor-Verträge | `lib/core/lumo_tutor_contracts.dart` (`LumoTutorHelpLevel` hintOnly→guidedStep→visualExplanation→fullMiniLesson, `LumoTutorVisualType` tenFrame/numberLine …) | Hilfestufen der Nachhilfe werden 1:1 auf diese vier Stufen abgebildet |
| Tutor-Engine | `lib/core/lumo_tutor_engine.dart` (lokal, offline; wählt Stufe nach Versuchen, schlägt Visual vor) | bleibt; Nachhilfe ergänzt die Wegeauswahl darunter |
| Rechentricks | `lib/core/math/lumo_rechentricks.dart` (`RechentricksKind` swapNumbers, neighborTask, bridgeTen, smallFirst …) | jeder Nachhilfe-Weg verweist auf den passenden RechentricksKind |
| Fehlerarten | `lib/domain/learning/lumo_learning_domain.dart` `ErrorType` (countingError, plusMinusConfusion, tenTransitionWeak, placeValueWeak …), `error_detective.dart` | Fehlermuster der Nachhilfe benutzen diese Enum-Werte |
| Aufgabenmodell | `TaskInstance` + `LegacyLumoTaskAdapter._visualData` (liefert `{operation: addition, left, right}` für „a + b = ?“) | Einstieg erkennt Aufgabentyp nur aus diesen geprüften Daten |
| Generatoren | `lib/core/math_task_templates.dart` (`g1_add_20` 2–12 + 1–8, `g2_add_20` 2–18 + 1–12, Minus bis 20, Plus/Minus bis 100, Einmaleins, Brüche) | M1 = „Plus bis 20“ (Kl. 1/2), M2 = Minus/100/Brüche/Einmaleins |
| 3D-Brücke | `lib/features/lumo3d/lumo3d_launcher.dart` `launchLumo3D(scene: 'learning', learning: NativeLearningActivity)`; Android `tools/auto_install/MainActivity.kt` Kind-Whitelist; Godot `app_boot.gd`, `scene_router.gd` | Tutor fährt als neue Kind `tutor` über dieselbe Lern-Route (Scope, Stimme, Rückkehr „learn“) |
| 3D-Lernwerkstatt | Godot `scripts/learning/learning_world.gd` (+ activity/atelier/holo_atrium), Kinds bridge_ten, addition, subtract_ten, equal_groups, equal_sharing, bridge_hundred, fraction_parts, clock, syllables, pattern, plant_parts, english_objects | Optik (Holo-Atrium, Wisps, Bevel-Boxen) und Sprachprotokoll `speakLearning` werden übernommen |
| Blender-Fuchs | Godot `scripts/characters/lumo/lumo_rigged_actor.gd` (Teacher-Modus: `teacher_react`, `set_teaching_target`, `set_teacher_speaking`) | Lumo zeigt im Tutor jeden Schritt vor |
| 2D-Visuals | `lib/features/tutoring/guided_ten_frame_animation.dart`, `guided_math_illustration.dart` | Stil-Referenz für den Flutter-Fallback |
| Lernfortschritt / Lern-DNA | `learning_dna*.dart`, `ErrorBreakdownRepository`, `progress_repository.dart` | nur lesend (M3), nie schreibend |

PR-Bezug: lumo-lernen #520–#525/#527 (Lernwerkstatt) und #510–#516 (NextGen Fuchs/Sprache); lumo-godot #191, #193 sind Vorfahren von `bb478880`, #194 inhaltlich laut INVENTUR enthalten. Flutter-Branches von #510–#516/#520–#522/#525 sind **keine** Vorfahren von `4af64ec5` (Inhalt ggf. per Squash übernommen – hier nicht dateiweise geprüft).

## Was fehlt (Auftrag dieses Strangs)

- Kein Tutor, der **eine konkrete Aufgabe** mit abgestuften Hilfen, mehreren Lösungswegen und Fehlermuster→Weg-Zuordnung durchführt.
- Keine interaktive 3D-Szene, in der Lumo einen Schritt vorzeigt und das Kind ihn selbst nachmacht (Rechenrahmen schieben, auf dem Zahlenstrahl hüpfen).

## Befund am Rande (nicht in diesem Strang geändert)

- `tools/auto_install/MainActivity.kt` (Basis 4af64ec5) lässt für `learning` die Kind `clock` **nicht** zu, Flutter sendet sie aber (`NativeLearningActivity.fromTask`, VisualType.clock). Folge laut Code: 3D-Uhr endet auf Android mit `invalid_learning`. Kein Gerätelog, nicht verifiziert.

## Leitplanken

Lernfortschritt, Profile, Schreibtrainer, Journal, Reward-Wallet: unverändert. Der Tutor schreibt keine Lerndaten, vergibt keine Sterne und gibt die Lösung der Originalaufgabe nie preis (Vorzeigen an einer Zwillingsaufgabe).
