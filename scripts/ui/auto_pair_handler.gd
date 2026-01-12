## Auto-Pairing Handler for GoCars Code Editor
## Automatically inserts closing brackets, quotes, etc.
## Author: Claude Code
## Date: January 2026

class_name AutoPairHandler

# Static class reference
static var _EditorConfigClass = preload("res://scripts/ui/editor_config.gd")

const PAIRS = {
	"(": ")",
	"[": "]",
	"{": "}",
	"'": "'",
	'"': '"',
}

var code_edit: CodeEdit

func _init(editor: CodeEdit) -> void:
	code_edit = editor

func handle_input(event: InputEventKey) -> bool:
	if not event.pressed or event.echo:
		return false

	if not _EditorConfigClass.enable_auto_pairing:
		return false

	var char_typed = char(event.unicode)
	var caret_col = code_edit.get_caret_column()
	var caret_line = code_edit.get_caret_line()
	var line_text = code_edit.get_line(caret_line)

	# Check if we should auto-pair
	if char_typed in PAIRS:
		return _handle_open_pair(char_typed, caret_col, caret_line, line_text)

	# Check if typing closing char that already exists
	if char_typed in PAIRS.values():
		return _handle_close_pair(char_typed, caret_col, line_text)

	# Handle backspace on empty pair
	if event.keycode == KEY_BACKSPACE:
		return _handle_backspace(caret_col, caret_line, line_text)

	return false

func _handle_open_pair(open_char: String, col: int, line: int, line_text: String) -> bool:
	var close_char = PAIRS[open_char]

	# Don't pair brackets if disabled
	if open_char in ["(", "[", "{"] and not _EditorConfigClass.auto_pair_brackets:
		return false

	# Don't pair quotes if disabled
	if open_char in ["'", '"'] and not _EditorConfigClass.auto_pair_quotes:
		return false

	# Don't pair if inside string/comment (simplified check)
	if _is_inside_string_or_comment(line_text, col):
		return false

	# Don't pair if next char is alphanumeric
	if col < line_text.length():
		var next_char = line_text[col]
		if next_char.is_valid_identifier() or next_char.is_valid_int():
			return false

	# Check for selected text - wrap it
	if code_edit.has_selection():
		var selected = code_edit.get_selected_text()
		code_edit.insert_text_at_caret(open_char + selected + close_char)
		# Position cursor after closing char
		var new_col = code_edit.get_caret_column()
		code_edit.set_caret_column(new_col - 1)
		return true

	# Insert pair and position cursor between
	code_edit.insert_text_at_caret(open_char + close_char)
	code_edit.set_caret_column(col + 1)
	return true

func _handle_close_pair(close_char: String, col: int, line_text: String) -> bool:
	# If next char is the same closing char, skip instead of inserting
	if col < line_text.length() and line_text[col] == close_char:
		code_edit.set_caret_column(col + 1)
		return true
	return false

func _handle_backspace(col: int, line: int, line_text: String) -> bool:
	if col == 0 or col >= line_text.length():
		return false

	var prev_char = line_text[col - 1]
	var next_char = line_text[col]

	# Check if we're between a pair
	if prev_char in PAIRS and PAIRS[prev_char] == next_char:
		# Delete both characters
		code_edit.select(line, col - 1, line, col + 1)
		code_edit.insert_text_at_caret("")
		return true

	return false

func _is_inside_string_or_comment(line_text: String, col: int) -> bool:
	# Simplified check: count quotes before cursor
	var single_quotes = 0
	var double_quotes = 0
	var in_comment = false

	for i in range(min(col, line_text.length())):
		var c = line_text[i]
		if c == "#" and single_quotes % 2 == 0 and double_quotes % 2 == 0:
			in_comment = true
			break
		elif c == "'":
			single_quotes += 1
		elif c == '"':
			double_quotes += 1

	# If odd number of quotes, we're inside a string
	return in_comment or (single_quotes % 2 == 1) or (double_quotes % 2 == 1)
