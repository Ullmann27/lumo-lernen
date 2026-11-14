extends SceneTree
## New Quiz presenter verification. --fixture is explicitly a UI/transport
## fixture, never a Dart/rule/persistence pass. --authority requires the separate
## production Dart quiz_native_authority.dart process and its isolated directory.
const SCENE := "res://scenes/games/quiz_studio.tscn"
const FIXTURE_TOKEN := "b1111111111111111111111111111111"
var table
var bridge
var output := ""
var authority_dir := ""
var fixture := false
var capture := false
var checks := 0
var failures: Array[String] = []
var inputs: Array[Dictionary] = []
var captures: Array[Dictionary] = []
var state_trace: Array[Dictionary] = []
var lifecycle_active := true
var pause_epoch := 0
var frames := 0
var previous_mouse_emulation := false
var previous_touch_emulation := false
var source_before: Dictionary = {}

class FixtureBridge extends RefCounted:
	var value: Dictionary = {}
	var requests: Array[Dictionary] = []
	var accept := true
	var finished := false
	func getTableState() -> String:
		return JSON.stringify(value)
	func submitTableAction(payload: String) -> bool:
		var parsed: Variant = JSON.parse_string(payload)
		if not parsed is Dictionary or not accept:
			return false
		requests.append(parsed)
		return true
	func returnToApp(destination: String, payload: String) -> bool:
		finished = destination == "games" and payload.is_empty()
		return finished

class DartDiskBridge extends RefCounted:
	var folder := ""
	var requests: Array[Dictionary] = []
	var finished := false
	func getTableState() -> String:
		var path := folder + "/public-state.json"
		return FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else "{}"
	func submitTableAction(payload: String) -> bool:
		var parsed: Variant = JSON.parse_string(payload)
		if not parsed is Dictionary:
			return false
		var path := folder + "/request.json"
		var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
		if file == null:
			return false
		file.store_string(payload)
		file.flush()
		var error := file.get_error()
		file.close()
		if error != OK or DirAccess.rename_absolute(path + ".tmp", path) != OK:
			return false
		requests.append(parsed)
		return true
	func returnToApp(destination: String, payload: String) -> bool:
		finished = destination == "games" and payload.is_empty()
		return finished


func _initialize() -> void:
	fixture = "--fixture" in OS.get_cmdline_user_args()
	capture = "--capture" in OS.get_cmdline_user_args()
	output = OS.get_environment("LUMO_CAPTURE_DIR")
	authority_dir = OS.get_environment("LUMO_QUIZ_QA_DIR")
	call_deferred("_run")


func _check(value: bool, message: String) -> bool:
	checks += 1
	if not value:
		failures.append(message)
		push_error("[QuizStudioRuntime] " + message)
	return value


func _write(path: String, value: Variant) -> void:
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		_check(false, "Open QA output " + path.get_file())
		return
	file.store_string(JSON.stringify(value))
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK or DirAccess.rename_absolute(path + ".tmp", path) != OK:
		_check(false, "Atomic QA output " + path.get_file())


func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return raw if raw is Dictionary else {}


func _frame() -> void:
	if not fixture:
		# Only the explicitly isolated test transport is written. This is not a
		# production save or a fabricated acknowledgement/answer.
		var path := authority_dir + "/lifecycle.json"
		var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
		if file != null:
			file.store_string(JSON.stringify({"active": lifecycle_active, "stamp": int(Time.get_unix_time_from_system() * 1000), "pauseEpoch": pause_epoch}))
			file.flush()
			file.close()
			DirAccess.rename_absolute(path + ".tmp", path)
	await process_frame
	if capture:
		await RenderingServer.frame_post_draw
	frames += 1


func _frames(count: int) -> void:
	for i in range(count):
		await _frame()


func _until(predicate: Callable, message: String, seconds: float = 10.0) -> bool:
	var until := Time.get_ticks_msec() + int(seconds * 1000)
	while Time.get_ticks_msec() < until:
		if predicate.call():
			return _check(true, message)
		await _frame()
	return _check(false, message)


