extends SceneTree
## Exercises only the integrated production physics tick. Initial placements
## arrange a fair encounter; no subsequent racer movement or rule tick is faked.
const LASSO = preload("res://scripts/games/kart_roadside_lasso.gd")
const POWERTRAIN = preload("res://scripts/games/kart_powertrain.gd")
const CATALOG = preload("res://scripts/games/kart_catalog.gd")
const STEP: float = 1.0 / 60.0
var failures: int = 0
var checks: int = 0
var game
var audio_playbacks: Array[WeakRef] = []
# Diagnostic-only copy: original physics, assertions and 3000 ms deadline retained.
var diagnostic_owners: Array[WeakRef] = []
var diagnostic_audio_nodes: Array[WeakRef] = []
var diagnostic_last_frame_usec: int = 0
var diagnostic_max_frame_gap_usec: int = 0
var diagnostic_last_mix_usec: int = 0
var diagnostic_mix_starts_observed: int = 0
var diagnostic_frames_observed: int = 0
var diagnostic_last_release_log: int = -1000


func _initialize() -> void:
	process_frame.connect(_diagnostic_frame)
	call_deferred("_run")


func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("[KartLassoProduction] " + label)


func _fresh(mode: String) -> void:
	_diagnostic_snapshot("fresh_begin_" + mode)
	if is_instance_valid(game):
		_observe_playbacks(game)
		game.abandoned = true
		game.queue_free()
		await process_frame
	game = load("res://scenes/games/kart_island.tscn").instantiate()
	diagnostic_owners.append(weakref(game))
	root.add_child(game)
	game.set_physics_process(false)
	game.lightweight = true
	await process_frame
	game._start_selected_race({"mode": mode, "driver": "fox", "kart": "comet", "track": "sonnenhafen", "difficulty": "pro"})
	game._end_preview()
	game.countdown = 0.0
	game.racing = true
	game.auto_gas = false
	game.item_box_distances.clear()
	await process_frame
	_diagnostic_snapshot("fresh_ready_" + mode)


func _place_player(at: float, lateral: float, pace: float) -> void:
	game.distance = at
	game.previous_road_distance = at
	game.checkpoint_index = floori(at / (game.track_length / 8.0))
	game.lane = lateral
	game.player.transform = game.world.reset_transform(at, lateral)
	game.player_heading = game._heading(at)
	game.player.rotation = Vector3(0.0, game.player_heading, 0.0)
	game.speed = pace
	game.physical_velocity = Vector3(-sin(game.player_heading), 0.0, -cos(game.player_heading)) * pace
	var pace_factor: float = float(CATALOG.entry(CATALOG.DIFFICULTIES, game.difficulty).speed)
	game.kart_factors = {"speed": pace / POWERTRAIN.top_speed({}, pace_factor), "turn": 2.0, "grip": 2.0}


func _run() -> void:
	print("[AudioLifetimeConfig] ", JSON.stringify({
		"engine": Engine.get_version_info(), "driver": AudioServer.get_driver_name(),
		"mix_rate": AudioServer.get_mix_rate(), "latency": AudioServer.get_output_latency(),
		"max_fps": Engine.max_fps, "low_processor": OS.low_processor_usage_mode,
		"user_data_dir": OS.get_user_data_dir(),
		"source_test_sha256": "9f3c81acfa9c5f864e3032d1d7ec66d3e45b25e11df8c21b519785cf7e05fe3c", "deadline_ms": 3000,
	}))
	await _fresh("training")
	await _player_lifecycle()
	await _fresh("race")
	await _rival_physics()
	_observe_playbacks(game)
	_diagnostic_snapshot("before_final_scene_queue_free")
	game.abandoned = true
	game.queue_free()
	await process_frame
	_check(not audio_playbacks.is_empty(), "Teardown observes actual music, effects or engine playbacks")
	# Godot's audio mixer retires stopped playbacks asynchronously. Observe
	# their actual lifetime rather than guessing that 0.1 s was sufficient.
	# A retained playback still fails the gate with its concrete class name.
	var release_started := Time.get_ticks_msec()
	var release_deadline := Time.get_ticks_msec() + 3000
	_diagnostic_snapshot("release_begin")
	while not _remaining_playbacks().is_empty() and Time.get_ticks_msec() < release_deadline:
		var elapsed := Time.get_ticks_msec() - release_started
		if elapsed - diagnostic_last_release_log >= 200:
			diagnostic_last_release_log = elapsed
			_diagnostic_snapshot("release_poll_%d_ms" % elapsed)
		await process_frame
	_diagnostic_snapshot("release_end_%d_ms" % (Time.get_ticks_msec() - release_started))
	_check(_remaining_playbacks().is_empty(), "All production audio playbacks released: " + str(_remaining_playbacks()))
	if failures == 0:
		print("[KartLassoProduction] PASS: %d assertions; real warning/catch/rival motion, pause, rescue and saved-race rebuild" % checks)
	quit(0 if failures == 0 else 1)


