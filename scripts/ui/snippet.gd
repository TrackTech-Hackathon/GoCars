## Code Snippet with Tab Stops for GoCars Editor
## Author: Claude Code
## Date: January 2026

class_name Snippet
extends RefCounted

var prefix: String           # Trigger text (e.g., "fori")
var name: String             # Display name
var description: String      # Help text
var body: Array[String]      # Lines of code
var tab_stops: Array[Dictionary] = []  # {index, line, column, placeholder, length}
var scope: String = "python" # Language scope

func _init(p: String, n: String, desc: String, b: Array[String]) -> void:
	prefix = p
	name = n
	description = desc
	body = b
	_parse_tab_stops()

func _parse_tab_stops() -> void:
	# Parse ${1:placeholder} and $1 patterns in body
	var regex = RegEx.new()
	regex.compile(r"\$\{(\d+):([^}]*)\}|\$(\d+)")

	for line_idx in range(body.size()):
		var line = body[line_idx]
		for match in regex.search_all(line):
			var index: int
			var placeholder: String

			if match.get_string(1) != "":
				# ${1:placeholder} format
				index = match.get_string(1).to_int()
				placeholder = match.get_string(2)
			else:
				# $1 format
				index = match.get_string(3).to_int()
				placeholder = ""

			tab_stops.append({
				"index": index,
				"line": line_idx,
				"column": match.get_start(),
				"placeholder": placeholder,
				"length": match.get_string().length()
			})

	# Sort by index
	tab_stops.sort_custom(func(a, b): return a.index < b.index)

func get_expanded_text(indent: String = "") -> String:
	var result: Array[String] = []

	for i in range(body.size()):
		var line = body[i]
		# Replace tab stop markers with placeholders
		var regex = RegEx.new()
		regex.compile(r"\$\{(\d+):([^}]*)\}|\$(\d+)")

		var processed_line = ""
		var last_end = 0

		for match in regex.search_all(line):
			processed_line += line.substr(last_end, match.get_start() - last_end)

			if match.get_string(2) != "":
				processed_line += match.get_string(2)  # Use placeholder text
			# $0 is final cursor position, leave empty

			last_end = match.get_end()

		processed_line += line.substr(last_end)

		# Add indent for all lines except first
		if i > 0:
			result.append(indent + processed_line)
		else:
			result.append(processed_line)

	return "\n".join(result)