func _physical(control: Control) -> Rect2:
	var transform := control.get_global_transform_with_canvas()
	var factor := Vector2(root.size) / root.get_visible_rect().size
	return Rect2((transform * Vector2.ZERO) * factor, control.size * transform.get_scale() * factor)


func _exposed(control: Control) -> bool:
	if not control.is_visible_in_tree():
		return false
	var rect := _physical(control)
	var factor := Vector2(root.size) / root.get_visible_rect().size
	var safe_rect := Rect2(table._safe_rect.position * factor, table._safe_rect.size * factor)
	if not safe_rect.grow(0.05).encloses(rect):
		return false
	var parent := control.get_parent()
	while parent != null:
		if parent is Control and parent.clip_contents and not _physical(parent).grow(0.05).encloses(rect):
			return false
		parent = parent.get_parent()
	return true


func _swipe_to(control: Control) -> bool:
	for attempt in range(13):
		if _exposed(control):
			return true
		if attempt == 12:
			break
		var rect := _physical(table.content_scroll)
		var target := _physical(control)
		var direction := 1.0 if target.end.y > rect.end.y else -1.0
		var distance := minf(rect.size.y * 0.60, maxf(60 * table._density, absf(target.get_center().y - rect.get_center().y)))
		var start := rect.get_center() + Vector2(0, direction * distance * 0.45)
		var end := start - Vector2(0, direction * distance)
		var initial := InputEventScreenTouch.new()
		initial.index = 3
		initial.pressed = true
		initial.position = start
		Input.parse_input_event(initial)
		Input.flush_buffered_events()
		inputs.append({"frame": frames, "kind": "screen_touch", "pressed": true, "target": str(control.name), "position": [start.x, start.y]})
		await _frame()
		var previous := start
		for step in range(1, 9):
			var point := start.lerp(end, float(step) / 8.0)
			var drag := InputEventScreenDrag.new()
			drag.index = 3
			drag.position = point
			drag.relative = point - previous
			drag.screen_relative = drag.relative
			drag.velocity = Vector2.ZERO if step == 8 else drag.relative * 24.0
			drag.screen_velocity = drag.velocity
			Input.parse_input_event(drag)
			Input.flush_buffered_events()
			inputs.append({"frame": frames, "kind": "screen_drag", "target": str(control.name), "position": [point.x, point.y]})
			previous = point
			await _frame()
		var release := InputEventScreenTouch.new()
		release.index = 3
		release.position = end
		release.pressed = false
		Input.parse_input_event(release)
		Input.flush_buffered_events()
		inputs.append({"frame": frames, "kind": "screen_touch", "pressed": false, "target": str(control.name), "position": [end.x, end.y]})
		await _frames(14)
	return _check(false, "Bounded real swipe exposes " + str(control.name))


func _tap(control: Button, label: String) -> bool:
	if not _check(control.is_visible_in_tree() and not control.disabled, label + " is enabled and visible"):
		return false
	if not await _swipe_to(control):
		return false
	var rect := _physical(control)
	var dp: Vector2 = rect.size / table._density
	if not _check(dp.x >= 48.0 - 0.00001 and dp.y >= 48.0 - 0.00001 and _exposed(control), label + " has a fully exposed >=48dp target"):
		return false
	var point := rect.get_center()
	for at in [Vector2.ZERO, point]:
		var motion := InputEventMouseMotion.new()
		motion.position = at
		Input.parse_input_event(motion)
		Input.flush_buffered_events()
	for down in [true, false]:
		var touch := InputEventScreenTouch.new()
		touch.index = 1
		touch.position = point
		touch.pressed = down
		Input.parse_input_event(touch)
		Input.flush_buffered_events()
		inputs.append({"frame": frames, "kind": "screen_touch", "label": label, "pressed": down,
			"position": [point.x, point.y], "rect_px": [rect.position.x, rect.position.y, rect.size.x, rect.size.y],
			"roundId": table._state.get("roundId"), "revision": table._state.get("revision"), "pending": table._pending})
		await _frame()
	return true


