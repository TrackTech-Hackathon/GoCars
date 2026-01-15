## Built-in Snippet Library for GoCars
## Author: Claude Code
## Date: January 2026

class_name SnippetLibrary

static var snippets: Array[Snippet] = []

static func _static_init() -> void:
	# Control Flow
	snippets.append(Snippet.new(
		"if", "If Statement", "If conditional block",
		["if ${1:condition}:", "\t${2:pass}"]
	))

	snippets.append(Snippet.new(
		"ife", "If-Else", "If-else conditional block",
		["if ${1:condition}:", "\t${2:pass}", "else:", "\t${3:pass}"]
	))

	snippets.append(Snippet.new(
		"ifel", "If-Elif-Else", "If-elif-else chain",
		["if ${1:condition}:", "\t${2:pass}", "elif ${3:condition}:", "\t${4:pass}", "else:", "\t${5:pass}"]
	))

	# Loops
	snippets.append(Snippet.new(
		"for", "For Loop", "For loop with iterator",
		["for ${1:item} in ${2:iterable}:", "\t${3:pass}"]
	))

	snippets.append(Snippet.new(
		"fori", "For Range Loop", "For loop with range",
		["for ${1:i} in range(${2:10}):", "\t${3:pass}"]
	))

	snippets.append(Snippet.new(
		"forr", "For Range with Start", "For loop with start and end",
		["for ${1:i} in range(${2:0}, ${3:10}):", "\t${4:pass}"]
	))

	snippets.append(Snippet.new(
		"while", "While Loop", "While loop block",
		["while ${1:condition}:", "\t${2:pass}"]
	))

	snippets.append(Snippet.new(
		"whilet", "While True Loop", "Infinite loop with break",
		["while True:", "\t${1:pass}", "\tif ${2:condition}:", "\t\tbreak"]
	))

	# Functions
	snippets.append(Snippet.new(
		"def", "Function Definition", "Define a function",
		["def ${1:function_name}(${2:params}):", "\t${3:pass}"]
	))

	snippets.append(Snippet.new(
		"defr", "Function with Return", "Function with return statement",
		["def ${1:function_name}(${2:params}):", "\t${3:result = None}", "\treturn ${4:result}"]
	))

	snippets.append(Snippet.new(
		"main", "Main Block", "Main entry point",
		["def main():", "\t${1:pass}", "", "main()"]
	))

	# Error Handling
	snippets.append(Snippet.new(
		"try", "Try-Except", "Try-except block",
		["try:", "\t${1:pass}", "except ${2:Exception}:", "\t${3:pass}"]
	))

	snippets.append(Snippet.new(
		"tryf", "Try-Except-Finally", "Try-except-finally block",
		["try:", "\t${1:pass}", "except ${2:Exception}:", "\t${3:pass}", "finally:", "\t${4:pass}"]
	))

	# Game-Specific Snippets (using short API)
	snippets.append(Snippet.new(
		"moveloop", "Movement Loop", "Loop with movement commands",
		["for ${1:i} in range(${2:5}):", "\tcar.move(1)", "\t${3:pass}"]
	))

	snippets.append(Snippet.new(
		"checkblock", "Check Blocked", "Check if blocked and handle",
		["if car.blocked():", "\t${1:car.turn(\"left\")}", "else:", "\tcar.go()"]
	))

	snippets.append(Snippet.new(
		"waitgreen", "Wait for Green Light", "Wait for traffic light",
		["while stoplight.is_red():", "\tcar.wait(0.5)", "car.go()"]
	))

	snippets.append(Snippet.new(
		"patrol", "Patrol Pattern", "Basic patrol loop",
		["while True:", "\tfor ${1:i} in range(${2:4}):", "\t\tcar.go()", "\tcar.turn(\"right\")"]
	))

	snippets.append(Snippet.new(
		"avoidobs", "Avoid Obstacle", "Obstacle avoidance pattern",
		["if car.front_crash():", "\tif car.left_road():", "\t\tcar.turn(\"left\")", "\telif car.right_road():", "\t\tcar.turn(\"right\")", "else:", "\tcar.go()"]
	))

	snippets.append(Snippet.new(
		"navloop", "Navigation Loop", "Complete navigation with checks",
		["while not car.at_end():", "\tif car.front_road():", "\t\tcar.go()", "\telif car.left_road():", "\t\tcar.turn(\"left\")", "\telif car.right_road():", "\t\tcar.turn(\"right\")", "\telse:", "\t\tcar.stop()"]
	))

static func get_by_prefix(prefix: String) -> Array[Snippet]:
	var result: Array[Snippet] = []
	var prefix_lower = prefix.to_lower()

	for snippet in snippets:
		if snippet.prefix.to_lower().begins_with(prefix_lower):
			result.append(snippet)

	return result

static func get_exact(prefix: String) -> Snippet:
	for snippet in snippets:
		if snippet.prefix == prefix:
			return snippet
	return null
