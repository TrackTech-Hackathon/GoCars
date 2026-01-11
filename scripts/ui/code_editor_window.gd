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

## Current file
var current_file: String = "main.py"
var is_modified: bool = false

## Speed options
var speed_options: Array = [0.5, 1.0, 2.0, 4.0]
var current_speed: float = 1.0

func _init() -> void:
	window_title = "Code Editor"
	min_size = Vector2(700, 500)
	default_size = Vector2(900, 600)
	default_position = Vector2(50, 50)

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
	hsplit.add_child(code_edit)

	# Status bar
	status_bar = HBoxContainer.new()
	status_bar.name = "StatusBar"
	vbox.add_child(status_bar)

	status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.text = "Ln 1, Col 1 | main.py | ✓ Saved"
	status_bar.add_child(status_label)

	# Connect signals
	run_button.pressed.connect(_on_run_pressed)
	pause_button.pressed.connect(_on_pause_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	file_explorer.file_selected.connect(_on_file_selected)
	code_edit.text_changed.connect(_on_text_changed)
	code_edit.caret_changed.connect(_update_status_bar)

func _input(event: InputEvent) -> void:
	# Only handle input when window is visible
	if not visible:
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

		# F2: Rename file (if file explorer supports it)
		elif event.keycode == KEY_F2:
			# Trigger rename on selected file
			if file_explorer:
				print("F2 pressed - rename functionality not yet implemented")
			get_viewport().set_input_as_handled()

		# F5 or Ctrl+Enter: Run code
		elif (event.keycode == KEY_F5) or (event.keycode == KEY_ENTER and event.ctrl_pressed):
			_on_run_pressed()
			get_viewport().set_input_as_handled()

func _create_python_highlighter() -> SyntaxHighlighter:
	var highlighter = SyntaxHighlighter.new()

	# Python keywords (purple)
	var keyword_color = Color(0.773, 0.525, 0.753)  # #C586C0
	var keywords = [
		"if", "elif", "else", "while", "for", "in", "range",
		"and", "or", "not", "break", "return", "def", "from", "import"
	]

	# Built-in constants (blue)
	var constant_color = Color(0.337, 0.612, 0.839)  # #569CD6
	var constants = ["True", "False", "None"]

	# This is a simplified highlighter - full implementation would require
	# a custom SyntaxHighlighter subclass with _get_line_syntax_highlighting
	return highlighter

## Set the virtual filesystem
func set_virtual_filesystem(vfs: Variant) -> void:
	virtual_fs = vfs
	if file_explorer:
		file_explorer.set_virtual_filesystem(vfs)
		_load_file(current_file)

## Load a file into the editor
func _load_file(file_path: String) -> void:
	if virtual_fs == null:
		return

	var content = virtual_fs.read_file(file_path)
	code_edit.text = content
	current_file = file_path
	is_modified = false
	_update_status_bar()

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
