extends Node3D
## The production Android route for the current Flutter lesson. Objects use
## real meshes and spatial picking; tap is the equivalent accessible action.

const ACTIVITY = preload("res://scripts/learning/learning_activity.gd")
const FOX = preload("res://scripts/characters/lumo/lumo_rigged_actor.gd")
const ATELIER = preload("res://scripts/learning/learning_atelier.gd")
const WISPS = preload("res://scripts/creative/treasure_wisps.gd")
const ENGLISH_GALLERY = preload("res://scripts/learning/english_object_gallery.gd")
const BEVEL = preload("res://scripts/games/visual/kart_harbor_cinema.gd")
const PART_LABELS := {"root": "Wurzel", "stem": "Stängel", "leaf": "Blatt", "flower": "Blüte"}
const PART_HELP := {
	"root": "Die Wurzel hält die Pflanze fest. Sie nimmt Wasser aus dem Boden auf.",
	"stem": "Der Stängel trägt die Blätter und die Blüte. Durch ihn gelangt Wasser nach oben.",
	"leaf": "Die Blätter nutzen Licht, Wasser und Luft, um Nahrung für die Pflanze herzustellen.",
	"flower":
	"Die Blüte ist für die Fortpflanzung wichtig. Aus vielen Blüten entstehen Früchte mit Samen.",
}

var activity = ACTIVITY.new()
var camera: Camera3D
var fox: Node3D
var wonder: Node3D
var tokens: Array[Node3D] = []
var targets: Array[Vector3] = []
var token_sources: Array[Vector3] = []
var content: Node3D
var plant: Node3D
var part_nodes: Dictionary = {}
var water_particles: Array[MeshInstance3D] = []
var sun: MeshInstance3D
var title: Label
var explanation: Label
var status: Label
var actions: HFlowContainer
var main_button: Button
var sun_button: Button
var water_button: Button
var header: PanelContainer
var footer: PanelContainer
var ui: Control
var capture_options: Dictionary = {}
var reduced_motion := false
var active_drag := -1
var drag_finger := -1
var drag_start := Vector2.ZERO
var drag_moved := false
var suspended := false
var _clock := 0.0
var _growth := 0.62
var _moving: Dictionary = {}
var _tweens: Array[Tween] = []
var _original_auto_quit := true
var _original_back_quit := true
var _original_scale_mode: Window.ContentScaleMode
var _materials: Dictionary = {}
var _box_meshes: Dictionary = {}
var _bevel_mesh: ArrayMesh
var _arrangement_set := false
var _portrait := false
var _source_tray: MeshInstance3D
var _source_label: MeshInstance3D
var _fraction_label: MeshInstance3D
var _hundred_stock: Node3D
var _hundred_summary: MeshInstance3D
var _frame_label: MeshInstance3D
var _group_labels: Array[MeshInstance3D] = []
var _group_plates: Array[MeshInstance3D] = []
var _layout_queued := false
var _speech_host: Object
var _speech_enabled := false
var _auto_read := false
var _speech_id := 0
var _speech_poll := 0.0
var _speech_wait := -1.0
var _speech_state := "idle"
var _speech_text := ""
var voice_button: Button
var english_models: Array[Node3D] = []
var english_buttons: Array[Button] = []
var english_stage_rect := Rect2()
var _atelier: Node3D
var _english_compact := false

# App-private observation only. This file never supplies inputs or persistence.
const LEARNING_OBSERVATION := "user://learning_layout_v1.json"
var _learning_launch: Dictionary = {}
var _observation_pending := false
var _observation_closed := false
var _observation_settle_frames := 0
var _observation_sequence := 0
var _observation_retry_after := 0


func _ready() -> void:
	DirAccess.remove_absolute(LEARNING_OBSERVATION)
	DirAccess.remove_absolute(LEARNING_OBSERVATION + ".tmp")
	_original_auto_quit = get_tree().auto_accept_quit
	_original_back_quit = get_tree().quit_on_go_back
	_original_scale_mode = get_window().content_scale_mode
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	get_tree().auto_accept_quit = false
	get_tree().quit_on_go_back = false
	var options: Dictionary = (
		capture_options if not capture_options.is_empty() else SceneRouter.launch_options
	)
	reduced_motion = bool(options.get("reduceAnimations", false))
	_speech_enabled = (
		options.get("learningVoiceEnabled", false) == true
		and options.get("localVoiceLicenseAccepted", false) == true
	)
	_auto_read = options.get("learningAutoRead", false) == true
	if Engine.has_singleton("LumoHost"):
		_speech_host = Engine.get_singleton("LumoHost")
	var raw: Variant = options.get("learning", {})
	if not raw is Dictionary:
		raw = {}
	activity.configure(raw)
	_learning_launch = _observed_launch(options)
	HostBridge.returned.connect(_observation_returned)
	_build_stage()
	_build_ui()
	_rebuild_activity()
	get_viewport().size_changed.connect(_layout)
	MobileRuntime.safe_area_changed.connect(_layout)
	_layout()
	_refresh()
	_teacher("welcome", Vector3(0, 1, 1.5))
	_queue_narration()


func _material(key: String, color: Color, metallic: float = 0.0) -> StandardMaterial3D:
	if _materials.has(key):
		return _materials[key]
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.62 if metallic > 0.0 else 0.82
	material.metallic = metallic
	material.metallic_specular = 0.25
	_materials[key] = material
	return material


func _mesh(
	parent: Node3D, mesh: Mesh, at: Vector3, material: Material, label: String = ""
) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material
	node.position = at
	if not label.is_empty():
		node.name = label
	parent.add_child(node)
	return node


func _box(
	parent: Node3D, at: Vector3, size: Vector3, material: Material, label: String = ""
) -> MeshInstance3D:
	if _bevel_mesh == null:
		_bevel_mesh = BEVEL._bevel_box(0.055)
	if not _box_meshes.has(size):
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		surface.append_from(_bevel_mesh, 0, Transform3D(Basis.from_scale(size), Vector3.ZERO))
		_box_meshes[size] = surface.commit()
	return _mesh(parent, _box_meshes[size], at, material, label)


func _sphere(
	parent: Node3D, at: Vector3, scale_value: Vector3, material: Material, label: String = ""
) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 16
	mesh.rings = 8
	var node := _mesh(parent, mesh, at, material, label)
	node.scale = scale_value
	return node


func _cylinder(
	parent: Node3D,
	at: Vector3,
	radius: float,
	height: float,
	material: Material,
	label: String = ""
) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 24
	return _mesh(parent, mesh, at, material, label)


func _text(
	parent: Node3D, words: String, at: Vector3, size_value: float, material: Material
) -> MeshInstance3D:
	var mesh := TextMesh.new()
	mesh.font = ThemeDB.fallback_font
	mesh.text = words
	mesh.font_size = 80
	mesh.pixel_size = size_value / 80.0
	mesh.depth = 0.045
	var readable := material.duplicate() as StandardMaterial3D
	readable.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	readable.metallic = 0.0
	var node := _mesh(parent, mesh, at, readable)
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return node


func _top_text(
	parent: Node3D, words: String, at: Vector3, size_value: float, material: Material
) -> MeshInstance3D:
	# A flat, extruded glyph stays completely above its supporting surface.
	# Tilting around TextMesh's baseline cut the lower glyphs into the blocks.
	var node := _text(parent, words, at, size_value, material)
	node.rotation.x = -PI * 0.5
	var bounds: AABB = node.transform * node.get_aabb()
	node.position.y += maxf(0.0, at.y - bounds.position.y)
	return node