func _observe_playbacks(node: Node) -> void:
	if node is AudioStreamPlayer and node.has_stream_playback():
		audio_playbacks.append(weakref(node.get_stream_playback()))
		diagnostic_audio_nodes.append(weakref(node))
		print("[AudioLifetimeObserve] ", JSON.stringify({
			"node_path": str(node.get_path()), "node_id": node.get_instance_id(),
			"playback_id": node.get_stream_playback().get_instance_id(),
			"stream": node.stream.resource_path, "player_playing": node.playing,
			"stream_paused": node.stream_paused,
		}))
	for child in node.get_children():
		_observe_playbacks(child)


func _remaining_playbacks() -> Array[String]:
	var remaining: Array[String] = []
	for reference in audio_playbacks:
		var playback = reference.get_ref()
		if playback != null:
			remaining.append(playback.get_class())
	return remaining


func _player_lifecycle() -> void:
	var encounter = game.roadside_lasso
	_check(encounter != null and encounter == game.world.get_node_or_null("RoadsideLasso"), "Production world owns the active roadside node")
	if encounter == null:
		return
	var line: float = float(encounter.layout[0].distance)
	var lateral: float = float(encounter.layout[0].lateral)
	_place_player(line - 90.0, lateral, 40.0)
	game.auto_gas = true
	var warned_at: float = -1.0
	var paused_checked: bool = false
	for frame in range(240):
		var target: Vector3 = game.world.position_at(game.previous_road_distance + 12.0, lateral)
		var direction: Vector3 = target - game.player.position
		game.steering = clampf(-angle_difference(game.player_heading, atan2(-direction.x, -direction.z)) * 2.0, -1.0, 1.0)
		var clock_before: float = encounter.clock
		game._physics_process(STEP)
		if frame == 0:
			_check(is_equal_approx(encounter.clock - clock_before, STEP), "Exactly one roadside tick runs per production physics tick")
		if warned_at < 0.0 and game.message.text.begins_with("Lasso rechts"):
			warned_at = encounter.clock
			_check(encounter.views[0].marker.visible and encounter.views[0].beams[0].visible, "Production warning enables the matching target and rope")
		if warned_at >= 0.0 and not paused_checked:
			var position: Vector3 = game.player.position
			var clock: float = encounter.clock
			var rules_clock: float = float(encounter.rules.racers.player.clock)
			game.paused = true
			game._physics_process(0.75)
			_check(game.player.position == position and encounter.clock == clock, "Paused production tick moves neither kart nor encounter")
			_check(float(encounter.rules.racers.player.clock) == rules_clock, "Paused production tick freezes the warning clock")
			game.paused = false
			paused_checked = true
		if encounter.catches > 0:
			break
		if frame % 30 == 29:
			await process_frame
	_check(encounter.catches == 1, "Production player is caught once after a real lane crossing")
	_check(warned_at >= 0.0 and encounter.clock - warned_at >= LASSO.RULES.WARNING_SECONDS, "Visible warning precedes the real catch by the required time")
	_check(game.speed < 30.0 and game.physical_velocity.length() < 30.0, "Catch immediately reduces both actual player motion fields")
	_check(is_equal_approx(float(game.player.get_meta(LASSO.SPEED_META)), LASSO.RULES.SPEED_FACTOR), "Player drive target shares the bounded hold factor")
	# Save while actually caught, then use the real saved-race rebuild path.
	game._save_session()
	var previous_node_id: int = encounter.get_instance_id()
	game._resume_saved_race()
	await process_frame
	encounter = game.roadside_lasso
	_check(encounter.get_instance_id() != previous_node_id and encounter.rules.racers.is_empty(), "Saved race creates a fresh encounter node and state")
	_check(float(game.player.get_meta(LASSO.SPEED_META, 0.0)) == 1.0 and game.paused, "Restored race is paused with no inherited lasso hold")
	game._resume()
	game._physics_process(STEP)
	_check(encounter.catches == 0 and float(game.player.get_meta(LASSO.SPEED_META, 0.0)) == 1.0, "Restored position cannot invent an immediate catch")
	# Seed an actual new approach by restarting the production race. The reset
	# itself must clear a live catch even before its normal 0.65 s expiration.
	await _fresh("training")
	encounter = game.roadside_lasso
	line = float(encounter.layout[0].distance)
	lateral = float(encounter.layout[0].lateral)
	_place_player(line - 90.0, lateral, 40.0)
	game.auto_gas = true
	for frame in range(240):
		var target: Vector3 = game.world.position_at(game.previous_road_distance + 12.0, lateral)
		var direction: Vector3 = target - game.player.position
		game.steering = clampf(-angle_difference(game.player_heading, atan2(-direction.x, -direction.z)) * 2.0, -1.0, 1.0)
		game._physics_process(STEP)
		if encounter.catches > 0:
			break
	_check(encounter.catches == 1, "Rescue scenario begins with a real catch")
	var reset_count: int = game.reset_count
	game._reset_kart()
	game._physics_process(STEP)
	_check(game.reset_count == reset_count + 1, "Production rescue ran")
	_check(float(encounter.rules.racers.player.remaining) == 0.0 and float(game.player.get_meta(LASSO.SPEED_META, 0.0)) == 1.0, "Rescue clears a live hold in the next production tick")


