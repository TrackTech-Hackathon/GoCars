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

# ============================================
# Vehicle Types
# ============================================
enum VehicleType {
	SEDAN,      # Standard car - Speed 1.0x, Size 1.0
	SUV,        # Larger vehicle - Speed 0.9x, Size 1.2
	MOTORCYCLE, # Fast and small - Speed 1.3x, Size 0.5 (can lane split)
	JEEPNEY,    # Filipino transport - Speed 0.7x, Size 1.5
	TRUCK,      # Large cargo - Speed 0.6x, Size 2.0 (longer stopping)
	TRICYCLE    # Small 3-wheeler - Speed 0.7x, Size 0.7 (tight turns)
}

# Vehicle type configuration
const VEHICLE_CONFIG: Dictionary = {
	VehicleType.SEDAN: {
		"name": "Sedan",
		"speed_mult": 1.0,
		"size_mult": 1.0,
		"color": Color(0.2, 0.4, 0.8),  # Blue
		"can_lane_split": false,
		"stopping_distance": 1.0
	},
	VehicleType.SUV: {
		"name": "SUV",
		"speed_mult": 0.9,
		"size_mult": 1.2,
		"color": Color(0.3, 0.3, 0.3),  # Dark gray
		"can_lane_split": false,
		"stopping_distance": 1.1
	},
	VehicleType.MOTORCYCLE: {
		"name": "Motorcycle",
		"speed_mult": 1.3,
		"size_mult": 0.5,
		"color": Color(0.8, 0.2, 0.2),  # Red
		"can_lane_split": true,
		"stopping_distance": 0.7
	},
	VehicleType.JEEPNEY: {
		"name": "Jeepney",
		"speed_mult": 0.7,
		"size_mult": 1.5,
		"color": Color(0.9, 0.7, 0.1),  # Yellow/Gold
		"can_lane_split": false,
		"stopping_distance": 1.3
	},
	VehicleType.TRUCK: {
		"name": "Truck",
		"speed_mult": 0.6,
		"size_mult": 2.0,
		"color": Color(0.5, 0.3, 0.1),  # Brown
		"can_lane_split": false,
		"stopping_distance": 1.5
	},
	VehicleType.TRICYCLE: {
		"name": "Tricycle",
		"speed_mult": 0.7,
		"size_mult": 0.7,
		"color": Color(0.2, 0.7, 0.3),  # Green
		"can_lane_split": false,
		"stopping_distance": 0.8
	}
}

# Vehicle properties
@export var vehicle_id: String = "car1"
@export var vehicle_type: VehicleType = VehicleType.SEDAN
@export var speed: float = 200.0  # Base pixels per second
@export var destination: Vector2 = Vector2.ZERO

# Vehicle state (0 = crashed, 1 = normal/active)
var vehicle_state: int = 1

# Type-based properties (set in _ready based on vehicle_type)
var type_speed_mult: float = 1.0
var type_size_mult: float = 1.0
var can_lane_split: bool = false
var stopping_distance_mult: float = 1.0

# Movement state
var is_moving: bool = false
var is_waiting: bool = false
var wait_timer: float = 0.0
var queued_turn: String = ""  # "left" or "right" or ""
var direction: Vector2 = Vector2.RIGHT  # Current facing direction

# Speed multiplier (for car.speed() function)
var speed_multiplier: float = 1.0

# Auto-navigate mode - car automatically follows road
var auto_navigate: bool = false
var _nav_check_timer: float = 0.0
const NAV_CHECK_INTERVAL: float = 0.1  # Check road every 100ms

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


func _ready() -> void:
	# Add to vehicles group for detection
	add_to_group("vehicles")

	# Set up collision
	set_collision_layer_value(1, true)  # Layer 1 for vehicles
	set_collision_mask_value(1, true)   # Detect other vehicles

	# Apply vehicle type configuration
	_apply_vehicle_type()


