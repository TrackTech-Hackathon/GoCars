extends Node2D
class_name Stoplight

## Traffic light entity that can be controlled via code commands.
## Supports: set_red(), set_green(), set_yellow(), get_state()
##
## The stoplight uses a state machine pattern with three states.
## Vehicles check the stoplight's state to decide whether to stop.

# Signal emitted when the light state changes
signal state_changed(stoplight_id: String, new_state: String)

# Available states for the traffic light
enum LightState { RED, YELLOW, GREEN }

# Stoplight properties
@export var stoplight_id: String = "stoplight1"
@export var initial_state: LightState = LightState.RED

# Current state
var current_state: LightState = LightState.RED

# Colors for visual representation (used by the sprite/shader)
const COLOR_RED: Color = Color(1.0, 0.2, 0.2)     # Bright red
const COLOR_YELLOW: Color = Color(1.0, 0.9, 0.2)  # Bright yellow
const COLOR_GREEN: Color = Color(0.2, 1.0, 0.3)   # Bright green
const COLOR_OFF: Color = Color(0.2, 0.2, 0.2)     # Dark gray (off)

# References to light sprites (set in _ready or via scene)
var _red_light: Node = null
var _yellow_light: Node = null
var _green_light: Node = null


func _ready() -> void:
	# Set initial state
	current_state = initial_state

	# Find light child nodes if they exist (for simple 2-way stoplight)
	_red_light = get_node_or_null("RedLight")
	_yellow_light = get_node_or_null("YellowLight")
	_green_light = get_node_or_null("GreenLight")

	# Update visual representation
	_update_visuals()

	# Also update any direction-based lights (for 4-way stoplights)
	_update_directional_lights()


# ============================================
# Command Functions (called by SimulationEngine)
# ============================================

## Set the traffic light to red (short name)
func red() -> void:
	_set_state(LightState.RED)


## Legacy: set_red (alias)
func set_red() -> void:
	red()


## Set the traffic light to green (short name)
func green() -> void:
	_set_state(LightState.GREEN)


## Legacy: set_green (alias)
func set_green() -> void:
	green()


## Set the traffic light to yellow (short name)
func yellow() -> void:
	_set_state(LightState.YELLOW)


## Legacy: set_yellow (alias)
func set_yellow() -> void:
	yellow()


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

## Returns true if the light is red
func is_red() -> bool:
	return current_state == LightState.RED


## Returns true if the light is green
func is_green() -> bool:
	return current_state == LightState.GREEN


## Returns true if the light is yellow
func is_yellow() -> bool:
	return current_state == LightState.YELLOW


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
