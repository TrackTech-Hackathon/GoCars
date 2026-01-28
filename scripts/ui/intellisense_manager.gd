## IntelliSense Manager for GoCars Code Editor
## Coordinates autocomplete, signature help, auto-pairing, and indentation
## Author: Claude Code
## Date: January 2026

class_name IntelliSenseManager
extends Node

# Static class references
static var _GameCommandsClass = preload("res://scripts/ui/game_commands.gd")
static var _EditorConfigClass = preload("res://scripts/ui/editor_config.gd")

var code_edit: CodeEdit
var auto_pair_handler: Variant
var indent_handler: Variant

var user_symbols: Dictionary = {}  # filename -> Array of symbols
var current_file: String = ""

# Popup references
var autocomplete_popup: Variant

# Trigger tracking
var last_typed_char: String = ""
var typing_word: bool = false

func _init(editor: CodeEdit) -> void:
	code_edit = editor
	var AutoPairClass = load("res://scripts/ui/auto_pair_handler.gd")
	auto_pair_handler = AutoPairClass.new(editor)
	var IndentClass = load("res://scripts/ui/indent_handler.gd")
	indent_handler = IndentClass.new(editor)

func setup_popups(parent: Control) -> void:
	# Create autocomplete popup
	var AutocompleteClass = load("res://scripts/ui/autocomplete_popup.gd")
	autocomplete_popup = AutocompleteClass.new()
	autocomplete_popup.name = "AutocompletePopup"
	parent.add_child(autocomplete_popup)
	autocomplete_popup.suggestion_selected.connect(_on_suggestion_selected)

func handle_input(event: InputEvent) -> bool:
	if event is InputEventKey and event.pressed:
		# Tab handling - also completes autocomplete if visible
		if event.keycode == KEY_TAB:
			# Check if autocomplete is open - Tab completes it like VSCode
			if autocomplete_popup and autocomplete_popup.visible and not event.shift_pressed:
				autocomplete_popup.confirm_selection()
				if code_edit:
					code_edit.get_viewport().set_input_as_handled()
				return true
			if code_edit:
				code_edit.get_viewport().set_input_as_handled()
			return indent_handler.handle_tab(event.shift_pressed)

		# Enter handling
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			# Check if autocomplete is open
			if autocomplete_popup and autocomplete_popup.visible:
				autocomplete_popup.confirm_selection()
				if code_edit:
					code_edit.get_viewport().set_input_as_handled()
				return true
			else:
				var handled = indent_handler.handle_enter()
				if handled and code_edit:
					code_edit.get_viewport().set_input_as_handled()
				return handled

		# Ctrl+Space - manual trigger
		if event.keycode == KEY_SPACE and event.ctrl_pressed:
			_trigger_suggestions()
			if code_edit:
				code_edit.get_viewport().set_input_as_handled()
			return true

		# Escape - hide popups
		if event.keycode == KEY_ESCAPE:
			var was_visible = false
			if autocomplete_popup and autocomplete_popup.visible:
				autocomplete_popup.visible = false
				was_visible = true
			if was_visible and code_edit:
				code_edit.get_viewport().set_input_as_handled()
			return was_visible

		# Navigation when popup is visible
		if autocomplete_popup and autocomplete_popup.visible:
			if event.keycode == KEY_UP:
				autocomplete_popup.select_previous()
				if code_edit:
					code_edit.get_viewport().set_input_as_handled()
				return true
			if event.keycode == KEY_DOWN:
				autocomplete_popup.select_next()
				if code_edit:
					code_edit.get_viewport().set_input_as_handled()
				return true

		# Auto-pairing
		if auto_pair_handler.handle_input(event):
			if code_edit:
				code_edit.get_viewport().set_input_as_handled()
			# After inserting pair, trigger signature help if it was '('
			if char(event.unicode) == "(":
				# Defer to next frame to let text update
				if code_edit and code_edit.get_tree():
					code_edit.get_tree().process_frame.connect(_deferred_text_changed, CONNECT_ONE_SHOT)
			return true

	return false

