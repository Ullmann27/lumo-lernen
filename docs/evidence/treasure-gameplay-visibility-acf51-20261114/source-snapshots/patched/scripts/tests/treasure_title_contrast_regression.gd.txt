extends SceneTree
## Actual production HUD and touch input with an explicit saved-position and
## asynchronous inset fixture. This is local renderer evidence, not Android.

const PROFILES := [
	[Vector2i(1920, 1080), 1.5, Rect2(112, 36, 0, 24), "landscape"],
	[Vector2i(640, 320), 1.0, Rect2(), "compact"],
	[Vector2i(1080, 2400), 2.625, Rect2(0, 136, 0, 63), "portrait"],
	[Vector2i(2176, 1812), 2.25, Rect2(0, 136, 0, 63), "fold"],
	[Vector2i(2400, 1080), 2.625, Rect2(136, 63, 0, 63), "landscape-cutout"],
]

var checks := 0
var failures: Array[String] = []
var observations: Array[Dictionary] = []
var game
var mobile
var density := 1.0
var insets := Rect2()
var output := "user://treasure-title-contrast"
var capture := false


func _initialize() -> void:
	capture = "--capture" in OS.get_cmdline_user_args()
	if not OS.get_environment("LUMO_CAPTURE_DIR").is_empty():
		output = OS.get_environment("LUMO_CAPTURE_DIR")
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)
		push_error("[TreasureTitleContrast] " + description)


func _settle(count: int = 8) -> void:
	for index in range(count):
		await process_frame


func _physical(control: Control) -> Rect2:
	var transform := control.get_global_transform_with_canvas()
	var rect := Rect2(transform * Vector2.ZERO, Vector2.ZERO)
	for point in [Vector2(control.size.x, 0), control.size, Vector2(0, control.size.y)]:
		rect = rect.expand(transform * point)
	var factor := Vector2(root.size) / root.get_visible_rect().size
	return Rect2(rect.position * factor, rect.size * factor)


func _request(completed: Callable) -> bool:
	completed.call_deferred({"view_size": Vector2(root.size), "decor_size": Vector2(root.size),
		"render_rect": Rect2(Vector2.ZERO, Vector2(root.size)),
		"system_insets": insets, "insets": insets})
	return true


func _button(caption: String) -> Button:
	for control in game.find_children("*", "Button", true, false):
		if control.text == caption and control.is_visible_in_tree():
			return control
	return null


func _exposed(control: Control) -> Rect2:
	var rect := _physical(control)
	var ancestor := control.get_parent()
	while ancestor != null:
		if ancestor is Control and ancestor.clip_contents:
			rect = rect.intersection(_physical(ancestor))
		ancestor = ancestor.get_parent()
	return rect.intersection(_physical(game.safe_ui))


func _tap(control: Button) -> void:
	_check(is_instance_valid(control), "Real button exists")
	if not is_instance_valid(control):
		return
	var rect := _physical(control)
	_check(minf(rect.size.x, rect.size.y) / density >= 47.99, control.text + " remains at least48dp")
	_check(_physical(game.safe_ui).grow(0.51).encloses(rect), control.text + " remains inside safe area")
	var exposed := _exposed(control)
	_check(minf(exposed.size.x, exposed.size.y) / density >= 47.95,
		control.text + " exposes a real 48dp touch surface through all clipping ancestors")
	# Establish the desktop pointer only for X11's synthetic-touch prerequisite.
	# The action itself still comes from an actual ScreenTouch press/release.
	for point in [Vector2.ZERO, exposed.get_center()]:
		var motion := InputEventMouseMotion.new()
		motion.position = point
		Input.parse_input_event(motion)
		await process_frame
	for down in [true, false]:
		var touch := InputEventScreenTouch.new()
		touch.index = 0
		touch.position = exposed.get_center()
		touch.pressed = down
		Input.parse_input_event(touch)
		await _settle(2)
	await _settle(4)


