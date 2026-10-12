# 05 JUMP & RUN — Asset Prompt

## Shared generation prefix
"Original LUMO game asset, premium family-friendly 3D render, AAA-inspired mobile game quality, deep midnight-blue/cyan/gold art direction, soft volumetric lighting, clean readable silhouette, physically believable but stylized materials, child-safe, no third-party brand language, no copyrighted franchise styling."

## Technical handoff
Each generated render is a MODEL/ART REFERENCE unless explicitly listed as a background. The implementer must convert reference objects to proper runtime assets, keep collision/LOD/material budgets appropriate for Android/Fold, and verify actual runtime vs the image.

## Transparent environment/gameplay references
1. jump_platform_grass.png
2. jump_platform_stone.png
3. jump_platform_cloud.png
4. jump_moving_platform.png
5. jump_spring_pad.png
6. jump_checkpoint_gate.png
7. jump_star_pickup.png
8. jump_crystal_pickup.png
9. jump_enemy_slime.png
10. jump_enemy_cloudling.png
11. jump_enemy_beetle.png
12. jump_breakable_crate.png
13. jump_bridge_module.png
14. jump_waterfall_arch.png
15. jump_finish_gate.png
16. jump_lumo_run_pose.png
17. jump_lumo_air_pose.png
18. jump_lumo_land_pose.png

## World background
- bg_jump_world_wide.png — floating-island adventure landscape, no UI.

## Implementation prompt
Real platformer physics with coyote time, jump buffer, floor snap, stable landing, moving-platform parenting, enemy collisions, checkpoints, reset, camera look-ahead and touch controls. Reference images become meshes/material guides, not flat collision substitutes.
