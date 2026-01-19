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
var fold_manager: Variant = null
var error_highlighter: Variant = null
var execution_tracer: Variant = null
var performance_metrics: Variant = null

## Hover tooltip
var hover_tooltip: PanelContainer = null
var hover_timer: Timer = null
var last_hover_word: String = ""

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
	code_edit.gutters_draw_fold_gutter = true  # Enable code folding arrows
	code_edit.wrap_mode = TextEdit.LINE_WRAPPING_NONE

	# Enable indent-based code folding (required for Python-style folding)
	code_edit.indent_automatic = true
	code_edit.indent_size = 4
	code_edit.indent_use_spaces = true

	# Enable folding via delimiters and indentation
	code_edit.add_comment_delimiter("#", "", true)  # Single line comment
	code_edit.add_string_delimiter("\"", "\"", false)
	code_edit.add_string_delimiter("'", "'", false)
	code_edit.add_string_delimiter("\"\"\"", "\"\"\"", false)  # Multi-line strings can fold
	code_edit.add_string_delimiter("'''", "'''", false)

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

	# Setup Fold Manager
	var FoldManagerClass = load("res://scripts/core/fold_manager.gd")
	fold_manager = FoldManagerClass.new(code_edit)
	print("CodeEditorWindow: Fold manager initialized")

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

	# Setup hover tooltip
	_setup_hover_tooltip(content)

	# Connect signals
	run_button.pressed.connect(_on_run_pressed)
	pause_button.pressed.connect(_on_pause_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	file_explorer.file_selected.connect(_on_file_selected)
	code_edit.text_changed.connect(_on_text_changed)
	code_edit.caret_changed.connect(_update_status_bar)
	code_edit.gutter_clicked.connect(_on_gutter_clicked)
	code_edit.mouse_exited.connect(_on_code_edit_mouse_exited)

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

	# Update code folding regions
	if fold_manager:
		fold_manager.analyze_folds(code_edit.text)

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

	# Print to terminal
	if terminal_panel:
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

## Gutter clicked (for breakpoints and folding)
func _on_gutter_clicked(line: int, gutter: int) -> void:
	# Handle code folding (gutter 0 is the folding gutter)
	if gutter == 0 and fold_manager:
		fold_manager.toggle_fold(line)
		return

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

## Setup hover tooltip UI
func _setup_hover_tooltip(parent: Control) -> void:
	# Create tooltip panel
	hover_tooltip = PanelContainer.new()
	hover_tooltip.name = "HoverTooltip"
	hover_tooltip.visible = false
	hover_tooltip.z_index = 150
	hover_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.add_theme_constant_override("separation", 4)
	hover_tooltip.add_child(vbox)

	var signature_label = Label.new()
	signature_label.name = "SignatureLabel"
	signature_label.add_theme_color_override("font_color", Color(0.6, 0.9, 0.6))
	vbox.add_child(signature_label)

	var doc_label = Label.new()
	doc_label.name = "DocLabel"
	doc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	doc_label.custom_minimum_size = Vector2(200, 0)
	doc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(doc_label)

	parent.add_child(hover_tooltip)

	# Create hover timer
	hover_timer = Timer.new()
	hover_timer.one_shot = true
	hover_timer.wait_time = 0.5  # 500ms delay before showing tooltip
	hover_timer.timeout.connect(_on_hover_timer_timeout)
	add_child(hover_timer)

	print("CodeEditorWindow: Hover tooltip initialized")

## Process mouse motion for hover tooltips
func _process(_delta: float) -> void:
	if not visible or not code_edit:
		return

	# Check if mouse is over code_edit
	var mouse_pos = code_edit.get_local_mouse_position()
	if not code_edit.get_rect().has_point(mouse_pos + code_edit.position):
		return

	# Get the word under the mouse cursor
	var line_col = _get_line_col_at_pos(mouse_pos)
	if line_col.x < 0 or line_col.y < 0:
		return

	var word = _get_word_at_position(line_col.x, line_col.y)

	if word != last_hover_word:
		last_hover_word = word
		if hover_tooltip:
			hover_tooltip.visible = false
		if word != "" and hover_timer:
			hover_timer.start()

## Get line and column from mouse position
func _get_line_col_at_pos(pos: Vector2) -> Vector2i:
	if not code_edit:
		return Vector2i(-1, -1)

	# Calculate line from Y position using line height
	var line_height = code_edit.get_line_height()
	var scroll_offset = code_edit.get_v_scroll()
	var line = int((pos.y / line_height) + scroll_offset)

	if line < 0 or line >= code_edit.get_line_count():
		return Vector2i(-1, -1)

	# Estimate column based on X position
	var line_text = code_edit.get_line(line)
	var font = code_edit.get_theme_font("font")
	var font_size = code_edit.get_theme_font_size("font_size")
	var char_width = 8.0  # Default fallback
	if font and font_size > 0:
		char_width = font.get_char_size(ord("m"), font_size).x
	if char_width <= 0:
		char_width = 8.0
	var col = int(pos.x / char_width)
	col = clamp(col, 0, line_text.length())

	return Vector2i(line, col)

## Get word at specific line and column
func _get_word_at_position(line: int, col: int) -> String:
	if not code_edit:
		return ""

	var line_text = code_edit.get_line(line)
	if col >= line_text.length():
		return ""

	# Find word boundaries
	var start = col
	var end = col

	# Move start backwards
	while start > 0 and (line_text[start - 1].is_valid_identifier() or line_text[start - 1] == "_"):
		start -= 1

	# Move end forwards
	while end < line_text.length() and (line_text[end].is_valid_identifier() or line_text[end] == "_"):
		end += 1

	if start == end:
		return ""

	return line_text.substr(start, end - start)

## Timer timeout - show tooltip if word has documentation
func _on_hover_timer_timeout() -> void:
	if last_hover_word == "":
		return

	# Look up the word in GameCommands
	var GameCommandsClass = load("res://scripts/ui/game_commands.gd")
	var cmd = GameCommandsClass.find_by_name(last_hover_word)

	if cmd.is_empty():
		# Check if it's an object
		if last_hover_word in ["car", "stoplight", "boat"]:
			cmd = {
				"signature": last_hover_word,
				"doc": "Game object - type '.' to see available methods"
			}
		else:
			return

	_show_hover_tooltip(cmd)

## Show the hover tooltip
func _show_hover_tooltip(cmd: Dictionary) -> void:
	if not hover_tooltip or not code_edit:
		return

	var signature_label = hover_tooltip.get_node_or_null("VBoxContainer/SignatureLabel")
	var doc_label = hover_tooltip.get_node_or_null("VBoxContainer/DocLabel")

	if signature_label:
		signature_label.text = cmd.get("signature", "")
	if doc_label:
		doc_label.text = cmd.get("doc", "")

	# Position tooltip near mouse
	var mouse_pos = code_edit.get_local_mouse_position()
	var global_mouse = code_edit.global_position + mouse_pos
	var tooltip_pos = global_mouse
	tooltip_pos.y -= hover_tooltip.size.y + 10  # Above the mouse

	# Keep on screen
	var viewport = get_viewport()
	if viewport:
		var screen_size = viewport.get_visible_rect().size
		if tooltip_pos.x + hover_tooltip.size.x > screen_size.x:
			tooltip_pos.x = screen_size.x - hover_tooltip.size.x
		if tooltip_pos.y < 0:
			tooltip_pos.y = global_mouse.y + 20  # Below instead

	hover_tooltip.global_position = tooltip_pos
	hover_tooltip.visible = true

## Mouse exited code edit
func _on_code_edit_mouse_exited() -> void:
	if hover_tooltip:
		hover_tooltip.visible = false
	if hover_timer:
		hover_timer.stop()
	last_hover_word = ""

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