func _linear(value: float) -> float:
	return value / 12.92 if value <= 0.04045 else pow((value + 0.055) / 1.055, 2.4)


func _luminance(color: Color) -> float:
	return _linear(color.r) * 0.2126 + _linear(color.g) * 0.7152 + _linear(color.b) * 0.0722


func _progress() -> Dictionary:
	var value: Dictionary = game.model.to_data().duplicate(true)
	# Normal gravity and automatic positional saving continue during this test.
	# The unchanged quest identity and progress are the invariant under HUD taps.
	value.erase("position")
	return value


func _rect_values(rect: Rect2) -> Array:
	return [rect.position.x, rect.position.y, rect.size.x, rect.size.y]


func _avatar_pixels() -> Rect2:
	# Project every corner of the actual visible companion meshes. A hard-coded
	# screen point would miss the original body/face occlusion at compact sizes.
	var result := Rect2()
	var first := true
	var factor := Vector2(root.size) / root.get_visible_rect().size
	for node in game.fox.find_children("*", "MeshInstance3D", true, false):
		if node.mesh == null or not node.is_visible_in_tree():
			continue
		var bounds: AABB = node.get_aabb()
		for index in range(8):
			var world: Vector3 = node.global_transform * bounds.get_endpoint(index)
			_check(not game.camera.is_position_behind(world), "Actual fox mesh remains in front of camera")
			var point: Vector2 = game.camera.unproject_position(world) * factor
			if first:
				result = Rect2(point, Vector2.ZERO)
				first = false
			else:
				result = result.expand(point)
	_check(not first and result.has_area(), "Actual fox mesh provides a nonempty projected silhouette bound")
	return result


func _gameplay_view(label: String) -> Dictionary:
	var avatar := _avatar_pixels()
	_check(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(avatar), label + " entire fox remains within the view")
	var regions: Array[Dictionary] = []
	var controls := [
		{"role": "header", "control": game.top},
		{"role": "clue", "control": game.clue_panel},
		{"role": "toast", "control": game.toast},
		{"role": "joystick", "control": game.joystick},
		{"role": "action", "control": game.action},
		{"role": "jump", "control": game.jump_button},
	]
	var hint := _button("Hinweis")
	if is_instance_valid(hint):
		controls.append({"role": "hint", "control": hint})
	var toast_rect := _physical(game.toast)
	for entry in controls:
		var control: Control = entry.control
		if not control.is_visible_in_tree():
			continue
		var rect := _physical(control)
		var overlap := rect.intersection(avatar)
		regions.append({"role": entry.role, "name": str(control.name), "rect_px": _rect_values(rect),
			"overlap_px": _rect_values(overlap)})
		_check(not rect.intersects(avatar), label + " HUD does not cover actual fox: " + str(control.name))
		if entry.role in ["joystick", "action", "jump", "hint"]:
			_check(not rect.intersects(toast_rect), label + " message does not cover touch control: " + str(entry.role))
	var background = game.toast.get_theme_stylebox("normal")
	var contrast := 0.0
	_check(background is StyleBoxFlat, label + " secondary message has a real backdrop")
	if background is StyleBoxFlat:
		_check(background.bg_color.a >= 0.90, label + " secondary backdrop resists bright scenery")
		var color: Color = background.bg_color
		var white := Color(color.r * color.a + 1.0 - color.a,
			color.g * color.a + 1.0 - color.a, color.b * color.a + 1.0 - color.a)
		contrast = (_luminance(game.toast.get_theme_color("font_color")) + 0.05) / (_luminance(white) + 0.05)
		_check(contrast >= 7.0, label + " secondary text retains at least 7:1 contrast")
	_check(_physical(game.safe_ui).grow(0.51).encloses(_physical(game.toast)), label + " entire message is inside safe area")
	_check(game.toast.get_visible_line_count() == game.toast.get_line_count(), label + " full secondary message remains visible")
	return {"avatar_rect_px": _rect_values(avatar), "hud_rects": regions,
		"secondary_white_backdrop_contrast": contrast}


