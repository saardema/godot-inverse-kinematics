#@tool
extends Node3D
@onready var plant_target: Marker3D = $"Plant target"
@onready var foot: Node3D = $Foot

@export var stride_xz_curve: Curve
@export var stride_y_curve: Curve
@export var step_target: Marker3D
@export var ipsilateral_leg: Node3D
@export var contralateral_leg: Node3D
@export var crosslateral_leg: Node3D

var _step_speed: float = 1.0
var _foot_lift: float = 0.3
var _step_start_position: Vector3
var _linear_step_progress: float = 0

var step_offset: Vector3:
	get: return (step_target.position - foot.position)
var is_stepping: bool = false

func start_step(speed: float, foot_lift: float):
	if not is_stepping:
		_step_start_position = foot.global_position
		_step_speed = speed
		_foot_lift = foot_lift
		_linear_step_progress = 0
	is_stepping = true

func _physics_process(delta: float):
	if _linear_step_progress < 1:
		_linear_step_progress = min(1, _linear_step_progress + delta * _step_speed)
		plant_target.global_position = step_target.global_position
	else:
		is_stepping = false

	var progress_xz = stride_xz_curve.sample(_linear_step_progress)
	foot.global_position = lerp(_step_start_position, plant_target.position, progress_xz)
	foot.position.y = stride_y_curve.sample(_linear_step_progress) * _foot_lift
