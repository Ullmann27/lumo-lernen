extends Node3D
## Touch-first, actual 3D construction. No prerendered screenshot substitutes the world.
const CATALOG = preload("res://scripts/creative/build_catalog.gd")
const STATE = preload("res://scripts/creative/build_state.gd")
const RUNTIME = preload("res://scripts/creative/creative_runtime.gd")
const KIT = preload("res://scripts/creative/creative_kit.gd")
const SANDBOX = preload("res://scripts/creative/build_sandbox_tools.gd")
const EXPLORER = preload("res://scripts/creative/build_explorer.gd")
const STICK = preload("res://scripts/games/kart_joystick.gd")
const JUMP_BUTTON = preload("res://scripts/games/jump_touch_button.gd")
var model = STATE.new()
var kit = KIT.new()
var world: Node3D
var camera: Camera3D
var preview: MeshInstance3D
var guide: MeshInstance3D
var chosen: String = "sand"
var category: String = "Bauen"
var turn: int = 0
var layer: int = 0
var erase_mode: bool = false
var paused: bool = false
# Start overview: pulled back past the expanded rim and canyon so Werkstatt,
# Sternwarte, castle and waterfall still share one frame (Tafel 03 framing).
const START_ORBIT: float = 0.48
const START_TILT: float = 0.48
const START_RADIUS: float = 44.0
const START_FOCUS := Vector3(0.6, 0.8, 4.0)
const RADIUS_MIN: float = 10.0
const RADIUS_MAX: float = 72.0
const FOCUS_LIMIT: float = 32.0
var orbit: float = START_ORBIT
var tilt: float = START_TILT
var radius: float = START_RADIUS
var focus := START_FOCUS
var tap_start := Vector2.ZERO
var pointer_id: int = -1
var dragged: bool = false
var status: Label
var goal_label: Label
var count_label: Label
var palette: HBoxContainer
var goal: String = "bridge"
var slot: int = 1
var child_key: String = "standalone"
var save_path: String
var pause_panel: PanelContainer
var choice_window: Window
var guide_path: Array[Vector3i] = []
var guide_time: float = 0.0
var autosave: float = 0.0
var dirty: bool = false
var sandbox_mode: String = ""
var sandbox_points: Array[Vector3i] = []
var previous_runtime: Dictionary
var safe_ui: Control
var placed_nodes: Dictionary = {}
var touches: Dictionary = {}
var touch_gesture: bool = false
var move_mode := false
var selected_uid := -1
var move_cell := Vector3i.ZERO
var move_problem := ""
var object_drag := false
var explorer: CharacterBody3D
var exploring := false
var explore_ui: Control
var walk_stick: Control
var jump_button: Control
var interaction_button: Button
var mode_button: Button
var editor_controls: Array[Control] = []
var tool_actions: HBoxContainer
var camera_tools: HBoxContainer
var goal_panel: PanelContainer
var goal_access_button: Button
var lower_hud: VBoxContainer
var upper_hud: MarginContainer
var editor_camera: Dictionary = {}
var walk_orbit := 0.48
var walk_tilt := 0.34
var walk_camera_distance := 7.8
var selection_ghost: Node3D
var selection_grid: MeshInstance3D
var walk_notice: Label


func _ready() -> void:
	previous_runtime = RUNTIME.enter(self, true)
	previous_runtime["embed_subwindows"] = get_viewport().gui_embed_subwindows
	get_viewport().gui_embed_subwindows = true
	SceneRouter.current_scene_id = "build"
	child_key = (
		str(
			SceneRouter.launch_options.get(
				"childKey", HostBridge.launch_options().get("childKey", "standalone")
			)
		)
		. validate_filename()
		. substr(0, 80)
	)
	slot = clampi(int(SceneRouter.launch_options.get("buildSlot", 1)), 1, 6)
	save_path = "user://lumo_build_" + child_key + "_" + str(slot) + ".json"
	kit.environment(self, "bauwelt_day")
	_ground()
	world = Node3D.new()
	world.name = "Construction"
	add_child(world)
	camera = Camera3D.new()
	camera.fov = 54
	camera.far = 200
	add_child(camera)
	camera.current = true
	preview = kit.box(self, Vector3(-5, 0.5, 0), Vector3.ONE * 1.01, Color("67deff"))
	preview.material_override = kit.material(Color("67deff"), true, true)
	preview.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	guide = kit.mesh(
		self,
		preload("res://scripts/games/kart_world_meshes.gd").star(),
		Vector3(-1, 2, 2.5),
		Color("ffe6a0"),
		true
	)
	guide.scale = Vector3.ONE * 0.3
	guide.visible = false
	_ui()
	if not load_world(false):
		model.template("castle")
		# Start with a usable scene and leave the first bridge task for the child.
		model.place("tree", Vector3i(-11, 0, 3))
		model.place("lantern", Vector3i(-4, 0, -4))
		model.place("flowers", Vector3i(-7, 0, 1))
		# Visible 2013 landmarks on the free right bank and river (off the castle).
		model.place("cottage", Vector3i(7, 0, 5))
		model.place("observatory", Vector3i(9, 0, -2))
		model.place("tree", Vector3i(11, 0, 4))
		model.place("tree", Vector3i(5, 0, 8))
		model.place("bridge", Vector3i(-1, 0, 6))
		model.place("bridge", Vector3i(2, 0, 6))
		model.place("magic", Vector3i(5, 0, 5))
		model.place("lantern", Vector3i(6, 0, 4))
		# Ready-to-use plots on the new land and river islands (kids can keep building).
		model.add_starter_plot("garden", false)
		model.add_starter_plot("harbor", false)
		model.add_starter_plot("island", false)
	_rebuild()
	explorer = EXPLORER.new()
	add_child(explorer)
	_camera_update()
	get_viewport().size_changed.connect(_resize)
	_resize()
	_update_labels()
	print("[Bauwelt] ready: real geometry, ", CATALOG.PARTS.size(), " parts, save=", save_path)


func _ground() -> void:
	# Collision stays a flat island so placed blocks do not float; visuals are dressed separately.
	# Footprint matches build_state.HALF (24): banks x=-24.5..0 and 4..24.5, z=-24.5..24.5.
	var half := float(STATE.HALF) + 0.5
	for side in [-1, 1]:
		var bank := StaticBody3D.new()
		bank.name = "RiverBank"
		add_child(bank)
		var width := half if side == -1 else half - 4.0
		var center := Vector3((-width * 0.5) if side == -1 else (4.0 + width * 0.5), -1.2, 0)
		var size := Vector3(width, 2.4, half * 2.0)
		kit.collision(bank, center, size)
	var water := kit.box(self, Vector3(2, -0.38, 0), Vector3(4, 0.14, half * 2.0), Color("1b81bd"))
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://assets/shaders/kart_water.gdshader")
	water.material_override = mat
	# Buildable river islands (tops at y=0, same support rule as the main banks).
	for island_z in [-12.0, 20.0]:
		var isle := StaticBody3D.new()
		isle.name = "RiverIsland"
		add_child(isle)
		kit.collision(isle, Vector3(2.0, -1.2, island_z), Vector3(4.0, 2.4, 4.0))
	BuildLandmarks.dress_world(self, kit)


func _resize() -> void:
	_camera_update()
	if is_instance_valid(safe_ui):
		RUNTIME.safe_area(self, safe_ui)
		if is_instance_valid(pause_panel):
			pause_panel.position = (safe_ui.size - pause_panel.size) * 0.5
		_layout_explore_controls()
		_layout_choice_dialog()
		_layout_camera_tools.call_deferred()
		_layout_goal_access.call_deferred()


