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
var main_vsplit: VSplitContainer  # Main vertical split for editor and terminal
var hsplit: HSplitContainer
var file_explorer: FileExplorer
var code_edit: CodeEdit
var terminal_panel: Variant = null  # Terminal/Output panel
var status_bar: HBoxContainer
var status_label: Label
var metrics_label: Label

## Virtual filesystem reference
var virtual_fs: Variant = null  # VirtualFileSystem instance

## Debugger reference
var debugger: Variant = null  # Debugger instance

## IntelliSense manager
var intellisense: Variant = null

## Advanced features
var snippet_handler: Variant = null
var error_highlighter: Variant = null
var execution_tracer: Variant = null
var performance_metrics: Variant = null

## Execution line highlighting with smooth transition
var _current_highlighted_line: int = -1
var _highlight_tween: Tween = null

## Store breakpoints locally if no debugger is connected
var local_breakpoints: Dictionary = {}  # line -> bool

## Current file
var current_file: String = "main.py"
var is_modified: bool = false

## Speed options
var speed_options: Array = [0.5, 1.0, 2.0, 4.0]
var current_speed: float = 1.0

## Debugger constants
const BREAKPOINT_GUTTER: int = 1
const EXECUTION_LINE_COLOR: Color = Color(1.0, 1.0, 0.0, 0.35)  # Brighter yellow highlight

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

	# Main VSplit for editor area and terminal
	main_vsplit = VSplitContainer.new()
	main_vsplit.name = "MainVSplit"
	main_vsplit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vsplit.split_offset = -150  # Terminal takes bottom ~150px
	vbox.add_child(main_vsplit)

	# HSplit for file explorer and editor
	hsplit = HSplitContainer.new()
	hsplit.name = "HSplit"
	hsplit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vsplit.add_child(hsplit)

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
	code_edit.gutters_draw_fold_gutter = false  # Disable code folding arrows
	code_edit.wrap_mode = TextEdit.LINE_WRAPPING_NONE

	# Basic editor settings
	code_edit.indent_automatic = true
	code_edit.indent_size = 4
	code_edit.indent_use_spaces = true

	# String and comment delimiters for syntax highlighting (not folding)
	code_edit.add_comment_delimiter("#", "", true)  # Single line comment
	code_edit.add_string_delimiter("\"", "\"", false)
	code_edit.add_string_delimiter("'", "'", false)

	# Add breakpoint gutter
	code_edit.add_gutter(BREAKPOINT_GUTTER)
	code_edit.set_gutter_name(BREAKPOINT_GUTTER, "breakpoints")
	code_edit.set_gutter_clickable(BREAKPOINT_GUTTER, true)
	code_edit.set_gutter_draw(BREAKPOINT_GUTTER, true)
	code_edit.set_gutter_type(BREAKPOINT_GUTTER, TextEdit.GUTTER_TYPE_ICON)

	hsplit.add_child(code_edit)

	# Terminal/Output Panel (below the code editor)
	var TerminalPanelClass = load("res://scripts/ui/terminal_panel.gd")
	terminal_panel = TerminalPanelClass.new()
	terminal_panel.name = "TerminalPanel"
	terminal_panel.custom_minimum_size = Vector2(0, 120)
	main_vsplit.add_child(terminal_panel)

	# Connect terminal panel signals
	terminal_panel.error_clicked.connect(_on_terminal_error_clicked)
	print("CodeEditorWindow: Terminal panel initialized")

	# Status bar
	status_bar = HBoxContainer.new()
	status_bar.name = "StatusBar"
	vbox.add_child(status_bar)

	status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.text = "Ln 1, Col 1 | main.py | ✓ Saved"
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_bar.add_child(status_label)

	# Spacer to push metrics to the right
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_bar.add_child(spacer)

	# Performance metrics label (right-aligned)
	metrics_label = Label.new()
	metrics_label.name = "MetricsLabel"
	metrics_label.text = "Steps: 0 | LOC: 0"
	metrics_label.add_theme_color_override("font_color", Color(0.6, 0.8, 0.6))
	status_bar.add_child(metrics_label)

	# Setup IntelliSense
	var IntelliSenseClass = load("res://scripts/ui/intellisense_manager.gd")
	intellisense = IntelliSenseClass.new(code_edit)
	intellisense.setup_popups(content)
	intellisense.set_current_file(current_file)

	# Setup Snippet Handler
	var SnippetHandlerClass = load("res://scripts/core/snippet_handler.gd")
	snippet_handler = SnippetHandlerClass.new(code_edit)
	print("CodeEditorWindow: Snippet handler initialized")

	# Setup Error Highlighter (includes linter)
	var ErrorHighlighterClass = load("res://scripts/ui/error_highlighter.gd")
	error_highlighter = ErrorHighlighterClass.new(code_edit)
	error_highlighter.setup_error_panel(vbox)  # Add error panel below editor
	print("CodeEditorWindow: Error highlighter initialized")

	# Setup Execution Tracer
	var ExecutionTracerClass = load("res://scripts/core/execution_tracer.gd")
	execution_tracer = ExecutionTracerClass.new(code_edit)
	print("CodeEditorWindow: Execution tracer initialized")

	# Setup Performance Metrics
	var PerformanceMetricsClass = load("res://scripts/core/performance_metrics.gd")
	performance_metrics = PerformanceMetricsClass.new()
	print("CodeEditorWindow: Performance metrics initialized")

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
		# Tab: Try snippet expansion first
		if event.keycode == KEY_TAB and snippet_handler:
			var text_before_caret = code_edit.get_line(code_edit.get_caret_line()).substr(0, code_edit.get_caret_column())
			var word_match = text_before_caret.rfind(" ")
			var trigger = text_before_caret.substr(word_match + 1) if word_match != -1 else text_before_caret
			if snippet_handler.try_expand(trigger.strip_edges()):
				get_viewport().set_input_as_handled()
				return
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

