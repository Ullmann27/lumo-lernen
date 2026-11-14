extends SceneTree
## Real production Dart/controller/session through an explicit local QA file
## transport. Only this test reads the private deck plan. The presenter receives
## public-state.json exclusively. The clock is a fixture, not a device FPS claim.
const TABLE := "res://scripts/games/memory/memory_table.gd"
var directory := ""
var output := ""
var capture := false
var table
var bridge
var step_id := 0
var clock_ms := 0
var checks := 0
var failures: Array[String] = []
var inputs: Array[Dictionary] = []
var captures: Array[Dictionary] = []
var motion_frames: Array[Dictionary] = []
var started := 0
var original_touch := false
var initial_round := ""
var first_token := ""
var completed_round := ""

class DiskBridge extends RefCounted:
	var folder := ""
	var pending_raw := ""
	var originals: Array[String] = []
	var returns := 0
	func getTableState() -> String:
		return FileAccess.get_file_as_string(folder+"/public-state.json")
	func submitTableAction(payload: String) -> bool:
		if not pending_raw.is_empty(): return false
		pending_raw = payload
		originals.append(payload)
		return true
	func returnToApp(destination: String,payload: String) -> bool:
		var state: Variant = JSON.parse_string(getTableState())
		if destination != "games" or payload != "" or not state is Dictionary or state.get("exit") != true:
			return false
		returns += 1
		return true


func _initialize() -> void:
	directory = OS.get_environment("LUMO_MEMORY_QA_DIR")
	output = OS.get_environment("LUMO_MEMORY_CAPTURE_DIR")
	capture = "--capture" in OS.get_cmdline_user_args()
	call_deferred("_run")


func _check(value: bool,message: String) -> bool:
	checks += 1
	if not value:
		failures.append(message)
		push_error("[MemoryTableRuntime] "+message)
	return value


func _read(name: String) -> Dictionary:
	var path := directory+"/"+name
	if not FileAccess.file_exists(path): return {}
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return value if value is Dictionary else {}


func _write(name: String,value: Dictionary) -> bool:
	var path := directory+"/"+name
	var file := FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file == null: return _check(false,"QA output writable "+name)
	file.store_string(JSON.stringify(value))
	file.flush()
	var error := file.get_error()
	file.close()
	if error == OK: error = DirAccess.rename_absolute(path+".tmp",path)
	return _check(error==OK,"atomic QA output "+name)


func _frames(count: int) -> void:
	for index in range(count):
		await process_frame
		if capture: await RenderingServer.frame_post_draw


func _exchange(elapsed: int=0,control: String="") -> bool:
	step_id += 1
	clock_ms += elapsed
	var packet := {"id":step_id,"clock_ms":clock_ms}
	var raw: String = bridge.pending_raw
	if not raw.is_empty(): packet["request_raw"]=raw
	if not control.is_empty(): packet["control"]=control
	if not _write("input.json",packet): return false
	var deadline := Time.get_ticks_msec()+12000
	while Time.get_ticks_msec()<deadline:
		var error := _read("authority-failure.json")
		if not error.is_empty(): return _check(false,"Dart authority failed: "+str(error.get("error")))
		var receipt := _read("step-receipt.json")
		if int(receipt.get("id",-1))==step_id:
			if not _check(receipt.get("status")=="ACK" and int(receipt.get("clock_ms",-1))==clock_ms,"exact current Dart step receipt"):
				return false
			bridge.pending_raw=""
			if is_instance_valid(table): table._poll_state()
			await _frames(4)
			return true
		await _frames(1)
	return _check(false,"bounded Dart step response "+str(step_id))


func _physical(control: Control) -> Rect2:
	var factor := Vector2(root.size)/root.get_visible_rect().size
	var transform := control.get_global_transform_with_canvas()
	return Rect2(transform*Vector2.ZERO*factor,control.size*transform.get_scale()*factor)


func _tap(button: Button,label: String,elapsed: int=0) -> bool:
	if not _check(button.is_visible_in_tree() and not button.disabled,label+" actual enabled control"): return false
	var rect := _physical(button)
	if not _check(rect.size.x/table._density>=48.0 and rect.size.y/table._density>=48.0,label+" >=48dp"): return false
	var point := rect.get_center()
	for position in [Vector2.ZERO,point]:
		var motion := InputEventMouseMotion.new()
		motion.position=position
		Input.parse_input_event(motion)
		Input.flush_buffered_events()
	var before: String = JSON.stringify(table._state)
	var previous_count: int = bridge.originals.size()
	for pressed in [true,false]:
		var event := InputEventScreenTouch.new()
		event.index=1
		event.position=point
		event.pressed=pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		inputs.append({"label":label,"pressed":pressed,"point":[point.x,point.y],"clock_ms":clock_ms,"revision":int(table._state.revision)})
		await _frames(1)
	if not _check(bridge.originals.size()==previous_count+1 and not bridge.pending_raw.is_empty(),label+" emits exactly one actual intent"): return false
	_check(JSON.stringify(table._state)==before,label+" cannot invent authority state before ACK")
	_check(not FileAccess.file_exists("user://memory_layout_v1.json"),"pending actual intent removes settled snapshot")
	inputs.append({"label":label,"original_request":bridge.pending_raw})
	return await _exchange(elapsed)


