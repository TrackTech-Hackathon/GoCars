# linter_rules.gd
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

# Known game functions for validation (using short API names)
static var known_functions: Array[String] = [
	# Car movement functions
	"go", "stop", "turn", "move", "wait",
	# Car speed functions
	"set_speed", "get_speed",
	# Car road detection
	"front_road", "left_road", "right_road", "dead_end",
	# Car detection
	"front_car", "front_crash",
	# Car state
	"moving", "blocked", "at_cross", "at_end", "at_red", "turning",
	# Car distance
	"dist",
	# Stoplight control
	"red", "yellow", "green",
	# Stoplight state
	"is_red", "is_yellow", "is_green", "state",
	# Boat control
	"depart",
	# Boat state
	"is_ready", "is_full", "get_passenger_count",
	# Built-in Python functions
	"print", "len", "range", "int", "str", "float",
	"abs", "min", "max", "sum", "round", "type"
]

static var python_keywords: Array[String] = [
	"if", "else", "elif", "while", "for", "def", "return", "class",
	"import", "from", "as", "try", "except", "finally", "with",
	"pass", "break", "continue", "and", "or", "not", "in", "is",
	"True", "False", "None", "lambda", "yield", "global", "nonlocal"
]

# Common string constants used in the game (for turn directions, states, etc.)
# These are often passed as string arguments and should not trigger undefined name errors
static var known_string_constants: Array[String] = [
	"left", "right",  # Turn directions
	"red", "yellow", "green",  # Stoplight colors
	"north", "south", "east", "west"  # Cardinal directions
]
