extends SceneTree
## Unmodified production scene; actual touch events drive a ten-second take.
## A fixed capture timestep produces 24 output frames/s, not measured device FPS.

const RECORD_FRAMES := 240
var game
var failures: Array[String] = []
var samples: Array[Dictionary] = []
var events: Array[Dictionary] = []
var states: Dictionary = {}
var stick_down := false
var previous_stick_point := Vector2.ZERO
var output := ""
var frames_output := ""
var frame_index := 0


func _initialize() -> void:
	output = OS.get_environment("LUMO_RUNTIME_EVIDENCE_DIR")
	frames_output = OS.get_environment("LUMO_RUNTIME_FRAMES_DIR")
	_run.call_deferred()


func _check(value: bool, label: String) -> void:
	if not value:
		failures.append(label)
		push_error("[JumpRuntimeMovie] " + label)


func _physical(point: Vector2) -> Vector2:
	return point * Vector2(root.size) / root.get_visible_rect().size


func _touch(point: Vector2, finger: int, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.position = _physical(point)
	event.index = finger
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	events.append({"frame": frame_index, "kind": "touch", "finger": finger,
		"pressed": pressed, "physical_position": [event.position.x, event.position.y]})


func _stick(axis: Vector2) -> void:
	var rectangle: Rect2 = game.movement_stick.get_global_rect()
	if axis == Vector2.ZERO:
		if stick_down:
			_touch(rectangle.get_center(), 3, false)
		stick_down = false
		return
	if not stick_down:
		_touch(rectangle.get_center(), 3, true)
		stick_down = true
		previous_stick_point = _physical(rectangle.get_center())
	var point := _physical(rectangle.get_center() + axis * rectangle.size.x * 0.31)
	var event := InputEventScreenDrag.new()
	event.position = point
	event.relative = point - previous_stick_point
	event.index = 3
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	previous_stick_point = point
	events.append({"frame": frame_index, "kind": "stick_drag", "axis": [axis.x, axis.y]})


func _jump(pressed: bool) -> void:
	_touch(game.jump_action.get_global_rect().get_center(), 4, pressed)


func _schedule() -> void:
	match frame_index:
		20: _stick(Vector2(0, -0.28))
		48: _stick(Vector2(0.22, -0.976).normalized())
		54: _jump(true)
		77:
			_jump(false)
			_stick(Vector2.ZERO)
		96: _stick(Vector2(-0.28, 0))
		125: _stick(Vector2.RIGHT)
		143: _stick(Vector2.ZERO)
		168: _jump(true)
		190: _jump(false)


func _sample() -> void:
	var state: String = game.original_lumo.get_current_behavior()
	states[state] = int(states.get(state, 0)) + 1
	var position: Vector3 = game.actor.position
	var velocity: Vector3 = game.actor.velocity
	samples.append({"frame": frame_index, "time_seconds": float(frame_index) / 24.0,
		"position": [position.x, position.y, position.z],
		"velocity": [velocity.x, velocity.y, velocity.z],
		"grounded": game.actor.is_on_floor(), "animation": state,
		"checkpoint": game.checkpoint, "falls": game.falls,
		"stick_finger": game.movement_stick.touch_id, "jump_held": game.jump_held})


func _run() -> void:
	if DisplayServer.get_name() == "headless" or output.is_empty() or frames_output.is_empty():
		push_error("[JumpRuntimeMovie] Requires actual renderer and evidence output directory")
		quit(1)
		return
	root.size = Vector2i(960, 540)
	root.get_node("HostBridge")._options = {
		"displayDensity": 1.0, "soundEnabled": false,
		"reduceAnimations": false, "childKey": "studio-runtime-movie-isolated"
	}
	root.get_node("SceneRouter").launch_options = {
		"grade": 2, "subject": "Mathematik", "jumpCourse": 0,
		"childKey": "studio-runtime-movie-isolated"
	}
	game = load("res://scenes/games/jump_islands.tscn").instantiate()
	root.add_child(game)
	_check(is_instance_valid(game.original_lumo) and game.original_lumo.is_usable(),
		"Original Lumo rig is loaded in the production Jump scene")
	if not failures.is_empty():
		quit(1)
		return
	_check(game.original_lumo.skeleton.get_bone_count() == 65, "Original 65-bone rig")
	for index in range(RECORD_FRAMES):
		frame_index = index
		if index == 12:
			var stick: Rect2 = game.movement_stick.get_global_rect()
			var action: Rect2 = game.jump_action.get_global_rect()
			_check(not stick.intersects(action), "Thumb controls remain separate")
			_check(root.get_visible_rect().encloses(stick) and root.get_visible_rect().encloses(action),
				"Thumb controls remain fully visible")
		_schedule()
		await process_frame
		_sample()
		await RenderingServer.frame_post_draw
		var picture := root.get_texture().get_image()
		_check(picture != null and picture.get_size() == Vector2i(960, 540),
			"Unmodified current viewport supplies the requested physical image size")
		if not failures.is_empty():
			quit(1)
			return
		_check(picture.save_png(frames_output.path_join("frame-%04d.png" % index)) == OK,
			"Actual renderer frame written")
	_stick(Vector2.ZERO)
	_jump(false)
	for required in ["idle", "walk_loop", "run_loop", "jump_rise", "jump_fall", "land"]:
		_check(int(states.get(required, 0)) > 0, "Actual runtime state observed: " + required)
	_check(game.falls == 0, "No fall or respawn in the recorded take")
	_check(game.checkpoint >= 1, "Actual jump reached the second production island")
	_check(game.actor.is_on_floor(), "Take ends with real floor contact")
	var braking_samples := 0
	for index in range(1, samples.size()):
		var previous: Array = samples[index - 1].velocity
		var current: Array = samples[index].velocity
		if samples[index].grounded and Vector2(previous[0], previous[2]).length() > Vector2(current[0], current[2]).length() + 0.05:
			braking_samples += 1
	_check(braking_samples > 0, "Actual horizontal braking observed")
	var report := {"kind": "production_jump_runtime_movie", "display": DisplayServer.get_name(),
		"recording_method": "actual_viewport_png_sequence",
		"capture_format_fps": 24, "fixed_capture_timestep": true, "scheduled_frames": RECORD_FRAMES,
		"physical_device_fps_measured": false, "scene": "res://scenes/games/jump_islands.tscn",
		"scene_or_camera_or_physics_modified": false, "animation_states": states,
		"braking_samples": braking_samples, "events": events, "frames": samples, "failures": failures}
	var file := FileAccess.open(output.path_join("runtime-frames.json"), FileAccess.WRITE)
	_check(file != null, "Runtime manifest writable")
	if file != null:
		file.store_string(JSON.stringify(report, "  "))
		file.close()
	game.abandoned = true
	if failures.is_empty():
		print("[JumpRuntimeMovie] PASS states=", JSON.stringify(states), " frames=", samples.size(), " braking=", braking_samples, " checkpoint=", game.checkpoint)
		quit(0)
	else:
		print("[JumpRuntimeMovie] FAIL ", failures)
		quit(1)
