extends RefCounted
class_name PythonParser

## Python Parser for GoCars
## Parses a subset of Python syntax into an Abstract Syntax Tree (AST)
## Supports: variables, if/elif/else, while, for, break, function calls

# ============================================
# Signals
# ============================================
signal parse_error(error: String, line: int)

# ============================================
# Token Types
# ============================================
enum TokenType {
	# Literals
	NUMBER,
	STRING,
	# Identifiers and Keywords
	IDENTIFIER,
	KEYWORD,
	# Operators
	PLUS,        # +
	MINUS,       # -
	STAR,        # *
	SLASH,       # /
	EQ,          # =
	EQEQ,        # ==
	NE,          # !=
	LT,          # <
	GT,          # >
	LE,          # <=
	GE,          # >=
	# Delimiters
	LPAREN,      # (
	RPAREN,      # )
	COLON,       # :
	COMMA,       # ,
	DOT,         # .
	# Special
	NEWLINE,
	INDENT,
	DEDENT,
	EOF,
}

# Keywords
const KEYWORDS: Array = [
	"if", "elif", "else", "while", "for", "in", "range",
	"and", "or", "not", "True", "False", "break",
	"def", "return", "from", "import"  # NEW: Function and import support
]

# ============================================
# Token Class
# ============================================
class Token:
	var type: TokenType
	var value: Variant
	var line: int
	var column: int

	func _init(t: TokenType, v: Variant, l: int, c: int) -> void:
		type = t
		value = v
		line = l
		column = c

	func _to_string() -> String:
		return "Token(%s, %s, line %d)" % [TokenType.keys()[type], value, line]

# ============================================
# AST Node Types
# ============================================
enum ASTType {
	PROGRAM,
	# Statements
	EXPRESSION_STMT,
	ASSIGNMENT,
	IF_STMT,
	WHILE_STMT,
	FOR_STMT,
	BREAK_STMT,
	FUNCTION_DEF,     # NEW: def function_name(params): body
	RETURN_STMT,      # NEW: return value
	IMPORT_STMT,      # NEW: from module import names
	# Expressions
	BINARY_EXPR,
	UNARY_EXPR,
	CALL_EXPR,
	MEMBER_EXPR,
	IDENTIFIER,
	NUMBER_LITERAL,
	STRING_LITERAL,
	BOOLEAN_LITERAL,
}

# ============================================
# Parser State
# ============================================
var _source: String = ""
var _tokens: Array = []
var _current: int = 0
var _errors: Array = []

# Tokenizer state
var _pos: int = 0
var _line: int = 1
var _column: int = 1
var _indent_stack: Array = [0]  # Stack of indentation levels

# ============================================
# Public API
# ============================================

## Parse source code and return AST
func parse(source: String) -> Dictionary:
	_source = source
	_tokens = []
	_current = 0
	_errors = []
	_pos = 0
	_line = 1
	_column = 1
	_indent_stack = [0]

	# Tokenize
	_tokenize()

	if _errors.size() > 0:
		return {"type": ASTType.PROGRAM, "body": [], "errors": _errors}

	# Parse
	var body: Array = []
	while not _is_at_end():
		var stmt = _parse_statement()
		if stmt != null:
			body.append(stmt)
		if _errors.size() > 0:
			break

	return {"type": ASTType.PROGRAM, "body": body, "errors": _errors}

## Get list of tokens (for testing)
func tokenize(source: String) -> Array:
	_source = source
	_tokens = []
	_pos = 0
	_line = 1
	_column = 1
	_indent_stack = [0]
	_errors = []

	_tokenize()
	return _tokens

## Get errors
func get_errors() -> Array:
	return _errors

# ============================================
# Tokenizer
# ============================================

