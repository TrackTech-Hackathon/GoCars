## Linter Rules for GoCars Python Linter
## Author: Claude Code
## Date: January 2026

class_name LinterRules

enum Severity { ERROR, WARNING, INFO, HINT }

# Syntax patterns to check
static var rules: Array[Dictionary] = [
	# Syntax errors
	{
		"id": "E001",
		"name": "unclosed_parenthesis",
		"severity": Severity.ERROR,
		"message": "Unclosed parenthesis",
		"check": "bracket_balance"
	},
	{
		"id": "E002",
		"name": "unclosed_string",
		"severity": Severity.ERROR,
		"message": "Unclosed string literal",
		"check": "string_balance"
	},
	{
		"id": "E003",
		"name": "invalid_syntax",
		"severity": Severity.ERROR,
		"message": "Invalid syntax",
		"check": "syntax_parse"
	},
	{
		"id": "E004",
		"name": "indentation_error",
		"severity": Severity.ERROR,
		"message": "Unexpected indentation",
		"check": "indentation"
	},
	{
		"id": "E005",
		"name": "missing_colon",
		"severity": Severity.ERROR,
		"message": "Expected ':' after statement",
		"check": "block_colon"
	},

	# Name errors
	{
		"id": "E101",
		"name": "undefined_name",
		"severity": Severity.ERROR,
		"message": "Undefined name '%s'",
		"check": "name_defined"
	},
	{
		"id": "E102",
		"name": "undefined_function",
		"severity": Severity.ERROR,
		"message": "Undefined function '%s'. Did you mean '%s'?",
		"check": "function_defined"
	},

	# Warnings
	{
		"id": "W001",
		"name": "unused_variable",
		"severity": Severity.WARNING,
		"message": "Variable '%s' is assigned but never used",
		"check": "variable_usage"
	},
	{
		"id": "W002",
		"name": "unused_import",
		"severity": Severity.WARNING,
		"message": "Imported module '%s' is never used",
		"check": "import_usage"
	},
	{
		"id": "W003",
		"name": "type_mismatch",
		"severity": Severity.WARNING,
		"message": "Expected %s but got %s",
		"check": "type_check"
	},
	{
		"id": "W004",
		"name": "unreachable_code",
		"severity": Severity.WARNING,
		"message": "Unreachable code after '%s'",
		"check": "reachability"
	},

	# Info/Hints
	{
		"id": "I001",
		"name": "could_simplify",
		"severity": Severity.INFO,
		"message": "This could be simplified to '%s'",
		"check": "simplification"
	},
	{
		"id": "I002",
		"name": "naming_convention",
		"severity": Severity.HINT,
		"message": "Consider using snake_case for variable names",
		"check": "naming"
	},
]

# Known game functions for validation (GoCars short API)
static var known_functions: Array[String] = [
	# Car movement
	"go", "stop", "turn", "move", "wait",
	# Speed
	"set_speed", "get_speed",
	# Road detection
	"front_road", "left_road", "right_road", "dead_end",
	# Car detection
	"front_car", "front_crash",
	# State
	"moving", "blocked", "at_cross", "at_end", "at_red", "turning",
	# Distance
	"dist",
	# Stoplight
	"red", "yellow", "green", "is_red", "is_yellow", "is_green", "state",
	# Boat
	"depart", "is_ready", "is_full", "get_passenger_count",
	# Python built-ins
	"print", "len", "range", "int", "str", "float", "list", "dict",
	"abs", "min", "max", "sum", "round", "type", "input"
]

static var python_keywords: Array[String] = [
	"if", "else", "elif", "while", "for", "def", "return", "class",
	"import", "from", "as", "try", "except", "finally", "with",
	"pass", "break", "continue", "and", "or", "not", "in", "is",
	"True", "False", "None", "lambda", "yield", "global", "nonlocal"
]