func _rival_physics() -> void:
	var encounter = game.roadside_lasso
	var line: float = float(encounter.layout[0].distance)
	var lateral: float = float(encounter.layout[0].lateral)
	# The rightmost production driver naturally aims for the marked side lane.
	var index: int = 4
	var rival = game.opponents[index]
	_place_player(line - 45.0, -3.2, 0.0)
	for other in range(game.opponents.size()):
		var at: float = line - 220.0 - other * 18.0
		if other == index:
			at = line - 120.0
		game.opponent_distances[other] = at
		game.opponent_lanes[other] = lateral if other == index else -2.8 + other * 1.35
		game.opponent_headings[other] = game._heading(at)
		game.opponents[other].transform = game.world.reset_transform(at, game.opponent_lanes[other])
		game.opponents[other].set_motion(40.0, 0.0, false, false)
	var caught: bool = false
	var measured_before: float = 0.0
	var speed_after: float = 0.0
	var warned_at: float = -1.0
	for frame in range(300):
		var before: Vector3 = rival.position
		game._physics_process(STEP)
		if warned_at < 0.0 and not encounter.rules.racers["rival_4"].armed.is_empty():
			warned_at = encounter.clock
			_check(encounter.views[0].marker.visible and encounter.views[0].beams[0].visible, "Approaching rival enables a visible warning without a player warning")
		if float(rival.get_meta(LASSO.SPEED_META, 1.0)) < 1.0:
			var step: Vector3 = rival.position - before
			measured_before = Vector2(step.x, step.z).length() / STEP
			speed_after = rival.motion_speed
			caught = true
			break
		if frame % 30 == 29:
			await process_frame
	_check(caught, "An actual production rival drives through the marked lane and is caught")
	if not caught:
		return
	_check(warned_at >= 0.0 and encounter.clock - warned_at >= LASSO.RULES.WARNING_SECONDS, "Real rival has the same visible warning time as the player")
	_check(absf(speed_after - measured_before * LASSO.RULES.SPEED_FACTOR) < 0.02, "Rival observed momentum receives the same immediate 68 percent reduction")
	var view: Dictionary = encounter.views[0]
	var expected: Vector3 = (view.root as Node3D).to_local(rival.global_position) + Vector3.UP * 0.6
	_check(view.marker.visible and view.beams[0].visible and view.ring.position.distance_to(expected) < 0.01, "Visible catch rope follows the caught rival, not the nearby player")
	var before: Vector3 = rival.position
	game._physics_process(STEP)
	var moved: Vector3 = rival.position - before
	var held_speed: float = Vector2(moved.x, moved.z).length() / STEP
	_check(held_speed < measured_before * 0.75 and held_speed > measured_before * 0.45, "Next production rival step physically travels at the reduced speed")
	var held_position: Vector3 = rival.position
	var remaining: float = float(encounter.rules.racers["rival_4"].remaining)
	game.paused = true
	game._physics_process(0.75)
	_check(rival.position == held_position and float(encounter.rules.racers["rival_4"].remaining) == remaining, "Production pause freezes rival position and remaining hold")
	game.paused = false
	var caught_clock: float = encounter.clock
	while encounter.clock - caught_clock < 0.8:
		game._physics_process(STEP)
	_check(float(rival.get_meta(LASSO.SPEED_META, 0.0)) == 1.0, "Rival hold expires through the production clock without repeated damping")
	_check(float(encounter.rules.racers["rival_4"].immunity) > 0.0, "Rival receives the same recovery immunity")
	print("[KartLassoProductionMotion] before=%.3f immediate=%.3f next_physical=%.3f" % [measured_before, speed_after, held_speed])