func _tokenize() -> void:
	while _pos < _source.length():
		_skip_whitespace_same_line()

		if _pos >= _source.length():
			break

		var c = _source[_pos]

		# Handle newlines and indentation
		if c == "\n":
			_add_token(TokenType.NEWLINE, "\\n")
			_advance()
			_handle_indentation()
			continue

		# Skip comments
		if c == "#":
			_skip_comment()
			continue

		# Handle carriage return
		if c == "\r":
			_advance()
			continue

		# Operators and delimiters
		if c == "+":
			_add_token(TokenType.PLUS, "+")
			_advance()
		elif c == "-":
			_add_token(TokenType.MINUS, "-")
			_advance()
		elif c == "*":
			_add_token(TokenType.STAR, "*")
			_advance()
		elif c == "/":
			_add_token(TokenType.SLASH, "/")
			_advance()
		elif c == "(":
			_add_token(TokenType.LPAREN, "(")
			_advance()
		elif c == ")":
			_add_token(TokenType.RPAREN, ")")
			_advance()
		elif c == ":":
			_add_token(TokenType.COLON, ":")
			_advance()
		elif c == ",":
			_add_token(TokenType.COMMA, ",")
			_advance()
		elif c == ".":
			_add_token(TokenType.DOT, ".")
			_advance()
		elif c == "=":
			if _peek_next() == "=":
				_add_token(TokenType.EQEQ, "==")
				_advance()
				_advance()
			else:
				_add_token(TokenType.EQ, "=")
				_advance()
		elif c == "!":
			if _peek_next() == "=":
				_add_token(TokenType.NE, "!=")
				_advance()
				_advance()
			else:
				_add_error("SyntaxError: unexpected character '!'")
		elif c == "<":
			if _peek_next() == "=":
				_add_token(TokenType.LE, "<=")
				_advance()
				_advance()
			else:
				_add_token(TokenType.LT, "<")
				_advance()
		elif c == ">":
			if _peek_next() == "=":
				_add_token(TokenType.GE, ">=")
				_advance()
				_advance()
			else:
				_add_token(TokenType.GT, ">")
				_advance()
		# Strings
		elif c == '"' or c == "'":
			_tokenize_string(c)
		# Numbers
		elif c.is_valid_int() or (c == "." and _peek_next().is_valid_int()):
			_tokenize_number()
		# Identifiers and keywords
		elif _is_identifier_start(c):
			_tokenize_identifier()
		else:
			_add_error("SyntaxError: unexpected character '%s'" % c)
			_advance()

	# Emit remaining DEDENTs
	while _indent_stack.size() > 1:
		_indent_stack.pop_back()
		_add_token(TokenType.DEDENT, "DEDENT")

	_add_token(TokenType.EOF, "")

func _handle_indentation() -> void:
	# Count spaces at start of line
	var spaces = 0
	while _pos < _source.length() and _source[_pos] == " ":
		spaces += 1
		_advance()

	# Handle tabs (convert to 4 spaces)
	while _pos < _source.length() and _source[_pos] == "\t":
		spaces += 4
		_advance()

	# Skip blank lines and comment-only lines
	if _pos >= _source.length() or _source[_pos] == "\n" or _source[_pos] == "#":
		return

	var current_indent = _indent_stack[_indent_stack.size() - 1]

	if spaces > current_indent:
		_indent_stack.append(spaces)
		_add_token(TokenType.INDENT, "INDENT")
	elif spaces < current_indent:
		while _indent_stack.size() > 1 and _indent_stack[_indent_stack.size() - 1] > spaces:
			_indent_stack.pop_back()
			_add_token(TokenType.DEDENT, "DEDENT")
		if _indent_stack[_indent_stack.size() - 1] != spaces:
			_add_error("IndentationError: unindent does not match any outer indentation level")

