extends Control
# Attach to: JeepneyLane (Control)
#
# FIX (smoke going downward):
# Your previous tween used the Control-local Y direction (down is +Y).
# We now FORCE the end Y to be SMALLER than the start Y using min(),
# so it ALWAYS animates upward even if something weird happens with values.

@export var jeepney_texture: Texture2D
@export var tricycle_texture: Texture2D

@export_range(0.0, 1.0, 0.01) var jeepney_chance: float = 0.70

@export var lane1_min_speed: float = 70.0
@export var lane1_max_speed: float = 120.0
@export var lane2_min_speed: float = 60.0
@export var lane2_max_speed: float = 110.0

@export var lane1_spawn_delay_min: float = 2.0
@export var lane1_spawn_delay_max: float = 5.0
@export var lane2_spawn_delay_min: float = 2.0
@export var lane2_spawn_delay_max: float = 5.0

@export var jeepney_scale_min: float = 0.95
@export var jeepney_scale_max: float = 1.05

@export var tricycle_scale_min: float = 0.80
@export var tricycle_scale_max: float = 0.95

@export var tricycle_y_offset_px: float = 12.0

@export var spawn_y_pos_1: float = 40.0
@export var spawn_y_pos_2: float = 140.0

@export var lane1_min_spawn_gap_px: float = 260.0
@export var lane2_min_spawn_gap_px: float = 260.0

@export var lane1_retry_delay: float = 0.35
@export var lane2_retry_delay: float = 0.35

@export var edge_buffer: float = 40.0

@export var bounce_amplitude_px: float = 2.5
@export var bounce_freq_min: float = 1.2
@export var bounce_freq_max: float = 2.2
@export var bounce_phase_random: bool = true

# ─────────────────────────────────────────
# SMOKE (EXHAUST) SETTINGS
# ─────────────────────────────────────────
@export var smoke_texture: Texture2D

@export var smoke_interval_min: float = 0.12
@export var smoke_interval_max: float = 0.28

@export var smoke_lifetime: float = 0.55
@export var smoke_start_scale: float = 0.55
@export var smoke_end_scale: float = 1.25
@export var smoke_start_alpha: float = 0.75
@export var smoke_end_alpha: float = 0.0

@export var smoke_rise_px: float = 22.0
@export var smoke_drift_px: float = 14.0

@export var smoke_base_y_offset_px: float = 8.0
@export var smoke_back_buffer_px: float = 8.0

@export var smoke_jeepney_x_offset_px: float = 0.0
@export var smoke_tricycle_x_offset_px: float = 10.0

@export var debug_print_lane_size: bool = true

var _rng := RandomNumberGenerator.new()
var _lane_size: Vector2

# { node, tex, speed, dir, lane, base_y, b_freq, b_phase, t, smoke_cd }
var _cars: Array[Dictionary] = []

func _ready() -> void:
	_rng.randomize()

	_lane_size = size
	if debug_print_lane_size:
		print("[JeepneyLane] size = ", _lane_size)

	_schedule_next_spawn_lane(1)
	_schedule_next_spawn_lane(2)

	_try_spawn_lane(1, true)
	_try_spawn_lane(2, true)

func _process(delta: float) -> void:
	if size != _lane_size:
		_lane_size = size

	for i in range(_cars.size() - 1, -1, -1):
		var entry := _cars[i]
		var car: TextureRect = entry["node"]
		if !is_instance_valid(car):
			_cars.remove_at(i)
			continue

		var spd: float = float(entry["speed"])
		var dir: int = int(entry["dir"])

		# Move X
		car.position.x += spd * float(dir) * delta

		# Bounce Y
		entry["t"] = float(entry["t"]) + delta
		var t: float = float(entry["t"])
		var base_y: float = float(entry["base_y"])
		var b_freq: float = float(entry["b_freq"])
		var b_phase: float = float(entry["b_phase"])
		car.position.y = base_y + sin((t * TAU * b_freq) + b_phase) * bounce_amplitude_px

		# Smoke emission timer
		entry["smoke_cd"] = float(entry["smoke_cd"]) - delta
		if float(entry["smoke_cd"]) <= 0.0:
			_spawn_smoke_for_vehicle(car, dir, entry["tex"], base_y)
			entry["smoke_cd"] = _rng.randf_range(smoke_interval_min, smoke_interval_max)

		_cars[i] = entry

		var car_w := car.size.x * car.scale.x

		if dir == 1:
			if car.position.x > (_lane_size.x + edge_buffer + car_w):
				car.queue_free()
				_cars.remove_at(i)
		else:
			if car.position.x < (-edge_buffer - car_w):
				car.queue_free()
				_cars.remove_at(i)

