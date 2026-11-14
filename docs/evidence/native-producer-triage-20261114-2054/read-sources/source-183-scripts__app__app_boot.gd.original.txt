## 2013 game-identity covers are generated from real scene captures; never reuse puzzle motifs.
## The existing Godot boot route with a themed real-image game entry.
## No invented percent, account registration or additional gameplay state.
extends Node

const UI = preload("res://scripts/games/kart_ui_theme.gd")
const WORDMARK = preload("res://scripts/games/kart_wordmark.gd")
const MENU_ART = preload("res://scripts/games/kart_menu_art.gd")
const LUMO_MODEL := "res://assets/characters/lumo_animated/Lumo-Animated-Mobile.glb"
const LOAD_TIMEOUT_SECONDS := 30.0
const COVER_BY_SCENE: Dictionary = {
	"kart": "res://assets/kart/menu/lumo-world.webp",
	"build": "res://assets/creative/covers/build.png",
	"settlement": "res://assets/creative/covers/build.png",
	"puzzle": "res://assets/creative/covers/puzzle.png",
	"rhythm": "res://assets/creative/covers/rhythm.png",
	"treasure": "res://assets/creative/covers/treasure.png",
	"jump": "res://assets/kart/menu/lumo-world.webp",
}
const TITLE_BY_SCENE: Dictionary = {
	"kart": "LUMO KART",
	"build": "LUMO BAUWELT",
	"settlement": "LUMO DORF & WIRTSCHAFT",
	"puzzle": "LUMO PUZZLE-ATELIER",
	"rhythm": "LUMO RHYTHM PARTY",
	"treasure": "LUMO SCHATZSUCHE",
	"jump": "LUMO ABENTEUER",
	"learning": "LUMO LERNWERKSTATT",
	"cards": "LUMO CARDS",
	"connect_four": "VIER GEWINNT",
	"memory": "LUMO MEMORY",
	"quiz": "LUMO QUIZSHOW",
}
signal load_state_changed(state: String)
## Test harnesses may attach the actual boot scene without starting navigation.
## No host/settings option can enable these capture-only controls.
var auto_begin := true
var auto_transition := true
var target_scene := ""
var load_phase := "idle"
var actual_progress := 0.0
var _paths: Array[String] = []
var _resources: Dictionary = {}
var _load_started_ms := 0
var _reduced_motion := false
var _fade: Tween
var _logo: Control
var _retry_row: HBoxContainer
var _retry_button: Button
var _back_button: Button
var _hero_box: SubViewportContainer
var _hero_viewport: SubViewport
var _hero: Node3D
var _hero_camera: Camera3D
var _hero_clock := 0.0


func _ready() -> void:
	EventBus.boot_started.emit()
	var options: Dictionary = {}
	if OS.has_feature("web"):
		var raw = JavaScriptBridge.eval(
			"JSON.stringify(Object.fromEntries(new URL(window.location.href).searchParams))"
		)
		var parsed = JSON.parse_string(str(raw))
		if parsed is Dictionary:
			options = parsed
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--") and arg.contains("="):
			var pair = arg.trim_prefix("--").split("=", true, 1)
			options[pair[0]] = pair[1]
	# Embedded host identity wins; all original grade/profile options survive.
	if HostBridge.is_embedded():
		options.merge(HostBridge.launch_options(), true)
	SceneRouter.launch_options = options
	_reduced_motion = bool(options.get("reduceAnimations", false))
	var session := ConfigFile.new()
	if session.load("user://kart_sonnenhafen_session.cfg") == OK:
		_reduced_motion = _reduced_motion or bool(session.get_value("race", "reduced_motion", false))
	var requested: String = str(options.get("scene", ""))
	var target: String = requested if requested in [
		"kart", "jump", "puzzle", "build", "settlement", "rhythm", "treasure", "learning", "cards", "connect_four", "memory", "quiz", "home", "games"
	] else "games"
	_show_cover(target)
	_build_actions()
	get_viewport().size_changed.connect(_layout)
	MobileRuntime.safe_area_changed.connect(_layout)
	_layout()
	SceneRouter.loaded_navigation_failed.connect(_navigation_failed)
	# Let the real cover render before requesting the scene and native model.
	await get_tree().process_frame
	if auto_begin:
		_begin_loading(target)