func _diagnostic_frame() -> void:
	var now := Time.get_ticks_usec()
	if diagnostic_last_frame_usec > 0:
		diagnostic_max_frame_gap_usec = maxi(diagnostic_max_frame_gap_usec, now - diagnostic_last_frame_usec)
	diagnostic_last_frame_usec = now
	diagnostic_frames_observed += 1
	var estimated_mix_usec := now - int(AudioServer.get_time_since_last_mix() * 1000000.0)
	if estimated_mix_usec - diagnostic_last_mix_usec > 2000:
		diagnostic_mix_starts_observed += 1
		diagnostic_last_mix_usec = estimated_mix_usec


func _diagnostic_snapshot(phase: String) -> void:
	var playbacks: Array[Dictionary] = []
	for reference in audio_playbacks:
		var playback = reference.get_ref()
		if playback != null:
			playbacks.append({
				"id": playback.get_instance_id(), "class": playback.get_class(),
				"reference_count_including_this_temporary_read": playback.get_reference_count(),
				"stream_playing": playback.is_playing(), "position": playback.get_playback_position(),
			})
	var live_owners: Array[int] = []
	for reference in diagnostic_owners:
		var owner = reference.get_ref()
		if owner != null:
			live_owners.append(owner.get_instance_id())
	var live_audio_nodes: Array[int] = []
	for reference in diagnostic_audio_nodes:
		var player = reference.get_ref()
		if player != null:
			live_audio_nodes.append(player.get_instance_id())
	print("[AudioLifetimeDiag] ", JSON.stringify({
		"phase": phase, "ticks_ms": Time.get_ticks_msec(),
		"observed_playbacks": audio_playbacks.size(), "remaining": playbacks,
		"live_game_owners": live_owners, "live_observed_audio_nodes": live_audio_nodes,
		"tree_node_count": get_node_count(), "process_frames": Engine.get_process_frames(),
		"frames_observed": diagnostic_frames_observed,
		"maximum_frame_gap_ms": diagnostic_max_frame_gap_usec / 1000.0,
		"mix_starts_observed_at_frame_samples": diagnostic_mix_starts_observed,
		"estimated_last_mix_usec": diagnostic_last_mix_usec,
		"seconds_since_mix": AudioServer.get_time_since_last_mix(),
		"seconds_to_next_mix": AudioServer.get_time_to_next_mix(),
	}))
