extends SceneTree
## Format fixture only. No Lumo scene, profile, game state or APK is loaded.


func _initialize() -> void:
	var output := OS.get_environment("LUMO_QA_CONFIG_FIXTURE")
	if output.is_empty():
		push_error("Explicit isolated fixture output path is required")
		quit(1)
		return
	var config := ConfigFile.new()
	var scope := "synthetic-qa-profile-never-installed".sha256_text()
	var subject := "Mathematik"
	config.set_value("jump", "version", 1)
	config.set_value("jump", "child_scope", scope)
	config.set_value("jump", "course", 0)
	config.set_value("jump", "grade", 1)
	config.set_value("jump", "subject", subject)
	config.set_value("jump", "result_id", "synthetic-serializer-format-only")
	config.set_value("jump", "checkpoint", 0)
	config.set_value("jump", "collected", {0: true, 3: true})
	config.set_value("jump", "goals_completed", {})
	config.set_value("jump", "active_question", {
		"question": "A={B} and a quoted \"word\"",
		"nested": {"answer": 8, "options": ["8", "9"]}
	})
	var recent: Array[String] = ["first", "second {quoted} \"word\""]
	config.set_value("jump", "recent_questions", recent)
	var name := "jump_%s_1_%s.cfg" % [scope.substr(0, 24), subject.sha256_text().substr(0, 12)]
	var status := config.save(output.path_join(name))
	print("[ConfigFixture] engine=%s file=%s save_status=%d" % [Engine.get_version_info().string, name, status])
	quit(0 if status == OK else 1)