# ─────────────────────────────────────────
# Spawn scheduling
# ─────────────────────────────────────────
func _schedule_next_spawn_lane(lane: int) -> void:
	var wait_time: float = _rng.randf_range(lane1_spawn_delay_min, lane1_spawn_delay_max) if lane == 1 \
		else _rng.randf_range(lane2_spawn_delay_min, lane2_spawn_delay_max)

	get_tree().create_timer(wait_time).timeout.connect(func():
		_try_spawn_lane(lane, false)
	)

func _try_spawn_lane(lane: int, force: bool) -> void:
	if jeepney_texture == null and tricycle_texture == null:
		push_warning("JeepneyLane: Assign at least one texture (jeepney_texture or tricycle_texture).")
		_schedule_next_spawn_lane(lane)
		return

	if !force and _is_lane_spawn_blocked(lane):
		var retry: float = lane1_retry_delay if lane == 1 else lane2_retry_delay
		get_tree().create_timer(retry).timeout.connect(func():
			_try_spawn_lane(lane, false)
		)
		return

	_spawn_vehicle_lane(lane)
	_schedule_next_spawn_lane(lane)

func _is_lane_spawn_blocked(lane: int) -> bool:
	var min_gap: float = lane1_min_spawn_gap_px if lane == 1 else lane2_min_spawn_gap_px

	if lane == 1:
		var edge_x: float = _lane_size.x + edge_buffer
		for entry in _cars:
			if int(entry["lane"]) != 1:
				continue
			var car: TextureRect = entry["node"]
			if !is_instance_valid(car):
				continue
			if car.position.x > (edge_x - min_gap):
				return true
		return false

	var left_edge_x: float = -edge_buffer
	for entry in _cars:
		if int(entry["lane"]) != 2:
			continue
		var car2: TextureRect = entry["node"]
		if !is_instance_valid(car2):
			continue
		if car2.position.x < (left_edge_x + min_gap):
			return true
	return false

# ─────────────────────────────────────────
# Vehicle spawn
# ─────────────────────────────────────────
func _pick_vehicle_texture() -> Texture2D:
	if jeepney_texture == null:
		return tricycle_texture
	if tricycle_texture == null:
		return jeepney_texture
	return jeepney_texture if _rng.randf() <= jeepney_chance else tricycle_texture

func _get_scale_for_texture(tex: Texture2D) -> float:
	return _rng.randf_range(tricycle_scale_min, tricycle_scale_max) if tex == tricycle_texture \
		else _rng.randf_range(jeepney_scale_min, jeepney_scale_max)

func _get_y_offset_for_texture(tex: Texture2D) -> float:
	return tricycle_y_offset_px if tex == tricycle_texture else 0.0

