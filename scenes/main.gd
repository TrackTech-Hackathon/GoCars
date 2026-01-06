extends Node2D

## Main scene controller - connects UI to SimulationEngine
## Manages hearts, road cards, and tile editing

@onready var simulation_engine: SimulationEngine = $SimulationEngine
@onready var level_manager: LevelManager = LevelManager.new()
@onready var code_editor: TextEdit = $UI/CodeEditor
@onready var run_button: Button = $UI/RunButton
@onready var status_label: Label = $UI/StatusLabel
@onready var speed_label: Label = $UI/SpeedLabel
@onready var hearts_label: Label = $UI/HeartsLabel
@onready var road_cards_label: Label = $UI/RoadCardsLabel
@onready var test_vehicle: Vehicle = $GameWorld/TestVehicle
@onready var test_stoplight: Stoplight = $GameWorld/TestStoplight
@onready var roads_container: Node2D = $GameWorld/Roads

# Result popup elements
@onready var result_popup: Panel = $UI/ResultPopup
@onready var result_title: Label = $UI/ResultPopup/ResultTitle
@onready var result_message: Label = $UI/ResultPopup/ResultMessage
@onready var retry_button: Button = $UI/ResultPopup/RetryButton
@onready var next_button: Button = $UI/ResultPopup/NextButton

# Stoplight panel elements
@onready var stoplight_panel: Panel = $UI/StoplightPanel
@onready var stoplight_red_button: Button = $UI/StoplightPanel/RedButton
@onready var stoplight_yellow_button: Button = $UI/StoplightPanel/YellowButton
@onready var stoplight_green_button: Button = $UI/StoplightPanel/GreenButton
@onready var stoplight_state_label: Label = $UI/StoplightPanel/StateLabel

# Help panel elements
@onready var help_panel: Panel = $UI/HelpPanel
@onready var toggle_help_button: Button = $UI/ToggleHelpButton

# Current line highlighting
var _current_executing_line: int = -1

# Game state
var hearts: int = 10
var road_cards: int = 10
var initial_hearts: int = 10
var initial_road_cards: int = 10

# Road tile constants
const TILE_SIZE: int = 144
var road_tile_scene: PackedScene = preload("res://scenes/map_editor/road_tile.tscn")
var road_tiles: Dictionary = {}  # Key: Vector2i grid position, Value: RoadTile instance

# Map editing state
var is_editing_enabled: bool = true

# Camera movement
const CAMERA_SPEED: float = 500.0
const CAMERA_ZOOM_DEFAULT: Vector2 = Vector2(0.5, 0.5)  # Zoomed out to see more
@onready var camera: Camera2D = $GameWorld/Camera2D

# Parking spots (spawn and destination)
@onready var spawn_parking: Sprite2D = $GameWorld/SpawnParking
@onready var destination_parking: Sprite2D = $GameWorld/DestinationParking

# Car spawning
var car_spawn_timer: float = 0.0
const CAR_SPAWN_INTERVAL: float = 15.0  # Spawn every 15 seconds
# Spawn position - will be set from parking spot
# Road is at row 3, tile center is at y = 3*144 + 72 = 504
var car_spawn_position: Vector2 = Vector2(72, 504)  # Tile (0,3) center
var car_spawn_direction: Vector2 = Vector2.RIGHT
var car_spawn_rotation: float = PI / 2  # 90 degrees - car faces right
var car_destination: Vector2 = Vector2(1368, 504)  # Tile (9,3) center (9*144+72)
var is_spawning_cars: bool = false
var next_car_id: int = 2  # Start from 2 since car1 is the test vehicle


