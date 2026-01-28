extends Node2D
class_name Stoplight

## Traffic light entity that can be controlled via code commands.
## Now supports Python-like code execution with direction-based state management.
## Each stoplight has its own script that runs in a loop.
##
## Supports:
## - Legacy: set_red(), set_green(), set_yellow(), get_state()
## - Direction-based: green("north", "south"), red("east", "west"), yellow("north")
## - State queries: is_red(), is_green(), is_yellow()
## - Timing: wait(seconds)

# Signal emitted when the light state changes
signal state_changed(stoplight_id: String, new_state: String)

# Available states for the traffic light
enum LightState { RED, YELLOW, GREEN }

# Stoplight properties
@export var stoplight_id: String = "stoplight1"
@export var initial_state: LightState = LightState.RED
@export var stoplight_code: String = ""  # Python-like code for this stoplight

# Current state
var current_state: LightState = LightState.RED

# Direction-based state (for 4-way stoplights)
var _directional_states: Dictionary = {
	"north": LightState.RED,
	"south": LightState.RED,
	"east": LightState.RED,
	"west": LightState.RED,
}

# Colors for visual representation (used by the sprite/shader)
const COLOR_RED: Color = Color(1.0, 0.2, 0.2)     # Bright red
const COLOR_YELLOW: Color = Color(1.0, 0.9, 0.2)  # Bright yellow
const COLOR_GREEN: Color = Color(0.2, 1.0, 0.3)   # Bright green
const COLOR_OFF: Color = Color(0.2, 0.2, 0.2)     # Dark gray (off)

# References to light sprites (set in _ready or via scene)
var _red_light: Node = null
var _yellow_light: Node = null
var _green_light: Node = null

# Audio player for click sound
var _click_audio: AudioStreamPlayer = null

# Code execution state
var _interpreter: Variant = null  # PythonInterpreter instance
var _code_parser: Variant = null  # PythonParser instance
var _is_running_code: bool = false  # Whether stoplight code is executing
var _current_line: int = 0  # Current line in stoplight code for UI display
var _wait_timer: float = 0.0  # Timer for wait() function
var _wait_duration: float = 0.0  # Total wait duration (for progress display)

# When > 0, the stoplight is forced to stay solid red and its
# normal Python code execution is temporarily paused. Used by
# tutorial forced-failure sequences (e.g. Tutorial 4 demo).
var _forced_red_timer: float = 0.0

# Preset codes for quick setup
const PRESET_STANDARD_4WAY = """
while True:
	stoplight.green("north", "south")
	stoplight.red("east", "west")
    wait(5)
	stoplight.yellow("north", "south")
    wait(2)
	stoplight.red("north", "south")
	stoplight.green("east", "west")
    wait(5)
	stoplight.yellow("east", "west")
    wait(2)
"""

const PRESET_FAST_CYCLE = """
while True:
	stoplight.green("north", "south")
	stoplight.red("east", "west")
    wait(3)
	stoplight.yellow("north", "south")
    wait(1)
	stoplight.red("north", "south")
	stoplight.green("east", "west")
    wait(3)
	stoplight.yellow("east", "west")
    wait(1)
"""

const PRESET_ALL_GREEN = """
stoplight.green()
"""

const PRESET_ALWAYS_RED_NS = """
stoplight.red("north", "south")
stoplight.green("east", "west")
"""


func _ready() -> void:
	# Set initial state
	current_state = initial_state
	_directional_states = {
		"north": initial_state,
		"south": initial_state,
		"east": initial_state,
		"west": initial_state,
	}

	# Find light child nodes if they exist (for simple 2-way stoplight)
	_red_light = get_node_or_null("RedLight")
	_yellow_light = get_node_or_null("YellowLight")
	_green_light = get_node_or_null("GreenLight")
	
	# Setup click sound
	_click_audio = AudioStreamPlayer.new()
	_click_audio.stream = load("res://assets/audio/click-345983.mp3")
	_click_audio.volume_db = -10.0
	add_child(_click_audio)

	# Update visual representation
	_update_visuals()

	# Setup code interpreter - use default code if none provided
	if stoplight_code.is_empty():
		stoplight_code = PRESET_STANDARD_4WAY
	
	_setup_interpreter()
	_start_code_execution()


