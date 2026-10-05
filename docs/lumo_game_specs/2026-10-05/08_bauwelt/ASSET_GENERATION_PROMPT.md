# 08 BAUWELT — Asset Prompt

## Shared generation prefix
"Original LUMO game asset, premium family-friendly 3D render, AAA-inspired mobile game quality, deep midnight-blue/cyan/gold art direction, soft volumetric lighting, clean readable silhouette, physically believable but stylized materials, child-safe, no third-party brand language, no copyrighted franchise styling."

## Technical handoff
Each generated render is a MODEL/ART REFERENCE unless explicitly listed as a background. The implementer must convert reference objects to proper runtime assets, keep collision/LOD/material budgets appropriate for Android/Fold, and verify actual runtime vs the image.

## Transparent build-kit references
1. build_block_stone.png
2. build_block_wood.png
3. build_block_glass_cyan.png
4. build_arch.png
5. build_bridge_short.png
6. build_bridge_long.png
7. build_tower.png
8. build_tree.png
9. build_lantern.png
10. build_crystal.png
11. build_waterfall_piece.png
12. build_rotate_tool.png
13. build_delete_tool.png
14. build_lumo_builder_pose.png

## Implementation prompt
Real place/rotate/snap/delete/undo, occupancy grid or socket system, orbit/zoom/pan camera, save/load templates, placement ghost and collision validity. Do not represent construction as pre-rendered final screenshots.
