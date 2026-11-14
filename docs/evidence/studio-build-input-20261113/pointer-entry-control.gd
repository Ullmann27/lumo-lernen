extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func settle(frames: int = 6) -> void:
	for frame in range(frames):
		await process_frame
func run() -> void:
	Input.emulate_touch_from_mouse = true
	root.size = Vector2i(640, 320)
	root.position = Vector2i(80, 60)
	root.content_scale_size = Vector2i(720, 1280)
	root.gui_embed_subwindows = false
	for mode in ["fresh", "pointer-inside-window", "replacement", "pointer-on-target", "replacement-other-point"]:
		var button := Button.new()
		button.text = mode
		button.position = Vector2(20,20)
		button.size = Vector2(200,60)
		var received := [false]
		button.pressed.connect(func(): received[0] = true; print("[HoverProbe] PRESSED ", mode))
		button.mouse_entered.connect(func(): print("[HoverProbe] entered ",mode))
		button.mouse_exited.connect(func(): print("[HoverProbe] exited ",mode))
		button.button_down.connect(func(): print("[HoverProbe] DOWN ",mode," draw=",button.get_draw_mode()))
		button.button_up.connect(func(): print("[HoverProbe] UP ",mode," draw=",button.get_draw_mode()))
		button.gui_input.connect(func(event): print("[HoverProbe] GUI ",mode, " ",event))
		root.add_child(button)
		await settle()
		var point := root.get_screen_transform() * button.get_global_transform_with_canvas() * (button.size * 0.5)
		if mode == "replacement-other-point": point.x += 1.0
		print("[HoverProbe] before mode=",mode," point=",point," draw=",button.get_draw_mode()," mouse=",root.get_mouse_position()," hover=",root.gui_get_hovered_control())
		if mode == "pointer-inside-window":
			root.warp_mouse(Vector2(400,400))
			await settle()
		if mode == "pointer-on-target":
			root.warp_mouse(button.get_global_rect().get_center())
			await settle()
		if mode == "mouse-motion":
			var motion := InputEventMouseMotion.new()
			motion.position = point
			motion.relative = Vector2(1,0)
			Input.parse_input_event(motion)
			Input.flush_buffered_events()
			await settle()
		if mode == "touch-only-no-mouse-emulation": Input.emulate_mouse_from_touch = false
		for pressed in [true,false]:
			var event := InputEventScreenTouch.new()
			event.index = 4
			event.position = point
			event.pressed = pressed
			Input.parse_input_event(event)
			Input.flush_buffered_events()
			await process_frame
			print("[HoverProbe] after pressed=",pressed," draw=",button.get_draw_mode()," mouse=",root.get_mouse_position()," hover=",root.gui_get_hovered_control())
		await settle()
		print("[HoverProbe] result mode=",mode," received=",received[0])
		button.queue_free()
		await settle()
	quit(0)
