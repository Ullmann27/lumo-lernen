extends SceneTree
## Runtime regression for the reusable roadside modules and physical chassis aero set.
## Run on the exact integrated Godot project, not on an isolated replacement scene.
const WORLD = preload("res://scripts/games/kart_world.gd")
const TRACKS = preload("res://scripts/games/kart_tracks.gd")
const PARTS = preload("res://scripts/games/kart_modular_route_props.gd")
const VEHICLE = preload("res://scripts/games/kart_vehicle.gd")
const FLEET = preload("res://scripts/games/kart_fleet.gd")
const AERO = preload("res://scripts/games/kart_modular_aero_kit.gd")

func _initialize() -> void:
	call_deferred("_run")


func _check_world(id: String, light: bool) -> Dictionary:
	var world = WORLD.new()
	root.add_child(world)
	world.build(light, id, true)
	var record: Dictionary = world.get_meta("kart_modular_parts", {})
	assert(not record.is_empty(), "Runtime did not call the modular prop builder")
	assert(str(record.track_id) == id, "Wrong course metadata")
	assert(int(record.revision) == 1)
	assert(bool(record.low_detail) == light)
	assert(int(record.colliders_added) == 0)
	assert(float(record.minimum_lateral_m) >= 8.0)
	var sites: Array = record.sites
	assert(sites.size() > 0, "No real modular roadside pieces on " + id)
	assert(int(record.instance_count) >= sites.size() * 5, "Instanced assembly is missing")
	for entry: Dictionary in sites:
		var d: float = float(entry.distance)
		assert(d >= 32.0 and d <= world.length - 32.0)
		assert(absf(float(entry.side)) == 1.0)
		assert(str(entry.kind) in ["beacon", "service", "signal", "sculpture"])
		assert(PARTS.is_safe_site(world, d), "A prop enters a reserved racing section")
		for side in [-1.0, 1.0]:
			var foot: Vector3 = world.position_at(d, side * PARTS.SAFETY_LATERAL_M)
			assert(not world._near_road(foot, 7.1), "Scenery overlaps a return road")
	var batches: int = 0
	for child in world.get_children():
		if child is MultiMeshInstance3D and str(child.name).begins_with("Decor_"):
			batches += 1
	assert(batches > 0, "Props did not enter the actual world MultiMesh renderer")
	var result: Dictionary = {"track": id, "mode": "mobile" if light else "high",
		"sites": sites.size(), "instances": int(record.instance_count), "draw_batches": batches}
	world.free()
	return result


func _check_fleet() -> int:
	assert(FLEET.ids().size() == 14, "Fleet catalog changed")
	var total: int = 0
	for style in ["comet", "glider", "terra", "phantom"]:
		var kart = VEHICLE.new()
		root.add_child(kart)
		kart.configure("fox" if style == "comet" else "rabbit", Color("76bded"), style)
		var body: Node3D = kart.get_node_or_null("AuroraCoachwork")
		assert(body != null, "Original chassis root missing")
		assert(int(body.get_meta("modular_aero_revision", 0)) == 1)
		var parts: int = int(body.get_meta("modular_aero_count", 0))
		assert(parts >= 20 and parts <= 28, "New chassis details absent or unbounded")
		assert(kart.wheel_pivots.size() == 4, "Wheel anchors changed")
		for anchor: Vector3 in AERO.envelope_anchors():
			assert(absf(anchor.x) <= 0.7 and anchor.y < 0.9 and absf(anchor.z) <= 1.19,
				"Additional aero hardware exceeds the original chassis envelope")
		total += 1
		kart.free()
	return total


func _run() -> void:
	var report: Array[Dictionary] = []
	for id in TRACKS.IDS:
		report.append(_check_world(id, true))
	report.append(_check_world("sonnenhafen", false))
	report.append(_check_world("crystal_canyon", false))
	var chassis: int = _check_fleet()
	assert(report.size() == 14 and chassis == 4)
	var path: String = "user://kart_modular_parts_report.json"
	var output := FileAccess.open(path, FileAccess.WRITE)
	assert(output != null)
	output.store_string(JSON.stringify({
		"schema": 1, "engine": Engine.get_version_info().string,
		"routes_checked": report.size(), "chassis_checked": chassis,
		"runtime_source": true, "android_frame_time_verified": false,
		"results": report
	}, "\t"))
	output.close()
	print("[KartModularParts] PASS: 12 mobile tracks + 2 high-detail scenes; four live chassis; no racing/LOD authority changed")
	quit(0)
