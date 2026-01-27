extends Control
# Attach to: a Control node that represents your lane area (same role as JeepneyLane)
#
# Spawns TextureRects that:
# - move left/right depending on lane direction (dir = -1 or +1)
# - animate by alternating between 2 textures (frame_a / frame_b) like a flipbook
# - supports manual offsets (per lane + per direction), scale ranges, spawn gaps, delays, edge buffer
# - optional bounce like your previous controller

# ─────────────────────────────────────────
# FLIPBOOK FRAMES (2 textures)
# ─────────────────────────────────────────
@export var frame_a: Texture2D
@export var frame_b: Texture2D

@export var fps_min: float = 6.0
@export var fps_max: float = 10.0
@export var random_start_frame: bool = true

# ─────────────────────────────────────────
# LANE DIRECTION
# -1 = spawn RIGHT, move LEFT
# +1 = spawn LEFT,  move RIGHT
# ─────────────────────────────────────────
@export var lane1_dir: int = -1
@export var lane2_dir: int =  1

# ─────────────────────────────────────────
# SPEED (per lane)
# ─────────────────────────────────────────
@export var lane1_min_speed: float = 70.0
@export var lane1_max_speed: float = 120.0
@export var lane2_min_speed: float = 60.0
@export var lane2_max_speed: float = 110.0

# ─────────────────────────────────────────
# SPAWN DELAYS (per lane)
# ─────────────────────────────────────────
@export var lane1_spawn_delay_min: float = 2.0
@export var lane1_spawn_delay_max: float = 5.0
@export var lane2_spawn_delay_min: float = 2.0
@export var lane2_spawn_delay_max: float = 5.0

# ─────────────────────────────────────────
# LANE Y POSITIONS
# ─────────────────────────────────────────
@export var spawn_y_pos_1: float = 40.0
@export var spawn_y_pos_2: float = 140.0

# ─────────────────────────────────────────
# SCALE (per lane)
# ─────────────────────────────────────────
@export var lane1_scale_min: float = 0.95
@export var lane1_scale_max: float = 1.05
@export var lane2_scale_min: float = 0.95
@export var lane2_scale_max: float = 1.05

# ─────────────────────────────────────────
# ANTI-OVERLAP (per lane)
# ─────────────────────────────────────────
@export var lane1_min_spawn_gap_px: float = 260.0
@export var lane2_min_spawn_gap_px: float = 260.0
@export var lane1_retry_delay: float = 0.35
@export var lane2_retry_delay: float = 0.35

@export var edge_buffer: float = 40.0

# ─────────────────────────────────────────
# OFFSETS (manual manipulation)
# ─────────────────────────────────────────
@export var lane1_spawn_offset: Vector2 = Vector2(0, 0)
@export var lane2_spawn_offset: Vector2 = Vector2(0, 0)

@export var offset_when_moving_right: Vector2 = Vector2(0, 0)
@export var offset_when_moving_left: Vector2 = Vector2(0, 0)

# Rare: nudge the rect itself if your art has padding weirdness
@export var texture_rect_extra_offset: Vector2 = Vector2(0, 0)

# ─────────────────────────────────────────
# OPTIONAL BOUNCE
# ─────────────────────────────────────────
@export var bounce_enabled: bool = true
@export var bounce_amplitude_px: float = 2.5
@export var bounce_freq_min: float = 1.2
@export var bounce_freq_max: float = 2.2
@export var bounce_phase_random: bool = true

@export var debug_print_size: bool = false


var _rng := RandomNumberGenerator.new()
var _lane_size: Vector2

# Each entry:
# { node, lane, dir, speed, base_y, t, b_freq, b_phase, fps, frame_a_first, flip_timer }
var _items: Array[Dictionary] = []


func _ready() -> void:
	_rng.randomize()
	_lane_size = size
	if debug_print_size:
		print("[FlipbookLaneController] size = ", _lane_size)

	_schedule_next_spawn_lane(1)
	_schedule_next_spawn_lane(2)

	_try_spawn_lane(1, true)
	_try_spawn_lane(2, true)


func _process(delta: float) -> void:
	if size != _lane_size:
		_lane_size = size

	for i in range(_items.size() - 1, -1, -1):
		var e := _items[i]
		var node: TextureRect = e["node"]

		if !is_instance_valid(node):
			_items.remove_at(i)
			continue

		var dir: int = int(e["dir"])
		var spd: float = float(e["speed"])

		# Move X (same core logic you wanted extracted)
		node.position.x += spd * float(dir) * delta

		# Optional bounce
		if bounce_enabled:
			e["t"] = float(e["t"]) + delta
			var t: float = float(e["t"])
			var base_y: float = float(e["base_y"])
			var b_freq: float = float(e["b_freq"])
			var b_phase: float = float(e["b_phase"])
			node.position.y = base_y + sin((t * TAU * b_freq) + b_phase) * bounce_amplitude_px

		# 2-frame flipbook
		var fps: float = float(e["fps"])
		if fps > 0.0:
			e["flip_timer"] = float(e["flip_timer"]) - delta
			if float(e["flip_timer"]) <= 0.0:
				e["flip_timer"] = 1.0 / fps
				e["frame_a_first"] = !bool(e["frame_a_first"])
				_apply_frame(node, bool(e["frame_a_first"]))

		_items[i] = e

		# Cleanup offscreen
		var w := node.size.x * node.scale.x
		if dir == 1:
			if node.position.x > (_lane_size.x + edge_buffer + w):
				node.queue_free()
				_items.remove_at(i)
		else:
			if node.position.x < (-edge_buffer - w):
				node.queue_free()
				_items.remove_at(i)


