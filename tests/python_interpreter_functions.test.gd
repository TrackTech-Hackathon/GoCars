## Integration tests for PythonInterpreter - Function and Import Features
## Tests function definitions, calls, returns, and imports

extends SceneTree

const PythonParser = preload("res://scripts/core/python_parser.gd")
const PythonInterpreter = preload("res://scripts/core/python_interpreter.gd")
const VirtualFileSystem = preload("res://scripts/core/virtual_filesystem.gd")
const ModuleLoader = preload("res://scripts/core/module_loader.gd")

var _test_count: int = 0
var _pass_count: int = 0
var _fail_count: int = 0

func _init():
	print("=".repeat(70))
	print("Running PythonInterpreter Function & Import Integration Tests")
	print("=".repeat(70))

	# Test groups
	test_function_definition_and_call()
	test_function_with_return()
	test_function_with_parameters()
	test_import_and_call()
	test_complete_import_chain()

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

func test_function_definition_and_call():
	print("\n--- Function Definition and Call Tests ---")

	var parser = PythonParser.new()
	var interpreter = PythonInterpreter.new()

	# Test 1: Simple function without parameters
	var code1 = """
def greet():
	return 42

result = greet()
"""
	var ast1 = parser.parse(code1)
	assert_no_errors(parser, "Simple function should parse")

	interpreter.start_execution(ast1)
	while interpreter.step():
		pass

	assert_no_errors(interpreter, "Function execution should not error")
	assert_equal(interpreter._variables.get("result"), 42, "Function should return 42")

	# Test 2: Function called multiple times
	var code2 = """
def double(x):
	return x * 2

a = double(5)
b = double(10)
"""
	var ast2 = parser.parse(code2)
	interpreter.start_execution(ast2)
	while interpreter.step():
		pass

	assert_no_errors(interpreter, "Multiple function calls should work")
	assert_equal(interpreter._variables.get("a"), 10, "double(5) should be 10")
	assert_equal(interpreter._variables.get("b"), 20, "double(10) should be 20")

func test_function_with_return():
	print("\n--- Function Return Tests ---")

	var parser = PythonParser.new()
	var interpreter = PythonInterpreter.new()

	# Test 1: Return with value
	var code1 = """
def get_speed():
	return 2

speed = get_speed()
"""
	var ast1 = parser.parse(code1)
	interpreter.start_execution(ast1)
	while interpreter.step():
		pass

	assert_equal(interpreter._variables.get("speed"), 2, "Should return 2")

	# Test 2: Return without value (None)
	var code2 = """
def do_nothing():
	return

value = do_nothing()
"""
	var ast2 = parser.parse(code2)
	interpreter.start_execution(ast2)
	while interpreter.step():
		pass

	assert_null(interpreter._variables.get("value"), "Should return null")

	# Test 3: Early return
	var code3 = """
def check(x):
	if x > 5:
		return True
	return False

result_true = check(10)
result_false = check(3)
"""
	var ast3 = parser.parse(code3)
	interpreter.start_execution(ast3)
	while interpreter.step():
		pass

	assert_equal(interpreter._variables.get("result_true"), true, "check(10) should be true")
	assert_equal(interpreter._variables.get("result_false"), false, "check(3) should be false")

func test_function_with_parameters():
	print("\n--- Function Parameter Tests ---")

	var parser = PythonParser.new()
	var interpreter = PythonInterpreter.new()

	# Test 1: Single parameter
	var code1 = """
def triple(n):
	return n * 3

result = triple(7)
"""
	var ast1 = parser.parse(code1)
	interpreter.start_execution(ast1)
	while interpreter.step():
		pass

	assert_equal(interpreter._variables.get("result"), 21, "triple(7) should be 21")

	# Test 2: Multiple parameters
	var code2 = """
def add(a, b):
	return a + b

sum_val = add(10, 20)
"""
	var ast2 = parser.parse(code2)
	interpreter.start_execution(ast2)
	while interpreter.step():
		pass

	assert_equal(interpreter._variables.get("sum_val"), 30, "add(10, 20) should be 30")

	# Test 3: Parameter scope (doesn't affect outer variables)
	var code3 = """
x = 100
def change_param(x):
	x = 50
	return x

result = change_param(10)
"""
	var ast3 = parser.parse(code3)
	interpreter.start_execution(ast3)
	while interpreter.step():
		pass

	assert_equal(interpreter._variables.get("result"), 50, "Function should return 50")
	assert_equal(interpreter._variables.get("x"), 100, "Outer x should still be 100")

