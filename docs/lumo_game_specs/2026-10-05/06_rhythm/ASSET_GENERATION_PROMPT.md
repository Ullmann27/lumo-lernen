# 06 RHYTHM PARTY — Asset Prompt

## Shared generation prefix
"Original LUMO game asset, premium family-friendly 3D render, AAA-inspired mobile game quality, deep midnight-blue/cyan/gold art direction, soft volumetric lighting, clean readable silhouette, physically believable but stylized materials, child-safe, no third-party brand language, no copyrighted franchise styling."

## Technical handoff
Each generated render is a MODEL/ART REFERENCE unless explicitly listed as a background. The implementer must convert reference objects to proper runtime assets, keep collision/LOD/material budgets appropriate for Android/Fold, and verify actual runtime vs the image.

## Transparent assets
1. rhythm_stage_main.png
2. rhythm_speaker_left.png
3. rhythm_speaker_right.png
4. rhythm_neon_drum.png
5. rhythm_note_tap.png
6. rhythm_note_hold.png
7. rhythm_note_slide.png
8. rhythm_note_special.png
9. rhythm_combo_burst.png
10. rhythm_perfect_burst.png
11. rhythm_good_burst.png
12. rhythm_miss_soft.png
13. rhythm_lumo_headphones.png
14. rhythm_lumo_dance_pose.png

## Background
- bg_rhythm_stage_wide.png — moonlit holographic concert stage, cyan/gold/violet lighting, no UI.

## Implementation prompt
Beat-synced input lane, tap/hold/slide/special, timing windows, combo, BPM-driven stage pulses, latency calibration, no busy overlays. Lumo dance should be rig animation driven by beat markers, not a looping GIF in final runtime.