func _exit_tree() -> void:
	get_viewport().gui_embed_subwindows = bool(previous_runtime.get("embed_subwindows", false))
	RUNTIME.restore(self, previous_runtime)


func _ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(root)
	safe_ui = root
	var margin := MarginContainer.new()
	upper_hud = margin
	margin.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	root.add_child(margin)
	var hud := VBoxContainer.new()
	margin.add_child(hud)
	var top := HBoxContainer.new()
	hud.add_child(top)
	top.add_child(_day_button("‹ Spiele", _leave))
	var title := _day_label("LUMO BAUWELT", 22)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.clip_text = true
	top.add_child(title)
	count_label = _day_label("", 15)
	top.add_child(_day_button("Ⅱ", func(): _pause(true), 52))
	hud.add_child(count_label)
	var tools := HBoxContainer.new()
	hud.add_child(tools)
	editor_controls.append(tools)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tools.add_child(scroll)
	var actions := HBoxContainer.new()
	tool_actions = actions
	scroll.add_child(actions)
	for spec in [
		["Verschieben", _toggle_move],
		["Siedlung", _open_settlement.bind("settlement")],
		["Wettbau", _open_settlement.bind("rival")],
		["Drehen ↻", _rotate],
		["Entfernen", _toggle_erase],
		["Rückgängig", _undo],
		["Wiederholen", _redo],
		["Füllen", _set_sandbox_mode.bind("fill")],
		["Kopieren", _set_sandbox_mode.bind("copy")],
		["Spiegel X", _set_sandbox_mode.bind("mirror_x")],
		["Spiegel Z", _set_sandbox_mode.bind("mirror_z")],
		["Welten (6)", _slots],
		["Speichern", save_world],
		["Laden", load_world],
		["Vorlagen", _templates],
		["Bauziele", _goals]
	]:
		var action_button := _day_button(spec[0], spec[1])
		action_button.mouse_filter = Control.MOUSE_FILTER_PASS
		actions.add_child(action_button)
	goal_access_button = _day_button("Aktuelles Bauziel", _current_goal)
	goal_access_button.mouse_filter = Control.MOUSE_FILTER_PASS
	goal_access_button.visible = false
	actions.add_child(goal_access_button)
	mode_button = _day_button("Mit Lumo laufen", _toggle_explore)
	top.add_child(mode_button)
	var layer_down: Button = _day_button(
		"Ebene −",
		func():
			layer = maxi(0, layer - 1)
			_update_labels()
	)
	var layer_up: Button = _day_button(
		"Ebene +",
		func():
			layer = mini(17, layer + 1)
			_update_labels()
	)
	layer_down.mouse_filter = Control.MOUSE_FILTER_PASS
	layer_up.mouse_filter = Control.MOUSE_FILTER_PASS
	actions.add_child(layer_down)
	actions.add_child(layer_up)
	goal_panel = PanelContainer.new()
	goal_panel.add_theme_stylebox_override("panel", _day_panel())
	goal_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	goal_panel.position = Vector2(14, 156)
	goal_panel.custom_minimum_size = Vector2(282, 0)
	root.add_child(goal_panel)
	editor_controls.append(goal_panel)
	var goal_box := VBoxContainer.new()
	goal_panel.add_child(goal_box)
	goal_label = _day_label("", 17)
	goal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	goal_label.custom_minimum_size.x = 260
	goal_box.add_child(goal_label)
	goal_box.add_child(_day_button("Mein Bauwerk testen", _test_challenge))
	var lower := VBoxContainer.new()
	lower_hud = lower
	lower.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	lower.offset_top = -162
	lower.offset_left = 12
	lower.offset_right = -12
	root.add_child(lower)
	editor_controls.append(lower)
	status = _day_label("Tippe zum Bauen. Ziehe zum Drehen der Kamera. Zwei Finger: zoomen.", 14)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lower.add_child(status)
	var category_scroll := ScrollContainer.new()
	category_scroll.name = "BuildCategoriesScroll"
	category_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	lower.add_child(category_scroll)
	var categories := HBoxContainer.new()
	category_scroll.add_child(categories)
	for name in ["Bauen", "Dächer", "Wege", "Natur", "Deko"]:
		categories.add_child(
			_day_button(
				name,
				func():
					category = name
					_palette(),
				64
			)
		)
	var parts_scroll := ScrollContainer.new()
	parts_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	parts_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lower.add_child(parts_scroll)
	palette = HBoxContainer.new()
	parts_scroll.add_child(palette)
	_palette()
	camera_tools = HBoxContainer.new()
	camera_tools.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	camera_tools.position = Vector2(-200, -228)
	root.add_child(camera_tools)
	editor_controls.append(camera_tools)
	camera_tools.add_child(
		_day_button(
			"−",
			func():
				radius = clampf(radius + 3, RADIUS_MIN, RADIUS_MAX)
				_camera_update(),
			48
		)
	)
	camera_tools.add_child(
		_day_button(
			"+",
			func():
				radius = clampf(radius - 3, RADIUS_MIN, RADIUS_MAX)
				_camera_update(),
			48
		)
	)
	camera_tools.add_child(
		_day_button(
			"Mitte",
			func():
				focus = START_FOCUS
				orbit = START_ORBIT
				tilt = START_TILT
				radius = START_RADIUS
				_camera_update(),
			48
		)
	)
	pause_panel = PanelContainer.new()
	pause_panel.add_theme_stylebox_override("panel", _day_panel())
	pause_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	pause_panel.position = Vector2(-160, -140)
	pause_panel.custom_minimum_size = Vector2(320, 280)
	pause_panel.visible = false
	root.add_child(pause_panel)
	var pause_box := VBoxContainer.new()
	pause_panel.add_child(pause_box)
	pause_box.add_child(_day_label("Deine Welt wartet auf dich", 22))
	pause_box.add_child(_day_button("Weiterbauen", func(): _pause(false)))
	pause_box.add_child(_day_button("Speichern", save_world))
	pause_box.add_child(_day_button("Zur Spielewelt", _leave))
	_build_explore_controls(root)


func _layout_camera_tools() -> void:
	if not is_instance_valid(camera_tools) or not is_instance_valid(tool_actions):
		return
	var floating_top := safe_ui.get_global_rect().end.y - 228.0
	var toolbar_bottom := tool_actions.get_global_rect().end.y
	var compact := floating_top < toolbar_bottom + 8.0
	for button in camera_tools.get_children():
		button.mouse_filter = Control.MOUSE_FILTER_PASS if compact else Control.MOUSE_FILTER_STOP
	# On a short landscape screen the floating camera row would intercept
	# toolbar touches. Preserve every action in the existing scrolling row.
	if compact:
		if camera_tools.get_parent() != tool_actions:
			camera_tools.reparent(tool_actions, false)
			camera_tools.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	else:
		if camera_tools.get_parent() != safe_ui:
			camera_tools.reparent(safe_ui, false)
		camera_tools.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
		camera_tools.position = safe_ui.size + Vector2(-200, -228)


func _layout_goal_access() -> void:
	if not is_instance_valid(goal_panel) or not is_instance_valid(lower_hud):
		return
	# Preserve the complete assignment and its original action when the fixed
	# panel would be covered by the bottom palette on a short display.
	var compact := goal_panel.get_global_rect().end.y + 8.0 > lower_hud.get_global_rect().position.y
	goal_panel.visible = not compact and not exploring
	goal_access_button.visible = compact