func _snapshot(name: String) -> void:
	if not await _until(func(): return FileAccess.file_exists(table.LAYOUT_OBSERVATION), "Settled layout for " + name):
		return
	var raw := FileAccess.get_file_as_string(table.LAYOUT_OBSERVATION)
	var layout: Variant = JSON.parse_string(raw)
	_check(layout is Dictionary and layout.get("settled") == true and layout.get("pending") == 0 and layout.get("token") == table._token and int(layout.get("revision", -1)) == int(table._state.revision), "Snapshot binds exact current state " + name)
	var sidecar := FileAccess.open(output + "/" + name + ".layout.json", FileAccess.WRITE)
	sidecar.store_string(raw)
	sidecar.close()
	state_trace.append({"name": name, "frame": frames, "state": table._state.duplicate(true), "layout_sha256": FileAccess.get_sha256(output + "/" + name + ".layout.json")})
	if capture:
		var image := root.get_texture().get_image()
		var path := output + "/" + name + ".png"
		if not _check(image != null and image.save_png(path) == OK, "Save real framebuffer " + name):
			return
		_check(image.get_width() == root.size.x and image.get_height() == root.size.y, "Framebuffer %s actual=%s window=%s" % [name, image.get_size(), root.size])
		captures.append({"file": name + ".png", "sha256": FileAccess.get_sha256(path), "size_px": [image.get_width(), image.get_height()], "window_px": [root.size.x, root.size.y],
			"layout": name + ".layout.json", "fixture": fixture, "revision": table._state.revision})


func _profile(size: Vector2i, density: float = 1.0, insets: Rect2 = Rect2()) -> void:
	var mobile := root.get_node("MobileRuntime")
	root.get_node("HostBridge")._options["displayDensity"] = density
	mobile._android_safe_area_enabled = insets != Rect2()
	mobile._safe_area_reader = func(completed: Callable) -> bool:
		var pixels := Vector2(root.size)
		completed.call_deferred({"view_size": pixels, "decor_size": pixels, "render_rect": Rect2(Vector2.ZERO, pixels), "system_insets": insets, "insets": insets})
		return true
	root.size = size
	mobile.request_safe_area_refresh()
	table._layout()
	await _frames(12)
	_check(table.safe.is_visible_in_tree(), "Current safe area is ready at " + str(size))
	for button in [table.return_button, table.pause_button]:
		var rect := _physical(button)
		_check(rect.size.x / density >= 48.0 - 0.00001 and rect.size.y / density >= 48.0 - 0.00001 and _exposed(button), "Header >=48dp and inside actual safe area " + str(size))


func _fixture_state() -> Dictionary:
	return {"schema": 1, "game": "quiz", "token": FIXTURE_TOKEN, "roundId": "c".repeat(32), "owner": "a".repeat(64),
		"revision": 1, "recordRevision": 1, "ack": 0, "rejected": 0, "paused": false, "exit": false,
		"reduceMotion": false, "subject": "alle", "grade": 1, "number": 1, "total": 20,
		"questionSubject": "Mathe", "prompt": "Wie viele Ecken hat ein Dreieck?", "options": ["Zwei", "Drei", "Vier", "Fünf"],
		"selected": null, "revealed": false, "gameOver": false, "won": false, "correctIndex": null,
		"explanation": null, "hidden": [], "usedJokers": [], "audience": null, "hint": null,
		"securedStars": 0, "awardedStars": 0, "rewarded": false, "error": null,
		"canSelect": true, "canReveal": false, "canNext": false}


func _fixture_publish(delta: Dictionary = {}) -> void:
	var value: Dictionary = bridge.value.duplicate(true)
	value.merge(delta, true)
	value.revision = int(table._state.get("revision", 0)) + 1
	bridge.value = value
	table._poll_state()
	await _frames(8)


func _fixture_ack(delta: Dictionary) -> void:
	_check(not bridge.requests.is_empty(), "Fixture has an actual submitted request")
	if bridge.requests.is_empty():
		return
	var value := delta.duplicate(true)
	value.ack = int(bridge.requests.back().sequence)
	value.recordRevision = int(table._state.recordRevision) + 1
	await _fixture_publish(value)


