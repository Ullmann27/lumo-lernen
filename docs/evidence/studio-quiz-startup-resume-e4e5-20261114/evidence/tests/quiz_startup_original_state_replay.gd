extends "res://scripts/tests/quiz_studio_runtime.gd"
## Explicit UI/transport counterexample. The captured state is immutable input;
## only the fixture bridge acknowledges a real Resume touch. This is NOT Dart.
var original_state: Dictionary = {}
var replay_case := ""
var processed_requests := 0
var replay_started := 0
var replay_input_path := ""
const ORIGINAL_STATE_SHA256 := "3b8d23928226847217ea944e9544f2030c5d1f583fc76e2d4309780576b7dae2"


func _initialize() -> void:
	replay_started = Time.get_ticks_msec()
	replay_case = OS.get_environment("LUMO_QUIZ_STARTUP_REPLAY_CASE")
	replay_input_path = OS.get_environment("LUMO_QUIZ_STARTUP_REPLAY_STATE")
	if replay_case not in ["paused_ack", "active_no_touch", "paused_no_ack"] or FileAccess.get_sha256(replay_input_path) != ORIGINAL_STATE_SHA256:
		printerr("Explicit case and unchanged original paused-state fixture required")
		quit(2)
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(replay_input_path))
	if not parsed is Dictionary:
		quit(2)
		return
	original_state = parsed
	super._initialize()


func _fixture_state() -> Dictionary:
	var value := original_state.duplicate(true)
	# The inherited fixture's launch option uses this isolated test token.
	# All question/round/owner/revision fields stay exactly as captured.
	value.token = FIXTURE_TOKEN
	if replay_case == "active_no_touch":
		value.paused = false
		value.canSelect = true
	return value


func _frame() -> void:
	await super._frame()
	if not is_instance_valid(bridge) or not is_instance_valid(table):
		return
	while processed_requests < bridge.requests.size():
		var request: Dictionary = bridge.requests[processed_requests]
		processed_requests += 1
		if not _check(request.get("action") == "resume" and request.get("token") == FIXTURE_TOKEN and request.get("roundId") == original_state.roundId and int(request.get("revision", -1)) == int(bridge.value.revision), "Only the exact current Resume intent is accepted by the declared fixture"):
			return
		_check(bool(bridge.value.paused) and int(table._pending) == int(request.sequence), "A real input is pending before any fixture acknowledgement")
		if replay_case == "paused_no_ack":
			continue
		var value: Dictionary = bridge.value.duplicate(true)
		value.revision = int(value.revision) + 1
		value.ack = int(request.sequence)
		value.paused = false
		value.canSelect = true
		bridge.value = value
		table._poll_state()


func _fixture_contracts() -> void:
	var expected_requests := 0 if replay_case == "active_no_touch" else 1
	_check(replay_case != "paused_no_ack", "A missing acknowledgement must never reach the quiz contract body")
	var resume_touches := inputs.filter(func(event: Dictionary): return event.get("label") == "Resume observed paused Quiz at startup")
	_check(bridge.requests.size() == expected_requests and resume_touches.size() == expected_requests * 2, "Exactly one real Resume tap for paused start; no Resume input for active start")
	_check(table._authority_ready and not bool(table._state.paused) and bool(table._state.canSelect) and table._pending == 0, "The next contract starts only from acknowledged interactive authority")
	for key in ["roundId", "owner", "recordRevision", "subject", "grade", "number", "total", "questionSubject", "prompt", "options", "selected", "revealed", "gameOver", "won", "correctIndex", "explanation", "hidden", "usedJokers", "audience", "hint", "securedStars", "awardedStars", "rewarded"]:
		_check(table._state[key] == original_state[key], "Resume preserves captured question and reward field " + key)
	_check(int(table._state.ack) == expected_requests, "Only the submitted Resume sequence is acknowledged")
	_check(FileAccess.get_sha256(replay_input_path) == ORIGINAL_STATE_SHA256, "Original CI state bytes are unchanged")


func _finish() -> void:
	_write(output + "/startup-replay.json", {
		"schema": 1, "kind": "quiz_startup_original_state_replay", "case": replay_case,
		"scope": "Actual Godot presenter/input against an explicitly synthetic acknowledgement transport; no Dart, wallet, Android or renderer acceptance",
		"original_state_sha256": ORIGINAL_STATE_SHA256,
		"token_mapping": {"from": original_state.get("token"), "to": FIXTURE_TOKEN},
		"active_control_delta": ["paused=false", "canSelect=true"] if replay_case == "active_no_touch" else [],
		"elapsed_ms": Time.get_ticks_msec() - replay_started,
		"requests": bridge.requests if is_instance_valid(bridge) else [],
		"inputs": inputs, "failures": failures.duplicate(),
		"final_state": table._state.duplicate(true) if is_instance_valid(table) else {},
	})
	await super._finish()
