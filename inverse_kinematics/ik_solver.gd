class_name IKSolver

var epsilon: float
var _eps_sq: float
var min_per_frame: int
var max_per_frame: int
var system: IKSystem
var _frame_pass_counter: int
var _time_counter: int
var _system_length_sq: int
var _last_end_position: Vector2
var _before_last_end_position: Vector2
var safe_solved_vecs: PackedVector2Array
var _duration_logger: DataLogger
var _displacement_logger: DataLogger
var _average_displacement: float
var average_end_movement_threshold: float = 50000
var backup_mode: bool
var _target_history: PackedVector2Array

func _init(ik_system: IKSystem, eps: float = 0.1, min_passes_per_frame: int = 1, max_passes_per_frame: int = 1):
	epsilon = eps
	_eps_sq = eps ** 2
	min_per_frame = min_passes_per_frame
	max_per_frame = max(min_per_frame, max_passes_per_frame)
	system = ik_system
	safe_solved_vecs.resize(system.joints.size())
	_displacement_logger = DataLogger.new(5, 1, 0, 5)
	_duration_logger = DataLogger.new(30, 1, 300, 1)

func end_to_target():
	return (system.joints[-1].position - system.target).length_squared()

func root_to_target():
	return (system.joints[0].position - system.target).length_squared()

func run(dt: float):
	_time_counter = Time.get_ticks_usec()
	for i in max_per_frame:
		single_pass()
		_frame_pass_counter = i + 1

		if _frame_pass_counter >= min_per_frame:
			if should_break(): break
	DebugOverlay.write('BU', backup_mode)

	if not backup_mode: store_backup_solution()

	debug_output()

func single_pass():
	pass # lol

#func store_backup_target():

func store_backup_solution():
	for i in system.joints.size():
		safe_solved_vecs.set(i, system.joints[i].position)

func apply_backup_solution():
	for i in system.joints.size():
		var joint = system.joints[i]
		joint.position = safe_solved_vecs.get(i)
		if joint.parent:
			joint.parent.rotation = joint.parent.get_angle_to_child()

func debug_output():
	var template := '%3d pass(es) in %.3fms'
	var time_taken: float = (Time.get_ticks_usec() - _time_counter) / 1000.0
	var average = _duration_logger.update(time_taken).average

	DebugOverlay.write('IK', template % [_frame_pass_counter, average])

func is_oscillating():
	var pos = system.joints[-1].position

func should_break() -> bool:
	var current_pos = system.joints[-1].position
	var displacement = system.joints[-1].position.x + system.joints[-1].position.y
	_average_displacement = _displacement_logger.update(displacement).average
	var displacement_deviation = abs(displacement - _average_displacement)
	DebugOverlay.write('AP', '%6.2f' % _average_displacement)

	var end_movement = current_pos - _before_last_end_position
	_before_last_end_position = _last_end_position
	_last_end_position = current_pos

	if displacement_deviation < 1:
		return true

	backup_mode = displacement_deviation > average_end_movement_threshold
	if backup_mode:
		return true

	if abs(end_movement.x) + abs(end_movement.y) < epsilon:
		return true

	return false

class DataLogger:
	var values: Array[float]
	var _downsampling: int
	var _pointer: int
	var average: float:
		get: return _get_average()
	var _average: float
	var _accumulator: float
	var _count: int
	var _cache_invalid: bool
	var _last_update: int
	var _current_time: int
	var refresh_rate: int
	var _mode: int

	enum MODE {
		INTERPOLATE = 1
	}

	func _init(count: int, mode: int = 0, refresh_rate_ms: int = 0, downsampling: int = 1):
		values.resize(count)
		_downsampling = clamp(downsampling, 1, count)
		_mode = mode
		_count = count
		refresh_rate = refresh_rate_ms

	func update(value: float) -> DataLogger:
		refresh_rate = 1
		_downsampling = 3
		values[_pointer] = value
		_pointer = (_pointer + 1) % _count
		_current_time = Time.get_ticks_msec()

		if _current_time > _last_update + refresh_rate:
			_last_update = _current_time
			_cache_invalid = true

		return self

	func _get_average() -> float:
		if _cache_invalid:
			_cache_invalid = false
			_accumulator = 0

			for i in range(0, _count, _downsampling):
				_accumulator += values[i]
			_average = _accumulator / _count * _downsampling

		return _average
