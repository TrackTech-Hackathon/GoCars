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

	# Also update any direction-based lights (for 4-way stoplights)
	_update_directional_lights()

	# Setup code interpreter - use default code if none provided
	if stoplight_code.is_empty():
		stoplight_code = PRESET_STANDARD_4WAY
	
	_setup_interpreter()
	_start_code_execution()


func _process(delta: float) -> void:
	# Handle wait timer for code execution
	if _is_running_code:
		if _wait_timer > 0:
			_wait_timer -= delta
			if _wait_timer <= 0:
				_wait_timer = 0
				# Wait finished, continue execution
				_continue_code_execution()
		else:
			# No wait active, keep executing steps
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
	
	# Execute one step
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
func green(north: String = "", south: String = "", east: String = "", west: String = "") -> void:
	print("[STOPLIGHT] green() called - north:", north, " south:", south, " east:", east, " west:", west)
	
	# If no directions specified, set all to green
	if north.is_empty() and south.is_empty() and east.is_empty() and west.is_empty():
		_set_state(LightState.GREEN)
		_directional_states["north"] = LightState.GREEN
		_directional_states["south"] = LightState.GREEN
		_directional_states["east"] = LightState.GREEN
		_directional_states["west"] = LightState.GREEN
		_update_visuals()
	else:
		# Set specific directions
		if not north.is_empty() and north.to_lower() == "north":
			_directional_states["north"] = LightState.GREEN
		if not south.is_empty() and south.to_lower() == "south":
			_directional_states["south"] = LightState.GREEN
		if not east.is_empty() and east.to_lower() == "east":
			_directional_states["east"] = LightState.GREEN
		if not west.is_empty() and west.to_lower() == "west":
			_directional_states["west"] = LightState.GREEN
		_update_visuals()


## Set specific directions to red (or all directions if none specified)
func red(north: String = "", south: String = "", east: String = "", west: String = "") -> void:
	# If no directions specified, set all to red
	if north.is_empty() and south.is_empty() and east.is_empty() and west.is_empty():
		_set_state(LightState.RED)
		_directional_states["north"] = LightState.RED
		_directional_states["south"] = LightState.RED
		_directional_states["east"] = LightState.RED
		_directional_states["west"] = LightState.RED
		_update_visuals()
	else:
		# Set specific directions
		if not north.is_empty() and north.to_lower() == "north":
			_directional_states["north"] = LightState.RED
		if not south.is_empty() and south.to_lower() == "south":
			_directional_states["south"] = LightState.RED
		if not east.is_empty() and east.to_lower() == "east":
			_directional_states["east"] = LightState.RED
		if not west.is_empty() and west.to_lower() == "west":
			_directional_states["west"] = LightState.RED
		_update_visuals()


## Set specific directions to yellow (or all directions if none specified)
func yellow(north: String = "", south: String = "", east: String = "", west: String = "") -> void:
	# If no directions specified, set all to yellow
	if north.is_empty() and south.is_empty() and east.is_empty() and west.is_empty():
		_set_state(LightState.YELLOW)
		_directional_states["north"] = LightState.YELLOW
		_directional_states["south"] = LightState.YELLOW
		_directional_states["east"] = LightState.YELLOW
		_directional_states["west"] = LightState.YELLOW
		_update_visuals()
	else:
		# Set specific directions
		if not north.is_empty() and north.to_lower() == "north":
			_directional_states["north"] = LightState.YELLOW
		if not south.is_empty() and south.to_lower() == "south":
			_directional_states["south"] = LightState.YELLOW
		if not east.is_empty() and east.to_lower() == "east":
			_directional_states["east"] = LightState.YELLOW
		if not west.is_empty() and west.to_lower() == "west":
			_directional_states["west"] = LightState.YELLOW
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
		# No direction specified, check global state
		return current_state == LightState.RED
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
		# No direction specified, check global state
		return current_state == LightState.GREEN
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
		# No direction specified, check global state
		return current_state == LightState.YELLOW
	else:
		# Check specific direction
		var dir_lower = direction.to_lower().strip_edges()
		if _directional_states.has(dir_lower):
			return _directional_states[dir_lower] == LightState.YELLOW
		# Invalid direction, return false
		return false


## Returns true if vehicles should stop (red or yellow)
func should_stop() -> bool:
	return current_state == LightState.RED or current_state == LightState.YELLOW


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
	# Turn off all lights first
	if _red_light:
		_set_light_color(_red_light, COLOR_OFF)
	if _yellow_light:
		_set_light_color(_yellow_light, COLOR_OFF)
	if _green_light:
		_set_light_color(_green_light, COLOR_OFF)

	# Turn on the active light
	match current_state:
		LightState.RED:
			if _red_light:
				_set_light_color(_red_light, COLOR_RED)
		LightState.YELLOW:
			if _yellow_light:
				_set_light_color(_yellow_light, COLOR_YELLOW)
		LightState.GREEN:
			if _green_light:
				_set_light_color(_green_light, COLOR_GREEN)

	# Update directional lights too
	_update_directional_lights()


## Update directional lights (for 4-way stoplights)
func _update_directional_lights() -> void:
	# Direction names for 4-way stoplights
	var directions = ["North", "South", "East", "West"]

	for dir_name in directions:
		var dir_node = get_node_or_null(dir_name)
		if dir_node:
			var red = dir_node.get_node_or_null("RedLight")
			var green = dir_node.get_node_or_null("GreenLight")

			# Turn off both lights first
			if red:
				_set_light_color(red, COLOR_OFF)
			if green:
				_set_light_color(green, COLOR_OFF)

			# Turn on the appropriate light
			match current_state:
				LightState.RED:
					if red:
						_set_light_color(red, COLOR_RED)
				LightState.YELLOW:
					# Yellow shows red light blinking (simplified)
					if red:
						_set_light_color(red, COLOR_YELLOW)
				LightState.GREEN:
					if green:
						_set_light_color(green, COLOR_GREEN)


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
	current_state = initial_state
	_update_visuals()


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