func _build_stage() -> void:
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("a6bdc4")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("e7e6d9")
	settings.ambient_light_energy = 0.24
	settings.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	settings.tonemap_white = 6.0
	settings.fog_density = 0.0
	settings.volumetric_fog_density = 0.0
	environment.environment = settings
	add_child(environment)
	var key := DirectionalLight3D.new()
	key.name = "LearningSunlight"
	key.rotation_degrees = Vector3(-60, -25, 0)
	key.light_color = Color("fff2db")
	key.light_energy = 0.34
	key.light_specular = 0.22
	key.shadow_enabled = true
	key.directional_shadow_max_distance = 30
	add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-30, 150, 0)
	fill.light_color = Color("c1d5df")
	fill.light_energy = 0.09
	fill.light_specular = 0.0
	add_child(fill)
	_atelier = ATELIER.new()
	add_child(_atelier)
	fox = FOX.new()
	fox.name = "OriginalLearningLumo"
	add_child(fox)
	fox.position = Vector3(-4.6, 0.05, -0.4)
	if fox.is_usable():
		var skeleton: Skeleton3D = fox.skeleton
		var low := INF
		var high := -INF
		for bone in range(skeleton.get_bone_count()):
			var y: float = skeleton.get_bone_global_rest(bone).origin.y
			low = minf(low, y)
			high = maxf(high, y)
		var fitted := 3.1 / maxf(0.2, high - low)
		fox.scale = Vector3.ONE * fitted
		fox.position.y = -low * fitted + 0.03
		fox.rotation.y = 0.3
		fox.set_reduced_motion(reduced_motion)
		_soften_teacher_materials()
	else:
		fox.hide()
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.current = true
	camera.near = 0.1
	camera.far = 60
	add_child(camera)
	camera.position = Vector3(0.0, 14.0, 11.0)
	camera.look_at(Vector3(0.0, 0.7, 0.0))
	wonder = WISPS.new()
	wonder.name = "LearningWonder"
	wonder.celebration_only = true
	wonder.set_reduced_motion(reduced_motion)
	add_child(wonder)
	if activity.kind == "english_objects":
		# Keep every existing atelier mesh behind the fitted object gallery.
		# Orthographic translation along view depth preserves its screen position.
		_atelier.position = -camera.global_basis.z * 24.0
		camera.far = 100.0


func _soften_teacher_materials() -> void:
	# Keep the original textures and rig. The atelier has its own quieter
	# instance finish; never mutate the shared Kart/character resources.
	for node in fox.visual.find_children("*", "MeshInstance3D", true, false):
		for surface in range(node.mesh.get_surface_count()):
			var original: Material = node.get_active_material(surface)
			if original is StandardMaterial3D:
				var material := original.duplicate() as StandardMaterial3D
				material.metallic = minf(material.metallic, 0.18)
				material.roughness = maxf(material.roughness, 0.82)
				material.metallic_specular = 0.22
				node.set_surface_override_material(surface, material)


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(ui)
	header = _panel()
	ui.add_child(header)
	header.resized.connect(_queue_layout)
	var heading := VBoxContainer.new()
	header.add_child(heading)
	title = Label.new()
	title.add_theme_font_size_override("font_size", 26)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	heading.add_child(title)
	explanation = Label.new()
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	explanation.add_theme_font_size_override("font_size", 19)
	heading.add_child(explanation)
	footer = _panel()
	ui.add_child(footer)
	footer.resized.connect(_queue_layout)
	var controls := VBoxContainer.new()
	footer.add_child(controls)
	status = Label.new()
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.add_theme_font_size_override("font_size", 17)
	controls.add_child(status)
	actions = HFlowContainer.new()
	actions.add_theme_constant_override("h_separation", 8)
	actions.add_theme_constant_override("v_separation", 8)
	controls.add_child(actions)


func _panel() -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("112e49")
	style.border_color = Color("70b6d2")
	style.set_border_width_all(1)
	style.set_corner_radius_all(16)
	style.set_content_margin_all(14)
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	return panel


func _button(caption: String, action: Callable, flags: int = 0) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(64, 52)
	button.add_theme_font_size_override("font_size", 17)
	var primary := (
		caption
		in [
			"Ein Objekt zeigen",
			"Einen Würfel wegnehmen",
			"Einen Würfel einordnen",
			"Einen Würfel verteilen",
			"Ein Teil zeigen",
			"Nächste Silbe zeigen",
			"Wasser geben",
			"Sonne öffnen"
		]
	)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("dca847") if primary else Color("294b5a")
	style.border_color = Color("f1d59c") if primary else Color("648390")
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(12)
	button.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate() as StyleBoxFlat
	hover.bg_color = style.bg_color.lightened(0.1)
	button.add_theme_stylebox_override("hover", hover)
	var pressed := style.duplicate() as StyleBoxFlat
	pressed.bg_color = style.bg_color.darkened(0.12)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_color_override("font_color", Color("1d3540") if primary else Color("f5ead5"))
	button.pressed.connect(action, flags)
	actions.add_child(button)
	return button


func _rebuild_activity() -> void:
	_cancel_drag()
	for tween in _tweens:
		if tween.is_valid():
			tween.kill()
	_tweens.clear()
	_moving.clear()
	if content != null:
		content.free()
	content = Node3D.new()
	content.name = "InteractiveLearningObjects"
	add_child(content)
	tokens.clear()
	targets.clear()
	token_sources.clear()
	part_nodes.clear()
	english_models.clear()
	english_buttons.clear()
	water_particles.clear()
	_arrangement_set = false
	_source_tray = null
	_source_label = null
	_fraction_label = null
	_hundred_stock = null
	_hundred_summary = null
	_frame_label = null
	_group_labels.clear()
	_group_plates.clear()
	plant = null
	for button in actions.get_children():
		button.free()
	main_button = null
	voice_button = null
	match activity.kind:
		"english_objects":
			_build_english_objects()
			main_button = _button("Hinweis", _english_hint)
		"bridge_ten", "addition", "bridge_hundred":
			_build_ten_frame()
			main_button = _button("Ein Objekt zeigen", _show_one)
		"subtract_ten":
			_build_subtraction()
			main_button = _button("Einen Würfel wegnehmen", _show_one)
		"equal_groups":
			_build_groups()
			main_button = _button("Einen Würfel einordnen", _show_one)
		"equal_sharing":
			_build_groups()
			main_button = _button("Einen Würfel verteilen", _show_one)
		"fraction_parts":
			_build_fractions()
			main_button = _button("Ein Teil zeigen", _show_one)
		"syllables":
			_build_syllables()
			main_button = _button("Nächste Silbe zeigen", _show_one)
		"plant_parts":
			_build_plant()
			water_button = _button("Wasser geben", _give_water)
			sun_button = _button("Sonne öffnen", _give_sun)
			for part in PART_LABELS:
				_button(str(PART_LABELS[part]), _inspect.bind(str(part)))
	# Rebuilding frees the old controls after their input signal has returned.
	_button("Neu" if activity.kind == "english_objects" else "Noch einmal", restart, CONNECT_DEFERRED)
	if (
		_speech_enabled
		and is_instance_valid(_speech_host)
		and _speech_host.has_method("speakLearning")
	):
		voice_button = _button("Schritt anhören", _voice_action)
	_button("Zur Aufgabe", _return_to_lesson)
	_layout.call_deferred()


func _slot(index: int) -> Vector3:
	var tray := index / 10
	var cell := index % 10
	return Vector3(
		-1.7 + float(cell % 5) * 0.85, 0.4, -2.1 + float(cell / 5) * 1.0 + float(tray) * 2.55
	)


func _build_ten_frame() -> void:
	title.text = "Zahlen zum Anfassen · %d + %d" % [activity.a, activity.b]
	var rim := _material("frame", Color("b1986b"), 0.06)
	var inset := _material("slot", Color("253f48"))
	var first := _material("blue", Color("3c91ad"), 0.05)
	var added := _material("gold", Color("d69b39"), 0.06)
	for tray in range(2):
		_box(content, Vector3(0, 0.03, -1.6 + tray * 2.55), Vector3(4.65, 0.18, 2.05), rim)
		for i in range(10):
			var at := _slot(tray * 10 + i)
			targets.append(at)
			_box(
				content,
				Vector3(at.x, 0.14, at.z),
				Vector3(0.7, 0.12, 0.74),
				inset,
				"TenFrameSlot%d" % (tray * 10 + i)
			)
	for i in range(activity.initial_count()):
		_box(content, _slot(i), Vector3(0.58, 0.36, 0.58), first, "InitialCube%d" % i)
	for i in range(activity.token_count()):
		var at := Vector3(3.05 + float(i % 2) * 0.78, 0.3, -1.8 + float(i / 2) * 0.78)
		var cube := _box(content, at, Vector3(0.58, 0.36, 0.58), added, "MovableCube%d" % i)
		tokens.append(cube)
		token_sources.append(at)
	_source_tray = _box(
		content,
		Vector3(3.5, 0.03, 0),
		Vector3(1.9, 0.18, 4.1),
		_material("source_tray", Color("75563a")),
		"SourceTray"
	)
	_frame_label = _top_text(
		content, "10", Vector3(0, 0.25, -2.8), 0.43, _material("cream_ink", Color("f5e1ad"))
	)
	_source_label = _text(content, "+ %d" % activity.b, Vector3(3.4, 1.1, -2.6), 0.6, added)
	if activity.kind == "bridge_hundred":
		title.text = "Zehner bündeln · %d + %d" % [activity.a, activity.b]
		_build_hundred_stock(first, inset)
		for cube in content.find_children("InitialCube*", "MeshInstance3D", true, false) + tokens:
			_top_text(cube, "10", Vector3(0, 0.23, 0), 0.24, inset)