func _current_goal() -> void:
	_choice_dialog("Aktuelles Bauziel", [[goal, "Mein Bauwerk testen"]],
		func(_id): _test_challenge(), goal_label.text)


func _palette() -> void:
	for child in palette.get_children():
		palette.remove_child(child)
		child.queue_free()
	for item in CATALOG.PARTS:
		if item.category != category:
			continue
		var button: Button = _day_button(
			str(item.name),
			func():
				chosen = item.id
				erase_mode = false
				_cancel_selection()
				move_mode = false
				_update_labels(),
			96
		)
		button.add_theme_color_override("font_color", item.color.darkened(0.35))
		button.tooltip_text = "%s · %d×%d×%d" % [item.name, item.size.x, item.size.y, item.size.z]
		palette.add_child(button)


func _rebuild() -> void:
	var active: Dictionary = {}
	var batches: Dictionary = {}
	for piece in model.pieces:
		var uid := int(piece.uid)
		active[uid] = true
		var item: Dictionary = CATALOG.part(str(piece.part))
		if BuildVoxelStyle.is_batchable(item):
			if placed_nodes.has(uid) and placed_nodes[uid].get_meta("piece") != piece:
				world.remove_child(placed_nodes[uid])
				placed_nodes[uid].queue_free()
				placed_nodes.erase(uid)
			if not placed_nodes.has(uid):
				var node: StaticBody3D = BuildVoxelStyle.collision_body(kit, item)
				var piece_xform: Transform3D = BuildVoxelStyle.piece_transform(piece, item)
				node.position = piece_xform.origin
				node.rotation.y = int(piece.turn) * PI * 0.5
				node.set_meta("uid", uid)
				node.set_meta("piece", piece.duplicate())
				world.add_child(node)
				placed_nodes[uid] = node
			if not batches.has(item.id):
				batches[item.id] = []
			batches[item.id].append({"piece": piece, "item": item})
			continue
		if placed_nodes.has(uid) and placed_nodes[uid].get_meta("piece") == piece:
			continue
		if placed_nodes.has(uid):
			world.remove_child(placed_nodes[uid])
			placed_nodes[uid].queue_free()
		var unique: StaticBody3D = kit.part_node(item)
		var turns := int(piece.turn)
		var size: Vector3 = item.size
		var offset: Vector3 = [
			Vector3.ZERO, Vector3(0, 0, size.x), Vector3(size.x, 0, size.z), Vector3(size.z, 0, 0)
		][posmod(turns, 4)]
		unique.position = Vector3(piece.x, piece.y, piece.z) + offset
		unique.rotation.y = turns * PI * 0.5
		unique.set_meta("uid", uid)
		unique.set_meta("piece", piece.duplicate())
		world.add_child(unique)
		placed_nodes[uid] = unique
	for uid in placed_nodes.keys():
		if not active.has(uid):
			world.remove_child(placed_nodes[uid])
			placed_nodes[uid].queue_free()
			placed_nodes.erase(uid)
	_sync_batched_visuals(batches)
	_update_labels()


func _typed_xforms(raw: Array) -> Array[Transform3D]:
	var result: Array[Transform3D] = []
	for item in raw:
		result.append(item)
	return result


func _sync_batched_visuals(batches: Dictionary) -> void:
	var wall_xforms: Array = []
	var pane_xforms: Array = []
	var planter_xforms: Array = []
	var grass_body_xforms: Array = []
	var grass_cap_xforms: Array = []
	for ident in BuildVoxelStyle.BATCHABLE:
		var entries: Array = batches.get(ident, [])
		if ident == "wall":
			for entry in entries:
				var px: Transform3D = BuildVoxelStyle.piece_transform(entry.piece, entry.item)
				wall_xforms.append(px)
				pane_xforms.append(Transform3D(px.basis, px.origin + px.basis * Vector3(0.5, 1.18, 1.02)))
				planter_xforms.append(Transform3D(px.basis, px.origin + px.basis * Vector3(0.5, 0.82, 1.16)))
			continue
		if ident == "grass":
			for entry in entries:
				var px: Transform3D = BuildVoxelStyle.piece_transform(entry.piece, entry.item)
				grass_body_xforms.append(Transform3D(px.basis, px.origin + px.basis * Vector3(0.5, 0.4, 0.5)))
				grass_cap_xforms.append(Transform3D(px.basis, px.origin + px.basis * Vector3(0.5, 0.91, 0.5)))
			continue
		var xforms: Array = []
		var sample: Dictionary = CATALOG.part(ident)
		for entry in entries:
			xforms.append(
				BuildVoxelStyle.box_instance_transform(
					BuildVoxelStyle.piece_transform(entry.piece, entry.item), entry.item
				)
			)
		BuildVoxelStyle.multimesh(
			world,
			"Batch_%s" % ident,
			BuildVoxelStyle.unit_box(),
			BuildVoxelStyle.material(BuildVoxelStyle.kind_for(sample), BuildVoxelStyle.tint_for(sample)),
			_typed_xforms(xforms)
		)
	BuildVoxelStyle.multimesh(
		world,
		"Batch_wall",
		BuildVoxelStyle.wall_mesh(),
		BuildVoxelStyle.material("sand", Color("d9a86c")),
		_typed_xforms(wall_xforms)
	)
	BuildVoxelStyle.multimesh(
		world,
		"Batch_wall_glass",
		BuildVoxelStyle.window_pane(),
		BuildVoxelStyle.material("glass", Color("9ae8ff")),
		_typed_xforms(pane_xforms)
	)
	BuildVoxelStyle.multimesh(
		world,
		"Batch_wall_planters",
		BuildLandmarks.planter_mesh(),
		BuildVoxelStyle.material("leaves", Color("7ec85a")),
		_typed_xforms(planter_xforms)
	)
	BuildVoxelStyle.multimesh(
		world,
		"Batch_grass_body",
		BuildVoxelStyle.grass_body(),
		BuildVoxelStyle.material("dirt", Color("c4a078")),
		_typed_xforms(grass_body_xforms)
	)
	BuildVoxelStyle.multimesh(
		world,
		"Batch_grass_cap",
		BuildVoxelStyle.grass_cap(),
		BuildVoxelStyle.material("grass_top", Color.WHITE),
		_typed_xforms(grass_cap_xforms)
	)


func _camera_update() -> void:
	if not is_instance_valid(camera) or not camera.is_inside_tree():
		return
	if exploring:
		return
	camera.position = (
		focus + Vector3(sin(orbit) * cos(tilt), sin(tilt), cos(orbit) * cos(tilt)) * radius
	)
	camera.look_at(focus + Vector3.UP * 1.2)


func _ray(at: Vector2) -> Dictionary:
	var origin: Vector3 = camera.project_ray_origin(at)
	var query := PhysicsRayQueryParameters3D.create(
		origin, origin + camera.project_ray_normal(at) * 150
	)
	return get_world_3d().direct_space_state.intersect_ray(query)


