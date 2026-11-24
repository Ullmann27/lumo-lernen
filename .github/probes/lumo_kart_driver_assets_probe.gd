extends SceneTree

var failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _require(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("[DriverAPK] " + message)


func _run() -> void:
	var arguments := OS.get_cmdline_user_args()
	if arguments.size() != 2:
		push_error("Expected source inventory and result paths")
		quit(2)
		return
	var expected: Variant = JSON.parse_string(FileAccess.get_file_as_string(arguments[0]))
	if not expected is Dictionary or not expected.get("source_files") is Array:
		push_error("Invalid driver source inventory")
		quit(2)
		return
	var files: Array = expected["source_files"]
	_require(files.size() == 27, "Exactly 27 production driver scenes are required")
	var manifest_hash := FileAccess.get_sha256("res://" + str(expected["source_manifest"]))
	_require(manifest_hash == str(expected["source_manifest_sha256"]),
		"The packaged driver manifest differs from the verified source manifest")
	if failures != 0:
		quit(1)
		return
	var scenes: Array[Dictionary] = []
	for entry: Dictionary in files:
		var relative := str(entry["file"])
		var packed := load("res://" + relative) as PackedScene
		_require(packed != null, "Packaged scene missing: " + relative)
		if packed == null:
			continue
		var actor := packed.instantiate()
		var skeletons := actor.find_children("*", "Skeleton3D", true, false)
		var players := actor.find_children("*", "AnimationPlayer", true, false)
		var meshes := actor.find_children("*", "MeshInstance3D", true, false)
		var rig: Skeleton3D = skeletons[0] as Skeleton3D if skeletons.size() == 1 else null
		var expected_bones: Array = entry["bones"]
		_require(rig != null and rig.get_bone_count() == expected_bones.size(),
			"Packaged skeleton bone count differs from the source manifest: " + relative)
		var bone_names: Array[String] = []
		for bone: String in expected_bones:
			var present: bool = rig != null and rig.find_bone(bone) >= 0
			_require(present, "Packaged bone " + bone + " missing: " + relative)
			if present:
				bone_names.append(bone)
		var player: AnimationPlayer = players[0] as AnimationPlayer if players.size() == 1 else null
		var clips: Array[String] = []
		for clip: String in entry["clips"]:
			var present: bool = player != null and player.has_animation(clip)
			_require(present, "Packaged animation " + clip + " missing: " + relative)
			if present:
				clips.append(clip)
		var skinned_meshes := 0
		var albedo_surfaces := 0
		for node: Node in meshes:
			var mesh_instance := node as MeshInstance3D
			if mesh_instance.skin != null:
				skinned_meshes += 1
			if mesh_instance.mesh == null:
				continue
			for surface in range(mesh_instance.mesh.get_surface_count()):
				var material := mesh_instance.get_active_material(surface) as BaseMaterial3D
				if material != null and material.albedo_texture != null and material.albedo_texture.get_width() > 0:
					albedo_surfaces += 1
		_require(skinned_meshes > 0, "Packaged skinned mesh missing: " + relative)
		_require(albedo_surfaces > 0, "Packaged Meshy albedo texture missing: " + relative)
		scenes.append({"file": relative, "bones": rig.get_bone_count() if rig != null else 0, "bone_names": bone_names,
			"clips": clips, "skinned_meshes": skinned_meshes, "albedo_surfaces": albedo_surfaces})
		actor.free()
	var report := FileAccess.open(arguments[1], FileAccess.WRITE)
	if report == null:
		push_error("Cannot write the packaged driver report")
		quit(2)
		return
	report.store_string(JSON.stringify({"status": "PASS" if failures == 0 else "FAIL",
		"source_manifest_sha256": manifest_hash, "scenes": scenes, "failures": failures}, "\t") + "\n")
	report.close()
	if failures == 0:
		print("KART_DRIVER_PCK_PASS: 27 production variants loaded from the actual APK pack")
	quit(int(failures != 0))
