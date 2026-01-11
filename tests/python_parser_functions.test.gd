## Unit tests for PythonParser - Function and Import Features
## Tests def, return, from/import parsing

extends SceneTree

const PythonParser = preload("res://scripts/core/python_parser.gd")

var _test_count: int = 0
var _pass_count: int = 0
var _fail_count: int = 0

func _init():
	print("=".repeat(70))
	print("Running PythonParser Function & Import Tests")
	print("=".repeat(70))

	# Test groups
	test_function_definitions()
	test_return_statements()
	test_import_statements()
	test_complete_examples()
	test_error_cases()

	# Summary
	print("\n" + "=".repeat(70))
	print("Test Summary")
	print("=".repeat(70))
	print("Total tests: %d" % _test_count)
	print("Passed: %d" % _pass_count)
	print("Failed: %d" % _fail_count)

	if _fail_count == 0:
		print("\n✓ All tests passed!")
	else:
		print("\n✗ Some tests failed")

	quit()

func test_function_definitions():
	print("\n--- Function Definition Tests ---")

	var parser = PythonParser.new()

	# Test 1: Simple function with no parameters
	var code1 = "def greet():\n    car.go()"
	var result1 = parser.parse(code1)
	assert_no_errors(parser, "Simple function should parse")
	assert_equal(result1["statements"].size(), 1, "Should have 1 statement")
	var func1 = result1["statements"][0]
	assert_equal(func1["type"], PythonParser.ASTType.FUNCTION_DEF, "Should be FUNCTION_DEF")
	assert_equal(func1["name"], "greet", "Function name should be 'greet'")
	assert_equal(func1["parameters"].size(), 0, "Should have no parameters")
	assert_equal(func1["body"].size(), 1, "Should have 1 body statement")

	# Test 2: Function with parameters
	var code2 = "def smart_turn(vehicle, direction):\n    vehicle.turn(direction)"
	var result2 = parser.parse(code2)
	assert_no_errors(parser, "Function with parameters should parse")
	var func2 = result2["statements"][0]
	assert_equal(func2["parameters"].size(), 2, "Should have 2 parameters")
	assert_equal(func2["parameters"][0], "vehicle", "First parameter should be 'vehicle'")
	assert_equal(func2["parameters"][1], "direction", "Second parameter should be 'direction'")

	# Test 3: Function with multiple body statements
	var code3 = """def navigate():
    if car.front_road():
        car.go()
    else:
        car.stop()"""
	var result3 = parser.parse(code3)
	assert_no_errors(parser, "Function with if/else should parse")
	var func3 = result3["statements"][0]
	assert_equal(func3["body"].size(), 1, "Should have 1 body statement (if)")
	assert_equal(func3["body"][0]["type"], PythonParser.ASTType.IF_STMT, "Body should contain IF_STMT")

	# Test 4: Function with return value
	var code4 = """def calculate(x):
    return x * 2"""
	var result4 = parser.parse(code4)
	assert_no_errors(parser, "Function with return should parse")
	var func4 = result4["statements"][0]
	assert_equal(func4["body"].size(), 1, "Should have 1 body statement")
	assert_equal(func4["body"][0]["type"], PythonParser.ASTType.RETURN_STMT, "Body should contain RETURN_STMT")

	# Test 5: Function with single parameter
	var code5 = "def move_car(vehicle):\n    vehicle.go()"
	var result5 = parser.parse(code5)
	assert_no_errors(parser, "Function with single parameter should parse")
	var func5 = result5["statements"][0]
	assert_equal(func5["parameters"].size(), 1, "Should have 1 parameter")
	assert_equal(func5["parameters"][0], "vehicle", "Parameter should be 'vehicle'")

