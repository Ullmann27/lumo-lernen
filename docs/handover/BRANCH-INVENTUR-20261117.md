# Branch-Inventur lumo-lernen – 17.11.2026 (Nullpunkt)

Erstellt von Lumo · HAUPTBOT (Grok Bot) im Auftrag von Heinz („Ja merge“, 17.11.2026 12:35 Europe/Vienna).

Integrationsbasis: `origin/integration/lumo-original-assets-readiness-20261117 @ 7e71dd07`. Remote-Branches gesamt (ohne main): 784.

## Kategorien

- **A** schon enthalten: Tip ist Vorfahre von main/Integrationslinie, oder ein Merge ändert keine Datei (dann als No-op-Merge formal angeschlossen).
- **B** fertig und integrierbar: konfliktfrei, ab 10.11.2026, ändert keine `.github`-Workflows → gemergt.
- **C** Konflikt, halbfertig (WIP), veraltet (vor 10.11.), ändert CI/Release-Workflows oder enthält Release-Werkzeug → nicht gemergt, Grund angegeben.
- **D** ersetzt: Tip ist Vorfahre eines neueren Branches (genannt) oder parallele Variante.
- **W** in Arbeit anderer Bots (lumo-2040/* Lumo · Design, lumo-kart/* Chef-HAUPTBOT-Bots) → nicht angefasst.
- **N** nach der Inventur neu angelegt → nicht angefasst.

| Kategorie | Anzahl |
|---|---|
| A | 321 |
| B | 25 |
| C | 300 |
| D | 137 |
| W | 1 |

## Tabelle

| Branch | PR | SHA | Datum | Kat. | Beleg | Aktion |
|---|---|---|---|---|---|---|
| `lumo-2040/memory-20261117` | – | b93aef5b | 2026-11-17 | W | in Arbeit (Lumo · Design) | nicht angefasst |
| `checkpoint/lumo-803-ci-20261114-2708` | – | 6a5ae532 | 2026-11-14 | B | konfliktfrei, 171 Datei(en): docs/evidence/android-803a-original-20261114/README.md;docs/evidence/android-803a-original-20261114/c4/original-job-1324 | Merge |
| `checkpoint/lumo-aab-ci-20261114-2708` | – | 6845d78d | 2026-11-14 | B | konfliktfrei, 633 Datei(en): docs/evidence/c4-057a-prebuild-originals-20261114/android-host-compile-original.log;docs/evidence/c4-057a-prebuild-origi | Merge |
| `evidence/lumo-budget-reviews-20261114` | – | 458e0b13 | 2026-11-14 | B | konfliktfrei, 6 Datei(en): docs/evidence/combined-budgets-independent-20261114/budget-pack-manifest.original.json;docs/evidence/combined-budgets-in | Merge |
| `evidence/lumo-c4-3d91bd83-20261114` | – | 1fb10622 | 2026-11-14 | B | konfliktfrei, 6 Datei(en): docs/evidence/c4-3d-runtime-compile-20261114/handoff.json;docs/evidence/c4-3d-runtime-compile-20261114/original-archive- | Merge |
| `evidence/lumo-c4-79c0ec8-20261114` | – | 5e186bd0 | 2026-11-14 | B | konfliktfrei, 30 Datei(en): docs/evidence/c4-79c0ec8-run43581113174/actual-runtime/compact-checkpoint.tar.gz;docs/evidence/c4-79c0ec8-run43581113174 | Merge |
| `evidence/lumo-feature-7136-20261114` | – | 75ef92e1 | 2026-11-14 | B | konfliktfrei, 13 Datei(en): docs/evidence/feature-7136-run43591310250/artifacts.original.json;docs/evidence/feature-7136-run43591310250/bound-summar | Merge |
| `evidence/lumo-feature-trigger-b2-20261114` | – | 1b20b238 | 2026-11-14 | B | konfliktfrei, 1 Datei(en): docs/evidence/safari-mode-ownership-20261114/b2-trigger-source-review.json | Merge |
| `evidence/lumo-feature30-red-93bd9b78-20261114` | – | c4a6692e | 2026-11-14 | B | konfliktfrei, 8 Datei(en): docs/evidence/live-integration-20261114/feature30-red-93bd9b78/artifact-and-source-manifest.json;docs/evidence/live-inte | Merge |
| `evidence/lumo-final-flutter-04a8e850-20261114` | – | ceb38070 | 2026-11-14 | B | konfliktfrei, 30 Datei(en): docs/evidence/live-integration-20261114/final-04a8e850/feature30/archive-manifest.json;docs/evidence/live-integration-20 | Merge |
| `evidence/lumo-final-flutter-07cac-20261114` | – | b40260ed | 2026-11-14 | B | konfliktfrei, 9 Datei(en): docs/evidence/flutter-final-07cac-20261114/README.md;docs/evidence/flutter-final-07cac-20261114/acceptance-summary-from- | Merge |
| `evidence/lumo-final-flutter-1e22-20261114` | – | 8eeaa8fb | 2026-11-14 | B | konfliktfrei, 47 Datei(en): docs/evidence/flutter-final-1e22-20261114/README.md;docs/evidence/flutter-final-1e22-20261114/dedicated-c4/observed-jobs | Merge |
| `evidence/lumo-final-flutter-6b3047b7-20261114` | – | e10a171a | 2026-11-14 | B | konfliktfrei, 22 Datei(en): docs/evidence/live-integration-20261114/final-6b3047b7/feature30/artifact-and-source-manifest.json;docs/evidence/live-in | Merge |
| `evidence/lumo-integration-0b7-20261114` | – | ff7e1e87 | 2026-11-14 | B | konfliktfrei, 311 Datei(en): docs/evidence/c4-preferences-independent-review-20261114/manifest.json;docs/evidence/c4-preferences-independent-review-2 | Merge |
| `evidence/lumo-live-android-07cac722-20261114` | – | 5cc5ef04 | 2026-11-14 | B | konfliktfrei, 17 Datei(en): docs/evidence/live-integration-20261114/final-07cac722/astra-script-regression/actual-checkout-commit-api.json;docs/evid | Merge |
| `evidence/lumo-live-android-1e22d245-20261114` | – | 95670d76 | 2026-11-14 | B | konfliktfrei, 199 Datei(en): docs/evidence/live-integration-20261114/final-04a8e850/build-contracts/build-contracts.original.log;docs/evidence/live-i | Merge |
| `evidence/lumo-native-original-review-07cac722-20261114` | – | a6216484 | 2026-11-14 | B | konfliktfrei, 7 Datei(en): docs/evidence/live-integration-20261114/native-original-review-07cac722/README.md;docs/evidence/live-integration-2026111 | Merge |
| `evidence/lumo-producer-1225-host-20261114` | – | fcf514a6 | 2026-11-14 | B | konfliktfrei, 10 Datei(en): docs/evidence/producer-1225-host-20261114/README.md;docs/evidence/producer-1225-host-20261114/baseline-review.json;docs/ | Merge |
| `evidence/lumo-producer-heads-20261114` | – | bf6b6e4b | 2026-11-14 | B | konfliktfrei, 21 Datei(en): docs/evidence/producer-heads-20261114-1050/index.json;docs/evidence/producer-heads-20261114-1050/originals/host32_tree.j | Merge |
| `evidence/lumo-release-readiness-1e22-20261114` | – | 520e1538 | 2026-11-14 | B | konfliktfrei, 14 Datei(en): docs/evidence/release-readiness-1e22-20261114/READINESS.json;docs/evidence/release-readiness-1e22-20261114/README.md;doc | Merge |
| `evidence/lumo-root-04-review-20261114` | – | 877dcec4 | 2026-11-14 | B | konfliktfrei, 15 Datei(en): docs/evidence/current-host04-review-20261114/all-current-runs-1909.original.json;docs/evidence/current-host04-review-202 | Merge |
| `evidence/lumo-root-6b-review-20261114` | – | b3988eb7 | 2026-11-14 | B | konfliktfrei, 39 Datei(en): docs/evidence/current-built-apks-6b-20261114/actual-village-return-blocker.json;docs/evidence/current-built-apks-6b-2026 | Merge |
| `evidence/lumo-upstream057-garage-review-20261114` | – | c9d40fdf | 2026-11-14 | B | konfliktfrei, 7 Datei(en): docs/evidence/upstream057-host-review-20261114/focused-command.json;docs/evidence/upstream057-host-review-20261114/focus | Merge |
| `evidence/lumo-village-return-lifecycle-6b-20261114` | – | 297cc672 | 2026-11-14 | B | konfliktfrei, 11 Datei(en): docs/evidence/live-integration-20261114/final-6b3047b7/village-diagnostic-independent-review/diagnostic-independent-revi | Merge |
| `feature/lumo-nextgen-learning-chat2-20261115` | – | 7f555aa6 | 2026-11-15 | B | konfliktfrei, 1 Datei(en): docs/nextgen_20261115/CHAT2_HANDOFF.md | Merge |
| `feature/lumo-nextgen-learning-tasks-20261115` | – | 42637538 | 2026-11-15 | B | konfliktfrei, 3 Datei(en): docs/integration/lumo-nextgen-20261115/CHAT2_TASKS_HANDOFF.md;docs/integration/lumo-nextgen-20261115/COVERAGE_BASELINE.j | Merge |
| `active-sentence-syllables-20260503` | – | a1ca3dc0 | 2026-05-03 | C | veraltet: Stand 2026-05-03, 2704 Commits hinter Integrationslinie; ändert lib/core/lumo_learning_help_orchestrator.dart;test/lumo_learning_help_orchestrator_test.dart | nicht gemergt (veraltet, ungeprüft) |
| `audit-voice-barrel-20260503` | – | 10ef5386 | 2026-05-03 | C | Merge-Konflikt in 2 Datei(en): lib/features/shared/widgets/lumo_widgets.dart;test/lumo_widgets_barrel_test.dart | nicht gemergt |
| `audit-voice-widgets-20260503` | – | 7a4da777 | 2026-05-03 | C | Merge-Konflikt in 2 Datei(en): lib/features/shared/widgets/lumo_widgets.dart;test/lumo_widgets_barrel_test.dart | nicht gemergt |
| `audit/lumo-1919-diagnostics-2026-10-09` | – | cfbb4ce8 | 2026-10-10 | C | ändert .github (Workflows/Agenten, u.a. APK/Publish/Patcher): .github/probes/inspect_lumo_1919_api35.py;.github/probes/inspect_lumo_1919_failure.py;.github/probes/inspect_lumo_1919_s | nicht gemergt (CI/Release-Risiko, Einzelprüfung nötig) |
| `audit/lumo-1919-gas-recovery-2026-10-09` | #242 | 2247999b | 2026-10-10 | C | ändert .github (Workflows/Agenten, u.a. APK/Publish/Patcher): .github/probes/fixtures/lumo-1919-baseline-apksigner.txt;.github/probes/prepare_lumo_1919_gas_replay.py;.github/probes/r | nicht gemergt (CI/Release-Risiko, Einzelprüfung nötig) |
| `audit/lumo-1919-verified-package-2026-10-09` | – | 8e4f20c3 | 2026-10-10 | C | ändert .github (Workflows/Agenten, u.a. APK/Publish/Patcher): .github/probes/collect_lumo_1919_evidence.py;.github/probes/lumo_1919_aggregation_lock.json;.github/probes/replay_lumo_1 | nicht gemergt (CI/Release-Risiko, Einzelprüfung nötig) |
| `audit/lumo-originals-9de-20261114` | – | 40f47361 | 2026-11-14 | C | Merge-Konflikt in 21 Datei(en): .github/probes/modernization_android_tour.py;.github/workflows/lumo-astra-script-recovery.yml;.github/workflows/lumo-connect-four-2020.yml;.github/workflows/lumo-learning-curriculum-audit. | nicht gemergt |
| `chatgpt/android-install-upgrade-2026-10-07` | #209 | 0510b374 | 2026-10-07 | C | ändert .github (Workflows/Agenten, u.a. APK/Publish/Patcher): .github/workflows/lumo-1321-update-audit.yml;docs/checkpoints/android-install-upgrade-2026-10-07.md;scripts/probes/lumo_ | nicht gemergt (CI/Release-Risiko, Einzelprüfung nötig) |
| `chatgpt/apk1948-resume-qa-2026-10-16` | – | c6153496 | 2026-10-16 | C | ändert .github (Workflows/Agenten, u.a. APK/Publish/Patcher): .github/probes/kart_complete_android_probe.py;.github/workflows/lumo-1948-recheck.yml;tools/android_qa/tests/fixtures/ka | nicht gemergt (CI/Release-Risiko, Einzelprüfung nötig) |
| `chatgpt/cards-resume-safety-2026-10-06` | #206 | 589f10c8 | 2026-10-06 | C | Merge-Konflikt in 4 Datei(en): lib/features/games/lumo_cards/lumo_cards_screen.dart;test/lumo_cards_controller_lifecycle_test.dart;test/lumo_cards_session_ui_test.dart;test/lumo_cards_session_visual_test.dart | nicht gemergt |
| `chatgpt/fix-akademie-practical-scroll-2026-10-06` | – | eac00552 | 2026-10-07 | C | Merge-Konflikt in 15 Datei(en): lib/app/app_theme.dart;lib/core/cognitive_profile_generator.dart;lib/core/cognitive_profile_repository.dart;lib/core/cognitive_profile_scorer.dart;lib/features/learning/curriculum_activiti | nicht gemergt |
| `chatgpt/fold-apk-android-2026-10-07` | – | bec8bca5 | 2026-10-07 | C | Merge-Konflikt in 1 Datei(en): .github/probes/creative_android_probe.py | nicht gemergt |
| `chatgpt/fold-apk-build-2026-10-07` | – | 8d3f9a7a | 2026-10-07 | C | ändert .github (Workflows/Agenten, u.a. APK/Publish/Patcher): .github/workflows/lumo-fold-exact-apk.yml | nicht gemergt (CI/Release-Risiko, Einzelprüfung nötig) |
| `chatgpt/fold-reference-recovery-2026-10-05` | #192 | 06cb801f | 2026-10-05 | C | Merge-Konflikt in 3 Datei(en): lib/app/app_shell.dart;lib/features/home/home_content.dart;lib/widgets/fox/lumo_free_companion.dart | nicht gemergt |
| `chatgpt/gemini-source-export-2026-10-15` | – | 2d1f255c | 2026-10-15 | C | ändert .github (Workflows/Agenten, u.a. APK/Publish/Patcher): .github/workflows/lumo-gemini-source-export.yml | nicht gemergt (CI/Release-Risiko, Einzelprüfung nötig) |
| `chatgpt/hologlass-consistency-stage2-2026-10-06` | – | b3f161e7 | 2026-10-06 | C | Merge-Konflikt in 2 Datei(en): lib/features/games/games_content.dart;lib/features/learning/learning_dna_card.dart | nicht gemergt |
| `chatgpt/hologlass-quiz-stage3-2026-10-06` | – | f37a93b8 | 2026-10-06 | C | Merge-Konflikt in 1 Datei(en): lib/features/quiz/quiz_show_content.dart | nicht gemergt |
| `chatgpt/learning-visual-fold-tree-2026-10-09` | #275,#234 | 1579327f | 2026-10-09 | C | Merge-Konflikt in 2 Datei(en): lib/features/learning/renderers/adaptive_task_renderer.dart;lib/features/teacher_mode/lumo_akademie_screen.dart | nicht gemergt |
| `chatgpt/lumo-1916-apk-artifact-2026-10-09` | – | 4f3f4ae6 | 2026-10-09 | C | ändert .github (Workflows/Agenten, u.a. APK/Publish/Patcher): .github/workflows/lumo-1916-apk-artifact.yml | nicht gemergt (CI/Release-Risiko, Einzelprüfung nötig) |
| `chatgpt/lumo-1917-apk-artifact-2026-10-09` | #238 | b82b6475 | 2026-10-09 | C | Merge-Konflikt in 1 Datei(en): pubspec.yaml | nicht gemergt |
| `chatgpt/lumo-1938-android-smoke-2026-10-12` | – | 5dae77a7 | 2026-10-12 | C | Merge-Konflikt in 1 Datei(en): .github/probes/creative_android_probe.py | nicht gemergt |
| `chatgpt/lumo-1938-android-smoke-direct-2026-10-12` | – | 7e9523ea | 2026-10-12 | C | ändert .github (Workflows/Agenten, u.a. APK/Publish/Patcher): .github/probes/creative_android_probe.py;.github/workflows/lumo-1938-android-smoke-direct.yml | nicht gemergt (CI/Release-Risiko, Einzelprüfung nötig) |
| `chatgpt/lumo-1938-emergency-fallback-2026-10-12` | – | e0ce0dd4 | 2026-10-12 | C | veraltet: Stand 2026-10-12, 1552 Commits hinter Integrationslinie; ändert config/lumo-emergency-takeover-1938.json;docs/handoffs/LUMO_EMERGENCY_TAKEOVER_1938_2026-10-12.md | nicht gemergt (veraltet, ungeprüft) |
| `chatgpt/lumo-1938-evidence-2026-10-12` | – | 3ce49455 | 2026-10-12 | C | ändert .github (Workflows/Agenten, u.a. APK/Publish/Patcher): .github/workflows/lumo-1938-evidence.yml | nicht gemergt (CI/Release-Risiko, Einzelprüfung nötig) |
| `chatgpt/lumo-1963-direct-arm64-apk-2026-10-16` | – | 8a478271 | 2026-10-16 | C | ändert .github (Workflows/Agenten, u.a. APK/Publish/Patcher): .github/workflows/lumo-1963-direct-apk.yml | nicht gemergt (CI/Release-Risiko, Einzelprüfung nötig) |
| `chatgpt/lumo-1977-verified-arm64-download-2026-10-18` | #365 | b6b52918 | 2026-10-18 | C | ändert .github (Workflows/Agenten, u.a. APK/Publish/Patcher): .github/workflows/lumo-1977-arm64-delivery.yml | nicht gemergt (CI/Release-Risiko, Einzelprüfung nötig) |
| `chatgpt/lumo-1978-connect-four-fold-controls-2026-10-18` | #364 | 96ceeda4 | 2026-10-18 | C | Merge-Konflikt in 2 Datei(en): lib/features/games/connect_four/lumo_connect_four_game.dart;test/games/connect_four_fold_controls_test.dart | nicht gemergt |
| `chatgpt/lumo-1987-denkprofil-knobel-unified-2026-10-19` | #380 | aa30567c | 2026-10-19 | C | veraltet: Stand 2026-10-19, 853 Commits hinter Integrationslinie; ändert test/cognitive_profile_visual_prompt_test.dart | nicht gemergt (veraltet, ungeprüft) |
| `chatgpt/lumo-1991-full-race-qa-2026-10-20` | #388 | b1720b77 | 2026-10-20 | C | ändert .github (Workflows/Agenten, u.a. APK/Publish/Patcher): .github/workflows/lumo-1991-full-race-acceptance.yml | nicht gemergt (CI/Release-Risiko, Einzelprüfung nötig) |
| `chatgpt/lumo-1992-direct-release-20261020` | – | 323e03a6 | 2026-10-20 | C | ändert .github (Workflows/Agenten, u.a. APK/Publish/Patcher): .github/workflows/lumo-1992-chrome-direct-release.yml | nicht gemergt (CI/Release-Risiko, Einzelprüfung nötig) |
| `chatgpt/lumo-2005-star-trail-scroll-regression-fix-20261103` | – | 80ed7304 | 2026-11-03 | C | Merge-Konflikt in 1 Datei(en): test/design/parent_games_polish_test.dart | nicht gemergt |
| `chatgpt/lumo-2015-android-garage-qa-20261111` | #456 | a1d581f0 | 2026-11-11 | C | ändert .github (Workflows/Agenten, u.a. APK/Publish/Patcher): .github/probes/lumo_2015_garage_android_probe.py;.github/workflows/lumo-2015-android-garage-qa.yml;docs/qa/lumo-2015-and | nicht gemergt (CI/Release-Risiko, Einzelprüfung nötig) |
| `chatgpt/lumo-2015-verified-apk-delivery-20261111` | – | 2bb543dd | 2026-11-11 | C | ändert .github (Workflows/Agenten, u.a. APK/Publish/Patcher): .github/workflows/lumo-2015-verified-release.yml;docs/LUMO_2015_DELIVERY_PREPARATION_20261111.md;docs/qa/lumo_2015_deliv | nicht gemergt (CI/Release-Risiko, Einzelprüfung nötig) |
| `chatgpt/lumo-2016-direct-apk-candidate-20261111` | #458 | fe3f75d3 | 2026-11-11 | C | ändert .github (Workflows/Agenten, u.a. APK/Publish/Patcher): .github/workflows/lumo-2016-direct-apk-candidate.yml | nicht gemergt (CI/Release-Risiko, Einzelprüfung nötig) |
| `chatgpt/lumo-2017-publication-recovery-20261112` | #460 | 1166e9ae | 2026-11-12 | C | ändert .github (Workflows/Agenten, u.a. APK/Publish/Patcher): .github/workflows/lumo-2017-publication-recovery.yml | nicht gemergt (CI/Release-Risiko, Einzelprüfung nötig) |
| `chatgpt/lumo-2018-android-acceptance-20261113` | – | ab3c004c | 2026-11-13 | C | Merge-Konflikt in 5 Datei(en): .github/probes/creative_android_probe.py;.github/probes/lumo_2003_update_android_probe.py;.github/probes/lumo_nextgen_surfaces_android_probe.py;tools/android_qa/tests/test_update_preservati | nicht gemergt |
| `chatgpt/lumo-2018-review-recovery-20261113` | – | b56295f5 | 2026-11-13 | C | Merge-Konflikt in 1 Datei(en): scripts/tests/test_nextgen_review_recovery.py | nicht gemergt |
| `chatgpt/lumo-2019-release-candidate-20261113` | #467 | d5bf60e7 | 2026-11-13 | C | Merge-Konflikt in 13 Datei(en): config/godot-source.json;docs/evidence/kart-graphics-2019-reviewed/metadata/feedback/artifact.json;docs/evidence/kart-graphics-2019-reviewed/metadata/feedback/image-manifest.json;docs/evid | nicht gemergt |
| `chatgpt/lumo-2020-android-qa-recovery-20261113` | – | 8deec32c | 2026-11-13 | C | Merge-Konflikt in 50 Datei(en): .github/probes/lumo_2003_update_android_probe.py;.github/probes/modernization_android_tour.py;.github/workflows/lumo-kart-graphics-2019.yml;.github/workflows/lumo-unified-integration-2026. | nicht gemergt |
| `chatgpt/lumo-2020-direct-apk-delivery-20261113` | – | 4a7cf762 | 2026-11-13 | C | Merge-Konflikt in 50 Datei(en): .github/probes/lumo_2003_update_android_probe.py;.github/probes/modernization_android_tour.py;.github/workflows/lumo-kart-graphics-2019.yml;.github/workflows/lumo-unified-integration-2026. | nicht gemergt |
| `chatgpt/lumo-android17-cli22-recheck-20261113` | #472 | 02376fb6 | 2026-11-13 | C | Merge-Konflikt in 10 Datei(en): .github/probes/lumo_2003_update_android_probe.py;config/godot-source.json;scripts/android_framework_ready.py;scripts/prepare_android37_cli22.py;scripts/prepare_android37_emulator_action.py | nicht gemergt |
| `chatgpt/lumo-android17-framework-recheck-20261113` | #470 | 03630761 | 2026-11-13 | C | Merge-Konflikt in 9 Datei(en): .github/probes/lumo_2003_update_android_probe.py;config/godot-source.json;scripts/android_framework_ready.py;scripts/prepare_android37_emulator_action.py;scripts/tests/test_android_framewor | nicht gemergt |
| `chatgpt/lumo-android17-sdk-diagnostic-20261113` | – | 31b6c1d6 | 2026-11-13 | C | Merge-Konflikt in 6 Datei(en): .github/probes/lumo_2003_update_android_probe.py;config/godot-source.json;scripts/tests/test_candidate_2011_pin.py;scripts/verify_legacy_release_pin.py;tools/android_qa/tests/test_update_pr | nicht gemergt |
| `chatgpt/lumo-asset-production-100plus-2026-10-05` | #193 | 8dfad9c4 | 2026-10-05 | C | veraltet: Stand 2026-10-05, 2108 Commits hinter Integrationslinie; ändert tools/fetch_lumo_generated_reference_boards.sh | nicht gemergt (veraltet, ungeprüft) |
| `chatgpt/lumo-cards-landscape-hud-2026-10-09` | #231 | 9b6127f3 | 2026-10-09 | C | Merge-Konflikt in 6 Datei(en): lib/features/games/lumo_cards/lumo_cards_screen.dart;lib/features/games/lumo_cards/widgets/lumo_cards_score_header.dart;lib/features/games/lumo_cards/widgets/lumo_discard_pile.dart;lib/feat | nicht gemergt |
| `chatgpt/lumo-chat4-dialogue-20261115` | #512 | 4fa88ee2 | 2026-11-15 | C | Merge-Konflikt in 2 Datei(en): lib/app/lumo_companion_host.dart;lib/core/lumo_conversation_controller.dart | nicht gemergt |
| `chatgpt/lumo-ci-evidence-followup-2026-10-04` | #167 | f1b86c05 | 2026-10-04 | C | Merge-Konflikt in 1 Datei(en): .github/workflows/lumo-change-review.yml | nicht gemergt |
| `chatgpt/lumo-complete-games-2026-10-07` | #210 | 3123cb09 | 2026-10-07 | C | Merge-Konflikt in 13 Datei(en): .github/probes/creative_android_probe.py;config/godot-source.json;lib/app/app_shell.dart;lib/features/games/widgets/lumo_game_spotlights.dart;lib/features/home/home_content.dart | nicht gemergt |
| `chatgpt/lumo-complete-verified-2026-10-07` | – | 8d62c837 | 2026-10-07 | C | Merge-Konflikt in 12 Datei(en): .github/probes/creative_android_probe.py;lib/app/app_shell.dart;lib/features/games/widgets/lumo_game_spotlights.dart;lib/features/home/home_content.dart;lib/features/teacher_mode/lumo_akad | nicht gemergt |
| `chatgpt/lumo-creative-android-31883868-20261113` | #473 | 2fdd038d | 2026-11-13 | C | Merge-Konflikt in 22 Datei(en): .github/probes/lumo_2003_update_android_probe.py;.github/probes/studio_creative_android_probe.py;.github/workflows/lumo-studio-2019.yml;config/godot-source.json;scripts/android_framework_r | nicht gemergt |
| `chatgpt/lumo-cross-grade-hologlas-progress-safe-2026-10-16` | #320 | cc683eab | 2026-10-16 | C | Merge-Konflikt in 4 Datei(en): .github/workflows/lumo-cross-grade-visual-qa.yml;lib/features/learning/cross_grade_practice_screen.dart;test/cross_grade_practice_storage_hardening_test.dart;test/cross_grade_visual_capture | nicht gemergt |
| `chatgpt/lumo-direct-village-flutter-20261114` | #496 | 99f04bff | 2026-11-14 | C | Merge-Konflikt in 19 Datei(en): .github/workflows/lumo-connect-four-2020.yml;.github/workflows/lumo-learning-curriculum-audit.yml;.github/workflows/lumo-unified-integration-2026.yml;config/godot-source.json;lib/features/ | nicht gemergt |
| `chatgpt/lumo-floating-animated-fox-2026-10-07` | – | 76bd4e25 | 2026-10-07 | C | veraltet: Stand 2026-10-07, 2006 Commits hinter Integrationslinie; ändert docs/automation/lumo-floating-animated-fox-status-2026-10-07.md;lib/widgets/fox/lumo_free_companion. | nicht gemergt (veraltet, ungeprüft) |
| `chatgpt/lumo-home-readability-2026-10-04` | #179 | 22897357 | 2026-10-04 | C | veraltet: Stand 2026-10-04, 2119 Commits hinter Integrationslinie; ändert test/home_readability_acceptance_test.dart | nicht gemergt (veraltet, ungeprüft) |
| `chatgpt/lumo-inventory-2026-10-13` | #289 | 65eed904 | 2026-10-13 | C | veraltet: Stand 2026-10-13, 1532 Commits hinter Integrationslinie; ändert docs/audit/2026-10-13/ASTRA-ANBINDUNG.md;docs/audit/2026-10-13/BESTANDSMATRIX.md;docs/audit/2026-10- | nicht gemergt (veraltet, ungeprüft) |
| `chatgpt/lumo-kart-assets-handoff-2026-10-10` | #258 | 7cb18f10 | 2026-10-10 | C | veraltet: Stand 2026-10-10, 2106 Commits hinter Integrationslinie; ändert tools/upload_lumo_kart_assets.sh | nicht gemergt (veraltet, ungeprüft) |
| `chatgpt/lumo-learning-visual-apk-1915-2026-10-09` | – | 7f2c9b40 | 2026-10-09 | C | Merge-Konflikt in 2 Datei(en): .github/workflows/lumo-runtime-apk.yml;pubspec.yaml | nicht gemergt |
| `chatgpt/lumo-meister-host-safe-area-2026-10-15` | #305 | 305ecd52 | 2026-10-15 | C | Merge-Konflikt in 1 Datei(en): lib/features/quiz/quiz_show_content.dart | nicht gemergt |
| `chatgpt/lumo-meister-live-stage-2026-10-18` | #370 | 56b8ccb9 | 2026-10-18 | C | Merge-Konflikt in 2 Datei(en): lib/features/games/games_content.dart;lib/features/quiz/quiz_show_content.dart | nicht gemergt |
| `chatgpt/lumo-next-integration-2026-10-07` | – | 65d0a7d7 | 2026-10-07 | C | ändert .github (Workflows/Agenten, u.a. APK/Publish/Patcher): .github/workflows/lumo-next-integration.yml | nicht gemergt (CI/Release-Risiko, Einzelprüfung nötig) |
| `chatgpt/lumo-nextgen-feature-20261114` | – | 16442f28 | 2026-11-14 | C | Merge-Konflikt in 55 Datei(en): .github/probes/creative_android_probe.py;.github/probes/lumo_2003_update_android_probe.py;.github/probes/lumo_2020_update_android_probe.py;.github/probes/lumo_connect_four_android_probe.py | nicht gemergt |
| `chatgpt/lumo-play-aab-secure-staging-2026-10-19` | #382 | 89838274 | 2026-10-19 | C | Merge-Konflikt in 9 Datei(en): .github/workflows/lumo-games-before-after.yml;.github/workflows/lumo-unified-integration-2026.yml;lib/features/games/games_content.dart;lib/features/games/widgets/lumo_game_spotlights.dart; | nicht gemergt |
| `chatgpt/lumo-product-brief-2026-10-04` | #168 | 708945c0 | 2026-10-04 | C | veraltet: Stand 2026-10-04, 2133 Commits hinter Integrationslinie; ändert docs/PRODUKTAUFTRAG_LERNFORTSCHRITT_KART_2026-10-04.md | nicht gemergt (veraltet, ungeprüft) |
| `chatgpt/lumo-sonnenhafen-unified-apk-2026-10-15` | – | 1978642c | 2026-10-15 | C | Merge-Konflikt in 1 Datei(en): config/godot-source.json | nicht gemergt |
| `chatgpt/lumo-story-scene-art-transparent-2026-10-18` | #372 | 9226c089 | 2026-10-18 | C | Merge-Konflikt in 3 Datei(en): lib/features/learning_modules/zahlen_bis_100/zahlen_bis_100_screen.dart;lib/features/story/lumo_story_reader_screen.dart;lib/widgets/design/lumo_scene_art_panel.dart | nicht gemergt |
| `chatgpt/lumo-studio-078-kart-recheck-20261114` | – | 3f89e5f0 | 2026-11-14 | C | Merge-Konflikt in 45 Datei(en): .github/probes/creative_android_probe.py;.github/probes/lumo_2003_update_android_probe.py;.github/probes/lumo_2020_update_android_probe.py;.github/probes/lumo_connect_four_android_probe.py | nicht gemergt |
| `chatgpt/lumo-studio-2020-20261114` | #494 | 16442f28 | 2026-11-14 | C | Merge-Konflikt in 55 Datei(en): .github/probes/creative_android_probe.py;.github/probes/lumo_2003_update_android_probe.py;.github/probes/lumo_2020_update_android_probe.py;.github/probes/lumo_connect_four_android_probe.py | nicht gemergt |
| `chatgpt/lumo-studio-4ab-ocr-recheck-20261114` | #478 | 7d7b703f | 2026-11-14 | C | Merge-Konflikt in 26 Datei(en): .github/probes/creative_android_probe.py;.github/probes/lumo_2003_update_android_probe.py;.github/probes/studio_creative_android_probe.py;.github/workflows/lumo-studio-2019.yml;config/godo | nicht gemergt |
| `chatgpt/lumo-studio-4ab96666-evidence-20261114` | #477 | e9ee5892 | 2026-11-14 | C | Merge-Konflikt in 26 Datei(en): .github/probes/lumo_2003_update_android_probe.py;.github/probes/lumo_studio_surfaces_android_probe.py;.github/probes/studio_creative_android_probe.py;.github/workflows/lumo-studio-2019.yml | nicht gemergt |
| `chatgpt/lumo-studio-evidence-archive-20261114` | #479 | 995e5eeb | 2026-11-14 | C | Merge-Konflikt in 26 Datei(en): .github/probes/lumo_2003_update_android_probe.py;.github/probes/lumo_studio_surfaces_android_probe.py;.github/probes/studio_creative_android_probe.py;.github/workflows/lumo-studio-2019.yml | nicht gemergt |
| `chatgpt/lumo-technical-art-host-20261111` | #455 | 6fbb1e2e | 2026-11-11 | C | Merge-Konflikt in 2 Datei(en): CONTINUE.md;STATUS.md | nicht gemergt |
| `chatgpt/lumo-three-qa-workers-20261114` | – | de4a5b85 | 2026-11-14 | C | Merge-Konflikt in 4 Datei(en): .github/workflows/lumo-learning-curriculum-audit.yml;lib/core/school_exercise_generator.dart;test/learning/learning_exact_selection_test.dart;tools/audit_learning_tasks_all_grades.dart | nicht gemergt |
| `chatgpt/lumo-visual-prep-2026-10-05` | – | 03ccb4f9 | 2026-10-05 | C | veraltet: Stand 2026-10-05, 2110 Commits hinter Integrationslinie; ändert docs/lumo_game_specs/2026-10-05/production_prep/README.md;docs/lumo_game_specs/2026-10-05/production | nicht gemergt (veraltet, ungeprüft) |
| `chatgpt/parent-games-polish-2026-10-07` | – | 4abda8dd | 2026-10-07 | C | Merge-Konflikt in 2 Datei(en): lib/features/games/widgets/lumo_game_spotlights.dart;test/design/parent_games_polish_test.dart | nicht gemergt |
| `chatgpt/visual-fidelity-recovery-2026-10-05` | – | eb7e62ce | 2026-10-05 | C | Merge-Konflikt in 3 Datei(en): lib/app/app_shell.dart;lib/features/home/home_content.dart;lib/widgets/design/lumo_design_system.dart | nicht gemergt |
| `checkpoint/lumo-198dd3-build-evidence-20261114` | – | 243ea774 | 2026-11-14 | C | Merge-Konflikt in 21 Datei(en): .github/probes/modernization_android_tour.py;.github/workflows/lumo-astra-script-recovery.yml;.github/workflows/lumo-connect-four-2020.yml;.github/workflows/lumo-learning-curriculum-audit. | nicht gemergt |
| `checkpoint/lumo-198dd3-early-evidence-20261114` | – | 1fec8cc0 | 2026-11-14 | C | Merge-Konflikt in 21 Datei(en): .github/probes/modernization_android_tour.py;.github/workflows/lumo-astra-script-recovery.yml;.github/workflows/lumo-connect-four-2020.yml;.github/workflows/lumo-learning-curriculum-audit. | nicht gemergt |
| `checkpoint/lumo-198dd3-native-evidence-20261114` | – | 09e6a618 | 2026-11-14 | C | Merge-Konflikt in 21 Datei(en): .github/probes/modernization_android_tour.py;.github/workflows/lumo-astra-script-recovery.yml;.github/workflows/lumo-connect-four-2020.yml;.github/workflows/lumo-learning-curriculum-audit. | nicht gemergt |
| `checkpoint/lumo-2018-card-recovery-20261113` | – | a6a0de28 | 2026-11-13 | C | Merge-Konflikt in 4 Datei(en): config/godot-source.json;scripts/tests/test_candidate_2011_pin.py;scripts/tests/test_nextgen_workflow_contract.py;scripts/verify_legacy_release_pin.py | nicht gemergt |
| `checkpoint/lumo-9de-android-evidence-20261114` | – | 728559c5 | 2026-11-14 | C | Merge-Konflikt in 21 Datei(en): .github/probes/modernization_android_tour.py;.github/workflows/lumo-astra-script-recovery.yml;.github/workflows/lumo-connect-four-2020.yml;.github/workflows/lumo-learning-curriculum-audit. | nicht gemergt |
| `checkpoint/lumo-9de-early-evidence-20261114` | – | 316e9cbc | 2026-11-14 | C | Merge-Konflikt in 21 Datei(en): .github/probes/modernization_android_tour.py;.github/workflows/lumo-astra-script-recovery.yml;.github/workflows/lumo-connect-four-2020.yml;.github/workflows/lumo-learning-curriculum-audit. | nicht gemergt |
| `checkpoint/lumo-9de-native-build-evidence-20261114` | – | e480133d | 2026-11-14 | C | Merge-Konflikt in 21 Datei(en): .github/probes/modernization_android_tour.py;.github/workflows/lumo-astra-script-recovery.yml;.github/workflows/lumo-connect-four-2020.yml;.github/workflows/lumo-learning-curriculum-audit. | nicht gemergt |
| `checkpoint/lumo-agent-publication-198dd3-20261114` | – | 0ec2dc90 | 2026-11-14 | C | Merge-Konflikt in 21 Datei(en): .github/probes/modernization_android_tour.py;.github/workflows/lumo-astra-script-recovery.yml;.github/workflows/lumo-connect-four-2020.yml;.github/workflows/lumo-learning-curriculum-audit. | nicht gemergt |
| `checkpoint/lumo-agent-publication-7c5-20261114` | – | 11c3929b | 2026-11-14 | C | Merge-Konflikt in 21 Datei(en): .github/probes/modernization_android_tour.py;.github/workflows/lumo-astra-script-recovery.yml;.github/workflows/lumo-connect-four-2020.yml;.github/workflows/lumo-learning-curriculum-audit. | nicht gemergt |
| `checkpoint/lumo-agent-publication-9de-20261114` | – | 9f5c4615 | 2026-11-14 | C | Merge-Konflikt in 21 Datei(en): .github/probes/modernization_android_tour.py;.github/workflows/lumo-astra-script-recovery.yml;.github/workflows/lumo-connect-four-2020.yml;.github/workflows/lumo-learning-curriculum-audit. | nicht gemergt |
| `checkpoint/lumo-agent-publication-review-20261114` | – | ae5e6d4d | 2026-11-14 | C | Merge-Konflikt in 21 Datei(en): .github/probes/modernization_android_tour.py;.github/workflows/lumo-astra-script-recovery.yml;.github/workflows/lumo-connect-four-2020.yml;.github/workflows/lumo-learning-curriculum-audit. | nicht gemergt |
| `checkpoint/lumo-c4-diagnostic-20261114` | – | a234c472 | 2026-11-14 | C | Merge-Konflikt in 18 Datei(en): .github/workflows/lumo-astra-script-recovery.yml;.github/workflows/lumo-connect-four-2020.yml;.github/workflows/lumo-learning-curriculum-audit.yml;.github/workflows/lumo-unified-integratio | nicht gemergt |
| `checkpoint/lumo-c4-navigation-20261114` | – | 59a3ea16 | 2026-11-14 | C | Merge-Konflikt in 18 Datei(en): .github/workflows/lumo-astra-script-recovery.yml;.github/workflows/lumo-connect-four-2020.yml;.github/workflows/lumo-learning-curriculum-audit.yml;.github/workflows/lumo-unified-integratio | nicht gemergt |
| `checkpoint/lumo-c4-preferences-20261114` | – | c91a3104 | 2026-11-14 | C | Merge-Konflikt in 21 Datei(en): .github/probes/modernization_android_tour.py;.github/workflows/lumo-astra-script-recovery.yml;.github/workflows/lumo-connect-four-2020.yml;.github/workflows/lumo-learning-curriculum-audit. | nicht gemergt |
| `checkpoint/lumo-c4-preferences-diagnostic-20261114` | – | f4526c87 | 2026-11-14 | C | Merge-Konflikt in 21 Datei(en): .github/probes/modernization_android_tour.py;.github/workflows/lumo-astra-script-recovery.yml;.github/workflows/lumo-connect-four-2020.yml;.github/workflows/lumo-learning-curriculum-audit. | nicht gemergt |
| `checkpoint/lumo-c4-return-51ec-diagnostic-20261114` | – | 40853963 | 2026-11-14 | C | Merge-Konflikt in 21 Datei(en): .github/probes/modernization_android_tour.py;.github/workflows/lumo-astra-script-recovery.yml;.github/workflows/lumo-connect-four-2020.yml;.github/workflows/lumo-learning-curriculum-audit. | nicht gemergt |
| `checkpoint/lumo-c4-return-evidence-20261114` | – | 60f5ac33 | 2026-11-14 | C | Merge-Konflikt in 21 Datei(en): .github/probes/modernization_android_tour.py;.github/workflows/lumo-astra-script-recovery.yml;.github/workflows/lumo-connect-four-2020.yml;.github/workflows/lumo-learning-curriculum-audit. | nicht gemergt |
| `checkpoint/lumo-c4-return-fixtures-recovery-20261114` | – | 3dd945b7 | 2026-11-14 | C | Merge-Konflikt in 21 Datei(en): .github/probes/modernization_android_tour.py;.github/workflows/lumo-astra-script-recovery.yml;.github/workflows/lumo-connect-four-2020.yml;.github/workflows/lumo-learning-curriculum-audit. | nicht gemergt |
| `checkpoint/lumo-final-integration-20261114` | – | 2a1ef0b8 | 2026-11-14 | C | Merge-Konflikt in 6 Datei(en): config/godot-source.json;docs/evidence/flutter-full-acceptance-cf2593-20261114/README.md;docs/evidence/home-subject-capture-20261114/README.md;docs/evidence/live-root-integration-20261114/s | nicht gemergt |
| `checkpoint/lumo-kart-diagnostic-20261114` | – | 2be4d11c | 2026-11-14 | C | Merge-Konflikt in 21 Datei(en): .github/probes/modernization_android_tour.py;.github/workflows/lumo-astra-script-recovery.yml;.github/workflows/lumo-connect-four-2020.yml;.github/workflows/lumo-learning-curriculum-audit. | nicht gemergt |
| `checkpoint/lumo-kart-observer-evidence-20261114` | – | c44a015f | 2026-11-14 | C | Merge-Konflikt in 21 Datei(en): .github/probes/modernization_android_tour.py;.github/workflows/lumo-astra-script-recovery.yml;.github/workflows/lumo-connect-four-2020.yml;.github/workflows/lumo-learning-curriculum-audit. | nicht gemergt |
| `checkpoint/lumo-kart-scroll-recovery-20261114` | – | 4ff6fa2a | 2026-11-14 | C | Merge-Konflikt in 21 Datei(en): .github/probes/modernization_android_tour.py;.github/workflows/lumo-astra-script-recovery.yml;.github/workflows/lumo-connect-four-2020.yml;.github/workflows/lumo-learning-curriculum-audit. | nicht gemergt |
| `checkpoint/lumo-live-publisher-04a8-20261114` | – | 1dbf1111 | 2026-11-14 | C | ändert .github (Workflows/Agenten, u.a. APK/Publish/Patcher): .github/workflows/lumo-live-2020-publish.yml;docs/evidence/publisher-04a8-preflight-20261114/README.md;docs/evidence/pub | nicht gemergt (CI/Release-Risiko, Einzelprüfung nötig) |
| `checkpoint/lumo-live-publisher-1e22-20261114` | – | 21c221fa | 2026-11-14 | C | ändert .github (Workflows/Agenten, u.a. APK/Publish/Patcher): .github/workflows/lumo-live-2020-publish.yml;docs/evidence/live-integration-20261114/publisher-apk-precheck-1e22d245.jso | nicht gemergt (CI/Release-Risiko, Einzelprüfung nötig) |
| `checkpoint/lumo-live-publisher-6b-20261114` | – | 361f409f | 2026-11-14 | C | ändert .github (Workflows/Agenten, u.a. APK/Publish/Patcher): .github/workflows/lumo-live-2020-publish.yml;docs/evidence/publisher-6b3047-preflight-20261114/README.md;docs/evidence/p | nicht gemergt (CI/Release-Risiko, Einzelprüfung nötig) |
| `checkpoint/lumo-live-publisher-ec936873-20261114` | – | 1e7835f5 | 2026-11-14 | C | Merge-Konflikt in 2 Datei(en): CONTINUE.md;STATUS.md | nicht gemergt |
| `checkpoint/lumo-live-qa-aab09275-20261114` | – | be956271 | 2026-11-14 | C | Merge-Konflikt in 2 Datei(en): scripts/verify_connect_four_delivery.py;tools/android_qa/connect_four_android_evidence.py | nicht gemergt |
| `checkpoint/lumo-originals-9de-diagnostic-audit-20261114` | – | 747ded41 | 2026-11-14 | C | Merge-Konflikt in 21 Datei(en): .github/probes/modernization_android_tour.py;.github/workflows/lumo-astra-script-recovery.yml;.github/workflows/lumo-connect-four-2020.yml;.github/workflows/lumo-learning-curriculum-audit. | nicht gemergt |
| `checkpoint/lumo-unchanged-2020-diagnostic-20261114` | – | fd2a2fba | 2026-11-14 | C | ändert .github (Workflows/Agenten, u.a. APK/Publish/Patcher): .github/workflows/lumo-unchanged-2020-apk-diagnostic.yml;docs/evidence/live-integration-20261114/unchanged-2020-diagnost | nicht gemergt (CI/Release-Risiko, Einzelprüfung nötig) |
| `chore-audit-tests-20260503b` | – | b9739947 | 2026-05-03 | C | Merge-Konflikt in 1 Datei(en): test/primary_school_word_data_test.dart | nicht gemergt |
| `chore-chat-guard-patcher` | – | 705d1528 | 2026-05-04 | C | ändert .github (Workflows/Agenten, u.a. APK/Publish/Patcher): .github/workflows/apply_chat_guard.yml | nicht gemergt (CI/Release-Risiko, Einzelprüfung nötig) |
| `chore-core-audit-tests-20260503` | – | 20686d0a | 2026-05-03 | C | Merge-Konflikt in 1 Datei(en): test/primary_school_word_data_test.dart | nicht gemergt |
| `chore-learn-guard-patcher` | – | 2bce0331 | 2026-05-04 | C | ändert .github (Workflows/Agenten, u.a. APK/Publish/Patcher): .github/workflows/apply_learn_guard.yml | nicht gemergt (CI/Release-Risiko, Einzelprüfung nötig) |
| `chore-problem-word-trainer` | – | 81741915 | 2026-05-04 | C | ändert .github (Workflows/Agenten, u.a. APK/Publish/Patcher): .github/workflows/apply_trainer_patch.yml | nicht gemergt (CI/Release-Risiko, Einzelprüfung nötig) |
| `chore-reading-guard-patcher` | – | 55e15bb6 | 2026-05-04 | C | ändert .github (Workflows/Agenten, u.a. APK/Publish/Patcher): .github/workflows/apply_reading_guard.yml | nicht gemergt (CI/Release-Risiko, Einzelprüfung nötig) |
| `chore-release-candidate-patcher` | – | 040cdfb4 | 2026-05-04 | C | ändert .github (Workflows/Agenten, u.a. APK/Publish/Patcher): .github/scripts/build_rc_patch.py;.github/workflows/apply_rc_patch.yml;rc_test.txt | nicht gemergt (CI/Release-Risiko, Einzelprüfung nötig) |
| `chore-smart-ears-patcher` | – | 72d83f04 | 2026-05-04 | C | ändert .github (Workflows/Agenten, u.a. APK/Publish/Patcher): .github/workflows/apply_smart_ears_patch.yml | nicht gemergt (CI/Release-Risiko, Einzelprüfung nötig) |
| `chore-syllable-ui-patcher` | – | 6814b051 | 2026-05-04 | C | ändert .github (Workflows/Agenten, u.a. APK/Publish/Patcher): .github/workflows/apply_syllable_patch.yml | nicht gemergt (CI/Release-Risiko, Einzelprüfung nötig) |
| `claude/design-tafeln` | #273,#183 | 8344c10f | 2026-10-04 | C | Merge-Konflikt in 1 Datei(en): pubspec.yaml | nicht gemergt |
| `claude/design-test-apk` | – | 4e5264ac | 2026-10-05 | C | Merge-Konflikt in 2 Datei(en): .github/workflows/release-apk.yml;config/godot-source.json | nicht gemergt |
| `claude/fix-lumo-cards-debugneeds` | – | 99315fba | 2026-05-22 | C | Merge-Konflikt in 2 Datei(en): lib/features/games/lumo_cards/lumo_cards_screen.dart;lib/features/games/lumo_cards/widgets/lumo_intro_splash.dart | nicht gemergt |
| `claude/integration-stories-2026-10-16` | – | 484a0de5 | 2026-10-16 | C | Merge-Konflikt in 1 Datei(en): lib/features/story/lumo_story_setup_screen.dart | nicht gemergt |
| `claude/kart-test-apk` | – | 142c139f | 2026-10-04 | C | Merge-Konflikt in 2 Datei(en): .github/workflows/release-apk.yml;config/godot-source.json | nicht gemergt |
| `claude/lumo-2027-coordination-20261029` | – | 89ab19bd | 2026-11-06 | C | veraltet: Stand 2026-11-06, 437 Commits hinter Integrationslinie; ändert docs/visual/2026-10-29-2027/BRIEFING.md;docs/visual/2026-10-29-2027/README.md | nicht gemergt (veraltet, ungeprüft) |
| `claude/lumo-2027-parents-20261029` | – | baa6d04f | 2026-10-29 | C | veraltet: Stand 2026-10-29, 437 Commits hinter Integrationslinie; ändert docs/audit/2026-10-29/PARENTS-2027-CLAIM.md | nicht gemergt (veraltet, ungeprüft) |
| `claude/lumo-aaa-spielwelt-20261113` | – | 8f269d3b | 2026-11-13 | C | Merge-Konflikt in 10 Datei(en): docs/evidence/kart-graphics-2019-reviewed/metadata/feedback/artifact.json;docs/evidence/kart-graphics-2019-reviewed/metadata/feedback/image-manifest.json;docs/evidence/kart-graphics-2019-r | nicht gemergt |
| `claude/lumo-android-integration-m0-aloove` | #331 | c116408a | 2026-10-29 | C | Merge-Konflikt in 5 Datei(en): lib/core/lumo_child_speech_normalizer.dart;lib/core/task_hint_service.dart;test/adaptive_task_help_test.dart;test/cross_grade_second_chance_test.dart;test/lumo_child_speech_normalizer_test. | nicht gemergt |
| `claude/lumo-kart-premium-A9oBr` | – | 5eda712b | 2026-05-20 | C | Merge-Konflikt in 4 Datei(en): lib/features/games/games_content.dart;lib/features/games/kart/lumo_kart_screen.dart;lib/features/writing/lumo_writing_coach_screen.dart;test/smoke_lumo_kart_test.dart | nicht gemergt |
| `claude/phase56-on-main` | – | 38d7a3f5 | 2026-05-21 | C | Merge-Konflikt in 18 Datei(en): lib/app/app_shell.dart;lib/core/lumo_companion_state.dart;lib/domain/writing/writing_word_bank.dart;lib/features/learning_modules/farben/farben_screen.dart;lib/features/learning_modules/ja | nicht gemergt |
| `claude/qa-empty-semantics-retry` | – | 0fad189b | 2026-10-04 | C | Merge-Konflikt in 1 Datei(en): tools/android_qa/tests/test_flutter_empty_semantics.py | nicht gemergt |
| `claude/voice-improvement-fwjkX` | #150 | d927321f | 2026-06-17 | C | Merge-Konflikt in 3 Datei(en): lib/core/app_settings.dart;lib/core/lumo_voice.dart;lib/features/settings/settings_content.dart | nicht gemergt |
| `claude/voice-on-codex-followup` | #154 | 37edbd33 | 2026-10-03 | C | Merge-Konflikt in 3 Datei(en): lib/core/app_settings.dart;lib/core/lumo_voice.dart;lib/features/settings/settings_content.dart | nicht gemergt |
| `codex/check-.github/workflows/release-apk.yml` | #49 | bc71868d | 2026-05-18 | C | Merge-Konflikt in 1 Datei(en): .github/workflows/release-apk.yml | nicht gemergt |
| `codex/lumo-1905-original-android-diagnosis-2026-10-08` | – | 7cff9e0e | 2026-10-09 | C | ändert .github (Workflows/Agenten, u.a. APK/Publish/Patcher): .github/workflows/lumo-original-android-diagnosis.yml;docs/handoffs/LUMO_ORIGINAL_ANDROID_DIAGNOSIS_1905_2026-10-08.md | nicht gemergt (CI/Release-Risiko, Einzelprüfung nötig) |
| `codex/lumo-holographic-2026-10-03` | – | f8445af2 | 2026-10-04 | C | Merge-Konflikt in 1 Datei(en): config/godot-source.json | nicht gemergt |
| `codex/lumo-host-time-precision-2026-10-09` | #229 | 280b2425 | 2026-10-09 | C | Merge-Konflikt in 2 Datei(en): .github/probes/kart_complete_android_probe.py;tools/android_qa/tests/test_kart_complete_android_evidence.py | nicht gemergt |
| `codex/lumo-kart-event-forensics-2026-10-09` | – | caff6535 | 2026-10-09 | C | ändert .github (Workflows/Agenten, u.a. APK/Publish/Patcher): .github/workflows/lumo-finish-event-forensics.yml | nicht gemergt (CI/Release-Risiko, Einzelprüfung nötig) |
| `codex/lumo-kart-menu-1921-2026-10-10` | #246 | f9295c76 | 2026-10-10 | C | veraltet: Stand 2026-10-10, 1733 Commits hinter Integrationslinie; ändert docs/design/2026-10-10-lumo-games/README.md;docs/design/2026-10-10-lumo-games/SONNET_5_5_UMSETZUNGSA | nicht gemergt (veraltet, ungeprüft) |
| `codex/lumo-kart-premium-apk-1921-2026-10-10` | #245 | b39ed83b | 2026-10-10 | C | Merge-Konflikt in 3 Datei(en): .github/workflows/lumo-runtime-apk.yml;config/godot-source.json;pubspec.yaml | nicht gemergt |
| `codex/lumo-main-proof-read-2026-10-10` | – | 848ae3ef | 2026-10-10 | C | ändert .github (Workflows/Agenten, u.a. APK/Publish/Patcher): .github/workflows/lumo-main-proof-inspect.yml | nicht gemergt (CI/Release-Risiko, Einzelprüfung nötig) |
| `codex/lumo-profile-android-1920-2026-10-10` | #244 | 8d16e719 | 2026-10-10 | C | ändert .github (Workflows/Agenten, u.a. APK/Publish/Patcher): .github/probes/profile_assignment_android_probe.py;.github/workflows/lumo-profile-android-1920.yml;tools/android_qa/test | nicht gemergt (CI/Release-Risiko, Einzelprüfung nötig) |
| `codex/lumo-profile-diagnostics-2026-10-10` | – | 3c9a5b6a | 2026-10-10 | C | ändert .github (Workflows/Agenten, u.a. APK/Publish/Patcher): .github/probes/profile_assignment_android_probe.py;.github/workflows/lumo-profile-android-1920.yml;.github/workflows/lum | nicht gemergt (CI/Release-Risiko, Einzelprüfung nötig) |
| `codex/lumo-return-frame-recovery-2026-10-09` | #224 | 2fea2da9 | 2026-10-09 | C | Merge-Konflikt in 5 Datei(en): .github/probes/kart_complete_android_probe.py;OPUS_NEXT.md;config/godot-source.json;tools/android_qa/native_handoff_evidence_recovery.py;tools/android_qa/native_lap_evidence_recovery.py | nicht gemergt |
| `codex/lumo-stage1-audit-44095eb` | #153 | 3bd1128a | 2026-10-02 | C | veraltet: Stand 2026-10-02, 2290 Commits hinter Integrationslinie; ändert docs/LUMO_ETAPPE_1_2026-10-02.md;scripts/audit_question_bundles.py;scripts/tests/test_audit_question | nicht gemergt (veraltet, ungeprüft) |
| `codex/lumo-tutor-quota-diagnostics-2026-10-03` | – | 51845502 | 2026-10-03 | C | Merge-Konflikt in 1 Datei(en): server/lumo-ai-proxy/test/server.test.js | nicht gemergt |
| `codex/lumo-unified-android-2026-10-03` | – | ea76df9e | 2026-10-04 | C | ändert .github (Workflows/Agenten, u.a. APK/Publish/Patcher): .github/workflows/lumo-asset-staging.yml;docs/ASSET_EMPFANG_2026-10-04.md;scripts/assets/fetch_lumo_bundle_2026_10_04.py | nicht gemergt (CI/Release-Risiko, Einzelprüfung nötig) |
| `codex/lumo-visual-fidelity-2026-10-08` | #219 | 49733466 | 2026-10-08 | C | Merge-Konflikt in 5 Datei(en): .github/probes/kart_complete_android_probe.py;.github/workflows/lumo-runtime-apk.yml;OPUS_NEXT.md;config/godot-source.json;pubspec.yaml | nicht gemergt |
| `codex/opus-86c5a33-test-apk` | #195 | 20d8bb5f | 2026-10-05 | C | Merge-Konflikt in 2 Datei(en): .github/workflows/release-apk.yml;config/godot-source.json | nicht gemergt |
| `computer/lumo-1927-apk-handoff-2026-10-10` | – | 395ee554 | 2026-10-10 | C | Merge-Konflikt in 1 Datei(en): .github/workflows/release-apk.yml | nicht gemergt |
| `computer/lumo-1927-runtime-qa-same-apk-2026-10-10` | – | 05458f22 | 2026-10-10 | C | Merge-Konflikt in 2 Datei(en): .github/probes/lumo_speech_android_probe.py;.github/workflows/release-apk.yml | nicht gemergt |
| `computer/lumo-voice-next-runtime-fixes-2026-10-10` | – | c546f560 | 2026-10-10 | C | Merge-Konflikt in 1 Datei(en): test/profile_screen_test.dart | nicht gemergt |
| `connect-reading-v2-20260503` | – | 5aed42a2 | 2026-05-03 | C | Merge-Konflikt in 1 Datei(en): test/reading_syllable_chip_test.dart | nicht gemergt |
| `copilot/analyze-and-refactor-code` | #41 | cafcb70f | 2026-05-17 | C | Merge-Konflikt in 1 Datei(en): lib/core/writing_target_parser.dart | nicht gemergt |
| `copilot/check-current-status` | #37 | 05776f98 | 2026-05-17 | C | Merge-Konflikt in 2 Datei(en): lib/app/app_shell.dart;lib/app/app_state.dart | nicht gemergt |
| `copilot/create-lumo-lernen-app` | #1 | 2c7b6c14 | 2026-05-17 | C | Merge-Konflikt in 7 Datei(en): .github/workflows/android-debug-apk.yml;.github/workflows/copilot-setup-steps.yml;.github/workflows/release-apk.yml;.gitignore;analysis_options.yaml | nicht gemergt |
| `copilot/finalize-lumo-jump-adventure` | #44 | e432e1d7 | 2026-05-17 | C | Merge-Konflikt in 2 Datei(en): lib/app/app_state.dart;lib/features/games/games_content.dart | nicht gemergt |
| `copilot/fix-lumo-jump-game` | #45 | d461b15e | 2026-05-17 | C | Merge-Konflikt in 2 Datei(en): lib/app/app_theme.dart;lib/features/games/games_content.dart | nicht gemergt |
| `copilot/hol-dir-den-neuesten-stand-von-lumo` | – | fae80ee5 | 2026-05-28 | C | Merge-Konflikt in 2 Datei(en): lib/core/task_quality_guard.dart;lib/domain/quiz/quiz_question_bank.dart | nicht gemergt |
| `copilot/optimiere-spiel-performance-und-code-struktur` | #42 | ddddf577 | 2026-05-17 | C | Merge-Konflikt in 2 Datei(en): lib/features/games/games_content.dart;lib/features/games/mini_games/stars_path_game.dart | nicht gemergt |
| `copilot/optimize-game-code-performance` | #43 | b863dc41 | 2026-05-17 | C | Merge-Konflikt in 2 Datei(en): lib/features/games/games_content.dart;lib/features/games/mini_games/stars_path_game.dart | nicht gemergt |
| `copilot/review-first-172-170` | – | d1ca0878 | 2026-10-05 | C | Merge-Konflikt in 1 Datei(en): lib/core/game_progress_repository.dart | nicht gemergt |
| `copilot/stabilization-pr-39` | #40 | 014c2f43 | 2026-05-17 | C | Merge-Konflikt in 1 Datei(en): lib/features/games/games_content.dart | nicht gemergt |
| `copilot/transfer-codex-clause-4-6` | #48 | d7b363b9 | 2026-05-18 | C | Merge-Konflikt in 9 Datei(en): .github/workflows/android-debug-apk.yml;lib/app/app_shell.dart;lib/core/lumo_voice.dart;lib/features/agent/lumo_agent_content.dart;lib/features/games/flame/lumo_jump_game.dart | nicht gemergt |
| `copilot/ullmann27-lumo-lernen` | – | 443554f0 | 2026-10-07 | C | Merge-Konflikt in 1 Datei(en): lib/features/games/lumo_cards/lumo_cards_screen.dart | nicht gemergt |
| `delivery/lumo-2031-workshop-test-apk-20261116` | #522 | eb39b6d2 | 2026-11-16 | C | Merge-Konflikt in 4 Datei(en): .github/probes/lumo_nextgen_2031_runtime_cases.json;config/godot-source.json;lib/domain/tutoring/native_learning_activity.dart;scripts/verify_legacy_release_pin.py | nicht gemergt |
| `delivery/lumo-2032-complete-source-to-apk-20261116` | #518 | c5dfcec0 | 2026-11-16 | C | Merge-Konflikt in 3 Datei(en): .github/probes/lumo_nextgen_2031_runtime_cases.json;lib/features/games/memory/lumo_memory_game.dart;test/games/memory_native_entry_test.dart | nicht gemergt |
| `delivery/lumo-2034-gesamt-20261116` | – | e6bc2117 | 2026-11-16 | C | Merge-Konflikt in 4 Datei(en): .github/workflows/lumo-einfach-apk.yml;config/godot-source.json;pubspec.yaml;scripts/verify_legacy_release_pin.py | nicht gemergt |
| `delivery/lumo-2035-complete-20261116` | – | e6bc2117 | 2026-11-16 | C | Merge-Konflikt in 4 Datei(en): .github/workflows/lumo-einfach-apk.yml;config/godot-source.json;pubspec.yaml;scripts/verify_legacy_release_pin.py | nicht gemergt |
| `design/lumo-cards-build-connect-four-2026-10-10` | #247 | 790ad36f | 2026-10-10 | C | veraltet: Stand 2026-10-10, 1738 Commits hinter Integrationslinie; ändert docs/design/CLAUDE_SONNET_55_UMSETZUNG_CARDS_BUILD_4GEWINNT.md;docs/design/lumo-4-gewinnt-ui-konzept | nicht gemergt (veraltet, ungeprüft) |
| `design/lumo-nextgen-visual-brief-20261020` | #391 | c597105a | 2026-10-20 | C | Merge-Konflikt in 2 Datei(en): docs/design/lumo-nextgen-2026-10-20/CONTINUE.md;docs/design/lumo-nextgen-2026-10-20/STATUS.md | nicht gemergt |
| `diagnostic/lumo-c4-preferences-51ec-20261114` | – | cd03e1e2 | 2026-11-14 | C | Merge-Konflikt in 21 Datei(en): .github/probes/modernization_android_tour.py;.github/workflows/lumo-astra-script-recovery.yml;.github/workflows/lumo-connect-four-2020.yml;.github/workflows/lumo-learning-curriculum-audit. | nicht gemergt |
| `diagnostic/lumo-c4-return-51ec-20261114` | – | 2322632c | 2026-11-14 | C | Merge-Konflikt in 21 Datei(en): .github/probes/modernization_android_tour.py;.github/workflows/lumo-astra-script-recovery.yml;.github/workflows/lumo-connect-four-2020.yml;.github/workflows/lumo-learning-curriculum-audit. | nicht gemergt |
| `diagnostic/lumo-c4-return-74a-20261114` | – | a0c35c04 | 2026-11-14 | C | Merge-Konflikt in 18 Datei(en): .github/workflows/lumo-astra-script-recovery.yml;.github/workflows/lumo-connect-four-2020.yml;.github/workflows/lumo-learning-curriculum-audit.yml;.github/workflows/lumo-unified-integratio | nicht gemergt |
| `diagnostic/lumo-kart-scroll-6f42-20261114` | – | 7ef691cb | 2026-11-14 | C | Merge-Konflikt in 21 Datei(en): .github/probes/modernization_android_tour.py;.github/workflows/lumo-astra-script-recovery.yml;.github/workflows/lumo-connect-four-2020.yml;.github/workflows/lumo-learning-curriculum-audit. | nicht gemergt |
| `docs/lumo-2031-delivery-status-20261116` | – | f9a42e38 | 2026-11-16 | C | Merge-Konflikt in 2 Datei(en): docs/nextgen/ACCEPTANCE_CASES_2031.md;docs/nextgen/ANDROID_DELIVERY_2031.md | nicht gemergt |
| `docs/lumo-living-intelligence-verification-20261029` | – | 2b45a284 | 2026-10-30 | C | Merge-Konflikt in 1 Datei(en): CONTINUE.md | nicht gemergt |
| `docs/lumo-nextgen-2032-delivery-draft-20261116` | – | 05e0b3a9 | 2026-11-16 | C | überschreibt aktuelle STATUS.md/CONTINUE.md mit veraltetem 2032-Lieferstand; konfliktfrei, 6 Datei(en): CONTINUE.md;STATUS.md;docs/nextgen/ANDROID_DELIVERY_2032.md;docs/nextgen/evidence/2032-build-activation-20261116/act | nicht gemergt (würde aktuelle Statusdoku zurücksetzen) |
| `docs/lumo-nextgen-host-source-coverage-20261116` | – | 2094aaa7 | 2026-11-16 | C | Merge-Konflikt in 1 Datei(en): tools/nextgen/build_coverage.py | nicht gemergt |
| `evidence/lumo-final-flutter-ec936873-20261114` | – | 1f58bb3c | 2026-11-14 | C | Merge-Konflikt in 2 Datei(en): CONTINUE.md;STATUS.md | nicht gemergt |
| `evidence/lumo-home-village-captures-20261114` | – | 34ea2eec | 2026-11-14 | C | ändert .github (Workflows/Agenten, u.a. APK/Publish/Patcher): .github/workflows/lumo-direct-village-flutter.yml;docs/evidence/home-village-original-pngs-20261114/README.md;docs/evide | nicht gemergt (CI/Release-Risiko, Einzelprüfung nötig) |
| `evidence/lumo-publisher-syntax-20261114` | – | 68cff445 | 2026-11-14 | C | ändert .github (Workflows/Agenten, u.a. APK/Publish/Patcher): .github/workflows/lumo-live-2020-publish.yml;docs/evidence/live-integration-20261114/publisher-apk-precheck-07cac722.jso | nicht gemergt (CI/Release-Risiko, Einzelprüfung nötig) |
| `evidence/lumo-root-ec-review-20261114` | – | 67de5874 | 2026-11-14 | C | Merge-Konflikt in 2 Datei(en): CONTINUE.md;STATUS.md | nicht gemergt |
| `evidence/lumo-union-preflight-f365-20261114` | – | 76abafc2 | 2026-11-14 | C | Merge-Konflikt in 9 Datei(en): .github/workflows/lumo-connect-four-2020.yml;CONTINUE.md;STATUS.md;config/godot-source.json;scripts/tests/test_candidate_2011_pin.py | nicht gemergt |
| `evidence/lumo-village-6b-diagnostic-originals-20261114` | – | 866f9bce | 2026-11-14 | C | ändert .github (Workflows/Agenten, u.a. APK/Publish/Patcher): .github/probes/lumo_6b_roundtrip_diagnostic.py;.github/workflows/lumo-village-return-6b-diagnostic.yml;docs/evidence/liv | nicht gemergt (CI/Release-Risiko, Einzelprüfung nötig) |
| `feat-chat-enforce-ai-policy` | – | a635c035 | 2026-05-04 | C | Merge-Konflikt in 1 Datei(en): lib/features/agent/lumo_agent_content.dart | nicht gemergt |
| `feat-core-add-ai-policy-guard` | – | 3d5dc083 | 2026-05-04 | C | veraltet: Stand 2026-05-04, 2696 Commits hinter Integrationslinie; ändert lib/core/lumo_ai_policy_guard.dart;test/lumo_ai_policy_guard_test.dart | nicht gemergt (veraltet, ungeprüft) |
| `feat-integrated-ai-tutor` | – | 197d3bf9 | 2026-05-04 | C | Merge-Konflikt in 3 Datei(en): lib/core/lumo_ai_proxy_client.dart;lib/features/learning/learning_content.dart;lib/features/learning/renderers/adaptive_task_renderer.dart | nicht gemergt |
| `feat-learn-enforce-ai-policy` | – | 74e0e2f6 | 2026-05-04 | C | Merge-Konflikt in 1 Datei(en): lib/features/learning/learning_content.dart | nicht gemergt |
| `feat-learning-rescue-feedback` | – | 4791a947 | 2026-05-04 | C | Merge-Konflikt in 2 Datei(en): lib/domain/learning/lumo_learning_feedback_engine.dart;test/lumo_learning_feedback_engine_test.dart | nicht gemergt |
| `feat-lumo-jump-adventure-prototype` | #39 | 787e1ccf | 2026-05-17 | C | veraltet: Stand 2026-05-17, 2631 Commits hinter Integrationslinie; ändert lib/features/games/mini_games/lumo_jump_adventure_game.dart | nicht gemergt (veraltet, ungeprüft) |
| `feat-modern-lumo-ui-components-20260503` | – | 26466640 | 2026-05-03 | C | Merge-Konflikt in 1 Datei(en): lib/features/shared/widgets/lumo_modern_card.dart | nicht gemergt |
| `feat-parents-ai-selector-ui` | – | 87aee875 | 2026-05-04 | C | Merge-Konflikt in 1 Datei(en): lib/features/parents/widgets/lumo_ai_policy_selector.dart | nicht gemergt |
| `feat-reading-problem-word-trainer` | – | 609d5a27 | 2026-05-04 | C | Merge-Konflikt in 1 Datei(en): lib/features/reading/reading_content.dart | nicht gemergt |
| `feat-release-candidate` | – | 111c57a7 | 2026-05-04 | C | ändert .github (Workflows/Agenten, u.a. APK/Publish/Patcher): .github/scripts/build_rc_patch.py | nicht gemergt (CI/Release-Risiko, Einzelprüfung nötig) |
| `feat/primary-word-bank-german-generator` | – | 0775656b | 2026-05-02 | C | Merge-Konflikt in 1 Datei(en): lib/core/school_exercise_generator.dart | nicht gemergt |
| `feature-session-variety-guard-20260502` | – | 6084a416 | 2026-05-02 | C | Merge-Konflikt in 2 Datei(en): lib/core/session_variety_guard.dart;test/session_variety_guard_test.dart | nicht gemergt |
| `feature/lumo-jungle-emerald-3600-20261115-a298` | – | e96e4b7b | 2026-11-15 | C | ändert .github (Workflows/Agenten, u.a. APK/Publish/Patcher): .github/probes/jungle_android_tour.py;.github/workflows/lumo-jungle-emerald-apk.yml | nicht gemergt (CI/Release-Risiko, Einzelprüfung nötig) |
| `feature/lumo-nextgen-learning-20261115` | – | 1641b7da | 2026-11-15 | C | Merge-Konflikt in 16 Datei(en): lib/core/lumo_story_summary_scoring.dart;lib/features/games/lumo_cards/widgets/lumo_learning_card_overlay.dart;lib/features/games/mini_games/mini_game_learning_screen.dart;lib/features/lea | nicht gemergt |
| `feature/lumo-nextgen-voice-20261115` | #515 | 9df3cef1 | 2026-11-15 | C | Merge-Konflikt in 3 Datei(en): lib/app/lumo_companion_host.dart;lib/core/lumo_conversation_controller.dart;test/lumo_context_conversation_test.dart | nicht gemergt |
| `fix-learning-ui-and-tutor` | – | 87de74a5 | 2026-05-04 | C | ändert .github (Workflows/Agenten, u.a. APK/Publish/Patcher): .github/learning_fix_trigger.txt;.github/workflows/apply_learning_fix.yml | nicht gemergt (CI/Release-Risiko, Einzelprüfung nötig) |
| `fix-red-main-word-bank-variety-20260503` | – | 0b23c7b1 | 2026-05-03 | C | Merge-Konflikt in 1 Datei(en): lib/core/primary_school_word_data.dart | nicht gemergt |
| `fix-v0.3.1-core-stabilization` | – | ada85107 | 2026-05-05 | C | Merge-Konflikt in 7 Datei(en): .github/workflows/android-debug-apk.yml;lib/app/app_shell.dart;lib/app/app_state.dart;lib/core/ai_task_cache.dart;lib/core/learning_profile_engine.dart | nicht gemergt |
| `fix/grade-learning-structure-2026-10-12` | #281 | 3101d302 | 2026-10-13 | C | Merge-Konflikt in 42 Datei(en): lib/core/german_task_templates.dart;lib/core/math_task_templates.dart;lib/core/progress_recommendation_service.dart;lib/core/school_exercise_generator.dart;lib/domain/learning/learning_dna | nicht gemergt |
| `fix/lumo-core-menu-presenter-20261116` | – | 2c91bc72 | 2026-11-16 | C | Merge-Konflikt in 3 Datei(en): lib/app/app_shell.dart;lib/features/learning/learning_content.dart;test/learning/core_conversation_route_test.dart | nicht gemergt |
| `fix/lumo-lab-route-scope-20261116` | – | b730a2b8 | 2026-11-16 | C | Merge-Konflikt in 1 Datei(en): test/learning/lab_conversation_return_test.dart | nicht gemergt |
| `fix/lumo-learning-conversation-scope-20261115` | – | bb2d5dc4 | 2026-11-16 | C | Merge-Konflikt in 2 Datei(en): lib/app/lumo_companion_host.dart;lib/features/learning/lab/learning_lab_screen.dart | nicht gemergt |
| `fix/lumo-memory-child-safe-start-20261116` | – | 71b9e54f | 2026-11-16 | C | Merge-Konflikt in 34 Datei(en): lib/core/lumo_context_engine.dart;lib/core/lumo_conversation_controller.dart;lib/core/lumo_voice.dart;lib/domain/tutoring/native_learning_activity.dart;lib/features/agent/lumo_agent_conten | nicht gemergt |
| `fix/lumo-source-public-download-20261116` | – | 79258ab7 | 2026-11-16 | C | Merge-Konflikt in 1 Datei(en): .github/workflows/lumo-nextgen-learning-apk.yml | nicht gemergt |
| `integration/lumo-2022-complete-20261115` | – | a12b5ae8 | 2026-11-15 | C | ändert .github (Workflows/Agenten, u.a. APK/Publish/Patcher): .github/workflows/lumo-2022-union-audit.yml | nicht gemergt (CI/Release-Risiko, Einzelprüfung nötig) |
| `integration/lumo-c4-connections-20261114` | #485 | fa5e8695 | 2026-11-14 | C | Merge-Konflikt in 32 Datei(en): .github/probes/lumo_connect_four_android_probe.py;.github/probes/lumo_memory_android_probe.py;.github/probes/lumo_quiz_android_probe.py;.github/probes/lumo_village_android_probe.py;.github | nicht gemergt |
| `integration/lumo-c4-publisher-20261114` | – | 72143d35 | 2026-11-14 | C | enthält scripts/publish_connect_four_delivery.py (erzeugt Git-Tags und GitHub-Releases); konfliktfrei, 14 Datei(en): docs/evidence/c4-publisher-source-20261114/README.md;docs/evidence/c4-publisher-source-20261114/complet | nicht gemergt (Release-Werkzeug, nur mit Heinz) |
| `integration/lumo-learning-dschungelherz-2032-20261116` | – | 653300d1 | 2026-11-16 | C | Merge-Konflikt in 1 Datei(en): tools/nextgen/build_coverage.py | nicht gemergt |
| `integration/lumo-learning-nextgen-20261115` | #511 | 71b9e54f | 2026-11-16 | C | Merge-Konflikt in 34 Datei(en): lib/core/lumo_context_engine.dart;lib/core/lumo_conversation_controller.dart;lib/core/lumo_voice.dart;lib/domain/tutoring/native_learning_activity.dart;lib/features/agent/lumo_agent_conten | nicht gemergt |
| `integration/lumo-magic-family-apk-20261114` | #495 | 34e079a2 | 2026-11-14 | C | Merge-Konflikt in 3 Datei(en): .github/workflows/lumo-connect-four-2020.yml;config/godot-source.json;scripts/verify_legacy_release_pin.py | nicht gemergt |
| `integration/lumo-next-authorities-lint-20261114` | – | ce50999f | 2026-11-14 | C | Merge-Konflikt in 24 Datei(en): .github/probes/lumo_memory_android_probe.py;.github/probes/lumo_quiz_android_probe.py;.github/probes/modernization_android_tour.py;CONTINUE.md;STATUS.md | nicht gemergt |
| `integration/lumo-nextgen-learning-20261115` | – | 8479f004 | 2026-11-16 | C | überschreibt aktuelle STATUS.md/CONTINUE.md mit veraltetem 2032-Lieferstand; konfliktfrei, 377 Datei(en): CONTINUE.md;STATUS.md;docs/nextgen/ANDROID_DELIVERY_2032.md;docs/nextgen/DELIVERY_2032_FINAL.json;docs/nextgen/evi | nicht gemergt (würde aktuelle Statusdoku zurücksetzen) |
| `integration/lumo-reviewed-delta-20261115-58e0` | – | 238b0aad | 2026-11-15 | C | Merge-Konflikt in 28 Datei(en): lib/core/lumo_context_engine.dart;lib/core/lumo_conversation_controller.dart;lib/core/lumo_voice.dart;lib/domain/tutoring/native_learning_activity.dart;lib/features/agent/lumo_agent_conten | nicht gemergt |
| `lumo-2014/cards-resume-20261110` | #454 | d555a44d | 2026-11-10 | C | Merge-Konflikt in 5 Datei(en): lib/app/app_state.dart;lib/core/reward_wallet_repository.dart;lib/features/games/lumo_cards/lumo_cards_screen.dart;lib/features/games/lumo_cards/lumo_cards_session.dart;lib/features/games/l | nicht gemergt |
| `lumo-2014/learning-tutor-20261110` | #452 | 98698f4f | 2026-11-10 | C | Merge-Konflikt in 7 Datei(en): lib/app/app_state.dart;lib/core/progress_repository.dart;lib/features/tutoring/guided_lesson_screen.dart;lib/features/tutoring/guided_math_illustration.dart;lib/features/tutoring/guided_ten | nicht gemergt |
| `lumo-2014/quiz-lock-final-20261110` | – | e3870b67 | 2026-11-10 | C | Merge-Konflikt in 1 Datei(en): lib/features/quiz/quiz_show_content.dart | nicht gemergt |
| `lumo-2014/quiz-lock-lifetime-20261110` | – | 0d583cea | 2026-11-10 | C | Merge-Konflikt in 1 Datei(en): test/quiz_category_lock_lifetime_test.dart | nicht gemergt |
| `ops/lumo-codex-checkpoint-protection-20261020` | #394 | b63e0e84 | 2026-10-20 | C | Merge-Konflikt in 3 Datei(en): AGENTS.md;lib/widgets/design/lumo_design_system.dart;test/curriculum_cross_grade_navigation_test.dart | nicht gemergt |
| `p5-ai-mode-settings` | – | 20fc2f20 | 2026-05-04 | C | Merge-Konflikt in 2 Datei(en): lib/core/app_settings.dart;test/app_settings_ai_mode_test.dart | nicht gemergt |
| `perplexity/lumo-cards-approved-design-2026-10-10` | – | c2261901 | 2026-10-10 | C | veraltet: Stand 2026-10-10, 1718 Commits hinter Integrationslinie; ändert lib/features/games/lumo_cards/widgets/approved_cards_board.dart | nicht gemergt (veraltet, ungeprüft) |
| `perplexity/lumo-nvidia-tutor-pilot-2026-10-15` | #310 | 0a9101cc | 2026-10-15 | C | ändert .github (Workflows/Agenten, u.a. APK/Publish/Patcher): .github/workflows/lumo-nvidia-pilot-node-tests.yml;docs/NVIDIA_NEMOTRON_3_ULTRA_PILOT_2026-10-15.md;lib/core/lumo_nvidia | nicht gemergt (CI/Release-Risiko, Einzelprüfung nötig) |
| `qa/lumo-2004-real-upgrade-20261031` | #426 | 45102463 | 2026-10-31 | C | ändert .github (Workflows/Agenten, u.a. APK/Publish/Patcher): .github/probes/lumo_2004_update_android_probe.py;.github/workflows/lumo-2004-actual-update-gate.yml | nicht gemergt (CI/Release-Risiko, Einzelprüfung nötig) |
| `qa/lumo-2020-legible-3d-entry-20261114` | – | d1242d58 | 2026-11-14 | C | ändert .github (Workflows/Agenten, u.a. APK/Publish/Patcher): .github/workflows/lumo-2020-legible-3d-entry-proof.yml | nicht gemergt (CI/Release-Risiko, Einzelprüfung nötig) |
| `qa/lumo-2020-visible-flutter-20261114` | – | df7615b4 | 2026-11-14 | C | ändert .github (Workflows/Agenten, u.a. APK/Publish/Patcher): .github/workflows/lumo-2020-visible-home-proof.yml | nicht gemergt (CI/Release-Risiko, Einzelprüfung nötig) |
| `qa/lumo-2031-active-syllable-observation-20261116` | – | db1180a7 | 2026-11-16 | C | Merge-Konflikt in 1 Datei(en): tools/android_qa/tests/test_nextgen_2031_runtime_cases.py | nicht gemergt |
| `qa/lumo-2031-immutable-replay-20261116` | – | 5b08d82e | 2026-11-16 | C | Merge-Konflikt in 1 Datei(en): config/nextgen-2031-replay.json | nicht gemergt |
| `qa/lumo-2031-lab-runtime-cases-20261116` | – | d05419d9 | 2026-11-16 | C | Merge-Konflikt in 6 Datei(en): .github/probes/lumo_nextgen_2031_runtime_cases_android_probe.py;.github/probes/lumo_nextgen_learning_android_probe.py;config/nextgen-2031-replay.json;docs/nextgen/ANDROID_DELIVERY_2031.md;t | nicht gemergt |
| `qa/lumo-2031-native-runtime-cases-20261116` | – | 09f483b3 | 2026-11-16 | C | Merge-Konflikt in 6 Datei(en): .github/probes/lumo_nextgen_2031_native_runtime_cases.py;.github/probes/lumo_nextgen_learning_android_probe.py;config/nextgen-2031-replay.json;docs/nextgen/ANDROID_DELIVERY_2031.md;tools/an | nicht gemergt |
| `qa/lumo-all-registers-grade-1-4-visual-20261031` | #427 | 744ee8ea | 2026-10-31 | C | ändert .github (Workflows/Agenten, u.a. APK/Publish/Patcher): .github/workflows/lumo-2004-full-register-visual-qa.yml;test/design/app_full_register_tour_capture_test.dart | nicht gemergt (CI/Release-Risiko, Einzelprüfung nötig) |
| `qa/lumo-android-runtime-1e22-20261114` | – | 4017a94d | 2026-11-14 | C | ändert .github (Workflows/Agenten, u.a. APK/Publish/Patcher): .github/workflows/lumo-unchanged-2020-apk-diagnostic.yml;docs/evidence/live-integration-20261114/unchanged-2020-diagnost | nicht gemergt (CI/Release-Risiko, Einzelprüfung nötig) |
| `qa/lumo-c4-small-result-actions-20261114-2708` | – | dc2e1b50 | 2026-11-14 | C | ändert .github (Workflows/Agenten, u.a. APK/Publish/Patcher): .github/workflows/lumo-c4-small-result-actions-qa.yml;scripts/run_connect_four_small_result_actions_qa.py;test/games/con | nicht gemergt (CI/Release-Risiko, Einzelprüfung nötig) |
| `qa/lumo-c4-small-result-actions-20261114-2708-r2` | – | c082ebe0 | 2026-11-14 | C | ändert .github (Workflows/Agenten, u.a. APK/Publish/Patcher): .github/workflows/lumo-c4-small-result-actions-qa.yml;scripts/run_connect_four_small_result_actions_qa.py;test/games/con | nicht gemergt (CI/Release-Risiko, Einzelprüfung nötig) |
| `qa/lumo-c4-small-result-actions-20261114-2708-r3` | – | 51d05896 | 2026-11-14 | C | ändert .github (Workflows/Agenten, u.a. APK/Publish/Patcher): .github/workflows/lumo-c4-small-result-actions-qa.yml;scripts/run_connect_four_small_result_actions_qa.py;test/games/con | nicht gemergt (CI/Release-Risiko, Einzelprüfung nötig) |
| `qa/lumo-console-start-7b16-20261114` | #486 | 0ac948f6 | 2026-11-14 | C | Merge-Konflikt in 2 Datei(en): .github/workflows/lumo-1966-cards-route-kart-qa.yml;.github/workflows/lumo-astra-script-recovery.yml | nicht gemergt |
| `qa/lumo-creative-51e-20261113` | #474 | d2c4589a | 2026-11-13 | C | Merge-Konflikt in 4 Datei(en): .github/probes/studio_creative_android_probe.py;CONTINUE.md;STATUS.md;scripts/tests/test_studio_creative_android_probe.py | nicht gemergt |
| `qa/lumo-mic-postgrant-reader-20261116` | – | 6cd862b8 | 2026-11-16 | C | Merge-Konflikt in 1 Datei(en): tools/android_qa/tests/test_nextgen_learning_android_probe.py | nicht gemergt |
| `qa/lumo-native-panel-readiness-20261116` | – | ac37416f | 2026-11-16 | C | Merge-Konflikt in 1 Datei(en): tools/android_qa/tests/test_nextgen_2031_native_runtime_cases.py | nicht gemergt |
| `qa/lumo-nextgen-2028-replay-implementation-20261116` | – | 9e7c3f77 | 2026-11-16 | C | Merge-Konflikt in 2 Datei(en): config/nextgen-2028-replay.json;tools/nextgen/prepare_current_learning_release.py | nicht gemergt |
| `qa/lumo-nextgen-2029-native-diagnostic-20261116` | – | e04e2943 | 2026-11-16 | C | ändert .github (Workflows/Agenten, u.a. APK/Publish/Patcher): .github/probes/lumo_nextgen_2029_native_diagnostic.py;.github/probes/run_lumo_nextgen_2029_native_diagnostic.sh;.github/ | nicht gemergt (CI/Release-Risiko, Einzelprüfung nötig) |
| `qa/lumo-nextgen-2031-android-20261116` | – | 1c848385 | 2026-11-16 | C | Merge-Konflikt in 1 Datei(en): docs/nextgen/ANDROID_DELIVERY_2031.md | nicht gemergt |
| `qa/lumo-nextgen-2032-runtime-cases-20261116` | – | ce8458e8 | 2026-11-16 | C | ändert .github (Workflows/Agenten, u.a. APK/Publish/Patcher): .github/probes/lumo_nextgen_2032_runtime_cases.json;.github/probes/lumo_nextgen_2032_runtime_cases_android_probe.py;.git | nicht gemergt (CI/Release-Risiko, Einzelprüfung nötig) |
| `qa/lumo-nextgen-native-reference-diagnostic-20261115` | – | e4b6f073 | 2026-11-15 | C | Merge-Konflikt in 4 Datei(en): .github/probes/lumo_nextgen_learning_android_probe.py;.github/probes/lumo_nextgen_reference_android_probe.py;tools/android_qa/tests/test_nextgen_learning_android_probe.py;tools/android_qa/t | nicht gemergt |
| `qa/lumo-nextgen-pattern-reader-20261116` | – | 5d5ba41b | 2026-11-16 | C | Merge-Konflikt in 2 Datei(en): .github/probes/lumo_nextgen_current_reference_android_probe.py;tools/android_qa/tests/test_nextgen_native_reader.py | nicht gemergt |
| `qa/lumo-original-replay-selftest-04-20261114` | – | 1f84f069 | 2026-11-14 | C | ändert .github (Workflows/Agenten, u.a. APK/Publish/Patcher): .github/workflows/lumo-original-replay-04.yml;.github/workflows/lumo-original-replay-selftest-04.yml;docs/evidence/origi | nicht gemergt (CI/Release-Risiko, Einzelprüfung nötig) |
| `qa/lumo-original-replay-selftest-6b-20261114` | – | 98a8919f | 2026-11-14 | C | ändert .github (Workflows/Agenten, u.a. APK/Publish/Patcher): .github/workflows/lumo-original-replay-6b.yml;.github/workflows/lumo-original-replay-selftest-6b.yml;docs/evidence/origi | nicht gemergt (CI/Release-Risiko, Einzelprüfung nötig) |
| `qa/lumo-original-replay-selftest-ec-20261114` | – | 58cb9ca3 | 2026-11-14 | C | Merge-Konflikt in 2 Datei(en): CONTINUE.md;STATUS.md | nicht gemergt |
| `qa/lumo-permission-reader-20261116` | – | 842285f1 | 2026-11-16 | C | Merge-Konflikt in 2 Datei(en): .github/probes/lumo_nextgen_learning_android_probe.py;tools/android_qa/tests/test_nextgen_learning_android_probe.py | nicht gemergt |
| `qa/lumo-prompt-label-contrast-20261114-2708` | – | 21e03686 | 2026-11-14 | C | ändert .github (Workflows/Agenten, u.a. APK/Publish/Patcher): .github/workflows/lumo-prompt-label-contrast-qa.yml | nicht gemergt (CI/Release-Risiko, Einzelprüfung nötig) |
| `qa/lumo-recording-start-20261116` | – | 5bcfc870 | 2026-11-16 | C | Merge-Konflikt in 2 Datei(en): .github/probes/lumo_nextgen_learning_android_probe.py;tools/android_qa/tests/test_nextgen_learning_android_probe.py | nicht gemergt |
| `qa/lumo-resize-capture-20261116` | – | d9eb3aa4 | 2026-11-16 | C | Merge-Konflikt in 2 Datei(en): .github/probes/lumo_nextgen_learning_android_probe.py;tools/android_qa/tests/test_nextgen_learning_android_probe.py | nicht gemergt |
| `qa/lumo-supplemental-academy-navigation-20261116` | – | 625729d7 | 2026-11-16 | C | Merge-Konflikt in 4 Datei(en): .github/probes/lumo_nextgen_2031_runtime_cases.json;.github/probes/lumo_nextgen_2031_runtime_cases_android_probe.py;docs/nextgen/ANDROID_DELIVERY_2031.md;tools/android_qa/tests/test_nextgen | nicht gemergt |
| `qa/lumo-supplemental-numeric-capture-20261116` | – | 8c0158ee | 2026-11-16 | C | Merge-Konflikt in 2 Datei(en): .github/probes/lumo_nextgen_2031_runtime_cases.json;docs/nextgen/ANDROID_DELIVERY_2031.md | nicht gemergt |
| `qa/lumo-village-return-6b-20261114` | – | 3cae9c40 | 2026-11-14 | C | ändert .github (Workflows/Agenten, u.a. APK/Publish/Patcher): .github/probes/lumo_6b_roundtrip_diagnostic.py;.github/probes/lumo_connect_four_android_probe.py;.github/workflows/lumo- | nicht gemergt (CI/Release-Risiko, Einzelprüfung nötig) |
| `recovery/lumo-c4-return-fixtures-20261114` | – | ad1fbec3 | 2026-11-14 | C | Merge-Konflikt in 21 Datei(en): .github/probes/modernization_android_tour.py;.github/workflows/lumo-astra-script-recovery.yml;.github/workflows/lumo-connect-four-2020.yml;.github/workflows/lumo-learning-curriculum-audit. | nicht gemergt |
| `recovery/lumo-public-bases-20261106` | – | 10bfcc42 | 2026-11-06 | C | ändert .github (Workflows/Agenten, u.a. APK/Publish/Patcher): .github/workflows/lumo-public-source-recovery.yml | nicht gemergt (CI/Release-Risiko, Einzelprüfung nötig) |
| `release/lumo-1993-direct-chrome-20261021` | – | c56188ad | 2026-10-21 | C | ändert .github (Workflows/Agenten, u.a. APK/Publish/Patcher): .github/workflows/lumo-1993-direct-test-release.yml | nicht gemergt (CI/Release-Risiko, Einzelprüfung nötig) |
| `release/lumo-2002-family-button-20261029` | #422 | 6fa94e6b | 2026-10-29 | C | ändert .github (Workflows/Agenten, u.a. APK/Publish/Patcher): .github/workflows/lumo-2002-family-button-release.yml | nicht gemergt (CI/Release-Risiko, Einzelprüfung nötig) |
| `release/lumo-2004-family-update-20261102` | #428 | 0aaba1af | 2026-11-02 | C | ändert .github (Workflows/Agenten, u.a. APK/Publish/Patcher): .github/workflows/lumo-2004-family-button-release.yml | nicht gemergt (CI/Release-Risiko, Einzelprüfung nötig) |
| `release/lumo-2020-arm64-one-apk-20261114` | – | 77f45f72 | 2026-11-14 | C | Merge-Konflikt in 10 Datei(en): .github/workflows/lumo-connect-four-2020.yml;config/godot-source.json;lib/features/learning/learning_content.dart;lib/features/lumo3d/lumo3d_launcher.dart;scripts/tests/test_candidate_2011 | nicht gemergt |
| `release/lumo-2020-wiring-apk-20261114` | – | 91e9d6db | 2026-11-14 | C | ändert .github (Workflows/Agenten, u.a. APK/Publish/Patcher): .github/workflows/lumo-2020-wiring-signed-apk.yml | nicht gemergt (CI/Release-Risiko, Einzelprüfung nötig) |
| `repair/lumo-405-real-adventure-visibility-20261023` | #406 | 445ea17c | 2026-10-23 | C | Merge-Konflikt in 1 Datei(en): test/home_subject_islands_premium_test.dart | nicht gemergt |
| `repair/lumo-c4-safe-entry-20261114` | #505 | 90401bf1 | 2026-11-14 | C | Merge-Konflikt in 5 Datei(en): lib/features/games/connect_four/lumo_connect_four_game.dart;lib/features/games/spielwelt/spielwelt_hub.dart;test/games/connect_four_native_route_test.dart;test/games/games_screen_flow_test. | nicht gemergt |
| `repair/lumo-learning-workshop-relevance-20261116` | #520 | fd8b90c9 | 2026-11-16 | C | Merge-Konflikt in 37 Datei(en): config/godot-source.json;lib/core/lumo_context_engine.dart;lib/core/lumo_conversation_controller.dart;lib/core/lumo_voice.dart;lib/domain/tutoring/native_learning_activity.dart | nicht gemergt |
| `repair/lumo-live-diagnostic-20261114` | – | f39e393a | 2026-11-14 | C | Merge-Konflikt in 2 Datei(en): scripts/tests/test_connect_four_delivery.py;scripts/verify_connect_four_delivery.py | nicht gemergt |
| `repair/lumo-live-drawing-20261114` | – | 886c7ff9 | 2026-11-14 | C | Merge-Konflikt in 1 Datei(en): test/learning_modules/deutsch_sach_module_progress_test.dart | nicht gemergt |
| `repair/lumo-live-village-android-20261114` | – | fb652a41 | 2026-11-14 | C | Merge-Konflikt in 4 Datei(en): .github/probes/lumo_village_android_probe.py;scripts/verify_connect_four_candidate.py;scripts/verify_connect_four_delivery.py;tools/android_qa/tests/test_village_android_evidence.py | nicht gemergt |
| `repair/lumo-live-village-host-20261114` | – | 445094a1 | 2026-11-14 | C | Merge-Konflikt in 7 Datei(en): .github/workflows/lumo-connect-four-2020.yml;lib/features/lumo3d/lumo3d_launcher.dart;scripts/tests/test_connect_four_pipeline.py;test/design/dorfwirtschaft_spielewelt_capture_test.dart;tes | nicht gemergt |
| `repair/lumo-living-workshop-polish-20261029` | #417 | 31f3b059 | 2026-10-29 | C | Merge-Konflikt in 11 Datei(en): .github/workflows/lumo-living-workshop-visual-qa.yml;lib/features/learning/adapters/legacy_lumo_task_adapter.dart;lib/features/learning/cross_grade_practice_screen.dart;lib/features/learni | nicht gemergt |
| `repair/lumo-producer-flutter-union-20261114` | – | 318dd189 | 2026-11-14 | C | Merge-Konflikt in 1 Datei(en): test/games/games_screen_flow_test.dart | nicht gemergt |
| `repair/lumo-single-apk-20261114` | #502 | eae427a8 | 2026-11-14 | C | Merge-Konflikt in 18 Datei(en): .github/probes/lumo_connect_four_android_probe.py;.github/probes/modernization_android_tour.py;.github/workflows/lumo-connect-four-2020.yml;.github/workflows/lumo-unified-integration-2026. | nicht gemergt |
| `sol/fix-answer-crystal-depth-20261021` | – | f27a50b5 | 2026-10-21 | C | Merge-Konflikt in 1 Datei(en): test/design/minus_crystal_depth_regression_test.dart | nicht gemergt |
| `sol/lumo-1932-download-2026-10-12` | – | cf753965 | 2026-10-12 | C | Merge-Konflikt in 1 Datei(en): scripts/tests/test_android_1930_navigation.py | nicht gemergt |
| `sol/lumo-1933-android-delivery-2026-10-12` | – | 694c31a6 | 2026-10-12 | C | Merge-Konflikt in 1 Datei(en): tools/package_android_test_delivery.py | nicht gemergt |
| `sol/lumo-1936-android-delivery-2026-10-12` | – | 10c8fab3 | 2026-10-12 | C | ändert .github (Workflows/Agenten, u.a. APK/Publish/Patcher): .github/workflows/lumo-education-1936.yml | nicht gemergt (CI/Release-Risiko, Einzelprüfung nötig) |
| `sol/lumo-1936-android-delivery-v2-2026-10-12` | – | a107558e | 2026-10-12 | C | ändert .github (Workflows/Agenten, u.a. APK/Publish/Patcher): .github/workflows/lumo-education-1936-v2.yml | nicht gemergt (CI/Release-Risiko, Einzelprüfung nötig) |
| `sol/lumo-1936-android-delivery-v3-2026-10-12` | – | c17a4de7 | 2026-10-12 | C | ändert .github (Workflows/Agenten, u.a. APK/Publish/Patcher): .github/workflows/lumo-education-1936-v3.yml | nicht gemergt (CI/Release-Risiko, Einzelprüfung nötig) |
| `sol/lumo-1936-runtime-screenshots-2026-10-12` | – | 03a616de | 2026-10-12 | C | ändert .github (Workflows/Agenten, u.a. APK/Publish/Patcher): .github/workflows/lumo-1936-screenshots.yml | nicht gemergt (CI/Release-Risiko, Einzelprüfung nötig) |
| `sol/lumo-1937-android-acceptance-2026-10-12` | – | 694d83f1 | 2026-10-12 | C | Merge-Konflikt in 1 Datei(en): .github/probes/kart_complete_android_probe.py | nicht gemergt |
| `sol/lumo-1939-local-qa-backup-2026-10-14` | – | 85e3b8b2 | 2026-10-14 | C | Merge-Konflikt in 1 Datei(en): test/story_setup_learning_path_grade_test.dart | nicht gemergt |
| `sol/lumo-app-audit-2026-10-13` | – | a1ed3034 | 2026-10-13 | C | Merge-Konflikt in 13 Datei(en): lib/domain/quiz/quiz_question_bank.dart;lib/domain/quiz/quiz_show.dart;lib/features/deutsch/lumo_deutsch_screen.dart;lib/features/games/games_content.dart;lib/features/home/home_content.da | nicht gemergt |
| `sol/lumo-direct-download-2026-10-11` | – | 7a2fe155 | 2026-10-11 | C | ändert .github (Workflows/Agenten, u.a. APK/Publish/Patcher): .github/workflows/lumo-direct-download.yml;.github/workflows/lumo-private-draft-download.yml;docs/education/2026-10-11-1 | nicht gemergt (CI/Release-Risiko, Einzelprüfung nötig) |
| `sol/lumo-learning-repair-20261026` | – | f9789dd6 | 2026-10-26 | C | Merge-Konflikt in 2 Datei(en): lib/core/task_hint_service.dart;test/cross_grade_second_chance_test.dart | nicht gemergt |
| `sol/lumo-learning-repair-check-2026-10-12` | – | 88b82b66 | 2026-10-12 | C | Merge-Konflikt in 11 Datei(en): lib/domain/quiz/quiz_question_bank.dart;lib/domain/quiz/quiz_show.dart;lib/features/deutsch/lumo_deutsch_screen.dart;lib/features/games/games_content.dart;lib/features/home/home_content.da | nicht gemergt |
| `sol/lumo-learning-repair-check2-2026-10-12` | – | bd8b6751 | 2026-10-12 | C | Merge-Konflikt in 11 Datei(en): lib/domain/quiz/quiz_question_bank.dart;lib/domain/quiz/quiz_show.dart;lib/features/deutsch/lumo_deutsch_screen.dart;lib/features/games/games_content.dart;lib/features/home/home_content.da | nicht gemergt |
| `sol/lumo-learning-repair-check3-2026-10-12` | – | 512999c0 | 2026-10-12 | C | Merge-Konflikt in 11 Datei(en): lib/domain/quiz/quiz_question_bank.dart;lib/domain/quiz/quiz_show.dart;lib/features/deutsch/lumo_deutsch_screen.dart;lib/features/games/games_content.dart;lib/features/home/home_content.da | nicht gemergt |
| `sol/lumo-meister-20-stars-2026-10-12` | #282 | b623c3cc | 2026-10-13 | C | Merge-Konflikt in 11 Datei(en): lib/domain/quiz/quiz_question_bank.dart;lib/domain/quiz/quiz_show.dart;lib/features/deutsch/lumo_deutsch_screen.dart;lib/features/games/games_content.dart;lib/features/home/home_content.da | nicht gemergt |
| `sol/lumo-meister-apk-2026-10-12` | – | d3b385fe | 2026-10-12 | C | Merge-Konflikt in 8 Datei(en): lib/domain/quiz/quiz_question_bank.dart;lib/domain/quiz/quiz_show.dart;lib/features/deutsch/lumo_deutsch_screen.dart;lib/features/quiz/quiz_show_content.dart;lib/features/story/lumo_story_l | nicht gemergt |
| `sol/lumo-release-repair-20261026` | – | 5ad37779 | 2026-10-26 | C | veraltet: Stand 2026-10-26, 552 Commits hinter Integrationslinie; ändert docs/RELEASE_REPAIR_HANDOFF_2026-10-26.md;scripts/LumoAabCertificateVerifier.java;scripts/build_unif | nicht gemergt (veraltet, ungeprüft) |
| `sol/lumo-update-repair-20261026` | – | 1a4e67dc | 2026-10-26 | C | Merge-Konflikt in 1 Datei(en): .github/workflows/lumo-1999-update-gate.yml | nicht gemergt |
| `sol/lumo-writing-repair-20261026` | – | 62e061d7 | 2026-10-26 | C | veraltet: Stand 2026-10-26, 552 Commits hinter Integrationslinie; ändert docs/INTEGRATION_AUDIT_HANDOFF_2026-10-26.md | nicht gemergt (veraltet, ungeprüft) |
| `speech-tools-20260503` | – | c840ed17 | 2026-05-03 | C | Merge-Konflikt in 2 Datei(en): lib/core/lumo_child_speech_normalizer.dart;test/lumo_child_speech_normalizer_test.dart | nicht gemergt |
| `support/lumo-c4-open-close-20261115` | #517 | 4df1b606 | 2026-11-15 | C | Merge-Konflikt in 32 Datei(en): lib/core/lumo_context_engine.dart;lib/core/lumo_conversation_controller.dart;lib/core/lumo_voice.dart;lib/domain/tutoring/native_learning_activity.dart;lib/features/agent/lumo_agent_conten | nicht gemergt |
| `task-word-bank-generator` | – | c6c0eede | 2026-05-02 | C | Merge-Konflikt in 1 Datei(en): lib/core/school_exercise_generator.dart | nicht gemergt |
| `test-recent-repository-20260503` | – | 95c13607 | 2026-05-03 | C | Merge-Konflikt in 1 Datei(en): test/recent_task_repository_test.dart | nicht gemergt |
| `ux/lumo-scroll-all-sections-20261103` | #429 | 02addd79 | 2026-11-03 | C | Merge-Konflikt in 2 Datei(en): lib/widgets/shell/left_navigation.dart;test/lumo_child_navigation_cluster_test.dart | nicht gemergt |
| `validation/lumo-native-bebf7bba-20261114` | – | 38e8b3e2 | 2026-11-14 | C | Merge-Konflikt in 18 Datei(en): .github/workflows/lumo-astra-script-recovery.yml;.github/workflows/lumo-connect-four-2020.yml;.github/workflows/lumo-learning-curriculum-audit.yml;.github/workflows/lumo-unified-integratio | nicht gemergt |
| `validation/root-recovery-1750-20261114` | – | 62c8753e | 2026-11-14 | C | Merge-Konflikt in 24 Datei(en): .github/probes/lumo_memory_android_probe.py;.github/probes/lumo_quiz_android_probe.py;.github/probes/modernization_android_tour.py;CONTINUE.md;STATUS.md | nicht gemergt |
| `voice-bubble-20260503` | – | 784ef016 | 2026-05-03 | C | veraltet: Stand 2026-05-03, 2726 Commits hinter Integrationslinie; ändert lib/features/shared/widgets/lumo_voice_bubble.dart;test/lumo_voice_bubble_test.dart | nicht gemergt (veraltet, ungeprüft) |
| `work/lumo-dream-ui-recovery-20261114` | #492 | de3b74c5 | 2026-11-14 | C | Merge-Konflikt in 3 Datei(en): lib/widgets/design/lumo_scene_atmosphere.dart;test/games/connect_four_navigation_test.dart;test/lumo_scene_atmosphere_test.dart | nicht gemergt |
| `work/lumo-learning-audit-20261114` | – | 9008d462 | 2026-11-14 | C | ändert .github (Workflows/Agenten, u.a. APK/Publish/Patcher): .github/workflows/lumo-learning-native-lab.yml;.github/workflows/lumo-learning-source-audit.yml | nicht gemergt (CI/Release-Risiko, Einzelprüfung nötig) |
| `work/lumo-spielwelt-studio-20261114` | – | 14162d32 | 2026-11-14 | C | Merge-Konflikt in 1 Datei(en): lib/features/games/spielwelt/spielwelt_hub.dart | nicht gemergt |
| `assets/lumo-pack-import` | – | 3b7cbca8 | 2026-05-24 | D | alle 1 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `astra/lumo-learning-quality-2026-10-11` | #263 | 4b7a063d | 2026-10-11 | D | alle 3 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `chatgpt/flame-round-regression-2026-10-06` | – | 825cd7dc | 2026-10-06 | D | alle 1 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `chatgpt/fold-native-check-2026-10-07` | – | 4d9e603d | 2026-10-07 | D | Tip ist Vorfahre von chatgpt/fold-apk-android-2026-10-07 | nicht gemergt (ersetzt) |
| `chatgpt/gemini-story-compatibility-2026-10-15` | – | 701bb260 | 2026-10-15 | D | Tip ist Vorfahre von claude/integration-stories-2026-10-16 | nicht gemergt (ersetzt) |
| `chatgpt/install-upgrade-2026-10-07` | #208 | 5fe85acf | 2026-10-07 | D | Tip ist Vorfahre von chatgpt/parent-games-polish-2026-10-07 | nicht gemergt (ersetzt) |
| `chatgpt/lumo-android-recheck-2019-20261113` | – | 21df16b1 | 2026-11-13 | D | Tip ist Vorfahre von chatgpt/lumo-android17-cli22-recheck-20261113 (+1 weitere) | nicht gemergt (ersetzt) |
| `chatgpt/lumo-asset-delivery-2026-10-04` | – | 3bc248a7 | 2026-10-04 | D | Tip ist Vorfahre von codex/lumo-unified-android-2026-10-03 | nicht gemergt (ersetzt) |
| `chatgpt/lumo-cards-heartbeat-20261113` | – | 651d4d96 | 2026-11-13 | D | Tip ist Vorfahre von chatgpt/lumo-creative-android-31883868-20261113 (+9 weitere) | nicht gemergt (ersetzt) |
| `chatgpt/lumo-complete-app-20261113` | #468 | 1f47a961 | 2026-11-13 | D | Tip ist Vorfahre von chatgpt/lumo-2020-android-qa-recovery-20261113 (+1 weitere) | nicht gemergt (ersetzt) |
| `chatgpt/lumo-complete-delivery-2026-10-07` | – | c274ef2a | 2026-10-07 | D | Tip ist Vorfahre von chatgpt/lumo-complete-games-2026-10-07 (+1 weitere) | nicht gemergt (ersetzt) |
| `chatgpt/lumo-games-3d-launch-20261103` | #431 | c6784bb7 | 2026-11-03 | D | alle 10 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `chatgpt/lumo-historical-1999-verifier-20261113` | – | a5e03117 | 2026-11-13 | D | Tip ist Vorfahre von chatgpt/lumo-creative-android-31883868-20261113 (+9 weitere) | nicht gemergt (ersetzt) |
| `chatgpt/lumo-kart-graphics-apk-20261113` | – | bc58a16f | 2026-11-13 | D | Tip ist Vorfahre von chatgpt/lumo-2019-release-candidate-20261113 (+2 weitere) | nicht gemergt (ersetzt) |
| `chatgpt/lumo-learning-curriculum-audit-20261114` | #484 | f536ecf8 | 2026-11-14 | D | Tip ist Vorfahre von chatgpt/lumo-playstore-agent-network-20261114 (+1 weitere) | nicht gemergt (ersetzt) |
| `chatgpt/lumo-learning-curriculum-cognitive-2026-10-06` | #204 | 17ab56f3 | 2026-10-06 | D | Tip ist Vorfahre von chatgpt/fix-akademie-practical-scroll-2026-10-06 | nicht gemergt (ersetzt) |
| `chatgpt/lumo-learning-glass-cards-2026-10-09` | #276,#230 | fa9f5557 | 2026-10-09 | D | Tip ist Vorfahre von chatgpt/lumo-cards-landscape-hud-2026-10-09 | nicht gemergt (ersetzt) |
| `chatgpt/lumo-marktstart-vorbereitung-2026-10-11` | #277,#260 | 7d33604e | 2026-10-11 | D | alle 6 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `chatgpt/lumo-nextgen-blender-flutter-apk-20261115` | #516 | f1accf60 | 2026-11-15 | D | Tip ist Vorfahre von repair/lumo-learning-workshop-relevance-20261116 | nicht gemergt (ersetzt) |
| `chatgpt/lumo-playstore-agent-network-20261114` | #487 | 330951be | 2026-11-14 | D | Tip ist Vorfahre von chatgpt/lumo-three-qa-workers-20261114 | nicht gemergt (ersetzt) |
| `chatgpt/lumo-sonnenhafen-godot-pin-2026-10-15` | #319 | 46304ecc | 2026-10-15 | D | Tip ist Vorfahre von chatgpt/lumo-sonnenhafen-unified-apk-2026-10-15 | nicht gemergt (ersetzt) |
| `chatgpt/lumo-studio-20261113` | #466 | 86445f53 | 2026-11-14 | D | Tip ist Vorfahre von chatgpt/lumo-nextgen-feature-20261114 (+2 weitere) | nicht gemergt (ersetzt) |
| `chatgpt/lumo-studio-31883868-evidence-20261113` | – | 908493ec | 2026-11-13 | D | Tip ist Vorfahre von chatgpt/lumo-nextgen-feature-20261114 (+7 weitere) | nicht gemergt (ersetzt) |
| `chatgpt/lumo-studio-runtime-integration-20261113` | – | 39ddc673 | 2026-11-14 | D | Tip ist Vorfahre von chatgpt/lumo-nextgen-feature-20261114 (+6 weitere) | nicht gemergt (ersetzt) |
| `chatgpt/lumo-visual-polish-2026-10-07` | – | 36969d8b | 2026-10-07 | D | Tip ist Vorfahre von chatgpt/lumo-complete-delivery-2026-10-07 (+2 weitere) | nicht gemergt (ersetzt) |
| `chatgpt/lumo-writing-stability-2026-10-10` | #274,#253 | b2882f46 | 2026-10-10 | D | alle 5 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `chatgpt/visual-gap-fold-2026-10-05` | – | ec916506 | 2026-10-05 | D | alle 1 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `checkpoint/lumo-c4-cleanup-diagnostic-6b-20261114` | – | a7de7409 | 2026-11-14 | D | Tip ist Vorfahre von qa/lumo-village-return-6b-20261114 | nicht gemergt (ersetzt) |
| `checkpoint/lumo-c4-flutter-repairs-20261114` | – | a1dc5972 | 2026-11-14 | D | Tip ist Vorfahre von audit/lumo-originals-9de-20261114 (+30 weitere) | nicht gemergt (ersetzt) |
| `checkpoint/lumo-c4-return-observer-04-20261114` | – | d04ac259 | 2026-11-14 | D | Tip ist Vorfahre von checkpoint/lumo-live-publisher-ec936873-20261114 (+5 weitere) | nicht gemergt (ersetzt) |
| `checkpoint/lumo-live-combined-aab-20261114` | – | f36579a3 | 2026-11-14 | D | alle 0 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `checkpoint/lumo-live-publisher-20261114` | – | bb5aa0e5 | 2026-11-14 | D | Tip ist Vorfahre von evidence/lumo-publisher-syntax-20261114 | nicht gemergt (ersetzt) |
| `checkpoint/lumo-native-budget-20261114` | – | 1a85b02d | 2026-11-14 | D | alle 1 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `checkpoint/lumo-original-replay-04-20261114` | – | ee08fd14 | 2026-11-14 | D | Tip ist Vorfahre von qa/lumo-original-replay-selftest-04-20261114 | nicht gemergt (ersetzt) |
| `checkpoint/lumo-original-replay-6b-20261114` | – | 3049c835 | 2026-11-14 | D | Tip ist Vorfahre von qa/lumo-original-replay-selftest-6b-20261114 | nicht gemergt (ersetzt) |
| `checkpoint/lumo-original-replay-ec-20261114` | – | 99faf8de | 2026-11-14 | D | Tip ist Vorfahre von qa/lumo-original-replay-selftest-ec-20261114 | nicht gemergt (ersetzt) |
| `checkpoint/lumo-unchanged-2020-diagnostic-union-20261114` | – | 2590ff27 | 2026-11-14 | D | Tip ist Vorfahre von qa/lumo-android-runtime-1e22-20261114 | nicht gemergt (ersetzt) |
| `checkpoint/lumo-village-return-diagnostic-20261114` | – | 8166e50e | 2026-11-14 | D | Tip ist Vorfahre von checkpoint/lumo-c4-cleanup-diagnostic-6b-20261114 (+2 weitere) | nicht gemergt (ersetzt) |
| `claude/asset-ai-briefing` | – | ac16cf4d | 2026-05-24 | D | alle 1 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `claude/chatgpt-megaprompt` | – | 7bcf3f66 | 2026-05-24 | D | alle 1 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `claude/design-lernen` | #186 | 4f05c578 | 2026-10-05 | D | Tip ist Vorfahre von chatgpt/fold-reference-recovery-2026-10-05 | nicht gemergt (ersetzt) |
| `claude/design-polish-subject-tiles` | – | cb6cc00c | 2026-05-21 | D | alle 1 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `claude/design-targets-heinz` | – | 62bf2225 | 2026-10-04 | D | alle 3 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `claude/feat-lumo-cards-avatar-picker` | – | 2131800f | 2026-05-22 | D | alle 1 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `claude/feat-lumo-cards-avatars` | – | c6ccc014 | 2026-05-22 | D | alle 1 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `claude/feat-lumo-cards-from-sheet` | – | 50213e22 | 2026-05-22 | D | alle 1 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `claude/feat-lumo-cards-layout-polish` | – | 5b1214e3 | 2026-05-22 | D | alle 1 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `claude/feat-lumo-cards-layout-spec` | – | 48523c30 | 2026-05-22 | D | alle 1 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `claude/feat-lumo-cards-mvp` | – | 9d8c4f66 | 2026-05-21 | D | alle 1 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `claude/feat-lumo-cards-solo-bot` | – | 00ef7a1f | 2026-05-22 | D | alle 1 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `claude/feat-lumo-cards-specials` | – | bfef009e | 2026-05-22 | D | alle 1 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `claude/feat-lumo-cards-uno-style` | – | 50785c63 | 2026-05-22 | D | alle 1 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `claude/fix-farben-wuerfel-kaputt` | – | 0d7ecd1b | 2026-05-21 | D | alle 1 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `claude/fix-games` | – | 51e27cc6 | 2026-10-04 | D | alle 2 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `claude/fix-learning-modules` | – | 16276490 | 2026-10-04 | D | alle 7 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `claude/fix-lumo-cards-crash-overflow` | – | ca9e1ce8 | 2026-05-22 | D | alle 1 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `claude/fix-lumo-cards-layout` | – | 94b1b3f6 | 2026-05-21 | D | alle 1 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `claude/fix-lumo-cards-still-crashes` | – | 59630afc | 2026-05-22 | D | alle 1 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `claude/fix-tutorial-jumps-writing` | – | 490d2cef | 2026-05-21 | D | alle 1 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `claude/fix-update-detection-profile-reset` | – | 8b424a11 | 2026-05-21 | D | alle 1 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `claude/fix-wordcoach-crash-tutorial` | – | ddfa233c | 2026-05-21 | D | alle 1 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `claude/i18n-foundation` | – | f8493647 | 2026-05-24 | D | alle 1 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `claude/in-app-update-keystore` | – | 767c9609 | 2026-05-21 | D | alle 1 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `claude/lumo-cards-4-players` | – | f55e2705 | 2026-05-23 | D | alle 1 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `claude/lumo-cards-animations` | – | 30ca42d4 | 2026-05-23 | D | alle 1 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `claude/lumo-cards-big-refactor` | – | 29b3e2bc | 2026-05-22 | D | alle 1 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `claude/lumo-cards-dependents-fix` | – | e189b8a7 | 2026-05-22 | D | alle 1 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `claude/lumo-cards-hand-crash-fix` | – | 8b0dac7d | 2026-05-22 | D | alle 1 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `claude/lumo-cards-hud-polish` | – | 3027851b | 2026-05-22 | D | alle 1 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `claude/lumo-cards-more-anims` | – | b5c48926 | 2026-05-23 | D | alle 1 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `claude/lumo-cards-multiplayer-rules` | – | 644e9e54 | 2026-05-23 | D | alle 1 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `claude/lumo-cards-new-cards` | – | 26f462b6 | 2026-05-22 | D | alle 1 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `claude/lumo-cards-smarter` | – | 0fdb571c | 2026-05-23 | D | alle 1 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `claude/lumo-living-world-visual-20261029` | #416 | f249fd78 | 2026-10-29 | D | Tip ist Vorfahre von repair/lumo-living-workshop-polish-20261029 | nicht gemergt (ersetzt) |
| `claude/lumo-nextgen-app-20261113` | – | 5fb7e6fd | 2026-11-13 | D | Tip ist Vorfahre von chatgpt/lumo-2019-release-candidate-20261113 | nicht gemergt (ersetzt) |
| `claude/polish-2-tiere` | – | 6dd3a233 | 2026-05-21 | D | alle 1 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `claude/tier1-foundation` | – | a19322fe | 2026-05-23 | D | alle 1 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `claude/tier3-audio` | – | 3d4d6e32 | 2026-05-23 | D | alle 1 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `claude/tier4-3d-optics` | – | 660c896e | 2026-05-24 | D | alle 1 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `claude/tier6-card-polish` | – | 2f4c9161 | 2026-05-24 | D | alle 1 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `claude/writing-canvas-touch-fix` | – | 7a227a75 | 2026-05-23 | D | alle 1 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `codex/lumo-1985-spatial-reading-2026-10-19` | #377 | 427bd417 | 2026-10-19 | D | alle 5 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `codex/lumo-app-recovery-2026-10-09` | – | 2b60f28a | 2026-10-09 | D | Tip ist Vorfahre von codex/lumo-return-frame-recovery-2026-10-09 | nicht gemergt (ersetzt) |
| `codex/lumo-integrated-runtime-2026-10-08` | #216 | 2b60f28a | 2026-10-09 | D | Tip ist Vorfahre von codex/lumo-return-frame-recovery-2026-10-09 | nicht gemergt (ersetzt) |
| `computer/lumo-android-1929-runtime-repair-2026-10-11` | #264 | 7851da27 | 2026-10-11 | D | alle 5 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `delivery/lumo-2037-memory-werkstatt-20261117` | #526 | e2a8e9fe | 2026-11-17 | D | parallele Variante von #527 delivery/lumo-2037-memory-workshop-20261117 (gleiche Basis 2036, gleiches Ziel, 4 Min. später); #527 ist Vorfahre der Integrationslinie 7e71dd07. Merge-Konflikt in 6 Datei(en): .github/workflo | nicht gemergt (ersetzt durch #527) |
| `delivery/lumo-nextgen-2031-replay-20261116` | – | 7270fbb7 | 2026-11-16 | D | Tip ist Vorfahre von delivery/lumo-2031-workshop-test-apk-20261116 (+2 weitere) | nicht gemergt (ersetzt) |
| `feat-didactic-task-styles-20260503` | – | f509ad77 | 2026-05-03 | D | alle 1 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `feat-reading-active-sentence-view` | – | 3f234d43 | 2026-05-04 | D | alle 1 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `feat-reading-analyzer-integration` | – | 49567cd3 | 2026-05-04 | D | alle 1 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `feat-settings-ai-selector-visible` | – | 796fbd15 | 2026-05-04 | D | alle 1 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `feat/asset-registry-pr-a` | – | f254647e | 2026-05-24 | D | alle 1 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `feat/pr-b-companion-pose` | – | 3655a769 | 2026-05-24 | D | alle 1 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `feat/pr-c-lumo-sound-registry` | – | e570df8d | 2026-05-24 | D | alle 1 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `feat/pr-d-lottie` | – | 770192eb | 2026-05-24 | D | alle 1 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `feat/pr-e-svg-icons` | – | c04f9cdb | 2026-05-24 | D | alle 1 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `feat/pr-f-learning-questions` | – | e8c92ee2 | 2026-05-24 | D | alle 1 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `feat/pr-g-error-sfx` | – | 0d238ac0 | 2026-05-24 | D | alle 1 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `feat/pr-h1-star-burst` | – | f8918195 | 2026-05-25 | D | alle 1 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `feat/pr-h2-result-lottie` | – | 99687783 | 2026-05-25 | D | alle 1 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `feat/pr-h3-music` | – | af7484ed | 2026-05-25 | D | alle 1 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `feat/pr-i-audio-settings` | – | 2bbf5526 | 2026-05-25 | D | alle 1 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `feature-local-tutor-hints-20260502` | – | 7ceaa1f9 | 2026-05-02 | D | alle 1 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `feature-task-generator-20260502` | – | 67ecf236 | 2026-05-02 | D | alle 1 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `feature-wire-session-variety-20260502` | – | d60b6d66 | 2026-05-03 | D | alle 1 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `feature/lumo-nextgen-conversation-20261115-403a` | – | 3e39038d | 2026-11-15 | D | Tip ist Vorfahre von chatgpt/lumo-nextgen-blender-flutter-apk-20261115 (+5 weitere) | nicht gemergt (ersetzt) |
| `fix-actions-artifact-quota-20260503` | – | 93e3e567 | 2026-05-03 | D | alle 1 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `fix-recent-task-memory-20260502` | – | ee508298 | 2026-05-02 | D | alle 1 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `integration/lumo-2031-learning-workshop-repair-20261116` | #521 | 92cf6037 | 2026-11-16 | D | Tip ist Vorfahre von delivery/lumo-2031-workshop-test-apk-20261116 | nicht gemergt (ersetzt) |
| `integration/lumo-agent-execution-20261114` | #493 | 198dd3d1 | 2026-11-14 | D | Tip ist Vorfahre von checkpoint/lumo-198dd3-build-evidence-20261114 (+3 weitere) | nicht gemergt (ersetzt) |
| `integration/lumo-discovery-host-7136-20261114` | – | 5ad005bd | 2026-11-14 | D | Tip ist Vorfahre von integration/lumo-c4-connections-20261114 (+5 weitere) | nicht gemergt (ersetzt) |
| `integration/lumo-learning-generation-20261115-ea41` | #510 | 916c2f9c | 2026-11-15 | D | Tip ist Vorfahre von chatgpt/lumo-nextgen-blender-flutter-apk-20261115 (+5 weitere) | nicht gemergt (ersetzt) |
| `integration/lumo-live-connections-20261114` | #497 | ec936873 | 2026-11-14 | D | Tip ist Vorfahre von checkpoint/lumo-live-publisher-ec936873-20261114 (+4 weitere) | nicht gemergt (ersetzt) |
| `integration/lumo-next-candidate-1913-20261114` | – | 05d96d94 | 2026-11-14 | D | Tip ist Vorfahre von integration/lumo-c4-connections-20261114 (+1 weitere) | nicht gemergt (ersetzt) |
| `integration/lumo-next-hub-20261114` | – | 036e3360 | 2026-11-14 | D | Tip ist Vorfahre von integration/lumo-c4-connections-20261114 (+6 weitere) | nicht gemergt (ersetzt) |
| `integration/lumo-next-repair-1952-20261114` | – | 6ab8748c | 2026-11-14 | D | Tip ist Vorfahre von integration/lumo-c4-connections-20261114 | nicht gemergt (ersetzt) |
| `integration/lumo-next-table-authorities-20261114` | – | b3c2bd00 | 2026-11-14 | D | Tip ist Vorfahre von integration/lumo-c4-connections-20261114 (+2 weitere) | nicht gemergt (ersetzt) |
| `lumo-2014/cards-games-20261110` | #453 | 9d297100 | 2026-11-10 | D | Tip ist Vorfahre von lumo-2014/cards-resume-20261110 | nicht gemergt (ersetzt) |
| `qa/lumo-console-joystick-7b16-20261114` | #483 | 7e2ab20f | 2026-11-14 | D | Tip ist Vorfahre von qa/lumo-console-start-7b16-20261114 | nicht gemergt (ersetzt) |
| `qa/lumo-foreground-transition-20261116` | – | 7fc39247 | 2026-11-16 | D | alle 1 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `qa/lumo-kart-observer-20261114` | – | 1af7db2f | 2026-11-14 | D | Tip ist Vorfahre von checkpoint/lumo-kart-observer-evidence-20261114 | nicht gemergt (ersetzt) |
| `qa/lumo-nextgen-reference-android-20261115` | – | c600e1e0 | 2026-11-15 | D | Tip ist Vorfahre von qa/lumo-nextgen-native-reference-diagnostic-20261115 | nicht gemergt (ersetzt) |
| `repair/lumo-2020-exact-learning-20261114` | #500 | 64b0b9f9 | 2026-11-14 | D | Tip ist Vorfahre von release/lumo-2020-arm64-one-apk-20261114 | nicht gemergt (ersetzt) |
| `repair/lumo-2020-one-apk-20261114` | #498 | c06200cc | 2026-11-14 | D | Tip ist Vorfahre von release/lumo-2020-arm64-one-apk-20261114 (+2 weitere) | nicht gemergt (ersetzt) |
| `repair/lumo-2020-village-hook-20261114` | #499 | f86509f0 | 2026-11-14 | D | Tip ist Vorfahre von release/lumo-2020-arm64-one-apk-20261114 (+1 weitere) | nicht gemergt (ersetzt) |
| `repair/lumo-capture-state-20261114` | #501 | b5b7f6d9 | 2026-11-14 | D | Tip ist Vorfahre von evidence/lumo-home-village-captures-20261114 | nicht gemergt (ersetzt) |
| `repair/lumo-console-and-joystick-7b16-20261114` | – | 21f7fbe6 | 2026-11-14 | D | Tip ist Vorfahre von qa/lumo-console-joystick-7b16-20261114 (+1 weitere) | nicht gemergt (ersetzt) |
| `repair/lumo-exact-learning-20261114` | – | 26046435 | 2026-11-14 | D | Tip ist Vorfahre von audit/lumo-originals-9de-20261114 (+32 weitere) | nicht gemergt (ersetzt) |
| `repair/lumo-historical-diagnostic-fixture-20261114` | – | bb968e28 | 2026-11-14 | D | Tip ist Vorfahre von audit/lumo-originals-9de-20261114 (+29 weitere) | nicht gemergt (ersetzt) |
| `repair/lumo-native-3d-games-hub-entry-20261114` | #504 | 5259bfe0 | 2026-11-14 | D | Tip ist Vorfahre von repair/lumo-c4-safe-entry-20261114 | nicht gemergt (ersetzt) |
| `repair/lumo-nextgen-apk-qa-20261020` | #393 | 7e1bd535 | 2026-10-20 | D | Tip ist Vorfahre von ops/lumo-codex-checkpoint-protection-20261020 | nicht gemergt (ersetzt) |
| `repo-tests-20260503` | – | 675df97f | 2026-05-03 | D | alle 1 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `sol/lumo-1932-verified-bundle-2026-10-12` | – | 8843498d | 2026-10-12 | D | Tip ist Vorfahre von sol/lumo-1932-download-2026-10-12 | nicht gemergt (ersetzt) |
| `test-didactic-styles-20260503` | – | a123b96c | 2026-05-03 | D | alle 1 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `test-german-generator-20260503` | – | 8dd3c209 | 2026-05-03 | D | alle 1 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `test-local-tutor-engine-20260502` | – | 81eee35b | 2026-05-02 | D | alle 1 Commits patch-gleich in Integrationslinie (git cherry) | keine |
| `work/lumo-nextgen-voice-20261115-ea41` | – | 421a0c32 | 2026-11-15 | D | Tip ist Vorfahre von chatgpt/lumo-nextgen-blender-flutter-apk-20261115 (+6 weitere) | nicht gemergt (ersetzt) |
| `audit/lumo-p0-pose-android-diagnose-20261105` | #434 | 2e04b424 | 2026-11-05 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `chatgpt/3d-launch-lifecycle-2026-10-07` | #207 | b6a0afa4 | 2026-10-07 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `chatgpt/ci-final-apk-evidence-count-2026-10-15` | – | 49d8a8b5 | 2026-10-15 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `chatgpt/ci-start-hero-regression-2026-10-15` | – | ef95672c | 2026-10-15 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `chatgpt/denktest-qualitaet-2026-10-09` | – | b41cfc54 | 2026-10-09 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `chatgpt/fold-kart-controls-2026-10-07` | #211 | 48cb8261 | 2026-10-07 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `chatgpt/fold-resize-fix-2026-10-05` | #197 | 853c4989 | 2026-10-05 | A | Merge in Integrationslinie ändert keine Datei (git merge-tree: Baum identisch) | No-op-Merge (formal angeschlossen) |
| `chatgpt/gemini-safe-fixes-learning-2026-10-15` | – | b0939042 | 2026-10-15 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `chatgpt/kart-qa-real-caption-2026-10-15` | – | 1e7be430 | 2026-10-15 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `chatgpt/kart-video-quality-2026-10-07` | #212 | 99b2afc3 | 2026-10-07 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `chatgpt/learning-number-compare-responsive-2026-10-09` | #239 | bea22025 | 2026-10-09 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `chatgpt/learning-symbols-ui-2026-10-09` | #237 | f16884e7 | 2026-10-09 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `chatgpt/learning-tablet-answer-grid-2026-10-09` | #236 | f41c214a | 2026-10-09 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `chatgpt/learning-tree-cinematic-qa-2026-10-09` | #235 | 4b2f837a | 2026-10-09 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `chatgpt/lumo-1918-apk-artifact-2026-10-09` | #240 | ab21b229 | 2026-10-09 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `chatgpt/lumo-1925-apk-build-2026-10-10` | – | 9ace64f1 | 2026-10-10 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `chatgpt/lumo-1926-sulafat-apk-2026-10-10` | – | dcebfbc4 | 2026-10-10 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `chatgpt/lumo-1938-complete-integration-2026-10-12` | #280 | 5fe56eb1 | 2026-10-12 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `chatgpt/lumo-1940-combined-test-apk-2026-10-14` | – | 414380fe | 2026-10-14 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `chatgpt/lumo-1941-tutor-voice-hologlass-2026-10-14` | #297 | 7d356faf | 2026-10-14 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `chatgpt/lumo-1942-family-preview-updates-2026-10-14` | #298 | d39946ac | 2026-10-14 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `chatgpt/lumo-1943-grade-menu-content-audit-2026-10-14` | #299 | cbb25b27 | 2026-10-14 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `chatgpt/lumo-1944-mobile-learning-qa-2026-10-14` | #300 | 26b8dcae | 2026-10-14 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `chatgpt/lumo-1945-question-quality-repair-2026-10-14` | #301 | b10205f6 | 2026-10-14 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `chatgpt/lumo-1949-all-integrated-2026-10-16` | – | bb55cdbc | 2026-10-16 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `chatgpt/lumo-1954-ci-repair-2026-10-16` | – | 088ff7b6 | 2026-10-16 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `chatgpt/lumo-1954-ocr-runtime-repair-2026-10-17` | – | a9781d42 | 2026-10-17 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `chatgpt/lumo-1954-preserve-ui-validation-2026-10-16` | #326 | b3147156 | 2026-10-16 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `chatgpt/lumo-1954-tesseract-deu-eng-gate-2026-10-17` | – | f9879d85 | 2026-10-17 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `chatgpt/lumo-1956-sonnenhafen-lookouts-2026-10-16` | #328 | 416a7348 | 2026-10-16 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `chatgpt/lumo-1957-race-gate-pin-2026-10-16` | – | 75800710 | 2026-10-16 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `chatgpt/lumo-1958-visual-story-integration-2026-10-16` | – | 6c1abbae | 2026-10-16 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `chatgpt/lumo-1959-kart-garage-ocr-repair-2026-10-16` | #332 | 8f96c6c8 | 2026-10-16 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `chatgpt/lumo-1961-cross-grade-fold-visual-proof-2026-10-16` | #333 | 4113c72f | 2026-10-16 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `chatgpt/lumo-1962-profile-non-destructive-persistence-2026-10-16` | #335 | b2b70804 | 2026-10-16 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `chatgpt/lumo-1963-integrated-profile-fold-android-2026-10-16` | #336 | 91258810 | 2026-10-16 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `chatgpt/lumo-1964-abc-premium-design-2026-10-16` | #337 | 53f02c32 | 2026-10-16 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `chatgpt/lumo-1965-cards-reference-hub-2026-10-16` | #339 | 3d14140e | 2026-10-16 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `chatgpt/lumo-1966-cards-route-race-telemetry-2026-10-16` | #340 | 32cd14ad | 2026-10-16 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `chatgpt/lumo-1967-sonnenhafen-crane-integrated-2026-10-17` | #341 | 0fc59169 | 2026-10-17 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `chatgpt/lumo-1968-audio-event-channel-capture-2026-10-17` | #342 | 57d62816 | 2026-10-17 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `chatgpt/lumo-1969-godot-hoist-candidate-2026-10-17` | – | a3f51484 | 2026-10-17 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `chatgpt/lumo-1970-godot-grounding-candidate-2026-10-17` | – | 124eac9a | 2026-10-17 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `chatgpt/lumo-1970-profile-field-guard-integrate-2026-10-17` | – | 53b9d158 | 2026-10-17 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `chatgpt/lumo-1971-profile-guard-release-candidate-2026-10-17` | #356 | 2c5cfbd2 | 2026-10-17 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `chatgpt/lumo-1973-b3-green-apk-2026-10-17` | – | 1a2634de | 2026-10-17 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `chatgpt/lumo-1975-grounded-gate-apk-2026-10-17` | #360 | aebf360d | 2026-10-17 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `chatgpt/lumo-1976-darkride-crystal-android-2026-10-18` | #362 | 840708ac | 2026-10-18 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `chatgpt/lumo-1977-real-font-screenshot-qa-2026-10-18` | #366 | c7f72fc9 | 2026-10-18 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `chatgpt/lumo-1978-real-hud-ocr-recovery-2026-10-18` | #368 | 0e6373e3 | 2026-10-18 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `chatgpt/lumo-1978-visual-accessible-release-2026-10-18` | #367 | 4124bda9 | 2026-10-18 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `chatgpt/lumo-1982-meister-show-2026-10-18` | #371 | ef89137f | 2026-10-18 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `chatgpt/lumo-1983-quiz-studio-reference-2026-10-18` | #373 | 653d854d | 2026-10-18 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `chatgpt/lumo-1984-animated-scenes-android-2026-10-18` | #376 | f3277e57 | 2026-10-18 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `chatgpt/lumo-1984-atelier-voice-replay-2026-10-18` | #374 | 72cb00f5 | 2026-10-18 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `chatgpt/lumo-1986-integrated-reading-release-2026-10-19` | #379 | f4d3f8ea | 2026-10-19 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `chatgpt/lumo-1989-premium-learning-cards-2026-10-19` | #383 | d45827c5 | 2026-10-19 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `chatgpt/lumo-1990-integration-hardening-2026-10-19` | #385 | b0010963 | 2026-10-19 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `chatgpt/lumo-1990-ui-unified-polish-2026-10-19` | #384 | 04904f0a | 2026-10-19 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `chatgpt/lumo-1991-complete-android-2026-10-20` | #387 | 3ff5ba4d | 2026-10-20 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `chatgpt/lumo-1992-modern-worlds-link-20261020` | – | 0eb91e98 | 2026-10-20 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `chatgpt/lumo-1992-premium-navigation-magic-2026-10-20` | #389 | d2a01779 | 2026-10-20 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `chatgpt/lumo-1992-second-chance-learning-20261020` | #390 | cdb58c71 | 2026-10-20 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `chatgpt/lumo-2005-full-games-candidate-20261103` | #432 | 0ef9c273 | 2026-11-03 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `chatgpt/lumo-2016-host-integration-20261111` | #457 | 43f1d7c2 | 2026-11-11 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `chatgpt/lumo-2018-speech-logcat-recovery-20261113` | – | d32c0803 | 2026-11-13 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `chatgpt/lumo-2027-memory-stage-20261029` | #423 | 4f4ba187 | 2026-10-29 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `chatgpt/lumo-3d-learning-islands-2026-10-15` | – | e6a991c8 | 2026-10-15 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `chatgpt/lumo-aaa-kart-integration-2026-10-10` | #251 | 20b4dbe6 | 2026-10-10 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `chatgpt/lumo-agent-hologlass-1940-2026-10-14` | #294 | 64b2aeda | 2026-10-14 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `chatgpt/lumo-agent-squad-2026-10-04` | – | c4745de0 | 2026-10-04 | A | Merge in Integrationslinie ändert keine Datei (git merge-tree: Baum identisch) | No-op-Merge (formal angeschlossen) |
| `chatgpt/lumo-apk-1914-qa-2026-10-09` | – | a1025eeb | 2026-10-09 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `chatgpt/lumo-app-reference-ui-2026-10-06` | – | 450f7346 | 2026-10-06 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `chatgpt/lumo-astra-app-script-recovery-2026-10-18` | #361 | 8a830ded | 2026-10-18 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `chatgpt/lumo-b3-1973-android-candidate-2026-10-17` | #358 | 1a2634de | 2026-10-17 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `chatgpt/lumo-b4-1974-performance-candidate-2026-10-17` | #359 | 27bfa21b | 2026-10-17 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `chatgpt/lumo-change-review-2026-10-04` | – | 7c71b505 | 2026-10-04 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `chatgpt/lumo-character-apk-1919-2026-10-09` | #241 | d07b2b48 | 2026-10-09 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `chatgpt/lumo-ci-pin-repair-2026-10-17` | – | 2a39fc3a | 2026-10-17 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `chatgpt/lumo-cross-grade-scene-polish-2026-10-15` | #315 | d187d11d | 2026-10-15 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `chatgpt/lumo-crystal-depth-integration-20261021` | #401 | 9fae296a | 2026-10-21 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `chatgpt/lumo-dna-evidence-2026-10-13` | #290 | fe377884 | 2026-10-13 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `chatgpt/lumo-fair-cards-buildworld-release-gates-2026-10-19` | #381 | cb4ee545 | 2026-10-19 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `chatgpt/lumo-feedback-voice-navigation-1955-2026-10-16` | #327 | 3287a458 | 2026-10-16 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `chatgpt/lumo-first-frame-icons-2026-10-17` | – | fdc0b921 | 2026-10-17 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `chatgpt/lumo-flutter-render-readiness-2026-10-17` | – | 83b96330 | 2026-10-17 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `chatgpt/lumo-fold-contrast-3d-identity-2026-10-16` | – | 7e394043 | 2026-10-16 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `chatgpt/lumo-game-specs-2026-10-05` | – | 591aee19 | 2026-10-05 | A | Merge in Integrationslinie ändert keine Datei (git merge-tree: Baum identisch) | No-op-Merge (formal angeschlossen) |
| `chatgpt/lumo-insight-responsive-stats-2026-10-17` | – | fc58137b | 2026-10-17 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `chatgpt/lumo-integrated-apk-2026-10-06` | #202 | 35299467 | 2026-10-06 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `chatgpt/lumo-lernen-kart-unified-2026-10-15` | – | b5b501ce | 2026-10-15 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `chatgpt/lumo-living-village-host-20261113` | – | fe66edf9 | 2026-11-13 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `chatgpt/lumo-milestone-a-1972-integrated-2026-10-17` | #357 | 06c8e26b | 2026-10-17 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `chatgpt/lumo-milestone-a-integrated-1972-2026-10-17` | – | 06c8e26b | 2026-10-17 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `chatgpt/lumo-mobile-navigation-visual-2026-10-13` | #293 | b256c915 | 2026-10-13 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `chatgpt/lumo-nextgen-20261113` | #461 | 8eab2284 | 2026-11-13 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `chatgpt/lumo-onboarding-voice-1924-2026-10-10` | #252 | 4ae665ee | 2026-10-10 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `chatgpt/lumo-parent-grade-and-subject-icons-2026-10-15` | #313 | d5711f3b | 2026-10-15 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `chatgpt/lumo-pr291-ci-regressions-2026-10-13` | #292 | d5f9ae59 | 2026-10-13 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `chatgpt/lumo-pr295-grade-semantic-tests-2026-10-14` | #296 | c86535b9 | 2026-10-14 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `chatgpt/lumo-premium-quiz-stage-2026-10-15` | – | aafb57f6 | 2026-10-15 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `chatgpt/lumo-reading-android-reduced-motion-2026-10-19` | #378 | 285e3f56 | 2026-10-19 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `chatgpt/lumo-scene-art-staged-1984-2026-10-18` | #375 | 397676a9 | 2026-10-18 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `chatgpt/lumo-schreiben-repair-1951-2026-10-16` | – | 120765b8 | 2026-10-16 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `chatgpt/lumo-sol-integrated-1995-20261021` | #400 | 64ff88e7 | 2026-10-21 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `chatgpt/lumo-spielewelt-stage-20261112` | #459 | 47889f74 | 2026-11-12 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `chatgpt/lumo-stabilisierung-2026-10-17` | #343 | b649cf61 | 2026-10-17 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `chatgpt/lumo-stabilisierung-nativehash-fix-2026-10-17` | – | 981aa204 | 2026-10-17 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `chatgpt/lumo-stability-1954-provenance-cli-2026-10-17` | – | 0600d817 | 2026-10-17 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `chatgpt/lumo-stability-ndk-unknown-archive-2026-10-17` | – | 75477ad1 | 2026-10-17 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `chatgpt/lumo-story-entry-2026-10-13` | #291 | c06b849a | 2026-10-13 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `chatgpt/lumo-story-reader-visual-fix-2026-10-14` | #295 | f846c754 | 2026-10-14 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `chatgpt/lumo-story-save-audit-2026-10-13` | #288 | 086eb42a | 2026-10-13 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `chatgpt/lumo-sulafat-everywhere-2026-10-10` | #255 | 1dd6a3f7 | 2026-10-10 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `chatgpt/lumo-test-apk-2026-10-05` | – | 3429a68e | 2026-10-05 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `chatgpt/lumo-writing-no-score-child-flow-1952-2026-10-16` | #324 | e7f1d5bf | 2026-10-16 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `chatgpt/native-source-preflight-2026-10-15` | – | bc7dbd65 | 2026-10-15 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `chatgpt/onboarding-hologlass-2026-10-05` | – | d1b05361 | 2026-10-05 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `chatgpt/opus-1953-mentor-journal-followup-2026-10-16` | #325 | 11f3e51d | 2026-10-16 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `chatgpt/pr207-provenance-clean-2026-10-07` | – | 905f3b77 | 2026-10-07 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `chatgpt/repair-android16-qa-2026-10-07` | – | 9bcd223e | 2026-10-07 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `chatgpt/repair-opus-handoff-2026-10-07` | #213 | 92a45c11 | 2026-10-07 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `chatgpt/resume-claude-cross-grade-practice-2026-10-15` | #314 | 5aee1c20 | 2026-10-15 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `chatgpt/verify-pr285-flutter-2026-10-13` | #287 | d7440bea | 2026-10-13 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `checkpoint/lumo-base-2b586-20261114-2708` | – | 81289b39 | 2026-11-14 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `checkpoint/lumo-c4-scroll-2708-20261114` | – | 43d66732 | 2026-11-14 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `checkpoint/lumo-cloud-rescue-20261021-014435` | #395 | d53c71bf | 2026-10-21 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `checkpoint/lumo-cloud-rescue-20261021-065029-8430` | – | fdba4fdd | 2026-10-21 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `checkpoint/lumo-creative-observations-7b16-20261114` | – | 843321d0 | 2026-11-14 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `checkpoint/lumo-host-51e-evidence-20261113` | – | fb8b0f77 | 2026-11-13 | A | Merge in Integrationslinie ändert keine Datei (git merge-tree: Baum identisch) | No-op-Merge (formal angeschlossen) |
| `checkpoint/lumo-host-cup-selector-20261113` | – | 84865ce2 | 2026-11-13 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `checkpoint/lumo-host-followups-20261113-1810` | – | 51e92fb5 | 2026-11-13 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `checkpoint/lumo-image-prompt-privacy-20261114-2708` | – | 7c1d1bbf | 2026-11-14 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `checkpoint/lumo-jungle-resume-20261116-c652` | – | dc6f7f56 | 2026-11-16 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `checkpoint/lumo-next-quality-20261114-2708` | – | aab09275 | 2026-11-14 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `checkpoint/lumo-play-aab-20261114` | – | 86445246 | 2026-11-14 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `checkpoint/lumo-play-data-audit-20261114-2708` | – | 31ea02ad | 2026-11-14 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `checkpoint/lumo-public-2032-source-20261116` | – | 9b38360c | 2026-11-16 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `checkpoint/lumo-quality-ci-fixture-20261114` | – | a32b56ac | 2026-11-14 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `checkpoint/lumo-quality-integrated-20261114-2708` | – | c1fef2d5 | 2026-11-14 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `checkpoint/lumo-runtime-followup-7b16-20261114` | – | 19919d35 | 2026-11-14 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `checkpoint/lumo-studio-cards-86445-20261114` | – | 0159e001 | 2026-11-14 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `claude/aufgaben-abenteuer` | – | d7282f35 | 2026-10-05 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `claude/cleanup` | – | c4daad0d | 2026-10-04 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `claude/continue-previous-chat-KtY7p` | – | f9b0a80a | 2026-10-16 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `claude/copilot-setup-steps` | – | c091d5d4 | 2026-10-04 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `claude/design-assets-part2` | – | 14fdb48e | 2026-10-04 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `claude/design-icons` | – | 4fa332d5 | 2026-10-04 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `claude/lern-lesen-schreiben` | – | 8d2f7758 | 2026-10-05 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `claude/lumo-2027-adventure-20261029` | – | 5457b2ee | 2026-10-29 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `claude/lumo-2027-bauwelt-20261029` | – | 5457b2ee | 2026-10-29 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `claude/lumo-2027-cards-20261029` | – | 5457b2ee | 2026-10-29 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `claude/lumo-2027-exam-planner-20261029` | – | 5457b2ee | 2026-10-29 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `claude/lumo-2027-home-companion-20261029` | – | 5457b2ee | 2026-10-29 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `claude/lumo-2027-kart-entry-20261029` | – | 5457b2ee | 2026-10-29 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `claude/lumo-2027-memory-20261029` | – | 5457b2ee | 2026-10-29 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `claude/lumo-2027-spielwelt-20261029` | – | 5457b2ee | 2026-10-29 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `claude/lumo-2027-tutor-presence-20261029` | – | 5457b2ee | 2026-10-29 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `claude/lumo-gesamt` | – | 87a7e57c | 2026-10-07 | A | Merge in Integrationslinie ändert keine Datei (git merge-tree: Baum identisch) | No-op-Merge (formal angeschlossen) |
| `claude/lumo-lernen-kart-modernisierung-ild8i2` | – | b9ab8d4f | 2026-10-16 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `claude/mathe-lehrplan` | – | dd6492b4 | 2026-10-04 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `codex/find-current-app-status` | – | fade1707 | 2026-05-09 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `codex/hybrid-lumo-voice` | – | f66129f7 | 2026-05-18 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `codex/lumo-1977-premium-learning-2026-10-18` | #363 | 83b7add1 | 2026-10-18 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `codex/lumo-action-android-qa-2026-10-09` | – | 0a4f988e | 2026-10-09 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `codex/lumo-action-apk-2026-10-09` | – | aa651922 | 2026-10-09 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `codex/lumo-android-qa-followup-2026-10-08` | #218 | bd08f8c5 | 2026-10-08 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `codex/lumo-android-surface-qa-2026-10-08` | – | 4f7108f9 | 2026-10-08 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `codex/lumo-apk-1910-2026-10-09` | #225 | f38bb1ac | 2026-10-09 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `codex/lumo-claude-game-entry-2026-10-09` | – | bc631705 | 2026-10-09 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `codex/lumo-game-entry-polish-2026-10-09` | #226 | c9a82313 | 2026-10-09 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `codex/lumo-host-finish-numeric-2026-10-09` | #228 | fc33aa44 | 2026-10-09 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `codex/lumo-integrated-runtime-1904-2026-10-08` | – | 1be923a6 | 2026-10-08 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `codex/lumo-kart-1903-qa-2026-10-08` | – | fa2da691 | 2026-10-08 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `codex/lumo-kart-modal-scroll-2026-10-08` | – | 3e1d0eb3 | 2026-10-08 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `codex/lumo-learning-lab-2026-10-18` | #369 | cbc63079 | 2026-10-18 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `codex/lumo-next-2026-10-10` | #243 | 554c2b6a | 2026-10-10 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `codex/lumo-nextgen-navigation-20261023` | #405 | df5be7eb | 2026-10-23 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `codex/lumo-reference-app-2026-10-08` | – | c857aa92 | 2026-10-08 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `codex/lumo-reference-assets-2026-10-10` | #248 | 23540f5e | 2026-10-10 | A | Merge in Integrationslinie ändert keine Datei (git merge-tree: Baum identisch) | No-op-Merge (formal angeschlossen) |
| `codex/lumo-restart-school-test-2026-10-02` | – | 131bfc77 | 2026-10-02 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `codex/lumo-runtime-apk-2026-10-08` | #215 | 9f56cb8d | 2026-10-08 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `codex/lumo-school-readiness-followup-2026-10-02` | – | e4d6309b | 2026-10-02 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `codex/lumo-selective-app-qa-2026-10-08` | – | f6c4f335 | 2026-10-08 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `codex/lumo-source-guard-qa-2026-10-08` | – | 6b0171cd | 2026-10-08 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `codex/sprint-8-number-house` | – | 4b41fded | 2026-05-17 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `computer/lumo-aaa-integration-2026-10-10` | #250 | c747abc2 | 2026-10-10 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `computer/lumo-android-1930-verified-bundle-2026-10-11` | #266 | 15f5111d | 2026-10-11 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `computer/lumo-cards-connect-four-2026-10-10` | #249 | 8b308aee | 2026-10-10 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `computer/lumo-context-sulafat-2026-10-10` | – | 8408f377 | 2026-10-10 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `computer/lumo-education-excellence-2026-10-11` | #262 | e4756bbc | 2026-10-11 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `computer/lumo-kart-android-1928-2026-10-11` | #259 | bef1403e | 2026-10-11 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `computer/lumo-learning-adventures-2026-10-11` | #261 | 5f2f32f0 | 2026-10-11 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `computer/lumo-learning-companion-discovery-2026-10-11` | #265 | 9b8b7c86 | 2026-10-11 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `computer/lumo-rival-roster-2026-10-10` | #257 | d2d25c35 | 2026-10-10 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `computer/lumo-visual-foundation-2026-10-10` | #256 | 5d7a675b | 2026-10-10 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `copilot/175-lumo-ui-luna-arbeiten` | – | d539bbc8 | 2026-10-04 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `copilot/5979796457-update-integrationsaudit` | – | 008d86a1 | 2026-10-04 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `copilot/add-animated-lumo-fox` | – | 4756c56e | 2026-05-18 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `copilot/add-premium-voice-api` | – | f66129f7 | 2026-05-18 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `copilot/checkpoint-sichern-opus-5-5` | – | 3b9bb248 | 2026-10-05 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `copilot/codexlumo-holographic-kart-2026-10-03` | – | 86bbd20b | 2026-10-03 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `copilot/explore-codebase-implementation-plan` | – | 1edadaed | 2026-05-18 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `copilot/feat-engine-overhaul-timer-replacement` | – | 901289f3 | 2026-05-17 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `copilot/fix-android-debug-apk-build` | – | 1edadaed | 2026-05-18 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `copilot/fix-current-frame-index` | – | 1edadaed | 2026-05-18 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `copilot/fix-pr-316-auto-check` | #317 | 8c56edb3 | 2026-10-15 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `copilot/implement-hybrid-voice-patch` | – | f66129f7 | 2026-05-18 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `copilot/learning-sonnet-durable-spielefreischaltung` | – | d9bc664f | 2026-10-04 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `copilot/lumo-1938-integration-follow-up` | #285 | d7440bea | 2026-10-13 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `copilot/lumo-design-sprint` | – | 44aff5bb | 2026-10-04 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `copilot/quality-product-sprint-lumo-lernen` | – | 881ba365 | 2026-05-17 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `copilot/review-first-172-170-again` | – | d539bbc8 | 2026-10-04 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `copilot/stabilize-existing-feature` | – | 4b6e3e67 | 2026-05-17 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `copilot/ui-luna-design-sprint-runtime-screens` | – | b333a776 | 2026-10-04 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `copilot/update-asset-handling` | – | 66809d93 | 2026-10-04 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `delivery/lumo-2023-complete-update-20261115` | #509 | 6f4a8c47 | 2026-11-15 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `delivery/lumo-2033-workshop-from-published-2032-20261116` | #523 | d72cc9e2 | 2026-11-16 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `delivery/lumo-2034-kombination-20261116` | #524 | b16bee17 | 2026-11-16 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `delivery/lumo-2035-konkrete-3d-lernwelt-20261116` | – | 9ef51a0c | 2026-11-16 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `delivery/lumo-2036-gesicherte-3d-einstiege-20261116` | – | 4af64ec5 | 2026-11-16 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `delivery/lumo-2037-memory-workshop-20261117` | #527 | e823a5c9 | 2026-11-17 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `delivery/lumo-apk-einfach-20261116` | – | 106c92d4 | 2026-11-16 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `delivery/lumo-nextgen-2028-replay-20261116` | – | 0919f324 | 2026-11-16 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `design/lumo-full-visual-integration-apk-20261021` | #399 | 1d5633c1 | 2026-10-21 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `design/lumo-home-cinematic-20261020` | – | 4746aebd | 2026-10-20 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `design/lumo-learning-premium-tiles-20261020` | #392 | be656dae | 2026-10-20 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `design/lumo-nextgen-home-math-20261021` | – | a3f2d6ad | 2026-10-21 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `design/lumo-rechentricks-kindgerechte-trickwerkstatt-20261021` | #397 | 4e032aef | 2026-10-21 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `design/lumo-spielwelt-kart-quiz-20261022` | #404 | 5d269c36 | 2026-10-22 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `docs-ai-handoff-pack-20260503` | – | 6fd1ba00 | 2026-05-03 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `feat-modern-lumo-widgets-20260504` | – | 7ff8490b | 2026-05-03 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `feat-reading-unclear-feedback` | – | 0680e3c1 | 2026-05-04 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `feat/lumo-living-intelligence-2002-20261029` | #415 | ff791642 | 2026-10-29 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `feat/lumo-living-intelligence-20261029` | #414 | 5d6d7dcd | 2026-10-29 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `feat/lumo-personal-daily-learning-plan-20261028` | #413 | a79ff08c | 2026-10-28 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `feat/lumo-personal-tutor-place-value-20261028` | #410 | 8693ff80 | 2026-10-28 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `feat/lumo-proactive-tutor-offer-20261028` | #412 | e689ada0 | 2026-10-28 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `feat/lumo-tutor-brain-2001-20261028` | – | 9fdfc3f1 | 2026-10-28 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `fix/ci-nuclear-remove-native-plugins` | – | 0c0d8ba5 | 2026-05-25 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `fix/ci-rescue-l10n-yaml` | – | febf79ad | 2026-05-25 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `fix/lumo-2034-fachspezifische-3d-lernszenen-20261116` | #525 | e3175133 | 2026-11-16 | A | Merge in Integrationslinie ändert keine Datei (git merge-tree: Baum identisch) | No-op-Merge (formal angeschlossen) |
| `fix/lumo-banana-speech-quote-20261116` | – | 9aa6c53f | 2026-11-16 | A | Merge in Integrationslinie ändert keine Datei (git merge-tree: Baum identisch) | No-op-Merge (formal angeschlossen) |
| `fix/lumo-core-conversation-scope-20261116` | – | 51944015 | 2026-11-16 | A | Merge in Integrationslinie ändert keine Datei (git merge-tree: Baum identisch) | No-op-Merge (formal angeschlossen) |
| `fix/lumo-lab-requested-return-frame-20261116` | – | a4e73ccf | 2026-11-16 | A | Merge in Integrationslinie ändert keine Datei (git merge-tree: Baum identisch) | No-op-Merge (formal angeschlossen) |
| `integration/lumo-2000-sonnenhafen-tutor-20261028` | #411 | a6558161 | 2026-10-28 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `integration/lumo-2003-living-intelligence-original-fox-20261029` | #418 | 680b64d5 | 2026-10-29 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `integration/lumo-2004-full-learning-stunts-20261030` | #425 | 1f99665c | 2026-10-30 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `integration/lumo-2006-complete-app-20261103` | – | f889de99 | 2026-11-03 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `integration/lumo-2006-native-pin-review-20261105` | #437 | 9f5b47b3 | 2026-11-06 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `integration/lumo-blender-apk-20261115-f131` | – | 3584bc54 | 2026-11-15 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `integration/lumo-c4-fixture-repair-20261114` | – | 18628301 | 2026-11-14 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `integration/lumo-combined-art-2023-f131` | – | 0a18ca37 | 2026-11-15 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `integration/lumo-complete-apk-20261114-7a1` | – | 3d93745e | 2026-11-14 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `integration/lumo-connections-20261113` | #465 | 7b16f2f5 | 2026-11-14 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `integration/lumo-feature-connections-20261114` | – | 7136fd69 | 2026-11-14 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `integration/lumo-original-assets-readiness-20261117` | #528 | 7e71dd07 | 2026-11-17 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `integration/lumo-playready-20261117` | – | 4af64ec5 | 2026-11-16 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `integration/lumo-upstream057-review-20261114` | – | 6b3047b7 | 2026-11-14 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `lumo-2013/apk-candidate-20261110` | #450 | 76aa559c | 2026-11-10 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `lumo-2013/flutter-games-20261110` | #444 | cc951ffc | 2026-11-10 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `lumo-2013/flutter-games-play-20261110` | #449,#447 | 84f61052 | 2026-11-10 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `lumo-2013/guard-ci-20261110` | #442 | 0de7afc2 | 2026-11-10 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `lumo-2013/hub-routing-20261110` | #445 | 550b3fc6 | 2026-11-10 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `lumo-2013/integration-20261110` | #443 | 0853d3c3 | 2026-11-10 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `lumo-2013/lern-optik-20261110` | #446 | d723ea88 | 2026-11-10 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `lumo-2014/cards-loss-reward-20261111` | – | 74b29f7a | 2026-11-10 | A | Merge in Integrationslinie ändert keine Datei (git merge-tree: Baum identisch) | No-op-Merge (formal angeschlossen) |
| `lumo-2014/integration-20261110` | #451 | 696db258 | 2026-11-10 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `lumo-2014/learning-tip-review-20261110` | – | 87b12d1c | 2026-11-10 | A | Merge in Integrationslinie ändert keine Datei (git merge-tree: Baum identisch) | No-op-Merge (formal angeschlossen) |
| `lumo-next/design-flutter-games-20261110` | – | 9c700522 | 2026-11-10 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `lumo-next/integration-20261110` | #438 | 85afcb0e | 2026-11-10 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `lumo-next/release-pipeline-20261110` | – | af044d93 | 2026-11-10 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `lumo-next/visual-game-identity-2013-20261110` | #441 | 3e4d8c23 | 2026-11-10 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `p4help` | – | cd773b58 | 2026-05-03 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `p4readinganalyzer` | – | cd773b58 | 2026-05-03 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `p4readingui` | – | cd773b58 | 2026-05-03 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `p5-ai-policy-bridge` | – | 6a4d4e76 | 2026-05-04 | A | Merge in Integrationslinie ändert keine Datei (git merge-tree: Baum identisch) | No-op-Merge (formal angeschlossen) |
| `perplexity/lumo-1938-integration-2026-10-13-0942` | #284 | e68b6990 | 2026-10-13 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `perplexity/lumo-cross-grade-storage-hardening-2026-10-15` | #316 | 15bc02ed | 2026-10-15 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `perplexity/lumo-profile-schema-guard-2026-10-17` | #354 | 0bd7c6fb | 2026-10-17 | A | Merge in Integrationslinie ändert keine Datei (git merge-tree: Baum identisch) | No-op-Merge (formal angeschlossen) |
| `perplexity/lumo-profile-storage-hardening-2026-10-16` | #334 | 33b1ef5d | 2026-10-16 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `qa/lumo-agent-base-20261114` | – | 2b586530 | 2026-11-14 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `qa/lumo-android-runtime-7b16-20261114` | #480 | 61c94cfb | 2026-11-14 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `qa/lumo-android-runtime-7b16-followup-20261114` | #482 | e6a9407c | 2026-11-14 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `qa/lumo-creative-7b16-20261114` | #481 | f89b77bb | 2026-11-14 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `qa/lumo-current-native-stop-20261116` | – | c55df64c | 2026-11-16 | A | Merge in Integrationslinie ändert keine Datei (git merge-tree: Baum identisch) | No-op-Merge (formal angeschlossen) |
| `qa/lumo-nextgen-2028-android-20261116` | – | 0919f324 | 2026-11-16 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `qa/lumo-recording-offline-observation-20261116` | – | b5e747b3 | 2026-11-16 | A | Merge in Integrationslinie ändert keine Datei (git merge-tree: Baum identisch) | No-op-Merge (formal angeschlossen) |
| `reading-syllable-chip-20260503` | – | 3081220b | 2026-05-03 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `release/lumo-2003-family-button-20261029` | #421 | 5457b2ee | 2026-10-29 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `release/lumo-2003-living-world-20261029` | #419 | 18ced631 | 2026-10-29 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `release/lumo-nextgen-1999-integrated-20261024` | #407 | aa1c61e6 | 2026-10-24 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `repair/lumo-1999-native-kart-tour-20261024` | #408 | 26fced8f | 2026-10-25 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `repair/lumo-1999-update-learning-hub-20261026` | #409 | c6cfbaa4 | 2026-10-26 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `repair/lumo-2020-exhaustive-wiring-20261114` | #508 | c9813fde | 2026-11-15 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `repair/lumo-2022-delivery-20261115` | – | 3584bc54 | 2026-11-15 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `repair/lumo-android-runtime-7b16-20261114` | – | fd3076ea | 2026-11-14 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `repair/lumo-astra-rescue-home-qa-20261021` | #396 | d859380f | 2026-10-21 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `repair/lumo-feature-reward-frame-20261114` | – | 407e3503 | 2026-11-14 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `repair/lumo-garage-observed-scroll-20261114` | – | d7b5289f | 2026-11-14 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `repair/lumo-historical-visual-qa-20261022` | #403 | f510378e | 2026-10-22 | A | Merge in Integrationslinie ändert keine Datei (git merge-tree: Baum identisch) | No-op-Merge (formal angeschlossen) |
| `repair/lumo-live-safari-mode-20261114` | – | fe5df7f4 | 2026-11-14 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `repair/lumo-nextgen-math-recovery-20261021` | #398 | 7646d5a0 | 2026-10-21 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `repair/lumo-vs-all-subjects-access-20261030` | #424 | 11b9a08f | 2026-10-30 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `review/render-first-portable-build-20261022` | #402 | ed0491c8 | 2026-10-22 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `snapshot/lumo-apk-base-07cac722-20261114` | – | 07cac722 | 2026-11-14 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `sol/lumo-1934-android-delivery-2026-10-12` | – | 35d825e4 | 2026-10-12 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `sol/lumo-1935-fold-return-2026-10-12` | #272 | 43b4634c | 2026-10-12 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `sol/lumo-1936-unified-integration-2026-10-12` | #278 | 2dedb404 | 2026-10-12 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `sol/lumo-1937-content-kart-2026-10-12` | #279 | a71c1cde | 2026-10-12 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `sol/lumo-1939-runtime-followup-2026-10-14` | – | 1b5ebadb | 2026-10-14 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `sol/lumo-active-companion-2026-10-11` | #268 | d2050147 | 2026-10-12 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `sol/lumo-adaptive-local-help-2026-10-11` | #267 | 0dc3b1f3 | 2026-10-11 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `sol/lumo-curriculum-depth-1938-2026-10-12` | – | de7bcd0a | 2026-10-12 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `sol/lumo-games-fold-1934-2026-10-12` | #271 | ed17826e | 2026-10-12 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `sol/lumo-guided-language-nature-2026-10-12` | #269 | 65009c41 | 2026-10-12 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `sol/lumo-hologlass-quality-1939-2026-10-14` | – | ae219f69 | 2026-10-14 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `sol/lumo-parent-report-privacy-2026-10-12` | #270 | 91fc9e25 | 2026-10-12 | A | Tip ist Vorfahre von origin/main | keine (bereits enthalten) |
| `sol/lumo-runtime-crystals-kart-20261021` | – | 0eef84aa | 2026-10-21 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `support/lumo-topic-identity-20261114` | – | 4564ad40 | 2026-11-14 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
| `work/lumo-play-quality-20261114` | #491 | 057a4e8d | 2026-11-14 | A | Tip ist Vorfahre der Integrationslinie origin/i | keine (bereits enthalten) |
