extends SceneTree

## Tests for PythonInterpreter
## Tests execution, variables, control flow, and game object interaction

var _passed: int = 0
var _failed: int = 0

func _init():
	print("=".repeat(50))
	print("Running PythonInterpreter tests...")
	print("=".repeat(50))

	# Expression evaluation tests
	test_evaluate_numbers()
	test_evaluate_strings()
	test_evaluate_booleans()
	test_evaluate_arithmetic()
	test_evaluate_comparisons()
	test_evaluate_logical_operators()
	test_evaluate_unary_operators()

	# Variable tests
	test_assignment()
	test_variable_retrieval()
	test_undefined_variable_error()

	# Control flow tests
	test_if_statement_true()
	test_if_statement_false()
	test_if_elif_else()
	test_while_loop()
	test_for_loop()
	test_break_statement()
	test_nested_loops()

	# Game object tests
	test_method_call()
	test_method_with_arguments()
	test_method_return_value()
	test_undefined_method_error()

	# Error handling tests
	test_division_by_zero()
	test_type_error_arithmetic()

	print("=".repeat(50))
	print("Results: %d passed, %d failed" % [_passed, _failed])
	if _failed == 0:
		print("All tests passed!")
	print("=".repeat(50))

	quit()

# ============================================
# Test Helpers
# ============================================

func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  + %s" % message)
	else:
		_failed += 1
		print("  X FAILED: %s" % message)

func _assert_eq(actual: Variant, expected: Variant, message: String) -> void:
	if actual == expected:
		_passed += 1
		print("  + %s" % message)
	else:
		_failed += 1
		print("  X FAILED: %s (expected %s, got %s)" % [message, expected, actual])

# Mock game object for testing
class MockCar:
	var _speed: float = 1.0
	var _is_moving: bool = false
	var _position: Vector2 = Vector2.ZERO
	var call_log: Array = []

	func go() -> void:
		_is_moving = true
		call_log.append({"method": "go", "args": []})

	func stop() -> void:
		_is_moving = false
		call_log.append({"method": "stop", "args": []})

	func set_speed(speed: float) -> void:
		_speed = speed
		call_log.append({"method": "set_speed", "args": [speed]})

	func get_speed() -> float:
		call_log.append({"method": "get_speed", "args": []})
		return _speed

	func is_moving() -> bool:
		call_log.append({"method": "is_moving", "args": []})
		return _is_moving

	func wait(seconds: float) -> void:
		call_log.append({"method": "wait", "args": [seconds]})

	func is_at_destination() -> bool:
		call_log.append({"method": "is_at_destination", "args": []})
		return _position.x >= 100

	func move_forward() -> void:
		_position.x += 10
		call_log.append({"method": "move_forward", "args": []})

func _parse_and_execute(code: String, objects: Dictionary = {}) -> Dictionary:
	var parser = PythonParser.new()
	var ast = parser.parse(code)

	var interpreter = PythonInterpreter.new()
	for obj_name in objects:
		interpreter.register_object(obj_name, objects[obj_name])

	return interpreter.execute(ast)

# ============================================
# Expression Evaluation Tests
# ============================================

func test_evaluate_numbers():
	print("\ntest_evaluate_numbers:")
	var result = _parse_and_execute("x = 42")
	_assert(result["success"], "Should execute without errors")
	_assert_eq(result["variables"]["x"], 42, "x should be 42")

	result = _parse_and_execute("y = 3.14")
	_assert_eq(result["variables"]["y"], 3.14, "y should be 3.14")

func test_evaluate_strings():
	print("\ntest_evaluate_strings:")
	var result = _parse_and_execute('msg = "hello"')
	_assert(result["success"], "Should execute without errors")
	_assert_eq(result["variables"]["msg"], "hello", "msg should be 'hello'")

func test_evaluate_booleans():
	print("\ntest_evaluate_booleans:")
	var result = _parse_and_execute("flag = True")
	_assert(result["success"], "Should execute without errors")
	_assert_eq(result["variables"]["flag"], true, "flag should be true")

	result = _parse_and_execute("flag = False")
	_assert_eq(result["variables"]["flag"], false, "flag should be false")