func _ready() -> void:
	# Initialize the tilemap with some grass
	_create_default_map()

	# Initialize level manager
	add_child(level_manager)
	level_manager.set_simulation_engine(simulation_engine)
	level_manager.set_game_world($GameWorld)

	# Connect level manager signals
	level_manager.level_completed.connect(_on_level_manager_completed)
	level_manager.level_failed.connect(_on_level_manager_failed)

	# Register vehicle with simulation engine
	simulation_engine.register_vehicle(test_vehicle)

	# Pass road checker reference to vehicle for road detection
	test_vehicle.set_road_checker(self)

	# Register stoplight if it exists
	if test_stoplight:
		simulation_engine.register_stoplight(test_stoplight)

	# Connect UI signals
	run_button.pressed.connect(_on_run_button_pressed)

	# Connect simulation signals
	simulation_engine.simulation_started.connect(_on_simulation_started)
	simulation_engine.simulation_paused.connect(_on_simulation_paused)
	simulation_engine.simulation_ended.connect(_on_simulation_ended)
	simulation_engine.car_reached_destination.connect(_on_car_reached_destination)
	simulation_engine.car_crashed.connect(_on_car_crashed)
	simulation_engine.level_completed.connect(_on_level_completed)
	simulation_engine.level_failed.connect(_on_level_failed)
	simulation_engine.execution_line_changed.connect(_on_execution_line_changed)
	simulation_engine.execution_error_occurred.connect(_on_execution_error)

	# Connect vehicle signals if vehicle exists
	if test_vehicle:
		test_vehicle.ran_red_light.connect(_on_car_ran_red_light)
		test_vehicle.off_road_crash.connect(_on_car_off_road)

	# Connect result popup buttons
	retry_button.pressed.connect(_on_retry_pressed)
	next_button.pressed.connect(_on_next_pressed)

	# Connect stoplight panel buttons
	stoplight_red_button.pressed.connect(_on_stoplight_red_pressed)
	stoplight_yellow_button.pressed.connect(_on_stoplight_yellow_pressed)
	stoplight_green_button.pressed.connect(_on_stoplight_green_pressed)

	# Connect help panel button
	toggle_help_button.pressed.connect(_on_toggle_help_pressed)

	# Update stoplight panel if stoplight exists
	if test_stoplight:
		test_stoplight.state_changed.connect(_on_stoplight_state_changed)
		_update_stoplight_state_label()

	# Set initial code (example showing new features)
	code_editor.text = "car.go()"

	# Enable line numbers in code editor (CodeEdit has this, TextEdit doesn't)
	# Note: If using CodeEdit, uncomment these:
	# code_editor.gutters_draw_line_numbers = true
	# code_editor.highlight_current_line = true

	_update_status("Ready - Enter code and press 'Run Code' (F5)")
	_update_speed_label()
	_update_hearts_label()
	_update_road_cards_label()


func _process(delta: float) -> void:
	# Handle camera movement (WASD or Arrow keys)
	if camera:
		var camera_velocity = Vector2.ZERO
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
			camera_velocity.y -= 1
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
			camera_velocity.y += 1
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
			camera_velocity.x -= 1
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
			camera_velocity.x += 1

		if camera_velocity != Vector2.ZERO:
			camera.position += camera_velocity.normalized() * CAMERA_SPEED * delta

	# Handle car spawning
	if is_spawning_cars:
		car_spawn_timer += delta
		if car_spawn_timer >= CAR_SPAWN_INTERVAL:
			car_spawn_timer = 0.0
			_spawn_new_car()


func _create_default_map() -> void:
	# With 144x144 tiles, create a horizontal road using RoadTile scenes
	# No grass for now as per user request - only roads

	# Add a horizontal road (10 tiles = 1440 pixels wide)
	# Position at row 3 (y=3) so cars at y=432+72=504 are centered on road
	for x in range(0, 10):
		var grid_pos = Vector2i(x, 3)
		_place_road_tile(grid_pos)

	# Connect adjacent road tiles
	_update_all_road_connections()