func _tokenize_string(quote: String) -> void:
	_advance()  # Skip opening quote
	var _start = _pos  # Track start position (for potential future use)
	var value = ""

	while _pos < _source.length() and _source[_pos] != quote:
		if _source[_pos] == "\n":
			_add_error("SyntaxError: EOL while scanning string literal")
			return
		if _source[_pos] == "\\" and _pos + 1 < _source.length():
			# Handle escape sequences
			_advance()
			match _source[_pos]:
				"n": value += "\n"
				"t": value += "\t"
				"\\": value += "\\"
				"'": value += "'"
				'"': value += '"'
				_: value += _source[_pos]
		else:
			value += _source[_pos]
		_advance()

	if _pos >= _source.length():
		_add_error("SyntaxError: EOL while scanning string literal")
		return

	_advance()  # Skip closing quote
	_add_token(TokenType.STRING, value)

func _tokenize_number() -> void:
	var start = _pos
	var has_dot = false

	while _pos < _source.length():
		var c = _source[_pos]
		if c.is_valid_int():
			_advance()
		elif c == "." and not has_dot:
			has_dot = true
			_advance()
		else:
			break

	var num_str = _source.substr(start, _pos - start)
	var value: Variant
	if has_dot:
		value = float(num_str)
	else:
		value = int(num_str)

	_add_token(TokenType.NUMBER, value)

func _tokenize_identifier() -> void:
	var start = _pos

	while _pos < _source.length() and _is_identifier_char(_source[_pos]):
		_advance()

	var name = _source.substr(start, _pos - start)

	if name in KEYWORDS:
		_add_token(TokenType.KEYWORD, name)
	else:
		_add_token(TokenType.IDENTIFIER, name)

func _skip_whitespace_same_line() -> void:
	while _pos < _source.length():
		var c = _source[_pos]
		if c == " " or c == "\t":
			_advance()
		else:
			break

func _skip_comment() -> void:
	while _pos < _source.length() and _source[_pos] != "\n":
		_advance()

func _advance() -> void:
	if _pos < _source.length():
		if _source[_pos] == "\n":
			_line += 1
			_column = 1
		else:
			_column += 1
		_pos += 1

func _peek_next() -> String:
	if _pos + 1 < _source.length():
		return _source[_pos + 1]
	return ""

func _is_identifier_start(c: String) -> bool:
	return (c >= "a" and c <= "z") or (c >= "A" and c <= "Z") or c == "_"

func _is_identifier_char(c: String) -> bool:
	return _is_identifier_start(c) or c.is_valid_int()

func _add_token(type: TokenType, value: Variant) -> void:
	_tokens.append(Token.new(type, value, _line, _column))

func _add_error(message: String) -> void:
	var error = "%s (line %d)" % [message, _line]
	_errors.append({"line": _line, "message": message, "full": error})
	parse_error.emit(message, _line)

# ============================================
# Parser Helpers
# ============================================

func _is_at_end() -> bool:
	return _current >= _tokens.size() or _peek().type == TokenType.EOF

func _peek() -> Token:
	if _current < _tokens.size():
		return _tokens[_current]
	return Token.new(TokenType.EOF, "", _line, 0)

func _peek_type() -> TokenType:
	return _peek().type

func _previous() -> Token:
	if _current > 0:
		return _tokens[_current - 1]
	return Token.new(TokenType.EOF, "", 0, 0)

func _advance_token() -> Token:
	if not _is_at_end():
		_current += 1
	return _previous()

func _check(type: TokenType) -> bool:
	if _is_at_end():
		return false
	return _peek_type() == type

func _check_keyword(keyword: String) -> bool:
	if _is_at_end():
		return false
	var token = _peek()
	return token.type == TokenType.KEYWORD and token.value == keyword

func _match(types: Array) -> bool:
	for type in types:
		if _check(type):
			_advance_token()
			return true
	return false

func _match_keyword(keyword: String) -> bool:
	if _check_keyword(keyword):
		_advance_token()
		return true
	return false

func _consume(type: TokenType, message: String) -> Token:
	if _check(type):
		return _advance_token()
	_add_error(message)
	return null

func _consume_keyword(keyword: String, message: String) -> Token:
	if _check_keyword(keyword):
		return _advance_token()
	_add_error(message)
	return null

