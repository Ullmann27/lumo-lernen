extends Node3D
## Native spatial surface of the existing Dart Cards engine. No duplicate rules.
signal action_requested(request: Dictionary)

const SEATED = preload("res://scripts/games/cards/cards_table_actor.gd")
const ACTOR = preload("res://scripts/characters/lumo/lumo_rigged_actor.gd")
const LAYOUT_OBSERVATION := "user://cards_layout_v1.json"
const COLORS := {
	"orange": Color("e64e48"),
	"purple": Color("efd34b"),
	"blue": Color("3297ed"),
	"green": Color("58b877")
}
const COLOR_NAMES := {"orange": "Rot", "purple": "Gelb", "blue": "Blau", "green": "Grün"}
var camera: Camera3D
var actor: Node3D
var hand_root: Node3D
var opponent_root: Node3D
var discard_root: Node3D
var ui: Control
var heading: Label
var message: Label
var status: Label
var footer: VBoxContainer
var pages: HBoxContainer
var compact_bar: HBoxContainer
var header: PanelContainer
var seated
var _compact := false
var actions: HBoxContainer
var modal: PanelContainer
var modal_content: VBoxContainer
var modal_scroll: ScrollContainer
var page_label: Label
var play_button: Button
var draw_button: Button
var pause_button: Button
var call_button: Button
var _host: Object
var _token := ""
var _state: Dictionary = {}
var _cards: Dictionary = {}
var _selected := ""
var _sequence := 0
var _pending := 0
var _poll_time := 0.0
var _page := 0
var _page_size := 7
var _elapsed := 0.0
var _focus := 0.0
var _materials: Dictionary = {}
var _textures: Dictionary = {}
var _closed := false
var _ui_scale := 1.0
var _android_safe_area_enabled := false
var _android_safe_area: Dictionary = {}
var _layout_observation_pending := false
var _layout_settle_frames := 0
var _layout_sequence := 0
var _layout_retry_after := 0
var _hand_targets: Dictionary = {}
var room_batches: Array[MultiMeshInstance3D] = []
var room_source_boxes := 0
var _wood_detail_mask: GradientTexture1D


func _ready() -> void:
	get_window().content_scale_size = Vector2i.ZERO
	_android_safe_area_enabled = MobileRuntime.requires_safe_area_observation()
	if Engine.has_singleton("LumoHost"):
		_host = Engine.get_singleton("LumoHost")
	_token = str(HostBridge.launch_options().get("cardsToken", ""))
	_build_room()
	_build_interface()
	get_viewport().size_changed.connect(_resize)
	MobileRuntime.safe_area_changed.connect(_resize)
	_resize()
	_poll()


func _material(
	key: String, color: Color, roughness: float = 0.55, metal: float = 0.0
) -> StandardMaterial3D:
	if _materials.has(key):
		return _materials[key]
	var mat := StandardMaterial3D.new()
	mat.resource_name = key
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = metal
	_materials[key] = mat
	return mat


