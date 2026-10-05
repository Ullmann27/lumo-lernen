# 02 MEMORY — Asset Prompt

## Shared generation prefix
"Original LUMO game asset, premium family-friendly 3D render, AAA-inspired mobile game quality, deep midnight-blue/cyan/gold art direction, soft volumetric lighting, clean readable silhouette, physically believable but stylized materials, child-safe, no third-party brand language, no copyrighted franchise styling."

## Technical handoff
Each generated render is a MODEL/ART REFERENCE unless explicitly listed as a background. The implementer must convert reference objects to proper runtime assets, keep collision/LOD/material budgets appropriate for Android/Fold, and verify actual runtime vs the image.

## Transparent assets
1. memory_card_back_master.png
2. memory_card_front_fox.png
3. memory_card_front_wolf.png
4. memory_card_front_owl.png
5. memory_card_front_deer.png
6. memory_card_front_rabbit.png
7. memory_card_front_bear.png
8. memory_card_front_otter.png
9. memory_card_front_hedgehog.png
10. memory_table_frame.png
11. memory_match_starburst.png
12. memory_mismatch_soft_cloud.png
13. memory_reward_chest.png
14. memory_lumo_cheer_pose.png

## Visual target
Cards look like premium tactile 3D objects: bevel, rim light, subtle holographic cyan edge, readable animal art, no text dependence.

## Implementation prompt
Real card grid, front/back materials, 3D Y-axis flip with stable state machine, match/mismatch timing, input lock during animation, scalable 2x3/3x4/4x4 layouts, persistence/restart/back, reward exactly once, responsive Phone/Fold.
