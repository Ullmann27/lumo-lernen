# Lumo Agent Lanes — model-specific coordination

This file is the shared contract for model-specific GitHub Copilot custom agents. Coordination issue: #170.

## Purpose

Use model strengths without parallel edits colliding. One active writer owns a path at a time. Other models review first. ChatGPT outside the repo coordinates freshness, claims, evidence and cross-agent handoffs.

## Active lanes

| Agent profile | Pinned model | Main responsibility | Writes? |
| --- | --- | --- | --- |
| Lumo UI Luna | GPT-5.6 Luna | Flutter UI, assets, navigation, responsive/Fold | Yes, narrow claims |
| Lumo Learning Sonnet | Claude Sonnet 5.5 | learning, durable unlock state, TTS/help, persistence/migration | Yes, narrow claims |
| Lumo Integration Sol | GPT-5.6 Sol | deep debugging, Flutter/Godot bridge and multi-lane integration | Review-first; yes only after claim |
| Lumo Visual QA | MAI-Code-1.1-Flash | target-vs-runtime image/screenshot QA | No |
| Lumo Release Astra | GPT-6 Astra | final long-horizon release/provenance audit | No tracked edits |
| Lumo Kart Opus (lumo-godot repo) | Claude Opus 5.5 | Godot tracks, arcade physics, camera and performance | Yes, Godot-only claims |

GitHub's model label/profile is the authority for a lane. Do not infer a session's model from prose alone.

## Claim protocol

Before a tracked write, post:
- AGENT PROFILE and model lane
- base branch + full SHA
- exact file paths
- reason/acceptance tests
- explicit excluded paths

Then re-read current head, open PRs, comments and active claims immediately before push. If another current claim overlaps, stop and coordinate instead of racing.

A claim ends only with a result comment containing resulting SHA, exact changed files, tests/counts, NOT EXECUTED checks and the next review owner.

## Handoffs

- Luna output -> Sonnet review-only for learning/state regressions when relevant; Visual QA for visual changes.
- Sonnet output -> Luna review-only for navigation/UI regressions.
- Kart Opus output -> Sol review-only for bridge/provenance/integration before Flutter pin update.
- Sol integration output -> owning lane retests its domain.
- Release Astra runs only after the same-candidate reports are available.

No lane silently fixes another lane's files during review. Review findings trigger a new explicit claim.

## Fault handling

For every substantive fault:
1. reproduce with commit/log/evidence and exclude an already existing fix;
2. obtain a real independent countercheck/alternative when available;
3. choose the smallest supported fix, exactly one writer edits, others retest.

Never fabricate a missing agent response. Do not create duplicate sessions to evade model/credit/quota limits.

## Product rule

Learning is the primary product. Durable learning progress unlocks Memory, then the project's own UNO-like Lumo Cards, later optionally selected small games, then Lumo Kart. Production thresholds/extra games/prices are not invented.

Inside Lumo Kart: **no learning questions, learning cups, answer timers or correct-answer turbo mechanics.** Books/library imagery may remain as scenery/gameplay decoration.

## Release gates

A green CI check is not visual/device/release acceptance. Final candidate needs matching Flutter/Godot SHAs, real test numbers/skips, runtime screenshot comparisons, Android learning/Memory/Cards/Kart flows, narrow/Fold layouts, offline restart and persisted progress. Missing tests are NOT EXECUTED.

APK bytes must be downloaded and inspected for package/version/build, signature/certificate, provenance, embedded Godot revision/PCK, asset content and SHA-256. Build 280 is not the redesigned final release.
