extends Node3D
@export_range(0, 2) var hip_influence: float
@export_range(0, 2) var shoulder_influence: float

@export var leg_fl: Node3D
@export var leg_fr: Node3D
@export var leg_bl: Node3D
@export var leg_br: Node3D
@export var body_parts: Array[Node3D]
@export var offsets: Array[float]

@onready var shoulder_target: Marker3D = $ShoulderTarget
@onready var hip_target: Marker3D = $HipTarget
@onready var path: Path3D = $Path3D

@export_group('Hips suspension')
var hips_spring_damper: SpringDamper
@export_range(0, 5000) var hips_spring: float=10:
	set(value):
		hips_spring = value
		if hips_spring_damper: hips_spring_damper.r = value
@export_range(0, 1000) var hips_damper: float = 1:
	set(value):
		hips_damper = value
		if hips_spring_damper: hips_spring_damper.k = value
@export_range(1, 100) var hips_mass: float=10:
	set(value):
		hips_mass = value
		if hips_spring_damper: hips_spring_damper.m = value

@export_group('Shoulders suspension')
var shoulders_spring_damper: SpringDamper
@export_range(0, 5000) var shoulders_spring: float=10:
	set(value):
		shoulders_spring = value
		if shoulders_spring_damper: shoulders_spring_damper.r = value
@export_range(0, 1000) var shoulders_damper: float = 1:
	set(value):
		shoulders_damper = value
		if shoulders_spring_damper: shoulders_spring_damper.k = value
@export_range(1, 100) var shoulders_mass: float = 10:
	set(value):
		shoulders_mass = value
		if shoulders_spring_damper: shoulders_spring_damper.m = value
@export_range(0, 1000) var shoulders_gravity: float:
	set(value):
		shoulders_gravity = value
		if shoulders_spring_damper: shoulders_spring_damper.g = value

func _ready():
	hips_spring_damper = SpringDamper.new(hips_spring, hips_damper, hips_mass)
	shoulders_spring_damper = SpringDamper.new(shoulders_spring, shoulders_damper, shoulders_mass, shoulders_gravity)
	offsets.resize(body_parts.size())

func _curve_spine():
	path.curve.set_point_position(0, hip_target.position)
	path.curve.set_point_position(1, shoulder_target.position)
	path.curve.set_point_out(0, hip_target.basis * Vector3.FORWARD * hip_influence)
	path.curve.set_point_in(1, shoulder_target.basis * Vector3.BACK * shoulder_influence)

	for n in range(body_parts.size()):
		var part = body_parts[n]
		var offset = offsets[n]
		part.transform = path.curve.sample_baked_with_rotation(offset)
		var normalized_offset = offset / offsets[0]
		part.rotate_object_local(Vector3.BACK, lerp(hip_target.rotation.z, shoulder_target.rotation.z, normalized_offset) / 3)

func update(dt: float, speed: float):

	#var hip_force = (leg_bl.foot.position.y + leg_br.foot.position.y) / 5
	#hip_force *= speed
	#hip_target.position.y = hips_spring_damper.get_value(hip_force - hip_target.position.y, dt)

	var interpolation = 0
	if not leg_fl.is_stepping: interpolation += 0.5
	if not leg_fr.is_stepping: interpolation += 0.5

	var shoulder_force = min(0.5, pow(min(0, leg_fr.step_offset.z), 8))
	shoulder_force *= speed * 0
	shoulder_target.position.y = shoulders_spring_damper.get_value(shoulder_force - shoulder_target.position.y, dt, interpolation)

	DebugOverlay.write('f', shoulder_force)

	DebugOverlay.draw_line_3d_immediate(
		shoulder_target.global_position,
		shoulder_target.global_position + Vector3.UP * shoulders_spring_damper.acceleration / 20,
		Color.GREEN
	)

	var dir = get_parent_node_3d().transform.basis * Vector3.FORWARD * 0.02

	DebugOverlay.draw_line_3d_immediate(
		shoulder_target.global_position + dir,
		shoulder_target.global_position + dir + Vector3.UP * shoulders_spring_damper.velocity / 1,
		Color.RED
	)

	DebugOverlay.draw_line_3d_immediate(
		shoulder_target.global_position + dir * 2,
		shoulder_target.global_position + dir * 2 + Vector3.UP * shoulder_target.position.y / 1,
		Color.YELLOW
	)

	_curve_spine()

class SpringDamper:
	var acceleration: float
	var velocity: float
	var m: float
	var r: float
	var k: float
	var g: float
	var value: float

	func _init(spring: float, damper: float, mass: float = 1.0, gravity: float = 0):
		r = spring
		k = damper
		m = mass
		velocity = 0
		acceleration = 0
		g = gravity

	func get_value(deviation: float, dt: float, interpolation: float = 1) -> float:
		acceleration = clamp((r * deviation - k * velocity) / m, 0, 100)
		acceleration *= interpolation
		acceleration -= g * m
		velocity += acceleration * dt
		value += velocity * dt

		if value < -0.4:
			velocity = max(0, velocity)
			acceleration = max(0, acceleration)
		elif value > 0.4:
			velocity = min(0, velocity)
			acceleration = min(0, acceleration)

		return value
