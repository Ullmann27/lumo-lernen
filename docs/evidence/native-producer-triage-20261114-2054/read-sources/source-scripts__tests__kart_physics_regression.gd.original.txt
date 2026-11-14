extends SceneTree
## Rails are real walls on every course, drift has two turbo tiers, driving against the course
## is announced, and neither reversing over the line nor jumping ahead creates lap progress.
const STEP: float = 1.0 / 60.0
const POWERTRAIN = preload("res://scripts/games/kart_powertrain.gd")
const SCENE_TEARDOWN = preload("res://scripts/tests/helpers/kart_scene_teardown.gd")
var game
## An assertion aborts its function. PASS requires every check to finish.
var completed_checks: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _start(mode: String, track: String) -> void:
	game._start_selected_race(
		{"mode": mode, "driver": "fox", "kart": "comet", "track": track, "difficulty": "flott"}
	)
	# Finish the new grid-roll preview before a probe sets its own heading.
	# Otherwise the first manual physics tick restores the forward start pose.
	game._end_preview()
	game.countdown = 0
	game.racing = true
	await process_frame


func _steer_towards(target: Vector3) -> void:
	var direction: Vector3 = target - game.player.position
	var heading: float = atan2(-direction.x, -direction.z)
	game.steering = clampf(-angle_difference(game.player_heading, heading) * 2.1, -1, 1)


func _face(heading: float, speed: float) -> void:
	game.player_heading = heading
	game.speed = speed
	game.physical_velocity = Vector3(-sin(heading), 0, -cos(heading)) * speed


func _test_walls(track: String) -> void:
	for side in [1.0, -1.0]:
		await _start("training", track)
		var start_distance: float = game.distance
		var widest: float = 0.0
		for frame in range(300):
			# Aim far beyond the rail at full turbo speed: the worst case for tunnelling.
			_steer_towards(game.world.position_at(game.previous_road_distance + 14.0, side * 14.0))
			game.boost_time = 3.0
			game._physics_process(STEP)
			widest = maxf(widest, absf(game.lane))
		var wall: float = game.WORLD.WALL_LATERAL
		assert(
			widest <= wall + 0.02, "%s: the kart stays inside the rail (%.2f m)" % [track, widest]
		)
		assert(game.wall_contacts > 10, "%s: the rail was actually hit" % track)
		assert(game.reset_count == 0, "%s: a rail hit never drops the kart" % track)
		assert(game.distance - start_distance > 25.0, "%s: the kart slides along the rail" % track)
		print(
			(
				"[KartPhysics] %s side %+d: widest %.2f m, %d wall contacts, %.0f m along the rail"
				% [track, int(side), widest, game.wall_contacts, game.distance - start_distance]
			)
		)
	completed_checks += 1


func _test_drift_tiers() -> void:
	await _start("training", "sonnenhafen")
	_face(game._heading(0), 15.0)
	game.drifting = true
	var blue_frames: int = roundi(1.0 / (STEP * POWERTRAIN.PACE_SCALE))
	for frame in range(blue_frames):
		game.steering = 1.0
		game._physics_process(STEP)
	assert(game.drift_charge >= 0.8 and game.drift_charge < 1.8, "A controlled drift charges blue at the live pace scale")
	game.boost_time = 0
	game._release_drift()
	assert(is_equal_approx(game.boost_time, 1.0) and game.drift_tier_count == [1, 0])
	assert("Blauer" in game.message.text)
	game.drifting = true
	game.drift_charge = 1.9
	game.boost_time = 0
	game._release_drift()
	assert(game.boost_time >= 1.8 and game.drift_tier_count == [1, 1], "A long drift is orange")
	game.drifting = true
	game.drift_charge = 0.5
	game.boost_time = 0
	game._release_drift()
	assert(game.boost_time == 0 and game.drift_tier_count == [1, 1], "A short drift gives nothing")
	completed_checks += 1


func _test_wrong_way() -> void:
	await _start("training", "sonnenhafen")
	var d: float = game.track_length * 0.25
	game.player.transform = game.world.reset_transform(d)
	game.previous_road_distance = d
	game.distance = d
	_face(game._heading(d) + PI, 12.0)
	for frame in range(150):
		_steer_towards(game.world.position_at(game.previous_road_distance - 12.0))
		game._physics_process(STEP)
	assert(game.wrong_way, "Driving backwards is detected")
	assert("Falsche Richtung" in game.message.text, "Driving backwards is announced")
	_face(game._heading(game.previous_road_distance), 12.0)
	for frame in range(30):
		_steer_towards(game.world.position_at(game.previous_road_distance + 12.0))
		game._physics_process(STEP)
	assert(not game.wrong_way, "The warning clears once the kart turns around")
	completed_checks += 1


