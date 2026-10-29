# Lumo 2027 – Shared briefing for all sub-agents (read fully before starting)

You are a sub-agent of the Lead Director (Claude Opus 5.5) working for Heinz Ullmann on
"Lumo Lernen" (Flutter learning app for Austrian primary school, grades 1–4) and
"Lumo Kart" (Godot 4.6.3 kart racer embedded in the Android app). Heinz's goal: Lumo must look
2027-premium. Warm, magical, cinematic, animated and child-friendly; clear, with heart. Premium
stylized-3D quality that adult gamers also respect. It is an EXECUTION order: inspect the real
code, decide the best buildable solution, implement it, test it, render real screenshots,
document it, commit and push. No mock claims, no empty placeholders, no fantasy promises.

## 1. Product rules (binding)

- Learning is the primary product. Inside Lumo Kart there are NO learning questions, learning
  cups, answer timers or correct-answer turbo mechanics.
- Never copy protected IP: no Mario/Nintendo, Call of Duty or other franchise characters,
  tracks, logos, names or assets. Quality may be inspired by big games; the look must be
  Lumo's own.
- Lumo is the original orange fox with goggles and a dark blue/cyan hoodie with a star. Use the
  ORIGINAL Lumo assets (`assets/lumo_design/...`, `LumoDesignFoxPose`, and the living character
  `lib/widgets/fox/living/lumo_living_character.dart`). Never invent a generic new fox.
- Show real data (stars, XP, level, progress) from the app state. Never show example numbers
  from mockups.
- Child-friendly: touch targets ≥ 48×48 dp, text scaling up to 2.0 must not overflow, Galaxy Z
  Fold (cover ≈ 344 dp wide, open ≈ 690–882 dp), reduce-motion
  (`LumoMotion.reduced(context)`) gets calm end states without endless loops.
- Honesty: render captures from Flutter widget tests or Godot under xvfb are NOT physical
  device tests. Never claim Fold7, FPS or device results you did not measure. Report exactly
  which commands ran and their results; list everything NOT executed.

## 2. Repositories and tools

- Flutter app: Ullmann27/lumo-lernen. Your worktree and branch are given in your mission.
  Base for all app work: `origin/release/lumo-2003-family-button-20261029` @ 5457b2ee
  (0.12.91+2003). It already contains Sol's tutor core ("living intelligence"), the living
  original Lumo and the Zehner-Werkstatt.
- Godot game: Ullmann27/lumo-godot. Base: `origin/qa/sonnenhafen-2003-aerial-flight-captures-20261029`
  @ 54ed315. Release 2003 pins revision adcce30. NEVER change the app's
  `config/godot-source.json` pin yourself.
- Flutter: `export PATH=/home/user/sdk/flutter/bin:$PATH` (3.44.9). The "running as root"
  warning is harmless. Run `flutter pub get` once in your worktree.
- Godot: `/home/user/tools/godot` (4.6.3). Headless:
  `godot --headless --path . --quit-after N res://...`. Real GL renders:
  `xvfb-run -a -s "-screen 0 1280x1024x24" /home/user/tools/godot --path . --rendering-driver opengl3 ...`.
  gdtoolkit: `/tmp/claude-0/-home-user/96aec6ad-48cf-593d-89d1-7a01d1494b24/scratchpad/gdvenv/bin/gdlint`
  and the matching `gdformat` in the same directory.
- The machine has only 4 CPU cores shared by several agents. Use `flutter test --concurrency=1`
  (or `-j 1`), run focused tests, never `flutter build`. Do not run the full Flutter suite more
  than once (and only at the end, `--concurrency=2 --timeout=120s`). Keep Godot runs short.
- Do not cd into other agents' worktrees. Do not use `git stash`. Never touch `/home/user/lumo-lernen`,
  `/home/user/lumo-living`, `/home/user/lumo-sol-base` or other agents' `/home/user/wt/*`
  directories.

## 3. Repository rules (CLAUDE.md, binding)

1. Green build: `flutter analyze` 0 errors (pre-existing infos/warnings may stay and must not
   grow in your files); the tests you touch pass. Godot: gdlint + gdformat --check on changed
   scripts, `python3 tools/validate_project.py`, headless smoke of changed scenes.
2. Small commits, one thing per commit, descriptive messages (English, conventional style,
   e.g. `feat(parents): ...`). End EVERY commit message with exactly these two lines:
   `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`
   `Claude-Session: https://claude.ai/code/session_01AWfMj3v4p197BTTiyyZYnQ`
   Never put a model name anywhere else (code, docs, PR text).
3. No new packages in pubspec.yaml without a strong reason. Never add imports of inactive
   packages. Prefer Flutter core (CustomPainter, FragmentProgram shaders, Transform with
   perspective, implicit animations) and the existing design system.
4. Images are files under `assets/` (never base64 in code). Register new asset folders in
   pubspec.yaml. Godot: no binaries > 1 MB, CC0 sources documented in `assets/CREDITS.md`.
5. Real data only.
6. No force-push, no rebase of pushed history, no merge into `main`, no release, no version bump,
   no changes to release/CI workflows unless your mission says so.
7. Report only verified success.
8. No dead code: every file in `lib/` must be reachable from `lib/main.dart`. If your new
   widget replaces an old one, wire it in and remove the old one only if nothing else uses it.

