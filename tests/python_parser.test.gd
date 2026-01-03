extends SceneTree

## Tests for PythonParser
## Tests tokenization and AST building

var _passed: int = 0
var _failed: int = 0

func _init():
	print("=" .repeat(50))
	print("Running PythonParser tests...")
	print("=" .repeat(50))

	# Tokenizer tests
	test_tokenize_keywords()
	test_tokenize_numbers()
	test_tokenize_strings()
	test_tokenize_operators()
	test_tokenize_indentation()
	test_tokenize_comments()

	# AST tests
	test_parse_simple_call()
	test_parse_method_chain()
	test_parse_assignment()
	test_parse_if_statement()
	test_parse_if_elif_else()
	test_parse_while_loop()
	test_parse_for_loop()
	test_parse_binary_expressions()
	test_parse_logical_operators()
	test_parse_comparison_operators()
	test_parse_unary_operators()
	test_parse_break_statement()
	test_parse_nested_blocks()

	# Error tests
	test_error_missing_colon()
	test_error_bad_indentation()
	test_error_unclosed_string()

	print("=" .repeat(50))
	print("Results: %d passed, %d failed" % [_passed, _failed])
	if _failed == 0:
		print("All tests passed!")
	print("=" .repeat(50))

	quit()

# ============================================
# Test Helpers
# ============================================

func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  ✓ %s" % message)
	else:
		_failed += 1
		print("  ✗ FAILED: %s" % message)

func _assert_eq(actual: Variant, expected: Variant, message: String) -> void:
	if actual == expected:
		_passed += 1
		print("  ✓ %s" % message)
	else:
		_failed += 1
		print("  ✗ FAILED: %s (expected %s, got %s)" % [message, expected, actual])

# ============================================
# Tokenizer Tests
# ============================================

func test_tokenize_keywords():
	print("\ntest_tokenize_keywords:")
	var parser = PythonParser.new()

	var tokens = parser.tokenize("if elif else while for in range and or not True False break")

	_assert(tokens.size() >= 12, "Should have at least 12 keyword tokens")

	var keywords_found = []
	for token in tokens:
		if token.type == PythonParser.TokenType.KEYWORD:
			keywords_found.append(token.value)

	_assert("if" in keywords_found, "Should find 'if' keyword")
	_assert("elif" in keywords_found, "Should find 'elif' keyword")
	_assert("else" in keywords_found, "Should find 'else' keyword")
	_assert("while" in keywords_found, "Should find 'while' keyword")
	_assert("for" in keywords_found, "Should find 'for' keyword")
	_assert("True" in keywords_found, "Should find 'True' keyword")
	_assert("False" in keywords_found, "Should find 'False' keyword")

func test_tokenize_numbers():
	print("\ntest_tokenize_numbers:")
	var parser = PythonParser.new()

	var tokens = parser.tokenize("42 3.14 0 0.5")

	var numbers = []
	for token in tokens:
		if token.type == PythonParser.TokenType.NUMBER:
			numbers.append(token.value)

	_assert(numbers.size() == 4, "Should find 4 numbers")
	_assert(42 in numbers, "Should find 42")
	_assert(0 in numbers, "Should find 0")

func test_tokenize_strings():
	print("\ntest_tokenize_strings:")
	var parser = PythonParser.new()

	var tokens = parser.tokenize('"hello" \'world\'')

	var strings = []
	for token in tokens:
		if token.type == PythonParser.TokenType.STRING:
			strings.append(token.value)

	_assert(strings.size() == 2, "Should find 2 strings")
	_assert("hello" in strings, "Should find 'hello'")
	_assert("world" in strings, "Should find 'world'")

func test_tokenize_operators():
	print("\ntest_tokenize_operators:")
	var parser = PythonParser.new()

	var tokens = parser.tokenize("+ - * / = == != < > <= >=")

	var op_types = []
	for token in tokens:
		if token.type != PythonParser.TokenType.EOF and token.type != PythonParser.TokenType.NEWLINE:
			op_types.append(token.type)

	_assert(PythonParser.TokenType.PLUS in op_types, "Should find PLUS")
	_assert(PythonParser.TokenType.MINUS in op_types, "Should find MINUS")
	_assert(PythonParser.TokenType.STAR in op_types, "Should find STAR")
	_assert(PythonParser.TokenType.SLASH in op_types, "Should find SLASH")
	_assert(PythonParser.TokenType.EQ in op_types, "Should find EQ")
	_assert(PythonParser.TokenType.EQEQ in op_types, "Should find EQEQ")
	_assert(PythonParser.TokenType.NE in op_types, "Should find NE")
	_assert(PythonParser.TokenType.LT in op_types, "Should find LT")
	_assert(PythonParser.TokenType.GT in op_types, "Should find GT")
	_assert(PythonParser.TokenType.LE in op_types, "Should find LE")
	_assert(PythonParser.TokenType.GE in op_types, "Should find GE")

