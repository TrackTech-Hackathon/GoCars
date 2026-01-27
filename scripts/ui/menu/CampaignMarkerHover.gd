extends TextureButton

@export var hover_scale: Vector2 = Vector2(1.08, 1.08)
@export var in_time: float = 0.08
@export var out_time: float = 0.14

# Icon bob (idle + hover speed)
@export var idle_bob_period: float = 0.70      # slow idle bob
@export var hover_bob_period: float = 0.35     # fast bob on hover

# Icon bob (amount)
@export var icon_bob_amount: float = 10.0
@export var icon_bob_period: float = 0.35      # (legacy) not used directly anymore
@export var icon_return_time: float = 0.14     # (kept) used if you call _stop_bob_and_return()

# Click state (sticky)
@export var click_down_offset: float = 6.0
@export var click_down_time: float = 0.20

# Icon pop (click)
@export var icon_pop_from: float = 0.65
@export var icon_pop_time: float = 0.25   # very soft / premium

# Label fade (click)
@export var label_fade_to: float = 0.0
@export var label_fade_time: float = 0.12

# Pop feel (not too bouncy)
@export var in_transition := Tween.TRANS_BACK
@export var in_ease := Tween.EASE_OUT
@export var out_transition := Tween.TRANS_BACK
@export var out_ease := Tween.EASE_OUT

# Bob feel (smooth)
@export var bob_transition := Tween.TRANS_SINE
@export var bob_ease := Tween.EASE_IN_OUT

# ---- Assign these in the Inspector (drag & drop) ----
@export var texture_rect_path: NodePath
@export var icon1_path: NodePath
@export var icon2_path: NodePath
@export var label_path: NodePath

# Selected (clicked) base size
@export var selected_scale: float = 1.25
@export var selected_scale_time: float = 0.05 # how fast it grows on select

# Breathing (clicked)
@export var breathe_scale: float = 1.03  # breathing multiplier on top of selected size
@export var breathe_period: float = 0.9
@export var breathe_transition := Tween.TRANS_SINE
@export var breathe_ease := Tween.EASE_IN_OUT

var _tween: Tween
var _bob_tween: Tween
var _click_tween: Tween
var _fade_tween: Tween
var _label_tween: Tween
var _icon_pop_tween: Tween
var _breathe_tween: Tween

var _base_scale: Vector2
var _selected_base_scale: Vector2
var _hovered := false
var _clicked := false
var _pending_hover_restore := false

var _icon: TextureRect = null
var _icon1: Node = null
var _icon2: Node = null
var _label: Label = null

var _icon_base_pos: Vector2 = Vector2.ZERO

var _icon1_base_a: float = 1.0
var _icon2_base_a: float = 1.0
var _label_base_a: float = 1.0

var _icon1_base_scale: Vector2 = Vector2.ONE
var _icon2_base_scale: Vector2 = Vector2.ONE
var _icon1_is_control := false
var _icon2_is_control := false


func _ready() -> void:
	_base_scale = scale
	_selected_base_scale = _base_scale * selected_scale
	_cache_fade_group()


	# Center pivot so scaling grows from the center
	pivot_offset = size * 0.5
	resized.connect(_on_resized)
	_on_resized()

	# Get nodes
	var n_icon = get_node_or_null(texture_rect_path)
	if n_icon != null and n_icon is TextureRect:
		_icon = n_icon
		_icon_base_pos = _icon.position

	var n_i1 = get_node_or_null(icon1_path)
	if n_i1 != null:
		_icon1 = n_i1
		_cache_icon_info(_icon1, true)

	var n_i2 = get_node_or_null(icon2_path)
	if n_i2 != null:
		_icon2 = n_i2
		_cache_icon_info(_icon2, false)

	var n_lbl = get_node_or_null(label_path)
	if n_lbl != null and n_lbl is Label:
		_label = n_lbl
		_label_base_a = _label.modulate.a

	mouse_entered.connect(_on_enter)
	mouse_exited.connect(_on_exit)

	# Required so this Control receives hover + click
	mouse_filter = Control.MOUSE_FILTER_STOP

	# Start unclicked visuals instantly
	_apply_clicked_visuals(false, true)

	# ✅ NEW: idle bob when unselected (always, unless clicked)
	if not _clicked:
		_start_bob(idle_bob_period)


