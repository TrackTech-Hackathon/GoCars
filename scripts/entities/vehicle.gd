extends CharacterBody2D
class_name Vehicle

## Vehicle entity that can be controlled via code commands.
## Supports: go(), stop(), turn_left(), turn_right(), wait(seconds)
##
## Vehicles do NOT automatically stop at red lights - players must code this!
## Running a red light (passing through when red) costs the player a heart.

signal reached_destination(vehicle_id: String)
signal crashed(vehicle_id: String)
signal ran_red_light(vehicle_id: String, stoplight_id: String)
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
var _is_moving: bool = false
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

# Stoplight awareness (for red light violation detection)
var _nearby_stoplights: Array = []  # Array of Stoplight nodes in range
var _passed_stoplights: Array = []  # Track stoplights we've passed (for violation detection)
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
var _move_start_position: Vector2 = Vector2.ZERO
const TILE_SIZE: float = 64.0  # Pixels per tile

# Command queue for sequential execution
# Commands: {"type": "move", "tiles": N}, {"type": "wait", "seconds": N},
#           {"type": "turn", "direction": "left"/"right"}, {"type": "go"}, {"type": "stop"}
var _command_queue: Array = []
var _current_command: Dictionary = {}  # Currently executing command


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
			# Wait command completed - process next command
			_command_completed()
		return

	# Handle smooth turning animation
	if _is_turning:
		_process_turn(delta)
		return

	# Check for red light violations (player must code stoplight handling!)
	if _is_moving:
		_check_red_light_violation()

	# Auto-navigate: check road and turn if needed
	if auto_navigate and _is_moving and not _is_turning:
		_nav_check_timer += delta
		if _nav_check_timer >= NAV_CHECK_INTERVAL:
			_nav_check_timer = 0.0
			_auto_navigate_check()

	# Handle movement
	if _is_moving:
		# Check for queued turn at intersection
		if queued_turn != "":
			_check_intersection_for_turn()
		_move(delta)
		_check_destination()
		# Check if we've moved enough tiles (for move(N) command)
		if _tiles_to_move > 0:
			var distance_moved = global_position.distance_to(_move_start_position)
			if distance_moved >= _tiles_to_move * TILE_SIZE:
				_tiles_to_move = 0
				_is_moving = false
				_wants_to_move = false
				velocity = Vector2.ZERO
				# Move command completed - process next command
				_command_completed()


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
# These queue commands for sequential execution
# ============================================

## Start moving forward continuously
func go() -> void:
	_command_queue.append({"type": "go"})
	_process_next_command()


## Stop immediately
func stop() -> void:
	_command_queue.append({"type": "stop"})
	_process_next_command()


## Queue a 90-degree left turn at next intersection
func turn_left() -> void:
	_command_queue.append({"type": "turn", "direction": "left"})
	_process_next_command()


## Queue a 90-degree right turn at next intersection
func turn_right() -> void:
	_command_queue.append({"type": "turn", "direction": "right"})
	_process_next_command()


## Pause movement for specified seconds
func wait(seconds: float) -> void:
	_command_queue.append({"type": "wait", "seconds": seconds})
	_process_next_command()


## Set speed multiplier (0.5 to 2.0) - executes immediately (no queue)
func set_speed(value: float) -> void:
	speed_multiplier = clamp(value, 0.5, 2.0)


## Get current speed multiplier
func get_speed() -> float:
	return speed_multiplier


## Check if vehicle is currently moving (internal)
func is_vehicle_moving() -> bool:
	return _is_moving


## Check if vehicle is currently moving (Python API)
func is_moving() -> bool:
	return is_vehicle_moving()


## Check if vehicle path is blocked (by another car or red light ahead)
func is_blocked() -> bool:
	# Check if there's a red light ahead
	if is_blocked_by_light():
		return true
	# Check if there's a car in front
	return is_front_car()


## Turn left or right (simplified - no intersection required)
func turn(turn_direction: String) -> void:
	_command_queue.append({"type": "turn", "direction": turn_direction})
	_process_next_command()


## Move a specific number of tiles
func move(tiles: int) -> void:
	if tiles <= 0:
		return
	_command_queue.append({"type": "move", "tiles": tiles})
	_process_next_command()


# ============================================
# Command Queue Processing
# ============================================

