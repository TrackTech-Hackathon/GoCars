extends RefCounted
class_name PythonInterpreter

## Python Interpreter for GoCars
## Executes AST produced by PythonParser
## Supports STEP-BASED execution for proper loop handling
## Each call to step() executes one statement/iteration

# ============================================
# Signals
# ============================================
signal execution_started()
signal execution_line(line_number: int)
signal execution_error(error: String, line: int)
signal execution_completed()
signal command_executed(object_name: String, method_name: String, args: Array)

# ============================================
# Constants
# ============================================
const MAX_LOOP_ITERATIONS: int = 10000
const MAX_EXECUTION_TIME_MS: int = 10000  # 10 seconds

# ============================================
# State
# ============================================
var _variables: Dictionary = {}
var _game_objects: Dictionary = {}  # name -> object reference
var _errors: Array = []
var _break_requested: bool = false
var _execution_start_time: int = 0
var _current_line: int = 0
var _last_emitted_line: int = -1  # Track last emitted line to avoid duplicate signals

# Step-based execution state
var _execution_stack: Array = []  # Stack of execution contexts
var _is_running: bool = false
var _is_paused: bool = false
var _current_ast: Dictionary = {}

# ============================================
# Execution Context Types
# ============================================
enum ContextType {
	BLOCK,      # Executing a block of statements
	WHILE_LOOP, # While loop - re-evaluate condition each step
	FOR_LOOP,   # For loop - iterate through range
	IF_STMT     # If statement (handled immediately, not pushed)
}

# ============================================
# Public API
# ============================================

## Register a game object (car, stoplight, boat) for the interpreter to control
func register_object(name: String, object: Variant) -> void:
	_game_objects[name] = object

## Unregister a game object
func unregister_object(name: String) -> void:
	_game_objects.erase(name)

## Clear all registered objects
func clear_objects() -> void:
	_game_objects.clear()

## Initialize execution with AST (call once, then call step() repeatedly)
func start_execution(ast: Dictionary) -> void:
	_variables.clear()
	_errors.clear()
	_break_requested = false
	_execution_start_time = Time.get_ticks_msec()
	_current_line = 0
	_last_emitted_line = -1  # Reset line tracking
	_execution_stack.clear()
	_current_ast = ast
	_is_running = true
	_is_paused = false

	execution_started.emit()

	# Check for parse errors
	if ast.has("errors") and ast["errors"].size() > 0:
		for err in ast["errors"]:
			_errors.append(err)
		_is_running = false
		return

	# Push the main program body onto the execution stack
	if ast.has("body") and ast["body"].size() > 0:
		_push_block_context(ast["body"])


## Execute one step (one statement or one loop iteration)
## Returns true if there's more to execute, false if done
func step() -> bool:
	if not _is_running or _is_paused:
		return false

	if _execution_stack.size() == 0:
		# Execution complete
		_is_running = false
		execution_completed.emit()
		return false

	if _errors.size() > 0:
		_is_running = false
		return false

	if _check_timeout():
		_add_error("RuntimeError: infinite loop detected (exceeded 10s)", _current_line)
		_is_running = false
		return false

	# Check if car is busy (turning or waiting) - don't execute next step yet
	if _is_car_busy():
		# Reset timeout while waiting for car action to complete
		_execution_start_time = Time.get_ticks_msec()
		return true  # Still running, but wait for car to finish

	# Get current context and execute one step
	var context = _execution_stack.back()
	_execute_context_step(context)

	return _execution_stack.size() > 0 and _is_running


## Check if the car is busy (turning, waiting, etc.)
func _is_car_busy() -> bool:
	if "car" in _game_objects:
		var car = _game_objects["car"]
		if car != null and is_instance_valid(car):
			# Check if car is turning
			if car.has_method("is_turning") and car.is_turning():
				return true
			# Check if car is waiting
			if car.has_method("is_waiting") and car.is_waiting:
				return true
	return false


## Check if the car has reached a dead end (no roads in any direction)
## This allows loops to complete naturally when navigating edited roads
func _is_car_at_dead_end() -> bool:
	if "car" in _game_objects:
		var car = _game_objects["car"]
		if car != null and is_instance_valid(car):
			if car.has_method("is_at_dead_end") and car.is_at_dead_end():
				# Car is at dead end and not moving - navigation complete
				if car.has_method("is_vehicle_moving") and not car.is_vehicle_moving():
					return true
	return false


