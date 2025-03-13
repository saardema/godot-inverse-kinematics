#@tool
class_name Leg
extends Node3D
@onready var plant_target: Marker3D = $"Plant target"
@onready var foot: Node3D = $Foot
@onready var _geometry: CSGBox3D = $Foot/CSGBox3D

@export var stride_xz_curve: Curve
@export var stride_y_curve: Curve
@export var step_target: Marker3D
@export var ipsilateral_leg: Node3D
@export var contralateral_leg: Node3D
@export var crosslateral_leg: Node3D


var _foot_lift: float = 0.3
var _step_start_position: Vector3
var _step_timer: float = 0
var _step_duration: float = 0.25
var _linear_step_progress: float = 0

var is_stepping: bool = false
var step_offset: Vector3:
	get: return (step_target.position - foot.position - position)

func set_color(colorIndex: int):
	var color: Color

	match colorIndex:
		1: color = Color.DARK_RED
		2: color = Color.DARK_BLUE
		0, _: color = Color.DARK_GREEN

	_geometry.material.albedo_color = color

func start_step(duration: float, foot_lift: float, type: int = 0):
	if not is_stepping:
		_step_duration = min(duration, 1)
		set_color(type)
		_step_start_position = foot.global_position
		_step_timer = 0
		_foot_lift = foot_lift
	is_stepping = true

func _physics_process(delta: float):
	if _step_timer < _step_duration:
		_step_timer += delta
		plant_target.global_position = step_target.global_position
		_linear_step_progress = min(_step_timer / _step_duration, 1)
	else:
		is_stepping = false

	var progress_xz = stride_xz_curve.sample(_linear_step_progress)
	foot.global_position = lerp(_step_start_position, plant_target.position, progress_xz)
	foot.position.y = stride_y_curve.sample(_linear_step_progress) * _foot_lift

	#if ipsilateral_leg.name == 'LegBL':
		#DebugOverlay.write('leg', foot.position)
