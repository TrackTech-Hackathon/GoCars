extends CharacterBody2D
class_name Vehicle

## Vehicle entity that can be controlled via code commands.
## Supports: go(), stop(), turn_left(), turn_right(), wait(seconds)
##
## Vehicles automatically stop at red lights when they enter a stoplight's
## detection zone. They resume when the light turns green.

signal reached_destination(vehicle_id: String)
signal crashed(vehicle_id: String)
signal stopped_at_light(vehicle_id: String, stoplight_id: String)
signal resumed_from_light(vehicle_id: String, stoplight_id: String)
signal off_road_crash(vehicle_id: String)

# Vehicle properties
@export var vehicle_id: String = "car1"
@export var speed: float = 200.0  # Pixels per second
@export var destination: Vector2 = Vector2.ZERO

# Vehicle state (0 = crashed, 1 = normal/active)
var vehicle_state: int = 1

# Movement state
var is_moving: bool = false
var is_waiting: bool = false
var wait_timer: float = 0.0
var queued_turn: String = ""  # "left" or "right" or ""
var direction: Vector2 = Vector2.RIGHT  # Current facing direction

# Speed multiplier (for car.speed() function)
var speed_multiplier: float = 1.0

# Stoplight awareness
var _nearby_stoplights: Array = []  # Array of Stoplight nodes in range
var _stopped_at_stoplight: Stoplight = null  # Currently stopped at this stoplight
var _wants_to_move: bool = false  # True if go() was called (intention to move)

# Intersection/turn tracking
var _intersections: Array = []  # Array of intersection positions (Vector2)
var _is_turning: bool = false
var _turn_progress: float = 0.0
var _turn_start_rotation: float = 0.0
var _turn_target_rotation: float = 0.0
var _turn_start_direction: Vector2 = Vector2.ZERO

# Distance threshold for reaching destination
const DESTINATION_THRESHOLD: float = 10.0

# Distance at which vehicle detects stoplights (in pixels)
const STOPLIGHT_DETECTION_RANGE: float = 100.0

# Distance at which vehicle must stop for red light (in pixels)
const STOPLIGHT_STOP_DISTANCE: float = 50.0

# Distance at which vehicle detects intersections (in pixels)
const INTERSECTION_DETECTION_RANGE: float = 30.0

# Turn animation duration in seconds
const TURN_DURATION: float = 0.3

# TileMap reference for road checking
var _tile_map_layer: TileMapLayer = null
const ROAD_TILE_COLUMN_START: int = 1  # Columns 1-16 are road tiles

# Tile-based movement
var _tiles_to_move: int = 0
var _moving_to_tile: bool = false
var _target_tile_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	# Add to vehicles group for detection
	add_to_group("vehicles")

	# Set up collision
	set_collision_layer_value(1, true)  # Layer 1 for vehicles
	set_collision_mask_value(1, true)   # Detect other vehicles


func _physics_process(delta: float) -> void:
	# Don't process if crashed
	if vehicle_state == 0:
		return

	# Handle waiting (from wait() command)
	if is_waiting:
		wait_timer -= delta
		if wait_timer <= 0:
			is_waiting = false
			wait_timer = 0.0
		return

	# Handle smooth turning animation
	if _is_turning:
		_process_turn(delta)
		return

	# Check stoplight state if we want to move
	if _wants_to_move:
		_check_stoplights()

	# Handle movement
	if is_moving:
		# Check for queued turn at intersection
		if queued_turn != "":
			_check_intersection_for_turn()
		_move(delta)
		_check_destination()


func _move(delta: float) -> void:
	# Check if car is on a road tile
	if _tile_map_layer != null:
		if not _is_on_road():
			_on_off_road_crash()
			return

	var actual_speed = speed * speed_multiplier
	velocity = direction * actual_speed
	move_and_slide()

	# Check for collisions with other vehicles
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		if collision.get_collider() is Vehicle:
			var other_vehicle = collision.get_collider() as Vehicle

			# If we hit a crashed car, just this car crashes
			if other_vehicle.vehicle_state == 0:
				_on_crash()
				return

			# If both cars are active, both crash
			if vehicle_state == 1 and other_vehicle.vehicle_state == 1:
				_on_crash()
				other_vehicle._on_crash()
				return