## Connect to simulation engine for execution visualization
func connect_to_simulation(sim_engine: Variant) -> void:
	if not sim_engine:
		return

	# Connect execution tracer if available
	if execution_tracer and sim_engine.has_signal("execution_started"):
		sim_engine.execution_started.connect(func(): execution_tracer.start_execution(code_edit.text))
		sim_engine.execution_ended.connect(func(success): execution_tracer.stop_execution())

	# Connect execution line highlighting (signal is execution_line_changed)
	if sim_engine.has_signal("execution_line_changed"):
		sim_engine.execution_line_changed.connect(_on_execution_line_changed)
		print("CodeEditorWindow: Connected execution_line_changed signal")

	# Connect print output for Python print() statements
	if sim_engine.has_signal("print_output"):
		sim_engine.print_output.connect(_on_print_output)
		print("CodeEditorWindow: Connected print_output signal")

	# Connect execution errors
	if sim_engine.has_signal("execution_error_occurred"):
		sim_engine.execution_error_occurred.connect(_on_execution_error)
		print("CodeEditorWindow: Connected execution_error_occurred signal")

	print("CodeEditorWindow: Connected to simulation engine")

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

	# Update LOC metrics
	update_metrics()

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

	# Trigger linting (error checking)
	if error_highlighter:
		error_highlighter.lint_content(code_edit.text)

	# Update performance metrics (LOC count) in real-time
	update_metrics()

func _update_status_bar() -> void:
	var line = code_edit.get_caret_line() + 1
	var col = code_edit.get_caret_column() + 1
	var saved_text = "✓ Saved" if not is_modified else "● Modified"
	status_label.text = "Ln %d, Col %d | %s | %s" % [line, col, current_file, saved_text]

func _on_run_pressed() -> void:
	# Auto-save before running
	if is_modified:
		_save_file()

	# Clear any previous execution highlight
	_clear_execution_line()

	# Clear terminal and print execution start
	if terminal_panel:
		terminal_panel.clear()
		terminal_panel.print_execution_started()

	# Update metrics to show execution started
	on_execution_started()

	code_run_requested.emit(code_edit.text)

func _on_pause_pressed() -> void:
	code_pause_requested.emit()

func _on_reset_pressed() -> void:
	# Clear execution highlight
	_clear_execution_line()
	# Reset metrics display
	update_metrics()
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

## Highlight execution line (for execution visualization)
## Call this with the current line number (0-indexed) when code is executing
func highlight_line(line: int) -> void:
	_highlight_execution_line(line)

## Clear execution visualization
func clear_highlight() -> void:
	_clear_execution_line()