func _skip_newlines() -> void:
	while _check(TokenType.NEWLINE):
		_advance_token()

# ============================================
# Parser - Statements
# ============================================

func _parse_statement() -> Variant:
	_skip_newlines()

	if _is_at_end():
		return null

	# Check for compound statements
	if _check_keyword("if"):
		return _parse_if_statement()
	if _check_keyword("while"):
		return _parse_while_statement()
	if _check_keyword("for"):
		return _parse_for_statement()
	if _check_keyword("break"):
		return _parse_break_statement()

	# NEW: Function and module statements
	if _check_keyword("def"):
		return _parse_function_def()
	if _check_keyword("return"):
		return _parse_return_stmt()
	if _check_keyword("from"):
		return _parse_import_stmt()

	# Simple statement (assignment or expression)
	return _parse_simple_statement()

func _parse_simple_statement() -> Variant:
	var expr = _parse_expression()
	if expr == null:
		return null

	# Check for assignment
	if _check(TokenType.EQ):
		if expr["type"] != ASTType.IDENTIFIER:
			_add_error("SyntaxError: cannot assign to expression")
			return null
		_advance_token()  # Consume =
		var value = _parse_expression()
		if value == null:
			return null
		_match([TokenType.NEWLINE])
		return {
			"type": ASTType.ASSIGNMENT,
			"name": expr["name"],
			"value": value,
			"line": expr.get("line", _line)
		}

	_match([TokenType.NEWLINE])
	return {
		"type": ASTType.EXPRESSION_STMT,
		"expression": expr,
		"line": expr.get("line", _line)
	}

func _parse_if_statement() -> Variant:
	var line = _peek().line
	_consume_keyword("if", "SyntaxError: expected 'if'")

	var condition = _parse_expression()
	if condition == null:
		return null

	if not _consume(TokenType.COLON, "SyntaxError: expected ':' after if condition"):
		return null

	_consume(TokenType.NEWLINE, "SyntaxError: expected newline after ':'")

	if not _consume(TokenType.INDENT, "IndentationError: expected an indented block after 'if'"):
		return null

	var then_body = _parse_block()

	# Parse elif clauses
	var elif_clauses: Array = []
	while _check_keyword("elif"):
		_advance_token()
		var elif_condition = _parse_expression()
		if elif_condition == null:
			return null
		if not _consume(TokenType.COLON, "SyntaxError: expected ':' after elif condition"):
			return null
		_consume(TokenType.NEWLINE, "SyntaxError: expected newline after ':'")
		if not _consume(TokenType.INDENT, "IndentationError: expected an indented block after 'elif'"):
			return null
		var elif_body = _parse_block()
		elif_clauses.append({"condition": elif_condition, "body": elif_body})

	# Parse else clause
	var else_body: Array = []
	if _check_keyword("else"):
		_advance_token()
		if not _consume(TokenType.COLON, "SyntaxError: expected ':' after else"):
			return null
		_consume(TokenType.NEWLINE, "SyntaxError: expected newline after ':'")
		if not _consume(TokenType.INDENT, "IndentationError: expected an indented block after 'else'"):
			return null
		else_body = _parse_block()

	return {
		"type": ASTType.IF_STMT,
		"condition": condition,
		"then_body": then_body,
		"elif_clauses": elif_clauses,
		"else_body": else_body,
		"line": line
	}

func _parse_while_statement() -> Variant:
	var line = _peek().line
	_consume_keyword("while", "SyntaxError: expected 'while'")

	var condition = _parse_expression()
	if condition == null:
		return null

	if not _consume(TokenType.COLON, "SyntaxError: expected ':' after while condition"):
		return null

	_consume(TokenType.NEWLINE, "SyntaxError: expected newline after ':'")

	if not _consume(TokenType.INDENT, "IndentationError: expected an indented block after 'while'"):
		return null

	var body = _parse_block()

	return {
		"type": ASTType.WHILE_STMT,
		"condition": condition,
		"body": body,
		"line": line
	}

