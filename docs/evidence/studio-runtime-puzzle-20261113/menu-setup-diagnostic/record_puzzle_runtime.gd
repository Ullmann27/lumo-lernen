extends SceneTree
## External recorder: production UI, physics picking and touch only.
const FRAMES := 240
const PIECE_ID := 2
const SEED := 20191113
var game
var output := ""
var frames_output := ""
var frame_index := -1
var failures: Array[String] = []
var events: Array[Dictionary] = []
var samples: Array[Dictionary] = []
var initial: Dictionary = {}
var drag_start := Vector2.ZERO
var drag_end := Vector2.ZERO
var last_point := Vector2.ZERO


func _initialize() -> void:
	output = OS.get_environment("LUMO_RUNTIME_EVIDENCE_DIR")
	frames_output = OS.get_environment("LUMO_RUNTIME_FRAMES_DIR")
	_run.call_deferred()


func _check(value: bool, label: String) -> void:
	if not value:
		failures.append(label)
		push_error("[PuzzleRuntimeMovie] " + label)


func _physical(point: Vector2) -> Vector2:
	return point * Vector2(root.size) / root.get_visible_rect().size


func _touch(point: Vector2, pressed: bool, purpose: String) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 21
	event.position = _physical(point)
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	events.append({"frame": frame_index, "kind": "InputEventScreenTouch",
		"finger": event.index, "pressed": pressed, "purpose": purpose,
		"physical_position": [event.position.x, event.position.y]})