func _process(delta: float) -> void:
	# When a forced-red timer is active, keep the light solid red
	# and pause the internal Python code that normally drives it.
	if _forced_red_timer > 0.0:
		_forced_red_timer -= delta
		if _forced_red_timer <= 0.0:
			_forced_red_timer = 0.0
			# Resume normal scripted behaviour
			_start_code_execution()
	else:
		# Handle wait timer for code execution
		if _is_running_code:
			if _wait_timer > 0:
				_wait_timer -= delta
				if _wait_timer <= 0:
					_wait_timer = 0
			# Always continue code execution if not waiting
			if _wait_timer <= 0:
				_continue_code_execution()
	# Redraw direction indicators
	queue_redraw()


func _draw() -> void:
	# Draw direction arrows showing which directions are green/red/yellow
	var arrow_distance = 60  # Distance from center
	var arrow_size = 20
	
	# North arrow (↑)
	var north_color = _get_state_color(_directional_states.get("north", LightState.RED))
	draw_line(Vector2(0, -arrow_distance), Vector2(0, -arrow_distance - arrow_size), north_color, 3.0)
	draw_line(Vector2(0, -arrow_distance - arrow_size), Vector2(-5, -arrow_distance - arrow_size + 8), north_color, 3.0)
	draw_line(Vector2(0, -arrow_distance - arrow_size), Vector2(5, -arrow_distance - arrow_size + 8), north_color, 3.0)
	
	# South arrow (↓)
	var south_color = _get_state_color(_directional_states.get("south", LightState.RED))
	draw_line(Vector2(0, arrow_distance), Vector2(0, arrow_distance + arrow_size), south_color, 3.0)
	draw_line(Vector2(0, arrow_distance + arrow_size), Vector2(-5, arrow_distance + arrow_size - 8), south_color, 3.0)
	draw_line(Vector2(0, arrow_distance + arrow_size), Vector2(5, arrow_distance + arrow_size - 8), south_color, 3.0)
	
	# East arrow (→)
	var east_color = _get_state_color(_directional_states.get("east", LightState.RED))
	draw_line(Vector2(arrow_distance, 0), Vector2(arrow_distance + arrow_size, 0), east_color, 3.0)
	draw_line(Vector2(arrow_distance + arrow_size, 0), Vector2(arrow_distance + arrow_size - 8, -5), east_color, 3.0)
	draw_line(Vector2(arrow_distance + arrow_size, 0), Vector2(arrow_distance + arrow_size - 8, 5), east_color, 3.0)
	
	# West arrow (←)
	var west_color = _get_state_color(_directional_states.get("west", LightState.RED))
	draw_line(Vector2(-arrow_distance, 0), Vector2(-arrow_distance - arrow_size, 0), west_color, 3.0)
	draw_line(Vector2(-arrow_distance - arrow_size, 0), Vector2(-arrow_distance - arrow_size + 8, -5), west_color, 3.0)
	draw_line(Vector2(-arrow_distance - arrow_size, 0), Vector2(-arrow_distance - arrow_size + 8, 5), west_color, 3.0)


func _get_state_color(state: LightState) -> Color:
	match state:
		LightState.RED:
			return COLOR_RED
		LightState.YELLOW:
			return COLOR_YELLOW
		LightState.GREEN:
			return COLOR_GREEN
		_:
			return COLOR_OFF


## Setup the code interpreter for this stoplight
func _setup_interpreter() -> void:
	if _code_parser == null:
		_code_parser = preload("res://scripts/core/python_parser.gd").new()
	if _interpreter == null:
		_interpreter = preload("res://scripts/core/python_interpreter.gd").new()
	
	# Register this stoplight in the interpreter
	_interpreter.register_object("stoplight", self)


## Start executing the stoplight's code
func _start_code_execution() -> void:
	if stoplight_code.is_empty():
		return
	
	_setup_interpreter()
	_is_running_code = true
	
	print("Starting stoplight code execution for: ", stoplight_id)
	
	# Parse the code
	var ast = _code_parser.parse(stoplight_code)
	if ast.has("errors") and ast["errors"].size() > 0:
		push_error("Stoplight code parse error: ", ast["errors"])
		_is_running_code = false
		return
	
	# Start execution
	_interpreter.start_execution(ast)


## Continue executing the next step in the stoplight code
func _continue_code_execution() -> void:
	if not _is_running_code or not _interpreter:
		return

	# Execute ONE step per frame instead of a while loop
	# This prevents the stoplight from monopolizing execution time
	if _wait_timer <= 0:
		var has_more = _interpreter.step()
		_current_line = _interpreter.get_current_line() if _interpreter.has_method("get_current_line") else 0

		if not has_more:
			# Code completed, restart (infinite loop)
			print("Stoplight code loop completed, restarting...")
			_start_code_execution()


