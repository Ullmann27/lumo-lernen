extends SceneTree
## Local two-process integration. Touch -> production Godot intent -> real Dart
## controller/engine/save -> acknowledged state -> geometry. Not an Android test.
const TABLE = "res://scripts/games/connect_four/connect_four_table.gd"
var table
var bridge
var output := ""
var capture := false
var record := false
var frames := 0
var tick := 100000
var checks := 0
var errors: Array[String] = []
var inputs: Array[Dictionary] = []
var positions: Array[Dictionary] = []
var targets: Array[Dictionary] = []
var previous_touch_emulation := false

class LocalDartBridge extends RefCounted:
	var folder := ""
	var raw_request := "{}"
	var finished := false
	func getConnectFourState() -> String:
		return FileAccess.get_file_as_string(folder + "/state.json")
	func submitConnectFourAction(payload: String) -> bool:
		var parsed: Variant = JSON.parse_string(payload)
		if not parsed is Dictionary:
			return false
		raw_request = payload
		return true
	func returnToApp(_destination: String, _payload: String) -> bool:
		finished = true
		return true


func _initialize() -> void:
	output = OS.get_environment("LUMO_C4_RUNTIME_DIR")
	capture = "--capture" in OS.get_cmdline_user_args()
	call_deferred("_run")


func _check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		errors.append(message)
		push_error("[ConnectFourRuntime] " + message)


func _atomic(name: String, value: Variant) -> void:
	var file := FileAccess.open(output + "/" + name + ".tmp", FileAccess.WRITE)
	file.store_string(JSON.stringify(value))
	file.flush()
	file.close()
	DirAccess.rename_absolute(output + "/" + name + ".tmp", output + "/" + name)


func _frame() -> void:
	tick += 42
	var file := FileAccess.open(output + "/input.json.tmp", FileAccess.WRITE)
	file.store_string('{"clock_ms":%d,"lifecycle":{"active":true,"stamp":%d,"pauseEpoch":0},"request":%s}' % [tick, tick, bridge.raw_request])
	file.close()
	DirAccess.rename_absolute(output + "/input.json.tmp", output + "/input.json")
	await process_frame
	if capture:
		await RenderingServer.frame_post_draw
	if record:
		if capture:
			root.get_texture().get_image().save_png(output + "/frames/%05d.png" % frames)
		var discs: Array = []
		for disc in table._discs:
			discs.append([disc.position.x, disc.position.y, disc.position.z])
		positions.append({"frame": frames, "tick": tick, "revision": table._state.get("revision", 0), "ack": table._state.get("ack", 0), "discs": discs, "dropping": table._dropping, "win_rings": table._win_root.get_child_count()})
		frames += 1


func _frames(count: int) -> void:
	for i in range(count):
		await _frame()


func _until(predicate: Callable, message: String, limit: int = 160) -> void:
	for i in range(limit):
		if predicate.call():
			_check(true, message)
			return
		await _frame()
	_check(false, message)


func _physical(control: Control) -> Rect2:
	var transform := control.get_global_transform_with_canvas()
	var factor := Vector2(root.size) / root.get_visible_rect().size
	return Rect2((transform * Vector2.ZERO) * factor, control.size * factor)


func _tap(control: Button, label: String) -> void:
	_check(is_instance_valid(control) and control.is_visible_in_tree() and not control.disabled, label + " actionable")
	var rect := _physical(control)
	var dp: Vector2 = rect.size / table._density
	_check(dp.x >= 47.99 and dp.y >= 47.99, label + " >=48dp")
	var safe_pixels := Rect2(table._safe_rect.position * table._density, table._safe_rect.size * table._density)
	_check(safe_pixels.grow(1).encloses(rect), label + " inside current safe surface")
	var ancestor := control.get_parent()
	while ancestor != null:
		if ancestor is Control and ancestor.clip_contents:
			_check(_physical(ancestor).grow(1).encloses(rect), label + " fully exposed inside scroll clip")
		ancestor = ancestor.get_parent()
	targets.append({"label": label, "size_dp": [dp.x, dp.y], "rect_px": [rect.position.x, rect.position.y, rect.size.x, rect.size.y]})
	var point := rect.get_center()
	# X11 synthetic touch emulates mouse; establish the actual pointer position
	# before a new Control receives a press. Events remain real ScreenTouch.
	var motion := InputEventMouseMotion.new()
	motion.position = Vector2.ZERO
	Input.parse_input_event(motion)
	Input.flush_buffered_events()
	motion = InputEventMouseMotion.new()
	motion.position = point
	Input.parse_input_event(motion)
	Input.flush_buffered_events()
	for down in [true, false]:
		var touch := InputEventScreenTouch.new()
		touch.index = 1
		touch.position = point
		touch.pressed = down
		Input.parse_input_event(touch)
		Input.flush_buffered_events()
		inputs.append({"frame": frames, "label": label, "pressed": down, "screen_px": [point.x, point.y], "snapshot_revision": table._state.get("revision", 0)})
		await _frame()


