extends Node3D
## Shared visual character adapter. No race physics, audio engine or rewards.
## Uses the existing companion behavior names rather than a second event bus.
signal behavior_started(behavior: String)
signal behavior_finished(behavior: String)
const MODEL := "res://assets/characters/lumo_facial/Lumo-Facial-Mobile.glb"
const ORIGINAL_MODEL := "res://assets/characters/lumo_animated/Lumo-Animated-Mobile.glb"
const WALK = preload("res://scripts/characters/lumo/lumo_walk_locomotion.gd")
const PLATFORM_POSE = preload("res://scripts/characters/lumo/lumo_platform_pose.gd")
const TEACHER_POSE = preload("res://scripts/characters/lumo/lumo_teacher_pose.gd")
const FACIAL_POSE = preload("res://scripts/characters/lumo/lumo_facial_pose.gd")
static var _cached_model: PackedScene
static var _cached_load_kind := ""
var model_load_kind := ""
const CLIPS: Array[String] = [
	"idle", "greeting_wave", "celebrate", "point_portal", "agree_nod",
	"kart_seated", "kart_steer_left", "kart_steer_right", "kart_jump",
]
var visual: Node3D
var skeleton: Skeleton3D
var player: AnimationPlayer
var current_behavior := "idle"
var reduced_motion := false
var suspended := false
var mouth_supported := false
var phoneme_lipsync_supported := false
var facial_pose
var last_audio_position := 0.0
var last_audio_envelope := 0.0
var audio_active := false
var locomotion
var walking := false
var walk_speed_mps: float = 0.0
var platform_pose
var platform_active: bool = false
var teacher_pose
var teacher_enabled: bool = false
var _teacher_previous_process_mode: int = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_IDLE


func _ready() -> void:
	if _cached_model == null:
		var selected_model := MODEL
		if not ResourceLoader.exists(selected_model, "PackedScene") and not FileAccess.file_exists(selected_model):
			selected_model = ORIGINAL_MODEL
		# Exported games resolve the GLB through Godot's imported PackedScene.
		# Do not require raw source bytes, and never put loading side effects
		# inside assert(): release builds remove those expressions.
		if ResourceLoader.exists(selected_model, "PackedScene"):
			_cached_model = ResourceLoader.load(selected_model, "PackedScene") as PackedScene
			_cached_load_kind = "imported_packed_scene"
		elif FileAccess.file_exists(selected_model):
			# Bare headless review fixtures can run before editor import.
			var document := GLTFDocument.new()
			var state := GLTFState.new()
			var error := document.append_from_file(selected_model, state)
			if error != OK:
				push_warning("[LumoRig] Source model cannot be loaded; retain existing visual")
				return
			var source := document.generate_scene(state)
			if source == null:
				return
			var packed := PackedScene.new()
			error = packed.pack(source)
			source.free()
			if error != OK:
				return
			_cached_model = packed
			_cached_load_kind = "source_fixture"
	if _cached_model == null:
		push_warning("[LumoRig] Model is unavailable; retain existing visual")
		return
	visual = _cached_model.instantiate() as Node3D
	if visual == null:
		return
	add_child(visual)
	for node in visual.find_children("*", "Skeleton3D", true, false):
		skeleton = node
	for node in visual.find_children("*", "AnimationPlayer", true, false):
		player = node
	if skeleton == null or player == null or skeleton.get_bone_count() != 65:
		push_warning("[LumoRig] Incompatible skeleton; retain existing visual")
		return
	for clip in CLIPS:
		if not player.has_animation(clip):
			push_warning("[LumoRig] Missing animation: " + clip)
			player = null
			return
	model_load_kind = _cached_load_kind
	for clip in ["idle", "kart_seated", "kart_steer_left", "kart_steer_right"]:
		player.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	player.animation_finished.connect(_finished)
	locomotion = WALK.new()
	facial_pose = FACIAL_POSE.new()
	if not facial_pose.bind(visual, skeleton):
		facial_pose = null
	mouth_supported = facial_pose != null
	play_behavior("idle")


