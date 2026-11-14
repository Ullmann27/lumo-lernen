# LUMO Kart — Modular 3D Track Parts & Chassis Aero Kit (14 November 2026)

## Current result and scope
Real source-connected geometry, added on `chatgpt/lumo-kart-modular-parts-20261114` from the already tested `chatgpt/lumo-kart-adventure-20261114-a839` branch. No external Nintendo geometry, no new paid dependencies, no change to the original characters, rigs, race rewards, route coordinates, saves or vehicle collision model.

### New, actually wired parts
- **Four reusable roadside families:** floating wayfinding beacons (crystal/torus), illuminated service platforms with real panels and raised control lamps, open-road high-clearance signal gantries with star-shaped markers, and gyroscopic track sculptures.
- **Theme-specific palettes** from each of the twelve course definitions, augmented with the selected course's own dark support material.
- **14 existing fleet chassis** use the shared aero-kit hook in `kart_vehicle.gd` before static batching and LOD generation; the four representative bodies (Comet, Glider, Terra, Phantom) are checked by the new regression.
- **Kart manufactured finishes**: pairwise aerodynamic sill assemblies and LED accents; inset nose intakes with individually moulded vanes; machined exhaust bezels and energy rings; raised nose chevrons; an integrated rear bumper cap.
- No new collision or gameplay triggers. The loop, ramps, jumps, action pads, rival AI and item scoring remain authoritative.

### Production integration
`kart_world.gd` calls `kart_modular_route_props.gd` in **all three** world-build branches (Himmelsinseln, expansion tracks, original world). The parts are submitted to the existing 48 m-cell `_prop` and `_flush_instances` GPU MultiMesh batches. Mobile builds use eight candidate sites per course and fewer decorative details; high-detail builds use thirteen. Actual placement skips the protected tunnel corridor, bridge-like action zones, jumps, open edges and nearby return roads.

`kart_vehicle.gd` calls `kart_modular_aero_kit.gd` immediately after the established coachwork pass. Near-only microdetails have disabled shadow casting and retain the existing LOD/far proxy mechanism.

### Quality gates
`scripts/tests/kart_modular_parts_regression.gd` is source-bound to the genuine production classes and checks:
- 12 mobile tracks + 2 full-detail tracks; planned physical site clearance and batched runtime geometry;
- Original safety rail, no added scenery colliders, no track/physics edits;
- 14 catalog styles retained; four representative live chassis with their four wheel pivots and bounded aero components.

CI workflow `.github/workflows/lumo-kart-modular-parts.yml` runs actual Godot 4.6.3 import and regression. Evidence is tied to the exact branch commit. On this chat's execution host, Godot/Blender executables are unavailable, so no local engine render or Fold7 frame time is asserted before the CI or device results arrive.

### How to run
```bash
godot --headless --editor --import --path .
godot --headless --path . --script res://scripts/tests/kart_modular_parts_regression.gd
```

This is a development branch, not a merged Android APK. Godot source assets can be included in the existing LUMO Flutter/Godot release pipeline after green regression and real Android Fold7 checks.
