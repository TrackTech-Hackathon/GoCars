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

# ============================================
# Vehicle Colors (for palette swap shader)
# ============================================
enum VehicleColor {
	# Common colors (60% spawn chance)
	WHITE,   # Index 0
	GRAY,    # Index 1
	BLACK,   # Index 2
	RED,     # Index 3
	BEIGE,   # Index 4
	# Uncommon colors (30% spawn chance)
	GREEN,   # Index 5
	BLUE,    # Index 6
	CYAN,    # Index 7
	ORANGE,  # Index 8
	BROWN,   # Index 9
	# Rare colors (10% spawn chance)
	LIME,    # Index 10
	MAGENTA, # Index 11
	PINK,    # Index 12
	PURPLE,  # Index 13
	YELLOW   # Index 14
}

# Color rarity tiers
enum ColorRarity {
	COMMON,    # 60% chance
	UNCOMMON,  # 30% chance
	RARE       # 10% chance
}

# Color palette file names (match the PNG files in assets/cars/Cars Color Palette/)
const COLOR_PALETTE_FILES: Dictionary = {
	VehicleColor.WHITE: "WHITE",
	VehicleColor.GRAY: "GRAY",
	VehicleColor.BLACK: "BLACK",
	VehicleColor.RED: "RED",
	VehicleColor.BEIGE: "BEIGE",
	VehicleColor.GREEN: "GREEN",
	VehicleColor.BLUE: "BLUE",
	VehicleColor.CYAN: "CYAN",
	VehicleColor.ORANGE: "ORANGE",
	VehicleColor.BROWN: "BROWN",
	VehicleColor.LIME: "LIME",
	VehicleColor.MAGENTA: "MAGENTA",
	VehicleColor.PINK: "PINK",
	VehicleColor.PURPLE: "PURPLE",
	VehicleColor.YELLOW: "YELLOW"
}

# Rarity spawn weights (must sum to 100)
const RARITY_WEIGHTS: Dictionary = {
	ColorRarity.COMMON: 60,
	ColorRarity.UNCOMMON: 30,
	ColorRarity.RARE: 10
}

# Colors grouped by rarity
const COMMON_COLORS: Array = [
	VehicleColor.WHITE,
	VehicleColor.GRAY,
	VehicleColor.BLACK,
	VehicleColor.RED,
	VehicleColor.BEIGE
]

const UNCOMMON_COLORS: Array = [
	VehicleColor.GREEN,
	VehicleColor.BLUE,
	VehicleColor.CYAN,
	VehicleColor.ORANGE,
	VehicleColor.BROWN
]

const RARE_COLORS: Array = [
	VehicleColor.LIME,
	VehicleColor.MAGENTA,
	VehicleColor.PINK,
	VehicleColor.PURPLE,
	VehicleColor.YELLOW
]

# All colors (for equal-chance selection like Jeepneys)
const ALL_COLORS: Array = [
	VehicleColor.WHITE, VehicleColor.GRAY, VehicleColor.BLACK, VehicleColor.RED, VehicleColor.BEIGE,
	VehicleColor.GREEN, VehicleColor.BLUE, VehicleColor.CYAN, VehicleColor.ORANGE, VehicleColor.BROWN,
	VehicleColor.LIME, VehicleColor.MAGENTA, VehicleColor.PINK, VehicleColor.PURPLE, VehicleColor.YELLOW
]

# Vehicle type configuration
const VEHICLE_CONFIG: Dictionary = {
	VehicleType.SEDAN: {
		"name": "Sedan",
		"speed_mult": 1.0,
		"size_mult": 1.1,
		"can_lane_split": false,
		"stopping_distance": 1.0
	},
	VehicleType.ESTATE: {
		"name": "Estate",
		"speed_mult": 0.9,
		"size_mult": 1.1,
		"can_lane_split": false,
		"stopping_distance": 1.0
	},
	VehicleType.SPORT: {
		"name": "Sport",
		"speed_mult": 1.4,
		"size_mult": 1.1,
		"can_lane_split": false,
		"stopping_distance": 1.0
	},
	VehicleType.MICRO: {
		"name": "Micro",
		"speed_mult": 1.1,
		"size_mult": 1.1,
		"can_lane_split": false,
		"stopping_distance": 1.0
	},
	VehicleType.PICKUP: {
		"name": "Pickup",
		"speed_mult": 0.8,
		"size_mult": 1.1,
		"can_lane_split": false,
		"stopping_distance": 1.0
	},
	VehicleType.JEEPNEY_1: {
		"name": "Jeepney 1",
		"speed_mult": 0.7,
		"size_mult": 1.1,
		"can_lane_split": false,
		"stopping_distance": 1.0
	},
	VehicleType.JEEPNEY_2: {
		"name": "Jeepney 2",
		"speed_mult": 0.7,
		"size_mult": 1.1,
		"can_lane_split": false,
		"stopping_distance": 1.0
	},
	VehicleType.BUS: {
		"name": "Bus",
		"speed_mult": 0.6,
		"size_mult": 1.1,
		"can_lane_split": false,
		"stopping_distance": 1.0
	}
}

# Spawn Group enum (matches RoadTileMapLayer.SpawnGroup)
enum SpawnGroup { A, B, C, D, NONE }

# Vehicle properties
@export var vehicle_id: String = "car1"
@export var vehicle_type: VehicleType = VehicleType.SEDAN
@export var speed: float = 200.0  # Base pixels per second
@export var destination: Vector2 = Vector2.ZERO
@export var spawn_group: SpawnGroup = SpawnGroup.NONE  # Which group this car belongs to

# Multiple destinations support - car can reach ANY of these
var _all_destinations: Array = []  # Array of Vector2 positions
# Destinations for this car's group only
var _group_destinations: Array = []  # Array of destination data for matching group

# Vehicle state (0 = crashed, 1 = normal/active)
var vehicle_state: int = 1

# State enum for stats display
enum VehicleState { PARKED, MOVING, WAITING, CRASHED }

