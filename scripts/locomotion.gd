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

@onready var legs: Array[Node3D] = [leg_bl, leg_fl, leg_fr, leg_br]
@onready var target_container: Node3D = $TargetContainer
@onready var body: Node3D = $Body

@export_group('Path')
@export var path: Path3D
var target_path_point: Vector3
var path_point_index: int = 0

var _step_interval: float
var velocity: Vector3
var acceleration: Vector3
var angular_velocity: float
var steering: float
var speed: float:
	get(): return velocity.length()

func _ready():
	gait_manager.step_trigger.connect(_on_step_trigger)

func follow_path():
	if not target_path_point:
		target_path_point = path.curve.get_point_position(0)

	if position.distance_to(target_path_point) < 15:
		path_point_index += 1
		path_point_index %= path.curve.point_count
		target_path_point = path.curve.get_point_position(path_point_index)

	var angle = (transform.basis * Vector3.FORWARD).signed_angle_to(position - target_path_point, Vector3.UP)
	steering = clamp(pow(angle, 2) * -sign(angle), -steering_force/5, steering_force/5)

func _physics_process(dt: float):
	DebugOverlay.write('FPS', Engine.get_frames_per_second())

	acceleration = Vector3.ZERO
	steering = 0

	if speed > 0.1:
		gait_manager.sync(dt * speed * _step_interval, speed)

	if path: follow_path()

	avoid_edge()
	controls()
	physics(dt)
	body.update(dt, speed)
	feet()

func _on_step_trigger(index: int):
	_step_interval = gait_manager.current_gait.step_interval
	legs[index].start_step(clamp(gait_manager.current_gait.step_duration / speed, 0.1, 0.6), gait_manager.current_gait.foot_lift)

func feet():
	DebugOverlay.write('Speed', speed, 2)
	DebugOverlay.write('Step interval', _step_interval)

	target_container.position = (velocity * transform.basis / 3).limit_length(.5)

	for leg in legs:
		if abs(leg.step_offset.x) > max_stride_x and not leg.contralateral_leg.is_stepping:
			leg.start_step(0.32, 0.3)

func physics(dt: float):
	if auto_speed:
		acceleration += -transform.basis.z * auto_speed * input_force

	acceleration -= friction * velocity
	acceleration -= static_friction * velocity.normalized()

	velocity += acceleration * dt

	angular_velocity += steering / (speed / 15 + 1) * dt

	#angular_velocity -= 0.03 * sign(angular_velocity)
	angular_velocity -= 0.03 * angular_velocity

	global_position += velocity * dt
	rotate(Vector3.UP, angular_velocity * dt)

func controls():
	var input = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if input:
		if input.y > 0: input.y -= 0.3
		acceleration += (transform.basis * Vector3(input.x, 0, input.y)) * input_force
		if Input.is_key_pressed(KEY_SHIFT):
			acceleration *= 1.5

	if Input.is_key_pressed(KEY_Q):
		steering += steering_force
	if Input.is_key_pressed(KEY_E):
		steering -= steering_force

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

	if Input.is_key_pressed(KEY_9):
		Engine.time_scale = 0.5

	if Input.is_key_pressed(KEY_8):
		Engine.time_scale = 0.25

	if Input.is_key_pressed(KEY_7):
		Engine.time_scale = 0.1


func _input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP, 6]:
			input_force = input_force * 1.005 + 0.005
		if event.button_index in [MOUSE_BUTTON_WHEEL_DOWN, 7]:
			input_force = input_force / 1.005 - 0.005
			if input_force < 0.01:
				input_force = 0

func avoid_edge():
	var angle = (transform.basis * Vector3.FORWARD).signed_angle_to(-position, Vector3.UP)
	if position.length() > 45:
		if abs(angle) > 1.5 and speed > 3:
			acceleration += -position.normalized() * 7
		steering = clamp(angle * angle * sign(angle), -.12, .12)
