extends SceneTree

# Check the normal Android race catalogue against the exported PCK.
const EXPANSION_ITEMS := [
	"thunder_star", "frost_crystal", "fire_meteor", "star_fortress", "whirlwind",
	"gravity_wave", "star_decoy", "turbo_xl", "arc_trap", "time_bloom",
]

var failures: int = 0

func _initialize() -> void:
	_run.call_deferred()

func _check(condition: bool, operation: String) -> void:
	print("[Kart-PCK] ", "PASS" if condition else "FAIL", " ", operation)
	failures += int(not condition)

func _run() -> void:
	var roster = load("res://scripts/games/lumo_opponent_roster.gd")
	_check(roster != null and roster.ready_for_race(), "packaged race roster")
	for driver in roster.for_game("kart"):
		var id := str(driver.id)
		for level in range(3):
			var path: String = roster.racing_model_path(id, level)
			var scene := load(path) as PackedScene
			_check(scene != null, "%s imported LOD %d" % [id, level])
			if scene != null:
				var actor := scene.instantiate()
				var players := actor.find_children("*", "AnimationPlayer", true, false)
				_check(players.size() == 1 and players[0].has_animation("kart_seated"), "%s LOD %d seated animation" % [id, level])
				actor.free()
	var catalog = load("res://scripts/games/kart_catalog.gd")
	for entry in catalog.KARTS:
		var id := str(entry.id)
		var packed := load("res://assets/kart/production/fleet/%s.glb" % id) as PackedScene
		var portrait := load("res://assets/kart/menu/fleet/%s.webp" % id) as Texture2D
		_check(packed != null and portrait != null, "%s vehicle body and garage portrait" % id)
		if packed == null:
			continue
		var body := packed.instantiate()
		for level in range(3):
			var mesh := body.find_child("LOD%d" % level, true, false) as MeshInstance3D
			_check(mesh != null and mesh.mesh != null, "%s packaged shell LOD%d" % [id, level])
		body.free()
	for id in ["bridge", "mill", "orchard", "signal_gate", "slider", "station", "turbine", "workshop", "wind_whale"]:
		var path := "res://assets/kart/production/windwerk/%s" % id
		_check(load(path + ".glb") is PackedScene and load(path + ".webp") is Texture2D, "%s Windwerk module and portrait" % id)
	for id in ["pawn", "rook", "knight", "bishop", "queen", "king", "board"]:
		_check(load("res://assets/chess/models/%s.glb" % id) is PackedScene, "%s chess table model" % id)
	var parcours = load("res://scripts/games/parcours/parcours_worlds.gd")
	for id in parcours.playable_ids():
		_check(load("res://assets/kart/parcours_previews/%s.webp" % id) is Texture2D, "%s adventure menu photograph" % id)
	var memory = load("res://scripts/games/memory/memory_table.gd")
	for motif in memory.MOTIFS:
		var card_face := load("res://assets/games/memory/collection/%s.webp" % motif) as Texture2D
		_check(card_face != null and card_face.get_width() >= 768, "%s high-resolution Memory card" % motif)
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
		var item_catalog = load("res://scripts/games/kart_items/kart_item_catalog.gd")
		var collected: Dictionary = {}
		var rng := RandomNumberGenerator.new()
		rng.seed = 2056
		for place in range(1, 7):
			for draw in range(400):
				collected[item_catalog.roll(place, rng)] = true
		for id in EXPANSION_ITEMS:
			var item: Dictionary = item_catalog.entry(id)
			var behaviour := str(item.get("behaviour", ""))
			_check(collected.has(id), "%s is drawable from the packaged race catalogue" % id)
			_check(game.item_ext.effect(behaviour) != null, "%s has an active race effect" % id)
		game.queue_free()
		await process_frame
	quit(int(failures != 0))