func _place_road_tile(grid_pos: Vector2i) -> RoadTile:
	# Check if tile already exists
	if road_tiles.has(grid_pos):
		return road_tiles[grid_pos]

	# Create new road tile
	var road_tile = road_tile_scene.instantiate() as RoadTile
	road_tile.position = Vector2(grid_pos.x * TILE_SIZE, grid_pos.y * TILE_SIZE)
	roads_container.add_child(road_tile)
	road_tiles[grid_pos] = road_tile
	return road_tile


func _remove_road_tile(grid_pos: Vector2i) -> void:
	if road_tiles.has(grid_pos):
		var road_tile = road_tiles[grid_pos]
		road_tile.queue_free()
		road_tiles.erase(grid_pos)
		_update_all_road_connections()


func _update_all_road_connections() -> void:
	# Update connections for all road tiles
	for grid_pos in road_tiles:
		_update_road_tile_connections(grid_pos)


func _update_road_tile_connections(grid_pos: Vector2i) -> void:
	if not road_tiles.has(grid_pos):
		return

	var road_tile = road_tiles[grid_pos] as RoadTile

	# Check all 8 neighbors
	var directions = {
		"top": Vector2i(0, -1),
		"bottom": Vector2i(0, 1),
		"left": Vector2i(-1, 0),
		"right": Vector2i(1, 0),
		"top_left": Vector2i(-1, -1),
		"top_right": Vector2i(1, -1),
		"bottom_left": Vector2i(-1, 1),
		"bottom_right": Vector2i(1, 1)
	}

	var conn_dict = {}
	var extended_dict = {}

	for dir_name in directions:
		var offset = directions[dir_name]
		var neighbor_pos = grid_pos + offset
		conn_dict[dir_name] = road_tiles.has(neighbor_pos)

		# Check 2-step connections for extended visibility rules
		var two_step_pos = grid_pos + offset * 2
		var extended_key = dir_name + "_" + dir_name
		if road_tile.extended_connections.has(extended_key):
			extended_dict[extended_key] = road_tiles.has(two_step_pos)

	road_tile.set_all_connections(conn_dict, extended_dict)


## Check if there's a road tile at the given world position (public API for vehicles)
func is_road_at_position(world_pos: Vector2) -> bool:
	var grid_pos = Vector2i(int(world_pos.x / TILE_SIZE), int(world_pos.y / TILE_SIZE))
	return road_tiles.has(grid_pos)


func _get_grid_pos_from_world(world_pos: Vector2) -> Vector2i:
	return Vector2i(int(world_pos.x / TILE_SIZE), int(world_pos.y / TILE_SIZE))


## Get tile size (public API for vehicles)
func get_tile_size() -> float:
	return float(TILE_SIZE)


func _on_run_button_pressed() -> void:
	var code = code_editor.text
	if code.strip_edges().is_empty():
		_update_status("Error: No code entered")
		return

	# Reset vehicle position before running (check if vehicle still exists)
	if is_instance_valid(test_vehicle):
		if test_vehicle.vehicle_state == 1:  # Only reset if not crashed
			test_vehicle.reset(car_spawn_position, Vector2.RIGHT)
		else:
			# Vehicle is crashed, spawn a new one
			_respawn_test_vehicle()
	else:
		# Vehicle was freed, spawn a new one
		_respawn_test_vehicle()

	# Execute the code
	simulation_engine.execute_code(code)


func _on_simulation_started() -> void:
	_update_status("Running...")
	run_button.disabled = true
	is_editing_enabled = true  # Keep editing enabled during gameplay
	is_spawning_cars = true  # Start spawning cars
	car_spawn_timer = 0.0  # Reset spawn timer


func _on_simulation_paused() -> void:
	_update_status("Paused (Press Space to resume)")


func _on_simulation_ended(success: bool) -> void:
	run_button.disabled = false
	is_editing_enabled = true
	is_spawning_cars = false  # Stop spawning cars
	_current_executing_line = -1  # Clear line highlighting
	if success:
		_update_status("Simulation complete!")
	else:
		_update_status("Simulation failed")


