extends StaticBody3D

func _physics_process(delta: float) -> void:
	rotate_z(5 * delta)
	#pass
