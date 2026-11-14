# Aktuelle acf51-Logs: Studio und Gameplay

Die gespeicherten Originalmetadaten bestätigen **studio (Job 132356963309)** und **gameplay (Job 132356963393)** als `completed/success` im Lauf **43565059832, Versuch 1**, Quelle `acf51d3bd2997c4b731e9a48e1791e05e756a132`. Die Jobs endeten um 06:25:14 bzw. 06:25:28 UTC. Der Status wurde aus `polls/064334-jobs-original.json` gelesen, nicht aus PASS-Zeilen abgeleitet. Dieser Review führt keine Tests aus und öffnet keine Bilder.

## Studio: 20 aktuelle Prüfgruppen

| Gruppe | Ausführung | Tatsächlich gemeldete Werte | Originallog-Zeile |
|---|---|---|---:|
| LearningSharing | headless | checks=1811 | 3224 |
| LearningStudio | headless | checks=183 | 3252 |
| LumoStudioMotion | headless | checks=1047 | 3263 |
| PuzzleRotation | headless | checks=4558 | 3274 |
| PuzzleMenuLifecycle | headless | checks=720 | 3343 |
| TreasureExploration | headless | checks=87 | 3354 |
| CardsAndroidInsets | public Java API boundary fixture | checks=20, failures=0 | 3364 |
| CardsSafeArea | headless fixture | checks=662, failures=0, profiles=5, images=0 | 3376 |
| MobileSafeArea | headless platform fixture | checks=112, failures=0, controls=15, images=0 | 3420 |
| LearningSharingCapture | renderer | captures=6 | 3468 |
| LumoStudioCapture | renderer | renderer_frames=8 | 3486 |
| PuzzleRotation | renderer | checks=4565 | 3504 |
| PuzzleMenuLifecycle | renderer | checks=732 | 3580 |
| TreasureExploration | renderer | checks=90 | 3598 |
| CardsSafeArea | renderer platform fixture | checks=671, failures=0, profiles=5, images=3 | 3616 |
| MobileSafeArea | renderer platform fixture | checks=124, failures=0, controls=15, images=4 | 3668 |
| LumoFacial | headless | checks=102, original_bones=65, original_clips=9, phoneme_lipsync=False | 3680 |
| LumoFacialCapture | renderer/movie capture | declared_capture_frames=144, recording_fps=24, not_device_fps=True | 3699 |
| ConnectFourVisual | renderer visual-state fixture | checks=303, captures=4, fixture=True | 3724 |
| TreasureTitleContrast | renderer platform fixture | checks=137, failures=0 | 3749 |

Der anschließende Roster akzeptiert **53 PNG-Dateien**. Die globale `[LumoStudio] PASS`-Zeile ist eine Zusammenfassung, keine 21. Prüfgruppe. Headless- und Renderausführungen sind getrennt aufgeführt; ihre überlappenden Bedingungen werden nicht zu einer vermeintlich eindeutigen Testgesamtzahl addiert.

Der aktuelle MovieMaker meldet **640×640, 148 geschriebene Frames, 24 Aufnahmebilder/s**; der Capturemarker benennt separat 144 Inhaltsframes. Die gedruckten Durchschnittswerte CPU 128,79 ms/Frame, GPU 125,18 ms/Frame und Encoding 4,72 ms/Frame stammen aus dem Linux-Software-Renderer. Sie sind **kein Android- oder Fold7-Leistungsnachweis** und werden nicht zu einer Geräte-FPS-Angabe umgedeutet.

## Gameplay: aktuelle quantitative Zusammenfassungen

| Gruppe | Tatsächlich gemeldeter Umfang |
|---|---|
| KartLasso | 34 assertions |
| KartLassoProduction | 26 assertions |
| SpatialMenu | 594 checks; 5/5 cases |
| RoadsideAction | 183 assertions |
| GarageTargets | 255 visible controls, >=48x48dp |
| CompactKartSelection | 355 checks; 6/6 cases |
| ZauberwaldLibrary | 601 checks |
| JumpExtras | 12 checks |
| CreativeTouchLayout | 300 checks |
| PuzzleExpansion | 1103 checks |
| Garage3DTouch | 27 checks |
| MenuDepth | 41 checks |
| LumoKartTickCadence | 1196 checks; failures=0 |
| LumoGestureContact | 200 checks; failures=0 |
| GaragePresentation | 66 checks |
| AirTrick | 20 checks |
| LumoAttentionLanding | 1846 checks; failures=0 |

Der Strukturprüfer meldet separat **117 PASS / 7 WARN / 0 FAIL**. Weitere qualitative Gruppen einschließlich Hostbridge, Sprung, Kartphysik, Drift/Items, KI, Streckenkontakt, Vollrunden, Bauwerkzeuge und Materialintegration sind mit ihren unveränderten Originalzeilen in [review.json](review.json) erhalten. Die 8.000 geteilten Aufgaben sind ein Inhaltsumfang; der alte 44px-Marker ist keine 48dp-Geräteabnahme. Weder diese Werte noch wiederholte globale PASS-Zeilen werden addiert.

Die neue Attention-Landing-Zeile bestätigt tatsächlich **1.846 Bedingungen / 0 Fehler**, unverändertes Originalmodell und gebundenen Gesichtsableiter, Handkontaktmaximum 1,14512140862644 mm sowie Landeimpuls 0,573351026912431. Der Bericht setzt selbst `android_test=false` und `fps_measured=false`.

