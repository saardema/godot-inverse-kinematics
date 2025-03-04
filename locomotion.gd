#@tool
extends Node3D

@export_group('Feet')
@export_range(0.01, 1.5) var min_stride: float = 0.2
@export_range(0.01, 1.5) var max_stride_z: float = 1.0
@export_range(0.01, 1.5) var max_stride_x: float = 0.3
@export var step_speed_curve: Curve
@export var step_interval_curve: Curve
@export var foot_lift_curve: Curve

@export_group('Input')
@export_range(0, 0.5) var input_force: float = 0.2
@export_range(0, 0.1) var friction: float = 0.01
@export_range(0, 0.1) var static_friction: float = 0.01
@export_range(0, 1, 0.0001, 'or_greater') var auto_speed: float = 0

@onready var leg_fl: Node3D = $Legs/LegFL
@onready var leg_fr: Node3D = $Legs/LegFR
@onready var leg_bl: Node3D = $Legs/LegBL
@onready var leg_br: Node3D = $Legs/LegBR
@onready var walk_gait: Array[Node3D] = [leg_fl, leg_br, leg_fr, leg_bl]
@onready var target_container: Node3D = $TargetContainer
@onready var body_mesh: CSGBox3D = $Body

var _foot_pointer: int:
	set(value): _foot_pointer = posmod(value, 4)
var _step_timer: float
var velocity: Vector3
var acceleration: Vector3
var angular_velocity: float
var steering: float
var speed: float:
	get(): return velocity.length()

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
	var roll: float = lerp(body_mesh.rotation.z, relative_acceleration.x * -2.5, 0.04)
	var pitch = lerp(body_mesh.rotation.x, relative_acceleration.z * 0.8, 0.04)
	body_mesh.rotation.x = pitch
	body_mesh.position.x = roll * -0.8
	body_mesh.rotation.z = roll

func feet(dt: float):
	var step_speed = step_speed_curve.sample(speed)
	var step_interval = step_interval_curve.sample(speed)
	var foot_lift = foot_lift_curve.sample(speed)

	DebugOverlay.write('speed', str('%.5f' % speed))
	DebugOverlay.write('step timer', str('%.2f' % _step_timer))
	DebugOverlay.write('foot pointer', str(_foot_pointer))
	DebugOverlay.write('step speed', str('%.2f' % step_speed))
	DebugOverlay.write('step interval', str('%.2f' % step_interval))

	#target_container.position = velocity.rotated(Vector3.UP, -rotation.y) * 0.1

	# Offset based stepping below speed 1
	for leg in walk_gait:
		if speed < 1 and abs(leg.step_offset.z) > max_stride_z:
			if not leg.ipsilateral_leg.is_stepping and not leg.contralateral_leg.is_stepping:
				leg.start_step(step_speed, foot_lift)
				_foot_pointer = walk_gait.find(leg)

		# Side stepping
		if abs(leg.step_offset.x) > max_stride_x and not leg.contralateral_leg.is_stepping:
			leg.start_step(step_speed * 1, foot_lift)

	if speed > 1:
		_step_timer += step_interval * dt

	if _step_timer >= 1:
		var leg = walk_gait[_foot_pointer]
		leg.start_step(step_speed, foot_lift)
		_foot_pointer += 1
		_step_timer = 0

func physics(dt: float):
	if auto_speed:
		acceleration += Vector3.FORWARD.rotated(Vector3.UP, rotation.y) * auto_speed

	acceleration -= friction * velocity
	if speed > static_friction: acceleration -= static_friction * velocity.normalized()

	velocity += acceleration

	#DebugOverlay.draw_line_3d('acc', global_position + Vector3.UP * 1.5, global_position + Vector3.UP * 1.5 + acceleration * 10, Color.RED)
	#DebugOverlay.draw_line_3d('vel', global_position + Vector3.UP * 1.5, global_position + Vector3.UP * 1.5 + velocity / 3, Color.AQUA)

	angular_velocity += steering / (speed / 8 + 1)

	angular_velocity -= sign(angular_velocity) * 0.03
	angular_velocity *= 0.97

	global_position += velocity * dt
	rotate(Vector3.UP, angular_velocity * dt)


func controls():
	var input = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if input:
		if input.y < 0: input.y *= 1.6
		var dir = Vector3(input.x * 0.8, 0, input.y).rotated(Vector3.UP, rotation.y)
		acceleration = dir * input_force

	steering = 0
	if Input.is_key_pressed(KEY_Q):
		steering += 0.3
	if Input.is_key_pressed(KEY_E):
		steering -= 0.3

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
			input_force = input_force * 1.0005 + 0.0005
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			input_force = input_force / 1.0005 - 0.0005
			if input_force < 0.01:
				input_force = 0
