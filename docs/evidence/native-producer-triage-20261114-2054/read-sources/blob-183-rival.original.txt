# LUMO Kart — rival GLB handoff

**Contract date: 2026-11-14. Target: Godot 4.6.3.** This describes the implemented importer, not a claim that the reference characters have been delivered. The five reference identities are `lion`, `owl`, `rabbit` (Nova), `squirrel` and `turtle`; their current `runtimeReady` flags remain `false`.

Authoritative code: `scripts/games/kart_rival_model_contract.gd`, `kart_rival_visual_adapter.gd`, `lumo_opponent_roster.gd` and `kart_vehicle.gd`. Existing files in `lumo-kart-production/models-final` are static snapshots of the current procedural product geometry. They contain no skins or animation clips and are placement/review references, not replacement driver rigs.

## 1. Coordinates and seated placement

Deliver the character alone at `res://assets/characters/rivals/<id>/driver.glb`. Use metres, **Godot Y up, -Z forward, +X to the driver's right**. The root is already in kart-local space: the adapter adds no automatic scale, translation, turn or standing-to-seated retarget. Keep the character root transform identity and bake any required fitting into the authored asset/rig.

For Blender authoring, `(x, y, z)` in Godot corresponds to `(x, -z, y)` in Blender. Thus the kart's front faces Blender +Y. Export the standard glTF Y-up conversion once; do not apply a second 90-degree correction.

The actual current contact references are:

| Reference | Godot kart-local metres / transform |
|---|---|
| Steering-wheel centre | `(0, 1.035, -0.330)` |
| Wheel rest tilt | X rotation `-0.45` radians |
| Left/right glove contact centres at rest | `(-0.160, 1.055, -0.340)` / `(0.160, 1.055, -0.340)` |
| Wheel-local contact points, approximately | `(±0.160, 0.022360, -0.000305)` |
| Wheel steering | Z rotation `-steer * 0.40`, where `steer` is in `[-1, 1]` |
| Shoulder joint references | `(±0.290, 1.215, 0.015)` |
| Boot centres | `(±0.180, 0.800, -0.240)` |
| Sole centres / bottom | `(±0.180, 0.742, -0.240)` / bottom Y `0.716` |
| Pedal centres / top | `(±0.180, 0.689, -0.240)` / top Y `0.7115` before the chassis width transform |
| Seat cushion | Centre `(0, 0.690, 0.070)`; top approximately Y `0.780` |
| Existing head pivot, for scale reference | `(0, 1.680, 0.070)` |

The authoritative moving hand targets are `steering_wheel.global_transform * wheel_rest_grips[index]`. Pedals belong to `AuroraCoachwork`; some fleet variants scale that parent's X axis, so inspect the actual selected chassis instead of assuming every pedal world X is exactly ±0.180. Keep boots inside the footwell and below the wheel; preserve the clear bonnet and seat envelope.

**Current limitation:** the rival adapter plays authored seated/steering clips. It does not infer hand bones, perform IK, continuously blend steering poses or enforce contact geometrically. Left/right clips are selected when `abs(steer) > 0.30`; otherwise it selects `kart_seated`. Review hands and feet at neutral, partial and full steering before activating a delivery. Machine validation alone does not certify pose fit.

## 2. Rig and animation contract

A GLB must import as a `PackedScene` with a `Node3D` root, at least one genuinely weighted mesh and a local `Skeleton3D`. Bone names are asset-specific: no Lumo bone-name template is imposed. Every animation bone path must resolve to an existing bone in that model's skeleton.

| Clip basename | Required / behaviour |
|---|---|
| `kart_seated` | Required; finite positive duration, with at least one keyed skeletal transform track. Frame/time zero must already be a complete seated pose. |
| `kart_steer_left` | Optional; selected for steering below `-0.30`. |
| `kart_steer_right` | Optional; selected for steering above `0.30`. |
| `kart_hit` | Optional; short reaction to a real hit edge, held for at most one second. |
| `kart_celebrate` | Optional; seated finish celebration. |

A library prefix such as `Rival/kart_seated` is accepted. Put the required and optional clips in the same `AnimationPlayer`. Unknown clips are not selected. Missing or rejected optional clips fall back to `kart_seated`. Keep clips in place: no root movement that pulls the driver out of the vehicle. The adapter can restart a completed selected clip while its state persists; author sustained steering/idle poses and celebrations accordingly.

Accepted enabled tracks are position, rotation and scale 3D tracks plus blend-shape tracks. Paths must remain inside the imported model; each accepted clip must include actual keyed bone animation. Method/value/audio tracks are rejected for selected clips. Scene scripts, collision objects, audio-player nodes and `AnimationTree` are rejected. Imported autoplay is disabled. The vehicle owns the single manual 30 Hz visual clock; pause and reduced-motion state come from the real race.