func _cache_icon_info(node: Node, is_icon1: bool) -> void:
	# Alpha
	if node is CanvasItem:
		if is_icon1:
			_icon1_base_a = (node as CanvasItem).modulate.a
		else:
			_icon2_base_a = (node as CanvasItem).modulate.a

	# Scale + type
	if node is Control:
		if is_icon1:
			_icon1_is_control = true
			_icon1_base_scale = (node as Control).scale
		else:
			_icon2_is_control = true
			_icon2_base_scale = (node as Control).scale
	elif node is Node2D:
		if is_icon1:
			_icon1_is_control = false
			_icon1_base_scale = (node as Node2D).scale
		else:
			_icon2_is_control = false
			_icon2_base_scale = (node as Node2D).scale


func _on_resized() -> void:
	pivot_offset = size * 0.5


# ✅ CLICK HANDLING (toggle click state)
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_clicked = not _clicked
		_apply_clicked_visuals(_clicked, false)
		# Don't call accept_event() - let the pressed signal propagate to parent handlers
		# accept_event()


# ✅ Click outside -> unselect
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# If already selected and click happens OUTSIDE this Control -> unselect
		if _clicked and not get_global_rect().has_point(event.global_position):
			_clicked = false
			_apply_clicked_visuals(false, false)


func _on_enter() -> void:
	_hovered = true
	if _clicked:
		return # disable hover effects while clicked

	_pop_to(_base_scale * hover_scale, in_time, in_transition, in_ease)

	# ✅ NEW: faster bob while hovered (still bobs even when not hovered)
	_start_bob(hover_bob_period)


func _on_exit() -> void:
	_hovered = false
	if _clicked:
		return # disable hover-out effects while clicked

	_pop_to(_base_scale, out_time, out_transition, out_ease)

	# ✅ NEW: go back to idle bob speed when not hovered
	_start_bob(idle_bob_period)


func _apply_clicked_visuals(is_clicked: bool, instant: bool) -> void:
	# If entering clicked state: cancel bob + hover, bump to selected size, then breathe
	if is_clicked:
		_kill_bob()
		_stop_hover_scale(instant)

		# keep selected base scale updated (in case you tweak in Inspector during runtime)
		_selected_base_scale = _base_scale * selected_scale

		# bump to selected size first
		if instant:
			scale = _selected_base_scale
		else:
			_pop_to(_selected_base_scale, selected_scale_time, in_transition, in_ease)

		_start_breathe(instant)
	else:
		_stop_breathe(instant)
		if instant:
			scale = _base_scale
		else:
			_pop_to(_base_scale, out_time, out_transition, out_ease)

	# 1) Move TextureRect: down when clicked, base when not
	if _icon != null:
		var target_pos := _icon_base_pos
		if is_clicked:
			target_pos = _icon_base_pos + Vector2(0, 50)

		if instant:
			_icon.position = target_pos

			# If instantly back to base, we can resume bob immediately
			if not is_clicked:
				if _hovered:
					_pop_to(_base_scale * hover_scale, in_time, in_transition, in_ease)
					_start_bob(hover_bob_period)
				else:
					_pop_to(_base_scale, out_time, out_transition, out_ease)
					_start_bob(idle_bob_period)
		else:
			# When unclicking, wait until the icon reaches base before restoring hover/idle bob
			if not is_clicked:
				_pending_hover_restore = true
				_tween_icon_pos_return_and_then(target_pos, click_down_time)
			else:
				_tween_icon_pos(target_pos, click_down_time)

	# 2) Icons alpha + pop scale
	if instant:
		_set_icons_alpha(1.0 if is_clicked else -1.0)
		_set_icons_scale_to_base()
	else:
		if is_clicked:
			_tween_icons_alpha(1.0, click_down_time)
			_pop_icons_in()
		else:
			_restore_icons_alpha(click_down_time)
			_pop_icons_out()

	# 2.5) Label alpha
	if _label != null:
		var target_a := (label_fade_to if is_clicked else _label_base_a)
		if instant:
			_label.modulate.a = target_a
		else:
			_tween_label_alpha(target_a, label_fade_time)

	# If we unclicked, we already set _pending_hover_restore = true above (non-instant path).
	# If we clicked, cancel any pending restore.
	if is_clicked:
		_pending_hover_restore = false
	
	if instant:
		# ✅ apply instantly (NO tween object needed)
		for item in _fade_group_base_a.keys():
			var base_a: float = _fade_group_base_a[item]
			(item as CanvasItem).modulate.a = (base_a if is_clicked else fade_out_to)
	else:
		_tween_fade_group(is_clicked)




