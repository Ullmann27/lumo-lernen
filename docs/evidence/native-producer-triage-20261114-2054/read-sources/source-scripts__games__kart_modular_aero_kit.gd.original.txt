extends RefCounted
## Additional physically modeled aero / lighting hardware for the production fleet.
## No changes to collider dimensions, chassis anchors, steering joints or original rigs.
## Called before the existing static combine and distance LOD generation.

const CRAFT = preload("res://scripts/games/kart_coachwork_finish.gd")
const STEEL := Color("67788b")
const DARK := Color("192632")
const RUBBER := Color("101921")


static func _detail(kart, node: MeshInstance3D, name: String, close_only: bool = false) -> void:
	# All optional parts use the existing machined coachwork finish family.
	# Vertex-colour batching preserves their unique pigment without extra draw passes.
	var source: StandardMaterial3D = node.material_override as StandardMaterial3D
	assert(source != null)
	node.material_override = kart._mat(source.albedo_color, 0.35, 0.56)
	node.name = name
	if close_only:
		node.set_meta("near_only", true)
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


static func decorate(kart, body: Node3D, spec: Dictionary) -> void:
	var accent: Color = spec.get("accent", Color("6ddfff"))
	var paint: Color = spec.get("paint", Color("4778a5"))
	var pieces: int = 0
	# Sculpted side skirt and inset LED trim; each is inside the existing wheel width.
	for side in [-1.0, 1.0]:
		var sill: MeshInstance3D = CRAFT.rounded_box(kart, body,
			Vector3(side * 0.545, 0.344, 0.01), Vector3(0.11, 0.115, 0.60),
			DARK, 0.35, 0.56)
		_detail(kart, sill, "AeroSideSkirt")
		pieces += 1
		var edge: MeshInstance3D = CRAFT.rounded_box(kart, body,
			Vector3(side * 0.612, 0.394, 0.01), Vector3(0.018, 0.030, 0.52),
			accent, 0.35, 0.26)
		_detail(kart, edge, "AeroSillLight", true)
		pieces += 1
		# A real bevelled aero intake with a dark interior and four pressed vanes.
		var surround: MeshInstance3D = CRAFT.rounded_box(kart, body,
			Vector3(side * 0.45, 0.492, -0.79), Vector3(0.16, 0.125, 0.185),
			paint.darkened(0.17), 0.35, 0.26)
		_detail(kart, surround, "SculptedNoseIntake")
		pieces += 1
		var well: MeshInstance3D = CRAFT.rounded_box(kart, body,
			Vector3(side * 0.454, 0.514, -0.793), Vector3(0.108, 0.022, 0.134),
			RUBBER, 0.0, 0.82)
		_detail(kart, well, "NoseIntakeWell")
		pieces += 1
		for fin in range(3):
			var at: Vector3 = Vector3(side * 0.456, 0.53, -0.842 + fin * 0.049)
			var vane: MeshInstance3D = CRAFT.rounded_box(kart, body,
				at, Vector3(0.08, 0.013, 0.014), STEEL, 0.7, 0.26)
			_detail(kart, vane, "NoseIntakeVane", true)
			pieces += 1
		# Twin metallic exhaust bezels, properly oriented toward the rear.
		var nozzle: MeshInstance3D = kart._ring(body,
			Vector3(side * 0.34, 0.466, 1.162), 0.079, 0.112, STEEL, 0.7)
		nozzle.rotation.x = PI * 0.5
		_detail(kart, nozzle, "ExhaustMachinedBezel", true)
		pieces += 1
		var core: MeshInstance3D = kart._ring(body,
			Vector3(side * 0.34, 0.466, 1.174), 0.046, 0.067, accent, 0.35)
		core.rotation.x = PI * 0.5
		_detail(kart, core, "ExhaustEnergyRing", true)
		pieces += 1
	# Centerline insignia and low-profile chevrons never enter the driver's footwell.
	var badge: MeshInstance3D = CRAFT.rounded_box(kart, body,
		Vector3(0.0, 0.575, -0.955), Vector3(0.20, 0.035, 0.15),
		STEEL, 0.70, 0.26)
	_detail(kart, badge, "AuroraNoseEmblemSeat")
	pieces += 1
	for side in [-1.0, 1.0]:
		var stripe: MeshInstance3D = CRAFT.rounded_box(kart, body,
			Vector3(side * 0.085, 0.600, -0.952),
			Vector3(0.035, 0.010, 0.105), accent, 0.35, 0.26)
		stripe.rotation.y = side * 0.32
		_detail(kart, stripe, "AuroraRaisedChevron", true)
		pieces += 1
	# The physical rear diffuser remains owned by the vehicle; small overlay only.
	var rear: MeshInstance3D = CRAFT.rounded_box(kart, body,
		Vector3(0.0, 0.363, 1.139), Vector3(0.49, 0.040, 0.075),
		DARK, 0.35, 0.56)
	_detail(kart, rear, "RearBumperAeroCap")
	pieces += 1
	body.set_meta("modular_aero_revision", 1)
	body.set_meta("modular_aero_count", pieces)


static func envelope_anchors() -> PackedVector3Array:
	# Fixed manufacturing datums, for regression checks and reviewer positioning.
	return PackedVector3Array([
		Vector3(-0.612, 0.394, 0.01),
		Vector3(0.612, 0.394, 0.01),
		Vector3(-0.45, 0.492, -0.79),
		Vector3(0.45, 0.492, -0.79),
		Vector3(-0.34, 0.466, 1.174),
		Vector3(0.34, 0.466, 1.174),
		Vector3(0.0, 0.575, -0.955)
	])
