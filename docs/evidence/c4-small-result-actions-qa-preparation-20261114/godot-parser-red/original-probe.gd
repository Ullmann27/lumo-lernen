extends "res://scripts/tests/connect_four_runtime_regression.gd"
## Separate QA overlay for the two lower winning-modal actions at 640x360.
## Production and the inherited touch/scroll/transport helpers stay unchanged.
const QA_SCHEMA := 1
const QA_HELPER_BLOB := "94c32597c0170c5c3199e39ca6fbfcc1caf25f99"
const QA_HISTORY := [0, 6, 1, 6, 2, 5, 3]
var actions: Array[Dictionary] = []
var _last_capture_layout := -1


class AuditedDartBridge extends RefCounted:
	var folder := ""
	var raw_request := "{}"
	var finished := false
	var requests: Array[Dictionary] = []

	func getConnectFourState() -> String:
		return FileAccess.get_file_as_string(folder + "/state.json")

	func submitConnectFourAction(payload: String) -> bool:
		var parsed: Variant = JSON.parse_string(payload)
		if not parsed is Dictionary:
			return false
		raw_request = payload
		requests.append(parsed.duplicate(true))
		return true

	func returnToApp(destination: String, payload: String) -> bool:
		if destination != "games" or not payload.is_empty():
			return false
		finished = true
		return true


func _frame() -> void:
	# The inherited helper advances the real process and original file handshake.
	# No film is recorded; every input step still receives a monotonic frame id.
	await super._frame()
	frames += 1


func _wait(predicate: Callable, message: String) -> bool:
	await _until(predicate, message)
	return bool(predicate.call())


func _guard(value: bool, message: String) -> bool:
	_check(value, message)
	return value


func _tap_ack(
	control: Button, label: String, action: String, extras: Dictionary = {}
) -> Dictionary:
	var before: Dictionary = table._state.duplicate(true)
	var first_request: int = bridge.requests.size()
	var error_count := errors.size()
	await _tap(control, label)
	if errors.size() != error_count:
		return {}
	if not await _wait(
		func(): return bridge.requests.size() >= first_request + 1,
		label + " produces an actual submitted request"
	):
		return {}
	if not _guard(bridge.requests.size() == first_request + 1, label + " submits exactly once"):
		return {}
	var request: Dictionary = bridge.requests[first_request].duplicate(true)
	var exact := (
		request.get("action") == action
		and request.get("token") == before.token
		and request.get("roundId") == before.roundId
		and int(request.get("revision", -1)) == int(before.revision)
		and int(request.get("sequence", -1)) > int(before.ack)
		and int(request.get("sequence", -1)) > int(before.rejected)
	)
	for key in extras:
		exact = exact and request.get(key) == extras[key]
	if not _guard(exact, label + " binds action and extras to the actual prior state"):
		return {}
	var sequence := int(request.sequence)
	if not await _wait(
		func():
			return int(table._state.get("ack", -1)) == sequence and table._pending == 0,
		label + " receives the matching production ACK"
	):
		return {}
	var after: Dictionary = table._state.duplicate(true)
	if not _guard(
		int(after.revision) > int(before.revision)
		and int(after.rejected) == int(before.rejected)
		and after.owner == before.owner and after.token == before.token,
		label + " advances revision without rejection or session-owner change"
	):
		return {}
	return {"request": request, "before_state": before, "after_state": after}


func _reveal_without_submit(control: Button, label: String) -> bool:
	var request_count: int = bridge.requests.size()
	var revision := int(table._state.revision)
	var error_count := errors.size()
	await _reveal_menu_button(control)
	return _guard(
		errors.size() == error_count
		and bridge.requests.size() == request_count
		and int(table._state.revision) == revision,
		label + " scrolls without accidentally activating an action"
	)


