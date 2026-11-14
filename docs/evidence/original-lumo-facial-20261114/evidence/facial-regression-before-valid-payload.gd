extends SceneTree
const ACTOR = preload("res://scripts/characters/lumo/lumo_rigged_actor.gd")
const WORLD := "res://scripts/learning/learning_world.gd"
var checks: int = 0
var failures: Array[String] = []

class SpeechHost:
	extends RefCounted
	var response: Dictionary = {"id": 77, "state": "preparing", "positionMs": 0, "envelope": 0.8, "audible": false, "envelopeAvailable": true}
	var stops: int = 0
	func getLearningSpeechStatus() -> String:
		return JSON.stringify(response)
	func stopLearningSpeech() -> void:
		stops += 1

func _initialize() -> void:
	_run.call_deferred()

func _check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures.append(label)
		push_error("[LumoFacial] " + label)

func _run() -> void:
	var actor = ACTOR.new()
	root.add_child(actor)
	actor.set_process(false)
	_check(actor.is_usable() and actor.skeleton.get_bone_count() == 65, "original 65-bone rig imports")
	if not actor.is_usable() or actor.facial_pose == null:
		_check(false, "derived geometry adapter must bind")
		quit(1)
		return
	for clip in ACTOR.CLIPS:
		_check(actor.player.has_animation(clip), "original clip preserved: " + clip)
	_check(actor.mouth_supported and not actor.phoneme_lipsync_supported, "actual muzzle morph supported without phoneme claim")
	var face = actor.facial_pose
	_check(face.body.mesh.get_blend_shape_count() == 5, "five actual surface morphs exist")
	_check(face.lids.mesh.get_blend_shape_count() == 8, "eight actual curved-surface lid stages exist")
	_check(face.lids.mesh.get_surface_count() == 2, "physical lids batch into two material surfaces")
	_check(actor.model_load_kind == "imported_packed_scene", "imported asset required to verify deforming-mesh LOD policy")
	var body_surfaces: Array = face.body.mesh.get("_surfaces")
	var lid_surfaces: Array = face.lids.mesh.get("_surfaces")
	_check(body_surfaces[0].get("lods", []).size() > 0, "original body LODs remain generated")
	for surface in lid_surfaces:
		_check(surface.get("lods", []).is_empty(), "authored lid topology survives import without destructive neutral-state LODs")
	_check(not face.lids.visible and is_zero_approx(face.jaw), "neutral face hides additional lids and leaves mouth unchanged")
	actor.player.pause()
	var neutral: Array[Quaternion] = []
	for bone in range(65):
		neutral.append(actor.skeleton.get_bone_pose_rotation(bone))
	var arrays: Array = face.body.mesh.surface_get_arrays(0)
	var shapes: Array = face.body.mesh.surface_get_blend_shape_arrays(0)
	var base_vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var jaw_vertices: PackedVector3Array = shapes[face.body_ids[4]][Mesh.ARRAY_VERTEX]
	var maximum_delta: float = 0.0
	for index in range(base_vertices.size()):
		maximum_delta = maxf(maximum_delta, base_vertices[index].distance_to(jaw_vertices[index]))
	print("[LumoFacial] jaw_mesh_delta_m=", maximum_delta, " blend_mode=", face.body.mesh.get_blend_shape_mode())
	_check(maximum_delta > 0.002 and maximum_delta < 0.015, "imported jaw changes real bounded geometry")
	face.set_target(Vector3(2, 1.7, 4))
	for frame in range(100):
		face.advance(1.0 / 60.0)
	_check(face.gaze.x > 0.2 and face.body.get_blend_shape_value(face.body_ids[1]) > 0.2, "visible gaze morph follows an actual world point")
	for frame in range(12):
		face.advance(1.0 / 60.0)
	_check(face.blink > 0.8 and face.lids.visible, "elapsed idle produces actual physical eyelid closure")
	_check(face.lids.get_blend_shape_value(face.lid_ids[3]) > 0.6, "closed lid mesh receives nonzero authored shape")
	for bone in range(65):
		_check(neutral[bone] == actor.skeleton.get_bone_pose_rotation(bone), "face leaves exact body-bone quaternion unchanged " + str(bone))
	for frame in range(20):
		actor.apply_speech_sample(float(frame) / 60.0, 0.75, true)
		face.advance(1.0 / 60.0)
	_check(face.jaw > 0.70 and face.body.get_blend_shape_value(face.body_ids[4]) > 0.70, "actual envelope seam moves actual muzzle geometry")
	actor.apply_speech_sample(0.5, 0.9, false)
	_check(face.jaw == 0.0 and face.body.get_blend_shape_value(face.body_ids[4]) == 0.0, "stop/mute closes immediately without a timer")
	actor.apply_speech_sample(1.0, 0.8, true)
	for frame in range(60):
		actor.apply_speech_sample(1.0, 0.8, true)
		face.advance(1.0 / 60.0)
	_check(face.jaw < 0.001, "repeated frozen player positions cannot perpetuate speech")
	actor.apply_speech_sample(NAN, 0.8, true)
	_check(face.jaw == 0.0, "nonfinite media position closes")
	actor.apply_speech_sample(2.0, NAN, true)
	_check(face.jaw == 0.0, "nonfinite amplitude closes")
	actor.apply_speech_sample(2.0, 0.8, true)
	face.advance(0.05)
	actor.set_suspended(true)
	_check(face.jaw == 0.0 and not face.lids.visible and not actor.audio_active, "suspension clears face and audio state")
	actor.set_suspended(false)
	actor.set_reduced_motion(true)
	actor.apply_speech_sample(3.0, 0.8, true)
	actor._process(0.1)
	_check(face.jaw == 0.0 and not face.lids.visible, "reduced-motion preference remains effective")
	actor.set_reduced_motion(false)
	actor.queue_free()
	await process_frame
	await process_frame
	var lesson = load(WORLD).new()
	lesson.capture_options = {"learningVoiceEnabled": true, "localVoiceLicenseAccepted": true, "learningAutoRead": false, "learning": {"mode": "bridge_ten", "a": 8, "b": 5}}
	root.add_child(lesson)
	await process_frame
	lesson.set_process(false)
	lesson.fox.set_process(false)
	var speech := SpeechHost.new()
	lesson._speech_host = speech
	lesson._speech_id = 77
	lesson._speech_enabled = true
	lesson._tick_speech(0.06)
	lesson.fox._process(0.06)
	_check(lesson.fox.facial_pose.jaw == 0.0, "production teacher rejects synthesis-only amplitude")
	speech.response.state = "playing"
	speech.response.audible = true
	speech.response.positionMs = 200
	lesson._tick_speech(0.06)
	lesson.fox._process(0.06)
	_check(lesson.fox.facial_pose.jaw > 0.4, "actual productive teacher reads matching playback envelope")
	speech.response.audible = false
	lesson._tick_speech(0.06)
	_check(lesson.fox.facial_pose.jaw == 0.0, "actual productive teacher closes for host stream mute")
	speech.response.audible = true
	speech.response.envelopeAvailable = false
	lesson._tick_speech(0.06)
	_check(lesson.fox.facial_pose.jaw == 0.0, "unavailable PCM envelope cannot invent articulation")
	speech.response.envelopeAvailable = true
	speech.response.positionMs = 350
	lesson._tick_speech(0.06)
	lesson.fox._process(0.06)
	lesson._stop_speech()
	_check(lesson.fox.facial_pose.jaw == 0.0 and speech.stops > 0, "production stop clears geometry and calls actual transport seam")
	lesson._tick_speech(0.06)
	_check(lesson.fox.facial_pose.jaw == 0.0, "cancelled utterance ID cannot reopen the muzzle")
	lesson.queue_free()
	await process_frame
	await process_frame
	if failures.is_empty():
		print("LUMO_FACIAL_PASS checks=", checks, " actual_meshes=true original_bones=65 original_clips=9 phoneme_lipsync=false")
		quit(0)
	else:
		print("LUMO_FACIAL_FAIL checks=", checks, " failures=", failures)
		quit(1)
