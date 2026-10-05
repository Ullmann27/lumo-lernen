# 00 MASTER — Lumo Character, Rig and Animation Reference Pack

## Shared generation prefix
"Original LUMO game asset, premium family-friendly 3D render, AAA-inspired mobile game quality, deep midnight-blue/cyan/gold art direction, soft volumetric lighting, clean readable silhouette, physically believable but stylized materials, child-safe, no third-party brand language, no copyrighted franchise styling."

## Technical handoff
Each generated render is a MODEL/ART REFERENCE unless explicitly listed as a background. The implementer must convert reference objects to proper runtime assets, keep collision/LOD/material budgets appropriate for Android/Fold, and verify actual runtime vs the image.

## Goal
Create a consistent master character package so a 3D artist/engineer can build ONE rigged Lumo and reuse him across all games.

## Transparent still references — exact filenames
1. lumo_front_neutral.png
2. lumo_back_neutral.png
3. lumo_left_profile.png
4. lumo_right_profile.png
5. lumo_threequarter_front.png
6. lumo_threequarter_back.png
7. lumo_head_closeup.png
8. lumo_hands_gloves_detail.png
9. lumo_boots_detail.png
10. lumo_tail_detail.png
11. lumo_jacket_material_detail.png
12. lumo_goggles_detail.png
13. lumo_backpack_detail.png
14. lumo_scarf_detail.png

## Expression references
15. lumo_face_happy.png
16. lumo_face_proud.png
17. lumo_face_think.png
18. lumo_face_surprised.png
19. lumo_face_concerned.png
20. lumo_face_celebrate.png
21. lumo_face_focus.png
22. lumo_face_laugh.png

## Key-pose references
23. lumo_pose_wave.png
24. lumo_pose_point.png
25. lumo_pose_thumbsup.png
26. lumo_pose_cheer.png
27. lumo_pose_dance_headphones.png
28. lumo_pose_card_hold.png
29. lumo_pose_puzzle_place.png
30. lumo_pose_compass_check.png
31. lumo_pose_build_rotate.png
32. lumo_pose_kart_driver.png

## Animation sequences
Produce numbered frame references, same camera/scale:
- idle_breathe_01..08
- walk_01..08
- run_01..08
- jump_start_01..04
- jump_air_01..04
- land_01..04
- turn_left_01..06
- turn_right_01..06
- dance_01..12
- celebrate_01..08
- card_play_01..08
- puzzle_pick_place_01..10
- treasure_open_01..10
- build_pick_rotate_place_01..12

Optional: compile each sequence into preview WebP/GIF for visual review only.

## 3D implementation prompt
Build one production GLB/glTF Lumo with Skeleton, Skinned Mesh, eye/jaw/mouth or facial blend shapes where feasible, separate material slots, secondary motion for ears/tail/scarf/backpack, AnimationTree/StateMachine blend transitions and no foot sliding. Use the still/sequence references only to model and animate; do not ship sprite substitutions where 3D movement is required.
