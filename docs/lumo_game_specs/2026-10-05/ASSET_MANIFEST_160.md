# LUMO — 160+ Asset Production Manifest

This manifest is a production brief for image/model-reference generation. It does NOT authorize using flat PNGs as fake 3D geometry. Transparent renders are references for modeling, materials, UI and animation. Real free-moving characters/vehicles/environment pieces require actual 3D assets (prefer GLB/glTF 2.0) with proper topology, UVs, materials, collisions and, for Lumo, skeleton/skinning/animation clips.

## Global visual target
Premium family-friendly 3D game art, original LUMO IP, mobile-optimized AAA-inspired presentation: deep midnight blue, cyan luminous accents, warm gold reward light, believable materials, soft volumetric moonlight, high depth, clean readable silhouettes, polished but not photorealistic-human, suitable for children 6–10.

Lumo identity MUST remain constant:
young orange fox, white muzzle/chest/tail tip, large warm brown eyes, blue aviator goggles on forehead, dark navy adventure/racing jacket with orange-white trim and glowing cyan L emblem, black gloves when gameplay calls for them; optional scarf/backpack only when the corresponding game reference requires it.

## Render rules
- Character/prop/model reference renders: transparent background, 2048×2048 PNG, full object visible, no crop, no text, orthographic-ish or 3/4 production view, neutral studio lighting plus subtle cyan rim light.
- Animation reference frames: same camera, same proportions, same costume, same scale, one pose per frame; export numbered PNGs. A GIF/WebP preview may be produced, but runtime animation must come from a rigged 3D model, not the GIF.
- Background/key art: no UI, no buttons, no labels unless a world-sign is explicitly part of the set; 16:9 landscape 2400×1350 plus 3:2 or 4:3 tablet variant.
- Track/world kit assets: transparent turntable-style renders are reference only; engineer recreates them as real modular 3D meshes.
- Never declare reference matched until exact runtime screenshot vs target is compared.

## Asset count overview
- 00 Master Lumo: 32
- 01 Spielwelt Hub: 18
- 02 Memory: 14
- 03 Lumo Cards: 14
- 04 Puzzle: 14
- 05 Jump & Run: 18
- 06 Rhythm Party: 14
- 07 Schatzsuche: 14
- 08 Bauwelt: 14
- 09 Lumo Kart: 30+
Total: 178+ requested production references.

## Required implementation behavior
For every generated reference asset:
1. save with the exact filename from the per-folder brief;
2. add source/provenance note;
3. wire only after checking it fits the target screen;
4. do not stretch/crop a portrait background to fake a Fold/landscape target;
5. do not use a static Lumo image as the final solution where movement/turning/interaction is required;
6. add runtime screenshot after integration;
7. if exact visual gap remains, mark VISUAL_GAP / NOT FINISHED.
