# Lumo 1999 release continuation implementation plan

> **For agentic workers:** Execute in this session using superpowers:executing-plans. Preserve every existing APK, branch and user record.

**Goal:** Close the missing in-place update gate for the already built candidate before releasing it, then modernize the rendered application incrementally.

**Architecture:** Reuse the current live Android UI helpers, native race session reader and strict race assertions. A separate CI job downloads immutable baseline/candidate artifacts; it never rebuilds or relabels an old APK as a new application version. Product changes follow only after the 1999 release gate.

**Tech Stack:** Flutter 3.44.9, Godot 4.6.3, Python, Android API 35 emulator, GitHub Actions.

**Spec:** User's “LUMO LERNEN – MASTER-FORTSETZUNGSAUFTRAG” dated 2026-10-24, supplied 2026-10-25; AGENTS.md.

## Global constraints

- Package `dev.ullmann.lumo.lumo_lernen.coachpreview`.
- Certificate `a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702`.
- Current product version `0.12.87+1999`; any product change needs a higher versionCode.
- Godot source `4d0fd40fdf188be6ca86057596c7b51f41701fa3`, engine 4.6.3.
- No weakened assertions, fabricated performance measurements, destructive Git actions or user-data resets.

## Review focus

Wrong APK/source pairing; an empty profile mistaken for meaningful persistence; replaced installation identity; duplicate rewards during update/restart; off-screen portals masked by helper/navigation.

### Task 1: Actual update gate for the existing candidate

**Files:** `tools/android_qa/update_preservation.py`, `tools/android_qa/tests/test_update_preservation.py`, `.github/probes/candidate_update_android_probe.py`, `.github/workflows/lumo-1999-update-gate.yml`.

**Interfaces:** Accept the original 1997 and c60bff1 1999 APK/provenance pairs. Produce `update-result.json`, screenshots, XML, unchanged installation identity and nonempty saved learning evidence. Reuse strict Kart helpers from `modernization_android_tour.py`.

- [x] Write failing tests for UID/time/version validation and meaningful learning/reward preservation, including negative cases (missing module RED, five checks GREEN).
- [x] Run tests, implement guards, run focused Python regression: 5 update + 15 native evidence + 10 existing tour identity tests passed locally.
- [ ] Install 1997, onboard through live UI, solve the real learning journey, install candidate with `-r`, verify offline/restart/Fold persistence and repeat native Kart tour.
- [ ] Inspect CI logs and actual images. Publish the verified ARM64 bytes only after all required checks pass; verify public download size/hash.
- [ ] Commit and push evidence/status; no merge into main.

### Task 2: Rendered app and module audit (after release gate)

**Files:** Existing `lib/features/games/spielwelt/spielwelt_hub.dart`, `lib/features/teacher_mode/lumo_akademie_screen.dart`, app-shell, design and navigation tests; dedicated new-version branch for product edits.

- [ ] Audit Start, Akademie, Mathematik, Deutsch, Lesen, Schreiben, Quiz and Spielwelt renders and every specialized module route.
- [ ] Reproduce portal visibility with helper/navigation enabled, small Fold cover, open Fold, landscape and large text; test before changing layout.
- [ ] Keep the full illustration, adapt height to actual content viewport, preserve reduced-motion and low-device behavior.
- [ ] Run full Flutter, pinned Godot export, Android/update/signature tests on a higher product version before publishing.

### Task 3: Kart presentation and measured hardware performance

- [ ] Review pinned native source and existing tracks/modes/vehicles/saves before isolated changes.
- [ ] Validate responsive controls, camera, HUD and reduced motion with real frames.
- [ ] Record real device frame times; a software-rendered emulator cannot establish the 60 FPS hardware target.

## Execution ledger

- Initial workspace was empty; cloned exactly the repair branch, clean at `c60bff1`. No preexisting local work was overwritten.
- Existing run 40096024152 and all four other head CI runs succeeded. Publication skipped because the release job only accepts the integration branch.
- Native evidence: drive distance +30.29, elapsed +5.02; screenshot shows 24 km/h; pause frozen, Flutter returned, profile/restart preserved. Existing test is fresh-install only.
- Candidate ARM64 SHA-256 `6d821c210afa4a26b905325551fb527ac3559eac877dc5ec322993d9350334e2`, distinct from original aa1c61e6 APK `b616f29ae696a116f7386453513b25dec056062b194dcc6133c15882e2fad582`.
- Ruling: use current isolated fresh clone on the user's repair branch; no extra worktree or plan approval pause, because the user explicitly ordered immediate execution.
