## Code Editor Window for GoCars
## Main code editing window with file explorer, editor, and controls
## Author: Claude Code
## Date: January 2026

extends FloatingWindow
class_name CodeEditorWindow

## Signals
signal code_run_requested(code: String)
signal code_pause_requested()
signal code_reset_requested()
signal speed_changed(speed: float)

## Child nodes
var control_bar: HBoxContainer
var run_button: Button
var pause_button: Button
var reset_button: Button
var speed_button: MenuButton
var hsplit: HSplitContainer
var file_explorer: FileExplorer
var code_edit: CodeEdit
var status_bar: HBoxContainer
var status_label: Label

## Virtual filesystem reference
var virtual_fs: Variant = null  # VirtualFileSystem instance

## Debugger reference
var debugger: Variant = null  # Debugger instance

## IntelliSense manager
var intellisense: Variant = null

## Current file
var current_file: String = "main.py"
var is_modified: bool = false

## Speed options
var speed_options: Array = [0.5, 1.0, 2.0, 4.0]
var current_speed: float = 1.0

## Debugger constants
const BREAKPOINT_GUTTER: int = 1
const EXECUTION_LINE_COLOR: Color = Color(1.0, 1.0, 0.0, 0.2)  # Yellow highlight

func _init() -> void:
	window_title = "Code Editor"
	min_size = Vector2(700, 500)
	default_size = Vector2(900, 600)
	# Center the window - will be calculated in _ready based on viewport size
	default_position = Vector2.ZERO  # Will be set to center in _ready

func _ready() -> void:
	super._ready()
	_setup_editor_ui()

