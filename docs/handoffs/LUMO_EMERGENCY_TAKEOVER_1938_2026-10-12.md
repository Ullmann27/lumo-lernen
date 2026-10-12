# Lumo emergency takeover baseline — 2026-10-12

This branch exists only so a fallback model can continue immediately if the active Sol 6.1 Work session hits a usage limit.

## Frozen safe baseline

- Flutter product: `a71c1cdea21af202d71273da19bb4d00988fc970`
- Godot product: `ec96515a2e359d21e9591120fc81dfd15116e81e`
- Version: `0.12.30+1937`
- Successful unified APK run: `38238926882`
- ARM64 artifact: `11742812420`

Do not overwrite or merge the active Sol branches. On takeover, first refresh their latest heads and compare them to this baseline.

## Sol work already seen after 1937

At snapshot time:

- `sol/lumo-curriculum-depth-1938-2026-10-12` at `9848b0a568a147f5da69d12346dae4c953724d68`
  - adds deeper spelling, English and grammar banks.
- `sol/lumo-1937-android-acceptance-2026-10-12`
  - acceptance-only work; product source remains the frozen 1937 commit.
  - previous failures reached real Kart runtime/screenshots but failed strict probe conditions.

If Sol produces newer commits before takeover, import those newer commits selectively first.

## High-value material still requiring re-audit

Priority sources:

1. `chatgpt/lumo-kart-assets-handoff-2026-10-10`
   - game/world key art, technical boards, asset production material.
2. Godot `chatgpt/puzzle-3d-core-2026-10-07`
   - puzzle key art/board and 3D production specification.
3. `claude/lumo-kart-premium-A9oBr`
   - inspect only missing writing/recognition components; do not revive obsolete Flutter Kart architecture.
4. `claude/tier4-3d-optics`
   - inspect missing 3D card flip / visual components.
5. `astra/lumo-learning-quality-2026-10-11`
   - learning visual/didactic work.
6. `sol/lumo-guided-language-nature-2026-10-12`
   - guided language/nature course work.

## Known findings to preserve

- The guided subtraction lesson already contains a real animated quantity model. Example `12 − 5`: first 2 items move away to reach 10, then 3 more; timing is tested. No committed finished MP4 was found in 1937.
- A major portion of expensive visual work exists as boards/reference art rather than runtime 3D. The missing production step is generally:
  Reference → mesh/Blender → material → collider/LOD → Godot prefab → scene placement → runtime screenshot.
- Current Godot already contains newer versions of several old premium-menu/visual-fidelity ideas. Never wholesale-merge an old branch merely because its name sounds premium.

## Emergency takeover sequence

1. Refresh Sol 6.1 branch heads and current GitHub Actions state.
2. Preserve every Sol product commit that is newer than the frozen baseline.
3. Separate product changes from QA-only/probe changes.
4. Compare remaining divergent branches file-by-file.
5. Port only demonstrably missing higher-quality assets/functions.
6. Prioritize:
   - richer curriculum/lesson variety,
   - polished guided subtraction animation,
   - real 3D conversion of existing art,
   - one visibly upgraded Kart world as quality reference,
   - Fold-safe controls/runtime.
7. Run analyzer/tests/Godot checks.
8. Build a new unified APK only after visible product changes.
9. Produce screenshots from the exact same Flutter/Godot product commits as the APK.
10. Downloads are delivered only through GitHub Actions artifact links.

No merge to `main` and no public release without explicit user approval.