## Check if the car has reached its destination
## This allows loops to complete naturally when car arrives at destination
func _is_car_at_destination() -> bool:
	if "car" in _game_objects:
		var car = _game_objects["car"]
		if car != null and is_instance_valid(car):
			if car.has_method("is_at_destination") and car.is_at_destination():
				return true
	return false


## Check if execution is still running
func is_running() -> bool:
	return _is_running and _execution_stack.size() > 0


## Check if there are errors
func has_errors() -> bool:
	return _errors.size() > 0


## Stop execution
func stop_execution() -> void:
	_is_running = false
	_execution_stack.clear()


## Pause execution
func pause_execution() -> void:
	_is_paused = true


## Resume execution
func resume_execution() -> void:
	_is_paused = false


## Legacy execute function (runs all at once - for backwards compatibility)
func execute(ast: Dictionary) -> Dictionary:
	_variables.clear()
	_errors.clear()
	_break_requested = false
	_execution_start_time = Time.get_ticks_msec()
	_current_line = 0
	_last_emitted_line = -1  # Reset line tracking

	execution_started.emit()

	# Check for parse errors
	if ast.has("errors") and ast["errors"].size() > 0:
		for err in ast["errors"]:
			_errors.append(err)
		return {"success": false, "errors": _errors}

	# Execute program body
	if ast.has("body"):
		for stmt in ast["body"]:
			if _break_requested or _errors.size() > 0:
				break
			if _check_timeout():
				_add_error("RuntimeError: infinite loop detected (exceeded 10s)", _current_line)
				break
			_execute_statement(stmt)

	execution_completed.emit()

	return {
		"success": _errors.size() == 0,
		"errors": _errors,
		"variables": _variables.duplicate()
	}


## Get current variables (for debugging)
func get_variables() -> Dictionary:
	return _variables.duplicate()

## Get errors
func get_errors() -> Array:
	return _errors

# ============================================
# Context Management
# ============================================

## Push a block context (list of statements to execute)
func _push_block_context(statements: Array) -> void:
	if statements.size() == 0:
		return
	_execution_stack.push_back({
		"type": ContextType.BLOCK,
		"statements": statements,
		"index": 0
	})


## Push a while loop context
func _push_while_context(condition: Dictionary, body: Array, line: int) -> void:
	_execution_stack.push_back({
		"type": ContextType.WHILE_LOOP,
		"condition": condition,
		"body": body,
		"iterations": 0,
		"line": line
	})


## Push a for loop context
func _push_for_context(variable: String, range_end: int, body: Array, line: int) -> void:
	_execution_stack.push_back({
		"type": ContextType.FOR_LOOP,
		"variable": variable,
		"range_end": range_end,
		"current": 0,
		"body": body,
		"line": line
	})


# ============================================
# Step Execution
# ============================================

## Execute one step of the current context
func _execute_context_step(context: Dictionary) -> void:
	match context["type"]:
		ContextType.BLOCK:
			_execute_block_step(context)
		ContextType.WHILE_LOOP:
			_execute_while_step(context)
		ContextType.FOR_LOOP:
			_execute_for_step(context)


## Execute one step of a block (one statement)
func _execute_block_step(context: Dictionary) -> void:
	var statements = context["statements"]
	var index = context["index"]

	if index >= statements.size() or _break_requested:
		# Block complete, pop context
		_execution_stack.pop_back()
		return

	var stmt = statements[index]
	context["index"] = index + 1

	# Execute the statement (may push new contexts)
	_execute_statement_step(stmt)


## Execute one iteration of a while loop
func _execute_while_step(context: Dictionary) -> void:
	# Check for break
	if _break_requested:
		_break_requested = false
		_execution_stack.pop_back()
		return

	# Check if car has reached destination (natural termination)
	if _is_car_at_destination():
		# Car has reached its destination - complete the loop
		_execution_stack.pop_back()
		return

	# Check if car is at dead end (natural termination for navigation loops)
	if _is_car_at_dead_end():
		# Car has navigated to the end of the road - complete the loop
		_execution_stack.pop_back()
		return

	context["iterations"] += 1
	_current_line = context.get("line", _current_line)

	# Check iteration limit
	if context["iterations"] > MAX_LOOP_ITERATIONS:
		_add_error("RuntimeError: maximum loop iterations exceeded", _current_line)
		_execution_stack.pop_back()
		return

	# Evaluate condition
	var condition_result = _evaluate_expression(context["condition"])
	if _errors.size() > 0:
		_execution_stack.pop_back()
		return

	if _is_truthy(condition_result):
		# Condition true, push body for execution
		# Body will be executed, then we'll come back to while_step
		if context["body"].size() > 0:
			_push_block_context(context["body"])
	else:
		# Condition false, loop done
		_execution_stack.pop_back()


