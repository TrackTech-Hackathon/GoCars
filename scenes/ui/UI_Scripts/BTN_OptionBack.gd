extends Control
# Attach to: ControlBTN/OptionLabel
# Hover + press visuals animate parent (ControlBTN)
# Click works even if other UI overlaps (uses _input + rect hit-testing)
# On click: toggles menu visibility (show_node visible, hide_node invisible)

signal clicked

# ─────────────────────────────────────────
# ✦ MENU VISIBILITY (Inspector)
# ─────────────────────────────────────────
@export var show_node: CanvasItem        # what to show (ex: OptionsUI)
@export var hide_node: CanvasItem        # what to hide (ex: MC_MainMenu)
@export var debug_print: bool = false

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

# If true: the clickable/hover area is the whole parent (ControlBTN)
# If false: clickable/hover area is OptionLabel only
@export var use_parent_hitbox: bool = false

var target_button: Control  # parent (ControlBTN)

var _tween: Tween
var _base_scale: Vector2
var _base_z: int

var _is_hovered := false
var _is_pressed := false
var _press_started_inside := false


func _ready() -> void:
	# We are NOT relying on GUI events, so mouse_filter doesn't matter.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE

	target_button = get_parent() as Control
	if not target_button:
		push_error("OptionLabel FX: parent is not a Control.")
		return

	_base_scale = target_button.scale
	_base_z = target_button.z_index
	target_button.modulate = normal_modulate

	await get_tree().process_frame
	_center_parent_pivot()
	target_button.resized.connect(_center_parent_pivot)

	# ✅ Needed for hover + global click detection
	set_process(true)
	set_process_input(true)


func _center_parent_pivot() -> void:
	target_button.pivot_offset = target_button.size * 0.5


func _hit_rect() -> Rect2:
	# ✅ pick which rect should count as "clickable"
	return target_button.get_global_rect() if use_parent_hitbox else get_global_rect()


func _process(_delta: float) -> void:
	if not target_button:
		return

	var mouse_pos := get_viewport().get_mouse_position()
	var now_hovered := _hit_rect().has_point(mouse_pos)

	if now_hovered != _is_hovered:
		_is_hovered = now_hovered
		if not _is_hovered:
			_is_pressed = false
			_press_started_inside = false
		_apply_state()


func _input(event: InputEvent) -> void:
	if not target_button:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos := get_viewport().get_mouse_position()
		var inside := _hit_rect().has_point(mouse_pos)

		if event.pressed:
			# press must start inside
			_press_started_inside = inside
			if _press_started_inside:
				_is_pressed = true
				_apply_state()
		else:
			# click only if press started inside AND released inside
			var should_click := _press_started_inside and inside

			_press_started_inside = false
			_is_pressed = false

			# release bounce
			if inside:
				_is_hovered = true
				_apply_state(release_time)
			else:
				_is_hovered = false
				_apply_state()

			if should_click:
				emit_signal("clicked")
				_do_open_toggle()


func _do_open_toggle() -> void:
	if debug_print:
		print("TOGGLE:", name, " show=", show_node, " hide=", hide_node)

	if show_node:
		show_node.visible = true
	if hide_node:
		hide_node.visible = false


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
		_tween_to(hover_scale * press_scale, pressed_modulate, t, Tween.TRANS_QUAD, Tween.EASE_OUT)
		return

	if _is_hovered:
		target_button.z_index = hover_z_index
		var t := hover_time if time_override < 0.0 else time_override
		_tween_to(hover_scale, hover_modulate, t, Tween.TRANS_BACK, Tween.EASE_OUT)
	else:
		target_button.z_index = _base_z
		var t := unhover_time if time_override < 0.0 else time_override
		_tween_to(1.0, normal_modulate, t, Tween.TRANS_QUAD, Tween.EASE_OUT)
