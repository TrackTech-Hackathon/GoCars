## Game Commands Registry for GoCars
## Contains all available game commands with documentation for IntelliSense
## Author: Claude Code
## Date: January 2026

class_name GameCommands

static var commands: Array = [
	# Car Movement Commands (Short API)
	{"name": "go", "type": "function", "signature": "car.go()", "doc": "Start moving forward", "category": "movement"},
	{"name": "stop", "type": "function", "signature": "car.stop()", "doc": "Stop immediately", "category": "movement"},
	{"name": "turn", "type": "function", "signature": "car.turn(direction: str)", "doc": "Turn 90°. Direction: 'left' or 'right'", "category": "movement"},
	{"name": "move", "type": "function", "signature": "car.move(tiles: int)", "doc": "Move forward N tiles", "category": "movement"},
	{"name": "wait", "type": "function", "signature": "car.wait(seconds: float)", "doc": "Wait N seconds", "category": "movement"},

	# Speed Control
	{"name": "set_speed", "type": "function", "signature": "car.set_speed(speed: float)", "doc": "Set speed (0.5-2.0)", "category": "speed"},
	{"name": "get_speed", "type": "function", "signature": "car.get_speed() -> float", "doc": "Get current speed", "category": "speed"},

	# Road Detection
	{"name": "front_road", "type": "function", "signature": "car.front_road() -> bool", "doc": "Returns True if road ahead", "category": "sensor"},
	{"name": "left_road", "type": "function", "signature": "car.left_road() -> bool", "doc": "Returns True if road to left", "category": "sensor"},
	{"name": "right_road", "type": "function", "signature": "car.right_road() -> bool", "doc": "Returns True if road to right", "category": "sensor"},
	{"name": "dead_end", "type": "function", "signature": "car.dead_end() -> bool", "doc": "Returns True if no roads anywhere", "category": "sensor"},

	# Car Detection
	{"name": "front_car", "type": "function", "signature": "car.front_car() -> bool", "doc": "Returns True if any car ahead", "category": "sensor"},
	{"name": "front_crash", "type": "function", "signature": "car.front_crash() -> bool", "doc": "Returns True if crashed car ahead", "category": "sensor"},

	# State Queries
	{"name": "moving", "type": "function", "signature": "car.moving() -> bool", "doc": "Returns True if car is moving", "category": "state"},
	{"name": "blocked", "type": "function", "signature": "car.blocked() -> bool", "doc": "Returns True if path blocked", "category": "state"},
	{"name": "at_cross", "type": "function", "signature": "car.at_cross() -> bool", "doc": "Returns True if at intersection", "category": "state"},
	{"name": "at_end", "type": "function", "signature": "car.at_end() -> bool", "doc": "Returns True if at destination", "category": "state"},
	{"name": "at_red", "type": "function", "signature": "car.at_red() -> bool", "doc": "Returns True if near red light", "category": "state"},
	{"name": "turning", "type": "function", "signature": "car.turning() -> bool", "doc": "Returns True if currently turning", "category": "state"},

	# Distance
	{"name": "dist", "type": "function", "signature": "car.dist() -> float", "doc": "Returns distance to destination", "category": "utility"},

	# Stoplight Commands
	{"name": "red", "type": "function", "signature": "stoplight.red()", "doc": "Set stoplight to red", "category": "traffic"},
	{"name": "yellow", "type": "function", "signature": "stoplight.yellow()", "doc": "Set stoplight to yellow", "category": "traffic"},
	{"name": "green", "type": "function", "signature": "stoplight.green()", "doc": "Set stoplight to green", "category": "traffic"},
	{"name": "is_red", "type": "function", "signature": "stoplight.is_red() -> bool", "doc": "Returns True if stoplight is red", "category": "traffic"},
	{"name": "is_yellow", "type": "function", "signature": "stoplight.is_yellow() -> bool", "doc": "Returns True if stoplight is yellow", "category": "traffic"},
	{"name": "is_green", "type": "function", "signature": "stoplight.is_green() -> bool", "doc": "Returns True if stoplight is green", "category": "traffic"},
	{"name": "state", "type": "function", "signature": "stoplight.state() -> str", "doc": "Returns stoplight state: 'red', 'yellow', or 'green'", "category": "traffic"},

	# Boat Commands
	{"name": "depart", "type": "function", "signature": "boat.depart()", "doc": "Force immediate boat departure", "category": "boat"},
	{"name": "is_ready", "type": "function", "signature": "boat.is_ready() -> bool", "doc": "Returns True if boat is docked and ready", "category": "boat"},
	{"name": "is_full", "type": "function", "signature": "boat.is_full() -> bool", "doc": "Returns True if boat is at capacity", "category": "boat"},
	{"name": "get_passenger_count", "type": "function", "signature": "boat.get_passenger_count() -> int", "doc": "Returns number of cars on board", "category": "boat"},

	# Python Built-ins
	{"name": "print", "type": "builtin", "signature": "print(*args)", "doc": "Print values to the console", "category": "utility"},
	{"name": "len", "type": "builtin", "signature": "len(obj) -> int", "doc": "Return the length of an object", "category": "utility"},
	{"name": "range", "type": "builtin", "signature": "range(start, stop=None, step=1) -> range", "doc": "Generate a sequence of numbers", "category": "utility"},
	{"name": "abs", "type": "builtin", "signature": "abs(x) -> number", "doc": "Return absolute value", "category": "utility"},
	{"name": "min", "type": "builtin", "signature": "min(*args) -> value", "doc": "Return the smallest value", "category": "utility"},
	{"name": "max", "type": "builtin", "signature": "max(*args) -> value", "doc": "Return the largest value", "category": "utility"},
	{"name": "int", "type": "builtin", "signature": "int(x) -> int", "doc": "Convert to integer", "category": "utility"},
	{"name": "float", "type": "builtin", "signature": "float(x) -> float", "doc": "Convert to float", "category": "utility"},
	{"name": "str", "type": "builtin", "signature": "str(x) -> str", "doc": "Convert to string", "category": "utility"},
	{"name": "bool", "type": "builtin", "signature": "bool(x) -> bool", "doc": "Convert to boolean", "category": "utility"},
]