func _deferred_text_changed() -> void:
	# Called after one frame to update IntelliSense
	on_text_changed()

func on_text_changed() -> void:
	# Called when CodeEdit text changes
	if not code_edit:
		return

	var caret_col = code_edit.get_caret_column()
	var caret_line = code_edit.get_caret_line()

	if caret_line >= code_edit.get_line_count():
		return

	var line_text = code_edit.get_line(caret_line)

	# IMPORTANT: Don't show suggestions if cursor is inside a string or comment
	if _is_inside_string_or_comment(line_text, caret_col):
		if autocomplete_popup:
			autocomplete_popup.visible = false
		return

	# Check for dot trigger (car. stoplight. boat.)
	if caret_col > 0 and line_text.substr(caret_col - 1, 1) == ".":
		# Get the object before the dot
		var obj_end = caret_col - 1
		var obj_start = _find_word_start(line_text, obj_end)
		var obj_name = line_text.substr(obj_start, obj_end - obj_start)

		if obj_name in ["car", "stoplight", "boat"]:
			_show_object_methods(obj_name)
			return

	# Get the word being typed
	var word_start = _find_word_start(line_text, caret_col)
	var current_word = line_text.substr(word_start, caret_col - word_start)

	# Check if there's a dot before the word (car.go typing "g")
	if word_start > 1 and line_text.substr(word_start - 1, 1) == ".":
		var obj_end = word_start - 1
		var obj_start = _find_word_start(line_text, obj_end)
		var obj_name = line_text.substr(obj_start, obj_end - obj_start)

		if obj_name in ["car", "stoplight", "boat"]:
			_show_object_methods(obj_name, current_word)
			return

	# Show suggestions if typing
	if current_word.length() >= _EditorConfigClass.autocomplete_trigger_length:
		_show_suggestions_for(current_word)
	elif current_word.length() == 0:
		# Hide popup when no word is being typed
		if autocomplete_popup:
			autocomplete_popup.visible = false
	else:
		# Update filter if already showing, or hide if too short
		if autocomplete_popup and autocomplete_popup.visible:
			autocomplete_popup.update_filter(current_word)
		else:
			# Hide if popup is visible but word is too short
			if autocomplete_popup:
				autocomplete_popup.visible = false

func _trigger_suggestions() -> void:
	if not code_edit:
		return

	var caret_col = code_edit.get_caret_column()
	var caret_line = code_edit.get_caret_line()

	if caret_line >= code_edit.get_line_count():
		return

	var line_text = code_edit.get_line(caret_line)

	var word_start = _find_word_start(line_text, caret_col)
	var current_word = line_text.substr(word_start, caret_col - word_start)

	_show_suggestions_for(current_word if current_word.length() > 0 else "")

func _show_object_methods(obj_name: String, prefix: String = "") -> void:
	var suggestions: Array = []

	# Get methods for this object
	suggestions.append_array(_GameCommandsClass.get_methods_for_object(obj_name, prefix))

	if suggestions.is_empty():
		if autocomplete_popup:
			autocomplete_popup.hide()
		return

	# Get caret screen position (VSCode style - position UNDER current line)
	var caret_draw = code_edit.get_caret_draw_pos()
	var line_height = code_edit.get_line_height()

	# Position is caret X, but Y is moved down by one line height
	var local_pos = Vector2(caret_draw.x, caret_draw.y + line_height)
	var global_pos = code_edit.get_global_transform() * local_pos

	autocomplete_popup.show_suggestions(suggestions, prefix, global_pos)