func _layout_matches(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	return (
		value.get("settled") == true
		and value.get("token") == table._token
		and value.get("owner") == table._state.owner
		and value.get("roundId") == table._state.roundId
		and int(value.get("revision", -1)) == int(table._state.revision)
		and int(value.get("ack", -1)) == int(table._state.ack)
		and int(value.get("pending", -1)) == 0
		and value.get("phase") == table._state.phase
		and value.get("paused") == table._state.paused
		and value.get("twoPlayers") == table._state.twoPlayers
		and value.get("rewarded") == table._state.rewarded
		and value.get("columns") == table._state.columns
		and value.get("window_px") == [640, 360]
		and value.get("viewport_px") == [640, 360]
		and absf(float(value.get("density", 0.0)) - 1.0) < 0.0001
		and value.get("safe_rect") == [0, 24, 640, 312]
	)


func _current_layout_ready() -> bool:
	if not FileAccess.file_exists(table.LAYOUT_OBSERVATION):
		return false
	var value: Variant = JSON.parse_string(
		FileAccess.get_file_as_string(table.LAYOUT_OBSERVATION)
	)
	return _layout_matches(value) and int(value.get("layout_sequence", -1)) > _last_capture_layout


func _capture_bound(name: String) -> Dictionary:
	if not await _wait(
		func(): return _current_layout_ready(),
		name + " waits for the matching fresh settled layout"
	):
		return {}
	var error_count := errors.size()
	await _capture(name)
	if errors.size() != error_count:
		return {}
	var value: Variant = JSON.parse_string(
		FileAccess.get_file_as_string(output + "/" + name + ".layout.json")
	)
	if not _guard(_layout_matches(value), name + " matches current 640x360 acknowledged state"):
		return {}
	var layout: Dictionary = value
	if not _guard(
		int(layout.get("layout_sequence", -1)) > _last_capture_layout,
		name + " has a fresh layout observation"
	):
		return {}
	var png := FileAccess.get_file_as_bytes(output + "/" + name + ".png")
	if not _guard(
		png.size() > 8 and png.slice(0, 8) == PackedByteArray([137, 80, 78, 71, 13, 10, 26, 10]),
		name + " has an original rendered PNG"
	):
		return {}
	_last_capture_layout = int(layout.layout_sequence)
	return layout


func _visible_target(layout: Dictionary, id: String) -> Dictionary:
	for value in layout.buttons:
		if value.get("id") != id:
			continue
		var target: Dictionary = value.duplicate(true)
		var rect: Array = target.rect_px
		var hit: Array = target.hit_rect_px
		var complete := (
			bool(target.visible) and bool(target.enabled) and not bool(target.clipped)
			and rect.size() == 4 and hit.size() == 4
			and float(rect[2]) >= 48.0 and float(rect[3]) >= 48.0
		)
		if complete:
			for index in range(4):
				complete = complete and absf(float(rect[index]) - float(hit[index])) < 0.1
		if not _guard(complete, id + " is fully exposed, enabled and at least 48dp"):
			return {}
		target["size_dp"] = [float(rect[2]), float(rect[3])]
		return target
	_guard(false, "Captured layout contains the requested " + id + " target")
	return {}


func _fresh_round(before: Dictionary, two_players: bool) -> bool:
	var state: Dictionary = table._state
	return (
		state.roundId != before.roundId
		and state.phase == "playing" and not state.paused and not state.exit
		and state.twoPlayers == two_players
		and state.columns.is_empty() and state.winningLine.is_empty()
		and state.board.size() == 42
		and state.board.all(func(piece): return int(piece) == 0)
		and int(state.turn) == 1 and bool(state.canDrop) and not state.rewarded
		and table._pending == 0 and not table._dropping and table._drop_queue.is_empty()
	)


func _win_round(label: String) -> bool:
	var round_id := str(table._state.roundId)
	if not _guard(
		table._state.twoPlayers and table._state.phase == "playing"
		and table._state.columns.is_empty() and not table._state.paused,
		label + " starts a real empty two-player round"
	):
		return false
	for index in range(QA_HISTORY.size()):
		if not await _wait(
			func():
				return table._pending == 0 and bool(table._state.canDrop) \
					and not table._dropping and table._drop_queue.is_empty(),
			label + " enables next actual column touch"
		):
			return false
		var column: int = QA_HISTORY[index]
		var result: Dictionary = await _tap_ack(
			table.column_buttons[column], label + " drop " + str(index + 1),
			"drop", {"column": column}
		)
		if result.is_empty():
			return false
		if not await _wait(
			func():
				return not table._dropping and table._drop_queue.is_empty() \
					and table._state.columns.size() == index + 1,
			label + " acknowledges and visibly lands each real move"
		):
			return false
		if not _guard(
			table._state.roundId == round_id
			and table._state.columns.map(func(value): return int(value)) == QA_HISTORY.slice(0, index + 1)
			and table._discs.size() == index + 1,
			label + " retains exact touch history and matching disc geometry"
		):
			return false
	if not await _wait(
		func():
			return (
				table._state.phase == "won" and bool(table._state.rewarded)
				and table._pending == 0
			),
		label + " commits the original winning state and reward"
	):
		return false
	return _guard(
		table._win_root.get_child_count() == 4
		and table._state.winningLine.map(func(point): return [int(point[0]), int(point[1])])
			== [[5, 0], [5, 1], [5, 2], [5, 3]],
		label + " identifies the four original winning positions"
	)


func _exercise_result_action(action: String, control: Button, two_players: bool) -> bool:
	var opened: Dictionary = await _tap_ack(
		table.pause_button, action + " open won result menu", "pause"
	)
	if opened.is_empty():
		return false
	if not _guard(
		table._state.phase == "won" and table._state.paused and table._state.rewarded
		and table.overlay.visible and table.resume_button.text == "Brett ansehen",
		action + " uses the actual acknowledged winning dialog"
	):
		return false
	# Restore the upper reference target by real scrolling, without activating it.
	if not await _reveal_without_submit(table.resume_button, action + " upper reference"):
		return false
	var scroll: ScrollContainer = table.overlay.get_child(0)
	var hidden_rect := _physical(control)
	if not _guard(
		not _physical(scroll).grow(1).encloses(hidden_rect),
		action + " starts with the lower target not fully exposed"
	):
		return false
	var input_start := inputs.size()
	var scroll_before := scroll.scroll_vertical
	var state_before: Dictionary = table._state.duplicate(true)
	if not await _reveal_without_submit(control, action + " lower target"):
		return false
	var input_end := inputs.size()
	var drag_count := 0
	for index in range(input_start, input_end):
		if inputs[index].get("drag") == true:
			drag_count += 1
	if not _guard(
		drag_count > 0 and scroll.scroll_vertical != scroll_before
		and _physical(scroll).grow(1).encloses(_physical(control)),
		action + " is exposed by actual bounded drag input"
	):
		return false
	var scroll_after := scroll.scroll_vertical
	var prefix := "small_result_" + action
	var before_layout: Dictionary = await _capture_bound(prefix + "_before")
	if before_layout.is_empty():
		return false
	var target: Dictionary = _visible_target(before_layout, action)
	if target.is_empty():
		return false
	var expected_text := "Neue Runde" if action == "restart" else "Gegen Lumo spielen"
	if not _guard(target.text == expected_text, action + " target has the exact winning-dialog label"):
		return false
	var extras := {} if action == "restart" else {"twoPlayers": false}
	var transition: Dictionary = await _tap_ack(control, action + " exposed result action", action, extras)
	if transition.is_empty():
		return false
	if not _guard(transition.before_state == state_before, action + " scrolling kept the won state intact"):
		return false
	if not await _wait(
		func(): return _fresh_round(state_before, two_players),
		action + " creates the expected acknowledged fresh round"
	):
		return false
	var after_layout: Dictionary = await _capture_bound(prefix + "_after")
	if after_layout.is_empty():
		return false
	var after: Dictionary = table._state.duplicate(true)
	if not _guard(
		int(after.ack) == int(transition.request.sequence)
		and after.owner == state_before.owner and after.token == state_before.token
		and int(after.rejected) == int(state_before.rejected),
		action + " final capture retains the exact accepted action"
	):
		return false
	actions.append({
		"action": action, "request": transition.request,
		"before_state": transition.before_state, "after_state": after,
		"before_capture": prefix + "_before.png", "after_capture": prefix + "_after.png",
		"before_layout": prefix + "_before.layout.json", "after_layout": prefix + "_after.layout.json",
		"target": target,
		"scroll_evidence": {
			"input_start_inclusive": input_start, "input_end_exclusive": input_end,
			"drag_events": drag_count, "scroll_before": scroll_before,
			"scroll_after": scroll_after,
			"initial_target_rect_px": [hidden_rect.position.x, hidden_rect.position.y, hidden_rect.size.x, hidden_rect.size.y]
		}
	})
	return true


func _exercise() -> bool:
	if not await _wait(
		func(): return not table._state.is_empty() and bool(table._state.get("canDrop", false)),
		"Fresh original Dart session is active"
	):
		return false
	if not _guard(
		not table._state.twoPlayers and table._state.columns.is_empty(),
		"Dedicated QA starts from a fresh solo session"
	):
		return false
	var paused: Dictionary = await _tap_ack(table.pause_button, "Setup pause", "pause")
	if paused.is_empty():
		return false
	if not await _reveal_without_submit(table.mode_button, "Setup two-player mode"):
		return false
	var mode: Dictionary = await _tap_ack(
		table.mode_button, "Setup real two-player round", "mode", {"twoPlayers": true}
	)
	if mode.is_empty():
		return false
	if not await _wait(
		func(): return _fresh_round(mode.before_state, true),
		"Setup mode change opens a real empty two-player round"
	):
		return false
	if not await _win_round("restart prerequisite"):
		return false
	if not await _exercise_result_action("restart", table.restart_button, true):
		return false
	if not await _win_round("mode prerequisite"):
		return false
	if not await _exercise_result_action("mode", table.mode_button, false):
		return false
	var exit_action: Dictionary = await _tap_ack(table.return_button, "Return after both lower actions", "exit")
	if exit_action.is_empty():
		return false
	return await _wait(func(): return bridge.finished and bool(table._state.exit), "Exact exit ACK permits return")


func _run() -> void:
	if output.is_empty():
		push_error("[ConnectFourSmallResultActionsQA] requires LUMO_C4_RUNTIME_DIR")
		quit(1)
		return
	if DirAccess.make_dir_recursive_absolute(output) != OK:
		push_error("[ConnectFourSmallResultActionsQA] cannot create output directory")
		quit(1)
		return
	bridge = AuditedDartBridge.new()
	bridge.folder = output
	previous_touch_emulation = Input.emulate_touch_from_mouse
	Input.emulate_touch_from_mouse = true
	record = false
	if not _guard(capture, "Dedicated QA requires original rendered captures via --capture"):
		await _finish(false)
		return
	root.size = Vector2i(640, 360)
	root.position = Vector2i(40, 40)
	root.grab_focus()
	root.get_node("HostBridge")._options = {
		"displayDensity": 1.0, "connectFourToken": "a".repeat(32), "reduceAnimations": false
	}
	var mobile := root.get_node("MobileRuntime")
	mobile._android_safe_area_enabled = true
	mobile._safe_area_reader = func(completed: Callable) -> bool:
		var size := Vector2(root.size)
		var inset := Rect2(0, 24, 0, 24)
		completed.call_deferred({
			"view_size": size, "decor_size": size,
			"render_rect": Rect2(Vector2.ZERO, size), "system_insets": inset, "insets": inset
		})
		return true
	mobile.request_safe_area_refresh()
	table = load(TABLE).new()
	table._host = bridge
	root.add_child(table)
	await _frames(12)
	var completed: bool = await _exercise()
	await _finish(completed)


func _finish(completed: bool) -> void:
	var passed: bool = completed and errors.is_empty() and actions.size() == 2 and bridge.finished
	var final_state: Dictionary = table._state.duplicate(true) if is_instance_valid(table) else {}
	_atomic("native-result.json", {
		"schema": QA_SCHEMA, "passed": passed, "checks": checks, "errors": errors,
		"transport": "local two-process original production Dart controller; not Android",
		"helper_source": {"path": "scripts/tests/connect_four_runtime_regression.gd", "blob": QA_HELPER_BLOB},
		"viewport_px": [640, 360], "density": 1.0, "declared_insets_px": [0, 24, 0, 24],
		"actions": actions, "inputs": inputs, "targets": targets,
		"submitted_requests": bridge.requests, "frames": frames,
		"frame_counter": "monotonic logical probe frames; no movie or measured FPS",
		"final_state": final_state, "return_acknowledged": bridge.finished
	})
	_atomic("done.json", {"finished": true, "passed": passed})
	print("[ConnectFourSmallResultActionsQA] %s %d checks, %d actions" % [
		"PASS" if passed else "FAIL", checks, actions.size()
	])
	Input.emulate_touch_from_mouse = previous_touch_emulation
	if is_instance_valid(table):
		table.queue_free()
		await process_frame
	quit(0 if passed else 1)