func test_return_statements():
	print("\n--- Return Statement Tests ---")

	var parser = PythonParser.new()

	# Test 1: Return with value
	var code1 = """def get_speed():
    return 2"""
	var result1 = parser.parse(code1)
	assert_no_errors(parser, "Return with value should parse")
	var func1 = result1["statements"][0]
	var ret1 = func1["body"][0]
	assert_equal(ret1["type"], PythonParser.ASTType.RETURN_STMT, "Should be RETURN_STMT")
	assert_not_null(ret1["value"], "Should have a return value")
	assert_equal(ret1["value"]["type"], PythonParser.ASTType.NUMBER_LITERAL, "Return value should be NUMBER")

	# Test 2: Return with expression
	var code2 = """def double(x):
    return x * 2"""
	var result2 = parser.parse(code2)
	assert_no_errors(parser, "Return with expression should parse")
	var func2 = result2["statements"][0]
	var ret2 = func2["body"][0]
	assert_equal(ret2["value"]["type"], PythonParser.ASTType.BINARY_EXPR, "Return value should be BINARY_EXPR")

	# Test 3: Return with variable
	var code3 = """def get_var():
    return speed"""
	var result3 = parser.parse(code3)
	assert_no_errors(parser, "Return with variable should parse")
	var func3 = result3["statements"][0]
	var ret3 = func3["body"][0]
	assert_equal(ret3["value"]["type"], PythonParser.ASTType.IDENTIFIER, "Return value should be IDENTIFIER")

	# Test 4: Return without value (None)
	var code4 = """def no_return():
    return"""
	var result4 = parser.parse(code4)
	assert_no_errors(parser, "Return without value should parse")
	var func4 = result4["statements"][0]
	var ret4 = func4["body"][0]
	assert_null(ret4["value"], "Return value should be null")

func test_import_statements():
	print("\n--- Import Statement Tests ---")

	var parser = PythonParser.new()

	# Test 1: Single import
	var code1 = "from helpers import smart_turn"
	var result1 = parser.parse(code1)
	assert_no_errors(parser, "Single import should parse")
	assert_equal(result1["statements"].size(), 1, "Should have 1 statement")
	var imp1 = result1["statements"][0]
	assert_equal(imp1["type"], PythonParser.ASTType.IMPORT_STMT, "Should be IMPORT_STMT")
	assert_equal(imp1["module"], "helpers", "Module should be 'helpers'")
	assert_equal(imp1["names"].size(), 1, "Should import 1 name")
	assert_equal(imp1["names"][0], "smart_turn", "Should import 'smart_turn'")

	# Test 2: Multiple imports
	var code2 = "from helpers import smart_turn, wait_for_green, navigate"
	var result2 = parser.parse(code2)
	assert_no_errors(parser, "Multiple imports should parse")
	var imp2 = result2["statements"][0]
	assert_equal(imp2["names"].size(), 3, "Should import 3 names")
	assert_equal(imp2["names"][0], "smart_turn", "First import should be 'smart_turn'")
	assert_equal(imp2["names"][1], "wait_for_green", "Second import should be 'wait_for_green'")
	assert_equal(imp2["names"][2], "navigate", "Third import should be 'navigate'")

	# Test 3: Dotted module name
	var code3 = "from modules.navigation import find_path"
	var result3 = parser.parse(code3)
	assert_no_errors(parser, "Dotted module should parse")
	var imp3 = result3["statements"][0]
	assert_equal(imp3["module"], "modules.navigation", "Module should be 'modules.navigation'")
	assert_equal(imp3["names"][0], "find_path", "Should import 'find_path'")

	# Test 4: Nested dotted module
	var code4 = "from deep.nested.module import func"
	var result4 = parser.parse(code4)
	assert_no_errors(parser, "Nested dotted module should parse")
	var imp4 = result4["statements"][0]
	assert_equal(imp4["module"], "deep.nested.module", "Module should be 'deep.nested.module'")