func _fixture_contracts() -> void:
	var initial: Dictionary = table._state.duplicate(true)
	var malformed := [
		{"token": "f".repeat(32)}, {"owner": "f".repeat(64)}, {"roundId": "INVALID"},
		{"revision": 0}, {"revision": 1, "prompt": "Same revision, changed question"},
		{"correctIndex": 1}, {"explanation": "Premature answer"}, {"options": ["A"]},
		{"hidden": [0, 0]}, {"usedJokers": ["other"]}, {"audience": [10, 10, 10, 10]},
		{"selected": 4}, {"canReveal": true}, {"canNext": true}, {"grade": 0},
		{"subject": "unknown"}, {"paused": true}, {"recordRevision": 0}, {"ack": -1}, {"private_answer": 1}]
	for delta in malformed:
		var bad := initial.duplicate(true)
		bad.merge(delta, true)
		if not delta.has("revision"):
			bad.revision = int(initial.revision) + 1
		_check(not table.apply_state(bad), "Reject malformed/foreign state " + JSON.stringify(delta))
		_check(table._state == initial, "Malformed state cannot change public presentation")
	bridge.value = {}
	table._poll_state()
	_check(not table._authority_ready and table.return_button.disabled and table.answer_buttons[0].disabled, "Lost authority disables stale controls")
	bridge.value = initial
	table._poll_state()
	await _frames(8)
	_check(table._authority_ready, "Identical valid state can reconnect")
	_check(not table._send("reward") and not table._send("select", {"option": 1, "token": "evil"}), "No reward or forged extra key submission")
	bridge.accept = false
	_check(not table._send("select", {"option": 1}) and table._pending == 0, "Rejected transport cannot create a pending or saved state")
	bridge.accept = true
	await _profile(Vector2i(960, 540))
	await _snapshot("quiz-question-landscape")
	await _tap(table.answer_buttons[1], "Select answer B through actual UI")
	_check(bridge.requests.size() == 1 and bridge.requests.back().action == "select" and int(bridge.requests.back().option) == 1, "Actual touch submits the selected option once")
	_check(table._state.selected == null and table._pending > 0, "Transport receipt is not an authoritative selection")
	_check(not table._send("select", {"option": 2}), "Pending request blocks a second submission")
	await _fixture_ack({"selected": 1, "canReveal": true})
	var stale_ack: Dictionary = table._state.duplicate(true)
	stale_ack.revision = int(stale_ack.revision) + 1
	stale_ack.ack = 0
	_check(not table.apply_state(stale_ack), "Higher layout revision cannot roll back acknowledged input")
	await _profile(Vector2i(412, 915))
	await _snapshot("quiz-selected-phone")
	await _tap(table.joker_buttons[1], "Audience joker through current visible UI")
	_check(bridge.requests.back().action == "joker" and bridge.requests.back().joker == "audience", "Actual joker intent has exact host spelling")
	await _fixture_ack({"audience": [8, 76, 11, 5], "usedJokers": ["audience"], "hint": "Zähle die Ecken der Form."})
	await _profile(Vector2i(960, 540))
	await _swipe_to(table.joker_buttons[0])
	await _snapshot("quiz-jokers-landscape")
	await _tap(table.reveal_button, "Reveal selected answer")
	_check(not table._state.revealed and not table.feedback.visible, "No local answer reveal before host acknowledgement")
	await _fixture_ack({"revealed": true, "correctIndex": 1, "explanation": "Ein Dreieck hat genau drei Ecken.", "canSelect": false, "canReveal": false, "canNext": true})
	await _profile(Vector2i(640, 360))
	await _swipe_to(table.next_button)
	await _snapshot("quiz-revealed-small")
	_check(table.feedback.text.contains("Richtig") and table.answer_buttons[1].disabled, "Acknowledged result changes real labels and input state")
	await _tap(table.pause_button, "Pause current quiz")
	await _fixture_ack({"paused": true, "canNext": false})
	await _profile(Vector2i(360, 800))
	await _swipe_to(table.resume_button)
	await _snapshot("quiz-paused-portrait")
	_check(table.menu_heading.text == "Spiel pausiert" and table.fox.suspended, "Pause stops the real character and exposes the menu")
	await _tap(table.resume_button, "Resume exact current round")
	await _fixture_ack({"paused": false, "canNext": true})
	_check(table._state.roundId == initial.roundId and table._state.selected == 1 and table._state.revealed, "Presenter resume retains the acknowledged question")
	await _fixture_publish({"gameOver": true, "won": true, "number": 20, "canNext": false, "securedStars": 5000, "awardedStars": 5000, "rewarded": false})
	_check(table.restart_button.disabled and table.status.text.contains("noch bestätigt"), "Unsettled reward remains pending, no local award")
	await _fixture_publish({"rewarded": true})
	await _profile(Vector2i(1200, 896))
	await _swipe_to(table.restart_button)
	await _snapshot("quiz-result-fold")
	# Restore a declared fixture snapshot, not a production round/save.
	var fresh := _fixture_state()
	fresh.roundId = "d".repeat(32)
	fresh.ack = int(table._state.ack)
	fresh.rejected = int(table._state.rejected)
	await _fixture_publish(fresh)
	await _profile(Vector2i(2400, 1080), 2.625, Rect2(136, 63, 0, 63))
	await _snapshot("quiz-question-cutout")
	var mobile := root.get_node("MobileRuntime")
	mobile._safe_area_reader = func(completed: Callable) -> bool:
		var pixels := Vector2(root.size)
		completed.call_deferred({"view_size": pixels, "decor_size": pixels, "render_rect": Rect2(Vector2.ZERO, pixels), "system_insets": Rect2(0, 63, 136, 63), "insets": Rect2(0, 63, 136, 63)})
		return true
	mobile.request_safe_area_refresh()
	await _frames(12)
	_check(table._safe_rect.position.x == 0.0 and table._safe_rect.end.x < root.get_visible_rect().size.x, "Same-size 180-degree inset change moves only the actual unsafe side")
	await _tap(table.answer_buttons[0], "Pending selection rejected by host")
	var rejected_sequence: int = table._pending
	await _fixture_publish({"rejected": rejected_sequence})
	_check(table._pending == 0 and table._state.selected == null, "Terminal negative acknowledgement releases pending slot without applying answer")
	await _tap(table.return_button, "Request save and return")
	_check(not bridge.finished and table._pending > 0, "Sending exit never returns before durable acknowledgement")
	await _fixture_publish({"paused": true, "exit": true, "canSelect": false})
	_check(not bridge.finished, "Unacknowledged exit state cannot close the view")
	await _fixture_ack({})
	_check(bridge.finished and table._closed, "Exact accepted exit acknowledgement authorizes Flutter return")


