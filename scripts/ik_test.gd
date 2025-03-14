extends Control

var timer: Timer
var system: IKSystem
var solver: IKSolver

func _ready() -> void:
	system = IKSystem.new()
	system.target = Vector2(800, 700)
	system.init(Vector2(300, 500), IKJoint.new(-0.5, 0.5))
	system.extend(IKJoint.new(-2.5, 2.5), 250)
	system.extend(IKJoint.new(), 250)
	solver = FabrikSolver.new(system, 0.1, 1, 20)


func _process(delta: float) -> void:
	for j in system.joints.size() - 1:
		var values = [
			system.joints[j].rotation,
			system.joints[j]._rotation,
			system.joints[j]._child_angle,
			system.joints[j].rotation_error,
			system.joints[j].min_angle,
			system.joints[j].max_angle
		]
		DebugOverlay.write('Joint %d' % j, '%5.2f   |   _r %.2f   c %.2f   e %5.2f   [ %.2f   %.2f ]' % values)

	#system.target.x = sin(Time.get_ticks_msec() / 400.0) * 400 + 500 + sin(Time.get_ticks_msec() / 123.0) * 80
	#system.target.y = cos(Time.get_ticks_msec() / 1000.0) * 300 + 400 + sin(Time.get_ticks_msec() / 223.0) * 140
	system.target = get_global_mouse_position()
	solver.run()
	queue_redraw()


class IKSolver:
	var epsilon: float
	var _eps_sq: float
	var min_passes_per_frame: int
	var max_passes_per_frame: int
	var system: IKSystem
	var _frame_pass: int

	func _init(ik_system: IKSystem, eps: float = 10, min_per_frame: int = 1, max_per_frame: int = 10):
		epsilon = eps
		_eps_sq = eps ** 2
		min_passes_per_frame = min_per_frame
		max_passes_per_frame = max_per_frame
		system = ik_system

	func get_error():
		return (system.joints[-1].position - system.target).length_squared()

	func run():
		_frame_pass = 0

		for i in min_passes_per_frame:
			_frame_pass += 1
			self.single_pass()

		for i in max_passes_per_frame - min_passes_per_frame - 1:
			if get_error() < _eps_sq: break
			_frame_pass += 1
			self.single_pass()
		DebugOverlay.write('PPF', _frame_pass)

	func single_pass():
		pass # lol


class FabrikSolver extends IKSolver:
	func single_pass():
		var joint_count = system.joints.size()

		# Forward
		system.joints[-1].position = system.target
		for i in range(joint_count - 2, -1, -1):
			var joint = system.joints[i]
			joint._child_angle = joint.get_angle_to_child()
			if joint.child._child_angle:
				joint.child.rotation = angle_difference(joint._child_angle, joint.child._child_angle)
				joint._child_angle += joint.child.rotation_error
			joint.settle_length_to_child()

		# Backward
		system.joints[0].position = system.root
		for i in range(joint_count):
			var joint = system.joints[i]
			var angle: float = 0

			if joint.parent:
				if joint.parent.parent: angle = joint.parent.parent._child_angle
				joint.parent.rotation = angle_difference(angle, joint.parent._child_angle)
				joint.parent._child_angle -= joint.parent.rotation_error
			joint.settle_length_to_parent()


class IKJoint:
	var rotation: float:
		set(val): _rotation = val
		get: return clampf(_rotation, min_angle, max_angle)
	var position: Vector2
	var length: float
	var min_angle: float
	var max_angle: float
	var child: IKJoint
	var parent: IKJoint
	var _child_angle: float
	var _rotation: float

	var rotation_error: float:
		get: return (_rotation - rotation)

	func _init(min_rot: float = - PI, max_rot: float = PI):
		min_angle = min_rot
		max_angle = max_rot

	func get_angle_to_child():
		return position.angle_to_point(child.position)

	func settle_length_to_parent():
		if parent: position = parent.position + Vector2.from_angle(parent._child_angle) * parent.length

	func settle_length_to_child():
		position = child.position + Vector2.from_angle(PI + _child_angle) * length


class IKSystem:
	var target: Vector2
	var joints: Array[IKJoint]
	var root: Vector2

	func init(root_pos: Vector2, root_joint: IKJoint,) -> IKSystem:
		joints.clear()
		root = root_pos
		root_joint.position = root_pos
		joints.append(root_joint)

		return self

	func extend(joint: IKJoint, offset: float = 100) -> IKSystem:
		var parent = joints[-1]
		joint.parent = parent
		parent.child = joint
		joint.position = parent.position + Vector2.RIGHT * offset
		parent.length = offset
		joints.append(joint)

		return self

func _draw():
	for joint in system.joints:
		if joint._child_angle:
			draw_dashed_line(joint.position, joint.position + Vector2.from_angle(joint._child_angle) * joint.length, Color.DARK_GREEN, 1, 10, false, false)
		#if joint.rotation_error:
			#draw_dashed_line(joint.position, joint.position + Vector2.from_angle(joint.rotation_error) * 50, Color.YELLOW, 1, 15, true, false)

		var rot = joint.rotation
		if joint.parent: rot += joint.parent._child_angle
		draw_dashed_line(joint.position, joint.position + Vector2.from_angle(rot) * joint.length, Color.YELLOW if joint.rotation_error else Color.PURPLE, -1, 5, false, false)
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