func _setup_editor_ui() -> void:
	var content = get_content_container()

	# Main VBox for editor content
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(vbox)

	# Control bar
	control_bar = HBoxContainer.new()
	control_bar.name = "ControlBar"
	vbox.add_child(control_bar)

	# Run button
	run_button = Button.new()
	run_button.name = "RunButton"
	run_button.text = "▶ Run"
	run_button.tooltip_text = "Run code (F5 or Ctrl+Enter)"
	control_bar.add_child(run_button)

	# Pause button
	pause_button = Button.new()
	pause_button.name = "PauseButton"
	pause_button.text = "⏸ Pause"
	pause_button.tooltip_text = "Pause execution (Space)"
	control_bar.add_child(pause_button)

	# Reset button
	reset_button = Button.new()
	reset_button.name = "ResetButton"
	reset_button.text = "🔄 Reset"
	reset_button.tooltip_text = "Reset level (R or Ctrl+R)"
	control_bar.add_child(reset_button)

	# Speed button
	speed_button = MenuButton.new()
	speed_button.name = "SpeedButton"
	speed_button.text = "1x ▼"
	speed_button.tooltip_text = "Change simulation speed"
	control_bar.add_child(speed_button)

	# Setup speed menu
	var popup = speed_button.get_popup()
	for speed in speed_options:
		popup.add_item("%.1fx" % speed)
	popup.index_pressed.connect(_on_speed_selected)

	# HSplit for file explorer and editor
	hsplit = HSplitContainer.new()
	hsplit.name = "HSplit"
	hsplit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(hsplit)

	# File explorer
	var FileExplorerClass = load("res://scripts/ui/file_explorer.gd")
	file_explorer = FileExplorerClass.new()
	file_explorer.name = "FileExplorer"
	file_explorer.custom_minimum_size = Vector2(200, 0)
	hsplit.add_child(file_explorer)

	# Code editor
	code_edit = CodeEdit.new()
	code_edit.name = "CodeEdit"
	code_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	code_edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	code_edit.syntax_highlighter = _create_python_highlighter()
	code_edit.gutters_draw_line_numbers = true
	code_edit.wrap_mode = TextEdit.LINE_WRAPPING_NONE

	# Add breakpoint gutter
	code_edit.add_gutter(BREAKPOINT_GUTTER)
	code_edit.set_gutter_name(BREAKPOINT_GUTTER, "breakpoints")
	code_edit.set_gutter_clickable(BREAKPOINT_GUTTER, true)
	code_edit.set_gutter_draw(BREAKPOINT_GUTTER, true)
	code_edit.set_gutter_type(BREAKPOINT_GUTTER, TextEdit.GUTTER_TYPE_ICON)

	hsplit.add_child(code_edit)

	# Status bar
	status_bar = HBoxContainer.new()
	status_bar.name = "StatusBar"
	vbox.add_child(status_bar)

	status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.text = "Ln 1, Col 1 | main.py | ✓ Saved"
	status_bar.add_child(status_label)

	# Setup IntelliSense
	var IntelliSenseClass = load("res://scripts/ui/intellisense_manager.gd")
	intellisense = IntelliSenseClass.new(code_edit)
	intellisense.setup_popups(content)
	intellisense.set_current_file(current_file)

	# Connect signals
	run_button.pressed.connect(_on_run_pressed)
	pause_button.pressed.connect(_on_pause_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	file_explorer.file_selected.connect(_on_file_selected)
	code_edit.text_changed.connect(_on_text_changed)
	code_edit.caret_changed.connect(_update_status_bar)
	code_edit.gutter_clicked.connect(_on_gutter_clicked)

func _input(event: InputEvent) -> void:
	# Only handle input when window is visible
	if not visible:
		return

	# Let IntelliSense handle input first
	if intellisense and intellisense.handle_input(event):
		return

	if event is InputEventKey and event.pressed and not event.echo:
		# Ctrl+N: New file
		if event.keycode == KEY_N and event.ctrl_pressed:
			file_explorer._on_new_file_pressed()
			get_viewport().set_input_as_handled()

		# Ctrl+S: Save file
		elif event.keycode == KEY_S and event.ctrl_pressed:
			_save_file()
			get_viewport().set_input_as_handled()

		# F2: Rename file
		elif event.keycode == KEY_F2:
			if file_explorer:
				file_explorer._on_rename_pressed()
			get_viewport().set_input_as_handled()

		# F5 or Ctrl+Enter: Run code / Continue debugging
		elif (event.keycode == KEY_F5) or (event.keycode == KEY_ENTER and event.ctrl_pressed):
			if debugger and debugger.is_paused():
				debugger.resume_execution()
			else:
				_on_run_pressed()
			get_viewport().set_input_as_handled()

		# F10: Step over
		elif event.keycode == KEY_F10:
			if debugger:
				debugger.step_over()
			get_viewport().set_input_as_handled()

		# F11: Step into
		elif event.keycode == KEY_F11 and not event.shift_pressed:
			if debugger:
				debugger.step_into()
			get_viewport().set_input_as_handled()

		# Shift+F11: Step out
		elif event.keycode == KEY_F11 and event.shift_pressed:
			if debugger:
				debugger.step_out()
			get_viewport().set_input_as_handled()

func _create_python_highlighter() -> SyntaxHighlighter:
	# Load and create the custom PythonSyntaxHighlighter
	var PythonSyntaxHighlighterClass = load("res://scripts/ui/python_syntax_highlighter.gd")
	var highlighter = PythonSyntaxHighlighterClass.new()
	return highlighter

## Set the virtual filesystem
func set_virtual_filesystem(vfs: Variant) -> void:
	virtual_fs = vfs
	if file_explorer:
		file_explorer.set_virtual_filesystem(vfs)
		_load_file(current_file)

## Set the debugger
func set_debugger(dbg: Variant) -> void:
	debugger = dbg
	if debugger:
		# Connect debugger signals
		debugger.breakpoint_hit.connect(_on_breakpoint_hit)
		debugger.execution_paused.connect(_on_execution_paused)
		debugger.execution_resumed.connect(_on_execution_resumed)
		debugger.execution_line_changed.connect(_on_execution_line_changed)

## Load a file into the editor
func _load_file(file_path: String) -> void:
	if virtual_fs == null:
		return

	var content = virtual_fs.read_file(file_path)
	code_edit.text = content
	current_file = file_path
	is_modified = false
	_update_status_bar()

	# Parse file for IntelliSense
	if intellisense:
		intellisense.parse_file_symbols(file_path, content)
		intellisense.set_current_file(file_path)

## Save current file
func _save_file() -> void:
	if virtual_fs == null or current_file == "":
		return

	virtual_fs.update_file(current_file, code_edit.text)
	is_modified = false
	_update_status_bar()

func _on_file_selected(file_path: String) -> void:
	# Save current file if modified
	if is_modified:
		_save_file()

	_load_file(file_path)

func _on_text_changed() -> void:
	is_modified = true
	_update_status_bar()

	# Trigger IntelliSense
	if intellisense:
		intellisense.on_text_changed()

func _update_status_bar() -> void:
	var line = code_edit.get_caret_line() + 1
	var col = code_edit.get_caret_column() + 1
	var saved_text = "✓ Saved" if not is_modified else "● Modified"
	status_label.text = "Ln %d, Col %d | %s | %s" % [line, col, current_file, saved_text]

func _on_run_pressed() -> void:
	# Auto-save before running
	if is_modified:
		_save_file()
	code_run_requested.emit(code_edit.text)

func _on_pause_pressed() -> void:
	code_pause_requested.emit()

func _on_reset_pressed() -> void:
	code_reset_requested.emit()

func _on_speed_selected(index: int) -> void:
	current_speed = speed_options[index]
	speed_button.text = "%.1fx ▼" % current_speed
	speed_changed.emit(current_speed)

## Get current code
func get_code() -> String:
	return code_edit.text

## Set code
func set_code(code: String) -> void:
	code_edit.text = code
	is_modified = false
	_update_status_bar()

## Gutter clicked (for breakpoints)
func _on_gutter_clicked(line: int, gutter: int) -> void:
	if gutter != BREAKPOINT_GUTTER or not debugger:
		return

	# Toggle breakpoint
	var is_active = debugger.toggle_breakpoint(current_file, line)

	if is_active:
		# Add breakpoint icon
		code_edit.set_line_gutter_icon(line, BREAKPOINT_GUTTER, _create_breakpoint_icon())
	else:
		# Remove breakpoint icon
		code_edit.set_line_gutter_icon(line, BREAKPOINT_GUTTER, null)

## Create breakpoint icon
func _create_breakpoint_icon() -> Texture2D:
	var size = 16
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)

	# Draw red circle
	for y in range(size):
		for x in range(size):
			var dx = x - size / 2.0
			var dy = y - size / 2.0
			var dist = sqrt(dx * dx + dy * dy)
			if dist <= size / 2.0:
				image.set_pixel(x, y, Color.RED)

	return ImageTexture.create_from_image(image)

## Debugger callbacks
func _on_breakpoint_hit(line: int, file: String) -> void:
	if file == current_file:
		_highlight_execution_line(line)

func _on_execution_paused() -> void:
	# Could show a paused indicator in the UI
	pass

func _on_execution_resumed() -> void:
	# Clear execution line highlighting
	_clear_execution_line()

func _on_execution_line_changed(file: String, line: int) -> void:
	if file == current_file:
		_highlight_execution_line(line)

## Highlight the current execution line
func _highlight_execution_line(line: int) -> void:
	# Remove previous highlight
	_clear_execution_line()

	# Set background color for the execution line
	code_edit.set_line_background_color(line, EXECUTION_LINE_COLOR)

## Clear execution line highlighting
func _clear_execution_line() -> void:
	# Clear all line background colors
	for i in range(code_edit.get_line_count()):
		code_edit.set_line_background_color(i, Color(0, 0, 0, 0))
