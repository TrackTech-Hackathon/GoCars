## Terminal/Output Panel for GoCars Code Editor
## Provides a VS Code-style terminal/output panel for displaying
## debug messages, print statements, errors, and execution info
## Author: Claude Code
## Date: January 2026

extends PanelContainer
class_name TerminalPanel

## Signals
signal terminal_cleared()
signal error_clicked(line: int)

## Message types for coloring
enum MessageType {
	INFO,      # White/default
	DEBUG,     # Gray
	WARNING,   # Yellow
	ERROR,     # Red
	SUCCESS,   # Green
	PRINT      # Cyan - for user print() statements
}

## Child nodes
var header_container: HBoxContainer
var tab_bar: HBoxContainer
var clear_button: Button
var copy_button: Button
var scroll_container: ScrollContainer
var output_text: RichTextLabel

## State
var auto_scroll: bool = true
var max_lines: int = 500
var current_tab: String = "OUTPUT"
var is_collapsed: bool = false
var original_height: float = 150.0

## Colors for different message types
var colors: Dictionary = {
	MessageType.INFO: "#FFFFFF",
	MessageType.DEBUG: "#888888",
	MessageType.WARNING: "#FFD700",
	MessageType.ERROR: "#FF4444",
	MessageType.SUCCESS: "#44FF44",
	MessageType.PRINT: "#00FFFF"
}

## Prefixes for different message types
var prefixes: Dictionary = {
	MessageType.INFO: "",
	MessageType.DEBUG: "[DEBUG] ",
	MessageType.WARNING: "[WARNING] ",
	MessageType.ERROR: "[ERROR] ",
	MessageType.SUCCESS: "[SUCCESS] ",
	MessageType.PRINT: "> "
}

func _ready() -> void:
	_setup_ui()
	_apply_style()

func _setup_ui() -> void:
	name = "TerminalPanel"
	custom_minimum_size = Vector2(0, 100)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Main VBox container
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(vbox)

	# Header with tabs and buttons
	header_container = HBoxContainer.new()
	header_container.name = "HeaderContainer"
	header_container.custom_minimum_size = Vector2(0, 28)
	vbox.add_child(header_container)

	# Tab bar (OUTPUT | PROBLEMS | DEBUG CONSOLE)
	tab_bar = HBoxContainer.new()
	tab_bar.name = "TabBar"
	tab_bar.add_theme_constant_override("separation", 0)
	header_container.add_child(tab_bar)

	# Create tabs
	var tabs = ["OUTPUT", "PROBLEMS", "DEBUG"]
	for tab_name in tabs:
		var tab_button = Button.new()
		tab_button.text = tab_name
		tab_button.flat = true
		tab_button.toggle_mode = true
		tab_button.button_pressed = (tab_name == "OUTPUT")
		tab_button.custom_minimum_size = Vector2(80, 24)
		tab_button.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
		tab_button.add_theme_color_override("font_pressed_color", Color(0.9, 0.9, 0.95))
		tab_button.add_theme_color_override("font_hover_color", Color(0.8, 0.8, 0.85))
		tab_button.pressed.connect(_on_tab_pressed.bind(tab_name))
		tab_bar.add_child(tab_button)

	# Spacer
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_container.add_child(spacer)

	# Collapse/Expand toggle
	var collapse_button = Button.new()
	collapse_button.name = "CollapseButton"
	collapse_button.text = "▼"
	collapse_button.flat = true
	collapse_button.custom_minimum_size = Vector2(24, 24)
	collapse_button.tooltip_text = "Collapse/Expand terminal"
	collapse_button.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	collapse_button.pressed.connect(_on_collapse_pressed)
	header_container.add_child(collapse_button)

	# Clear button
	clear_button = Button.new()
	clear_button.name = "ClearButton"
	clear_button.text = "Clear"
	clear_button.flat = true
	clear_button.custom_minimum_size = Vector2(50, 24)
	clear_button.tooltip_text = "Clear terminal output (Ctrl+L)"
	clear_button.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	clear_button.add_theme_color_override("font_hover_color", Color(0.9, 0.9, 0.95))
	clear_button.pressed.connect(_on_clear_pressed)
	header_container.add_child(clear_button)

	# Copy button
	copy_button = Button.new()
	copy_button.name = "CopyButton"
	copy_button.text = "Copy"
	copy_button.flat = true
	copy_button.custom_minimum_size = Vector2(50, 24)
	copy_button.tooltip_text = "Copy all output to clipboard"
	copy_button.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	copy_button.add_theme_color_override("font_hover_color", Color(0.9, 0.9, 0.95))
	copy_button.pressed.connect(_on_copy_pressed)
	header_container.add_child(copy_button)

	# Separator
	var separator = HSeparator.new()
	separator.add_theme_color_override("separation_color", Color(0.25, 0.25, 0.3))
	vbox.add_child(separator)

	# Scroll container for output
	scroll_container = ScrollContainer.new()
	scroll_container.name = "ScrollContainer"
	scroll_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll_container)

	# Rich text label for colored output
	output_text = RichTextLabel.new()
	output_text.name = "OutputText"
	output_text.bbcode_enabled = true
	output_text.scroll_following = true
	output_text.selection_enabled = true
	output_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	output_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	output_text.add_theme_color_override("default_color", Color(0.85, 0.85, 0.9))
	output_text.add_theme_font_size_override("normal_font_size", 13)
	scroll_container.add_child(output_text)

	# Connect meta clicked for clickable error links
	output_text.meta_clicked.connect(_on_meta_clicked)

