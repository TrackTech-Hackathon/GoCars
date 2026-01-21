extends Node
class_name LevelManager

## Manages level loading, entity spawning, win/lose tracking, and level transitions.
## Loads level configurations from JSON files in data/levels/

# Level types
enum LevelType {
	CODE_ONLY,       # Fixed roads, no building - pure coding puzzle
	BUILD_AND_CODE   # Limited road cards - building IS part of the puzzle
}

signal level_loaded(level_id: String)
signal level_started(level_id: String)
signal level_completed(level_id: String, stars: int)
signal level_failed(level_id: String, reason: String)
signal level_restarted(level_id: String)

# Level data paths
const LEVELS_PATH: String = "res://data/levels/"

# Current level state
var current_level_id: String = ""
var current_level_data: Dictionary = {}
var current_level_type: LevelType = LevelType.CODE_ONLY
var _level_start_time: float = 0.0
var _code_lines_used: int = 0

# Entity references (spawned entities)
var _spawned_vehicles: Array = []
var _spawned_stoplights: Array = []
var _spawned_intersections: Array = []  # Vector2 positions

# Preloaded scenes
var _vehicle_scene: PackedScene = null
var _stoplight_scene: PackedScene = null
var _stoplight_4way_scene: PackedScene = null

# References
var _simulation_engine: SimulationEngine = null
var _game_world: Node2D = null

# Star rating criteria (from level data or defaults)
var _star_criteria: Dictionary = {
	"one_star": "complete",
	"two_stars": "no_crashes",
	"three_stars": "lines_of_code <= 5"
}

# Level completion tracking
var _crashes_occurred: int = 0
var _level_completed_flag: bool = false


func _ready() -> void:

	# Try to preload stoplight scenes (may not exist yet)
	if ResourceLoader.exists("res://scenes/entities/stoplight.tscn"):
		_stoplight_scene = preload("res://scenes/entities/stoplight.tscn")
	if ResourceLoader.exists("res://scenes/entities/stoplight_4way.tscn"):
		_stoplight_4way_scene = preload("res://scenes/entities/stoplight_4way.tscn")


# ============================================
# Initialization
# ============================================

## Set the simulation engine reference
func set_simulation_engine(engine: SimulationEngine) -> void:
	_simulation_engine = engine

	# Connect to simulation signals
	if _simulation_engine:
		_simulation_engine.level_completed.connect(_on_simulation_level_completed)
		_simulation_engine.level_failed.connect(_on_simulation_level_failed)
		_simulation_engine.car_crashed.connect(_on_car_crashed)


## Set the game world node (parent for spawned entities)
func set_game_world(world: Node2D) -> void:
	_game_world = world


# ============================================
# Level Loading
# ============================================

## Load a level by ID (e.g., "T1", "C1", "W1")
func load_level(level_id: String) -> bool:
	var level_path = LEVELS_PATH + level_id.to_lower() + ".json"

	# Check if file exists
	if not FileAccess.file_exists(level_path):
		push_error("Level file not found: %s" % level_path)
		return false

	# Load JSON file
	var file = FileAccess.open(level_path, FileAccess.READ)
	if file == null:
		push_error("Failed to open level file: %s" % level_path)
		return false

	var json_text = file.get_as_text()
	file.close()

	# Parse JSON
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	if parse_result != OK:
		push_error("Failed to parse level JSON: %s (line %d)" % [json.get_error_message(), json.get_error_line()])
		return false

	current_level_data = json.data
	current_level_id = level_id

	# Load star criteria if present
	if current_level_data.has("star_criteria"):
		_star_criteria = current_level_data["star_criteria"]

	# Parse level type (default to CODE_ONLY if not specified)
	if current_level_data.has("level_type"):
		match current_level_data["level_type"]:
			"CODE_ONLY":
				current_level_type = LevelType.CODE_ONLY
			"BUILD_AND_CODE":
				current_level_type = LevelType.BUILD_AND_CODE
			_:
				current_level_type = LevelType.CODE_ONLY
	else:
		current_level_type = LevelType.CODE_ONLY

	level_loaded.emit(level_id)
	return true


## Load level from a Dictionary (for testing or dynamic levels)
func load_level_from_data(level_data: Dictionary) -> bool:
	if not level_data.has("id"):
		push_error("Level data must have an 'id' field")
		return false

	current_level_data = level_data
	current_level_id = level_data["id"]

	if current_level_data.has("star_criteria"):
		_star_criteria = current_level_data["star_criteria"]

	# Parse level type
	if current_level_data.has("level_type"):
		match current_level_data["level_type"]:
			"CODE_ONLY":
				current_level_type = LevelType.CODE_ONLY
			"BUILD_AND_CODE":
				current_level_type = LevelType.BUILD_AND_CODE
			_:
				current_level_type = LevelType.CODE_ONLY
	else:
		current_level_type = LevelType.CODE_ONLY

	level_loaded.emit(current_level_id)
	return true