func _parse_for_statement() -> Variant:
	var line = _peek().line
	_consume_keyword("for", "SyntaxError: expected 'for'")

	var var_token = _consume(TokenType.IDENTIFIER, "SyntaxError: expected variable name after 'for'")
	if var_token == null:
		return null
	var var_name = var_token.value

	if not _consume_keyword("in", "SyntaxError: expected 'in' after variable name"):
		return null

	if not _consume_keyword("range", "SyntaxError: expected 'range' after 'in'"):
		return null

	if not _consume(TokenType.LPAREN, "SyntaxError: expected '(' after 'range'"):
		return null

	var range_arg = _parse_expression()
	if range_arg == null:
		return null

	if not _consume(TokenType.RPAREN, "SyntaxError: expected ')' after range argument"):
		return null

	if not _consume(TokenType.COLON, "SyntaxError: expected ':' after for statement"):
		return null

	_consume(TokenType.NEWLINE, "SyntaxError: expected newline after ':'")

	if not _consume(TokenType.INDENT, "IndentationError: expected an indented block after 'for'"):
		return null

	var body = _parse_block()

	return {
		"type": ASTType.FOR_STMT,
		"variable": var_name,
		"range_end": range_arg,
		"body": body,
		"line": line
	}

func _parse_break_statement() -> Dictionary:
	var line = _peek().line
	_consume_keyword("break", "SyntaxError: expected 'break'")
	_match([TokenType.NEWLINE])
	return {
		"type": ASTType.BREAK_STMT,
		"line": line
	}

# ============================================
# NEW: Function and Import Parsing
# ============================================

func _parse_function_def() -> Variant:
	## Parse function definition: def func_name(param1, param2): body
	var line = _peek().line
	_consume_keyword("def", "SyntaxError: expected 'def'")

	# Function name
	if not _check(TokenType.IDENTIFIER):
		_add_error("SyntaxError: expected function name after 'def'")
		return null
	var func_name = _advance_token().value

	# Parameters
	if not _consume(TokenType.LPAREN, "SyntaxError: expected '(' after function name"):
		return null

	var parameters: Array = []
	if not _check(TokenType.RPAREN):
		# Parse first parameter
		if not _check(TokenType.IDENTIFIER):
			_add_error("SyntaxError: expected parameter name")
			return null
		parameters.append(_advance_token().value)

		# Parse additional parameters
		while _match([TokenType.COMMA]):
			if not _check(TokenType.IDENTIFIER):
				_add_error("SyntaxError: expected parameter name after ','")
				return null
			parameters.append(_advance_token().value)

	if not _consume(TokenType.RPAREN, "SyntaxError: expected ')' after parameters"):
		return null

	# Colon
	if not _consume(TokenType.COLON, "SyntaxError: expected ':' after function signature"):
		return null

	_consume(TokenType.NEWLINE, "SyntaxError: expected newline after ':'")

	# Body
	if not _consume(TokenType.INDENT, "IndentationError: expected an indented block after 'def'"):
		return null

	var body = _parse_block()

	return {
		"type": ASTType.FUNCTION_DEF,
		"name": func_name,
		"parameters": parameters,
		"body": body,
		"line": line
	}

func _parse_return_stmt() -> Dictionary:
	## Parse return statement: return value
	var line = _peek().line
	_consume_keyword("return", "SyntaxError: expected 'return'")

	# Optional return value
	var value = null
	if not _check(TokenType.NEWLINE) and not _is_at_end():
		value = _parse_expression()

	_match([TokenType.NEWLINE])

	return {
		"type": ASTType.RETURN_STMT,
		"value": value,
		"line": line
	}

