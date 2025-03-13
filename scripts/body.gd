extends Node3D
@export_range(0, 2) var hip_influence: float
@export_range(0, 2) var shoulder_influence: float
@export var pelvic_rotation: Vector3
@export var pelvic_rotation_origin: Vector3

@export var shoulder_rotation: Vector3

@export var leg_fl: Node3D
@export var leg_fr: Node3D
@export var leg_bl: Node3D
@export var leg_br: Node3D
@export var body_parts: Array[Node3D]
@export var offsets: Array[float]

@onready var shoulder_target: Marker3D = $ShoulderTarget
@onready var hip_target: Marker3D = $HipTarget
@onready var path: Path3D = $Spine

var hips_acceleration_y: float = 0
var hips_velocity_y: float = 0
@export var hips_gravity: float = 30
var shoulders_acceleration_y: float = 0
var shoulders_velocity_y: float = 0
@export var shoulders_gravity: float = 30

func _ready():
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
		part.rotate_z(hip_target.rotation.z * max(0, 0.8 - offset))

func simulate_leg(leg, target_joint, joint_y_vel, spring_const, damp_const, kick_const, spring_height_const, gait, speed) -> float:
	var force: float = 0

	if not leg.is_stepping and target_joint.position.y < 0.1:
		var compression = 1 / target_joint.global_position.distance_squared_to(leg.foot.global_position)
		var kick_force: float = 0
		var spring_force: float = 0
		var damp_force: float = max(0, -joint_y_vel * damp_const * 1.5)

		if joint_y_vel < 3:
			kick_force = pow(max(0, -leg.step_offset.z * gait.step_interval * 15), 2) * kick_const * speed
			spring_force = max(0, -target_joint.position.y + spring_height_const) * spring_const * 1.5

		force += kick_force + damp_force + spring_force

		if leg in [leg_bl, leg_fl]:
			var dir = get_parent_node_3d().transform.basis * Vector3.FORWARD * 0.03

			DebugOverlay.draw_line_3d_immediate(
				target_joint.global_position,
				target_joint.global_position + Vector3.UP * kick_force / 100.0,
				Color.BLUE_VIOLET
			)

			DebugOverlay.draw_line_3d_immediate(
				target_joint.global_position + dir,
				target_joint.global_position + dir + Vector3.UP * spring_force / 100,
				Color.GREEN
			)

			DebugOverlay.draw_line_3d_immediate(
				target_joint.global_position + dir * 2,
				target_joint.global_position + dir * 2 + Vector3.UP * damp_force / 100,
				Color.RED
			)

			#DebugOverlay.draw_line_3d_immediate(
				#target_joint.global_position + dir * 3,
				#target_joint.global_position + dir * 3 + Vector3.UP * compression / 10,
				#Color.YELLOW
			#)

	return force

func update(dt: float, speed: float, gait: Gait, clock: float):
	update_hips(dt, speed, gait, clock)
	update_shoulders(dt, speed, gait, clock)
	_curve_spine()

func update_shoulders(dt: float, speed: float, gait: Gait, clock: float):
	shoulders_acceleration_y = 0
	var force_fl := simulate_leg(leg_fl, shoulder_target, shoulders_velocity_y, gait.sh_spring, gait.sh_damp, gait.sh_kick, gait.sh_spring_height, gait, speed)
	var force_fr := simulate_leg(leg_fr, shoulder_target, shoulders_velocity_y, gait.sh_spring, gait.sh_damp, gait.sh_kick, gait.sh_spring_height, gait, speed)

	var front_distribution: float = sin((clock + gait.sh_weight_shift_offset) * PI * 2) * gait.weight_shifting / 2 + 0.5
	if leg_fl.is_stepping != leg_fr.is_stepping:
		force_fl *= 1 + (1-gait.weight_shifting)
		force_fr *= 1 + (1-gait.weight_shifting)

	shoulders_acceleration_y = force_fl * front_distribution + force_fr * (1 - front_distribution)

	shoulders_acceleration_y += -shoulders_gravity
	shoulders_velocity_y += shoulders_acceleration_y * dt
	shoulder_target.position.y += shoulders_velocity_y * dt

	if shoulder_target.position.y > 0.8:
		shoulders_acceleration_y = min(0, shoulders_acceleration_y)
		shoulders_velocity_y = min(0, shoulders_velocity_y)
		shoulder_target.position.y = 0.8

	if shoulder_target.position.y < -0.7:
		shoulders_acceleration_y = max(0, shoulders_acceleration_y)
		shoulders_velocity_y = max(0, shoulders_velocity_y)
		shoulder_target.position.y = -0.7

	shoulder_target.position.x = (front_distribution - 0.5) * shoulder_rotation.z


func update_hips(dt: float, speed: float, gait: Gait, clock: float):
	hips_acceleration_y = 0
	var force_bl := simulate_leg(leg_bl, hip_target, hips_velocity_y, gait.hp_spring, gait.hp_damp, gait.hp_kick, gait.hp_spring_height, gait, speed)
	var force_br := simulate_leg(leg_br, hip_target, hips_velocity_y, gait.hp_spring, gait.hp_damp, gait.hp_kick, gait.hp_spring_height, gait, speed)
	var rear_distribution: float = sin((clock + gait.hp_weight_shift_offset) * PI * 2 ) * gait.weight_shifting / 2 + 0.5

	if leg_bl.is_stepping != leg_br.is_stepping:
		force_bl *= 1 + (1-gait.weight_shifting)
		force_br *= 1 + (1-gait.weight_shifting)
	hips_acceleration_y = force_bl * rear_distribution + force_br * (1-rear_distribution)

	hips_acceleration_y += -hips_gravity
	hips_velocity_y += hips_acceleration_y * dt
	hip_target.position.y += hips_velocity_y * dt

	if hip_target.position.y > 0.8:
		hips_acceleration_y = min(0, hips_acceleration_y)
		hips_velocity_y = min(0, hips_velocity_y)
		hip_target.position.y = 0.8

	if hip_target.position.y < -0.8:
		hips_acceleration_y = max(0, hips_acceleration_y)
		hips_velocity_y = max(0, hips_velocity_y)
		hip_target.position.y = -0.8

	# Pelvic tilt
	var ha = hip_target.position.y + position.y + 0.1
	var hto = hip_target.position.z - ((leg_bl.foot.position.z + leg_br.foot.position.z) / 2)
	hip_target.rotation.x = atan2(ha, hto) * pelvic_rotation.x + pelvic_rotation_origin.x

	var hpo = leg_br.foot.position.z - leg_bl.foot.position.z
	hip_target.rotation.y = sin(hpo) * pelvic_rotation.y + pelvic_rotation_origin.y

	hip_target.rotation.z = (rear_distribution - 0.5) * pelvic_rotation.z
	hip_target.position.x = (rear_distribution - 0.5) * pelvic_rotation_origin.z
