# Lumo Next Generation: shared briefing for every agent (13.11.2026)

Read this fully before you start. You are a sub-agent of the lead (Claude Opus 5.5) working for
Heinz Ullmann on "Lumo Lernen" (Flutter learning app for Austrian primary school, grades 1–4,
with an embedded Godot 4.6.3 game layer: Lumo Kart, Bauwelt, Cards, Puzzle, Treasure hunt,
Jump & Run, Memory, Rhythm Party and more). The target device is a Galaxy Z Fold7 on Android 17.

Heinz's order today: every game must look like the reference images below. The look must be
the same across all games. He wants truly modern AAA+ quality: warm, magical, cinematic and
child-friendly, so that adult gamers respect it too.

This is an EXECUTION order: inspect the real code, build, test, render real captures, then
commit and push.

## 1. Binding reference images (Heinz, 13.11.2026)

All files are in `docs/design_targets/2026-11-13-aaa/ (im Flutter-Repo)`.
Look at the ones for your module with the Read tool before you design anything.

| File | Shows |
|---|---|
| `spielwelt-hub.jpg` | **Spielwelt main hub (most important).** Night-blue magical world: castle, waterfalls, moon, lanterns, wooden signs. The big glossy "Lumo Spielwelt" logo. Lumo stands centred on a rock. Glass portal cards around him, each with key art (Memory, Cards, Puzzle, Jump & Run, Rhythm Party, Schatzsuche, Bauwelt). A big cyan "Auf ins Abenteuer!" button. A bottom glass bar with Elternbereich, Fortschritt and Einstellungen. |
| `spielwelt-board.jpg` | Technical board for the hub. It covers the floating-island map, the portal states (normal vs active: scale plus glow), the primary and secondary buttons, the icons (star, lock, NEU, done, progress), the glass panel and its typography, the orbit camera, the VFX (moonlight, stars, glow, waterfalls, reflections, fog) and the animations (Lumo breathing/blinking/waving, portal float and glitter, floating islands, flags, lanterns). |
| `lumo-master-sheet.jpg` | **Lumo master character.** Orange fox, cream belly and muzzle, big brown eyes, cyan-blue bandana with a star, and a dark backpack with a glowing star. The sheet shows a turnaround, 8 expressions (happy, excited, focused, thoughtful, surprised, cheering, calm, sleepy) and key poses (idle with breathing and blinking, walk, run, jump start, in the air, landing, point, dance, card throw). It also gives the colour palette. |
| `memory-poster.jpg`, `cards-poster.jpg`, `puzzle-poster.jpg`, `jumprun-poster.jpg`, `schatzsuche-poster.jpg`, `bauwelt-poster.jpg`, `rhythm-poster.jpg` | Key art and title screen for each game. Same night world, same logo style ("Lumo" in gold, the game name in cyan, with a gold orbit ring and stars). The bottom glass panel shows the design and implementation notes. |
| `cards-board.jpg`, `schatzsuche-board.jpg`, `rhythm-board.jpg`, `jumprun-board.jpg`, `bauwelt-board.jpg` | Per-game boards: runtime mockup, asset palette, flow, UI components, VFX and camera. |
| `kart-main-menu.jpg` | Lumo Kart main menu. Lumo (goggles plus racing suit) sits in a glossy blue/gold kart in the 3D Sonnenhafen world. On the left, mode pills: Modus, Fahrer, Kart, Garage, Welt, Tempo. Below, mode cards: Grand Prix, Zeitrennen, Einzelrennen, Mehrspieler, Abenteuer. A big gold START button, a bottom customise bar, and a top bar with stars and the profile level. **Ignore** the right-hand "Menü-Entwicklung im Vergleich" panel; it is commentary. |
| `kart-garage.jpg` | Kart garage. Top tabs: Garage, Rennen, Welt, Missionen, Shop, Profil, Einstellungen. Left categories: Anpassen, Fahrzeuge, Fahrer, Lackierung, Räder, Aufkleber, Outfits, Accessoires, Effekte, Sound & Hupe. A stats card with bars (Tempo, Beschleunigung, Handling, Grip, Turbo). Kart plus Lumo on a glowing turntable, with rotate, photo and fullscreen buttons. On the right, Fahrer/Outfit/Accessoires tabs, an outfit grid, colour dots and an accessory row. At the bottom, a parts tab row (Karosserie, Spoiler, Räder, Lackierung, Aufkleber, Effekte) and a kart carousel. "Zurück" sits bottom left and a big gold "Bereit zum Rennen!" bottom right. |
| `kart-finish-1st/2nd/3rd.jpg` | Race finish. Night celebration street with a FINISH banner, Lumo cheering in his kart, and a big placement badge (gold, silver or bronze). The stats panel shows Gesamtzeit, Beste Runde, Münzen and Sterne/XP. Buttons: Weiter (gold) and Nochmal. In the app the texts are **German**. |