func _parse_import_stmt() -> Variant:
	## Parse import statement: from module import name1, name2
	var line = _peek().line
	_consume_keyword("from", "SyntaxError: expected 'from'")

	# Module name (can be dotted: modules.helpers)
	if not _check(TokenType.IDENTIFIER):
		_add_error("SyntaxError: expected module name after 'from'")
		return null

	var module_parts: Array = []
	module_parts.append(_advance_token().value)

	# Handle dotted module names (e.g., modules.navigation)
	while _match([TokenType.DOT]):
		if not _check(TokenType.IDENTIFIER):
			_add_error("SyntaxError: expected identifier after '.'")
			return null
		module_parts.append(_advance_token().value)

	var module_name = ".".join(module_parts)

	# 'import' keyword
	if not _consume_keyword("import", "SyntaxError: expected 'import' after module name"):
		return null

	# Import names
	var import_names: Array = []

	if not _check(TokenType.IDENTIFIER):
		_add_error("SyntaxError: expected import name after 'import'")
		return null

	import_names.append(_advance_token().value)

	# Additional import names
	while _match([TokenType.COMMA]):
		if not _check(TokenType.IDENTIFIER):
			_add_error("SyntaxError: expected import name after ','")
			return null
		import_names.append(_advance_token().value)

	_match([TokenType.NEWLINE])

	return {
		"type": ASTType.IMPORT_STMT,
		"module": module_name,
		"names": import_names,
		"line": line
	}

func _parse_block() -> Array:
	var statements: Array = []

	while not _check(TokenType.DEDENT) and not _is_at_end():
		_skip_newlines()
		if _check(TokenType.DEDENT) or _is_at_end():
			break
		var stmt = _parse_statement()
		if stmt != null:
			statements.append(stmt)
		if _errors.size() > 0:
			break

	_match([TokenType.DEDENT])
	return statements

# ============================================
# Parser - Expressions
# ============================================

func _parse_expression() -> Variant:
	return _parse_or_expr()

func _parse_or_expr() -> Variant:
	var left = _parse_and_expr()
	if left == null:
		return null

	while _check_keyword("or"):
		var op_token = _advance_token()
		var right = _parse_and_expr()
		if right == null:
			return null
		left = {
			"type": ASTType.BINARY_EXPR,
			"operator": "or",
			"left": left,
			"right": right,
			"line": op_token.line
		}

	return left

func _parse_and_expr() -> Variant:
	var left = _parse_not_expr()
	if left == null:
		return null

	while _check_keyword("and"):
		var op_token = _advance_token()
		var right = _parse_not_expr()
		if right == null:
			return null
		left = {
			"type": ASTType.BINARY_EXPR,
			"operator": "and",
			"left": left,
			"right": right,
			"line": op_token.line
		}

	return left

func _parse_not_expr() -> Variant:
	if _check_keyword("not"):
		var op_token = _advance_token()
		var operand = _parse_not_expr()
		if operand == null:
			return null
		return {
			"type": ASTType.UNARY_EXPR,
			"operator": "not",
			"operand": operand,
			"line": op_token.line
		}

	return _parse_comparison()

func _parse_comparison() -> Variant:
	var left = _parse_term()
	if left == null:
		return null

	var comp_ops = [TokenType.EQEQ, TokenType.NE, TokenType.LT, TokenType.GT, TokenType.LE, TokenType.GE]

	while _match(comp_ops):
		var op_token = _previous()
		var op_str = _token_to_operator(op_token.type)
		var right = _parse_term()
		if right == null:
			return null
		left = {
			"type": ASTType.BINARY_EXPR,
			"operator": op_str,
			"left": left,
			"right": right,
			"line": op_token.line
		}

	return left

func _parse_term() -> Variant:
	var left = _parse_factor()
	if left == null:
		return null

	while _match([TokenType.PLUS, TokenType.MINUS]):
		var op_token = _previous()
		var op_str = "+" if op_token.type == TokenType.PLUS else "-"
		var right = _parse_factor()
		if right == null:
			return null
		left = {
			"type": ASTType.BINARY_EXPR,
			"operator": op_str,
			"left": left,
			"right": right,
			"line": op_token.line
		}

	return left

