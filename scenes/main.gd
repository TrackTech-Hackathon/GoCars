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
@onready var tile_map_layer: TileMapLayer = $GameWorld/TileMapLayer

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

# Current line highlighting
var _current_executing_line: int = -1

# Game state
var hearts: int = 10
var road_cards: int = 10
var initial_hearts: int = 10
var initial_road_cards: int = 10

# TileMap constants
const SOURCE_ID: int = 0
const TILE_SIZE: int = 64
const GRASS_TILE: Vector2i = Vector2i(0, 0)
const ROAD_TILE: Vector2i = Vector2i(1, 0)  # Basic road tile

# Map editing state
var is_editing_enabled: bool = true

# Car spawning
var car_spawn_timer: float = 0.0
const CAR_SPAWN_INTERVAL: float = 15.0  # Spawn every 15 seconds
# Spawn position aligned with tile (1, 4): X = 1*64+32 = 96, Y = 4*64+32 = 288 (tile center)
var car_spawn_position: Vector2 = Vector2(96, 288)
var car_spawn_direction: Vector2 = Vector2.RIGHT
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

	# Pass tile map layer to vehicle for road checking
	test_vehicle.set_tile_map_layer(tile_map_layer)

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

	# Connect vehicle stoplight signals if vehicle exists
	if test_vehicle:
		test_vehicle.stopped_at_light.connect(_on_car_stopped_at_light)
		test_vehicle.resumed_from_light.connect(_on_car_resumed_from_light)
		test_vehicle.off_road_crash.connect(_on_car_off_road)

	# Connect result popup buttons
	retry_button.pressed.connect(_on_retry_pressed)
	next_button.pressed.connect(_on_next_pressed)

	# Connect stoplight panel buttons
	stoplight_red_button.pressed.connect(_on_stoplight_red_pressed)
	stoplight_yellow_button.pressed.connect(_on_stoplight_yellow_pressed)
	stoplight_green_button.pressed.connect(_on_stoplight_green_pressed)

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
	# Handle car spawning
	if is_spawning_cars:
		car_spawn_timer += delta
		if car_spawn_timer >= CAR_SPAWN_INTERVAL:
			car_spawn_timer = 0.0
			_spawn_new_car()


func _create_default_map() -> void:
	# Create a simple grass field with a road path
	for x in range(-5, 15):
		for y in range(-5, 15):
			tile_map_layer.set_cell(Vector2i(x, y), SOURCE_ID, GRASS_TILE)

	# Add a horizontal road in the middle
	for x in range(0, 12):
		tile_map_layer.set_cell(Vector2i(x, 4), SOURCE_ID, ROAD_TILE)


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


func _on_car_stopped_at_light(car_id: String, stoplight_id: String) -> void:
	_update_status("Car '%s' stopped at red light '%s'" % [car_id, stoplight_id])


func _on_car_resumed_from_light(car_id: String, stoplight_id: String) -> void:
	_update_status("Car '%s' resumed (light '%s' turned green)" % [car_id, stoplight_id])


func _on_execution_line_changed(line_number: int) -> void:
	# Update the current executing line (highlight it)
	_current_executing_line = line_number
	# TextEdit lines are 0-indexed, but code lines are 1-indexed
	if line_number > 0:
		var target_line = line_number - 1
		# Set caret to the current line to highlight it
		code_editor.set_caret_line(target_line)
		# Ensure the line is visible
		code_editor.center_viewport_to_caret()


func _on_execution_error(error: String, line: int) -> void:
	_update_status("Error at line %d: %s" % [line, error])
	# Highlight the error line
	if line > 0:
		code_editor.set_caret_line(line - 1)
		code_editor.center_viewport_to_caret()


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
	var tile_pos = tile_map_layer.local_to_map(tile_map_layer.to_local(mouse_pos))

	# Check if tile is not already a road
	var current_tile = tile_map_layer.get_cell_atlas_coords(tile_pos)
	if current_tile == ROAD_TILE:
		_update_status("Road already exists here")
		return

	# Place road and consume a card
	tile_map_layer.set_cell(tile_pos, SOURCE_ID, ROAD_TILE)
	road_cards -= 1
	_update_road_cards_label()
	_update_status("Road placed at %s" % tile_pos)


