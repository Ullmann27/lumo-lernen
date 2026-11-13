extends SceneTree
const AUDIO = preload("res://scripts/games/kart_audio.gd")
var observed: Array[WeakRef] = []
var owners: Array[WeakRef] = []
func _initialize() -> void: call_deferred("run")
func remaining() -> Array:
	var entries: Array=[]
	for ref in observed:
		var pb=ref.get_ref()
		if pb!=null:entries.append({"id":pb.get_instance_id(),"class":pb.get_class(),"refs":pb.get_reference_count(),"playing":pb.is_playing(),"position":pb.get_playback_position()})
	return entries
func observe(node: Node) -> void:
	if node is AudioStreamPlayer and node.has_stream_playback():observed.append(weakref(node.get_stream_playback()))
	for c in node.get_children():observe(c)
func run() -> void:
	print("[MixerControl] driver=",AudioServer.get_driver_name()," rate=",AudioServer.get_mix_rate()," latency=",AudioServer.get_output_latency())
	for cycle in range(40):
		var parent=Node.new();root.add_child(parent)
		var music=AUDIO.new();parent.add_child(music)
		music.play_menu();music.play_track("sonnenhafen");music.effect("collision")
		var engine=AudioStreamPlayer.new()
		var stream=AudioStreamGenerator.new();stream.mix_rate=22050;stream.buffer_length=0.1
		engine.stream=stream;parent.add_child(engine);engine.play()
		owners.append(weakref(parent))
		await process_frame
		observe(parent)
		parent.queue_free()
		await process_frame
	var started=Time.get_ticks_msec()
	var last_log=-1000
	while not remaining().is_empty() and Time.get_ticks_msec()-started<3000:
		var elapsed=Time.get_ticks_msec()-started
		if elapsed-last_log>=200:
			last_log=elapsed
			print("[MixerControl] elapsed=",elapsed," since=",AudioServer.get_time_since_last_mix()," next=",AudioServer.get_time_to_next_mix()," remaining=",remaining())
		await process_frame
	var live_owners=0
	for owner in owners:
		if owner.get_ref()!=null:live_owners+=1
	print("[MixerControl] end ms=",Time.get_ticks_msec()-started," observed=",observed.size()," live_owners=",live_owners," remaining=",remaining())
	quit(0 if remaining().is_empty() else 1)