# Current color palette
var current_color_palette: VehicleColor = VehicleColor.WHITE

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
var _guideline_enabled: bool = true  # Keep enabled for turn detection
var _current_path: Array = []        # Waypoints to follow (world positions)
var _path_index: int = 0             # Current waypoint index
var _current_tile: Vector2i = Vector2i(-1, -1)   # Tile we're currently on
var _entry_direction: String = ""    # Direction we entered current tile from
var _last_exit_direction: String = "" # Direction we exited the previous tile
var _use_simple_movement: bool = false # After turning, use simple movement until entering new tile
var _current_move_dir: Vector2 = Vector2.RIGHT  # Stable movement direction for grid calculations
var _debug_draw_paths: bool = false  # Debug: visualize guideline paths (set to true to see paths)

# Decision locking state (prevents zigzag from continuous re-evaluation)
var _decision_made_for_tile: bool = false     # True once turn/go executed on this tile
var _locked_exits: Array = []                 # Available exits cached at tile entry
var _locked_entry_direction: String = ""      # Entry direction frozen at tile entry

# Auto-navigate mode - car automatically follows road
var auto_navigate: bool = false
var _nav_check_timer: float = 0.0
const NAV_CHECK_INTERVAL: float = 0.1  # Check road every 100ms

# Stoplight awareness (for red light violation detection)
var _nearby_stoplights: Array = []  # Array of Stoplight nodes in range
var _passed_stoplights: Array = []  # Track stoplights we've passed (for violation detection)
var _wants_to_move: bool = false  # True if go() was called (intention to move)

# Pending command flags - used to block interpreter until command completes
var _pending_go_command: bool = false  # True when go() called, completes when movement starts
var _pending_stop_command: bool = false  # True when stop() called, completes when car stops

# Intersection/turn tracking
var _intersections: Array = []  # Array of intersection positions (Vector2)
var _is_turning: bool = false
var _turn_progress: float = 0.0
var _turn_start_rotation: float = 0.0
var _turn_target_rotation: float = 0.0
var _turn_start_direction: Vector2 = Vector2.ZERO

# Distance threshold for reaching destination
# Reduced to ensure vehicles (especially buses) park at the true center
const DESTINATION_THRESHOLD: float = 15.0

# Lane offset - cars drive in center of road (no offset for simpler movement)
const LANE_OFFSET: float = 0.0

# Distance at which vehicle detects stoplights (in pixels)
const STOPLIGHT_DETECTION_RANGE: float = 100.0

# Distance at which vehicle must stop for red light (in pixels)
const STOPLIGHT_STOP_DISTANCE: float = 150.0

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


# Stats Node with labels (read by StatsUIPanel)
var _stats_node: Node2D = null
var _stats_type_label: Label = null
var _stats_color_label: Label = null
var _stats_group_label: Label = null
var _stats_speed_label: Label = null
var _stats_facing_label: Label = null
var _stats_state_label: Label = null


## Area2D nodes for collision detection (created from existing CollisionShape2D nodes)
var _car_collision_area: Area2D = null        # For car-to-car collision
var _road_building_area: Area2D = null        # For road/building collision
var _front_checker_area: Area2D = null        # For front_car() detection

## Reverse movement state
var _is_reversing: bool = false

func _ready() -> void:
	# Add to vehicles group for detection
	add_to_group("vehicles")
	add_to_group("Car")

	# Set up collision layers for CharacterBody2D (used for physics movement)
	set_collision_layer_value(1, true)  # Layer 1 for vehicles
	set_collision_mask_value(1, true)   # Detect other vehicles

	# Setup Area2D nodes for collision detection using the existing CollisionShape2D nodes
	_setup_collision_areas()

	# Apply vehicle type configuration
	_apply_vehicle_type()

	# Find and register wheels
	_setup_wheels()

	# Setup stats node with labels
	_setup_stats_node()


## Setup Area2D nodes for collision detection using existing CollisionShape2D children
func _setup_collision_areas() -> void:
	# Setup CarCollision Area2D - detects other cars for crashes
	var car_collision_shape = get_node_or_null("CarCollision")
	if car_collision_shape and car_collision_shape.shape:
		_car_collision_area = Area2D.new()
		_car_collision_area.name = "CarCollisionArea"
		_car_collision_area.collision_layer = 1  # Layer 1 = Cars
		_car_collision_area.collision_mask = 1   # Detect Cars only
		_car_collision_area.monitoring = true
		_car_collision_area.monitorable = true
		add_child(_car_collision_area)
		var area_shape = CollisionShape2D.new()
		area_shape.shape = car_collision_shape.shape.duplicate()
		area_shape.position = car_collision_shape.position
		_car_collision_area.add_child(area_shape)
		# Disable the original CollisionShape2D (we use Area2D now)
		car_collision_shape.disabled = true

	# Setup RoadBuildingCollision Area2D - detects road boundaries/buildings
	var road_building_shape = get_node_or_null("RoadBuildingCollision")
	if road_building_shape and road_building_shape.shape:
		_road_building_area = Area2D.new()
		_road_building_area.name = "RoadBuildingArea"
		_road_building_area.collision_layer = 1  # Layer 1 = Cars
		_road_building_area.collision_mask = 2   # Detect Roads/Buildings (Layer 2)
		_road_building_area.monitoring = true
		_road_building_area.monitorable = true
		add_child(_road_building_area)
		var area_shape = CollisionShape2D.new()
		area_shape.shape = road_building_shape.shape.duplicate()
		area_shape.position = road_building_shape.position
		_road_building_area.add_child(area_shape)
		# Disable the original CollisionShape2D
		road_building_shape.disabled = true

	# Setup FrontChecker Area2D - for front_car() detection
	var front_checker_shape = get_node_or_null("FrontChecker")
	if front_checker_shape and front_checker_shape.shape:
		_front_checker_area = Area2D.new()
		_front_checker_area.name = "FrontCheckerArea"
		_front_checker_area.collision_layer = 0  # Don't broadcast
		_front_checker_area.collision_mask = 1   # Detect Cars only
		_front_checker_area.monitoring = true
		_front_checker_area.monitorable = false
		add_child(_front_checker_area)
		var area_shape = CollisionShape2D.new()
		area_shape.shape = front_checker_shape.shape.duplicate()
		area_shape.position = front_checker_shape.position
		_front_checker_area.add_child(area_shape)
		# Disable the original CollisionShape2D
		front_checker_shape.disabled = true