func _build_actions() -> void:
	_logo = WORDMARK.new()
	$Layer.add_child(_logo)
	_retry_row = HBoxContainer.new()
	_retry_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_retry_row.add_theme_constant_override("separation", 12)
	$Layer.add_child(_retry_row)
	for caption in ["Erneut versuchen", "Zur Spielewelt"]:
		var button := Button.new()
		button.text = caption
		button.theme = UI.create()
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(130, 48)
		var style := StyleBoxFlat.new()
		style.bg_color = Color("ffd645") if caption == "Erneut versuchen" else Color("153757")
		style.border_color = Color("fff6bf") if caption == "Erneut versuchen" else Color("72eaff")
		style.set_border_width_all(2)
		style.set_corner_radius_all(16)
		style.set_content_margin_all(6)
		button.add_theme_stylebox_override("normal", style)
		button.add_theme_stylebox_override("hover", style)
		button.add_theme_stylebox_override("pressed", style)
		button.add_theme_color_override("font_color", Color("143463") if caption == "Erneut versuchen" else Color("f7fbff"))
		_retry_row.add_child(button)
	_retry_button = _retry_row.get_child(0)
	_back_button = _retry_row.get_child(1)
	_retry_button.pressed.connect(func(): _begin_loading(target_scene))
	_back_button.pressed.connect(_back_to_games)
	_retry_row.hide()


func _begin_loading(scene_id: String) -> void:
	if load_phase in ["loading", "transitioning"]:
		return
	target_scene = scene_id
	_show_cover(scene_id)
	if is_instance_valid(_hero_box):
		_hero_box.visible = scene_id == "kart"
		_hero.set_process(scene_id == "kart")
		_hero_viewport.render_target_update_mode = (
			SubViewport.UPDATE_ALWAYS if scene_id == "kart" else SubViewport.UPDATE_DISABLED)
	for child in $Layer.get_children():
		if child is CanvasItem:
			child.modulate.a = 1.0
	_retry_row.hide()
	actual_progress = 0.0
	_resources.clear()
	_paths.clear()
	if not SceneRouter.SCENES.has(scene_id):
		_show_failure("Diese Spielwelt ist gerade nicht verfügbar.")
		return
	_paths.append(str(SceneRouter.SCENES[scene_id]))
	if scene_id == "kart":
		_paths.append(LUMO_MODEL)
	for path in _paths:
		if not ResourceLoader.exists(path, "PackedScene"):
			_show_failure("Die Spielwelt konnte nicht geladen werden. Versuche es noch einmal.")
			return
		# A retry may use a still-running or completed engine request. Never
		# issue two concurrent requests for the same native resource.
		var state := ResourceLoader.load_threaded_get_status(path)
		if state in [ResourceLoader.THREAD_LOAD_IN_PROGRESS, ResourceLoader.THREAD_LOAD_LOADED]:
			continue
		var error := ResourceLoader.load_threaded_request(path, "PackedScene")
		if error != OK:
			_show_failure("Die Spielwelt konnte nicht geladen werden. Versuche es noch einmal.")
			return
	_load_started_ms = Time.get_ticks_msec()
	_set_phase("loading")
	_layout()


func _set_phase(value: String) -> void:
	load_phase = value
	load_state_changed.emit(value)


func _process(delta: float) -> void:
	if load_phase == "loading":
		_poll_loading()
	if is_instance_valid(_hero_camera) and not _reduced_motion and load_phase != "error":
		_hero_clock += delta
		var angle := sin(_hero_clock * 0.45) * 0.045
		_hero_camera.look_at_from_position(
			Vector3(2.37 + angle, 1.96, -3.8), Vector3(0, 1.0, 0))