func _box(parent: Node3D, at: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.material_override = mat
	instance.position = at
	parent.add_child(instance)
	return instance


func _cylinder(
	parent: Node3D, at: Vector3, radius: float, height: float, mat: Material
) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 48
	instance.mesh = mesh
	instance.material_override = mat
	instance.position = at
	parent.add_child(instance)
	return instance


func _wood(key: String, tint: Color, roughness: float = 0.82) -> StandardMaterial3D:
	var mat := _material(key, tint, roughness)
	# Keep the original grain as a quiet detail over matte walnut. Multiplying
	# the entire base by this high-contrast source obscured the cards in review.
	if _wood_detail_mask == null:
		var mask := Gradient.new()
		mask.set_color(0, Color(0.16, 0.16, 0.16, 1.0))
		mask.set_color(1, Color(0.16, 0.16, 0.16, 1.0))
		_wood_detail_mask = GradientTexture1D.new()
		_wood_detail_mask.width = 2
		_wood_detail_mask.gradient = mask
	mat.detail_enabled = true
	mat.detail_albedo = preload(
		"res://assets/generated/lumo3d_assets/textures/albedo/wood_warm_soft_albedo.png"
	)
	mat.detail_blend_mode = BaseMaterial3D.BLEND_MODE_MUL
	mat.detail_mask = _wood_detail_mask
	mat.normal_enabled = true
	mat.normal_texture = preload(
		"res://assets/generated/lumo3d_assets/textures/normal/wood_warm_soft_normal.png"
	)
	mat.normal_scale = 0.06
	mat.uv1_triplanar = true
	mat.uv1_scale = Vector3.ONE * (0.65 if key.begins_with("floor") else 2.7)
	return mat


func _batch_room_boxes() -> void:
	# Only direct, static room boxes at this construction boundary are batched.
	# The rig and all playable cards retain their separate geometry and shadows.
	var groups: Dictionary = {}
	for child in get_children():
		if child is MeshInstance3D and child.mesh is BoxMesh and child.material_override != null:
			var key := (
				"%d/%d/%d"
				% [child.material_override.get_instance_id(), child.cast_shadow, child.layers]
			)
			if not groups.has(key):
				groups[key] = []
			groups[key].append(child)
	var unit_box := BoxMesh.new()
	unit_box.size = Vector3.ONE
	for entries: Array in groups.values():
		var first: MeshInstance3D = entries[0]
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.mesh = unit_box
		multimesh.instance_count = entries.size()
		var batch := MultiMeshInstance3D.new()
		batch.name = "RoomBatch_" + first.material_override.resource_name
		batch.multimesh = multimesh
		batch.material_override = first.material_override
		batch.cast_shadow = first.cast_shadow
		batch.layers = first.layers
		for i in range(entries.size()):
			var source: MeshInstance3D = entries[i]
			var fitted := source.transform
			fitted.basis = fitted.basis * Basis.from_scale(source.mesh.size)
			multimesh.set_instance_transform(i, fitted)
			remove_child(source)
			source.free()
		add_child(batch)
		room_batches.append(batch)
		room_source_boxes += entries.size()


func _ring(
	parent: Node3D, at: Vector3, radius: float, width: float, mat: Material
) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius - width
	mesh.outer_radius = radius + width
	mesh.rings = 64
	mesh.ring_segments = 8
	node.mesh = mesh
	node.material_override = mat
	node.position = at
	parent.add_child(node)
	return node


func _beveled_table(mat: Material) -> void:
	var profile: Array[Vector2] = [
		Vector2(2.48, 0.87),
		Vector2(2.64, 0.90),
		Vector2(2.74, 0.98),
		Vector2(2.74, 1.04),
		Vector2(2.65, 1.12),
		Vector2(2.48, 1.12)
	]
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in range(profile.size() - 1):
		for segment in range(64):
			var points: Array[Vector3] = []
			for corner in [
				Vector2i(row, segment),
				Vector2i(row, segment + 1),
				Vector2i(row + 1, segment + 1),
				Vector2i(row + 1, segment)
			]:
				var angle := float(corner.y) * TAU / 64.0
				points.append(
					Vector3(
						cos(angle) * profile[corner.x].x,
						profile[corner.x].y,
						sin(angle) * profile[corner.x].x * 1.04
					)
				)
			for vertex in [0, 2, 1, 0, 3, 2]:
				surface.set_uv(Vector2(float(segment) / 8.0, float(row) / profile.size()))
				surface.add_vertex(points[vertex])
	surface.generate_normals()
	var node := MeshInstance3D.new()
	node.name = "RoundedWalnutTableRim"
	node.mesh = surface.commit()
	node.material_override = mat
	add_child(node)


func _window(x: float, frame: Material, trim: Material) -> void:
	var sky := _material("night_sky", Color("173440"), 1.0)
	_box(self, Vector3(x, 2.7, -4.94), Vector3(1.8, 2.25, 0.1), sky)
	var moon := _material("moon", Color("e1c992"), 0.9)
	moon.emission_enabled = true
	moon.emission = Color("8d784b")
	moon.emission_energy_multiplier = 0.16
	var sphere := MeshInstance3D.new()
	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radius = 0.21
	sphere_mesh.height = 0.42
	sphere_mesh.radial_segments = 20
	sphere_mesh.rings = 10
	sphere.mesh = sphere_mesh
	sphere.material_override = moon
	sphere.position = Vector3(x + 0.37, 3.2, -4.77)
	add_child(sphere)
	for side in [-1, 1]:
		_box(self, Vector3(x + side * 0.9, 2.7, -4.38), Vector3(0.16, 2.35, 0.42), frame)
	for y in [1.56, 3.85]:
		_box(self, Vector3(x, y, -4.35), Vector3(1.98, 0.14, 0.5), frame)
	_box(self, Vector3(x, 1.5, -4.20), Vector3(2.15, 0.1, 0.7), trim)
	for offset in [-0.45, 0.45]:
		_box(self, Vector3(x + offset, 2.66, -4.18), Vector3(0.035, 2.13, 0.045), frame)
	_box(self, Vector3(x, 2.58, -4.18), Vector3(1.8, 0.045, 0.045), frame)
	# Shaped geometry beyond the window gives real depth rather than a picture.
	for i in range(4):
		var tree := MeshInstance3D.new()
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = 0.24
		cone.height = 0.8 + i * 0.1
		cone.radial_segments = 10
		tree.mesh = cone
		tree.material_override = _material("night_trees", Color("172922"), 0.95)
		tree.position = Vector3(x - 0.65 + 0.42 * i, 1.9, -4.66)
		add_child(tree)


func _build_room() -> void:
	var walnut := _wood("walnut", Color("6a5646"), 0.8)
	var dark_wood := _wood("dark_wood", Color("493c32"), 0.86)
	var brass := _material("aged_brass", Color("b59359"), 0.4, 0.68)
	var felt := _material("green_felt", Color("164c3c"), 0.98)
	felt.normal_enabled = true
	felt.normal_texture = preload(
		"res://assets/generated/lumo3d_assets/textures/normal/velvet_blue_3d_normal.png"
	)
	felt.normal_scale = 0.22
	felt.uv1_scale = Vector3(5, 5, 5)
	felt.uv1_triplanar = true
	var plaster := _material("plaster", Color("31423b"), 0.95)
	_box(self, Vector3(0, -0.12, 0), Vector3(16, 0.2, 18), dark_wood)
	for plank in range(20):
		_box(
			self,
			Vector3(-6.2 + plank * 0.65, 0.0, 1),
			Vector3(0.64, 0.035, 12),
			_wood(
				"floor%d" % (plank % 3),
				[Color("766553"), Color("6c5c4c"), Color("7b6957")][plank % 3],
				0.87
			)
		)
	_box(self, Vector3(0, 2.7, -4.45), Vector3(4.25, 2.4, 0.28), plaster)
	_box(self, Vector3(0, 4.6, -4.45), Vector3(11, 1.65, 0.28), plaster)
	for side in [-1, 1]:
		_box(self, Vector3(side * 5.0, 2.7, -4.45), Vector3(1.65, 2.4, 0.28), plaster)
		_box(self, Vector3(side * 5.65, 2.7, 0), Vector3(0.25, 5.4, 10), plaster)
		_window(side * 3.15, dark_wood, walnut)
	_box(self, Vector3(0, 0.73, -4.32), Vector3(11.2, 1.46, 0.3), dark_wood)
	for panel in range(9):
		_box(self, Vector3(-4.8 + panel * 1.2, 0.76, -4.13), Vector3(1.02, 1.02, 0.08), walnut)
		_box(self, Vector3(-4.8 + panel * 1.2, 0.76, -4.075), Vector3(0.86, 0.86, 0.035), dark_wood)
	for y in [0.12, 1.43]:
		_box(self, Vector3(0, y, -4.06), Vector3(11.2, 0.09, 0.13), walnut)
	for side in [-1, 1]:
		var x := float(side) * 4.35
		_box(self, Vector3(x, 1.15, -3.85), Vector3(1.35, 2.3, 0.54), dark_wood)
		for shelf in range(3):
			_box(self, Vector3(x, 0.35 + shelf * 0.7, -3.50), Vector3(1.43, 0.09, 0.82), walnut)
			for book in range(5):
				var color: Color = [
					Color("77443b"), Color("345665"), Color("8c7445"), Color("365c49")
				][(shelf + book) % 4]
				var height := 0.41 + (book % 3) * 0.04
				_box(
					self,
					Vector3(x - 0.5 + book * 0.24, 0.4 + shelf * 0.7 + height * 0.5, -3.55),
					Vector3(0.17, height, 0.4),
					_material("cloth_book%d" % ((shelf + book) % 4), color, 0.86)
				)
				_box(
					self,
					Vector3(x - 0.5 + book * 0.24, 0.49 + shelf * 0.7, -3.342),
					Vector3(0.15, 0.018, 0.012),
					brass
				)
	var rug := _material("woven_rug", Color("283e45"), 1.0)
	_cylinder(self, Vector3(0, 0.032, 0), 3.2, 0.018, rug).scale.z = 1.07
	_ring(self, Vector3(0, 0.045, 0), 3.09, 0.025, _material("rug_stitch", Color("806d50"), 1.0)).scale.z = 1.07
	_beveled_table(walnut)
	_cylinder(self, Vector3(0, 1.105, 0), 2.49, 0.026, felt).scale.z = 1.04
	_ring(self, Vector3(0, 1.125, 0), 2.51, 0.017, brass).scale.z = 1.04
	_cylinder(self, Vector3(0, 0.48, 0), 0.44, 0.86, dark_wood)
	_cylinder(self, Vector3(0, 0.13, 0), 0.65, 0.16, walnut)
	for side in [-1, 1]:
		for z in [-1.65, 1.65]:
			_box(self, Vector3(side * 1.55, 0.47, z), Vector3(0.20, 0.86, 0.20), dark_wood)
			_cylinder(self, Vector3(side * 1.55, 0.12, z), 0.14, 0.12, brass)
	# The authored pelvis is fitted to the chair, not positioned on the tabletop.
	var chair_z := -2.73
	_box(self, Vector3(0, 0.63, chair_z), Vector3(1.45, 0.18, 1.1), walnut)
	_box(self, Vector3(0, 0.75, chair_z), Vector3(1.28, 0.12, 0.98), felt)
	_box(self, Vector3(0, 1.43, chair_z - 0.53), Vector3(1.52, 1.7, 0.16), walnut)
	_box(self, Vector3(0, 1.44, chair_z - 0.43), Vector3(1.25, 1.4, 0.12), felt)
	for side in [-1, 1]:
		_box(self, Vector3(side * 0.64, 0.34, chair_z), Vector3(0.12, 0.65, 0.12), dark_wood)
	actor = ACTOR.new()
	actor.name = "OriginalLumo"
	actor.scale = Vector3.ONE * 1.65
	add_child(actor)
	seated = SEATED.new()
	seated.bind(actor, Vector3(0, 0.85, chair_z))
	var emblem := MeshInstance3D.new()
	var text_mesh := TextMesh.new()
	text_mesh.text = "LUMO"
	text_mesh.font_size = 48
	text_mesh.pixel_size = 0.012
	text_mesh.depth = 0.003
	emblem.mesh = text_mesh
	emblem.material_override = _material("inlay", Color("a08c60"), 0.8, 0.2)
	emblem.position = Vector3(0, 1.125, 1.25)
	emblem.rotation.x = -PI * 0.5
	add_child(emblem)
	var env := WorldEnvironment.new()
	var resource := Environment.new()
	resource.background_mode = Environment.BG_COLOR
	resource.background_color = Color("101c23")
	resource.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	resource.ambient_light_color = Color("b4c4bb")
	resource.ambient_light_energy = 0.28
	resource.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = resource
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -32, 0)
	sun.light_color = Color("ffe2b4")
	sun.light_energy = 0.72
	sun.shadow_enabled = true
	add_child(sun)
	var rim := OmniLight3D.new()
	rim.position = Vector3(0, 3.5, -2.8)
	rim.light_color = Color("a4bed6")
	rim.light_energy = 0.45
	rim.omni_range = 6.5
	add_child(rim)
	for side in [-1, 1]:
		_box(self, Vector3(side * 1.7, 2.65, -4.11), Vector3(0.16, 0.52, 0.18), brass)
		var shade := _cylinder(
			self,
			Vector3(side * 1.7, 2.85, -3.94),
			0.23,
			0.3,
			_material("linen", Color("cab58c"), 0.94)
		)
		shade.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var lamp := OmniLight3D.new()
		lamp.position = Vector3(side * 1.7, 2.6, -3.7)
		lamp.light_color = Color("ffc783")
		lamp.light_energy = 0.34
		lamp.omni_range = 4.2
		add_child(lamp)
	_batch_room_boxes()
	camera = Camera3D.new()
	camera.fov = 46
	camera.near = 0.1
	camera.far = 35
	camera.current = true
	add_child(camera)
	hand_root = Node3D.new()
	hand_root.name = "PlayerCards"
	add_child(hand_root)
	opponent_root = Node3D.new()
	opponent_root.name = "OpponentCards"
	add_child(opponent_root)
	discard_root = Node3D.new()
	discard_root.name = "Discard"
	add_child(discard_root)
	for i in range(6):
		_make_card(self, {}, Vector3(-0.62, 1.14 + i * 0.027, -0.23), false)