func is_usable() -> bool:
	return is_instance_valid(skeleton) and is_instance_valid(player) and not model_load_kind.is_empty()


func _process(delta: float) -> void:
	if teacher_enabled:
		if not suspended and not reduced_motion:
			# The same owner restores and samples the authored pose before
			# adding gaze; constant animation tracks cannot accumulate offsets.
			teacher_pose.restore_sampled_pose()
			player.advance(minf(delta, 0.10))
			teacher_pose.advance(self, delta)
		_advance_face(delta)
		return
	if walking and not platform_active and not suspended and not reduced_motion and locomotion != null:
		locomotion.advance(delta, walk_speed_mps)
	_advance_face(delta)


func _advance_face(delta: float) -> void:
	if facial_pose != null and not suspended and not reduced_motion:
		facial_pose.advance(delta)


## The owner supplies actual horizontal velocity from navigation/physics.
## This API affects bones only; it cannot teleport or slide the root node.
func set_locomotion_speed(speed_mps: float) -> bool:
	if not is_usable():
		return false
	_stop_teacher_mode()
	_stop_platform_pose()
	if not is_finite(speed_mps) or speed_mps <= 0.045:
		if walking:
			play_behavior("idle")
		return true
	walk_speed_mps = clampf(speed_mps, 0.05, 3.2)
	if not walking:
		return play_behavior("walk_loop")
	return true


## Feed after move_and_slide(), once per physics tick. This optional mode is
## shared by Jump and walking worlds. It has sole ownership of animated bones;
## the original AnimationPlayer is paused until a gesture/legacy mode resumes.
func set_platform_motion(velocity: Vector3, grounded: bool, delta: float) -> bool:
	if not is_usable() or suspended or not velocity.is_finite() or delta <= 0.0:
		return false
	_stop_teacher_mode()
	var speed: float = Vector2(velocity.x, velocity.z).length()
	# Let the original authored idle breathe again after the landing settles.
	# Do not repeatedly restart it on every physics tick.
	if grounded and speed <= 0.06:
		if platform_active and platform_pose.was_grounded and platform_pose.landing_left <= 0.0:
			_stop_platform_pose()
		if not platform_active:
			if walking:
				play_behavior("idle")
			return true
	if not platform_active:
		if walking and locomotion != null:
			locomotion.stop()
		player.play("idle", 0.0)
		# play() resumes an already-selected idle at its current position.
		# The studio curves are relative to frame zero, including Root height.
		player.seek(0.0, true)
		player.advance(0.0)
		player.pause()
		platform_pose = PLATFORM_POSE.new()
		if not platform_pose.bind(skeleton):
			player.play("idle")
			return false
		platform_active = true
	walking = grounded and speed > 0.06
	walk_speed_mps = speed
	if reduced_motion:
		platform_pose.stop()
		return true
	platform_pose.advance(velocity, grounded, delta)
	current_behavior = platform_pose.state
	return true


func _stop_platform_pose() -> void:
	if not platform_active:
		return
	platform_pose.stop()
	platform_active = false
	walking = false
	current_behavior = "idle"
	player.play("idle", 0.12)


func _enable_teacher_mode() -> bool:
	if not is_usable():
		return false
	if teacher_enabled:
		return true
	# The kart adapter already owns its AnimationPlayer manually. Do not
	# compete with that owner if a caller accidentally sends teacher events.
	if player.callback_mode_process == AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL:
		return false
	_stop_platform_pose()
	if walking:
		play_behavior("idle")
	teacher_pose = TEACHER_POSE.new()
	if not teacher_pose.bind(skeleton):
		return false
	_teacher_previous_process_mode = player.callback_mode_process
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	teacher_enabled = true
	return true