func _on_car_reached_destination(car_id: String) -> void:
	_update_status("Car '%s' reached destination!" % car_id)


func _on_car_crashed(car_id: String) -> void:
	_lose_heart()
	_update_status("Car '%s' crashed! Lost 1 heart" % car_id)


func _on_car_off_road(car_id: String) -> void:
	_lose_heart()
	_update_status("Car '%s' went off-road! Lost 1 heart" % car_id)


func _on_level_completed(stars: int) -> void:
	_update_status("Level Complete! Stars: %s" % stars)
	_show_victory_popup(stars)


func _on_level_failed(reason: String) -> void:
	_update_status("Level Failed: %s" % reason)
	_show_failure_popup(reason)


func _on_car_ran_red_light(vehicle_id: String, stoplight_id: String) -> void:
	hearts -= 1
	_update_hearts_label()
	_update_status("%s ran a red light! (-1 heart)" % vehicle_id)
	if hearts <= 0:
		_on_level_failed("Ran too many red lights!")


func _on_execution_line_changed(line_number: int) -> void:
	# Clear previous line highlight
	if _current_executing_line > 0:
		var prev_line = _current_executing_line - 1
		if prev_line < code_editor.get_line_count():
			code_editor.set_line_background_color(prev_line, Color(0, 0, 0, 0))  # Transparent

	# Update the current executing line
	_current_executing_line = line_number

	# Highlight the new line (TextEdit lines are 0-indexed, code lines are 1-indexed)
	if line_number > 0:
		var target_line = line_number - 1
		if target_line < code_editor.get_line_count():
			# Highlight with a yellow/gold background color
			code_editor.set_line_background_color(target_line, Color(0.3, 0.3, 0.0, 0.5))
			# Set caret to current line (without scrolling)
			code_editor.set_caret_line(target_line)


func _on_execution_error(error: String, line: int) -> void:
	_update_status("Error at line %d: %s" % [line, error])
	# Clear previous highlight
	if _current_executing_line > 0:
		var prev_line = _current_executing_line - 1
		if prev_line < code_editor.get_line_count():
			code_editor.set_line_background_color(prev_line, Color(0, 0, 0, 0))
	# Highlight the error line in red
	if line > 0:
		var target_line = line - 1
		if target_line < code_editor.get_line_count():
			code_editor.set_line_background_color(target_line, Color(0.5, 0.0, 0.0, 0.5))
			code_editor.set_caret_line(target_line)


## Clear any line highlighting in the code editor
func _clear_line_highlight() -> void:
	if _current_executing_line > 0:
		var prev_line = _current_executing_line - 1
		if prev_line < code_editor.get_line_count():
			code_editor.set_line_background_color(prev_line, Color(0, 0, 0, 0))
	_current_executing_line = -1


func _on_level_manager_completed(level_id: String, stars: int) -> void:
	_update_status("Level '%s' complete with %d stars!" % [level_id, stars])
	_show_victory_popup(stars)


func _on_level_manager_failed(level_id: String, reason: String) -> void:
	_update_status("Level '%s' failed: %s" % [level_id, reason])
	_show_failure_popup(reason)


func _update_status(message: String) -> void:
	status_label.text = "Status: %s" % message


func _update_speed_label() -> void:
	speed_label.text = "Speed: %.1fx" % simulation_engine.speed_multiplier


func _update_hearts_label() -> void:
	hearts_label.text = "Hearts: %d" % hearts


func _update_road_cards_label() -> void:
	road_cards_label.text = "Road Cards: %d" % road_cards


func _lose_heart() -> void:
	hearts -= 1
	_update_hearts_label()
	if hearts <= 0:
		_on_level_failed("Out of hearts!")


