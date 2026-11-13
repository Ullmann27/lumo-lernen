# Combined LUMO integration / candidate 2019

Updated: 2026-11-13, 18:43 UTC. Active drafts: Native PR160 and Host PR465.
The current Native integration source is `90d34181409c15d1b1ad3a6a9643539453155c1d`,
Tree `9b407d61633a6421dc47b6858e6a6fb3fa60bea5`. Its own complete CI is running.
The preceding cce checkpoint reported GitHub SUCCESS for all fifteen workflows;
those originals retain their cce source identities. The current auxiliary-log
review found that the new Kart geometry job reports SUCCESS despite GDScript
parse/compile failures. Its PASS marker cannot establish a valid gate in the
presence of these errors. The hand-copied fixture omits two existing pose
dependencies; the bounded fixture/error-handling repair is being isolated.

This Host checkpoint adds the source-reviewed final-scroll observation,
API37 SDK-package selection and Native Python-environment repairs. The five
changed files passed 157 focused methods without errors or skips; two changed
workflows passed actionlint. Full original producer diagnostics, counterchecks,
frozen source hashes and the independent review are preserved under
[Android readiness evidence](docs/evidence/integration-20261113/host-2019-readiness/README.md).

The preceding public Host checkpoint is `2fa3b3d346c9d53930782bf6b9f0ad035ada7ac0`,
Tree `99f25c730a9a062d9529fea1979f3196e5831692`. Its 434 full Script and 794 full
Android-QA test results retain that earlier source scope. This checkpoint does
not change version, native pins, visual receipts or publication conditions.
Host PR465 remains at `e5c8d6f931647b56368daefab5b924070a02f11f` until current
Native evidence has passed and its original images have been reviewed.

Next: complete the exact 90d Native/Graphics evidence, review current original
images, record both source-bound receipts and update all three 2019 Native
identities together. Then publish the Host integration tree to its existing
draft and observe actual ARM64/x86, API35/API37 and 2017-to-2019 update gates.
The integration branch does not publish an APK. Main, PR461 and producer
worktrees remain protected. See [CONTINUE.md](CONTINUE.md) for the handoff.

## Earlier candidate-2017 history

The following preserved notes describe their original 2017 candidates and
historical decisions. They are not the active integration source or approval.

# Lumo Spielewelt and Kart action candidate 2017

Updated: 2026-11-12. Branch: `chatgpt/lumo-spielewelt-stage-20261112`.

## Corrected kart-card source; fresh visual acceptance pending

The current native pin is the concrete card-viewport correction `1d5c5cb45a323228f627ec529e6ff1ddd86f1c57`. Fresh exact-source renderer captures and Android APK/visual acceptance remain pending. Its headless regression is described below; this handoff is not release acceptance.

The preceding native pin `f04e580ec0d7d8f70e8be269523fabedd15b0766` and host `d279afa3af65e5224d28ae3855594a2da6a99739` remain an unpublished, visually rejected intermediate candidate. Actual renderer review found a selected 90 dp Gecko kart card in a visible scroll viewport of only 82.2857 dp at 2400x1080/420dpi; scrolling could not expose the whole card. The current workflow and 2017 policy reject this source as well as `0aa89cd`. D279's completed Flutter and native gates are valid partial evidence for that rejected source, not acceptance of the new pin. Its run `43215384284` had reached APK build before this follow-up commit; cancellation by the new synchronized run must be observed, not assumed.

The preceding host `c0ff902552e94856ea1dcda3cfb1f07e9e2044ed` remains visually rejected. Its Android tour passed 21 functional checks and its APK integrity was verified, but artifact `13940128981` exposed header/tab overlap and excessive landing-model occlusion at 2400x1080. Native pin `0aa89cdea3a07d0c2bc0a31a153737a1fee41454` is explicitly rejected by both the current 2017 policy and the current workflow's initial source check. Host run `43203717096` was actually cancelled at 11:54:51 UTC: its update job was cancelled and its publication job had no executed steps. The 2017 release lookup returned 404. That APK must not be published or presented as the corrected build. Current workflow changes cannot alter historical workflow revisions used by older runs.

## Source identity

