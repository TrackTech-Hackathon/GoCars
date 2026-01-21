extends TextureButton



# ─────────────────────────────────────────
# ✦ HOVER & PRESS VISUALS
# ─────────────────────────────────────────
@export var show_node: CanvasItem        # what to show (ex: OptionsUI)
@export var hide_node: CanvasItem        # what to hide (ex: MC_MainMenu)

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

var _tween: Tween
var _base_scale: Vector2 = Vector2.ONE
var _base_z: int

var _is_hovered := false
var _is_pressed := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	pressed.connect(_do_open_toggle)
	focus_mode = Control.FOCUS_NONE

	modulate = normal_modulate

	_base_scale = scale
	_base_z = z_index

	# Make sure we scale from center (layout sizes are valid after 1 frame)
	await get_tree().process_frame
	_update_pivot()

	# Keep pivot correct if window/layout changes
	resized.connect(_update_pivot)

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _update_pivot() -> void:
	pivot_offset = size * 0.5

func _kill_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = null

func _tween_to(target_scale: Vector2, target_modulate: Color, time: float, trans := Tween.TRANS_QUAD, ease := Tween.EASE_OUT) -> void:
	_kill_tween()
	_tween = create_tween()
	_tween.set_trans(trans)
	_tween.set_ease(ease)
	_tween.tween_property(self, "scale", target_scale, time)
	_tween.parallel().tween_property(self, "modulate", target_modulate, time)

func _apply_hover_state() -> void:
	# If pressed, pressed visuals win
	if _is_pressed:
		_tween_to(_base_scale * (hover_scale * press_scale), pressed_modulate, press_time, Tween.TRANS_QUAD, Tween.EASE_OUT)
		return

	if _is_hovered:
		z_index = hover_z_index
		_tween_to(_base_scale * hover_scale, hover_modulate, hover_time, Tween.TRANS_BACK, Tween.EASE_OUT)
	else:
		# restore z_index after shrink finishes
		_kill_tween()
		_tween = create_tween()
		_tween.set_trans(Tween.TRANS_QUAD)
		_tween.set_ease(Tween.EASE_OUT)
		_tween.tween_property(self, "scale", _base_scale, unhover_time)
		_tween.parallel().tween_property(self, "modulate", normal_modulate, unhover_time)
		_tween.finished.connect(func():
			z_index = _base_z
		)

func _on_mouse_entered() -> void:
	_is_hovered = true
	_apply_hover_state()

func _on_mouse_exited() -> void:
	_is_hovered = false
	_is_pressed = false
	_apply_hover_state()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_is_pressed = true
			_tween_to(_base_scale * (hover_scale * press_scale), pressed_modulate, press_time, Tween.TRANS_QUAD, Tween.EASE_OUT)
		else:
			_is_pressed = false
			if _is_hovered:
				_tween_to(_base_scale * hover_scale, hover_modulate, release_time, Tween.TRANS_BACK, Tween.EASE_OUT)
			else:
				_apply_hover_state()

	# ✅ DO NOT accept_event()




# ─────────────────────────────────────────
# ✦ MENU VISIBILITY TOGGLE OR SCENE CHANGE
# ─────────────────────────────────────────

@export var scene_to_load: String = ""



func _do_open_toggle() -> void:
	print("TOGGLE:", name, " show=", show_node, " hide=", hide_node)

	# If scene_to_load is set, change scene instead of toggling visibility
	if scene_to_load != "":
		get_tree().change_scene_to_file(scene_to_load)
		return

	if show_node:
		show_node.visible = true
		# Lower music volume when showing sub-menus
		if MusicManager:
			MusicManager.lower_volume()
	if hide_node:
		hide_node.visible = false
		# Restore music volume when hiding sub-menus (going back to main menu)
		if MusicManager:
			MusicManager.restore_volume()
