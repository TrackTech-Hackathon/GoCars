## Windows 11-Style Window Snap Controller for GoCars
## Provides snap-to-edge functionality for floating windows
## Drag to left edge → snap to left half
## Drag to right edge → snap to right half
## Drag to top → maximize
## Drag to corners → snap to quadrants
## Double-click title bar → toggle maximize
## Author: Claude Code
## Date: January 2026

extends Node
class_name SnapWindowController

## Signals
signal window_snapped(snap_zone: SnapZone)
signal window_unsnapped()
signal window_maximized()
signal window_minimized()
signal window_restored()

## Snap zones
enum SnapZone {
	NONE,
	LEFT_HALF,
	RIGHT_HALF,
	TOP_HALF,
	BOTTOM_HALF,
	TOP_LEFT,
	TOP_RIGHT,
	BOTTOM_LEFT,
	BOTTOM_RIGHT,
	MAXIMIZED
}

## Configuration
@export var snap_threshold: int = 20  # Pixels from edge to trigger snap
@export var snap_preview_alpha: float = 0.3
@export var snap_animation_duration: float = 0.15
@export var enable_corner_snapping: bool = true

## State
var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var original_rect: Rect2  # Store rect before snapping
var current_snap_zone: SnapZone = SnapZone.NONE
var is_maximized: bool = false
var is_minimized: bool = false

## References
var target_window: Control = null  # The window being controlled
var snap_preview: Panel = null  # Visual preview of snap zone
var title_bar: Control = null  # Draggable area

## Last click time for double-click detection
var last_click_time: float = 0.0
const DOUBLE_CLICK_THRESHOLD: float = 0.3

func _ready() -> void:
	_create_snap_preview()

## Setup the snap controller with a window and its title bar
func setup(window: Control, titlebar: Control) -> void:
	target_window = window
	title_bar = titlebar

	# Store initial rect
	original_rect = Rect2(window.global_position, window.size)

	# Connect title bar signals
	if title_bar:
		title_bar.gui_input.connect(_on_title_bar_input)

## Create the snap preview panel
func _create_snap_preview() -> void:
	snap_preview = Panel.new()
	snap_preview.name = "SnapPreview"
	snap_preview.visible = false
	snap_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	snap_preview.z_index = 1000  # Always on top

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.3, 0.5, 1.0, snap_preview_alpha)
	style.border_color = Color(0.4, 0.6, 1.0, 0.8)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	snap_preview.add_theme_stylebox_override("panel", style)

	# Add to root so it's always on top
	call_deferred("_add_preview_to_root")

func _add_preview_to_root() -> void:
	if target_window and target_window.get_tree():
		target_window.get_tree().root.add_child(snap_preview)

## Handle title bar input
func _on_title_bar_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				# Check for double-click
				var current_time = Time.get_ticks_msec() / 1000.0
				if current_time - last_click_time < DOUBLE_CLICK_THRESHOLD:
					toggle_maximize()
					last_click_time = 0.0  # Reset to prevent triple-click
				else:
					last_click_time = current_time
					_start_drag(mb.global_position)
			else:
				_end_drag()

	elif event is InputEventMouseMotion and is_dragging:
		_update_drag(event.global_position)

## Start dragging
func _start_drag(mouse_pos: Vector2) -> void:
	if not target_window:
		return

	is_dragging = true
	drag_offset = mouse_pos - target_window.global_position

	# If currently snapped, unsnap first (restore to floating size)
	if current_snap_zone != SnapZone.NONE:
		_unsnap_window()
		# Adjust drag offset to be in the center of the restored window
		drag_offset.x = min(drag_offset.x, original_rect.size.x / 2)

## Update drag position and check for snap zones
func _update_drag(mouse_pos: Vector2) -> void:
	if not is_dragging or not target_window:
		return

	# Move window
	target_window.global_position = mouse_pos - drag_offset

	# Check snap zones and show preview
	var detected_zone = _detect_snap_zone(mouse_pos)
	_update_snap_preview(detected_zone)

## End dragging and apply snap if in a zone
func _end_drag() -> void:
	is_dragging = false

	if snap_preview:
		snap_preview.visible = false

	if not target_window:
		return

	var mouse_pos = target_window.get_viewport().get_mouse_position()
	var snap_zone = _detect_snap_zone(mouse_pos)

	if snap_zone != SnapZone.NONE:
		_snap_to_zone(snap_zone)

## Detect which snap zone the mouse is in
func _detect_snap_zone(mouse_pos: Vector2) -> SnapZone:
	if not target_window:
		return SnapZone.NONE

	var viewport_size = target_window.get_viewport_rect().size
	var threshold = snap_threshold

	var at_left = mouse_pos.x <= threshold
	var at_right = mouse_pos.x >= viewport_size.x - threshold
	var at_top = mouse_pos.y <= threshold
	var at_bottom = mouse_pos.y >= viewport_size.y - threshold

	# Corner detection (if enabled)
	if enable_corner_snapping:
		if at_left and at_top:
			return SnapZone.TOP_LEFT
		if at_right and at_top:
			return SnapZone.TOP_RIGHT
		if at_left and at_bottom:
			return SnapZone.BOTTOM_LEFT
		if at_right and at_bottom:
			return SnapZone.BOTTOM_RIGHT

	# Edge detection
	if at_left:
		return SnapZone.LEFT_HALF
	if at_right:
		return SnapZone.RIGHT_HALF
	if at_top:
		return SnapZone.MAXIMIZED

	return SnapZone.NONE

