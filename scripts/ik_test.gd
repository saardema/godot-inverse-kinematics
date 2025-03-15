extends Control
var timer: Timer
var system: IKSystem
var solver: FabrikSolver

func _ready() -> void:
	var vps = get_viewport_rect().size
	system = IKSystem.new()
	system.init(Vector2(vps.x / 2, 300), IKJoint.new(120, -1, 1, -.01, .01))
	system.target = Vector2(800, 300)
	system.extend(IKJoint.new(150, -1.4, 1.4, -0.01, 0.01))
	system.extend(IKJoint.new(90, -1.4, 1.4, -0.01, 0.01))
	system.finish()
	#for i in 60:
		#system.extend(IKJoint.new(-2.5, 2.5, -1, 1), 15)

	solver = FabrikSolver.new(system)

func _process(delta: float) -> void:
	for j in system.joints.size() - 1:
		var values = [
			system.joints[j].rotation,
			system.joints[j]._rotation,
			system.joints[j]._child_angle,
			system.joints[j].rotation_error,
			system.joints[j].length,
			system.joints[j].neg_hard_limit,
			system.joints[j].pos_hard_limit,
			system.joints[j].neg_soft_limit,
			system.joints[j].pos_soft_limit,
		]
		DebugOverlay.write(&'Joint %d' % j, &'%5.2f  _%5.2f  c%5.2f  e%5.2f  l%5.1f [ %5.2f %5.2f %5.2f %5.2f ]' % values)

	#system.target.x = sin(Time.get_ticks_msec() / 400.0) * 400 + 500 + sin(Time.get_ticks_msec() / 123.0) * 80
	#system.target.y = cos(Time.get_ticks_msec() / 1000.0) * 300 + 400 + sin(Time.get_ticks_msec() / 223.0) * 140
	#system.target.x = sin(Time.get_ticks_msec() / 500.0) * 200 + 700
	system.target = get_global_mouse_position()
	solver.run(delta)
	queue_redraw()

func _draw():
	for i in solver.safe_solved_vecs.size():
		var pos = solver.safe_solved_vecs.get(i)
		draw_circle(pos, 3, Color.GREEN)
		if i < solver.safe_solved_vecs.size() - 1:
			var next = solver.safe_solved_vecs.get(i + 1)
			draw_line(pos, next, Color.YELLOW if solver.backup_mode else Color.GRAY)
	draw_rect(Rect2(200, solver._displacement_logger.average / 3, 20, 20), Color.WHITE)

	for joint in system.joints:
		#if joint._child_angle:
			#draw_dashed_line(joint.position, joint.position + Vector2.from_angle(joint._child_angle) * joint.length, Color.DARK_GREEN, 1, 10, false, false)
		#if joint.rotation_error:
			#draw_dashed_line(joint.position, joint.position + Vector2.from_angle(joint.rotation_error) * 50, Color.YELLOW, 1, 15, true, false)

		#var rot = joint.rotation
		#if joint.parent: rot += joint.parent._child_angle
		#draw_dashed_line(joint.position, joint.position + Vector2.from_angle(rot) * joint.length, Color.YELLOW if joint.rotation_error else Color.PURPLE, -1, 5, false, false)
		draw_circle(joint.position, 8, Color.CORNFLOWER_BLUE, false, 1, true)

func _input(event):
	if event is InputEventKey and event.pressed and not event.is_echo():
		pass
		#if event.keycode == KEY_Q: init()
		#elif event.keycode == KEY_W: fabrik_step()

	elif event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_RIGHT:
			system.target = get_global_mouse_position()


func get_intersections(x0, y0, r0, x1, y1, r1):
	# circle 1: (x0, y0), radius r0
	# circle 2: (x1, y1), radius r1

	var d = sqrt((x1-x0)**2 + (y1-y0)**2)

	# non intersecting
	if d > r0 + r1:
		return null
	# One circle within other
	if d < abs(r0-r1):
		return null
	# coincident circles
	if d == 0 and r0 == r1:
		return null
	else:
		var a = (r0**2 - r1**2 + d**2)/(2*d)
		var h = sqrt(r0**2 - a**2)

		var x2 = x0 + a*(x1 - x0)/d
		var y2 = y0 + a*(y1 - y0)/d

		var x3 = x2 + h*(y1 - y0)/d
		var y3 = y2 - h*(x1 - x0)/d

		var x4 = x2 - h*(y1 - y0)/d
		var y4 = y2 + h*(x1 - x0)/d

		return [x3, y3, x4, y4]
