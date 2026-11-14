extends RefCounted
## Physically modelled, reusable LUMO Kart roadside parts.
## Decoration only: no CollisionObject3D, Item award, modified road or checkpoints.
## All primitives are fed into the production world's spatial MultiMesh batching.

const TUNNELS = preload("res://scripts/games/kart_adventure_tunnels.gd")
const SAFETY_LATERAL_M: float = 8.25
const GANTRY_TOP_M: float = 8.5
const MIN_GAP_M: float = 25.0
const LOW_CANDIDATES: int = 8
const HIGH_CANDIDATES: int = 13

static func candidate_distances(length_m: float, low_detail: bool) -> PackedFloat32Array:
	var result := PackedFloat32Array()
	var count: int = LOW_CANDIDATES if low_detail else HIGH_CANDIDATES
	for index in range(count):
		result.append(length_m * (0.055 + (float(index) + 0.5) * 0.89 / float(count)))
	return result


static func _overlaps(distance: float, start: float, finish: float, padding: float) -> bool:
	return distance >= start - padding and distance <= finish + padding


static func is_safe_site(world, distance: float) -> bool:
	if distance < 32.0 or distance > world.length - 32.0:
		return false
	if TUNNELS.contains(world, distance, MIN_GAP_M):
		return false
	if not world.loop_layout.is_empty():
		if _overlaps(distance, float(world.loop_layout.start), float(world.loop_layout.start) + 70.0, 20.0):
			return false
	for offset in [-15.0, 0.0, 15.0]:
		if world.in_gap(distance + offset):
			return false
	if not world.jump.is_empty() and world.jump.has("ramp_start") and world.jump.has("gap_end"):
		if _overlaps(distance, float(world.jump.ramp_start), float(world.jump.gap_end), 22.0):
			return false
	if not world.action.is_empty():
		for pad: Dictionary in world.action.get("pads", []):
			if _overlaps(distance, float(pad.start), float(pad.end), 13.0):
				return false
		for gate: Dictionary in world.action.get("gates", []):
			if absf(distance - float(gate.distance)) <= 18.0:
				return false
		for kicker: Dictionary in world.action.get("kickers", []):
			if _overlaps(distance, float(kicker.start), float(kicker.take_off) + 10.0, 20.0):
				return false
		for dive: Dictionary in world.action.get("dives", []):
			if _overlaps(distance, float(dive.start), float(dive.end), 22.0):
				return false
		for edge: Dictionary in world.action.get("edges", []):
			if _overlaps(distance, float(edge.start), float(edge.end), 20.0):
				return false
	# A new pylon must be clear of a nearby return leg, not merely its own lane.
	for side in [-1.0, 1.0]:
		if world._near_road(world.position_at(distance, side * SAFETY_LATERAL_M), 7.1):
			return false
	return true


static func planned_sites(world) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var candidates: PackedFloat32Array = candidate_distances(world.length, world.low_detail)
	for index in range(candidates.size()):
		var distance: float = candidates[index]
		if not is_safe_site(world, distance):
			continue
		var side: float = -1.0 if index % 2 == 0 else 1.0
		var kind: String = ["beacon", "service", "signal", "sculpture"][index % 4]
		result.append({"distance": distance, "side": side, "kind": kind})
	return result


static func build(world) -> void:
	var built: Array[Dictionary] = planned_sites(world)
	var before: int = world.decoration_count
	var accent: Color = world.definition.accent
	var trim: Color = accent.lightened(0.28)
	var dark: Color = _dark_color(str(world.track_id))
	for item: Dictionary in built:
		var distance: float = float(item.distance)
		var side: float = float(item.side)
		var basis: Basis = world.frame(distance)
		match str(item.kind):
			"beacon":
				_beacon(world, distance, side, basis, dark, accent, trim)
			"service":
				_service(world, distance, side, basis, dark, accent, trim)
			"signal":
				_gantry(world, distance, basis, dark, accent, trim)
			"sculpture":
				_sculpture(world, distance, side, basis, dark, accent, trim)
	world.set_meta("kart_modular_parts", {
		"revision": 1,
		"track_id": str(world.track_id),
		"low_detail": world.low_detail,
		"sites": built,
		"instance_count": world.decoration_count - before,
		"minimum_lateral_m": SAFETY_LATERAL_M,
		"colliders_added": 0
	})


static func _dark_color(track: String) -> Color:
	match track:
		"sonnenhafen": return Color("244965")
		"zauberwald", "jungle_temple": return Color("28534c")
		"candy_cloud": return Color("66517c")
		"volcano_night": return Color("41303b")
		"winter_sprint": return Color("44667e")
		"desert_drift": return Color("6d513d")
		"galaxy_ringway", "holo_city", "learning_lab": return Color("243856")
		_: return Color("3d4669")