## Update performance metrics display
func update_metrics(steps: int = -1, loc: int = -1, time_ms: float = -1) -> void:
	if not metrics_label:
		return

	# If steps is -1, calculate LOC from current code
	if steps < 0 and loc < 0:
		# Just count lines of code
		var code = code_edit.text
		var lines = code.split("\n")
		var code_lines = 0
		for line in lines:
			var stripped = line.strip_edges()
			if not stripped.is_empty() and not stripped.begins_with("#"):
				code_lines += 1
		loc = code_lines

	# Build metrics text
	var parts: Array[String] = []

	if steps >= 0:
		parts.append("Steps: %d" % steps)
	if loc >= 0:
		parts.append("LOC: %d" % loc)
	if time_ms >= 0:
		parts.append("Time: %.1fms" % time_ms)

	if parts.is_empty():
		metrics_label.text = ""
	else:
		metrics_label.text = " | ".join(parts)

## Called when code execution starts
func on_execution_started() -> void:
	if performance_metrics:
		performance_metrics.reset()
		performance_metrics.lines_of_code = _count_lines_of_code()
	update_metrics(0, _count_lines_of_code())

## Called when code execution ends
func on_execution_ended(success: bool = true) -> void:
	if performance_metrics:
		update_metrics(
			performance_metrics.execution_steps,
			performance_metrics.lines_of_code,
			performance_metrics.total_time_ms
		)
	# Print completion message to terminal
	if terminal_panel:
		terminal_panel.print_execution_completed(success)

## Count non-empty, non-comment lines
func _count_lines_of_code() -> int:
	var code = code_edit.text
	var lines = code.split("\n")
	var count = 0
	for line in lines:
		var stripped = line.strip_edges()
		if not stripped.is_empty() and not stripped.begins_with("#"):
			count += 1
	return count

## Gutter clicked (for breakpoints)
func _on_gutter_clicked(line: int, gutter: int) -> void:
	# Handle breakpoints - works with or without debugger
	if gutter != BREAKPOINT_GUTTER:
		return

	var is_active: bool

	if debugger:
		# Use debugger if available
		is_active = debugger.toggle_breakpoint(current_file, line)
	else:
		# Toggle local breakpoint
		if local_breakpoints.has(line):
			local_breakpoints.erase(line)
			is_active = false
		else:
			local_breakpoints[line] = true
			is_active = true

	if is_active:
		# Add breakpoint icon
		code_edit.set_line_gutter_icon(line, BREAKPOINT_GUTTER, _create_breakpoint_icon())
	else:
		# Remove breakpoint icon
		code_edit.set_line_gutter_icon(line, BREAKPOINT_GUTTER, null)

## Get all breakpoints
func get_breakpoints() -> Array:
	if debugger:
		return debugger.get_breakpoints(current_file)
	else:
		return local_breakpoints.keys()

## Check if a line has a breakpoint
func has_breakpoint(line: int) -> bool:
	if debugger:
		return debugger.has_breakpoint(current_file, line)
	else:
		return local_breakpoints.has(line)

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

func _on_execution_line_changed(file_or_line, line: int = -1) -> void:
	# Handle both (file, line) and (line) signatures
	if line == -1:
		# Called with just line number
		_highlight_execution_line(file_or_line as int)
	elif file_or_line == current_file:
		# Called with file and line
		_highlight_execution_line(line)

## Highlight the current execution line with smooth transition
func _highlight_execution_line(line: int) -> void:
	if not code_edit:
		return

	# Cancel any existing highlight tween
	if _highlight_tween and _highlight_tween.is_valid():
		_highlight_tween.kill()

	# Clear previous line highlight (fade out quickly)
	if _current_highlighted_line >= 0 and _current_highlighted_line < code_edit.get_line_count():
		code_edit.set_line_background_color(_current_highlighted_line, Color(0, 0, 0, 0))

	# Store new line
	_current_highlighted_line = line

	# Create smooth fade-in animation
	_highlight_tween = create_tween()
	_highlight_tween.set_ease(Tween.EASE_OUT)
	_highlight_tween.set_trans(Tween.TRANS_CUBIC)

	# Animate from transparent to highlight color over 150ms
	var start_color = Color(EXECUTION_LINE_COLOR.r, EXECUTION_LINE_COLOR.g, EXECUTION_LINE_COLOR.b, 0.0)
	var end_color = EXECUTION_LINE_COLOR

	# Set initial transparent color
	code_edit.set_line_background_color(line, start_color)

	# Animate the alpha
	_highlight_tween.tween_method(
		func(alpha: float):
			if code_edit and line < code_edit.get_line_count():
				var color = Color(EXECUTION_LINE_COLOR.r, EXECUTION_LINE_COLOR.g, EXECUTION_LINE_COLOR.b, alpha)
				code_edit.set_line_background_color(line, color),
		0.0,
		EXECUTION_LINE_COLOR.a,
		0.15  # 150ms transition
	)

