class_name StoplightProxy
extends RefCounted

## A read-only proxy for the Stoplight class.
## This is passed to car scripts to prevent them from changing the stoplight's state.
## It allows cars to read the state (is_red, is_green) but blocks them
## from calling control methods (red, green).

var _real_stoplight: Stoplight

var global_position: Vector2:
	get:
		if is_instance_valid(_real_stoplight):
			return _real_stoplight.global_position
		return Vector2.ZERO


func _init(stoplight_to_wrap: Stoplight):
	_real_stoplight = stoplight_to_wrap


# --- Read-only methods (Allowed) ---

func is_red(direction: String = "") -> bool:
	if not is_instance_valid(_real_stoplight):
		return true # Fail-safe
	# Note: This will correctly show the deprecation warning if direction is empty
	return _real_stoplight.is_red(direction)


func is_green(direction: String = "") -> bool:
	if not is_instance_valid(_real_stoplight):
		return false # Fail-safe
	return _real_stoplight.is_green(direction)


func is_yellow(direction: String = "") -> bool:
	if not is_instance_valid(_real_stoplight):
		return true # Fail-safe
	return _real_stoplight.is_yellow(direction)


# --- Write methods (Blocked) ---

func green(... _directions) -> void:
	push_error("A car script cannot change a stoplight's color. This action is ignored.")


func red(... _directions) -> void:
	push_error("A car script cannot change a stoplight's color. This action is ignored.")


func yellow(... _directions) -> void:
	push_error("A car script cannot change a stoplight's color. This action is ignored.")

func wait(... _args) -> void:
	push_error("A car script cannot call wait() on a stoplight. This action is ignored.")

func set_red() -> void:
	push_error("A car script cannot change a stoplight's color. This action is ignored.")

func set_green() -> void:
	push_error("A car script cannot change a stoplight's color. This action is ignored.")

func set_yellow() -> void:
	push_error("A car script cannot change a stoplight's color. This action is ignored.")