func _spawn_vehicle_lane(lane: int) -> void:
	var tex := _pick_vehicle_texture()
	if tex == null:
		return

	var car := TextureRect.new()
	car.texture = tex
	car.mouse_filter = Control.MOUSE_FILTER_IGNORE
	car.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	car.texture_repeat = CanvasItem.TEXTURE_REPEAT_DISABLED

	car.z_index = 1 if lane == 1 else 10

	car.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	car.custom_minimum_size = tex.get_size()
	add_child(car)

	var s := _get_scale_for_texture(tex)
	car.scale = Vector2(s, s)

	await get_tree().process_frame

	var car_size := car.size * car.scale
	var max_y: float = max(0.0, _lane_size.y - car_size.y)

	var lane_y: float = (spawn_y_pos_1 if lane == 1 else spawn_y_pos_2)
	var base_y: float = clamp(lane_y + _get_y_offset_for_texture(tex), 0.0, max_y)

	var spd: float
	var dir: int
	if lane == 1:
		spd = _rng.randf_range(lane1_min_speed, lane1_max_speed)
		dir = -1
		car.flip_h = true
		car.position.x = _lane_size.x + edge_buffer
	else:
		spd = _rng.randf_range(lane2_min_speed, lane2_max_speed)
		dir = 1
		car.flip_h = false
		car.position.x = -edge_buffer - car_size.x

	car.position.y = base_y

	var b_freq: float = _rng.randf_range(bounce_freq_min, bounce_freq_max)
	var b_phase: float = _rng.randf_range(0.0, TAU) if bounce_phase_random else 0.0

	_cars.append({
		"node": car,
		"tex": tex,
		"speed": spd,
		"dir": dir,
		"lane": lane,
		"base_y": base_y,
		"b_freq": b_freq,
		"b_phase": b_phase,
		"t": 0.0,
		"smoke_cd": _rng.randf_range(smoke_interval_min, smoke_interval_max)
	})

# ─────────────────────────────────────────
# Smoke puff
# ─────────────────────────────────────────
func _get_smoke_type_x_offset(tex: Texture2D) -> float:
	return smoke_tricycle_x_offset_px if tex == tricycle_texture else smoke_jeepney_x_offset_px

func _spawn_smoke_for_vehicle(car: TextureRect, dir: int, tex: Texture2D, base_y: float) -> void:
	if smoke_texture == null:
		return
	if !is_instance_valid(car):
		return

	var puff := TextureRect.new()
	puff.texture = smoke_texture
	puff.mouse_filter = Control.MOUSE_FILTER_IGNORE
	puff.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	puff.texture_repeat = CanvasItem.TEXTURE_REPEAT_DISABLED
	puff.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	puff.custom_minimum_size = smoke_texture.get_size()

	puff.z_index = car.z_index - 1
	add_child(puff)

	var car_size := car.size * car.scale

	var type_x_off: float = _get_smoke_type_x_offset(tex)
	var spawn_x: float
	if dir == 1:
		spawn_x = car.position.x - smoke_back_buffer_px + type_x_off
	else:
		spawn_x = car.position.x + car_size.x + smoke_back_buffer_px + type_x_off


	var spawn_y: float = base_y + (car_size.y * 0.65) + smoke_base_y_offset_px

	puff.position = Vector2(spawn_x, spawn_y)
	puff.scale = Vector2(smoke_start_scale, smoke_start_scale)
	puff.modulate.a = smoke_start_alpha

	var drift_sign := -1.0 if _rng.randf() < 0.5 else 1.0

	# ✅ HARD-FORCE "UP":
	# end_y is ALWAYS smaller than start_y, no matter what values are set.
	var end_x := puff.position.x + (smoke_drift_px * drift_sign)
	var end_y: float = puff.position.y - max(1.0, abs(smoke_rise_px))

	var end_pos := Vector2(end_x, end_y)

	var tw := create_tween()
	tw.set_trans(Tween.TRANS_SINE)
	tw.set_ease(Tween.EASE_OUT)

	tw.tween_property(puff, "position", end_pos, smoke_lifetime)
	tw.parallel().tween_property(puff, "scale", Vector2(smoke_end_scale, smoke_end_scale), smoke_lifetime)
	tw.parallel().tween_property(puff, "modulate:a", smoke_end_alpha, smoke_lifetime)

	tw.finished.connect(func():
		if is_instance_valid(puff):
			puff.queue_free()
	)
