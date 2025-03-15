class_name IKJoint

var rotation: float:
	set(val): _rotation = val
	get: return clampf(_rotation, neg_hard_limit, pos_hard_limit)
var position: Vector2
var length: float
var neg_hard_limit: float
var pos_hard_limit: float
var child: IKJoint
var parent: IKJoint
var _child_angle: float
var _rotation: float
var neg_soft_limit: float
var pos_soft_limit: float
var rotation_error: float:
	get:
		var error := _rotation - rotation
		if neg_soft_limit and rotation < neg_soft_limit:
			error -= (_rotation - neg_soft_limit) / (neg_hard_limit - neg_soft_limit) / 50
		if pos_soft_limit and _rotation > pos_soft_limit:
			error += (_rotation - pos_soft_limit) / (pos_hard_limit - pos_soft_limit) / 50
		return clamp(error, -.5, .5)
		#return error

func _init(len: float, min_rot: float = - PI, max_rot: float = PI, neg_soft_limit_rot: float = 0, pos_soft_limit_rot: float = 0):
	length = len
	neg_hard_limit = min_rot
	pos_hard_limit = max_rot
	neg_soft_limit = neg_soft_limit_rot
	pos_soft_limit = pos_soft_limit_rot

func get_angle_to_child():
	return position.angle_to_point(child.position)

func settle_length_to_parent():
	if parent: position = parent.position + Vector2.from_angle(parent._child_angle) * parent.length

func settle_length_to_child():
	position = child.position + Vector2.from_angle(PI + _child_angle) * length