## Setup the stats node with labels that StatsUIPanel reads
func _setup_stats_node() -> void:
	# Create container node for stats labels
	_stats_node = Node2D.new()
	_stats_node.name = "StatsNode"
	_stats_node.visible = false  # Labels are hidden, just for data storage
	add_child(_stats_node)

	# Create individual labels for each stat
	_stats_type_label = Label.new()
	_stats_type_label.name = "TypeLabel"
	_stats_node.add_child(_stats_type_label)

	_stats_color_label = Label.new()
	_stats_color_label.name = "ColorLabel"
	_stats_node.add_child(_stats_color_label)

	_stats_group_label = Label.new()
	_stats_group_label.name = "GroupLabel"
	_stats_node.add_child(_stats_group_label)

	_stats_speed_label = Label.new()
	_stats_speed_label.name = "SpeedLabel"
	_stats_node.add_child(_stats_speed_label)

	_stats_facing_label = Label.new()
	_stats_facing_label.name = "FacingLabel"
	_stats_node.add_child(_stats_facing_label)

	_stats_state_label = Label.new()
	_stats_state_label.name = "StateLabel"
	_stats_node.add_child(_stats_state_label)

	# Set initial values
	_update_stats_type()
	_update_stats_color()
	_update_stats_group()
	_update_stats_speed()
	_update_stats_facing()
	_update_stats_state()


## Update type label (called once when set)
func _update_stats_type() -> void:
	if _stats_type_label:
		_stats_type_label.text = get_vehicle_type_name()


## Update color label (called when spawned/color changes)
func _update_stats_color() -> void:
	if _stats_color_label:
		_stats_color_label.text = get_color_name()


## Update group label (called when spawned)
func _update_stats_group() -> void:
	if _stats_group_label:
		_stats_group_label.text = get_spawn_group_name()


## Update speed label (called once when set)
func _update_stats_speed() -> void:
	if _stats_speed_label:
		var effective_speed = speed * speed_multiplier * type_speed_mult
		_stats_speed_label.text = "%.1f" % effective_speed


## Update facing label (called every turn)
func _update_stats_facing() -> void:
	if _stats_facing_label:
		_stats_facing_label.text = get_facing_direction_name()


## Debug: Draw guideline paths
func _process(_delta: float) -> void:
	if _debug_draw_paths:
		queue_redraw()


func _draw() -> void:
	if not _debug_draw_paths or _current_path.is_empty():
		return
	
	# Draw path waypoints as circles and lines
	var prev_point = global_position
	for i in range(_path_index, _current_path.size()):
		var waypoint = _current_path[i]
		var local_point = waypoint - global_position
		
		# Draw line from previous point to this waypoint
		if i == _path_index:
			draw_line(Vector2.ZERO, local_point, Color.GREEN, 2.0)
		else:
			var prev_local = _current_path[i-1] - global_position
			draw_line(prev_local, local_point, Color.YELLOW, 2.0)
		
		# Draw waypoint circle
		draw_circle(local_point, 8.0, Color.RED if i == _path_index else Color.ORANGE)
		prev_point = waypoint


## Update state label (called every state change)
func _update_stats_state() -> void:
	if _stats_state_label:
		_stats_state_label.text = get_state_name()


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
			_update_stats_state()  # Update state label after wait ends
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
		# Check if we've moved enough tiles (for move(N) or move(-N) command)
		if _tiles_to_move > 0:
			var distance_moved = global_position.distance_to(_move_start_position)
			if distance_moved >= _tiles_to_move * TILE_SIZE:
				_tiles_to_move = 0
				_is_moving = false
				_is_reversing = false  # Reset reverse flag
				_wants_to_move = false
				velocity = Vector2.ZERO
				# Move command completed - process next command
				_command_completed()

		# Complete pending go() command once movement has started
		if _pending_go_command and velocity.length() > 1.0:
			_pending_go_command = false
			_command_completed()

	# Complete pending stop() command once movement has stopped
	if _pending_stop_command and velocity.length() < 0.1:
		_pending_stop_command = false
		_command_completed()


func _move(_delta: float) -> void:
	# Check if car is on a road tile
	if _road_checker != null:
		if not _is_on_road():
			_on_off_road_crash()
			return

	# Apply both user speed multiplier and vehicle type speed multiplier
	var actual_speed = speed * speed_multiplier * type_speed_mult

	# Reverse movement is 50% slower
	if _is_reversing:
		actual_speed *= 0.5
		velocity = -direction * actual_speed  # Move opposite to facing direction
	else:
		velocity = direction * actual_speed

	# Direct position update instead of move_and_slide() to avoid physics-based sliding
	global_position += velocity * get_physics_process_delta_time()

	# Collision detection is handled by dedicated Area2D nodes (CarCollision, RoadBuildingCollision)
	# Check for overlapping bodies using the collision area
	_check_area_collisions()


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

	# Check for tile transition (must happen even during simple movement!)
	var current_grid = _get_current_grid_pos()
	if current_grid != _current_tile:
		_on_enter_new_tile(current_grid)

	# After turning, use simple movement until entering a new tile
	if _use_simple_movement:
		_move(delta)
		return

	# Only acquire path when we have no path
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

	# Resume guideline movement on new tile
	_use_simple_movement = false

	# RESET decision lock for new tile (allows new road detection)
	_decision_made_for_tile = false
	_locked_exits.clear()

	# Calculate and LOCK entry direction
	# ALWAYS use _last_exit_direction for entry calculation (more stable)
	# The grid-based calculation is unreliable due to lane offset swings
	if _last_exit_direction != "":
		_locked_entry_direction = RoadTile.get_opposite_direction(_last_exit_direction)
	else:
		# First tile only - use facing direction
		_locked_entry_direction = _get_opposite_direction(_vector_to_connection_direction(direction))

	# Keep _entry_direction in sync for compatibility
	_entry_direction = _locked_entry_direction

	# Cache available exits for this tile
	_cache_available_exits()

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

	# If no valid exit, just return - let simple movement handle it
	# Crash will happen naturally if the car moves off-road
	if chosen_exit == "":
		return

	# Save exit direction for next tile's entry calculation
	_last_exit_direction = chosen_exit

	# Get the path
	_current_path = tile.get_guideline_path(_entry_direction, chosen_exit)
	_path_index = 0

	# Skip waypoints that are behind the car's current position
	# This handles spawning at tile center instead of entry edge
	if _current_path.size() > 1:
		var forward = direction.normalized()
		while _path_index < _current_path.size() - 1:
			var to_waypoint = _current_path[_path_index] - global_position
			# If waypoint is behind us (negative dot product), skip it
			if to_waypoint.dot(forward) < 0:
				_path_index += 1
			else:
				break

	# Clear queued turn only if it was actually used
	if turn_was_used:
		queued_turn = ""