func _reveal_menu_button(control: Button) -> void:
	var scroll: ScrollContainer = table.overlay.get_child(0)
	for attempt in range(6):
		if _physical(scroll).grow(1).encloses(_physical(control)):
			return
		var rect := _physical(scroll)
		var start := rect.position + rect.size * Vector2(0.5, 0.85)
		var end := rect.position + rect.size * Vector2(0.5, 0.15)
		var touch := InputEventScreenTouch.new()
		touch.index = 3
		touch.position = start
		touch.pressed = true
		Input.parse_input_event(touch)
		Input.flush_buffered_events()
		await _frame()
		var previous := start
		for step in range(1, 9):
			var point := start.lerp(end, float(step) / 8.0)
			var drag := InputEventScreenDrag.new()
			drag.index = 3
			drag.position = point
			drag.relative = point - previous
			drag.screen_relative = drag.relative
			drag.velocity = drag.relative * 24.0
			drag.screen_velocity = drag.velocity
			Input.parse_input_event(drag)
			Input.flush_buffered_events()
			inputs.append({"frame":frames,"label":"Actual menu scroll","drag":true,"screen_px":[point.x,point.y],"snapshot_revision":table._state.revision})
			previous = point
			await _frame()
		touch = InputEventScreenTouch.new()
		touch.index = 3
		touch.position = end
		touch.pressed = false
		Input.parse_input_event(touch)
		Input.flush_buffered_events()
		await _frames(8)
	_check(_physical(scroll).grow(1).encloses(_physical(control)), "Real bounded menu swipe reveals complete target")


func _capture(name: String) -> void:
	await _until(func(): return FileAccess.file_exists(table.LAYOUT_OBSERVATION), "Settled read-only layout exists for " + name)
	var raw := FileAccess.get_file_as_string(table.LAYOUT_OBSERVATION)
	var layout: Variant = JSON.parse_string(raw)
	_check(layout is Dictionary and layout.get("settled") == true and int(layout.get("revision",0)) == int(table._state.revision) and layout.get("token") == table._token, "Layout bound to actual acknowledged state: " + name)
	var file := FileAccess.open(output + "/" + name + ".layout.json", FileAccess.WRITE)
	file.store_string(raw)
	file.close()
	if capture:
		root.get_texture().get_image().save_png(output + "/" + name + ".png")


