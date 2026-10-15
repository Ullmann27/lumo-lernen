# Lumo production implementation plan

Goal: continue from verified Android 1931, preserve existing data, and deliver functioning milestones in the approved order.

Architecture: reuse LearningProfileLease, LearningProfileEngine, the existing local interaction bus and offline voice. Keep source 0dc3b1f30d7d885cc0c9914d1f557fad8655d762 recoverable. No public release, payments, paid speech calls, replacement app or parallel profile database.

Execution: native implementation under superpowers:executing-plans; meaningful regression tests before fixes. One whole-branch review after the next integrated candidate.

## Task 1: Profile-bound companion memory

Files: lib/core/lumo_companion_state.dart, lib/features/magic_hub/lumo_magic_hub_screen.dart, the six direct module callers; test/lumo_companion_profile_test.dart.

- [ ] Reproduce global-memory contamination through the actual Magic Hub UI.
- [ ] Derive companion summaries from the captured profile's existing canonical progress. Leave unowned lumo_companion_v1 bytes intact; do not guess their owner or recount accepted answers.
- [ ] Refresh the visible greeting on profile changes; discard late UI completions using the existing lease.
- [ ] Verify A/B/A, saved restart, existing legacy bytes, and late completion.
- [ ] Commit the verified change.

## Task 2: Calm, task-bound proactive help

Files: lib/core/lumo_companion_guide.dart, lib/app/lumo_companion_host.dart, lib/widgets/fox/lumo_free_companion.dart; their existing tests.

- [ ] Reproduce the blocked automatic help offer after two wrong attempts in an active task.
- [ ] Permit only an accepted in-place help offer, preserving 15-second quiet period, 90-second cooldown and 10-minute dismissal.
- [ ] Bind proposals to taskId and profileGeneration. Clear stale proposals on task/profile changes and lifecycle transitions. Never start microphone or paid service.
- [ ] Verify two wrong attempts, dismissal, wrong-task prevention, success, hidden route, assessment and profile change.
- [ ] Commit the verified change.

## Task 3: Integrate and deliver the next Android candidate

- [ ] Compare PR263 changes against candidate files; incorporate only unmerged applicable improvements without reverting 1930/1931 storage fixes.
- [ ] Run focused regression tests, then the full Flutter suite once, analysis and existing content checks.
- [ ] Save actual before/after Flutter captures; distinguish them from Android and physical hardware.
- [ ] Build one new version for product-code changes, preserve package/signature, verify exact-source emulator update and actual help controls.
- [ ] Deliver a complete single ZIP with APK, German instructions, source/version/checksums and honest report. Verify actual download/CRC. Use the already established unpublished owner-only draft path for durable delivery; publish nothing.

## Subsequent approved milestones

- [ ] Guided Deutsch pilot: syllables; guided Sachunterricht pilot: parts of a flowering plant. Explanation, guided practice, independent new task and saved completion.
- [ ] Official Austrian grades 1–4 topic inventory and sequential maths/Deutsch/Sachunterricht expansion. Automatic checks and pedagogical review remain distinct.
- [ ] Extend voluntary higher-grade discovery with preserved parent consent/revocation and separate progress.
- [ ] Improve shared visual components, starting Plus/Minus/forms/time/numbers; original Lumo and references preserved. Check small screens, tablet, Fold targets, orientation and large text.
- [ ] Prepare Play technical/privacy/license/store materials; publication/payment requires explicit user approval.
- [ ] Finish existing Cards and Connect Four with real Blender/Godot assets and measured mobile runtime; then improve Kart. Reuse Meshy inventory if accessible; no paid generation without authorization.

Review focus: late writes after profile switch; stale help for a new task; native storage rejection; incorrect reward/answer duplication; grade/consent changes during discovery.
