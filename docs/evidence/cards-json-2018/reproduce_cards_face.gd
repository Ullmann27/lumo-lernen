extends SceneTree
const TABLE = "res://scripts/games/cards/cards_table.gd"
const STATE_PATH = "res://docs/evidence/cards-json-2018/mailbox-card-faces.json"
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var state: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(STATE_PATH))
	var table = load(TABLE).new()
	print("engine=", Engine.get_version_info().string)
	print("integer_literal=", str(5), " float_literal=", str(5.0), " parsed_json=", str(state.top.number))
	var cards: Array = state.hand.slice(0, 3)
	cards.append(state.top)
	cards.append(state.hand[5])
	for card: Dictionary in cards:
		var texture: Texture2D = table._texture(card, true)
		var number: Variant = card.get("number")
		print(JSON.stringify({"id":card.id,"type":card.type,"number_type":typeof(number),"number_string":str(number),"texture":texture.resource_path if texture != null else "NULL"}))
	var normalized: Dictionary = state.top.duplicate(true)
	normalized.number = int(normalized.number)
	var texture: Texture2D = table._texture(normalized, true)
	print("normalized_top_texture=", texture.resource_path if texture != null else "NULL")
	print("back_texture=", table._texture({}, false).resource_path)
	table.free()
	quit(0)
