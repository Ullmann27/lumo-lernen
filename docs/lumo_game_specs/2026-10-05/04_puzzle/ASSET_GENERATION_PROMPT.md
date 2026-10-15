# 04 PUZZLE — Asset Prompt

## Shared generation prefix
"Original LUMO game asset, premium family-friendly 3D render, AAA-inspired mobile game quality, deep midnight-blue/cyan/gold art direction, soft volumetric lighting, clean readable silhouette, physically believable but stylized materials, child-safe, no third-party brand language, no copyrighted franchise styling."

## Technical handoff
Each generated render is a MODEL/ART REFERENCE unless explicitly listed as a background. The implementer must convert reference objects to proper runtime assets, keep collision/LOD/material budgets appropriate for Android/Fold, and verify actual runtime vs the image.

## Transparent assets
1. puzzle_board_frame.png
2. puzzle_piece_corner_cyan.png
3. puzzle_piece_edge_gold.png
4. puzzle_piece_center_blue.png
5. puzzle_piece_center_green.png
6. puzzle_picture_castle.png
7. puzzle_picture_fox.png
8. puzzle_picture_planet.png
9. puzzle_picture_forest.png
10. puzzle_lift_glow.png
11. puzzle_snap_ring.png
12. puzzle_success_burst.png
13. puzzle_tray.png
14. puzzle_lumo_place_pose.png

## Implementation prompt
Pieces are independent draggable objects with touch lift, depth, shadow, rotation if enabled, snap threshold, occupied-slot protection, success VFX, no fake full-board image interaction. Difficulty scales piece count and rotation.