func _poll_loading() -> void:
	if load_phase != "loading":
		return
	if Time.get_ticks_msec() - _load_started_ms >= LOAD_TIMEOUT_SECONDS * 1000.0:
		_show_failure("Das Laden dauert gerade zu lange. Versuche es noch einmal.")
		return
	var total := 0.0
	var all_loaded := true
	for path in _paths:
		# load_threaded_get consumes the engine's request entry. A resource
		# already retrieved successfully must not be queried as "invalid"
		# while the other native resource is still being loaded.
		if _resources.has(path):
			total += 1.0
			continue
		var progress: Array = []
		var state := ResourceLoader.load_threaded_get_status(path, progress)
		if state in [ResourceLoader.THREAD_LOAD_INVALID_RESOURCE, ResourceLoader.THREAD_LOAD_FAILED]:
			_show_failure("Die Spielwelt konnte nicht geladen werden. Versuche es noch einmal.")
			return
		if state == ResourceLoader.THREAD_LOAD_LOADED:
			total += 1.0
			if not _resources.has(path):
				var resource = ResourceLoader.load_threaded_get(path)
				if not resource is PackedScene or not resource.can_instantiate():
					_show_failure("Die Spielwelt konnte nicht geöffnet werden. Versuche es noch einmal.")
					return
				_resources[path] = resource
		else:
			all_loaded = false
			total += clampf(float(progress[0]), 0.0, 1.0) if not progress.is_empty() else 0.0
	actual_progress = maxf(actual_progress, total / float(_paths.size()))
	var bar: ProgressBar = $Layer/LoadBar
	bar.indeterminate = false
	bar.value = actual_progress * 100.0
	# This is the engine's resource progress, not elapsed time or an invented
	# percentage of total scene initialization. Keep percentage text hidden.
	if target_scene == "kart" and _resources.has(LUMO_MODEL):
		_build_hero()
		$Layer/LoadingLabel.text = "Rennwelt wird vorbereitet …"
	if all_loaded:
		_set_phase("ready")
		$Layer/LoadingLabel.text = "Startklar!"
		if auto_transition:
			_finish_loading()


func _build_hero() -> void:
	if is_instance_valid(_hero):
		return
	_hero_box = SubViewportContainer.new()
	_hero_box.stretch = true
	_hero_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Layer.add_child(_hero_box)
	$Layer.move_child(_hero_box, 2) # Original art, veil, then true transparent 3D.
	_hero_viewport = SubViewport.new()
	_hero_viewport.own_world_3d = true
	_hero_viewport.transparent_bg = true
	_hero_viewport.msaa_3d = Viewport.MSAA_DISABLED if SettingsStore.get_profile() == "low" else Viewport.MSAA_2X
	_hero_box.add_child(_hero_viewport)
	var stage := Node3D.new()
	_hero_viewport.add_child(stage)
	var built: Dictionary = load("res://scripts/games/kart_stage.gd").build(stage, Color("53ddfd"), false)
	_hero_camera = built.camera
	built.key.shadow_enabled = SettingsStore.get_profile() != "low"
	_hero = load("res://scripts/games/kart_vehicle.gd").new()
	_hero.configure("fox", Color("357cba"), "comet")
	_hero.reduced_motion = _reduced_motion
	_hero.set_animated_lumo_enabled(true)
	built.pivot.rotation.y = -0.25
	built.pivot.add_child(_hero)
	if is_instance_valid(_hero.lumo_animation) and not _reduced_motion:
		_hero.lumo_animation.play_menu_behavior("greeting_wave")
	_hero_camera.look_at_from_position(Vector3(2.37, 1.96, -3.8), Vector3(0, 1.0, 0))
	_layout()


func _finish_loading() -> void:
	if load_phase != "ready":
		return
	_set_phase("transitioning")
	SceneRouter.launch_options["reduceAnimations"] = _reduced_motion
	if target_scene == "kart":
		# One entry, not a boot greeting followed by another forced 4.4s intro.
		SceneRouter.launch_options["kartEntryPrepared"] = true
	# Present the actually ready scene once; do not fade a not-yet-drawn hero.
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
	else:
		await get_tree().process_frame
	if not _reduced_motion:
		_fade = create_tween().set_parallel(true)
		for child in $Layer.get_children():
			if child is CanvasItem and child.name not in ["Background", "Veil"]:
				_fade.tween_property(child, "modulate:a", 0.0, 0.16)
		await _fade.finished
	var error := SceneRouter.goto_loaded(target_scene, _resources.get(str(SceneRouter.SCENES[target_scene])))
	if error != OK:
		_show_failure("Die Spielwelt konnte nicht geöffnet werden. Versuche es noch einmal.")