func _capture(name: String,settled: bool=true,motion: bool=false) -> void:
	if settled:
		await _frames(4)
		var present := FileAccess.file_exists("user://memory_layout_v1.json")
		_check(present,"current settled geometry "+name)
		if present:
			var raw := FileAccess.get_file_as_string("user://memory_layout_v1.json")
			var layout: Variant = JSON.parse_string(raw)
			_check(layout is Dictionary and layout.get("settled")==true and int(layout.get("revision",-1))==int(table._state.revision) and layout.get("token")==table._state.token,"same-token current layout "+name)
			var file := FileAccess.open(output+"/"+name+".layout.json",FileAccess.WRITE)
			file.store_string(raw)
			file.close()
	if not capture: return
	var image := root.get_texture().get_image()
	if not _check(image!=null and not image.is_empty(),"real renderer framebuffer "+name): return
	var path := output+"/"+name+".png"
	if not _check(image.save_png(path)==OK,"capture saved "+name): return
	var row := {"file":name+".png","sha256":FileAccess.get_sha256(path),"width":image.get_width(),"height":image.get_height(),
		"roundId":table._state.roundId,"token":table._state.token,"revision":int(table._state.revision)}
	if motion: motion_frames.append(row)
	else: captures.append(row)


func _create_table() -> bool:
	if is_instance_valid(table):
		table.queue_free()
		await _frames(3)
	var state := _read("public-state.json")
	if not _check(not state.is_empty(),"actual Dart public state exists"): return false
	root.get_node("HostBridge")._options={"scene":"memory","tableToken":state.token,"displayDensity":1.0}
	var script: GDScript=load(TABLE)
	if not _check(script!=null and script.can_instantiate(),"production Memory script compiles"): return false
	table=script.new()
	table._host=bridge
	root.add_child(table)
	await _frames(8)
	return _check(table._state.token==state.token and table._state.roundId==state.roundId,"scene binds actual new token and round")


func _finish() -> void:
	var result := {"schema":1,"mode":"production_dart_disk_authority","success":failures.is_empty(),"checks":checks,"failures":failures,
		"scope":"Actual production Godot ScreenTouch to Dart rules/session/persistence via explicit QA disk transport and monotonic clock fixture. No Android/device FPS claim.",
		"display_driver":DisplayServer.get_name(),"capture":capture,"captures":captures,"motion_frames":motion_frames,
		"inputs":inputs,"native_original_requests":bridge.originals if bridge!=null else [],"return_observed":bridge.returns if bridge!=null else 0,
		"initial_round":initial_round,"completed_round":completed_round,"clock_ms":clock_ms,"elapsed_wall_ms":Time.get_ticks_msec()-started}
	if not output.is_empty():
		var file := FileAccess.open(output+"/memory-runtime-report.json",FileAccess.WRITE)
		if file!=null:
			file.store_string(JSON.stringify(result,"\t"))
			file.close()
	if not directory.is_empty(): _write("native-result.json",result)
	if is_instance_valid(table):
		table.queue_free()
		await _frames(4)
	Input.emulate_touch_from_mouse=original_touch
	print("[MemoryTableRuntime] %s checks=%d inputs=%d" % ["PASS" if failures.is_empty() else "FAIL",checks,inputs.size()])
	quit(0 if failures.is_empty() else 1)


