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
	var arguments := OS.get_cmdline_user_args()
	var phase := "all" if arguments.is_empty() else str(arguments[0])
	if arguments.size() > 1 or phase not in ["all", "assets", "race"]:
		push_error("Expected one PCK probe phase: assets or race")
		quit(2)
		return
	print("[Kart-PCK] phase ", phase)
	if phase in ["all", "assets"]:
		_check_assets()
	if phase in ["all", "race"]:
		await _check_race()
	quit(int(failures != 0))


func _check_assets() -> void:
	_check(load("res://scenes/learning/holo_lesson.tscn") is PackedScene, "packaged interactive learning lesson")
	_check(load("res://scenes/learning/tutor_world.tscn") is PackedScene, "packaged interactive tutoring world")
	for script_path in [
		"res://scripts/learning/holo/holo_lesson_plan.gd",
		"res://scripts/learning/tutor/tutor_plan.gd",
		"res://scripts/games/run/run_stunt_relay.gd",
		"res://scripts/games/kart_arena_battle.gd",
		"res://scripts/games/parcours/parcours_worlds.gd",
		"res://scripts/games/chess/chess_school.gd",
	]:
		_check(load(script_path) is GDScript, "packaged feature script %s" % script_path)
	var roster = load("res://scripts/games/lumo_opponent_roster.gd")
	_check(roster != null and roster.ready_for_race(), "packaged race roster")
	var catalog = load("res://scripts/games/kart_catalog.gd")
	var model_ids: Dictionary = {}
	for rival in roster.for_game("kart"):
		model_ids[str(rival.id)] = true
	var playable_ids: Array[String] = []
	for entry in catalog.DRIVERS:
		var id := str(entry.id)
		playable_ids.append(id)
		_check(load("res://assets/kart/menu/drivers/%s.webp" % id) is Texture2D, "%s playable driver portrait" % id)
		if id != "fox":
			model_ids[id] = true
	playable_ids.sort()
	_check(playable_ids == ["badger", "cat", "fox", "frog", "lion", "otter", "owl", "rabbit", "squirrel", "turtle"], "all ten playable drivers are in the exported selection catalogue")
	var lumo_scene := load("res://assets/characters/lumo_facial/Lumo-Facial-Mobile.glb") as PackedScene
	_check(lumo_scene != null, "original Lumo facial model")
	if lumo_scene != null:
		var actor := lumo_scene.instantiate()
		var players := actor.find_children("*", "AnimationPlayer", true, false)
		_check(players.size() == 1 and players[0].has_animation("kart_seated"), "original Lumo seated animation")
		actor.free()
	# Check shared rival/player models once; player-only Borin, Yuki and Milo
	# must not depend on membership in the independent opponent roster.
	for model_id in model_ids:
		var id := str(model_id)
		for level in range(3):
			var path: String = roster.racing_model_path(id, level)
			var scene := load(path) as PackedScene
			_check(scene != null, "%s imported LOD %d" % [id, level])
			if scene != null:
				var actor := scene.instantiate()
				var players := actor.find_children("*", "AnimationPlayer", true, false)
				_check(players.size() == 1 and players[0].has_animation("kart_seated"), "%s LOD %d seated animation" % [id, level])
				actor.free()
	_check(load("res://assets/kart/track_stage/clips/windwerk_auftakt.ogv") is VideoStream, "packaged race opening film")
	for route in catalog.TRACKS:
		var photo_path := "res://assets/kart/track_stage/%s.webp" % route.id
		var photo := load(photo_path) as Texture2D
		_check(photo != null and photo.get_width() >= 1920 and photo.get_height() >= 1080, "%s full-size track photograph" % route.id)
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


func _check_race() -> void:
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
