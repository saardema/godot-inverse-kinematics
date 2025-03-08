class_name Gait
extends Resource
@export var name: String

@export_group('Phases')
@export_range(0, 0.99) var front_offset: float = 0.25
@export_range(0, 0.99) var front_right_offset: float = 0.5
@export_range(0, 0.99) var rear_right_offset: float = 0.5

@export_group('Characteristics')
@export_range(0, 0.99) var step_duration: float = 0.3
@export_range(0.2, 3) var step_interval: float = 1
@export_range(0, 1) var foot_lift: float = 0.2

@export_group('Scheduling')
@export_range(0, 20) var start_at: float = 0
@export_range(0, 20) var fade_out: float = 0.25

@export_group("Body")
@export var body_y_curve := Curve.new()
@export var body_rotation_curve := Curve.new()

var body_rotation: float
var body_y: float
