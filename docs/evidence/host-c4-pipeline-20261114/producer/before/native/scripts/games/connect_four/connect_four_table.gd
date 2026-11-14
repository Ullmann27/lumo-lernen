extends Node3D
## Production view of the existing Dart ConnectFourEngine. This renderer has no
## bot, winning-rule evaluator or reward API. Only acknowledged legal history
## drives geometry. The host owns the round and its profile-bound persistence.
const LUMO = preload("res://scripts/characters/lumo/lumo_rigged_actor.gd")
const CYAN := Color("53ddfd")
const GOLD := Color("ffd166")
const NAVY := Color("123555")
const SPACING := 0.86
const ROWS := 6
const COLUMNS := 7
const LAYOUT_OBSERVATION := "user://connect_four_layout_v1.json"
var _host: Object
var _token := ""
var _state: Dictionary = {}
var _sequence := 0
var _pending := 0
var _poll := 0.0
var _closed := false
var _previous: Dictionary
var _seen_history: Array = []
var _round_id := ""
var _drop_queue: Array[Dictionary] = []
var _dropping := false
var _drop_tween: Tween
var _discs: Array[MeshInstance3D] = []
var _disc_roots: Node3D
var _win_root: Node3D
var camera: Camera3D
var fox
var ui: Control
var safe: Control
var header: PanelContainer
var footer: PanelContainer
var overlay: PanelContainer
var status: Label
var detail: Label
var title: Label
var pause_button: Button
var return_button: Button
var resume_button: Button
var restart_button: Button
var mode_button: Button
var level_buttons: Array[Button] = []
var column_buttons: Array[Button] = []
var column_scroll: ScrollContainer
var _safe_rect := Rect2()
var _board_rect := Rect2()
var _density := 1.0
var _theme: Theme
var _disc_materials: Array[StandardMaterial3D] = []
var _layout_dirty := true
var _layout_frames := 2
var _layout_sequence := 0
var _layout_retry := 0


func _ready() -> void:
	var window := get_window()
	_previous = {"scale": window.content_scale_size, "mode": window.content_scale_mode,
		"quit": get_tree().quit_on_go_back, "accept": get_tree().auto_accept_quit,
		"orientation": DisplayServer.screen_get_orientation()}
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_tree().quit_on_go_back = false
	get_tree().auto_accept_quit = false
	if OS.has_feature("mobile"):
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR)
	if _host == null and Engine.has_singleton("LumoHost"):
		_host = Engine.get_singleton("LumoHost")
	_token = str(HostBridge.launch_options().get("connectFourToken", ""))
	_build_room()
	_build_ui()
	window.size_changed.connect(_layout)
	MobileRuntime.safe_area_changed.connect(_layout)
	_layout()
	_poll_state()


func _exit_tree() -> void:
	_closed = true
	DirAccess.remove_absolute(LAYOUT_OBSERVATION)
	DirAccess.remove_absolute(LAYOUT_OBSERVATION + ".tmp")
	if is_instance_valid(_drop_tween):
		_drop_tween.kill()
	if MobileRuntime.safe_area_changed.is_connected(_layout):
		MobileRuntime.safe_area_changed.disconnect(_layout)
	if get_window().size_changed.is_connected(_layout):
		get_window().size_changed.disconnect(_layout)
	if not _previous.is_empty():
		get_window().content_scale_size = _previous.scale
		get_window().content_scale_mode = _previous.mode
		get_tree().quit_on_go_back = _previous.quit
		get_tree().auto_accept_quit = _previous.accept
		if OS.has_feature("mobile"):
			DisplayServer.screen_set_orientation(_previous.orientation)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST or what == NOTIFICATION_WM_CLOSE_REQUEST:
		if not _state.is_empty():
			_send("pause")


func _process(delta: float) -> void:
	_poll += delta
	if _poll >= 0.08:
		_poll = 0.0
		_poll_state()
	_publish_layout_observation()


