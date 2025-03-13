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
@export_range(0, 1) var weight_shifting: float = 1
@export var step_target_offset: float = 0

@export_group('Scheduling')
@export_range(0, 20) var start_at: float = 0
@export_range(0, 20) var fade_out: float = 0.25

@export_group('Hips suspension')
@export_range(0, 50) var hp_spring: float = 25
@export_range(-0.5, 0.3) var hp_spring_height: float = 0
@export_range(0, 30) var hp_damp: float = 5
@export_range(0, 0.3, 0.00005) var hp_kick: float = 0.1
@export_range(0, 1) var hp_weight_shift_offset: float = 0.5

@export_group('Shoulders suspension')
@export_range(0, 50) var sh_spring: float = 25
@export_range(-0.5, 0.5) var sh_spring_height: float = 0
@export_range(0, 30) var sh_damp: float = 5
@export_range(0, 0.3, 0.00005) var sh_kick: float = 0.1
@export_range(0, 1) var sh_weight_shift_offset: float = 0.25


func lerp(gait: Gait, t: float):
	var lerped_gait := Gait.new()

	for prop in self.get_property_list():
		if prop.type == TYPE_FLOAT:
			lerped_gait[prop.name] = (1-t) * self[prop.name] + t * gait[prop.name]

	return lerped_gait