## 3. Geometry and material delivery

These are the **implemented validation limits**, counted across the entire imported model:

| Limit | Enforced value |
|---|---:|
| Triangles | `1…60,000` total; triangle primitives only |
| Material surfaces | At most `16` total across meshes |
| Bones | `1…128` per referenced skeleton |
| Skin binds | `1…128` per skin; each bind resolves to that skeleton |
| Vertex influences | `4` or `8`; finite non-negative weights summing to `0.98…1.02` per vertex |

Preserve a coherent Lumo material hierarchy: matte coat and cloth, restrained eye gloss, distinct nose/boot finishes. Deliver standard glTF PBR materials and embedded images; retain vertex colours where used. Prefer a shared material atlas and opaque fur over overlapping transparent shells. A practical art target is one 2K base-colour/normal/ORM set per character, but **texture dimensions, embedded-image completeness and visual material quality are not enforced by the current contract**. Review them separately on the target device. A Blender still does not establish Android frame rate.

## 4. Validate a supplied GLB without activating the roster

Run from the project checkout. Import newly delivered files first, then use the real contract directly. The temporary checker below does not change `roster.json` or save any scene:

```bash
LUMO_PROJECT=/workspace/scratch/a8392560be8d/lumo-kart
GODOT_BIN=/opt/godot/4.6.3/Godot_v4.6.3-stable_linux.x86_64
"$GODOT_BIN" --headless --editor --path "$LUMO_PROJECT" --import
cat > /tmp/lumo_rival_contract_check.gd <<'GDSCRIPT'
extends SceneTree
const CONTRACT = preload("res://scripts/games/kart_rival_model_contract.gd")
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var paths := OS.get_cmdline_user_args()
	var passed: bool = not paths.is_empty()
	for path in paths:
		if not CONTRACT.model_path_allowed(path) or not ResourceLoader.exists(path, "PackedScene"):
			print("[RivalGLB] FAIL missing/unbounded asset: ", path)
			passed = false
			continue
		var scene := ResourceLoader.load(path, "PackedScene") as PackedScene
		if scene == null:
			print("[RivalGLB] FAIL not a PackedScene: ", path)
			passed = false
			continue
		var model: Node = scene.instantiate()
		var report: Dictionary = CONTRACT.inspect(model)
		report.erase("player")
		report["path"] = path
		passed = passed and bool(report.get("valid", false))
		print("[RivalGLB] ", JSON.stringify(report))
		model.free()
	if passed:
		print("[RivalGLB] PASS")
	quit(0 if passed else 1)
GDSCRIPT
python3 "$LUMO_PROJECT/tools/run_godot_probe.py" \
  --log /tmp/lumo-rival-contract.log --timeout 120 --required '[RivalGLB] PASS' -- \
  "$GODOT_BIN" --headless --path "$LUMO_PROJECT" \
  --script /tmp/lumo_rival_contract_check.gd -- \
  res://assets/characters/rivals/lion/driver.glb \
  res://assets/characters/rivals/owl/driver.glb \
  res://assets/characters/rivals/rabbit/driver.glb \
  res://assets/characters/rivals/squirrel/driver.glb \
  res://assets/characters/rivals/turtle/driver.glb
```

Pass one path to check an individual delivery. The current undelivered set is expected to fail this asset check. Existing implementation regressions are `scripts/tests/kart_rival_visual_adapter_regression.gd` and `lumo_opponent_roster_regression.gd`. The adapter regression deliberately checks the current pending roster and uses in-memory fixture rigs; it is not proof that any external reference asset exists.

## 5. Activation, fallback and original Lumo

`runtimeReady:true` alone is insufficient. `lumo_opponent_roster.racing_scene()` also loads and validates the real GLB. `ready_for_race()` requires **exactly five kart identities and all five usable models**. Only then does `kart_island.gd` switch the race's entire opponent roster to lion/owl/rabbit/squirrel/turtle. A partial delivery leaves the existing otter/rabbit/badger/cat/fox field in use. Time-trial and training modes still create no rivals.

Keep undelivered or rejected entries false. After actual import, pose/contact/material review and runtime checks, activate only the delivered entries. Restart the scene/process when changing assets or readiness because the roster and successful validations are cached. A requested imported visual that cannot bind keeps the existing procedural 3D driver visible. A valid import hides that procedural driver and uses a chassis-only distant proxy, so there is one character rather than two overlapping skins.

**Original Lumo is invariant:** do not overwrite, recolour, rescale, rename bones in, re-rig or replace `assets/characters/lumo_animated` or the original Lumo animation adapter. `set_reference_rival_enabled()` explicitly refuses to replace the fox/player Lumo. The static Blender exports are review deliverables; do not install them as rigged opponent assets or claim their review animation is gameplay animation.
