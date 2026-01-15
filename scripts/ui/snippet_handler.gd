## Snippet Expansion Handler for GoCars Editor
## Author: Claude Code
## Date: January 2026

class_name SnippetHandler
extends RefCounted

signal snippet_expanded(snippet: Snippet)
signal tab_stop_changed(index: int, total: int)

var code_edit: CodeEdit
var active_snippet: Snippet = null
var active_tab_stops: Array[Dictionary] = []
var current_tab_index: int = 0
var snippet_start_line: int = 0
var snippet_start_col: int = 0

func _init(editor: CodeEdit) -> void:
	code_edit = editor

func try_expand(prefix: String) -> bool:
	var snippet = SnippetLibrary.get_exact(prefix)
	if snippet == null:
		return false

	expand_snippet(snippet, prefix.length())
	return true

func expand_snippet(snippet: Snippet, prefix_length: int) -> void:
	# Store starting position
	snippet_start_line = code_edit.get_caret_line()
	snippet_start_col = code_edit.get_caret_column() - prefix_length

	# Get current line indent
	var line = code_edit.get_line(snippet_start_line)
	var indent = ""
	for c in line:
		if c == " " or c == "\t":
			indent += c
		else:
			break

	# Delete the prefix
	code_edit.select(snippet_start_line, snippet_start_col, snippet_start_line, code_edit.get_caret_column())
	code_edit.delete_selection()

	# Insert expanded text
	var expanded = snippet.get_expanded_text(indent)
	code_edit.insert_text_at_caret(expanded)

	# Setup tab stops
	active_snippet = snippet
	_setup_tab_stops(snippet, indent)

	if active_tab_stops.size() > 0:
		current_tab_index = 0
		_select_tab_stop(0)
		snippet_expanded.emit(snippet)

func _setup_tab_stops(snippet: Snippet, base_indent: String) -> void:
	active_tab_stops.clear()

	# Calculate actual positions in the editor
	var line_offset = snippet_start_line

	for ts in snippet.tab_stops:
		var actual_line = line_offset + ts.line
		var actual_col = ts.column

		# Adjust column for indent on lines after first
		if ts.line > 0:
			actual_col += base_indent.length()
		else:
			actual_col += snippet_start_col

		active_tab_stops.append({
			"index": ts.index,
			"line": actual_line,
			"column": actual_col,
			"placeholder": ts.placeholder,
			"length": ts.placeholder.length()
		})

func _select_tab_stop(index: int) -> void:
	if index >= active_tab_stops.size():
		_finish_snippet()
		return

	var ts = active_tab_stops[index]

	# Select the placeholder text
	code_edit.set_caret_line(ts.line)
	code_edit.set_caret_column(ts.column)

	if ts.length > 0:
		code_edit.select(ts.line, ts.column, ts.line, ts.column + ts.length)

	tab_stop_changed.emit(index + 1, active_tab_stops.size())

func next_tab_stop() -> bool:
	if active_snippet == null:
		return false

	# Update current tab stop length based on selection/edit
	if current_tab_index < active_tab_stops.size():
		var ts = active_tab_stops[current_tab_index]
		var current_col = code_edit.get_caret_column()
		ts.length = current_col - ts.column

	current_tab_index += 1

	if current_tab_index >= active_tab_stops.size():
		_finish_snippet()
		return false

	_select_tab_stop(current_tab_index)
	return true

func prev_tab_stop() -> bool:
	if active_snippet == null or current_tab_index <= 0:
		return false

	current_tab_index -= 1
	_select_tab_stop(current_tab_index)
	return true

func _finish_snippet() -> void:
	active_snippet = null
	active_tab_stops.clear()
	current_tab_index = 0

func is_active() -> bool:
	return active_snippet != null

func cancel() -> void:
	_finish_snippet()