func _preview_at(at: Vector2) -> Vector3i:
	if selected_uid >= 0:
		return _move_preview_at(at)
	var hit: Dictionary = _ray(at)
	var target: Vector3
	if not hit.is_empty():
		target = hit.position + hit.normal * 0.04
	else:
		var origin: Vector3 = camera.project_ray_origin(at)
		var direction: Vector3 = camera.project_ray_normal(at)
		if absf(direction.y) < 0.001:
			return Vector3i(50, 0, 50)
		target = origin + direction * ((float(layer) - origin.y) / direction.y)
	var cell := Vector3i(floori(target.x), layer, floori(target.z))
	var size: Vector3 = CATALOG.size_of(chosen, turn)
	preview.position = Vector3(cell) + size * 0.5
	preview.mesh.size = size * 1.02
	preview.material_override = kit.material(
		(
			Color("6fe3ff")
			if model.placement_error(chosen, cell, turn).is_empty()
			else Color("e8ab95")
		),
		true,
		true
	)
	return cell


func _tap(at: Vector2) -> void:
	if paused or exploring:
		return
	if move_mode:
		if selected_uid >= 0:
			_move_preview_at(at)
			_commit_move()
		else:
			var selected: Dictionary = _ray(at)
			if not selected.is_empty() and selected.collider.has_meta("uid"):
				_select_piece(int(selected.collider.get_meta("uid")))
		return
	if not sandbox_mode.is_empty():
		_sandbox_tap(_preview_at(at))
		return
	if erase_mode:
		var hit: Dictionary = _ray(at)
		if not hit.is_empty() and hit.collider.has_meta("uid"):
			if model.remove(int(hit.collider.get_meta("uid"))):
				_rebuild()
				dirty = true
			else:
				status.text = "Entferne zuerst die Bauteile darüber, damit nichts schwebt."
		return
	var cell: Vector3i = _preview_at(at)
	var problem: String = model.place(chosen, cell, turn)
	status.text = (
		"%s platziert. Deine Welt wächst!" % CATALOG.part(chosen).name
		if problem.is_empty()
		else problem
	)
	if problem.is_empty():
		dirty = true
		_rebuild()
		_place_feedback(cell)


func _world_gesture_starts_on_ui(point: Vector2) -> bool:
	for control in [upper_hud, lower_hud, goal_panel, camera_tools]:
		if not is_instance_valid(control) or not control.is_visible_in_tree():
			continue
		var local: Vector2 = control.get_global_transform_with_canvas().affine_inverse() * point
		if Rect2(Vector2.ZERO, control.size).has_point(local):
			return true
	return false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouse and event.device == InputEvent.DEVICE_ID_EMULATION:
		return
	if event.is_action_pressed("ui_cancel"):
		_pause(not paused)
		return
	if paused:
		return
	# Scrolling controls pass touch events to their ancestors. Such a press
	# belongs to the HUD and must not also start an orbit or object drag below.
	# Existing world gestures keep their original release/ownership behavior.
	if ((event is InputEventScreenTouch or event is InputEventMouseButton)
		and event.pressed and _world_gesture_starts_on_ui(event.position)):
		return
	if exploring:
		_explore_input(event)
		return
	if event is InputEventMouseButton:
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			radius = clampf(
				radius + (-2 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 2), RADIUS_MIN, RADIUS_MAX
			)
			_camera_update()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				tap_start = event.position
				dragged = false
				pointer_id = 0
				if _begin_object_drag(event.position):
					return
				_preview_at(event.position)
			else:
				if pointer_id == 0 and not dragged:
					_tap(event.position)
				pointer_id = -1
	elif event is InputEventMouseMotion:
		if pointer_id == 0:
			dragged = dragged or event.position.distance_to(tap_start) > 10
			if object_drag:
				_move_preview_at(event.position)
				return
			if dragged:
				if event.shift_pressed:
					focus += (
						camera.basis.x * (-event.relative.x * 0.035)
						+ (
							Vector3(camera.basis.z.x, 0, camera.basis.z.z)
							* (-event.relative.y * 0.035)
						)
					)
				else:
					orbit -= event.relative.x * 0.007
					tilt = clampf(tilt + event.relative.y * 0.005, 0.25, 1.2)
				_clamp_focus()
				_camera_update()
		else:
			_preview_at(event.position)
	elif event is InputEventScreenTouch:
		if event.pressed:
			touches[event.index] = event.position
			if touches.size() == 1 and not touch_gesture:
				pointer_id = event.index
				tap_start = event.position
				dragged = false
				_begin_object_drag(event.position)
			else:
				touch_gesture = true
				dragged = true
				object_drag = false
		else:
			if pointer_id == event.index and not dragged and not touch_gesture and not event.canceled:
				_tap(event.position)
			touches.erase(event.index)
			if touches.is_empty():
				touch_gesture = false
				pointer_id = -1
	elif event is InputEventScreenDrag and touches.has(event.index):
		if object_drag and event.index == pointer_id and touches.size() == 1:
			touches[event.index] = event.position
			dragged = dragged or event.position.distance_to(tap_start) > 10
			_move_preview_at(event.position)
			return
		if touches.size() >= 2:
			var keys := touches.keys()
			var a: Vector2 = touches[keys[0]]
			var b: Vector2 = touches[keys[1]]
			var before := maxf(1, a.distance_to(b))
			var old_center := (a + b) * 0.5
			touches[event.index] = event.position
			a = touches[keys[0]]
			b = touches[keys[1]]
			radius = clampf(radius * before / maxf(1, a.distance_to(b)), RADIUS_MIN, RADIUS_MAX)
			var motion := (a + b) * 0.5 - old_center
			focus += (
				camera.basis.x * (-motion.x * radius / 650.0)
				+ Vector3(camera.basis.z.x, 0, camera.basis.z.z) * (-motion.y * radius / 650.0)
			)
		else:
			touches[event.index] = event.position
			dragged = dragged or event.position.distance_to(tap_start) > 10
			if dragged and not touch_gesture:
				orbit -= event.relative.x * 0.007
				tilt = clampf(tilt + event.relative.y * 0.005, 0.25, 1.2)
		_clamp_focus()
		_camera_update()
	elif event is InputEventMagnifyGesture:
		radius = clampf(radius / event.factor, RADIUS_MIN, RADIUS_MAX)
		_camera_update()
	elif event is InputEventPanGesture:
		focus += (
			camera.basis.x * event.delta.x * 0.1
			+ Vector3(camera.basis.z.x, 0, camera.basis.z.z) * event.delta.y * 0.1
		)
		_clamp_focus()
		_camera_update()


func _process(delta: float) -> void:
	if paused:
		return
	autosave += delta
	if dirty and autosave >= 3:
		autosave = 0
		save_world(false)
	if exploring:
		_update_walk_camera(delta)
	if not guide_path.is_empty():
		guide_time += delta * 1.3
		var index: int = mini(int(guide_time), guide_path.size() - 1)
		var next: int = mini(index + 1, guide_path.size() - 1)
		guide.position = (
			Vector3(guide_path[index]).lerp(Vector3(guide_path[next]), fmod(guide_time, 1.0))
			+ Vector3(0.5, 1.6, 0.5)
		)
		guide.rotate_y(delta)
		if guide_time > guide_path.size() + 1:
			guide.visible = false
			guide_path.clear()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if is_instance_valid(status):
			save_world(false)
			_pause(true)


func _set_sandbox_mode(mode: String) -> void:
	_cancel_selection()
	move_mode = false
	sandbox_mode = "" if sandbox_mode == mode else mode
	sandbox_points.clear()
	erase_mode = false
	if sandbox_mode.is_empty():
		status.text = "Werkzeug beendet. Tippe auf einen freien Platz zum Bauen."
	elif sandbox_mode == "fill":
		status.text = "Füllen: Tippe die erste und die gegenüberliegende Ecke."
	else:
		status.text = (
			"Kopieren: Wähle zwei Ecken und danach den Zielpunkt."
			if sandbox_mode == "copy"
			else "Spiegeln: Wähle zwei Ecken und danach den Zielpunkt."
		)


