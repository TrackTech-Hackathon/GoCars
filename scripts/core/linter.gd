# linter.gd
class_name Linter
extends RefCounted

signal diagnostics_updated(diagnostics: Array)

class Diagnostic:
	var line: int
	var column_start: int
	var column_end: int
	var severity: LinterRules.Severity
	var code: String
	var message: String
	var suggestions: Array[String] = []

	func _init(l: int, cs: int, ce: int, sev: LinterRules.Severity, c: String, msg: String) -> void:
		line = l
		column_start = cs
		column_end = ce
		severity = sev
		code = c
		message = msg

var diagnostics: Array[Diagnostic] = []
var defined_variables: Dictionary = {}  # name -> line defined
var used_variables: Dictionary = {}     # name -> Array of lines used
var defined_functions: Dictionary = {}  # name -> line defined

# Debounce timer for performance
var lint_timer: Timer
var pending_content: String = ""

func _init() -> void:
	lint_timer = Timer.new()
	lint_timer.one_shot = true
	lint_timer.wait_time = 0.3  # 300ms debounce
	lint_timer.timeout.connect(_do_lint)

func get_timer() -> Timer:
	return lint_timer

func lint(content: String) -> void:
	pending_content = content
	lint_timer.start()

func _do_lint() -> void:
	diagnostics.clear()
	defined_variables.clear()
	used_variables.clear()
	defined_functions.clear()

	var lines = pending_content.split("\n")

	# First pass: collect definitions
	_collect_definitions(lines)

	# Second pass: check for errors
	for i in range(lines.size()):
		var line = lines[i]
		_check_line(line, i, lines)

	# Third pass: check for unused variables
	_check_unused()

	diagnostics_updated.emit(diagnostics)

func _collect_definitions(lines: Array) -> void:
	for i in range(lines.size()):
		var line = lines[i]
		var stripped = line.strip_edges()

		# Function definitions
		if stripped.begins_with("def "):
			var func_name = _extract_function_name(stripped)
			if func_name != "":
				defined_functions[func_name] = i

		# Variable assignments
		if "=" in stripped and not stripped.begins_with("#"):
			var parts = stripped.split("=")
			if parts.size() >= 2:
				var var_name = parts[0].strip_edges()
				# Skip comparison operators
				if not var_name.ends_with("!") and not var_name.ends_with("<") and not var_name.ends_with(">"):
					if var_name.is_valid_identifier():
						defined_variables[var_name] = i

func _check_line(line: String, line_num: int, all_lines: Array) -> void:
	var stripped = line.strip_edges()

	# Skip empty lines and comments
	if stripped.is_empty() or stripped.begins_with("#"):
		return

	# Check bracket balance
	_check_brackets(line, line_num)

	# Check string balance
	_check_strings(line, line_num)

	# Check for missing colons
	_check_missing_colon(stripped, line_num)

	# Check indentation
	_check_indentation(line, line_num, all_lines)

	# Check undefined names
	_check_undefined_names(line, line_num)

	# Track variable usage
	_track_usage(line, line_num)

func _check_brackets(line: String, line_num: int) -> void:
	var stack: Array[Dictionary] = []  # {char, column}
	var in_string = false
	var string_char = ""

	for i in range(line.length()):
		var c = line[i]

		# Track string state
		if c in ["'", '"'] and (i == 0 or line[i-1] != "\\"):
			if not in_string:
				in_string = true
				string_char = c
			elif c == string_char:
				in_string = false

		if in_string:
			continue

		# Track brackets
		if c in ["(", "[", "{"]:
			stack.append({"char": c, "column": i})
		elif c in [")", "]", "}"]:
			var expected = {"(": ")", "[": "]", "{": "}"}
			if stack.is_empty():
				diagnostics.append(Diagnostic.new(
					line_num, i, i + 1,
					LinterRules.Severity.ERROR,
					"E001",
					"Unmatched closing bracket '%s'" % c
				))
			else:
				var last = stack.pop_back()
				if expected[last.char] != c:
					diagnostics.append(Diagnostic.new(
						line_num, i, i + 1,
						LinterRules.Severity.ERROR,
						"E001",
						"Mismatched bracket: expected '%s' but found '%s'" % [expected[last.char], c]
					))

	# Check for unclosed brackets at end of line
	for bracket in stack:
		diagnostics.append(Diagnostic.new(
			line_num, bracket.column, bracket.column + 1,
			LinterRules.Severity.ERROR,
			"E001",
			"Unclosed bracket '%s'" % bracket.char
		))