## Choose which exit to take based on queued commands
## Returns [chosen_exit, turn_was_used] - turn_was_used indicates if queued_turn should be cleared
## Returns ["", false] if no valid path available
func _choose_exit(entry: String, available_exits: Array) -> Array:
	var opposite = RoadTile.get_opposite_direction(entry)

	# If there's a queued turn command, try to use it first
	if queued_turn == "left":
		var left = RoadTile.get_left_of(entry)
		if left in available_exits:
			return [left, true]  # Turn used
	elif queued_turn == "right":
		var right = RoadTile.get_right_of(entry)
		if right in available_exits:
			return [right, true]  # Turn used

	# Try to go straight (opposite of entry)
	if opposite in available_exits:
		return [opposite, false]  # Turn NOT used (kept for later)

	# Can't go straight - if a turn was queued but not available, try other directions
	if queued_turn != "":
		# Turn was queued but preferred direction not available
		# Try the other direction as fallback
		if queued_turn == "left":
			var right = RoadTile.get_right_of(entry)
			if right in available_exits:
				return [right, true]
		elif queued_turn == "right":
			var left = RoadTile.get_left_of(entry)
			if left in available_exits:
				return [left, true]

	# No turn queued and can't go straight - no valid path
	return ["", false]


## Move along the current path toward waypoints
func _move_along_path(delta: float) -> void:
	if _path_index >= _current_path.size():
		# Path complete - clear it so we get a new one on next tile
		_current_path.clear()
		_path_index = 0
		return

	var target = _current_path[_path_index]
	var to_target = target - global_position
	var dist = to_target.length()

	# Check if reached waypoint (threshold increased to prevent fast car overshoot)
	if dist < 15.0:
		_path_index += 1
		if _path_index >= _current_path.size():
			# Path complete
			_current_path.clear()
			_path_index = 0
		return

	# Move toward waypoint
	var move_dir = to_target.normalized()
	_current_move_dir = move_dir  # Save stable movement direction for grid calculations

	# Smoothly rotate toward waypoint (visual only)
	var target_rotation = move_dir.angle() + PI / 2
	rotation = lerp_angle(rotation, target_rotation, 0.3)

	# Keep direction in sync with visual rotation (so car faces where it appears to face)
	direction = Vector2.UP.rotated(rotation)

	# Move toward waypoint using move_dir (NOT direction)
	# This ensures car moves toward waypoint while visually rotating smoothly
	var actual_speed = speed * speed_multiplier * type_speed_mult
	velocity = move_dir * actual_speed
	global_position += velocity * delta

	# Collision detection is handled by dedicated Area2D nodes (CarCollision, RoadBuildingCollision)
	# Check for overlapping bodies using the collision area
	_check_area_collisions()


## Convert grid offset to direction string
func _grid_offset_to_direction(offset: Vector2i) -> String:
	match offset:
		Vector2i(0, -1): return "top"
		Vector2i(0, 1): return "bottom"
		Vector2i(-1, 0): return "left"
		Vector2i(1, 0): return "right"
	return ""


## Cache available exits when entering a tile (for decision locking)
func _cache_available_exits() -> void:
	_locked_exits.clear()
	if _road_checker == null or not _road_checker.has_method("get_road_tile"):
		return
	var tile = _road_checker.get_road_tile(_current_tile)
	if tile != null:
		_locked_exits = tile.get_available_exits(_locked_entry_direction)


func _check_destination() -> void:
	# Check against all destinations (multiple parking spots)
	if not _all_destinations.is_empty():
		for dest in _all_destinations:
			var distance = global_position.distance_to(dest)
			if distance < DESTINATION_THRESHOLD:
				stop()
				# Stop the interpreter for this vehicle (prevents move() from continuing)
				_stop_vehicle_interpreter()
				reached_destination.emit(vehicle_id)
				return
	# Fallback to single destination for backwards compatibility
	elif destination != Vector2.ZERO:
		var distance = global_position.distance_to(destination)
		if distance < DESTINATION_THRESHOLD:
			stop()
			# Stop the interpreter for this vehicle (prevents move() from continuing)
			_stop_vehicle_interpreter()
			reached_destination.emit(vehicle_id)


## Stop this vehicle's interpreter when reaching destination or crashing
func _stop_vehicle_interpreter() -> void:
	if has_meta("interpreter"):
		var interp = get_meta("interpreter")
		if interp != null and interp.has_method("stop_execution"):
			interp.stop_execution()
		# Clear the interpreter reference
		remove_meta("interpreter")


func _on_crash() -> void:
	stop()
	vehicle_state = 0  # Mark as crashed
	_switch_to_crashed_sprite()
	_update_stats_state()  # Update state label
	# Stop the interpreter for this vehicle
	_stop_vehicle_interpreter()
	crashed.emit(vehicle_id)


func _on_off_road_crash() -> void:
	stop()
	vehicle_state = 0  # Mark as crashed
	_switch_to_crashed_sprite()
	_update_stats_state()  # Update state label
	# Stop the interpreter for this vehicle
	_stop_vehicle_interpreter()
	off_road_crash.emit(vehicle_id)


