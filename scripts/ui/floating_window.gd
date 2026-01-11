## Floating Window Base Class for GoCars
## Provides draggable, resizable, minimizable window functionality
## Author: Claude Code
## Date: January 2026

extends PanelContainer
class_name FloatingWindow

## Signals
signal window_closed()
signal window_minimized()
signal window_restored()
signal window_focused()

## Window state
var is_minimized: bool = false
var is_dragging: bool = false
var is_resizing: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var resize_start_pos: Vector2 = Vector2.ZERO
var resize_start_size: Vector2 = Vector2.ZERO
var resize_mode: int = ResizeMode.NONE

## Size constraints
@export var min_size: Vector2 = Vector2(300, 200)
@export var max_size: Vector2 = Vector2(1200, 800)
@export var default_size: Vector2 = Vector2(600, 400)
@export var default_position: Vector2 = Vector2(100, 100)

## Window title
@export var window_title: String = "Window"

## Resize modes
enum ResizeMode {
	NONE,
	TOP,
	BOTTOM,
	LEFT,
	RIGHT,
	TOP_LEFT,
	TOP_RIGHT,
	BOTTOM_LEFT,
	BOTTOM_RIGHT
}

## Child nodes (to be assigned in _ready)
var title_bar: PanelContainer
var title_label: Label
var minimize_button: Button
var close_button: Button
var content_container: MarginContainer
var resize_handle_size: int = 8

func _ready() -> void:
	# Set initial size and position
	custom_minimum_size = min_size
	size = default_size
	position = default_position

	# Setup window structure
	_setup_window_structure()

	# Connect signals
	_connect_signals()

	# Enable mouse filter
	mouse_filter = Control.MOUSE_FILTER_STOP

func _setup_window_structure() -> void:
	# Main VBox layout
	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	add_child(vbox)

	# Title bar
	title_bar = PanelContainer.new()
	title_bar.name = "TitleBar"
	title_bar.custom_minimum_size = Vector2(0, 32)
	vbox.add_child(title_bar)

	var title_hbox = HBoxContainer.new()
	title_bar.add_child(title_hbox)

	# Title label
	title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.text = window_title
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_hbox.add_child(title_label)

	# Minimize button
	minimize_button = Button.new()
	minimize_button.name = "MinimizeButton"
	minimize_button.text = "−"
	minimize_button.custom_minimum_size = Vector2(24, 24)
	title_hbox.add_child(minimize_button)

	# Close button
	close_button = Button.new()
	close_button.name = "CloseButton"
	close_button.text = "×"
	close_button.custom_minimum_size = Vector2(24, 24)
	title_hbox.add_child(close_button)

	# Content container
	content_container = MarginContainer.new()
	content_container.name = "ContentContainer"
	content_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_container.add_theme_constant_override("margin_left", 4)
	content_container.add_theme_constant_override("margin_right", 4)
	content_container.add_theme_constant_override("margin_top", 4)
	content_container.add_theme_constant_override("margin_bottom", 4)
	vbox.add_child(content_container)

func _connect_signals() -> void:
	# Title bar drag
	title_bar.gui_input.connect(_on_title_bar_input)

	# Buttons
	minimize_button.pressed.connect(_on_minimize_pressed)
	close_button.pressed.connect(_on_close_pressed)

	# Window focus
	gui_input.connect(_on_window_input)

func _on_title_bar_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.pressed:
				is_dragging = true
				drag_offset = get_global_mouse_position() - global_position
				_bring_to_front()
			else:
				is_dragging = false

	elif event is InputEventMouseMotion and is_dragging:
		global_position = get_global_mouse_position() - drag_offset

func _on_window_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			_bring_to_front()

func _input(event: InputEvent) -> void:
	# Handle resize dragging
	if is_resizing and event is InputEventMouseMotion:
		_handle_resize(get_global_mouse_position())

	elif event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if not mouse_event.pressed and is_resizing:
				is_resizing = false
				resize_mode = ResizeMode.NONE

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			# Check if clicking on resize area
			var local_pos = mouse_event.position
			resize_mode = _get_resize_mode(local_pos)

			if resize_mode != ResizeMode.NONE:
				is_resizing = true
				resize_start_pos = get_global_mouse_position()
				resize_start_size = size

	elif event is InputEventMouseMotion:
		# Update cursor based on resize mode
		var local_pos = event.position
		var mode = _get_resize_mode(local_pos)
		_update_cursor(mode)

