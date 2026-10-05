# 07 SCHATZSUCHE — Asset Prompt

## Shared generation prefix
"Original LUMO game asset, premium family-friendly 3D render, AAA-inspired mobile game quality, deep midnight-blue/cyan/gold art direction, soft volumetric lighting, clean readable silhouette, physically believable but stylized materials, child-safe, no third-party brand language, no copyrighted franchise styling."

## Technical handoff
Each generated render is a MODEL/ART REFERENCE unless explicitly listed as a background. The implementer must convert reference objects to proper runtime assets, keep collision/LOD/material budgets appropriate for Android/Fold, and verify actual runtime vs the image.

## Transparent assets
1. treasure_compass.png
2. treasure_map_folded.png
3. treasure_map_open.png
4. treasure_clue_tablet.png
5. treasure_key_gold.png
6. treasure_key_cyan.png
7. treasure_chest_closed.png
8. treasure_chest_open.png
9. treasure_crystal_cache.png
10. treasure_cave_arch.png
11. treasure_ruin_pillar.png
12. treasure_footprints.png
13. treasure_lumo_compass_pose.png
14. treasure_lumo_open_chest_pose.png

## Background
- bg_treasure_world_wide.png — mysterious floating ruins, cave, waterfall, moonlight, readable exploration path, no UI.

## Implementation prompt
Loop: clue -> explore -> puzzle -> find -> reward. Real hotspots/navigation, clue state, no dead-end progression, save/resume, child-safe hints, reward exactly once.
