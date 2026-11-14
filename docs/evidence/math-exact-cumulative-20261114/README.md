> **Execution update:** The identical final Dart contract has now run against both exact sources: original red, corrected green. See [EXECUTION.md](EXECUTION.md) and the unchanged raw logs under `execution/`. The source-only report below records the earlier pre-execution checkpoint.

# Exact cumulative Math-topic selection — source checkpoint

This checkpoint contains a focused source fix and a new shared Dart regression. **The new regression has not yet run.** The runtime became unavailable before its staging/execution completed. The original three-case diagnostic below did run against unchanged production Dart. No new Flutter, Android, or complete-candidate result is claimed.

## Bound source and actual finding

Reviewed source: Host `f4df466ed004879fc56284b024475a0ab0661259` (tree `350c713c20e58d17991d8bd09a160206e97dd119`). Its product source equals `faaf9d906bd72c2ffe9ab677c76355fe538cddfe`; the f4df step added evidence only. The later Host checkpoint `182e5e236a9a08fa4e8b33778338ac22ac05575a` was independently read back for MathTaskTemplates, ExerciseFactory, and LearningContent: all three original blobs still match.

The original real Dart diagnostic produced:

| Grade | Selected topic | Seed | Actual topic |
|---|---|---|---|
| 2 | Geld | 1 | Geld wechseln |
| 3 | Geometrie Formen | 1 | Umfang |
| 4 | Geometrie Formen | 1 | Flächeninhalt |

The diagnostic process returned 0 because it prints observations; it reported three selection failures. It is not a passing correctness test. Its exact probe and original tool output are retained separately. This was actual Dart execution, without Flutter, network calls, or a Python reproduction of the generator.

## Reachability from the product

This is a reachable source path for an older recorded weakness at a higher profile grade. `LumoCoachCard` loads the active student's attempt history. `LearningAnalysis.analyze` groups that history without filtering by current school grade, and its help message preserves the weakest record's unit. The help button passes that unit to `HomeContent._startPractice`. An explicit unit takes priority over the filter used only for implicit last-topic resumption. AppShell opens LearningContent, whose cumulative-topic check now uses `nextExact`. That postcondition correctly rejects the aliased output.

Open teacher assignments also pass their stored topic through the same Home callback. Their applicability filter checks class/target/archive; it does not substitute a current-grade topic. These are source-level route findings, not a newly executed UI test or a claim about a particular child's stored data.

The usual current-grade Academy list is narrower. In particular, the grade-2 tile titled “Geld” already maps to “Geld wechseln”. This checkpoint does not claim that this tile itself selects the older Geld topic.

Exact files, blobs, line references, and behavior are recorded in `manifest.json`.

## Minimal production change

The generator first finds exact templates in the allowed cumulative grade range. Current-grade priority and earlier-grade review then operate within that exact topic. If no exact topic exists, the existing current-grade/legacy-alias fallback remains. It never relabels an unrelated task as the requested topic.

Only `lib/core/math_task_templates.dart` changes in production: old blob `f5febd9c1e65516eef23b3d1ba40d670f62a2f89` → prepared blob `85fbad4a0b09753a7f22663690a9660f98382f39`. The full `nextExact` grade/subject/unit postguard, weakness weights, profile grade, curriculum, and task data remain unchanged.

## New executable regression, pending execution

The shared helper is `test/support/math_exact_topic_selection_contract.dart`, blob `becda7215230494989c04a71ee9f0b6a09c4fda2`; the normal Flutter test wrapper is `test/math_exact_topic_selection_test.dart`, blob `f82604a4239bd8982ac666b97aa478b65a8fa2e8`.

It imports actual production Dart. It covers every real cumulative Math unit in grades 1–4 over 32 seeds, plus the three reported counterexamples, 128 seeds preserving current/earlier-grade mixing inside Textaufgaben, and real legacy aliases. It checks actual template pattern/difficulty membership as well as unit identity, so changing only an output label cannot satisfy the template contract. Factory checks retain grade and subject under competing weak-skill inputs. Shape-tracing tasks retain their intentional empty choices.

Planned package-free execution:

```sh
dart test/support/math_exact_topic_selection_contract.dart
```

A nonempty failure list causes exit 1. The Flutter wrapper calls the same contract; no second implementation exists. **Neither new local red/green execution nor execution of this wrapper is claimed here.** The complete next candidate CI must execute the new test. No candidate ref was changed by this checkpoint.

## Bounded integration review and protected modules

The actual 803a→f4df product diff contains six lib files, with old/new identities in the manifest. Review found this Math selection integration gap. The independent child review found no additional demonstrated regression in the four decorative/drawing UI changes: the ink input surface stayed byte-identical, stroke snapshots support repainting on undo/clear, and only the noninteractive decorative layer stops in reduced-motion mode. New Flutter tests were read, not run locally.

Twenty explicitly checked trainer, journal, profile, progress, ink, and navigation files are byte-identical between those two sources. The entire assets tree is identical (`e344fab9b20ff85379d48984a778a0ab2a392b53`), including original fox assets. These are source-preservation checks, not a fresh Android/Flutter acceptance.

The separate 82% Math screenshot is consistent with the existing observed-skill mastery formula: one correct unaided attempt contributes 80 + 0.5 + 2, truncated to 82. The panel averages existing subject skill records; it is not a completed-curriculum fraction. No new arithmetic defect was established from that still image, and no metric change is included.