func test_evaluate_arithmetic():
	print("\ntest_evaluate_arithmetic:")
	var result = _parse_and_execute("x = 5 + 3")
	_assert_eq(result["variables"]["x"], 8, "5 + 3 should be 8")

	result = _parse_and_execute("x = 10 - 4")
	_assert_eq(result["variables"]["x"], 6, "10 - 4 should be 6")

	result = _parse_and_execute("x = 6 * 7")
	_assert_eq(result["variables"]["x"], 42, "6 * 7 should be 42")

	result = _parse_and_execute("x = 15 / 3")
	_assert_eq(result["variables"]["x"], 5.0, "15 / 3 should be 5.0")

	# Operator precedence
	result = _parse_and_execute("x = 2 + 3 * 4")
	_assert_eq(result["variables"]["x"], 14, "2 + 3 * 4 should be 14 (not 20)")

func test_evaluate_comparisons():
	print("\ntest_evaluate_comparisons:")
	var result = _parse_and_execute("x = 5 == 5")
	_assert_eq(result["variables"]["x"], true, "5 == 5 should be true")

	result = _parse_and_execute("x = 5 != 3")
	_assert_eq(result["variables"]["x"], true, "5 != 3 should be true")

	result = _parse_and_execute("x = 3 < 5")
	_assert_eq(result["variables"]["x"], true, "3 < 5 should be true")

	result = _parse_and_execute("x = 5 > 3")
	_assert_eq(result["variables"]["x"], true, "5 > 3 should be true")

	result = _parse_and_execute("x = 5 <= 5")
	_assert_eq(result["variables"]["x"], true, "5 <= 5 should be true")

	result = _parse_and_execute("x = 5 >= 5")
	_assert_eq(result["variables"]["x"], true, "5 >= 5 should be true")

func test_evaluate_logical_operators():
	print("\ntest_evaluate_logical_operators:")
	var result = _parse_and_execute("x = True and True")
	_assert_eq(result["variables"]["x"], true, "True and True should be true")

	result = _parse_and_execute("x = True and False")
	_assert_eq(result["variables"]["x"], false, "True and False should be false")

	result = _parse_and_execute("x = True or False")
	_assert_eq(result["variables"]["x"], true, "True or False should be true")

	result = _parse_and_execute("x = False or False")
	_assert_eq(result["variables"]["x"], false, "False or False should be false")

func test_evaluate_unary_operators():
	print("\ntest_evaluate_unary_operators:")
	var result = _parse_and_execute("x = -5")
	_assert_eq(result["variables"]["x"], -5, "-5 should be -5")

	result = _parse_and_execute("x = not True")
	_assert_eq(result["variables"]["x"], false, "not True should be false")

	result = _parse_and_execute("x = not False")
	_assert_eq(result["variables"]["x"], true, "not False should be true")

# ============================================
# Variable Tests
# ============================================

func test_assignment():
	print("\ntest_assignment:")
	var result = _parse_and_execute("speed = 1.5")
	_assert(result["success"], "Should execute without errors")
	_assert_eq(result["variables"]["speed"], 1.5, "speed should be 1.5")

func test_variable_retrieval():
	print("\ntest_variable_retrieval:")
	var code = """x = 10
y = x + 5
"""
	var result = _parse_and_execute(code)
	_assert(result["success"], "Should execute without errors")
	_assert_eq(result["variables"]["y"], 15, "y should be 15")

func test_undefined_variable_error():
	print("\ntest_undefined_variable_error:")
	var result = _parse_and_execute("x = undefined_var + 1")
	_assert(not result["success"], "Should have errors")

	var has_name_error = false
	for err in result["errors"]:
		if "NameError" in err["message"]:
			has_name_error = true
	_assert(has_name_error, "Should have NameError")

# ============================================
# Control Flow Tests
# ============================================

func test_if_statement_true():
	print("\ntest_if_statement_true:")
	var code = """x = 0
if True:
    x = 1
"""
	var result = _parse_and_execute(code)
	_assert(result["success"], "Should execute without errors")
	_assert_eq(result["variables"]["x"], 1, "x should be 1 (if block executed)")

func test_if_statement_false():
	print("\ntest_if_statement_false:")
	var code = """x = 0
if False:
    x = 1
"""
	var result = _parse_and_execute(code)
	_assert(result["success"], "Should execute without errors")
	_assert_eq(result["variables"]["x"], 0, "x should be 0 (if block not executed)")