func _check_strings(line: String, line_num: int) -> void:
	var in_string = false
	var string_char = ""
	var string_start = 0

	var i = 0
	while i < line.length():
		var c = line[i]

		# Check for triple quotes
		if i + 2 < line.length():
			var triple = line.substr(i, 3)
			if triple in ['"""', "'''"]:
				if not in_string:
					in_string = true
					string_char = triple
					string_start = i
					i += 3
					continue
				elif string_char == triple:
					in_string = false
					i += 3
					continue

		# Single/double quotes
		if c in ["'", '"'] and (i == 0 or line[i-1] != "\\"):
			if not in_string:
				in_string = true
				string_char = c
				string_start = i
			elif c == string_char:
				in_string = false

		i += 1

	# Check for unclosed string (only for single-line strings)
	if in_string and string_char.length() == 1:
		diagnostics.append(Diagnostic.new(
			line_num, string_start, line.length(),
			LinterRules.Severity.ERROR,
			"E002",
			"Unclosed string literal"
		))

func _check_missing_colon(stripped: String, line_num: int) -> void:
	var block_starters = ["if ", "elif ", "else", "while ", "for ", "def ", "class ", "try", "except", "finally", "with "]

	for starter in block_starters:
		if stripped.begins_with(starter) or stripped == starter.strip_edges():
			if not stripped.ends_with(":"):
				# Check if it's a multi-line statement (ends with \)
				if not stripped.ends_with("\\"):
					diagnostics.append(Diagnostic.new(
						line_num, stripped.length(), stripped.length() + 1,
						LinterRules.Severity.ERROR,
						"E005",
						"Expected ':' after '%s' statement" % starter.strip_edges()
					))
			break

func _check_indentation(line: String, line_num: int, all_lines: Array) -> void:
	if line.strip_edges().is_empty():
		return

	var indent = 0
	for c in line:
		if c == " ":
			indent += 1
		elif c == "\t":
			indent += 4  # Treat tabs as 4 spaces
		else:
			break

	# Check for inconsistent indentation (not multiple of 4)
	if indent % 4 != 0:
		diagnostics.append(Diagnostic.new(
			line_num, 0, indent,
			LinterRules.Severity.WARNING,
			"E004",
			"Indentation is not a multiple of 4 spaces"
		))

func _check_undefined_names(line: String, line_num: int) -> void:
	# Extract identifiers from line (already skips strings and comments)
	var identifiers = _extract_identifiers(line)

	for id_info in identifiers:
		var name = id_info.name
		var col = id_info.column

		# Skip if it's a keyword, known function, or defined variable/function
		if name in LinterRules.python_keywords:
			continue
		if name in LinterRules.known_functions:
			continue
		if name in defined_variables:
			continue
		if name in defined_functions:
			continue
		# Skip common object names
		if name in ["car", "stoplight", "boat"]:
			continue
		# Skip known string constants (extra safeguard)
		if name in LinterRules.known_string_constants:
			continue

		# Check for similar names (typo detection)
		var suggestion = _find_similar_name(name)
		var msg = "Undefined name '%s'" % name
		if suggestion != "":
			msg += ". Did you mean '%s'?" % suggestion

		diagnostics.append(Diagnostic.new(
			line_num, col, col + name.length(),
			LinterRules.Severity.ERROR,
			"E101",
			msg
		))

		if suggestion != "":
			diagnostics[diagnostics.size() - 1].suggestions.append(suggestion)

func _track_usage(line: String, line_num: int) -> void:
	var identifiers = _extract_identifiers(line)

	for id_info in identifiers:
		var name = id_info.name
		if name in defined_variables:
			if not used_variables.has(name):
				used_variables[name] = []
			used_variables[name].append(line_num)

