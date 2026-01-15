## Execution Tracer for Code Visualization
## Author: Claude Code
## Date: January 2026

class_name ExecutionTracer
extends Node

signal line_executed(line: int, variables: Dictionary)
signal execution_started()
signal execution_paused()
signal execution_resumed()
signal execution_finished()
signal car_moved(from: Vector2i, to: Vector2i, action: String)

enum State { IDLE, RUNNING, PAUSED, STEPPING }

var current_state: State = State.IDLE
var current_line: int = -1
var execution_speed: float = 1.0  # Lines per second
var step_delay: float = 0.5      # Delay between steps in auto mode

var execution_history: Array[Dictionary] = []  # {line, variables, action, position}
var variable_snapshots: Dictionary = {}

# Reference to the game interpreter
var interpreter: Node  # Your Python interpreter implementation

func _init(interp: Node = null) -> void:
	interpreter = interp

func start_execution(code: String) -> void:
	execution_history.clear()
	variable_snapshots.clear()
	current_line = 0
	current_state = State.RUNNING
	execution_started.emit()

	# Start the interpreter (if available)
	if interpreter:
		interpreter.call("execute", code)

func pause_execution() -> void:
	if current_state == State.RUNNING:
		current_state = State.PAUSED
		if interpreter:
			interpreter.call("pause")
		execution_paused.emit()

func resume_execution() -> void:
	if current_state == State.PAUSED:
		current_state = State.RUNNING
		if interpreter:
			interpreter.call("resume")
		execution_resumed.emit()

func step_execution() -> void:
	if current_state == State.PAUSED or current_state == State.IDLE:
		current_state = State.STEPPING
		if interpreter:
			interpreter.call("step")

func stop_execution() -> void:
	current_state = State.IDLE
	if interpreter:
		interpreter.call("stop")
	execution_finished.emit()

# Called by interpreter when a line is about to execute
func on_line_execute(line: int, vars: Dictionary, action: String = "", car_pos: Vector2i = Vector2i.ZERO) -> void:
	current_line = line
	variable_snapshots = vars.duplicate(true)

	var history_entry = {
		"line": line,
		"variables": vars.duplicate(true),
		"action": action,
		"position": car_pos,
		"timestamp": Time.get_ticks_msec()
	}
	execution_history.append(history_entry)

	line_executed.emit(line, vars)

	if action != "" and action.begins_with("move"):
		var prev_pos = Vector2i.ZERO
		if execution_history.size() > 1:
			prev_pos = execution_history[-2].position
		car_moved.emit(prev_pos, car_pos, action)

func get_variable_at_step(step_index: int) -> Dictionary:
	if step_index >= 0 and step_index < execution_history.size():
		return execution_history[step_index].variables
	return {}

func get_execution_path() -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	for entry in execution_history:
		if entry.position != Vector2i.ZERO and (path.is_empty() or path[-1] != entry.position):
			path.append(entry.position)
	return path

func set_execution_speed(speed: float) -> void:
	execution_speed = clamp(speed, 0.1, 10.0)
	step_delay = 1.0 / execution_speed
