extends SceneTree
## External QA recorder: production learning scene, real touch events only.
## The 24fps fixed recording format is not measured Android performance.

const FRAMES := 240
const FIRST_PRESS := 24
const PRESS_INTERVAL := 12
const WORLD := "res://scenes/learning/learning_world.tscn"
var game
var output := ""
var frames_output := ""
var frame_index := 0
var button_activations := 0
var failures: Array[String] = []
var samples: Array[Dictionary] = []
var inputs: Array[Dictionary] = []
var rounds: Dictionary = {}
var animations: Dictionary = {}


func _initialize() -> void:
	output = OS.get_environment("LUMO_RUNTIME_EVIDENCE_DIR")
	frames_output = OS.get_environment("LUMO_RUNTIME_FRAMES_DIR")
	_run.call_deferred()


func _check(value: bool, label: String) -> void:
	if not value:
		failures.append(label)
		push_error("[LearningRuntimeMovie] " + label)


func _pressed() -> void:
	button_activations += 1
	inputs.append({"frame": frame_index, "kind": "production_button_pressed_signal",
		"activation": button_activations, "placed_after_callback": game.activity.placed.size()})


func _touch(pressed: bool) -> void:
	var rectangle: Rect2 = game.main_button.get_global_rect()
	_check(root.get_visible_rect().encloses(rectangle), "Production action is fully inside the viewport")
	if pressed:
		_check(not game.main_button.disabled, "Each scheduled touch begins after the preceding actual move")
	var point := rectangle.get_center() * Vector2(root.size) / root.get_visible_rect().size
	var event := InputEventScreenTouch.new()
	event.index = 7
	event.position = point
	event.pressed = pressed
	inputs.append({"frame": frame_index, "kind": "InputEventScreenTouch", "finger": 7,
		"pressed": pressed, "physical_position": [point.x, point.y],
		"button_text": game.main_button.text, "placed_before_input": game.activity.placed.size()})
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _sample() -> void:
	var counts: Array[int] = []
	for group in range(3):
		counts.append(game.activity.count_in_group(group))
		_check(game._group_labels[group].mesh.text == str(counts[-1]), "Actual 3D count matches its group")
	_check(counts.max() - counts.min() <= 1, "Every group receives one cube before the next fair round")
	_check(counts[0] + counts[1] + counts[2] == game.activity.placed.size(), "No cube is lost or invented")
	var positions: Array[Array] = []
	for token in game.tokens:
		var p: Vector3 = token.global_position
		positions.append([p.x, p.y, p.z])
	if game.activity.placed.size() > 0 and game.activity.placed.size() % 3 == 0 and game._moving.is_empty():
		rounds[str(game.activity.placed.size() / 3)] = counts.duplicate()
	var behavior: String = game.fox.get_current_behavior()
	animations[behavior] = int(animations.get(behavior, 0)) + 1
	samples.append({"frame": frame_index, "time_seconds": float(frame_index) / 24.0,
		"engine_process_frame": Engine.get_process_frames(), "placed": game.activity.placed.size(),
		"group_counts": counts, "token_world_positions": positions,
		"moving_tokens": game._moving.keys(), "button_activations": button_activations,
		"button_disabled": game.main_button.disabled, "teacher_behavior": behavior,
		"complete": game.activity.is_complete(), "status": game.status.text,
		"explanation": game.explanation.text})


func _run() -> void:
	if DisplayServer.get_name() == "headless" or output.is_empty() or frames_output.is_empty():
		push_error("[LearningRuntimeMovie] Actual renderer and isolated evidence output required")
		quit(1)
		return
	root.size = Vector2i(960, 540)
	root.get_node("HostBridge")._options = {
		"displayDensity": 1.0, "soundEnabled": false, "reduceAnimations": false,
		"childKey": "studio-runtime-learning-isolated"
	}
	root.get_node("SceneRouter").launch_options = {
		"learning": {"kind": "equal_sharing", "a": 12, "b": 3},
		"reduceAnimations": false, "learningVoiceEnabled": false,
		"learningAutoRead": false, "childKey": "studio-runtime-learning-isolated"
	}
	game = (load(WORLD) as PackedScene).instantiate()
	root.add_child(game)
	_check(game.activity.kind == "equal_sharing" and game.tokens.size() == 12, "Production scene has all twelve real cubes")
	_check(game.fox.is_usable() and game.fox.skeleton.get_bone_count() == 65, "Original 65-bone Lumo is loaded")
	game.main_button.pressed.connect(_pressed)
	for warmup in range(24):
		await process_frame
	await RenderingServer.frame_post_draw
	for index in range(FRAMES):
		frame_index = index
		var offset: int = index - FIRST_PRESS
		if offset >= 0 and offset / PRESS_INTERVAL < 12:
			if offset % PRESS_INTERVAL == 0:
				_touch(true)
			elif offset % PRESS_INTERVAL == 1:
				_touch(false)
		await process_frame
		_sample()
		await RenderingServer.frame_post_draw
		var picture := root.get_texture().get_image()
		_check(picture != null and picture.get_size() == Vector2i(960, 540), "Actual renderer frame has the requested size")
		if not failures.is_empty():
			break
		_check(picture.save_png(frames_output.path_join("frame-%04d.png" % index)) == OK, "Actual consecutive viewport frame saved")
	_check(samples.size() == FRAMES, "All 240 frames were recorded")
	_check(button_activations == 12, "Exactly twelve production button activations from twelve real touch pairs")
	_check(game.activity.is_complete() and game._moving.is_empty(), "Completion includes finished real geometry movement")
	_check(rounds.size() == 4, "All four fair sharing rounds were observed")
	for group in range(3):
		_check(game.activity.count_in_group(group) == 4, "Each final group has four cubes")
	for step in range(game.activity.placed.size()):
		var token: int = game.activity.placed[step]
		_check(game.tokens[token].position.distance_to(game.targets[game.activity.target_for_step(step)]) < 0.001,
			"Every actual cube reached its production target")
	for index in range(1, samples.size()):
		_check(samples[index].engine_process_frame == samples[index - 1].engine_process_frame + 1,
			"No runtime process frame was skipped inside the recorded sequence")
	var report := {"kind": "production_equal_sharing_runtime_movie", "scene": WORLD,
		"activity": {"kind": "equal_sharing", "a": 12, "b": 3},
		"display": DisplayServer.get_name(), "renderer": RenderingServer.get_current_rendering_method(),
		"capture_format_fps": 24, "fixed_capture_timestep": true, "scheduled_frames": FRAMES,
		"scene_camera_or_gameplay_modified": false, "input_method": "InputEventScreenTouch on existing production button",
		"original_rig_bones": game.fox.skeleton.get_bone_count(), "original_model_load_kind": game.fox.model_load_kind,
		"button_activations": button_activations, "fair_rounds": rounds,
		"teacher_behaviors": animations, "inputs": inputs, "frames": samples, "failures": failures}
	var file := FileAccess.open(output.path_join("runtime-frames.json"), FileAccess.WRITE)
	_check(file != null, "Runtime evidence is writable")
	if file != null:
		file.store_string(JSON.stringify(report, "  "))
		file.close()
	game.queue_free()
	await process_frame
	print("[LearningRuntimeMovie] ", "PASS" if failures.is_empty() else "FAIL",
		" frames=", samples.size(), " taps=", button_activations, " rounds=", JSON.stringify(rounds))
	quit(0 if failures.is_empty() else 1)
