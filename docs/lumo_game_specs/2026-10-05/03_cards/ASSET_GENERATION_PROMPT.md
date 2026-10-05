# 03 LUMO CARDS — Asset Prompt

## Shared generation prefix
"Original LUMO game asset, premium family-friendly 3D render, AAA-inspired mobile game quality, deep midnight-blue/cyan/gold art direction, soft volumetric lighting, clean readable silhouette, physically believable but stylized materials, child-safe, no third-party brand language, no copyrighted franchise styling."

## Technical handoff
Each generated render is a MODEL/ART REFERENCE unless explicitly listed as a background. The implementer must convert reference objects to proper runtime assets, keep collision/LOD/material budgets appropriate for Android/Fold, and verify actual runtime vs the image.

## Transparent assets
1. cards_back_master.png
2. cards_color_cyan.png
3. cards_color_gold.png
4. cards_color_violet.png
5. cards_color_green.png
6. cards_number_token_0.png
7. cards_number_token_1.png
8. cards_number_token_2.png
9. cards_number_token_3.png
10. cards_action_swap.png
11. cards_action_boost.png
12. cards_action_shield.png
13. cards_deck_box.png
14. cards_lumo_play_pose.png

## Implementation prompt
Original Lumo card game, no imitation of proprietary branded card layouts. Build real hand fan, draw/discard piles, turn states, card fly/throw animation, readable color+shape accessibility, AI opponent, pause/restart/back, deterministic tests and reward/persistence.