func _show_suggestions_for(prefix: String) -> void:
	var suggestions: Array = []

	# Get game commands
	suggestions.append_array(_GameCommandsClass.get_by_prefix(prefix))

	# Get user-defined symbols
	for symbol in user_symbols.get(current_file, []):
		if symbol.name.to_lower().begins_with(prefix.to_lower()):
			suggestions.append(symbol)

	if suggestions.is_empty():
		if autocomplete_popup:
			autocomplete_popup.hide()
		return

	# Get caret screen position (VSCode style - position UNDER current line)
	var caret_draw = code_edit.get_caret_draw_pos()
	var line_height = code_edit.get_line_height()

	# Position is caret X, but Y is moved down by one line height
	var local_pos = Vector2(caret_draw.x, caret_draw.y + line_height)
	var global_pos = code_edit.get_global_transform() * local_pos

	autocomplete_popup.show_suggestions(suggestions, prefix, global_pos)

func _find_word_start(line: String, col: int) -> int:
	var start = col
	while start > 0:
		var c = line[start - 1]
		if not (c.is_valid_identifier() or c == "_"):
			break
		start -= 1
	return start


## Check if cursor is inside a string literal or comment
## This prevents intellisense from showing suggestions when typing string arguments
func _is_inside_string_or_comment(line_text: String, col: int) -> bool:
	var single_quotes = 0
	var double_quotes = 0
	var in_comment = false
	var i = 0

	while i < min(col, line_text.length()):
		var c = line_text[i]

		# Check for comment (but only if not inside a string)
		if c == "#" and single_quotes % 2 == 0 and double_quotes % 2 == 0:
			in_comment = true
			break

		# Track quotes (skip escaped quotes)
		if c == "\\" and i + 1 < line_text.length():
			i += 2  # Skip escaped character
			continue
		elif c == "'" and double_quotes % 2 == 0:
			single_quotes += 1
		elif c == '"' and single_quotes % 2 == 0:
			double_quotes += 1

		i += 1

	# If odd number of quotes, we're inside a string
	return in_comment or (single_quotes % 2 == 1) or (double_quotes % 2 == 1)

func _on_suggestion_selected(text: String) -> void:
	# Replace the current word with the selected suggestion
	var caret_col = code_edit.get_caret_column()
	var caret_line = code_edit.get_caret_line()

	if caret_line >= code_edit.get_line_count():
		return

	var line_text = code_edit.get_line(caret_line)

	var word_start = _find_word_start(line_text, caret_col)

	code_edit.select(caret_line, word_start, caret_line, caret_col)
	code_edit.insert_text_at_caret(text)

	# If function with (), position cursor inside
	if text.ends_with("()"):
		var new_col = code_edit.get_caret_column()
		code_edit.set_caret_column(new_col - 1)

		# Trigger signature help (use code_edit's tree since we're not in scene tree)
		if code_edit and code_edit.get_tree():
			await code_edit.get_tree().process_frame
			on_text_changed()

func parse_file_symbols(filename: String, content: String) -> void:
	# Parse file for variable and function definitions
	var symbols: Array = []
	var lines = content.split("\n")

	for i in range(lines.size()):
		var line = lines[i].strip_edges()

		# Function definition
		if line.begins_with("def "):
			var match_result = _parse_function_def(line)
			if not match_result.is_empty():
				match_result["line"] = i
				symbols.append(match_result)

		# Variable assignment (simple detection)
		elif "=" in line and not line.begins_with("#"):
			var parts = line.split("=")
			if parts.size() >= 2:
				var var_name = parts[0].strip_edges()
				if var_name.is_valid_identifier():
					symbols.append({
						"name": var_name,
						"type": "variable",
						"signature": var_name,
						"doc": "User variable",
						"line": i
					})

	user_symbols[filename] = symbols
	current_file = filename

func _parse_function_def(line: String) -> Dictionary:
	# Parse "def function_name(params):"
	var regex = RegEx.new()
	regex.compile("def\\s+(\\w+)\\s*\\(([^)]*)\\)")
	var result = regex.search(line)

	if result:
		var func_name = result.get_string(1)
		var params = result.get_string(2)
		return {
			"name": func_name,
			"type": "function",
			"signature": "def %s(%s)" % [func_name, params],
			"doc": "User-defined function"
		}

	return {}

func set_current_file(filename: String) -> void:
	current_file = filename
