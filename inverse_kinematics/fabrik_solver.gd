class_name FabrikSolver
extends IKSolver

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
