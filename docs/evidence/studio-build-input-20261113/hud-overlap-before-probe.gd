extends SceneTree
func _initialize() -> void: call_deferred("run")
func settle(n: int = 8) -> void:
	for frame in range(n): await process_frame
func find_button(node: Node, text: String) -> Button:
	if node is Button and node.text == text: return node
	for child in node.get_children():
		var found := find_button(child,text)
		if found != null: return found
	return null
func physical(control: Control) -> Rect2:
	var transform := control.get_viewport().get_screen_transform() * control.get_global_transform_with_canvas()
	return Rect2(transform * Vector2.ZERO,transform.basis_xform(control.size))
func tap(point: Vector2) -> void:
	for pressed in [true,false]:
		var event := InputEventScreenTouch.new()
		event.index=4;event.position=point;event.pressed=pressed
		Input.parse_input_event(event);Input.flush_buffered_events()
		await process_frame
	await settle()
func run() -> void:
	Input.emulate_touch_from_mouse=true
	for profile in [[Vector2i(2400,1080),2.625],[Vector2i(640,360),1.0],[Vector2i(640,320),1.0],[Vector2i(2176,1812),2.25],[Vector2i(1080,2400),2.625]]:
		root.size=profile[0]
		root.get_node("HostBridge")._options={"displayDensity":profile[1],"soundEnabled":false,"reduceAnimations":true}
		root.get_node("SceneRouter").launch_options={"childKey":"isolated-hud-%d-%s"%[OS.get_process_id(),profile[0]]}
		var game=load("res://scenes/creative/build_world.tscn").instantiate()
		root.add_child(game);current_scene=game
		await settle(16)
		var target:=find_button(game,"Mein Bauwerk testen")
		var target_rect:=physical(target)
		var events: Array[String]=[]
		target.pressed.connect(func():events.append("Mein Bauwerk testen"))
		var intersections: Array=[]
		for caption in ["Bauen","Dächer","Wege","Natur","Deko"]:
			var button:=find_button(game,caption)
			button.pressed.connect(func():events.append(caption))
			if target_rect.intersects(physical(button)): intersections.append({"caption":caption,"rect":str(physical(button)),"overlap":str(target_rect.intersection(physical(button)))})
		await tap(target_rect.get_center())
		print("[HUDOverlap] ",JSON.stringify({"surface":str(profile[0]),"density":profile[1],"test_rect_pixels":str(target_rect),"test_rect_dp":str(Rect2(target_rect.position/profile[1],target_rect.size/profile[1])),"intersections":intersections,"center_tap_signals":events,"goal_text_pixels":str(physical(game.goal_label)),"status_pixels":str(physical(game.status))}))
		game.queue_free();await settle()
	quit(0)
