# Lumo 1978 – Premium learning + visual QA + Fold controls

Source: stacked on the completed 1977 candidate and the **real-font screenshot repair** in [PR #366](https://github.com/Ullmann27/lumo-lernen/pull/366). The original 1976 `0.12.64+1976` APK, stable 1977 `0.12.65+1977` APK and their archives are left untouched.

The source version in this branch is **`0.12.66+1978`** and the embedded 3D engine remains pinned to exactly Godot 4.6.3 commit `efa1f69b4128a047e6196ee85762447e412db266` from [Godot PR #101](https://github.com/Ullmann27/lumo-godot/pull/101). No preexisting registered Godot source hash was changed. The separate successful real two-lap testing improvements from Godot PR #102 remain independent; this release does not need to rebuild or replace the game physics.

## Delivered source improvements

- Fixed ABC and cross-grade screenshot factories, using **real original Nunito, MaterialIcons and (on headless Linux) Noto Color Emoji fonts** instead of synthetic Ahem bars, along with the actual production Flutter app theme. The production ABC Emoji text uses an explicit system emoji fallback; all 26 letters, examples and speech hooks are preserved.
- Pixel-level fail-closed screenshot quality gate: six real PNG files (phone, Fold cover, unfolded Fold), reject large solid white Ahem bars; Python positive/negative fixture tests and a dedicated GitHub Actions renderer test.
- 4 Gewinnt / Connect Four: seven existing 44dp column touch targets are reachable with horizontal scroll on narrow portrait Fold devices, and normal board alignment remains unchanged on landscape/tablet devices. The regression performs an **actual player tap into the seventh column at 320dp**.
- Verified build version 1978 with a strict new approved native source mapping. Unknown/future 1979 builds and version-to-native cross pins are rejected. Previous 1950–1977 pin history remains immutable.
- Full unified APK pipeline now installs Noto Color Emoji before all Flutter tests, runs the real-font PNG verification before archiving any captured images, captures five gameplay layouts of 4 Gewinnt, and archives an **individual, directly downloadable ARM64 candidate with matching SHA-256 and build provenance** as well as the original two-ABI candidate. A separate Android emulator tour must pass independently; this is not a claim about physical Fold7 performance.

## Evidence policy

Screenshots from a Flutter widget test **are not device screenshots**. Android x86_64 emulator screenshots are also not physical Fold7 captures. A successful static analyzer, tests, and ZIP hash cannot prove visual console-level quality or 60 FPS. The prior unusable block-font images must never be presented as genuine preview shots.

The draft PR and all release candidate artifacts remain separate from `main`; no force-push, no public release, no deletion of core learning/voice/journal/profile or saved-game modules.
