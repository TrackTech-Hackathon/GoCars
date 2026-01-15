## Path Visualizer for Game Map
## Author: Claude Code
## Date: January 2026

class_name PathVisualizer
extends Node2D

var tracer: ExecutionTracer
var tile_size: Vector2 = Vector2(64, 64)

var path_points: Array[Vector2] = []
var current_position: Vector2 = Vector2.ZERO

var path_color: Color = Color(0.2, 0.6, 1.0, 0.7)
var path_width: float = 4.0
var dot_radius: float = 6.0
var arrow_size: float = 12.0

var show_step_numbers: bool = true
var show_direction_arrows: bool = true
var fade_old_path: bool = true

func _init(execution_tracer: ExecutionTracer) -> void:
	tracer = execution_tracer
	tracer.car_moved.connect(_on_car_moved)
	tracer.execution_started.connect(_clear_path)
	tracer.execution_finished.connect(_finalize_path)

func _on_car_moved(from: Vector2i, to: Vector2i, action: String) -> void:
	var world_from = grid_to_world(from)
	var world_to = grid_to_world(to)

	if path_points.is_empty() or path_points[-1] != world_from:
		path_points.append(world_from)

	path_points.append(world_to)
	current_position = world_to

	queue_redraw()

func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos) * tile_size + tile_size / 2

func _draw() -> void:
	if path_points.size() < 2:
		return

	# Draw path line
	for i in range(path_points.size() - 1):
		var from = path_points[i]
		var to = path_points[i + 1]

		var alpha = 1.0
		if fade_old_path:
			alpha = float(i + 1) / path_points.size()

		var color = Color(path_color.r, path_color.g, path_color.b, path_color.a * alpha)
		draw_line(from, to, color, path_width, true)

		if show_direction_arrows:
			_draw_arrow(from, to, color)

	# Draw dots at each point
	for i in range(path_points.size()):
		var point = path_points[i]
		var alpha = 1.0 if not fade_old_path else float(i + 1) / path_points.size()
		var color = Color(path_color.r, path_color.g, path_color.b, alpha)

		draw_circle(point, dot_radius, color)

		if show_step_numbers:
			var font = ThemeDB.fallback_font
			var text = str(i + 1)
			var text_size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12)
			draw_string(font, point - text_size / 2 + Vector2(0, 4), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)

	# Draw current position indicator
	if not path_points.is_empty():
		var last = path_points[-1]
		draw_circle(last, dot_radius + 4, Color.YELLOW)
		draw_circle(last, dot_radius + 2, path_color)

func _draw_arrow(from: Vector2, to: Vector2, color: Color) -> void:
	var direction = (to - from).normalized()
	var mid = (from + to) / 2

	var arrow_base = mid - direction * arrow_size / 2
	var perpendicular = Vector2(-direction.y, direction.x)

	var tip = mid + direction * arrow_size / 2
	var left = arrow_base + perpendicular * arrow_size / 3
	var right = arrow_base - perpendicular * arrow_size / 3

	var points = PackedVector2Array([tip, left, right])
	draw_colored_polygon(points, color)

func _clear_path() -> void:
	path_points.clear()
	queue_redraw()

func _finalize_path() -> void:
	queue_redraw()

func get_total_distance() -> float:
	var total = 0.0
	for i in range(path_points.size() - 1):
		total += path_points[i].distance_to(path_points[i + 1])
	return total

func get_step_count() -> int:
	return path_points.size()