func _button(label: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(52, 52)
	button.set_meta("base_width", 52.0)
	button.pressed.connect(callback)
	return button


func _build_interface() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(ui)
	header = PanelContainer.new()
	header.name = "Header"
	header.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	ui.add_child(header)
	var header_style := StyleBoxFlat.new()
	header_style.bg_color = Color(0.025, 0.065, 0.085, 0.86)
	header_style.set_corner_radius_all(14)
	header_style.content_margin_left = 8
	header_style.content_margin_right = 8
	header_style.content_margin_top = 5
	header_style.content_margin_bottom = 7
	header.add_theme_stylebox_override("panel", header_style)
	var top := VBoxContainer.new()
	top.name = "Top"
	header.add_child(top)
	var nav := HBoxContainer.new()
	top.add_child(nav)
	var back := _button("Zurück", _leave)
	back.name = "Back"
	nav.add_child(back)
	heading = Label.new()
	heading.text = "Lumos Kartenstube"
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.clip_text = true
	heading.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	nav.add_child(heading)
	pause_button = _button(
		"Pause", func(): _send("resume" if bool(_state.get("paused", false)) else "pause")
	)
	nav.add_child(pause_button)
	status = Label.new()
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(status)
	message = Label.new()
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	top.add_child(message)
	footer = VBoxContainer.new()
	footer.name = "Footer"
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer.offset_left = 16
	footer.offset_right = -16
	footer.offset_top = -128
	footer.offset_bottom = -12
	ui.add_child(footer)
	compact_bar = HBoxContainer.new()
	compact_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_child(compact_bar)
	compact_bar.hide()
	pages = HBoxContainer.new()
	pages.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_child(pages)
	pages.add_child(_button("‹", func(): _change_page(-1)))
	page_label = Label.new()
	page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page_label.custom_minimum_size.x = 40
	pages.add_child(page_label)
	pages.add_child(_button("›", func(): _change_page(1)))
	actions = HBoxContainer.new()
	actions.name = "Actions"
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_child(actions)
	play_button = _button(
		"Karte legen",
		func():
			if not _selected.is_empty():
				_send("play", {"cardId": _selected})
	)
	actions.add_child(play_button)
	draw_button = _button("Ziehen", func(): _send("draw"))
	actions.add_child(draw_button)
	call_button = _button("LUMO! +1", func(): _send("call"))
	call_button.hide()
	actions.add_child(call_button)
	modal = PanelContainer.new()
	modal.name = "Decision"
	modal.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	modal_scroll = ScrollContainer.new()
	modal_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	modal.add_child(modal_scroll)
	modal_content = VBoxContainer.new()
	modal_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	modal_content.add_theme_constant_override("separation", 10)
	modal_scroll.add_child(modal_content)
	ui.add_child(modal)
	modal.hide()
	var theme := Theme.new()
	theme.default_font_size = 18
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("123455")
	normal.border_color = Color("67bdcf")
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(12)
	normal.content_margin_left = 14
	normal.content_margin_right = 14
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8
	theme.set_stylebox("normal", "Button", normal)
	var focus := normal.duplicate() as StyleBoxFlat
	focus.bg_color = Color("31647e")
	theme.set_stylebox("hover", "Button", focus)
	theme.set_stylebox("pressed", "Button", focus)
	theme.set_stylebox("focus", "Button", focus)
	var panel := normal.duplicate() as StyleBoxFlat
	panel.bg_color = Color("0d233e")
	panel.content_margin_left = 20
	panel.content_margin_right = 20
	panel.content_margin_top = 18
	panel.content_margin_bottom = 18
	theme.set_stylebox("panel", "PanelContainer", panel)
	ui.theme = theme


func _resize() -> void:
	if not is_inside_tree() or not is_instance_valid(camera) or not is_instance_valid(ui):
		return
	_mark_layout_changed()
	_android_safe_area = _get_safe_area_observation()
	var viewport_size := get_viewport().get_visible_rect().size
	var pixels := Vector2(get_window().size)
	var factor := viewport_size / pixels if pixels.x > 0 and pixels.y > 0 else Vector2.ONE
	var insets := _safe_area_insets()
	ui.offset_left = insets.position.x * factor.x
	ui.offset_top = insets.position.y * factor.y
	ui.offset_right = -insets.size.x * factor.x
	ui.offset_bottom = -insets.size.y * factor.y
	# Do not expose system-bar-covered controls while the first Android View
	# measurement (or a newly rotated View) is still being attached.
	ui.visible = not _android_safe_area_enabled or _android_safe_area.get("window_size") == get_window().size
	var size := ui.size
	_ui_scale = MobileRuntime.get_ui_density()
	# UI canvas pixels are native pixels; all touch targets retain at least 48 dp.
	for button in ui.find_children("*", "Button", true, false):
		button.custom_minimum_size = (
			Vector2(float(button.get_meta("base_width", 52.0)), 52.0) * _ui_scale
		)
		button.add_theme_font_size_override("font_size", int(18 * _ui_scale))
	for label in [heading, status, message, page_label]:
		label.add_theme_font_size_override("font_size", int(18 * _ui_scale))
	var width_dp := size.x / _ui_scale
	_compact = size.y / _ui_scale < 520 and size.x > size.y
	if _compact and pages.get_parent() != compact_bar:
		pages.reparent(compact_bar)
		actions.reparent(compact_bar)
	elif not _compact and pages.get_parent() != footer:
		pages.reparent(footer)
		actions.reparent(footer)
	compact_bar.visible = _compact
	status.visible = not _compact
	header.offset_left = 12 * _ui_scale
	header.offset_right = -12 * _ui_scale
	header.offset_top = 8 * _ui_scale
	message.add_theme_font_size_override("font_size", int((14 if _compact else 16) * _ui_scale))
	_page_size = 7 if width_dp > 850 else (5 if width_dp > 550 else 3)
	footer.offset_top = -(64 if _compact else 128) * _ui_scale
	footer.offset_bottom = -12 * _ui_scale
	modal.offset_left = -minf(size.x * 0.45, 280 * _ui_scale)
	modal.offset_right = minf(size.x * 0.45, 280 * _ui_scale)
	modal.offset_top = -minf(size.y * 0.28, 200 * _ui_scale)
	modal.offset_bottom = minf(size.y * 0.28, 200 * _ui_scale)
	_update_camera()
	if not _state.is_empty():
		_render_hand()
	_layout_modal()


func _safe_area_insets() -> Rect2:
	if _android_safe_area.get("window_size") == get_window().size:
		var observed: Rect2 = _android_safe_area.insets
		var scale: Vector2 = Vector2(get_window().size) / _android_safe_area.view_size
		return Rect2(observed.position * scale, observed.size * scale)
	var insets := Rect2()
	if OS.has_feature("mobile"):
		insets = MobileRuntime.get_safe_area_insets()
		var screen := DisplayServer.screen_get_size()
		var safe := DisplayServer.get_display_safe_area()
		if not MobileRuntime.requires_safe_area_observation() and screen.x > 0 and screen.y > 0 and safe.has_area():
			insets.position.x = maxf(insets.position.x, safe.position.x)
			insets.position.y = maxf(insets.position.y, safe.position.y)
			insets.size.x = maxf(insets.size.x, screen.x - safe.end.x)
			insets.size.y = maxf(insets.size.y, screen.y - safe.end.y)
	return insets


func _get_safe_area_observation() -> Dictionary:
	return MobileRuntime.get_safe_area_observation()


func _update_camera() -> void:
	var size := get_viewport().get_visible_rect().size
	var aspect := size.x / maxf(1, size.y)
	var distance_scale := maxf(1.0, 0.72 / aspect)
	camera.position = Vector3(_focus * 0.12, 5.3 * distance_scale, 7.0 * distance_scale)
	camera.look_at(Vector3(0, 1.05, -0.25))


func _process(delta: float) -> void:
	_elapsed += delta
	if seated != null:
		seated.advance(delta)
	_poll_time += delta
	if _poll_time >= 0.20:
		_poll_time = 0
		_poll()
	_focus = move_toward(_focus, 0, delta * 0.9)
	_update_camera()
	_publish_layout_observation()


func _poll() -> void:
	if not is_instance_valid(_host) or _closed:
		return
	var raw = JSON.parse_string(str(_host.call("getCardsState")))
	if raw is Dictionary and raw.get("protocol") == 1 and str(raw.get("token", "")) == _token:
		if int(raw.get("revision", -1)) != int(_state.get("revision", -2)):
			apply_state(raw)
	elif is_instance_valid(message):
		_clear_authority_view()


func _clear_authority_view() -> void:
	# Closing/invalidation must also hide the previous question and counters.
	DirAccess.remove_absolute(LAYOUT_OBSERVATION)
	_layout_observation_pending = false
	_state.clear()
	_cards.clear()
	_selected = ""
	for container in [hand_root, opponent_root, discard_root]:
		for child in container.get_children():
			child.queue_free()
	modal.hide()
	call_button.hide()
	status.text = ""
	page_label.text = ""
	heading.text = "Lumos Kartenstube"
	play_button.disabled = true
	draw_button.disabled = true
	pause_button.disabled = true
	message.text = "Die Runde wartet auf die Lern-App. Mit Zurück bleibt dein Spielstand erhalten."


func apply_state(next: Dictionary) -> void:
	if int(next.get("protocol", 0)) != 1 or not next.get("hand", []) is Array:
		return
	var previous := _state
	_state = next.duplicate(true)
	_token = str(next.get("token", _token))
	_sequence = maxi(_sequence, int(next.get("ack", 0)))
	if int(next.get("ack", 0)) >= _pending:
		_pending = 0
	var top: Dictionary = next.get("top", {}) if next.get("top") is Dictionary else {}
	var previous_top: Dictionary = (
		previous.get("top", {}) if previous.get("top") is Dictionary else {}
	)
	var top_changed := (
		not top.is_empty() and str(top.get("id", "")) != str(previous_top.get("id", ""))
	)
	var departure := Vector3(0, 1.2, -2.0)
	if _cards.has(str(top.get("id", ""))):
		departure = _cards[str(top.get("id", ""))].position
	for child in discard_root.get_children():
		child.queue_free()
	if not top.is_empty():
		var node := _make_card(discard_root, top, Vector3(0.62, 1.17, -0.23), true)
		if top_changed and not previous.is_empty() and not bool(next.get("reduceMotion", false)):
			node.position = departure + Vector3(0, 0.35, 0)
			var tween := node.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.tween_property(node, "position", Vector3(0.62, 1.17, -0.23), 0.4)
			_focus = 1.0
			actor.call("play_behavior", "agree_nod")
	_render_hand()
	_render_opponent()
	_update_interface()
	if str(next.get("phase", "")) == "gameOver" and str(previous.get("phase", "")) != "gameOver":
		actor.call("play_behavior", "celebrate")
	actor.call("set_suspended", bool(next.get("paused", false)))
	actor.call("set_reduced_motion", bool(next.get("reduceMotion", false)))


func _texture(card: Dictionary, face: bool) -> Texture2D:
	var path := "res://assets/cards_table/cards/back/card_back_default.png"
	if face:
		var folder: String = (
			{"orange": "red", "purple": "yellow", "blue": "blue", "green": "green"}
			. get(str(card.get("color", "")), "red")
		)
		var kind := str(card.get("type", "number"))
		if kind == "colorMagic":
			path = "res://assets/cards_table/cards/special/color_magic.png"
		elif kind == "superRain":
			path = "res://assets/cards_table/cards/special/wild_draw_four.png"
		else:
			var suffix := (
				# JSON mailbox numbers are floats; asset names use integer digits.
				str(int(card.get("number", 1)))
				if kind == "number"
				else str(
					(
						{
							"lumoJump": "skip",
							"starRain": "draw_two",
							"whirlwind": "reverse",
							"thinkPause": "think_pause"
						}
						. get(kind, "1")
					)
				)
			)
			path = "res://assets/cards_table/cards/%s/%s_%s.png" % [folder, folder, suffix]
	if not _textures.has(path):
		_textures[path] = load(path) if ResourceLoader.exists(path) else null
	return _textures[path]


func _make_card(parent: Node3D, card: Dictionary, at: Vector3, face: bool) -> Node3D:
	var node := Node3D.new()
	node.position = at
	parent.add_child(node)
	_box(
		node,
		Vector3.ZERO,
		Vector3(0.83, 0.032, 1.18),
		_material("card_edge", Color("e6e3d9"), 0.44)
	)
	var surface := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(0.83, 1.18)
	surface.mesh = plane
	surface.position.y = 0.017
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = _texture(card, face)
	mat.roughness = 0.63
	mat.metallic_specular = 0.24
	mat.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	surface.material_override = mat
	node.add_child(surface)
	return node


func _render_hand() -> void:
	_mark_layout_changed()
	var old: Dictionary = {}
	for id in _cards:
		if is_instance_valid(_cards[id]):
			old[id] = _cards[id].position
	for child in hand_root.get_children():
		child.queue_free()
	_cards.clear()
	_hand_targets.clear()
	var hand: Array = _state.get("hand", [])
	var max_page := maxi(0, ceili(float(hand.size()) / float(_page_size)) - 1)
	_page = clampi(_page, 0, max_page)
	var visible: Array = hand.slice(_page * _page_size, mini(hand.size(), (_page + 1) * _page_size))
	var visible_ids: Array[String] = []
	for i in range(visible.size()):
		var card: Dictionary = visible[i]
		var id := str(card.get("id", ""))
		visible_ids.append(id)
		var offset := float(i) - float(visible.size() - 1) * 0.5
		var size := ui.size
		var viewport_size := get_viewport().get_visible_rect().size
		var card_height := (
			(96 * _ui_scale) if _compact else clampf(size.y * 0.28, 96 * _ui_scale, 180 * _ui_scale)
		)
		var card_width := card_height * 0.83 / 1.18
		var spacing := minf(
			card_width * 1.08, (size.x - 32 * _ui_scale - card_width) / maxf(1, visible.size() - 1)
		)
		var screen := ui.position + Vector2(
			size.x * 0.5 + offset * spacing,
			size.y - (76 if _compact else 140) * _ui_scale - card_height * 0.5
		)
		var at := camera.project_position(screen, 4.0)
		var node := _make_card(hand_root, card, at, true)
		node.name = "HandCard%d" % i
		var scale_factor := (
			(2 * 4.0 * tan(deg_to_rad(camera.fov * 0.5))) * card_height / viewport_size.y / 1.18
		)
		node.basis = camera.global_basis * Basis(Vector3.RIGHT, PI * 0.5)
		node.scale = Vector3.ONE * scale_factor
		_hand_targets[id] = at
		_cards[id] = node
		if bool(card.get("playable", false)):
			_box(
				node,
				Vector3(0, -0.02, 0),
				Vector3(0.88, 0.02, 1.23),
				_material("legal_gold", Color("f5c259"), 0.32, 0.4)
			)
	if _selected not in visible_ids:
		_selected = ""
	_highlight_selection()
	if not bool(_state.get("reduceMotion", false)):
		var index := 0
		for id in _cards:
			var node: Node3D = _cards[id]
			var destination := node.position
			# Newly dealt/drawn cards physically travel from the deck into the hand.
			node.position = old.get(id, Vector3(-0.62, 1.32, -0.23))
			var tween := node.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			node.set_meta("move_tween", tween)
			if old.is_empty():
				tween.tween_interval(index * 0.035)
			tween.tween_property(node, "position", destination, 0.30)
			index += 1
	if is_instance_valid(page_label):
		page_label.text = "%d/%d" % [_page + 1, max_page + 1]


func _render_opponent() -> void:
	for child in opponent_root.get_children():
		child.queue_free()
	var players: Array = _state.get("players", [])
	if players.size() != 2:
		return
	var count := int(players[1 - int(_state.get("viewer", 0))].get("count", 0))
	for i in range(mini(count, 12)):
		var offset := float(i) - float(mini(count, 12) - 1) * 0.5
		var node := _make_card(
			opponent_root, {}, Vector3(offset * 0.20, 1.17 + i * 0.002, -1.7), false
		)
		node.rotation.y = offset * 0.055 + PI


func _highlight_selection() -> void:
	_mark_layout_changed()
	for id in _cards:
		var card_node: Node3D = _cards[id]
		var moving = card_node.get_meta("move_tween") if card_node.has_meta("move_tween") else null
		if moving is Tween and moving.is_valid():
			moving.kill()
		card_node.position = (
			_hand_targets[id] + camera.global_basis.y * (0.08 if id == _selected else 0.0)
		)
	if is_instance_valid(play_button):
		play_button.disabled = (
			_selected.is_empty() or _pending > 0 or bool(_state.get("paused", false))
		)


func _change_page(change: int) -> void:
	_page += change
	_selected = ""
	_render_hand()


func _update_interface() -> void:
	heading.text = (
		"Sternenpokal %d/%d" % [int(_state.get("round", 1)), int(_state.get("totalRounds", 1))]
		if int(_state.get("totalRounds", 1)) > 1
		else "Lumos Kartenstube"
	)
	var players: Array = _state.get("players", [])
	if players.size() == 2:
		status.text = (
			"%s: %d Karten   ·   %s: %d Karten"
			% [
				players[0].get("name", "Du"),
				int(players[0].get("count", 0)),
				players[1].get("name", "Lumo"),
				int(players[1].get("count", 0))
			]
		)
	message.text = str(_state.get("message", ""))
	if _compact and players.size() == 2:
		message.text = (
			"Du: %d · Lumo: %d · %s"
			% [int(players[0].get("count", 0)), int(players[1].get("count", 0)), message.text]
		)
	draw_button.disabled = not bool(_state.get("canDraw", false)) or _pending > 0
	pause_button.text = "Weiter" if bool(_state.get("paused", false)) else "Pause"
	pause_button.disabled = _pending > 0
	call_button.visible = bool(_state.get("canCall", false))
	call_button.disabled = _pending > 0
	for child in modal_content.get_children():
		child.queue_free()
	var phase := str(_state.get("phase", "playing"))
	modal.visible = (
		bool(_state.get("paused", false))
		or phase in ["chooseColor", "learningQuestion", "passDevice", "gameOver"]
	)
	if not modal.visible:
		return
	var title := Label.new()
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", int(22 * _ui_scale))
	modal_content.add_child(title)
	if bool(_state.get("paused", false)):
		title.text = "Dein Zug wartet auf dich."
		modal_content.add_child(_button("Weiterspielen", func(): _send("resume")))
	elif phase == "chooseColor":
		title.text = "Welche Farbe wählst du?"
		for color in ["orange", "purple", "blue", "green"]:
			var button := _button(COLOR_NAMES[color], func(): _send("color", {"color": color}))
			button.modulate = COLORS[color].lightened(0.35)
			modal_content.add_child(button)
	elif phase == "learningQuestion":
		var question: Dictionary = _state.get("question", {})
		title.text = str(question.get("prompt", "Lumo überlegt …"))
		var options: Array = question.get("options", [])
		for i in range(options.size()):
			modal_content.add_child(_button(str(options[i]), func(): _send("answer", {"index": i})))
	elif phase == "passDevice":
		title.text = "Gerät weitergeben. Deine Karten bleiben verdeckt."
		modal_content.add_child(_button("Ich bin bereit", func(): _send("handover")))
	elif phase == "gameOver":
		title.text = str(_state.get("message", "Die Runde ist beendet."))
		modal_content.add_child(_button("Ergebnis ansehen", _leave))
	for button in modal_content.find_children("*", "Button", true, false):
		button.custom_minimum_size.y = 52 * _ui_scale
		button.add_theme_font_size_override("font_size", int(18 * _ui_scale))
		button.disabled = _pending > 0
	_layout_modal.call_deferred()


func _layout_modal() -> void:
	if not is_inside_tree() or not is_instance_valid(modal) or not modal.visible:
		return
	var size := ui.size
	var height := minf(
		modal_content.get_combined_minimum_size().y + 44 * _ui_scale, size.y - 24 * _ui_scale
	)
	modal.offset_top = -height * 0.5
	modal.offset_bottom = height * 0.5


func _mark_layout_changed() -> void:
	# This diagnostic is separate from all gameplay saves. A previous settled
	# snapshot must not survive a page/selection transition with the same revision.
	if not _layout_observation_pending:
		DirAccess.remove_absolute(LAYOUT_OBSERVATION)
	_layout_observation_pending = true
	_layout_settle_frames = 2


func _vector_values(vector: Vector2) -> Array:
	return [vector.x, vector.y]


func _rect_values(rect: Rect2) -> Array:
	return [rect.position.x, rect.position.y, rect.size.x, rect.size.y]


func _observation_source() -> String:
	return "android_window_insets" if _android_safe_area_enabled and not _android_safe_area.is_empty() else "platform_safe_area"


func _face_quad(card: Node3D) -> Array:
	for child in card.get_children():
		if child is MeshInstance3D and child.mesh is PlaneMesh:
			var half: Vector2 = child.mesh.size * 0.5
			var factor := Vector2(get_window().size) / get_viewport().get_visible_rect().size
			var quad := []
			for corner in [Vector3(-half.x, 0, -half.y), Vector3(half.x, 0, -half.y),
				Vector3(half.x, 0, half.y), Vector3(-half.x, 0, half.y)]:
				quad.append(_vector_values(camera.unproject_position(child.to_global(corner)) * factor))
			return quad
	return []


func _publish_layout_observation() -> void:
	if not _layout_observation_pending or _state.is_empty() or _pending > 0 or not ui.is_visible_in_tree():
		return
	if _layout_settle_frames > 0:
		_layout_settle_frames -= 1
		return
	if _focus != 0.0 or Time.get_ticks_msec() < _layout_retry_after:
		return
	for card: Node3D in _cards.values():
		var tween: Variant = card.get_meta("move_tween") if card.has_meta("move_tween") else null
		if tween is Tween and tween.is_valid() and tween.is_running():
			return
	var hand := []
	# _cards preserves the actual visible public-hand insertion order.
	for id in _cards:
		hand.append({"id": id, "quad": _face_quad(_cards[id])})
	var discard := {}
	if discard_root.get_child_count() > 0:
		discard = {"id": str(_state.get("top", {}).get("id", "")),
			"quad": _face_quad(discard_root.get_child(discard_root.get_child_count() - 1))}
	var android := {}
	for key in ["view_size", "decor_size"]:
		if _android_safe_area.has(key):
			android[key] = _vector_values(_android_safe_area[key])
	for key in ["render_rect", "system_insets", "insets"]:
		if _android_safe_area.has(key):
			android[key] = _rect_values(_android_safe_area[key])
	var factor := Vector2(get_window().size) / get_viewport().get_visible_rect().size
	var ui_pixels := Rect2(ui.get_global_position() * factor, ui.size * factor)
	_layout_sequence += 1
	var snapshot := {
		"schema": 1, "layout_sequence": int(_layout_sequence), "ticks_msec": int(Time.get_ticks_msec()),
		"settled": true, "ui_visible": ui.is_visible_in_tree(),
		"observation_source": _observation_source(), "pending": int(_pending),
		"token": str(_state.get("token", "")), "roundId": str(_state.get("roundId", "")),
		"revision": int(_state.get("revision", 0)), "ack": int(_state.get("ack", 0)),
		"viewer": int(_state.get("viewer", 0)), "paused": bool(_state.get("paused", false)),
		"phase": str(_state.get("phase", "")), "page": int(_page), "page_size": int(_page_size),
		"selected_card_id": _selected, "density": _ui_scale,
		"window_px": _vector_values(Vector2(get_window().size)),
		"viewport_px": _vector_values(get_viewport().get_visible_rect().size),
		"android_observation": android, "ui_rect": _rect_values(ui_pixels),
		"hand": hand, "discard": discard,
	}
	var file := FileAccess.open(LAYOUT_OBSERVATION + ".tmp", FileAccess.WRITE)
	if file == null:
		_layout_retry_after = Time.get_ticks_msec() + 2000
		return
	file.store_string(JSON.stringify(snapshot))
	file.flush()
	var error := file.get_error()
	file.close()
	if error == OK:
		error = DirAccess.rename_absolute(LAYOUT_OBSERVATION + ".tmp", LAYOUT_OBSERVATION)
	if error == OK:
		_layout_observation_pending = false
	else:
		_layout_retry_after = Time.get_ticks_msec() + 2000


func _exit_tree() -> void:
	if MobileRuntime.safe_area_changed.is_connected(_resize):
		MobileRuntime.safe_area_changed.disconnect(_resize)
	if get_viewport().size_changed.is_connected(_resize):
		get_viewport().size_changed.disconnect(_resize)
	DirAccess.remove_absolute(LAYOUT_OBSERVATION)
	DirAccess.remove_absolute(LAYOUT_OBSERVATION + ".tmp")


func _unhandled_input(event: InputEvent) -> void:
	var point := Vector2.ZERO
	if event is InputEventScreenTouch and event.pressed:
		point = event.position
	elif (
		event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	):
		point = event.position
	else:
		return
	if modal.visible or _pending > 0 or bool(_state.get("paused", false)):
		return
	var origin := camera.project_ray_origin(point)
	var direction := camera.project_ray_normal(point)
	var closest := INF
	var picked := ""
	for id in _cards:
		var card_node: Node3D = _cards[id]
		var local_origin := card_node.to_local(origin)
		var local_direction := card_node.global_basis.inverse() * direction
		if absf(local_direction.y) < 0.001:
			continue
		var distance := -local_origin.y / local_direction.y
		var hit := local_origin + local_direction * distance
		if distance > 0 and distance < closest and absf(hit.x) <= 0.48 and absf(hit.z) <= 0.65:
			closest = distance
			picked = id
	if picked.is_empty():
		return
	for card in _state.get("hand", []):
		if str(card.get("id", "")) == picked and not bool(card.get("playable", false)):
			message.text = "Diese Karte passt gerade nicht. Goldene Karten kannst du legen."
			return
	if picked == _selected:
		_send("play", {"cardId": picked})
	else:
		_selected = picked
		_highlight_selection()
	get_viewport().set_input_as_handled()


func _send(action: String, payload: Dictionary = {}) -> void:
	if _state.is_empty() or _pending > 0 or _closed:
		return
	_sequence += 1
	var request := payload.duplicate(true)
	request["token"] = _token
	request["revision"] = int(_state.get("revision", 0))
	request["sequence"] = _sequence
	request["action"] = action
	action_requested.emit(request)
	var accepted := true
	if is_instance_valid(_host):
		accepted = HostBridge.durable_ack(_host.call("submitCardsAction", JSON.stringify(request)))
	if accepted:
		_pending = _sequence
		_mark_layout_changed()
		message.text = "Dein Zug wird gespeichert …"
		play_button.disabled = true
		draw_button.disabled = true
		pause_button.disabled = true
	else:
		message.text = "Der Zug wurde aktualisiert. Bitte noch einmal wählen."


func _leave() -> void:
	if _closed:
		return
	if HostBridge.is_embedded():
		_closed = HostBridge.return_to_app("games")
	else:
		SceneRouter.goto("games")
