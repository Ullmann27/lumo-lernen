extends "res://scripts/tests/learning_world_capture.gd"

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("[HundredEqualsCapture] Actual renderer required")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(output)
	var world := load("res://scenes/learning/learning_world.tscn") as PackedScene
	var bridge = root.get_node("HostBridge")
	var original_options: Dictionary = bridge._options.duplicate(true)
	for size_value in [Vector2i(1280, 720), Vector2i(412, 915), Vector2i(2400, 1080)]:
		root.size = size_value
		bridge._options["displayDensity"] = 2.625 if size_value.x == 2400 else 1.0
		var game = world.instantiate()
		game.capture_options = {
			"learning": {"kind": "bridge_hundred", "a": 180, "b": 50},
			"reduceAnimations": true
		}
		root.add_child(game)
		await _settle()
		await _capture(game, "bridge_hundred-start-%dx%d" % [size_value.x, size_value.y], size_value)
		for index in range(game.activity.goal_count()):
			await _tap(game.main_button.get_global_rect().get_center())
			_check(game.activity.placed.size() == index + 1, "Actual child-facing touch moves one ten")
		_check(game.activity.is_complete(), "Actual hundred lesson completes through five real taps")
		await _capture(game, "bridge_hundred-complete-%dx%d" % [size_value.x, size_value.y], size_value)
		game.queue_free()
		await _settle()
	bridge._options = original_options
	if failures == 0 and captures == 6:
		print("[HundredEqualsCapture] PASS captures=6; actual production scene and real lesson taps")
	else:
		push_error("[HundredEqualsCapture] FAIL captures=%d failures=%d" % [captures, failures])
	quit(0 if failures == 0 and captures == 6 else 1)
