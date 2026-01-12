## Indent Handler for GoCars Code Editor
## Handles Tab-to-Spaces conversion and smart auto-indentation
## Author: Claude Code
## Date: January 2026

class_name IndentHandler

# Static class reference
static var _EditorConfigClass = preload("res://scripts/ui/editor_config.gd")

const INDENT_TRIGGERS = [":", "{", "[", "("]
const DEDENT_KEYWORDS = ["return", "pass", "break", "continue", "raise"]
const BLOCK_KEYWORDS = ["if", "else", "elif", "while", "for", "def", "class", "try", "except", "finally", "with"]

var code_edit: CodeEdit
var indent_string: String

func _init(editor: CodeEdit) -> void:
	code_edit = editor
	_update_indent_string()

func _update_indent_string() -> void:
	if _EditorConfigClass.use_spaces:
		indent_string = " ".repeat(_EditorConfigClass.indent_size)
	else:
		indent_string = "\t"

func handle_tab(shift_pressed: bool) -> bool:
	_update_indent_string()

	if shift_pressed:
		_dedent_selection()
	else:
		if code_edit.has_selection():
			_indent_selection()
		else:
			code_edit.insert_text_at_caret(indent_string)
	return true

func handle_enter() -> bool:
	if not _EditorConfigClass.auto_indent:
		return false

	var caret_line = code_edit.get_caret_line()
	var line_text = code_edit.get_line(caret_line)
	var caret_col = code_edit.get_caret_column()

	# Get current line's indentation
	var current_indent = _get_line_indent(line_text)
	var line_before_cursor = line_text.substr(0, caret_col).strip_edges(false, true)

	# Check if we should increase indent
	var should_indent = false
	if line_before_cursor.ends_with(":"):
		should_indent = true

	# Check for empty pair - add extra newline
	var text_after_cursor = line_text.substr(caret_col)
	var has_closing_bracket = false
	if caret_col > 0 and caret_col < line_text.length():
		var prev_char = line_text[caret_col - 1]
		var next_char = line_text[caret_col]
		if (prev_char == "(" and next_char == ")") or \
		   (prev_char == "[" and next_char == "]") or \
		   (prev_char == "{" and next_char == "}"):
			has_closing_bracket = true

	# Insert newline with appropriate indent
	var new_indent = current_indent
	if should_indent:
		new_indent += indent_string

	if has_closing_bracket:
		# Insert two newlines with proper indentation
		code_edit.insert_text_at_caret("\n" + new_indent + "\n" + current_indent)
		# Move cursor to middle line
		code_edit.set_caret_line(caret_line + 1)
		code_edit.set_caret_column(new_indent.length())
	else:
		code_edit.insert_text_at_caret("\n" + new_indent)

	return true

func _get_line_indent(line: String) -> String:
	var indent = ""
	for c in line:
		if c == " " or c == "\t":
			indent += c
		else:
			break
	return indent

func _indent_selection() -> void:
	var from_line = code_edit.get_selection_from_line()
	var to_line = code_edit.get_selection_to_line()

	code_edit.begin_complex_operation()
	for i in range(from_line, to_line + 1):
		var line = code_edit.get_line(i)
		code_edit.set_line(i, indent_string + line)
	code_edit.end_complex_operation()

func _dedent_selection() -> void:
	var from_line: int
	var to_line: int

	if code_edit.has_selection():
		from_line = code_edit.get_selection_from_line()
		to_line = code_edit.get_selection_to_line()
	else:
		from_line = code_edit.get_caret_line()
		to_line = from_line

	code_edit.begin_complex_operation()
	for i in range(from_line, to_line + 1):
		var line = code_edit.get_line(i)
		if line.begins_with(indent_string):
			code_edit.set_line(i, line.substr(indent_string.length()))
		elif line.begins_with("\t"):
			code_edit.set_line(i, line.substr(1))
		elif line.begins_with(" "):
			# Remove up to indent_size spaces
			var spaces_to_remove = 0
			for j in range(min(_EditorConfigClass.indent_size, line.length())):
				if line[j] == " ":
					spaces_to_remove += 1
				else:
					break
			if spaces_to_remove > 0:
				code_edit.set_line(i, line.substr(spaces_to_remove))
	code_edit.end_complex_operation()
