## Execution Highlighter for Line-by-Line Visualization
## Author: Claude Code
## Date: January 2026

class_name ExecutionHighlighter
extends Node

var code_edit: CodeEdit
var tracer: ExecutionTracer

var current_exec_line: int = -1
var breakpoint_lines: Array[int] = []

const EXEC_LINE_COLOR = Color(1.0, 0.8, 0.2, 0.3)  # Yellow highlight
const BREAKPOINT_COLOR = Color(1.0, 0.2, 0.2, 0.5)  # Red highlight
const EXECUTED_LINE_COLOR = Color(0.2, 0.8, 0.2, 0.1)  # Faint green

const GUTTER_BREAKPOINT = 3
const GUTTER_EXEC_ARROW = 4

var breakpoint_icon: Texture2D
var exec_arrow_icon: Texture2D

func _init(editor: CodeEdit, execution_tracer: ExecutionTracer) -> void:
	code_edit = editor
	tracer = execution_tracer

	tracer.line_executed.connect(_on_line_executed)
	tracer.execution_finished.connect(_on_execution_finished)

	_setup_gutters()

func _setup_gutters() -> void:
	# Breakpoint gutter
	code_edit.add_gutter(GUTTER_BREAKPOINT)
	code_edit.set_gutter_type(GUTTER_BREAKPOINT, CodeEdit.GUTTER_TYPE_ICON)
	code_edit.set_gutter_width(GUTTER_BREAKPOINT, 16)
	code_edit.set_gutter_clickable(GUTTER_BREAKPOINT, true)

	# Execution arrow gutter
	code_edit.add_gutter(GUTTER_EXEC_ARROW)
	code_edit.set_gutter_type(GUTTER_EXEC_ARROW, CodeEdit.GUTTER_TYPE_ICON)
	code_edit.set_gutter_width(GUTTER_EXEC_ARROW, 16)

	code_edit.gutter_clicked.connect(_on_gutter_clicked)

func _on_line_executed(line: int, _vars: Dictionary) -> void:
	# Clear previous highlight
	if current_exec_line >= 0:
		code_edit.set_line_background_color(current_exec_line, Color.TRANSPARENT)
		code_edit.set_line_gutter_icon(current_exec_line, GUTTER_EXEC_ARROW, null)

	# Set new highlight
	current_exec_line = line

	# Check if hit breakpoint
	if line in breakpoint_lines:
		code_edit.set_line_background_color(line, BREAKPOINT_COLOR)
		tracer.pause_execution()
	else:
		code_edit.set_line_background_color(line, EXEC_LINE_COLOR)

	# Show execution arrow
	code_edit.set_line_gutter_icon(line, GUTTER_EXEC_ARROW, exec_arrow_icon)

	# Scroll to visible
	_ensure_line_visible(line)

func _on_execution_finished() -> void:
	if current_exec_line >= 0:
		code_edit.set_line_background_color(current_exec_line, Color.TRANSPARENT)
		code_edit.set_line_gutter_icon(current_exec_line, GUTTER_EXEC_ARROW, null)
	current_exec_line = -1

func _on_gutter_clicked(line: int, gutter: int) -> void:
	if gutter == GUTTER_BREAKPOINT:
		toggle_breakpoint(line)

func toggle_breakpoint(line: int) -> void:
	if line in breakpoint_lines:
		breakpoint_lines.erase(line)
		code_edit.set_line_gutter_icon(line, GUTTER_BREAKPOINT, null)
		code_edit.set_line_background_color(line, Color.TRANSPARENT)
	else:
		breakpoint_lines.append(line)
		code_edit.set_line_gutter_icon(line, GUTTER_BREAKPOINT, breakpoint_icon)

func clear_all_breakpoints() -> void:
	for line in breakpoint_lines:
		code_edit.set_line_gutter_icon(line, GUTTER_BREAKPOINT, null)
	breakpoint_lines.clear()

func _ensure_line_visible(line: int) -> void:
	var visible_lines = code_edit.get_visible_line_count()
	var first_visible = code_edit.get_first_visible_line()

	if line < first_visible or line >= first_visible + visible_lines:
		code_edit.set_line_as_center_visible(line)