func _hint_input() -> void:
	var compact: bool = game.safe_ui.size.y < 480 and game.safe_ui.size.x >= 600
	var hint := _button("Hinweis")
	if not compact:
		_check(game.clue_panel.is_visible_in_tree(), "Tall format keeps its existing visible clue")
		_check(not is_instance_valid(hint), "Tall format does not duplicate the clue control")
		return
	_check(not game.clue_panel.is_visible_in_tree(), "Compact format removes the obstructing permanent clue panel")
	_check(is_instance_valid(hint), "Compact format exposes a real full-clue button")
	if not is_instance_valid(hint):
		return
	var before := _progress()
	var full_text: String = game.clue_label.text
	await _tap(hint)
	_check(game.paused and game.modal.visible, "Actual clue touch opens the existing modal and pauses exploration")
	var found := false
	for child in game.modal_box.get_children():
		if child is Label and child.text == full_text:
			found = true
	_check(found, "Clue dialog retains the complete existing progress and clue text")
	_check(game.modal_scroll.is_visible_in_tree(), "Full clue uses the existing bounded scroll container")
	await _tap(hint)
	var after_background_tap := false
	for child in game.modal_box.get_children():
		if child is Label and child.text == full_text:
			after_background_tap = true
	_check(game.paused and game.modal.visible and after_background_tap,
		"Background clue touch cannot replace or dismiss the active dialog")
	await _tap(_button("Weiter erkunden"))
	_check(not game.paused and not game.modal.visible, "Actual clue close restores exploration")
	_check(_progress() == before, "Opening and closing clue does not alter quest or reward identity")