func _run() -> void:
	_check(not output.is_empty(), "explicit isolated IPC folder")
	if output.is_empty():
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(output + "/frames")
	bridge = LocalDartBridge.new()
	bridge.folder = output
	previous_touch_emulation = Input.emulate_touch_from_mouse
	Input.emulate_touch_from_mouse = true
	root.size = Vector2i(960, 540)
	root.position = Vector2i(40, 40)
	root.grab_focus()
	root.get_node("HostBridge")._options = {"displayDensity": 1.0, "connectFourToken": "a".repeat(32), "reduceAnimations": false}
	table = load(TABLE).new()
	table._host = bridge
	root.add_child(table)
	await _until(func(): return not table._state.is_empty() and table._state.canDrop, "Dart session active")
	_check(table.fox.is_usable(), "Original 65-bone Lumo imported and connected")
	_check(table.get_node("PerforatedBoard").mesh.get_surface_count() == 1, "Real perforated board is one geometry surface")
	await _frames(4)
	# A separate real single-player opening, before the film's two-player round.
	var portrait_mobile := root.get_node("MobileRuntime")
	root.get_node("HostBridge")._options["displayDensity"] = 2.625
	portrait_mobile._android_safe_area_enabled = true
	portrait_mobile._safe_area_reader = func(completed: Callable) -> bool:
		var size := Vector2(root.size)
		var inset := Rect2(0, 136, 0, 63)
		completed.call_deferred({"view_size":size,"decor_size":size,"render_rect":Rect2(Vector2.ZERO,size),"system_insets":inset,"insets":inset})
		return true
	root.size = Vector2i(1080, 2400)
	portrait_mobile.request_safe_area_refresh()
	await _frames(12)
	for button in table.column_buttons:
		var physical := _physical(button)
		_check(_physical(table.column_scroll).grow(1).encloses(physical), "411dp portrait exposes every complete column")
		_check(physical.size.x / table._density >= 47.99, "411dp portrait column >=48dp")
	await _capture("connect_four_phone_playing")
	await _tap(table.column_buttons[3], "Portrait single-player human move")
	await _until(func(): return table._state.columns.size() == 2 and not table._dropping and table._drop_queue.is_empty(), "Original Dart bot answers actual portrait touch")
	_check(not table._state.twoPlayers and int(table._state.turn) == 1, "Bot returns turn to child without copied rules")
	await _capture("connect_four_phone_bot_response")
	portrait_mobile._android_safe_area_enabled = false
	root.get_node("HostBridge")._options["displayDensity"] = 1.0
	root.size = Vector2i(960, 540)
	await _frames(12)
	await _tap(table.pause_button, "Pause before mode choice")
	await _until(func(): return table._state.paused and table.overlay.visible and table._pending == 0, "Pause acknowledged")
	await _tap(table.mode_button, "Start local two-player round")
	await _until(func(): return table._state.twoPlayers and table._state.canDrop and table._pending == 0, "Existing Dart two-player round ready")
	await _capture("connect_four_empty")
	record = true
	await _frames(14)
	var history := [0, 6, 1, 6, 2, 5, 3]
	for i in range(history.size()):
		var column: int = history[i]
		await _until(func(): return table._pending == 0 and not table._dropping and table._drop_queue.is_empty() and table._state.canDrop, "Next real touch enabled")
		await _tap(table.column_buttons[column], "Drop %d into column %d" % [i + 1, column + 1])
		await _until(func(): return table._state.columns.size() == i + 1 and table._pending == 0, "Dart durably acknowledged move %d" % (i + 1))
		if i == 0 and table._dropping:
			await _tap(table.pause_button, "Pause during actual falling motion")
			await _until(func(): return table._state.paused and table.overlay.visible and table._pending == 0, "Falling-disc pause acknowledged")
			var paused_position: Vector3 = table._discs.back().position
			await _frames(8)
			_check(table._discs.back().position.is_equal_approx(paused_position), "Paused drop cannot keep animating")
			await _tap(table.resume_button, "Resume actual paused drop")
			await _until(func(): return not table._state.paused and table._pending == 0, "Paused drop explicitly resumes")
		await _until(func(): return not table._dropping and table._drop_queue.is_empty(), "Visible falling disc landed %d" % (i + 1))
		_check(table._discs.size() == i + 1, "One geometry disc per acknowledged move")
		await _frames(6)
		if i == 2:
			await _tap(table.pause_button, "Pause real round")
			await _until(func(): return table._state.paused and table.overlay.visible and table._pending == 0, "Saved same round paused")
			await _capture("connect_four_pause")
			var columns: Array = table._state.columns.duplicate()
			await _frames(12)
			_check(table._state.columns == columns, "Paused board cannot advance")
			await _tap(table.resume_button, "Resume same round")
			await _until(func(): return not table._state.paused and table._pending == 0, "Explicit resume acknowledged")
	await _until(func(): return table._state.phase == "won" and table._state.rewarded, "Dart win and original wallet reward committed")
	_check(table._win_root.get_child_count() == 4, "Four actual winning discs visibly marked")
	_check(table._state.winningLine.map(func(point): return [int(point[0]), int(point[1])]) == [[5, 0], [5, 1], [5, 2], [5, 3]], "Winning positions supplied by original Dart engine")
	await _capture("connect_four_win")
	await _frames(36)
	record = false
	# Physical density/layout cases use the exact same acknowledged round.
	# A platform boundary fixture supplies declared insets, never Android claims.
	for profile in [
		["phone_portrait", Vector2i(1080, 2400), 2.625, Rect2(0,136,0,63)],
		["fold_landscape", Vector2i(2400, 1080), 2.625, Rect2(136,63,0,63)],
		["small_landscape", Vector2i(640, 360), 1.0, Rect2(0,24,0,24)],
		["small_portrait", Vector2i(320, 740), 1.0, Rect2(0,24,0,24)]]:
		var mobile := root.get_node("MobileRuntime")
		root.get_node("HostBridge")._options["displayDensity"] = profile[2]
		mobile._android_safe_area_enabled = true
		var inset: Rect2 = profile[3]
		mobile._safe_area_reader = func(completed: Callable) -> bool:
			var size := Vector2(root.size)
			completed.call_deferred({"view_size": size, "decor_size": size, "render_rect": Rect2(Vector2.ZERO,size), "system_insets":inset,"insets":inset})
			return true
		root.size = profile[1]
		mobile.request_safe_area_refresh()
		await _frames(12)
		await _tap(table.pause_button, str(profile[0]) + " menu in real safe area")
		await _until(func(): return table._state.paused and table._pending == 0, "Responsive menu acknowledged")
		await _reveal_menu_button(table.resume_button)
		await _capture("connect_four_" + str(profile[0]))
		# Actual scroll + touch leaves the same won board; no restart is invoked.
		await _tap(table.resume_button, str(profile[0]) + " actual visible resume")
		await _until(func(): return not table._state.paused and table._pending == 0, "Leave responsive menu")
	await _tap(table.return_button, "Return to exact Flutter caller")
	await _until(func(): return bridge.finished, "Return only after exit ACK")
	_atomic("native-result.json", {"passed": errors.is_empty(), "checks": checks, "errors": errors, "transport":"local two-process production Dart controller; not Android", "inputs":inputs,"targets":targets,"frames":frames,"fps_format":24,"positions":positions,"final_state":table._state})
	_atomic("done.json", {"finished":true})
	print("[ConnectFourRuntime] %s %d checks, %d frames" % ["PASS" if errors.is_empty() else "FAIL", checks, frames])
	Input.emulate_touch_from_mouse = previous_touch_emulation
	table.queue_free()
	await process_frame
	quit(0 if errors.is_empty() else 1)
