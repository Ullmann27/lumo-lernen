extends SceneTree
## Run against the actual PCK extracted from the ARM64 APK, not a source checkout.
const WORLD_CONTENT := "res://assets/creative/lumo_world/"
const FILES := [
	"res://assets/characters/animals/figures.json",
	"res://assets/creative/lumo_world/open_world_content.json",
	"res://assets/creative/lumo_world/sonnenhafen/kit/kit.json",
	"res://assets/creative/lumo_world/sonnenhafen/sonnenhafen_layout.json",
	"res://assets/creative/lumo_world/sonnenhafen/sonnenhafen_quests.json",
	"res://assets/creative/lumo_world/sonnenhafen/sonnenhafen_residents.json",
	"res://assets/kart/signature/vulkanexpress/models.json",
	"res://assets/kart/signature/wolkensturm/models.json",
	"res://assets/kart/signature/kristallflut/models.json",
	"res://assets/audio/kart/signature/vulkanexpress/manifest.json",
	"res://assets/audio/kart/signature/wolkensturm/manifest.json",
	"res://assets/audio/kart/signature/kristallflut/manifest.json",
]
const FIGURES := ["badger", "cat", "frog", "lion", "otter", "owl", "rabbit", "squirrel", "turtle"]
const REGION_MISSIONS := {
	"waldheim": [
		"wegzeichen", "spurwechsel", "kartenblick", "brueckenholz", "leuchtpunkte",
		"unterstand", "bachpegel", "wasserrinne", "beetplatz", "samenkiste", "waldpost", "waldtafel",
	],
	"sternenstadt": ["parkblick", "stadtroute", "marktlicht"],
}

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var failures: Array[String] = []
	for path in FILES:
		if not FileAccess.file_exists(path):
			failures.append("Missing packed data: " + path)
			continue
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if not (parsed is Dictionary or parsed is Array):
			failures.append("Invalid packed JSON: " + path)
	for id in FIGURES:
		var path := "res://assets/characters/animals/%s/figure.glb" % id
		if not ResourceLoader.exists(path, "PackedScene"):
			failures.append("Missing packed figure: " + id)
		else:
			var model := ResourceLoader.load(path, "PackedScene") as PackedScene
			if model == null:
				failures.append("Invalid packed figure: " + id)
	var resident_path := "res://assets/creative/lumo_world/sonnenhafen/sonnenhafen_residents.json"
	if FileAccess.file_exists(resident_path):
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(resident_path))
		if not data is Dictionary or not data.get("residents") is Array or data.residents.size() != 14:
			failures.append("Expected fourteen packed Sonnenhafen residents")
	if "--console-world" in OS.get_cmdline_user_args():
		_verify_regions(failures)
	if failures.is_empty():
		print("[Intelligence2083Pack] PASS: all required figures and runtime data present")
	else:
		for failure in failures:
			push_error(failure)
	quit(0 if failures.is_empty() else 1)


func _verify_regions(failures: Array[String]) -> void:
	var quests = load("res://scripts/creative/lumo_world_quests.gd")
	var world_state = load("res://scripts/creative/lumo_world_state.gd")
	if quests == null or world_state == null:
		failures.append("Missing packed World quest or save model")
		return
	# Keep the existing six main missions, four atlas missions and five harbor
	# missions in the total. Regional data is loaded as the game itself loads it.
	var mission_count: int = world_state.MISSIONS.size()
	for relative_path in ["open_world_content.json", "sonnenhafen/sonnenhafen_quests.json"]:
		var model = quests.new(JSON.parse_string(FileAccess.get_file_as_string(WORLD_CONTENT + relative_path)))
		if not model.ready():
			failures.append("Invalid packed quest model: " + relative_path)
		else:
			mission_count += model.mission_ids().size()
	for region in REGION_MISSIONS:
		var region_script = load("res://scripts/creative/lumo_world_%s.gd" % region)
		if region_script == null:
			failures.append("Missing packed region script: " + region)
			continue
		var chapter = region_script.new()
		var model = chapter.model
		var missions: Array[String] = model.mission_ids()
		var expected: Array[String] = []
		expected.assign(REGION_MISSIONS[region])
		missions.sort()
		expected.sort()
		if not model.ready() or missions != expected:
			failures.append("Missing or invalid packed missions: " + region)
		else:
			mission_count += missions.size()
			var expected_residents := 5 if region == "waldheim" else 3
			var routines: Variant = model.content.get("routines")
			if model.content.figures.size() != expected_residents or not routines is Dictionary or routines.size() != expected_residents:
				failures.append("Missing packed residents or routines: " + region)
			if region == "waldheim" and (not chapter._validate_stations().is_empty() or chapter.stations.size() != 11):
				failures.append("Missing or invalid packed Waldheim stations")
		chapter.free()
	if mission_count != 30:
		failures.append("Expected 30 packed World missions, found %d" % mission_count)
	if not load("res://scenes/creative/lumo_world.tscn") is PackedScene:
		failures.append("Missing packed World scene")
	for prop in ["tree_fir", "tree_birch", "reeds"]:
		if not load("res://assets/creative/village3d/models/%s.glb" % prop) is PackedScene:
			failures.append("Missing packed woodland model: " + prop)
	for material in ["grass_albedo", "wood_albedo"]:
		if not load("res://assets/creative/adventure/textures/%s.jpg" % material) is Texture2D:
			failures.append("Missing packed woodland texture: " + material)