## Execute one iteration of a for loop
func _execute_for_step(context: Dictionary) -> void:
	# Check for break
	if _break_requested:
		_break_requested = false
		_execution_stack.pop_back()
		return

	var current = context["current"]
	var range_end = context["range_end"]
	_current_line = context.get("line", _current_line)

	if current >= range_end:
		# Loop complete
		_execution_stack.pop_back()
		return

	# Set loop variable
	_variables[context["variable"]] = current
	context["current"] = current + 1

	# Push body for execution
	if context["body"].size() > 0:
		_push_block_context(context["body"])


## Execute a single statement (may push contexts for loops)
func _execute_statement_step(stmt: Dictionary) -> void:
	if stmt == null:
		return

	_current_line = stmt.get("line", _current_line)
	# Only emit if line actually changed (prevents flickering)
	if _current_line != _last_emitted_line:
		_last_emitted_line = _current_line
		execution_line.emit(_current_line)

	var stmt_type = stmt.get("type", -1)

	match stmt_type:
		PythonParser.ASTType.EXPRESSION_STMT:
			_execute_expression_stmt(stmt)
		PythonParser.ASTType.ASSIGNMENT:
			_execute_assignment(stmt)
		PythonParser.ASTType.IF_STMT:
			_execute_if_stmt_step(stmt)
		PythonParser.ASTType.WHILE_STMT:
			# Push while context - will be executed on next step
			_push_while_context(stmt["condition"], stmt["body"], _current_line)
		PythonParser.ASTType.FOR_STMT:
			_execute_for_stmt_init(stmt)
		PythonParser.ASTType.BREAK_STMT:
			_break_requested = true
		_:
			_add_error("RuntimeError: unknown statement type", _current_line)


## Execute if statement (immediately evaluates and pushes appropriate block)
func _execute_if_stmt_step(stmt: Dictionary) -> void:
	var condition = _evaluate_expression(stmt["condition"])
	if _errors.size() > 0:
		return

	if _is_truthy(condition):
		if stmt["then_body"].size() > 0:
			_push_block_context(stmt["then_body"])
		return

	# Check elif clauses
	for elif_clause in stmt.get("elif_clauses", []):
		var elif_condition = _evaluate_expression(elif_clause["condition"])
		if _errors.size() > 0:
			return
		if _is_truthy(elif_condition):
			if elif_clause["body"].size() > 0:
				_push_block_context(elif_clause["body"])
			return

	# Execute else clause
	if stmt.get("else_body", []).size() > 0:
		_push_block_context(stmt["else_body"])


## Initialize for loop (evaluate range and push context)
func _execute_for_stmt_init(stmt: Dictionary) -> void:
	var var_name = stmt["variable"]
	var range_end = _evaluate_expression(stmt["range_end"])

	if _errors.size() > 0:
		return

	if not (range_end is int or range_end is float):
		_add_error("TypeError: range() requires an integer, got %s" % typeof(range_end), _current_line)
		return

	var end_val = int(range_end)
	_push_for_context(var_name, end_val, stmt["body"], _current_line)


# ============================================
# Statement Execution (Legacy - for execute())
# ============================================

func _execute_statement(stmt: Dictionary) -> void:
	if stmt == null:
		return

	_current_line = stmt.get("line", _current_line)
	# Only emit if line actually changed (prevents flickering)
	if _current_line != _last_emitted_line:
		_last_emitted_line = _current_line
		execution_line.emit(_current_line)

	if _check_timeout():
		_add_error("RuntimeError: infinite loop detected (exceeded 10s)", _current_line)
		return

	var stmt_type = stmt.get("type", -1)

	match stmt_type:
		PythonParser.ASTType.EXPRESSION_STMT:
			_execute_expression_stmt(stmt)
		PythonParser.ASTType.ASSIGNMENT:
			_execute_assignment(stmt)
		PythonParser.ASTType.IF_STMT:
			_execute_if_stmt(stmt)
		PythonParser.ASTType.WHILE_STMT:
			_execute_while_stmt(stmt)
		PythonParser.ASTType.FOR_STMT:
			_execute_for_stmt(stmt)
		PythonParser.ASTType.BREAK_STMT:
			_break_requested = true
		_:
			_add_error("RuntimeError: unknown statement type", _current_line)

func _execute_expression_stmt(stmt: Dictionary) -> void:
	_evaluate_expression(stmt["expression"])

