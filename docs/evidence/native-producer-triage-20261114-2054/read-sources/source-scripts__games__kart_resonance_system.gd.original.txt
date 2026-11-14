extends RefCounted
## Lumo Kart: racing skill, never a hidden random item table.
## A single pure deterministic scoring policy serves the human racer and
## opponents. No rewards depend on place: leaders and newcomers are equal.
const BOOST: String = "boost"
const PHASE_SHIELD: String = "shield"
const GRAVITY_PULSE: String = "pulse"
const SYMBOLS = preload("res://scripts/games/kart_item_symbols.gd")

const BRONZE_THRESHOLD: float = 0.0
const SILVER_THRESHOLD: float = 0.55
const GOLD_THRESHOLD: float = 0.9
const MIN_PICKUP_SPEED: float = 6.5


static func award(
	speed: float,
	course_speed: float,
	lateral_error: float,
	drift_charge: float,
	hit_recently: bool
) -> Dictionary:
	# The reference speed is the kart's own tuned target, not a fixed speed
	# favouring expensive/fast karts. Driving near the ring's ideal line is
	# the biggest contributor; controlled drift and speed are both rewarded.
	var pace: float = clampf(maxf(speed, 0.0) / maxf(course_speed, 1.0), 0.0, 1.0)
	var line: float = 1.0 - clampf(absf(lateral_error) / 2.3, 0.0, 1.0)
	var drift: float = clampf(drift_charge / 1.5, 0.0, 1.0)
	var score: float = clampf(line * 0.47 + pace * 0.38 + drift * 0.15, 0.0, 1.0)
	if hit_recently:
		score = minf(score, 0.28)
	var tier: int = 0
	var reward: String = BOOST
	if score >= GOLD_THRESHOLD:
		tier = 2
		reward = GRAVITY_PULSE
	elif score >= SILVER_THRESHOLD:
		tier = 1
		reward = PHASE_SHIELD
	return {"item": reward, "tier": tier, "score": snappedf(score, 0.001)}


static func ring_colour(tier: int) -> Color:
	match tier:
		2:
			return Color("f8c85d")
		1:
			return Color("ad9cff")
		_:
			return Color("53e8ef")


static func build_ring(parent: Node3D, transform: Transform3D) -> Node3D:
	# Every gate offers the same three skill outcomes. Its crown shows all three
	# actual item silhouettes, never a fixed reward or an implied random draw.
	# The root is the track's placement frame; only descendants may animate.
	var root := Node3D.new()
	root.name = "SkillResonanceRing"
	root.transform = transform
	parent.add_child(root)
	root.set_meta("lumo_racing_pickup", "skill_resonance")
	root.set_meta("lumo_reward_policy", "racing_skill")
	root.set_meta("lumo_gate_outcomes", SYMBOLS.KINDS.duplicate())
	root.set_meta("lumo_skill_hint", "Linie · Tempo · Drift")
	var structure := Node3D.new()
	structure.name = "GateStructure"
	root.add_child(structure)
	var body_material := StandardMaterial3D.new()
	body_material.albedo_color = Color("24485a")
	body_material.metallic = 0.65
	body_material.roughness = 0.28
	var light_material := StandardMaterial3D.new()
	light_material.albedo_color = Color("d0f7ff")
	light_material.metallic = 0.15
	light_material.roughness = 0.28
	light_material.emission_enabled = true
	light_material.emission = Color("79d5e8")
	light_material.emission_energy_multiplier = 0.65
	_gate_torus(structure, "ResonanceHalo", 1.89, 2.10, body_material)
	_gate_torus(structure, "InnerLightRail", 1.80, 1.85, light_material)

	var symbols := Node3D.new()
	symbols.name = "OutcomeSymbols"
	root.add_child(symbols)
	for index in range(SYMBOLS.KINDS.size()):
		var kind: String = SYMBOLS.KINDS[index]
		var angle: float = deg_to_rad(136.0 - 46.0 * float(index))
		var position := Vector3(cos(angle) * 2.04, sin(angle) * 2.04, 0.0)
		var seat := MeshInstance3D.new()
		seat.name = "OutcomeSeat_" + kind
		var seat_mesh := CylinderMesh.new()
		seat_mesh.top_radius = 0.43
		seat_mesh.bottom_radius = 0.46
		seat_mesh.height = 0.22
		seat_mesh.radial_segments = 12
		seat.mesh = seat_mesh
		seat.rotation.x = PI * 0.5
		seat.position = position
		seat.material_override = body_material
		seat.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		structure.add_child(seat)
		var rim := _gate_torus(structure, "OutcomeRim_" + kind, 0.41, 0.45, SYMBOLS.accent_material(kind))
		rim.position = position + Vector3(0.0, 0.0, 0.135)
		var symbol: Node3D = SYMBOLS.build(kind)
		symbol.position = position + Vector3(0.0, 0.0, 0.20)
		symbol.scale = Vector3.ONE * 0.50
		symbols.add_child(symbol)

	# Six small travelling traces suggest a powered crossing. The continuous
	# rail and reward crown stay aligned to the banked road at every frame.
	var motion := Node3D.new()
	motion.name = "GateMotion"
	root.add_child(motion)
	var trace_mesh := BoxMesh.new()
	trace_mesh.size = Vector3(0.10, 0.23, 0.09)
	for index in range(6):
		var angle: float = float(index) * TAU / 6.0
		var trace := MeshInstance3D.new()
		trace.name = "EnergyTrace%d" % index
		trace.mesh = trace_mesh
		trace.material_override = light_material
		trace.position = Vector3(cos(angle) * 1.95, sin(angle) * 1.95, 0.125)
		trace.rotation.z = angle
		trace.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		motion.add_child(trace)
	return root


static func advance_ring(root: Node3D, elapsed: float, reduced_motion: bool = false) -> void:
	if not is_instance_valid(root):
		return
	var phase: float = 0.0 if reduced_motion or not is_finite(elapsed) else elapsed
	var motion := root.get_node_or_null("GateMotion") as Node3D
	if motion != null:
		motion.rotation.z = phase * 0.22
	var symbols := root.get_node_or_null("OutcomeSymbols") as Node3D
	if symbols != null:
		for index in range(symbols.get_child_count()):
			SYMBOLS.advance(symbols.get_child(index) as Node3D, phase + float(index) * 0.55, reduced_motion)


static func _gate_torus(parent: Node3D, name: String, inner: float, outer: float, material: Material) -> MeshInstance3D:
	var mesh := TorusMesh.new()
	mesh.inner_radius = inner
	mesh.outer_radius = outer
	mesh.rings = 32
	mesh.ring_segments = 8
	var node := MeshInstance3D.new()
	node.name = name
	node.mesh = mesh
	node.rotation.x = PI * 0.5
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)
	return node
