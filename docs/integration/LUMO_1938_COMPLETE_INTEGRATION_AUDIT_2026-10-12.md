# Lumo 1938 complete integration audit — 2026-10-12

Base product:
- Flutter/Sol: de7bcd0a27d813ccc816090b5ca4c4e1fe07be1f
- Godot runtime: ec96515a2e359d21e9591120fc81dfd15116e81e

## Integrated without replacing newer product code

- 52 Lumo production boards, manifests and agent handoffs from the 100+ asset production line.
- 42 Astra learning-quality evidence / Kart asset handoff files.
- 142 missing runtime design assets from claude/design-tafeln. These directories were already declared in pubspec and current runtime code already references recovered Kart assets.
- Android profile edit-button semantics from the later computer voice-runtime fix, with its regression test.
- Fold renderer guard preventing wide measurement/fraction visuals from being squeezed into half-width columns, with regression coverage.
- Market-start and Lumo game reference packages.
- Godot puzzle 3D production/reference package on the separate integration branch.

## Verified as already present or superseded

- Astra learning-quality product changes: current 1938 already contains the short-landscape lesson frame, clock 12→1 fixes, successor 9→10, denser lesson glass and task layouts.
- Reading/writing asset-handoff code: reading domain, word bank, reading library and tests are blob-identical; current writing_engine is newer/larger.
- Claude old writing coach: current coach has four modes, curriculum progression, custom words, persistence, current feedback, voice and rewards; old branch only analyzes I/L/O/H.
- Tier-4 card optics: current cards already have 3D perspective; discard/draw animations are newer and lifecycle-safe. Old extra flip was not stacked on top.
- Hologlass/cards branch: current Cards screen/design system is newer and already uses glass presentation.
- Cognitive curriculum branch: repository/scorer/catalog/domain/screens are present, several blob-identical; current generator/tests are newer.
- Old Claude voice branch: current Lumo voice/settings contain newer Sulafat and offline logic.
- Old Godot Sulafat branch: current AudioManager/generator has stricter manifest/hash/model validation.
- Old Godot visual-fidelity/premium-menu/touch branches: current runtime contains newer equivalents and stronger multi-touch/brake/label behavior.

Rule used throughout: never wholesale-merge a branch that is behind the product line; port only a demonstrably missing higher-quality delta.
