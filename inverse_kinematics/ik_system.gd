class_name IKSystem

var target: Vector2
var joints: Array[IKJoint]
var root: Vector2

func init(root_pos: Vector2, root_joint: IKJoint) -> IKSystem:
	joints.clear()
	root = root_pos
	root_joint.position = root_pos
	joints.append(root_joint)


	return self

func extend(joint: IKJoint) -> IKSystem:
	var parent = joints[-1]
	joint.parent = parent
	parent.child = joint
	joint.position = parent.position + Vector2.RIGHT * joint.length
	joints.append(joint)

	return self

func finish():
	var end_joint = IKJoint.new(0)
	end_joint.parent = joints[-1]
	joints[-1].child = end_joint
	joints.append(end_joint)