## Clear execution line highlighting with smooth fade out
func _clear_execution_line() -> void:
	if not code_edit:
		return

	# Cancel any existing tween
	if _highlight_tween and _highlight_tween.is_valid():
		_highlight_tween.kill()

	# If there's a highlighted line, fade it out
	if _current_highlighted_line >= 0 and _current_highlighted_line < code_edit.get_line_count():
		var line = _current_highlighted_line
		var current_color = code_edit.get_line_background_color(line)

		if current_color.a > 0:
			_highlight_tween = create_tween()
			_highlight_tween.set_ease(Tween.EASE_OUT)
			_highlight_tween.set_trans(Tween.TRANS_CUBIC)

			# Fade out over 100ms
			_highlight_tween.tween_method(
				func(alpha: float):
					if code_edit and line < code_edit.get_line_count():
						var color = Color(current_color.r, current_color.g, current_color.b, alpha)
						code_edit.set_line_background_color(line, color),
				current_color.a,
				0.0,
				0.1  # 100ms fade out
			)
			_highlight_tween.tween_callback(func():
				# Clear all line colors after fade completes
				if code_edit:
					for i in range(code_edit.get_line_count()):
						code_edit.set_line_background_color(i, Color(0, 0, 0, 0))
			)
		else:
			# Already transparent, just clear
			for i in range(code_edit.get_line_count()):
				code_edit.set_line_background_color(i, Color(0, 0, 0, 0))

	_current_highlighted_line = -1

## Terminal error clicked - navigate to line
func _on_terminal_error_clicked(line: int) -> void:
	if code_edit:
		code_edit.set_caret_line(line - 1)  # Convert 1-indexed to 0-indexed
		code_edit.set_caret_column(0)
		code_edit.center_viewport_to_caret()
		# Highlight the error line briefly
		_highlight_execution_line(line - 1)

## Terminal API - Print message to terminal
func terminal_print(message: String) -> void:
	if terminal_panel:
		terminal_panel.print_output(message)

## Terminal API - Print info message
func terminal_info(message: String) -> void:
	if terminal_panel:
		terminal_panel.print_info(message)

## Terminal API - Print debug message
func terminal_debug(message: String) -> void:
	if terminal_panel:
		terminal_panel.print_debug(message)

## Terminal API - Print warning message
func terminal_warning(message: String) -> void:
	if terminal_panel:
		terminal_panel.print_warning(message)

## Terminal API - Print error message with optional line number
func terminal_error(message: String, line_number: int = -1) -> void:
	if terminal_panel:
		terminal_panel.print_error(message, line_number)

## Terminal API - Print success message
func terminal_success(message: String) -> void:
	if terminal_panel:
		terminal_panel.print_success(message)

## Terminal API - Clear terminal
func terminal_clear() -> void:
	if terminal_panel:
		terminal_panel.clear()

## Terminal API - Mark execution as complete
func terminal_execution_complete(success: bool = true) -> void:
	if terminal_panel:
		terminal_panel.print_execution_completed(success)

## Get terminal panel reference
func get_terminal_panel() -> Variant:
	return terminal_panel

## Handle print output from Python code
func _on_print_output(message: String) -> void:
	terminal_print(message)

## Handle execution errors from simulation
func _on_execution_error(error: String, line: int) -> void:
	# Show detailed error in terminal
	terminal_error(error, line)

	# Also show the code line that caused the error (if available)
	if code_edit and line > 0 and line <= code_edit.get_line_count():
		var error_line = code_edit.get_line(line - 1).strip_edges()  # Convert to 0-indexed
		if not error_line.is_empty():
			if terminal_panel:
				terminal_panel.print_debug("    → " + error_line)

	# Print execution failed message
	if terminal_panel:
		terminal_panel.print_execution_completed(false)