func _authority_action(control: Button, label: String) -> bool:
	var previous_ack: int = int(table._state.ack)
	if not await _tap(control, label):
		return false
	return await _until(func(): return int(table._state.ack) > previous_ack and table._pending == 0, "Production Dart accepted and persisted " + label)


func _authority_contracts() -> void:
	await _profile(Vector2i(960, 540))
	await _snapshot("quiz-dart-question")
	var first_round: String = str(table._state.roundId)
	# These are real inputs against the existing production authority. The
	# private oracle is read only here, never in quiz_studio.gd or launch options.
	for joker in [2, 1, 0]:
		if not await _authority_action(table.joker_buttons[joker], "joker " + str(joker)):
			return
	_check(table._state.usedJokers.size() == 3 and table._state.hidden.size() == 2 and table._state.audience is Array and table._state.hint is String, "Three actual production jokers publish their distinct effects")
	await _snapshot("quiz-dart-jokers")
	for question in range(1, 21):
		# The authority atomically writes public state and the private QA oracle
		# as two separate files. Wait for a matching pair; never use an answer
		# from the previous question during that short publication interval.
		if not await _until(func():
			var value := _read(authority_dir + "/private-test-control.json")
			return value.get("roundId") == table._state.roundId and int(value.get("number", 0)) == int(table._state.number), "Private QA oracle reaches the current public state", 3.0):
			return
		var oracle := _read(authority_dir + "/private-test-control.json")
		if not _check(oracle.get("roundId") == table._state.roundId and int(oracle.get("number", 0)) == int(table._state.number), "Private test oracle binds current public round and question"):
			return
		var correct := int(oracle.get("correctIndex", -1))
		if not _check(correct >= 0 and correct < 4 and table._state.correctIndex == null and table._state.explanation == null, "Public state does not disclose the answer before reveal"):
			return
		if not await _authority_action(table.answer_buttons[correct], "answer question %d" % question):
			return
		if question == 1:
			await _profile(Vector2i(412, 915))
			await _snapshot("quiz-dart-selected-phone")
		if not await _authority_action(table.reveal_button, "reveal question %d" % question):
			return
		_check(table._state.revealed and int(table._state.correctIndex) == correct, "Production result reveals actual answer")
		if question == 1:
			await _profile(Vector2i(640, 360))
			await _swipe_to(table.next_button)
			await _snapshot("quiz-dart-revealed-small")
		if question == 5:
			_check(int(table._state.securedStars) == 50, "Production engine reached its existing first secured milestone")
			if not await _authority_action(table.pause_button, "pause after five questions"):
				return
			await _snapshot("quiz-dart-paused")
			var persisted := _read(authority_dir + "/round-" + str(table._state.owner) + ".json")
			_check(not persisted.is_empty(), "Real production DiskStore has a saved round")
			var saved_state: Dictionary = table._state.duplicate(true)
			# Actual scene disposal/recreation, same external production session.
			table.queue_free()
			await _frames(3)
			table = load(SCENE).instantiate()
			table._host = bridge
			root.add_child(table)
			if not await _until(func(): return table._authority_ready and bool(table._state.paused), "Reopened native scene receives the same saved paused session"):
				return
			_check(table._state.roundId == first_round and table._state.selected == saved_state.selected and table._state.revealed and table._state.number == saved_state.number, "Scene recreation does not reset answers or round identity")
			if not await _authority_action(table.resume_button, "resume the exact saved round"):
				return
		if question < 20:
			if not await _authority_action(table.next_button, "next question %d" % question):
				return
	_check(table._state.gameOver and table._state.won and int(table._state.awardedStars) == 5000 and table._state.rewarded, "All twenty actual production questions completed with confirmed reward")
	await _profile(Vector2i(1200, 896))
	await _swipe_to(table.restart_button)
	await _snapshot("quiz-dart-complete")
	var wallet := _read(authority_dir + "/wallet.json")
	_check(int(wallet.get("stars", -1)) == 5000 and wallet.get("ids", []).size() == 1, "Production controller invokes the QA award ledger once for the completed round")
	if not await _authority_action(table.pause_button, "pause completed round"):
		return
	if not await _authority_action(table.resume_button, "resume completed round"):
		return
	_check(_read(authority_dir + "/wallet.json") == wallet, "Resume cannot award the completed round twice")
	await _tap(table.return_button, "Save and return from completed production quiz")
	await _until(func(): return bridge.finished and table._closed, "Actual host exit ACK precedes native return")
	_check(_read(authority_dir + "/wallet.json") == wallet, "Exit cannot award the completed round twice")


