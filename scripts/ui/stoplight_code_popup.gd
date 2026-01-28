extends Control
class_name StoplightCodePopup

## Popup UI for editing and displaying stoplight code
## Shows the code with current line highlighted and countdown timer
## Includes IntelliSense for stoplight functions only

# References
var code_edit: CodeEdit = null
var timer_label: Label = null
var edit_hint: Label = null

# State
var _stoplight: Variant = null
var _is_visible_to_user: bool = false
var _is_editable: bool = false

# Stoplight function keywords for IntelliSense
const STOPLIGHT_FUNCTIONS = [
	"stoplight.green",
	"stoplight.red",
	"stoplight.yellow",
	"stoplight.is_green",
	"stoplight.is_red",
	"stoplight.is_yellow",
	"wait",
]

# Default starter code
const DEFAULT_STOPLIGHT_CODE = """# Standard traffic light cycle
while True:
    stoplight.green()
    wait(5)
    stoplight.yellow()
    wait(2)
    stoplight.red()
    wait(5)
"""

func _ready() -> void:
	# Find child nodes
	code_edit = get_node_or_null("PanelContainer/VBoxContainer/CodeEdit")
	timer_label = get_node_or_null("PanelContainer/VBoxContainer/TimerLabel")
	edit_hint = get_node_or_null("PanelContainer/VBoxContainer/EditHint")
	
	if code_edit == null or timer_label == null or edit_hint == null:
		push_error("StoplightCodePopup: Failed to find child nodes!")
		return
	
	# Setup code editor
	code_edit.syntax_highlighter = CodeHighlighter.new()
	_setup_syntax_highlighting()
	code_edit.text_changed.connect(_on_code_changed)
	code_edit.focus_entered.connect(_on_code_focus_entered)
	code_edit.focus_exited.connect(_on_code_focus_exited)
	
	# Start hidden
	hide()
	
	# Connect to mouse events
	gui_input.connect(_on_gui_input)
	
	print("StoplightCodePopup: Initialized successfully")


func _process(delta: float) -> void:
	if not _is_visible_to_user or _stoplight == null:
		return
	
	# Update timer display
	if _stoplight._wait_timer > 0:
		timer_label.text = "⏱ Next change in: %.1fs" % _stoplight._wait_timer
	else:
		timer_label.text = "⏱ Executing..."
	
	# Update direction indicator
	_update_direction_indicator()
	
	# Highlight current executing line in code editor
	# Clear all previous highlights first
	for i in range(code_edit.get_line_count()):
		code_edit.set_line_background_color(i, Color(0, 0, 0, 0))

	# Highlight current line if code is running (convert 1-based to 0-based)
	if _stoplight._is_running_code and _stoplight._current_line >= 0:
		var line_idx = clamp(_stoplight._current_line - 1, 0, code_edit.get_line_count() - 1)
		code_edit.set_line_background_color(line_idx, Color.YELLOW.darkened(0.7))


## Update the direction indicator showing which directions are green/red
func _update_direction_indicator() -> void:
	if _stoplight == null:
		return
	
	# Create visual indicator of directions
	var indicator = "Directions: "
	
	# North
	var north_state = _stoplight._directional_states.get("north", _stoplight.LightState.RED)
	indicator += _get_direction_arrow("north", north_state) + " "
	
	# South
	var south_state = _stoplight._directional_states.get("south", _stoplight.LightState.RED)
	indicator += _get_direction_arrow("south", south_state) + " "
	
	# East
	var east_state = _stoplight._directional_states.get("east", _stoplight.LightState.RED)
	indicator += _get_direction_arrow("east", east_state) + " "
	
	# West
	var west_state = _stoplight._directional_states.get("west", _stoplight.LightState.RED)
	indicator += _get_direction_arrow("west", west_state)
	
	# Update title with direction info
	var title = get_node_or_null("PanelContainer/VBoxContainer/TitleLabel")
	if title:
		title.text = "📝 STOPLIGHT - " + indicator