func _sandbox_tap(cell: Vector3i) -> void:
	if STATE.out_of_world(cell):
		status.text = "Dieser Punkt liegt außerhalb deiner Bauwelt."
		return
	sandbox_points.append(cell)
	if sandbox_mode == "fill" and sandbox_points.size() < 2:
		status.text = "Füllen: Jetzt die gegenüberliegende Ecke wählen."
		return
	if sandbox_mode != "fill" and sandbox_points.size() < 2:
		status.text = "Bereich gewählt: Jetzt die zweite Ecke wählen."
		return
	if sandbox_mode != "fill" and sandbox_points.size() < 3:
		status.text = "Bereich gewählt: Jetzt den Zielpunkt für die Kopie wählen."
		return

	var result: Dictionary
	if sandbox_mode == "fill":
		result = SANDBOX.fill_rect(model, chosen, sandbox_points[0], sandbox_points[1], turn)
	else:
		var source_low := Vector3i(
			mini(sandbox_points[0].x, sandbox_points[1].x),
			mini(sandbox_points[0].y, sandbox_points[1].y),
			mini(sandbox_points[0].z, sandbox_points[1].z)
		)
		var offset: Vector3i = sandbox_points[2] - source_low
		if sandbox_mode == "copy":
			result = SANDBOX.copy_region(
				model, sandbox_points[0], sandbox_points[1], offset
			)
		else:
			result = SANDBOX.mirror_copy_region(
				model,
				sandbox_points[0],
				sandbox_points[1],
				"x" if sandbox_mode == "mirror_x" else "z",
				offset
			)
	sandbox_points.clear()
	if bool(result.get("ok", false)):
		dirty = true
		_rebuild()
		_update_labels()
		status.text = "%d Teile mit %s erstellt. Rückgängig macht alles auf einmal." % [
			int(result.get("count", 0)),
			(
				"Füllen"
				if sandbox_mode == "fill"
				else ("Kopieren" if sandbox_mode == "copy" else "Spiegeln")
			),
		]
	else:
		status.text = str(result.get("error", "Die Werkzeugaktion konnte nicht ausgeführt werden."))


func _rotate() -> void:
	turn = posmod(turn + 1, 4)
	if selected_uid >= 0:
		_refresh_move_preview(move_cell)
	_update_labels()


func _toggle_erase() -> void:
	_cancel_selection()
	move_mode = false
	erase_mode = not erase_mode
	if erase_mode:
		sandbox_mode = ""
		sandbox_points.clear()
	status.text = (
		"Tippe auf das Bauteil, das du entfernen möchtest."
		if erase_mode
		else "Tippe auf einen freien Platz zum Bauen."
	)


func _undo() -> void:
	_cancel_selection()
	sandbox_points.clear()
	if model.undo():
		dirty = true
		_rebuild()


func _redo() -> void:
	_cancel_selection()
	sandbox_points.clear()
	if model.redo():
		dirty = true
		_rebuild()


func _update_labels() -> void:
	if not is_instance_valid(count_label):
		return
	count_label.text = (
		"Welt %d · %d Teile · Ebene %d · %d°" % [slot, model.pieces.size(), layer, turn * 90]
	)
	var texts: Dictionary = {
		"bridge": "Verbinde die Inseln\nBaue einen durchgehenden Weg über den Fluss.",
		"house": "Ein Zuhause für Lumo\nBaue Wände, eine Haustür und ein getragenes Dach.",
		"tower": "Turm der Sterne\nEine Laterne auf einem tragenden Turm: mindestens 5 Ebenen.",
		"garden": "Ein Garten zum Verweilen\nBaum, Blumen, Bank und Laterne gehören zusammen.",
		"castle":
		"Das große Sternenschloss\nBaue vier Türme mit Dächern und ein bewohnbares Haus im Hof.",
		"village": "Ein Dorf für Freunde\nDrei Häuser, ein Garten und eine Brücke gehören zusammen."
	}
	goal_label.text = (
		str(texts[goal]) + ("\n✓ Schon geschafft" if model.completed.has(goal) else "")
	)
	_layout_goal_access.call_deferred()


func _pause(value: bool) -> void:
	paused = value
	pause_panel.visible = value
	pointer_id = -1
	touches.clear()
	touch_gesture = false
	object_drag = false
	if is_instance_valid(explorer):
		explorer.set_active(exploring and not value)
		explorer.visible = exploring
	if is_instance_valid(walk_stick):
		walk_stick.set_enabled(exploring and not value)
		jump_button.set_enabled(exploring and not value)
		interaction_button.disabled = value
	if value:
		save_world(false)


func save_world(show_message: bool = true) -> bool:
	var data: Dictionary = model.to_data()
	data["goal"] = goal
	data["camera"] = {
		"orbit": orbit, "tilt": tilt, "radius": radius, "focus": [focus.x, focus.y, focus.z]
	}
	var file := FileAccess.open(save_path + ".tmp", FileAccess.WRITE)
	if file == null:
		status.text = "Deine Welt konnte noch nicht gespeichert werden. Versuche es bitte erneut."
		return false
	file.store_string(JSON.stringify(data))
	file.flush()
	var error: Error = file.get_error()
	file.close()
	if error != OK or DirAccess.rename_absolute(save_path + ".tmp", save_path) != OK:
		status.text = "Speichern fehlgeschlagen. Deine Welt bleibt geöffnet."
		return false
	dirty = false
	if show_message:
		status.text = "Deine Welt ist gespeichert – du kannst jederzeit weiterbauen."
	return true


func load_world(show_message: bool = true) -> bool:
	if not FileAccess.file_exists(save_path):
		if show_message:
			status.text = "In diesem Platz ist noch keine Welt gespeichert."
		return false
	var raw = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if not raw is Dictionary or not model.restore(raw):
		if show_message:
			status.text = "Dieser Spielstand ist beschädigt. Deine offene Welt bleibt erhalten."
		return false
	_cancel_selection()
	goal = str(raw.get("goal", "bridge"))
	if goal not in ["house", "bridge", "tower", "garden", "castle", "village"]:
		goal = "bridge"
	if raw.get("camera") is Dictionary:
		orbit = float(raw.camera.get("orbit", 0.62))
		tilt = clampf(float(raw.camera.get("tilt", 0.68)), 0.25, 1.2)
		radius = clampf(float(raw.camera.get("radius", 29)), RADIUS_MIN, RADIUS_MAX)
		var saved_focus = raw.camera.get("focus", [])
		if saved_focus is Array and saved_focus.size() == 3:
			focus = Vector3(
				clampf(float(saved_focus[0]), -FOCUS_LIMIT, FOCUS_LIMIT),
				clampf(float(saved_focus[1]), 0, 19),
				clampf(float(saved_focus[2]), -FOCUS_LIMIT, FOCUS_LIMIT)
			)
	_rebuild()
	_camera_update()
	if show_message:
		status.text = "Willkommen zurück! Hier wartet dein Bauwerk."
	return true


