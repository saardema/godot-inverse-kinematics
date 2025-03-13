extends Node3D

@onready var tripod_cam: Camera3D = $TripodCam
@onready var follow_cam: Camera3D = $FollowCam

func _input(event: InputEvent):
	if event is InputEventKey:
		if event.keycode == KEY_BRACKETLEFT:
			tripod_cam.current = true
		elif event.keycode == KEY_BRACKETRIGHT:
			follow_cam.current = true
