# Original Lumo — facial derivative, 14 November 2026

This asset derives from `assets/characters/lumo_animated/Lumo-Animated-Mobile.glb`, whose attribution is preserved unchanged in `../lumo_animated/ATTRIBUTION.md`. That source is the existing Lumo model generated in Meshy from the user-authorized reference `50137.jpeg` on 10 October 2026, subsequently rigged and animated locally. No replacement character or third-party character design was generated for this facial extension.

- Original generation provider: [Meshy](https://www.meshy.ai/).
- License recorded for the existing model: [Creative Commons Attribution 4.0 International](https://creativecommons.org/licenses/by/4.0/).
- Original Lumo source SHA-256: `62700aee1f4ea1d7b53ee8058be05493fc68e8d61465c0ca23315e21d71d240a`.
- Unchanged Smart-Rig source SHA-256: `983f0d17ecaabfcd50d1b6244c04d54771dbdc45cfd1c37926acf437637f48dd`.
- Animated mobile source SHA-256: `3559f700784bc1006905ee3aae01e8bcfbffb95b4f621f7430ce771ba0e3efd5`.
- Facial derivative SHA-256: `e14aea79eb9918f5184c8ded64e8c1343bf71f553772a4f59298ada6862d9524`.

## Changes in this derivative

Locally authored in Blender 4.3.2: restrained left/right/up/down morphs on the original painted eye surface, a closed-muzzle jaw articulation morph, and physical head-skinned eyelids fitted to measured original triangle/UV contours. The eyelid mesh contains two material surfaces, 2,368 vertices and 4,320 triangles, with four curved closure stages for each eye. The original body attributes, UVs, materials, embedded textures, 65-bone skin and nine original animation clips remain intact; the six separate Studio body-motion clips remain unchanged. New body and eyelid weights are zero in the neutral asset.

The existing painted eyes remain part of the original continuous mesh. These are restrained surface deformations, not independent anatomical eyeballs. The original model has no mouth cavity; the jaw morph articulates the closed muzzle. Speech amplitude from actual local playback can drive this morph, but it is not phoneme-based lip synchronization or a set of visemes.

The Godot import sidecar retains body LOD generation and disables generated LODs only on `Lumo-Facial-Mobile_LumoEyelids`: reducing the collapsed neutral lid mesh produced visible holes during morphing. Preserve this sidecar with the GLB.

Preserve this attribution, the upstream modification notice and license URL when distributing this derivative. No endorsement by Meshy is implied. Local Blender/Godot evidence and JVM boundary tests do not constitute physical Android, Fold7, sound-output or 60-FPS acceptance.