func _show_failure(message: String) -> void:
	_set_phase("error")
	print("[BootLoad] error: ", message)
	$Layer/LoadingLabel.text = message
	$Layer/LoadBar.hide()
	for child in $Layer.get_children():
		if child is CanvasItem:
			child.modulate.a = 1.0
	if is_instance_valid(_retry_row):
		_retry_row.show()
	if is_instance_valid(_hero):
		_hero.set_process(false)
	if is_instance_valid(_hero_viewport):
		_hero_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	_layout()


func _navigation_failed(scene_id: String) -> void:
	if scene_id == target_scene and is_inside_tree():
		_show_failure("Die Spielwelt konnte nicht geöffnet werden. Versuche es noch einmal.")


func _back_to_games() -> void:
	if load_phase == "transitioning":
		return
	if HostBridge.is_embedded():
		if not HostBridge.return_to_app("learn" if target_scene == "learning" else "games"):
			_show_failure(HostBridge.SAVE_FAILURE)
	else:
		_set_phase("idle")
		_begin_loading("games")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_back_to_games()


func _show_cover(scene_id: String) -> void:
	var cover: TextureRect = $Layer/Background
	# Until a renderer capture of this lesson is shipped, use the neutral
	# loading surface instead of falsely presenting the Kart world as learning.
	cover.visible = scene_id not in ["learning", "memory", "quiz"]
	var path: String = str(COVER_BY_SCENE.get(scene_id, "res://assets/kart/menu/lumo-world.webp"))
	cover.texture = MENU_ART.world_texture() if path == MENU_ART.WORLD.resource_path else load(path) as Texture2D
	var title: Label = $Layer/Title
	title.text = str(TITLE_BY_SCENE.get(scene_id, "LUMO SPIELEWELT"))
	title.add_theme_font_override("font", UI.HEADING)
	title.add_theme_color_override("font_color", Color("f7fbff"))
	var subtitle: Label = $Layer/Subtitle
	subtitle.text = "MIT LUMO BEGREIFEN UND AUSPROBIEREN" if scene_id == "learning" else "DEIN NÄCHSTES ABENTEUER"
	subtitle.add_theme_font_override("font", UI.BODY)
	subtitle.add_theme_color_override("font_color", Color("53ddfd"))
	var status: Label = $Layer/LoadingLabel
	status.text = "Deine Lernansicht wird vorbereitet …" if scene_id == "learning" else "Spielwelt wird vorbereitet …"
	if is_instance_valid(_back_button):
		_back_button.text = "Zur Aufgabe" if scene_id == "learning" else "Zur Spielewelt"
	status.add_theme_font_override("font", UI.BODY)
	status.add_theme_color_override("font_color", Color("f7fbff"))
	var bar: ProgressBar = $Layer/LoadBar
	bar.indeterminate = true
	bar.show_percentage = false
	bar.show()
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var background := StyleBoxFlat.new()
	background.bg_color = Color("20466a")
	background.set_corner_radius_all(12)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("53ddfd")
	fill.set_corner_radius_all(12)
	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", fill)
	var brand := StyleBoxFlat.new()
	brand.bg_color = Color(0.025, 0.145, 0.36, 0.90)
	brand.border_color = Color("53ddfd")
	brand.set_border_width_all(2)
	brand.set_corner_radius_all(19)
	($Layer/TopBar as Panel).add_theme_stylebox_override("panel", brand)
	var glass := StyleBoxFlat.new()
	glass.bg_color = Color(0.012, 0.09, 0.22, 0.90)
	glass.border_color = Color(0.32, 0.87, 1, 0.78)
	glass.set_border_width_all(2)
	glass.set_corner_radius_all(22)
	($Layer/BottomPanel as Panel).add_theme_stylebox_override("panel", glass)