func _set_icons_alpha(target_a_or_restore: float) -> void:
	# target_a_or_restore < 0 means "restore"
	if _icon1 != null and _icon1 is CanvasItem:
		(_icon1 as CanvasItem).modulate.a = (_icon1_base_a if target_a_or_restore < 0.0 else target_a_or_restore)
	if _icon2 != null and _icon2 is CanvasItem:
		(_icon2 as CanvasItem).modulate.a = (_icon2_base_a if target_a_or_restore < 0.0 else target_a_or_restore)


func _set_icons_scale_to_base() -> void:
	if _icon1 != null:
		if _icon1_is_control and _icon1 is Control:
			(_icon1 as Control).scale = _icon1_base_scale
		elif _icon1 is Node2D:
			(_icon1 as Node2D).scale = _icon1_base_scale

	if _icon2 != null:
		if _icon2_is_control and _icon2 is Control:
			(_icon2 as Control).scale = _icon2_base_scale
		elif _icon2 is Node2D:
			(_icon2 as Node2D).scale = _icon2_base_scale


func _pop_to(target: Vector2, duration: float, trans: Tween.TransitionType, ease_type: Tween.EaseType) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()

	_tween = create_tween()
	_tween.set_trans(trans)
	_tween.set_ease(ease_type)
	_tween.tween_property(self, "scale", target, duration)


# ✅ NEW: bob period is now parameterized (idle vs hover)
func _start_bob(period: float) -> void:
	if _icon == null:
		return
	if _clicked:
		return

	_kill_bob()

	_bob_tween = create_tween()
	_bob_tween.set_trans(bob_transition)
	_bob_tween.set_ease(bob_ease)
	_bob_tween.set_loops()

	var start_pos := _icon.position
	_bob_tween.tween_property(_icon, "position", start_pos + Vector2(0, -icon_bob_amount), period)
	_bob_tween.tween_property(_icon, "position", start_pos, period)


# (kept for compatibility; no longer used by hover exit)
func _stop_bob_and_return() -> void:
	if _icon == null:
		return

	_kill_bob()

	_bob_tween = create_tween()
	_bob_tween.set_trans(Tween.TRANS_SINE)
	_bob_tween.set_ease(Tween.EASE_OUT)
	_bob_tween.tween_property(_icon, "position", _icon_base_pos, icon_return_time)


func _kill_bob() -> void:
	if _bob_tween != null and _bob_tween.is_valid():
		_bob_tween.kill()


func _tween_icon_pos(target_pos: Vector2, duration: float) -> void:
	if _icon == null:
		return

	if _click_tween != null and _click_tween.is_valid():
		_click_tween.kill()

	_click_tween = create_tween()
	_click_tween.set_trans(Tween.TRANS_SINE)
	_click_tween.set_ease(Tween.EASE_OUT)
	_click_tween.tween_property(_icon, "position", target_pos, duration)


