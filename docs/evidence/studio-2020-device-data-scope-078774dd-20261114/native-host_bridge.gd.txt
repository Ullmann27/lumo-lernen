extends Node
## In-process Android host; desktop and separate Godot exports remain playable.

signal returned(destination: String, payload: Dictionary)
signal reward_reported(payload: Dictionary)
signal return_failed(message: String)

const PENDING_REWARDS: String = "user://lumo_host_pending_rewards.cfg"
const SAVE_FAILURE: String = "Speichern fehlgeschlagen. Bitte erneut versuchen."

var _host: Object
var _options: Dictionary = {}
var _result_ids: Dictionary = {}
var _return_pending: bool = false
var _pending_rewards: Dictionary = {}
var _persisted_reward_ids: Dictionary = {}


func _ready() -> void:
	if Engine.has_singleton("LumoHost"):
		_host = Engine.get_singleton("LumoHost")
		var parsed = JSON.parse_string(str(_host.call("getLaunchOptions")))
		if parsed is Dictionary:
			_options = validated_options(parsed)
		else:
			push_warning("[LumoHost] launch options are not valid JSON")
		_load_pending_rewards()
		retry_pending_rewards()


func is_embedded() -> bool:
	return is_instance_valid(_host)


static func validated_options(raw: Dictionary) -> Dictionary:
	var options: Dictionary = raw.duplicate(true)
	options["grade"] = clampi(int(raw.get("grade", 1)), 1, 4)
	options["stars"] = maxi(0, int(raw.get("stars", 0)))
	options["scene"] = str(raw.get("game", raw.get("scene", "kart")))
	if options["scene"] not in ["kart", "jump", "puzzle", "build", "rhythm", "treasure", "learning", "cards", "connect_four", "games", "home"]:
		options["scene"] = "kart"
	if (
		str(raw.get("subject", "Mathematik"))
		not in ["Mathematik", "Deutsch", "Sachunterricht", "Logik"]
	):
		options["subject"] = "Mathematik"
	return options


func launch_options() -> Dictionary:
	return _options.duplicate(true)


func new_result_id() -> String:
	# OS epoch plus monotonic microseconds also distinguishes quick restarts.
	return (
		"%s-%d-%d"
		% [
			str(_options.get("sessionId", "standalone")),
			int(Time.get_unix_time_from_system() * 1000),
			Time.get_ticks_usec()
		]
	)


static func durable_ack(accepted: Variant) -> bool:
	# Godot 4.6.3 Android JavaObject returns JNI jboolean as Variant(uint8_t),
	# hence TYPE_INT 0/1. Keep desktop/mock BOOL support without coercing other
	# numbers, strings or nil into a successful durable storage acknowledgement.
	if typeof(accepted) == TYPE_BOOL:
		return accepted
	if typeof(accepted) == TYPE_INT:
		return accepted == 1
	return false


func reward(payload: Dictionary) -> bool:
	var result_id: String = str(payload.get("resultId", ""))
	if result_id.is_empty():
		return false
	if _result_ids.has(result_id):
		return true
	if is_embedded():
		# Retain a completed payload across engine/process death until the host
		# confirms its durable event. Never claim that a failed write succeeded.
		_pending_rewards[result_id] = payload.duplicate(true)
		_save_pending_rewards()
		var accepted = _host.call("reward", JSON.stringify(payload))
		if not durable_ack(accepted):
			push_warning("[LumoHost] reward not saved; retry on return: %s" % result_id)
			return false
		print("[LumoHost] reward reported: %s" % result_id)
		_pending_rewards.erase(result_id)
		_save_pending_rewards()
	_result_ids[result_id] = true
	reward_reported.emit(payload.duplicate(true))
	return true


func _load_pending_rewards() -> void:
	var config := ConfigFile.new()
	if config.load(PENDING_REWARDS) != OK:
		return
	var pending = config.get_value("rewards", "pending", {})
	if pending is Dictionary:
		for id in pending:
			if pending[id] is Dictionary and pending[id].get("status", "") == "completed":
				_pending_rewards[str(id)] = pending[id].duplicate(true)
				_persisted_reward_ids[str(id)] = true


func _save_pending_rewards() -> void:
	if _pending_rewards.is_empty():
		DirAccess.remove_absolute(PENDING_REWARDS)
		_persisted_reward_ids.clear()
		return
	var config := ConfigFile.new()
	config.set_value("rewards", "pending", _pending_rewards)
	var error: Error = config.save(PENDING_REWARDS + ".tmp")
	if error == OK:
		error = DirAccess.rename_absolute(PENDING_REWARDS + ".tmp", PENDING_REWARDS)
	if error != OK:
		push_warning("[LumoHost] completed reward backup not saved: %s" % error)
		return
	_persisted_reward_ids.clear()
	for id in _pending_rewards:
		_persisted_reward_ids[id] = true


func reward_is_recoverable(result_id: String) -> bool:
	return _result_ids.has(result_id) or _persisted_reward_ids.has(result_id)


func retry_pending_rewards() -> bool:
	for payload in _pending_rewards.duplicate(true).values():
		reward(payload)
	return _pending_rewards.is_empty()


func return_to_app(destination: String, payload: Dictionary = {}) -> bool:
	if not is_embedded():
		return false
	if _return_pending:
		return true
	if not retry_pending_rewards():
		return_failed.emit(SAVE_FAILURE)
		return false
	var target: String = "learn" if destination == "learn" else "games"
	var result: Dictionary = payload.duplicate(true)
	result["sessionId"] = str(_options.get("sessionId", ""))
	var accepted = _host.call("returnToApp", target, JSON.stringify(result))
	if not durable_ack(accepted):
		return_failed.emit(SAVE_FAILURE)
		return false
	_return_pending = true
	returned.emit(target, result)
	print("[LumoHost] return: %s" % target)
	return true