func _layout() -> void:
	if not is_inside_tree():
		return
	$Layer.visible = MobileRuntime.safe_area_is_ready()
	var size: Vector2 = get_viewport().get_visible_rect().size
	if size.x < 1 or size.y < 1:
		return
	var physical := Vector2(get_window().size)
	var dp := physical / MobileRuntime.get_ui_density()
	var scale_factor := maxf(size.x / dp.x, size.y / dp.y)
	var insets := MobileRuntime.get_safe_area_insets() if OS.has_feature("android") or MobileRuntime.requires_safe_area_observation() else Rect2()
	var safe_origin := insets.position * size / physical
	var safe_size := size - (insets.position + insets.size) * size / physical
	var compact: bool = dp.y < 410
	var margin: float = clampf(minf(dp.x, dp.y) * 0.035, 12.0, 32.0) * scale_factor
	var header_height: float = (56.0 if compact else 85.0) * scale_factor
	var top: Panel = $Layer/TopBar
	top.position = safe_origin + Vector2(margin, margin)
	top.size = Vector2(safe_size.x - margin * 2.0, header_height)
	var title: Label = $Layer/Title
	title.add_theme_font_size_override("font_size", roundi((24 if compact else 34) * scale_factor))
	title.position = top.position + Vector2(18, 3 if compact else 7) * scale_factor
	title.size = Vector2(top.size.x - 36 * scale_factor, (40 if compact else 48) * scale_factor)
	var subtitle: Label = $Layer/Subtitle
	subtitle.visible = not compact
	subtitle.add_theme_font_size_override("font_size", roundi(13 * scale_factor))
	subtitle.position = top.position + Vector2(18, 51) * scale_factor
	subtitle.size = Vector2(top.size.x - 36 * scale_factor, 25 * scale_factor)
	var failed: bool = load_phase == "error"
	var panel_height: float = (164.0 if failed else (82.0 if compact else 116.0)) * scale_factor
	var bottom: Panel = $Layer/BottomPanel
	var panel_width := minf(safe_size.x - margin * 2.0, 680 * scale_factor)
	bottom.position = safe_origin + Vector2((safe_size.x - panel_width) * 0.5, safe_size.y - margin - panel_height)
	bottom.size = Vector2(panel_width, panel_height)
	var label: Label = $Layer/LoadingLabel
	label.add_theme_font_size_override("font_size", roundi((17 if compact or dp.x < 520 else 23) * scale_factor))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.position = bottom.position + Vector2(16, 9 if compact else 16) * scale_factor
	label.size = Vector2(bottom.size.x - 32 * scale_factor, (74 if failed else 40) * scale_factor)
	var bar: ProgressBar = $Layer/LoadBar
	bar.position = bottom.position + Vector2(24, 56 if compact else 78) * scale_factor
	bar.size = Vector2(bottom.size.x - 48 * scale_factor, 12 * scale_factor)
	if is_instance_valid(_retry_row):
		_retry_row.position = bottom.position + Vector2(12, 98) * scale_factor
		_retry_row.size = Vector2(bottom.size.x - 24 * scale_factor, 48 * scale_factor)
		_retry_row.add_theme_constant_override("separation", roundi(12 * scale_factor))
		for button in [_retry_button, _back_button]:
			button.custom_minimum_size = Vector2(120, 48) * scale_factor
			button.add_theme_font_size_override("font_size", roundi((14 if dp.x < 520 else 17) * scale_factor))
	if is_instance_valid(_logo):
		var kart_cover: bool = target_scene == "kart" or (target_scene.is_empty() and title.text == "LUMO KART")
		_logo.visible = kart_cover
		top.visible = not kart_cover
		title.visible = not kart_cover
		subtitle.visible = not kart_cover and not compact
		_logo.size = Vector2(114, 65) * scale_factor if compact else Vector2(244, 140) * scale_factor
		_logo.position = safe_origin + Vector2((safe_size.x - _logo.size.x) * 0.5, margin)
		if is_instance_valid(_hero_box):
			var top_edge := _logo.position.y + _logo.size.y + 6 * scale_factor
			_hero_box.position = Vector2(safe_origin.x + margin, top_edge)
			_hero_box.size = Vector2(safe_size.x - margin * 2, maxf(48 * scale_factor, bottom.position.y - top_edge - 8 * scale_factor))
			var portrait_stage: bool = _hero_box.size.x < _hero_box.size.y
			_hero_camera.keep_aspect = Camera3D.KEEP_WIDTH if portrait_stage else Camera3D.KEEP_HEIGHT
			_hero_camera.fov = 46.0 if portrait_stage else 37.0


func _exit_tree() -> void:
	if MobileRuntime.safe_area_changed.is_connected(_layout):
		MobileRuntime.safe_area_changed.disconnect(_layout)
	if get_viewport().size_changed.is_connected(_layout):
		get_viewport().size_changed.disconnect(_layout)
