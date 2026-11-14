extends SceneTree
var game
var check_failures: Array[String] = []
func _initialize() -> void:
	call_deferred("run")
func settle(n: int = 6) -> void:
	for frame in range(n): await process_frame
func report(label: String) -> void:
	print("[ModalExit] ",JSON.stringify({"label":label,"embed":root.gui_embed_subwindows,"subwindows":root.get_embedded_subwindows().size(),"position":str(root.position),"surface":str(root.size),"view":str(root.get_visible_rect()),"screen_transform":str(root.get_screen_transform()),"mouse":str(root.get_mouse_position()),"focused":root.has_focus()}))
func touch(button: Button) -> void:
	var point := button.get_viewport().get_screen_transform() * button.get_global_transform_with_canvas() * (button.size * 0.5)
	for pressed in [true,false]:
		var event := InputEventScreenTouch.new()
		event.position = point
		event.index = 4
		event.pressed = pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await process_frame
	await settle()
func run() -> void:
	Input.emulate_touch_from_mouse = true
	root.size = Vector2i(640,320)
	root.position = Vector2i(80,60)
	for original in [true,false]:
		root.gui_embed_subwindows = original
		root.get_node("HostBridge")._options = {"displayDensity":1.0,"soundEnabled":false,"reduceAnimations":true}
		root.get_node("SceneRouter").launch_options = {"childKey":"isolated-modal-exit-%d-%s"%[OS.get_process_id(),original]}
		game = load("res://scenes/creative/build_world.tscn").instantiate()
		root.add_child(game)
		current_scene = game
		await settle(8)
		game._templates()
		await settle(6)
		var modal: Window = game.choice_window
		modal.tree_exiting.connect(func(): report("modal tree_exiting"))
		modal.tree_exited.connect(func(): report("modal tree_exited"))
		game.tree_exiting.connect(func(): report("game tree_exiting"))
		game.tree_exited.connect(func(): report("game tree_exited"))
		report("before queue_free")
		game.queue_free()
		await settle(12)
		report("after scene free original=%s"%original)
		if root.gui_embed_subwindows != original or not root.get_embedded_subwindows().is_empty(): check_failures.append("restore")
		var button := Button.new()
		button.position = Vector2(20,20)
		button.size = Vector2(200,60)
		button.text = "Following scene"
		var received := [false]
		button.pressed.connect(func(): received[0] = true)
		root.add_child(button)
		await settle()
		await touch(button)
		print("[ModalExit] before desktop pointer precondition pressed=",received[0])
		received[0] = false
		root.warp_mouse(root.get_visible_rect().get_center())
		await settle(6)
		report("desktop pointer center before actual touch")
		await touch(button)
		print("[ModalExit] after desktop pointer precondition pressed=",received[0])
		if not received[0]: check_failures.append("following scene actual touch")
		button.queue_free()
		await settle()
	print("[ModalExit] ", "PASS" if check_failures.is_empty() else "FAIL", " ",check_failures)
	quit(0 if check_failures.is_empty() else 1)