## Called by interpreter: wait(seconds)
func wait(seconds: float) -> void:
	_wait_timer = seconds
	_wait_duration = seconds


# ============================================
# Command Functions (called by SimulationEngine or Code)
# ============================================

## Set specific directions to green (or all directions if none specified)
func green(... directions) -> void:
	# directions can be passed in any order: green("north", "west")
	if directions.size() == 0:
		_set_state(LightState.GREEN)
		_directional_states["north"] = LightState.GREEN
		_directional_states["south"] = LightState.GREEN
		_directional_states["east"] = LightState.GREEN
		_directional_states["west"] = LightState.GREEN
		_update_visuals()
		return

	var changed = false
	for dir in directions:
		var d = str(dir).to_lower()
		if _directional_states.get(d, LightState.RED) != LightState.GREEN:
			match d:
				"north":
					_directional_states["north"] = LightState.GREEN
					changed = true
				"south":
					_directional_states["south"] = LightState.GREEN
					changed = true
				"east":
					_directional_states["east"] = LightState.GREEN
					changed = true
				"west":
					_directional_states["west"] = LightState.GREEN
					changed = true
				_:  # ignore invalid tokens
					pass
	
	if changed and _click_audio and not _click_audio.playing:
		_click_audio.play()

	_update_visuals()


## Set specific directions to red (or all directions if none specified)
func red(... directions) -> void:
	if directions.size() == 0:
		_set_state(LightState.RED)
		_directional_states["north"] = LightState.RED
		_directional_states["south"] = LightState.RED
		_directional_states["east"] = LightState.RED
		_directional_states["west"] = LightState.RED
		_update_visuals()
		return

	var changed = false
	for dir in directions:
		var d = str(dir).to_lower()
		if _directional_states.get(d, LightState.GREEN) != LightState.RED:
			match d:
				"north":
					_directional_states["north"] = LightState.RED
					changed = true
				"south":
					_directional_states["south"] = LightState.RED
					changed = true
				"east":
					_directional_states["east"] = LightState.RED
					changed = true
				"west":
					_directional_states["west"] = LightState.RED
					changed = true
				_:
					pass

	if changed and _click_audio and not _click_audio.playing:
		_click_audio.play()

	_update_visuals()


## Set specific directions to yellow (or all directions if none specified)
func yellow(... directions) -> void:
	if directions.size() == 0:
		_set_state(LightState.YELLOW)
		_directional_states["north"] = LightState.YELLOW
		_directional_states["south"] = LightState.YELLOW
		_directional_states["east"] = LightState.YELLOW
		_directional_states["west"] = LightState.YELLOW
		_update_visuals()
		return

	var changed = false
	for dir in directions:
		var d = str(dir).to_lower()
		if _directional_states.get(d, LightState.RED) != LightState.YELLOW:
			match d:
				"north":
					_directional_states["north"] = LightState.YELLOW
					changed = true
				"south":
					_directional_states["south"] = LightState.YELLOW
					changed = true
				"east":
					_directional_states["east"] = LightState.YELLOW
					changed = true
				"west":
					_directional_states["west"] = LightState.YELLOW
					changed = true
				_:
					pass

	if changed and _click_audio and not _click_audio.playing:
		_click_audio.play()

	_update_visuals()


## Set the traffic light to red (short name) - sets all directions
func set_red() -> void:
	_set_state(LightState.RED)
	_directional_states = {
		"north": LightState.RED,
		"south": LightState.RED,
		"east": LightState.RED,
		"west": LightState.RED,
	}


## Set the traffic light to green (short name) - sets all directions
func set_green() -> void:
	_set_state(LightState.GREEN)
	_directional_states = {
		"north": LightState.GREEN,
		"south": LightState.GREEN,
		"east": LightState.GREEN,
		"west": LightState.GREEN,
	}


## Set the traffic light to yellow (short name) - sets all directions
func set_yellow() -> void:
	_set_state(LightState.YELLOW)
	_directional_states = {
		"north": LightState.YELLOW,
		"south": LightState.YELLOW,
		"east": LightState.YELLOW,
		"west": LightState.YELLOW,
	}


## Get the current state as a string (short name)
func state() -> String:
	match current_state:
		LightState.RED:
			return "red"
		LightState.YELLOW:
			return "yellow"
		LightState.GREEN:
			return "green"
	return "unknown"


