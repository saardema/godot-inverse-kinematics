class_name GaitManager
extends Resource

signal step_trigger(index: int)

@export var gaits: Array[Gait]

var _step_tracker := [false, false, false, false]
var clock: float
var current_gait: Gait = Gait.new()

func sync(tick: float, speed: float):
	clock += tick * current_gait.step_interval * speed

	if clock > 1 and not _step_tracker.has(false):
		clock = fmod(clock, 1)
		_step_tracker = [false, false, false, false]

	_update_gait(speed)

	if not _step_tracker[0]:
		_step_tracker[0] = true
		step_trigger.emit(0)

	if not _step_tracker[1] and clock > current_gait.front_offset:
		_step_tracker[1] = true
		step_trigger.emit(1)

	if not _step_tracker[2] and \
		clock > fmod(current_gait.front_offset + current_gait.front_right_offset, 1):
		_step_tracker[2] = true
		step_trigger.emit(2)

	if not _step_tracker[3] and clock > current_gait.rear_right_offset:
		_step_tracker[3] = true
		step_trigger.emit(3)


func _update_gait(speed: float):
	var updated_gait = gaits[0]

	if not current_gait: current_gait = gaits[0]

	for gait in gaits:
		if gait.start_at < speed and gait.start_at > updated_gait.start_at: updated_gait = gait

	var index = gaits.find(updated_gait)

	DebugOverlay.write('Step timer', clock)
	DebugOverlay.write('Gait', updated_gait.name)
	DebugOverlay.write('Fade', 'None')

	if index < gaits.size() - 1 and speed > gaits[index + 1].start_at - updated_gait.fade_out:
		var next_gait = gaits[index + 1]
		var fade = (speed - next_gait.start_at + updated_gait.fade_out) / updated_gait.fade_out
		DebugOverlay.write('Fade', fade)
		DebugOverlay.write('Gait', '%s -> %s' % [updated_gait.name, next_gait.name])

		current_gait = updated_gait.lerp(next_gait, fade)

	else:
		current_gait = updated_gait