# ─────────────────────────────────────────
# Spawn scheduling
# ─────────────────────────────────────────
func _schedule_next_spawn_lane(lane: int) -> void:
	var wait_time: float = (
		_rng.randf_range(lane1_spawn_delay_min, lane1_spawn_delay_max) if lane == 1
		else _rng.randf_range(lane2_spawn_delay_min, lane2_spawn_delay_max)
	)

	get_tree().create_timer(wait_time).timeout.connect(func():
		_try_spawn_lane(lane, false)
	)


func _try_spawn_lane(lane: int, force: bool) -> void:
	if frame_a == null and frame_b == null:
		push_warning("FlipbookLaneController: assign at least one frame texture (frame_a or frame_b).")
		_schedule_next_spawn_lane(lane)
		return

	if !force and _is_lane_spawn_blocked(lane):
		var retry: float = lane1_retry_delay if lane == 1 else lane2_retry_delay
		get_tree().create_timer(retry).timeout.connect(func():
			_try_spawn_lane(lane, false)
		)
		return

	_spawn_item_lane(lane)
	_schedule_next_spawn_lane(lane)


func _is_lane_spawn_blocked(lane: int) -> bool:
	var min_gap: float = lane1_min_spawn_gap_px if lane == 1 else lane2_min_spawn_gap_px
	var dir: int = lane1_dir if lane == 1 else lane2_dir

	# dir=+1 spawns from LEFT edge
	if dir == 1:
		var left_edge_x: float = -edge_buffer
		for e in _items:
			if int(e["lane"]) != lane:
				continue
			var n: TextureRect = e["node"]
			if !is_instance_valid(n):
				continue
			if n.position.x < (left_edge_x + min_gap):
				return true
		return false

	# dir=-1 spawns from RIGHT edge
	var right_edge_x: float = _lane_size.x + edge_buffer
	for e2 in _items:
		if int(e2["lane"]) != lane:
			continue
		var n2: TextureRect = e2["node"]
		if !is_instance_valid(n2):
			continue
		if n2.position.x > (right_edge_x - min_gap):
			return true
	return false


# ─────────────────────────────────────────
# Spawning
# ─────────────────────────────────────────
func _spawn_item_lane(lane: int) -> void:
	var node := TextureRect.new()
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	node.texture_repeat = CanvasItem.TEXTURE_REPEAT_DISABLED
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE

	# Choose a base texture (whichever exists)
	var base_tex: Texture2D = frame_a if frame_a != null else frame_b
	node.texture = base_tex
	node.custom_minimum_size = base_tex.get_size()

	add_child(node)

	# Optional nudge (rare)
	node.position += texture_rect_extra_offset

	# Lane dir
	var dir: int = lane1_dir if lane == 1 else lane2_dir
	node.flip_h = (dir < 0)

	# Scale per lane
	var s: float = (
		_rng.randf_range(lane1_scale_min, lane1_scale_max) if lane == 1
		else _rng.randf_range(lane2_scale_min, lane2_scale_max)
	)
	node.scale = Vector2(s, s)

	await get_tree().process_frame

	var node_size := node.size * node.scale
	var max_y: float = max(0.0, _lane_size.y - node_size.y)

	# Base Y
	var lane_y: float = spawn_y_pos_1 if lane == 1 else spawn_y_pos_2
	var base_y: float = clamp(lane_y, 0.0, max_y)

	# Apply offsets
	var lane_off: Vector2 = lane1_spawn_offset if lane == 1 else lane2_spawn_offset
	var dir_off: Vector2 = offset_when_moving_right if dir == 1 else offset_when_moving_left

	base_y = clamp(base_y + lane_off.y + dir_off.y, 0.0, max_y)

	# Spawn X based on direction
	if dir == 1:
		node.position.x = -edge_buffer - node_size.x
	else:
		node.position.x = _lane_size.x + edge_buffer

	node.position.x += lane_off.x + dir_off.x
	node.position.y = base_y

	# Speed per lane
	var spd: float = (
		_rng.randf_range(lane1_min_speed, lane1_max_speed) if lane == 1
		else _rng.randf_range(lane2_min_speed, lane2_max_speed)
	)

	# Flipbook fps per item
	var fps: float = _rng.randf_range(fps_min, fps_max)
	var start_a: bool = true
	if random_start_frame:
		start_a = (_rng.randi() % 2) == 0

	_apply_frame(node, start_a)

	# Bounce params
	var b_freq: float = _rng.randf_range(bounce_freq_min, bounce_freq_max)
	var b_phase: float = _rng.randf_range(0.0, TAU) if bounce_phase_random else 0.0

	_items.append({
		"node": node,
		"lane": lane,
		"dir": dir,
		"speed": spd,
		"base_y": base_y,
		"t": 0.0,
		"b_freq": b_freq,
		"b_phase": b_phase,
		"fps": fps,
		"frame_a_first": start_a,
		"flip_timer": (1.0 / max(0.001, fps))
	})


func _apply_frame(node: TextureRect, use_a: bool) -> void:
	if !is_instance_valid(node):
		return

	if frame_a == null and frame_b == null:
		return
	if frame_a == null:
		node.texture = frame_b
		return
	if frame_b == null:
		node.texture = frame_a
		return

	node.texture = frame_a if use_a else frame_b