## Try to start the next command if idle
func _process_next_command() -> void:
	# If already executing a command, wait for it to finish
	if not _current_command.is_empty():
		return

	# If queue is empty, nothing to do
	if _command_queue.is_empty():
		return

	# Get next command
	_current_command = _command_queue.pop_front()

	# Execute the command
	match _current_command["type"]:
		"go":
			_exec_go()
		"stop":
			_exec_stop()
		"turn":
			_exec_turn(_current_command["direction"])
		"wait":
			_exec_wait(_current_command["seconds"])
		"move":
			_exec_move(_current_command["tiles"])


## Called when current command completes
func _command_completed() -> void:
	_current_command = {}
	_process_next_command()


# ============================================
# Command Execution (internal)
# ============================================

func _exec_go() -> void:
	_wants_to_move = true
	_is_moving = true
	# go() runs indefinitely, so mark command as complete immediately
	# (the car keeps moving until stop() is called)
	_command_completed()


func _exec_stop() -> void:
	_is_moving = false
	_wants_to_move = false
	velocity = Vector2.ZERO
	_tiles_to_move = 0
	_command_completed()


func _exec_turn(turn_direction: String) -> void:
	if turn_direction == "left" or turn_direction == "right":
		_execute_turn(turn_direction)
		# Turn completion is handled in _process_turn()
	else:
		_command_completed()


func _exec_wait(seconds: float) -> void:
	wait_timer = seconds
	is_waiting = true
	# Wait completion is handled in _physics_process()


func _exec_move(tiles: int) -> void:
	_tiles_to_move = tiles
	_move_start_position = global_position
	_is_moving = true
	_wants_to_move = true
	# Move completion is handled in _physics_process()


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


## Check if the car is at a dead end (no road ahead, left, or right)
## This is useful for detecting when navigation is complete on edited roads
func is_at_dead_end() -> bool:
	if _tile_map_layer == null:
		return false
	# Dead end = no road in any direction the car can go
	return not is_front_road() and not is_left_road() and not is_right_road()


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


## Get distance to nearest intersection
func distance_to_intersection() -> float:
	if _intersections.is_empty():
		return -1.0  # No intersections registered

	var min_distance: float = -1.0
	for intersection_pos in _intersections:
		var dist = global_position.distance_to(intersection_pos)
		if min_distance < 0 or dist < min_distance:
			min_distance = dist
	return min_distance


## Reset vehicle to initial state
func reset(start_pos: Vector2, start_dir: Vector2 = Vector2.RIGHT) -> void:
	global_position = start_pos
	direction = start_dir.normalized()
	rotation = direction.angle()
	_is_moving = false
	is_waiting = false
	wait_timer = 0.0
	queued_turn = ""
	speed_multiplier = 1.0
	velocity = Vector2.ZERO
	_wants_to_move = false
	# Reset red light violation tracking
	_passed_stoplights.clear()
	# Reset tile-based movement
	_tiles_to_move = 0
	_move_start_position = Vector2.ZERO
	# Reset turn state
	_is_turning = false
	_turn_progress = 0.0
	# Reset auto-navigate
	auto_navigate = false
	_nav_check_timer = 0.0
	# Reset command queue
	_command_queue.clear()
	_current_command = {}


# ============================================
# Stoplight Detection
# ============================================

## Register a stoplight that this vehicle should be aware of
func add_stoplight(stoplight: Stoplight) -> void:
	if not stoplight in _nearby_stoplights:
		_nearby_stoplights.append(stoplight)


## Remove a stoplight from awareness
func remove_stoplight(stoplight: Stoplight) -> void:
	_nearby_stoplights.erase(stoplight)
	_passed_stoplights.erase(stoplight)


## Check if car runs a red light (passing through when light is red)
## This does NOT auto-stop - players must code stoplight handling!
func _check_red_light_violation() -> void:
	for stoplight in _nearby_stoplights:
		var distance = global_position.distance_to(stoplight.global_position)

		# If we're very close (passing through) and light is red
		if distance < 30.0 and stoplight.is_red():
			if stoplight not in _passed_stoplights:
				# First time passing this red light - violation!
				_passed_stoplights.append(stoplight)
				ran_red_light.emit(vehicle_id, stoplight.stoplight_id)

		# Reset tracking when we're far away from the stoplight
		elif distance > STOPLIGHT_DETECTION_RANGE:
			if stoplight in _passed_stoplights:
				_passed_stoplights.erase(stoplight)


## Check if there's a red light nearby (for player queries)
func is_at_red_light() -> bool:
	for stoplight in _nearby_stoplights:
		if stoplight.is_red():
			var distance = global_position.distance_to(stoplight.global_position)
			if distance < STOPLIGHT_STOP_DISTANCE:
				return true
	return false


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

		# Turn command completed - process next command
		_command_completed()
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
