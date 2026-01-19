## Floating Window Base Class for GoCars
## Provides draggable, resizable, minimizable window functionality
## With Windows 11-style snap zones
## Author: Claude Code
## Date: January 2026

extends PanelContainer
class_name FloatingWindow

## Signals
signal window_closed()
signal window_minimized()
signal window_restored()
signal window_focused()
signal window_maximized()
signal window_snapped(zone: int)

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
var maximize_button: Button
var close_button: Button
var content_container: MarginContainer
var resize_handle_size: int = 8

## Snap controller for Windows 11-style window snapping
var snap_controller: Variant = null

## Pre-maximized state
var pre_maximize_rect: Rect2 = Rect2()
var is_window_maximized: bool = false

func _ready() -> void:
	# Set initial size and position
	custom_minimum_size = min_size
	size = default_size

	# Center window if default_position is zero
	if default_position == Vector2.ZERO:
		var viewport_size = get_viewport_rect().size
		position = (viewport_size - default_size) / 2
	else:
		position = default_position

	# Add stylish panel with rounded corners and shadow
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.18, 0.98)  # Dark background
	style.border_color = Color(0.3, 0.3, 0.35, 1.0)  # Subtle border
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.shadow_size = 8
	style.shadow_color = Color(0, 0, 0, 0.3)
	add_theme_stylebox_override("panel", style)

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
	title_bar.custom_minimum_size = Vector2(0, 36)

	# Style title bar
	var title_style = StyleBoxFlat.new()
	title_style.bg_color = Color(0.2, 0.2, 0.24, 1.0)  # Slightly lighter than window
	title_style.corner_radius_top_left = 7
	title_style.corner_radius_top_right = 7
	title_bar.add_theme_stylebox_override("panel", title_style)
	vbox.add_child(title_bar)

	var title_hbox = HBoxContainer.new()
	title_hbox.add_theme_constant_override("separation", 8)
	title_bar.add_child(title_hbox)

	# Add spacer for padding
	var spacer_left = Control.new()
	spacer_left.custom_minimum_size = Vector2(8, 0)
	title_hbox.add_child(spacer_left)

	# Title label
	title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.text = window_title
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95, 1.0))
	title_label.add_theme_font_size_override("font_size", 14)
	title_hbox.add_child(title_label)

	# Minimize button
	minimize_button = Button.new()
	minimize_button.name = "MinimizeButton"
	minimize_button.text = "−"
	minimize_button.custom_minimum_size = Vector2(28, 28)
	minimize_button.flat = true
	minimize_button.tooltip_text = "Minimize"
	minimize_button.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75, 1.0))
	minimize_button.add_theme_font_size_override("font_size", 18)
	title_hbox.add_child(minimize_button)

	# Maximize button
	maximize_button = Button.new()
	maximize_button.name = "MaximizeButton"
	maximize_button.text = "□"
	maximize_button.custom_minimum_size = Vector2(28, 28)
	maximize_button.flat = true
	maximize_button.tooltip_text = "Maximize"
	maximize_button.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75, 1.0))
	maximize_button.add_theme_font_size_override("font_size", 14)
	title_hbox.add_child(maximize_button)

	# Close button
	close_button = Button.new()
	close_button.name = "CloseButton"
	close_button.text = "×"
	close_button.custom_minimum_size = Vector2(28, 28)
	close_button.flat = true
	close_button.tooltip_text = "Close"
	close_button.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4, 1.0))
	close_button.add_theme_font_size_override("font_size", 20)
	title_hbox.add_child(close_button)

	# Add spacer for padding
	var spacer_right = Control.new()
	spacer_right.custom_minimum_size = Vector2(4, 0)
	title_hbox.add_child(spacer_right)

	# Content container
	content_container = MarginContainer.new()
	content_container.name = "ContentContainer"
	content_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_container.add_theme_constant_override("margin_left", 8)
	content_container.add_theme_constant_override("margin_right", 8)
	content_container.add_theme_constant_override("margin_top", 8)
	content_container.add_theme_constant_override("margin_bottom", 8)
	vbox.add_child(content_container)

func _connect_signals() -> void:
	# Setup snap controller
	var SnapWindowControllerClass = load("res://scripts/ui/snap_window_controller.gd")
	if SnapWindowControllerClass:
		snap_controller = SnapWindowControllerClass.new()
		add_child(snap_controller)
		snap_controller.setup(self, title_bar)
		snap_controller.window_maximized.connect(_on_snap_maximized)
		snap_controller.window_restored.connect(_on_snap_restored)
		snap_controller.window_snapped.connect(_on_window_snapped)

	# Title bar drag (if snap controller not handling it, use fallback)
	if not snap_controller:
		title_bar.gui_input.connect(_on_title_bar_input)

	# Buttons
	minimize_button.pressed.connect(_on_minimize_pressed)
	maximize_button.pressed.connect(_on_maximize_pressed)
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
	# Only handle input when this window is visible and focused
	if not visible:
		return

	# Handle resize dragging
	if is_resizing and event is InputEventMouseMotion:
		_handle_resize(get_global_mouse_position())

	elif event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if not mouse_event.pressed and is_resizing:
				is_resizing = false
				resize_mode = ResizeMode.NONE

	# Handle keyboard shortcuts
	elif event is InputEventKey and event.pressed and not event.echo:
		# F11: Toggle maximize
		if event.keycode == KEY_F11:
			toggle_maximize()
			get_viewport().set_input_as_handled()

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

func _on_maximize_pressed() -> void:
	toggle_maximize()

func _on_close_pressed() -> void:
	close()

## Snap controller callbacks
func _on_snap_maximized() -> void:
	is_window_maximized = true
	_update_maximize_button()
	window_maximized.emit()

func _on_snap_restored() -> void:
	is_window_maximized = false
	_update_maximize_button()
	window_restored.emit()

func _on_window_snapped(zone: int) -> void:
	window_snapped.emit(zone)

## Update maximize button appearance
func _update_maximize_button() -> void:
	if maximize_button:
		if is_window_maximized:
			maximize_button.text = "❐"  # Restore icon (overlapping squares)
			maximize_button.tooltip_text = "Restore"
		else:
			maximize_button.text = "□"  # Maximize icon
			maximize_button.tooltip_text = "Maximize"

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

## Maximize the window
func maximize() -> void:
	if snap_controller:
		snap_controller.maximize()
	else:
		# Fallback maximization without snap controller
		if not is_window_maximized:
			pre_maximize_rect = Rect2(global_position, size)
			var viewport_size = get_viewport_rect().size
			global_position = Vector2(4, 4)
			size = viewport_size - Vector2(8, 8)
			is_window_maximized = true
			_update_maximize_button()
			window_maximized.emit()

## Restore from maximized state
func restore_from_maximize() -> void:
	if snap_controller:
		snap_controller.restore()
	else:
		# Fallback restoration without snap controller
		if is_window_maximized and pre_maximize_rect.size != Vector2.ZERO:
			global_position = pre_maximize_rect.position
			size = pre_maximize_rect.size
			is_window_maximized = false
			_update_maximize_button()
			window_restored.emit()

## Toggle maximize state
func toggle_maximize() -> void:
	if is_window_maximized:
		restore_from_maximize()
	else:
		maximize()

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