func _check_unused() -> void:
	for var_name in defined_variables:
		if not used_variables.has(var_name):
			var def_line = defined_variables[var_name]
			diagnostics.append(Diagnostic.new(
				def_line, 0, var_name.length(),
				LinterRules.Severity.WARNING,
				"W001",
				"Variable '%s' is assigned but never used" % var_name
			))

func _extract_identifiers(line: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	# First, mark string and comment regions so we can skip identifiers inside them
	var skip_regions: Array[Vector2i] = _get_string_and_comment_regions(line)

	var regex = RegEx.new()
	regex.compile("\\b([a-zA-Z_][a-zA-Z0-9_]*)\\b")

	for match_result in regex.search_all(line):
		var col = match_result.get_start(1)

		# Skip if this identifier is inside a string or comment
		var should_skip = false
		for region in skip_regions:
			if col >= region.x and col < region.y:
				should_skip = true
				break

		if not should_skip:
			result.append({
				"name": match_result.get_string(1),
				"column": col
			})

	return result


## Get regions of the line that are inside strings or comments (returns array of Vector2i with start/end)
func _get_string_and_comment_regions(line: String) -> Array[Vector2i]:
	var regions: Array[Vector2i] = []
	var in_string = false
	var string_char = ""
	var string_start = 0

	var i = 0
	while i < line.length():
		var c = line[i]

		# Check for comment - everything after # is skipped (unless in a string)
		if c == "#" and not in_string:
			# Mark from comment start to end of line
			regions.append(Vector2i(i, line.length()))
			break

		# Check for triple quotes first
		if i + 2 < line.length() and not in_string:
			var triple = line.substr(i, 3)
			if triple == '"""' or triple == "'''":
				in_string = true
				string_char = triple
				string_start = i
				i += 3
				continue

		# Check for closing triple quotes
		if in_string and string_char.length() == 3 and i + 2 < line.length():
			var triple = line.substr(i, 3)
			if triple == string_char:
				regions.append(Vector2i(string_start, i + 3))
				in_string = false
				string_char = ""
				i += 3
				continue

		# Single/double quotes (skip escaped quotes)
		if c in ["'", '"']:
			# Check for escape
			if i > 0 and line[i-1] == "\\":
				i += 1
				continue

			if not in_string:
				in_string = true
				string_char = c
				string_start = i
			elif c == string_char and string_char.length() == 1:
				regions.append(Vector2i(string_start, i + 1))
				in_string = false
				string_char = ""

		i += 1

	# If still in string at end of line, mark to end
	if in_string:
		regions.append(Vector2i(string_start, line.length()))

	return regions

func _extract_function_name(line: String) -> String:
	var regex = RegEx.new()
	regex.compile(r"def\s+(\w+)")
	var result = regex.search(line)
	if result:
		return result.get_string(1)
	return ""

func _find_similar_name(name: String) -> String:
	var best_match = ""
	var best_distance = 3  # Max edit distance threshold

	var all_names: Array[String] = []
	all_names.append_array(LinterRules.known_functions)
	all_names.append_array(defined_variables.keys())
	all_names.append_array(defined_functions.keys())

	for candidate in all_names:
		var distance = _levenshtein_distance(name.to_lower(), candidate.to_lower())
		if distance < best_distance:
			best_distance = distance
			best_match = candidate

	return best_match

func _levenshtein_distance(s1: String, s2: String) -> int:
	var len1 = s1.length()
	var len2 = s2.length()

	var matrix: Array[Array] = []
	for i in range(len1 + 1):
		matrix.append([])
		for j in range(len2 + 1):
			matrix[i].append(0)

	for i in range(len1 + 1):
		matrix[i][0] = i
	for j in range(len2 + 1):
		matrix[0][j] = j

	for i in range(1, len1 + 1):
		for j in range(1, len2 + 1):
			var cost = 0 if s1[i-1] == s2[j-1] else 1
			matrix[i][j] = min(
				matrix[i-1][j] + 1,      # deletion
				min(
					matrix[i][j-1] + 1,  # insertion
					matrix[i-1][j-1] + cost  # substitution
				)
			)

	return matrix[len1][len2]

func get_diagnostics_for_line(line_num: int) -> Array:
	var result: Array = []
	for diag in diagnostics:
		if diag.line == line_num:
			result.append(diag)
	return result