func _remove_road_at_mouse() -> void:
	var mouse_pos = get_global_mouse_position()
	var tile_pos = tile_map_layer.local_to_map(tile_map_layer.to_local(mouse_pos))

	# Check if tile is a road
	var current_tile = tile_map_layer.get_cell_atlas_coords(tile_pos)
	if current_tile != ROAD_TILE:
		_update_status("No road here to remove")
		return

	# Remove road and gain a card back
	tile_map_layer.set_cell(tile_pos, SOURCE_ID, GRASS_TILE)
	road_cards += 1
	_update_road_cards_label()
	_update_status("Road removed at %s" % tile_pos)


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
# Car Spawning Functions
# ============================================

func _spawn_new_car() -> void:
	# Load the vehicle scene
	var vehicle_scene = load("res://objects/test_vehicle.tscn")
	if vehicle_scene == null:
		_update_status("Error: Could not load vehicle scene")
		return

	# Create new vehicle instance
	var new_car = vehicle_scene.instantiate()
	new_car.vehicle_id = "car%d" % next_car_id
	next_car_id += 1

	# Assign random vehicle type for variety
	var random_type = Vehicle.get_random_type()
	new_car.vehicle_type = random_type

	# Set position and direction
	new_car.global_position = car_spawn_position
	new_car.direction = car_spawn_direction
	new_car.rotation = car_spawn_direction.angle()

	# Set destination (end of road at tile column 11, same row)
	new_car.destination = Vector2(11 * 64 + 32, 288)  # Tile (11, 4) center

	# Add to scene
	$GameWorld.add_child(new_car)

	# Set tilemap reference
	new_car.set_tile_map_layer(tile_map_layer)

	# Register with simulation engine
	simulation_engine.register_vehicle(new_car)

	# Connect signals
	new_car.reached_destination.connect(_on_car_reached_destination)
	new_car.crashed.connect(_on_car_crashed)
	new_car.off_road_crash.connect(_on_car_off_road)
	new_car.stopped_at_light.connect(_on_car_stopped_at_light)
	new_car.resumed_from_light.connect(_on_car_resumed_from_light)

	# Make aware of stoplight
	if test_stoplight:
		new_car.add_stoplight(test_stoplight)

	# Execute current code on the new car
	if is_spawning_cars:
		simulation_engine.execute_code(code_editor.text)

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
	# Load the vehicle scene
	var vehicle_scene = load("res://objects/test_vehicle.tscn")
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

	# Set position and direction (aligned with road at tile row 4)
	test_vehicle.global_position = car_spawn_position
	test_vehicle.direction = Vector2.RIGHT
	test_vehicle.rotation = Vector2.RIGHT.angle()

	# Set destination (end of road at tile column 11, same row)
	test_vehicle.destination = Vector2(11 * 64 + 32, 288)  # Tile (11, 4) center

	# Add to scene
	$GameWorld.add_child(test_vehicle)

	# Set tilemap reference
	test_vehicle.set_tile_map_layer(tile_map_layer)

	# Register with simulation engine
	simulation_engine.register_vehicle(test_vehicle)

	# Connect signals
	test_vehicle.reached_destination.connect(_on_car_reached_destination)
	test_vehicle.crashed.connect(_on_car_crashed)
	test_vehicle.off_road_crash.connect(_on_car_off_road)
	test_vehicle.stopped_at_light.connect(_on_car_stopped_at_light)
	test_vehicle.resumed_from_light.connect(_on_car_resumed_from_light)

	# Make aware of stoplight
	if test_stoplight:
		test_vehicle.add_stoplight(test_stoplight)