## Get list of available level IDs
func get_available_levels() -> Array:
	var levels: Array = []
	var dir = DirAccess.open(LEVELS_PATH)

	if dir == null:
		push_warning("Could not open levels directory: %s" % LEVELS_PATH)
		return levels

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if file_name.ends_with(".json"):
			levels.append(file_name.replace(".json", "").to_upper())
		file_name = dir.get_next()

	dir.list_dir_end()
	return levels


# ============================================
# Level Setup (Spawning)
# ============================================

## Start the current level (spawn entities and configure simulation)
func start_level() -> void:
	if current_level_data.is_empty():
		push_error("No level loaded")
		return

	if _game_world == null:
		push_error("Game world not set")
		return

	# Clear any existing entities
	_clear_spawned_entities()

	# Reset tracking
	_crashes_occurred = 0
	_level_completed_flag = false
	_code_lines_used = 0
	_level_start_time = Time.get_ticks_msec() / 1000.0

	# Spawn entities from level data
	_spawn_entities()

	# Configure simulation engine
	_configure_simulation()

	level_started.emit(current_level_id)


## Clear all spawned entities
func _clear_spawned_entities() -> void:
	# Unregister and free vehicles
	for vehicle in _spawned_vehicles:
		if is_instance_valid(vehicle):
			if _simulation_engine:
				_simulation_engine.unregister_vehicle(vehicle.vehicle_id)
			vehicle.queue_free()
	_spawned_vehicles.clear()

	# Unregister and free stoplights
	for stoplight in _spawned_stoplights:
		if is_instance_valid(stoplight):
			if _simulation_engine:
				_simulation_engine.unregister_stoplight(stoplight.stoplight_id)
			stoplight.queue_free()
	_spawned_stoplights.clear()

	# Clear intersection positions
	_spawned_intersections.clear()


## Spawn all entities defined in level data
func _spawn_entities() -> void:
	if not current_level_data.has("entities"):
		return

	var entities = current_level_data["entities"]

	# Spawn vehicles
	if entities.has("cars"):
		for car_data in entities["cars"]:
			_spawn_vehicle(car_data)

	# Spawn stoplights
	if entities.has("stoplights"):
		for light_data in entities["stoplights"]:
			_spawn_stoplight(light_data)

	# Register intersections
	if entities.has("intersections"):
		for intersection_data in entities["intersections"]:
			_register_intersection(intersection_data)


## Spawn a vehicle from data
func _spawn_vehicle(data: Dictionary) -> Vehicle:
	if _vehicle_scene == null:
		push_error("Vehicle scene not loaded")
		return null

	var vehicle: Vehicle = _vehicle_scene.instantiate()

	# Configure vehicle
	if data.has("id"):
		vehicle.vehicle_id = data["id"]

	# Set position (data uses [x, y] array or grid coordinates)
	if data.has("position"):
		var pos = data["position"]
		if pos is Array and pos.size() >= 2:
			# Check if using grid coordinates (small values) or pixel coordinates
			if pos[0] < 50 and pos[1] < 50:
				# Assume grid coordinates, convert to pixels (64px per tile)
				vehicle.position = Vector2(pos[0] * 64, pos[1] * 64)
			else:
				# Pixel coordinates
				vehicle.position = Vector2(pos[0], pos[1])

	# Set destination
	if data.has("destination"):
		var dest = data["destination"]
		if dest is Array and dest.size() >= 2:
			if dest[0] < 50 and dest[1] < 50:
				vehicle.destination = Vector2(dest[0] * 64, dest[1] * 64)
			else:
				vehicle.destination = Vector2(dest[0], dest[1])

	# Set initial direction
	if data.has("direction"):
		var dir_str = data["direction"]
		match dir_str:
			"right": vehicle.direction = Vector2.RIGHT
			"left": vehicle.direction = Vector2.LEFT
			"up": vehicle.direction = Vector2.UP
			"down": vehicle.direction = Vector2.DOWN
		vehicle.rotation = vehicle.direction.angle()

	# Set speed multiplier
	if data.has("speed"):
		vehicle.speed_multiplier = data["speed"]

	# Set random color based on vehicle type and rarity
	vehicle.set_random_color()

	# Add to game world
	_game_world.add_child(vehicle)
	_spawned_vehicles.append(vehicle)

	# Register with simulation engine
	if _simulation_engine:
		_simulation_engine.register_vehicle(vehicle)

		# Make vehicle aware of all stoplights
		for stoplight in _spawned_stoplights:
			vehicle.add_stoplight(stoplight)

		# Make vehicle aware of all intersections
		for intersection_pos in _spawned_intersections:
			vehicle.add_intersection(intersection_pos)

	return vehicle


