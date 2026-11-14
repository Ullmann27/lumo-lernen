# Executed Math selection regression — 14 November 2026

This is the later execution evidence for the earlier source-only checkpoint in this directory. The earlier “pending execution” statement describes that historical checkpoint. **The final shared contract has now actually run, unchanged, against the original and corrected production sources.**

## Actual result

| Source | Math blob | Exit | Contract failures | Checked conditions | Duration |
|---|---|---:|---:|---:|---:|
| Original | `f5febd9c1e65516eef23b3d1ba40d670f62a2f89` | 1 | 386 | 29,565 | 0.750 s |
| Corrected | `85fbad4a0b09753a7f22663690a9660f98382f39` | 0 | 0 | 29,845 | 0.516 s |

Both commands used the exact contract blob `becda7215230494989c04a71ee9f0b6a09c4fda2`. It was not edited between runs. The different count of checked conditions comes from the original generator throwing 140 caught StateErrors: those calls reach the explicit failure condition instead of the three normal metadata/answer conditions. No test was removed or changed for the green run.

Actual execution: 2026-11-14 11:12:05–11:12:07 UTC, Dart SDK 3.12.2, linux_x64. The full commands, precise timestamps, SDK output, process exits, source identities before/after and raw-output hashes are in `execution/execution.json`.

The shared contract exercised **145 allowed cumulative grade/topic combinations**: 19 in grade 1, 30 in grade 2, 40 in grade 3, and 56 in grade 4. Each combination used 32 seeds, yielding 4,640 actual ExerciseFactory calls. The same contract also made 3,955 direct MathTaskTemplates calls, including the fixed counterexamples, same-topic grade mixing and genuine legacy aliases.

The original failures included the reported Geld/Geometrie cases and the same underlying alias issue for Textaufgaben in grades 3 and 4. The full original failure records are preserved. All are absent with the corrected source.

## Source and scope binding

Each isolated source directory contained the exact 13-file production dependency closure plus the shared test helper and an **unexecuted** Flutter wrapper. It was not presented as a full repository checkout. Only `lib/core/math_task_templates.dart` differs between the original and corrected directories; the other 12 production dependencies and both test files are identical.

All staged files were checked against their expected Git blob IDs before execution and checked again afterward. Every source and test byte remained unchanged. The actual files used by the corrected run were independently read back from Host `dfc3e0a1ea20f1491e4844ecfa913c598e1c6c5f`: all 15 expected file blobs match. That separate GitHub readback is retained in `execution/host-source-binding.json`.

Commands run in their respective isolated directories:

```sh
/workspace/scratch/e0abce7d2838/toolchain/flutter/bin/cache/dart-sdk/bin/dart test/support/math_exact_topic_selection_contract.dart
```

The process runner in `execution/run_contract.py` invokes the actual Dart source and saves its original bytes. It contains no Python implementation of the task generator. No package download or SDK installation was needed.

**This proves the bounded generator contract. No Flutter/widget test, Android build, emulator flow, native render, or complete-candidate acceptance is claimed by these runs.** The Flutter wrapper remains for the upcoming full candidate CI.

## Unchanged original files

- `execution/original.stdout.log`: all original 386 failures, no truncation.
- `execution/patched.stdout.log`: full corrected contract result.
- `execution/original.stderr.log` and `execution/patched.stderr.log`: both genuinely empty.
- `execution/dart-version.stdout.log` and `execution/dart-version.stderr.log`: actual SDK response.
- `execution/execution.json`: both executions and complete before/after source identities.
- `execution/run_contract.py`: exact runner that was executed.

No candidate or quality ref was changed by this evidence capture.