func test_complete_examples():
	print("\n--- Complete Example Tests ---")

	var parser = PythonParser.new()

	# Test 1: Function definition + import + usage
	var code1 = """from helpers import smart_turn

def navigate_to_end():
    while not car.at_end():
        if car.front_road():
            car.go()
        else:
            smart_turn(car)

navigate_to_end()"""
	var result1 = parser.parse(code1)
	assert_no_errors(parser, "Complete example should parse")
	assert_equal(result1["statements"].size(), 3, "Should have 3 top-level statements")
	assert_equal(result1["statements"][0]["type"], PythonParser.ASTType.IMPORT_STMT, "First should be import")
	assert_equal(result1["statements"][1]["type"], PythonParser.ASTType.FUNCTION_DEF, "Second should be function")
	assert_equal(result1["statements"][2]["type"], PythonParser.ASTType.EXPRESSION_STMT, "Third should be function call")

	# Test 2: Multiple functions
	var code2 = """def move_forward(vehicle):
    vehicle.go()

def turn_left(vehicle):
    vehicle.turn("left")

move_forward(car)
turn_left(car)"""
	var result2 = parser.parse(code2)
	assert_no_errors(parser, "Multiple functions should parse")
	assert_equal(result2["statements"].size(), 4, "Should have 4 statements (2 defs + 2 calls)")

	# Test 3: Function with conditional return
	var code3 = """def should_stop(vehicle):
    if vehicle.front_crash():
        return True
    else:
        return False"""
	var result3 = parser.parse(code3)
	assert_no_errors(parser, "Function with conditional return should parse")
	var func3 = result3["statements"][0]
	assert_equal(func3["body"][0]["type"], PythonParser.ASTType.IF_STMT, "Body should have IF_STMT")

func test_error_cases():
	print("\n--- Error Case Tests ---")

	var parser = PythonParser.new()

	# Test 1: Function without name
	var code1 = "def ():\n    pass"
	var result1 = parser.parse(code1)
	assert_has_errors(parser, "Function without name should error")

	# Test 2: Function without colon
	var code2 = "def foo()\n    pass"
	var result2 = parser.parse(code2)
	assert_has_errors(parser, "Function without colon should error")

	# Test 3: Function without parentheses
	var code3 = "def foo:\n    pass"
	var result3 = parser.parse(code3)
	assert_has_errors(parser, "Function without parentheses should error")

	# Test 4: Import without 'import' keyword
	var code4 = "from helpers"
	var result4 = parser.parse(code4)
	assert_has_errors(parser, "Import without 'import' keyword should error")

	# Test 5: Import without module name
	var code5 = "from import foo"
	var result5 = parser.parse(code5)
	assert_has_errors(parser, "Import without module name should error")

# Test assertion helpers
func assert_true(condition: bool, message: String):
	_test_count += 1
	if condition:
		_pass_count += 1
		print("  ✓ %s" % message)
	else:
		_fail_count += 1
		print("  ✗ FAILED: %s" % message)

func assert_false(condition: bool, message: String):
	assert_true(not condition, message)

func assert_equal(actual, expected, message: String):
	_test_count += 1
	if actual == expected:
		_pass_count += 1
		print("  ✓ %s" % message)
	else:
		_fail_count += 1
		print("  ✗ FAILED: %s (expected: %s, got: %s)" % [message, expected, actual])

func assert_not_null(value, message: String):
	_test_count += 1
	if value != null:
		_pass_count += 1
		print("  ✓ %s" % message)
	else:
		_fail_count += 1
		print("  ✗ FAILED: %s (value was null)" % message)

func assert_null(value, message: String):
	_test_count += 1
	if value == null:
		_pass_count += 1
		print("  ✓ %s" % message)
	else:
		_fail_count += 1
		print("  ✗ FAILED: %s (value was not null: %s)" % [message, value])

func assert_no_errors(parser: PythonParser, message: String):
	_test_count += 1
	if parser._errors.size() == 0:
		_pass_count += 1
		print("  ✓ %s" % message)
	else:
		_fail_count += 1
		print("  ✗ FAILED: %s (errors: %s)" % [message, parser._errors])

func assert_has_errors(parser: PythonParser, message: String):
	_test_count += 1
	if parser._errors.size() > 0:
		_pass_count += 1
		print("  ✓ %s" % message)
	else:
		_fail_count += 1
		print("  ✗ FAILED: %s (expected errors but got none)" % message)
