extends SceneTree
## Actual production teacher and viewport; the desktop bridge plays one
## preserved local word clip. MovieMaker 24fps is recording format, not FPS QA.
const WORLD := "res://scripts/learning/learning_world.gd"
var rows: Array[Dictionary] = []
var lesson: Node3D
var status_label: Label
var output: String

class LocalPlayback:
	extends RefCounted
	var player: AudioStreamPlayer
	var envelope: PackedFloat32Array = PackedFloat32Array()
	var id: int = 0
	var state: String = "idle"
	var muted: bool = false
	func prepare(stream: AudioStreamWAV) -> bool:
		var data: PackedByteArray = stream.data
		var channels: int = 2 if stream.stereo else 1
		var frames: int = data.size() / (channels * 2)
		var window: int = stream.mix_rate * 20 / 1000
		if stream.format != AudioStreamWAV.FORMAT_16_BITS or window <= 0:
			return false
		for first in range(0, frames, window):
			var last: int = mini(frames, first + window)
			var square: float = 0.0
			for frame in range(first, last):
				for channel in range(channels):
					var at: int = frame * channels * 2 + channel * 2
					var value: int = int(data[at]) | (int(data[at + 1]) << 8)
					if value >= 32768:
						value -= 65536
					var sample: float = float(value) / 32768.0
					square += sample * sample
			var rms: float = sqrt(square / float((last - first) * channels))
			envelope.append(clampf((rms - 0.006) / 0.24, 0.0, 1.0))
		return not envelope.is_empty()
	func speakLearning(payload: String) -> int:
		var request: Dictionary = JSON.parse_string(payload)
		id = int(request.id)
		player.play()
		state = "playing"
		return 1
	func stopLearningSpeech() -> void:
		if is_instance_valid(player):
			player.stop()
		state = "idle"
	func getLearningSpeechStatus() -> String:
		if state == "playing" and not player.playing:
			state = "completed"
		var seconds: float = player.get_playback_position() if player.playing else 0.0
		var audible: bool = player.playing and not muted
		var index: int = int(seconds * 50.0)
		var amplitude: float = envelope[index] if audible and index >= 0 and index < envelope.size() else 0.0
		return JSON.stringify({"id": id, "state": state, "positionMs": seconds * 1000.0, "durationMs": player.stream.get_length() * 1000.0, "audible": audible, "envelopeAvailable": true, "envelope": amplitude})