func _build_hundred_stock(material: Material, ink: Material) -> void:
	_hundred_stock = Node3D.new()
	_hundred_stock.name = "ExistingHundreds"
	content.add_child(_hundred_stock)
	var count: int = activity.a / 100
	for index in range(count):
		_box(
			_hundred_stock,
			Vector3(0, 0.15 + index * 0.17, 0),
			Vector3(1.7, 0.15, 1.7),
			material,
			"HundredBundle%d" % index
		)
	# Ten visible rods, each subdivided into ten units, form the top hundred.
	# This is one actual 100-cell mesh batch, not a same-sized anonymous ten.
	var cells := MultiMesh.new()
	cells.transform_format = MultiMesh.TRANSFORM_3D
	cells.mesh = _bevel_mesh
	cells.instance_count = 100
	var top := 0.15 + float(count - 1) * 0.17 + 0.10
	for index in range(100):
		cells.set_instance_transform(
			index,
			Transform3D(
				Basis.from_scale(Vector3(0.148, 0.045, 0.148)),
				Vector3(-0.72 + float(index % 10) * 0.16, top, -0.72 + float(index / 10) * 0.16)
			)
		)
	var grid := MultiMeshInstance3D.new()
	grid.name = "HundredUnitGrid"
	grid.multimesh = cells
	grid.material_override = _material("hundred_cells", Color("5d9a9f"))
	_hundred_stock.add_child(grid)
	_box(
		_hundred_stock,
		Vector3(0, top + 0.04, 0),
		Vector3(1.5, 0.04, 0.45),
		_material("hundred_tag", Color("e6d4a4"))
	)
	var caption := "100" if count == 1 else "%d × 100" % count
	var label := _top_text(_hundred_stock, caption, Vector3(0, top + 0.075, 0), 0.32, ink)
	label.name = "HundredStockValue"
	_hundred_summary = _text(
		content, "", Vector3(0, 0.72, 2.1), 0.34, _material("hundred_ink", Color("f5e1ad"))
	)
	_hundred_summary.name = "CurrentPlaceValue"
	# Keep the real extruded caption parallel to the viewing plane. An upright
	# sign and a deeper plate have different screen projections from above;
	# their lower glyphs otherwise fall onto the similarly colored tray rim.
	_hundred_summary.global_basis = camera.global_basis
	var caption_plate := MeshInstance3D.new()
	caption_plate.name = "CaptionPlate"
	caption_plate.mesh = BoxMesh.new()
	var plate_material := StandardMaterial3D.new()
	plate_material.albedo_color = Color("122f45")
	plate_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	caption_plate.material_override = plate_material
	caption_plate.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_hundred_summary.add_child(caption_plate)


func _build_subtraction() -> void:
	title.text = "Wegnehmen · %d − %d" % [activity.a, activity.b]
	var rim := _material("frame", Color("b1986b"), 0.06)
	var inset := _material("slot", Color("253f48"))
	var cube_material := _material("blue", Color("3c91ad"), 0.05)
	for tray in range(2):
		_box(content, Vector3(0, 0.03, -1.6 + tray * 2.55), Vector3(4.65, 0.18, 2.05), rim)
		for i in range(10):
			var at := _slot(tray * 10 + i)
			_box(content, Vector3(at.x, 0.14, at.z), Vector3(0.68, 0.12, 0.68), inset)
	for index in range(activity.a):
		var source := _slot(activity.a - 1 - index)
		var token := _box(
			content, source, Vector3(0.58, 0.36, 0.58), cube_material, "SubtractCube%d" % index
		)
		tokens.append(token)
		token_sources.append(source)
	for index in range(activity.b):
		targets.append(
			Vector3(
				3.0 + float(index % 3) * 0.62,
				0.3 + float(index / 9) * 0.5,
				-1.5 + float((index / 3) % 3) * 0.62
			)
		)
	_source_tray = _box(content, Vector3(3.6, 0.02, -0.9), Vector3(2.3, 0.15, 2.3), inset)
	_source_label = _text(content, "weg", Vector3(3.6, 1.0, -2.4), 0.65, rim)


func _build_groups() -> void:
	title.text = (
		"Gerecht teilen · %d : %d" % [activity.a, activity.b]
		if activity.kind == "equal_sharing"
		else "Gleiche Gruppen · %d × %d" % [activity.a, activity.b]
	)
	var plate := _material("group_plate", Color("b6ceb0"))
	var cube_material := _material("group_cube", Color("f8c25b"), 0.1)
	var ink := _material("group_ink", Color("193644"))
	for group in range(activity.group_count()):
		var center := Vector3(-1.8 + float(group % 3) * 1.8, 0.06, -1.6 + float(group / 3) * 2.15)
		_group_plates.append(_cylinder(content, center, 0.83, 0.15, plate, "GroupPlate%d" % group))
		_group_labels.append(_top_text(content, "0", center + Vector3(0, 0.15, 0.61), 0.25, ink))
		for item in range(activity.group_size()):
			var at := (
				center
				+ Vector3(-0.42 + float(item % 3) * 0.42, 0.28, -0.23 + float(item / 3) * 0.46)
			)
			targets.append(at)
	for i in range(activity.token_count()):
		var source := Vector3(
			3.7 + float(i % 3) * 0.38, 0.28 + float(i / 9) * 0.38, -1.0 + float((i / 3) % 3) * 0.4
		)
		var token := _box(content, source, Vector3.ONE * 0.33, cube_material, "GroupCube%d" % i)
		tokens.append(token)
		token_sources.append(source)


func _build_fractions() -> void:
	title.text = "Gleiche Bruchteile · %d/%d" % [activity.a + activity.extra, activity.b]
	var base := _material("fraction_base", Color("153b59"))
	var filled := _material("fraction_filled", Color("57bcdd"), 0.1)
	var adding := _material("fraction_added", Color("ffd361"), 0.12)
	var width_value: float = 5.4 / activity.b
	_box(content, Vector3(0.5, 0.04, -0.4), Vector3(5.6, 0.16, 2.25), base, "FractionWhole")
	for index in range(activity.b):
		var at := Vector3(-2.2 + width_value * (float(index) + 0.5), 0.27, -0.4)
		targets.append(at)
		_box(
			content,
			Vector3(at.x, 0.16, at.z),
			Vector3(width_value - 0.035, 0.12, 2.05),
			_material("fraction_empty", Color("6b8791")),
			"EqualPart%d" % index
		)
		if index < activity.initial_count():
			_box(content, at, Vector3(width_value - 0.04, 0.3, 2.0), filled)
	for index in range(activity.token_count()):
		var source := Vector3(-2.2 + width_value * (float(index) + 0.5), 0.35, 1.95)
		var token := _box(
			content,
			source,
			Vector3(width_value - 0.04, 0.3, 2.0),
			adding,
			"FractionPiece%d" % index
		)
		tokens.append(token)
		token_sources.append(source)
	_fraction_label = _text(
		content, "", Vector3(0.5, 0.7, -1.8), 0.6, _material("fraction_ink", Color("f5e1ad"))
	)
	_fraction_label.name = "CurrentFractionValue"