## Spawn a stoplight from data
func _spawn_stoplight(data: Dictionary) -> Stoplight:
	var scene_to_use = _stoplight_scene

	# Use 4-way stoplight if specified
	if data.has("type") and data["type"] == "4way":
		scene_to_use = _stoplight_4way_scene

	if scene_to_use == null:
		push_error("Stoplight scene not loaded")
		return null

	var stoplight: Stoplight = scene_to_use.instantiate()

	# Configure stoplight
	if data.has("id"):
		stoplight.stoplight_id = data["id"]

	# Set position
	if data.has("position"):
		var pos = data["position"]
		if pos is Array and pos.size() >= 2:
			if pos[0] < 50 and pos[1] < 50:
				stoplight.position = Vector2(pos[0] * 64, pos[1] * 64)
			else:
				stoplight.position = Vector2(pos[0], pos[1])

	# Set initial state
	if data.has("initial_state"):
		match data["initial_state"]:
			"red": stoplight.initial_state = Stoplight.LightState.RED
			"yellow": stoplight.initial_state = Stoplight.LightState.YELLOW
			"green": stoplight.initial_state = Stoplight.LightState.GREEN

	# Add to game world
	_game_world.add_child(stoplight)
	_spawned_stoplights.append(stoplight)

	# Register with simulation engine
	if _simulation_engine:
		_simulation_engine.register_stoplight(stoplight)

	# Make all existing vehicles aware of this stoplight
	for vehicle in _spawned_vehicles:
		vehicle.add_stoplight(stoplight)

	return stoplight


## Register an intersection position
func _register_intersection(data: Dictionary) -> void:
	var pos = Vector2.ZERO

	if data.has("position"):
		var pos_data = data["position"]
		if pos_data is Array and pos_data.size() >= 2:
			if pos_data[0] < 50 and pos_data[1] < 50:
				pos = Vector2(pos_data[0] * 64, pos_data[1] * 64)
			else:
				pos = Vector2(pos_data[0], pos_data[1])

	_spawned_intersections.append(pos)

	# Make all existing vehicles aware of this intersection
	for vehicle in _spawned_vehicles:
		vehicle.add_intersection(pos)


## Configure simulation engine with level settings
func _configure_simulation() -> void:
	if _simulation_engine == null:
		return

	# Set time limit if specified
	if current_level_data.has("time_limit"):
		_simulation_engine.set_time_limit(float(current_level_data["time_limit"]))
	else:
		_simulation_engine.set_time_limit(0)  # No limit

	# Set map bounds if specified
	if current_level_data.has("bounds"):
		var bounds = current_level_data["bounds"]
		if bounds is Dictionary:
			var rect = Rect2(
				bounds.get("x", 0),
				bounds.get("y", 0),
				bounds.get("width", 2000),
				bounds.get("height", 2000)
			)
			_simulation_engine.set_map_bounds(rect)


# ============================================
# Level Restart
# ============================================

## Restart the current level
func restart_level() -> void:
	if current_level_id.is_empty():
		push_error("No level to restart")
		return

	# Reset simulation
	if _simulation_engine:
		_simulation_engine.reset()

	# Re-spawn entities
	start_level()

	level_restarted.emit(current_level_id)


## Reset vehicles to starting positions (without re-spawning)
func reset_vehicles() -> void:
	if not current_level_data.has("entities"):
		return

	var entities = current_level_data["entities"]

	if entities.has("cars"):
		var car_index = 0
		for car_data in entities["cars"]:
			if car_index < _spawned_vehicles.size():
				var vehicle = _spawned_vehicles[car_index]

				# Reset position
				if car_data.has("position"):
					var pos = car_data["position"]
					if pos is Array and pos.size() >= 2:
						if pos[0] < 50 and pos[1] < 50:
							vehicle.reset(Vector2(pos[0] * 64, pos[1] * 64))
						else:
							vehicle.reset(Vector2(pos[0], pos[1]))

				# Reset direction
				if car_data.has("direction"):
					var dir_str = car_data["direction"]
					var dir_vec = Vector2.RIGHT
					match dir_str:
						"right": dir_vec = Vector2.RIGHT
						"left": dir_vec = Vector2.LEFT
						"up": dir_vec = Vector2.UP
						"down": dir_vec = Vector2.DOWN
					vehicle.direction = dir_vec
					vehicle.rotation = dir_vec.angle()

				car_index += 1