func _execute_assignment(stmt: Dictionary) -> void:
	var var_name = stmt["name"]
	var value = _evaluate_expression(stmt["value"])
	if _errors.size() == 0:
		_variables[var_name] = value

func _execute_if_stmt(stmt: Dictionary) -> void:
	var condition = _evaluate_expression(stmt["condition"])
	if _errors.size() > 0:
		return

	if _is_truthy(condition):
		_execute_block(stmt["then_body"])
		return

	# Check elif clauses
	for elif_clause in stmt.get("elif_clauses", []):
		var elif_condition = _evaluate_expression(elif_clause["condition"])
		if _errors.size() > 0:
			return
		if _is_truthy(elif_condition):
			_execute_block(elif_clause["body"])
			return

	# Execute else clause
	if stmt.get("else_body", []).size() > 0:
		_execute_block(stmt["else_body"])

func _execute_while_stmt(stmt: Dictionary) -> void:
	var iterations = 0
	_break_requested = false

	while true:
		if _check_timeout():
			_add_error("RuntimeError: infinite loop detected (exceeded 10s)", _current_line)
			return

		iterations += 1
		if iterations > MAX_LOOP_ITERATIONS:
			_add_error("RuntimeError: maximum loop iterations exceeded", _current_line)
			return

		var condition = _evaluate_expression(stmt["condition"])
		if _errors.size() > 0:
			return

		if not _is_truthy(condition):
			break

		_execute_block(stmt["body"])

		if _break_requested:
			_break_requested = false
			break

		if _errors.size() > 0:
			break

func _execute_for_stmt(stmt: Dictionary) -> void:
	var var_name = stmt["variable"]
	var range_end = _evaluate_expression(stmt["range_end"])

	if _errors.size() > 0:
		return

	if not (range_end is int or range_end is float):
		_add_error("TypeError: range() requires an integer, got %s" % typeof(range_end), _current_line)
		return

	var end_val = int(range_end)
	_break_requested = false

	for i in range(end_val):
		if _check_timeout():
			_add_error("RuntimeError: infinite loop detected (exceeded 10s)", _current_line)
			return

		_variables[var_name] = i
		_execute_block(stmt["body"])

		if _break_requested:
			_break_requested = false
			break

		if _errors.size() > 0:
			break

func _execute_block(statements: Array) -> void:
	for stmt in statements:
		if _break_requested or _errors.size() > 0:
			break
		if _check_timeout():
			_add_error("RuntimeError: infinite loop detected (exceeded 10s)", _current_line)
			break
		_execute_statement(stmt)

# ============================================
# Expression Evaluation
# ============================================

func _evaluate_expression(expr: Dictionary) -> Variant:
	if expr == null:
		return null

	_current_line = expr.get("line", _current_line)

	var expr_type = expr.get("type", -1)

	match expr_type:
		PythonParser.ASTType.NUMBER_LITERAL:
			return expr["value"]
		PythonParser.ASTType.STRING_LITERAL:
			return expr["value"]
		PythonParser.ASTType.BOOLEAN_LITERAL:
			return expr["value"]
		PythonParser.ASTType.IDENTIFIER:
			return _evaluate_identifier(expr)
		PythonParser.ASTType.BINARY_EXPR:
			return _evaluate_binary_expr(expr)
		PythonParser.ASTType.UNARY_EXPR:
			return _evaluate_unary_expr(expr)
		PythonParser.ASTType.CALL_EXPR:
			return _evaluate_call_expr(expr)
		PythonParser.ASTType.MEMBER_EXPR:
			return _evaluate_member_expr(expr)
		_:
			_add_error("RuntimeError: unknown expression type", _current_line)
			return null

func _evaluate_identifier(expr: Dictionary) -> Variant:
	var ident_name = expr["name"]

	# Check if it's a game object
	if ident_name in _game_objects:
		return _game_objects[ident_name]

	# Check if it's a variable
	if ident_name in _variables:
		return _variables[ident_name]

	_add_error("NameError: '%s' is not defined" % ident_name, _current_line)
	return null