func _check_destination() -> void:
	if destination != Vector2.ZERO:
		var distance = global_position.distance_to(destination)
		if distance < DESTINATION_THRESHOLD:
			stop()
			reached_destination.emit(vehicle_id)


func _on_crash() -> void:
	stop()
	vehicle_state = 0  # Mark as crashed
	modulate = Color(0.5, 0.5, 0.5, 1.0)  # Darken the sprite to show it's crashed
	crashed.emit(vehicle_id)
	# TODO: Change sprite to crashed sprite when available


func _on_off_road_crash() -> void:
	stop()
	vehicle_state = 0  # Mark as crashed
	modulate = Color(0.5, 0.5, 0.5, 1.0)  # Darken the sprite to show it's crashed
	off_road_crash.emit(vehicle_id)
	# TODO: Change sprite to crashed sprite when available


# ============================================
# Command Functions (called by SimulationEngine)
# ============================================

## Start moving forward continuously
func go() -> void:
	_wants_to_move = true
	# Only actually move if not blocked by a red light
	if _stopped_at_stoplight == null:
		is_moving = true


## Stop immediately
func stop() -> void:
	is_moving = false
	_wants_to_move = false
	_stopped_at_stoplight = null
	velocity = Vector2.ZERO


## Queue a 90-degree left turn at next intersection
func turn_left() -> void:
	queued_turn = "left"
	# If not moving or no intersections registered, turn immediately
	if not is_moving or _intersections.is_empty():
		_execute_turn("left")


## Queue a 90-degree right turn at next intersection
func turn_right() -> void:
	queued_turn = "right"
	# If not moving or no intersections registered, turn immediately
	if not is_moving or _intersections.is_empty():
		_execute_turn("right")


## Pause movement for specified seconds
func wait(seconds: int) -> void:
	is_waiting = true
	wait_timer = float(seconds)


## Set speed multiplier (0.5 to 2.0)
func set_speed(value: float) -> void:
	speed_multiplier = clamp(value, 0.5, 2.0)


## Turn left or right (simplified - no intersection required)
func turn(turn_direction: String) -> void:
	if turn_direction == "left":
		_execute_turn("left")
	elif turn_direction == "right":
		_execute_turn("right")


## Move a specific number of tiles
func move(tiles: int) -> void:
	_tiles_to_move = tiles
	# Movement will be handled in physics process


## Check if there's a road in front of the car
func is_front_road() -> bool:
	if _tile_map_layer == null:
		return false

	# Get the tile in front based on current direction
	var front_offset = direction.normalized() * 64  # One tile size ahead
	var front_pos = global_position + front_offset
	return _is_road_at_position(front_pos)


## Check if there's a road to the left of the car
func is_left_road() -> bool:
	if _tile_map_layer == null:
		return false

	# Get the tile to the left based on current direction
	var left_direction = direction.rotated(-PI / 2)  # 90 degrees counter-clockwise
	var left_offset = left_direction.normalized() * 64
	var left_pos = global_position + left_offset
	return _is_road_at_position(left_pos)


## Check if there's a road to the right of the car
func is_right_road() -> bool:
	if _tile_map_layer == null:
		return false

	# Get the tile to the right based on current direction
	var right_direction = direction.rotated(PI / 2)  # 90 degrees clockwise
	var right_offset = right_direction.normalized() * 64
	var right_pos = global_position + right_offset
	return _is_road_at_position(right_pos)


## Check if there's ANY car (crashed or active) in front
func is_front_car() -> bool:
	var front_offset = direction.normalized() * 64  # One tile size ahead
	var front_pos = global_position + front_offset
	return _is_vehicle_at_position(front_pos)


## Check if there's a CRASHED car in front
func is_front_crashed_car() -> bool:
	var front_offset = direction.normalized() * 64  # One tile size ahead
	var front_pos = global_position + front_offset
	return _is_crashed_vehicle_at_position(front_pos)