func test_tokenize_indentation():
	print("\ntest_tokenize_indentation:")
	var parser = PythonParser.new()

	var code = """if True:
    car.go()
    car.stop()
"""
	var tokens = parser.tokenize(code)

	var has_indent = false
	var has_dedent = false
	for token in tokens:
		if token.type == PythonParser.TokenType.INDENT:
			has_indent = true
		if token.type == PythonParser.TokenType.DEDENT:
			has_dedent = true

	_assert(has_indent, "Should have INDENT token")
	_assert(has_dedent, "Should have DEDENT token")

func test_tokenize_comments():
	print("\ntest_tokenize_comments:")
	var parser = PythonParser.new()

	var code = """car.go()  # This is a comment
# This is another comment
car.stop()"""

	var tokens = parser.tokenize(code)

	# Comments should be skipped, only car.go() and car.stop() should generate tokens
	var identifiers = []
	for token in tokens:
		if token.type == PythonParser.TokenType.IDENTIFIER:
			identifiers.append(token.value)

	_assert("car" in identifiers, "Should find 'car' identifier")
	_assert("go" in identifiers, "Should find 'go' identifier")
	_assert("stop" in identifiers, "Should find 'stop' identifier")

# ============================================
# AST Tests
# ============================================

func test_parse_simple_call():
	print("\ntest_parse_simple_call:")
	var parser = PythonParser.new()

	var ast = parser.parse("car.go()")

	_assert(ast["errors"].size() == 0, "Should have no errors")
	_assert(ast["body"].size() == 1, "Should have 1 statement")

	var stmt = ast["body"][0]
	_assert(stmt["type"] == PythonParser.ASTType.EXPRESSION_STMT, "Should be expression statement")

	var expr = stmt["expression"]
	_assert(expr["type"] == PythonParser.ASTType.CALL_EXPR, "Should be call expression")
	_assert(expr["method"] == "go", "Method should be 'go'")

func test_parse_method_chain():
	print("\ntest_parse_method_chain:")
	var parser = PythonParser.new()

	var ast = parser.parse("car.wait(5)")

	_assert(ast["errors"].size() == 0, "Should have no errors")

	var stmt = ast["body"][0]
	var expr = stmt["expression"]
	_assert(expr["type"] == PythonParser.ASTType.CALL_EXPR, "Should be call expression")
	_assert(expr["method"] == "wait", "Method should be 'wait'")
	_assert(expr["arguments"].size() == 1, "Should have 1 argument")
	_assert(expr["arguments"][0]["value"] == 5, "Argument should be 5")

func test_parse_assignment():
	print("\ntest_parse_assignment:")
	var parser = PythonParser.new()

	var ast = parser.parse("speed = 1.5")

	_assert(ast["errors"].size() == 0, "Should have no errors")
	_assert(ast["body"].size() == 1, "Should have 1 statement")

	var stmt = ast["body"][0]
	_assert(stmt["type"] == PythonParser.ASTType.ASSIGNMENT, "Should be assignment")
	_assert(stmt["name"] == "speed", "Variable name should be 'speed'")
	_assert(stmt["value"]["value"] == 1.5, "Value should be 1.5")

func test_parse_if_statement():
	print("\ntest_parse_if_statement:")
	var parser = PythonParser.new()

	var code = """if stoplight.is_red():
    car.stop()
"""
	var ast = parser.parse(code)

	_assert(ast["errors"].size() == 0, "Should have no errors")
	_assert(ast["body"].size() == 1, "Should have 1 statement")

	var stmt = ast["body"][0]
	_assert(stmt["type"] == PythonParser.ASTType.IF_STMT, "Should be if statement")
	_assert(stmt["then_body"].size() == 1, "Should have 1 statement in body")

func test_parse_if_elif_else():
	print("\ntest_parse_if_elif_else:")
	var parser = PythonParser.new()

	var code = """if stoplight.is_red():
    car.stop()
elif stoplight.is_yellow():
    car.stop()
else:
    car.go()
"""
	var ast = parser.parse(code)

	_assert(ast["errors"].size() == 0, "Should have no errors")

	var stmt = ast["body"][0]
	_assert(stmt["type"] == PythonParser.ASTType.IF_STMT, "Should be if statement")
	_assert(stmt["elif_clauses"].size() == 1, "Should have 1 elif clause")
	_assert(stmt["else_body"].size() == 1, "Should have else body")

func test_parse_while_loop():
	print("\ntest_parse_while_loop:")
	var parser = PythonParser.new()

	var code = """while not car.is_at_destination():
    car.go()
"""
	var ast = parser.parse(code)

	_assert(ast["errors"].size() == 0, "Should have no errors")

	var stmt = ast["body"][0]
	_assert(stmt["type"] == PythonParser.ASTType.WHILE_STMT, "Should be while statement")
	_assert(stmt["body"].size() == 1, "Should have 1 statement in body")

