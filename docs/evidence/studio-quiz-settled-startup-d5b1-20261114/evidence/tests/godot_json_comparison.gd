extends SceneTree
func _initialize() -> void:
 var original = {"revision": 2, "values": [0, 1]}
 var parsed = JSON.parse_string(JSON.stringify(original))
 print(JSON.stringify({"dict_equality": parsed == original, "recursive_equality": parsed.recursive_equal(original, 10), "array_equality": [960.0, 540.0] == [960, 540], "scalar_equality": 2.0 == 2, "cancel_property": "canceled" in InputEventScreenTouch.new()}))
 quit(0)