func _case(profile: Array, index: int, restored: bool) -> void:
	root.size = profile[0]
	density = profile[1]
	insets = profile[2]
	await _settle()
	mobile.request_safe_area_refresh()
	await _settle()
	var child := "treasure-title-contrast-%d-%s" % [index, "restored" if restored else "spawn"]
	var save_path := "user://lumo_treasure_" + child + ".json"
	DirAccess.remove_absolute(save_path)
	if restored:
		var raw := FileAccess.get_file_as_string("res://scripts/tests/fixtures/treasure_title_86445.json")
		var file := FileAccess.open(save_path, FileAccess.WRITE)
		file.store_string(raw)
		file.close()
	var options := {"displayDensity": density, "soundEnabled": false,
		"reduceAnimations": true, "childKey": child}
	root.get_node("HostBridge")._options = options
	root.get_node("SceneRouter").launch_options = options.duplicate(true)
	game = load("res://scenes/creative/treasure_world.tscn").instantiate()
	root.add_child(game)
	await _settle(30)
	_check(game.model.to_data().get("solved_clues", []).has("tree") == restored,
		"Declared original saved-position fixture or genuine fresh start loaded")
	_check(game.title_label.text == "LUMOS STERNENSCHATZ", "Exact existing title unchanged")
	_check(_physical(game.safe_ui).grow(0.51).encloses(_physical(game.title_label)), "Title remains inside safe UI")
	var background = game.title_label.get_theme_stylebox("normal")
	var contrast := 0.0
	_check(background is StyleBoxFlat, "Title has a real contrasting backdrop")
	if background is StyleBoxFlat:
		_check(background.bg_color.a >= 0.90, "Bright cloud cannot erase title backdrop")
		var color: Color = background.bg_color
		var on_white := Color(color.r * color.a + 1.0 - color.a,
			color.g * color.a + 1.0 - color.a, color.b * color.a + 1.0 - color.a)
		contrast = (_luminance(game.title_label.get_theme_color("font_color")) + 0.05) / (_luminance(on_white) + 0.05)
		_check(contrast >= 7.0, "Title keeps readable contrast over white scenery")
	for control in game.top.get_children():
		if control is Button:
			var rect := _physical(control)
			_check(minf(rect.size.x, rect.size.y) / density >= 47.99, "Header touch size preserved: " + control.text)
			_check(_physical(game.safe_ui).grow(0.51).encloses(rect), "Header stays in safe area: " + control.text)
			_check(not rect.intersects(_physical(game.title_label)), "Title does not cover header input: " + control.text)
	var before := _progress()
	var view := _gameplay_view(str(profile[3]) + (" restored" if restored else " spawn"))
	var item := {"profile": profile[3], "window_px": [root.size.x, root.size.y],
		"density": density, "insets_fixture": [insets.position.x, insets.position.y, insets.size.x, insets.size.y],
		"title_rect": [_physical(game.title_label).position.x, _physical(game.title_label).position.y,
			_physical(game.title_label).size.x, _physical(game.title_label).size.y],
		"worst_white_backdrop_contrast": contrast,
		"initial_state_fixture": "original86445 first tree save" if restored else "production fresh start",
		"gameplay_view": view}
	# Preserve the four original restored-position capture names. The new
	# exact 2400x1080 case records the fresh spawn from the reported failure.
	if capture and (restored if index < 4 else not restored):
		_check(DisplayServer.get_name() != "headless", "PNG requires a real renderer")
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		var path := output.path_join("treasure-title-" + str(profile[3]) + ".png")
		_check(image.save_png(path) == OK, "Fresh original viewport PNG saved")
		item["image"] = path
		item["image_sha256"] = FileAccess.get_sha256(path)
		item["image_px"] = [image.get_width(), image.get_height()]
	await _hint_input()
	await _tap(_button("Rucksack"))
	_check(game.paused and game.modal.visible, "Actual inventory touch still opens its dialog")
	await _tap(_button("Weiter erkunden"))
	_check(not game.paused and not game.modal.visible, "Actual inventory close resumes scene")
	await _tap(_button("Ⅱ"))
	_check(game.paused and game.modal.visible, "Actual pause touch still opens its dialog")
	await _tap(_button("Weiter erkunden"))
	_check(not game.paused and not game.modal.visible, "Actual pause close resumes scene")
	_check(_progress() == before, "Quest progress and identity unchanged by all four real taps")
	_gameplay_view(str(profile[3]) + " after dialog close")
	observations.append(item)
	game.queue_free()
	await _settle()
	DirAccess.remove_absolute(save_path)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(output)
	mobile = root.get_node("MobileRuntime")
	var prior_reader: Callable = mobile._safe_area_reader
	var prior_enabled: bool = mobile._android_safe_area_enabled
	var prior_emulation := Input.emulate_touch_from_mouse
	var prior_options: Dictionary = root.get_node("HostBridge")._options.duplicate(true)
	var prior_launch: Dictionary = root.get_node("SceneRouter").launch_options.duplicate(true)
	mobile._safe_area_reader = _request
	mobile._android_safe_area_enabled = true
	mobile.set_process(true)
	Input.emulate_touch_from_mouse = true
	for index in range(PROFILES.size()):
		for restored in [false, true]:
			await _case(PROFILES[index], index, restored)
	_check(observations.size() == PROFILES.size() * 2 and checks >= 100,
		"Every declared profile and its actual input checks completed")
	mobile._safe_area_reader = prior_reader
	mobile._android_safe_area_enabled = prior_enabled
	mobile.set_process(prior_enabled)
	Input.emulate_touch_from_mouse = prior_emulation
	root.get_node("HostBridge")._options = prior_options
	root.get_node("SceneRouter").launch_options = prior_launch
	var file := FileAccess.open(output.path_join("treasure-title-report.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks": checks, "failures": failures, "observations": observations,
		"scope": "Production HUD, real ScreenTouch, declared saved-position and Android-boundary fixture; not device execution"}, "  "))
	file.close()
	print("[TreasureTitleContrast] %s checks=%d failures=%d" % ["PASS" if failures.is_empty() else "FAIL", checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