func _test_lap_validity() -> void:
	await _start("time_trial", "sonnenhafen")
	_face(game._heading(0) + PI, 10.0)
	for frame in range(240):
		_steer_towards(game.world.position_at(game.previous_road_distance - 12.0))
		game._physics_process(STEP)
	assert(game.distance < 1.0 and game.checkpoint_index == 0, "Reversing over the line is no lap")
	assert(not game.finished)
	var before: float = game.distance
	game.player.position = game.world.position_at(game.track_length * 0.9)
	game._physics_process(STEP)
	assert(game.distance - before < 5.0, "Jumping ahead gives no progress")
	assert(game.checkpoint_index == 0)
	assert(not game.finished)
	completed_checks += 1


func _test_pedals() -> void:
	await _start("training", "sonnenhafen")
	game.auto_gas = false
	_face(game._heading(0), 0.0)
	for frame in range(60):
		game._physics_process(STEP)
	assert(game.speed < 0.5, "Without GAS the kart does not drive off")
	game.gas_held = true
	for frame in range(90):
		game._physics_process(STEP)
	assert(game.speed > 10.0, "Holding GAS accelerates (%.1f m/s)" % game.speed)
	game.gas_held = false
	game.control_brake = 1.0
	for frame in range(90):
		game._physics_process(STEP)
	assert(game.speed < 1.0, "BREMSE stops the kart")
	for frame in range(90):
		game._physics_process(STEP)
	assert(game.speed < -1.0, "Holding BREMSE while stopped reverses slowly")
	game.control_brake = 0.0
	# The pedal pad sits fully on screen without overlapping buttons.
	game._update_hud()
	await process_frame
	var screen: Rect2 = root.get_visible_rect()
	var rects: Array[Rect2] = []
	for button in [
		game.gas_button, game.brake_button, game.drift_button, game.boost_button, game.item_button
	]:
		var rect: Rect2 = button.get_global_rect()
		assert(screen.encloses(rect), "Pedal pad button on screen")
		for other in rects:
			assert(not rect.grow(-4).intersects(other), "Pad buttons do not overlap")
		rects.append(rect)
	assert(not game.joystick.get_global_rect().intersects(rects[0]), "Stick and GAS are apart")
	game.auto_gas = true
	completed_checks += 1


func _test_boost_response() -> void:
	await _start("training", "sonnenhafen")
	_face(game._heading(0), 5.0)
	game.steering = 0.6
	game._physics_process(STEP)
	var unboosted_delta: float = game.speed - 5.0

	await _start("training", "sonnenhafen")
	game._update_hud()
	game.muted = false
	game.host_sound_enabled = true
	game.kart_audio.set_muted(false)
	_face(game._heading(0), 5.0)
	game.steering = 0.6
	var speed_before: float = game.speed
	var effect_cursor_before: int = int(game.kart_audio.get("_effect_cursor"))
	var effect_players: Array = game.kart_audio.get("_effects")
	var boost_audio_player: AudioStreamPlayer = (
		effect_players[effect_cursor_before] as AudioStreamPlayer
	)
	var input_usec: int = Time.get_ticks_usec()
	game.boost_button._press()
	var accepted_usec: int = Time.get_ticks_usec()
	assert(game.boosts == 0 and game.boost_time == 3.2, "Touch accepts and consumes one boost")
	game._physics_process(STEP)
	var physics_usec: int = Time.get_ticks_usec()
	var speed_delta: float = game.speed - speed_before
	var feedback_visible: bool = game.player.motion_boost
	var effect_cursor_after: int = int(game.kart_audio.get("_effect_cursor"))
	assert(
		speed_delta > unboosted_delta * 1.5,
		(
			"Boost increases speed on its first physics step (%.3f vs %.3f)"
			% [speed_delta, unboosted_delta]
		)
	)
	assert(feedback_visible, "Boost flame is active on the first physics step")
	assert(
		effect_cursor_after == (effect_cursor_before + 1) % effect_players.size(),
		"Boost sound starts on accepted input"
	)
	assert(boost_audio_player.playing, "Boost sound begins on accepted input")
	assert(
		absf(game.player_heading - game._heading(0)) > 0.0001, "Steering remains active with boost"
	)
	print(
		(
			(
				"[KartBoost] input→accepted %d µs, accepted→physics %d µs, "
				+ "speed +%.3f m/s (normal +%.3f), VFX/audio active"
			)
			% [
				accepted_usec - input_usec,
				physics_usec - accepted_usec,
				speed_delta,
				unboosted_delta
			]
		)
	)
	game.boost_button._release()
	var boost_time_after_first_tap: float = game.boost_time
	game.boost_button._press()
	assert(
		game.boosts == 0 and game.boost_time == boost_time_after_first_tap,
		"A second tap cannot queue an empty boost"
	)
	game.boost_button._release()
	completed_checks += 1