func _tween_icons_alpha(target_a: float, duration: float) -> void:
	if (_icon1 == null or not (_icon1 is CanvasItem)) and (_icon2 == null or not (_icon2 is CanvasItem)):
		return

	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()

	# Check if we have at least one valid icon before creating tween
	var has_icon1 = _icon1 != null and _icon1 is CanvasItem
	var has_icon2 = _icon2 != null and _icon2 is CanvasItem
	if not has_icon1 and not has_icon2:
		return

	_fade_tween = create_tween()
	_fade_tween.set_trans(Tween.TRANS_SINE)
	_fade_tween.set_ease(Tween.EASE_OUT)

	if has_icon1:
		_fade_tween.tween_property(_icon1, "modulate:a", target_a, duration)
	if has_icon2:
		_fade_tween.tween_property(_icon2, "modulate:a", target_a, duration)


func _restore_icons_alpha(duration: float) -> void:
	if (_icon1 == null or not (_icon1 is CanvasItem)) and (_icon2 == null or not (_icon2 is CanvasItem)):
		return

	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()

	# Check if we have at least one valid icon before creating tween
	var has_icon1 = _icon1 != null and _icon1 is CanvasItem
	var has_icon2 = _icon2 != null and _icon2 is CanvasItem
	if not has_icon1 and not has_icon2:
		return

	_fade_tween = create_tween()
	_fade_tween.set_trans(Tween.TRANS_SINE)
	_fade_tween.set_ease(Tween.EASE_OUT)

	if has_icon1:
		_fade_tween.tween_property(_icon1, "modulate:a", _icon1_base_a, duration)
	if has_icon2:
		_fade_tween.tween_property(_icon2, "modulate:a", _icon2_base_a, duration)


func _tween_label_alpha(target_a: float, duration: float) -> void:
	if _label == null:
		return

	if _label_tween != null and _label_tween.is_valid():
		_label_tween.kill()

	_label_tween = create_tween()
	_label_tween.set_trans(Tween.TRANS_SINE)
	_label_tween.set_ease(Tween.EASE_OUT)
	_label_tween.tween_property(_label, "modulate:a", target_a, duration)


func _pop_icons_in() -> void:
	# Return early if no icons to animate
	if _icon1 == null and _icon2 == null:
		return

	if _icon_pop_tween != null and _icon_pop_tween.is_valid():
		_icon_pop_tween.kill()

	_icon_pop_tween = create_tween()
	_icon_pop_tween.set_trans(Tween.TRANS_BACK)
	_icon_pop_tween.set_ease(Tween.EASE_OUT)

	if _icon1 != null:
		var from1 := _icon1_base_scale * icon_pop_from
		if _icon1_is_control and _icon1 is Control:
			(_icon1 as Control).scale = from1
		elif _icon1 is Node2D:
			(_icon1 as Node2D).scale = from1
		_icon_pop_tween.tween_property(_icon1, "scale", _icon1_base_scale, icon_pop_time)

	if _icon2 != null:
		var from2 := _icon2_base_scale * icon_pop_from
		if _icon2_is_control and _icon2 is Control:
			(_icon2 as Control).scale = from2
		elif _icon2 is Node2D:
			(_icon2 as Node2D).scale = from2
		_icon_pop_tween.tween_property(_icon2, "scale", _icon2_base_scale, icon_pop_time)


func _pop_icons_out() -> void:
	# Return early if no icons to animate
	if _icon1 == null and _icon2 == null:
		return

	if _icon_pop_tween != null and _icon_pop_tween.is_valid():
		_icon_pop_tween.kill()

	_icon_pop_tween = create_tween()
	_icon_pop_tween.set_trans(Tween.TRANS_SINE)
	_icon_pop_tween.set_ease(Tween.EASE_OUT)

	if _icon1 != null:
		_icon_pop_tween.tween_property(_icon1, "scale", _icon1_base_scale, 0.10)
	if _icon2 != null:
		_icon_pop_tween.tween_property(_icon2, "scale", _icon2_base_scale, 0.10)