func _parse_factor() -> Variant:
	var left = _parse_unary()
	if left == null:
		return null

	while _match([TokenType.STAR, TokenType.SLASH]):
		var op_token = _previous()
		var op_str = "*" if op_token.type == TokenType.STAR else "/"
		var right = _parse_unary()
		if right == null:
			return null
		left = {
			"type": ASTType.BINARY_EXPR,
			"operator": op_str,
			"left": left,
			"right": right,
			"line": op_token.line
		}

	return left

func _parse_unary() -> Variant:
	if _match([TokenType.MINUS]):
		var op_token = _previous()
		var operand = _parse_unary()
		if operand == null:
			return null
		return {
			"type": ASTType.UNARY_EXPR,
			"operator": "-",
			"operand": operand,
			"line": op_token.line
		}

	return _parse_call()

func _parse_call() -> Variant:
	var expr = _parse_primary()
	if expr == null:
		return null

	while true:
		if _match([TokenType.DOT]):
			var name_token = _consume(TokenType.IDENTIFIER, "SyntaxError: expected method name after '.'")
			if name_token == null:
				return null

			if _match([TokenType.LPAREN]):
				# Method call
				var args = _parse_arguments()
				if not _consume(TokenType.RPAREN, "SyntaxError: expected ')' after arguments"):
					return null
				expr = {
					"type": ASTType.CALL_EXPR,
					"object": expr,
					"method": name_token.value,
					"arguments": args,
					"line": name_token.line
				}
			else:
				# Member access (property)
				expr = {
					"type": ASTType.MEMBER_EXPR,
					"object": expr,
					"property": name_token.value,
					"line": name_token.line
				}
		elif _match([TokenType.LPAREN]):
			# Direct function call (like range(5))
			var args = _parse_arguments()
			if not _consume(TokenType.RPAREN, "SyntaxError: expected ')' after arguments"):
				return null
			expr = {
				"type": ASTType.CALL_EXPR,
				"object": null,
				"method": expr.get("name", ""),
				"arguments": args,
				"line": expr.get("line", _line)
			}
		else:
			break

	return expr

func _parse_arguments() -> Array:
	var args: Array = []

	if not _check(TokenType.RPAREN):
		var arg = _parse_expression()
		if arg != null:
			args.append(arg)

		while _match([TokenType.COMMA]):
			arg = _parse_expression()
			if arg != null:
				args.append(arg)

	return args

func _parse_primary() -> Variant:
	# Number
	if _match([TokenType.NUMBER]):
		var token = _previous()
		return {
			"type": ASTType.NUMBER_LITERAL,
			"value": token.value,
			"line": token.line
		}

	# String
	if _match([TokenType.STRING]):
		var token = _previous()
		return {
			"type": ASTType.STRING_LITERAL,
			"value": token.value,
			"line": token.line
		}

	# Boolean
	if _check_keyword("True"):
		var token = _advance_token()
		return {
			"type": ASTType.BOOLEAN_LITERAL,
			"value": true,
			"line": token.line
		}

	if _check_keyword("False"):
		var token = _advance_token()
		return {
			"type": ASTType.BOOLEAN_LITERAL,
			"value": false,
			"line": token.line
		}

	# Identifier
	if _match([TokenType.IDENTIFIER]):
		var token = _previous()
		return {
			"type": ASTType.IDENTIFIER,
			"name": token.value,
			"line": token.line
		}

	# Parenthesized expression
	if _match([TokenType.LPAREN]):
		var expr = _parse_expression()
		if not _consume(TokenType.RPAREN, "SyntaxError: expected ')' after expression"):
			return null
		return expr

	_add_error("SyntaxError: unexpected token '%s'" % str(_peek().value))
	return null

func _token_to_operator(type: TokenType) -> String:
	match type:
		TokenType.EQEQ: return "=="
		TokenType.NE: return "!="
		TokenType.LT: return "<"
		TokenType.GT: return ">"
		TokenType.LE: return "<="
		TokenType.GE: return ">="
	return ""
