extends MeshInstance3D
@onready var path_follow_3d: PathFollow3D = $".."
var prev_pos: Vector3
var vel: Vector3

var toggle := false
func _physics_process(delta: float) -> void:
	path_follow_3d.progress += 1 * delta
	rotate_x(vel.length() / -mesh.radius)
	vel = abs(global_position - prev_pos)
	prev_pos = global_position