## Check for collisions using the dedicated Area2D nodes
func _check_area_collisions() -> void:
	# Skip if already crashed
	if vehicle_state == 0:
		return

	# Check CarCollision Area - detect other cars for crashes
	if _car_collision_area:
		var car_overlaps = _car_collision_area.get_overlapping_areas()
		for area in car_overlaps:
			var parent = area.get_parent()
			if parent and parent != self and parent.is_in_group("Car"):
				var other_vehicle = parent as Vehicle
				if other_vehicle:
					# If hit a crashed car, only this car crashes
					if other_vehicle.vehicle_state == 0:
						_on_crash()
						return
					# If both active, both crash
					if vehicle_state == 1 and other_vehicle.vehicle_state == 1:
						_on_crash()
						other_vehicle._on_crash()
						return

	# Check RoadBuildingCollision Area - detect road boundaries/buildings
	if _road_building_area:
		var road_overlaps = _road_building_area.get_overlapping_bodies()
		for body in road_overlaps:
			if body.is_in_group("Road") or body.is_in_group("Building"):
				_on_off_road_crash()
				return
		# Also check areas in case roads use Area2D
		var road_area_overlaps = _road_building_area.get_overlapping_areas()
		for area in road_area_overlaps:
			if area.is_in_group("Road") or area.is_in_group("Building"):
				_on_off_road_crash()
				return
			var parent = area.get_parent()
			if parent and (parent.is_in_group("Road") or parent.is_in_group("Building")):
				_on_off_road_crash()
				return


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


## Move a specific number of tiles (positive = forward, negative = reverse)
## Reverse speed is 50% of normal speed
func move(tiles: int = 1) -> void:
	if tiles == 0:
		return
	if tiles < 0:
		# Reverse movement - negative tiles
		_command_queue.append({"type": "move_reverse", "tiles": -tiles})
	else:
		# Forward movement
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
		"move_reverse":
			_exec_move_reverse(_current_command["tiles"])


## Called when current command completes
func _command_completed() -> void:
	_current_command = {}
	_process_next_command()


# ============================================
# Command Execution (internal)
# ============================================

func _exec_go() -> void:
	# Safety check: don't start moving if already at destination or crashed
	if at_end() or vehicle_state == 0:
		_command_completed()
		return

	if _is_moving:
		# Already moving, complete immediately
		_command_completed()
		return

	# Start moving, but don't complete until movement actually starts
	_wants_to_move = true
	_is_moving = true
	# Track the direction we're moving so we don't turn back to it
	_last_move_direction = direction
	# Initialize exit direction if not set (ensures stable entry direction calculation)
	if _last_exit_direction == "":
		_last_exit_direction = _vector_to_connection_direction(direction)
	# NOTE: Do NOT set _decision_made_for_tile here!
	# go() should allow subsequent turn detection when car reaches tile center
	# Only turn() should lock the decision to prevent multiple turns
	_update_stats_state()  # Update state label

	# NEW: Set velocity IMMEDIATELY so car starts moving in the same frame
	# This eliminates the 1-frame delay that was visible to the player
	var actual_speed = speed * speed_multiplier * type_speed_mult
	velocity = direction * actual_speed

	# Block interpreter by setting pending command flag
	# Command will complete once velocity reaches minimum movement threshold
	_pending_go_command = true


func _exec_stop() -> void:
	if not _is_moving and velocity.length() < 0.1:
		# Already stopped, complete immediately
		_command_completed()
		return

	# Stop moving, but don't complete until velocity actually reaches zero
	_is_moving = false
	_is_reversing = false  # Reset reverse flag
	_wants_to_move = false
	velocity = Vector2.ZERO
	_tiles_to_move = 0
	_update_stats_state()  # Update state label

	# Block interpreter by setting pending command flag
	# Command will complete once velocity reaches zero
	_pending_stop_command = true


func _exec_turn(turn_direction: String) -> void:
	if turn_direction == "left" or turn_direction == "right":
		# LOCK decision for this tile (prevents zigzag from re-evaluation)
		_decision_made_for_tile = true

		# NEW: Stop the car when turning (matches CLAUDE.md documentation pattern)
		# User must call car.go() again to resume movement in new direction
		_is_moving = false
		_is_reversing = false  # Reset reverse flag
		_wants_to_move = false
		velocity = Vector2.ZERO

		# ALWAYS rotate immediately - bad code will crash, good code checked first
		_execute_turn(turn_direction)
		# Turn completion is handled in _process_turn()
	else:
		_command_completed()


func _exec_wait(seconds: float) -> void:
	wait_timer = seconds
	is_waiting = true
	_update_stats_state()  # Update state label
	# Wait completion is handled in _physics_process()


func _exec_move(tiles: int) -> void:
	# Safety check: don't move if already at destination or crashed
	if at_end() or vehicle_state == 0:
		_command_completed()
		return

	_tiles_to_move = tiles
	_move_start_position = global_position
	_is_moving = true
	_is_reversing = false
	_wants_to_move = true
	# Track the direction we're moving so we don't turn back to it
	_last_move_direction = direction
	# Move completion is handled in _physics_process()


## Execute reverse movement - move backwards at 50% speed
func _exec_move_reverse(tiles: int) -> void:
	# Safety check: don't move if already at destination or crashed
	if at_end() or vehicle_state == 0:
		_command_completed()
		return

	_tiles_to_move = tiles
	_move_start_position = global_position
	_is_moving = true
	_is_reversing = true  # Flag for reverse movement
	_wants_to_move = true
	# For reverse, we move opposite to current direction
	_last_move_direction = -direction
	# Move completion is handled in _physics_process()


## Get the grid position of the tile the car is currently on (compensating for lane offset)
func _get_current_grid_pos() -> Vector2i:
	# Use stable movement direction for lane offset (not the lerping visual direction)
	# This prevents grid position from jumping during rotation smoothing
	var offset_dir = _current_move_dir.rotated(PI / 2)
	var center_pos = global_position + (offset_dir.normalized() * LANE_OFFSET)
	return Vector2i(int(center_pos.x / TILE_SIZE), int(center_pos.y / TILE_SIZE))


