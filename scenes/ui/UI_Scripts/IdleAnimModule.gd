extends Control
# Attach to any Control node (Label, TextureRect, etc.)
# Idle wobble: rotation + scale ONLY (no position/centering movement)

@export var rot_degrees: float = 2.0
@export var rot_time: float = 2.6

@export var scale_amount: float = 0.035
@export var scale_time: float = 2.2

@export var start_random_offset: bool = true

var _base_scale: Vector2
var _t_rot: Tween
var _t_scale: Tween


func _ready() -> void:
	# Center pivot for clean rotate/scale around middle
	pivot_offset = size * 0.5

	_base_scale = scale

	if start_random_offset:
		_apply_random_phase()

	_start_loops()


func _apply_random_phase() -> void:
	rotation = deg_to_rad(randf_range(-rot_degrees, rot_degrees))
	scale = _base_scale * (1.0 + randf_range(-scale_amount, scale_amount))


func _start_loops() -> void:
	# Rotation loop
	_t_rot = create_tween()
	_t_rot.set_loops()
	_t_rot.set_trans(Tween.TRANS_SINE)
	_t_rot.set_ease(Tween.EASE_IN_OUT)
	_t_rot.tween_property(self, "rotation", deg_to_rad(rot_degrees), rot_time)
	_t_rot.tween_property(self, "rotation", deg_to_rad(-rot_degrees), rot_time)

	# Scale loop
	_t_scale = create_tween()
	_t_scale.set_loops()
	_t_scale.set_trans(Tween.TRANS_SINE)
	_t_scale.set_ease(Tween.EASE_IN_OUT)
	_t_scale.tween_property(self, "scale", _base_scale * (1.0 + scale_amount), scale_time)
	_t_scale.tween_property(self, "scale", _base_scale * (1.0 - scale_amount), scale_time)


func stop_idle() -> void:
	if _t_rot and _t_rot.is_valid(): _t_rot.kill()
	if _t_scale and _t_scale.is_valid(): _t_scale.kill()


func restart_idle() -> void:
	stop_idle()
	if start_random_offset:
		_apply_random_phase()
	_start_loops()