func test_if_elif_else():
	print("\ntest_if_elif_else:")
	# Test if branch
	var code = """result = 0
value = 1
if value == 1:
    result = 1
elif value == 2:
    result = 2
else:
    result = 3
"""
	var result = _parse_and_execute(code)
	_assert(result["success"], "Should execute without errors")
	_assert_eq(result["variables"]["result"], 1, "result should be 1 (if branch)")

	# Test elif branch
	code = """result = 0
value = 2
if value == 1:
    result = 1
elif value == 2:
    result = 2
else:
    result = 3
"""
	result = _parse_and_execute(code)
	_assert_eq(result["variables"]["result"], 2, "result should be 2 (elif branch)")

	# Test else branch
	code = """result = 0
value = 5
if value == 1:
    result = 1
elif value == 2:
    result = 2
else:
    result = 3
"""
	result = _parse_and_execute(code)
	_assert_eq(result["variables"]["result"], 3, "result should be 3 (else branch)")

func test_while_loop():
	print("\ntest_while_loop:")
	var code = """count = 0
while count < 5:
    count = count + 1
"""
	var result = _parse_and_execute(code)
	_assert(result["success"], "Should execute without errors")
	_assert_eq(result["variables"]["count"], 5, "count should be 5 after loop")

func test_for_loop():
	print("\ntest_for_loop:")
	var code = """total = 0
for i in range(5):
    total = total + 1
"""
	var result = _parse_and_execute(code)
	_assert(result["success"], "Should execute without errors")
	_assert_eq(result["variables"]["total"], 5, "total should be 5")
	_assert_eq(result["variables"]["i"], 4, "i should be 4 (last iteration value)")

func test_break_statement():
	print("\ntest_break_statement:")
	var code = """count = 0
while True:
    count = count + 1
    if count == 3:
        break
"""
	var result = _parse_and_execute(code)
	_assert(result["success"], "Should execute without errors")
	_assert_eq(result["variables"]["count"], 3, "count should be 3 (loop broken)")

func test_nested_loops():
	print("\ntest_nested_loops:")
	var code = """total = 0
for i in range(3):
    for j in range(3):
        total = total + 1
"""
	var result = _parse_and_execute(code)
	_assert(result["success"], "Should execute without errors")
	_assert_eq(result["variables"]["total"], 9, "total should be 9 (3x3)")

# ============================================
# Game Object Tests
# ============================================

func test_method_call():
	print("\ntest_method_call:")
	var car = MockCar.new()
	var result = _parse_and_execute("car.go()", {"car": car})
	_assert(result["success"], "Should execute without errors")
	_assert(car.call_log.size() > 0, "Should have called methods")
	_assert(car.call_log[0]["method"] == "go", "Should have called go()")

func test_method_with_arguments():
	print("\ntest_method_with_arguments:")
	var car = MockCar.new()
	var result = _parse_and_execute("car.set_speed(2.0)", {"car": car})
	_assert(result["success"], "Should execute without errors")

	var found_set_speed = false
	for call in car.call_log:
		if call["method"] == "set_speed":
			found_set_speed = true
			_assert_eq(call["args"][0], 2.0, "Speed argument should be 2.0")
	_assert(found_set_speed, "Should have called set_speed()")

func test_method_return_value():
	print("\ntest_method_return_value:")
	var car = MockCar.new()
	car._speed = 1.5
	var result = _parse_and_execute("speed = car.get_speed()", {"car": car})
	_assert(result["success"], "Should execute without errors")
	_assert_eq(result["variables"]["speed"], 1.5, "speed should be 1.5")

func test_undefined_method_error():
	print("\ntest_undefined_method_error:")
	var car = MockCar.new()
	var result = _parse_and_execute("car.fly()", {"car": car})
	_assert(not result["success"], "Should have errors")

	var has_attr_error = false
	for err in result["errors"]:
		if "AttributeError" in err["message"] or "method" in err["message"]:
			has_attr_error = true
	_assert(has_attr_error, "Should have AttributeError about missing method")

# ============================================
# Error Handling Tests
# ============================================

func test_division_by_zero():
	print("\ntest_division_by_zero:")
	var result = _parse_and_execute("x = 10 / 0")
	_assert(not result["success"], "Should have errors")

	var has_div_error = false
	for err in result["errors"]:
		if "division" in err["message"].to_lower() or "zero" in err["message"].to_lower():
			has_div_error = true
	_assert(has_div_error, "Should have ZeroDivisionError")

func test_type_error_arithmetic():
	print("\ntest_type_error_arithmetic:")
	var result = _parse_and_execute('x = "hello" + 5')
	_assert(not result["success"], "Should have errors")

	var has_type_error = false
	for err in result["errors"]:
		if "TypeError" in err["message"] or "type" in err["message"].to_lower():
			has_type_error = true
	_assert(has_type_error, "Should have TypeError")
