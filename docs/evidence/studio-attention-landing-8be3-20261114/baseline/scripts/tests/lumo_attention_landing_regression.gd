extends SceneTree
## Existing production vehicle + unchanged original GLB. Real bone and wheel
## transforms prove visual behavior; this is not a hardware/FPS benchmark.
const VEHICLE = preload("res://scripts/games/kart_vehicle.gd")
const STEP := 1.0 / 30.0
const ORIGINAL_MODEL_SHA256 := "3559f700784bc1006905ee3aae01e8bcfbffb95b4f621f7430ce771ba0e3efd5"
var checks := 0
var failures := 0
var kart
var adapter
var worst_contact := 0.0
var original_chassis: Transform3D
var original_scale: Vector3
var original_node_count := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("[LumoAttentionLanding] " + label)


func _pose(name: String) -> Quaternion:
	return adapter.actor.skeleton.get_bone_pose_rotation(
		adapter.actor.skeleton.find_bone(name))


func _step(frames: int = 1) -> void:
	for frame in range(frames):
		kart._process(STEP)
		var skeleton: Skeleton3D = adapter.actor.skeleton
		for index in range(2):
			var hand := skeleton.to_global(skeleton.get_bone_global_pose(
				skeleton.find_bone("Hand.L" if index == 0 else "Hand.R")).origin)
			var grip: Vector3 = kart.steering_wheel.to_global(kart.wheel_rest_grips[index])
			var error := hand.distance_to(grip)
			worst_contact = maxf(worst_contact, error)
			_check(error < 0.006, "Actual seated hand contact remains within 6 mm")
		_check(kart.transform.is_equal_approx(original_chassis),
			"Secondary motion cannot move the actual chassis")
		_check(kart.scale.is_equal_approx(original_scale), "Original proportions remain uniform")
		_check(_pose("Head").is_finite() and _pose("Chest").is_finite(),
			"Head and chest poses stay finite")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var output := args[0] if not args.is_empty() else "user://lumo-attention-landing.json"
	var orphan_baseline := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	kart = VEHICLE.new()
	kart.configure("fox", Color("357cba"), "comet")
	root.add_child(kart)
	kart.set_process(false)
	kart.set_animated_lumo_enabled(true)
	adapter = kart.lumo_animation
	_check(is_instance_valid(adapter) and adapter.actor.is_usable(), "Actual original rig loads")
	if not is_instance_valid(adapter) or not adapter.actor.is_usable():
		kart.free()
		quit(1)
		return
	_check(adapter.actor.skeleton.get_bone_count() == 65, "Existing 65-bone identity is retained")
	var model_sha := FileAccess.get_sha256(adapter.actor.MODEL)
	_check(model_sha == ORIGINAL_MODEL_SHA256, "Original shipped GLB bytes are unchanged")
	_check(not adapter.is_processing(), "Vehicle remains the sole visual clock")
	# Rotation/translation makes accidental world-as-local gaze coordinates fail.
	kart.transform = Transform3D(Basis(Vector3.UP, 0.7), Vector3(2.0, 0.0, -3.0))
	original_chassis = kart.transform
	original_scale = kart.scale
	original_node_count = kart.find_children("*", "", true, false).size()
	kart.set_motion(0.0, 0.0, false, false)
	kart.set_driver_runtime_state(false, false, false)
	_step(3)
	var breath_start := _pose("Chest")
	_step(25)
	_check(breath_start.angle_to(_pose("Chest")) > 0.005,
		"Static seated clip receives a visible, restrained chest breath")
	_check(breath_start.angle_to(_pose("Chest")) < 0.03,
		"Breathing cannot become a repeated large body sway")
	var before_attention := _pose("Head")
	_check(adapter.set_attention_target(adapter.actor.to_global(Vector3(4, 1.5, 4))),
		"Real world-space presentation target is accepted")
	_step()
	_check(adapter._attention_angles.x > 0.0 and adapter._attention_angles.x < 0.10,
		"New attention eases in rather than snapping to its bound")
	_step(29)
	_check(adapter._attention_angles.x > 0.27 and adapter._attention_angles.x <= 0.28,
		"World target resolves through the rotated kart and clamps yaw")
	_check(before_attention.angle_to(_pose("Head")) > 0.20,
		"Attention really rotates the existing head bone")
	adapter.set_attention_target(adapter.actor.to_global(Vector3(-4, 1.5, 4)))
	_step(30)
	_check(adapter._attention_angles.x < -0.27 and adapter._attention_angles.x >= -0.28,
		"Rapid opposite selection converges to the latest target")
	adapter.clear_attention_target()
	_step(24)
	_check(adapter._attention_angles.length() < 0.002,
		"Clearing attention returns gently to the original forward pose")
	adapter.set_attention_target(adapter.actor.to_global(Vector3(4, 1.5, -4)))
	_step(24)
	_check(adapter._attention_angles.length() < 0.0001,
		"Behind-head target never turns the neck backwards")
	_check(not adapter.set_attention_target(Vector3(NAN, 0, 0)), "Non-finite target is rejected")
	adapter.clear_attention_target()

	kart.set_motion(18.0, 0.7, true, true)
	kart.set_driver_runtime_state(true, false, false)
	_step(10)
	_check(adapter.landing_amount == 0.0, "Airborne state does not invent a landing")
	kart.set_driver_runtime_state(false, false, false)
	var peak := 0.0
	for frame in range(30):
		_step()
		peak = maxf(peak, adapter.landing_amount)
	_check(peak > 0.45 and peak < 0.60, "Actual landing edge creates one bounded settling response")
	_check(adapter.landing_amount == 0.0, "Grounded samples do not restart landing after 420 ms")
	_step(20)
	_check(adapter.landing_amount == 0.0, "No unprompted repeated landing motion")

	kart.set_driver_runtime_state(true, false, false)
	_step(3)
	kart.set_driver_runtime_state(false, false, false)
	_step(3)
	var landing_before_pause: float = adapter.landing_amount
	var pose_before_pause := _pose("Head")
	var elapsed_before_pause: float = adapter.elapsed
	kart.set_driver_runtime_state(false, false, true)
	_step(30)
	_check(adapter.landing_amount == landing_before_pause and adapter.elapsed == elapsed_before_pause,
		"Pause freezes both secondary motion and original animation time")
	_check(_pose("Head").is_equal_approx(pose_before_pause), "Pause freezes the actual head")
	kart.set_driver_runtime_state(false, false, false)
	_step(20)
	_check(adapter.landing_amount == 0.0, "Resume finishes the interrupted settle without replay")

	kart.reduced_motion = true
	kart.set_driver_runtime_state(false, false, false)
	adapter.set_attention_target(adapter.actor.to_global(Vector3(4, 3, 4)))
	_step(2)
	var reduced_head := _pose("Head")
	var reduced_chest := _pose("Chest")
	kart.set_driver_runtime_state(true, false, false)
	_step(3)
	kart.set_driver_runtime_state(false, false, false)
	_step(30)
	_check(adapter.landing_amount == 0.0 and adapter._attention_angles == Vector2.ZERO,
		"Reduced motion disables gaze, breath and pending landing response")
	_check(_pose("Head").is_equal_approx(reduced_head) and _pose("Chest").is_equal_approx(reduced_chest),
		"Reduced motion restores the original fixed seated pose")
	kart.reduced_motion = false
	kart.set_driver_runtime_state(false, false, false)
	_step()
	_check(adapter.landing_amount == 0.0, "Leaving reduced motion cannot replay an old landing")
	adapter.clear_attention_target()
	kart.set_motion(0.0, 0.0, false, false)
	_step(15)
	_check(adapter.play_menu_behavior("agree_nod"), "Original selection acknowledgement remains usable")
	adapter.set_attention_target(adapter.actor.to_global(Vector3(-4, 1.4, 4)))
	_step(60)
	_check(not adapter.victory and adapter.actor.current_behavior == "kart_seated",
		"Selection gesture returns to seated living motion with both wheel contacts")
	_check(kart.find_children("*", "", true, false).size() == original_node_count,
		"Attention, landing and repeated inputs allocate no extra scene nodes")
	var load_kind: String = adapter.actor.model_load_kind
	kart.free()
	await process_frame
	await process_frame
	_check(int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)) == orphan_baseline,
		"Scene teardown leaves no orphan nodes")
	var report := {"checks": checks, "failures": failures, "worst_hand_contact_mm": worst_contact * 1000.0,
		"landing_peak": peak, "model_load_kind": load_kind,
		"model_unchanged": model_sha == ORIGINAL_MODEL_SHA256, "model_sha256": model_sha,
		"godot": Engine.get_version_info().string, "display": DisplayServer.get_name(),
		"android_test": false, "fps_measured": false}
	DirAccess.make_dir_recursive_absolute(output.get_base_dir())
	var file := FileAccess.open(output, FileAccess.WRITE)
	if file == null:
		push_error("[LumoAttentionLanding] Cannot save report")
		quit(1)
		return
	file.store_string(JSON.stringify(report, "\t") + "\n")
	file.close()
	print("[LumoAttentionLanding] ", JSON.stringify(report))
	quit(0 if failures == 0 else 1)
