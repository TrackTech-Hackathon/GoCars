extends Node
class_name SimulationEngine

## Manages code execution and simulation playback.
## Coordinates between PythonParser, PythonInterpreter, and Vehicle entities.

signal simulation_started()
signal simulation_paused()
signal simulation_ended(success: bool)
signal code_executed(commands: Array)
signal car_reached_destination(car_id: String)
signal car_crashed(car_id: String)
signal level_completed(stars: int)
signal level_failed(reason: String)
signal execution_line_changed(line_number: int)
signal execution_error_occurred(error: String, line: int)
signal infinite_loop_detected()
signal print_output(message: String)  # For Python print() statements

# Simulation state
enum State { IDLE, RUNNING, PAUSED, STEP }
var current_state: State = State.IDLE

# Playback speed
var speed_multiplier: float = 1.0
const SPEED_NORMAL: float = 1.0
const SPEED_FAST: float = 2.0
const SPEED_FASTER: float = 4.0
const SPEED_SLOW: float = 0.5

# Step-by-step mode
var _step_mode: bool = false
var _step_timer: float = 0.0
const STEP_DURATION: float = 0.5  # Time per step in seconds

# References
var _python_parser: PythonParser
var _python_interpreter: PythonInterpreter
var _vehicles: Dictionary = {}  # vehicle_id -> Vehicle node
var _stoplights: Dictionary = {}  # stoplight_id -> Stoplight node
var _command_queue: Array = []
var _current_command_index: int = 0

# Step-based execution (execute one statement per interval)
var _current_code: String = ""
var _execution_interval: float = 0.016  # Execute one step every 16ms (~60fps) for smooth movement
var _execution_timer: float = 0.0
var _is_executing: bool = false
var _current_ast: Dictionary = {}

# Level tracking
var _vehicles_at_destination: int = 0
var _total_vehicles: int = 0

# Timer for time-limited levels
var _level_timer: float = 0.0
var _level_time_limit: float = 0.0  # 0 = no limit
var _timer_active: bool = false

# Map boundaries for out-of-bounds detection
var _map_bounds: Rect2 = Rect2(-100, -100, 2000, 2000)  # Default large bounds

# Callback to check if code editor is focused (set by main scene)
# When this returns true, keyboard shortcuts are disabled
var is_editor_focused_callback: Callable = Callable()


func _ready() -> void:
	_python_parser = PythonParser.new()
	_python_interpreter = PythonInterpreter.new()
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Connect interpreter signals
	_python_interpreter.execution_line.connect(_on_interpreter_execution_line)
	_python_interpreter.execution_error.connect(_on_interpreter_execution_error)
	_python_interpreter.print_output.connect(_on_interpreter_print_output)


# ============================================
# Stoplight Registration
# ============================================

## Register a stoplight with the simulation
func register_stoplight(stoplight: Stoplight) -> void:
	_stoplights[stoplight.stoplight_id] = stoplight
	# Connect state change signal
	stoplight.state_changed.connect(_on_stoplight_state_changed)
	# Make all existing vehicles aware of this stoplight
	for vehicle_id in _vehicles:
		_vehicles[vehicle_id].add_stoplight(stoplight)


## Unregister a stoplight
func unregister_stoplight(stoplight_id: String) -> void:
	if stoplight_id in _stoplights:
		_stoplights.erase(stoplight_id)


## Get all registered stoplight IDs
func get_stoplight_ids() -> Array:
	return _stoplights.keys()


## Get a stoplight by ID
func get_stoplight(stoplight_id: String) -> Stoplight:
	if stoplight_id in _stoplights:
		return _stoplights[stoplight_id]
	return null


func _on_stoplight_state_changed(stoplight_id: String, new_state: String) -> void:
	# Can be used for logging or triggering other events
	print("Stoplight %s changed to %s" % [stoplight_id, new_state])


func _process(delta: float) -> void:
	if current_state == State.RUNNING or current_state == State.STEP:
		# Time limit disabled - levels no longer fail due to time
		# if _timer_active and _level_time_limit > 0:
		# 	_level_timer += delta
		# 	if _level_timer >= _level_time_limit:
		# 		_on_level_failed("Time expired!")
		# 		return

		# Out-of-bounds check disabled - cars can leave the map
		# _check_vehicle_boundaries()

		# Step-based code execution (one statement/iteration per interval)
		_execution_timer += delta
		if _execution_timer >= _execution_interval:
			_execution_timer = 0.0
			# Execute main interpreter
			if _is_executing:
				_execute_one_step()
			# Execute each vehicle's interpreter
			_execute_vehicle_interpreters()

		# Handle step mode
		if current_state == State.STEP:
			_step_timer += delta
			if _step_timer >= STEP_DURATION:
				pause()
				_step_timer = 0.0