func _start_breathe(instant: bool) -> void:
	if _breathe_tween != null and _breathe_tween.is_valid():
		_breathe_tween.kill()

	# breathe around selected base scale
	var small := _selected_base_scale
	var big := _selected_base_scale * breathe_scale

	if instant:
		scale = small

	_breathe_tween = create_tween()
	_breathe_tween.set_trans(breathe_transition)
	_breathe_tween.set_ease(breathe_ease)
	_breathe_tween.set_loops()

	_breathe_tween.tween_property(self, "scale", big, breathe_period * 0.5)
	_breathe_tween.tween_property(self, "scale", small, breathe_period * 0.5)


func _stop_breathe(instant: bool) -> void:
	if _breathe_tween != null and _breathe_tween.is_valid():
		_breathe_tween.kill()

	if instant:
		scale = _base_scale


func _stop_hover_scale(instant: bool) -> void:
	# cancel any hover scale tween and return to base (so clicked state owns the scale)
	if _tween != null and _tween.is_valid():
		_tween.kill()

	if instant:
		scale = _base_scale
	else:
		_pop_to(_base_scale, out_time, out_transition, out_ease)


func _tween_icon_pos_return_and_then(target_pos: Vector2, duration: float) -> void:
	if _icon == null:
		return

	if _click_tween != null and _click_tween.is_valid():
		_click_tween.kill()

	_click_tween = create_tween()
	_click_tween.set_trans(Tween.TRANS_SINE)
	_click_tween.set_ease(Tween.EASE_OUT)
	_click_tween.tween_property(_icon, "position", target_pos, duration)

	# ✅ After return finishes: restore hover/idle bob ONLY if still not clicked
	_click_tween.finished.connect(func():
		if _clicked:
			return
		if not _pending_hover_restore:
			return

		_pending_hover_restore = false

		if _hovered:
			_pop_to(_base_scale * hover_scale, in_time, in_transition, in_ease)
			_start_bob(hover_bob_period)
		else:
			_pop_to(_base_scale, out_time, out_transition, out_ease)
			_start_bob(idle_bob_period)
	)
	
	
	# ✅ Fade a whole external UI group (root + children + descendants)
@export var fade_group_root_path: NodePath
@export var fade_out_to: float = 0.0        # unselected -> fade out
@export var fade_time: float = 0.14         # tween duration

var _fade_group_root: Node = null
var _fade_group_tween: Tween = null
var _fade_group_base_a := {}  # CanvasItem -> base alpha

func _cache_fade_group() -> void:
	_fade_group_root = get_node_or_null(fade_group_root_path)
	_fade_group_base_a.clear()
	if _fade_group_root == null:
		return

	_collect_canvas_items(_fade_group_root)


func _collect_canvas_items(n: Node) -> void:
	if n is CanvasItem:
		_fade_group_base_a[n] = (n as CanvasItem).modulate.a

	for c in n.get_children():
		if c is Node:
			_collect_canvas_items(c)


func _tween_fade_group(is_clicked: bool) -> void:
	if _fade_group_root == null:
		return

	if _fade_group_tween != null and _fade_group_tween.is_valid():
		_fade_group_tween.kill()
	
	# Return early if no items to animate
	if _fade_group_base_a.is_empty():
		return

	_fade_group_tween = create_tween()
	_fade_group_tween.set_parallel(true) # ✅ key line: run tracks simultaneously
	_fade_group_tween.set_trans(Tween.TRANS_SINE)
	_fade_group_tween.set_ease(Tween.EASE_OUT)

	for item in _fade_group_base_a.keys():
		var base_a: float = _fade_group_base_a[item]
		var target_a: float = (base_a if is_clicked else fade_out_to)
		_fade_group_tween.tween_property(item, "modulate:a", target_a, fade_time)