## 4. Ownership and claims (other AIs work in parallel)

Sol (GPT) owns the learning brain. Do NOT edit these files:
`lib/core/tutor_coordination_engine.dart`, `lib/core/lumo_companion_requests.dart`, learning
journey and evidence stores, `lib/app/app_state.dart` logic, the daily planner, the scene contract
and the directors under `lib/features/learning/scenes/`, Sol's living intelligence files, the
writing trainer, the journal, release workflows, the pubspec version, and `main`.
`lib/features/learning/learning_content.dart` is Sol's file. Touch it only if your mission
explicitly allows a narrow, additive hook. Presentation (widgets, painters, layout) is yours
within your mission's paths.

Before your first commit, create `docs/audit/2026-10-29/<YOUR-MODULE>-2027-CLAIM.md`
(in the Godot repo: `docs/audit/2026-10-29/...` as well). It must contain:
- agent profile "Claude Opus 5.5 – Lumo 2027 <module>";
- base branch and full SHA;
- the exact paths you will touch;
- reason and acceptance tests;
- explicitly excluded paths.

At the end, append a "Result" section to the claim with:
- resulting SHA and exact changed files;
- tests/counts run;
- NOT EXECUTED checks;
- next review owner.

## 5. Visual DNA (shared by every module)

- Tokens: `lib/theme/lumo_visual_tokens.dart`. Design system: `lib/widgets/design/`
  (`LumoGlassOptics`, `LumoPressable`, `LumoAnswerCrystal`, `LumoMotion`,
  `lumo_design_system.dart` with `LumoDesignFoxPose`/`LumoFoxPose`).
- Target pictures from Heinz: `docs/design_targets/2026-10-04/` and
  `docs/DESIGN_ZIEL_2026-10-04.md`.
- Look: deep night-blue/cyan hologlass, warm gold accents, controlled reflections, depth, soft
  light reactions on touch, clear labels, unified cards and buttons.
- Living Lumo (2D mesh rig on the original renders, 11 states: greet, listen, think, explain,
  demonstrate, encourage, approve, idea, celebrate, pause, wait):
  `LumoLivingCharacter(controller: LumoLivingController(...), size: ...)`, with
  `controller.perform(LumoLivingState.x, lookAt: Offset(-1..1, -1..1))`. It honours reduce-motion.
  This is not a 3D skeleton; never claim one.
- Motion rules: `lib/features/learning/scenes/learning_scene_motion.dart` and
  `lib/widgets/design/lumo_motion.dart`.
- Kart reference pictures (Heinz, 29.10.):
  `docs/design_targets/2026-10-29-kart-reference/*.jpg` in the Godot worktrees, also at
  `/tmp/claude-0/-home-user/96aec6ad-48cf-593d-89d1-7a01d1494b24/scratchpad/2027/kart-ref-*.jpg`.
  They show:
  - a sunny stylized coastal world: loops with blue chevron lights and stars, glass tubes,
    waterfalls, elevated bridges;
  - hot-air balloons with Lumo face, windmills, lighthouse, Lumo banners, sailing boats;
  - a "LUMO KART" tunnel gate, glowing blue boost chevron pads, red/white curbs, neon-blue guard
    rails, collectible gold stars;
  - the HUD: a dark top bar "RUNDE 1/2 PLATZ 1/6 48 km/h ★13" with a "Pause" button, a centre
    callout ("Lumo-Boost!", "Letzte Runde!"), a big glowing blue joystick bottom-left, and glossy
    square buttons DRIFT, SPEED (with count badge), SCHILD (badge), BREMSE and a large gold GAS.

## 6. Tests and real screenshots

- Capture helper: `test/helpers/lumo_capture.dart` (`loadLumoCaptureFonts`,
  `captureLumoBoundary`, `lumoCaptureSizes` phone 412×915, fold-cover 344×882,
  fold-open 690×829). Also capture 344×882 at text scale 2.0. Gate writing PNGs behind an
  env variable so CI does not write files.
- Make BEFORE captures on the base commit first, then AFTER captures. Put both under
  `docs/visual/2026-10-29-2027/<module>/` (Godot: `docs/visual/2026-10-29-2027/<module>/`).
- Budget: at most about 14 PNG/JPG per module, pixelRatio 1.25–1.5, each ideally under
  400 KB.
- Look at your own captures (Read the PNG) and iterate until they are genuinely good. Compare
  with the targets honestly.

## 7. Commit, push, finish

- `git add` only your files. Commit in small steps. Push with
  `git push -u origin <your-branch>`; retry up to 4 times on network errors (2 s, 4 s, 8 s, 16 s).
- Do NOT open pull requests. Do NOT merge. Leave the branch open for other AIs. Write a
  German handoff note `docs/visual/2026-10-29-2027/<module>/HANDOFF.md` covering what was
  checked, what was built, how to run tests and captures, what is open, and the next best step.
- Final answer to the Lead (concise, in English or German):
  - branch and final SHA;
  - what you checked (findings with file:line);
  - what you built;
  - exact test commands and results;
  - capture paths and your honest visual verdict versus the targets;
  - NOT EXECUTED items and open problems;
  - recommended next step.