func _evaluate_binary_expr(expr: Dictionary) -> Variant:
	var op = expr["operator"]
	var left = _evaluate_expression(expr["left"])
	if _errors.size() > 0:
		return null

	# Short-circuit evaluation for 'and' and 'or'
	if op == "and":
		if not _is_truthy(left):
			return false
		var right_and = _evaluate_expression(expr["right"])
		return _is_truthy(right_and)

	if op == "or":
		if _is_truthy(left):
			return true
		var right_or = _evaluate_expression(expr["right"])
		return _is_truthy(right_or)

	var right = _evaluate_expression(expr["right"])
	if _errors.size() > 0:
		return null

	match op:
		"+":
			if left is String and right is String:
				return left + right
			if (left is int or left is float) and (right is int or right is float):
				return left + right
			_add_error("TypeError: unsupported operand type(s) for +", _current_line)
			return null
		"-":
			if (left is int or left is float) and (right is int or right is float):
				return left - right
			_add_error("TypeError: unsupported operand type(s) for -", _current_line)
			return null
		"*":
			if (left is int or left is float) and (right is int or right is float):
				return left * right
			_add_error("TypeError: unsupported operand type(s) for *", _current_line)
			return null
		"/":
			if (left is int or left is float) and (right is int or right is float):
				if right == 0:
					_add_error("ZeroDivisionError: division by zero", _current_line)
					return null
				return float(left) / float(right)
			_add_error("TypeError: unsupported operand type(s) for /", _current_line)
			return null
		"==":
			return left == right
		"!=":
			return left != right
		"<":
			return left < right
		">":
			return left > right
		"<=":
			return left <= right
		">=":
			return left >= right
		_:
			_add_error("RuntimeError: unknown operator '%s'" % op, _current_line)
			return null

func _evaluate_unary_expr(expr: Dictionary) -> Variant:
	var op = expr["operator"]
	var operand = _evaluate_expression(expr["operand"])

	if _errors.size() > 0:
		return null

	match op:
		"-":
			if operand is int or operand is float:
				return -operand
			_add_error("TypeError: bad operand type for unary -", _current_line)
			return null
		"not":
			return not _is_truthy(operand)
		_:
			_add_error("RuntimeError: unknown unary operator '%s'" % op, _current_line)
			return null

func _evaluate_call_expr(expr: Dictionary) -> Variant:
	var obj = expr.get("object")
	var method = expr["method"]
	var args_exprs = expr.get("arguments", [])

	# Evaluate arguments
	var args: Array = []
	for arg_expr in args_exprs:
		var val = _evaluate_expression(arg_expr)
		if _errors.size() > 0:
			return null
		args.append(val)

	# If object is null, it might be a built-in function like range()
	if obj == null:
		if method == "range":
			# range() returns array, but we handle it in for loop
			if args.size() > 0:
				return args[0]
			return 0
		_add_error("NameError: '%s' is not defined" % method, _current_line)
		return null

	# Evaluate object
	var obj_val = _evaluate_expression(obj)
	if _errors.size() > 0:
		return null

	if obj_val == null:
		return null

	# Get object name for signal
	var obj_name = ""
	if obj.get("type") == PythonParser.ASTType.IDENTIFIER:
		obj_name = obj.get("name", "")

	# Call method on game object
	return _call_method(obj_val, obj_name, method, args)

func _evaluate_member_expr(expr: Dictionary) -> Variant:
	var obj = _evaluate_expression(expr["object"])
	if _errors.size() > 0:
		return null

	var property = expr["property"]

	# Handle member access (property read)
	if obj != null and obj.has_method("get"):
		if obj.has(property):
			return obj.get(property)

	_add_error("AttributeError: object has no attribute '%s'" % property, _current_line)
	return null

func _call_method(obj: Variant, obj_name: String, method: String, args: Array) -> Variant:
	# Emit command signal for the simulation engine
	command_executed.emit(obj_name, method, args)

	# Check if object has the method
	if obj == null:
		_add_error("AttributeError: cannot call method on null", _current_line)
		return null

	if not obj.has_method(method):
		_add_error("AttributeError: '%s' object has no method '%s'" % [obj_name, method], _current_line)
		return null

	# Call the method based on argument count
	var result: Variant = null
	match args.size():
		0:
			result = obj.call(method)
		1:
			result = obj.call(method, args[0])
		2:
			result = obj.call(method, args[0], args[1])
		3:
			result = obj.call(method, args[0], args[1], args[2])
		_:
			result = obj.callv(method, args)

	return result

# ============================================
# Helper Functions
# ============================================

func _is_truthy(value: Variant) -> bool:
	if value == null:
		return false
	if value is bool:
		return value
	if value is int:
		return value != 0
	if value is float:
		return value != 0.0
	if value is String:
		return value.length() > 0
	return true

func _check_timeout() -> bool:
	var elapsed = Time.get_ticks_msec() - _execution_start_time
	return elapsed > MAX_EXECUTION_TIME_MS

func _add_error(message: String, line: int) -> void:
	var error = "%s (line %d)" % [message, line]
	_errors.append({"line": line, "message": message, "full": error})
	execution_error.emit(message, line)