## Get arrow and color for a direction state
func _get_direction_arrow(direction: String, state: int) -> String:
	var arrow = ""
	
	match direction:
		"north":
			arrow = "↑"
		"south":
			arrow = "↓"
		"east":
			arrow = "→"
		"west":
			arrow = "←"
	
	# Color based on state (using LightState enum: RED=0, YELLOW=1, GREEN=2)
	var color = "gray"
	match state:
		0:  # RED
			color = "red"
		1:  # YELLOW
			color = "gold"
		2:  # GREEN
			color = "lime"
	
	return "[color=%s]%s[/color]" % [color, arrow]


## Show the popup for a stoplight
func show_for_stoplight(stoplight: Variant, editable: bool = false) -> void:
	if stoplight == null:
		hide_popup()
		return
	
	if code_edit == null or timer_label == null or edit_hint == null:
		print("StoplightCodePopup: Child nodes not initialized!")
		return
	
	_stoplight = stoplight
	_is_visible_to_user = true
	_is_editable = editable
	
	print("StoplightCodePopup: Showing for stoplight %s (editable: %s)" % [stoplight.stoplight_id, editable])
	
	# Load code into editor
	var code = stoplight.stoplight_code
	if code.is_empty():
		code = DEFAULT_STOPLIGHT_CODE
	
	code_edit.text = code
	code_edit.editable = editable
	
	# Update edit hint
	if editable:
		edit_hint.text = "✏️ Editable - Click to modify stoplight code"
	else:
		edit_hint.text = "🔒 Read-only - Code auto-executes"
	
	# Show the popup
	show()
	
	# Position popup near the stoplight
	if stoplight is Node2D:
		global_position = stoplight.global_position + Vector2(50, -100)
		print("StoplightCodePopup: Positioned at %s" % global_position)


## Hide the popup
func hide_popup() -> void:
	_is_visible_to_user = false
	hide()
	_stoplight = null


## Setup syntax highlighting
func _setup_syntax_highlighting() -> void:
	var highlighter = code_edit.syntax_highlighter as CodeHighlighter
	if highlighter == null:
		return
	
	# Keywords
	highlighter.add_keyword_color("while", Color.SLATE_BLUE)
	highlighter.add_keyword_color("if", Color.SLATE_BLUE)
	highlighter.add_keyword_color("else", Color.SLATE_BLUE)
	highlighter.add_keyword_color("True", Color.KHAKI)
	highlighter.add_keyword_color("False", Color.KHAKI)
	
	# Stoplight functions
	highlighter.add_keyword_color("stoplight", Color.CYAN)
	highlighter.add_keyword_color("wait", Color.MEDIUM_AQUAMARINE)
	highlighter.add_keyword_color("green", Color.GREEN)
	highlighter.add_keyword_color("red", Color.RED)
	highlighter.add_keyword_color("yellow", Color.YELLOW)
	highlighter.add_keyword_color("is_green", Color.GREEN)
	highlighter.add_keyword_color("is_red", Color.RED)
	highlighter.add_keyword_color("is_yellow", Color.YELLOW)
	
	# Comments
	highlighter.add_color_region("#", "\n", Color.GRAY, false)


## Called when code is edited
func _on_code_changed() -> void:
	if _stoplight == null or not _is_editable:
		return
	
	# Update the stoplight's code
	_stoplight.stoplight_code = code_edit.text
	print("StoplightCodePopup: Code updated for %s" % _stoplight.stoplight_id)
	
	# Restart code execution with new code
	_stoplight._start_code_execution()


## Called when code editor gains focus
func _on_code_focus_entered() -> void:
	print("StoplightCodePopup: Code editor focused")


## Called when code editor loses focus
func _on_code_focus_exited() -> void:
	print("StoplightCodePopup: Code editor unfocused")


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			# Focus the code editor when clicked
			if code_edit and _is_editable:
				code_edit.grab_focus()
