extends SceneTree

var failures: int = 0

func _initialize() -> void:
	_run.call_deferred()

func _check(condition: bool, operation: String) -> void:
	print("[Kart-PCK] ", "PASS" if condition else "FAIL", " ", operation)
	failures += int(not condition)

func _run() -> void:
	var roster = load("res://scripts/games/lumo_opponent_roster.gd")
	_check(roster != null and roster.ready_for_race(), "packaged race roster")
	for id in ["frog", "rabbit"]:
		for level in range(3):
			var path: String = roster.racing_model_path(id, level)
			var scene := load(path) as PackedScene
			_check(scene != null, "%s imported LOD %d" % [id, level])
			if scene != null:
				var actor := scene.instantiate()
				var players := actor.find_children("*", "AnimationPlayer", true, false)
				_check(players.size() == 1 and players[0].has_animation("kart_seated"), "%s LOD %d seated animation" % [id, level])
				actor.free()
	var track := load("res://scenes/games/kart_island.tscn") as PackedScene
	_check(track != null, "normal race scene")
	if track != null:
		var game = track.instantiate()
		root.add_child(game)
		await process_frame
		game._start_selected_race({"mode":"race", "track":"jungle_emerald_3600", "driver":"fox", "kart":"comet", "difficulty":"gemuetlich"})
		var field: Dictionary = {}
		for rival in game.opponents:
			field[rival.animal] = is_instance_valid(rival.production_driver)
		_check(game.opponents.size() == 5 and field.get("frog", false) and field.get("rabbit", false), "real Dschungelherz lineup with five rivals and both authored drivers")
		game.queue_free()
		await process_frame
	quit(int(failures != 0))