func _run() -> void:
	if "--parse-only" in OS.get_cmdline_user_args():
		var script: GDScript=load(TABLE)
		print("[MemoryTableRuntime] parser-only; no authority execution")
		quit(0 if script!=null and script.can_instantiate() else 1)
		return
	started=Time.get_ticks_msec()
	if directory.is_empty() or output.is_empty():
		push_error("LUMO_MEMORY_QA_DIR and LUMO_MEMORY_CAPTURE_DIR are required")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(output)
	if capture and not _check(DisplayServer.get_name()!="headless","capture requires real renderer"):
		await _finish();return
	original_touch=Input.emulate_touch_from_mouse
	Input.emulate_touch_from_mouse=true
	root.size=Vector2i(960,540)
	root.position=Vector2i(32,32)
	root.grab_focus()
	var mobile=root.get_node("MobileRuntime")
	mobile._android_safe_area_enabled=true
	mobile._safe_area_reader=func(_callback): return false
	mobile._safe_area_observation={"window_size":root.size,"view_size":Vector2(root.size),"decor_size":Vector2(root.size),
		"render_rect":Rect2(Vector2.ZERO,Vector2(root.size)),"system_insets":Rect2(),"insets":Rect2()}
	mobile.safe_area_changed.emit()
	bridge=DiskBridge.new()
	bridge.folder=directory
	var deadline:=Time.get_ticks_msec()+20000
	while not FileAccess.file_exists(directory+"/private-test-control.json") and Time.get_ticks_msec()<deadline:
		await _frames(1)
	if not _check(FileAccess.file_exists(directory+"/private-test-control.json"),"bounded real authority readiness"):
		await _finish();return
	if not await _create_table(): await _finish();return
	if not await _exchange(): await _finish();return
	initial_round=str(table._state.roundId)
	first_token=str(table._state.token)
	_check(table._state.canFlip and not table._state.paused,"actual first round interactive")
	await _capture("01-memory-real-hidden")
	var plan:=_read("private-test-control.json")
	var mismatch: Array=plan.mismatch
	if not await _tap(table._cards[int(mismatch[0])].button,"first actual Dart card"):
		await _finish();return
	var changing:=0
	for frame in range(12):
		await _frames(2)
		var angle: float=table._cards[int(mismatch[0])].root.rotation.y
		if angle>0.001 and angle<PI-0.001: changing+=1
		await _capture("motion-%02d" % frame,false,true)
	_check(changing>=4,"real authority acknowledgement drives multiple intermediate flip poses")
	await _frames(12)
	await _capture("02-memory-real-face")
	if not await _tap(table._cards[int(mismatch[1])].button,"second actual Dart card"):
		await _finish();return
	await _frames(34)
	_check(table._state.phase=="resolve" and int(table._state.remainingMs)==850,"actual original pair delay")
	if not await _tap(table.pause_button,"pause real resolve",300): await _finish();return
	_check(table._state.paused and int(table._state.remainingMs)==550,"pause persists exact remaining turn time")
	var paused_state: Dictionary=table._state.duplicate(true)
	if not await _exchange(1500): await _finish();return
	_check(table._state==paused_state,"paused authority does not resolve the pair")
	await _capture("03-memory-real-paused")
	if not await _tap(table.resume_button,"explicit real resume"): await _finish();return
	_check(not table._state.paused and table._state.roundId==initial_round,"explicit same-round resume")
	if not await _tap(table.pause_button,"pause before actual return"): await _finish();return
	if not await _tap(table.back_button,"durable unfinished return"): await _finish();return
	_check(bridge.returns==1,"first actual return waits for durable Dart exit")
	if not await _exchange(0,"unfinished-reopen"): await _finish();return
	if not await _create_table(): await _finish();return
	_check(table._state.roundId==initial_round and table._state.token!=first_token and table._state.paused,"reopen preserves unfinished round with distinct token and explicit pause")
	await _capture("04-memory-real-reopened")
	if not await _tap(table.resume_button,"resume restored real round"): await _finish();return
	if not await _exchange(550): await _finish();return
	await _frames(34)
	_check(table._state.turn=="lumo" and table._state.phase=="botFirst","actual mismatch hands turn to original Dart opponent")
	if not await _exchange(900): await _finish();return
	await _frames(34)
	_check(table._state.phase=="botSecond","original Dart opponent made first decision")
	await _capture("05-memory-real-bot-first")
	if not await _exchange(900): await _finish();return
	await _frames(34)
	_check(table._state.phase=="resolve" and table._state.turn=="lumo","original Dart opponent made second decision")
	await _capture("06-memory-real-bot-second")
	if not await _exchange(850): await _finish();return
	await _frames(34)
	if not await _tap(table.pause_button,"pause after real bot reply"): await _finish();return
	if not await _tap(table.restart_button,"real new-round button"): await _finish();return
	await _frames(4)
	_check(table._state.roundId!=initial_round and not table._state.paused,"actual restart has a new round identity")
	plan=_read("private-test-control.json")
	for pair in plan.pairs:
		for index in pair:
			if not await _tap(table._cards[int(index)].button,"legal actual pair card"):
				await _finish();return
			await _frames(34)
		if not await _exchange(850): await _finish();return
		await _frames(4)
	_check(table._state.complete and table._state.rewarded and int(table._state.kindPairs)==4 and int(table._state.lumoPairs)==0,"actual completed round persisted before reward display")
	completed_round=str(table._state.roundId)
	await _capture("07-memory-real-win")
	if not await _tap(table.back_button,"durable completed return"): await _finish();return
	_check(bridge.returns==2,"completed return acknowledged")
	if not await _exchange(0,"paid-reopen"): await _finish();return
	if not await _create_table(): await _finish();return
	_check(table._state.roundId!=completed_round and not table._state.complete,"paid reopening follows original next-round behavior")
	await _capture("08-memory-real-paid-reopen")
	if not await _tap(table.back_button,"final actual return"): await _finish();return
	_check(bridge.returns==3,"every actual return has an authority acknowledgement")
	if not await _exchange(0,"finish"): await _finish();return
	var authority:=_read("authority-result.json")
	_check(authority.get("success")==true and int(authority.get("award_calls",-1))==1,"actual durable QA ledger paid only once")
	await _finish()