func _build_syllables() -> void:
	title.text = "Wörter bauen · " + activity.word
	var paper := _material("word_paper", Color("f2e6bf"))
	var ink := _material("word_ink", Color("153d62"))
	var colors: Array[Color] = [
		Color("58bedb"), Color("ffbd55"), Color("ad91dc"), Color("83c995"), Color("ed9a9b")
	]
	var spacing := minf(1.72, 7.4 / float(activity.syllables.size()))
	var start := -float(activity.syllables.size() - 1) * spacing * 0.5
	var word_size := minf(0.85, 7.0 / maxf(1.0, float(activity.word.length()) * 0.60))
	_text(content, activity.word, Vector3(0, 2.6, -1.3), word_size, paper)
	for i in range(activity.syllables.size()):
		var target := Vector3(start + float(i) * spacing, 0.35, -0.8)
		targets.append(target)
		_box(
			content,
			Vector3(target.x, 0.1, target.z),
			Vector3(spacing * 0.91, 0.2, 1.2),
			ink,
			"WordSlot%d" % i
		)
		var piece := Node3D.new()
		piece.name = "Syllable%d" % i
		content.add_child(piece)
		var at := Vector3(start + float(activity.syllables.size() - 1 - i) * spacing, 0.35, 1.4)
		piece.position = at
		_box(
			piece,
			Vector3.ZERO,
			Vector3(spacing * 0.84, 0.45, 0.95),
			_material("syllable%d" % i, colors[i], 0.06)
		)
		var letters := _top_text(
			piece,
			activity.syllables[i],
			Vector3(0, 0.26, 0.04),
			minf(0.66, spacing * 1.4 / float(activity.syllables[i].length())),
			ink
		)
		letters.name = "SyllableGlyphs"
		tokens.append(piece)
		token_sources.append(at)


func _branch(
	parent: Node3D, from: Vector3, to: Vector3, radius: float, material: Material
) -> MeshInstance3D:
	var branch := _cylinder(parent, (from + to) * 0.5, radius, from.distance_to(to), material)
	var direction := (to - from).normalized()
	branch.quaternion = Quaternion(Vector3.UP, direction)
	return branch


func _build_plant() -> void:
	title.text = "Pflanzen entdecken"
	_growth = 0.62
	var soil := _material("soil", Color("785c41"))
	var green := _material("stem", Color("4c8b48"))
	var leaves := _material("leaves", Color("78bd51"))
	var root_material := _material("roots", Color("e4bd88"))
	_cylinder(content, Vector3(0.8, 0.15, 0.15), 1.75, 0.3, soil)
	plant = Node3D.new()
	plant.name = "LivingPlant"
	plant.position = Vector3(0.8, 0.35, 0.15)
	content.add_child(plant)
	var roots := Node3D.new()
	roots.name = "Roots"
	content.add_child(roots)
	roots.position = Vector3(0.8, 0.32, 1.1)
	for i in range(7):
		var angle := float(i) * TAU / 7.0
		var end := Vector3(cos(angle) * 1.3, 0.015, 0.65 + sin(angle) * 0.42)
		_branch(roots, Vector3(0, 0.05, -0.9), end, 0.055, root_material)
	part_nodes["root"] = roots
	part_nodes["stem"] = _cylinder(plant, Vector3(0, 1.3, 0), 0.12, 2.6, green, "Stem")
	var leaf_group := Node3D.new()
	leaf_group.name = "Leaves"
	plant.add_child(leaf_group)
	for side in [-1, 1]:
		for i in range(2):
			var at := Vector3(side * 0.55, 0.8 + i * 0.85, 0.04)
			var leaf := _sphere(leaf_group, at, Vector3(1.1, 0.1, 0.5), leaves)
			leaf.rotation.z = side * 0.35
	part_nodes["leaf"] = leaf_group
	var flower := Node3D.new()
	flower.name = "Flower"
	flower.position.y = 2.7
	plant.add_child(flower)
	var pink := _material("petals", Color("ee9cb9"))
	for i in range(8):
		var angle := float(i) * TAU / 8.0
		_sphere(
			flower, Vector3(cos(angle) * 0.4, sin(angle) * 0.4, 0), Vector3(0.55, 0.55, 0.22), pink
		)
	_sphere(
		flower, Vector3(0, 0, 0.12), Vector3(0.47, 0.47, 0.24), _material("pollen", Color("ffd65d"))
	)
	part_nodes["flower"] = flower
	sun = _sphere(
		content,
		Vector3(3.6, 3.7, -1.5),
		Vector3.ONE * 1.05,
		_material("sun_closed", Color("8993a2")),
		"Sun"
	)
	for i in range(7):
		var drop := _sphere(
			content,
			Vector3.ZERO,
			Vector3.ONE * 0.12,
			_material("water", Color("5ac9ed"), 0.15),
			"WaterDrop%d" % i
		)
		drop.hide()
		water_particles.append(drop)
	plant.scale = Vector3.ONE * _growth


func _refresh() -> void:
	_mark_learning_observation()
	explanation.text = activity.explanation()
	for group in range(_group_labels.size()):
		_group_labels[group].mesh.text = str(activity.count_in_group(group))
		var next_group: int = (
			activity.placed.size() % activity.b
			if activity.kind == "equal_sharing"
			else activity.placed.size() / activity.b
		)
		_group_plates[group].material_override = _material(
			"group_next" if group == next_group and not activity.is_complete() else "group_plate",
			(
				Color("d7ae58")
				if group == next_group and not activity.is_complete()
				else Color("b6ceb0")
			)
		)
	if is_instance_valid(_fraction_label):
		_fraction_label.mesh.text = (
			"%d/%d" % [activity.initial_count() + activity.placed.size(), activity.b]
		)
	if is_instance_valid(_hundred_summary):
		var value: int = activity.a + activity.placed.size() * 10
		_hundred_summary.mesh.text = (
			"%d = %d Hunderter + %d Zehner" % [value, value / 100, (value % 100) / 10]
		)
		# The actual extruded text needs its own contrasting surface. Without it
		# the cream glyphs disappear against the ten-frame's cream lower rim.
		var caption_bounds: AABB = _hundred_summary.get_aabb()
		var caption_plate: MeshInstance3D = _hundred_summary.get_node("CaptionPlate")
		caption_plate.mesh.size = Vector3(
			caption_bounds.size.x + 0.22, caption_bounds.size.y + 0.14, 0.035
		)
		caption_plate.position = Vector3(
			caption_bounds.get_center().x,
			caption_bounds.get_center().y,
			caption_bounds.position.z - 0.045
		)
		_frame_label.mesh.text = (
			"10 Zehner = 100"
			if activity.initial_count() + activity.placed.size() >= 10
			else "Zehner sammeln"
		)
	if activity.kind == "invalid":
		title.text = "Lumo Lernwerkstatt"
		status.text = "Kehre zur Aufgabe zurück und öffne die Lernansicht erneut."
	elif activity.kind == "english_objects":
		status.text = ("%s = %s · Passend zugeordnet" % [activity.word, activity.english_meaning]
			if activity.is_complete() else "Tippe den Gegenstand oder seine Zahl an.")
		main_button.disabled = activity.is_complete() or activity.english_hint_level >= 2
		for index in range(english_models.size()):
			english_buttons[index].disabled = activity.is_complete()
			english_models[index].get_node("HintRing").visible = (
				activity.english_objects[index] == activity.word
				and (activity.english_hint_level >= 2 or activity.is_complete()))
	elif activity.kind == "plant_parts":
		title.text = "Pflanzen entdecken"
		status.text = "%d von 4 Pflanzenteilen entdeckt" % activity.inspected.size()
		water_button.disabled = activity.watered
		sun_button.disabled = activity.sunlight
	else:
		status.text = (
			"%d / %d bewegt · Ziehen oder antippen"
			% [activity.placed.size(), activity.goal_count()]
		)
		main_button.disabled = activity.is_complete() or not _moving.is_empty()
	if activity.is_complete() and activity.kind != "english_objects":
		status.text = "Geschafft! Zurück bei deiner Aufgabe kannst du es selbst versuchen."
	_layout.call_deferred()


func _queue_layout() -> void:
	if not is_inside_tree():
		return
	_mark_learning_observation()
	if not _layout_queued:
		_layout_queued = true
		_layout.call_deferred()


