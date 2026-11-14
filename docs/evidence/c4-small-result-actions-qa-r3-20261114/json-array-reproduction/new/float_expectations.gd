extends SceneTree
## Exact QA predicate extraction; only the three expected array literal types vary.
var table: Dictionary = {}

func _layout_matches(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	return (
		value.get("settled") == true
		and value.get("token") == table._token
		and value.get("owner") == table._state.owner
		and value.get("roundId") == table._state.roundId
		and int(value.get("revision", -1)) == int(table._state.revision)
		and int(value.get("ack", -1)) == int(table._state.ack)
		and int(value.get("pending", -1)) == 0
		and value.get("phase") == table._state.phase
		and value.get("paused") == table._state.paused
		and value.get("twoPlayers") == table._state.twoPlayers
		and value.get("rewarded") == table._state.rewarded
		and value.get("columns") == table._state.columns
		and value.get("window_px") == [640.0, 360.0]
		and value.get("viewport_px") == [640.0, 360.0]
		and absf(float(value.get("density", 0.0)) - 1.0) < 0.0001
		and value.get("safe_rect") == [0.0, 24.0, 640.0, 312.0]
	)


func _init() -> void:
	# Synthetic metadata only. No application scene, assets or input is loaded.
	var valid: Dictionary = JSON.parse_string('{"settled":true,"token":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","owner":"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb","roundId":"cccccccccccccccccccccccccccccccc","revision":18,"ack":10,"pending":0,"phase":"won","paused":true,"twoPlayers":true,"rewarded":true,"columns":[0,6,1,6,2,5,3],"window_px":[640,360],"viewport_px":[640,360],"density":1.0,"safe_rect":[0,24,640,312]}')
	table = {"_token": str(valid.token), "_state": valid.duplicate(true)}
	var fixtures: Array[Dictionary] = [
		{"name":"exact_geometry","expected":true},
		{"name":"window_width_wrong","field":"window_px","value":[641,360],"expected":false},
		{"name":"window_height_wrong","field":"window_px","value":[640,361],"expected":false},
		{"name":"viewport_width_wrong","field":"viewport_px","value":[639,360],"expected":false},
		{"name":"viewport_height_wrong","field":"viewport_px","value":[640,359],"expected":false},
		{"name":"safe_left_wrong","field":"safe_rect","value":[1,24,640,312],"expected":false},
		{"name":"safe_top_wrong","field":"safe_rect","value":[0,25,640,312],"expected":false},
		{"name":"safe_width_wrong","field":"safe_rect","value":[0,24,639,312],"expected":false},
		{"name":"safe_height_wrong","field":"safe_rect","value":[0,24,640,311],"expected":false},
		{"name":"fractional_window","field":"window_px","value":[640.25,360],"expected":false},
		{"name":"fractional_viewport","field":"viewport_px","value":[640,360.25],"expected":false},
		{"name":"fractional_safe_rect","field":"safe_rect","value":[0,24.25,640,312],"expected":false},
		{"name":"window_extra_element","field":"window_px","value":[640,360,0],"expected":false},
		{"name":"safe_string_element","field":"safe_rect","value":[0,24,640,"312"],"expected":false},
		{"name":"viewport_missing","field":"viewport_px","remove":true,"expected":false},
	]
	var results: Array[Dictionary] = []
	var failures: int = 0
	for fixture in fixtures:
		var candidate: Dictionary = valid.duplicate(true)
		if fixture.has("field"):
			if fixture.get("remove") == true:
				candidate.erase(fixture.field)
			else:
				candidate[fixture.field] = fixture.value
		# Every case, including negatives, crosses the actual Godot JSON parser.
		var serialized: String = JSON.stringify(candidate)
		var decoded: Variant = JSON.parse_string(serialized)
		var accepted: bool = _layout_matches(decoded)
		var expected: bool = bool(fixture.expected)
		if accepted != expected:
			failures += 1
		results.append({"name":fixture.name,"expected":expected,"accepted":accepted,
			"passed":accepted == expected,"input_json":serialized})
	print("JSON_ARRAY_MATCH_REPRO " + JSON.stringify({
		"scope":"isolated JSON/type reproduction, synthetic layout values, no game/render/input",
		"source_overlay_blob":"cc9ef04069bb2d73d2953a725e7ee5974e5b496f",
		"input_number_type_ids":[typeof(valid.window_px[0]),
			typeof(valid.viewport_px[0]),typeof(valid.safe_rect[0])],"float_type_id":TYPE_FLOAT,
		"checks":results.size(),"failures":failures,"cases":results
	}))
	quit(0 if failures == 0 else 1)