func _poll_state() -> void:
	if _closed or not is_instance_valid(_host):
		return
	var raw: Variant = JSON.parse_string(str(_host.call("getConnectFourState")))
	if raw is Dictionary:
		apply_state(raw)


func _integer(value: Variant, lo: int, hi: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floor(float(value)) and float(value) >= lo and float(value) <= hi


func _valid_state(value: Dictionary) -> bool:
	if value.get("schema") != 1 or value.get("game") != "connect_four" or value.get("token") != _token or _token.length() != 32:
		return false
	if not value.get("roundId") is String or str(value.roundId).length() != 32 or not value.get("owner") is String or str(value.owner).length() != 64:
		return false
	for key in ["revision", "recordRevision"]:
		if not _integer(value.get(key), 1, 1000000000):
			return false
	for key in ["ack", "rejected"]:
		if not _integer(value.get(key), 0, 1000000000):
			return false
	for key in ["paused", "canDrop", "exit", "reduceMotion", "twoPlayers", "rewarded"]:
		if not value.get(key) is bool:
			return false
	if value.get("phase") not in ["playing", "won", "draw"] or value.get("level") not in ["leicht", "mittel", "schlau"] or not _integer(value.get("turn"), 1, 2):
		return false
	if not value.get("board") is Array or value.board.size() != 42 or not value.get("columns") is Array or value.columns.size() > 42:
		return false
	for cell in value.board:
		if not _integer(cell, 0, 2):
			return false
	for column in value.columns:
		if not _integer(column, 0, 6):
			return false
	if not value.get("validColumns") is Array or not value.get("winningLine") is Array or value.winningLine.size() > 7:
		return false
	for column in value.validColumns:
		if not _integer(column, 0, 6):
			return false
	for point in value.winningLine:
		if not point is Array or point.size() != 2 or not _integer(point[0], 0, 5) or not _integer(point[1], 0, 6):
			return false
	return true


func apply_state(value: Dictionary) -> bool:
	if not _valid_state(value):
		return false
	if not _state.is_empty() and int(value.revision) < int(_state.revision):
		return false
	if value == _state:
		return true
	if not _state.is_empty() and value.owner != _state.owner:
		return false
	_state = value.duplicate(true)
	_mark_layout_changed()
	_sequence = maxi(_sequence, maxi(int(value.ack), int(value.rejected)))
	if _pending <= maxi(int(value.ack), int(value.rejected)):
		_pending = 0
	_sync_geometry()
	if is_instance_valid(_drop_tween) and _dropping:
		if bool(value.paused):
			_drop_tween.pause()
		else:
			_drop_tween.play()
	_update_ui()
	if value.exit and _pending == 0:
		# The Dart controller has durably acknowledged this exact session exit.
		# Do not route unrelated pending Kart rewards through the C4 authority.
		_closed = HostBridge.durable_ack(_host.call("returnToApp", "games", "")) if is_instance_valid(_host) else false
	return true


func _send(action: String, extras: Dictionary = {}) -> bool:
	if _closed or _pending > 0 or _state.is_empty() or not is_instance_valid(_host) or not MobileRuntime.safe_area_is_ready():
		return false
	if action == "drop" and (not bool(_state.canDrop) or _dropping or not _drop_queue.is_empty()):
		return false
	_sequence += 1
	var request := {"token": _token, "roundId": _state.roundId,
		"revision": int(_state.revision), "sequence": _sequence, "action": action}
	request.merge(extras)
	if not HostBridge.durable_ack(_host.call("submitConnectFourAction", JSON.stringify(request))):
		status.text = "Eingabe noch nicht bestätigt. Bitte erneut versuchen."
		return false
	_pending = _sequence
	_mark_layout_changed()
	_update_ui()
	return true


func _cell(row: int, column: int) -> Vector3:
	return Vector3((column - 3) * SPACING, (5 - row) * SPACING + 0.85, 0)


func _sync_geometry() -> void:
	var history: Array = _state.columns
	var same_prefix: bool = _round_id == _state.roundId and history.size() >= _seen_history.size()
	if same_prefix:
		for i in range(_seen_history.size()):
			if int(history[i]) != int(_seen_history[i]):
				same_prefix = false
				break
	if not same_prefix:
		if is_instance_valid(_drop_tween):
			_drop_tween.kill()
		_dropping = false
		_drop_queue.clear()
		for disc in _discs:
			disc.queue_free()
		_discs.clear()
		_seen_history.clear()
		_round_id = _state.roundId
		# Reopening is a restored board, not forty-two new falling turns.
		for row in range(ROWS):
			for column in range(COLUMNS):
				var piece := int(_state.board[row * COLUMNS + column])
				if piece != 0:
					var disc := _disc(piece)
					disc.position = _cell(row, column)
		_seen_history = history.duplicate()
	else:
		for i in range(_seen_history.size(), history.size()):
			var column := int(history[i])
			var earlier := 0
			for n in range(i):
				if int(history[n]) == column:
					earlier += 1
			var row := 5 - earlier
			if row < 0 or int(_state.board[row * COLUMNS + column]) != (i % 2) + 1:
				return
			_drop_queue.append({"row": row, "column": column, "piece": (i % 2) + 1})
		_seen_history = history.duplicate()
	_start_drop()
	_update_win()


func _start_drop() -> void:
	if _dropping or _drop_queue.is_empty() or bool(_state.get("paused", true)):
		return
	_dropping = true
	var next: Dictionary = _drop_queue.pop_front()
	var disc := _disc(int(next.piece))
	var target := _cell(int(next.row), int(next.column))
	disc.position = Vector3(target.x, 6.3, 0)
	_drop_tween = create_tween()
	var duration := 0.06 if bool(_state.reduceMotion) else 0.25 + float(next.row) * 0.04
	_drop_tween.tween_property(disc, "position", target, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if not bool(_state.reduceMotion):
		_drop_tween.tween_property(disc, "position:y", target.y + 0.10, 0.07).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_drop_tween.tween_property(disc, "position:y", target.y, 0.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_drop_tween.tween_callback(_drop_finished)
	_update_ui()


func _drop_finished() -> void:
	_dropping = false
	_mark_layout_changed()
	_start_drop()
	_update_win()
	_update_ui()


func _disc(piece: int) -> MeshInstance3D:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.34
	cylinder.bottom_radius = 0.34
	cylinder.height = 0.22
	cylinder.radial_segments = 24
	var mesh := MeshInstance3D.new()
	mesh.mesh = cylinder
	mesh.rotation.x = PI / 2
	mesh.material_override = _disc_materials[piece - 1]
	_disc_roots.add_child(mesh)
	_discs.append(mesh)
	return mesh


func _update_win() -> void:
	for node in _win_root.get_children():
		node.queue_free()
	if _state.is_empty() or _state.phase != "won" or _dropping or not _drop_queue.is_empty():
		return
	var material := _material(Color("fff4b5"), 0.28, 0.1, 0.5)
	for point in _state.winningLine:
		var torus := TorusMesh.new()
		torus.inner_radius = 0.34
		torus.outer_radius = 0.395
		torus.rings = 24
		torus.ring_segments = 8
		var ring := MeshInstance3D.new()
		ring.mesh = torus
		ring.material_override = material
		ring.position = _cell(int(point[0]), int(point[1])) + Vector3(0, 0, 0.18)
		ring.rotation.x = PI / 2
		_win_root.add_child(ring)
	if is_instance_valid(fox) and fox.is_usable():
		fox.play_behavior("celebrate")


func _material(color: Color, roughness: float = 0.6, metallic: float = 0.0, glow: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	if glow > 0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = glow
	return material


func _box(parent: Node3D, size: Vector3, at: Vector3, material: Material) -> MeshInstance3D:
	var box := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	box.mesh = mesh
	box.material_override = material
	box.position = at
	parent.add_child(box)
	return box


func _ring_board() -> ArrayMesh:
	# One indexed geometry surface: square cell corners, genuine circular
	# front/back holes and cylindrical interior walls. No alpha-cutout texture.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Keep the flat front and the cylindrical hole walls separate at their rim.
	st.set_smooth_group(-1)
	var half := SPACING * 0.5
	var radius := 0.37
	for row in range(ROWS):
		for column in range(COLUMNS):
			var center := _cell(row, column)
			for segment in range(32):
				var a := TAU * segment / 32.0
				var b := TAU * (segment + 1) / 32.0
				var da := Vector2(cos(a), sin(a))
				var db := Vector2(cos(b), sin(b))
				var oa := da * (half / maxf(absf(da.x), absf(da.y)))
				var ob := db * (half / maxf(absf(db.x), absf(db.y)))
				var ia := da * radius
				var ib := db * radius
				for z in [-0.17, 0.17]:
					var points := [Vector3(ia.x, ia.y, z), Vector3(oa.x, oa.y, z),
						Vector3(ob.x, ob.y, z), Vector3(ib.x, ib.y, z)]
					_quad(st, points, center, z > 0)
				_quad(st, [Vector3(ia.x, ia.y, -0.17), Vector3(ia.x, ia.y, 0.17),
					Vector3(ib.x, ib.y, 0.17), Vector3(ib.x, ib.y, -0.17)], center, true)
	st.generate_normals()
	st.index()
	return st.commit()


func _quad(st: SurfaceTool, points: Array, center: Vector3, reverse: bool) -> void:
	for index in ([0, 2, 1, 0, 3, 2] if reverse else [0, 1, 2, 0, 2, 3]):
		st.add_vertex(points[index] + center)


func _build_room() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("091b34")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("86b9d5")
	environment.ambient_light_energy = 0.42
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = environment
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-28, -28, 0)
	sun.light_color = Color("ffedce")
	sun.light_energy = 0.85
	sun.shadow_enabled = true
	add_child(sun)
	var rim := OmniLight3D.new()
	rim.position = Vector3(-3, 5, 4)
	rim.omni_range = 14
	rim.light_energy = 0.28
	rim.light_color = CYAN
	add_child(rim)
	var wood := _material(Color("74544b"), 0.72)
	_box(self, Vector3(20, 0.2, 14), Vector3(0, -0.25, -1), _material(Color("213d54")))
	_box(self, Vector3(10, 0.22, 3.4), Vector3(0, 0.1, -0.35), wood)
	_box(self, Vector3(7, 0.20, 1.25), Vector3(0, 0.40, 0), _material(Color("19334c"), 0.38, 0.1))
	var frame := _material(NAVY, 0.68, 0.04)
	var board := MeshInstance3D.new()
	board.name = "PerforatedBoard"
	board.mesh = _ring_board()
	board.material_override = frame
	add_child(board)
	for side in [-1, 1]:
		_box(self, Vector3(0.18, 5.45, 0.48), Vector3(side * 3.14, 3.0, 0), frame)
		_box(self, Vector3(0.45, 0.36, 1.0), Vector3(side * 3.14, 0.57, 0), _material(GOLD, 0.35, 0.2))
	_box(self, Vector3(6.45, 0.14, 0.48), Vector3(0, 5.65, 0), frame)
	_disc_materials = [_material(CYAN, 0.54, 0.02), _material(GOLD, 0.54, 0.02)]
	_disc_roots = Node3D.new()
	_disc_roots.name = "AcknowledgedDiscs"
	add_child(_disc_roots)
	_win_root = Node3D.new()
	_win_root.name = "AuthoritativeWinLine"
	add_child(_win_root)
	fox = LUMO.new()
	fox.position = Vector3(4.5, 0.22, -0.15)
	fox.scale = Vector3.ONE * 1.3
	fox.rotation.y = -0.4
	add_child(fox)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.current = true
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.position = Vector3(0, 4.15, 16)
	add_child(camera)
	camera.look_at(Vector3(0, 3, 0))


func _panel(color: Color, radius: int = 16) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


func _button(caption: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(52, 52)
	button.pressed.connect(callback)
	return button


func _label(caption: String, size: int = 20) -> Label:
	var label := Label.new()
	label.text = caption
	label.add_theme_font_size_override("font_size", size)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label


func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	ui = Control.new()
	ui.name = "ConnectFourUI"
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(ui)
	_theme = Theme.new()
	_theme.default_font_size = 18
	_theme.set_color("font_color", "Button", Color("f2f7ff"))
	_theme.set_stylebox("normal", "Button", _panel(Color("204865"), 11))
	_theme.set_stylebox("hover", "Button", _panel(Color("2b6281"), 11))
	_theme.set_stylebox("pressed", "Button", _panel(Color("376a84"), 11))
	_theme.set_stylebox("disabled", "Button", _panel(Color("1a3049"), 11))
	ui.theme = _theme
	safe = Control.new()
	safe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(safe)
	header = PanelContainer.new()
	header.add_theme_stylebox_override("panel", _panel(Color("0d2844ec")))
	safe.add_child(header)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	header.add_child(top)
	return_button = _button("Zurück", func(): _send("exit"))
	return_button.name = "BackToFlutter"
	top.add_child(return_button)
	title = _label("Vier gewinnt", 22)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	pause_button = _button("Pause", func(): _send("pause"))
	pause_button.name = "Pause"
	top.add_child(pause_button)
	footer = PanelContainer.new()
	footer.add_theme_stylebox_override("panel", _panel(Color("0d2844f2")))
	safe.add_child(footer)
	var lower := VBoxContainer.new()
	lower.add_theme_constant_override("separation", 4)
	footer.add_child(lower)
	status = _label("Deine gespeicherte Runde wird geladen …", 18)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.custom_minimum_size.y = 25
	lower.add_child(status)
	column_scroll = ScrollContainer.new()
	column_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	column_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column_scroll.custom_minimum_size.y = 58
	column_scroll.get_h_scroll_bar().value_changed.connect(func(_value): _mark_layout_changed())
	lower.add_child(column_scroll)
	var columns := HBoxContainer.new()
	columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 3)
	column_scroll.add_child(columns)
	for column in range(COLUMNS):
		var button := _button(str(column + 1) + " ↓", _send.bind("drop", {"column": column}))
		button.custom_minimum_size = Vector2(48, 52)
		button.add_theme_font_size_override("font_size", 17)
		for variant in ["normal", "hover", "pressed", "disabled"]:
			var style: StyleBoxFlat = _theme.get_stylebox(variant, "Button").duplicate()
			style.content_margin_left = 4
			style.content_margin_right = 4
			button.add_theme_stylebox_override(variant, style)
		button.mouse_filter = Control.MOUSE_FILTER_PASS
		button.name = "Column%d" % column
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.tooltip_text = "Stein in Spalte %d werfen" % (column + 1)
		columns.add_child(button)
		column_buttons.append(button)
	overlay = PanelContainer.new()
	overlay.name = "PauseAndResult"
	overlay.add_theme_stylebox_override("panel", _panel(Color("112b46fa")))
	safe.add_child(overlay)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.get_v_scroll_bar().value_changed.connect(func(_value): _mark_layout_changed())
	overlay.add_child(scroll)
	var menu := VBoxContainer.new()
	menu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu.add_theme_constant_override("separation", 8)
	scroll.add_child(menu)
	detail = _label("", 19)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu.add_child(detail)
	resume_button = _button("Fortsetzen", func(): _send("resume"))
	menu.add_child(resume_button)
	restart_button = _button("Neue Runde", func(): _send("restart"))
	menu.add_child(restart_button)
	mode_button = _button("Zu zweit spielen", func(): _send("mode", {"twoPlayers": not bool(_state.get("twoPlayers", false))}))
	menu.add_child(mode_button)
	var levels := HBoxContainer.new()
	levels.add_theme_constant_override("separation", 4)
	menu.add_child(levels)
	for level in ["leicht", "mittel", "schlau"]:
		var button := _button(level.capitalize(), _send.bind("level", {"level": level}))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		levels.add_child(button)
		level_buttons.append(button)
	# Let ScrollContainer receive a drag begun on any real menu button.
	for button in [resume_button, restart_button, mode_button] + level_buttons:
		button.mouse_filter = Control.MOUSE_FILTER_PASS
	overlay.visible = false
	_update_ui()


func _layout() -> void:
	if not is_instance_valid(ui):
		return
	_mark_layout_changed()
	_density = MobileRuntime.get_ui_density()
	get_window().content_scale_size = Vector2i(Vector2(get_window().size) / _density)
	var logical := Vector2(get_window().content_scale_size)
	var insets := Rect2()
	if OS.has_feature("mobile") or MobileRuntime.requires_safe_area_observation():
		insets = MobileRuntime.get_safe_area_insets()
	var factor := logical / Vector2(get_window().size)
	_safe_rect = Rect2(insets.position * factor, logical - (insets.position + insets.size) * factor)
	safe.position = _safe_rect.position
	safe.size = _safe_rect.size
	safe.visible = MobileRuntime.safe_area_is_ready()
	var width := safe.size.x
	header.position = Vector2(8, 6)
	header.size = Vector2(width - 16, 68)
	title.add_theme_font_size_override("font_size", 17 if width < 400 else 22)
	footer.position = Vector2(8, safe.size.y - 118)
	footer.size = Vector2(width - 16, 110)
	_board_rect = Rect2(Vector2(8, 82) + safe.position, Vector2(width - 16, maxf(80, safe.size.y - 208)))
	var board_width := 7.0
	var board_height := 6.4
	var visible := logical
	var world_per_pixel := maxf(board_width / maxf(1, _board_rect.size.x), board_height / maxf(1, _board_rect.size.y))
	camera.size = world_per_pixel * visible.y
	var shift := (_board_rect.get_center() - visible * 0.5) * world_per_pixel
	# A small actual tilt reveals board/disc thickness; touch targets stay in UI.
	var tilt := Vector3(-0.10, 0.10, 0)
	camera.rotation = tilt
	camera.position = Vector3(0, 3.10, 0) + Basis.from_euler(tilt) * Vector3(-shift.x, shift.y, 16)
	fox.visible = width >= 700
	overlay.position = Vector2(10, 78)
	overlay.size = Vector2(width - 20, maxf(96, safe.size.y - 202))
	_update_ui()


func _update_ui() -> void:
	if not is_instance_valid(status):
		return
	var ready := not _state.is_empty()
	var paused := bool(_state.get("paused", true))
	var finished: bool = ready and _state.phase != "playing"
	var waiting := _pending > 0
	pause_button.disabled = not ready or waiting or paused
	return_button.disabled = not ready or waiting
	for column in range(column_buttons.size()):
		column_buttons[column].disabled = not ready or waiting or paused or not bool(_state.get("canDrop", false)) or _dropping or not _drop_queue.is_empty() or not _state.get("validColumns", []).any(func(value): return int(value) == column)
	if not ready:
		return
	var turn := "Cyan" if int(_state.turn) == 1 else ("Gold" if _state.twoPlayers else "Lumo")
	status.text = "Bitte kurz warten …" if waiting else ("Gespeichert · " + turn + " ist dran")
	if _state.get("error") != null:
		status.text = str(_state.error)
	elif finished:
		status.text = "Unentschieden" if _state.phase == "draw" else turn + " gewinnt!"
	elif _dropping or not _drop_queue.is_empty():
		status.text = "Der Stein fällt in seine Spalte …"
	elif not bool(_state.canDrop) and not paused:
		status.text = "Lumo denkt nach …" if not _state.twoPlayers and int(_state.turn) == 2 else "Der nächste Zug wird bereit …"
	overlay.visible = paused
	pause_button.text = "Menü" if finished else "Pause"
	detail.text = "Spiel pausiert. Deine Runde bleibt gespeichert." if paused and not finished else status.text + "\nVier in einer Reihe!" if _state.phase == "won" else "Alle Felder sind belegt. Gut gespielt!"
	resume_button.visible = true
	resume_button.text = "Speichern wiederholen" if finished and not bool(_state.rewarded) else "Brett ansehen" if finished else "Fortsetzen"
	resume_button.disabled = waiting
	restart_button.disabled = waiting or (finished and not bool(_state.rewarded))
	mode_button.disabled = waiting or (finished and not bool(_state.rewarded))
	mode_button.text = "Gegen Lumo spielen" if _state.twoPlayers else "Zu zweit spielen"
	for i in range(level_buttons.size()):
		level_buttons[i].visible = not bool(_state.twoPlayers)
		level_buttons[i].disabled = waiting or _state.level == ["leicht", "mittel", "schlau"][i]
	if is_instance_valid(fox):
		fox.reduced_motion = bool(_state.reduceMotion)
		fox.suspended = paused


func _mark_layout_changed() -> void:
	# Only an ephemeral observation is removed. No saved round is read or written.
	DirAccess.remove_absolute(LAYOUT_OBSERVATION)
	_layout_dirty = true
	_layout_frames = 2


func _v2(vector: Vector2) -> Array:
	return [vector.x, vector.y]


func _v3(vector: Vector3) -> Array:
	return [vector.x, vector.y, vector.z]


func _r4(rect: Rect2) -> Array:
	return [rect.position.x, rect.position.y, rect.size.x, rect.size.y]


func _control_pixels(control: Control) -> Rect2:
	var factor := Vector2(get_window().size) / get_viewport().get_visible_rect().size
	var transform := control.get_global_transform_with_canvas()
	return Rect2((transform * Vector2.ZERO) * factor, control.size * transform.get_scale() * factor)


func _button_observation(button: Button, id: String) -> Dictionary:
	var rect := _control_pixels(button)
	var hit_rect := rect.intersection(Rect2(Vector2.ZERO, Vector2(get_window().size)))
	var clipped := false
	var parent := button.get_parent()
	while parent != null:
		if parent is Control and parent.clip_contents:
			var clip := _control_pixels(parent)
			hit_rect = hit_rect.intersection(clip)
			if not clip.grow(0.1).encloses(rect):
				clipped = true
		parent = parent.get_parent()
	return {"id":id,"text":button.text,"rect_px":_r4(rect),"hit_rect_px":_r4(hit_rect),
		"visible":button.is_visible_in_tree(),"enabled":not button.disabled,"clipped":clipped}


func _publish_layout_observation() -> void:
	if not _layout_dirty or _closed or _state.is_empty() or _pending > 0 or not safe.is_visible_in_tree():
		return
	if _layout_frames > 0:
		_layout_frames -= 1
		return
	if _dropping or not _drop_queue.is_empty() or Time.get_ticks_msec() < _layout_retry:
		return
	var buttons := [_button_observation(return_button,"back"),_button_observation(pause_button,"pause"),
		_button_observation(resume_button,"resume"),_button_observation(restart_button,"restart"),_button_observation(mode_button,"mode")]
	for i in range(COLUMNS):
		buttons.append(_button_observation(column_buttons[i],"column_%d" % i))
	for i in range(level_buttons.size()):
		buttons.append(_button_observation(level_buttons[i],"level_" + ["leicht","mittel","schlau"][i]))
	var observed := MobileRuntime.get_safe_area_observation()
	var android := {}
	for key in ["view_size","decor_size"]:
		if observed.has(key):
			android[key] = _v2(observed[key])
	for key in ["render_rect","system_insets","insets"]:
		if observed.has(key):
			android[key] = _r4(observed[key])
	var factor := Vector2(get_window().size) / get_viewport().get_visible_rect().size
	var cells := []
	for row in range(ROWS):
		for column in range(COLUMNS):
			var point := _cell(row,column)
			var quad := []
			for corner in [Vector3(-0.34,0.34,0.11),Vector3(0.34,0.34,0.11),Vector3(0.34,-0.34,0.11),Vector3(-0.34,-0.34,0.11)]:
				quad.append(_v2(camera.unproject_position(point+corner)*factor))
			cells.append({"row":row,"column":column,"piece":int(_state.board[row*COLUMNS+column]),
				"world_center":_v3(point),"world_front_center":_v3(point+Vector3(0,0,0.11)),"disc_radius":0.34,
				"center_px":_v2(camera.unproject_position(point)*factor),"disc_quad":quad})
	_layout_sequence += 1
	var snapshot := {"schema":1,"game":"connect_four","layout_sequence":int(_layout_sequence),
		"ticks_msec":int(Time.get_ticks_msec()),"pid":int(OS.get_process_id()),"settled":true,
		"token":_token,"owner":str(_state.owner),"roundId":str(_state.roundId),
		"revision":int(_state.revision),"recordRevision":int(_state.recordRevision),
		"ack":int(_state.ack),"rejected":int(_state.rejected),"pending":int(_pending),
		"paused":bool(_state.paused),"canDrop":bool(_state.canDrop),"turn":int(_state.turn),
		"phase":str(_state.phase),"twoPlayers":bool(_state.twoPlayers),"level":str(_state.level),
		"columns":_state.columns.map(func(value): return int(value)),"rewarded":bool(_state.rewarded),
		"board":_state.board.map(func(value): return int(value)),
		"winningLine":_state.winningLine.map(func(point): return [int(point[0]),int(point[1])]),
		"ui_visible":safe.is_visible_in_tree(),"density":_density,
		"coordinate_space":"godot_window_px; map through android_observation.render_rect for decor screenshots",
		"window_px":_v2(Vector2(get_window().size)),"viewport_px":_v2(get_viewport().get_visible_rect().size),
		"safe_rect":_r4(Rect2(_safe_rect.position*factor,_safe_rect.size*factor)),
		"observation_source":"android_window_insets" if OS.has_feature("android") and not observed.is_empty() else "platform_fixture" if MobileRuntime.requires_safe_area_observation() else "platform_safe_area",
		"android_observation":android,"buttons":buttons,"cells":cells,
		"camera":{"projection":"orthogonal","size":camera.size,"keep_aspect":int(camera.keep_aspect),
			"origin":_v3(camera.global_position),"basis":[_v3(camera.global_basis.x),_v3(camera.global_basis.y),_v3(camera.global_basis.z)]},
		"geometry":{"spacing":SPACING,"rows":ROWS,"columns":COLUMNS,"first_row_y":5*SPACING+0.85,"disc_radius":0.34,"disc_depth":0.22}}
	var file := FileAccess.open(LAYOUT_OBSERVATION + ".tmp", FileAccess.WRITE)
	if file == null:
		_layout_retry = Time.get_ticks_msec() + 2000
		return
	file.store_string(JSON.stringify(snapshot))
	file.flush()
	var error := file.get_error()
	file.close()
	if error == OK:
		error = DirAccess.rename_absolute(LAYOUT_OBSERVATION + ".tmp", LAYOUT_OBSERVATION)
	if error == OK:
		_layout_dirty = false
	else:
		_layout_retry = Time.get_ticks_msec() + 2000