func _apply_style() -> void:
	# Apply dark terminal-like style
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.12, 1.0)  # Dark background
	style.border_color = Color(0.2, 0.2, 0.25, 1.0)
	style.border_width_top = 1
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	add_theme_stylebox_override("panel", style)

## Print a message with specified type
func print_message(message: String, type: MessageType = MessageType.PRINT) -> void:
	var color = colors.get(type, "#FFFFFF")
	var prefix = prefixes.get(type, "")

	# Format with color and prefix
	var formatted = "[color=%s]%s%s[/color]\n" % [color, prefix, message]
	output_text.append_text(formatted)

	_trim_output_if_needed()

	if auto_scroll:
		# Scroll to bottom after content is updated
		await get_tree().process_frame
		var scrollbar = scroll_container.get_v_scroll_bar()
		if scrollbar:
			scrollbar.value = scrollbar.max_value

## Print an info message
func print_info(message: String) -> void:
	print_message(message, MessageType.INFO)

## Print a debug message
func print_debug(message: String) -> void:
	print_message(message, MessageType.DEBUG)

## Print a warning message
func print_warning(message: String) -> void:
	print_message(message, MessageType.WARNING)

## Print an error message with optional line number
func print_error(message: String, line_number: int = -1) -> void:
	var line_info = ""
	if line_number > 0:
		# Make line number clickable
		line_info = " [url=line:%d](Line %d)[/url]" % [line_number, line_number]
	print_message(message + line_info, MessageType.ERROR)

## Print a success message
func print_success(message: String) -> void:
	print_message(message, MessageType.SUCCESS)

## Print user code output (from print() statements)
func print_output(message: String) -> void:
	print_message(message, MessageType.PRINT)

## Print execution started message
func print_execution_started() -> void:
	print_info("─".repeat(40))
	print_info("Running script...")

## Print execution completed message
func print_execution_completed(success: bool = true) -> void:
	if success:
		print_success("Script completed successfully")
	else:
		print_error("Script execution failed")
	print_info("─".repeat(40))

## Clear terminal output
func clear() -> void:
	output_text.clear()
	terminal_cleared.emit()

## Get all text content
func get_text() -> String:
	return output_text.get_parsed_text()

## Set auto-scroll behavior
func set_auto_scroll(enabled: bool) -> void:
	auto_scroll = enabled
	output_text.scroll_following = enabled

## Collapse/hide the terminal content
func collapse() -> void:
	if not is_collapsed:
		original_height = size.y
		scroll_container.visible = false
		custom_minimum_size.y = 28  # Just header height
		is_collapsed = true
		var collapse_btn = header_container.get_node_or_null("CollapseButton")
		if collapse_btn:
			collapse_btn.text = "▲"

## Expand/show the terminal content
func expand() -> void:
	if is_collapsed:
		scroll_container.visible = true
		custom_minimum_size.y = 100
		is_collapsed = false
		var collapse_btn = header_container.get_node_or_null("CollapseButton")
		if collapse_btn:
			collapse_btn.text = "▼"

## Toggle collapsed state
func toggle_collapse() -> void:
	if is_collapsed:
		expand()
	else:
		collapse()

## Internal: Trim output if it exceeds max lines
func _trim_output_if_needed() -> void:
	var line_count = output_text.get_line_count()
	if line_count > max_lines:
		var text = output_text.get_parsed_text()
		var lines = text.split("\n")
		if lines.size() > max_lines:
			var trimmed_lines = lines.slice(lines.size() - max_lines)
			output_text.clear()
			output_text.append_text("\n".join(trimmed_lines))

## Internal: Tab button pressed
func _on_tab_pressed(tab_name: String) -> void:
	current_tab = tab_name
	# Update tab button states
	for child in tab_bar.get_children():
		if child is Button:
			child.button_pressed = (child.text == tab_name)
	# TODO: Switch content based on tab (for now, all use same output)

## Internal: Collapse button pressed
func _on_collapse_pressed() -> void:
	toggle_collapse()

## Internal: Clear button pressed
func _on_clear_pressed() -> void:
	clear()

## Internal: Copy button pressed
func _on_copy_pressed() -> void:
	DisplayServer.clipboard_set(get_text())

## Internal: Meta (URL) clicked in output
func _on_meta_clicked(meta: Variant) -> void:
	var meta_str = str(meta)
	if meta_str.begins_with("line:"):
		var line_num = int(meta_str.substr(5))
		error_clicked.emit(line_num)