func _show_victory_popup(stars: int) -> void:
	result_title.text = "LEVEL COMPLETE!"

	# Create star display with filled/empty stars
	var star_display = ""
	for i in range(3):
		if i < stars:
			star_display += "[*]"
		else:
			star_display += "[ ]"

	# Count cars that reached destination
	var cars_completed = 0
	var total_cars = 0
	var vehicles = get_tree().get_nodes_in_group("vehicles")
	for vehicle in vehicles:
		total_cars += 1
		if vehicle.is_at_destination():
			cars_completed += 1

	# Build result message
	var message_parts: Array = []
	message_parts.append("Stars: %s" % star_display)
	message_parts.append("Time: %.1fs" % simulation_engine.get_elapsed_time())
	message_parts.append("Cars: %d/%d" % [cars_completed, total_cars])
	message_parts.append("Hearts remaining: %d" % hearts)

	result_message.text = "\n".join(message_parts)
	next_button.visible = true
	result_popup.visible = true


func _show_failure_popup(reason: String) -> void:
	result_title.text = "LEVEL FAILED"

	# Build detailed failure message based on reason
	var message_parts: Array = []
	message_parts.append(reason)
	message_parts.append("")  # Empty line

	# Add specific failure context
	if reason.find("hearts") >= 0 or reason.find("Hearts") >= 0:
		message_parts.append("Too many crashes!")
	elif reason.find("Time") >= 0 or reason.find("time") >= 0:
		message_parts.append("Try to be more efficient.")
	elif reason.find("infinite loop") >= 0:
		message_parts.append("Check your code for infinite loops.")
		message_parts.append("Use break or proper conditions.")
	elif reason.find("map") >= 0 or reason.find("boundary") >= 0:
		message_parts.append("Keep cars on the road!")
	elif reason.find("Error") >= 0 or reason.find("error") >= 0:
		message_parts.append("Check your Python syntax.")

	message_parts.append("")
	message_parts.append("Press R to retry")

	result_message.text = "\n".join(message_parts)
	next_button.visible = false  # Can't proceed on failure
	result_popup.visible = true


func _hide_result_popup() -> void:
	result_popup.visible = false


func _on_retry_pressed() -> void:
	_hide_result_popup()
	simulation_engine.reset()
	is_spawning_cars = false
	_clear_line_highlight()

	# Clear ALL spawned cars (crashed and active) except we'll respawn test vehicle
	_clear_all_spawned_cars()

	# Reset car ID counter
	next_car_id = 2

	# Always respawn the test vehicle fresh
	_respawn_test_vehicle()

	if test_stoplight:
		test_stoplight.reset()
	hearts = initial_hearts
	_update_hearts_label()
	_update_status("Reset - Ready")
	run_button.disabled = false


func _on_next_pressed() -> void:
	_hide_result_popup()

	# Try to load next level
	if level_manager.is_level_loaded():
		if level_manager.go_to_next_level():
			_update_status("Loading next level...")
			return

	# Fallback: just reset the current state
	_on_retry_pressed()
	_update_status("No more levels - Ready")


## Fast retry - instant reset (R or Ctrl+R)
func _do_fast_retry() -> void:
	_hide_result_popup()
	simulation_engine.reset()
	is_spawning_cars = false
	_clear_line_highlight()

	# Clear ALL spawned cars (crashed and active) except we'll respawn test vehicle
	_clear_all_spawned_cars()

	# Reset car ID counter
	next_car_id = 2

	# Always respawn the test vehicle fresh
	_respawn_test_vehicle()

	if test_stoplight:
		test_stoplight.reset()
	hearts = initial_hearts
	_update_hearts_label()
	_update_status("Reset - Ready")
	run_button.disabled = false


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		# Check for Ctrl modifier
		var ctrl_pressed = event.ctrl_pressed

		match event.keycode:
			KEY_F5:
				# F5 - Run code
				if not run_button.disabled:
					_on_run_button_pressed()
			KEY_ENTER:
				# Ctrl+Enter - Run code
				if ctrl_pressed and not run_button.disabled:
					_on_run_button_pressed()
			KEY_R:
				# R or Ctrl+R - Fast Retry (reset level)
				_do_fast_retry()
			KEY_F10:
				# F10 - Step mode (execute one step)
				simulation_engine.step()
				_update_status("Step executed")
			KEY_EQUAL, KEY_KP_ADD:
				# + key for speed up, Ctrl++ for 4x
				if ctrl_pressed:
					simulation_engine.set_speed(simulation_engine.SPEED_FASTER)
				else:
					simulation_engine.speed_up()
				call_deferred("_update_speed_label")
			KEY_MINUS, KEY_KP_SUBTRACT:
				# - key for slow down
				simulation_engine.slow_down()
				call_deferred("_update_speed_label")
			KEY_F1:
				# F1 - Toggle help panel
				_on_toggle_help_pressed()

	# Handle tile editing (only when not running simulation)
	if is_editing_enabled:
		if event is InputEventMouseButton and event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				_place_road_at_mouse()
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				_remove_road_at_mouse()


