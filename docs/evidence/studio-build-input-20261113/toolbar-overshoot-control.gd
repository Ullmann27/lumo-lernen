extends SceneTree
## Live production dialogs, their own viewport transforms and real touch events.
## Density fixtures are not a physical Android device or a performance test.

const PROFILES := [
	[Vector2i(2400, 1080), 2.625],
	[Vector2i(1080, 2400), 2.625],
	[Vector2i(2176, 1812), 2.25],
	[Vector2i(640, 360), 1.0],
	[Vector2i(640, 320), 1.0],
]
const TEMPLATE_LABELS := [
	"Großes Sternenschloss", "Dorf für Freunde", "Starter-Haus", "Brücke", "Sternenturm",
	"Garten", "Garten-Parzelle", "Hafen-Parzelle", "Insel-Parzelle", "Leere Insel",
]
const GOAL_LABELS := [
	"Ein Zuhause bauen", "Die Inseln verbinden", "Turm der Sterne",
	"Ein Garten zum Verweilen", "Großes Sternenschloss", "Dorf für Freunde",
]
var game
var density := 1.0
var checks := 0
var failures: Array[String] = []
var targets: Array[Dictionary] = []
var images: Array[Dictionary] = []
var capture := false
var output := "res://exports/build-dialog-density"


func _initialize() -> void:
	capture = "--capture" in OS.get_cmdline_user_args()
	if not OS.get_environment("LUMO_CAPTURE_DIR").is_empty():
		output = OS.get_environment("LUMO_CAPTURE_DIR")
	call_deferred("_run")


func _check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures.append(label)
		push_error("[BuildDialogDensity] " + label)


func _settle(frames: int = 6) -> void:
	for frame in range(frames):
		await process_frame


func _rect(transform: Transform2D, local: Rect2) -> Rect2:
	var rect := Rect2(transform * local.position, Vector2.ZERO)
	for point in [Vector2(local.end.x, local.position.y), local.end, Vector2(local.position.x, local.end.y)]:
		rect = rect.expand(transform * point)
	return rect


func _pixels(control: Control) -> Rect2:
	# A popup has its own viewport and screen transform. Root scaling alone
	# would lose its position and may report an unreachable target as valid.
	var transform := control.get_viewport().get_screen_transform() * control.get_global_transform_with_canvas()
	return _rect(transform, Rect2(Vector2.ZERO, control.size))


func _window_pixels(window: Window) -> Rect2:
	return _rect(window.get_screen_transform(), window.get_visible_rect())


func _button(node: Node, caption: String) -> Button:
	if node is Button and node.text == caption:
		return node
	for child in node.get_children():
		var found := _button(child, caption)
		if found != null:
			return found
	return null


func _scroll(node: Node) -> ScrollContainer:
	if node is ScrollContainer:
		return node
	for child in node.get_children():
		var found := _scroll(child)
		if found != null:
			return found
	return null


func _dialog() -> Window:
	for child in game.get_children():
		if child is Window and not child.is_queued_for_deletion():
			return child
	return null


func _target(control: Control, label: String, exposed: bool = true) -> void:
	_check(is_instance_valid(control), label + " exists")
	if not is_instance_valid(control):
		return
	var pixels := _pixels(control)
	var dp := pixels.size / density
	_check(control.is_visible_in_tree(), label + " is visible")
	_check(minf(dp.x, dp.y) >= 47.99, "%s actual hit area %s dp" % [label, dp])
	if exposed:
		_check(Rect2(Vector2.ZERO, Vector2(root.size)).grow(0.51).encloses(pixels), label + " fits the physical display")
		_check(_window_pixels(control.get_window()).grow(0.51).encloses(pixels), label + " fits its actual popup viewport")
		var ancestor := control.get_parent()
		while ancestor != null:
			if ancestor is Control and ancestor.clip_contents:
				_check(_pixels(ancestor).grow(0.51).encloses(pixels), label + " is fully exposed inside " + str(ancestor.name))
			ancestor = ancestor.get_parent()
	targets.append({"surface": [root.size.x, root.size.y], "density": density, "label": label,
		"physical_size": [pixels.size.x, pixels.size.y], "dp": [dp.x, dp.y], "fully_exposed_required": exposed,
		"popup_size": [control.get_window().size.x, control.get_window().size.y],
		"viewport_screen_transform": str(control.get_viewport().get_screen_transform())})