func _stop_teacher_mode() -> void:
	if not teacher_enabled:
		return
	teacher_pose.restore_sampled_pose()
	teacher_enabled = false
	player.callback_mode_process = _teacher_previous_process_mode
	player.advance(0.0)


func set_teaching_target(world_position: Vector3) -> bool:
	if not world_position.is_finite() or not _enable_teacher_mode():
		return false
	if facial_pose != null:
		facial_pose.set_target(world_position)
	return teacher_pose.set_target(world_position)


func clear_teaching_target() -> void:
	if teacher_enabled:
		teacher_pose.has_target = false
	if facial_pose != null:
		facial_pose.has_target = false


func teacher_react(event: String) -> bool:
	var clips: Dictionary = {"explain": "point_portal", "encourage": "agree_nod", "correct": "agree_nod", "celebrate": "celebrate", "welcome": "greeting_wave"}
	if not clips.has(event) or suspended or not _enable_teacher_mode():
		return false
	teacher_pose.react(event)
	return play_behavior(str(clips[event]))


func set_teacher_speaking(value: bool) -> bool:
	if not _enable_teacher_mode():
		return false
	# This drives gentle explaining motion only. It is not a viseme/jaw API.
	teacher_pose.speaking = value
	return true


func play_behavior(behavior: String) -> bool:
	if suspended or player == null:
		return false
	if teacher_enabled:
		teacher_pose.restore_sampled_pose()
	_stop_platform_pose()
	if behavior == "walk_loop":
		if not is_usable():
			return false
		_stop_teacher_mode()
		if not walking:
			player.play("idle", 0.0)
			player.seek(0.0, true)
			player.advance(0.0)
			player.pause()
			if locomotion == null or not locomotion.bind(skeleton):
				return false
		walking = true
		walk_speed_mps = maxf(walk_speed_mps, 0.9)
		current_behavior = behavior
		behavior_started.emit(behavior)
		return true
	if not CLIPS.has(behavior):
		return false
	if walking:
		walking = false
		locomotion.stop()
	current_behavior = behavior
	player.play(behavior, 0.12)
	player.advance(0.0)
	if reduced_motion:
		player.seek(0.0 if behavior == "idle" else player.get_animation(behavior).length * 0.5, true)
		player.pause()
	behavior_started.emit(behavior)
	return true


func _finished(behavior: StringName) -> void:
	behavior_finished.emit(str(behavior))
	if not suspended and str(behavior) == current_behavior:
		play_behavior("idle")


func set_suspended(value: bool) -> void:
	if suspended == value:
		return
	suspended = value
	if value and facial_pose != null:
		facial_pose.reset()
		apply_speech_sample(0.0, 0.0, false)
	if player == null:
		return
	if value:
		player.pause()
	else:
		if walking or platform_active:
			player.pause()
		else:
			player.play()
			if reduced_motion:
				player.pause()


func set_reduced_motion(value: bool) -> void:
	reduced_motion = value
	if value and facial_pose != null:
		facial_pose.reset()
		apply_speech_sample(0.0, 0.0, false)
	if platform_active:
		if value:
			platform_pose.stop()
		return
	if not suspended:
		play_behavior(current_behavior)


func apply_speech_sample(media_seconds: float, envelope: float, speaking: bool) -> void:
	# Actual PCM amplitude drives the derived closed-muzzle shape. The source
	# still has no mouth cavity or phoneme/viseme model; do not claim lip sync.
	speaking = speaking and not suspended and not reduced_motion
	last_audio_position = maxf(0.0, media_seconds) if is_finite(media_seconds) else 0.0
	last_audio_envelope = clampf(envelope, 0.0, 1.0) if speaking and is_finite(envelope) else 0.0
	audio_active = speaking
	if facial_pose != null:
		facial_pose.speech_sample(media_seconds, envelope, speaking)


func get_current_behavior() -> String:
	return current_behavior
