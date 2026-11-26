extends SceneTree
## Run against the actual PCK extracted from the ARM64 APK, not a source checkout.
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
	if failures.is_empty():
		print("[Intelligence2083Pack] PASS: all nine figures and runtime data present")
	else:
		for failure in failures:
			push_error(failure)
	quit(0 if failures.is_empty() else 1)
