extends RefCounted
class_name CodeParser

## Parses simplified Python-like syntax for vehicle control commands.
## See PRD TECH-003 for full specifications.

# Supported objects and their available functions
var _available_objects: Dictionary = {
	"car": ["go", "stop", "turn_left", "turn_right", "wait", "turn", "move", "is_front_road", "is_left_road", "is_right_road", "is_front_car", "is_front_crashed_car"],
	"stoplight": ["set_red", "set_green", "set_yellow", "get_state"],
	"boat": ["depart", "get_capacity"]
}

# Functions that require parameters: function_name -> [param_type, min, max] or ["string", allowed_values]
var _function_params: Dictionary = {
	"wait": ["int", 1, 60],
	"speed": ["float", 0.5, 2.0],
	"turn": ["string", ["left", "right"]],
	"move": ["int", 1, 100]
}

# Result structure for parsing
class ParseResult:
	var valid: bool = true
	var commands: Array = []
	var errors: Array = []

	func add_command(obj: String, func_name: String, params: Array = []) -> void:
		commands.append({
			"object": obj,
			"function": func_name,
			"params": params
		})

	func add_error(line_num: int, message: String) -> void:
		valid = false
		errors.append({
			"line": line_num,
			"message": message
		})


## Parse multiple lines of code
func parse(code: String, available_objects: Array = ["car"]) -> ParseResult:
	var result = ParseResult.new()
	var lines = code.split("\n")

	for i in range(lines.size()):
		var line = lines[i].strip_edges()
		var line_num = i + 1

		# Skip empty lines and comments
		if line.is_empty() or line.begins_with("#"):
			continue

		_parse_line(line, line_num, available_objects, result)

	return result


## Parse a single line of code
func _parse_line(line: String, line_num: int, available_objects: Array, result: ParseResult) -> void:
	# Check for basic syntax: must contain a dot and parentheses
	if not "." in line:
		result.add_error(line_num, "Syntax error: expected format 'object.function()'")
		return

	if not "(" in line or not ")" in line:
		result.add_error(line_num, "Syntax error: missing parentheses")
		return

	# Check parentheses are properly closed
	var open_paren = line.find("(")
	var close_paren = line.rfind(")")
	if close_paren < open_paren:
		result.add_error(line_num, "Syntax error: missing closing parenthesis")
		return

	# Split by dot to get object and method
	var dot_pos = line.find(".")
	var object_name = line.substr(0, dot_pos).strip_edges()
	var rest = line.substr(dot_pos + 1).strip_edges()

	# Validate object exists
	if not object_name in available_objects:
		result.add_error(line_num, "Object '%s' not found in this level" % object_name)
		return

	if not object_name in _available_objects:
		result.add_error(line_num, "Unknown object type: '%s'" % object_name)
		return

	# Extract function name and parameters
	var paren_pos = rest.find("(")
	var func_name = rest.substr(0, paren_pos).strip_edges()
	var params_str = rest.substr(paren_pos + 1, rest.rfind(")") - paren_pos - 1).strip_edges()

	# Validate function exists for this object
	var valid_functions = _available_objects[object_name]
	if not func_name in valid_functions:
		result.add_error(line_num, "Unknown function: %s.%s() is not available" % [object_name, func_name])
		return

	# Parse and validate parameters
	var params: Array = []
	if not params_str.is_empty():
		var param_result = _parse_params(func_name, params_str, line_num)
		if param_result.has("error"):
			result.add_error(line_num, param_result["error"])
			return
		params = param_result["params"]
	else:
		# Check if function requires parameters
		if func_name in _function_params:
			result.add_error(line_num, "%s.%s() requires a parameter" % [object_name, func_name])
			return

	# Command is valid
	result.add_command(object_name, func_name, params)


## Parse function parameters
func _parse_params(func_name: String, params_str: String, _line_num: int) -> Dictionary:
	var params: Array = []

	# Check if function accepts parameters
	if not func_name in _function_params:
		return {"error": "Function %s() does not accept parameters" % func_name}

	var param_spec = _function_params[func_name]
	var param_type = param_spec[0]

	# Parse based on expected type
	if param_type == "int":
		var param_min = param_spec[1]
		var param_max = param_spec[2]
		if not params_str.is_valid_int():
			return {"error": "%s() requires an integer parameter" % func_name}
		var value = params_str.to_int()
		if value < param_min or value > param_max:
			return {"error": "%s(%s) - value must be between %s and %s" % [func_name, value, param_min, param_max]}
		params.append(value)
	elif param_type == "float":
		var param_min = param_spec[1]
		var param_max = param_spec[2]
		if not params_str.is_valid_float():
			return {"error": "%s() requires a number parameter" % func_name}
		var value = params_str.to_float()
		if value < param_min or value > param_max:
			return {"error": "%s(%s) - value must be between %s and %s" % [func_name, value, param_min, param_max]}
		params.append(value)
	elif param_type == "string":
		var allowed_values = param_spec[1]
		# Remove quotes if present
		var value = params_str.strip_edges()
		if value.begins_with('"') and value.ends_with('"'):
			value = value.substr(1, value.length() - 2)
		elif value.begins_with("'") and value.ends_with("'"):
			value = value.substr(1, value.length() - 2)

		# Check if value is in allowed list
		if not value in allowed_values:
			return {"error": "%s('%s') - value must be one of: %s" % [func_name, value, ", ".join(allowed_values)]}
		params.append(value)

	return {"params": params}


## Parse a single command and return result (convenience method)
func parse_single(command: String, available_objects: Array = ["car"]) -> ParseResult:
	return parse(command, available_objects)
