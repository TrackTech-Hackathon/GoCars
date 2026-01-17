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
	ESTATE,     # Estate/wagon - Speed 0.9x, Size 1.2
	SPORT,      # Sports car - Speed 1.4x, Size 1.0
	MICRO,      # Micro car - Speed 1.1x, Size 0.8
	PICKUP,     # Pickup truck - Speed 0.8x, Size 1.3
	JEEPNEY_1,  # Jeepney variant 1 - Speed 0.7x, Size 1.5
	JEEPNEY_2,  # Jeepney variant 2 - Speed 0.7x, Size 1.5
	BUS         # Bus - Speed 0.6x, Size 1.8
}

# Vehicle type configuration
const VEHICLE_CONFIG: Dictionary = {
	VehicleType.SEDAN: {
		"name": "Sedan",
		"speed_mult": 1.0,
		"size_mult": 1.0,
		"can_lane_split": false,
		"stopping_distance": 1.0
	},
	VehicleType.ESTATE: {
		"name": "Estate",
		"speed_mult": 0.9,
		"size_mult": 1.2,
		"can_lane_split": false,
		"stopping_distance": 1.1
	},
	VehicleType.SPORT: {
		"name": "Sport",
		"speed_mult": 1.4,
		"size_mult": 1.0,
		"can_lane_split": false,
		"stopping_distance": 0.9
	},
	VehicleType.MICRO: {
		"name": "Micro",
		"speed_mult": 1.1,
		"size_mult": 0.8,
		"can_lane_split": false,
		"stopping_distance": 0.8
	},
	VehicleType.PICKUP: {
		"name": "Pickup",
		"speed_mult": 0.8,
		"size_mult": 1.3,
		"can_lane_split": false,
		"stopping_distance": 1.3
	},
	VehicleType.JEEPNEY_1: {
		"name": "Jeepney 1",
		"speed_mult": 0.7,
		"size_mult": 1.5,
		"can_lane_split": false,
		"stopping_distance": 1.4
	},
	VehicleType.JEEPNEY_2: {
		"name": "Jeepney 2",
		"speed_mult": 0.7,
		"size_mult": 1.5,
		"can_lane_split": false,
		"stopping_distance": 1.4
	},
	VehicleType.BUS: {
		"name": "Bus",
		"speed_mult": 0.6,
		"size_mult": 1.8,
		"can_lane_split": false,
		"stopping_distance": 1.6
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
var _last_move_direction: Vector2 = Vector2.ZERO  # Track where we came from (to avoid turning back)

# Speed multiplier (for car.speed() function)
var speed_multiplier: float = 1.0

# Guideline path following (new system)
var _guideline_enabled: bool = true  # Set false to use old reactive movement
var _current_path: Array = []        # Waypoints to follow (world positions)
var _path_index: int = 0             # Current waypoint index
var _current_tile: Vector2i = Vector2i(-1, -1)   # Tile we're currently on
var _entry_direction: String = ""    # Direction we entered current tile from
var _last_exit_direction: String = "" # Direction we exited the previous tile (for diagonal transitions)

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

# Lane offset - cars drive on the left side of their direction (pixels from center)
const LANE_OFFSET: float = 25.0

# Distance at which vehicle detects stoplights (in pixels)
const STOPLIGHT_DETECTION_RANGE: float = 100.0

# Distance at which vehicle must stop for red light (in pixels)
const STOPLIGHT_STOP_DISTANCE: float = 50.0

# Distance at which vehicle detects intersections (in pixels)
const INTERSECTION_DETECTION_RANGE: float = 30.0

# Turn animation duration in seconds
const TURN_DURATION: float = 0.3

# Road checker reference (main scene with road_tiles Dictionary)
var _road_checker: Node = null

# Tile-based movement
var _tiles_to_move: int = 0
var _move_start_position: Vector2 = Vector2.ZERO
var TILE_SIZE: float = 144.0  # Pixels per tile (updated from road checker)

# Command queue for sequential execution
# Commands: {"type": "move", "tiles": N}, {"type": "wait", "seconds": N},
#           {"type": "turn", "direction": "left"/"right"}, {"type": "go"}, {"type": "stop"}
var _command_queue: Array = []
var _current_command: Dictionary = {}  # Currently executing command

# Wheel references (set in _ready)
var wheels: Array = []

# Sprite region for each car type (8 cars in gocars.png spritesheet)
# Layout: 8 columns x 2 rows
# Row 0 = Active/Fixed cars, Row 1 = Crashed cars
# Each car is 48x96 pixels (16x3 wide, 16x6 tall)
const CAR_SPRITE_WIDTH: int = 48
const CAR_SPRITE_HEIGHT: int = 96
# Active sprite regions (row 0)
const CAR_SPRITE_REGIONS: Dictionary = {
	VehicleType.SEDAN: Rect2(0, 0, 48, 96),
	VehicleType.ESTATE: Rect2(48, 0, 48, 96),
	VehicleType.SPORT: Rect2(96, 0, 48, 96),
	VehicleType.MICRO: Rect2(144, 0, 48, 96),
	VehicleType.PICKUP: Rect2(192, 0, 48, 96),
	VehicleType.JEEPNEY_1: Rect2(240, 0, 48, 96),
	VehicleType.JEEPNEY_2: Rect2(288, 0, 48, 96),
	VehicleType.BUS: Rect2(336, 0, 48, 96)
}
# Crashed sprite regions (row 1)
const CAR_CRASHED_REGIONS: Dictionary = {
	VehicleType.SEDAN: Rect2(0, 96, 48, 96),
	VehicleType.ESTATE: Rect2(48, 96, 48, 96),
	VehicleType.SPORT: Rect2(96, 96, 48, 96),
	VehicleType.MICRO: Rect2(144, 96, 48, 96),
	VehicleType.PICKUP: Rect2(192, 96, 48, 96),
	VehicleType.JEEPNEY_1: Rect2(240, 96, 48, 96),
	VehicleType.JEEPNEY_2: Rect2(288, 96, 48, 96),
	VehicleType.BUS: Rect2(336, 96, 48, 96)
}

# Wheel positions per vehicle type (relative to center, for 48x96 car sprites)
# Sprite is 48 wide x 96 tall, car faces UP so width is left-right, height is front-back
const WHEEL_POSITIONS: Dictionary = {
	VehicleType.SEDAN: {
		"FL": Vector2(-16, -30),
		"FR": Vector2(16, -30),
		"BL": Vector2(-16, 30),
		"BR": Vector2(16, 30)
	},
	VehicleType.ESTATE: {
		"FL": Vector2(-16, -30),
		"FR": Vector2(16, -30),
		"BL": Vector2(-16, 30),
		"BR": Vector2(16, 30)
	},
	VehicleType.SPORT: {
		"FL": Vector2(-16, -32),
		"FR": Vector2(16, -32),
		"BL": Vector2(-16, 32),
		"BR": Vector2(16, 32)
	},
	VehicleType.MICRO: {
		"FL": Vector2(-14, -28),
		"FR": Vector2(14, -28),
		"BL": Vector2(-14, 28),
		"BR": Vector2(14, 28)
	},
	VehicleType.PICKUP: {
		"FL": Vector2(-16, -30),
		"FR": Vector2(16, -30),
		"BL": Vector2(-16, 30),
		"BR": Vector2(16, 30)
	},
	VehicleType.JEEPNEY_1: {
		"FL": Vector2(-16, -30),
		"FR": Vector2(16, -30),
		"BL": Vector2(-16, 30),
		"BR": Vector2(16, 30)
	},
	VehicleType.JEEPNEY_2: {
		"FL": Vector2(-16, -30),
		"FR": Vector2(16, -30),
		"BL": Vector2(-16, 30),
		"BR": Vector2(16, 30)
	},
	VehicleType.BUS: {
		"FL": Vector2(-16, -38),
		"FR": Vector2(16, -38),
		"BL": Vector2(-16, 38),
		"BR": Vector2(16, 38)
	}
}


func _ready() -> void:
	# Add to vehicles group for detection
	add_to_group("vehicles")

	# Set up collision
	set_collision_layer_value(1, true)  # Layer 1 for vehicles
	set_collision_mask_value(1, true)   # Detect other vehicles

	# Apply vehicle type configuration
	_apply_vehicle_type()

	# Find and register wheels
	_setup_wheels()


## Apply configuration based on vehicle type
func _apply_vehicle_type() -> void:
	if vehicle_type in VEHICLE_CONFIG:
		var config = VEHICLE_CONFIG[vehicle_type]
		type_speed_mult = config["speed_mult"]
		type_size_mult = config["size_mult"]
		can_lane_split = config["can_lane_split"]
		stopping_distance_mult = config["stopping_distance"]

		# Apply sprite region from gocars.png spritesheet
		var sprite = get_node_or_null("Sprite2D")
		if sprite and vehicle_type in CAR_SPRITE_REGIONS:
			sprite.region_enabled = true
			sprite.region_rect = CAR_SPRITE_REGIONS[vehicle_type]

		# Apply size scaling
		scale = Vector2(type_size_mult, type_size_mult)

		# Update wheel positions for this vehicle type
		_update_wheel_positions()


## Set up wheels - find wheel children and register them
func _setup_wheels() -> void:
	var wheels_container = get_node_or_null("Wheels")
	if wheels_container:
		for child in wheels_container.get_children():
			if child is Wheel:
				child.vehicle = self
				wheels.append(child)

	# Position wheels according to vehicle type
	_update_wheel_positions()


## Update wheel positions based on vehicle type
func _update_wheel_positions() -> void:
	if wheels.is_empty():
		return

	if vehicle_type not in WHEEL_POSITIONS:
		return

	var positions = WHEEL_POSITIONS[vehicle_type]
	var wheels_container = get_node_or_null("Wheels")
	if not wheels_container:
		return

	# Map wheel names to positions
	var wheel_fl = wheels_container.get_node_or_null("WheelFL")
	var wheel_fr = wheels_container.get_node_or_null("WheelFR")
	var wheel_bl = wheels_container.get_node_or_null("WheelBL")
	var wheel_br = wheels_container.get_node_or_null("WheelBR")

	if wheel_fl:
		wheel_fl.position = positions["FL"]
		wheel_fl.is_front_wheel = true
	if wheel_fr:
		wheel_fr.position = positions["FR"]
		wheel_fr.is_front_wheel = true
	if wheel_bl:
		wheel_bl.position = positions["BL"]
	if wheel_br:
		wheel_br.position = positions["BR"]


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
		VehicleType.ESTATE,
		VehicleType.SPORT,
		VehicleType.MICRO,
		VehicleType.PICKUP,
		VehicleType.JEEPNEY_1,
		VehicleType.JEEPNEY_2,
		VehicleType.BUS
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
		# Guideline path following (new system)
		if _guideline_enabled:
			_follow_guideline_path(delta)
		else:
			# Old reactive movement system
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
	if _road_checker != null:
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


# ============================================
# Guideline Path Following System
# ============================================

## Main guideline path following function
func _follow_guideline_path(delta: float) -> void:
	# Check if car is on a road tile
	if _road_checker != null:
		if not _is_on_road():
			_on_off_road_crash()
			return

	# Check for tile transition - do we need a new path?
	var current_grid = _get_current_grid_pos()
	if current_grid != _current_tile:
		_on_enter_new_tile(current_grid)

	# If no path, get one
	if _current_path.is_empty():
		_acquire_path_for_current_tile()

	# If still no path (dead end or error), fall back to old movement
	if _current_path.is_empty():
		_move(delta)
		return

	# Follow the current path
	_move_along_path(delta)


## Called when entering a new tile
func _on_enter_new_tile(new_tile: Vector2i) -> void:
	var old_tile = _current_tile
	_current_tile = new_tile

	# Determine entry direction based on where we came from
	if _last_exit_direction != "":
		# Use opposite of last exit direction (handles diagonals correctly)
		_entry_direction = RoadTile.get_opposite_direction(_last_exit_direction)
	elif old_tile != Vector2i(-1, -1):
		# Fallback to grid-based calculation (for cardinal directions)
		var diff = old_tile - new_tile
		_entry_direction = _grid_offset_to_direction(diff)
	else:
		# First tile - determine from our current facing direction
		_entry_direction = _get_opposite_direction(_vector_to_connection_direction(direction))

	# Clear path to force acquisition of new one
	_current_path.clear()
	_path_index = 0


## Get a path for the current tile
func _acquire_path_for_current_tile() -> void:
	if _road_checker == null or not _road_checker.has_method("get_road_tile"):
		return

	var tile = _road_checker.get_road_tile(_current_tile)
	if tile == null:
		return

	# Get available exits from our entry direction
	var exits = tile.get_available_exits(_entry_direction)

	if exits.is_empty():
		return  # Dead end

	# Choose exit based on commands
	var result = _choose_exit(_entry_direction, exits)
	var chosen_exit = result[0]
	var turn_was_used = result[1]

	# If no valid exit, car will fall back to old movement and crash
	if chosen_exit == "":
		return

	# Save exit direction for next tile's entry calculation
	_last_exit_direction = chosen_exit

	# Get the path
	_current_path = tile.get_guideline_path(_entry_direction, chosen_exit)
	_path_index = 0

	# Clear queued turn only if it was actually used
	if turn_was_used:
		queued_turn = ""


## Choose which exit to take based on queued commands
## Returns [chosen_exit, turn_was_used] - turn_was_used indicates if queued_turn should be cleared
## Returns ["", false] if no valid path (car should crash)
func _choose_exit(entry: String, available_exits: Array) -> Array:
	var opposite = RoadTile.get_opposite_direction(entry)

	# If there's a queued turn command, use it
	if queued_turn == "left":
		# First try cardinal left
		var left = RoadTile.get_left_of(entry)
		if left in available_exits:
			return [left, true]  # Turn used
		# Then try diagonal lefts
		var diagonal_lefts = _get_diagonal_lefts(entry)
		for diag in diagonal_lefts:
			if diag in available_exits:
				return [diag, true]  # Turn used
	elif queued_turn == "right":
		# First try cardinal right
		var right = RoadTile.get_right_of(entry)
		if right in available_exits:
			return [right, true]  # Turn used
		# Then try diagonal rights
		var diagonal_rights = _get_diagonal_rights(entry)
		for diag in diagonal_rights:
			if diag in available_exits:
				return [diag, true]  # Turn used

	# Try to go straight (opposite of entry)
	if opposite in available_exits:
		return [opposite, false]  # Turn NOT used (kept for later)

	# Can't go straight - only turn if a turn was actually queued
	if queued_turn != "":
		# Turn was queued but preferred direction not available
		# Try the other direction as fallback
		if queued_turn == "left":
			var right = RoadTile.get_right_of(entry)
			if right in available_exits:
				return [right, true]
			# Also try diagonal rights as fallback
			var diagonal_rights = _get_diagonal_rights(entry)
			for diag in diagonal_rights:
				if diag in available_exits:
					return [diag, true]
		elif queued_turn == "right":
			var left = RoadTile.get_left_of(entry)
			if left in available_exits:
				return [left, true]
			# Also try diagonal lefts as fallback
			var diagonal_lefts = _get_diagonal_lefts(entry)
			for diag in diagonal_lefts:
				if diag in available_exits:
					return [diag, true]

	# No valid path - car should crash (no turn queued and can't go straight)
	return ["", false]


## Move along the current path toward waypoints
func _move_along_path(delta: float) -> void:
	if _path_index >= _current_path.size():
		# Path complete - clear it so we get a new one on next tile
		_current_path.clear()
		_path_index = 0

		# For diagonal exits, force transition to correct tile
		# (grid position calculation fails due to perpendicular lane offset)
		if _last_exit_direction in ["top_left", "top_right", "bottom_left", "bottom_right"]:
			var next_tile = _current_tile + _get_grid_offset_from_direction(_last_exit_direction)
			_on_enter_new_tile(next_tile)
		return

	var target = _current_path[_path_index]
	var to_target = target - global_position
	var dist = to_target.length()

	# Check if reached waypoint
	if dist < 15.0:
		_path_index += 1
		if _path_index >= _current_path.size():
			# Path complete
			_current_path.clear()
			_path_index = 0

			# For diagonal exits, force transition to correct tile
			if _last_exit_direction in ["top_left", "top_right", "bottom_left", "bottom_right"]:
				var next_tile = _current_tile + _get_grid_offset_from_direction(_last_exit_direction)
				_on_enter_new_tile(next_tile)
		return

	# Move toward waypoint
	var move_dir = to_target.normalized()

	# Update direction and rotation
	direction = move_dir
	rotation = direction.angle() + PI / 2  # Sprite faces UP

	# Apply speed
	var actual_speed = speed * speed_multiplier * type_speed_mult
	velocity = direction * actual_speed
	move_and_slide()

	# Check for collisions
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		if collision.get_collider() is Vehicle:
			var other_vehicle = collision.get_collider() as Vehicle
			if other_vehicle.vehicle_state == 0:
				_on_crash()
				return
			if vehicle_state == 1 and other_vehicle.vehicle_state == 1:
				_on_crash()
				other_vehicle._on_crash()
				return


## Convert grid offset to direction string
func _grid_offset_to_direction(offset: Vector2i) -> String:
	match offset:
		# Cardinals
		Vector2i(0, -1): return "top"
		Vector2i(0, 1): return "bottom"
		Vector2i(-1, 0): return "left"
		Vector2i(1, 0): return "right"
		# Diagonals
		Vector2i(-1, -1): return "top_left"
		Vector2i(1, -1): return "top_right"
		Vector2i(-1, 1): return "bottom_left"
		Vector2i(1, 1): return "bottom_right"
	return ""


func _check_destination() -> void:
	if destination != Vector2.ZERO:
		var distance = global_position.distance_to(destination)
		if distance < DESTINATION_THRESHOLD:
			stop()
			reached_destination.emit(vehicle_id)


func _on_crash() -> void:
	stop()
	vehicle_state = 0  # Mark as crashed
	_switch_to_crashed_sprite()
	crashed.emit(vehicle_id)


func _on_off_road_crash() -> void:
	stop()
	vehicle_state = 0  # Mark as crashed
	_switch_to_crashed_sprite()
	off_road_crash.emit(vehicle_id)


## Switch to the crashed sprite from row 2 of the spritesheet
func _switch_to_crashed_sprite() -> void:
	var sprite = get_node_or_null("Sprite2D")
	if sprite and vehicle_type in CAR_CRASHED_REGIONS:
		sprite.region_rect = CAR_CRASHED_REGIONS[vehicle_type]


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


## Check if vehicle is currently moving (Python API - short name)
func moving() -> bool:
	return _is_moving


## Check if vehicle path is blocked (by another car or red light ahead)
func blocked() -> bool:
	# Check if there's a red light ahead
	if is_blocked_by_light():
		return true
	# Check if there's a car in front
	return front_car()


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
	# Track the direction we're moving so we don't turn back to it
	_last_move_direction = direction
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
		if _guideline_enabled:
			# With guidelines, just queue the turn - it will be used when acquiring next path
			queued_turn = turn_direction
			_command_completed()
		else:
			# Old system: execute turn immediately
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
	# Track the direction we're moving so we don't turn back to it
	_last_move_direction = direction
	# Move completion is handled in _physics_process()


## Get the grid position of the tile the car is currently on (compensating for lane offset)
func _get_current_grid_pos() -> Vector2i:
	# Lane offset is perpendicular to direction (90° clockwise)
	var offset_dir = direction.rotated(PI / 2)
	var center_pos = global_position - (offset_dir.normalized() * LANE_OFFSET)
	return Vector2i(int(center_pos.x / TILE_SIZE), int(center_pos.y / TILE_SIZE))


## Convert direction vector to RoadTile connection string
func _vector_to_connection_direction(dir: Vector2) -> String:
	var x = round(dir.normalized().x)
	var y = round(dir.normalized().y)

	if x == 0 and y == -1: return "top"
	if x == 0 and y == 1: return "bottom"
	if x == -1 and y == 0: return "left"
	if x == 1 and y == 0: return "right"
	if x == -1 and y == -1: return "top_left"
	if x == 1 and y == -1: return "top_right"
	if x == -1 and y == 1: return "bottom_left"
	if x == 1 and y == 1: return "bottom_right"
	return ""


## Get grid offset for a direction string
func _get_grid_offset_from_direction(dir: String) -> Vector2i:
	match dir:
		"top": return Vector2i(0, -1)
		"bottom": return Vector2i(0, 1)
		"left": return Vector2i(-1, 0)
		"right": return Vector2i(1, 0)
		"top_left": return Vector2i(-1, -1)
		"top_right": return Vector2i(1, -1)
		"bottom_left": return Vector2i(-1, 1)
		"bottom_right": return Vector2i(1, 1)
	return Vector2i.ZERO


## Get opposite direction string
func _get_opposite_direction(dir: String) -> String:
	match dir:
		"top": return "bottom"
		"bottom": return "top"
		"left": return "right"
		"right": return "left"
		"top_left": return "bottom_right"
		"top_right": return "bottom_left"
		"bottom_left": return "top_right"
		"bottom_right": return "top_left"
	return ""


## Get diagonal directions that count as "left" for a cardinal entry
## When entering from a cardinal direction, diagonals in the left half-plane are valid lefts
func _get_diagonal_lefts(entry: String) -> Array:
	match entry:
		"left": return ["bottom_left"]      # Traveling right, left is south side
		"right": return ["top_right"]       # Traveling left, left is north side
		"top": return ["top_left"]          # Traveling down, left is west side
		"bottom": return ["bottom_right"]   # Traveling up, left is east side
	return []


## Get diagonal directions that count as "right" for a cardinal entry
## When entering from a cardinal direction, diagonals in the right half-plane are valid rights
func _get_diagonal_rights(entry: String) -> Array:
	match entry:
		"left": return ["top_right"]        # Traveling right, right is north side
		"right": return ["bottom_left"]     # Traveling left, right is south side
		"top": return ["bottom_right"]      # Traveling down, right is east side
		"bottom": return ["top_left"]       # Traveling up, right is west side
	return []


## Check if there's a road in front of the car (short name)
## With guidelines: checks if current tile has a straight-through exit
## Without guidelines: checks adjacent tile for connection
func front_road() -> bool:
	if _road_checker == null:
		return false

	# With guideline system, check available exits from current tile
	if _guideline_enabled and _entry_direction != "":
		var tile = _road_checker.get_road_tile(_current_tile) if _road_checker.has_method("get_road_tile") else null
		if tile != null:
			var exits = tile.get_available_exits(_entry_direction)
			# "Front" means continuing straight (opposite of entry)
			var straight_exit = RoadTile.get_opposite_direction(_entry_direction)
			return straight_exit in exits

	# Fallback to old behavior
	var grid_pos = _get_current_grid_pos()
	var conn_dir = _vector_to_connection_direction(direction)

	if conn_dir != "" and _road_checker.has_method("is_road_connected"):
		var adjacent_offset = _get_grid_offset_from_direction(conn_dir)
		var adjacent_grid = grid_pos + adjacent_offset
		var opposite_dir = _get_opposite_direction(conn_dir)
		return _road_checker.is_road_connected(adjacent_grid, opposite_dir)

	var front_offset = direction.normalized() * TILE_SIZE
	var front_pos = global_position + front_offset
	return _is_road_at_position(front_pos)


## Check if there's a road to the left of the car (short name)
## With guidelines: checks if current tile has a left turn exit (cardinal or diagonal)
## Without guidelines: checks adjacent tile for connection
func left_road() -> bool:
	if _road_checker == null:
		return false

	# With guideline system, check available exits from current tile
	if _guideline_enabled and _entry_direction != "":
		var tile = _road_checker.get_road_tile(_current_tile) if _road_checker.has_method("get_road_tile") else null
		if tile != null:
			var exits = tile.get_available_exits(_entry_direction)
			# Check cardinal left direction
			var left_exit = RoadTile.get_left_of(_entry_direction)
			if left_exit in exits:
				return true
			# Also check diagonal lefts for cardinal entries
			var diagonal_lefts = _get_diagonal_lefts(_entry_direction)
			for diag in diagonal_lefts:
				if diag in exits:
					return true
			return false

	# Fallback to old behavior
	var grid_pos = _get_current_grid_pos()
	var left_dir = direction.rotated(-PI / 2)
	var conn_dir = _vector_to_connection_direction(left_dir)

	# Don't detect the road we came from
	if _last_move_direction != Vector2.ZERO:
		var came_from_dir = -_last_move_direction
		var came_from_conn = _vector_to_connection_direction(came_from_dir)
		if conn_dir == came_from_conn:
			return false

	if conn_dir != "" and _road_checker.has_method("is_road_connected"):
		var adjacent_offset = _get_grid_offset_from_direction(conn_dir)
		var adjacent_grid = grid_pos + adjacent_offset
		var opposite_dir = _get_opposite_direction(conn_dir)
		return _road_checker.is_road_connected(adjacent_grid, opposite_dir)

	var left_offset = left_dir.normalized() * TILE_SIZE
	var left_pos = global_position + left_offset
	return _is_road_at_position(left_pos)


## Check if there's a road to the right of the car (short name)
## With guidelines: checks if current tile has a right turn exit (cardinal or diagonal)
## Without guidelines: checks adjacent tile for connection
func right_road() -> bool:
	if _road_checker == null:
		return false

	# With guideline system, check available exits from current tile
	if _guideline_enabled and _entry_direction != "":
		var tile = _road_checker.get_road_tile(_current_tile) if _road_checker.has_method("get_road_tile") else null
		if tile != null:
			var exits = tile.get_available_exits(_entry_direction)
			# Check cardinal right direction
			var right_exit = RoadTile.get_right_of(_entry_direction)
			if right_exit in exits:
				return true
			# Also check diagonal rights for cardinal entries
			var diagonal_rights = _get_diagonal_rights(_entry_direction)
			for diag in diagonal_rights:
				if diag in exits:
					return true
			return false

	# Fallback to old behavior
	var grid_pos = _get_current_grid_pos()
	var right_dir = direction.rotated(PI / 2)
	var conn_dir = _vector_to_connection_direction(right_dir)

	# Don't detect the road we came from
	if _last_move_direction != Vector2.ZERO:
		var came_from_dir = -_last_move_direction
		var came_from_conn = _vector_to_connection_direction(came_from_dir)
		if conn_dir == came_from_conn:
			return false

	if conn_dir != "" and _road_checker.has_method("is_road_connected"):
		var adjacent_offset = _get_grid_offset_from_direction(conn_dir)
		var adjacent_grid = grid_pos + adjacent_offset
		var opposite_dir = _get_opposite_direction(conn_dir)
		return _road_checker.is_road_connected(adjacent_grid, opposite_dir)

	var right_offset = right_dir.normalized() * TILE_SIZE
	var right_pos = global_position + right_offset
	return _is_road_at_position(right_pos)


## Check if there's ANY car (crashed or active) in front (short name)
func front_car() -> bool:
	var front_offset = direction.normalized() * TILE_SIZE
	var front_pos = global_position + front_offset
	return _is_vehicle_at_position(front_pos)


## Check if there's a CRASHED car in front (short name)
func front_crash() -> bool:
	var front_offset = direction.normalized() * TILE_SIZE
	var front_pos = global_position + front_offset
	return _is_crashed_vehicle_at_position(front_pos)


## Check if the car is at a dead end (no road in any direction) (short name)
func dead_end() -> bool:
	if _road_checker == null:
		return false
	return not front_road() and not left_road() and not right_road()


# ============================================
# Auto-Navigation System
# ============================================

## Enable auto-navigation mode (car follows road automatically)
func set_auto_navigate(enabled: bool) -> void:
	auto_navigate = enabled
	_nav_check_timer = 0.0


## Check road ahead and turn if needed (called during auto-navigate)
func _auto_navigate_check() -> void:
	if _road_checker == null:
		return

	# If road ahead, keep going
	if front_road():
		return

	# No road ahead - check for turns
	# Priority: prefer continuing in same general direction
	var left_has_road = left_road()
	var right_has_road = right_road()

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


## Check if vehicle has reached its destination (short name)
func at_end() -> bool:
	if destination == Vector2.ZERO:
		return false
	return global_position.distance_to(destination) < DESTINATION_THRESHOLD


## Get distance to destination (short name)
func dist() -> float:
	if destination == Vector2.ZERO:
		return -1.0
	return global_position.distance_to(destination)


## Get distance to nearest intersection
func distance_to_intersection() -> float:
	if _intersections.is_empty():
		return -1.0
	var min_distance: float = -1.0
	for intersection_pos in _intersections:
		var d = global_position.distance_to(intersection_pos)
		if min_distance < 0 or d < min_distance:
			min_distance = d
	return min_distance


## Reset vehicle to initial state
## Note: Car sprites face UP by default, so rotation needs +PI/2 offset
func reset(start_pos: Vector2, start_dir: Vector2 = Vector2.RIGHT) -> void:
	global_position = start_pos
	direction = start_dir.normalized()
	# Car sprite faces UP, so add PI/2 to make it face the direction
	rotation = direction.angle() + PI / 2
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
	# Reset guideline path following
	_current_path.clear()
	_path_index = 0
	_last_exit_direction = ""
	# Reset last move direction tracking (used in fallback road detection)
	_last_move_direction = Vector2.ZERO
	# Initialize current tile and entry direction for guideline system
	# This ensures front_road(), left_road(), right_road() work immediately
	_current_tile = _get_current_grid_pos()
	_entry_direction = _get_opposite_direction(_vector_to_connection_direction(direction))


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


## Check if there's a red light nearby (short name)
func at_red() -> bool:
	for stoplight in _nearby_stoplights:
		if stoplight.is_red():
			var d = global_position.distance_to(stoplight.global_position)
			if d < STOPLIGHT_STOP_DISTANCE:
				return true
	return false


## Check if there's a red light ahead (within detection range)
func is_blocked_by_light() -> bool:
	for stoplight in _nearby_stoplights:
		if stoplight.should_stop():
			var d = global_position.distance_to(stoplight.global_position)
			if d < STOPLIGHT_DETECTION_RANGE:
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
		# Since rotation includes PI/2 offset (sprite faces UP), use UP.rotated instead
		direction = Vector2.UP.rotated(rotation)

		# Turn command completed - process next command
		_command_completed()
	else:
		# Interpolate rotation smoothly (ease in-out)
		var t = _ease_in_out(_turn_progress)
		rotation = lerp(_turn_start_rotation, _turn_target_rotation, t)
		# Since rotation includes PI/2 offset (sprite faces UP), use UP.rotated instead
		direction = Vector2.UP.rotated(rotation)


## Ease in-out function for smooth animation
func _ease_in_out(t: float) -> float:
	if t < 0.5:
		return 2.0 * t * t
	else:
		return 1.0 - pow(-2.0 * t + 2.0, 2.0) / 2.0


## Check if vehicle is currently at an intersection (short name)
func at_cross() -> bool:
	for intersection_pos in _intersections:
		var d = global_position.distance_to(intersection_pos)
		if d < INTERSECTION_DETECTION_RANGE:
			return true
	return false


## Check if vehicle is currently turning
func turning() -> bool:
	return _is_turning


# ============================================
# Road Detection
# ============================================

## Set the road checker reference (main scene with road_tiles Dictionary)
func set_road_checker(checker: Node) -> void:
	_road_checker = checker
	# Update tile size from road checker
	if _road_checker != null and _road_checker.has_method("get_tile_size"):
		TILE_SIZE = _road_checker.get_tile_size()


## Check if vehicle is currently on a road tile
func _is_on_road() -> bool:
	if _road_checker == null:
		return true  # If no road checker, assume roads everywhere

	# First check current position
	if _is_road_at_position(global_position):
		return true

	# For diagonal travel, the lane offset may put us in an "in-between" grid cell
	# Check if the expected diagonal tile exists (car is in valid transition)
	if _last_exit_direction in ["top_left", "top_right", "bottom_left", "bottom_right"]:
		var expected_next = _current_tile + _get_grid_offset_from_direction(_last_exit_direction)
		if _road_checker.has_method("get_road_tile"):
			var tile = _road_checker.get_road_tile(expected_next)
			if tile != null:
				return true  # Diagonal tile exists, car is in valid transition

	return false


## Check if there's a road at a specific world position
func _is_road_at_position(world_pos: Vector2) -> bool:
	if _road_checker == null:
		return true

	if _road_checker.has_method("is_road_at_position"):
		return _road_checker.is_road_at_position(world_pos)

	return true


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
