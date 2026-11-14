extends SceneTree
## Follow actual embedded launch options through the production boot loader.
## Table rules and Android transport are exercised by their separate authorities.
const BRIDGE = preload("res://scripts/systems/host_bridge.gd")
const CASES := {
	"memory": ["LUMO MEMORY", "res://scenes/games/memory_table.tscn"],
	"quiz": ["LUMO QUIZSHOW", "res://scenes/games/quiz_studio.tscn"],
	"cards": ["LUMO CARDS", "res://scenes/games/cards_table.tscn"],
	"connect_four": ["VIER GEWINNT", "res://scenes/games/connect_four_table.tscn"],
}
var checks := 0
var failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		printerr("[NativeTableBoot] FAIL " + message)


func _run() -> void:
	var bridge := root.get_node("HostBridge")
	var router := root.get_node("SceneRouter")
	var original_options: Dictionary = bridge.get("_options").duplicate(true)
	var original_host: Object = bridge.get("_host")
	var original_router_options: Dictionary = router.get("launch_options").duplicate(true)
	var transport := Node.new()
	root.add_child(transport)
	bridge.set("_host", transport)
	var packed := load("res://scenes/app/boot.tscn") as PackedScene
	for game: String in CASES:
		var options := BRIDGE.validated_options({
			"game": game,
			"childKey": "boot-child",
			"grade": 2,
			"subject": "Logik",
			"sessionId": "boot-" + game,
			"tableToken": "b".repeat(32),
			"reduceAnimations": true,
		})
		bridge.set("_options", options)
		var boot := packed.instantiate()
		boot.set("auto_transition", false)
		root.add_child(boot)
		await process_frame
		await process_frame
		var deadline := Time.get_ticks_msec() + 30000
		while boot.get("load_phase") not in ["ready", "error"] and Time.get_ticks_msec() < deadline:
			await create_timer(0.01).timeout
		_check(boot.get("target_scene") == game, game + " keeps its actual boot destination")
		_check(boot.get("load_phase") == "ready", game + " loads its actual scene resource")
		_check(boot.get_node("Layer/Title").text == CASES[game][0], game + " keeps its own title")
		if game in ["memory", "quiz"]:
			_check(not boot.get_node("Layer/Background").visible, game + " avoids an unrelated Kart cover")
		var resources: Dictionary = boot.get("_resources")
		_check(resources.has(CASES[game][1]), game + " resolves the correct production table")
		var routed: Dictionary = router.get("launch_options")
		_check(routed.get("tableToken") == options.tableToken, game + " preserves the authority token")
		_check(routed.get("childKey") == options.childKey and routed.get("sessionId") == options.sessionId,
			game + " preserves the original child and session")
		boot.queue_free()
		await process_frame
		await process_frame
	bridge.set("_host", original_host)
	bridge.set("_options", original_options)
	router.set("launch_options", original_router_options)
	transport.queue_free()
	await process_frame
	if failures.is_empty():
		print("[NativeTableBoot] PASS %d actual boot, resource and authority-context checks" % checks)
	quit(0 if failures.is_empty() else 1)