## Get grid position without lane offset (for road detection)
## Lane offset is for visual positioning, but road detection needs actual tile
func _get_raw_grid_pos() -> Vector2i:
	return Vector2i(int(global_position.x / TILE_SIZE), int(global_position.y / TILE_SIZE))


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


## Check if there's a road in front of the car (short name)
## Uses LOCKED entry direction for consistent results within a tile
func front_road() -> bool:
	# Can't evaluate roads while turning - prevents multiple turn queuing
	if _is_turning:
		return false
	# If a decision (go/turn) was already made for this tile, return false
	# This prevents multiple turns on the same tile
	if _decision_made_for_tile:
		return false
	if _road_checker == null:
		return false

	# Use LOCKED entry direction for consistent road detection (if available)
	# If not yet initialized, use fallback detection below
	if _locked_entry_direction != "":
		# Check available exits using locked entry direction
		var tile = _road_checker.get_road_tile(_current_tile) if _road_checker.has_method("get_road_tile") else null
		if tile != null:
			var exits = tile.get_available_exits(_locked_entry_direction)
			# "Front" means continuing straight (opposite of entry)
			var straight_exit = RoadTile.get_opposite_direction(_locked_entry_direction)
			return straight_exit in exits

	# Fallback: check adjacent tile based on facing direction
	var grid_pos = _get_raw_grid_pos()
	var conn_dir = _vector_to_connection_direction(direction)

	if conn_dir != "" and _road_checker.has_method("is_road_connected"):
		var adjacent_offset = _get_grid_offset_from_direction(conn_dir)
		var adjacent_grid = grid_pos + adjacent_offset
		var opposite_dir = _get_opposite_direction(conn_dir)
		return _road_checker.is_road_connected(adjacent_grid, opposite_dir)

	var front_offset = direction.normalized() * TILE_SIZE
	var front_pos = global_position + front_offset
	return _is_road_at_position(front_pos)


## Check if car is close enough to tile center for turn detection
## This prevents early turn detection at tile edges
func _is_near_turn_point() -> bool:
	# Get tile center position
	var tile_center = Vector2(
		_current_tile.x * TILE_SIZE + TILE_SIZE / 2,
		_current_tile.y * TILE_SIZE + TILE_SIZE / 2
	)
	# Check distance from car to tile center
	var dist_to_center = global_position.distance_to(tile_center)
	# Only allow turn detection when very close to center (in the middle of the road)
	return dist_to_center < 10


## Check if there's a road to the left of the car (short name)
## Uses LOCKED entry direction for consistent results within a tile
func left_road() -> bool:
	# Can't evaluate roads while turning - prevents multiple turn queuing
	if _is_turning:
		return false
	# If a decision (go/turn) was already made for this tile, return false
	# This prevents multiple turns on the same tile
	if _decision_made_for_tile:
		return false
	# Only detect side roads when near the turn point (prevents early turning)
	if not _is_near_turn_point():
		return false
	if _road_checker == null:
		return false

	# Use LOCKED entry direction for consistent road detection (if available)
	# If not yet initialized, use fallback detection below
	if _locked_entry_direction != "":
		# Check available exits using locked entry direction
		var tile = _road_checker.get_road_tile(_current_tile) if _road_checker.has_method("get_road_tile") else null
		if tile != null:
			var exits = tile.get_available_exits(_locked_entry_direction)
			# Check cardinal left direction
			var left_exit = RoadTile.get_left_of(_locked_entry_direction)
			return left_exit in exits

	# Fallback: check adjacent tile based on facing direction
	var grid_pos = _get_raw_grid_pos()
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
## Uses LOCKED entry direction for consistent results within a tile
func right_road() -> bool:
	# Can't evaluate roads while turning - prevents multiple turn queuing
	if _is_turning:
		return false
	# If a decision (go/turn) was already made for this tile, return false
	# This prevents multiple turns on the same tile
	if _decision_made_for_tile:
		return false
	# Only detect side roads when near the turn point (prevents early turning)
	if not _is_near_turn_point():
		return false
	if _road_checker == null:
		return false

	# Use LOCKED entry direction for consistent road detection (if available)
	# If not yet initialized, use fallback detection below
	if _locked_entry_direction != "":
		# Check available exits using locked entry direction
		var tile = _road_checker.get_road_tile(_current_tile) if _road_checker.has_method("get_road_tile") else null
		if tile != null:
			var exits = tile.get_available_exits(_locked_entry_direction)
			# Check cardinal right direction
			var right_exit = RoadTile.get_right_of(_locked_entry_direction)
			return right_exit in exits

	# Fallback: check adjacent tile based on facing direction
	var grid_pos = _get_raw_grid_pos()
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


## Check if there's ANY car (crashed or active) in front using FrontChecker Area2D
func front_car() -> bool:
	if _front_checker_area == null:
		# Fallback to position-based check
		var front_offset = direction.normalized() * TILE_SIZE
		var front_pos = global_position + front_offset
		return _is_vehicle_at_position(front_pos)

	# Use FrontChecker Area2D get_overlapping_areas()
	var overlapping = _front_checker_area.get_overlapping_areas()
	for area in overlapping:
		var parent = area.get_parent()
		if parent and parent != self and parent.is_in_group("Car"):
			return true
	return false


## Check if there's a CRASHED car in front using FrontChecker Area2D
func front_crash() -> bool:
	if _front_checker_area == null:
		# Fallback to position-based check
		var front_offset = direction.normalized() * TILE_SIZE
		var front_pos = global_position + front_offset
		return _is_crashed_vehicle_at_position(front_pos)

	# Use FrontChecker Area2D get_overlapping_areas()
	var overlapping = _front_checker_area.get_overlapping_areas()
	for area in overlapping:
		var parent = area.get_parent()
		if parent and parent != self and parent.is_in_group("Car"):
			var other_vehicle = parent as Vehicle
			if other_vehicle and other_vehicle.vehicle_state == 0:  # 0 = crashed
				return true
	return false


## Check if the car is at a dead end (no road in any direction) (short name)
func dead_end() -> bool:
	# Can't evaluate dead end while turning - prevents loop early termination
	if _is_turning:
		return false
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


