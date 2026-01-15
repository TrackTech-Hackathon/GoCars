## Metrics Tracker for Real-Time Performance Monitoring
## Author: Claude Code
## Date: January 2026

class_name MetricsTracker
extends Node

signal metrics_updated(metrics: PerformanceMetrics)

var metrics: PerformanceMetrics
var tracer: ExecutionTracer
var start_time: int = 0

func _init(execution_tracer: ExecutionTracer) -> void:
	metrics = PerformanceMetrics.new()
	tracer = execution_tracer

	tracer.execution_started.connect(_on_execution_started)
	tracer.execution_finished.connect(_on_execution_finished)
	tracer.line_executed.connect(_on_line_executed)
	tracer.car_moved.connect(_on_car_moved)

func set_level_pars(par_steps: int, par_time: float, optimal_loc: int) -> void:
	metrics.level_par_steps = par_steps
	metrics.level_par_time = par_time
	metrics.level_optimal_loc = optimal_loc

func analyze_code(code: String) -> void:
	var lines = code.split("\n")
	var loc = 0

	for line in lines:
		var stripped = line.strip_edges()
		if not stripped.is_empty() and not stripped.begins_with("#"):
			loc += 1

	metrics.lines_of_code = loc

func _on_execution_started() -> void:
	metrics.reset()
	start_time = Time.get_ticks_msec()

func _on_execution_finished() -> void:
	metrics.total_time_ms = Time.get_ticks_msec() - start_time
	metrics_updated.emit(metrics)

func _on_line_executed(line: int, variables: Dictionary) -> void:
	metrics.record_step()

func _on_car_moved(from: Vector2i, to: Vector2i, action: String) -> void:
	metrics.record_command(action)

	var distance = Vector2(to - from).length()
	metrics.record_movement(distance)

	if "turn" in action:
		metrics.record_turn()

func get_metrics() -> PerformanceMetrics:
	return metrics
