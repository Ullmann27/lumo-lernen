# LUMO Kart — extended courses, rival finish and readable items

This work belongs to the LUMO project and its own development branch. Its source
baseline is `9f8341494ea316c9e36ed6722915ab34b22e67bd`, from
`integration/lumo-complete-native-20261114-7a1`.

## Result

The eleven courses following Sonnenhafen now have individually authored routes
of approximately 1.96–2.04 km, with a continuous themed passage and a real descent
and ascent in the shared driving curve. Sonnenhafen retains its existing
1,851.68 m route. Grounded courses travel through covered hills; the sky, city,
space and laboratory settings use galleries appropriate to their worlds.

The actual runtime rivals have species-specific heads, coats, muzzles, tails and
suit palettes. Nova's rabbit eyes are smaller and shallower, with seated iris
surfaces. All fourteen chassis receive additional coachwork, cockpit and wheel
details while retaining their mechanical anchors and collision dimensions.
The original imported Lumo character, textures, rig and animations are unchanged.

Three original, solid item emblems replace ambiguous color-only rival orbs:
gold wind arrow, cyan shield and violet pulse. The same emblems appear together
on every universal skill gate. The gate does not promise a fixed reward: the
existing line/speed/drift scoring still chooses it. Road placement stays fixed;
only descendants animate. Race state now owns the rival effect clock.

## Integration

| Area | Runtime connection |
|---|---|
| Routes | `kart_tracks.gd` and `kart_expansion_tracks.gd` supply the authored controls to the existing curve, road sampling, physics and checkpoints. |
| Passages | `kart_world.gd` builds `AdventureTunnel` in all three world-build branches. The action planner reserves its span before placing kickers, dives or open edges. |
| Outdoor scenery | Forest clusters, city blocks and expansion scenery follow the longer road. Outdoor dressing skips reserved tunnel spans. |
| Drivers and chassis | `kart_vehicle.gd` connects the species finish and coachwork helpers before the existing static batching and LOD construction. |
| Imported future rivals | The real visual adapter validates and instantiates approved local skinned GLBs. Pending roster entries remain disabled. |
| Items | `kart_island.gd` calls `RESONANCE.advance_ring` and advances each rival FX once per active physics update. Pause, preview, menus and finished races stop that clock. |

The detailed [track handoff](TRACKS.md) contains measured lengths, passage names
and driving evidence. The [rival asset handoff](RIVAL_ASSET_HANDOFF.md) specifies
the actual model/rig/animation contract for the separate asset-production team.

## Verified behavior

- All twelve unchanged curve contracts pass: closed seam, road projection,
  banking, lane separation, curve radius and eight checkpoints.
- All eleven new worlds build; their passage geometry passes both detail levels,
  clearance, descent/ascent, action separation and front-face winding checks.
- Real production physics completed two laps and sixteen ordered checkpoints
  per course, with zero resets: twenty-four laps and 192 checkpoints in total.
  The first ten per-course results were completed before that long process was
  terminated; Desert and Lab passed in a fresh process with a clean final marker.
- The bounded Godot tunnel raster test passes six interior views with active
  backface culling, plus six hidden-shell negative controls.
- Existing item award, use, one-per-lap and save-key behavior passes. Actual
  island tests also cover exactly one FX update, pause, reduced motion and
  preservation of banked gate transforms.
- Held symbols and their hover rail clear the actual rabbit/glider mesh by at
  least 0.143 m, including the lowest animation bob.
- All fourteen chassis pass the existing detail/contact gate. The procedural
  steering test covers 16,280 measurements, with worst glove error 0.278 mm.
- The original imported Lumo cadence/contact suite passes 1,196 checks. The new
  rival adapter suite passes 46 checks, including repeated per-frame runtime
  state calls at 60 and 144 Hz and 30 animation evaluations per second.

These results use Godot 4.6.3 on the local desktop environment. They do not
establish Android GPU frame time or a newly installed APK. Revised near rival
geometry costs approximately 9–11% more triangles; distant karts retain their
batched proxy and omit the new wheel microdetails.

## Visual evidence and reproducibility

The actual product driver/item stage and the tunnel-only review stage use Godot
framebuffer capture. The tunnel review uses bounded production geometry with
studio lighting. The latter is distinct from a full race screenshot. Attempts
to render the complete large world in local software GL ended with signal 9;
those attempts are not accepted visual or performance evidence.

`scripts/tests/kart_adventure_asset_export.gd` exports and re-imports actual
visible runtime geometry. Vehicles are static snapshots, not exported rigs or
new animation systems. Standard PBR materials are retained; unsupported road
shaders receive a declared portable material approximation in the export
manifest. Gameplay, collision and procedural animation remain in Godot.

The export copies explicitly convert sRGB vertex colors to linear RGB and retain
alpha. Exported emissive factors are checked against the source materials and
written in linear RGB, while their strength and binary geometry chunk are
preserved. This prevents pale suits, tyres and item accents in Blender without
altering runtime materials. The color convention follows the
[glTF 2.0 specification](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html).

Tunnel export uses a real rendering backend: Godot's headless dummy backend does
not retain usable MultiMesh transform/color readback. The exporter rejects that
backend for tunnel/all mode before creating output files. Its bounded tunnel
scene keeps the actual road ribbons, nearby road instances and themed passage;
instance transforms are checked before writing. The camera and optional studio
light points are sampled from the existing driving curve. They do not add game
lighting or alter the course.

```sh
godot --headless --path . --script res://scripts/tests/kart_adventure_asset_export.gd -- --mode=items --output=/absolute/output/models
godot --headless --path . --script res://scripts/tests/kart_adventure_asset_export.gd -- --mode=vehicles --output=/absolute/output/models
python3 tools/run_local_renderer.py --display 120 --output /absolute/output/tunnel-export-qa --timeout 240 -- --script res://scripts/tests/kart_adventure_asset_export.gd -- --mode=tunnel --track-id=crystal_canyon --output=/absolute/output/models
blender -b --python-exit-code 1 --python tools/art/render_kart_adventure.py -- --input /absolute/output/models --output /absolute/output/blender-items --mode items --samples 96 --animate
blender -b --python-exit-code 1 --python tools/art/render_kart_adventure.py -- --input /absolute/output/models --output /absolute/output/blender-vehicles --mode vehicles --samples 96
blender -b --python-exit-code 1 --python tools/art/render_kart_adventure.py -- --input /absolute/output/models --output /absolute/output/blender-tunnel --mode tunnel --track-id=crystal_canyon --samples 64
```

The isolated renderer command requires an unused display number and a new QA
output directory. An existing desktop can instead run the export script with
Godot's normal Compatibility renderer and without `--headless`.

The Blender scenes retain the exported product meshes. Review lighting, cameras,
floor and display plinths are presentation elements. The optional item loop is
a studio preview of the real geometry, not a recording of an earned gameplay
event. Blender files, images, clips and export manifests are supplied separately
with the review package; the repository contains their reproducible source.
The item review uses Standard color display for clear hue separation; vehicles
use AgX. The tunnel uses broad studio lamps, bounded light paths and Blender's
albedo-guided bilateral compositor to reduce CPU sampling noise while retaining
part boundaries. This review setup does not change the game's materials or
lighting. The saved Blender scene includes those settings for inspection.