## Set all possible destinations (multiple parking spots)
## Car will be considered "at end" when reaching ANY of these
## Also filters group-specific destinations if car has a spawn group
func set_all_destinations(destinations: Array) -> void:
	_all_destinations.clear()
	_group_destinations.clear()
	for dest in destinations:
		if dest is Vector2:
			_all_destinations.append(dest)
		elif dest is Dictionary:
			if dest.has("position"):
				_all_destinations.append(dest["position"])
			# Store group-specific destinations
			# Compare as integers since RoadTileMapLayer.SpawnGroup and Vehicle.SpawnGroup are different enums
			if dest.has("group") and spawn_group != SpawnGroup.NONE:
				var dest_group_int = int(dest["group"])
				var spawn_group_int = int(spawn_group)
				if dest_group_int == spawn_group_int:
					_group_destinations.append(dest)


## Set spawn group and filter destinations
## Accepts Vehicle.SpawnGroup or RoadTileMapLayer.SpawnGroup (converts via int)
func set_spawn_group(group) -> void:
	# Convert to int first to handle different enum types
	var group_int = int(group)
	match group_int:
		0: spawn_group = SpawnGroup.A
		1: spawn_group = SpawnGroup.B
		2: spawn_group = SpawnGroup.C
		3: spawn_group = SpawnGroup.D
		_: spawn_group = SpawnGroup.NONE
	_update_stats_group()  # Update group label


## Get spawn group name as string
func get_spawn_group_name() -> String:
	match spawn_group:
		SpawnGroup.A: return "A"
		SpawnGroup.B: return "B"
		SpawnGroup.C: return "C"
		SpawnGroup.D: return "D"
		_: return "None"


## Check if car is at correct destination for its group
## Returns true if at correct group destination, false if at wrong group
func is_at_correct_destination() -> bool:
	if spawn_group == SpawnGroup.NONE:
		return true  # No group requirement
	if _group_destinations.is_empty():
		return true  # No group-specific destinations defined

	for dest_data in _group_destinations:
		var dest_pos = dest_data.get("position", Vector2.ZERO)
		if global_position.distance_to(dest_pos) < DESTINATION_THRESHOLD:
			return true  # At correct group destination

	return false  # Not at correct destination


## Check if car is at any destination (regardless of group)
func is_at_any_destination() -> bool:
	for dest in _all_destinations:
		if global_position.distance_to(dest) < DESTINATION_THRESHOLD:
			return true
	return false


## Get current vehicle state for stats display
func get_current_state() -> VehicleState:
	if vehicle_state == 0:
		return VehicleState.CRASHED
	if at_end():
		return VehicleState.PARKED
	if is_waiting:
		return VehicleState.WAITING
	if _is_moving:
		return VehicleState.MOVING
	return VehicleState.WAITING


## Get vehicle state name as string
func get_state_name() -> String:
	match get_current_state():
		VehicleState.PARKED: return "Parked"
		VehicleState.MOVING: return "Moving"
		VehicleState.WAITING: return "Waiting"
		VehicleState.CRASHED: return "Crashed"
	return "Unknown"


## Get facing direction as string (South, North, East, West)
func get_facing_direction_name() -> String:
	# Normalize direction to check
	var dir = direction.normalized()
	if abs(dir.y) > abs(dir.x):
		if dir.y > 0:
			return "South"
		else:
			return "North"
	else:
		if dir.x > 0:
			return "East"
		else:
			return "West"


## Check if vehicle has reached its destination (short name)
## Works with multiple destinations - returns true if at ANY destination
func at_end() -> bool:
	# Check against all destinations
	if not _all_destinations.is_empty():
		for dest in _all_destinations:
			if global_position.distance_to(dest) < DESTINATION_THRESHOLD:
				return true
		return false
	# Fallback to single destination
	if destination == Vector2.ZERO:
		return false
	return global_position.distance_to(destination) < DESTINATION_THRESHOLD


## Get distance to nearest destination (short name)
## Works with multiple destinations - returns distance to closest one
func dist() -> float:
	# Check against all destinations, return closest
	if not _all_destinations.is_empty():
		var min_dist: float = -1.0
		for dest in _all_destinations:
			var d = global_position.distance_to(dest)
			if min_dist < 0 or d < min_dist:
				min_dist = d
		return min_dist
	# Fallback to single destination
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
	_current_move_dir = direction  # Initialize stable movement direction
	# Car sprite faces UP, so add PI/2 to make it face the direction
	rotation = direction.angle() + PI / 2
	_is_moving = false
	_is_reversing = false  # Reset reverse flag
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
	_last_exit_direction = _vector_to_connection_direction(direction)  # Initialize with starting direction
	_use_simple_movement = false
	# Reset last move direction tracking (used in fallback road detection)
	_last_move_direction = Vector2.ZERO
	# Initialize current tile and entry direction for guideline system
	# This ensures front_road(), left_road(), right_road() work immediately
	_current_tile = _get_current_grid_pos()
	_entry_direction = _get_opposite_direction(_vector_to_connection_direction(direction))
	# Reset decision locking state
	_decision_made_for_tile = false
	_locked_exits.clear()
	_locked_entry_direction = _entry_direction  # Initialize locked entry direction


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

		# Use the car's FACING direction to check the correct arrow
		var direction_name = _vector_to_direction_name(direction)

		# If we're very close (passing through) and light is red for our direction
		if distance < 30.0 and stoplight.is_red(direction_name):
			if stoplight not in _passed_stoplights:
				# First time passing this red light - violation!
				_passed_stoplights.append(stoplight)
				ran_red_light.emit(vehicle_id, stoplight.stoplight_id)

		# Reset tracking when we're far away from the stoplight
		elif distance > STOPLIGHT_DETECTION_RANGE:
			if stoplight in _passed_stoplights:
				_passed_stoplights.erase(stoplight)


## Check if there's a red light nearby (short name)



func _vector_to_direction_name(vec: Vector2) -> String:
	# Determine which direction the vector is pointing
	if abs(vec.x) > abs(vec.y):
		return "east" if vec.x > 0 else "west"
	else:
		return "south" if vec.y > 0 else "north"