func _get_resize_mode(local_pos: Vector2) -> int:
	var at_left = local_pos.x < resize_handle_size
	var at_right = local_pos.x > size.x - resize_handle_size
	var at_top = local_pos.y < resize_handle_size
	var at_bottom = local_pos.y > size.y - resize_handle_size

	if at_top and at_left:
		return ResizeMode.TOP_LEFT
	elif at_top and at_right:
		return ResizeMode.TOP_RIGHT
	elif at_bottom and at_left:
		return ResizeMode.BOTTOM_LEFT
	elif at_bottom and at_right:
		return ResizeMode.BOTTOM_RIGHT
	elif at_top:
		return ResizeMode.TOP
	elif at_bottom:
		return ResizeMode.BOTTOM
	elif at_left:
		return ResizeMode.LEFT
	elif at_right:
		return ResizeMode.RIGHT
	else:
		return ResizeMode.NONE

func _update_cursor(mode: int) -> void:
	match mode:
		ResizeMode.TOP, ResizeMode.BOTTOM:
			mouse_default_cursor_shape = Control.CURSOR_VSIZE
		ResizeMode.LEFT, ResizeMode.RIGHT:
			mouse_default_cursor_shape = Control.CURSOR_HSIZE
		ResizeMode.TOP_LEFT, ResizeMode.BOTTOM_RIGHT:
			mouse_default_cursor_shape = Control.CURSOR_FDIAGSIZE
		ResizeMode.TOP_RIGHT, ResizeMode.BOTTOM_LEFT:
			mouse_default_cursor_shape = Control.CURSOR_BDIAGSIZE
		_:
			mouse_default_cursor_shape = Control.CURSOR_ARROW

func _handle_resize(mouse_pos: Vector2) -> void:
	var delta = mouse_pos - resize_start_pos
	var new_size = resize_start_size
	var new_pos = global_position

	match resize_mode:
		ResizeMode.RIGHT:
			new_size.x = resize_start_size.x + delta.x
		ResizeMode.BOTTOM:
			new_size.y = resize_start_size.y + delta.y
		ResizeMode.LEFT:
			new_size.x = resize_start_size.x - delta.x
			new_pos.x = resize_start_pos.x - resize_start_size.x + new_size.x
		ResizeMode.TOP:
			new_size.y = resize_start_size.y - delta.y
			new_pos.y = resize_start_pos.y - resize_start_size.y + new_size.y
		ResizeMode.TOP_LEFT:
			new_size.x = resize_start_size.x - delta.x
			new_size.y = resize_start_size.y - delta.y
			new_pos.x = resize_start_pos.x - resize_start_size.x + new_size.x
			new_pos.y = resize_start_pos.y - resize_start_size.y + new_size.y
		ResizeMode.TOP_RIGHT:
			new_size.x = resize_start_size.x + delta.x
			new_size.y = resize_start_size.y - delta.y
			new_pos.y = resize_start_pos.y - resize_start_size.y + new_size.y
		ResizeMode.BOTTOM_LEFT:
			new_size.x = resize_start_size.x - delta.x
			new_size.y = resize_start_size.y + delta.y
			new_pos.x = resize_start_pos.x - resize_start_size.x + new_size.x
		ResizeMode.BOTTOM_RIGHT:
			new_size.x = resize_start_size.x + delta.x
			new_size.y = resize_start_size.y + delta.y

	# Clamp size to constraints
	new_size.x = clamp(new_size.x, min_size.x, max_size.x)
	new_size.y = clamp(new_size.y, min_size.y, max_size.y)

	size = new_size
	global_position = new_pos

func _bring_to_front() -> void:
	# Move to front of parent's children
	if get_parent():
		get_parent().move_child(self, -1)
		window_focused.emit()

func _on_minimize_pressed() -> void:
	if is_minimized:
		restore()
	else:
		minimize()

func _on_close_pressed() -> void:
	close()

## Public API

## Minimize the window (hide content, keep title bar)
func minimize() -> void:
	is_minimized = true
	content_container.visible = false
	minimize_button.text = "□"
	window_minimized.emit()

## Restore the window from minimized state
func restore() -> void:
	is_minimized = false
	content_container.visible = true
	minimize_button.text = "−"
	window_restored.emit()

## Close the window (hide it)
func close() -> void:
	visible = false
	window_closed.emit()

## Show the window
func open() -> void:
	visible = true
	_bring_to_front()

## Set window title
func set_window_title(new_title: String) -> void:
	window_title = new_title
	if title_label:
		title_label.text = new_title

## Get content container to add custom content
func get_content_container() -> MarginContainer:
	return content_container

## Set window position
func set_window_position(pos: Vector2) -> void:
	global_position = pos

## Set window size
func set_window_size(new_size: Vector2) -> void:
	size = new_size.clamp(min_size, max_size)