# ============================================
# Utility Functions
# ============================================

## Set the destination for this vehicle
func set_destination(dest: Vector2) -> void:
	destination = dest


## Check if vehicle has reached its destination
func at_destination() -> bool:
	if destination == Vector2.ZERO:
		return false
	return global_position.distance_to(destination) < DESTINATION_THRESHOLD


## Get distance to destination
func distance_to_destination() -> float:
	if destination == Vector2.ZERO:
		return -1.0
	return global_position.distance_to(destination)


## Reset vehicle to initial state
func reset(start_pos: Vector2, start_dir: Vector2 = Vector2.RIGHT) -> void:
	global_position = start_pos
	direction = start_dir.normalized()
	rotation = direction.angle()
	is_moving = false
	is_waiting = false
	wait_timer = 0.0
	queued_turn = ""
	speed_multiplier = 1.0
	velocity = Vector2.ZERO
	_wants_to_move = false
	_stopped_at_stoplight = null
	# Reset turn state
	_is_turning = false
	_turn_progress = 0.0


# ============================================
# Stoplight Detection
# ============================================

## Register a stoplight that this vehicle should be aware of
func add_stoplight(stoplight: Stoplight) -> void:
	if not stoplight in _nearby_stoplights:
		_nearby_stoplights.append(stoplight)
		# Connect to state change signal
		if not stoplight.state_changed.is_connected(_on_stoplight_changed):
			stoplight.state_changed.connect(_on_stoplight_changed)


## Remove a stoplight from awareness
func remove_stoplight(stoplight: Stoplight) -> void:
	_nearby_stoplights.erase(stoplight)
	if stoplight == _stopped_at_stoplight:
		_stopped_at_stoplight = null
		if _wants_to_move:
			is_moving = true


## Check if any nearby stoplight requires us to stop
func _check_stoplights() -> void:
	# If already stopped at a light, check if we can resume
	if _stopped_at_stoplight != null:
		if not _stopped_at_stoplight.should_stop():
			# Light turned green, resume movement
			resumed_from_light.emit(vehicle_id, _stopped_at_stoplight.stoplight_id)
			_stopped_at_stoplight = null
			is_moving = true
		return

	# Check all nearby stoplights
	for stoplight in _nearby_stoplights:
		if stoplight.should_stop():
			# Check if we're close enough to need to stop
			var distance = global_position.distance_to(stoplight.global_position)
			if distance < STOPLIGHT_STOP_DISTANCE:
				# Need to stop at this light
				_stopped_at_stoplight = stoplight
				is_moving = false
				stopped_at_light.emit(vehicle_id, stoplight.stoplight_id)
				return


## Called when any connected stoplight changes state
func _on_stoplight_changed(stoplight_id: String, new_state: String) -> void:
	# If we're stopped at this light and it turned green, resume
	if _stopped_at_stoplight != null and _stopped_at_stoplight.stoplight_id == stoplight_id:
		if new_state == "green":
			resumed_from_light.emit(vehicle_id, stoplight_id)
			_stopped_at_stoplight = null
			if _wants_to_move:
				is_moving = true


## Check if vehicle is currently stopped at a red light
func is_at_red_light() -> bool:
	return _stopped_at_stoplight != null


## Check if there's a red light ahead (within detection range)
func is_blocked_by_light() -> bool:
	for stoplight in _nearby_stoplights:
		if stoplight.should_stop():
			var distance = global_position.distance_to(stoplight.global_position)
			if distance < STOPLIGHT_DETECTION_RANGE:
				return true
	return false


# ============================================
# Intersection Detection & Turn Mechanics
# ============================================

## Register an intersection position that this vehicle should be aware of
func add_intersection(intersection_pos: Vector2) -> void:
	if not intersection_pos in _intersections:
		_intersections.append(intersection_pos)


## Remove an intersection from awareness
func remove_intersection(intersection_pos: Vector2) -> void:
	_intersections.erase(intersection_pos)


## Clear all registered intersections
func clear_intersections() -> void:
	_intersections.clear()


