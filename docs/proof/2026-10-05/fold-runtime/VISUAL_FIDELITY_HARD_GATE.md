# Visual Fidelity Hard Gate — Fold runtime vs approved Lumo references

Status: **REJECT / NOT REFERENCE-FAITHFUL**

User-provided Fold runtime captures:
- `current_start.webp`
- `current_profile.webp`

Comparison sheet:
- `comparison_current_vs_targets.webp`

## Start/Home — critical deltas
1. Runtime is a desktop-like left-rail layout; target uses a cinematic Lumo world with stronger hero composition and more integrated bottom navigation.
2. Current orange/purple/teal/pink flat tiles do not match the deep-blue/cyan/gold glass treatment.
3. Lumo is small/static compared with the target hero scale and pose.
4. Background image is functioning as wallpaper behind large flat widgets rather than a coherent scene/UI composition.
5. Bottom assistant strip obscures content and conflicts with the target navigation hierarchy.
6. Kart hero/banner is too thin and lacks the target's cinematic focal hierarchy.
7. Typography, spacing, glow, depth, iconography and card treatment materially differ from the references.

## Profile — critical deltas
1. Large cream/white panels are outside the approved midnight-blue/cyan/glass visual system.
2. Emoji-like / flat icons do not match the luminous 3D badge/reward assets.
3. Target has a strong Lumo hero, achievement hexes, reward showcase and cinematic background; runtime is mostly white information cards.
4. Bottom assistant strip obscures content and breaks the target composition.
5. Reward objects lack the target's pedestal/glow/3D presentation.
6. Hierarchy and spacing are materially different from the approved reference.

## Acceptance rule
Do not accept an implementation as reference-faithful because it contains the same labels or background art.
For each target screen, require:
- same overall composition/hierarchy,
- same deep-blue/cyan/gold glass language,
- comparable Lumo scale and placement,
- comparable card/panel geometry and glow,
- no flat placeholder blocks,
- no cream/white business-dashboard surfaces,
- no content-obscuring assistant overlay,
- runtime screenshot beside the exact reference image.

## Writer rule
One UI writer only. Use `Lumo UI Luna / GPT-5.6 Luna` explicitly (not Auto) for Flutter UI/Responsive/Nav. Read-only Visual QA follows after the candidate exists.