## Konkrete Ressourcenmeldungen trotz erfolgreichem Job

| Unmittelbar zugehöriges Skript | Gameplay-Logzeilen | Meldung | Exitcode-Einordnung |
|---|---:|---|---|
| `scripts/tests/kart_ai_behavior_regression.gd` | 3817–3822 | ObjectDB + ERROR: 4 resources | 0, aus Pipelinefortsetzung abgeleitet |
| `scripts/tests/kart_racecraft_regression.gd` | 3905–3911 | ObjectDB + ERROR: 4 resources | 0, aus Pipelinefortsetzung abgeleitet |
| `scripts/tests/kart_full_field_regression.gd` | 4231–4236 | ObjectDB + ERROR: 2 resources | 0, aus Pipelinefortsetzung abgeleitet |
| `scripts/tests/kart_harbor_race_hook_regression.gd` | 4407–4412 | ObjectDB | 0, aus Pipelinefortsetzung abgeleitet |

**Der numerische Einzelprozess-Exitcode wird im Console-Log nicht separat ausgegeben.** Der Wert 0 ist aus den exakt an acf51 gebundenen Harnessquellen und der folgenden erfolgreichen Probe abgeleitet: `set -euo pipefail`, nicht maskierte `timeout/Godot | tee`-Pipelines, danach weitere Probeausführung und erfolgreicher GitHub-Schritt. Die Quellen sind unter `exact-sources/` mit ihren tatsächlichen Gitblobs gespeichert.

Die vorhandenen Checker in `validate_project.sh` und `validate_2014.sh` nehmen den Wortlaut `resources still in use at exit` ausdrücklich aus ihrer ERROR-Suche aus. Das erklärt den erfolgreichen Gateabschluss; **es belegt keine Harmlosigkeit der Ressourcenmeldung** und diagnostiziert keinen neuen Produktfehler. Die vier Prozesskontexte stehen vollständig in `review.json`. Die Resourceangaben 4, 4, 2 werden nicht zu einer Anzahl verschiedener geleakter Ressourcen zusammengezählt. Der zweite HarborRaceHook-Aufruf im Technical-Art-Teil ist getrennt protokolliert und hat dort keine unmittelbar folgende ObjectDB-Meldung.

## Weitere Warnungen und Grenzen

- Studio: je 10 Meldungen zu nicht umschaltbarem V-Sync, nicht verfügbarem Screen-space-AA und Volumetric Fog im Compatibility-Renderer; Gameplay jeweils 19. Beide verwenden tatsächlich Mesa/llvmpipe auf Linux.
- Gameplay-Struktur: sechs fehlende Manifestpfade unter `assets/models/` und ein nicht ausführbares `tools/build_web_bundle.sh`. Diese spezifischen Legacy-Pfadwarnungen sind nicht der Nachweis, dass der separat SHA-geprüfte Original-/Gesichtsfuchs fehlt.
- Hostbridge-Testabschnitte: 19 Meldungen `reward not saved; retry on return` mit `integer-pending`, `retry-test` bzw. `host-test`-Kennungen. Sie bleiben als Originalwarnungen erhalten; daraus folgt keine zusätzliche Android-Persistenzfreigabe.
- Ein fehlgeschlagener Cursor-Ladevorgang `crossed_circle`; ADB-Daemonverbindung abgelehnt einmal im Studio- und zweimal im Gameplaylog. Diese nativen Linux-Jobs sind keine angeschlossenen Android-Geräteläufe.
- Je Job ursprüngliche Node-/Action-Deklarationswarnungen zu `punycode`, `url.parse` und Node 20 → 24.
- Keine tatsächliche SCRIPT-/Parse-Error-Zeile beobachtet. Der in Shellbefehlen gedruckte Suchausdruck ist kein Laufzeitfehler. Gameplay bleibt wegen der drei Ressourcen-ERROR-Zeilen ausdrücklich **nicht logfehlerfrei**.

Noch nicht Gegenstand dieses Reviews: vollständiges Originalarchiv, persönliche Sichtung der acht zugeordneten neuen Bilder, alle übrigen Nativejobs, Android2020, physische Fold7-Wärme/FPS/Eingabelatenz. Die Desktop-Inset- und C4-Beispielzustände bleiben Fixtures, auch wenn ein wiederverwendeter Produktionslogger `actual Android View insets` schreibt.

## Unveränderte Originale

| Datei | Bytes | SHA256 |
|---|---:|---|
| studio-original-job.log | 369464 | `12af7f939bc5db2a9c03af0d207fb5f3a3b6bc5a0551d48319f6a0edcb7960e0` |
| gameplay-original-job.log | 528847 | `1202bb4bdf2aedca7cb71efb6d65db1e029959cbf947c7be8b03e228105d6563` |
| gespeicherte Jobmetadaten | 16343 | `e4726ae7a6222515568b4aa18923997a6b922c52bc737234a5a1176d34a64fc2` |

Die genauen Originalpfade, Zeitstempel, Warnungsstellen und Sourcebindungen sind in [review.json](review.json) dokumentiert. Keine Produktdatei und kein Gitref wurde verändert.
