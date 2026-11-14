extends "res://scripts/tests/build_dialog_density_regression.gd"

func _run() -> void:
	Input.emulate_touch_from_mouse = true
	density = 1.0
	root.size = Vector2i(640, 320)
	root.get_node("HostBridge")._options = {"displayDensity":1.0,"soundEnabled":false,"reduceAnimations":true}
	root.get_node("SceneRouter").launch_options = {"childKey":"isolated-all-goal-dialogs-%d"%OS.get_process_id()}
	game = load("res://scenes/creative/build_world.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await _settle(16)
	for goal_id in ["house", "bridge", "tower", "garden", "castle", "village"]:
		game._select_goal(goal_id)
		await _settle()
		var expected: String = game.goal_label.text
		var before: Dictionary = game.model.to_data()
		var dialog := await _open("Aktuelles Bauziel")
		if dialog == null:
			continue
		var details: Label = dialog.find_child("BuildGoalDescription", true, false)
		_check(details != null and details.text == expected, "Complete original description: " + goal_id)
		var scroll := _scroll(dialog)
		var button := _button(dialog,"Mein Bauwerk testen")
		if not _pixels(scroll).grow(0.51).encloses(_pixels(button)):
			await _reveal_with_touch(scroll,button)
		_target(button,"Accessible original test action: " + goal_id)
		_target(_button(dialog,"Abbrechen"),"Fixed cancellation: " + goal_id)
		print("[AllGoalDialogs] ",goal_id," description=",expected.replace("\n"," / ")," test_pixels=",_pixels(button)," scroll_pixels=",_pixels(scroll))
		await _tap(_button(dialog,"Abbrechen"),true)
		_check(not is_instance_valid(dialog) and game.goal == goal_id and game.model.to_data() == before,
			"Real cancellation retains selected goal and project: " + goal_id)
	game.queue_free()
	await _settle()
	print("[AllGoalDialogs] ","PASS" if failures.is_empty() else "FAIL"," checks=",checks," failures=",failures)
	quit(0 if failures.is_empty() else 1)
