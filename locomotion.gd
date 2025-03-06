#@tool
extends Node3D

@export_group('Gaits')

@export_group('Feet')
@export_range(0.01, 1.5) var min_stride: float = 0.2
@export_range(0.01, 1.5) var max_stride_z: float = 1.0
@export_range(0.01, 1.5) var max_stride_x: float = 0.3

@export_group('Input')
@export_range(0, 15) var input_force: float = 0.2
@export_range(0, 0.5) var steering_force: float = 0.3
@export_range(0, 10) var friction: float = 0.01
@export_range(0, 10) var static_friction: float = 0.01
@export_range(0, 10, 0.0001, 'or_greater') var auto_speed: float = 0

@export var gait_manager: GaitManager

@onready var leg_fl: Node3D = $Legs/LegFL
@onready var leg_fr: Node3D = $Legs/LegFR
@onready var leg_bl: Node3D = $Legs/LegBL
@onready var leg_br: Node3D = $Legs/LegBR
@onready var legs: Array[Node3D] = [leg_bl, leg_fl, leg_fr, leg_br]
@onready var target_container: Node3D = $TargetContainer
@onready var body_mesh: CSGBox3D = $Body

var _step_interval: float
var velocity: Vector3
var acceleration: Vector3
var angular_velocity: float
var steering: float
var speed: float:
	get(): return velocity.length()

func _ready():
	gait_manager.step_trigger.connect(_on_step_trigger)

func _on_step_trigger(index: int, gait):
	_step_interval = gait.step_interval
	legs[index].start_step(clamp(gait.step_duration / speed, 0.1, 0.6), gait.foot_lift)

func _physics_process(dt: float):
	acceleration = Vector3.ZERO
	controls()
	physics(dt)
	body()
	feet(dt)

func ease_in_out_cubic(x: float):
	return 4 * pow(x, 3) if x < 0.5 else 1 - pow(-2 * x + 2, 3) / 2

func ease_in_out_sin(x: float):
	return -(cos(PI * x) - 1) / 2

func body():
	var relative_acceleration = acceleration.rotated(Vector3.UP, -rotation.y)
	var roll: float = lerp(body_mesh.rotation.z, relative_acceleration.x * -0.01, 0.04)
	var pitch = clampf(lerp(body_mesh.rotation.x, relative_acceleration.z * 0.008, 0.04), body_mesh.rotation.x - 0.004, body_mesh.rotation.x + 0.004)
	body_mesh.rotation.x = pitch
	body_mesh.position.x = roll * -0.8
	body_mesh.rotation.z = roll

func feet(dt: float):
	DebugOverlay.write('Speed', speed, 2)
	DebugOverlay.write('Step interval', _step_interval)

	if speed > 0.1:
		gait_manager.sync(dt * speed * _step_interval, speed)

	# Offset based stepping below speed 1
	for leg in legs:
		#if speed < 1 and abs(leg.step_offset.z) > max_stride_z:
			#if not leg.ipsilateral_leg.is_stepping and not leg.contralateral_leg.is_stepping:
				#leg.start_step(step_speed, foot_lift)
				#_foot_pointer = walk_gait.find(leg)
#
		# Side stepping
		if abs(leg.step_offset.x) > max_stride_x and not leg.contralateral_leg.is_stepping:
			leg.start_step(0.2, 0.3)

func physics(dt: float):
	if auto_speed:
		acceleration += transform.basis.z * -auto_speed

	acceleration -= friction * velocity
	acceleration -= static_friction * velocity.normalized()

	velocity += acceleration * dt

	angular_velocity += steering / (speed / 15 + 1)

	angular_velocity -= 0.03 * sign(angular_velocity)
	angular_velocity -= 0.03 * angular_velocity

	global_position += velocity * dt
	rotate(Vector3.UP, angular_velocity * dt)


func controls():
	var input = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if input:
		if input.y < 0: input.y *= 1.6
		acceleration += transform.basis * Vector3(input.x, 0, input.y) * input_force

	steering = 0
	if Input.is_key_pressed(KEY_Q):
		steering += steering_force
	if Input.is_key_pressed(KEY_E):
		steering -= steering_force

	if Input.is_key_pressed(KEY_1):
		auto_speed = 0

	if Input.is_key_pressed(KEY_2):
		auto_speed = 0.035

	if Input.is_key_pressed(KEY_3):
		auto_speed = 0.04

	if Input.is_key_pressed(KEY_4):
		auto_speed = 0.06

	if Input.is_key_pressed(KEY_5):
		auto_speed = -0.04

func _input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			input_force = input_force * 1.005 + 0.005
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			input_force = input_force / 1.005 - 0.005
			if input_force < 0.01:
				input_force = 0