func _place_road_at_mouse() -> void:
	if road_cards <= 0:
		_update_status("No road cards left!")
		return

	var mouse_pos = get_global_mouse_position()
	var grid_pos = _get_grid_pos_from_world(mouse_pos)

	# Check if tile is not already a road
	if road_tiles.has(grid_pos):
		_update_status("Road already exists here")
		return

	# Place road and consume a card
	_place_road_tile(grid_pos)
	_update_all_road_connections()
	road_cards -= 1
	_update_road_cards_label()
	_update_status("Road placed at %s" % grid_pos)


func _remove_road_at_mouse() -> void:
	var mouse_pos = get_global_mouse_position()
	var grid_pos = _get_grid_pos_from_world(mouse_pos)

	# Check if tile is a road
	if not road_tiles.has(grid_pos):
		_update_status("No road here to remove")
		return

	# Remove road and gain a card back
	_remove_road_tile(grid_pos)
	road_cards += 1
	_update_road_cards_label()
	_update_status("Road removed at %s" % grid_pos)


# ============================================
# Stoplight Panel Functions
# ============================================

func _on_stoplight_red_pressed() -> void:
	if test_stoplight:
		test_stoplight.set_red()
		_update_status("Stoplight set to RED")


func _on_stoplight_yellow_pressed() -> void:
	if test_stoplight:
		test_stoplight.set_yellow()
		_update_status("Stoplight set to YELLOW")


func _on_stoplight_green_pressed() -> void:
	if test_stoplight:
		test_stoplight.set_green()
		_update_status("Stoplight set to GREEN")


func _on_stoplight_state_changed(_stoplight_id: String, _new_state: String) -> void:
	_update_stoplight_state_label()


func _update_stoplight_state_label() -> void:
	if test_stoplight:
		var state = test_stoplight.get_state()
		stoplight_state_label.text = "Current: %s" % state.capitalize()


# ============================================
# Help Panel Functions
# ============================================

func _on_toggle_help_pressed() -> void:
	help_panel.visible = not help_panel.visible


# ============================================
# Car Spawning Functions
# ============================================