static func _beacon(world, distance: float, side: float, basis: Basis,
		dark: Color, accent: Color, trim: Color) -> void:
	var up: Vector3 = basis.y
	var at: Vector3 = world.position_at(distance, side * 9.1)
	world._prop("cylinder", at + up * 0.09, Vector3(1.55, 0.18, 1.55), dark, basis)
	world._prop("cylinder", at + up * 0.23, Vector3(1.28, 0.12, 1.28), trim, basis)
	world._prop("cylinder", at + up * 1.9, Vector3(0.22, 3.28, 0.22), dark.lightened(0.12), basis)
	world._prop("crystal", at + up * 3.93, Vector3(0.58, 1.28, 0.58), accent, basis, true)
	world._prop("torus", at + up * 3.9, Vector3(1.28, 1.28, 1.28),
		trim, basis * Basis(Vector3.RIGHT, PI * 0.5), true)
	for direction in [-1.0, 1.0]:
		world._prop("box", at + basis.x * direction * 0.28 + up * 1.75,
			Vector3(0.10, 2.7, 0.10), accent.darkened(0.23), basis)
	if not world.low_detail:
		for level in range(3):
			world._prop("box", at + up * (0.75 + level * 0.65) + basis.z * 0.19,
				Vector3(0.32, 0.07, 0.06), trim, basis, true)


static func _service(world, distance: float, side: float, basis: Basis,
		dark: Color, accent: Color, trim: Color) -> void:
	# Everything in this small service/display island is outside the safety rail.
	var at: Vector3 = world.position_at(distance, side * 13.7)
	var up: Vector3 = basis.y
	world._prop("box", at + up * 0.18, Vector3(3.1, 0.38, 3.4), dark, basis)
	world._prop("box", at + up * 0.42, Vector3(2.78, 0.10, 2.98), dark.lightened(0.18), basis)
	for x in [-1.12, 1.12]:
		world._prop("box", at + basis.x * x + up * 1.45 + basis.z * 0.94,
			Vector3(0.16, 2.10, 0.18), dark, basis)
	world._prop("box", at + basis.z * 0.94 + up * 2.5,
		Vector3(2.72, 0.20, 0.18), trim, basis)
	world._prop("box", at + up * 1.65,
		Vector3(2.15, 1.40, 0.16), dark.darkened(0.35), basis)
	world._prop("box", at + up * 1.65 + basis.z * 0.11,
		Vector3(1.93, 1.18, 0.03), accent.darkened(0.38), basis, true)
	for i in range(3):
		world._prop("box", at + basis.x * (-0.58 + 0.58 * i) + up * (1.45 + i * 0.10) + basis.z * 0.15,
			Vector3(0.39, 0.055 + i * 0.17, 0.04), trim, basis, true)
	if not world.low_detail:
		for i in range(4):
			world._prop("cylinder", at + basis.x * (-1.03 + i * 0.68) + up * 0.58 - basis.z * 1.22,
				Vector3(0.12, 0.20, 0.12), accent, basis, true)


static func _gantry(world, distance: float, basis: Basis,
		dark: Color, accent: Color, trim: Color) -> void:
	var up: Vector3 = basis.y
	var center: Vector3 = world.position_at(distance)
	for side in [-1.0, 1.0]:
		var at: Vector3 = world.position_at(distance, side * 8.5)
		world._prop("box", at + up * 4.2, Vector3(0.42, 8.4, 0.56), dark, basis)
		world._prop("box", at - basis.x * side * 0.31 + up * 4.85,
			Vector3(0.08, 5.9, 0.12), accent, basis, true)
		world._prop("cylinder", at + up * 0.18, Vector3(1.08, 0.30, 1.08), dark.lightened(0.13), basis)
	world._prop("box", center + up * GANTRY_TOP_M,
		Vector3(17.5, 0.52, 0.70), dark, basis)
	world._prop("box", center + up * (GANTRY_TOP_M + 0.32),
		Vector3(16.8, 0.10, 0.52), trim, basis, true)
	for index in range(5):
		var x: float = -5.1 + float(index) * 2.55
		world._prop("star", center + basis.x * x + up * (GANTRY_TOP_M - 0.44),
			Vector3(0.44, 0.43, 0.10), accent if index % 2 == 0 else trim, basis, true)
	if not world.low_detail:
		world._prop("box", center + up * (GANTRY_TOP_M - 0.56),
			Vector3(14.1, 0.06, 0.09), accent.darkened(0.22), basis)


static func _sculpture(world, distance: float, side: float, basis: Basis,
		dark: Color, accent: Color, trim: Color) -> void:
	var up: Vector3 = basis.y
	var at: Vector3 = world.position_at(distance, side * 11.75)
	world._prop("cylinder", at + up * 0.15, Vector3(2.0, 0.30, 2.0), dark, basis)
	world._prop("cylinder", at + up * 0.35, Vector3(1.65, 0.12, 1.65), trim, basis)
	world._prop("cylinder", at + up * 1.1, Vector3(0.40, 1.4, 0.40), dark, basis)
	world._prop("ball", at + up * 2.48, Vector3(1.28, 1.28, 1.28), accent.darkened(0.27), basis)
	world._prop("torus", at + up * 2.48, Vector3(2.6, 2.6, 2.6),
		accent, basis * Basis(Vector3.RIGHT, PI * 0.5), true)
	world._prop("torus", at + up * 2.48, Vector3(2.48, 2.48, 2.48),
		trim, basis * Basis(Vector3.FORWARD, PI * 0.4), true)
	if not world.low_detail:
		for spoke in range(6):
			var angle: float = TAU * float(spoke) / 6.0
			var offset: Vector3 = basis.x * cos(angle) * 0.91 + basis.z * sin(angle) * 0.91
			world._prop("ball", at + up * 2.48 + offset, Vector3.ONE * 0.14,
				trim, basis, true)
