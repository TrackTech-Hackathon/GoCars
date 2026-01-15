## Performance Metrics for Code Evaluation
## Author: Claude Code
## Date: January 2026

class_name PerformanceMetrics
extends RefCounted

var execution_steps: int = 0
var total_time_ms: float = 0.0
var lines_of_code: int = 0
var function_calls: Dictionary = {}  # func_name -> call_count
var loop_iterations: int = 0
var commands_used: Dictionary = {}   # command -> count
var distance_traveled: float = 0.0
var turns_made: int = 0

# Level-specific metrics
var level_par_steps: int = 0       # "Par" step count for level
var level_par_time: float = 0.0    # "Par" time for level
var level_optimal_loc: int = 0     # Minimum LOC for level

# Rating thresholds (relative to par)
const RATING_EXCELLENT = 0.8   # <= 80% of par
const RATING_GOOD = 1.0        # <= 100% of par
const RATING_OK = 1.3          # <= 130% of par

func reset() -> void:
	execution_steps = 0
	total_time_ms = 0.0
	lines_of_code = 0
	function_calls.clear()
	loop_iterations = 0
	commands_used.clear()
	distance_traveled = 0.0
	turns_made = 0

func record_step() -> void:
	execution_steps += 1

func record_function_call(func_name: String) -> void:
	if not function_calls.has(func_name):
		function_calls[func_name] = 0
	function_calls[func_name] += 1

func record_loop_iteration() -> void:
	loop_iterations += 1

func record_command(command: String) -> void:
	if not commands_used.has(command):
		commands_used[command] = 0
	commands_used[command] += 1

func record_movement(distance: float) -> void:
	distance_traveled += distance

func record_turn() -> void:
	turns_made += 1

func get_step_rating() -> String:
	if level_par_steps <= 0:
		return "N/A"

	var ratio = float(execution_steps) / level_par_steps
	if ratio <= RATING_EXCELLENT:
		return "⭐⭐⭐ Excellent"
	elif ratio <= RATING_GOOD:
		return "⭐⭐ Good"
	elif ratio <= RATING_OK:
		return "⭐ OK"
	else:
		return "Needs Improvement"

func get_code_rating() -> String:
	if level_optimal_loc <= 0:
		return "N/A"

	var ratio = float(lines_of_code) / level_optimal_loc
	if ratio <= RATING_EXCELLENT:
		return "⭐⭐⭐ Minimal"
	elif ratio <= RATING_GOOD:
		return "⭐⭐ Clean"
	elif ratio <= RATING_OK:
		return "⭐ Adequate"
	else:
		return "Could be shorter"

func get_overall_score() -> int:
	var score = 100.0

	if level_par_steps > 0:
		var step_ratio = float(execution_steps) / level_par_steps
		score -= max(0, (step_ratio - 1.0) * 30)

	if level_optimal_loc > 0:
		var loc_ratio = float(lines_of_code) / level_optimal_loc
		score -= max(0, (loc_ratio - 1.0) * 20)

	return int(clamp(score, 0, 100))

func get_star_rating() -> int:
	var score = get_overall_score()
	if score >= 90:
		return 3
	elif score >= 70:
		return 2
	elif score >= 50:
		return 1
	else:
		return 0