func _spawn_new_car() -> void:
	# Load a random car scene from the 7 available
	var car_scenes = [
		"res://scenes/entities/car_sedan.tscn",
		"res://scenes/entities/car_estate.tscn",
		"res://scenes/entities/car_micro.tscn",
		"res://scenes/entities/car_sport.tscn",
		"res://scenes/entities/car_pickup.tscn",
		"res://scenes/entities/car_jeepney.tscn",
		"res://scenes/entities/car_motorbike.tscn"
	]
	var random_index = randi() % car_scenes.size()
	var vehicle_scene = load(car_scenes[random_index])
	if vehicle_scene == null:
		_update_status("Error: Could not load vehicle scene")
		return

	# Create new vehicle instance
	var new_car = vehicle_scene.instantiate()
	new_car.vehicle_id = "car%d" % next_car_id
	next_car_id += 1

	# Set position and direction (car sprite faces UP, so rotation PI/2 makes it face RIGHT)
	new_car.global_position = car_spawn_position
	new_car.direction = car_spawn_direction
	new_car.rotation = car_spawn_rotation

	# Set destination
	new_car.destination = car_destination

	# Note: Vehicle type is already set in the scene file

	# Add to scene
	$GameWorld.add_child(new_car)

	# Set road checker reference
	new_car.set_road_checker(self)

	# Register with simulation engine
	simulation_engine.register_vehicle(new_car)

	# Connect signals
	new_car.reached_destination.connect(_on_car_reached_destination)
	new_car.crashed.connect(_on_car_crashed)
	new_car.off_road_crash.connect(_on_car_off_road)
	new_car.ran_red_light.connect(_on_car_ran_red_light)

	# Make aware of stoplight
	if test_stoplight:
		new_car.add_stoplight(test_stoplight)

	# Execute current code on the new car (using vehicle-specific interpreter)
	if is_spawning_cars:
		simulation_engine.execute_code_for_vehicle(code_editor.text, new_car)

	_update_status("Spawned %s: %s" % [new_car.get_vehicle_type_name(), new_car.vehicle_id])


func _clear_all_crashed_cars() -> void:
	# Get all vehicles in the scene
	var vehicles = get_tree().get_nodes_in_group("vehicles")
	for vehicle in vehicles:
		if vehicle.vehicle_state == 0:  # Crashed
			# Unregister from simulation engine
			simulation_engine.unregister_vehicle(vehicle.vehicle_id)
			vehicle.queue_free()


func _clear_all_spawned_cars() -> void:
	# Get all vehicles in the scene and remove them
	var vehicles = get_tree().get_nodes_in_group("vehicles")
	for vehicle in vehicles:
		# Unregister from simulation engine
		simulation_engine.unregister_vehicle(vehicle.vehicle_id)
		vehicle.queue_free()

	# Clear the test_vehicle reference
	test_vehicle = null


func _respawn_test_vehicle() -> void:
	# Load a random car scene from the 7 available
	var car_scenes = [
		"res://scenes/entities/car_sedan.tscn",
		"res://scenes/entities/car_estate.tscn",
		"res://scenes/entities/car_micro.tscn",
		"res://scenes/entities/car_sport.tscn",
		"res://scenes/entities/car_pickup.tscn",
		"res://scenes/entities/car_jeepney.tscn",
		"res://scenes/entities/car_motorbike.tscn"
	]
	var random_index = randi() % car_scenes.size()
	var vehicle_scene = load(car_scenes[random_index])
	if vehicle_scene == null:
		_update_status("Error: Could not load vehicle scene")
		return

	# Remove old test_vehicle if it exists but is crashed
	if is_instance_valid(test_vehicle):
		simulation_engine.unregister_vehicle(test_vehicle.vehicle_id)
		test_vehicle.queue_free()

	# Create new vehicle instance
	test_vehicle = vehicle_scene.instantiate()
	test_vehicle.vehicle_id = "car1"

	# Set position and direction (car sprite faces UP, so rotation PI/2 makes it face RIGHT)
	test_vehicle.global_position = car_spawn_position
	test_vehicle.direction = car_spawn_direction
	test_vehicle.rotation = car_spawn_rotation

	# Set destination
	test_vehicle.destination = car_destination

	# Add to scene
	$GameWorld.add_child(test_vehicle)

	# Set road checker reference
	test_vehicle.set_road_checker(self)

	# Register with simulation engine
	simulation_engine.register_vehicle(test_vehicle)

	# Connect signals
	test_vehicle.reached_destination.connect(_on_car_reached_destination)
	test_vehicle.crashed.connect(_on_car_crashed)
	test_vehicle.off_road_crash.connect(_on_car_off_road)
	test_vehicle.ran_red_light.connect(_on_car_ran_red_light)

	# Make aware of stoplight
	if test_stoplight:
		test_vehicle.add_stoplight(test_stoplight)
