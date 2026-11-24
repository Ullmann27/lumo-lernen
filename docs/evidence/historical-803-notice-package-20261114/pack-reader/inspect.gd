extends SceneTree

func _init() -> void:
    var args := OS.get_cmdline_user_args()
    if args.size() != 1:
        printerr("Expected one local PCK path")
        quit(2)
        return
    var mounted := ProjectSettings.load_resource_pack(args[0], false)
    var paths := [
        "res://project.binary",
        "res://assets/fonts/Nunito-LICENSE.txt",
        "res://assets/characters/lumo_animated/ATTRIBUTION.md",
        "res://assets/characters/lumo_facial/ATTRIBUTION.md",
        "res://THIRD_PARTY_NOTICES.md",
    ]
    var members := {}
    for path in paths:
        var present := FileAccess.file_exists(path)
        var entry := {"present": present}
        if present:
            var bytes := FileAccess.get_file_as_bytes(path)
            entry["bytes"] = bytes.size()
            entry["sha256"] = FileAccess.get_sha256(path)
        members[path] = entry
    var report := {
        "mounted": mounted,
        "control_project_binary_present": members["res://project.binary"]["present"],
        "members": members,
        "scope": "Mounted only as a resource filesystem in a separate blank project. No scene, application script, renderer capture or game is launched by this inspection script.",
    }
    print("PCK_NOTICE_JSON=" + JSON.stringify(report))
    quit(0 if mounted and report["control_project_binary_present"] else 1)