func _test_skill_resonance_rings() -> void:
	await _start("training", "bergwelt")
	assert(game.item_boxes.size() == 5, "All five racing pickups must be real resonance rings")
	assert(game.item_box_laterals.size() == 5, "The skill policy needs the actual ideal crossing lane")
	for ring in game.item_boxes:
		assert(str(ring.get_meta("lumo_racing_pickup", "")) == "skill_resonance",
			"Random violet mystery prisms must not masquerade as racing resonance rings")
		assert(ring.get_child_count() == 1, "A ring uses only one opaque draw surface")
		var halo: MeshInstance3D = ring.get_node("ResonanceHalo")
		assert(halo.mesh is TorusMesh, "Real luminous ring geometry replaces box facets")
		assert(halo.material_override is StandardMaterial3D)
		var finish: StandardMaterial3D = halo.material_override
		assert(finish.emission_enabled and finish.emission_energy_multiplier <= 2.0,
			"Visible low-poly racing arch without extreme mobile bloom")
		assert(halo.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
	# Deprecated callers cannot receive random / rank-biased loot.
	assert(game._item_pool_for_place(1) == ["boost"])
	assert(game._item_pool_for_place(6) == ["boost"])
	game.item = ""
	game.racing = true
	game.countdown = 0.0
	game.speed = 20.0
	game.drift_charge = 1.5
	game.lane = game.item_box_laterals[0]
	game.player.position = game.item_boxes[0].position
	game._track_events()
	assert(not game.item.is_empty(), "Crossing a ring awards an actual tier by driving skill")
	assert(game.item_box_collected.has(0), "Used resonance ring remains hidden this lap")
	game._sync_item_box_visibility()
	assert(not game.item_boxes[0].visible, "No repeat farming on the same lap")
	completed_checks += 1


func _test_rival_item_tactics() -> void:
	await _start("race", "bergwelt")
	assert(game.opponent_items.size() == 5)
	assert(game.opponent_boost_times.size() == 5)
	assert(game.opponent_shield_times.size() == 5)

	# Keep physical transforms, headings, motion and race progress consistent.
	# The former fixture changed only progress and passed an invented gap while
	# the actual cars stayed in the crowded starting grid.
	var straight: float = -1.0
	for candidate in range(80, int(game.track_length) - 100, 5):
		var at: float = float(candidate)
		var forward: Vector3 = game.world.forward(at)
		var safe: bool = true
		for offset in [8.0, 20.0, 36.0]:
			if forward.angle_to(game.world.forward(at + offset)) > 0.10:
				safe = false
		if safe and not game.world.in_gap(at) and game.world.ramp_height(at) == 0.0:
			straight = at
			break
	assert(straight >= 0.0, "Bergwelt must contain a measurable clear straight for boost tactics")
	for i in range(game.opponents.size()):
		var at: float = straight if i == 0 else straight - 80.0 - i * 8.0
		game.opponents[i].transform = game.world.reset_transform(at, 0.0)
		game.opponent_distances[i] = at
		game.opponent_lanes[i] = 0.0
		game.opponent_headings[i] = game._heading(at)
		game.opponents[i].set_motion(18.0, 0.0, false, false)
	game.opponent_items[0] = "boost"
	game.opponent_boost_times[0] = 0.0
	game.distance = straight + 6.0
	game.speed = 0.0
	game.player.transform = game.world.reset_transform(game.distance, 0.0)
	game._update_rival_item_tactics(0, game.player.position - game.opponents[0].position, STEP)
	assert(game.opponent_items[0] == "boost", "A blocked rival must not boost into the stopped player")
	assert(game.opponent_boost_times[0] == 0.0)
	game.distance = straight + 70.0
	game.player.transform = game.world.reset_transform(game.distance, 0.0)
	game._update_rival_item_tactics(0, game.player.position - game.opponents[0].position, STEP)
	assert(game.opponent_items[0].is_empty())
	assert(game.opponent_boost_times[0] > 0.0, "Trailing rival boosts through a genuinely clear corridor")

	game.player.transform = game.world.reset_transform(straight + 6.0, 0.0)
	game.opponents[1].transform = game.world.reset_transform(straight + 4.0, 1.0)
	game.opponent_items[1] = "shield"
	game.opponent_shield_times[1] = 0.0
	game._update_rival_item_tactics(1, game.player.position - game.opponents[1].position, STEP)
	assert(game.opponent_shield_times[1] > 0.0, "Nearby rival can protect itself")

	game.opponent_stuns[1] = 0.0
	game.item = "pulse"
	game.player.position = game.opponents[1].position
	game._use_item()
	assert(game.opponent_stuns[1] == 0.0, "Rival shield blocks the player's pulse")

	game.hit_timer = 0.0
	game.shield_time = 0.0
	game.opponents[2].position = game.player.position + Vector3.RIGHT * 4.0
	game.opponent_items[2] = "pulse"
	var pulse_gap: Vector3 = game.player.position - game.opponents[2].position
	game._update_rival_item_tactics(2, pulse_gap, STEP)
	assert(
		game.hit_timer == 0.0 and game.opponent_pulse_warning_times[2] > 0.0,
		"Rival pulse must warn before it can affect the player"
	)
	game._update_rival_item_tactics(2, pulse_gap, game.RIVAL_PULSE_WARNING_SECONDS + STEP)
	assert(game.hit_timer > 0.0, "Rival pulse can pressure a player who stays in range")

	game.hit_timer = 0.0
	game.shield_time = 4.0
	game.opponents[3].position = game.player.position + Vector3.LEFT * 4.0
	game.opponent_items[3] = "pulse"
	pulse_gap = game.player.position - game.opponents[3].position
	game._update_rival_item_tactics(3, pulse_gap, STEP)
	game._update_rival_item_tactics(3, pulse_gap, game.RIVAL_PULSE_WARNING_SECONDS + STEP)
	assert(game.hit_timer == 0.0, "Player shield blocks a telegraphed rival pulse")
	completed_checks += 1


func _test_wolkenweg_split_route() -> void:
	await _start("training", "bergwelt")
	var midpoint: float = game.track_length * 0.800
	var raised_height: float = game.world.alternate_route_height(midpoint, -3.0)
	var main_height: float = game.world.alternate_route_height(midpoint, 3.0)
	assert(raised_height > 1.5, "Wolkenweg must provide a physical raised left lane")
	assert(main_height < 0.01, "Main lane must stay on the original road surface")

	game.player.position = game.world.position_at(midpoint, -3.0)
	game.previous_road_distance = midpoint
	game.distance = midpoint
	game.lane = -3.0
	var raised_road: Dictionary = game.world.sample_road(game.player.position, midpoint)
	var raised_base: float = float(raised_road.height) + 0.035
	assert(game._move_vertically(raised_road, midpoint, STEP))
	assert(
		game.player.position.y > raised_base + 1.5,
		"Player kart physically climbs onto the Wolkenweg deck"
	)

	game.player.position = game.world.position_at(midpoint, 3.0)
	game.previous_road_distance = midpoint
	game.distance = midpoint
	game.lane = 3.0
	game.airborne = false
	var main_road: Dictionary = game.world.sample_road(game.player.position, midpoint)
	var main_base: float = float(main_road.height) + 0.035
	assert(game._move_vertically(main_road, midpoint, STEP))
	assert(
		absf(game.player.position.y - main_base) < 0.05,
		"Parallel main lane remains physically on the original road"
	)
	print(
		(
			"[KartSplit] PASS: Wolkenweg raised %.2f m while main lane stayed at %.2f m"
			% [raised_height, main_height]
		)
	)
	completed_checks += 1


func _test_boost_gates_and_restart() -> void:
	await _start("training", "sonnenhafen")
	game.boosts = 1
	game.racing = false
	game.countdown = 1.0
	game._update_hud()
	assert(game.boost_button.disabled, "Boost is visibly locked during the countdown")
	game._boost()
	assert(game.boosts == 1 and game.boost_time == 0, "Countdown cannot queue a boost")
	game.racing = true
	game.paused = true
	game._update_hud()
	assert(game.boost_button.disabled, "Boost is visibly locked while paused")
	game._boost()
	assert(game.boosts == 1 and game.boost_time == 0, "Pause cannot queue a boost")
	game.paused = false
	game._physics_process(STEP)
	assert(game.boosts == 1 and game.boost_time == 0, "Paused input stays rejected after resume")
	game.finished = true
	game._update_hud()
	assert(game.boost_button.disabled, "Boost is visibly locked after finishing")
	game._boost()
	assert(game.boosts == 1 and game.boost_time == 0, "Finished race cannot queue a boost")
	game.finished = false
	game.boosts = 0
	game._boost()
	assert(game.boost_time == 0, "An empty boost slot cannot activate later")
	await _start("training", "sonnenhafen")
	assert(game.boosts == 1 and game.boost_time == 0, "Restart resets charges and active boost")
	completed_checks += 1


func _track_frame(forward: Vector3, normal: Vector3, mirrored: bool = false) -> Basis:
	var tangent: Vector3 = forward.normalized()
	var up: Vector3 = (normal - tangent * normal.dot(tangent)).normalized()
	var right: Vector3 = tangent.cross(up).normalized()
	if mirrored:
		right = -right
	return Basis(right, up, -tangent)


func _test_boost_chevrons_follow_travel() -> void:
	var samples: Array[Dictionary] = [
		{"name": "straight", "basis": Basis.IDENTITY},
		{"name": "curve", "basis": _track_frame(Vector3(1, 0, -1), Vector3.UP)},
		{"name": "sloped", "basis": _track_frame(Vector3(0.8, 0.5, -0.2), Vector3.UP)},
		{"name": "mirrored", "basis": _track_frame(Vector3(0.8, 0.5, -0.2), Vector3.UP, true)},
		{"name": "vertical", "basis": _track_frame(Vector3.UP, Vector3.RIGHT)}
	]
	for sample in samples:
		var basis: Basis = sample.basis
		var forward: Vector3 = (-basis.z).normalized()
		var right: Vector3 = basis.x.normalized()
		var left_arm: Dictionary = game._chevron_arm_geometry(basis, -1.0)
		var right_arm: Dictionary = game._chevron_arm_geometry(basis, 1.0)
		for geometry in [left_arm, right_arm]:
			assert(
				Vector3(geometry.direction).dot(forward) > 0.45,
				"%s chevron arm must converge in local travel direction" % sample.name
			)
			assert(
				absf(Vector3(geometry.direction).dot(Vector3(basis.y))) < 0.001,
				"%s chevron arm stays on the track plane" % sample.name
			)
		assert(
			Vector3(left_arm.offset).dot(right) < Vector3(right_arm.offset).dot(right),
			"%s chevron arms stay mirrored left/right" % sample.name
		)
	completed_checks += 1


func _test_boost_pad_and_airborne() -> void:
	await _start("training", "sonnenhafen")
	_face(game._heading(0), 5.0)
	game.distance = game.track_length * 0.12 + 1.1
	game._track_events()
	assert(game.boost_time >= 1.0, "Crossing a boost pad activates turbo")
	var pad_speed: float = game.speed
	game._physics_process(STEP)
	assert(game.speed > pad_speed, "Boost pad accelerates on its first physics step")

	await _start("training", "sonnenhafen")
	_face(game._heading(0), 5.0)
	game.airborne = true
	game.player.position.y += 2.0
	game._boost()
	var airborne_speed: float = game.speed
	game._physics_process(STEP)
	assert(game.speed > airborne_speed, "Boost also accelerates during a ramp jump")
	assert(game.airborne, "Boost does not cancel the jump")
	completed_checks += 1


func _run() -> void:
	DirAccess.remove_absolute("user://kart_sonnenhafen_session.cfg")
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/games/kart_island.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.lightweight = true
	# Drive deterministically even after a previous manual-pedal test saved preferences.
	game.auto_gas = true
	await process_frame
	for track in game.CATALOG.TRACKS:
		await _test_walls(str(track.id))
	await _test_drift_tiers()
	await _test_wrong_way()
	await _test_lap_validity()
	await _test_boost_response()
	await _test_boost_gates_and_restart()
	await _test_boost_pad_and_airborne()
	await _test_boost_chevrons_follow_travel()
	await _test_skill_resonance_rings()
	await _test_rival_item_tactics()
	await _test_wolkenweg_split_route()
	await _test_pedals()
	var expected_checks: int = game.CATALOG.TRACKS.size() + 11
	game.abandoned = true
	if not (await SCENE_TEARDOWN.release_scene(self, game, "[KartPhysics]")):
		push_error("[KartPhysics] FAIL: scene/audio teardown incomplete")
		quit(1)
		return
	DirAccess.remove_absolute("user://kart_sonnenhafen_session.cfg")
	if completed_checks != expected_checks:
		print("[KartPhysics] FAIL: %d of %d checks completed" % [completed_checks, expected_checks])
		quit(1)
		return
	print(
		(
			"[KartPhysics] PASS: rail walls on every course at full turbo, sliding contact, "
			+ "blue/orange drift tiers, wrong-way warning, reverse line and jump-ahead give no lap, "
			+ "GAS/BREMSE pedals with reverse, on-screen pad, forward-facing boost chevrons, "
			+ "and a physical Wolkenweg split route"
		)
	)
	quit(0)