func _drag(point: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = 21
	event.position = _physical(point)
	event.relative = event.position - _physical(last_point)
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	last_point = point
	events.append({"frame": frame_index, "kind": "InputEventScreenDrag",
		"finger": event.index, "physical_position": [event.position.x, event.position.y],
		"relative": [event.relative.x, event.relative.y]})


func _settle(count: int = 6) -> void:
	for _frame in range(count):
		await process_frame


func _menu_tap(kind: String) -> void:
	var button: Button
	for child in game.menu_box.get_children():
		if child is Button:
			if (kind == "count" and child.text.ends_with(" Teile")) or child.text.begins_with(kind):
				button = child
				break
	_check(is_instance_valid(button) and button.is_visible_in_tree(), "Menu button visible: " + kind)
	if not is_instance_valid(button):
		return
	var rect: Rect2 = button.get_global_rect()
	_check(root.get_visible_rect().encloses(rect), "Menu touch inside viewport: " + kind)
	var point := rect.get_center()
	_touch(point, true, "setup: " + button.text)
	await _settle(2)
	_touch(point, false, "setup release: " + kind)
	await _settle()


func _piece_point() -> Vector2:
	return game.camera.unproject_position(game.nodes[PIECE_ID].global_position + Vector3.UP * 0.16)


func _schedule() -> void:
	match frame_index:
		24:
			last_point = _piece_point()
			_touch(last_point, true, "select initial half-turned piece")
		28:
			_touch(last_point, false, "retain piece selection for rotate button")
		40, 72:
			_touch(game.rotate_button.get_global_rect().get_center(), true, "press production rotate button")
		43, 75:
			_touch(game.rotate_button.get_global_rect().get_center(), false, "release production rotate button")
		104:
			drag_start = _piece_point()
			last_point = drag_start
			_touch(drag_start, true, "pick correctly rotated piece for dragging")
		106:
			_check(game.dragging == PIECE_ID, "Real ray selection owns the drag")
			var slot: Vector2 = game.model.target(PIECE_ID)
			var offset: Vector2 = game.drag_offset
			drag_end = game.camera.unproject_position(Vector3(slot.x - offset.x, 0.35, slot.y - offset.y))
		178:
			_touch(last_point, false, "release above the real matching slot")
	if frame_index >= 110 and frame_index <= 170:
		var amount := float(frame_index - 110) / 60.0
		_drag(drag_start.lerp(drag_end, smoothstep(0.0, 1.0, amount)))


func _sample() -> void:
	var node: Node3D = game.nodes[PIECE_ID]
	var pos := node.position
	var q := node.quaternion
	samples.append({"frame": frame_index, "capture_time_seconds": float(frame_index) / 24.0,
		"engine_frame_drawn": Engine.get_frames_drawn(), "piece_id": PIECE_ID,
		"position": [pos.x, pos.y, pos.z], "quaternion": [q.x, q.y, q.z, q.w],
		"model_turn": int(game.model.pieces[PIECE_ID].turn),
		"selected_piece": game.selected_piece, "dragging": game.dragging,
		"matching_hover": game.matching_hover, "locked": bool(game.model.pieces[PIECE_ID].locked),
		"placed": game.model.placed(), "moves": game.model.moves, "hints": game.model.hints,
		"status_text": game.status.text})


func _run() -> void:
	if DisplayServer.get_name() == "headless" or output.is_empty() or frames_output.is_empty():
		push_error("[PuzzleRuntimeMovie] Actual renderer and output directories required")
		quit(1)
		return
	seed(SEED)
	root.size = Vector2i(960, 540)
	root.get_node("HostBridge")._options = {
		"displayDensity": 1.0, "soundEnabled": false, "reduceAnimations": false,
		"childKey": "studio-runtime-puzzle-isolated"
	}
	root.get_node("SceneRouter").launch_options = {"childKey": "studio-runtime-puzzle-isolated"}
	game = load("res://scenes/creative/puzzle_world.tscn").instantiate()
	root.add_child(game)
	await _settle(12)
	root.warp_mouse(root.get_visible_rect().size * 0.5)
	await _settle()
	_check(not FileAccess.file_exists(game.save_path), "New isolated profile has no seeded save")
	# The default 12-piece setting cycles 24, 48, 96, 6 through the real menu.
	for _press in range(4):
		await _menu_tap("count")
	await _menu_tap("Modus:")
	await _menu_tap("Neues Puzzle beginnen")
	await _settle(12)
	_check(not game.paused and not game.menu.visible, "Production menu starts the actual puzzle")
	_check(game.model.count == 6 and game.model.motif == 3 and game.model.rotation_enabled,
		"Real menu selects six-piece lighthouse rotation puzzle")
	_check(game.model.placed() == 0 and game.model.moves == 0 and game.model.hints == 0,
		"Recording begins without manufactured progress")
	_check(int(game.model.pieces[PIECE_ID].turn) == 2, "Deterministic source formula starts piece 2 at two quarters")
	initial = game.model.to_data()
	if not failures.is_empty():
		_finish()
		return
	for index in range(FRAMES):
		frame_index = index
		_schedule()
		await process_frame
		await RenderingServer.frame_post_draw
		_sample()
		var picture := root.get_texture().get_image()
		_check(picture != null and picture.get_size() == Vector2i(960, 540), "Actual frame has requested raster")
		if not failures.is_empty():
			_finish()
			return
		_check(picture.save_png(frames_output.path_join("frame-%04d.png" % index)) == OK, "Viewport frame saved")
	_check(int(samples[35].selected_piece) == PIECE_ID, "Touch selection persisted before rotation")
	_check(int(samples[55].model_turn) == 3 and int(samples[90].model_turn) == 0,
		"Two real button releases caused two quarter-turn state transitions")
	_check(game.model.placed() == 1 and bool(game.model.pieces[PIECE_ID].locked),
		"Touch drag and release snapped exactly one real piece")
	_check(game.model.moves == 4 and game.model.hints == 0, "Only selection release, two turns and final placement were counted")
	_check(game.last_snap_fx, "Production snap effect was triggered")
	var hovered := false
	for sample in samples:
		hovered = hovered or bool(sample.matching_hover)
	_check(hovered, "Actual matching-target hover observed before release")
	for index in range(1, samples.size()):
		_check(int(samples[index].engine_frame_drawn) == int(samples[index - 1].engine_frame_drawn) + 1,
			"Consecutive actual renderer frames")
	var saved = JSON.parse_string(FileAccess.get_file_as_string(game.save_path))
	_check(saved is Dictionary and bool(saved.pieces[PIECE_ID].locked), "Production autosave preserved the played placement")
	_finish()


func _finish() -> void:
	var report := {"kind": "production_puzzle_runtime_movie", "display": DisplayServer.get_name(),
		"scene": "res://scenes/creative/puzzle_world.tscn", "recording_method": "consecutive_actual_viewport_pngs",
		"format_fps": 24, "fixed_capture_timestep": true, "requested_frames": FRAMES,
		"physical_device_fps_measured": false, "source_or_camera_or_progress_modified": false,
		"rng_seed": SEED, "puzzle_initial_turn_formula": "posmod(id * 3 + motif + 1, 4)",
		"setup": "Real menu touches: count 12→24→48→96→6; motif stays 3; rotation enabled; new puzzle started",
		"desktop_pointer_precondition": "root.warp_mouse to viewport center before first menu touch",
		"initial_state": initial, "final_state": game.model.to_data(),
		"events": events, "frames": samples, "failures": failures}
	var file := FileAccess.open(output.path_join("runtime-frames.json"), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(report, "  "))
		file.close()
	else:
		failures.append("Could not write runtime report")
	if failures.is_empty():
		print("[PuzzleRuntimeMovie] PASS frames=", samples.size(), " placed=", game.model.placed(), " moves=", game.model.moves)
		quit(0)
	else:
		print("[PuzzleRuntimeMovie] FAIL ", failures)
		quit(1)
