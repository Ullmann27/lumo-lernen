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
	for embedded in [true, false]:
		root.gui_embed_subwindows = embedded
		var button := Button.new()
		button.text = "Touch probe"
		button.position = Vector2(20, 20)
		button.size = Vector2(200, 60)
		var received := [false]
		button.pressed.connect(func(): received[0] = true)
		button.gui_input.connect(func(event): print("[RootTransform] GUI ", event))
		root.add_child(button)
		await settle()
		var point := root.get_screen_transform() * button.get_global_transform_with_canvas() * (button.size * 0.5)
		print("[RootTransform] embedded=", embedded, " position=", root.position, " size=", root.size, " viewport=",root.get_visible_rect()," scale=",root.content_scale_size," transform=",root.get_screen_transform()," point=",point," focus=",root.has_focus())
		for pressed in [true,false]:
			var event := InputEventScreenTouch.new()
			event.index = 4
			event.position = point
			event.pressed = pressed
			Input.parse_input_event(event)
			Input.flush_buffered_events()
			await process_frame
		await settle()
		print("[RootTransform] received=",received[0])
		if not embedded:
			await RenderingServer.frame_post_draw
			print("[RootTransform] png=",root.get_texture().get_image().save_png("/tmp/lumo-root-input-transform.png"))
		button.queue_free()
		await settle()
	quit(0)
