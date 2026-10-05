# 09 LUMO KART — 30+ Track / Vehicle / World Asset Prompt

## Shared generation prefix
"Original LUMO game asset, premium family-friendly 3D render, AAA-inspired mobile game quality, deep midnight-blue/cyan/gold art direction, soft volumetric lighting, clean readable silhouette, physically believable but stylized materials, child-safe, no third-party brand language, no copyrighted franchise styling."

## Technical handoff
Each generated render is a MODEL/ART REFERENCE unless explicitly listed as a background. The implementer must convert reference objects to proper runtime assets, keep collision/LOD/material budgets appropriate for Android/Fold, and verify actual runtime vs the image.

## Vehicle / driver transparent references
1. kart_lumo_blue_front.png
2. kart_lumo_blue_back.png
3. kart_lumo_blue_left.png
4. kart_lumo_blue_right.png
5. kart_lumo_blue_threequarter.png
6. kart_wheel_neon.png
7. kart_boost_exhaust.png
8. kart_drift_sparks.png
9. kart_shield_item.png
10. kart_star_item.png

## WORLD A — HIMMELSINSELN
11. skyisland_track_module_straight.png
12. skyisland_track_module_curve.png
13. skyisland_track_module_hairpin.png
14. skyisland_track_module_ramp.png
15. skyisland_guardrail_cyan.png
16. skyisland_waterfall_tower.png
17. skyisland_castle_landmark.png
18. skyisland_bridge_landmark.png
19. skyisland_cloud_arch.png
20. skyisland_checkpoint_gate.png

Background: bg_kart_skyislands_wide.png — no UI, reference-matched k07-style depth: large foreground track, multiple vertical island tiers, dominant waterfalls, castle/city silhouette, cyan/gold lighting.

## WORLD B — LICHTERSTADT
21. city_track_straight.png
22. city_track_bank_curve.png
23. city_tunnel_neon.png
24. city_glass_tower.png
25. city_holo_sign_generic.png
26. city_checkpoint_gate.png

Background: bg_kart_city_wide.png — futuristic original Lumo city, no third-party signage.

## WORLD C — WISSENSWALD
27. forest_track_curve.png
28. forest_tree_glow.png
29. forest_library_arch.png
30. forest_bridge_root.png
31. forest_crystal_cluster.png
32. forest_checkpoint_gate.png

Background: bg_kart_forest_wide.png.

## WORLD D — SONNENHAFEN
33. harbor_track_coast.png
34. harbor_pier_module.png
35. harbor_lighthouse.png
36. harbor_boat_prop.png
37. harbor_market_arch.png
38. harbor_checkpoint_gate.png

Background: bg_kart_harbor_wide.png.

## WORLD E — KRISTALLHÖHLEN
39. cave_track_module.png
40. cave_crystal_wall.png
41. cave_crystal_pillar.png
42. cave_bridge.png
43. cave_mist_vent.png
44. cave_checkpoint_gate.png

Background: bg_kart_caves_wide.png.

## WORLD F — MONDTEMPEL
45. temple_track_stairslope.png
46. temple_gate.png
47. temple_column.png
48. temple_moon_statue.png
49. temple_bridge.png
50. temple_checkpoint_gate.png

Background: bg_kart_moon_temple_wide.png.

## Track implementation prompt
Each world must be a genuinely different drivable 3D route, not the same spline with a different wallpaper. Build modular road mesh, collision, bank/guardrails, landmarks, checkpoints, shortcuts, recovery zones, camera-safe geometry and readable racing line. Match the corresponding reference image in runtime composition/light/material density. No learning questions in-race.

## Proof gate
For each track: start-line screenshot, representative mid-lap screenshot, landmark screenshot, finish screenshot, full-lap telemetry, checkpoint order, reset/shortcut/reverse-finish test. If visual gap remains, NOT FINISHED.