## Check if vehicle is at an intersection and should execute queued turn
func _check_intersection_for_turn() -> void:
	for intersection_pos in _intersections:
		var distance = global_position.distance_to(intersection_pos)
		if distance < INTERSECTION_DETECTION_RANGE:
			# At intersection, execute the queued turn
			_execute_turn(queued_turn)
			return


## Execute a turn (starts smooth rotation animation)
func _execute_turn(turn_direction: String) -> void:
	if turn_direction == "":
		return

	# Start the turn animation
	_is_turning = true
	_turn_progress = 0.0
	_turn_start_rotation = rotation
	_turn_start_direction = direction

	if turn_direction == "left":
		_turn_target_rotation = rotation - PI / 2
	elif turn_direction == "right":
		_turn_target_rotation = rotation + PI / 2

	# Clear the queued turn
	queued_turn = ""


## Process smooth turn animation
func _process_turn(delta: float) -> void:
	_turn_progress += delta / TURN_DURATION

	if _turn_progress >= 1.0:
		# Turn complete
		_turn_progress = 1.0
		_is_turning = false

		# Snap to exact target rotation
		rotation = _turn_target_rotation
		direction = Vector2.RIGHT.rotated(rotation)
	else:
		# Interpolate rotation smoothly (ease in-out)
		var t = _ease_in_out(_turn_progress)
		rotation = lerp(_turn_start_rotation, _turn_target_rotation, t)
		direction = Vector2.RIGHT.rotated(rotation)


## Ease in-out function for smooth animation
func _ease_in_out(t: float) -> float:
	if t < 0.5:
		return 2.0 * t * t
	else:
		return 1.0 - pow(-2.0 * t + 2.0, 2.0) / 2.0


## Check if vehicle is currently at an intersection
func at_intersection() -> bool:
	for intersection_pos in _intersections:
		var distance = global_position.distance_to(intersection_pos)
		if distance < INTERSECTION_DETECTION_RANGE:
			return true
	return false


## Check if vehicle is currently turning
func is_turning() -> bool:
	return _is_turning


# ============================================
# Road Detection
# ============================================

## Set the TileMapLayer reference for road checking
func set_tile_map_layer(tilemap: TileMapLayer) -> void:
	_tile_map_layer = tilemap


## Check if vehicle is currently on a road tile
func _is_on_road() -> bool:
	if _tile_map_layer == null:
		return true  # If no tilemap, assume roads everywhere

	return _is_road_at_position(global_position)


## Check if there's a road at a specific world position
func _is_road_at_position(world_pos: Vector2) -> bool:
	if _tile_map_layer == null:
		return true

	var tile_pos = _tile_map_layer.local_to_map(_tile_map_layer.to_local(world_pos))
	var atlas_coords = _tile_map_layer.get_cell_atlas_coords(tile_pos)

	# Check if tile exists and is a road (columns 1-16 are roads)
	if atlas_coords == Vector2i(-1, -1):
		return false  # No tile

	return atlas_coords.x >= ROAD_TILE_COLUMN_START


## Check if there's ANY vehicle at a specific world position
func _is_vehicle_at_position(world_pos: Vector2) -> bool:
	# Get all vehicles in the scene
	var vehicles = get_tree().get_nodes_in_group("vehicles")
	for vehicle in vehicles:
		if vehicle == self:
			continue  # Skip self
		var distance = vehicle.global_position.distance_to(world_pos)
		if distance < 32:  # Within half a tile (64/2)
			return true
	return false


## Check if there's a CRASHED vehicle at a specific world position
func _is_crashed_vehicle_at_position(world_pos: Vector2) -> bool:
	# Get all vehicles in the scene
	var vehicles = get_tree().get_nodes_in_group("vehicles")
	for vehicle in vehicles:
		if vehicle == self:
			continue  # Skip self
		if vehicle.vehicle_state == 0:  # Check if crashed
			var distance = vehicle.global_position.distance_to(world_pos)
			if distance < 32:  # Within half a tile (64/2)
				return true
	return false
