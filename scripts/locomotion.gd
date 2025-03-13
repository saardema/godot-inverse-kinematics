extends Node3D

@export_group('Feet')
@export_range(0.01, 1.5) var min_stride: float = 0.2
@export_range(0.01, 1.5) var max_stride_z: float = 1.0
@export_range(0.01, 1.5) var max_stride_x: float = 0.3
@export var leg_fl: Node3D
@export var leg_fr: Node3D
@export var leg_bl: Node3D
@export var leg_br: Node3D

@export_group('Input')
@export_range(0, 15) var input_force: float = 0.2
@export_range(0, 100) var steering_force: float = 0.3
@export_range(0, 10) var friction: float = 0.01
@export_range(0, 10) var static_friction: float = 0.01
@export_range(0, 10, 0.0001, 'or_greater') var auto_speed: float = 0

@export_group('Gaits')
@export var gait_manager: GaitManager = GaitManager.new()

@onready var legs: Array[Leg] = [leg_bl, leg_fl, leg_fr, leg_br]
@onready var step_targets: Node3D = $StepTargets
@onready var body: Node3D = $Body
@onready var ball: MeshInstance3D = $"../Ball"
@onready var body_meshes: Node3D = $Body/BodyMeshes

@export_group('Path')
@export var path: Path3D
var target_path_point: Vector3
var path_point_index: int = 0

var input: Vector2
var _step_interval: float
var _bank_angle: float
var velocity: Vector3
var acceleration: Vector3
var acceleration_local: Vector3
var angular_velocity: float
var steering: float
var speed: float

func _ready():
	gait_manager.step_trigger.connect(_on_step_trigger)

func _physics_process(dt: float):
	acceleration_local = Vector3.ZERO
	steering = 0

	gait_manager.sync(dt, speed)

	#if path: follow_path()
	#walk_in_circle(45)
	avoid_edge()
	controls()

	apply_physics(dt)

	body.update(dt, speed, gait_manager.current_gait, gait_manager.clock)
	bank_angle(dt)
	feet()

func bank_angle(dt: float):
	var angle_force: float = clamp((acceleration * transform.basis).x * (speed * speed + 1)/ 500, -2, 2)
	_bank_angle = lerp(_bank_angle, angle_force, dt * 3)
	body_meshes.position.x = sin(_bank_angle) / 2
	body_meshes.position.y = abs(cos(_bank_angle) / 3) - .3
	body_meshes.rotation.z = -sin(_bank_angle) / 2
	body_meshes.rotation.y = sin(_bank_angle) / 2

func _on_step_trigger(index: int):
	_step_interval = gait_manager.current_gait.step_interval
	legs[index].start_step(clamp(gait_manager.current_gait.step_duration / (speed + 1) * 2, 0.1, 0.6), gait_manager.current_gait.foot_lift)

func feet():
	DebugOverlay.write('Speed', speed, 2)
	DebugOverlay.write('Step interval', _step_interval)

	step_targets.position = (velocity * transform.basis * gait_manager.current_gait.step_target_offset)
	step_targets.rotation.y = clamp(_bank_angle, -0.3, 0.3)

	for leg in legs:
		if abs(leg.step_offset.z) > max_stride_z and not leg.contralateral_leg.is_stepping:
			leg.start_step(0.2, 0.3, 1)
		if abs(leg.step_offset.x) > max_stride_x and not leg.contralateral_leg.is_stepping:
			leg.start_step(0.2, 0.3, 2)

func apply_physics(dt: float):
	if auto_speed:
		acceleration_local.z += -auto_speed * input_force
	DebugOverlay.write('Acc', acceleration_local)

	acceleration = transform.basis * acceleration_local
	acceleration -= friction * velocity
	if speed > static_friction:
		acceleration -= velocity.normalized() * static_friction
	velocity += acceleration * dt

	if steering:
		angular_velocity += steering / (speed / 2 + 1) * dt
	else:
		angular_velocity -= 5 * sign(angular_velocity) * dt
	angular_velocity -= 3 * angular_velocity * dt

	global_position += velocity * dt
	speed = velocity.length()
	rotate(Vector3.UP, angular_velocity * dt)

func controls():
	input = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if input:
		if input.y > 0:
			input.y *= 0.7
		elif Input.is_key_pressed(KEY_SHIFT):
			input.y *= 2.5
		acceleration_local += Vector3(input.x, 0, input.y) * input_force

	if Input.is_key_pressed(KEY_A):
		steering += steering_force
	if Input.is_key_pressed(KEY_D):
		steering += -steering_force

	if Input.is_key_pressed(KEY_1):
		auto_speed = 0

	if Input.is_key_pressed(KEY_2):
		auto_speed = 0.5

	if Input.is_key_pressed(KEY_3):
		auto_speed = 1

	if Input.is_key_pressed(KEY_4):
		auto_speed = 1.5

	if Input.is_key_pressed(KEY_5):
		auto_speed = 2

	# Time scale
	if Input.is_key_pressed(KEY_0):
		Engine.time_scale = 1

	if Input.is_key_pressed(KEY_8):
		Engine.time_scale += 0.005

	if Input.is_key_pressed(KEY_7):
		Engine.time_scale -= 0.005
		if Engine.time_scale < 0: Engine.time_scale = 0

func _input(event: InputEvent):
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		Engine.time_scale += event.relative.x / 1000
		Engine.time_scale = clamp(Engine.time_scale, 0, 1)

	if event is InputEventMouseButton:
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP, 6]:
			input_force = input_force * 1.005 + 0.005
		if event.button_index in [MOUSE_BUTTON_WHEEL_DOWN, 7]:
			input_force = input_force / 1.005 - 0.005
			if input_force < 0.01:
				input_force = 0

func avoid_edge():
	var angle = (transform.basis * Vector3.FORWARD).signed_angle_to(-position, Vector3.UP)
	if position.length() > 42:
		if abs(angle) > 1.5 and speed > 3:
			acceleration_local += transform.basis * position.normalized() * 7
		steering = clamp(angle * 10, -steering_force, steering_force)

func walk_in_circle(radius: float):
	var circ_dir := -position.cross(Vector3.UP)
	var radius_steering_offset = transform.basis * Vector3.FORWARD * (radius - position.length()) * 0.3
	var circle_steering = -(transform.basis * Vector3.RIGHT + radius_steering_offset).dot(circ_dir) * 3
	circle_steering = clamp(circle_steering, -steering_force, steering_force)
	steering += circle_steering

func follow_path():
	if not target_path_point:
		target_path_point = path.curve.get_point_position(0)

	if position.distance_to(target_path_point) < 20:
		path_point_index += 1
		path_point_index %= path.curve.point_count
		target_path_point = path.curve.get_point_position(path_point_index)
		ball.position = target_path_point

	var angle = (transform.basis * Vector3.FORWARD).signed_angle_to(target_path_point - global_position, Vector3.UP)
	steering = clamp( angle * 100, -steering_force, steering_force)
