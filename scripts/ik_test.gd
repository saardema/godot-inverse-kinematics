extends Control

@onready var _vp := get_viewport()

var mouse: Vector2
var nodes: Array[IKNode]
var target = Vector2(600, 400)
var lengths: Array[float] = [50, 70, 30]
var root = Vector2(700, 500)
var _is_fabriking: bool
var timer: Timer

func _ready() -> void:
	timer = Timer.new()
	add_child(timer)
	timer.wait_time = 0.2
	timer.start()
	timer.timeout.connect(_on_timer_timeout)
	init()

func _on_timer_timeout():
	#fabrik()
	timer.start()

func init():
	nodes = [
		IKNode.new(root, 15, -1, 1),
		IKNode.new(root, 180, 0.3, 2),
		IKNode.new(root, 80, 0.3, 1),
		IKNode.new(root, 50),
	]

	queue_redraw()


func _process(delta: float) -> void:
	target = get_global_mouse_position()
	forward()
	backward()

func fabrik():
	await forward(true)
	await backward(true)
	queue_redraw()

func forward(async: bool = false):
	nodes[-1].pos = target
	for i in range(nodes.size() - 2, -1, -1):
		var a = nodes[i+1]
		var b = nodes[i]
		var prev_angle = (nodes[i-1].pos if i > 0 else root).angle_to_point(b.pos)
		var angle_diff = angle_difference(prev_angle, b.pos.angle_to_point(a.pos))
		angle_diff = clamp(angle_diff, nodes[i].min_angle, nodes[i].max_angle)
		var angle = prev_angle + angle_diff
		b.pos = a.pos + Vector2.from_angle(angle + PI) * a.len

		queue_redraw()
		if async: await timer.timeout

func backward(async: bool = false):
	nodes[0].pos = root
	var prev_angle = 0
	for i in range(1, nodes.size()):
		var a = nodes[i-1]
		var b = nodes[i]
		var angle_diff = angle_difference(prev_angle, a.pos.angle_to_point(b.pos))
		angle_diff = clamp(angle_diff, nodes[i-1].min_angle, nodes[i-1].max_angle)
		var angle = prev_angle + angle_diff
		b.pos = a.pos + Vector2.from_angle(angle) * b.len

		prev_angle = angle
		queue_redraw()
		if async: await timer.timeout

func _draw():
	for i in nodes.size():
		var node = nodes[i]
		if i < nodes.size() - 1:
			draw_line(node.pos, nodes[i + 1].pos, Color.PURPLE, 1, true)
		draw_circle(node.pos, 5, Color.GREEN, true, -1, true)

func _input(event):
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode == KEY_R: init()
		elif event.keycode == KEY_Q: fabrik()

class IKNode:
	var pos: Vector2
	var len: float
	var min_angle: float
	var max_angle: float
	#var angle: float

	func _init(position: Vector2, length: float, min: float = -PI, max: float = PI):
		pos = position
		len = length
		min_angle = min
		max_angle = max
	#var target: Vector2
	#var angle: float:
		#get: return target.angle()
		#set(value): target = Vector2.from_angle(value) * length
	#var length: float:
		#get: return target.len()
		#set(value): target = (target.normalized() if target else Vector2.RIGHT) * value

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