# ============================================
# Vehicle Registration
# ============================================

## Register a vehicle with the simulation
func register_vehicle(vehicle: Vehicle) -> void:
	_vehicles[vehicle.vehicle_id] = vehicle
	_total_vehicles += 1

	# Connect signals
	vehicle.reached_destination.connect(_on_vehicle_reached_destination)
	vehicle.crashed.connect(_on_vehicle_crashed)

	# Make this vehicle aware of all existing stoplights
	for stoplight_id in _stoplights:
		vehicle.add_stoplight(_stoplights[stoplight_id])


## Unregister a vehicle
func unregister_vehicle(vehicle_id: String) -> void:
	if vehicle_id in _vehicles:
		_vehicles.erase(vehicle_id)
		_total_vehicles -= 1


## Get all registered vehicle IDs
func get_vehicle_ids() -> Array:
	return _vehicles.keys()


# ============================================
# Code Execution
# ============================================

## Parse and execute code using Python parser and interpreter
func execute_code(code: String) -> void:
	_execute_code_python(code)


## Execute code using the new Python parser and interpreter (step-based execution)
func _execute_code_python(code: String) -> void:
	# Store code for step-based execution
	_current_code = code
	_execution_timer = 0.0

	# Parse code with PythonParser
	_current_ast = _python_parser.parse(code)

	# Check for parse errors
	if _current_ast["errors"].size() > 0:
		for error in _current_ast["errors"]:
			push_error("Line %s: %s" % [error["line"], error["message"]])
			execution_error_occurred.emit(error["message"], error["line"])
		_is_executing = false
		return

	# Register game objects with interpreter
	_register_game_objects()

	# Initialize step-based execution
	_python_interpreter.start_execution(_current_ast)
	_is_executing = true

	# Execute first step immediately
	_execute_one_step()

	# Start the simulation
	start()


## Execute one step of code (one statement or one loop iteration)
func _execute_one_step() -> void:
	if not _is_executing:
		return

	# Re-register game objects (in case new vehicles spawned)
	_register_game_objects()

	# Execute one step
	var has_more = _python_interpreter.step()

	# Check for errors
	if _python_interpreter.has_errors():
		var errors = _python_interpreter.get_errors()
		if errors.size() > 0:
			var err = errors[0]
			execution_error_occurred.emit(err.get("message", "Unknown error"), err.get("line", 0))
		_is_executing = false
		return

	# Check if execution is complete
	if not has_more:
		_is_executing = false
		# Execution complete - code finished running


## Register all game objects with the interpreter
func _register_game_objects() -> void:
	_python_interpreter.clear_objects()

	# Register all vehicles as "car" (for simplicity, first vehicle)
	if _vehicles.size() > 0:
		var first_vehicle_id = _vehicles.keys()[0]
		_python_interpreter.register_object("car", _vehicles[first_vehicle_id])

	# Register all stoplights
	if _stoplights.size() > 0:
		var first_stoplight_id = _stoplights.keys()[0]
		_python_interpreter.register_object("stoplight", _stoplights[first_stoplight_id])


## Execute code for a specific vehicle (used for spawned cars)
func execute_code_for_vehicle(code: String, vehicle: Vehicle) -> void:
	# Create a temporary interpreter for this vehicle
	var temp_interpreter = PythonInterpreter.new()
	temp_interpreter.register_object("car", vehicle)

	# Register stoplights too
	if _stoplights.size() > 0:
		var first_stoplight_id = _stoplights.keys()[0]
		temp_interpreter.register_object("stoplight", _stoplights[first_stoplight_id])

	# Connect print output signal
	temp_interpreter.print_output.connect(_on_interpreter_print_output)

	# Parse and start execution
	var ast = _python_parser.parse(code)
	if ast["errors"].size() > 0:
		return

	temp_interpreter.start_execution(ast)

	# Store the interpreter for this vehicle
	vehicle.set_meta("interpreter", temp_interpreter)


## Execute one step for each vehicle's individual interpreter
func _execute_vehicle_interpreters() -> void:
	for vehicle_id in _vehicles:
		var vehicle = _vehicles[vehicle_id]
		if not is_instance_valid(vehicle):
			continue
		if vehicle.vehicle_state == 0:  # Skip crashed vehicles
			continue
		if vehicle.has_meta("interpreter"):
			var interp: PythonInterpreter = vehicle.get_meta("interpreter")
			if interp.is_running():
				interp.step()