func _choice_dialog(title: String, items: Array, action: Callable, description: String = "") -> void:
	if is_instance_valid(choice_window):
		return
	var dialog := Window.new()
	choice_window = dialog
	dialog.name = "BuildChoiceDialog"
	dialog.title = title
	dialog.borderless = true
	dialog.unresizable = true
	dialog.transient = true
	dialog.exclusive = true
	add_child(dialog)
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel", _day_panel())
	dialog.add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	var heading := _day_label(title, 23)
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(heading)
	var scroll := ScrollContainer.new()
	scroll.name = "BuildChoicesScroll"
	scroll.custom_minimum_size.y = 48
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var choices := VBoxContainer.new()
	choices.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(choices)
	if not description.is_empty():
		var details := _day_label(description, 17)
		details.name = "BuildGoalDescription"
		details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		details.mouse_filter = Control.MOUSE_FILTER_PASS
		choices.add_child(details)
	for item in items:
		var button := _day_button(item[1], _choose.bind(action, item[0], dialog))
		button.mouse_filter = Control.MOUSE_FILTER_PASS
		choices.add_child(button)
	# Cancellation stays outside the scroll viewport, including on a short phone.
	box.add_child(_day_button("Abbrechen", dialog.queue_free))
	dialog.close_requested.connect(dialog.queue_free)
	_layout_choice_dialog()
	dialog.popup_centered()
	_layout_choice_dialog()


func _layout_choice_dialog() -> void:
	if not is_instance_valid(choice_window) or not is_instance_valid(safe_ui):
		return
	var available := safe_ui.size - Vector2(24, 24)
	var extent := Vector2i(minf(390, available.x), minf(500, available.y))
	# Keep the real Window viewport at the bounded size; reset the old minimum
	# first so an already open dialog can shrink when a Fold changes orientation.
	choice_window.min_size = Vector2i.ZERO
	choice_window.size = extent
	choice_window.min_size = extent
	choice_window.position = Vector2i(safe_ui.position + (safe_ui.size - Vector2(extent)) * 0.5)


func _slots() -> void:
	var items: Array = []
	for i in range(1, 7):
		var path := "user://lumo_build_" + child_key + "_" + str(i) + ".json"
		items.append(
			[
				i,
				(
					"Welt %d · %s"
					% [i, "weiterbauen" if FileAccess.file_exists(path) else "neue Insel"]
				)
			]
		)
	_choice_dialog("Deine sechs Welten", items, _open_slot)


func _choose(action: Callable, id: Variant, dialog: Window) -> void:
	action.call(id)
	dialog.queue_free()


func _open_slot(id: int) -> void:
	if not save_world(false):
		return
	_cancel_selection()
	slot = id
	save_path = "user://lumo_build_" + child_key + "_" + str(slot) + ".json"
	if not load_world(false):
		model = STATE.new()
		goal = "bridge"
		focus = START_FOCUS
		dirty = true
		_rebuild()
		_camera_update()
	status.text = "Welt %d ist geöffnet. Hier kannst du deine eigene Idee bauen." % slot
	_update_labels()


func _templates() -> void:
	_choice_dialog(
		"Neue Welt / Vorlage",
		[
			["castle", "Großes Sternenschloss"],
			["village", "Dorf für Freunde"],
			["house", "Starter-Haus"],
			["bridge", "Brücke"],
			["tower", "Sternenturm"],
			["garden", "Garten"],
			["plot_garden", "Garten-Parzelle"],
			["plot_harbor", "Hafen-Parzelle"],
			["plot_island", "Insel-Parzelle"],
			["empty", "Leere Insel"]
		],
		_select_template
	)


func _select_template(id: String) -> void:
	_cancel_selection()
	model.template(id)
	dirty = true
	_rebuild()
	status.text = "Vorlage geöffnet. Rückgängig bringt deine vorherige Welt zurück."


func _goals() -> void:
	_choice_dialog(
		"Dein nächstes Bauziel",
		[
			["house", "Ein Zuhause bauen"],
			["bridge", "Die Inseln verbinden"],
			["tower", "Turm der Sterne"],
			["garden", "Ein Garten zum Verweilen"],
			["castle", "Großes Sternenschloss"],
			["village", "Dorf für Freunde"]
		],
		_select_goal
	)


func _select_goal(id: String) -> void:
	goal = id
	dirty = true
	_update_labels()


func _test_challenge() -> void:
	if not model.challenge_passes(goal):
		status.text = "Noch fehlt etwas. Prüfe dein Bauziel – Lumo glaubt an deine Idee!"
		return
	if goal == "bridge":
		guide_path = model.bridge_path()
		guide_time = 0
		guide.visible = true
	if not model.completed.has(goal):
		model.completed.append(goal)
		if not save_world(false):
			model.completed.erase(goal)
			return
		if HostBridge.is_embedded():
			var result: Dictionary = {
				"resultId": "build-" + child_key + "-" + goal,
				"game": "build",
				"status": "completed",
				"stars": 3,
				"xp": 24,
				"solved": 1,
				"grade": int(SceneRouter.launch_options.get("grade", 1)),
				"subject": "Logik"
			}
			if not HostBridge.reward(result):
				status.text = "Bauziel geschafft! Deine Sterne warten noch auf die Speicherbestätigung."
				_update_labels()
				return
	status.text = "Bauziel geschafft! Dein Bauwerk funktioniert."
	_update_labels()


func _leave() -> void:
	if save_world(false):
		SceneRouter.goto("games")

func _day_panel() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.96, 0.93, 0.84, 0.92)
	style.border_color = Color("2f8a96")
	style.set_border_width_all(1)
	style.set_corner_radius_all(14)
	style.set_content_margin_all(12)
	style.shadow_color = Color(0.12, 0.18, 0.16, 0.18)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 1)
	return style


func _day_button(text: String, callback: Callable, min_width: float = 82) -> Button:
	var control := Button.new()
	control.text = text
	control.custom_minimum_size = Vector2(min_width, 48)
	control.add_theme_stylebox_override("normal", _day_panel())
	var hover: StyleBoxFlat = _day_panel()
	hover.bg_color = Color("d7efe8")
	control.add_theme_stylebox_override("hover", hover)
	control.add_theme_stylebox_override("pressed", hover)
	control.add_theme_font_size_override("font_size", 16)
	control.add_theme_color_override("font_color", Color("243038"))
	control.add_theme_color_override("font_hover_color", Color("1a3c42"))
	control.pressed.connect(callback)
	return control


func _day_label(text: String, size: int = 18) -> Label:
	var control := Label.new()
	control.text = text
	control.add_theme_font_size_override("font_size", size)
	control.add_theme_color_override("font_color", Color("243038"))
	control.add_theme_color_override("font_shadow_color", Color(1, 1, 1, 0.35))
	control.add_theme_constant_override("shadow_offset_x", 0)
	control.add_theme_constant_override("shadow_offset_y", 1)
	return control


func _clamp_focus() -> void:
	focus.x = clampf(focus.x, -FOCUS_LIMIT, FOCUS_LIMIT)
	focus.z = clampf(focus.z, -FOCUS_LIMIT, FOCUS_LIMIT)


func _toggle_move() -> void:
	_cancel_selection()
	move_mode = not move_mode
	erase_mode = false
	sandbox_mode = ""
	sandbox_points.clear()
	status.text = (
		"Bauteil antippen oder greifen. Danach ziehen, drehen und auf einem freien Platz absetzen."
		if move_mode else "Tippe auf einen freien Platz zum Bauen."
	)