## Check if there's a red light nearby (short name)
func at_red() -> bool:
	for stoplight in _nearby_stoplights:
		if global_position.distance_to(stoplight.global_position) < STOPLIGHT_STOP_DISTANCE:
			# Use the car's FACING direction, not the direction to the stoplight
			var direction_name = _vector_to_direction_name(direction)
			if stoplight.is_red(direction_name):
				return true
	return false


## Check if there's a green light nearby (short name)
func at_green() -> bool:
	for stoplight in _nearby_stoplights:
		if global_position.distance_to(stoplight.global_position) < STOPLIGHT_STOP_DISTANCE:
			# Use the car's FACING direction, not the direction to the stoplight
			var direction_name = _vector_to_direction_name(direction)
			if stoplight.is_green(direction_name):
				return true
	return false


## Check if there's a yellow light nearby (short name)
func at_yellow() -> bool:
	for stoplight in _nearby_stoplights:
		if global_position.distance_to(stoplight.global_position) < STOPLIGHT_STOP_DISTANCE:
			# Use the car's FACING direction, not the direction to the stoplight
			var direction_name = _vector_to_direction_name(direction)
			if stoplight.is_yellow(direction_name):
				return true
	return false


## Check if car is blocked by light (within detection range)
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

		# Update exit direction to match new facing - critical for NEXT tile entry calculation
		_last_exit_direction = _vector_to_connection_direction(direction)

		# DO NOT update _entry_direction here - keep it LOCKED until new tile!
		# This is the key fix for the zigzag problem.
		# The locked entry direction ensures road detection returns consistent values.

		# Update facing label after turn completes
		_update_stats_facing()

		# After turning, use simple movement to exit the tile
		# We already know the exit direction (_last_exit_direction), so just move that way
		# Don't try to re-acquire a path based on old entry direction
		_use_simple_movement = true
		_current_path.clear()
		_path_index = 0

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


# ============================================
# Color Palette System
# ============================================

## Set a random color based on vehicle type and rarity rules
## - Cars (Sedan, Estate, Sport, Micro, Pickup): Use rarity weights (60% Common, 30% Uncommon, 10% Rare)
## - Jeepneys: Equal chance for all 15 colors
## - Bus: Always white
func set_random_color() -> void:
	var chosen_color: VehicleColor

	match vehicle_type:
		VehicleType.BUS:
			# Bus is always white
			chosen_color = VehicleColor.WHITE
		VehicleType.JEEPNEY_1, VehicleType.JEEPNEY_2:
			# Jeepneys have equal chance for all colors
			chosen_color = ALL_COLORS[randi() % ALL_COLORS.size()]
		_:
			# Regular cars use rarity-weighted selection
			chosen_color = _roll_color_by_rarity()

	set_color_palette(chosen_color)


## Roll a color based on rarity weights
func _roll_color_by_rarity() -> VehicleColor:
	var roll = randi() % 100  # 0-99

	if roll < RARITY_WEIGHTS[ColorRarity.COMMON]:
		# Common (0-59)
		return COMMON_COLORS[randi() % COMMON_COLORS.size()]
	elif roll < RARITY_WEIGHTS[ColorRarity.COMMON] + RARITY_WEIGHTS[ColorRarity.UNCOMMON]:
		# Uncommon (60-89)
		return UNCOMMON_COLORS[randi() % UNCOMMON_COLORS.size()]
	else:
		# Rare (90-99)
		return RARE_COLORS[randi() % RARE_COLORS.size()]


## Set the color palette for this vehicle
func set_color_palette(color: VehicleColor) -> void:
	current_color_palette = color
	_apply_color_palette()
	_update_stats_color()  # Update color label


## Set color palette by index (0-14)
func set_color_palette_index(index: int) -> void:
	if index >= 0 and index < ALL_COLORS.size():
		set_color_palette(ALL_COLORS[index])


## Apply the current color palette to the sprite's shader
func _apply_color_palette() -> void:
	var sprite = get_node_or_null("Sprite2D")
	if sprite == null:
		return

	# Get the color name for the palette file
	var color_name = get_color_name()
	var palette_path = "res://assets/cars/Cars Color Palette/gocars palette-%s.png" % color_name

	# Load the palette texture
	var palette_texture = load(palette_path)
	if palette_texture == null:
		push_warning("Could not load palette texture: %s" % palette_path)
		return

	# Get the shader material
	var material = sprite.material as ShaderMaterial
	if material == null:
		push_warning("Vehicle sprite does not have a ShaderMaterial")
		return

	# IMPORTANT: Duplicate the material so each vehicle has its own instance
	# Otherwise all vehicles would share the same color
	if not sprite.has_meta("material_duplicated"):
		sprite.material = material.duplicate()
		sprite.set_meta("material_duplicated", true)
		material = sprite.material as ShaderMaterial

	# Set the new palette texture
	material.set_shader_parameter("new_palette", palette_texture)


## Get the current color palette enum value
func get_color_palette() -> VehicleColor:
	return current_color_palette


## Get the current color palette index (0-14)
func get_color_palette_index() -> int:
	return current_color_palette as int


## Get total number of available colors
func get_palette_count() -> int:
	return ALL_COLORS.size()


## Get the name of the current color (e.g., "WHITE", "BLUE", "MAGENTA")
func get_color_name() -> String:
	if current_color_palette in COLOR_PALETTE_FILES:
		return COLOR_PALETTE_FILES[current_color_palette]
	return "WHITE"


## Get the rarity of the current color
func get_color_rarity() -> ColorRarity:
	if current_color_palette in COMMON_COLORS:
		return ColorRarity.COMMON
	elif current_color_palette in UNCOMMON_COLORS:
		return ColorRarity.UNCOMMON
	elif current_color_palette in RARE_COLORS:
		return ColorRarity.RARE
	return ColorRarity.COMMON


## Get the rarity name as a string
func get_color_rarity_name() -> String:
	match get_color_rarity():
		ColorRarity.COMMON:
			return "Common"
		ColorRarity.UNCOMMON:
			return "Uncommon"
		ColorRarity.RARE:
			return "Rare"
	return "Common"