## Get the rect for a snap zone
func _get_snap_rect(zone: SnapZone) -> Rect2:
	if not target_window:
		return Rect2()

	var viewport_size = target_window.get_viewport_rect().size
	var padding = 4  # Small gap from edges

	match zone:
		SnapZone.LEFT_HALF:
			return Rect2(padding, padding, viewport_size.x / 2 - padding * 1.5, viewport_size.y - padding * 2)
		SnapZone.RIGHT_HALF:
			return Rect2(viewport_size.x / 2 + padding * 0.5, padding, viewport_size.x / 2 - padding * 1.5, viewport_size.y - padding * 2)
		SnapZone.TOP_HALF:
			return Rect2(padding, padding, viewport_size.x - padding * 2, viewport_size.y / 2 - padding * 1.5)
		SnapZone.BOTTOM_HALF:
			return Rect2(padding, viewport_size.y / 2 + padding * 0.5, viewport_size.x - padding * 2, viewport_size.y / 2 - padding * 1.5)
		SnapZone.TOP_LEFT:
			return Rect2(padding, padding, viewport_size.x / 2 - padding * 1.5, viewport_size.y / 2 - padding * 1.5)
		SnapZone.TOP_RIGHT:
			return Rect2(viewport_size.x / 2 + padding * 0.5, padding, viewport_size.x / 2 - padding * 1.5, viewport_size.y / 2 - padding * 1.5)
		SnapZone.BOTTOM_LEFT:
			return Rect2(padding, viewport_size.y / 2 + padding * 0.5, viewport_size.x / 2 - padding * 1.5, viewport_size.y / 2 - padding * 1.5)
		SnapZone.BOTTOM_RIGHT:
			return Rect2(viewport_size.x / 2 + padding * 0.5, viewport_size.y / 2 + padding * 0.5, viewport_size.x / 2 - padding * 1.5, viewport_size.y / 2 - padding * 1.5)
		SnapZone.MAXIMIZED:
			return Rect2(padding, padding, viewport_size.x - padding * 2, viewport_size.y - padding * 2)

	return Rect2()

## Update snap preview visibility and position
func _update_snap_preview(zone: SnapZone) -> void:
	if not snap_preview:
		return

	if zone == SnapZone.NONE:
		snap_preview.visible = false
		return

	var target_rect = _get_snap_rect(zone)
	snap_preview.visible = true
	snap_preview.global_position = target_rect.position
	snap_preview.size = target_rect.size

## Snap window to a zone
func _snap_to_zone(zone: SnapZone) -> void:
	if zone == SnapZone.NONE or not target_window:
		return

	# Store original rect for restoration (only if not already snapped)
	if current_snap_zone == SnapZone.NONE:
		original_rect = Rect2(target_window.global_position, target_window.size)

	current_snap_zone = zone
	var target_rect = _get_snap_rect(zone)

	# Animate to snap position
	var tween = target_window.create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(target_window, "global_position", target_rect.position, snap_animation_duration)
	tween.tween_property(target_window, "size", target_rect.size, snap_animation_duration)

	is_maximized = (zone == SnapZone.MAXIMIZED)
	window_snapped.emit(zone)

	if is_maximized:
		window_maximized.emit()

## Unsnap window
func _unsnap_window() -> void:
	current_snap_zone = SnapZone.NONE
	is_maximized = false

	# Restore to floating size but keep at current position for smooth drag
	if original_rect.size != Vector2.ZERO:
		target_window.size = original_rect.size
	else:
		target_window.size = Vector2(600, 400)  # Default fallback

	window_unsnapped.emit()

## Toggle maximize state
func toggle_maximize() -> void:
	if is_maximized:
		restore()
	else:
		maximize()

## Maximize window
func maximize() -> void:
	if not target_window:
		return

	if not is_maximized:
		original_rect = Rect2(target_window.global_position, target_window.size)
	_snap_to_zone(SnapZone.MAXIMIZED)

## Restore window to original size
func restore() -> void:
	if not target_window:
		return

	if original_rect.size == Vector2.ZERO:
		original_rect = Rect2(Vector2(100, 100), Vector2(600, 400))

	var tween = target_window.create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(target_window, "global_position", original_rect.position, snap_animation_duration)
	tween.tween_property(target_window, "size", original_rect.size, snap_animation_duration)

	current_snap_zone = SnapZone.NONE
	is_maximized = false
	window_restored.emit()

## Minimize window (hide it)
func minimize() -> void:
	if not target_window:
		return

	is_minimized = true
	target_window.visible = false
	window_minimized.emit()

## Show window from minimized state
func show_window() -> void:
	if not target_window:
		return

	is_minimized = false
	target_window.visible = true

## Check if maximized
func is_window_maximized() -> bool:
	return is_maximized

## Get current snap zone
func get_snap_zone() -> SnapZone:
	return current_snap_zone

## Clean up
func _exit_tree() -> void:
	if snap_preview and is_instance_valid(snap_preview):
		snap_preview.queue_free()