func _open_settlement(mode: String) -> void:
	if paused or not save_world(false):
		return
	SceneRouter.launch_options["settlementMode"] = mode
	SceneRouter.launch_options["buildSlot"] = slot
	SceneRouter.goto("settlement")


func _cancel_selection() -> void:
	selected_uid = -1
	object_drag = false
	move_problem = ""
	if is_instance_valid(selection_ghost):
		selection_ghost.queue_free()
		selection_ghost = null
	if is_instance_valid(selection_grid):
		selection_grid.hide()
	if is_instance_valid(preview):
		preview.visible = not exploring


func _select_piece(uid: int) -> bool:
	var piece: Dictionary = model.piece_by_id(uid)
	if piece.is_empty():
		return false
	_cancel_selection()
	move_mode = true
	selected_uid = uid
	chosen = str(piece.part)
	turn = int(piece.turn)
	layer = int(piece.y)
	selection_ghost = kit.part_node(CATALOG.part(chosen))
	selection_ghost.name = "SelectedBuildGhost"
	# Preview geometry never receives a physics ray or collides with Lumo.
	selection_ghost.collision_layer = 0
	selection_ghost.collision_mask = 0
	add_child(selection_ghost)
	for collision in selection_ghost.find_children("*", "CollisionShape3D", true, false):
		collision.disabled = true
	_refresh_move_preview(Vector3i(piece.x, piece.y, piece.z))
	status.text = "%s ausgewählt. Ziehen oder Ziel antippen; Drehen ↻ verändert die Vorschau." % CATALOG.part(chosen).name
	return true


func _begin_object_drag(at: Vector2) -> bool:
	if not move_mode:
		return false
	var hit: Dictionary = _ray(at)
	if hit.is_empty() or not hit.collider.has_meta("uid"):
		return false
	var uid := int(hit.collider.get_meta("uid"))
	if selected_uid < 0:
		_select_piece(uid)
	if uid != selected_uid:
		return false
	object_drag = true
	return true


func _move_preview_at(at: Vector2) -> Vector3i:
	var origin := camera.project_ray_origin(at)
	var direction := camera.project_ray_normal(at)
	if absf(direction.y) < 0.001:
		return move_cell
	var distance := (float(layer) - origin.y) / direction.y
	if distance <= 0:
		return move_cell
	var target := origin + direction * distance
	var cell := Vector3i(floori(target.x), layer, floori(target.z))
	if cell != move_cell:
		_refresh_move_preview(cell)
	return cell


func _refresh_move_preview(cell: Vector3i) -> void:
	move_cell = cell
	move_problem = model.transform_error(selected_uid, cell, turn)
	var item: Dictionary = CATALOG.part(chosen)
	var size: Vector3 = CATALOG.size_of(chosen, turn)
	var original_size: Vector3 = item.size
	var offset: Vector3 = [
		Vector3.ZERO, Vector3(0, 0, original_size.x),
		Vector3(original_size.x, 0, original_size.z), Vector3(original_size.z, 0, 0)
	][posmod(turn, 4)]
	var color := Color("53ded0") if move_problem.is_empty() else Color("ed9675")
	var material := kit.material(color, true, true)
	if is_instance_valid(selection_ghost):
		selection_ghost.position = Vector3(cell) + offset
		selection_ghost.rotation.y = turn * PI * 0.5
		for mesh in selection_ghost.find_children("*", "MeshInstance3D", true, false):
			mesh.material_override = material
			mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	preview.position = Vector3(cell) + size * 0.5
	preview.mesh.size = size * 1.015
	preview.material_override = material
	preview.hide()
	if not is_instance_valid(selection_grid):
		selection_grid = MeshInstance3D.new()
		selection_grid.name = "BuildPlacementGrid"
		selection_grid.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(selection_grid)
	var lines := ImmediateMesh.new()
	lines.surface_begin(Mesh.PRIMITIVE_LINES, kit.material(color, true))
	for x in range(-2, int(size.x) + 3):
		lines.surface_add_vertex(Vector3(x, 0.035, -2))
		lines.surface_add_vertex(Vector3(x, 0.035, size.z + 2))
	for z in range(-2, int(size.z) + 3):
		lines.surface_add_vertex(Vector3(-2, 0.035, z))
		lines.surface_add_vertex(Vector3(size.x + 2, 0.035, z))
	lines.surface_end()
	selection_grid.mesh = lines
	selection_grid.position = Vector3(cell)
	selection_grid.show()
	_update_labels()


func _commit_move() -> bool:
	if selected_uid < 0:
		return false
	var problem: String = model.transform_piece(selected_uid, move_cell, turn)
	if not problem.is_empty():
		status.text = problem
		return false
	var part_name := str(CATALOG.part(chosen).name)
	_cancel_selection()
	dirty = true
	_rebuild()
	status.text = "%s versetzt. Rückgängig stellt den vorherigen Platz wieder her." % part_name
	return true


func _input(event: InputEvent) -> void:
	if event is InputEventMouse and event.device == InputEvent.DEVICE_ID_EMULATION:
		return
	# The world owns a picked object until its finger releases, including over
	# the palette. A second finger turns the operation into camera navigation.
	if paused or not object_drag:
		return
	var released: bool = (
		event is InputEventScreenTouch and event.index == pointer_id and not event.pressed
	) or (
		event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT
		and pointer_id == 0 and not event.pressed
	)
	if not released:
		return
	var canceled: bool = event is InputEventScreenTouch and event.canceled
	if dragged and not canceled:
		_move_preview_at(event.position)
		_commit_move()
	object_drag = false
	pointer_id = -1
	touches.clear()
	get_viewport().set_input_as_handled()


func _build_explore_controls(root: Control) -> void:
	explore_ui = Control.new()
	explore_ui.name = "BuildExploreControls"
	explore_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	explore_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	explore_ui.hide()
	root.add_child(explore_ui)
	walk_stick = STICK.new()
	walk_stick.name = "BuildWalkStick"
	explore_ui.add_child(walk_stick)
	walk_stick.tooltip_text = "Lumo bewegen: Stick in die gewünschte Richtung ziehen."
	jump_button = JUMP_BUTTON.new()
	jump_button.name = "BuildJumpButton"
	jump_button.hold_changed.connect(func(held: bool): explorer.hold_jump(held))
	explore_ui.add_child(jump_button)
	interaction_button = _day_button("Ansehen", _explore_interact, 110)
	interaction_button.name = "BuildInspectButton"
	explore_ui.add_child(interaction_button)
	walk_notice = _day_label("Links bewegen · rechts springen · Bauteile aus der Nähe ansehen", 16)
	walk_notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	walk_notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	walk_notice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	explore_ui.add_child(walk_notice)
	_layout_explore_controls()


func _layout_explore_controls() -> void:
	if not is_instance_valid(explore_ui):
		return
	var available := safe_ui.size
	var stick_side := clampf(minf(available.x * 0.29, available.y * 0.37), 112.0, 168.0)
	walk_stick.custom_minimum_size = Vector2.ONE * stick_side
	walk_stick.size = Vector2.ONE * stick_side
	walk_stick.position = Vector2(16, available.y - stick_side - 20)
	jump_button.size = Vector2(112, 112)
	jump_button.position = Vector2(available.x - 128, available.y - 132)
	interaction_button.size = Vector2(112, 52)
	interaction_button.position = Vector2(available.x - 128, available.y - 196)
	walk_notice.position = Vector2(16, 78)
	walk_notice.size = Vector2(maxf(120, available.x - 32), 48)