## Legacy: get_state (alias)
func get_state() -> String:
	return state()


# ============================================
# State Check Functions (for vehicles to query)
# ============================================

## Returns true if the light is red (or specific direction is red)

func is_red(direction: String = "") -> bool:

	if direction.is_empty():

		push_error("DEPRECATION WARNING: stoplight.is_red() called without a direction is unreliable. Please use car.at_red() instead for accurate directional checks.")

		# Fail-safe by returning true to prevent cars from entering an intersection unsafely.

		return true

	else:

		# Check specific direction

		var dir_lower = direction.to_lower().strip_edges()

		if _directional_states.has(dir_lower):

			return _directional_states[dir_lower] == LightState.RED

		# Invalid direction, return false

		return false





## Returns true if the light is green (or specific direction is green)

func is_green(direction: String = "") -> bool:

	if direction.is_empty():

		push_error("DEPRECATION WARNING: stoplight.is_green() called without a direction is unreliable. Please use car.at_green() instead for accurate directional checks.")

		# Fail-safe by returning false.

		return false

	else:

		# Check specific direction

		var dir_lower = direction.to_lower().strip_edges()

		if _directional_states.has(dir_lower):

			return _directional_states[dir_lower] == LightState.GREEN

		# Invalid direction, return false

		return false





## Returns true if the light is yellow (or specific direction is yellow)

func is_yellow(direction: String = "") -> bool:

	if direction.is_empty():

		push_error("DEPRECATION WARNING: stoplight.is_yellow() called without a direction is unreliable. Please use car.at_yellow() instead for accurate directional checks.")

		# Fail-safe by returning true to prevent cars from entering an intersection unsafely.

		return true

	else:

		# Check specific direction

		var dir_lower = direction.to_lower().strip_edges()

		if _directional_states.has(dir_lower):

			return _directional_states[dir_lower] == LightState.YELLOW

		# Invalid direction, return false

		return false





## Returns true if vehicles should stop (red or yellow)

func should_stop() -> bool:

	push_error("DEPRECATION WARNING: stoplight.should_stop() is unreliable. Please use car.at_red() or car.at_yellow() instead.")

	# Fail-safe by returning true to prevent cars from entering an intersection unsafely.

	return true





# ============================================

# Internal Functions

# ============================================

## Internal function to set state and emit signal
func _set_state(new_state: LightState) -> void:
	if current_state != new_state:
		current_state = new_state
		_update_visuals()
		state_changed.emit(stoplight_id, get_state())
		
		# Play click sound when light changes
		if _click_audio and not _click_audio.playing:
			_click_audio.play()


## Update the visual representation of the lights
func _update_visuals() -> void:
	if not is_node_ready():
		return

	# All three colored lights are always visible.
	# The active state is shown by the directional arrows.
	if _red_light:
		_set_light_color(_red_light, COLOR_RED)
	if _yellow_light:
		_set_light_color(_yellow_light, COLOR_YELLOW)
	if _green_light:
		_set_light_color(_green_light, COLOR_GREEN)

	# Redraw arrows to reflect the current state.
	queue_redraw()





## Set the color of a light node
func _set_light_color(light_node: Node, color: Color) -> void:
	# Works with Sprite2D nodes
	if light_node is Sprite2D:
		light_node.modulate = color
	# Works with ColorRect nodes
	elif light_node is ColorRect:
		(light_node as ColorRect).color = color
	# Works with any CanvasItem (fallback)
	elif light_node is CanvasItem:
		light_node.modulate = color


# ============================================
# Utility Functions
# ============================================

## Reset the stoplight to its initial state
func reset() -> void:
	_forced_red_timer = 0.0
	current_state = initial_state
	_update_visuals()


## Force the stoplight to stay red (all directions) for a number of seconds.
## Used by tutorial forced-failure demos so the light can't turn green
## while the player car is approaching.
func force_red_for_seconds(seconds: float) -> void:
	_forced_red_timer = max(0.0, seconds)
	# Stop any current scripted behaviour while we are forcing red.
	_is_running_code = false
	set_red()


## Get the current color for rendering
func get_current_color() -> Color:
	match current_state:
		LightState.RED:
			return COLOR_RED
		LightState.YELLOW:
			return COLOR_YELLOW
		LightState.GREEN:
			return COLOR_GREEN
	return COLOR_OFF
