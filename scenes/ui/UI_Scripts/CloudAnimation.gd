extends Control
# Attach to: a parent Control that spawns and moves clouds (jeepney-style)

@export var cloud_textures: Array[Texture2D] = []
@export var cloud_count: int = 3

# Movement
@export var speed_min: float = 8.0
@export var speed_max: float = 18.0

# Vertical spawn band
@export var y_min: float = 20.0
@export var y_max: float = 160.0

# Uniform scale
@export var scale_min: float = 0.8
@export var scale_max: float = 1.2

# Transparency
@export var alpha_min: float = 0.75
@export var alpha_max: float = 1.0

# Texture safety
@export var auto_fit_max_width_px: float = 220.0

# Manual control
@export var destroy_x: float = -1.0
@export var respawn_x: float = -120.0

# ✅ START FILL CONTROL (your request)
@export var start_fill_min_x: float = 0.0          # left boundary to fill on start
@export var start_fill_max_x: float = -1.0         # -1 = use size.x (right boundary)
@export var start_fill_allow_offscreen: float = 0.0 # e.g. 120 to spawn a bit beyond edges
@export var initial_jitter_strength: float = 0.3

# Z-layer
@export var cloud_z_index: int = -10

var _clouds: Array[Dictionary] = []

func _ready() -> void:
	randomize()
	_spawn_initial_distributed()

func _process(delta: float) -> void:
	var right_edge: float = _get_destroy_x()

	for i in range(_clouds.size() - 1, -1, -1):
		var entry := _clouds[i]
		var c: TextureRect = entry.node

		if not is_instance_valid(c):
			_clouds.remove_at(i)
			continue

		c.position.x += entry.speed * delta

		if c.position.x > right_edge:
			_respawn_cloud_from_left(entry)

	while _clouds.size() < cloud_count:
		_spawn_one_from_left()

# ─────────────────────────────────────────
# INITIAL SPAWN (fills chosen X range)
# ─────────────────────────────────────────
func _spawn_initial_distributed() -> void:
	var left: float = start_fill_min_x - start_fill_allow_offscreen
	var right: float = _get_start_fill_max_x() + start_fill_allow_offscreen
	var width: float = max(right - left, 1.0)

	var count: int = max(cloud_count, 1)
	var step: float = width / float(count)

	for i in range(count):
		var entry := _make_cloud_entry()
		_apply_cloud_style(entry)

		var c: TextureRect = entry.node
		var base_x: float = left + step * float(i)
		var jitter: float = randf_range(-step * initial_jitter_strength, step * initial_jitter_strength)

		c.position.x = clamp(base_x + jitter, left, right)

# ─────────────────────────────────────────
# SPAWN FROM LEFT (runtime)
# ─────────────────────────────────────────
func _spawn_one_from_left() -> void:
	var entry := _make_cloud_entry()
	_apply_cloud_style(entry)
	var c: TextureRect = entry.node
	c.position.x = respawn_x

# ─────────────────────────────────────────
# CREATE CLOUD
# ─────────────────────────────────────────
func _make_cloud_entry() -> Dictionary:
	var c := TextureRect.new()
	c.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.z_as_relative = false
	c.z_index = cloud_z_index
	add_child(c)

	var entry := {
		"node": c,
		"speed": randf_range(speed_min, speed_max)
	}
	_clouds.append(entry)
	return entry

# ─────────────────────────────────────────
# STYLE
# ─────────────────────────────────────────
func _apply_cloud_style(entry: Dictionary) -> void:
	var c: TextureRect = entry.node

	if cloud_textures.size() > 0:
		c.texture = cloud_textures[randi() % cloud_textures.size()]

	entry.speed = randf_range(speed_min, speed_max)

	var s: float = randf_range(scale_min, scale_max)
	if c.texture:
		var tex_w: float = float(c.texture.get_width())
		var fit: float = auto_fit_max_width_px / max(tex_w, 1.0)
		s *= fit

	c.scale = Vector2(s, s)
	c.modulate.a = randf_range(alpha_min, alpha_max)
	c.position.y = randf_range(y_min, min(y_max, size.y - 1.0))

# ─────────────────────────────────────────
# RECYCLE
# ─────────────────────────────────────────
func _respawn_cloud_from_left(entry: Dictionary) -> void:
	var c: TextureRect = entry.node
	_apply_cloud_style(entry)
	c.position.x = respawn_x

# ─────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────
func _get_start_fill_max_x() -> float:
	if start_fill_max_x >= 0.0:
		return start_fill_max_x
	return max(size.x, 1.0)

func _get_destroy_x() -> float:
	if destroy_x >= 0.0:
		return destroy_x
	return size.x + _max_cloud_width()

func _cloud_width_px(c: TextureRect) -> float:
	if c.texture:
		return float(c.texture.get_width()) * c.scale.x
	return c.size.x * c.scale.x

func _max_cloud_width() -> float:
	var max_w: float = 0.0
	for entry in _clouds:
		var c: TextureRect = entry.node
		if is_instance_valid(c):
			max_w = max(max_w, _cloud_width_px(c))
	return max_w