func _layout() -> void:
	_layout_queued = false
	if not is_inside_tree() or not is_instance_valid(camera) or not is_instance_valid(header):
		return
	_mark_learning_observation()
	var dimensions := get_viewport().get_visible_rect().size
	# Godot receives Android pixels; use the same density hint as the native
	# Kart controls. This keeps every action at least 48 device-independent px.
	var density: float = MobileRuntime.get_ui_density()
	var scale_value := minf(density, maxf(1.0, dimensions.x / 360.0))
	ui.scale = Vector2.ONE * scale_value
	var logical := dimensions / scale_value
	ui.visible = MobileRuntime.safe_area_is_ready()
	var insets := MobileRuntime.get_safe_area_insets() if OS.has_feature("android") or MobileRuntime.requires_safe_area_observation() else Rect2()
	var origin := insets.position / scale_value
	var available := logical - (insets.position + insets.size) / scale_value
	if activity.kind == "english_objects":
		_english_compact = available.x > available.y and available.y < 480.0
		# Keep the full hint text and its original readable font. On a short
		# landscape surface, reduce only empty panel padding so the actual
		# objects retain their readable size while the hint wraps to two lines.
		var header_style := header.get_theme_stylebox("panel") as StyleBoxFlat
		var vertical_margin := 8.0 if _english_compact else 14.0
		if header_style.content_margin_top != vertical_margin:
			header_style.content_margin_top = vertical_margin
			header_style.content_margin_bottom = vertical_margin
		# A short landscape window needs one row of full-sized actions, not a
		# two-row footer that reduces the real objects to tiny thumbnails.
		status.visible = not _english_compact
		for button: Button in actions.get_children():
			button.custom_minimum_size = Vector2(52, 52)
		_update_voice_button()
	header.position = origin + Vector2(12, 12)
	header.size.x = maxf(100, available.x - 24)
	header.size.y = header.get_combined_minimum_size().y
	footer.size.x = maxf(100, available.x - 24)
	footer.size.y = footer.get_combined_minimum_size().y
	footer.position = Vector2(
		origin.x + 12,
		maxf(header.position.y + header.size.y + 20, origin.y + available.y - footer.size.y - 12)
	)
	if activity.kind == "english_objects":
		_layout_english(dimensions, scale_value)
		return
	var portrait := dimensions.x / dimensions.y < 0.95
	if not _arrangement_set or portrait != _portrait:
		_arrange_activity(portrait)
	var free_height := maxf(
		80, (footer.position.y - header.position.y - header.size.y) * scale_value
	)
	var focus_height := 9.5 if portrait else 4.9
	if activity.kind == "fraction_parts":
		focus_height = maxf(focus_height, 5.8)
	var focus_width := 6.25 if portrait else 10.8
	if activity.kind == "syllables" and activity.syllables.size() > 3:
		focus_width = maxf(focus_width, 8.2)
	var needed_height := focus_height * dimensions.y / free_height
	camera.size = maxf(focus_width / maxf(0.2, dimensions.x / dimensions.y), needed_height)
	camera.h_offset = 0.0 if portrait else 0.1
	var content_mid := (header.position.y + header.size.y + footer.position.y) * 0.5 * scale_value
	camera.v_offset = (content_mid / dimensions.y - 0.5) * camera.size + (0.75 if portrait else 0.0)
	if (
		activity.kind == "bridge_hundred"
		and is_instance_valid(_frame_label)
		and _frame_label.is_inside_tree()
		and camera.is_inside_tree()
	):
		# Keep the full extruded equation readable: a lying '=' has almost no
		# projected gap between its bars. Cube-top labels keep their flat basis.
		_frame_label.global_basis = camera.global_basis


func _arrange_activity(portrait: bool) -> void:
	_portrait = portrait
	_arrangement_set = true
	_cancel_drag()
	for tween in _tweens:
		if tween.is_valid():
			tween.kill()
	_tweens.clear()
	_moving.clear()
	if is_instance_valid(fox):
		fox.position.x = -1.8 if portrait else -4.1
		fox.position.z = -3.8 if portrait else -0.1
		fox.rotation.y = 0.15 if portrait else 0.4
	if activity.kind in ["bridge_ten", "addition", "bridge_hundred"]:
		for index in range(tokens.size()):
			token_sources[index] = (
				Vector3(-1.7 + float(index % 5) * 0.85, 0.3, 3.1 + float(index / 5) * 1.0)
				if portrait
				else Vector3(3.05 + float(index % 2) * 0.78, 0.3, -1.8 + float(index / 2) * 0.78)
			)
		_source_tray.position = Vector3(0, 0.03, 3.55) if portrait else Vector3(3.5, 0.03, 0)
		_source_tray.scale = Vector3(4.65 / 1.9, 1, 1.85 / 4.1) if portrait else Vector3.ONE
		_source_label.position = Vector3(2.42, 0.7, 3.45) if portrait else Vector3(3.4, 0.9, -2.6)
		if activity.kind == "bridge_hundred":
			_hundred_stock.position = Vector3(1.35, 0, -3.85) if portrait else Vector3(-3.4, 0, 1.6)
			_hundred_summary.position = Vector3(0, 0.6, 2.25)
			_hundred_summary.global_basis = camera.global_basis
	elif activity.kind == "subtract_ten":
		for index in range(targets.size()):
			targets[index] = (
				Vector3(
					-1.7 + float(index % 5) * 0.85,
					0.3 + float(index / 10) * 0.42,
					3.1 + float((index / 5) % 2) * 1.0
				)
				if portrait
				else Vector3(
					3.0 + float(index % 3) * 0.62,
					0.3 + float(index / 9) * 0.5,
					-1.5 + float((index / 3) % 3) * 0.62
				)
			)
		_source_tray.position = Vector3(0, 0.02, 3.55) if portrait else Vector3(3.6, 0.02, -0.9)
		_source_tray.scale = Vector3(4.65 / 2.3, 1, 1.85 / 2.3) if portrait else Vector3.ONE
		_source_label.position = Vector3(2.45, 0.7, 3.45) if portrait else Vector3(3.6, 1.0, -2.4)
	elif activity.kind in ["equal_groups", "equal_sharing"]:
		for index in range(tokens.size()):
			token_sources[index] = (
				Vector3(-1.7 + float(index % 9) * 0.42, 0.28, 2.75 + float(index / 9) * 0.4)
				if portrait
				else Vector3(
					3.7 + float(index % 3) * 0.38,
					0.28 + float(index / 9) * 0.38,
					-1.0 + float((index / 3) % 3) * 0.4
				)
			)
	elif activity.kind == "fraction_parts":
		_fraction_label.position = Vector3(0.55, 0.7, -1.85)
	elif activity.kind == "plant_parts":
		sun.position.x = 2.45 if portrait else 3.6
	for index in range(tokens.size()):
		var placed_index: int = activity.placed.find(index)
		tokens[index].position = (
			targets[activity.target_for_step(placed_index)]
			if placed_index >= 0
			else token_sources[index]
		)
	if is_instance_valid(fox) and fox.is_usable():
		fox.set_teaching_target(Vector3(0, 0.5, 0))


func _input(event: InputEvent) -> void:
	# Continue an already-owned drag even when it crosses the HUD. New presses
	# are still picked only in unhandled input, so buttons retain priority.
	if active_drag < 0 or suspended:
		return
	if event is InputEventScreenDrag and event.index == drag_finger:
		_drag_to(event.position)
	elif event is InputEventScreenTouch and not event.pressed and event.index == drag_finger:
		_end_drag(event.position, event.canceled)
	elif event is InputEventMouse and event.device != -1 and drag_finger == -2:
		if event is InputEventMouseMotion:
			_drag_to(event.position)
		elif (
			event is InputEventMouseButton
			and event.button_index == MOUSE_BUTTON_LEFT
			and not event.pressed
		):
			_end_drag(event.position, false)