func _touch(point: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 4
	event.position = point
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	await process_frame


func _tap(control: Control, edge: bool = false) -> void:
	if not is_instance_valid(control):
		return
	var point := _pixels(control).get_center()
	if edge:
		point.y += 22.0 * density
	await _touch(point, true)
	await _touch(point, false)
	await _settle()


func _swipe_up(scroll: ScrollContainer) -> void:
	var rect := _pixels(scroll)
	var start := rect.position + rect.size * Vector2(0.5, 0.85)
	var end := rect.position + rect.size * Vector2(0.5, 0.15)
	await _drag_screen(start, end)


func _drag_screen(start: Vector2, end: Vector2) -> void:
	await _touch(start, true)
	var previous := start
	for step in range(1, 9):
		var point := start.lerp(end, float(step) / 8.0)
		var drag := InputEventScreenDrag.new()
		drag.index = 4
		drag.position = point
		drag.relative = point - previous
		drag.screen_relative = drag.relative
		drag.velocity = drag.relative * 60.0
		drag.screen_velocity = drag.velocity
		Input.parse_input_event(drag)
		Input.flush_buffered_events()
		previous = point
		await process_frame
	await _touch(end, false)
	await _settle()


func _reveal_toolbar(control: Control) -> void:
	var ancestor := control.get_parent()
	while ancestor != null and not ancestor is ScrollContainer:
		ancestor = ancestor.get_parent()
	if not ancestor is ScrollContainer:
		return
	var scroll: ScrollContainer = ancestor
	var before: Dictionary = game.model.to_data()
	for attempt in range(20):
		var viewport := _pixels(scroll)
		var target := _pixels(control)
		print("[ToolbarProbe] ", control.text," attempt=",attempt," scroll=",scroll.scroll_horizontal," viewport=",viewport," target=",target)
		if viewport.grow(0.51).encloses(target):
			break
		var left := target.end.x > viewport.end.x
		var start := viewport.position + viewport.size * Vector2(0.82 if left else 0.18, 0.4)
		var end := viewport.position + viewport.size * Vector2(0.18 if left else 0.82, 0.4)
		await _drag_screen(start, end)
	_check(_pixels(scroll).grow(0.51).encloses(_pixels(control)), "Actual horizontal drags expose toolbar action " + str(control.text))
	_check(game.model.to_data() == before, "Toolbar drags never build or modify objects underneath")


func _reveal_with_touch(scroll: ScrollContainer, last: Button) -> void:
	var initial := scroll.scroll_vertical
	for attempt in range(12):
		if _pixels(scroll).grow(0.51).encloses(_pixels(last)):
			break
		await _swipe_up(scroll)
	_check(scroll.scroll_vertical > initial, "Actual screen drags scroll the long selection list")
	_target(last, "last choice after real vertical drag")


func _open(caption: String) -> Window:
	var button := _button(game, caption)
	_check(button != null, "Production toolbar contains " + caption)
	if button == null:
		return null
	await _reveal_toolbar(button)
	_target(button, "toolbar " + caption)
	await _tap(button)
	var dialog := _dialog()
	_check(dialog != null, "Actual toolbar touch opens " + caption)
	if dialog != null:
		_check(dialog.is_embedded(), "Production dialog is embedded in the app")
		_check(dialog.size.x > 48 and dialog.size.y > 120, "Actual Window viewport is usable")
		_check(_pixels(game.safe_ui).grow(0.51).encloses(_window_pixels(dialog)), "Dialog fits the safe content area")
		_target(_button(dialog, "Abbrechen"), "fixed cancel at opening")
	return dialog


func _shot(stage: String) -> void:
	# The fifth, 320dp case guards the additional toolbar interception finding.
	# Keep the eight template captures plus four explicit current-goal captures.
	if not capture or root.size == Vector2i(640, 320):
		return
	await _settle()
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	_check(image != null and image.get_size() == root.size, "Genuine current embedded-dialog renderer surface")
	if image == null:
		return
	var name := "build-dialog-%dx%d-%s.png" % [root.size.x, root.size.y, stage]
	_check(image.save_png(output.path_join(name)) == OK, "Renderer capture saved: " + name)
	images.append({"filename": name, "width": image.get_width(), "height": image.get_height(), "density": density,
		"renderer": RenderingServer.get_current_rendering_method()})


func _fixture_surface(size: Vector2i, ui_density: float) -> void:
	root.size = size
	density = ui_density
	root.get_node("HostBridge")._options["displayDensity"] = density
	game._resize()
	await _settle(16)


func _goal_access(profile: Array) -> void:
	var initially_inline: bool = game.goal_panel.visible
	_check(initially_inline != game.goal_access_button.visible,
		"Exactly one current-goal entry presentation is visible")
	if initially_inline:
		_check(not _pixels(game.goal_panel).intersects(_pixels(game.lower_hud)),
			"Inline assignment is not covered by the lower HUD")
		_target(_button(game.goal_panel, "Mein Bauwerk testen"), "inline goal test before rotation")
		await _fixture_surface(Vector2i(640, 320), 1.0)
	_check(not game.goal_panel.visible and game.goal_access_button.visible,
		"A short display exposes the assignment through the existing toolbar")
	_check(game.save_world(false), "Pre-assignment project saves normally")
	var before: Dictionary = game.model.to_data()
	var before_file := FileAccess.get_file_as_string(game.save_path)
	var expected_description: String = game.goal_label.text
	var goal_before: String = game.goal
	var dialog := await _open("Aktuelles Bauziel")
	if dialog == null:
		return
	var details: Label = dialog.find_child("BuildGoalDescription", true, false)
	_check(details != null and details.text == expected_description,
		"Assignment dialog retains the complete current goal explanation")
	await _tap(_button(dialog, "Abbrechen"), true)
	_check(not is_instance_valid(dialog) and game.model.to_data() == before
		and game.goal == goal_before and FileAccess.get_file_as_string(game.save_path) == before_file,
		"Cancelling the assignment preserves goal, objects and saved bytes")
	dialog = await _open("Aktuelles Bauziel")
	if dialog == null:
		return
	if initially_inline:
		# A real toolbar touch opened the dialog before the orientation change.
		# The screenshot is a reachable open-modal state at the original size.
		await _fixture_surface(profile[0], float(profile[1]))
		_check(game.goal_panel.visible and not game.goal_access_button.visible,
			"Returning to a tall layout restores only its inline assignment entry")
		_check(not _pixels(game.goal_panel).intersects(_pixels(game.lower_hud)),
			"Restored inline assignment remains clear of the palette")
	_target(_button(dialog, "Abbrechen"), "assignment cancel after layout change")
	var test_button := _button(dialog, "Mein Bauwerk testen")
	_target(test_button, "assignment actual test action")
	var scroll := _scroll(dialog)
	_check(_pixels(scroll).grow(0.51).encloses(_pixels(test_button)),
		"The full 48dp assignment action is exposed inside the dialog")
	await _shot("current-goal")
	var activated := [0]
	test_button.pressed.connect(func(): activated[0] += 1)
	var category_before: String = game.category
	var expected_success: bool = game.model.challenge_passes(game.goal)
	await _tap(test_button, true)
	_check(activated[0] == 1 and not is_instance_valid(dialog),
		"Real edge ScreenTouch activates the original goal test exactly once")
	_check(game.category == category_before, "Testing a goal never chooses the obscuring roof category")
	_check(game.status.text.begins_with("Bauziel geschafft!") if expected_success
		else game.status.text.begins_with("Noch fehlt etwas."),
		"The unchanged challenge rule produces the expected test result")
	if initially_inline:
		var inline_test := _button(game.goal_panel, "Mein Bauwerk testen")
		_target(inline_test, "restored inline goal action")
		await _tap(inline_test, true)
		_check(game.category == category_before,
			"The restored inline goal action does not hit the palette")


func _exercise(caption: String, expected: Array, final_label: String) -> void:
	_check(game.save_world(false), "Isolated pre-dialog world saves normally")
	var before: Dictionary = game.model.to_data()
	var before_goal: String = game.goal
	var before_slot: int = game.slot
	var before_file := FileAccess.get_file_as_string(game.save_path)
	var dialog := await _open(caption)
	if dialog == null:
		return
	var scroll := _scroll(dialog)
	_check(scroll != null, caption + " has a bounded scroll viewport")
	if scroll == null:
		dialog.queue_free()
		await _settle()
		return
	var labels: Array[String] = []
	for child in scroll.get_child(0).get_children():
		if child is Button:
			labels.append(child.text)
			_target(child, "preserved option " + child.text, false)
	if caption == "Welten (6)":
		_check(labels.size() == 6, "All six original save slots remain")
		for index in range(labels.size()):
			_check(labels[index].begins_with("Welt %d · " % (index + 1)), "Slot order and identity remain " + str(index + 1))
	else:
		_check(labels == expected, "Every original option and its order remain: " + caption)
	if caption == "Vorlagen":
		await _shot("templates-top")
	var last := _button(dialog, final_label)
	if caption == "Welten (6)":
		last = _button(dialog, labels.back())
	_check(last != null, "Last choice is present: " + caption)
	if last != null:
		# Short lists fit on taller screens; long lists require actual drag input.
		if not _pixels(scroll).grow(0.51).encloses(_pixels(last)):
			await _reveal_with_touch(scroll, last)
		else:
			_target(last, "last choice already exposed")
	_target(_button(dialog, "Abbrechen"), "fixed cancel after bottom scroll")
	if caption == "Vorlagen":
		await _shot("templates-bottom")
	await _tap(_button(dialog, "Abbrechen"), true)
	_check(not is_instance_valid(dialog), "Actual 48dp-edge cancel tap closes " + caption)
	_check(game.model.to_data() == before and game.goal == before_goal and game.slot == before_slot,
		"Cancellation preserves build objects, goal and selected slot")
	_check(FileAccess.get_file_as_string(game.save_path) == before_file, "Cancellation preserves saved bytes")
	if is_instance_valid(dialog):
		dialog.queue_free()
		await _settle()
	dialog = await _open(caption)
	if dialog == null:
		return
	scroll = _scroll(dialog)
	last = _button(dialog, final_label) if caption != "Welten (6)" else _button(dialog, labels.back())
	if scroll == null or last == null:
		dialog.queue_free()
		await _settle()
		return
	if not _pixels(scroll).grow(0.51).encloses(_pixels(last)):
		await _reveal_with_touch(scroll, last)
	await _tap(last, true)
	_check(not is_instance_valid(dialog), "Actual last-option edge tap closes " + caption)
	if caption == "Vorlagen":
		_check(game.model.pieces.is_empty(), "Actual Leere Insel touch applies the final template")
	elif caption == "Welten (6)":
		_check(game.slot == 6 and game.save_path.ends_with("_6.json"), "Actual final-slot touch opens original slot six")
	else:
		_check(game.goal == "village", "Actual final-goal touch selects Dorf für Freunde")
	if is_instance_valid(dialog):
		dialog.queue_free()
		await _settle()


func _camera_actions() -> void:
	for caption in ["−", "+", "Mitte"]:
		var button := _button(game.camera_tools, caption)
		await _reveal_toolbar(button)
		_target(button, "reachable camera action " + caption)
		var before: float = game.radius
		await _tap(button)
		var expected := clampf(before + 3, game.RADIUS_MIN, game.RADIUS_MAX)
		if caption == "+":
			expected = clampf(before - 3, game.RADIUS_MIN, game.RADIUS_MAX)
		elif caption == "Mitte":
			expected = game.START_RADIUS
		_check(is_equal_approx(game.radius, expected), "Actual camera touch remains connected: " + caption)
	if root.get_visible_rect().size.y <= 360:
		_check(game.camera_tools.get_parent() == game.tool_actions,
			"Short-height camera controls join the existing toolbar without intercepting its buttons")
	else:
		_check(game.camera_tools.get_parent() == game.safe_ui,
			"At normal height camera controls retain their floating presentation")


func _run() -> void:
	if capture and DisplayServer.get_name() == "headless":
		push_error("[BuildDialogDensity] --capture requires a real renderer")
		quit(1)
		return
	if capture:
		DirAccess.make_dir_recursive_absolute(output)
	var host = root.get_node("HostBridge")
	var previous_touch_emulation := Input.emulate_touch_from_mouse
	# Android reports a touchscreen. The desktop test must enable the same
	# ScrollContainer touch path before injecting genuine ScreenDrag events.
	Input.emulate_touch_from_mouse = true
	_check(DisplayServer.is_touchscreen_available() and Input.emulate_mouse_from_touch,
		"Isolated desktop fixture enables Android-style touch routing")
	for index in range(1, 2):
		var profile: Array = PROFILES[index]
		density = float(profile[1])
		host._options = {"displayDensity": density, "soundEnabled": false, "reduceAnimations": true}
		root.size = profile[0]
		var original_embed := index % 2 == 0
		root.gui_embed_subwindows = original_embed
		var child := "build-dialog-density-%d-%d" % [OS.get_process_id(), index]
		root.get_node("SceneRouter").launch_options = {"childKey": child, "buildSlot": 1}
		game = load("res://scenes/creative/build_world.tscn").instantiate()
		root.add_child(game)
		current_scene = game
		await _settle(16)
		_check(root.gui_embed_subwindows, "Production entry embeds dialogs without test forcing it")
		await _goal_access(profile)
		await _camera_actions()
		await _exercise("Vorlagen", TEMPLATE_LABELS, "Leere Insel")
		await _exercise("Welten (6)", [], "")
		await _exercise("Bauziele", GOAL_LABELS, "Dorf für Freunde")
		# Resizing an already open modal must release its old minimum size.
		var dialog := await _open("Vorlagen")
		if dialog != null:
			root.size = Vector2i(640, 320)
			host._options["displayDensity"] = 1.0
			density = 1.0
			game._resize()
			await _settle(12)
			_check(_pixels(game.safe_ui).grow(0.51).encloses(_window_pixels(dialog)), "Open modal remains bounded after orientation/density change")
			_target(_button(dialog, "Abbrechen"), "cancel after live resize")
			await _tap(_button(dialog, "Abbrechen"), true)
			_check(not is_instance_valid(dialog), "Actual cancel after resize releases the modal")
		# Exit with a modal still open: no exclusive window or input ownership
		# may survive to the following scene, for either prior embed setting.
		await _open("Vorlagen")
		game.queue_free()
		await _settle(12)
		_check(root.gui_embed_subwindows == original_embed, "Scene exit restores the previous embedding policy")
		_check(root.get_embedded_subwindows().is_empty(), "Scene exit releases every embedded modal")
		var next_action := Button.new()
		next_action.text = "Next scene input"
		next_action.position = Vector2(20, 20)
		next_action.size = Vector2(200, 60)
		var received := [false]
		next_action.pressed.connect(func(): received[0] = true)
		root.add_child(next_action)
		await _settle()
		if DisplayServer.get_name() != "headless":
			# parse_input_event() does not move the desktop OS pointer. After
			# the live resize, X11 may still consider the native window exited.
			# Establish window entry at its center, away from the target; the
			# following press must still come from the original ScreenTouch path.
			print("[BuildDialogDensity] desktop entry before: position=", root.position,
				" size=", root.size, " viewport=", root.get_visible_rect(),
				" screen_transform=", root.get_screen_transform(),
				" pointer=", root.get_mouse_position(), " focused=", root.has_focus())
			root.warp_mouse(root.get_visible_rect().get_center())
			await _settle()
			_check(root.get_visible_rect().has_point(root.get_mouse_position()),
				"Desktop pointer enters the restored window before touch injection")
		await _tap(next_action)
		_check(received[0], "A subsequent scene receives routed touch after modal scene exit")
		next_action.queue_free()
		await _settle()
		print("[BuildDialogDensity] CASE ", profile, " checks=", checks, " failures=", failures.size())
	if capture:
		_check(images.size() == 12, "Exactly twelve genuine captures: eight templates and four current goals")
		var record := FileAccess.open(output.path_join("measurements.json"), FileAccess.WRITE)
		record.store_string(JSON.stringify({"images": images, "targets": targets,
			"scope": "Production scene, own popup transforms, real InputEvents and explicit density fixtures; not a physical Android/Fold7 test"}, "\t"))
	Input.emulate_touch_from_mouse = previous_touch_emulation
	if failures.is_empty():
		print("[BuildDialogDensity] PASS %d checks: bounded dialogs, preserved choices, actual scroll/select/cancel, >=48dp and restore" % checks)
		quit(0)
	else:
		print("[BuildDialogDensity] FAIL ", failures)
		quit(1)