- Flutter version: **0.13.5+2017**.
- Godot 4.6.3 source: **1d5c5cb45a323228f627ec529e6ff1ddd86f1c57** in [native PR #156](https://github.com/Ullmann27/lumo-godot/pull/156).
- The remote native commit was independently read back with tree `0941a80d811df4e3630f0c9de44d1417148ae320`, identical to local native commit `6279801354f0688b0c5ae166e502c5fab2d2651c`. Historical version policies 1950–2016 remain unchanged. Earlier unpublished 2017 candidates, including `b496fdd`, `0aa89cd` and `f04e580`, are explicitly rejected by the source policy.
- The installed-family package and public test certificate remain unchanged. This is not a Google Play signing claim.

## Current card-viewport correction

Native [card-viewport evidence](https://github.com/Ullmann27/lumo-godot/blob/1d5c5cb45a323228f627ec529e6ff1ddd86f1c57/docs/evidence/2026-11-12-card-viewport/RESULT.json) records **355 passing checks across six cases**, with all **14 kart cards fully visible** when selected and scrolled into view. The identical test fails on the rejected f04 baseline after **346 checks across six cases**. The corrected Android geometry has a 136.5714 dp scroll viewport for 90.28571 dp cards. These measurements are headless checks, not new renderer screenshots or Android APK acceptance. Local gdlint/gdformat were unavailable; no lint pass is claimed.

## Partial native layout evidence from the rejected f04 candidate

The native [layout evidence record](https://github.com/Ullmann27/lumo-godot/blob/f04e580ec0d7d8f70e8be269523fabedd15b0766/docs/evidence/2026-11-12-android-stage-layout/RESULT.json) reproduces the observed 2400x1080 Android geometry at 420 dpi, with a 1600x720 logical viewport and 1.5 pixel scale. The identical regression test executes **554 checks across five cases**: the corrected candidate passes and the rejected `0aa89cd` baseline fails. Compact selection passes **181 checks across four cases**; **240 touch controls** retain a minimum of 48x48 dp. These are headless geometry/behavior checks, not newly rendered Android screenshots. The touch-target run reports two resources still in use at teardown; local gdlint/gdformat were unavailable. No lint, renderer or device-performance pass is inferred from those runs.

## Included work and earlier development evidence

The Flutter Spielewelt restores the dimensional game cards and the established navigation. The native game presents its menus on one live 3D stage, uses twice the former physical driving pace, defaults new setups to the stronger `pro`/Extrem opponents, and adds physical ramps and bounded roadside lasso encounters. Existing learning modules, profiles and saved-game contracts remain in place.

The integrated native development checks include two driven laps with eight jumps and landings, sixteen checkpoints and two inverted loops; all thirty opponents across six fields completed their two-lap routes. The subsequent full touch/save/resume flow passed sixteen gates with two reopens and one reward delivery. Compact-menu validation passed 181 checks, and the camera checks passed 192 headless assertions. These checks do not establish Android frame rate or physical Fold7 performance.

The first active-snapshot engine probe now navigates the real section tabs and touches START once. Its unchanged eleven conditions passed with the first active snapshot at 1.0 seconds and the next at 6.016667 seconds. The adjacent snapshot and actual write-failure probes passed all 41 and 8 conditions respectively. Four additional rendered production fixtures use the same current navigation; their actual renderer acceptance remains a CI responsibility.

Earlier native portrait-labelled captures were found to contain landscape pixels because desktop startup reset the requested size. The integrated capture gate now resizes after startup, verifies the saved raster dimensions and checks rendered content. The earlier images are not evidence for portrait rendering. Exact-final-source native CI is still required.

Review of genuine portrait images then exposed magnified, blurred landing labels. The runtime now uses physical font and layout dimensions instead of scaling the whole landing Control. After 354 headless font/layout checks, actual X11 rendering on `b496fdd` passed **386 production UI checks** and saved correctly sized landing, garage and track images for all four surfaces. The two earlier workflow success-marker mismatches were corrected without changing game scripts or assets.

Historically, the now-rejected `0aa89cd` differed from `b496fdd` only in two test scripts, raw logs and a handoff. On that earlier source, the pointer probe passed **27 conditions** plus a failing disabled-tab negative control, MenuDepth passed **41 conditions**, and GaragePresentation passed **66 conditions**. Those were headless behavioral checks. The test-only description does not apply to the subsequent runtime corrections, and neither those checks nor the earlier 386 rendered UI checks establish current Android visual acceptance.

## Android delivery is pending

The host also includes the reviewed formatted-constructor guard correction: the actual multiline `AppShell(profile: _profile)` connection is accepted, while wrong direct arguments, quoted/commented lookalikes and nested arguments are rejected. The existing application-state checks and failed-scan handling remain enforced.

The current card-pin update passed **89 targeted pin, historical-policy, delivery, artifact-name and Android-tour contract tests with no skips**, plus the actual strict-pin CLI check. Current raw output and command/source hashes are stored separately in [card-pin evidence](docs/evidence/2026-11-12-host-card-pin/RESULT.json); the preceding d279/f04 host records remain unchanged in [earlier host evidence](docs/evidence/2026-11-12-host-layout-pin/RESULT.json). The historical 1950–2016 policy digest remains `6577810bda4d3811422fc9df47733f1d2e698ede56206d9c11f850dc6150b0db`. The regression executes the actual initial workflow Python check, requires each precise layout rejection for `0aa89cd` and `f04e580`, and accepts the current `1d5c5cb` pin. Synthetic publication metadata tests remain rejection-contract evidence only. No production Dart, concurrency setting or APK build script changed in this update.

The unified workflow now requires the existing full Flutter, legacy-native, 2014 and technical-art gates plus `validate_action_stage.sh` on the exact pin. The real Android tour touches Grand Prix, Garage, Fahrer and START. A separate real 2015→2017 install-in-place job must preserve learning and profile state through offline Kart, restart and simulated Fold changes.

Publication is restricted to this same-repository pull request after build, Android tour and update jobs succeed. It rechecks the actual ARM64 manifest, certificate, native source, APK hash and source-bound emulator evidence. It creates the immutable `coachpreview-build-2017` prerelease; an existing matching release can only be verified, never replaced. The final public APK is downloaded without authentication and compared byte-for-byte by size and SHA-256 before its link is accepted.

At this handoff there is **no newly built APK for `1d5c5cb` and no 2017 public download receipt**. Previous intermediate sources remain visually rejected; the cancelled c0ff update artifact is a partial record, not a successful upgrade result. The public test key, emulator acceptance and physical-device performance are distinct claims. Main and older published APKs remain unchanged.