Visual DNA, the same everywhere:
- Deep night blue (#0b1640 to #1b2f7a) with cyan glow (#3ad7ff) and warm gold (#ffc93c to #ffb000).
- Glossy glass panels with a thin cyan rim light and soft inner gradient.
- Big rounded bold type (the existing app fonts; Baloo/Fredoka style if already present). Big icons.
- Living motion: float, glitter, glow pulses, parallax, Lumo breathing and blinking.

## 2. How you may use the images

They are Heinz's own artworks, so you MAY crop regions of them into app assets: backgrounds,
key art for portal cards and title screens, character cut-outs. Rules for doing that:
- NEVER ship baked-in text, UI, logos-with-text or example numbers from the images. Crop them
  out. Real labels are built as real widgets or nodes with real data: stars, XP, level and
  times come from the actual app or game state.
- Assets go to `assets/...` as `.webp` or `.jpg`, each ideally ≤ 300 KB. In Flutter, register
  new folders in `pubspec.yaml`. No base64 in code.
- Commit the reference images you used, unchanged, to `docs/design_targets/2026-11-13-aaa/`
  in your repo, so reviewers can compare.

## 3. Repos, bases, branches

- Flutter: `Ullmann27/lumo-lernen`, main clone `/home/user/lumo-lernen` (do not work in it).
  Create your own worktree:
  `git -C /home/user/lumo-lernen worktree add -b <your-branch> /home/user/wt/<name> origin/chatgpt/lumo-kart-graphics-apk-20261113`
  - base `bc58a16f`, version 0.13.7+2019;
  - do not change `pubspec.yaml` version or `config/godot-source.json`; the lead does pins.
- Godot: `Ullmann27/lumo-godot`, main clone `/home/user/lumo-godot`. Base:
  `origin/claude/lumo-nextgen-combined-20261113` @ `76d49866`. This is the combined line of
  studio, Kart graphics, winter, creative effects, Bauwelt village and native integration.
  Create your worktree the same way with `git -C /home/user/lumo-godot worktree add ...`.
- Flutter SDK: `export PATH=/home/user/sdk/flutter/bin:$PATH` (3.44.9). Run `flutter pub get`
  once.
- Godot: `/home/user/tools/godot` (4.6.3). The first time, run
  `godot --headless --path . --import` in your worktree (takes a few minutes).
  - Real GL renders:
    `xvfb-run -a -s "-screen 0 1280x720x24" /home/user/tools/godot --path . --audio-driver Dummy --rendering-method gl_compatibility ...`
  - gdlint/gdformat:
    `/tmp/claude-0/-home-user/96aec6ad-48cf-593d-89d1-7a01d1494b24/scratchpad/gdvenv/bin/{gdlint,gdformat}`
- The machine has only 4 cores, shared by 5 agents. Use `flutter test --concurrency=1` on
  focused test files. Never run `flutter build` and never the full suite. Keep Godot runs short
  with `timeout`.
- Never touch other agents' worktrees. Never use `git stash`. Never `cd` into `/home/user/lumo-lernen`
  or `/home/user/lumo-godot` to change files.

## 4. Commit and push are MANDATORY (Heinz)

- Commit after every working step and push immediately: `git push -u origin <branch>`. Retry
  network errors 4 times (2, 4, 8, 16 s). Verify with `git ls-remote origin <branch>` that the
  remote SHA equals your HEAD. At least every 20–30 minutes something must be on GitHub.
  Before you finish, nothing may be left uncommitted or unpushed.
- End EVERY commit message with exactly these two lines:
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`
  `Claude-Session: https://claude.ai/code/session_01AWfMj3v4p197BTTiyyZYnQ`
  Never write a model name anywhere else (code, docs, PR text).
- No force-push, no rebase of pushed history, no merge into `main`, no release, no version bump,
  no changes to release/APK workflows, no pull requests. Leave the branch open.

## 5. Product rules

- Learning is the primary product. In Lumo Kart there are NO learning questions.
- Never copy protected IP (no Nintendo/Sega/Activision characters, names, tracks or logos).
  Lumo's look is our own.
- Real data only. Keep every existing function: routes, saves, child profiles, rules, cups,
  progress, voice, privacy, offline. The parents area stays separate and protected.
- Child-friendly: touch targets ≥ 48 dp; text scale 2.0 must not overflow; Fold layouts (cover
  ≈ 344 dp wide, open ≈ 690–882 dp); no status-bar overlap; reduce-motion
  (`LumoMotion.reduced(context)`) gets calm end states.
- Flutter rules (repo CLAUDE.md):
  - `flutter analyze` with no new errors;
  - the tests you touch must pass;
  - no new packages without a strong reason;
  - every file in `lib/` must be reachable from `lib/main.dart` (no dead code).
- Godot rules: gdlint plus gdformat --check on changed scripts, `python3 tools/validate_project.py`,
  and a headless probe/regression of what you changed.
- Sol's (GPT) learning brain stays logically untouched unless your mission says otherwise:
  `lib/core/tutor_coordination_engine.dart`, `lib/core/lumo_companion_requests.dart`, learning
  journey/evidence stores, `lib/app/app_state.dart` logic, the writing trainer and the journal.

## 6. Honesty

Flutter widget-test captures and Godot xvfb renders are NOT device tests. Never claim Fold7,
FPS, installation or release results. Report exactly which commands ran and their results, and
list what was NOT executed.

## 7. Captures

- Make BEFORE captures on the base and AFTER captures on your result. Put them under
  `docs/visual/2026-11-13-aaa/<module>/`, at most about 12 images, each ideally under 400 KB.
- Flutter: `test/helpers/lumo_capture.dart` if present (phone 412×915, fold-cover 344×882,
  fold-open 690×829). Gate PNG writing behind an env variable.
- Look at your captures with Read and iterate until they genuinely approach the reference. Then
  compare honestly.

## 8. Final answer to the lead (short)

Include:
- the branch and the final pushed SHA, verified with `ls-remote`;
- what you built, with file paths;
- exact test commands and their results;
- capture paths and an honest visual verdict versus the reference;
- what was NOT executed and what is still open;
- the next best step.

Also write `docs/visual/2026-11-13-aaa/<module>/HANDOFF.md` in German.