func _unhandled_input(event: InputEvent) -> void:
	if suspended or activity.kind == "invalid":
		return
	# Godot can also synthesize a mouse event from each touch. The real finger
	# owns the drag; its emulated mouse must not claim or release it a second time.
	if event is InputEventMouse and event.device == -1:
		return
	if event is InputEventScreenTouch:
		if event.pressed and active_drag < 0:
			_begin_drag(event.position, event.index)
		elif not event.pressed and event.index == drag_finger:
			_end_drag(event.position, event.canceled)
	elif event is InputEventScreenDrag and event.index == drag_finger:
		_drag_to(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and active_drag < 0:
			_begin_drag(event.position, -2)
		elif not event.pressed and drag_finger == -2:
			_end_drag(event.position, false)
	elif event is InputEventMouseMotion and drag_finger == -2:
		_drag_to(event.position)


func _begin_drag(point: Vector2, finger: int) -> void:
	if activity.kind == "english_objects":
		_pick_english_object(point)
		return
	if activity.kind == "plant_parts":
		var best := ""
		var distance := 60.0 * ui.scale.x
		for part in part_nodes:
			var at: Vector3 = _part_position(str(part))
			var projected := camera.unproject_position(at)
			var candidate := projected.distance_to(point)
			if candidate < distance:
				distance = candidate
				best = str(part)
		if not best.is_empty():
			_inspect(best)
		return
	var closest := 44.0 * ui.scale.x
	for i in range(tokens.size()):
		if activity.placed.has(i) or _moving.has(i):
			continue
		var distance := camera.unproject_position(tokens[i].global_position).distance_to(point)
		if distance < closest:
			closest = distance
			active_drag = i
	if active_drag < 0:
		return
	drag_finger = finger
	drag_start = point
	drag_moved = false
	_stop_speech()
	_teacher("explain", tokens[active_drag].global_position)
	get_viewport().set_input_as_handled()


func _drag_to(point: Vector2) -> void:
	if active_drag < 0:
		return
	drag_moved = drag_moved or point.distance_to(drag_start) > 10.0 * ui.scale.x
	var plane := Plane(Vector3.UP, 0.55)
	var hit: Variant = plane.intersects_ray(
		camera.project_ray_origin(point), camera.project_ray_normal(point)
	)
	if hit is Vector3:
		tokens[active_drag].position = Vector3(
			clampf(hit.x, -2.4, 5.0), 0.55, clampf(hit.z, -3.0, 3.7)
		)
		if fox != null and fox.is_usable():
			fox.set_teaching_target(tokens[active_drag].global_position)
	get_viewport().set_input_as_handled()


func _end_drag(point: Vector2, canceled: bool) -> void:
	if active_drag < 0:
		return
	var selected := active_drag
	var target: int = activity.target_index()
	var within_target := not drag_moved
	if target < targets.size():
		within_target = (
			within_target
			or camera.unproject_position(targets[target]).distance_to(point) <= 55.0 * ui.scale.x
		)
	active_drag = -1
	drag_finger = -1
	if canceled or not within_target or not move_token(selected):
		_animate_token(selected, token_sources[selected])
		if not canceled:
			_teacher("encourage", token_sources[selected])
		if not canceled and activity.kind == "syllables":
			explanation.text = activity.explanation()
		_queue_narration()
	get_viewport().set_input_as_handled()


func move_token(index: int) -> bool:
	if suspended or not _moving.is_empty():
		return false
	var destination: int = activity.target_index()
	if not activity.place(index, destination):
		_teacher("encourage", Vector3(0, 1, 0))
		return false
	print(
		(
			"[LearningWorld] move kind=%s token=%d target=%d placed=%d complete=%s"
			% [activity.kind, index, destination, activity.placed.size(), activity.is_complete()]
		)
	)
	_animate_token(index, targets[destination])
	_teacher("celebrate" if activity.is_complete() else "correct", targets[destination])
	wonder.celebrate(targets[destination] + Vector3.UP * 0.65)
	_refresh()
	_queue_narration()
	return true


func _animate_token(index: int, destination: Vector3) -> void:
	if index < 0 or index >= tokens.size():
		return
	if reduced_motion:
		tokens[index].position = destination
		return
	_moving[index] = true
	var tween := create_tween()
	_tweens.append(tween)
	var middle := (tokens[index].position + destination) * 0.5 + Vector3.UP * 0.5
	(
		tween
		. tween_property(tokens[index], "position", middle, 0.18)
		. set_trans(Tween.TRANS_QUAD)
		. set_ease(Tween.EASE_OUT)
	)
	(
		tween
		. tween_property(tokens[index], "position", destination, 0.2)
		. set_trans(Tween.TRANS_QUAD)
		. set_ease(Tween.EASE_IN)
	)
	tween.finished.connect(
		func():
			_moving.erase(index)
			_tweens.erase(tween)
			_refresh()
	)


func _show_one() -> void:
	if activity.is_complete():
		return
	for index in range(tokens.size()):
		if not activity.placed.has(index):
			move_token(index)
			return


func _part_position(part: String) -> Vector3:
	if part == "root":
		return Vector3(0.8, 0.35, 1.7)
	if part == "leaf":
		return plant.to_global(Vector3(0.7, 1.65, 0.0))
	return part_nodes[part].global_position


func _inspect(part: String) -> void:
	if suspended or not activity.inspect_part(part):
		return
	_refresh()
	title.text = "Pflanzen entdecken · " + str(PART_LABELS[part])
	explanation.text = str(PART_HELP[part])
	_teacher("explain", _part_position(part))
	wonder.celebrate(_part_position(part) + Vector3.UP * 0.38)
	_queue_narration()


func _give_water() -> void:
	if suspended or activity.kind != "plant_parts" or activity.watered:
		return
	activity.watered = true
	_refresh()
	explanation.text = "Wasser gelangt über die Wurzeln in den Stängel und zu den Blättern."
	_teacher("explain", _part_position("root"))
	wonder.celebrate(_part_position("root") + Vector3.UP * 0.38)
	_queue_narration()


func _give_sun() -> void:
	if suspended or activity.kind != "plant_parts" or activity.sunlight:
		return
	activity.sunlight = true
	sun.material_override = _material("sun_open", Color("ffcf65"), 0.06)
	_refresh()
	_teacher("explain", sun.global_position)
	wonder.celebrate(sun.global_position)
	_queue_narration()


func restart() -> void:
	if suspended:
		return
	_stop_speech()
	activity.reset()
	_rebuild_activity()
	_refresh()
	_teacher("explain", Vector3(0, 1, 0))
	_queue_narration()


func _process(delta: float) -> void:
	_publish_learning_observation()
	if suspended:
		return
	_clock += delta
	_tick_speech(delta)
	if plant != null:
		var desired := 1.0 if activity.watered and activity.sunlight else 0.62
		_growth = desired if reduced_motion else move_toward(_growth, desired, delta * 0.12)
		plant.scale = Vector3.ONE * _growth
		for i in range(water_particles.size()):
			var drop := water_particles[i]
			drop.visible = activity.watered
			if drop.visible:
				var phase := 0.5 if reduced_motion else fmod(_clock * 0.3 + float(i) / 7.0, 1.0)
				drop.position = Vector3(0.8, 0.4 + phase * 2.1 * _growth, 0.27)


func _cancel_drag() -> void:
	if active_drag >= 0 and active_drag < tokens.size() and is_instance_valid(tokens[active_drag]):
		tokens[active_drag].position = token_sources[active_drag]
	active_drag = -1
	drag_finger = -1


func _return_to_lesson() -> void:
	_stop_speech()
	_cancel_drag()
	if HostBridge.is_embedded():
		if not HostBridge.return_to_app("learn", {"status": "illustrated", "game": "learning"}):
			explanation.text = HostBridge.SAVE_FAILURE
	else:
		SceneRouter.goto("learn")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_return_to_lesson()
	elif what in [NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT]:
		suspended = true
		if is_instance_valid(wonder):
			wonder.set_paused(true)
		_mark_learning_observation()
		_stop_speech()
		_cancel_drag()
		for tween in _tweens:
			if tween.is_valid():
				tween.pause()
		if fox != null:
			fox.set_suspended(true)
	elif what in [NOTIFICATION_APPLICATION_RESUMED, NOTIFICATION_APPLICATION_FOCUS_IN]:
		suspended = false
		if is_instance_valid(wonder):
			wonder.set_paused(false)
		_mark_learning_observation()
		for tween in _tweens:
			if tween.is_valid():
				tween.play()
		if fox != null:
			fox.set_suspended(false)


func _exit_tree() -> void:
	_observation_closed = true
	_observation_pending = false
	if HostBridge.returned.is_connected(_observation_returned):
		HostBridge.returned.disconnect(_observation_returned)
	DirAccess.remove_absolute(LEARNING_OBSERVATION)
	DirAccess.remove_absolute(LEARNING_OBSERVATION + ".tmp")
	if MobileRuntime.safe_area_changed.is_connected(_layout):
		MobileRuntime.safe_area_changed.disconnect(_layout)
	if get_viewport().size_changed.is_connected(_layout):
		get_viewport().size_changed.disconnect(_layout)
	_stop_speech()
	get_tree().auto_accept_quit = _original_auto_quit
	get_tree().quit_on_go_back = _original_back_quit
	get_window().content_scale_mode = _original_scale_mode


func _teacher(reaction: String, at: Vector3) -> void:
	if fox != null and fox.is_usable():
		fox.set_teaching_target(at)
		fox.teacher_react(reaction)


func _queue_narration() -> void:
	_stop_speech()
	if _speech_enabled and _auto_read and not suspended:
		_speech_text = explanation.text
		_speech_wait = 0.55


func _voice_action() -> void:
	if suspended:
		return
	if _speech_state in ["preparing", "playing"] or _speech_wait >= 0:
		_stop_speech()
	else:
		_speak(explanation.text)


func _speak(words: String) -> void:
	if not _speech_enabled or suspended or not is_instance_valid(_speech_host):
		return
	_stop_speech()
	# Read the actual displayed quantities. No unrelated prerecorded answer.
	var spoken := (
		words
		. replace(" + ", " plus ")
		. replace(" = ", " ist ")
		. replace("/", " von ")
		. replace("×", "mal")
	)
	if spoken.is_empty() or spoken.length() > 220:
		return
	_speech_id += 1
	var accepted: Variant = _speech_host.call(
		"speakLearning",
		JSON.stringify(
			{
				"id": _speech_id,
				"text": spoken,
				"style": "celebrate" if activity.is_complete() else "explain"
			}
		)
	)
	_speech_state = "preparing" if HostBridge.durable_ack(accepted) else "unavailable"
	_update_voice_button()


func _stop_speech() -> void:
	_speech_wait = -1.0
	_speech_id += 1
	_speech_state = "idle"
	if is_instance_valid(_speech_host) and _speech_host.has_method("stopLearningSpeech"):
		_speech_host.call("stopLearningSpeech")
	if is_instance_valid(fox) and fox.is_usable():
		fox.set_teacher_speaking(false)
		fox.apply_speech_sample(0.0, 0.0, false)
	_update_voice_button()


func _tick_speech(delta: float) -> void:
	if _speech_wait >= 0:
		_speech_wait -= delta
		if _speech_wait <= 0:
			if not _moving.is_empty() or active_drag >= 0:
				_speech_wait = 0.1
			else:
				_speak(_speech_text)
	if not is_instance_valid(_speech_host) or not _speech_enabled:
		return
	_speech_poll += delta
	if _speech_poll < 0.05:
		return
	_speech_poll = 0.0
	if not _speech_host.has_method("getLearningSpeechStatus"):
		return
	var received: Variant = JSON.parse_string(str(_speech_host.call("getLearningSpeechStatus")))
	if not received is Dictionary or int(received.get("id", -1)) != _speech_id:
		return
	var received_state := str(received.get("state", "idle"))
	if received_state not in ["preparing", "playing", "completed", "unavailable", "idle"]:
		return
	_speech_state = received_state
	# Amplitude comes from the exact synthesized WAV and MediaPlayer position.
	# Preparing, mute, missing envelope and stopped playback remain closed.
	if is_instance_valid(fox) and fox.is_usable():
		var audible: bool = _speech_state == "playing" and received.get("audible", false) == true
		fox.set_teacher_speaking(audible)
		fox.apply_speech_sample(
			float(received.get("positionMs", 0.0)) / 1000.0,
			float(received.get("envelope", 0.0)),
			audible and received.get("envelopeAvailable", false) == true
		)
	_update_voice_button()


func _update_voice_button() -> void:
	if not is_instance_valid(voice_button):
		return
	var previous_caption := voice_button.text
	if activity.kind == "english_objects" and _english_compact:
		voice_button.text = "Stopp" if _speech_state in ["preparing", "playing"] else "Anhören"
	else:
		voice_button.text = (
			"Stimme stoppen" if _speech_state in ["preparing", "playing"] else "Schritt anhören"
		)
	voice_button.tooltip_text = (
		"Die lokale Stimme ist gerade nicht verfügbar. Der Lernschritt bleibt lesbar."
		if _speech_state == "unavailable"
		else ""
	)

	if voice_button.text != previous_caption:
		_mark_learning_observation()


func _build_english_objects() -> void:
	title.text = "Englisch · " + activity.word
	for index in range(activity.english_objects.size()):
		var model: Node3D = ENGLISH_GALLERY.make(activity.english_objects[index], index)
		content.add_child(model)
		english_models.append(model)
		var button := _button(str(index + 1), _choose_english.bind(index))
		button.name = "EnglishChoice%d" % (index + 1)
		button.tooltip_text = "Gegenstand %d auswählen" % (index + 1)
		english_buttons.append(button)


func _english_projected_bounds(node: Node3D) -> Rect2:
	var result := Rect2()
	var found := false
	for item: Node in node.find_children("*", "MeshInstance3D", true, false):
		var mesh := item as MeshInstance3D
		if mesh.mesh == null or not mesh.is_visible_in_tree():
			continue
		var box := mesh.get_aabb()
		for corner in range(8):
			var point := camera.unproject_position(mesh.to_global(box.get_endpoint(corner)))
			result = result.expand(point) if found else Rect2(point, Vector2.ZERO)
			found = true
	return result


func _layout_english(dimensions: Vector2, scale_value: float) -> void:
	if english_models.size() != 3 or dimensions.y <= 0.0:
		return
	var portrait := dimensions.x < dimensions.y * 0.95
	_portrait = portrait
	_arrangement_set = true
	camera.size = 12.0
	camera.h_offset = 0.0
	camera.v_offset = 0.0
	fox.position.x = -2.15 if portrait else -4.2
	fox.position.z = -0.6 if portrait else 0.2
	fox.rotation.y = 0.10 if portrait else 0.35
	for index in range(english_models.size()):
		english_models[index].position = (
			Vector3(1.25, 0, -2.8 + index * 2.8)
			if portrait else Vector3(-1.15 + index * 2.55, 0, 0.15))
		var number := english_models[index].get_node("ChoiceNumber") as MeshInstance3D
		number.global_basis = camera.global_basis
	if portrait:
		# Stack the actual projected geometry, including its number and base.
		# Different objects have different heights; a fixed depth gap can let
		# a tall pen cover the ruler or book behind it.
		var pixels_per_depth := (
			camera.unproject_position(Vector3.FORWARD * -1.0).y
			- camera.unproject_position(Vector3.ZERO).y)
		if pixels_per_depth > 0.001:
			for index in range(1, english_models.size()):
				var previous := _english_projected_bounds(english_models[index - 1])
				var current := _english_projected_bounds(english_models[index])
				var missing := previous.end.y + pixels_per_depth * 0.35 - current.position.y
				if missing > 0.0:
					english_models[index].position.z += missing / pixels_per_depth
	var top: float = header.get_global_rect().end.y + 8.0 * scale_value
	var bottom: float = footer.get_global_rect().position.y - 8.0 * scale_value
	var left: float = header.get_global_rect().position.x + 4.0 * scale_value
	english_stage_rect = Rect2(left, top, header.get_global_rect().size.x - 8.0 * scale_value, maxf(1.0, bottom - top))
	var bounds := _english_projected_bounds(content)
	var fox_bounds := _english_projected_bounds(fox)
	if fox_bounds.has_area():
		bounds = bounds.merge(fox_bounds)
	if bounds.size.x < 1.0 or bounds.size.y < 1.0:
		return
	var fitting := minf(english_stage_rect.size.x / bounds.size.x, english_stage_rect.size.y / bounds.size.y) * 0.94
	camera.size /= maxf(0.001, fitting)
	bounds = _english_projected_bounds(content)
	if fox_bounds.has_area():
		bounds = bounds.merge(_english_projected_bounds(fox))
	var shift := english_stage_rect.get_center() - bounds.get_center()
	var pixels_per_unit := dimensions.y / camera.size
	camera.h_offset = -shift.x / pixels_per_unit
	camera.v_offset = shift.y / pixels_per_unit
	if fox.is_usable():
		fox.set_teaching_target(english_models[activity.english_objects.find(activity.word)].global_position + Vector3.UP)


func english_pick_rect(index: int) -> Rect2:
	# Only offer a spatial target when a real 48dp square fits inside both
	# its projected collision volume and the unobscured current scene area.
	# Numbered 52dp buttons remain the equivalent action in tighter layouts.
	if index < 0 or index >= english_models.size() or not camera.is_inside_tree():
		return Rect2()
	var collision := english_models[index].get_node("ObjectTouchBody/CollisionShape3D") as CollisionShape3D
	var shape := collision.shape as BoxShape3D
	var box := AABB(-shape.size * 0.5, shape.size)
	var points := PackedVector2Array()
	for corner in range(8):
		points.append(camera.unproject_position(collision.to_global(box.get_endpoint(corner))))
	var hull := Geometry2D.convex_hull(points)
	var center := camera.unproject_position(collision.global_position)
	var edge: float = 48.0 * MobileRuntime.get_ui_density()
	var target := Rect2(center - Vector2.ONE * edge * 0.5, Vector2.ONE * edge)
	if not english_stage_rect.encloses(target):
		return Rect2()
	for corner in [target.position, Vector2(target.end.x, target.position.y), target.end, Vector2(target.position.x, target.end.y)]:
		if not Geometry2D.is_point_in_polygon(corner, hull):
			return Rect2()
	return target


func _pick_english_object(point: Vector2) -> void:
	if suspended or activity.is_complete():
		return
	var origin := camera.project_ray_origin(point)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + camera.project_ray_normal(point) * 60.0, 8)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty() or not hit.collider.has_meta("english_choice"):
		return
	var index: int = int(hit.collider.get_meta("english_choice"))
	if not english_pick_rect(index).has_area():
		return
	_choose_english(index)
	get_viewport().set_input_as_handled()


