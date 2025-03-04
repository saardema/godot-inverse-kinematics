#@tool
extends Camera3D

@export var look_target: Node3D
@export var position_target: Node3D
@export var base_fov: float = 75
@export var min_zoom_distance: float = 8
@export var min_fov: float = 30

var velocity: Vector3

func _physics_process(dt: float) -> void:
	if look_target: look_at_target()
	if position_target: follow_target(dt)

func look_at_target():
	look_at(look_target.global_position)

	var distance = global_position.distance_to(look_target.global_position)
	if distance > min_zoom_distance:
		fov = max(min_fov, base_fov - (distance - min_zoom_distance) * 5)
	else:
		fov = base_fov

func follow_target(dt: float):
	var delta_pos := position_target.global_position - global_position
	if delta_pos.is_equal_approx(Vector3.ZERO): return

	var dir = delta_pos.normalized()
	var len_sqr = delta_pos.length_squared()
	velocity = (dir * len_sqr).limit_length(13) + delta_pos * 5

	global_position += velocity * dt
	#velocity *= 0.94