func _init() -> void:
	# MovieMaker chooses its target before SceneTree._initialize/deferred work.
	# --resolution sets the window but does not replace these project values.
	ProjectSettings.set_setting("display/window/size/window_width_override", 640)
	ProjectSettings.set_setting("display/window/size/window_height_override", 640)

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("A real renderer is required")
		quit(1)
		return
	output = OS.get_environment("LUMO_FACE_CAPTURE_DIR")
	if output.is_empty():
		push_error("Explicit capture directory is required")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(output)
	root.size = Vector2i(640, 640)
	lesson = load(WORLD).new()
	lesson.capture_options = {"learningVoiceEnabled": true, "localVoiceLicenseAccepted": true, "learningAutoRead": false, "learning": {"kind": "syllables", "word": "Apfel", "syllables": ["Ap", "fel"]}}
	root.add_child(lesson)
	await process_frame
	await RenderingServer.frame_post_draw
	if lesson.activity.kind != "syllables" or lesson.activity.word != "Apfel" or lesson.tokens.size() != 2:
		push_error("A valid productive Apfel syllable lesson is required")
		quit(1)
		return
	var audio := AudioStreamPlayer.new()
	# Read the preserved original WAV bytes. Godot's asset importer normally
	# compresses this file; envelope measurement must use the actual PCM source.
	var wave: PackedByteArray = FileAccess.get_file_as_bytes("res://assets/audio/voice/words/apfel.wav")
	if wave.size() != 40970 or wave.slice(0, 4).get_string_from_ascii() != "RIFF" or wave.slice(8, 16).get_string_from_ascii() != "WAVEfmt " or wave.decode_u16(20) != 1 or wave.decode_u16(22) != 1 or wave.decode_u32(24) != 22050 or wave.decode_u16(34) != 16 or wave.slice(36, 40).get_string_from_ascii() != "data" or wave.decode_u32(40) != wave.size() - 44:
		push_error("Preserved original word PCM WAV identity/format mismatch")
		quit(1)
		return
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = wave.decode_u32(24)
	stream.stereo = false
	stream.data = wave.slice(44)
	audio.stream = stream
	root.add_child(audio)
	var bridge := LocalPlayback.new()
	bridge.player = audio
	if not bridge.prepare(audio.stream):
		push_error("Original PCM envelope preparation failed")
		quit(1)
		return
	lesson._speech_host = bridge
	var layer := CanvasLayer.new()
	root.add_child(layer)
	status_label = Label.new()
	status_label.position = Vector2(12, 606)
	status_label.visible = false
	status_label.add_theme_font_size_override("font_size", 18)
	status_label.add_theme_color_override("font_color", Color.WHITE)
	status_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	status_label.add_theme_constant_override("shadow_offset_x", 2)
	status_label.add_theme_constant_override("shadow_offset_y", 2)
	layer.add_child(status_label)
	var captures: Dictionary = {20: "teacher_scene", 28: "neutral", 39: "audio_jaw", 43: "blink", 44: "blink_intermediate", 67: "muted", 90: "gaze_left", 112: "stopped"}
	for frame in range(144):
		if frame == 24:
			status_label.visible = true
			lesson.ui.hide()
			lesson.fox.play_behavior("idle")
			var centre: Vector3 = lesson.fox.to_global(Vector3(0.0, 1.40, 0.13))
			lesson.camera.size = 0.86 * lesson.fox.scale.y
			lesson.camera.look_at_from_position(centre + lesson.fox.global_basis.orthonormalized() * Vector3(0.4, 0.05, 4.0), centre)
		if frame in [31, 60, 96]:
			bridge.muted = false
			audio.volume_db = 0.0
			lesson._speak("Apfel")
		if frame == 66:
			bridge.muted = true
			audio.volume_db = -80.0
		if frame == 76:
			lesson._stop_speech()
		if frame == 108:
			lesson._stop_speech()
		if frame in [30, 80]:
			var head: int = lesson.fox.skeleton.find_bone("Head")
			var centre: Vector3 = lesson.fox.skeleton.to_global(lesson.fox.skeleton.get_bone_global_pose(head).origin)
			lesson.fox.set_teaching_target(centre + lesson.fox.global_basis.orthonormalized() * Vector3(0.8 if frame == 30 else -0.8, 0.1, 4.0))
		await process_frame
		await RenderingServer.frame_post_draw
		var status: Dictionary = JSON.parse_string(bridge.getLearningSpeechStatus())
		var actual_lids: Array[float] = []
		for index in lesson.fox.facial_pose.lid_ids:
			actual_lids.append(lesson.fox.facial_pose.lids.get_blend_shape_value(index))
		rows.append({"lid_mesh_weights": actual_lids, "step": frame, "engine_drawn_frames": Engine.get_frames_drawn(), "player": status, "actual_jaw_weight": lesson.fox.facial_pose.body.get_blend_shape_value(lesson.fox.facial_pose.body_ids[4]), "blink": lesson.fox.facial_pose.blink, "gaze": [lesson.fox.facial_pose.gaze.x, lesson.fox.facial_pose.gaze.y]})
		status_label.text = "Original-Lumo · " + ("stumm" if bridge.muted else "„Apfel“ – lokale WAV" if status.state == "playing" else "Pause / geschlossen")
		if captures.has(frame):
			var path := output.path_join(str(captures[frame]) + ".png")
			if root.get_texture().get_image().save_png(path) != OK:
				push_error("Capture failed")
	var saw_audible_jaw: bool = false
	var saw_muted: bool = false
	var saw_stopped: bool = false
	var saw_blink: bool = false
	var max_jaw: float = 0.0
	for row in rows:
		max_jaw = maxf(max_jaw, float(row.actual_jaw_weight))
		if row.player.audible and row.actual_jaw_weight > 0.05:
			saw_audible_jaw = true
		if row.step >= 67 and row.step < 76 and not row.player.audible and is_zero_approx(row.actual_jaw_weight):
			saw_muted = true
		if row.step >= 112 and row.player.state == "idle" and is_zero_approx(row.actual_jaw_weight):
			saw_stopped = true
		if row.blink > 0.9:
			saw_blink = true
	if not (saw_audible_jaw and saw_muted and saw_stopped and saw_blink):
		push_error("Captured runtime did not show every required actual facial state")
		quit(1)
		return
	var report := {"scope": "actual Godot production teacher, inspection camera, original local word; not Android/phonemes/FPS", "recording_fps": 24, "actual_max_jaw_weight": max_jaw, "observed_audible_jaw": saw_audible_jaw, "observed_muted_closed": saw_muted, "observed_stopped_closed": saw_stopped, "observed_blink": saw_blink, "lesson_kind": lesson.activity.kind, "lesson_word": lesson.activity.word, "word_source": "res://assets/audio/voice/words/apfel.wav", "rows": rows}
	var file := FileAccess.open(output.path_join("runtime-frames.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  "))
	file.close()
	lesson._stop_speech()
	lesson.queue_free()
	layer.queue_free()
	await process_frame
	await process_frame
	audio.queue_free()
	await process_frame
	print("LUMO_FACIAL_CAPTURE_PASS frames=", rows.size(), " original_word=true recording_fps=24 not_device_fps=true")
	quit(0)
