# Lumo Spielewelt and Kart action candidate 2017

Updated: 2026-11-12. Branch: `chatgpt/lumo-spielewelt-stage-20261112`.

## Source identity

- Flutter version: **0.13.5+2017**.
- Godot 4.6.3 source: **0aa89cdea3a07d0c2bc0a31a153737a1fee41454** in [native PR #156](https://github.com/Ullmann27/lumo-godot/pull/156).
- The native GitData commit was checked against tree `f721fd75095d7244c1152c43cd83dcd8a88d5985` before this pin. Older version policies, including 2011–2016, remain unchanged. Earlier unpublished 2017 candidates, including `b496fdd`, are explicitly rejected by the source policy.
- The installed-family package and public test certificate remain unchanged. This is not a Google Play signing claim.

## Included work and development evidence

The Flutter Spielewelt restores the dimensional game cards and the established navigation. The native game presents its menus on one live 3D stage, uses twice the former physical driving pace, defaults new setups to the stronger `pro`/Extrem opponents, and adds physical ramps and bounded roadside lasso encounters. Existing learning modules, profiles and saved-game contracts remain in place.

The integrated native development checks include two driven laps with eight jumps and landings, sixteen checkpoints and two inverted loops; all thirty opponents across six fields completed their two-lap routes. The subsequent full touch/save/resume flow passed sixteen gates with two reopens and one reward delivery. Compact-menu validation passed 181 checks, and the camera checks passed 192 headless assertions. These checks do not establish Android frame rate or physical Fold7 performance.

The first active-snapshot engine probe now navigates the real section tabs and touches START once. Its unchanged eleven conditions passed with the first active snapshot at 1.0 seconds and the next at 6.016667 seconds. The adjacent snapshot and actual write-failure probes passed all 41 and 8 conditions respectively. Four additional rendered production fixtures use the same current navigation; their actual renderer acceptance remains a CI responsibility.

Earlier native portrait-labelled captures were found to contain landscape pixels because desktop startup reset the requested size. The integrated capture gate now resizes after startup, verifies the saved raster dimensions and checks rendered content. The earlier images are not evidence for portrait rendering. Exact-final-source native CI is still required.

Review of genuine portrait images then exposed magnified, blurred landing labels. The runtime now uses physical font and layout dimensions instead of scaling the whole landing Control. After 354 headless font/layout checks, actual X11 rendering on `b496fdd` passed **386 production UI checks** and saved correctly sized landing, garage and track images for all four surfaces. The two earlier workflow success-marker mismatches were corrected without changing game scripts or assets.

The current `0aa89cd` native pin differs from `b496fdd` only in two test scripts, their raw logs and a handoff; production scripts and assets are identical. The revised pointer probe passed **27 conditions** covering current native navigation and all retained legacy ray checks. Its negative control disabled the actual track tab and correctly failed the native touch/mouse conditions without printing PASS. MenuDepth passed all **41 conditions** after completed teardown, and the unchanged GaragePresentation probe passed **66 conditions**. Those last three behavioral probes ran headlessly; they do not replace actual rendering. The new exact-source CI and Android acceptance remain pending.

## Android delivery is pending

The host also includes the reviewed formatted-constructor guard correction: the actual multiline `AppShell(profile: _profile)` connection is accepted, while wrong direct arguments, quoted/commented lookalikes and nested arguments are rejected. The existing application-state checks and failed-scan handling remain enforced.

On the preceding combined host candidate, the complete Python build-contract suite passed **269 tests with no skips**, including the real Gradle contract probe and the twelve constructor tests; all **13 Android-tour contract tests** also passed. The current pin-only update passed **68 targeted pin, historical-policy and delivery-contract tests**, with the historical 1950–2016 policy digest unchanged. The workflow and build scripts are unchanged from their previously checked state. The metadata mutation tests use explicitly synthetic fixtures; they validate rejection logic and do not substitute for a built APK or emulator run.

The unified workflow now requires the existing full Flutter, legacy-native, 2014 and technical-art gates plus `validate_action_stage.sh` on the exact pin. The real Android tour touches Grand Prix, Garage, Fahrer and START. A separate real 2015→2017 install-in-place job must preserve learning and profile state through offline Kart, restart and simulated Fold changes.

Publication is restricted to this same-repository pull request after build, Android tour and update jobs succeed. It rechecks the actual ARM64 manifest, certificate, native source, APK hash and source-bound emulator evidence. It creates the immutable `coachpreview-build-2017` prerelease; an existing matching release can only be verified, never replaced. The final public APK is downloaded without authentication and compared byte-for-byte by size and SHA-256 before its link is accepted.

At this handoff there is **no verified 2017 APK or public download receipt**. The public test key, emulator acceptance and physical-device performance are distinct claims. Main and older published APKs remain unchanged.