## Execute all queued commands
func _execute_all_commands() -> void:
	for command in _command_queue:
		_execute_command(command)

	code_executed.emit(_command_queue)


## Execute a single command
func _execute_command(command: Dictionary) -> void:
	var obj_type = command["object"]
	var func_name = command["function"]
	var params = command["params"]

	# For now, all "car" commands go to all vehicles
	# In the future, we can have car1, car2, etc.
	if obj_type == "car":
		for vehicle_id in _vehicles:
			var vehicle = _vehicles[vehicle_id]
			_call_vehicle_function(vehicle, func_name, params)

	# Stoplight commands go to all stoplights
	# In the future, we can have stoplight1, stoplight2, etc.
	elif obj_type == "stoplight":
		for stoplight_id in _stoplights:
			var stoplight = _stoplights[stoplight_id]
			_call_stoplight_function(stoplight, func_name, params)


## Call a function on a vehicle
func _call_vehicle_function(vehicle: Vehicle, func_name: String, params: Array) -> void:
	match func_name:
		"go":
			vehicle.go()
		"stop":
			vehicle.stop()
		"turn_left":
			vehicle.turn_left()
		"turn_right":
			vehicle.turn_right()
		"turn":
			if params.size() > 0:
				vehicle.turn(params[0])
		"move":
			if params.size() > 0:
				vehicle.move(params[0])
		"wait":
			if params.size() > 0:
				vehicle.wait(params[0])
		"speed":
			if params.size() > 0:
				vehicle.set_speed(params[0])
		"front_road":
			# Query functions - return value but don't need to do anything here
			var _result = vehicle.front_road()
		"left_road":
			var _result = vehicle.left_road()
		"right_road":
			var _result = vehicle.right_road()
		"front_car":
			var _result = vehicle.front_car()
		"front_crash":
			var _result = vehicle.front_crash()
		"set_auto_navigate":
			if params.size() > 0:
				vehicle.set_auto_navigate(params[0])
			else:
				vehicle.set_auto_navigate(true)
		"auto_navigate":
			# Shorthand - enable auto-navigate and start moving
			vehicle.set_auto_navigate(true)
			vehicle.go()


## Call a function on a stoplight
func _call_stoplight_function(stoplight: Stoplight, func_name: String, _params: Array) -> void:
	match func_name:
		"set_red":
			stoplight.set_red()
		"set_green":
			stoplight.set_green()
		"set_yellow":
			stoplight.set_yellow()
		"get_state":
			# get_state returns a value, but for now we just call it
			# In a more advanced system, we could store the return value
			var _state = stoplight.get_state()


# ============================================
# Playback Controls
# ============================================

## Start or resume simulation
func start() -> void:
	if current_state == State.IDLE or current_state == State.PAUSED:
		current_state = State.RUNNING
		Engine.time_scale = speed_multiplier
		get_tree().paused = false
		simulation_started.emit()


## Pause simulation
func pause() -> void:
	if current_state == State.RUNNING:
		current_state = State.PAUSED
		get_tree().paused = true
		simulation_paused.emit()


## Toggle pause state
func toggle_pause() -> void:
	if current_state == State.RUNNING:
		pause()
	elif current_state == State.PAUSED:
		start()


## Stop and reset simulation
func stop() -> void:
	current_state = State.IDLE
	Engine.time_scale = 1.0
	get_tree().paused = false
	_command_queue.clear()
	_current_command_index = 0
	_vehicles_at_destination = 0
	_step_timer = 0.0
	_level_timer = 0.0
	# Stop step-based execution
	_is_executing = false
	_current_code = ""
	_current_ast = {}
	_execution_timer = 0.0
	_python_interpreter.stop_execution()


## Reset all vehicles to starting positions
func reset() -> void:
	stop()
	_step_mode = false
	# Note: Level manager should handle resetting vehicle positions


## Set playback speed
func set_speed(multiplier: float) -> void:
	speed_multiplier = clamp(multiplier, SPEED_SLOW, SPEED_FASTER)
	if current_state == State.RUNNING:
		Engine.time_scale = speed_multiplier


## Increase speed
func speed_up() -> void:
	if speed_multiplier < SPEED_FAST:
		set_speed(SPEED_FAST)
	else:
		set_speed(SPEED_FASTER)