func test_import_and_call():
	print("\n--- Import and Call Tests ---")

	var parser = PythonParser.new()
	var interpreter = PythonInterpreter.new()
	var vfs = VirtualFileSystem.new()
	var loader = ModuleLoader.new()

	loader.call("set_filesystem", vfs)
	interpreter.call("set_module_loader", loader)

	# Create a helper module
	vfs.create_file("helpers.py", """
def smart_turn(direction):
	return direction + "_turned"

def calculate(x):
	return x * 2
""")

	# Test 1: Import and use single function
	var code1 = """
from helpers import smart_turn

result = smart_turn("left")
"""
	var ast1 = parser.parse(code1)
	interpreter.start_execution(ast1)
	while interpreter.step():
		pass

	assert_no_errors(interpreter, "Import should work")
	assert_equal(interpreter._variables.get("result"), "left_turned", "Function should work after import")

	# Test 2: Import multiple functions
	var code2 = """
from helpers import smart_turn, calculate

turn_result = smart_turn("right")
calc_result = calculate(5)
"""
	var ast2 = parser.parse(code2)
	interpreter.start_execution(ast2)
	while interpreter.step():
		pass

	assert_equal(interpreter._variables.get("turn_result"), "right_turned", "First import should work")
	assert_equal(interpreter._variables.get("calc_result"), 10, "Second import should work")

func test_complete_import_chain():
	print("\n--- Complete Import Chain Tests ---")

	var parser = PythonParser.new()
	var interpreter = PythonInterpreter.new()
	var vfs = VirtualFileSystem.new()
	var loader = ModuleLoader.new()

	loader.call("set_filesystem", vfs)
	interpreter.call("set_module_loader", loader)

	# Create helpers module
	vfs.create_file("helpers.py", """
def double(x):
	return x * 2

def is_even(n):
	return n == 2 or n == 4 or n == 6 or n == 8
""")

	# Create nested module structure
	vfs.create_directory("modules")
	vfs.create_file("modules/math_utils.py", """
def square(x):
	return x * x
""")

	# Test complete workflow
	var code = """
from helpers import double, is_even
from modules.math_utils import square

a = double(5)
b = square(4)
c = is_even(4)
d = is_even(5)
"""
	var ast = parser.parse(code)
	interpreter.start_execution(ast)
	while interpreter.step():
		pass

	assert_no_errors(interpreter, "Complete import chain should work")
	assert_equal(interpreter._variables.get("a"), 10, "double(5) should be 10")
	assert_equal(interpreter._variables.get("b"), 16, "square(4) should be 16")
	assert_equal(interpreter._variables.get("c"), true, "is_even(4) should be true")
	assert_equal(interpreter._variables.get("d"), false, "is_even(5) should be false")

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

func assert_null(value, message: String):
	_test_count += 1
	if value == null:
		_pass_count += 1
		print("  ✓ %s" % message)
	else:
		_fail_count += 1
		print("  ✗ FAILED: %s (value was not null: %s)" % [message, value])

func assert_no_errors(obj, message: String):
	_test_count += 1
	if obj._errors.size() == 0:
		_pass_count += 1
		print("  ✓ %s" % message)
	else:
		_fail_count += 1
		print("  ✗ FAILED: %s (errors: %s)" % [message, obj._errors])