# ============================================
# Star Rating Calculation
# ============================================

## Track code lines used (call this when code is executed)
func set_code_lines(lines: int) -> void:
	_code_lines_used = lines


## Calculate star rating based on criteria
func calculate_stars() -> int:
	var stars = 0

	# Check one star (usually just completion)
	if _check_star_criteria(_star_criteria.get("one_star", "complete")):
		stars = 1

	# Check two stars
	if stars >= 1 and _check_star_criteria(_star_criteria.get("two_stars", "no_crashes")):
		stars = 2

	# Check three stars
	if stars >= 2 and _check_star_criteria(_star_criteria.get("three_stars", "lines_of_code <= 5")):
		stars = 3

	return stars


## Check if a star criteria is met
func _check_star_criteria(criteria: String) -> bool:
	match criteria:
		"complete":
			return _level_completed_flag
		"no_crashes":
			return _crashes_occurred == 0
		_:
			# Parse criteria like "lines_of_code <= 5" or "time <= 30"
			if criteria.begins_with("lines_of_code"):
				var parts = criteria.split(" ")
				if parts.size() >= 3:
					var op = parts[1]
					var value = int(parts[2])
					return _compare(op, _code_lines_used, value)
			elif criteria.begins_with("time"):
				var parts = criteria.split(" ")
				if parts.size() >= 3:
					var op = parts[1]
					var value = float(parts[2])
					var elapsed = _get_elapsed_time()
					return _compare(op, elapsed, value)

	return true  # Default to passing unknown criteria


## Compare values with operator
func _compare(op: String, left: float, right: float) -> bool:
	match op:
		"<=": return left <= right
		"<": return left < right
		">=": return left >= right
		">": return left > right
		"==": return left == right
		"!=": return left != right
	return false


## Get elapsed time since level start
func _get_elapsed_time() -> float:
	return (Time.get_ticks_msec() / 1000.0) - _level_start_time


# ============================================
# Level Transitions
# ============================================

## Get the next level ID in sequence
func get_next_level_id() -> String:
	if current_level_id.is_empty():
		return ""

	# Parse current level ID (e.g., "T1" -> prefix "T", number 1)
	var prefix = ""
	var number = 0

	for i in range(current_level_id.length()):
		var c = current_level_id[i]
		if c.is_valid_int():
			prefix = current_level_id.substr(0, i)
			number = int(current_level_id.substr(i))
			break

	# Try next number in same series
	var next_id = prefix + str(number + 1)
	var next_path = LEVELS_PATH + next_id.to_lower() + ".json"

	if FileAccess.file_exists(next_path):
		return next_id

	# If not found, try next series
	var series_order = ["T", "C", "W"]
	var current_series_index = series_order.find(prefix)

	if current_series_index >= 0 and current_series_index < series_order.size() - 1:
		var next_series = series_order[current_series_index + 1]
		next_id = next_series + "1"
		next_path = LEVELS_PATH + next_id.to_lower() + ".json"

		if FileAccess.file_exists(next_path):
			return next_id

	return ""  # No next level


## Load and start the next level
func go_to_next_level() -> bool:
	var next_id = get_next_level_id()
	if next_id.is_empty():
		return false

	if load_level(next_id):
		start_level()
		return true

	return false


# ============================================
# Event Handlers
# ============================================

func _on_simulation_level_completed(_stars: int) -> void:
	_level_completed_flag = true
	var calculated_stars = calculate_stars()
	level_completed.emit(current_level_id, calculated_stars)


func _on_simulation_level_failed(reason: String) -> void:
	level_failed.emit(current_level_id, reason)


func _on_car_crashed(_car_id: String) -> void:
	_crashes_occurred += 1


# ============================================
# Level Info Getters
# ============================================

## Get current level name
func get_level_name() -> String:
	return current_level_data.get("name", current_level_id)


## Get current level description
func get_level_description() -> String:
	return current_level_data.get("description", "")


## Get available functions for current level
func get_available_functions() -> Array:
	return current_level_data.get("available_functions", [])


## Get level time limit (0 = no limit)
func get_time_limit() -> float:
	return float(current_level_data.get("time_limit", 0))


## Check if level is loaded
func is_level_loaded() -> bool:
	return not current_level_data.is_empty()


## Get current level type
func get_level_type() -> LevelType:
	return current_level_type


## Get initial road cards for current level
func get_initial_road_cards() -> int:
	if current_level_type == LevelType.CODE_ONLY:
		return 0
	return int(current_level_data.get("road_cards", 10))
