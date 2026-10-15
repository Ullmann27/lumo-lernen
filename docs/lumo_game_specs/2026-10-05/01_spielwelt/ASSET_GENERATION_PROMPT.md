# 01 SPIELWELT — 3D Hub Asset Prompt

## Shared generation prefix
"Original LUMO game asset, premium family-friendly 3D render, AAA-inspired mobile game quality, deep midnight-blue/cyan/gold art direction, soft volumetric lighting, clean readable silhouette, physically believable but stylized materials, child-safe, no third-party brand language, no copyrighted franchise styling."

## Technical handoff
Each generated render is a MODEL/ART REFERENCE unless explicitly listed as a background. The implementer must convert reference objects to proper runtime assets, keep collision/LOD/material budgets appropriate for Android/Fold, and verify actual runtime vs the image.

## Opaque backgrounds / key art
- bg_spielwelt_wide.png — 16:9, no UI, moon, castle silhouette, floating islands, waterfalls, cyan paths, warm lanterns, clear center space for Lumo and portals.
- bg_spielwelt_tablet.png — 3:2/4:3 composition, same world identity, no crop/stretch hack.

## Transparent modular reference assets
1. hub_island_large.png
2. hub_island_small.png
3. hub_waterfall_tall.png
4. hub_waterfall_wide.png
5. hub_stone_bridge.png
6. hub_neon_bridge.png
7. hub_castle_gate.png
8. hub_library_portal.png
9. hub_memory_portal.png
10. hub_cards_portal.png
11. hub_puzzle_portal.png
12. hub_jump_portal.png
13. hub_rhythm_portal.png
14. hub_treasure_portal.png
15. hub_build_portal.png
16. hub_kart_portal.png
17. hub_lantern_cluster.png
18. hub_cyan_crystal_cluster.png

## Implementation prompt
Build a real navigable 3D hub from modular meshes. Portals must be real interactive objects, not baked UI in a background. Support touch camera/orbit or guided navigation, readable focus states and Fold/Phone framing. Use generated wide backgrounds only as far-distance sky/world backdrop if needed.