## Decrease speed
func slow_down() -> void:
	if speed_multiplier > SPEED_NORMAL:
		set_speed(SPEED_NORMAL)
	else:
		set_speed(SPEED_SLOW)


## Step forward one frame/action
func step() -> void:
	if current_state == State.PAUSED or current_state == State.IDLE:
		current_state = State.STEP
		_step_timer = 0.0
		Engine.time_scale = 1.0
		get_tree().paused = false


## Toggle step-by-step mode
func toggle_step_mode() -> void:
	_step_mode = not _step_mode
	if _step_mode and current_state == State.RUNNING:
		current_state = State.STEP
		_step_timer = 0.0


## Check if step mode is active
func is_step_mode() -> bool:
	return _step_mode


# ============================================
# Level Configuration
# ============================================

## Set time limit for the level (0 = no limit)
func set_time_limit(seconds: float) -> void:
	_level_time_limit = seconds
	_level_timer = 0.0
	_timer_active = seconds > 0


## Get remaining time
func get_remaining_time() -> float:
	if _level_time_limit <= 0:
		return -1.0
	return max(0.0, _level_time_limit - _level_timer)


## Get elapsed time
func get_elapsed_time() -> float:
	return _level_timer


## Set map boundaries for out-of-bounds detection
func set_map_bounds(bounds: Rect2) -> void:
	_map_bounds = bounds


## Check if any vehicle is out of bounds
func _check_vehicle_boundaries() -> void:
	# Create a list of vehicle IDs to check (to avoid modifying dict during iteration)
	var vehicle_ids = _vehicles.keys()
	for vehicle_id in vehicle_ids:
		if not vehicle_id in _vehicles:
			continue  # Vehicle was removed
		var vehicle = _vehicles[vehicle_id]
		# Check if vehicle is still valid (not freed)
		if not is_instance_valid(vehicle):
			_vehicles.erase(vehicle_id)
			continue
		if not _map_bounds.has_point(vehicle.global_position):
			_on_level_failed("Car '%s' left the map!" % vehicle_id)
			return


# ============================================
# Event Handlers
# ============================================

func _on_vehicle_reached_destination(vehicle_id: String) -> void:
	_vehicles_at_destination += 1
	car_reached_destination.emit(vehicle_id)

	# Check win condition - count active vehicles that need to reach destination
	var active_vehicles = _count_active_vehicles()
	if active_vehicles == 0 and _vehicles_at_destination > 0:
		# All active vehicles have reached destination
		_on_level_complete()


## Count vehicles that are active (not crashed) and haven't reached destination
func _count_active_vehicles() -> int:
	var count = 0
	for vehicle_id in _vehicles:
		var vehicle = _vehicles[vehicle_id]
		if is_instance_valid(vehicle) and vehicle.vehicle_state == 1:  # State 1 = Active
			if not vehicle.at_end():  # Only count those not yet at destination
				count += 1
	return count


func _on_vehicle_crashed(vehicle_id: String) -> void:
	car_crashed.emit(vehicle_id)
	# Note: We don't immediately fail the level on crash
	# Instead, main.gd handles the hearts system
	# Level only fails when hearts reach 0


func _on_level_complete() -> void:
	stop()
	level_completed.emit(3)  # TODO: Calculate actual stars
	simulation_ended.emit(true)


func _on_level_failed(reason: String) -> void:
	stop()
	level_failed.emit(reason)
	simulation_ended.emit(false)


func _on_interpreter_execution_line(line_number: int) -> void:
	execution_line_changed.emit(line_number)


func _on_interpreter_execution_error(error: String, line: int) -> void:
	execution_error_occurred.emit(error, line)
	# Infinite loop auto-fail disabled for presentation mode
	# Players can press R to reset manually
	# if error.find("infinite loop") >= 0:
	# 	infinite_loop_detected.emit()
	# 	_on_level_failed("Infinite loop detected at line %d" % line)


func _on_interpreter_print_output(message: String) -> void:
	print_output.emit(message)


# ============================================
# Input Handling (can be connected from UI)
# ============================================

func _unhandled_input(event: InputEvent) -> void:
	# Skip shortcuts if code editor is focused (player is typing)
	if is_editor_focused_callback.is_valid() and is_editor_focused_callback.call():
		return

	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE:
				toggle_pause()
			KEY_R:
				reset()
			KEY_EQUAL, KEY_KP_ADD:  # + key
				speed_up()
			KEY_MINUS, KEY_KP_SUBTRACT:  # - key
				slow_down()
			KEY_S:  # Step mode
				step()
