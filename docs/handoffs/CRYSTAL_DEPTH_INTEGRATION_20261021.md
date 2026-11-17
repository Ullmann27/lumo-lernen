# Lumo – SOL crystal depth integration · 21.10.2026

## Source of truth
- SOL remote branch: `sol/fix-answer-crystal-depth-20261021`, visual/test checkpoint `f7e359cc4df29c4b113ab8206def03c95feb08aa`, handoff `f27a50b5cdab2131a62330a0edf714822cf6312e`.
- Original independently checked Flutter base: `0eef84aa54f1ee4b180718e917bf8f1d529fe81c`.
- Destination parent: `chatgpt/lumo-sol-integrated-1995-20261021@64ff88e706718c84148b9cc070f0410045bb295f`.
- Isolated destination: `chatgpt/lumo-crystal-depth-integration-20261021`; no edits to SOL branches, default branch or signed APKs.

## Actual integration
- `lib/features/learning_modules/minus_bis_10/minus_bis_10_screen.dart`: use real `LumoCrystalAnswerGrid` instead of compact 68–84dp lesson cells. SOL target 108dp crystals.
- `lib/widgets/design/lumo_answer_crystal.dart`: SOL side faces, brighter triangulated facets, light edges, subtle number shadow and 3D pedestal; preserve interaction and semantics.
- `test/design/minus_crystal_depth_regression_test.dart`: navigate genuine Academy → class 1 → Maths → Minus, enforce four crystals, ≥100dp each, touch hit tests, native number semantics and rendered facet pixels.
- Historical SOL evidence copied to `docs/handoffs/evidence/crystal-depth-2026-10-21/`. Authentic before/after PNGs remain in the SOL source branch; no synthetic images:
  - [before](https://github.com/Ullmann27/lumo-lernen/blob/sol/fix-answer-crystal-depth-20261021/docs/handoffs/evidence/crystal-depth-2026-10-21/before/minus-bis-10-phone-360x800.png)
  - [after](https://github.com/Ullmann27/lumo-lernen/blob/sol/fix-answer-crystal-depth-20261021/docs/handoffs/evidence/crystal-depth-2026-10-21/after/minus-phone.png)
- Original evidence reports 12 passed tests and targeted analyze without issues. That evidence predates this integrated branch's CI and must **not** be misrepresented as integrated testing.

## Release safety and next step
- Run targeted Flutter analysis and real capture on this merged branch. Confirm saved screenshot and 12 actual route/progress tests.
- No new APK or direct Chrome release until the complete 1995+ candidate Flutter suite, Android build/signature/hash and real emulator tour pass. Previous Build 1995 Android run failed and must not be relabeled as green.
- SOL's crystal fix deliberately starts with Minus bis 10; other math modules need separately verified full-height grid/cell behavior.
- For a planned new APK, choose a new monotonically increasing versionCode and exact reviewed Godot SHA; do not overwrite 1993/1994/1995 artifacts.