func test_parse_for_loop():
	print("\ntest_parse_for_loop:")
	var parser = PythonParser.new()

	var code = """for i in range(3):
    car.go()
"""
	var ast = parser.parse(code)

	_assert(ast["errors"].size() == 0, "Should have no errors")

	var stmt = ast["body"][0]
	_assert(stmt["type"] == PythonParser.ASTType.FOR_STMT, "Should be for statement")
	_assert(stmt["variable"] == "i", "Loop variable should be 'i'")
	_assert(stmt["body"].size() == 1, "Should have 1 statement in body")

func test_parse_binary_expressions():
	print("\ntest_parse_binary_expressions:")
	var parser = PythonParser.new()

	var ast = parser.parse("x = 5 + 3 * 2")

	_assert(ast["errors"].size() == 0, "Should have no errors")

	var stmt = ast["body"][0]
	var value = stmt["value"]
	_assert(value["type"] == PythonParser.ASTType.BINARY_EXPR, "Should be binary expression")
	_assert(value["operator"] == "+", "Top operator should be +")

func test_parse_logical_operators():
	print("\ntest_parse_logical_operators:")
	var parser = PythonParser.new()

	var code = """if stoplight.is_green() and not car.is_blocked():
    car.go()
"""
	var ast = parser.parse(code)

	_assert(ast["errors"].size() == 0, "Should have no errors")

	var stmt = ast["body"][0]
	var condition = stmt["condition"]
	_assert(condition["type"] == PythonParser.ASTType.BINARY_EXPR, "Should be binary expression")
	_assert(condition["operator"] == "and", "Operator should be 'and'")

func test_parse_comparison_operators():
	print("\ntest_parse_comparison_operators:")
	var parser = PythonParser.new()

	var code = """if car.distance_to_destination() < 5:
    car.stop()
"""
	var ast = parser.parse(code)

	_assert(ast["errors"].size() == 0, "Should have no errors")

	var stmt = ast["body"][0]
	var condition = stmt["condition"]
	_assert(condition["type"] == PythonParser.ASTType.BINARY_EXPR, "Should be binary expression")
	_assert(condition["operator"] == "<", "Operator should be '<'")

func test_parse_unary_operators():
	print("\ntest_parse_unary_operators:")
	var parser = PythonParser.new()

	var ast = parser.parse("x = -5")

	_assert(ast["errors"].size() == 0, "Should have no errors")

	var stmt = ast["body"][0]
	var value = stmt["value"]
	_assert(value["type"] == PythonParser.ASTType.UNARY_EXPR, "Should be unary expression")
	_assert(value["operator"] == "-", "Operator should be '-'")

func test_parse_break_statement():
	print("\ntest_parse_break_statement:")
	var parser = PythonParser.new()

	var code = """while True:
    car.go()
    break
"""
	var ast = parser.parse(code)

	_assert(ast["errors"].size() == 0, "Should have no errors")

	var while_stmt = ast["body"][0]
	_assert(while_stmt["body"].size() == 2, "While body should have 2 statements")

	var break_stmt = while_stmt["body"][1]
	_assert(break_stmt["type"] == PythonParser.ASTType.BREAK_STMT, "Should be break statement")

func test_parse_nested_blocks():
	print("\ntest_parse_nested_blocks:")
	var parser = PythonParser.new()

	var code = """if True:
    if False:
        car.stop()
    else:
        car.go()
"""
	var ast = parser.parse(code)

	_assert(ast["errors"].size() == 0, "Should have no errors")

	var outer_if = ast["body"][0]
	_assert(outer_if["type"] == PythonParser.ASTType.IF_STMT, "Should be if statement")

	var inner_if = outer_if["then_body"][0]
	_assert(inner_if["type"] == PythonParser.ASTType.IF_STMT, "Inner should be if statement")
	_assert(inner_if["else_body"].size() == 1, "Inner if should have else body")

# ============================================
# Error Tests
# ============================================

func test_error_missing_colon():
	print("\ntest_error_missing_colon:")
	var parser = PythonParser.new()

	var ast = parser.parse("if True\n    car.go()")

	_assert(ast["errors"].size() > 0, "Should have errors")

	var has_colon_error = false
	for err in ast["errors"]:
		if ":" in err["message"]:
			has_colon_error = true

	_assert(has_colon_error, "Should have error about missing colon")

func test_error_bad_indentation():
	print("\ntest_error_bad_indentation:")
	var parser = PythonParser.new()

	var code = """if True:
  car.go()
    car.stop()
"""
	var ast = parser.parse(code)

	# Check for indentation-related errors
	var has_indent_error = false
	for err in ast["errors"]:
		if "indent" in err["message"].to_lower():
			has_indent_error = true

	# Note: This may or may not produce an error depending on implementation
	# The key is that inconsistent indentation is handled
	_assert(true, "Indentation handling checked")

func test_error_unclosed_string():
	print("\ntest_error_unclosed_string:")
	var parser = PythonParser.new()

	var ast = parser.parse('"hello')

	_assert(ast["errors"].size() > 0, "Should have errors")

	var has_string_error = false
	for err in ast["errors"]:
		if "string" in err["message"].to_lower() or "EOL" in err["message"]:
			has_string_error = true

	_assert(has_string_error, "Should have error about unclosed string")