## Apply configuration based on vehicle type
func _apply_vehicle_type() -> void:
	if vehicle_type in VEHICLE_CONFIG:
		var config = VEHICLE_CONFIG[vehicle_type]
		type_speed_mult = config["speed_mult"]
		type_size_mult = config["size_mult"]
		can_lane_split = config["can_lane_split"]
		stopping_distance_mult = config["stopping_distance"]

		# Apply color to sprite if it exists
		var sprite = get_node_or_null("Sprite2D")
		if sprite:
			sprite.modulate = config["color"]

		# Apply size scaling
		scale = Vector2(type_size_mult, type_size_mult)


## Set vehicle type and apply configuration
func set_vehicle_type(new_type: VehicleType) -> void:
	vehicle_type = new_type
	_apply_vehicle_type()


## Get vehicle type name
func get_vehicle_type_name() -> String:
	if vehicle_type in VEHICLE_CONFIG:
		return VEHICLE_CONFIG[vehicle_type]["name"]
	return "Unknown"


## Get a random vehicle type
static func get_random_type() -> VehicleType:
	var types = [
		VehicleType.SEDAN,
		VehicleType.SUV,
		VehicleType.MOTORCYCLE,
		VehicleType.JEEPNEY,
		VehicleType.TRUCK,
		VehicleType.TRICYCLE
	]
	return types[randi() % types.size()]


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

	# Auto-navigate: check road and turn if needed
	if auto_navigate and is_moving and not _is_turning:
		_nav_check_timer += delta
		if _nav_check_timer >= NAV_CHECK_INTERVAL:
			_nav_check_timer = 0.0
			_auto_navigate_check()

	# Handle movement
	if is_moving:
		# Check for queued turn at intersection
		if queued_turn != "":
			_check_intersection_for_turn()
		_move(delta)
		_check_destination()


func _move(_delta: float) -> void:
	# Check if car is on a road tile
	if _tile_map_layer != null:
		if not _is_on_road():
			_on_off_road_crash()
			return

	# Apply both user speed multiplier and vehicle type speed multiplier
	var actual_speed = speed * speed_multiplier * type_speed_mult
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
func wait(seconds: float) -> void:
	is_waiting = true
	wait_timer = seconds


## Set speed multiplier (0.5 to 2.0)
func set_speed(value: float) -> void:
	speed_multiplier = clamp(value, 0.5, 2.0)


## Get current speed multiplier
func get_speed() -> float:
	return speed_multiplier


## Check if vehicle is currently moving
func is_vehicle_moving() -> bool:
	return is_moving


## Check if vehicle path is blocked (by another car or obstacle)
func is_blocked() -> bool:
	# Check if stopped at a red light
	if _stopped_at_stoplight != null:
		return true
	# Check if there's a car in front
	return is_front_car()


## Turn left or right (simplified - no intersection required)
func turn(turn_direction: String) -> void:
	if turn_direction == "left":
		_execute_turn("left")
	elif turn_direction == "right":
		_execute_turn("right")


## Move a specific number of tiles
func move(tiles: int) -> void:
	if tiles <= 0:
		return
	_tiles_to_move = tiles
	go()  # Start moving, tiles will be counted down


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
# Auto-Navigation System
# ============================================

## Enable auto-navigation mode (car follows road automatically)
func set_auto_navigate(enabled: bool) -> void:
	auto_navigate = enabled
	_nav_check_timer = 0.0


## Check road ahead and turn if needed (called during auto-navigate)
func _auto_navigate_check() -> void:
	if _tile_map_layer == null:
		return

	# If road ahead, keep going
	if is_front_road():
		return

	# No road ahead - check for turns
	# Priority: prefer continuing in same general direction
	var left_has_road = is_left_road()
	var right_has_road = is_right_road()

	if left_has_road and not right_has_road:
		_execute_turn("left")
	elif right_has_road and not left_has_road:
		_execute_turn("right")
	elif left_has_road and right_has_road:
		# Both have roads - could add smarter logic here
		# For now, prefer right (arbitrary choice)
		_execute_turn("right")
	# else: no road anywhere - will crash on next move


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


## Alias for at_destination() to match Python API
func is_at_destination() -> bool:
	return at_destination()


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
	# Reset auto-navigate
	auto_navigate = false
	_nav_check_timer = 0.0
	# Reset tile-based movement
	_tiles_to_move = 0


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


## Alias for at_intersection() to match Python API
func is_at_intersection() -> bool:
	return at_intersection()


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
