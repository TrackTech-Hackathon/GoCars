extends Control
# Attach to: GameplayBTN/OptionLabel
# Hover + press visuals animate GameplayBTN (parent)
# Click on OptionLabel triggers show/hide (acts like a button)

# ─────────────────────────────────────────
# ✦ VISIBILITY ASSIGNMENTS (Inspector)
# ─────────────────────────────────────────
@export var show_node: CanvasItem

@export var hide_node_1: CanvasItem
@export var hide_node_2: CanvasItem
@export var hide_node_3: CanvasItem

# ─────────────────────────────────────────
# ✦ HOVER / PRESS VISUALS
# ─────────────────────────────────────────
@export var hover_scale: float = 1.05
@export var press_scale: float = 0.95

@export var hover_time: float = 0.10
@export var unhover_time: float = 0.12
@export var press_time: float = 0.06
@export var release_time: float = 0.10

@export var normal_modulate: Color = Color(1, 1, 1, 1)
@export var hover_modulate: Color = Color(1.08, 1.08, 1.08, 1)
@export var pressed_modulate: Color = Color(0.95, 0.95, 0.95, 1)

@export var hover_z_index: int = 50

# ─────────────────────────────────────────
# ✦ INTERNAL
# ─────────────────────────────────────────
var target_button: Control   # GameplayBTN (parent)

var _tween: Tween
var _base_scale: Vector2
var _base_z: int

var _is_hovered := false
var _is_pressed := false


func _ready() -> void:
	# OptionLabel must receive mouse events
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE

	# Parent is the visual target (GameplayBTN)
	target_button = get_parent() as Control
	if not target_button:
		push_error("OptionLabel script: parent is not a Control.")
		return

	target_button.modulate = normal_modulate
	_base_scale = target_button.scale
	_base_z = target_button.z_index

	# Center pivot after layout is valid
	await get_tree().process_frame
	_center_parent_pivot()

	target_button.resized.connect(_center_parent_pivot)

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _center_parent_pivot() -> void:
	target_button.pivot_offset = target_button.size * 0.5


func _kill_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = null


func _tween_to(scale_mul: float, color: Color, time: float, trans := Tween.TRANS_QUAD, ease := Tween.EASE_OUT) -> void:
	_kill_tween()
	_tween = create_tween()
	_tween.set_trans(trans)
	_tween.set_ease(ease)
	_tween.tween_property(target_button, "scale", _base_scale * scale_mul, time)
	_tween.parallel().tween_property(target_button, "modulate", color, time)


func _apply_state(time_override := -1.0) -> void:
	if _is_pressed:
		var t := press_time if time_override < 0.0 else time_override
		_tween_to(hover_scale * press_scale, pressed_modulate, t)
		return

	if _is_hovered:
		target_button.z_index = hover_z_index
		var t := hover_time if time_override < 0.0 else time_override
		_tween_to(hover_scale, hover_modulate, t, Tween.TRANS_BACK)
	else:
		target_button.z_index = _base_z
		var t := unhover_time if time_override < 0.0 else time_override
		_tween_to(1.0, normal_modulate, t)


func _on_mouse_entered() -> void:
	_is_hovered = true
	_apply_state()


func _on_mouse_exited() -> void:
	_is_hovered = false
	_is_pressed = false
	_apply_state()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_is_pressed = true
			_apply_state()
		else:
			_is_pressed = false
			# bounce back to hover state after release
			if _is_hovered:
				_apply_state(release_time)
			else:
				_apply_state()

			# ✅ treat mouse release as a "click"
			_do_visibility_toggle()

		accept_event()


func _do_visibility_toggle() -> void:
	# Show assigned node
	if show_node:
		show_node.visible = true

	# Hide assigned nodes
	if hide_node_1:
		hide_node_1.visible = false
	if hide_node_2:
		hide_node_2.visible = false
	if hide_node_3:
		hide_node_3.visible = false