func _finish() -> void:
	var source_after := _source_hashes()
	_check(source_after == source_before, "All measured source/model bytes unchanged by this run")
	var report := {"schema": 1, "kind": "quiz_studio_runtime", "mode": "declared_ui_transport_fixture" if fixture else "production_dart_disk_authority",
		"android": false, "checks": checks, "failures": failures, "frames": frames,
		"source_before": source_before, "source_after": source_after,
		"display_driver": DisplayServer.get_name(), "rendering_method": RenderingServer.get_current_rendering_method(),
		"video_adapter": RenderingServer.get_video_adapter_name(),
		"captures": captures, "inputs": inputs, "states": state_trace,
		"requests": bridge.requests if is_instance_valid(bridge) else [],
		"scope": "New original Godot presenter and real ScreenTouch/ScreenDrag; fixture acknowledgements are not a production Dart/save result" if fixture else "Original production Dart controller/session/question bank and disk persistence through a declared QA transport. The award callback is a QA ledger, not AppState/SharedPreferences. No Android Binder/device performance acceptance."}
	_write(output + "/quiz-runtime-report.json", report)
	if not fixture:
		_write(authority_dir + "/native-result.json", {"checks": checks, "failures": failures, "return_observed": bridge.finished})
	if is_instance_valid(table):
		table.queue_free()
		await process_frame
	Input.emulate_mouse_from_touch = previous_mouse_emulation
	Input.emulate_touch_from_mouse = previous_touch_emulation
	var marker := "QuizStudioFixture" if fixture else "QuizStudioRuntime"
	print("[%s] %s checks=%d captures=%d" % [marker, "PASS" if failures.is_empty() else "FAIL", checks, captures.size()])
	quit(0 if failures.is_empty() else 1)


