extends Control
# Attach to the Logo node (Label / TextureRect / Control)

@export var intro_dim: ColorRect

@export var rot_degrees: float = 2.0
@export var rot_time: float = 2.6

@export var scale_amount: float = 0.035
@export var scale_time: float = 2.2

@export var float_pixels: float = 6.0
@export var float_time: float = 2.4

@export var start_random_offset: bool = true

# Intro sequence timings
@export var intro_enabled: bool = true
@export var intro_wait_before_logo: float = 1
@export var intro_logo_fade_in_time: float = 0.45
@export var intro_hold_center_time: float = 1.5
@export var intro_move_time: float = 0.65
@export var intro_dim_fade_out_time: float = 0.60

@export var intro_bg_color: Color = Color(0.10, 0.10, 0.10, 1.0)
@export var intro_dim_path: NodePath = NodePath("../../../IntroDim")

# Background music
@export var bg_music_player: AudioStreamPlayer

# ------------------------------------------------------------------
# ✅ Splash (TextureRect) that plays BEFORE logo fade-in
# ------------------------------------------------------------------
@export var splash_enabled: bool = true
@export var splash_texture: Texture2D
@export var splash_size: Vector2 = Vector2(320, 320) # independent size (px)
@export var splash_wait_before: float = 0.0          # extra delay before splash shows
@export var splash_fade_in_time: float = 0.25
@export var splash_hold_time: float = 0.40
@export var splash_fade_out_time: float = 0.25

var _base_scale: Vector2
var _base_pos: Vector2

var _t_rot: Tween
var _t_scale: Tween
var _t_float: Tween

var _splash: TextureRect


# ------------------------------------------------------------------
# 🔒 FRAME-0 GUARANTEE (no flash, no alpha race)
# ------------------------------------------------------------------
func _enter_tree() -> void:
	var dim := get_node_or_null(intro_dim_path) as ColorRect
	if dim:
		dim.visible = true
		dim.color.a = 1.0
		dim.process_mode = Node.PROCESS_MODE_DISABLED


func _ready() -> void:
	await get_tree().process_frame

	pivot_offset = size * 0.5
	_base_scale = scale
	_base_pos = position

	# Prep splash node once (hidden, centered, independent)
	_setup_splash()

	if intro_enabled:
		_play_intro()
	else:
		_apply_random_phase()
		_start_loops()


func _setup_splash() -> void:
	# Remove previous if hot-reloading
	if _splash and is_instance_valid(_splash):
		_splash.queue_free()

	_splash = TextureRect.new()
	_splash.name = "IntroSplash"
	_splash.visible = false
	_splash.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# ✅ Texture
	_splash.texture = splash_texture

	# ✅ KEEP ASPECT + centered inside its own rect
	_splash.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_splash.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	# ✅ INDEPENDENT SIZE (not dependent on logo or texture)
	_splash.custom_minimum_size = splash_size
	_splash.size = splash_size

	# ✅ GODOT FIX: ignore parent transforms completely
	_splash.top_level = true
	_splash.scale = Vector2.ONE
	_splash.rotation = 0.0

	_splash.modulate.a = 0.0

	# Add splash as a sibling (safe). top_level ensures independence anyway.
	var p := get_parent()
	if p:
		p.add_child(_splash)
		_splash.z_index = z_index - 1

	_center_splash()


func _center_splash() -> void:
	if not (_splash and is_instance_valid(_splash)):
		return

	# Ensure size stays what you set, even if something tries to resize it
	_splash.size = splash_size

	var vp := get_viewport_rect()
	_splash.global_position = vp.position + (vp.size * 0.5) - (_splash.size * 0.5)


func _play_intro() -> void:
	_kill_loops()

	var dim := get_node_or_null(intro_dim_path) as ColorRect
	if dim:
		dim.visible = true
		dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dim.color = intro_bg_color
		dim.process_mode = Node.PROCESS_MODE_INHERIT

	# Hide logo initially
	modulate.a = 0.0
	scale = _base_scale
	rotation = 0.0

	# Center logo using GLOBAL coordinates
	var vp := get_viewport_rect()
	global_position = vp.position + (vp.size * 0.5) - (size * 0.5)

	# Re-center splash in case of window resize / layout changes
	_center_splash()

	var t := create_tween()
	t.set_trans(Tween.TRANS_SINE)
	t.set_ease(Tween.EASE_IN_OUT)

	# 0) OPTIONAL: splash sequence BEFORE your normal wait/logo fade
	if splash_enabled and splash_texture != null and _splash and is_instance_valid(_splash):
		t.tween_interval(max(0.0, splash_wait_before))

		t.tween_callback(func():
			_center_splash()
			_splash.visible = true
			_splash.modulate.a = 0.0
		)

		# Fade splash in
		t.tween_property(_splash, "modulate:a", 1.0, splash_fade_in_time)
		# Hold
		t.tween_interval(splash_hold_time)
		# Fade splash out
		t.tween_property(_splash, "modulate:a", 0.0, splash_fade_out_time)

		# Hide after fade
		t.tween_callback(func():
			_splash.visible = false
		)

	# 1) Wait before logo appears (your original)
	t.tween_interval(intro_wait_before_logo)

	# 2) Fade logo in (centered)
	t.tween_property(self, "modulate:a", 1.0, intro_logo_fade_in_time)

	# 3) Hold center
	t.tween_interval(intro_hold_center_time)

	# 4) Move to base position
	t.tween_property(self, "position", _base_pos, intro_move_time)

	# 5) Fade out IntroDim EXACTLY once (right before wobble)
	if dim and dim.has_method("fade_out"):
		t.tween_callback(func():
			dim.call("fade_out", intro_dim_fade_out_time)
		)

	# 6) Start wobble loops
	t.tween_callback(func():
		_apply_random_phase()
		_start_loops()
		# Play background music after logo animation completes
		if bg_music_player and is_instance_valid(bg_music_player):
			bg_music_player.play()
	)


func _apply_random_phase() -> void:
	if start_random_offset:
		rotation = deg_to_rad(randf_range(-rot_degrees, rot_degrees))
		scale = _base_scale * (1.0 + randf_range(-scale_amount, scale_amount))
		position = _base_pos + Vector2(0, randf_range(-float_pixels, float_pixels))
	else:
		rotation = 0.0
		scale = _base_scale
		position = _base_pos


func _kill_loops() -> void:
	if _t_rot and _t_rot.is_valid(): _t_rot.kill()
	if _t_scale and _t_scale.is_valid(): _t_scale.kill()
	if _t_float and _t_float.is_valid(): _t_float.kill()


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

	# Float loop
	_t_float = create_tween()
	_t_float.set_loops()
	_t_float.set_trans(Tween.TRANS_SINE)
	_t_float.set_ease(Tween.EASE_IN_OUT)
	_t_float.tween_property(self, "position", _base_pos + Vector2(0, -float_pixels), float_time)
	_t_float.tween_property(self, "position", _base_pos + Vector2(0, float_pixels), float_time)