func _toggle_explore() -> void:
	if paused or not is_instance_valid(explorer):
		return
	_cancel_selection()
	exploring = not exploring
	if exploring:
		editor_camera = {"orbit": orbit, "tilt": tilt, "radius": radius, "focus": focus}
		walk_orbit = orbit
		explorer.start_at(_find_explorer_spawn())
		_update_walk_camera(1.0)
	else:
		explorer.set_active(false)
		orbit = float(editor_camera.get("orbit", START_ORBIT))
		tilt = float(editor_camera.get("tilt", START_TILT))
		radius = float(editor_camera.get("radius", START_RADIUS))
		focus = editor_camera.get("focus", START_FOCUS)
		_camera_update()
	for control in editor_controls:
		control.visible = not exploring
	preview.visible = not exploring
	explore_ui.visible = exploring
	walk_stick.set_enabled(exploring)
	jump_button.set_enabled(exploring)
	mode_button.text = "Weiterbauen" if exploring else "Mit Lumo laufen"
	_layout_explore_controls()
	_layout_goal_access.call_deferred()


func _find_explorer_spawn() -> Vector3:
	var occupied: Dictionary = model.occupied()
	var preferred := Vector3i(clampi(roundi(focus.x), -23, 23), 0, clampi(roundi(focus.z + 3), -23, 23))
	var nearest := Vector3(-24.2, 0.08, -24.2)
	var best_distance := INF
	for x in range(-23, 24):
		for z in range(-23, 24):
			if not STATE.ground_at(x, z):
				continue
			if occupied.has(Vector3i(x, 0, z)) or occupied.has(Vector3i(x, 1, z)):
				continue
			var distance := Vector3i(x, 0, z).distance_squared_to(preferred)
			if distance < best_distance:
				best_distance = distance
				nearest = Vector3(x + 0.5, 0.08, z + 0.5)
	# At the world limit there are always bank cells outside the placed volumes.
	return nearest


func _physics_process(delta: float) -> void:
	if not exploring or paused or not is_instance_valid(explorer):
		return
	var keyboard := Vector2(
		float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))
		- float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),
		float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))
		- float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP))
	)
	explorer.move_axis = (walk_stick.target + keyboard).limit_length(1.0)
	explorer.camera_yaw = walk_orbit
	explorer.advance_motion(delta)


func _update_walk_camera(delta: float) -> void:
	var at := explorer.position + Vector3.UP * 1.05
	var offset := Vector3(sin(walk_orbit) * cos(walk_tilt), sin(walk_tilt), cos(walk_orbit) * cos(walk_tilt)) * walk_camera_distance
	var target := at + offset
	var ray := PhysicsRayQueryParameters3D.create(at, target, 1, [explorer.get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(ray)
	if not hit.is_empty():
		target = hit.position + hit.normal * 0.22
	camera.position = camera.position.lerp(target, 1.0 - exp(-10.0 * delta))
	if camera.position.distance_squared_to(at) > 0.01:
		camera.look_at(at)


func _explore_input(event: InputEvent) -> void:
	if event is InputEventKey and not event.echo:
		if event.physical_keycode == KEY_SPACE or event.keycode == KEY_SPACE:
			explorer.hold_jump(event.pressed)
		if event.pressed and event.keycode == KEY_E:
			_explore_interact()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		pointer_id = 0 if event.pressed else -1
	elif event is InputEventMouseMotion and pointer_id == 0:
		walk_orbit -= event.relative.x * 0.006
		walk_tilt = clampf(walk_tilt + event.relative.y * 0.004, 0.15, 0.80)
	elif event is InputEventScreenTouch:
		if event.pressed and pointer_id < 0:
			pointer_id = event.index
		elif not event.pressed and pointer_id == event.index:
			pointer_id = -1
	elif event is InputEventScreenDrag and event.index == pointer_id:
		walk_orbit -= event.relative.x * 0.006
		walk_tilt = clampf(walk_tilt + event.relative.y * 0.004, 0.15, 0.80)


func _explore_interact() -> void:
	if not exploring or paused:
		return
	var nearest: Dictionary = {}
	var distance := 3.5
	for piece in model.pieces:
		var size: Vector3 = CATALOG.size_of(str(piece.part), int(piece.turn))
		var bounds := AABB(Vector3(piece.x, piece.y, piece.z), size)
		var point := Vector3(
			clampf(explorer.position.x, bounds.position.x, bounds.end.x),
			clampf(explorer.position.y + 0.7, bounds.position.y, bounds.end.y),
			clampf(explorer.position.z, bounds.position.z, bounds.end.z)
		)
		var candidate := point.distance_to(explorer.position + Vector3.UP * 0.7)
		if candidate < distance:
			distance = candidate
			nearest = piece
	if nearest.is_empty():
		walk_notice.text = "Gehe zu einem Bauteil und tippe auf Ansehen."
		return
	var item: Dictionary = CATALOG.part(str(nearest.part))
	var size: Vector3i = CATALOG.size_of(str(nearest.part), int(nearest.turn))
	walk_notice.text = "%s · %d breit, %d hoch, %d tief. Das hast du gebaut!" % [item.name, size.x, size.y, size.z]
	explorer.point_at_object()


func _place_feedback(cell: Vector3i) -> void:
	## Small sparkle + chime after a successful place. Does not change save or grid logic.
	var item: Dictionary = CATALOG.part(chosen)
	var size: Vector3 = item.size if not item.is_empty() else Vector3.ONE
	var at := Vector3(cell) + Vector3(size.x, size.y, size.z) * Vector3(0.5, 0.55, 0.5)
	var spark := CPUParticles3D.new()
	spark.name = "PlaceSparkle"
	spark.one_shot = true
	spark.explosiveness = 0.9
	spark.lifetime = 0.45
	spark.amount = 8 if LumoQuality.tier() == "low" else 16
	spark.emitting = false
	spark.direction = Vector3.UP
	spark.spread = 70.0
	spark.initial_velocity_min = 1.2
	spark.initial_velocity_max = 3.0
	spark.gravity = Vector3(0, -5, 0)
	spark.scale_amount_min = 0.05
	spark.scale_amount_max = 0.12
	var puff := SphereMesh.new()
	puff.radius = 0.12
	puff.height = 0.24
	puff.radial_segments = 6
	puff.rings = 3
	spark.mesh = puff
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("fff3a8")
	mat.emission_enabled = true
	mat.emission = Color("7ad8ff")
	mat.emission_energy_multiplier = 1.4
	spark.material_override = mat
	spark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	spark.position = at
	add_child(spark)
	spark.emitting = true
	var chime := AudioStreamPlayer.new()
	chime.stream = _place_tone()
	chime.volume_db = -10.0
	add_child(chime)
	chime.play()
	get_tree().create_timer(0.7).timeout.connect(
		func():
			if is_instance_valid(spark):
				spark.queue_free()
			if is_instance_valid(chime):
				chime.queue_free()
	)


func _place_tone() -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.stereo = false
	var frames := 2205
	var data := PackedByteArray()
	data.resize(frames * 2)
	for i in range(frames):
		var tm := float(i) / 22050.0
		var env := 1.0 - tm / 0.1
		var sample := (sin(TAU * 880.0 * tm) * 0.22 + sin(TAU * 1320.0 * tm) * 0.10) * env
		var value := int(clampf(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = value & 255
		data[i * 2 + 1] = (value >> 8) & 255
	stream.data = data
	return stream