func _choose_english(index: int) -> void:
	if suspended or activity.kind != "english_objects" or activity.is_complete():
		return
	if index < 0 or index >= english_models.size():
		return
	_stop_speech()
	var matched: bool = activity.choose_english(index)
	_teacher("correct" if matched else "encourage", english_models[index].global_position + Vector3.UP)
	_refresh()
	_queue_narration()
	print("[LearningEnglish] choice=", index, " attempts=", activity.english_attempts, " complete=", activity.is_complete())


func _english_hint() -> void:
	if suspended or not activity.english_hint():
		return
	_stop_speech()
	_teacher("explain", english_models[activity.english_objects.find(activity.word)].global_position + Vector3.UP)
	_refresh()
	_queue_narration()


func _observed_launch(options: Dictionary) -> Dictionary:
	# Only the closed task catalogue and pseudonymous route identity are copied.
	# Child names, typed answers, free-form text and audio never enter this file.
	var session := str(options.get("sessionId", ""))
	var child := str(options.get("childKey", ""))
	var uuid := RegEx.create_from_string("^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$")
	var owner := RegEx.create_from_string("^p_[a-f0-9]{32}$")
	return {
		"scene": str(options.get("scene", options.get("game", ""))),
		"subject": "Englisch" if options.get("subject") == "Englisch" else "",
		"grade": int(options.get("grade", 0)),
		"sessionId": session if uuid.search(session) != null else "",
		"childKey": child if owner.search(child) != null else "",
		"learningVoiceEnabled": options.get("learningVoiceEnabled", false) == true,
		"localVoiceLicenseAccepted": options.get("localVoiceLicenseAccepted", false) == true,
		"learningAutoRead": options.get("learningAutoRead", false) == true,
		"learning": {
			"kind": activity.kind, "word": activity.word,
			"meaning": activity.english_meaning,
			"objects": activity.english_objects.duplicate(),
		} if activity.kind == "english_objects" else {},
	}