func _source_hashes() -> Dictionary:
	var hashes := {}
	for path in [SCENE, "res://scripts/games/quiz/quiz_studio.gd", "res://scripts/tests/quiz_studio_runtime.gd",
		"res://scripts/characters/lumo/lumo_rigged_actor.gd", "res://assets/characters/lumo_facial/Lumo-Facial-Mobile.glb"]:
		_check(FileAccess.file_exists(path), "Actual source exists " + path)
		hashes[path] = FileAccess.get_sha256(path)
	return hashes


func _run() -> void:
	if output.is_empty() or (fixture and not authority_dir.is_empty()) or (not fixture and authority_dir.is_empty()):
		printerr("Explicit LUMO_CAPTURE_DIR and exactly one mode: --fixture OR LUMO_QUIZ_QA_DIR required")
		quit(2)
		return
	if capture and DisplayServer.get_name() == "headless":
		printerr("QUIZ_STUDIO_CAPTURE_REQUIRES_REAL_RENDERER")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(output)
	if FileAccess.file_exists(output + "/quiz-runtime-report.json"):
		printerr("Refusing to replace existing quiz-runtime-report.json evidence")
		quit(2)
		return
	source_before = _source_hashes()
	previous_mouse_emulation = Input.emulate_mouse_from_touch
	previous_touch_emulation = Input.emulate_touch_from_mouse
	Input.emulate_mouse_from_touch = true
	# ScrollContainer enables its desktop touch-drag path through the same
	# platform emulation flag used by the existing native visual regressions.
	Input.emulate_touch_from_mouse = true
	root.size = Vector2i(960, 540)
	root.position = Vector2i(40, 40)
	if DisplayServer.get_name() != "headless":
		root.grab_focus()
	var token := FIXTURE_TOKEN
	if fixture:
		bridge = FixtureBridge.new()
		bridge.value = _fixture_state()
	else:
		bridge = DartDiskBridge.new()
		bridge.folder = authority_dir
		if not await _until(func(): return not _read(authority_dir + "/public-state.json").is_empty(), "External production Dart state exists", 20):
			await _finish()
			return
		token = str(_read(authority_dir + "/public-state.json").get("token", ""))
	root.get_node("HostBridge")._options = {"game": "quiz", "tableToken": token, "displayDensity": 1.0}
	table = load(SCENE).instantiate()
	table._host = bridge
	root.add_child(table)
	if not await _until(func(): return table._authority_ready and bool(table._state.get("canSelect", false)), "Current Quiz authority is active", 15):
		await _finish()
		return
	_check(table.fox.is_usable() and table.fox.skeleton.get_bone_count() == 65 and table.fox.CLIPS.size() == 9, "Actual original Lumo retains 65 bones and nine clips")
	for clip in table.fox.CLIPS:
		_check(table.fox.player.has_animation(clip), "Original authored clip " + str(clip))
	_check(table.get_node("StudioArch").mesh is TorusMesh and table.get_node("StudioPodium").mesh is CylinderMesh and table._lights.size() == 20, "Actual studio meshes and twenty authoritative question lamps")
	if fixture:
		await _fixture_contracts()
	else:
		await _authority_contracts()
	await _finish()