static var keywords: Array = [
	"if", "else", "elif", "while", "for", "def", "return", "class",
	"import", "from", "as", "try", "except", "finally", "with",
	"lambda", "yield", "pass", "break", "continue", "and", "or",
	"not", "in", "is", "True", "False", "None", "global", "nonlocal"
]

static var objects: Array = [
	"car", "stoplight", "boat"
]

static func get_by_prefix(prefix: String) -> Array:
	var results: Array = []
	var prefix_lower = prefix.to_lower()

	# Skip if prefix is empty
	if prefix_lower.is_empty():
		return results

	# Add matching commands
	for cmd in commands:
		if cmd.name.to_lower().begins_with(prefix_lower):
			results.append(cmd)

	# Add matching keywords
	for keyword in keywords:
		if keyword.to_lower().begins_with(prefix_lower):
			results.append({
				"name": keyword,
				"type": "keyword",
				"signature": keyword,
				"doc": "Python keyword",
				"category": "keyword"
			})

	# Add matching objects
	for obj in objects:
		if obj.to_lower().begins_with(prefix_lower):
			results.append({
				"name": obj,
				"type": "object",
				"signature": obj,
				"doc": "Game object",
				"category": "object"
			})

	# Sort by relevance (exact prefix first, then alphabetically)
	results.sort_custom(func(a, b):
		var a_exact = a.name.to_lower() == prefix_lower
		var b_exact = b.name.to_lower() == prefix_lower
		if a_exact != b_exact:
			return a_exact
		return a.name < b.name
	)

	return results

static func find_by_name(name: String) -> Dictionary:
	for cmd in commands:
		if cmd.name == name:
			return cmd
	return {}

## Get methods available for a specific game object
static func get_methods_for_object(obj_name: String, prefix: String = "") -> Array:
	var results: Array = []
	var prefix_lower = prefix.to_lower()

	# Define which categories belong to which object
	var object_categories = {
		"car": ["movement", "speed", "sensor", "state", "utility"],
		"stoplight": ["traffic"],
		"boat": ["boat"]
	}

	var valid_categories = object_categories.get(obj_name, [])

	for cmd in commands:
		if cmd.category in valid_categories:
			if prefix_lower.is_empty() or cmd.name.to_lower().begins_with(prefix_lower):
				results.append(cmd)

	# Sort alphabetically
	results.sort_custom(func(a, b): return a.name < b.name)

	return results