func _observation_returned(_destination: String, _payload: Dictionary) -> void:
	_observation_closed = true
	_observation_pending = false
	DirAccess.remove_absolute(LEARNING_OBSERVATION)
	DirAccess.remove_absolute(LEARNING_OBSERVATION + ".tmp")


func _mark_learning_observation() -> void:
	if _observation_closed or activity.kind != "english_objects":
		return
	if not _observation_pending:
		DirAccess.remove_absolute(LEARNING_OBSERVATION)
	_observation_pending = true
	_observation_settle_frames = 2


func _observation_vector(value: Vector2) -> Array:
	return [value.x, value.y]


func _observation_vector3(value: Vector3) -> Array:
	return [value.x, value.y, value.z]


func _observation_rect(value: Rect2) -> Array:
	return [value.position.x, value.position.y, value.size.x, value.size.y]


func _observation_control(button: Button, identifier: String, factor: Vector2) -> Dictionary:
	var rect := button.get_global_rect()
	var hit := rect.intersection(get_viewport().get_visible_rect())
	var parent := button.get_parent()
	while parent != null:
		if parent is Control and parent.clip_contents:
			hit = hit.intersection(parent.get_global_rect())
		parent = parent.get_parent()
	return {
		"id": identifier, "text": button.text,
		"visible": button.is_visible_in_tree(), "enabled": not button.disabled and not suspended,
		"rect_px": _observation_rect(Rect2(rect.position * factor, rect.size * factor)),
		"hit_rect_px": _observation_rect(Rect2(hit.position * factor, hit.size * factor)),
	}


func _publish_learning_observation() -> void:
	if not _observation_pending or _observation_closed or not is_inside_tree():
		return
	if not is_instance_valid(ui) or not ui.is_visible_in_tree() or not MobileRuntime.safe_area_is_ready():
		return
	if _layout_queued or _observation_settle_frames > 0:
		_observation_settle_frames = maxi(0, _observation_settle_frames - 1)
		return
	if Time.get_ticks_msec() < _observation_retry_after:
		return
	var viewport := get_viewport().get_visible_rect().size
	var factor := Vector2(get_window().size) / viewport
	var measured := MobileRuntime.get_safe_area_observation()
	var android := {}
	for key in ["view_size", "decor_size"]:
		if measured.has(key):
			android[key] = _observation_vector(measured[key])
	for key in ["render_rect", "system_insets", "insets"]:
		if measured.has(key):
			android[key] = _observation_rect(measured[key])
	var observation_source := "platform_safe_area"
	if not measured.is_empty():
		observation_source = "android_window_insets" if OS.has_feature("android") else "platform_fixture"
	var controls := []
	for index in range(english_buttons.size()):
		controls.append(_observation_control(english_buttons[index], "choice_%d" % index, factor))
	for button: Button in actions.get_children():
		if button in english_buttons:
			continue
		var identifier := "hint" if button == main_button else "voice" if button == voice_button else "restart" if button.text == "Neu" else "return"
		controls.append(_observation_control(button, identifier, factor))
	var objects := []
	for index in range(english_models.size()):
		var entry := ENGLISH_GALLERY.observe_geometry(english_models[index], camera, factor)
		var pick := english_pick_rect(index)
		entry["pick_rect_px"] = _observation_rect(Rect2(pick.position * factor, pick.size * factor))
		objects.append(entry)
	var projection := camera.get_camera_projection()
	var columns := []
	for column in range(4):
		var value: Vector4 = projection[column]
		columns.append([value.x, value.y, value.z, value.w])
	var view := camera.get_camera_transform().affine_inverse()
	var insets := MobileRuntime.get_safe_area_insets() if not measured.is_empty() else Rect2()
	var safe := Rect2(insets.position, viewport - insets.position - insets.size)
	_observation_sequence += 1
	var snapshot := {
		"schema": 1, "layout_sequence": int(_observation_sequence),
		"ticks_msec": int(Time.get_ticks_msec()), "pid": int(OS.get_process_id()),
		"settled": true, "ui_visible": true, "observation_source": observation_source,
		"launch": _learning_launch.duplicate(true),
		"selection": int(activity.english_choice), "hint_level": int(activity.english_hint_level),
		"attempts": int(activity.english_attempts), "complete": activity.is_complete(),
		"suspended": suspended, "voice_available": is_instance_valid(voice_button),
		"window_px": _observation_vector(Vector2(get_window().size)),
		"viewport_px": _observation_vector(viewport), "density": MobileRuntime.get_ui_density(),
		"android_observation": android,
		"safe_rect_px": _observation_rect(Rect2(safe.position * factor, safe.size * factor)),
		"stage_rect_px": _observation_rect(Rect2(english_stage_rect.position * factor, english_stage_rect.size * factor)),
		"header_rect_px": _observation_rect(Rect2(header.get_global_position() * factor, header.size * ui.scale * factor)),
		"footer_rect_px": _observation_rect(Rect2(footer.get_global_position() * factor, footer.size * ui.scale * factor)),
		"title": title.text, "explanation": explanation.text, "status": status.text,
		"controls": controls, "objects": objects,
		"camera": {"projection_columns": columns,
			"view_basis_columns": [_observation_vector3(view.basis.x), _observation_vector3(view.basis.y), _observation_vector3(view.basis.z)],
			"view_origin": _observation_vector3(view.origin)},
	}
	var file := FileAccess.open(LEARNING_OBSERVATION + ".tmp", FileAccess.WRITE)
	if file == null:
		_observation_retry_after = Time.get_ticks_msec() + 2000
		return
	file.store_string(JSON.stringify(snapshot))
	file.flush()
	var error := file.get_error()
	file.close()
	if error == OK:
		error = DirAccess.rename_absolute(LEARNING_OBSERVATION + ".tmp", LEARNING_OBSERVATION)
	if error == OK:
		_observation_pending = false
	else:
		_observation_retry_after = Time.get_ticks_msec() + 2000
